# Speculative decoding with the DSpark drafter (LiquidAI/LFM2.5-2.6B-DSpark), lfm2/dspark_ref.py's algorithm: the
# few-row kernels the target's verify pass and the drafter share (a weight row read once for up to MR rows of x), and
# the drafter's own kernels (q/k norms with interleaved RoPE, attention over its context cache and the block, the
# context K/V write, the Markov bias), plus the bookkeeping (the target's taps, the conv state after a partial accept).
# The drafter's weights stay bf16 (uint16 bits, widened exactly).
from std.math import exp, rsqrt
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.primitives.warp import sum as warp_sum

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U16 = UnsafePointer[UInt16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
comptime I32 = UnsafePointer[Int32, MutAnyOrigin]

comptime MR = 10  # rows a few-row kernel takes at most: the anchor and 9 drafts
comptime EPS = Float32(1e-5)
comptime HD = 64
comptime KMAX = 2064  # the drafter's attention: context keys (< 2048) and the 9 block keys


@always_inline
def bf16x8(p: U16, i: Int) -> SIMD[DType.float32, 8]:
    return bitcast[DType.float32, 8](p.load[width=8](i).cast[DType.uint32]() << 16)


# ---- few-row products: y[m, r] = W[r] . x[m] for rows m < count (count <= 12) ------------------------------------
# A 64-lane workgroup takes 8 weight rows. Its lanes are 4 groups of 16: group g holds x's rows g, g + 4, g + 8, and its
# 16 lanes take consecutive 8-weight words of the 8 weight rows (decode's coalesced order). Each x element is loaded by
# one lane and applied to the 8 rows; each weight is unpacked once a group (4 times a workgroup) and applied by a chain
# of fused multiply-adds. The 16 lanes' partial sums meet in shared memory at the end. (Measured on the 840 for gate/up,
# 21504 x 2048 int4, 10 rows: 0.85 ms, against 2.4 ms on the matrix units, where unpacking the weights into shared
# memory for an N of 16 dominated, and 0.38 ms for decode's single row; lfm2/bench_rows.mojo.) cols: a multiple of
# 128; n: of 8.

comptime TR = 8  # weight rows a workgroup


@always_inline
def load_x3[XQ: Int](x: F32, k: Int, col: Int, g: Int, count: Int) -> Tuple[SIMD[DType.float32, 8],
                                                                           SIMD[DType.float32, 8],
                                                                           SIMD[DType.float32, 8]]:
    """x[m, col .. col + 8) for the group's rows m = g, g + 4, g + 8 (the first XQ of them; zeros past count)."""
    var x0 = SIMD[DType.float32, 8](0)
    var x1 = SIMD[DType.float32, 8](0)
    var x2 = SIMD[DType.float32, 8](0)
    if g < count:
        x0 = x.load[width=8](g * k + col)
    comptime if XQ >= 2:
        if g + 4 < count:
            x1 = x.load[width=8]((g + 4) * k + col)
    comptime if XQ >= 3:
        if g + 8 < count:
            x2 = x.load[width=8]((g + 8) * k + col)
    return (x0, x1, x2)


@always_inline
def fma3[XQ: Int](w: SIMD[DType.float32, 8], x0: SIMD[DType.float32, 8], x1: SIMD[DType.float32, 8],
                  x2: SIMD[DType.float32, 8], mut acc: SIMD[DType.float32, TR * 4], j: Int):
    """acc[j, q] += w . x_q for the XQ slots in use: chains of fused multiply-adds."""
    var a0 = acc[j * 4]
    var a1 = acc[j * 4 + 1]
    var a2 = acc[j * 4 + 2]
    comptime for e in range(8):
        a0 += w[e] * x0[e]
        comptime if XQ >= 2:
            a1 += w[e] * x1[e]
        comptime if XQ >= 3:
            a2 += w[e] * x2[e]
    acc[j * 4] = a0
    acc[j * 4 + 1] = a1
    acc[j * 4 + 2] = a2


@always_inline
def finish_tile(sp: UnsafePointer[Float32, MutUntrackedOrigin, address_space=AddressSpace.SHARED],
                acc: SIMD[DType.float32, TR * 4], y: F32, n: Int, r0: Int, count: Int, t: Int):
    """Output (row r0 + j, x row m) is the sum of the 16 lanes of group m % 4, slot m / 4."""
    comptime for j in range(TR):
        comptime for q in range(3):
            sp[(j * 3 + q) * 64 + t] = acc[j * 4 + q]
    barrier()
    for o in range(t, TR * 12, 64):
        var j = o // 12
        var m = o % 12
        if m < count:
            var base = (j * 3 + m // 4) * 64 + (m % 4) * 16
            var tot = Float32(0)
            for uu in range(16):
                tot += sp[base + uu]
            y[m * n + r0 + j] = tot


def rows_q4[XQ: Int](wq: U32, ws: F16, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """int4 W (Q4_0's numbers: 8 a word, an fp16 scale per 32), each weight (q - 8) d as the reference dequantizes."""
    var sp = stack_allocation[64 * TR * 3, Float32, address_space=AddressSpace.SHARED]()
    var r0 = Int(block_idx.x) * TR
    var t = Int(thread_idx.x)
    var g = t // 16
    var u = t % 16
    var k = Int(cols)
    var cnt = Int(count)
    var words = k // 8
    var blocks = k // 32
    var acc = SIMD[DType.float32, TR * 4](0)
    for i in range(words // 16):
        var wi = i * 16 + u
        var xs = load_x3[XQ](x, k, wi * 8, g, cnt)
        comptime for j in range(TR):
            var word = wq[(r0 + j) * words + wi]
            var s = ws[(r0 + j) * blocks + wi // 4].cast[DType.float32]()
            var w = SIMD[DType.float32, 8]()
            comptime for e in range(8):
                w[e] = Float32((Int32((word >> UInt32(4 * e)) & 15) ^ 8) - 8) * s
            fma3[XQ](w, xs[0], xs[1], xs[2], acc, j)
    finish_tile(sp, acc, y, Int(n), r0, cnt, t)


def rows_bf[XQ: Int](w: U16, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """bf16 W (the drafter's), widened exactly."""
    var sp = stack_allocation[64 * TR * 3, Float32, address_space=AddressSpace.SHARED]()
    var r0 = Int(block_idx.x) * TR
    var t = Int(thread_idx.x)
    var g = t // 16
    var u = t % 16
    var k = Int(cols)
    var cnt = Int(count)
    var acc = SIMD[DType.float32, TR * 4](0)
    for i in range(k // 128):
        var col = (i * 16 + u) * 8
        var xs = load_x3[XQ](x, k, col, g, cnt)
        comptime for j in range(TR):
            fma3[XQ](bf16x8(w + (r0 + j) * k, col), xs[0], xs[1], xs[2], acc, j)
    finish_tile(sp, acc, y, Int(n), r0, cnt, t)


def head_q6_rows[XQ: Int](wq: U32, wd: F16, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """The tied head (Q6_K) for rows m < count. A lane's 8 weights 8 c8 .. 8 c8 + 7 of a row lie in one 32-weight chunk
    c8 / 4 (lk.q6_chunk's layout), as its words 2 sub, 2 sub + 1 (sub = c8 % 4), under one scale; everything but the
    row's base is the same for the workgroup's 8 rows, so it is worked out once an iteration. Each weight is
    (d sc) (q - 32), as ggml dequantizes it."""
    var sp = stack_allocation[64 * TR * 3, Float32, address_space=AddressSpace.SHARED]()
    var r0 = Int(block_idx.x) * TR
    var t = Int(thread_idx.x)
    var g = t // 16
    var u = t % 16
    var k = Int(cols)
    var cnt = Int(count)
    var nb = k // 256
    var acc = SIMD[DType.float32, TR * 4](0)
    for i in range(k // 128):
        var c8 = i * 16 + u
        var xs = load_x3[XQ](x, k, c8 * 8, g, cnt)
        var c = c8 // 4
        var sub = c8 % 4
        var b = c // 8
        var kq = c % 8
        var h = kq // 4
        var gq = kq % 4
        var ql = (64 * h + 32 * (gq & 1)) // 4 + 2 * sub  # words into the super-block
        var qh = 32 + 8 * h + 2 * sub
        var si = 8 * h + 2 * gq + (1 if sub >= 2 else 0)
        var scw_off = 48 + si // 4
        var sc_shift = UInt32(8 * (si % 4))
        var lo_shift = UInt32(4 * (gq >> 1))
        var hi_shift = UInt32(2 * gq)
        comptime for j in range(TR):
            var blk = (r0 + j) * nb + b
            var base = blk * 52
            var sc = Int32((wq[base + scw_off] >> sc_shift) & 255) ^ 128
            var ds = wd[blk].cast[DType.float32]() * Float32(sc - 128)
            var w = SIMD[DType.float32, 8]()
            comptime for ww in range(2):
                var qlw = wq[base + ql + ww]
                var qhw = wq[base + qh + ww]
                comptime for kk in range(4):
                    var q = Int32(((qlw >> (UInt32(8 * kk) + lo_shift)) & 15) |
                                  (((qhw >> (UInt32(8 * kk) + hi_shift)) & 3) << 4))
                    w[4 * ww + kk] = ds * Float32(q - 32)
            fma3[XQ](w, xs[0], xs[1], xs[2], acc, j)
    finish_tile(sp, acc, y, Int(n), r0, cnt, t)


def q6_to_q8(wq: U32, wd: F16, q8: U32, s16: F32, cols: Int32, rows: Int32):
    """The Q6_K head as int8 (q - 32, 4 a word, low byte first) and an fp32 scale per 16 weights (d sc, the product ggml
    multiplies by): the same weights, cheaper to unpack. A thread a group of 16 weights."""
    var i = global_idx.x
    var k = Int(cols)
    var groups = k // 16
    if i >= Int(rows) * groups:
        return
    var row = i // groups
    var e0 = (i % groups) * 16  # first element in the row
    var nb = k // 256
    var b = e0 // 256
    var ie = e0 % 256
    var h = ie // 128
    var jq = ie % 128
    var g = jq // 32
    var l0 = jq % 32
    var base = (row * nb + b) * 52
    var si = ie // 16
    var scw = wq[base + 48 + si // 4]
    var sc = Int32((scw >> UInt32(8 * (si % 4))) & 255) ^ 128
    s16[i] = wd[row * nb + b].cast[DType.float32]() * Float32(sc - 128)
    var lo_shift = UInt32(4 * (g >> 1))
    var hi_shift = UInt32(2 * g)
    var qlb = base * 4 + 64 * h + 32 * (g & 1) + l0  # bytes into the row's super-block
    var qhb = base * 4 + 128 + 32 * h + l0
    comptime for wv in range(4):
        var word = UInt32(0)
        comptime for kk in range(4):
            var l = 4 * wv + kk
            var qlbyte = (wq[(qlb + l) // 4] >> UInt32(8 * ((qlb + l) % 4))) & 255
            var qhbyte = (wq[(qhb + l) // 4] >> UInt32(8 * ((qhb + l) % 4))) & 255
            var q = Int32(((qlbyte >> lo_shift) & 15) | (((qhbyte >> hi_shift) & 3) << 4)) - 32
            word |= (UInt32(q) & 255) << UInt32(8 * kk)
        q8[(row * k + e0) // 4 + wv] = word


def head_q8_rows[XQ: Int](q8: U32, s16: F32, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """The tied head from q6_to_q8's copy for rows m < count: a lane's 8 weights are 2 words under one scale."""
    var sp = stack_allocation[64 * TR * 3, Float32, address_space=AddressSpace.SHARED]()
    var r0 = Int(block_idx.x) * TR
    var t = Int(thread_idx.x)
    var g = t // 16
    var u = t % 16
    var k = Int(cols)
    var cnt = Int(count)
    var acc = SIMD[DType.float32, TR * 4](0)
    for i in range(k // 128):
        var c8 = i * 16 + u
        var xs = load_x3[XQ](x, k, c8 * 8, g, cnt)
        comptime for j in range(TR):
            var row = r0 + j
            var w2 = q8.load[width=2]((row * k + c8 * 8) // 4)
            var sc = s16[(row * k + c8 * 8) // 16]
            var w = SIMD[DType.float32, 8]()
            comptime for wv in range(2):
                comptime for kk in range(4):
                    w[4 * wv + kk] = Float32((Int32((w2[wv] >> UInt32(8 * kk)) & 255) ^ 128) - 128) * sc
            fma3[XQ](w, xs[0], xs[1], xs[2], acc, j)
    finish_tile(sp, acc, y, Int(n), r0, cnt, t)


def argmax_rows(logits: F32, n: Int32, dst: I32, slot0: Int32):
    """Row block_idx.x's argmax (the lowest index among equals) into dst[slot0 + row]. 256-thread workgroups."""
    var sv = stack_allocation[256, Float32, address_space=AddressSpace.SHARED]()
    var si = stack_allocation[256, Int32, address_space=AddressSpace.SHARED]()
    var m = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var row = logits + m * Int(n)
    var best: Float32 = -3.402823e38
    var bi = Int32(0)
    for j in range(t, Int(n), 256):
        var v = row[j]
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
        dst[Int(slot0) + m] = si[0]


# ---- target bookkeeping ------------------------------------------------------------------------------------------


def copy_tap(x: F32, taps: F32, which: Int32, count: Int32, d: Int32):
    """taps[t, which * d ..] = x[t] for rows t < count: one of the target's 5 tapped residual streams."""
    var i = global_idx.x
    var D = Int(d)
    if i < Int(count) * D:
        var t = i // D
        taps[t * 5 * D + Int(which) * D + i % D] = x[i]


def conv_commit(vbx: F32, state: F32, p0: Int32, accepted: Int32, d: Int32):
    """After a verify of rows at p0 .. with `accepted` drafts kept: B x of the last two kept positions (p0 + accepted - 1,
    p0 + accepted) into their conv-state ring slots, from the verify's rows (vbx [MR, d])."""
    var i = global_idx.x
    var D = Int(d)
    if i < 2 * D:
        var k = Int(accepted) - 1 + i // D
        if k >= 0:
            state[((Int(p0) + k) % 3) * D + i % D] = vbx[k * D + i % D]


def copy_id(src: I32, src_slot: Int32, dst: I32, dst_slot: Int32):
    if thread_idx.x == 0:
        dst[Int(dst_slot)] = src[Int(src_slot)]


# ---- the drafter -------------------------------------------------------------------------------------------------


@always_inline
def interleaved(a: Float32, b: Float32, d: Int, cs: Float32, sn: Float32) -> Float32:
    """RoPE on interleaved pairs (2i, 2i + 1) (GPT-J style): lane d's rotated value from its own value a and its
    partner's b (lane d ^ 1)."""
    if d % 2 == 0:
        return a * cs - b * sn
    return a * cs + b * sn


def draft_qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kb: F32, vb: F32, p0: Int32, scale: Float32):
    """Head block_idx.x of block row block_idx.y (position p0 + row) of the drafter's q|k|v rows (32 + 8 + 8 heads): q
    gets its RMS norm, interleaved RoPE and the attention scale (in place); k its norm and RoPE, into kb; v into vb (rows
    of 8 x 64)."""
    var sh = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var t = Int(block_idx.y)
    var d = Int(thread_idx.x)
    var p = Int(p0) + t
    var row = 48 * HD
    var v = qkv[t * row + h * HD + d]
    if h >= 40:
        vb[t * 8 * HD + (h - 40) * HD + d] = v
        return
    var r = rsqrt(warp_sum(v * v) / Float32(HD) + EPS)
    sh[d] = v * r * (wq[d] if h < 32 else wk[d])
    barrier()
    var o = interleaved(sh[d], sh[d ^ 1], d, table[p * HD + d // 2], table[p * HD + 32 + d // 2])
    if h < 32:
        qkv[t * row + h * HD + d] = o * scale
    else:
        kb[t * 8 * HD + (h - 32) * HD + d] = o


def ctx_kv_write(kv: F32, wk: F32, table: F32, kd: F32, vd: F32, p0: Int32):
    """Context rows' K (k_norm, interleaved RoPE at p0 + row) and V into one drafter layer's cache ([position][8 x 64]):
    kv rows are k | v (1024); head block_idx.x (8 k heads, then 8 v heads) of row block_idx.y."""
    var sh = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var t = Int(block_idx.y)
    var d = Int(thread_idx.x)
    var p = Int(p0) + t
    var v = kv[t * 16 * HD + h * HD + d]
    if h >= 8:
        vd[p * 8 * HD + (h - 8) * HD + d] = v
        return
    var r = rsqrt(warp_sum(v * v) / Float32(HD) + EPS)
    sh[d] = v * r * wk[d]
    barrier()
    kd[p * 8 * HD + h * HD + d] = interleaved(sh[d], sh[d ^ 1], d, table[p * HD + d // 2], table[p * HD + 32 + d // 2])


def draft_attention(qkv: F32, kd: F32, vd: F32, kb: F32, vb: F32, y: F32, nctx: Int32, count: Int32):
    """softmax(q K^T) V for query head block_idx.x of block row block_idx.y over the nctx context keys (the drafter's
    cache) and all `count` block keys (not causal); q carries the scale. KV head h / 4."""
    var sq = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var ss = stack_allocation[KMAX, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var t = Int(block_idx.y)
    var lane = Int(thread_idx.x)
    var g = h // 4
    var nc = Int(nctx)
    var n = nc + Int(count)
    var krow = 8 * HD
    sq[lane] = qkv[t * 48 * HD + h * HD + lane]
    barrier()
    var highest: Float32 = -3.402823e38
    for j in range(lane, n, 64):
        var k = (kd + (j * krow + g * HD)) if j < nc else (kb + ((j - nc) * krow + g * HD))
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
    highest = red[0]
    barrier()
    var total: Float32 = 0
    for j in range(lane, n, 64):
        var e = exp(ss[j] - highest)
        ss[j] = e
        total += e
    red[lane] = total
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            red[lane] += red[lane + (32 >> stage)]
        barrier()
    var inv = 1 / red[0]
    var va = SIMD[DType.float32, 4](0)  # 4 independent sums: the keys' loads overlap
    var vp = vd + (g * HD + lane)
    var j = 0
    while j + 4 <= nc:
        comptime for q in range(4):
            va[q] += ss[j + q] * vp[(j + q) * krow]
        j += 4
    while j < nc:
        va[0] += ss[j] * vp[j * krow]
        j += 1
    for jb in range(Int(count)):
        va[1] += ss[nc + jb] * vb[jb * krow + g * HD + lane]
    y[t * 32 * HD + h * HD + lane] = va.reduce_add() * inv


comptime MV = 64  # vocabulary rows a workgroup of markov_best takes


def markov_best(base: F32, w1: U16, w2: U16, ids: I32, prev_slot: Int32, cand_v: F32, cand_i: I32, vocab: Int32):
    """A draft step's corrected logits base[v] + W2[v] . W1[prev] (prev = ids[prev_slot]) for MV rows a workgroup, a lane
    4 of each row's 256, and their best (the lowest index among equals) into cand_v / cand_i[workgroup]."""
    var t = Int(thread_idx.x)
    var prev = Int(ids[Int(prev_slot)])
    var e = bitcast[DType.float32, 4](w1.load[width=4](prev * 256 + 4 * t).cast[DType.uint32]() << 16)
    var best: Float32 = -3.402823e38
    var bi = Int32(0)
    for k in range(MV):
        var v = Int(block_idx.x) * MV + k
        if v < Int(vocab):  # uniform: the whole workgroup takes the same v
            var w = bitcast[DType.float32, 4](w2.load[width=4](v * 256 + 4 * t).cast[DType.uint32]() << 16)
            var l = base[v] + warp_sum((w * e).reduce_add())
            if l > best:
                best = l
                bi = Int32(v)
    if t == 0:
        cand_v[Int(block_idx.x)] = best
        cand_i[Int(block_idx.x)] = bi


def best_of(cand_v: F32, cand_i: I32, n: Int32, dst: I32, slot: Int32):
    """The best of n candidates (the lowest index among equal values) into dst[slot]. One 256-thread workgroup."""
    var sv = stack_allocation[256, Float32, address_space=AddressSpace.SHARED]()
    var si = stack_allocation[256, Int32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var best: Float32 = -3.402823e38
    var bi = Int32(2147483647)
    for j in range(t, Int(n), 256):
        var v = cand_v[j]
        var i = cand_i[j]
        if v > best or (v == best and i < bi):
            best = v
            bi = i
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


def gemm_bf(w: U16, x: F32, y: F32, n: Int32, k: Int32):
    """Y = X W^T with bf16 W, scalar 64 x 64 tiles (lk.gemm_h with bf16): the drafter's context projection of a prompt.
    rows, n: multiples of 64; k: of 16."""
    var sa = stack_allocation[64 * 17, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[64 * 17, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var tx = t % 16
    var ty = t // 16
    var row0 = Int(block_idx.y) * 64
    var col0 = Int(block_idx.x) * 64
    var K = Int(k)
    var acc = SIMD[DType.float32, 16](0)
    var lr = t // 4
    var lc = (t % 4) * 4
    for k0 in range(0, K, 16):
        var xv = x.load[width=4]((row0 + lr) * K + k0 + lc)
        var wv = bitcast[DType.float32, 4](w.load[width=4]((col0 + lr) * K + k0 + lc).cast[DType.uint32]() << 16)
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
