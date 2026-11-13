# Qwen3-4B kernels beyond what it reuses. The model runs on three existing kernel files:
#   lfm2/kernels/lk.mojo      int4 (Q4_0) gemv / gate-up / matrix-unit gemm, the Q6_K embedding and tied head, SiLU
#                             product, argmax
#   qwen3/kernels/qwen3k.mojo Qwen3's attention for one token: q/k head norms + RoPE + K/V cache writes
#                             (qk_norm_rope), scores and values (attn_scores, attn_values); Qwen3-4B has Qwen3-8B's
#                             attention shapes (32 query and 8 KV heads of 128), only its hidden size differs
#   gemma4/kernels/g4k.mojo   prefill attention on the matrix units from any position (qwen3p's three kernels,
#                             generalized: p_scores_mma, p_softmax, p_values_mma)
# Here: the residual add + RMS norm with Qwen3's eps (lk's has LFM2's 1e-5), the prefill rows' q/k norm + RoPE from
# position p0 (qwen3p's starts at 0), and one token's attention in chunks of positions (below), for long contexts.
from std.math import exp, rsqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.primitives.warp import sum as warp_sum, shuffle_xor

import qwen3k

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]

comptime EPS = Float32(1e-6)
comptime QKV = 6144  # q (32 x 128) | k (8 x 128) | v (8 x 128)
comptime SCALE = Float32(0.08838834764831845)  # 1 / sqrt(128)


def add_norm(x: F32, y: F32, w: F32, xn: F32, n: Int32, add: Int32):
    """Row t (workgroup t): [x += y if add], then xn = x / rms(x) * w (Qwen3RMSNorm, eps 1e-6)."""
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


def p_qk_norm_rope(qkv: qwen3k.F32, wq: qwen3k.F32, wk: qwen3k.F32, table: qwen3k.F32, kc: qwen3k.F32,
                   vc: qwen3k.F32, p0: Int32):
    """qwen3k's qk_norm_rope for row block_idx.y of a prefill batch, at position p0 + row (48 workgroups of 64 a row:
    q heads, k heads, v heads); then q times 1 / sqrt(128), the scale the matrix-unit scores (g4k.p_scores_mma)
    leave out."""
    var row = Int(block_idx.y)
    qwen3k._qk_norm_rope(qkv.unsafe_offset(row * QKV), wq, wk, table, kc, vc, Int32(Int(p0) + row))
    var h = global_idx.x // 64
    if h < 32:  # this lane's own two q values
        var i = row * QKV + h * 128 + global_idx.x % 64
        qkv[unsafe_offset=i] *= SCALE
        qkv[unsafe_offset=i + 64] *= SCALE


# ---- decode attention in chunks of positions (flash-decoding) --------------------------------------------------------
# qwen3k.attn_values gives each query head's half its own workgroup, which walks every cached position in turn: 64
# workgroups and a chain as long as the context, and qwen3k.attn_scores has each lane read its own K row (64 rows of
# 512 bytes a load instruction). At 1,100 positions the two cost 11-22 ms a token. Here a workgroup takes 32 positions
# of one KV head for its 4 query heads (each K and V row read once, coalesced): their scores, the chunk's softmax
# numerators against the chunk's own maximum, and P V; attn_combine then rescales the chunks to the common maximum.
# 5-6 ms a token at 1,100 positions: the K/V cache's 317 MB at the weights' ~58 GB/s.

comptime NQ = 4  # query heads a KV head
comptime CH = 32  # positions a chunk


def attn_part(qkv: F32, kc: F32, vc: F32, pv: F32, pm: F32, pos: Int32):
    """KV head g = block_idx.x, chunk c = block_idx.y (positions 32 c .. min(32 c + 31, pos)): for each of its query
    heads h = 4 g + j, the chunk's highest score m (pm[c, h]), the sum of exp(s - m) (pm[c, 32 + h]) and
    sum exp(s - m) V (pv[c, h, :]); scores are q . k / sqrt(128), q as qwen3k.qk_norm_rope leaves it. A K row is read
    by 16 lanes together (8 of its 128 floats each: two coalesced 256-byte loads, then a shuffle sum over the 16), four
    positions at a time; for the values lane d takes dimensions d and d + 64."""
    var sq = stack_allocation[NQ * 128, Float32, address_space=AddressSpace.SHARED]()
    var ss = stack_allocation[NQ * CH, Float32, address_space=AddressSpace.SHARED]()
    var g = Int(block_idx.x)
    var c = Int(block_idx.y)
    var lane = Int(thread_idx.x)
    var t0 = c * CH
    var n = min(CH, Int(pos) + 1 - t0)
    for i in range(lane, NQ * 128, 64):
        sq[i] = qkv[g * NQ * 128 + i]
    barrier()
    var grp = lane // 16
    var l = lane % 16
    var q0 = sq.load[width=8](l * 8)
    var q1 = sq.load[width=8](128 + l * 8)
    var q2 = sq.load[width=8](256 + l * 8)
    var q3 = sq.load[width=8](384 + l * 8)
    for i in range(CH // 4):  # every lane the same number of passes: the shuffles stay outside the guard
        var t = i * 4 + grp
        var kv = SIMD[DType.float32, 8](0)
        if t < n:
            kv = (kc + ((t0 + t) * 1024 + g * 128 + l * 8)).load[width=8]()
        var d0 = (q0 * kv).reduce_add()
        var d1 = (q1 * kv).reduce_add()
        var d2 = (q2 * kv).reduce_add()
        var d3 = (q3 * kv).reduce_add()
        comptime for stage in range(4):
            d0 += shuffle_xor(d0, UInt32(1 << stage))
            d1 += shuffle_xor(d1, UInt32(1 << stage))
            d2 += shuffle_xor(d2, UInt32(1 << stage))
            d3 += shuffle_xor(d3, UInt32(1 << stage))
        if l == 0:
            var bad = Float32(-3.402823e38)
            ss[t] = d0 * SCALE if t < n else bad
            ss[CH + t] = d1 * SCALE if t < n else bad
            ss[2 * CH + t] = d2 * SCALE if t < n else bad
            ss[3 * CH + t] = d3 * SCALE if t < n else bad
    barrier()
    # each head's maximum over the chunk (every lane reads all 4 x 32 scores), then the numerators exp(s - m)
    var m = SIMD[DType.float32, NQ](-3.402823e38)
    comptime for j in range(NQ):
        for t in range(CH):
            m[j] = max(m[j], ss[j * CH + t])
    barrier()
    var tot = SIMD[DType.float32, NQ](0)
    if lane < CH:
        comptime for j in range(NQ):
            var p = exp(ss[j * CH + lane] - m[j]) if lane < n else Float32(0)
            ss[j * CH + lane] = p
    barrier()
    var vb = vc + (t0 * 1024 + g * 128 + lane)
    var a0 = SIMD[DType.float32, NQ](0)
    var a1 = SIMD[DType.float32, NQ](0)
    for t in range(n):
        var v0 = vb[t * 1024]
        var v1 = vb[t * 1024 + 64]
        comptime for j in range(NQ):
            var p = ss[j * CH + t]
            tot[j] += p
            a0[j] += p * v0
            a1[j] += p * v1
    comptime for j in range(NQ):
        var h = g * NQ + j
        pv[(c * 32 + h) * 128 + lane] = a0[j]
        pv[(c * 32 + h) * 128 + 64 + lane] = a1[j]
    if lane == 0:
        comptime for j in range(NQ):
            pm[c * 64 + g * NQ + j] = m[j]
            pm[c * 64 + 32 + g * NQ + j] = tot[j]


def attn_combine(pv: F32, pm: F32, y: F32, pos: Int32):
    """Query head h = block_idx.x: y[h, :] = sum_c exp(m_c - M) pv[c, h, :] / sum_c exp(m_c - M) l_c over the chunks
    attn_part wrote (m_c = pm[c, h], l_c = pm[c, 32 + h], M their highest). Lane d: dimensions d and d + 64."""
    var h = Int(block_idx.x)
    var lane = Int(thread_idx.x)
    var nc = Int(pos) // CH + 1
    var hi: Float32 = -3.402823e38
    for c in range(nc):
        hi = max(hi, pm[c * 64 + h])
    var total: Float32 = 0
    var o0: Float32 = 0
    var o1: Float32 = 0
    for c in range(nc):
        var w = exp(pm[c * 64 + h] - hi)
        total += w * pm[c * 64 + 32 + h]
        o0 += w * pv[(c * 32 + h) * 128 + lane]
        o1 += w * pv[(c * 32 + h) * 128 + 64 + lane]
    y[h * 128 + lane] = o0 / total
    y[h * 128 + 64 + lane] = o1 / total
