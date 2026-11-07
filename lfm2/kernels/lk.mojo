# LFM2 (LiquidAI/LFM2.5-2.6B) kernels for the Adreno 840: a token (decode) or a batch of prompt rows (prefill) through
# the hybrid stack of double-gated short-convolution layers and grouped-query attention layers, each followed by a
# SwiGLU MLP, with pre-norms (RMSNorm, eps 1e-5, x / rms * w).
#
# Two weight storages (lfm2/export.py):
#   q4   the QAD GGUF's own numbers: Q4_0 matrices as int4 words (8 a uint32, two's complement, low nibble first) with
#        an fp16 scale per 32 weights of a row; the Q6_K tied embedding/head repacked to 208-byte super-blocks
#        (ql[128], qh[64], int8 scales[16]) with the fp16 d's apart
#   f16  every matrix dequantized to fp16, rows of [out, in]
# Activations, the K/V cache and the conv state are fp32.
#
# Every workgroup is one 64-lane subgroup unless noted. Loops before a subgroup sum run the same number of
# iterations in every lane (guards inside).
from std.math import exp, rsqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR
from max.gpu.memory import AddressSpace
from max.gpu.primitives.warp import sum as warp_sum

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
comptime I32 = UnsafePointer[Int32, MutAnyOrigin]

comptime G = 32  # weights per Q4_0 scale
comptime EPS = Float32(1e-5)
comptime HD = 64  # head dim
comptime KTILE = 1024  # keys an attention tile holds in shared memory


@always_inline
def silu(x: Float32) -> Float32:
    return x / (1 + exp(-x))


@always_inline
def dot_q4(wq: U32, ws: F16, row: Int, cols: Int, x: F32, t: Int) -> Float32:
    """Lane t's share of W[row] . x, W int4 (8 a word) with an fp16 scale per 32: lanes take words t, t + 64, ..."""
    var words = cols // 8
    var acc = Float32(0)
    for i in range((words + 63) // 64):
        var wi = i * 64 + t
        if wi < words:
            var word = wq[row * words + wi]
            var xv = x.load[width=8](wi * 8)
            var part = Float32(0)
            comptime for j in range(8):
                var q = Int32((word >> UInt32(4 * j)) & 15) ^ 8
                part += Float32(q - 8) * xv[j]
            acc += part * ws[row * (cols // G) + wi // 4].cast[DType.float32]()
    return acc


@always_inline
def dot_q4b(wq: U32, ws: F16, row: Int, cols: Int, x: F32, t: Int) -> Float32:
    """dot_q4 a block of 32 weights (4 words, one scale) a lane a step: one 16-byte load of W and one scale."""
    var blocks = cols // G
    var acc = Float32(0)
    var wr = wq + row * (cols // 8)
    for i in range((blocks + 63) // 64):
        var b = i * 64 + t
        if b < blocks:
            var w4 = wr.load[width=4](b * 4)
            var part = Float32(0)
            comptime for k in range(4):
                var xv = x.load[width=8](b * 32 + k * 8)
                comptime for j in range(8):
                    var q = Int32((w4[k] >> UInt32(4 * j)) & 15) ^ 8
                    part += Float32(q - 8) * xv[j]
            acc += part * ws[row * blocks + b].cast[DType.float32]()
    return acc


@always_inline
def dot_h(w: F16, row: Int, cols: Int, x: F32, t: Int) -> Float32:
    """Lane t's share of W[row] . x, W fp16: 8 weights a lane a step."""
    var chunks = cols // 8
    var acc = SIMD[DType.float32, 8](0)
    var wr = w + row * cols
    for i in range((chunks + 63) // 64):
        var c = i * 64 + t
        if c < chunks:
            acc += wr.load[width=8](c * 8).cast[DType.float32]() * x.load[width=8](c * 8)
    return acc.reduce_add()


@always_inline
def q6_chunk[DEQ: Bool](wq: U32, wd: F16, row: Int, cols: Int, c: Int, x: F32, y: F32) -> Float32:
    """Chunk c (32 weights) of a Q6_K row: element e = 32 c + l of super-block b = c / 8 is (6 bits - 32) times
    d * scales[e % 256 / 16]. DEQ: write the 32 dequantized weights to y[32 c ..] (as ggml computes them, (d sc) q);
    else return their dot product with x[32 c ..]."""
    var nb = cols // 256
    var b = c // 8
    var k = c % 8
    var h = k // 4
    var g = k % 4
    var base = (row * nb + b) * 52  # words: ql 0..31, qh 32..47, scales 48..51
    var qlb = base + (64 * h + 32 * (g & 1)) // 4
    var qhb = base + 32 + 8 * h
    var si = 8 * h + 2 * g  # the scale of l < 16; si + 1 for l >= 16
    var scw = wq[base + 48 + si // 4]
    var s0 = Int32((scw >> UInt32(8 * (si % 4))) & 255) ^ 128
    var s1 = Int32((scw >> UInt32(8 * (si % 4) + 8)) & 255) ^ 128
    var d = wd[row * nb + b].cast[DType.float32]()
    var ds0 = d * Float32(s0 - 128)
    var ds1 = d * Float32(s1 - 128)
    var lo_shift = UInt32(4 * (g >> 1))
    var hi_shift = UInt32(2 * g)
    var acc0 = Float32(0)
    var acc1 = Float32(0)
    comptime for w in range(8):
        var qlw = wq[qlb + w]
        var qhw = wq[qhb + w]
        comptime for kk in range(4):
            var q = Int32(((qlw >> (UInt32(8 * kk) + lo_shift)) & 15) | (((qhw >> (UInt32(8 * kk) + hi_shift)) & 3) << 4))
            var qf = Float32(q - 32)
            comptime if DEQ:
                comptime if w < 4:
                    y[c * 32 + 4 * w + kk] = ds0 * qf
                else:
                    y[c * 32 + 4 * w + kk] = ds1 * qf
            else:
                comptime if w < 4:
                    acc0 += qf * x[c * 32 + 4 * w + kk]
                else:
                    acc1 += qf * x[c * 32 + 4 * w + kk]
    return ds0 * acc0 + ds1 * acc1


# ---- matrix-vector products (decode) ------------------------------------------------------------------------------


def gemv_q4[B: Bool = False](wq: U32, ws: F16, x: F32, y: F32, cols: Int32):
    """y[r] = W[r] . x, int4 W: a workgroup a row (B: dot_q4b's 16-byte loads)."""
    var r = Int(block_idx.x)
    var s: Float32
    comptime if B:
        s = warp_sum(dot_q4b(wq, ws, r, Int(cols), x, Int(thread_idx.x)))
    else:
        s = warp_sum(dot_q4(wq, ws, r, Int(cols), x, Int(thread_idx.x)))
    if thread_idx.x == 0:
        y[r] = s


def gemv_h(w: F16, x: F32, y: F32, cols: Int32):
    """y[r] = W[r] . x, fp16 W: a workgroup a row."""
    var r = Int(block_idx.x)
    var s = warp_sum(dot_h(w, r, Int(cols), x, Int(thread_idx.x)))
    if thread_idx.x == 0:
        y[r] = s


def gate_up_q4[B: Bool = False](wq: U32, ws: F16, x: F32, a: F32, cols: Int32, f: Int32):
    """a[j] = silu(w1[j] . x) * (w3[j] . x): rows j and f + j of the fused gate|up matrix, workgroup j."""
    var j = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var g: Float32
    var u: Float32
    comptime if B:
        g = warp_sum(dot_q4b(wq, ws, j, Int(cols), x, t))
        u = warp_sum(dot_q4b(wq, ws, Int(f) + j, Int(cols), x, t))
    else:
        g = warp_sum(dot_q4(wq, ws, j, Int(cols), x, t))
        u = warp_sum(dot_q4(wq, ws, Int(f) + j, Int(cols), x, t))
    if t == 0:
        a[j] = silu(g) * u


def gate_up_h(w: F16, x: F32, a: F32, cols: Int32, f: Int32):
    var j = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var g = warp_sum(dot_h(w, j, Int(cols), x, t))
    var u = warp_sum(dot_h(w, Int(f) + j, Int(cols), x, t))
    if t == 0:
        a[j] = silu(g) * u


def head_q6(wq: U32, wd: F16, x: F32, y: F32, cols: Int32):
    """The tied head: y[r] = E[r] . x, E the Q6_K embedding: a workgroup a row, a 32-weight chunk a lane a step."""
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var n = Int(cols)
    var chunks = n // 32
    var acc = Float32(0)
    for i in range((chunks + 63) // 64):
        var c = i * 64 + t
        if c < chunks:
            acc += q6_chunk[False](wq, wd, r, n, c, x, x)
    var s = warp_sum(acc)
    if t == 0:
        y[r] = s


def argmax(logits: F32, n: Int32, dst: I32, slot: Int32):
    """Greedy: the index of the largest logit (the lowest among equals) into dst[slot]. One 256-thread workgroup."""
    var sv = stack_allocation[256, Float32, address_space=AddressSpace.SHARED]()
    var si = stack_allocation[256, Int32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var best: Float32 = -3.402823e38
    var bi = Int32(0)
    for j in range(t, Int(n), 256):
        var v = logits[j]
        if v > best:
            best = v
            bi = Int32(j)
    sv[t] = best
    si[t] = bi
    barrier()
    comptime for stage in range(8):
        if t < 128 >> stage:
            var o = t + (128 >> stage)
            if sv[o] > sv[t] or (sv[o] == sv[t] and si[o] < si[t]):
                sv[t] = sv[o]
                si[t] = si[o]
        barrier()
    if t == 0:
        dst[Int(slot)] = si[0]


# ---- row kernels: row t of a batch is position p0 + t (decode: one row) ------------------------------------------


def embed_q6(ids: I32, slot0: Int32, wq: U32, wd: F16, x: F32, cols: Int32):
    """x[t] = the Q6_K embedding row of token ids[slot0 + t], dequantized as ggml does: workgroup t."""
    var t = Int(block_idx.x)
    var tok = Int(ids[Int(slot0) + t])
    var n = Int(cols)
    var chunks = n // 32
    for c in range(Int(thread_idx.x), chunks, 64):
        _ = q6_chunk[True](wq, wd, tok, n, c, x, x + t * n)


def embed_h(ids: I32, slot0: Int32, w: F16, x: F32, cols: Int32):
    """x[t] = the fp16 embedding row of token ids[slot0 + t]: workgroup t."""
    var t = Int(block_idx.x)
    var tok = Int(ids[Int(slot0) + t])
    var n = Int(cols)
    for j in range(Int(thread_idx.x), n, 64):
        x[t * n + j] = w[tok * n + j].cast[DType.float32]()


def add_norm(x: F32, y: F32, w: F32, xn: F32, n: Int32, add: Int32):
    """Row t (workgroup t): [x += y if add], then xn = x / rms(x) * w."""
    var o = Int(block_idx.x) * Int(n)
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = x[o + j]
        if add != 0:
            v += y[o + j]
            x[o + j] = v
        ss += v * v
    var r = rsqrt(warp_sum(ss) / Float32(Int(n)) + EPS)
    for j in range(lane, Int(n), 64):
        xn[o + j] = x[o + j] * r * w[j]


def short_conv(bcx: F32, w: F32, state: F32, y: F32, p0: Int32, count: Int32, d: Int32, update: Int32, bxo: F32):
    """The double-gated short convolution of rows t < count: bcx rows are B | C | x (3 d), Bx = B * x, and
    y[t, c] = C * (w[c, 0] Bx[p - 2] + w[c, 1] Bx[p - 1] + w[c, 2] Bx[p]) at position p = p0 + t (causal, zero before
    the sequence). Bx of earlier rows of the batch from bcx, of earlier positions from the state ring (slot p % 3,
    zeroed at the start). update 1 (decode, count 1): also write Bx[p] into its slot (a slot no thread reads here);
    update 2 (a speculative verify): write each row's Bx into bxo [count, d], for dsk.conv_commit."""
    var i = global_idx.x
    var D = Int(d)
    if i >= Int(count) * D:
        return
    var t = i // D
    var c = i % D
    var r = bcx + t * 3 * D
    var bx0 = r[c] * r[2 * D + c]
    var bx = SIMD[DType.float32, 2](0)  # Bx at p - 1, p - 2
    comptime for k in range(1, 3):
        if t - k >= 0:
            var rk = bcx + (t - k) * 3 * D
            bx[k - 1] = rk[c] * rk[2 * D + c]
        else:
            var p = Int(p0) + t - k
            if p >= 0:
                bx[k - 1] = state[(p % 3) * D + c]
    var out = w[c * 3] * bx[1] + w[c * 3 + 1] * bx[0] + w[c * 3 + 2] * bx0
    y[t * D + c] = r[D + c] * out
    if update == 1:
        state[((Int(p0) + t) % 3) * D + c] = bx0
    elif update == 2:
        bxo[t * D + c] = bx0


def conv_state(bcx: F32, state: F32, p0: Int32, count: Int32, d: Int32):
    """After a batch: Bx of its last two rows into the state ring."""
    var i = global_idx.x
    var D = Int(d)
    if i >= 2 * D:
        return
    var t = Int(count) - 2 + i // D
    var c = i % D
    if t >= 0:
        var r = bcx + t * 3 * D
        state[((Int(p0) + t) % 3) * D + c] = r[c] * r[2 * D + c]


def qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, p0: Int32, heads: Int32, kvh: Int32,
                 scale: Float32):
    """Head block_idx.x of row block_idx.y of the fused q|k|v rows ((heads + 2 kvh) 64 floats each), position
    p = p0 + row: a query head gets its RMS norm (wq), RoPE and the attention scale, in place; a key head its RMS norm
    (wk) and RoPE, into K cache row p; a value head goes into V cache row p as it is. Lane d holds element d; RoPE
    rotates halves (rotate_half), the table row of p holds cos | sin of the first half."""
    var sh = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var t = Int(block_idx.y)
    var d = Int(thread_idx.x)
    var p = Int(p0) + t
    var nh = Int(heads)
    var kv = Int(kvh)
    var row = (nh + 2 * kv) * HD
    var v = qkv[t * row + h * HD + d]
    if h >= nh + kv:
        vc[p * kv * HD + (h - nh - kv) * HD + d] = v
        return
    var r = rsqrt(warp_sum(v * v) / Float32(HD) + EPS)
    var n = v * r * (wq[d] if h < nh else wk[d])
    sh[d] = n
    barrier()
    var j = d % 32
    var a = sh[j]
    var b = sh[j + 32]
    var cs = table[p * HD + j]
    var sn = table[p * HD + 32 + j]
    var o = (a * cs - b * sn) if d < 32 else (b * cs + a * sn)
    if h < nh:
        qkv[t * row + h * HD + d] = o * scale
    else:
        kc[p * kv * HD + (h - nh) * HD + d] = o


def attention(qkv: F32, kc: F32, vc: F32, y: F32, p0: Int32, heads: Int32, kvh: Int32):
    """softmax(q K^T) V for query head block_idx.x of row block_idx.y (position p = p0 + row), keys 0 .. p of KV
    head h / (heads / kvh); q already carries the scale. Keys in tiles of KTILE: a tile's scores in shared memory (a lane
    a key), then a lane a dimension for its values, with the running maximum and sum carried from tile to tile (online
    softmax). Up to KTILE keys this is one tile, the arithmetic of a plain softmax."""
    var sq = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var ss = stack_allocation[KTILE, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var t = Int(block_idx.y)
    var lane = Int(thread_idx.x)
    var p = Int(p0) + t
    var nh = Int(heads)
    var kv = Int(kvh)
    var g = h // (nh // kv)
    var krow = kv * HD
    sq[lane] = qkv[t * (nh + 2 * kv) * HD + h * HD + lane]
    barrier()
    var vp = vc + (g * HD + lane)
    var run_max: Float32 = -3.402823e38
    var run_sum: Float32 = 0
    var value: Float32 = 0
    for t0 in range(0, p + 1, KTILE):
        var n = min(KTILE, p + 1 - t0)
        var highest: Float32 = -3.402823e38
        for j in range(lane, n, 64):
            var k = kc + ((t0 + j) * krow + g * HD)
            var acc = SIMD[DType.float32, 4](0)
            comptime for e in range(0, HD, 4):
                acc += k.load[width=4](e) * sq.load[width=4](e)
            var s = acc.reduce_add()
            ss[j] = s
            highest = max(highest, s)
        red[lane] = highest
        barrier()
        comptime for stage in range(6):
            if lane < 32 >> stage:
                red[lane] = max(red[lane], red[lane + (32 >> stage)])
            barrier()
        var new_max = max(run_max, red[0])
        barrier()
        var total: Float32 = 0
        for j in range(lane, n, 64):
            var e = exp(ss[j] - new_max)
            ss[j] = e
            total += e
        red[lane] = total
        barrier()
        comptime for stage in range(6):
            if lane < 32 >> stage:
                red[lane] += red[lane + (32 >> stage)]
            barrier()
        var shrink = exp(run_max - new_max)  # 0 for the first tile
        var part: Float32 = 0
        for j in range(n):
            part += ss[j] * vp[(t0 + j) * krow]
        value = value * shrink + part
        run_sum = run_sum * shrink + red[0]
        run_max = new_max
        barrier()  # the next tile's scores overwrite ss
    y[t * nh * HD + h * HD + lane] = value / run_sum


def silu_mul(gu: F32, a: F32, f: Int32, count: Int32):
    """a[t, j] = silu(gu[t, j]) * gu[t, f + j] for rows t < count of the fused gate|up product (rows of 2 f)."""
    var i = global_idx.x
    var n = Int(f)
    if i < Int(count) * n:
        var t = i // n
        var j = i % n
        a[t * n + j] = silu(gu[t * 2 * n + j]) * gu[t * 2 * n + n + j]


# ---- prefill projections: Y[rows, n] = X[rows, k] W^T ---------------------------------------------------------------


def gemm_h(w: F16, x: F32, y: F32, n: Int32, k: Int32):
    """fp16 W, no matrix units (the baseline): a 256-thread workgroup computes a 64 x 64 block of Y, 4 x 4 outputs a
    thread (rows ty + 16 i, columns tx + 16 j), staging X's and W's slices of 16 k in shared memory as fp32.
    rows, n: multiples of 64; k: of 16."""
    var sa = stack_allocation[64 * 17, Float32, address_space=AddressSpace.SHARED]()  # X: 64 rows of 16 (+1 pad)
    var sb = stack_allocation[64 * 17, Float32, address_space=AddressSpace.SHARED]()  # W: 64 rows of 16 (+1 pad)
    var t = Int(thread_idx.x)
    var tx = t % 16
    var ty = t // 16
    var row0 = Int(block_idx.y) * 64
    var col0 = Int(block_idx.x) * 64
    var K = Int(k)
    var acc = SIMD[DType.float32, 16](0)
    var lr = t // 4  # the 4 values this thread stages: row lr, columns lc .. lc + 3
    var lc = (t % 4) * 4
    for k0 in range(0, K, 16):
        var xv = x.load[width=4]((row0 + lr) * K + k0 + lc)
        var wv = w.load[width=4]((col0 + lr) * K + k0 + lc).cast[DType.float32]()
        comptime for e in range(4):
            sa[lr * 17 + lc + e] = xv[e]
            sb[lr * 17 + lc + e] = wv[e]
        barrier()
        comptime for kk in range(16):
            var a = SIMD[DType.float32, 4]()
            var b = SIMD[DType.float32, 4]()
            comptime for i in range(4):
                a[i] = sa[(ty + 16 * i) * 17 + kk]
                b[i] = sb[(tx + 16 * i) * 17 + kk]
            comptime for i in range(4):
                comptime for j in range(4):
                    acc[i * 4 + j] += a[i] * b[j]
        barrier()
    var N = Int(n)
    comptime for i in range(4):
        comptime for j in range(4):
            y[(row0 + ty + 16 * i) * N + col0 + tx + 16 * j] = acc[i * 4 + j]


comptime BM = 128
comptime BN = 128
comptime BK = 16
comptime KC = 8  # the 840's fp32 product: 64 x 64 x 8
comptime THREADS = 256


def gemm_q4(wq: U32, ws: F16, x: F32, y: F32, n: Int64, k: Int64):
    """int4 W on the matrix units: llama/kernels/prefill's p_gemm_q4 with an fp16 scale per 32 (Q4_0's). A 256-thread
    workgroup (2 x 2 subgroups) computes a 128 x 128 block of Y; per k step of 16 it stages X's slice and W's slice,
    unpacked to fp32, in shared memory; each subgroup multiplies its 64 x 64 tile on fp32 cooperative matrices
    (64 x 64 x 8). rows, n and k: multiples of 128, 128 and 16."""
    var sa = stack_allocation[BM * BK, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[BN * BK, Float32, address_space=AddressSpace.SHARED]()
    var ldy = Int(n)
    var ldx = Int(k)
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * BM
    var col0 = Int(block_idx.x) * BN
    var sr = (sg // 2) * 64
    var sc = (sg % 2) * 64
    var out = y.unsafe_offset((row0 + sr) * ldy + col0 + sc)
    var wr = t // (BK // 8)
    var wc = t % (BK // 8) * 8
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for k0 in range(0, ldx, BK):
        comptime for i in range(BM * BK // 4 // THREADS):
            var v = i * THREADS + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            sa.unsafe_store(r * BK + c, x.unsafe_load[width=4]((row0 + r) * ldx + k0 + c))
        var word = wq[(col0 + wr) * (ldx // 8) + (k0 + wc) // 8]
        var scale = ws[(col0 + wr) * (ldx // G) + (k0 + wc) // G].cast[DType.float32]()
        comptime for j in range(8):
            var q = Int32((word >> UInt32(4 * j)) & 15) ^ 8
            sb.unsafe_store(wr * BK + wc + j, Float32(q - 8) * scale)
        barrier()
        comptime for kk in range(0, BK, KC):
            var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sa.unsafe_offset(sr * BK + kk), BK)
            var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(sc * BK + kk), BK)
            acc = at.multiply_add(bt, acc)
        barrier()
    acc.store(out, ldy)
