# Prefill matmul for all prompt tokens at once: Y = X W^T (p_add adds a residual: the 840's driver
# fails to create the pipeline, VK_ERROR_UNKNOWN, when the accumulator starts as a matrix loaded from Y).
# X: rows x k fp32 activations, W: n x k fp16 weights (row-major, as gemv reads them), Y: rows x n fp32.
# Built for adreno840 (KHR cooperative matrices, fp32 x fp32 -> fp32, 64 x 64 x 8). A 256-thread
# workgroup (2 x 2 subgroups) computes a 128 x 128 block of Y: per K step of 16 it stages X's slice
# (copied 4 elements per thread) and W's slice, converted to fp32 and transposed, in shared memory;
# each subgroup multiplies its 64 x 64 tile from there. rows, n and k: multiples of 128, 128 and 16.
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, thread_idx
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime BM = 128
comptime BN = 128
comptime BK = 16
comptime K = 8  # the 840's fp32 product: 64 x 64 x 8
comptime THREADS = 256


def p_gemm(w: UnsafePointer[Float16, MutAnyOrigin], x: UnsafePointer[Float32, MutAnyOrigin],
           y: UnsafePointer[Float32, MutAnyOrigin], n: Int64, k: Int64):
    var sa = stack_allocation[BM * BK, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[BK * BN, Float32, address_space=AddressSpace.SHARED]()
    var ldy = Int(n)
    var ldx = Int(k)
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * BM
    var col0 = Int(block_idx.x) * BN
    var sr = (sg // 2) * 64  # this subgroup's tile of the block
    var sc = (sg % 2) * 64
    var out = y.unsafe_offset((row0 + sr) * ldy + col0 + sc)
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    var bn = t % BN  # W's slice: this thread converts W[col0 + bn, k0 + kh .. k0 + kh + 8]
    var kh = t // BN * 8
    for k0 in range(0, ldx, BK):
        comptime for i in range(BM * BK // 4 // THREADS):
            var v = i * THREADS + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            sa.unsafe_store(r * BK + c, x.unsafe_load[width=4]((row0 + r) * ldx + k0 + c))
        var wrow = (col0 + bn) * ldx + k0 + kh
        comptime for j in range(2):
            var h = w.unsafe_load[width=4](wrow + j * 4).cast[DType.float32]()
            comptime for e in range(4):
                sb[(kh + j * 4 + e) * BN + bn] = h[e]
        barrier()
        comptime for kk in range(0, BK, K):
            var at = CoopMatrix[DType.float32, 64, K, MATRIX_A].load(sa.unsafe_offset(sr * BK + kk), BK)
            var bt = CoopMatrix[DType.float32, K, 64, MATRIX_B].load(sb.unsafe_offset(kk * BN + sc), BN)
            acc = at.multiply_add(bt, acc)
        barrier()
    acc.store(out, ldy)


def main() raises:
    var ctx = DeviceContext()
    var w = ctx.enqueue_create_buffer[DType.float16](2048 * 2048)
    var x = ctx.enqueue_create_buffer[DType.float32](128 * 2048)
    var y = ctx.enqueue_create_buffer[DType.float32](128 * 2048)
    ctx.enqueue_function[p_gemm](w, x, y, Int64(2048), Int64(2048), grid_dim=(16, 1), block_dim=THREADS)
    ctx.synchronize()
