# Qwen3-30B-A3B decode kernels: one token through a layer (hidden 2048; 32 query and 4 KV heads of 128, QK norm, RoPE;
# a router over 128 experts, top-8; experts' SwiGLU of 768 in int4) and greedy argmax. The int4 matrix-vector products
# of the attention and the output head are llama/kernels' gemv_q4 / gemv_add_q4 (an fp16 scale per 64 weights, 8
# weights a uint32 as 4-bit two's complement, low nibble first); here the same arithmetic, with a scale per 128,
# reads the selected experts' rows, whose ids the router leaves on the GPU, so a token needs no answer from the host.
# (The embedding row is copied by the executor itself: OP_GATHER.) Shared
# memory and barriers rather than shuffles after loops whose lanes diverge (see llama/kernels/attention.mojo).
from std.math import exp, rsqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.primitives.warp import sum as warp_sum

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
comptime I32 = UnsafePointer[Int32, MutAnyOrigin]

comptime D = 2048
comptime H = 32
comptime KVH = 4
comptime HD = 128
comptime KVW = KVH * HD  # 512: a K or V cache row
comptime TOPK = 8
comptime FE = 768  # an expert's SwiGLU width
comptime GE = 128  # the experts' weights per int4 scale


@always_inline
def dot_q4_row[G: Int](wq: U32, ws: F16, row: Int, cols: Int, x: F32, t: Int) -> Float32:
    """Lane t's share of W[row] . x for an int4 row of `cols` weights (a scale per G), 64 lanes taking words t,
    t + 64, ... Every lane runs the same number of iterations (768 columns are 96 words: the second pass guards
    its body), since a subgroup sum follows."""
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


def rmsnorm(x: F32, w: F32, y: F32, n: Int32):
    """y = x / rms(x) * w (eps 1e-6): one 64-lane workgroup."""
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = x[j]
        ss += v * v
    var r = rsqrt(warp_sum(ss) / Float32(Int(n)) + Float32(1e-6))
    for j in range(lane, Int(n), 64):
        y[j] = x[j] * r * w[j]


def qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, pos: Int32):
    """One 64-lane workgroup a head: query heads 0-31 (RMS norm over the head, RoPE, in place), key heads 32-35 (RMS
    norm, RoPE, into the K cache row `pos`), value heads 36-39 (into the V cache). Lane d holds d and d + 64 of the
    head; the table has cos | sin rows of 64 per position."""
    var h = Int(block_idx.x)
    var d = Int(thread_idx.x)
    var p = Int(pos)
    var base = h * HD
    var a = qkv[base + d]
    var b = qkv[base + d + 64]
    if h >= H + KVH:
        vc[p * KVW + (h - H - KVH) * HD + d] = a
        vc[p * KVW + (h - H - KVH) * HD + d + 64] = b
        return
    var w = wq if h < H else wk
    var r = rsqrt(warp_sum(a * a + b * b) / Float32(HD) + Float32(1e-6))
    a *= r * w[d]
    b *= r * w[d + 64]
    var c = table[p * HD + d]
    var s = table[p * HD + 64 + d]
    var ra = a * c - b * s
    var rb = b * c + a * s
    if h < H:
        qkv[base + d] = ra
        qkv[base + d + 64] = rb
    else:
        kc[p * KVW + (h - H) * HD + d] = ra
        kc[p * KVW + (h - H) * HD + d + 64] = rb


def attn_scores(q: F32, kc: F32, y: F32, pos: Int32, capacity: Int32):
    """Scaled q.k for positions 0 .. pos: a thread per KV head g and position t computes the 8 query heads 8g .. 8g+7
    that share it, so each cached K row is read once. Scores of head h at y[h * capacity + t]."""
    var i = global_idx.x
    var length = Int(pos) + 1
    if i < KVH * length:
        var g = i // length
        var t = i % length
        var k = kc + (t * KVW + g * HD)
        var qg = q + g * (H // KVH) * HD
        var acc = SIMD[DType.float32, 8](0)
        for d in range(0, HD, 4):
            var kv = k.load[width=4](d)
            comptime for j in range(8):
                acc[j] += (qg.load[width=4](j * HD + d) * kv).reduce_add()
        comptime for j in range(8):
            y[(8 * g + j) * Int(capacity) + t] = acc[j] * Float32(0.08838834764831845)  # 1 / sqrt(128)


def attn_values(scores: F32, vc: F32, y: F32, pos: Int32, capacity: Int32):
    """softmax(scores) V for one query head's 64 dimensions a workgroup (two a head)."""
    var sp = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var h = Int(block_idx.x) // 2
    var d = (Int(block_idx.x) % 2) * 64 + lane
    var n = Int(pos) + 1
    var s = scores + h * Int(capacity)
    var highest: Float32 = -3.402823e38
    for t0 in range(0, n, 64):
        if t0 + lane < n:
            highest = max(highest, s[t0 + lane])
    sp[lane] = highest
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] = max(sp[lane], sp[lane + (32 >> stage)])
        barrier()
    highest = sp[0]
    barrier()
    var v = vc + ((h // (H // KVH)) * HD + d)
    var total: Float32 = 0
    var value: Float32 = 0
    for t0 in range(0, n, 64):
        sp[lane] = exp(s[t0 + lane] - highest) if t0 + lane < n else 0
        barrier()
        for k in range(min(64, n - t0)):
            var p = sp[k]
            total += p
            value += p * v[(t0 + k) * KVW]
        barrier()
    y[h * HD + d] = value / total


def gemv_f32(w: F32, x: F32, y: F32, cols: Int32):
    """y[r] = W[r] . x for fp32 W (the router): a 64-lane workgroup a row."""
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var n = Int(cols)
    var acc = Float32(0)
    for j in range(t, n, 64):
        acc += w[r * n + j] * x[j]
    var s = warp_sum(acc)
    if t == 0:
        y[r] = s


def route(logits: F32, ids: I32, weights: F32):
    """The router's top 8 of 128 experts (the lowest index among equals), and their weights: softmax over the 128
    logits, the top 8 renormalized to sum 1, which is a softmax over the top 8 logits (Qwen3-MoE's
    norm_topk_prob). One 64-lane workgroup, two experts a lane."""
    var sv = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var si = stack_allocation[64, Int32, address_space=AddressSpace.SHARED]()
    var top = stack_allocation[TOPK, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var a = logits[lane]
    var b = logits[lane + 64]
    for k in range(TOPK):
        var best = a
        var bi = Int32(lane)
        if b > best:
            best = b
            bi = Int32(lane + 64)
        sv[lane] = best
        si[lane] = bi
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
            ids[k] = Int32(win)
            top[k] = sv[0]
        if win == lane:
            a = -3.402823e38
        if win == lane + 64:
            b = -3.402823e38
        barrier()
    if lane == 0:
        var m = top[0]
        var total = Float32(0)
        for k in range(TOPK):
            total += exp(top[k] - m)
        for k in range(TOPK):
            weights[k] = exp(top[k] - m) / total


def moe_gate_up(wq: U32, ws: F16, ids: I32, x: F32, a: F32):
    """a[e, j] = silu(gate[e, j]) * up[e, j], gate and up rows j and 768 + j of selected expert ids[e] (its int4 rows
    e * 1536 ..): workgroup (j, e) computes both."""
    var j = Int(block_idx.x)
    var e = Int(block_idx.y)
    var t = Int(thread_idx.x)
    var row = Int(ids[e]) * (2 * FE) + j
    var g = warp_sum(dot_q4_row[GE](wq, ws, row, D, x, t))
    var u = warp_sum(dot_q4_row[GE](wq, ws, row + FE, D, x, t))
    if t == 0:
        a[e * FE + j] = g / (1 + exp(-g)) * u


def moe_down(wq: U32, ws: F16, ids: I32, weights: F32, a: F32, x: F32):
    """x[r] += sum_e weights[e] * W_down[ids[e]][r] . a[e]: the experts' outputs, weighted, into the residual stream.
    A workgroup an output row."""
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var acc = Float32(0)
    comptime for e in range(TOPK):
        acc += weights[e] * dot_q4_row[GE](wq, ws, Int(ids[e]) * D + r, FE, a + e * FE, t)
    var s = warp_sum(acc)
    if t == 0:
        x[r] = x[r] + s


def argmax(logits: F32, n: Int32, tokens: I32, pos: Int32, write: Int32):
    """Greedy: the index of the largest logit (the lowest among equals) into tokens[pos + 1] when `write`. One
    256-thread workgroup."""
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
    if t == 0 and write != 0:
        tokens[Int(pos) + 1] = si[0]


# ---- prefill: T prompt tokens at once (rows of T) ----------------------------------------------------------------
# Every matrix row is read once and applied to all T tokens (a workgroup a row, a token at a time), so a prompt reads
# the attention weights once, and each expert's weights once, for the tokens routed to it. Positions p0 .. p0 + T - 1.


def p_rmsnorm(x: F32, w: F32, y: F32, n: Int32):
    """Row t (workgroup t): y[t] = x[t] / rms(x[t]) * w."""
    var t = Int(block_idx.x)
    var lane = Int(thread_idx.x)
    var xr = x + t * Int(n)
    var yr = y + t * Int(n)
    var ss: Float32 = 0
    for j in range(lane, Int(n), 64):
        var v = xr[j]
        ss += v * v
    var r = rsqrt(warp_sum(ss) / Float32(Int(n)) + Float32(1e-6))
    for j in range(lane, Int(n), 64):
        yr[j] = xr[j] * r * w[j]


def p_gemv_q4(wq: U32, ws: F16, x: F32, y: F32, cols: Int32, rows: Int32, tokens: Int32, add: Int32):
    """y[t, r] (+)= W[r] . x[t] for int4 W (a scale per 64), t < tokens: workgroup r reads its row once."""
    var r = Int(block_idx.x)
    var lane = Int(thread_idx.x)
    for t in range(Int(tokens)):
        var s = warp_sum(dot_q4_row[64](wq, ws, r, Int(cols), x + t * Int(cols), lane))
        if lane == 0:
            var i = t * Int(rows) + r
            y[i] = (y[i] + s) if add != 0 else s


def p_gemv_f32(w: F32, x: F32, y: F32, cols: Int32, rows: Int32, tokens: Int32):
    """y[t, r] = W[r] . x[t] for fp32 W (the router)."""
    var r = Int(block_idx.x)
    var lane = Int(thread_idx.x)
    var n = Int(cols)
    for t in range(Int(tokens)):
        var acc = Float32(0)
        for j in range(lane, n, 64):
            acc += w[r * n + j] * x[t * n + j]
        var s = warp_sum(acc)
        if lane == 0:
            y[t * Int(rows) + r] = s


def p_qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, p0: Int32):
    """qk_norm_rope for token row t (block y) at position p0 + t, head block x."""
    var h = Int(block_idx.x)
    var t = Int(block_idx.y)
    var d = Int(thread_idx.x)
    var p = Int(p0) + t
    var row = qkv + t * (H + 2 * KVH) * HD
    var base = h * HD
    var a = row[base + d]
    var b = row[base + d + 64]
    if h >= H + KVH:
        vc[p * KVW + (h - H - KVH) * HD + d] = a
        vc[p * KVW + (h - H - KVH) * HD + d + 64] = b
        return
    var w = wq if h < H else wk
    var r = rsqrt(warp_sum(a * a + b * b) / Float32(HD) + Float32(1e-6))
    a *= r * w[d]
    b *= r * w[d + 64]
    var c = table[p * HD + d]
    var s = table[p * HD + 64 + d]
    var ra = a * c - b * s
    var rb = b * c + a * s
    if h < H:
        row[base + d] = ra
        row[base + d + 64] = rb
    else:
        kc[p * KVW + (h - H) * HD + d] = ra
        kc[p * KVW + (h - H) * HD + d + 64] = rb


def p_attention(qkv: F32, kc: F32, vc: F32, y: F32, p0: Int32):
    """Causal attention of query head h (block x) of token row t (block y), at position p = p0 + t, over the cached
    keys 0 .. p (at most 512): scores into shared memory a lane a key, max and sum by shared reductions, then lane d
    sums dimensions d and d + 64 of V."""
    var sp = stack_allocation[512, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var t = Int(block_idx.y)
    var lane = Int(thread_idx.x)
    var n = Int(p0) + t + 1
    var g = h // (H // KVH)
    var q = qkv + (t * (H + 2 * KVH) * HD + h * HD)
    var highest: Float32 = -3.402823e38
    for k0 in range(0, n, 64):
        var k = k0 + lane
        if k < n:
            var kr = kc + (k * KVW + g * HD)
            var acc = SIMD[DType.float32, 4](0)
            for d in range(0, HD, 4):
                acc += q.load[width=4](d) * kr.load[width=4](d)
            var s = acc.reduce_add() * Float32(0.08838834764831845)
            sp[k] = s
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
    for k0 in range(0, n, 64):
        var k = k0 + lane
        if k < n:
            var e = exp(sp[k] - highest)
            sp[k] = e
            total += e
    red[lane] = total
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            red[lane] = red[lane] + red[lane + (32 >> stage)]
        barrier()
    total = red[0]
    var a: Float32 = 0
    var b: Float32 = 0
    var v = vc + g * HD
    for k in range(n):
        var pk = sp[k]
        a += pk * v[k * KVW + lane]
        b += pk * v[k * KVW + lane + 64]
    var out = y + (t * H * HD + h * HD)
    out[lane] = a / total
    out[lane + 64] = b / total


def p_route(logits: F32, ids: I32, weights: F32):
    """route() for token row t (workgroup t): its top 8 of 128 experts and their weights."""
    var t = Int(block_idx.x)
    var sv = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var si = stack_allocation[64, Int32, address_space=AddressSpace.SHARED]()
    var top = stack_allocation[TOPK, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var a = logits[t * 128 + lane]
    var b = logits[t * 128 + lane + 64]
    for k in range(TOPK):
        var best = a
        var bi = Int32(lane)
        if b > best:
            best = b
            bi = Int32(lane + 64)
        sv[lane] = best
        si[lane] = bi
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
            ids[t * TOPK + k] = Int32(win)
            top[k] = sv[0]
        if win == lane:
            a = -3.402823e38
        if win == lane + 64:
            b = -3.402823e38
        barrier()
    if lane == 0:
        var m = top[0]
        var total = Float32(0)
        for k in range(TOPK):
            total += exp(top[k] - m)
        for k in range(TOPK):
            weights[t * TOPK + k] = exp(top[k] - m) / total


comptime RB = 8  # rows a workgroup of the prefill's expert kernels
comptime PMAX = 256  # tokens a prefill runs at once (model.mojo's)


def p_expert_lists(ids: I32, lists: I32, counts: I32, tokens: Int32):
    """Workgroup e: the (token, slot) pairs, as t * 8 + k, whose choice k was expert e, into lists[e * PMAX ..], and
    their number into counts[e]. A token chooses an expert at most once, so a list holds at most PMAX."""
    var e = Int(block_idx.x)
    if Int(thread_idx.x) == 0:
        var n = 0
        for i in range(Int(tokens) * TOPK):
            if Int(ids[i]) == e:
                lists[e * PMAX + n] = Int32(i)
                n += 1
        counts[e] = Int32(n)


def p_moe_gate_up(wq: U32, ws: F16, lists: I32, counts: I32, x: F32, a: F32):
    """Expert e (block y), rows j = 8 * block x .. + 7: each gate and up row is read once, for the tokens that chose
    e: a[t, k, j] = silu(gate . x[t]) * (up . x[t]). An expert no token chose costs nothing."""
    var e = Int(block_idx.y)
    var lane = Int(thread_idx.x)
    var n = Int(counts[e])
    for rr in range(RB):
        var j = Int(block_idx.x) * RB + rr
        var row = e * (2 * FE) + j
        for i in range(n):  # the same for every lane: the subgroup sums stay uniform
            var tk = Int(lists[e * PMAX + i])
            var xt = x + (tk // TOPK) * D
            var g = warp_sum(dot_q4_row[GE](wq, ws, row, D, xt, lane))
            var u = warp_sum(dot_q4_row[GE](wq, ws, row + FE, D, xt, lane))
            if lane == 0:
                a[tk * FE + j] = g / (1 + exp(-g)) * u


def p_moe_down(wq: U32, ws: F16, lists: I32, counts: I32, a: F32, part: F32):
    """Expert e (block y), output rows r = 8 * block x .. + 7: each down row read once, for the tokens that chose e:
    part[t, k, r] = W_down[e][r] . a[t, k]."""
    var e = Int(block_idx.y)
    var lane = Int(thread_idx.x)
    var n = Int(counts[e])
    for rr in range(RB):
        var r = Int(block_idx.x) * RB + rr
        var row = e * D + r
        for i in range(n):
            var tk = Int(lists[e * PMAX + i])
            var s = warp_sum(dot_q4_row[GE](wq, ws, row, FE, a + tk * FE, lane))
            if lane == 0:
                part[tk * D + r] = s


def p_moe_sum(part: F32, weights: F32, x: F32, tokens: Int32):
    """x[t, r] += sum_k weights[t, k] * part[t, k, r]: the experts' outputs into the residual stream."""
    var i = global_idx.x
    if i < Int(tokens) * D:
        var t = i // D
        var r = i % D
        var acc = Float32(0)
        comptime for k in range(TOPK):
            acc += weights[t * TOPK + k] * part[(t * TOPK + k) * D + r]
        x[i] = x[i] + acc


# ---- prefill, a row a lane: 64 matrix rows x 8 tokens a workgroup ----------------------------------------------
# Each lane computes whole dot products for its own row, against 8 tokens at once: it decodes each int4 word once for
# the 8 tokens (two 4-wide accumulators), and the token values it reads are the same for every lane (broadcast
# loads). No subgroup sums. (64-wide SIMD accumulators, tried first, went to private memory: 10x slower.)

comptime TT = 8  # tokens a workgroup


@always_inline
def word4(word: UInt32, half: Int) -> SIMD[DType.float32, 4]:
    """Weights 4 * half .. + 3 of an int4 word (two's complement nibbles, low first)."""
    var w = SIMD[DType.float32, 4]()
    comptime for j in range(4):
        w[j] = Float32((Int32((word >> UInt32(4 * (4 * half + j))) & 15) ^ 8) - 8)
    return w


@always_inline
def row_tokens_q4[G: Int](wq: U32, ws: F16, row: Int, cols: Int, x: F32, xa: SIMD[DType.int32, 4],
                         xb: SIMD[DType.int32, 4], mut lo: SIMD[DType.float32, 4], mut hi: SIMD[DType.float32, 4]):
    """lo[t], hi[t - 4] += W[row] . x[o_t ..] for the 8 tokens (offsets o_0..3 in xa, o_4..7 in xb), a whole row in
    this lane."""
    var words = cols // 8
    for wi in range(words):
        var word = wq[row * words + wi]
        var sc = ws[row * (cols // G) + wi // (G // 8)].cast[DType.float32]()
        var w0 = word4(word, 0) * sc
        var w1 = word4(word, 1) * sc
        comptime for t in range(TT):
            var p = x + ((Int(xa[t]) if t < 4 else Int(xb[t - 4])) + wi * 8)
            var d = (w0 * p.load[width=4]() + w1 * (p + 4).load[width=4]()).reduce_add()
            comptime if t < 4:
                lo[t] += d
            else:
                hi[t - 4] += d


def t_gemv_q4(wq: U32, ws: F16, x: F32, y: F32, cols: Int32, rows: Int32, tokens: Int32, add: Int32):
    """y[t, r] (+)= W[r] . x[t] (int4, a scale per 64): row r = 64 * block x + lane, tokens 8 * block y .. + 7."""
    var r = Int(block_idx.x) * 64 + Int(thread_idx.x)
    var t0 = Int(block_idx.y) * TT
    var n = Int(tokens)
    var xa = SIMD[DType.int32, 4]()
    var xb = SIMD[DType.int32, 4]()
    comptime for t in range(4):
        xa[t] = Int32(min(t0 + t, n - 1) * Int(cols))
        xb[t] = Int32(min(t0 + 4 + t, n - 1) * Int(cols))
    var lo = SIMD[DType.float32, 4](0)
    var hi = SIMD[DType.float32, 4](0)
    row_tokens_q4[64](wq, ws, r, Int(cols), x, xa, xb, lo, hi)
    comptime for t in range(TT):
        if t0 + t < n:
            var i = (t0 + t) * Int(rows) + r
            var v = lo[t] if t < 4 else hi[t - 4]
            y[i] = (y[i] + v) if add != 0 else v


def p_expert_items(counts: I32, items: I32, nitems: I32):
    """The experts' (expert, first list entry) work items of 8 tokens each, in order: one lane."""
    if Int(thread_idx.x) == 0:
        var n = 0
        for e in range(128):
            for c in range(0, Int(counts[e]), TT):
                items[2 * n] = Int32(e)
                items[2 * n + 1] = Int32(c)
                n += 1
        nitems[0] = Int32(n)


def t_moe_gate_up(wq: U32, ws: F16, items: I32, nitems: I32, lists: I32, counts: I32, x: F32, a: F32):
    """Work item block y (expert e, its list entries c .. c + 7), j = 64 * block x + lane: gate row j and up row j
    against the 8 tokens' x, then a[t, k, j] = silu(gate) * up."""
    var it = Int(block_idx.y)
    if it >= Int(nitems[0]):
        return
    var e = Int(items[2 * it])
    var c = Int(items[2 * it + 1])
    var n = Int(counts[e])
    var j = Int(block_idx.x) * 64 + Int(thread_idx.x)
    var xa = SIMD[DType.int32, 4]()
    var xb = SIMD[DType.int32, 4]()
    comptime for t in range(4):
        xa[t] = Int32((Int(lists[e * PMAX + min(c + t, n - 1)]) // TOPK) * D)
        xb[t] = Int32((Int(lists[e * PMAX + min(c + 4 + t, n - 1)]) // TOPK) * D)
    var glo = SIMD[DType.float32, 4](0)
    var ghi = SIMD[DType.float32, 4](0)
    var ulo = SIMD[DType.float32, 4](0)
    var uhi = SIMD[DType.float32, 4](0)
    row_tokens_q4[GE](wq, ws, e * 2 * FE + j, D, x, xa, xb, glo, ghi)
    row_tokens_q4[GE](wq, ws, e * 2 * FE + FE + j, D, x, xa, xb, ulo, uhi)
    comptime for t in range(TT):
        if c + t < n:
            var g = glo[t] if t < 4 else ghi[t - 4]
            var u = ulo[t] if t < 4 else uhi[t - 4]
            a[Int(lists[e * PMAX + c + t]) * FE + j] = g / (1 + exp(-g)) * u


def t_moe_down(wq: U32, ws: F16, items: I32, nitems: I32, lists: I32, counts: I32, a: F32, part: F32):
    """Work item block y (expert e, list entries c .. c + 7), output row r = 64 * block x + lane:
    part[t, k, r] = W_down[e][r] . a[t, k]."""
    var it = Int(block_idx.y)
    if it >= Int(nitems[0]):
        return
    var e = Int(items[2 * it])
    var c = Int(items[2 * it + 1])
    var n = Int(counts[e])
    var r = Int(block_idx.x) * 64 + Int(thread_idx.x)
    var xa = SIMD[DType.int32, 4]()
    var xb = SIMD[DType.int32, 4]()
    comptime for t in range(4):
        xa[t] = Int32(Int(lists[e * PMAX + min(c + t, n - 1)]) * FE)
        xb[t] = Int32(Int(lists[e * PMAX + min(c + 4 + t, n - 1)]) * FE)
    var lo = SIMD[DType.float32, 4](0)
    var hi = SIMD[DType.float32, 4](0)
    row_tokens_q4[GE](wq, ws, e * D + r, FE, a, xa, xb, lo, hi)
    comptime for t in range(TT):
        if c + t < n:
            part[Int(lists[e * PMAX + c + t]) * D + r] = lo[t] if t < 4 else hi[t - 4]
