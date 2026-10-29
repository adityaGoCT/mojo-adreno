# Prefill attention, fused: causal grouped-query attention for a block of 64 prompt tokens per
# workgroup (one 64-thread subgroup per head and query block, grid heads x tokens/64), with the two
# matrix products on KHR cooperative matrices (fp32, 64 x 64 x 8; built for adreno840).
#
# For each block of 64 keys up to the diagonal, S = Q K^T comes from 8 multiply-adds (K read
# column-major straight from the KV cache) and goes to shared memory, where each thread owns one
# query row: a first pass over the key blocks finds each row's softmax max and sum, a second
# recomputes S, turns it into probabilities P (scaled, causally masked) and accumulates O += P V on
# the matrix units. Recomputing Q K^T (1.5x its flops) keeps O a cooperative matrix that never needs
# rescaling, which an opaque matrix cannot do row by row.
from max.gpu import barrier, block_idx, thread_idx
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR
from std.math import exp
from std.memory import stack_allocation

comptime H = 32
comptime KVH = 8
comptime HD = 64
comptime MAXPOS = 512
comptime QKV = (H + 2 * KVH) * HD
comptime D = H * HD
comptime BQ = 64  # queries per workgroup: the 840's matrix M
comptime BK = 64  # keys per block
comptime K = 8  # the 840's fp32 product: 64 x 64 x 8
comptime SCALE: Float32 = 0.125  # 1 / sqrt(HD)


def p_attention(qkv: UnsafePointer[Float32, MutAnyOrigin], kc: UnsafePointer[Float32, MutAnyOrigin],
                vc: UnsafePointer[Float32, MutAnyOrigin], y: UnsafePointer[Float32, MutAnyOrigin]):
    var s = stack_allocation[BQ * BK, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var qb = Int(block_idx.y)
    var r = Int(thread_idx.x)  # this thread's query row in the block
    var q0 = qb * BQ
    var qpos = q0 + r
    var kv = (h // (H // KVH)) * MAXPOS

    # Pass 0: each row's running max and sum of exp. Pass 1: P = softmax(S) block by block, and
    # O += P V on the matrix units. Each recomputes S = Q K^T for key block j into s (row-major).
    # Threads walk their row starting at their own column, so the 64 threads hit different banks.
    var m = Float32(-1e30)
    var l = Float32(0)
    var inv = Float32(0)
    var o = CoopMatrix[DType.float32, BQ, HD, ACCUMULATOR].zero()
    comptime for pass_ in range(2):
        comptime if pass_ == 1:
            inv = 1.0 / l
        for j in range(qb + 1):
            var acc = CoopMatrix[DType.float32, BQ, BK, ACCUMULATOR].zero()
            comptime for d in range(0, HD, K):
                var q = CoopMatrix[DType.float32, BQ, K, MATRIX_A].load(
                    qkv.unsafe_offset(q0 * QKV + h * HD + d), QKV)
                var kt = CoopMatrix[DType.float32, K, BK, MATRIX_B].load[row_major=False](
                    kc.unsafe_offset((kv + j * BK) * HD + d), HD)
                acc = q.multiply_add(kt, acc)
            barrier()  # the previous block's P has been read
            acc.store(s, BK)
            barrier()
            for i in range(BK):
                var c = (i + r) % BK
                var visible = j * BK + c <= qpos
                comptime if pass_ == 0:
                    if visible:
                        var v = s.unsafe_load(r * BK + c) * SCALE
                        if v > m:
                            l = l * exp(m - v) + 1.0
                            m = v
                        else:
                            l += exp(v - m)
                else:
                    var p = Float32(0)
                    if visible:
                        p = exp(s.unsafe_load(r * BK + c) * SCALE - m) * inv
                    s.unsafe_store(r * BK + c, p)
            comptime if pass_ == 1:
                barrier()
                comptime for kk in range(0, BK, K):
                    var pt = CoopMatrix[DType.float32, BQ, K, MATRIX_A].load(s.unsafe_offset(kk), BK)
                    var vt = CoopMatrix[DType.float32, K, HD, MATRIX_B].load(
                        vc.unsafe_offset((kv + j * BK + kk) * HD), HD)
                    o = pt.multiply_add(vt, o)
    o.store(y.unsafe_offset(q0 * D + h * HD), D)


def main() raises:
    var ctx = DeviceContext()
    var qkv = ctx.enqueue_create_buffer[DType.float32](128 * QKV)
    var kc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    var vc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    var o = ctx.enqueue_create_buffer[DType.float32](128 * D)
    ctx.enqueue_function[p_attention](qkv, kc, vc, o, grid_dim=(H, 2), block_dim=BQ)
    ctx.synchronize()
