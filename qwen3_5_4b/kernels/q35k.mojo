# Qwen3.5-4B kernels beyond what it reuses. The model runs on these existing kernel files too:
#   lfm2/kernels/lk.mojo         Q4_0 gemv / gate-up / matrix-unit gemm, the Q6_K embedding and tied head, SiLU product,
#                                argmax
#   qwen3_4b/kernels/q4bk.mojo   the residual add + RMS norm with eps 1e-6 (the GGUF stores Qwen3.5's 1 + w, so x / rms
#                                times the stored weight is transformers' zero-centred norm)
#   gemma4/kernels/g4k.mojo      prefill attention on the matrix units for heads of 256 and grouped KV heads
#                                (p_scores_mma, p_softmax, p_values_mma)
# Here:
#   - the affine storage of the GGUF's Q4_1 and Q5_K matrices (convert.c): products for decode and prefill
#   - an fp32 matrix-vector product (in_proj_a | in_proj_b, 64 rows)
#   - the linear attention (Gated DeltaNet): the causal conv over q|k|v with SiLU, q/k L2 norms, the decay and beta
#     (conv_qk), the conv state after a batch (conv_state), the delta rule over a head's 128 x 128 state, a token or a
#     batch of rows in turn (delta_rule), and the gated RMS norm (gated_norm)
#   - the full attention's q/k head norms + partial RoPE (the first 64 of 256 dimensions) + K/V cache rows, and decode
#     attention in chunks of positions (q4bk.attn_part / attn_combine for heads of 256, the output gate folded in)
#
# Linear-attention layout (the GGUF's): a row of the fused q|k|v|z projection is q (16 key heads x 128) | k (16 x 128)
# | v (32 value heads x 128) | z (32 x 128); value head h reads key head h % 16 (llama.cpp's tiled order). The state of
# a layer is [32 heads][128 value dims][128 key dims] fp32: S[h][v][k] is transformers' state[h][k][v].
#
# Every workgroup is one 64-lane subgroup. Loops before a subgroup sum or shuffle run the same number of iterations in
# every lane (guards inside).
from std.math import exp, log1p, rsqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR
from max.gpu.memory import AddressSpace
from max.gpu.primitives.warp import sum as warp_sum, shuffle_xor

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]

comptime EPS = Float32(1e-6)
comptime NK = 16  # linear attention: key heads
comptime NV = 32  # value heads
comptime DK = 128  # head dim (keys and values)
comptime CONV = 2 * NK * DK + NV * DK  # 8192 conv channels: q | k | v
comptime QSCALE = Float32(0.08838834764831845)  # 1 / sqrt(128)
comptime HD = 256  # full attention head dim
comptime H = 16  # query heads
comptime KVH = 4  # KV heads
comptime NQ = 4  # query heads a KV head
comptime ROT = 64  # rotated dimensions of a head
comptime ASCALE = Float32(0.0625)  # 1 / sqrt(256)


@always_inline
def silu(x: Float32) -> Float32:
    return x / (1 + exp(-x))


@always_inline
def sigmoid(x: Float32) -> Float32:
    return 1 / (1 + exp(-x))


@always_inline
def softplus(x: Float32) -> Float32:
    """torch's F.softplus (beta 1, threshold 20)."""
    return x if x > 20 else log1p(exp(x))


@always_inline
def sum16(v: Float32) -> Float32:
    """The sum over a lane's group of 16 (lanes 16 j .. 16 j + 15), in every lane of the group."""
    var s = v
    comptime for stage in range(4):
        s += shuffle_xor(s, UInt32(1 << stage))
    return s


# ---- the affine storage (convert.c's a41 / a5k): w = d (lo - 8 + 16 hi) + c a block of 32 ------------------------


@always_inline
def dot_aff[HI: Bool](wq: U32, wh: U32, wd: F32, wc: F32, row: Int, cols: Int, x: F32, t: Int) -> Float32:
    """Lane t's share of W[row] . x: a block of 32 weights a lane a step (one 16-byte load of its low bits, its high
    bits, d and c): d (sum (lo - 8) x + 16 sum_{hi} x) + c sum x."""
    var blocks = cols // 32
    var acc = Float32(0)
    var wr = wq + row * (cols // 8)
    for i in range((blocks + 63) // 64):
        var b = i * 64 + t
        if b < blocks:
            var w4 = wr.load[width=4](b * 4)
            var hb = UInt32(0)
            comptime if HI:
                hb = wh[row * blocks + b]
            var ps = Float32(0)
            var ph = Float32(0)
            var px = Float32(0)
            comptime for k in range(4):
                var xv = x.load[width=8](b * 32 + k * 8)
                comptime for j in range(8):
                    var q = Int32((w4[k] >> UInt32(4 * j)) & 15) ^ 8
                    ps += Float32(q - 8) * xv[j]
                    px += xv[j]
                    comptime if HI:
                        ph += Float32((hb >> UInt32(8 * k + j)) & 1) * xv[j]
            var d = wd[row * blocks + b]
            acc += d * (ps + 16 * ph) + wc[row * blocks + b] * px
    return acc


def gemv_aff[HI: Bool](wq: U32, wh: U32, wd: F32, wc: F32, x: F32, y: F32, cols: Int32):
    """y[r] = W[r] . x, W in the affine storage: a workgroup a row."""
    var r = Int(block_idx.x)
    var s = warp_sum(dot_aff[HI](wq, wh, wd, wc, r, Int(cols), x, Int(thread_idx.x)))
    if thread_idx.x == 0:
        y[r] = s


comptime BM = 128
comptime BN = 128
comptime BK = 16
comptime KC = 8  # the 840's fp32 product: 64 x 64 x 8
comptime THREADS = 256


def gemm_aff[HI: Bool](wq: U32, wh: U32, wd: F32, wc: F32, x: F32, y: F32, n: Int64, k: Int64):
    """Y[rows, n] = X[rows, k] W^T, W in the affine storage, on the matrix units: lk.gemm_q4 with this storage's
    unpacking (d (lo - 8 + 16 hi) + c into shared memory as fp32). Two k steps of 16 a block of 32: a thread loads its
    block's d, c and high bits once for both. rows, n and k: multiples of 128, 128 and 32."""
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
    var wc8 = t % (BK // 8) * 8
    var blocks = ldx // 32
    var wrow = wq + (col0 + wr) * (ldx // 8)
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for b0 in range(0, ldx, 32):
        var bi = (col0 + wr) * blocks + b0 // 32
        var d = wd[bi]
        var cc = wc[bi]
        var hb = UInt32(0)
        comptime if HI:
            hb = wh[bi]
        comptime for half in range(2):
            var k0 = b0 + half * BK
            comptime for i in range(BM * BK // 4 // THREADS):
                var v = i * THREADS + t
                var r = v // (BK // 4)
                var c = v % (BK // 4) * 4
                sa.unsafe_store(r * BK + c, x.unsafe_load[width=4]((row0 + r) * ldx + k0 + c))
            var word = wrow[(k0 + wc8) // 8]
            comptime for j in range(8):
                var q = Float32((Int32((word >> UInt32(4 * j)) & 15) ^ 8) - 8)
                comptime if HI:
                    q += Float32(16 * Int32((hb >> UInt32(half * BK + wc8 + j)) & 1))
                sb.unsafe_store(wr * BK + wc8 + j, d * q + cc)
            barrier()
            comptime for kk in range(0, BK, KC):
                var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sa.unsafe_offset(sr * BK + kk), BK)
                var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](
                    sb.unsafe_offset(sc * BK + kk), BK)
                acc = at.multiply_add(bt, acc)
            barrier()
    acc.store(out, ldy)


def gemm64[KIND: Int](wq: U32, ws: F16, wh: U32, wd: F32, wc: F32, x: F32, y: F32, n: Int64, k: Int64, row0: Int64):
    """The batch's last 64 rows (from row0) of Y[rows, n] = X[rows, k] W^T, so a prompt is padded to 64 rows rather than
    gemm_q4's 128: a 128-thread workgroup (2 subgroups) computes a 64 x 128 block. KIND 0: W Q4_0 (lk's words + fp16
    scales ws); 1: the affine storage; 2: the affine storage with high bits. A thread stages one W row's 16 weights a
    k step (2 words, half a block). n and k: multiples of 128 and 32."""
    var sa = stack_allocation[64 * BK, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[128 * BK, Float32, address_space=AddressSpace.SHARED]()
    var ldy = Int(n)
    var ldx = Int(k)
    var t = Int(thread_idx.x)
    var r0 = Int(row0)
    var col0 = Int(block_idx.x) * 128
    var sc = (t // 64) * 64
    var blocks = ldx // 32
    var wrow = wq + (col0 + t) * (ldx // 8)
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for k0 in range(0, ldx, BK):
        comptime for i in range(2):
            var v = i * 128 + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            sa.unsafe_store(r * BK + c, x.unsafe_load[width=4]((r0 + r) * ldx + k0 + c))
        var bi = (col0 + t) * blocks + k0 // 32
        var d: Float32
        var cc = Float32(0)
        var hb = UInt32(0)
        comptime if KIND == 0:
            d = ws[bi].cast[DType.float32]()
        else:
            d = wd[bi]
            cc = wc[bi]
            comptime if KIND == 2:
                hb = wh[bi] >> UInt32(k0 % 32)
        comptime for w in range(2):
            var word = wrow[k0 // 8 + w]
            comptime for j in range(8):
                var q = Float32((Int32((word >> UInt32(4 * j)) & 15) ^ 8) - 8)
                comptime if KIND == 2:
                    q += Float32(16 * Int32((hb >> UInt32(8 * w + j)) & 1))
                comptime if KIND == 0:
                    sb.unsafe_store(t * BK + 8 * w + j, q * d)
                else:
                    sb.unsafe_store(t * BK + 8 * w + j, d * q + cc)
        barrier()
        comptime for kk in range(0, BK, KC):
            var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sa.unsafe_offset(kk), BK)
            var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(sc * BK + kk), BK)
            acc = at.multiply_add(bt, acc)
        barrier()
    acc.store(y.unsafe_offset(r0 * ldy + col0 + sc), ldy)


def gemv_f32(w: F32, x: F32, y: F32, cols: Int32, n: Int32):
    """y[row, r] = W[r] . x[row] for W fp32 [n, cols]: workgroup (r, row) (block_idx.x, block_idx.y)."""
    var r = Int(block_idx.x)
    var row = Int(block_idx.y)
    var c = Int(cols)
    var t = Int(thread_idx.x)
    var acc = SIMD[DType.float32, 4](0)
    var wr = w + r * c
    var xr = x + row * c
    for i in range((c // 4 + 63) // 64):
        var j = (i * 64 + t) * 4
        if j < c:
            acc += wr.load[width=4](j) * xr.load[width=4](j)
    var s = warp_sum(acc.reduce_add())
    if t == 0:
        y[row * Int(n) + r] = s


# ---- linear attention (Gated DeltaNet) ------------------------------------------------------------------------------


def conv_qk(mix: F32, cw: F32, state: F32, y: F32, ab: F32, dtb: F32, a: F32, gb: F32, p0: Int32, stride: Int32,
            update: Int32):
    """Row t = block_idx.y (position p = p0 + t), channels 128 g .. 128 g + 127 (g = block_idx.x, 64 groups: 16 q heads,
    16 k heads, 32 v heads), lane d: channels d and d + 64. The causal depthwise conv (4 taps, transformers' conv1d with
    padding 3) over the projection rows' q|k|v (mix rows, `stride` floats apart), then SiLU:
        y[t, c] = silu(w[c, 0] x[p - 3] + w[c, 1] x[p - 2] + w[c, 2] x[p - 1] + w[c, 3] x[p])
    with earlier rows of the batch from mix, earlier positions from the state ring (slot p % 3; zero before the
    sequence). A q head is then L2-normed (rsqrt(sum + 1e-6)) and scaled by 1 / sqrt(128), a k head L2-normed. A v
    head's lane 0 also writes the head's decay exp(-exp(A_log) softplus(alpha + dt_bias)) and beta = sigmoid(b) into
    gb[t, h] and gb[t, 32 + h] (ab rows: alpha (32) | b (32); a = -exp(A_log), the GGUF's ssm_a). update 1 (decode,
    one row): x[p] into its ring slot after reading the slot's x[p - 3] (the same thread)."""
    var g = Int(block_idx.x)
    var t = Int(block_idx.y)
    var lane = Int(thread_idx.x)
    var p = Int(p0) + t
    var st = Int(stride)
    var o = SIMD[DType.float32, 2](0)
    comptime for e in range(2):
        var c = g * 128 + lane + 64 * e
        var w = cw.load[width=4](c * 4)
        var xp = mix[t * st + c]
        var acc = w[3] * xp
        comptime for k in range(1, 4):
            var xk = Float32(0)
            if t - k >= 0:
                xk = mix[(t - k) * st + c]
            elif p - k >= 0:
                xk = state[((p - k) % 3) * CONV + c]
            acc += w[3 - k] * xk
        o[e] = silu(acc)
        if update == 1:
            state[(p % 3) * CONV + c] = xp
    if g < 2 * NK:  # q or k: L2 norm over the head
        var r = rsqrt(warp_sum(o[0] * o[0] + o[1] * o[1]) + EPS)
        if g < NK:
            r *= QSCALE
        o *= r
    else:
        var h = g - 2 * NK
        if lane == 0:
            var al = ab[t * 2 * NV + h]
            var b = ab[t * 2 * NV + NV + h]
            gb[t * 2 * NV + h] = exp(a[h] * softplus(al + dtb[h]))
            gb[t * 2 * NV + NV + h] = sigmoid(b)
    y[t * CONV + g * 128 + lane] = o[0]
    y[t * CONV + g * 128 + lane + 64] = o[1]


def conv_state(mix: F32, state: F32, p0: Int32, count: Int32, stride: Int32):
    """After a batch of `count` rows from p0: the last three rows' conv inputs into the ring (slot position % 3)."""
    var i = global_idx.x
    if i >= 3 * CONV:
        return
    var t = Int(count) - 3 + i // CONV
    var c = i % CONV
    if t >= 0:
        state[((Int(p0) + t) % 3) * CONV + c] = mix[t * Int(stride) + c]


def delta_rule[NC: Int](qkv: F32, gb: F32, S: F32, o: F32, count: Int32):
    """The gated delta rule of value head h = block_idx.x, value dims 4 NC block_idx.y .. + 4 NC - 1 (NC a 16-lane
    group; lane l of a group holds key dims 8 l .. 8 l + 7 of its rows of the state), over rows 0 .. count - 1 of qkv
    (conv_qk's out: q, k normed, q scaled) in turn, the state in registers between rows. Per row, as transformers'
    torch_recurrent_gated_delta_rule:
        S *= decay;  kv = S k;  delta = (v - kv) beta;  S += delta k^T;  o = S q
    The next row's inputs are loaded before this row's arithmetic (their latency hides behind its reductions), and a
    group's NC columns are independent chains. S: [32 heads][128 v][128 k] fp32, read before the first row and written
    after the last."""
    var h = Int(block_idx.x)
    var lane = Int(thread_idx.x)
    var l = lane % 16
    var v0 = Int(block_idx.y) * 4 * NC + (lane // 16) * NC
    var kh = h % NK
    var sp = S + (h * DK * DK + v0 * DK + l * 8)
    var s = SIMD[DType.float32, 8 * NC](0)
    comptime for c in range(NC):
        s = s.insert[offset=8 * c](sp.load[width=8](c * DK))
    var n = Int(count)
    var qo = kh * DK + l * 8
    var ko = NK * DK + kh * DK + l * 8
    var vo = 2 * NK * DK + h * DK + v0
    var q8 = qkv.load[width=8](qo)
    var k8 = qkv.load[width=8](ko)
    var vv = SIMD[DType.float32, NC](0)
    comptime for c in range(NC):
        vv[c] = qkv[vo + c]
    var dec = gb[h]
    var bet = gb[NV + h]
    for t in range(n):
        var t1 = min(t + 1, n - 1)
        var row1 = qkv + t1 * CONV
        var nq8 = row1.load[width=8](qo)
        var nk8 = row1.load[width=8](ko)
        var nvv = SIMD[DType.float32, NC](0)
        comptime for c in range(NC):
            nvv[c] = row1[vo + c]
        var ndec = gb[t1 * 2 * NV + h]
        var nbet = gb[t1 * 2 * NV + NV + h]
        var ov = SIMD[DType.float32, NC](0)
        comptime for c in range(NC):
            var sc = s.slice[8, offset=8 * c]() * dec
            var kv = sum16((sc * k8).reduce_add())
            sc += k8 * ((vv[c] - kv) * bet)
            ov[c] = sum16((sc * q8).reduce_add())
            s = s.insert[offset=8 * c](sc)
        if l == 0:
            comptime for c in range(NC):
                o[t * NV * DK + h * DK + v0 + c] = ov[c]
        q8 = nq8
        k8 = nk8
        vv = nvv
        dec = ndec
        bet = nbet
    comptime for c in range(NC):
        sp.store(c * DK, s.slice[8, offset=8 * c]())


def gated_norm(o: F32, mix: F32, w: F32, y: F32, stride: Int32, zoff: Int32):
    """Head h = block_idx.x of row t = block_idx.y: y = w * (o / rms(o)) * silu(z) over the head's 128 (eps 1e-6;
    transformers' Qwen3_5RMSNormGated), z from the projection row (mix, at zoff + 128 h). Lane d: d and d + 64."""
    var h = Int(block_idx.x)
    var t = Int(block_idx.y)
    var d = Int(thread_idx.x)
    var base = t * NV * DK + h * DK
    var a = o[base + d]
    var b = o[base + d + 64]
    var r = rsqrt(warp_sum(a * a + b * b) / Float32(DK) + EPS)
    var z = mix + (t * Int(stride) + Int(zoff) + h * DK)
    y[base + d] = w[d] * (a * r) * silu(z[d])
    y[base + d + 64] = w[d + 64] * (b * r) * silu(z[d + 64])


# ---- full attention ---------------------------------------------------------------------------------------------------
# A row of the fused projection: q (16 x 256) | k (4 x 256) | v (4 x 256) | gate (16 x 256), `stride` floats.


def qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, p0: Int32, stride: Int32):
    """Head block_idx.x (16 q, 4 k, 4 v) of row t = block_idx.y, position p = p0 + t: a q head gets its RMS norm (wq,
    the stored 1 + w), RoPE on its first 64 dimensions and the scale 1 / 16, in place; a k head its norm and RoPE into
    K cache row p; a v head goes into V cache row p as it is (a cache row: 4 x 256). Lane d holds dimensions d, d + 64,
    d + 128, d + 192; RoPE rotates halves of the first 64 (pairs j, j + 32), the table row of p holds cos | sin of 32."""
    var sh = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var hh = Int(block_idx.x)
    var t = Int(block_idx.y)
    var d = Int(thread_idx.x)
    var p = Int(p0) + t
    var row = qkv + t * Int(stride)
    var x = SIMD[DType.float32, 4](0)
    if hh >= H + KVH:
        comptime for e in range(4):
            vc[p * KVH * HD + (hh - H - KVH) * HD + d + 64 * e] = row[H * HD + KVH * HD + (hh - H - KVH) * HD + d + 64 * e]
        return
    var base = hh * HD if hh < H else H * HD + (hh - H) * HD
    comptime for e in range(4):
        x[e] = row[base + d + 64 * e]
    var r = rsqrt(warp_sum((x * x).reduce_add()) / Float32(HD) + EPS)
    var w = wq if hh < H else wk
    comptime for e in range(4):
        x[e] = x[e] * r * w[d + 64 * e]
    sh[d] = x[0]
    barrier()
    var j = d % 32
    var a = sh[j]
    var b = sh[j + 32]
    var cs = table[p * ROT + j]
    var sn = table[p * ROT + 32 + j]
    x[0] = (a * cs - b * sn) if d < 32 else (b * cs + a * sn)
    if hh < H:
        comptime for e in range(4):
            row[base + d + 64 * e] = x[e] * ASCALE
    else:
        comptime for e in range(4):
            kc[p * KVH * HD + (hh - H) * HD + d + 64 * e] = x[e]


comptime CH = 32  # positions a decode-attention chunk


def attn_part(qkv: F32, kc: F32, vc: F32, pv: F32, pm: F32, pos: Int32):
    """q4bk.attn_part for heads of 256: KV head g = block_idx.x, chunk c = block_idx.y (positions 32 c ..
    min(32 c + 31, pos)); for each of its 4 query heads h = 4 g + j the chunk's highest score (pm[c, h]), its sum of
    exp(s - m) (pm[c, 16 + h]) and sum exp(s - m) V (pv[c, h, :]); q carries the scale. A K row is read by 16 lanes (16
    of its 256 floats each), four positions at a time; for the values lane d takes dimensions d + 64 e."""
    var sq = stack_allocation[NQ * HD, Float32, address_space=AddressSpace.SHARED]()
    var ss = stack_allocation[NQ * CH, Float32, address_space=AddressSpace.SHARED]()
    var g = Int(block_idx.x)
    var c = Int(block_idx.y)
    var lane = Int(thread_idx.x)
    var t0 = c * CH
    var n = min(CH, Int(pos) + 1 - t0)
    for i in range(lane, NQ * HD, 64):
        sq[i] = qkv[g * NQ * HD + i]
    barrier()
    var grp = lane // 16
    var l = lane % 16
    for i in range(CH // 4):  # every lane the same number of passes: the shuffles stay outside the guard
        var t = i * 4 + grp
        var ka = SIMD[DType.float32, 8](0)
        var kb = SIMD[DType.float32, 8](0)
        if t < n:
            var kp = kc + ((t0 + t) * KVH * HD + g * HD + l * 16)
            ka = kp.load[width=8]()
            kb = kp.load[width=8](8)
        var dd = SIMD[DType.float32, NQ](0)
        comptime for j in range(NQ):
            dd[j] = (sq.load[width=8](j * HD + l * 16) * ka + sq.load[width=8](j * HD + l * 16 + 8) * kb).reduce_add()
        var d0 = sum16(dd[0])
        var d1 = sum16(dd[1])
        var d2 = sum16(dd[2])
        var d3 = sum16(dd[3])
        if l == 0:
            var bad = Float32(-3.402823e38)
            ss[t] = d0 if t < n else bad
            ss[CH + t] = d1 if t < n else bad
            ss[2 * CH + t] = d2 if t < n else bad
            ss[3 * CH + t] = d3 if t < n else bad
    barrier()
    var m = SIMD[DType.float32, NQ](-3.402823e38)
    comptime for j in range(NQ):
        for t in range(CH):
            m[j] = max(m[j], ss[j * CH + t])
    barrier()
    if lane < CH:
        comptime for j in range(NQ):
            ss[j * CH + lane] = exp(ss[j * CH + lane] - m[j]) if lane < n else Float32(0)
    barrier()
    var vb = vc + (t0 * KVH * HD + g * HD + lane)
    var tot = SIMD[DType.float32, NQ](0)
    var acc = SIMD[DType.float32, NQ * 4](0)  # head j, dimension lane + 64 e at 4 j + e
    for t in range(n):
        var v4 = SIMD[DType.float32, 4](0)
        comptime for e in range(4):
            v4[e] = vb[t * KVH * HD + 64 * e]
        comptime for j in range(NQ):
            var p = ss[j * CH + t]
            tot[j] += p
            comptime for e in range(4):
                acc[4 * j + e] += p * v4[e]
    comptime for j in range(NQ):
        var h = g * NQ + j
        comptime for e in range(4):
            pv[(c * H + h) * HD + lane + 64 * e] = acc[4 * j + e]
    if lane == 0:
        comptime for j in range(NQ):
            pm[c * 2 * H + g * NQ + j] = m[j]
            pm[c * 2 * H + H + g * NQ + j] = tot[j]


def attn_combine(pv: F32, pm: F32, qkv: F32, y: F32, pos: Int32):
    """Query head h = block_idx.x: y[h, :] = (sum_c exp(m_c - M) pv[c, h, :] / sum_c exp(m_c - M) l_c) * sigmoid(gate)
    over attn_part's chunks; the gate from the projection row (after q | k | v). Lane d: dimensions d + 64 e."""
    var h = Int(block_idx.x)
    var lane = Int(thread_idx.x)
    var nc = Int(pos) // CH + 1
    var hi: Float32 = -3.402823e38
    for c in range(nc):
        hi = max(hi, pm[c * 2 * H + h])
    var total: Float32 = 0
    var acc = SIMD[DType.float32, 4](0)
    for c in range(nc):
        var w = exp(pm[c * 2 * H + h] - hi)
        total += w * pm[c * 2 * H + H + h]
        comptime for e in range(4):
            acc[e] += w * pv[(c * H + h) * HD + lane + 64 * e]
    comptime for e in range(4):
        var dim = h * HD + lane + 64 * e
        y[dim] = acc[e] / total * sigmoid(qkv[(H + 2 * KVH) * HD + dim])


def gate_mul(att: F32, qkv: F32, count: Int32, stride: Int32):
    """Prefill: att[t, j] *= sigmoid(gate[t, j]) for rows t < count (att rows of 16 x 256; the gate after q|k|v)."""
    var i = global_idx.x
    if i < Int(count) * H * HD:
        var t = i // (H * HD)
        var j = i % (H * HD)
        att[i] = att[i] * sigmoid(qkv[t * Int(stride) + (H + 2 * KVH) * HD + j])
