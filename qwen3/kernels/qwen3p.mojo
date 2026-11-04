# Qwen3-8B batched prefill kernels for qwen3/model.mojo's Qwen3.prefill: every prompt row at once, row r
# at block_idx.y = r and position r. The projections are bonsai/kernels/prefill.mojo's p_gemm_t2 (fp32
# rows times the packed ternary weights on cooperative matrices), so the norm, SwiGLU and residual here
# work on fp32 rows; q/k norm with RoPE and attention share qwen3k's decode kernels' bodies. Rows past `count`
# (the prompt padded to the matmul's 128 rows) skip the steps that write the KV cache or read it.
from std.math import exp, rsqrt
from max.gpu import block_idx, global_idx, thread_idx

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
    var row = Int(block_idx.y)
    if row < Int(count):
        qwen3k._qk_norm_rope(qkv.unsafe_offset(row * QKV), wq, wk, table, kc, vc, Int32(row))


def p_attn_scores(qkv: F32, kc: F32, y: F32, count: Int32, capacity: Int32):
    var row = Int(block_idx.y)
    if row < Int(count):
        qwen3k._attn_scores(qkv.unsafe_offset(row * QKV), kc, y.unsafe_offset(row * 32 * Int(capacity)), Int32(row),
                           capacity)


def p_attn_values(scores: F32, vc: F32, y: F32, count: Int32, capacity: Int32):
    var row = Int(block_idx.y)
    if row < Int(count):
        qwen3k._attn_values(scores.unsafe_offset(row * 32 * Int(capacity)), vc, y.unsafe_offset(row * D), Int32(row),
                           capacity)


def p_add(x: F32, y: F32):
    var i = Int(block_idx.y) * D + global_idx.x
    x[unsafe_offset=i] += y[unsafe_offset=i]


def p_swiglu(gu: F32, a: F32):
    """a = silu(gate) * up in fp32; a row of gu is gate (F) | up (F)."""
    var row = Int(block_idx.y)
    var i = global_idx.x
    var g = gu[unsafe_offset=row * 2 * F + i]
    a[unsafe_offset=row * F + i] = g / (1 + exp(-g)) * gu[unsafe_offset=row * 2 * F + F + i]
