# p_gemm with int4 W, as gemv_q4 reads it: n x k weights, 8 per 32-bit word (low nibble first, signed
# -8..7) and an fp16 scale per 64 weights of a row. Each thread unpacks one word of W's slice per K step
# into fp32 in shared memory; the rest, fp32 cooperative matrices on X and the dequantized W, is p_gemm.
# X: rows x k fp32 activations, Y: rows x n fp32.
# Built for adreno840 (KHR cooperative matrices, fp32 x fp32 -> fp32, 64 x 64 x 8). A 256-thread
# workgroup (2 x 2 subgroups) computes a 128 x 128 block of Y: per K step of 16 it stages X's slice
# and W's slice, converted to fp32, in shared memory, each copied 4 elements per thread with
# consecutive threads on consecutive addresses; W's slice keeps its layout, rows of W, so B = W^T is
# read from it column-major. Each subgroup multiplies its 64 x 64 tile from there. (A K step of 32
# fills the 840's 32 KB of shared memory exactly, and gave wrong results.) rows, n and k: multiples
# of 128, 128 and 16.
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
comptime G = 64  # weights per scale


def p_gemm_q4(wq: UnsafePointer[UInt32, MutAnyOrigin], ws: UnsafePointer[Float16, MutAnyOrigin],
              x: UnsafePointer[Float32, MutAnyOrigin], y: UnsafePointer[Float32, MutAnyOrigin], n: Int64,
              k: Int64):
    var sa = stack_allocation[BM * BK, Float32, address_space=AddressSpace.SHARED]()  # X: BM rows of BK
    var sb = stack_allocation[BN * BK, Float32, address_space=AddressSpace.SHARED]()  # W: BN rows of BK
    var ldy = Int(n)
    var ldx = Int(k)
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * BM
    var col0 = Int(block_idx.x) * BN
    var sr = (sg // 2) * 64  # this subgroup's tile of the block
    var sc = (sg % 2) * 64
    var out = y.unsafe_offset((row0 + sr) * ldy + col0 + sc)
    var wr = t // (BK // 8)  # the word of W's slice this thread unpacks: row wr, words wc .. wc + 8
    var wc = t % (BK // 8) * 8
    comptime assert BN * BK // 8 == THREADS, "one word of W per thread"
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for k0 in range(0, ldx, BK):
        comptime for i in range(BM * BK // 4 // THREADS):
            var v = i * THREADS + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            sa.unsafe_store(r * BK + c, x.unsafe_load[width=4]((row0 + r) * ldx + k0 + c))
        var word = wq[(col0 + wr) * (ldx // 8) + (k0 + wc) // 8]
        var scale = ws[(col0 + wr) * (ldx // G) + (k0 + wc) // G].cast[DType.float32]()
        comptime for j in range(8):
            var q = Int32((word >> UInt32(4 * j)) & 15) ^ 8
            sb.unsafe_store(wr * BK + wc + j, Float32(q - 8) * scale)
        barrier()
        comptime for kk in range(0, BK, K):
            var at = CoopMatrix[DType.float32, 64, K, MATRIX_A].load(sa.unsafe_offset(sr * BK + kk), BK)
            var bt = CoopMatrix[DType.float32, K, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(sc * BK + kk), BK)
            acc = at.multiply_add(bt, acc)
        barrier()
    acc.store(out, ldy)


def main() raises:
    var ctx = DeviceContext()
    var wq = ctx.enqueue_create_buffer[DType.uint32](2048 * 256)
    var ws = ctx.enqueue_create_buffer[DType.float16](2048 * 32)
    var x = ctx.enqueue_create_buffer[DType.float32](128 * 2048)
    var y = ctx.enqueue_create_buffer[DType.float32](128 * 2048)
    ctx.enqueue_function[p_gemm_q4](wq, ws, x, y, Int64(2048), Int64(2048), grid_dim=(16, 1), block_dim=THREADS)
    ctx.synchronize()
