# LFM2-MoE kernels (LFM2.5-8B-A1B, LFM2.5-24B-A2B) for the Adreno 840 / X2-90: the router and the routed experts.
# Everything else (short conv, attention, norms, the dense layers, the Q6_K head) is lfm2/kernels/lk.mojo's.
#
# The router (Lfm2MoeSparseMoeBlock): logits = W_router x (fp32 weights), s = sigmoid(logits); the top K of s + bias
# (the expert bias only chooses) and their weights s_k / (sum of the K s + 1e-6) (norm_topk_prob, scaling 1).
# Experts in the q4 storage (lfm2moe/export.py): egu = expert e's gate rows then its up rows at rows e * 2 FE, edown =
# its rows at e * D; int4 words with an fp16 scale per 32 (lk.dot_q4b's).
#
# Decode reads the K chosen experts' rows only (ids on the GPU: no host round trip). Prefill groups the batch's
# (token, choice) pairs by expert on the GPU (p_group), copies each expert's rows together (p_gather), and runs every
# expert's products in one launch on the matrix units (p_gemm_q4g: a work tile = an expert and 64 of its rows), then
# adds each token's K outputs, weighted (p_combine).
from std.math import exp
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR
from max.gpu.memory import AddressSpace
from max.gpu.primitives.warp import sum as warp_sum

import lk

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
comptime I32 = UnsafePointer[Int32, MutAnyOrigin]

comptime K = 4  # experts a token
comptime TM = 64  # rows a prefill work tile (one subgroup's cooperative matrix height)
comptime NEG = Float32(-3.402823e38)


def router(w: F32, x: F32, y: F32, cols: Int32, e: Int32):
    """y[row, r] = W[r] . x[row] (fp32 W [E, cols]): workgroup (r, row)."""
    var r = Int(block_idx.x)
    var row = Int(block_idx.y)
    var t = Int(thread_idx.x)
    var n = Int(cols)
    var wr = w + r * n
    var xr = x + row * n
    var acc = Float32(0)
    for i in range(0, n, 256):
        var c = i + t * 4
        if c < n:
            var a = wr.load[width=4](c)
            var b = xr.load[width=4](c)
            acc += (a * b).reduce_add()
    var s = warp_sum(acc)
    if t == 0:
        y[row * Int(e) + r] = s


def route(logits: F32, bias: F32, ids: I32, wts: F32, e: Int32):
    """Token row `row` (workgroup): its top K experts by sigmoid(logit) + bias (the lowest index among equals) into
    ids[row * K ..] and their normalized sigmoid weights into wts. An expert a lane (E <= 64)."""
    var row = Int(block_idx.x)
    var lane = Int(thread_idx.x)
    var sv = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var si = stack_allocation[64, Int32, address_space=AddressSpace.SHARED]()
    var ss = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var top = stack_allocation[K, Float32, address_space=AddressSpace.SHARED]()
    var s = Float32(0)
    var sel = NEG
    if lane < Int(e):
        s = 1 / (1 + exp(-logits[row * Int(e) + lane]))
        sel = s + bias[lane]
    ss[lane] = s
    for k in range(K):
        sv[lane] = sel
        si[lane] = Int32(lane)
        barrier()
        comptime for stage in range(6):
            if lane < 32 >> stage:
                var o = lane + (32 >> stage)
                if sv[o] > sv[lane] or (sv[o] == sv[lane] and si[o] < si[lane]):
                    sv[lane] = sv[o]
                    si[lane] = si[o]
            barrier()
        var win = Int(si[0])
        if lane == 0:
            ids[row * K + k] = Int32(win)
            top[k] = ss[win]
        if win == lane:
            sel = NEG
        barrier()
    if lane == 0:
        var total = Float32(0)
        comptime for k in range(K):
            total += top[k]
        total += 1e-6
        comptime for k in range(K):
            wts[row * K + k] = top[k] / total


def moe_gate_up(wq: U32, ws: F16, ids: I32, x: F32, a: F32, cols: Int32, fe: Int32):
    """Decode: a[k, j] = silu(gate_e[j] . x) * (up_e[j] . x) for the k-th chosen expert e = ids[k]: workgroup (j, k)."""
    var j = Int(block_idx.x)
    var k = Int(block_idx.y)
    var t = Int(thread_idx.x)
    var f = Int(fe)
    var row = Int(ids[k]) * 2 * f + j
    var g = warp_sum(lk.dot_q4b(wq, ws, row, Int(cols), x, t))
    var u = warp_sum(lk.dot_q4b(wq, ws, row + f, Int(cols), x, t))
    if t == 0:
        a[k * f + j] = lk.silu(g) * u


def moe_down(wq: U32, ws: F16, ids: I32, wts: F32, a: F32, y: F32, fe: Int32, d: Int32):
    """Decode: y[r] = sum_k wts[k] * down_e[r] . a[k] over the K chosen experts: workgroup r."""
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var f = Int(fe)
    var acc = Float32(0)
    comptime for k in range(K):
        acc += wts[k] * lk.dot_q4b(wq, ws, Int(ids[k]) * Int(d) + r, f, a + k * f, t)
    var s = warp_sum(acc)
    if t == 0:
        y[r] = s


# ---- prefill: the batch's experts grouped ---------------------------------------------------------------------------


def p_group(ids: I32, slot: I32, src: I32, tiles: I32, ntiles: I32, rows: Int32, e: Int32, tm: Int32):
    """One 64-lane workgroup. Expert e (lane e) takes the pairs i = t * K + k with ids[i] == e, in order: their rows in
    the grouped buffer are e's segment, which starts at offs[e] (the segments in expert order, each padded to tm rows):
    slot[i] = that row, src[row] = t. Work tiles of tm rows (expert, first row) into tiles; their number into ntiles.
    src's padding rows must hold -1 already (the caller fills it)."""
    var lane = Int(thread_idx.x)
    var cnt = stack_allocation[64, Int32, address_space=AddressSpace.SHARED]()
    var offs = stack_allocation[64, Int32, address_space=AddressSpace.SHARED]()
    var n = Int(rows) * K
    var c = 0
    if lane < Int(e):
        for i in range(n):
            if Int(ids[i]) == lane:
                c += 1
    cnt[lane] = Int32(c)
    barrier()
    var T = Int(tm)
    if lane == 0:
        var off = 0
        var nt = 0
        for x in range(Int(e)):
            offs[x] = Int32(off)
            var m = Int(cnt[x])
            var t0 = 0
            while t0 < m:
                tiles[2 * nt] = Int32(x)
                tiles[2 * nt + 1] = Int32(off + t0)
                nt += 1
                t0 += T
            off += (m + T - 1) // T * T
        ntiles[0] = Int32(nt)
    barrier()
    if lane < Int(e):
        var p = Int(offs[lane])
        for i in range(n):
            if Int(ids[i]) == lane:
                slot[i] = Int32(p)
                src[p] = Int32(i // K)
                p += 1


def p_gather(x: F32, src: I32, xg: F32, ntiles: I32, d: Int32, tm: Int32):
    """Grouped row r (workgroup) = x[src[r]], or zeros on a padding row; rows past the work tiles are left alone."""
    var r = Int(block_idx.x)
    if r >= Int(ntiles[0]) * Int(tm):
        return
    var t = Int(thread_idx.x)
    var n = Int(d)
    var s = Int(src[r])
    for c in range(t * 4, n, 256):
        var v = SIMD[DType.float32, 4](0)
        if s >= 0:
            v = x.load[width=4](s * n + c)
        xg.store(r * n + c, v)


def p_silu_mul(gu: F32, a: F32, ntiles: I32, fe: Int32, tm: Int32):
    """a[r, j] = silu(gu[r, j]) * gu[r, fe + j] for the grouped rows of the work tiles (rows of 2 fe)."""
    var i = global_idx.x
    var f = Int(fe)
    if i < Int(ntiles[0]) * Int(tm) * f:
        var r = i // f
        var j = i % f
        a[i] = lk.silu(gu[r * 2 * f + j]) * gu[r * 2 * f + f + j]


def p_combine(yd: F32, slot: I32, wts: F32, y: F32, rows: Int32, d: Int32):
    """y[t, c] = sum_k wts[t, k] * yd[slot[t, k], c]: each token's K expert outputs, weighted."""
    var i = global_idx.x
    var n = Int(d)
    if i < Int(rows) * n:
        var t = i // n
        var c = i % n
        var acc = Float32(0)
        comptime for k in range(K):
            acc += wts[t * K + k] * yd[Int(slot[t * K + k]) * n + c]
        y[i] = acc


comptime BN = 128
comptime BK = 16
comptime KC = 8  # the fp32 cooperative product: 64 x 64 x 8
comptime GT = 128  # threads: 2 subgroups, each a 64 x 64 tile of the work tile's 64 x 128


def p_gemm_q4g(wq: U32, ws: F16, xg: F32, y: F32, n: Int64, k: Int64, tiles: I32, ntiles: I32):
    """Grouped int4 products on the matrix units: work tile block y (expert e, grouped rows r0 .. r0 + 63) times
    expert e's matrix (its rows e * n ..): y[r0 + i, c] = xg[r0 + i] . W_e[c] for the 128 columns c of block x.
    lk.gemm_q4 with a 64-row tile: per k step of 16, X's 64 x 16 and W's 128 x 16 (unpacked to fp32) in shared
    memory; each subgroup multiplies its 64 x 64 on fp32 cooperative matrices. n: a multiple of 128; k: of 16."""
    var it = Int(block_idx.y)
    if it >= Int(ntiles[0]):
        return
    var e = Int(tiles[2 * it])
    var row0 = Int(tiles[2 * it + 1])
    var sa = stack_allocation[TM * BK, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[BN * BK, Float32, address_space=AddressSpace.SHARED]()
    var ldy = Int(n)
    var ldx = Int(k)
    var t = Int(thread_idx.x)
    var sc = (t // 64) * 64
    var col0 = Int(block_idx.x) * BN
    var wrow0 = e * ldy + col0  # expert e's first row of this block
    var out = y.unsafe_offset(row0 * ldy + col0 + sc)
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for k0 in range(0, ldx, BK):
        comptime for i in range(TM * BK // 4 // GT):
            var v = i * GT + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            sa.unsafe_store(r * BK + c, xg.unsafe_load[width=4]((row0 + r) * ldx + k0 + c))
        comptime for i in range(BN * BK // 8 // GT):
            var v = i * GT + t
            var wr = v // (BK // 8)
            var wc = v % (BK // 8) * 8
            var word = wq[(wrow0 + wr) * (ldx // 8) + (k0 + wc) // 8]
            var scale = ws[(wrow0 + wr) * (ldx // lk.G) + (k0 + wc) // lk.G].cast[DType.float32]()
            comptime for j in range(8):
                var q = Int32((word >> UInt32(4 * j)) & 15) ^ 8
                sb.unsafe_store(wr * BK + wc + j, Float32(q - 8) * scale)
        barrier()
        comptime for kk in range(0, BK, KC):
            var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sa.unsafe_offset(kk), BK)
            var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(sc * BK + kk), BK)
            acc = at.multiply_add(bt, acc)
        barrier()
    acc.store(out, ldy)


# ---- prefill without cooperative matrices (the X1-85 has none) ------------------------------------------------------
# lk.gemm_h's tiling with int4 weights: a 256-thread workgroup computes a 64 x 64 block of Y, 4 x 4 outputs a thread
# (rows ty + 16 i, columns tx + 16 j); per k step of 16 it stages X's 64 x 16 slice and W's 64 x 16 slice (unpacked to
# fp32 with its scale) in shared memory.


@always_inline
def _tile_s(wq: U32, ws: F16, x: F32, y: F32, xrow0: Int, wrow0: Int, yrow0: Int, col0: Int, ldy: Int, ldx: Int):
    var sa = stack_allocation[64 * 17, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[64 * 17, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var tx = t % 16
    var ty = t // 16
    var acc = SIMD[DType.float32, 16](0)
    var lr = t // 4  # X: row lr, columns lc .. lc + 3
    var lc = (t % 4) * 4
    var wr = (t % 128) // 2  # W: row wr, columns wc .. wc + 7 (threads < 128)
    var wc = (t % 2) * 8
    for k0 in range(0, ldx, 16):
        var xv = x.load[width=4]((xrow0 + lr) * ldx + k0 + lc)
        comptime for e in range(4):
            sa[lr * 17 + lc + e] = xv[e]
        if t < 128:
            var word = wq[(wrow0 + wr) * (ldx // 8) + (k0 + wc) // 8]
            var scale = ws[(wrow0 + wr) * (ldx // lk.G) + (k0 + wc) // lk.G].cast[DType.float32]()
            comptime for j in range(8):
                var q = Int32((word >> UInt32(4 * j)) & 15) ^ 8
                sb[wr * 17 + wc + j] = Float32(q - 8) * scale
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
    comptime for i in range(4):
        comptime for j in range(4):
            y[(yrow0 + ty + 16 * i) * ldy + col0 + tx + 16 * j] = acc[i * 4 + j]


def gemm_q4s(wq: U32, ws: F16, x: F32, y: F32, n: Int32, k: Int32):
    """Y[rows, n] = X[rows, k] W^T, int4 W, scalar: workgroup (block x: 64 columns, block y: 64 rows).
    rows, n: multiples of 64; k: of 16."""
    var row0 = Int(block_idx.y) * 64
    var col0 = Int(block_idx.x) * 64
    _tile_s(wq, ws, x, y, row0, col0, row0, col0, Int(n), Int(k))


def p_gemm_q4gs(wq: U32, ws: F16, xg: F32, y: F32, n: Int32, k: Int32, tiles: I32, ntiles: I32):
    """p_gemm_q4g without cooperative matrices: work tile block y (expert e, grouped rows r0 .. r0 + 63) times expert
    e's matrix, 64 of its columns (block x)."""
    var it = Int(block_idx.y)
    if it >= Int(ntiles[0]):
        return
    var e = Int(tiles[2 * it])
    var row0 = Int(tiles[2 * it + 1])
    var col0 = Int(block_idx.x) * 64
    _tile_s(wq, ws, xg, y, row0, e * Int(n) + col0, row0, col0, Int(n), Int(k))


# ---- decode, R rows a workgroup -------------------------------------------------------------------------------------
# lk.dot_q4b reads x's 32 values (128 bytes) for every block of 32 int4 weights (18 bytes): a row a workgroup is bound
# by those cache reads on the X1-85. Here a lane loads its block of x once and uses it for R rows.


@always_inline
def xblock(x: F32, b: Int) -> SIMD[DType.float32, 32]:
    var v = SIMD[DType.float32, 32]()
    comptime for k in range(4):
        var p = x.load[width=8](b * 32 + k * 8)
        comptime for j in range(8):
            v[k * 8 + j] = p[j]
    return v


@always_inline
def qdot(w4: SIMD[DType.uint32, 4], xv: SIMD[DType.float32, 32]) -> Float32:
    var part = Float32(0)
    comptime for k in range(4):
        comptime for j in range(8):
            var q = Int32((w4[k] >> UInt32(4 * j)) & 15) ^ 8
            part += Float32(q - 8) * xv[k * 8 + j]
    return part


@always_inline
def dots_q4[R: Int](wq: U32, ws: F16, row0: Int, cols: Int, x: F32, t: Int) -> SIMD[DType.float32, R]:
    """Lane t's shares of W[row0 + r] . x for r < R: blocks t, t + 64, ... (one x load a block for the R rows)."""
    var blocks = cols // 32
    var words = cols // 8
    var acc = SIMD[DType.float32, R](0)
    for i in range((blocks + 63) // 64):
        var b = i * 64 + t
        if b < blocks:
            var xv = xblock(x, b)
            comptime for r in range(R):
                var w4 = (wq + (row0 + r) * words).load[width=4](b * 4)
                acc[r] += qdot(w4, xv) * ws[(row0 + r) * blocks + b].cast[DType.float32]()
    return acc


def gemv_q4r[R: Int](wq: U32, ws: F16, x: F32, y: F32, cols: Int32):
    """y[r] = W[r] . x, int4 W: R rows a workgroup (rows: a multiple of R)."""
    var r0 = Int(block_idx.x) * R
    var t = Int(thread_idx.x)
    var acc = dots_q4[R](wq, ws, r0, Int(cols), x, t)
    comptime for r in range(R):
        var s = warp_sum(acc[r])
        if t == 0:
            y[r0 + r] = s


def gate_up_q4r[R: Int](wq: U32, ws: F16, x: F32, a: F32, cols: Int32, f: Int32, ids: I32, k: Int32):
    """a[kk, j] = silu(gate[j] . x) * (up[j] . x) for j = R * block x .. + R - 1, gate and up rows j and f + j of the
    fused matrix; with k > 0 the matrix is expert ids[kk]'s (rows ids[kk] * 2 f ..; kk = block y), else the dense one."""
    var j0 = Int(block_idx.x) * R
    var kk = Int(block_idx.y)
    var t = Int(thread_idx.x)
    var n = Int(f)
    var base = Int(ids[kk]) * 2 * n if Int(k) > 0 else 0
    var g = dots_q4[R](wq, ws, base + j0, Int(cols), x, t)
    var u = dots_q4[R](wq, ws, base + n + j0, Int(cols), x, t)
    comptime for r in range(R):
        var gs = warp_sum(g[r])
        var us = warp_sum(u[r])
        if t == 0:
            a[kk * n + j0 + r] = lk.silu(gs) * us


def moe_down_r[R: Int](wq: U32, ws: F16, ids: I32, wts: F32, a: F32, y: F32, fe: Int32, d: Int32):
    """y[r] = sum_k wts[k] * down_e[r] . a[k] over the K chosen experts, r = R * block x .. + R - 1."""
    var r0 = Int(block_idx.x) * R
    var t = Int(thread_idx.x)
    var f = Int(fe)
    var acc = SIMD[DType.float32, R](0)
    comptime for k in range(K):
        acc += wts[k] * dots_q4[R](wq, ws, Int(ids[k]) * Int(d) + r0, f, a + k * f, t)
    comptime for r in range(R):
        var s = warp_sum(acc[r])
        if t == 0:
            y[r0 + r] = s


@always_inline
def q6_dot(wq: U32, wd: F16, row: Int, cols: Int, c: Int, xv: SIMD[DType.float32, 32]) -> Float32:
    """lk.q6_chunk's dot product of chunk c (32 weights) of a Q6_K row with x's chunk, already in registers."""
    var nb = cols // 256
    var b = c // 8
    var k = c % 8
    var h = k // 4
    var g = k % 4
    var base = (row * nb + b) * 52  # words: ql 0..31, qh 32..47, scales 48..51
    var qlb = base + (64 * h + 32 * (g & 1)) // 4
    var qhb = base + 32 + 8 * h
    var si = 8 * h + 2 * g
    var scw = wq[base + 48 + si // 4]
    var s0 = Int32((scw >> UInt32(8 * (si % 4))) & 255) ^ 128
    var s1 = Int32((scw >> UInt32(8 * (si % 4) + 8)) & 255) ^ 128
    var d = wd[row * nb + b].cast[DType.float32]()
    var lo_shift = UInt32(4 * (g >> 1))
    var hi_shift = UInt32(2 * g)
    var acc0 = Float32(0)
    var acc1 = Float32(0)
    comptime for w in range(8):
        var qlw = wq[qlb + w]
        var qhw = wq[qhb + w]
        comptime for kk in range(4):
            var q = Int32(((qlw >> (UInt32(8 * kk) + lo_shift)) & 15) | (((qhw >> (UInt32(8 * kk) + hi_shift)) & 3) << 4))
            comptime if w < 4:
                acc0 += Float32(q - 32) * xv[4 * w + kk]
            else:
                acc1 += Float32(q - 32) * xv[4 * w + kk]
    return d * Float32(s0 - 128) * acc0 + d * Float32(s1 - 128) * acc1


def head_q6r[R: Int](wq: U32, wd: F16, x: F32, y: F32, cols: Int32):
    """lk.head_q6 with R rows a workgroup: each lane's 32 values of x loaded once for the R rows."""
    var r0 = Int(block_idx.x) * R
    var t = Int(thread_idx.x)
    var n = Int(cols)
    var chunks = n // 32
    var acc = SIMD[DType.float32, R](0)
    for i in range((chunks + 63) // 64):
        var c = i * 64 + t
        if c < chunks:
            var xv = xblock(x, c)
            comptime for r in range(R):
                acc[r] += q6_dot(wq, wd, r0 + r, n, c, xv)
    comptime for r in range(R):
        var s = warp_sum(acc[r])
        if t == 0:
            y[r0 + r] = s


def moe_down_f[R: Int](wq: U32, ws: F16, ids: I32, wts: F32, a: F32, y: F32, fe: Int32, d: Int32):
    """moe_down_r with the lanes over the K experts' blocks together (K * fe / 32 of them: 192 = 3 x 64 for fe 1536),
    so no lane idles when an expert's row has fewer than 64 blocks; R output rows a workgroup."""
    var r0 = Int(block_idx.x) * R
    var t = Int(thread_idx.x)
    var f = Int(fe)
    var blocks = f // 32
    var words = f // 8
    var total = K * blocks
    var acc = SIMD[DType.float32, R](0)
    for i in range((total + 63) // 64):
        var p = i * 64 + t
        if p < total:
            var k = p // blocks
            var b = p % blocks
            var xv = xblock(a + k * f, b)
            var row0 = Int(ids[k]) * Int(d) + r0
            var wk = wts[k]
            comptime for r in range(R):
                var w4 = (wq + (row0 + r) * words).load[width=4](b * 4)
                acc[r] += wk * qdot(w4, xv) * ws[(row0 + r) * blocks + b].cast[DType.float32]()
    comptime for r in range(R):
        var s = warp_sum(acc[r])
        if t == 0:
            y[r0 + r] = s


# ---- prefill without cooperative matrices, v2 -----------------------------------------------------------------------
# A 256-thread workgroup computes a TR x 64 block of Y (TR = 64, 32 or 16 rows), TR / 16 x 4 outputs a thread (rows
# ty * TR / 16 .., columns tx * 4 ..). Per k step of 32 (one Q4_0 block of each W row) it stages X's TR x 32 slice and
# W's 64 x 32 slice (unpacked to fp32 with its scale) in shared memory k-major, so each thread reads its rows and its 4
# columns as one vector each. Staging writes run along rows (consecutive threads, consecutive rows): no bank conflicts.


@always_inline
def _tile_v[TR: Int](wq: U32, ws: F16, x: F32, y: F32, xrow0: Int, wrow0: Int, yrow0: Int, col0: Int, ldy: Int,
                     ldx: Int):
    comptime SA = TR + 4  # k-major strides (16-byte aligned rows)
    comptime SB = 64 + 4
    comptime RT = TR // 16  # rows a thread
    var sa = stack_allocation[32 * SA, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[32 * SB, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var tx = t % 16
    var ty = t // 16
    var acc = SIMD[DType.float32, RT * 4](0)
    var wr = t % 64  # W staging: row wr, word wj of the block
    var wj = t // 64
    for k0 in range(0, ldx, 32):
        comptime for i in range((TR * 8 + 255) // 256):  # X: TR rows x 8 vectors of 4
            var v = i * 256 + t
            if v < TR * 8:
                var r = v % TR
                var c = (v // TR) * 4
                var xv = x.load[width=4]((xrow0 + r) * ldx + k0 + c)
                comptime for e in range(4):
                    sa[(c + e) * SA + r] = xv[e]
        var word = wq[(wrow0 + wr) * (ldx // 8) + k0 // 8 + wj]
        var scale = ws[(wrow0 + wr) * (ldx // lk.G) + k0 // lk.G].cast[DType.float32]()
        comptime for j in range(8):
            var q = Int32((word >> UInt32(4 * j)) & 15) ^ 8
            sb[(wj * 8 + j) * SB + wr] = Float32(q - 8) * scale
        barrier()
        comptime for kk in range(32):
            var b = sb.load[width=4](kk * SB + tx * 4)
            comptime if RT == 4:
                var a = sa.load[width=4](kk * SA + ty * 4)
                comptime for i in range(4):
                    comptime for j in range(4):
                        acc[i * 4 + j] += a[i] * b[j]
            elif RT == 2:
                var a = sa.load[width=2](kk * SA + ty * 2)
                comptime for i in range(2):
                    comptime for j in range(4):
                        acc[i * 4 + j] += a[i] * b[j]
            else:
                var a = sa[kk * SA + ty]
                comptime for j in range(4):
                    acc[j] += a * b[j]
        barrier()
    comptime for i in range(RT):
        var o = SIMD[DType.float32, 4]()
        comptime for j in range(4):
            o[j] = acc[i * 4 + j]
        y.store((yrow0 + ty * RT + i) * ldy + col0 + tx * 4, o)


def gemm_q4v(wq: U32, ws: F16, x: F32, y: F32, n: Int32, k: Int32):
    """Y[rows, n] = X[rows, k] W^T, int4 W, scalar v2: workgroup (block x: 64 columns, block y: 64 rows).
    rows, n: multiples of 64; k: of 32."""
    var row0 = Int(block_idx.y) * 64
    var col0 = Int(block_idx.x) * 64
    _tile_v[64](wq, ws, x, y, row0, col0, row0, col0, Int(n), Int(k))


def p_gemm_q4gv[TR: Int](wq: U32, ws: F16, xg: F32, y: F32, n: Int32, k: Int32, tiles: I32, ntiles: I32):
    """The grouped products, scalar v2, work tiles of TR rows: tile block y (expert e, grouped rows r0 ..) times expert
    e's matrix, 64 of its columns (block x)."""
    var it = Int(block_idx.y)
    if it >= Int(ntiles[0]):
        return
    var e = Int(tiles[2 * it])
    var row0 = Int(tiles[2 * it + 1])
    var col0 = Int(block_idx.x) * 64
    _tile_v[TR](wq, ws, xg, y, row0, e * Int(n) + col0, row0, col0, Int(n), Int(k))


@always_inline
def _tile_w(wq: U32, ws: F16, x: F32, y: F32, row0: Int, wrow0: Int, col0: Int, ldy: Int, ldx: Int):
    """One-subgroup tile: Y[row0 .. + 15, col0 .. + 63] = X[row0 .. + 15] . W[wrow0 .. + 63]; 64 threads, 4 x 4
    outputs each (rows ty * 4 .., columns tx * 4 ..). Per k step of 32 each lane stages one W row's block (one 16-byte
    load, unpacked) and 8 values of X, k-major in shared memory."""
    comptime SA = 16 + 4
    comptime SB = 64 + 4
    var t = Int(thread_idx.x)
    var wrow = wrow0 + t  # this lane's W row to stage
    var sa = stack_allocation[32 * SA, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[32 * SB, Float32, address_space=AddressSpace.SHARED]()
    var tx = t % 16
    var ty = t // 16
    var acc = SIMD[DType.float32, 16](0)
    var words = ldx // 8
    var blocks = ldx // lk.G
    for k0 in range(0, ldx, 32):
        comptime for i in range(2):  # X: 16 rows x 8 vectors of 4
            var v = i * 64 + t
            var r = v % 16
            var c = (v // 16) * 4
            var xv = x.load[width=4]((row0 + r) * ldx + k0 + c)
            comptime for q in range(4):
                sa[(c + q) * SA + r] = xv[q]
        var w4 = (wq + wrow * words).load[width=4](k0 // 8)
        var scale = ws[wrow * blocks + k0 // lk.G].cast[DType.float32]()
        comptime for kw in range(4):
            comptime for j in range(8):
                var q = Int32((w4[kw] >> UInt32(4 * j)) & 15) ^ 8
                sb[(kw * 8 + j) * SB + t] = Float32(q - 8) * scale
        barrier()
        comptime for kk in range(32):
            var a = sa.load[width=4](kk * SA + ty * 4)
            var b = sb.load[width=4](kk * SB + tx * 4)
            comptime for i in range(4):
                comptime for j in range(4):
                    acc[i * 4 + j] += a[i] * b[j]
        barrier()
    comptime for i in range(4):
        var o = SIMD[DType.float32, 4]()
        comptime for j in range(4):
            o[j] = acc[i * 4 + j]
        y.store((row0 + ty * 4 + i) * ldy + col0 + tx * 4, o)


def p_gemm_q4gw(wq: U32, ws: F16, xg: F32, y: F32, n: Int32, k: Int32, tiles: I32, ntiles: I32):
    """The grouped products with one-subgroup workgroups (_tile_w): work tile block y (expert e, 16 grouped rows
    r0 ..) times 64 columns (block x) of expert e's matrix."""
    var it = Int(block_idx.y)
    if it >= Int(ntiles[0]):
        return
    var e = Int(tiles[2 * it])
    var row0 = Int(tiles[2 * it + 1])
    var col0 = Int(block_idx.x) * 64
    _tile_w(wq, ws, xg, y, row0, e * Int(n) + col0, col0, Int(n), Int(k))


def gemm_q4w(wq: U32, ws: F16, x: F32, y: F32, n: Int32, k: Int32):
    """Y[rows, n] = X[rows, k] W^T with one-subgroup workgroups (_tile_w): block x 64 columns, block y 16 rows."""
    var col0 = Int(block_idx.x) * 64
    _tile_w(wq, ws, x, y, Int(block_idx.y) * 16, col0, col0, Int(n), Int(k))
