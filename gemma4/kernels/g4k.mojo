# Gemma 4 (E2B, E4B) decode kernels: one token through a layer, for any of the two models' sizes (runtime arguments).
# A layer: RMS norms that carry their own scale (not Gemma 3's 1 + w), q/k norms over each head and a scale-free v
# norm, RoPE from a table (cos | sin of the head's first half), attention with scale 1 over a sliding window of 512
# or all positions, norms after attention and the MLP before each residual add, a GELU-tanh MLP, and the per-layer
# input: a 256-wide gate from the residual stream times this layer's slice of the per-layer embedding, projected back,
# normed and added; then the layer scalar. The int4 storage is llama/kernels' gemv_q4's: an fp16 scale per 64
# weights of a row, 8 weights a uint32 as 4-bit two's complement, low nibble first.
#
# Every workgroup is one 64-lane subgroup unless noted. As in qwen3moe/kernels/moek.mojo: loops before a subgroup sum
# run the same number of iterations in every lane (guards inside), and reductions after divergent work use shared
# memory and barriers.
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

comptime G = 64  # weights per int4 scale
comptime EPS = Float32(1e-6)
comptime PL = 256  # the per-layer input's width


@always_inline
def dot_q4_row(wq: U32, ws: F16, row: Int, cols: Int, x: F32, t: Int) -> Float32:
    """Lane t's share of W[row] . x for an int4 row of `cols` weights, 64 lanes taking words t, t + 64, ... Every lane
    runs the same number of iterations (a 256-wide row is 32 words: half the lanes skip the body)."""
    var words = cols // 8
    var acc = Float32(0)
    for i in range((words + 63) // 64):
        var wi = i * 64 + t
        if wi < words:
            var word = wq[row * words + wi]
            var part = Float32(0)
            comptime for j in range(8):
                var q = Int32((word >> UInt32(4 * j)) & 15) ^ 8
                part += Float32(q - 8) * x[wi * 8 + j]
            acc += part * ws[row * (cols // G) + wi // (G // 8)].cast[DType.float32]()
    return acc


@always_inline
def gelu_tanh(x: Float32) -> Float32:
    """GELU, tanh form (gelu_pytorch_tanh): 0.5 x (1 + tanh(u)) = x / (1 + exp(-2u)), u = sqrt(2/pi) (x + 0.044715 x^3)."""
    var u = Float32(0.7978845608028654) * (x + Float32(0.044715) * x * x * x)
    return x / (1 + exp(-2 * u))


@always_inline
def softcap(x: Float32, cap: Float32) -> Float32:
    """cap * tanh(x / cap), tanh(z) = 1 - 2 / (exp(2z) + 1)."""
    return cap * (1 - 2 / (exp(2 * x / cap) + 1))


def gemv_q4(wq: U32, ws: F16, x: F32, y: F32, cols: Int32):
    """y[r] = W[r] . x, int4 W: a workgroup a row."""
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var s = warp_sum(dot_q4_row(wq, ws, r, Int(cols), x, t))
    if t == 0:
        y[r] = s


def head_q4(wq: U32, ws: F16, x: F32, y: F32, cols: Int32, cap: Float32):
    """The output head with Gemma's final soft-cap: y[r] = cap tanh(W[r] . x / cap)."""
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var s = warp_sum(dot_q4_row(wq, ws, r, Int(cols), x, t))
    if t == 0:
        y[r] = softcap(s, cap)


def gate_up_gelu(wq: U32, ws: F16, x: F32, a: F32, cols: Int32, f: Int32):
    """a[j] = gelu_tanh(gate[j] . x) * (up[j] . x): gate row j and up row f + j of the fused matrix, workgroup j."""
    var j = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var g = warp_sum(dot_q4_row(wq, ws, j, Int(cols), x, t))
    var u = warp_sum(dot_q4_row(wq, ws, Int(f) + j, Int(cols), x, t))
    if t == 0:
        a[j] = gelu_tanh(g) * u


def ple_gate(wq: U32, ws: F16, x: F32, ple: F32, off: Int32, a: F32, cols: Int32):
    """a[r] = gelu_tanh(per_layer_input_gate[r] . x) * ple[off + r], r < 256: this layer's per-layer input gate."""
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var s = warp_sum(dot_q4_row(wq, ws, r, Int(cols), x, t))
    if t == 0:
        a[r] = gelu_tanh(s) * ple[Int(off) + r]


def ple_prep(proj: F32, raw: F32, w: F32, ple: F32, dscale: Float32):
    """The per-layer inputs of a token: for layer l (workgroup l), v = proj[l] * D^-0.5 (per_layer_model_projection's
    output, scaled), then (rmsnorm(v) * w + raw[l] * 16) / sqrt(2), raw being the token's per-layer embedding row."""
    var l = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var v = SIMD[DType.float32, 4]()
    comptime for k in range(4):
        v[k] = proj[l * PL + t + 64 * k] * dscale
    var r = rsqrt(warp_sum((v * v).reduce_add()) / Float32(PL) + EPS)
    comptime for k in range(4):
        var i = l * PL + t + 64 * k
        ple[i] = (v[k] * r * w[t + 64 * k] + raw[i] * Float32(16)) * Float32(0.7071067811865476)


def rmsnorm(x: F32, w: F32, y: F32, n: Int32):
    """y = x / rms(x) * w (eps 1e-6), n a multiple of 64: one workgroup."""
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = x[j]
        ss += v * v
    var r = rsqrt(warp_sum(ss) / Float32(Int(n)) + EPS)
    for j in range(lane, Int(n), 64):
        y[j] = x[j] * r * w[j]


def start(xin: F32, x: F32, w: F32, xn: F32, n: Int32):
    """A step's first kernel: the residual stream x = the token's scaled embedding, and xn = rmsnorm(x) * w."""
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = xin[j]
        x[j] = v
        ss += v * v
    var r = rsqrt(warp_sum(ss) / Float32(Int(n)) + EPS)
    for j in range(lane, Int(n), 64):
        xn[j] = xin[j] * r * w[j]


def norm_add(x: F32, y: F32, w: F32, scale: F32, wn: F32, xn: F32, n: Int32, flags: Int32):
    """x = (x + rmsnorm(y) * w) [* scale[0] if flags & 1]; then [if flags & 2] xn = rmsnorm(x) * wn. One workgroup: a
    sub-layer's output norm and residual add, the layer scalar, and the next norm."""
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = y[j]
        ss += v * v
    var r = rsqrt(warp_sum(ss) / Float32(Int(n)) + EPS)
    var sc = scale[0] if (flags & 1) != 0 else Float32(1)
    var ss2: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = (x[j] + y[j] * r * w[j]) * sc
        x[j] = v
        ss2 += v * v
    if (flags & 2) != 0:
        var r2 = rsqrt(warp_sum(ss2) / Float32(Int(n)) + EPS)
        for j in range(lane, Int(n), 64):
            xn[j] = x[j] * r2 * wn[j]


def qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, pos: Int32, heads: Int32, kvh: Int32,
                 hd: Int32):
    """A workgroup a head of the fused q|k|v row: query heads 0 .. heads-1 (RMS norm with wq, RoPE, in place), key heads
    (RMS norm with wk, RoPE, into K cache row `pos`), value heads (RMS norm without a scale, into the V cache). A cache
    row is kvh * hd floats. Lane d holds elements d + 64 k of the head's first half and their partners hd / 2 later;
    the table row of `pos` holds cos | sin of the first half."""
    var h = Int(block_idx.x)
    var d = Int(thread_idx.x)
    var p = Int(pos)
    var n = Int(hd)
    var half = n // 2
    var nh = Int(heads)
    var kv = Int(kvh)
    var row = Int(kvh) * n
    var base = h * n
    var ss: Float32 = 0
    for e in range(d, half, 64):
        var a = qkv[base + e]
        var b = qkv[base + e + half]
        ss += a * a + b * b
    var r = rsqrt(warp_sum(ss) / Float32(n) + EPS)
    if h >= nh + kv:
        var dst = vc + (p * row + (h - nh - kv) * n)
        for e in range(d, half, 64):
            dst[e] = qkv[base + e] * r
            dst[e + half] = qkv[base + e + half] * r
        return
    var w = wq if h < nh else wk
    var dst = (qkv + base) if h < nh else (kc + (p * row + (h - nh) * n))
    for e in range(d, half, 64):
        var a = qkv[base + e] * r * w[e]
        var b = qkv[base + e + half] * r * w[e + half]
        var c = table[p * n + e]
        var s = table[p * n + half + e]
        dst[e] = a * c - b * s
        dst[e + half] = b * c + a * s


def attn_scores[NQ: Int](q: F32, kc: F32, y: F32, pos: Int32, first: Int32, kvh: Int32, hd: Int32, capacity: Int32):
    """q . k (scale 1) for cached positions first .. pos: a thread per KV head g and position t computes the NQ query
    heads g NQ .. g NQ + NQ - 1 that share it, so each cached K row is read once. Head h's scores at y[h capacity + t]."""
    var i = global_idx.x
    var length = Int(pos) - Int(first) + 1
    var n = Int(hd)
    if i < Int(kvh) * length:
        var g = i // length
        var t = Int(first) + i % length
        var k = kc + (t * Int(kvh) * n + g * n)
        var qg = q + g * NQ * n
        var acc = SIMD[DType.float32, NQ](0)
        for d in range(0, n, 4):
            var kv = k.load[width=4](d)
            comptime for j in range(NQ):
                acc[j] += (qg.load[width=4](j * n + d) * kv).reduce_add()
        comptime for j in range(NQ):
            y[(NQ * g + j) * Int(capacity) + t] = acc[j]


def attn_values(scores: F32, vc: F32, y: F32, pos: Int32, first: Int32, nq: Int32, kvh: Int32, hd: Int32,
                capacity: Int32):
    """softmax(scores[first .. pos]) V for 64 of a query head's dimensions a workgroup (hd / 64 a head; query head h
    reads KV head h / nq)."""
    var sp = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var n = Int(hd)
    var chunks = n // 64
    var h = Int(block_idx.x) // chunks
    var d = (Int(block_idx.x) % chunks) * 64 + lane
    var f = Int(first)
    var cnt = Int(pos) - f + 1
    var s = scores + (h * Int(capacity) + f)
    var highest: Float32 = -3.402823e38
    for t0 in range(0, cnt, 64):
        if t0 + lane < cnt:
            highest = max(highest, s[t0 + lane])
    sp[lane] = highest
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] = max(sp[lane], sp[lane + (32 >> stage)])
        barrier()
    highest = sp[0]
    barrier()
    var row = Int(kvh) * n
    var v = vc + (f * row + (h // Int(nq)) * n + d)
    var total: Float32 = 0
    var value: Float32 = 0
    for t0 in range(0, cnt, 64):
        sp[lane] = exp(s[t0 + lane] - highest) if t0 + lane < cnt else 0
        barrier()
        for k in range(min(64, cnt - t0)):
            var p = sp[k]
            total += p
            value += p * v[(t0 + k) * row]
        barrier()
    y[h * n + d] = value / total


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


# ---- prefill: up to PMAX prompt rows at once, row t at position p0 + t --------------------------------------------
# The projections are llama/kernels/prefill's p_gemm_q4 (cooperative matrices, fp32, rows padded to 128); these are the
# row kernels around them.


def p_ple_prep(proj: F32, raw: F32, w: F32, ple: F32, dscale: Float32, layers: Int32):
    """ple_prep for layer l (block x) of row t (block y)."""
    var l = Int(block_idx.x)
    var off = Int(block_idx.y) * Int(layers) * PL
    var t = Int(thread_idx.x)
    var v = SIMD[DType.float32, 4]()
    comptime for k in range(4):
        v[k] = proj[off + l * PL + t + 64 * k] * dscale
    var r = rsqrt(warp_sum((v * v).reduce_add()) / Float32(PL) + EPS)
    comptime for k in range(4):
        var i = off + l * PL + t + 64 * k
        ple[i] = (v[k] * r * w[t + 64 * k] + raw[i] * Float32(16)) * Float32(0.7071067811865476)


def p_start(xin: F32, x: F32, w: F32, xn: F32, n: Int32):
    """start for row t (workgroup t)."""
    var o = Int(block_idx.x) * Int(n)
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = xin[o + j]
        x[o + j] = v
        ss += v * v
    var r = rsqrt(warp_sum(ss) / Float32(Int(n)) + EPS)
    for j in range(lane, Int(n), 64):
        xn[o + j] = xin[o + j] * r * w[j]


def p_norm_add(x: F32, y: F32, w: F32, scale: F32, wn: F32, xn: F32, n: Int32, flags: Int32):
    """norm_add for row t (workgroup t)."""
    var o = Int(block_idx.x) * Int(n)
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = y[o + j]
        ss += v * v
    var r = rsqrt(warp_sum(ss) / Float32(Int(n)) + EPS)
    var sc = scale[0] if (flags & 1) != 0 else Float32(1)
    var ss2: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = (x[o + j] + y[o + j] * r * w[j]) * sc
        x[o + j] = v
        ss2 += v * v
    if (flags & 2) != 0:
        var r2 = rsqrt(warp_sum(ss2) / Float32(Int(n)) + EPS)
        for j in range(lane, Int(n), 64):
            xn[o + j] = x[o + j] * r2 * wn[j]


def p_qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, p0: Int32, heads: Int32, kvh: Int32,
                   hd: Int32, stride: Int32):
    """qk_norm_rope for head h (block x) of row t (block y) at position p0 + t; rows of `stride` floats."""
    var h = Int(block_idx.x)
    var tr = Int(block_idx.y)
    var d = Int(thread_idx.x)
    var p = Int(p0) + tr
    var n = Int(hd)
    var half = n // 2
    var nh = Int(heads)
    var kv = Int(kvh)
    var row = kv * n
    var base = tr * Int(stride) + h * n
    var ss: Float32 = 0
    for e in range(d, half, 64):
        var a = qkv[base + e]
        var b = qkv[base + e + half]
        ss += a * a + b * b
    var r = rsqrt(warp_sum(ss) / Float32(n) + EPS)
    if h >= nh + kv:
        var dst = vc + (p * row + (h - nh - kv) * n)
        for e in range(d, half, 64):
            dst[e] = qkv[base + e] * r
            dst[e + half] = qkv[base + e + half] * r
        return
    var w = wq if h < nh else wk
    var dst = (qkv + base) if h < nh else (kc + (p * row + (h - nh) * n))
    for e in range(d, half, 64):
        var a = qkv[base + e] * r * w[e]
        var b = qkv[base + e + half] * r * w[e + half]
        var c = table[p * n + e]
        var s = table[p * n + half + e]
        dst[e] = a * c - b * s
        dst[e + half] = b * c + a * s


def p_gelu_mul(gu: F32, a: F32, f: Int32, count: Int32):
    """a[t, j] = gelu_tanh(gu[t, j]) * gu[t, f + j] for rows t < count: the fused gate|up product's rows of 2 f."""
    var i = global_idx.x
    var n = Int(f)
    if i < Int(count) * n:
        var t = i // n
        var j = i % n
        a[t * n + j] = gelu_tanh(gu[t * 2 * n + j]) * gu[t * 2 * n + n + j]


def p_ple_gate_mul(g: F32, ple: F32, off: Int32, a: F32, count: Int32, layers: Int32):
    """a[t, r] = gelu_tanh(g[t, r]) * ple[t, off + r], r < 256: the per-layer input gate of rows t < count."""
    var i = global_idx.x
    if i < Int(count) * PL:
        var t = i // PL
        var r = i % PL
        a[i] = gelu_tanh(g[i]) * ple[t * Int(layers) * PL + Int(off) + r]


# Prefill attention on the matrix units (qwen3/kernels/qwen3p.mojo's p_scores_mma, p_softmax and p_values_mma, for
# Gemma's heads of 256 and 512, grouped KV heads, the sliding window and batches that start at p0). For the 64 rows
# of a block, the keys run from the 64-aligned start of the block's first row's window to the end of its last row's
# 64: scores[row, h, key] for those keys (rows of `capacity` keys), then probabilities with zeros outside each row's
# own keys, then P V. Rows past `count` and keys past the prompt get probability 0; the V cache starts zeroed, so
# they add 0, never NaN.


@always_inline
def _key_lo(pa: Int, window: Int) -> Int:
    """The first key a 64-row block starting at position pa reads: its first row's window start, 64-aligned."""
    return (max(0, pa - window + 1) // 64) * 64 if window > 0 else 0


def p_scores_mma[HD: Int](qkv: F32, kc: F32, y: F32, p0: Int32, window: Int32, nq: Int32, kvh: Int32, stride: Int32,
                          heads: Int32, capacity: Int32):
    """S = Q K^T (scale 1) for head block_idx.y and the 64 rows from 64 block_idx.x, 64 keys a tile: Q from the
    q|k|v rows (`stride` floats apart), K read column-major from the cache (rows of kvh HD)."""
    var h = Int(block_idx.y)
    var i0 = Int(block_idx.x) * 64
    var pa = Int(p0) + i0
    var ld = Int(heads) * Int(capacity)
    var row = Int(kvh) * HD
    var g = h // Int(nq)
    var st = Int(stride)
    for j0 in range(_key_lo(pa, Int(window)), pa + 64, 64):
        var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
        for k in range(0, HD, 8):  # the 840's fp32 product: 64 x 64 x 8
            var at = CoopMatrix[DType.float32, 64, 8, MATRIX_A].load(qkv.unsafe_offset(i0 * st + h * HD + k), st)
            var bt = CoopMatrix[DType.float32, 8, 64, MATRIX_B].load[row_major=False](
                kc.unsafe_offset(j0 * row + g * HD + k), row)
            acc = at.multiply_add(bt, acc)
        acc.store(y.unsafe_offset(i0 * ld + h * Int(capacity) + j0), ld)


def p_softmax(scores: F32, p0: Int32, count: Int32, window: Int32, heads: Int32, capacity: Int32):
    """Head block_idx.x's scores of row block_idx.y, in place, to probabilities over keys first .. p (p = p0 + row),
    and zeros for the rest of the keys its block reads. Padding rows (row >= count) get zeros only."""
    var sp = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var r = Int(block_idx.y)
    var s = scores + (r * Int(heads) * Int(capacity) + Int(block_idx.x) * Int(capacity))
    var w = Int(window)
    var p = Int(p0) + r
    var pa = Int(p0) + (r // 64) * 64
    var lo = _key_lo(pa, w)
    var first = max(0, p - w + 1) if w > 0 else 0
    var last = p if r < Int(count) else first - 1  # no keys for a padding row
    var highest: Float32 = -3.402823e38
    for t0 in range(first, last + 1, 64):
        if t0 + lane <= last:
            highest = max(highest, s[t0 + lane])
    sp[lane] = highest
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] = max(sp[lane], sp[lane + (32 >> stage)])
        barrier()
    highest = sp[0]
    barrier()
    var total: Float32 = 0
    for t0 in range(first, last + 1, 64):  # each lane rereads only what it wrote
        if t0 + lane <= last:
            var e = exp(s[t0 + lane] - highest)
            s[t0 + lane] = e
            total += e
    sp[lane] = total
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] += sp[lane + (32 >> stage)]
        barrier()
    var inv = 1 / sp[0] if last >= first else Float32(0)
    for t0 in range(lo, pa + 64, 64):
        var t = t0 + lane
        s[t] = s[t] * inv if (t >= first and t <= last) else 0


def p_values_mma[HD: Int](pr: F32, vc: F32, y: F32, p0: Int32, window: Int32, nq: Int32, kvh: Int32, heads: Int32,
                          capacity: Int32):
    """Attention output for the 64 rows from 64 block_idx.x and columns 64 (block_idx.y % (HD / 64)) of head
    block_idx.y / (HD / 64): P V on the matrix units over the keys the block reads, V straight from the cache.
    Output rows of heads HD."""
    comptime C = HD // 64
    var h = Int(block_idx.y) // C
    var c = Int(block_idx.y) % C
    var i0 = Int(block_idx.x) * 64
    var pa = Int(p0) + i0
    var ld = Int(heads) * Int(capacity)
    var row = Int(kvh) * HD
    var g = h // Int(nq)
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for t0 in range(_key_lo(pa, Int(window)), pa + 64, 8):  # the 840's fp32 product: 64 x 64 x 8
        var a = CoopMatrix[DType.float32, 64, 8, MATRIX_A].load(pr.unsafe_offset(i0 * ld + h * Int(capacity) + t0), ld)
        var b = CoopMatrix[DType.float32, 8, 64, MATRIX_B].load(vc.unsafe_offset(t0 * row + g * HD + c * 64), row)
        acc = a.multiply_add(b, acc)
    var oy = Int(heads) * HD
    acc.store(y.unsafe_offset(i0 * oy + h * HD + c * 64), oy)
