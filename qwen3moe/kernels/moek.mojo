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
