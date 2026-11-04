# Qwen3-8B batched prefill kernels for qwen3/model.mojo's Qwen3.prefill: every prompt row at once, row r
# at block_idx.y = r and position r. The projections are bonsai/kernels/prefill.mojo's p_gemm_t2 (fp32
# rows times the packed ternary weights on cooperative matrices), so the norm, SwiGLU and residual here
# work on fp32 rows. q/k norm with RoPE shares qwen3k's decode kernel's body; attention is on the matrix
# units too, for all rows at once: p_scores_mma (Q K^T), p_softmax, p_values_mma (P V). Rows past `count`
# (the prompt padded to the matmul's 128 rows) write nothing to the KV cache, and their attention is zero.
from std.math import exp, rsqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

import qwen3k

comptime F32 = Pointer[Float32, MutAnyOrigin]
comptime D = 4096
comptime QKV = 6144
comptime F = 12288


def p_rmsnorm(x: F32, w: F32, y: F32):
    """y = rmsnorm(x) * w in fp32, as rmsnorm_pack computes it: one 64-lane workgroup a row."""
    var row = Int(block_idx.y) * D
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(0, D, 128):
        var a = x[unsafe_offset=row + j + 2 * lane]
        var b = x[unsafe_offset=row + j + 2 * lane + 1]
        ss += a * a + b * b
    var r = rsqrt(qwen3k.lane_sum(ss) / Float32(D) + Float32(1e-6))
    for j in range(0, D, 128):
        var i = j + 2 * lane
        y[unsafe_offset=row + i] = x[unsafe_offset=row + i] * r * w[unsafe_offset=i]
        y[unsafe_offset=row + i + 1] = x[unsafe_offset=row + i + 1] * r * w[unsafe_offset=i + 1]


def p_qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, count: Int32):
    """qk_norm_rope for every row; then q is scaled by 1 / sqrt(128), the attention scale p_scores_mma leaves
    out (attn_scores applies it to each score instead)."""
    var row = Int(block_idx.y)
    if row < Int(count):
        qwen3k._qk_norm_rope(qkv.unsafe_offset(row * QKV), wq, wk, table, kc, vc, Int32(row))
        var h = global_idx.x // 64
        if h < 32:  # this lane's own two q values
            var i = row * QKV + h * 128 + global_idx.x % 64
            qkv[unsafe_offset=i] *= Float32(0.08838834764831845)
            qkv[unsafe_offset=i + 64] *= Float32(0.08838834764831845)


def p_scores_mma(qkv: F32, kc: F32, y: F32, capacity: Int32):
    """attn_scores for every row at once, on the matrix units: for head block_idx.y and the 64 rows from 64
    block_idx.x, S = Q K^T for every 64 cached positions up to the diagonal (Bonsai's p_scores_mma, for
    Qwen3's heads of 128 and four query heads a KV head). K is read column-major straight from the KV
    cache; S goes to the rows' scores as attn_scores leaves them. Tiles past a row's position hold
    values attn_values never reads."""
    var h = Int(block_idx.y)
    var i0 = Int(block_idx.x) * 64
    var ld = 32 * Int(capacity)
    for j0 in range(0, i0 + 64, 64):
        var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
        comptime for k in range(0, 128, 8):  # the 840's fp32 product: 64 x 64 x 8
            var at = CoopMatrix[DType.float32, 64, 8, MATRIX_A].load(qkv.unsafe_offset(i0 * QKV + h * 128 + k), QKV)
            var bt = CoopMatrix[DType.float32, 8, 64, MATRIX_B].load[row_major=False](
                kc.unsafe_offset(j0 * 1024 + (h // 4) * 128 + k), 1024)
            acc = at.multiply_add(bt, acc)
        acc.store(y.unsafe_offset(i0 * ld + h * Int(capacity) + j0), ld)


def p_softmax(scores: F32, count: Int32, capacity: Int32):
    """Head block_idx.x's scores of row block_idx.y, in place, to probabilities: positions 0 .. row, then zeros
    to the end of the row's 64-row tile, which p_values_mma reads whole. Padding rows get zeros only. The
    max and the sum are shared-memory reductions, as in qwen3k.attn_values."""
    var sp = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var row = Int(block_idx.y)
    var s = scores.unsafe_offset(row * 32 * Int(capacity) + Int(block_idx.x) * Int(capacity))
    var n = row + 1 if row < Int(count) else 0
    var highest: Float32 = -3.402823e38
    for t0 in range(0, n, 64):
        if t0 + lane < n:
            highest = max(highest, s[unsafe_offset=t0 + lane])
    sp[lane] = highest
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] = max(sp[lane], sp[lane + (32 >> stage)])
        barrier()
    highest = sp[0]
    barrier()
    var total: Float32 = 0
    for t0 in range(0, n, 64):  # each lane keeps its own positions, so it rereads only what it wrote
        if t0 + lane < n:
            var p = exp(s[unsafe_offset=t0 + lane] - highest)
            s[unsafe_offset=t0 + lane] = p
            total += p
    sp[lane] = total
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] += sp[lane + (32 >> stage)]
        barrier()
    var r = 1 / sp[0]
    for t0 in range(0, (row // 64 + 1) * 64, 64):
        var t = t0 + lane
        s[unsafe_offset=t] = s[unsafe_offset=t] * r if t < n else 0


def p_values_mma(p: F32, vc: F32, y: F32, capacity: Int32):
    """Attention output for the 64 rows from 64 block_idx.x and half block_idx.y % 2 of head block_idx.y // 2:
    P V on the matrix units, P p_softmax's probabilities for every position to the end of the rows' tile
    (zero past each row's own), V straight from the cache. Positions past the prompt in that tile read the
    cache's zeros (Qwen3 clears it), never NaN."""
    var h = Int(block_idx.y) // 2
    var i0 = Int(block_idx.x) * 64
    var ld = 32 * Int(capacity)
    var col = h * 128 + (Int(block_idx.y) % 2) * 64
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for t0 in range(0, i0 + 64, 8):  # the 840's fp32 product: 64 x 64 x 8
        var a = CoopMatrix[DType.float32, 64, 8, MATRIX_A].load(p.unsafe_offset(i0 * ld + h * Int(capacity) + t0), ld)
        var b = CoopMatrix[DType.float32, 8, 64, MATRIX_B].load(
            vc.unsafe_offset(t0 * 1024 + (h // 4) * 128 + (Int(block_idx.y) % 2) * 64), 1024)
        acc = a.multiply_add(b, acc)
    acc.store(y.unsafe_offset(i0 * D + col), D)


def p_add(x: F32, y: F32):
    var i = Int(block_idx.y) * D + global_idx.x
    x[unsafe_offset=i] += y[unsafe_offset=i]


def p_swiglu(gu: F32, a: F32):
    """a = silu(gate) * up in fp32; a row of gu is gate (F) | up (F)."""
    var row = Int(block_idx.y)
    var i = global_idx.x
    var g = gu[unsafe_offset=row * 2 * F + i]
    a[unsafe_offset=row * F + i] = g / (1 + exp(-g)) * gu[unsafe_offset=row * 2 * F + F + i]
