# llama/kernels/prefill's p_gemm_q4 with int8 W, as g4k's gemv[True] reads it: n x k weights, 4 per 32-bit word (low
# byte first, signed -127..127) and an fp16 scale per 64 weights of a row. The same blocks as p_gemm_q4 (a 256-thread
# workgroup, 2 x 2 subgroups, computes a 128 x 128 block of Y; K steps of 16; fp32 cooperative matrices, 64 x 64 x 8),
# but W's slice per K step is 2 words a thread: row t / 2, weights 8 (t % 2) .. 8 (t % 2) + 7 of the step.
# X: rows x k fp32 activations, Y: rows x n fp32. rows, n and k: multiples of 128, 128 and 16.
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime BM = 128
comptime BN = 128
comptime BK = 16
comptime K = 8  # the 840's fp32 product: 64 x 64 x 8
comptime THREADS = 256
comptime G = 64  # weights per scale


def p_gemm_q8(wq: UnsafePointer[UInt32, MutAnyOrigin], ws: UnsafePointer[Float16, MutAnyOrigin],
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
    var wr = t // (BK // 8)  # the two words of W's slice this thread unpacks: row wr, weights wc .. wc + 7
    var wc = t % (BK // 8) * 8
    comptime assert BN * BK // 8 == THREADS, "8 weights of W per thread"
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for k0 in range(0, ldx, BK):
        comptime for i in range(BM * BK // 4 // THREADS):
            var v = i * THREADS + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            sa.unsafe_store(r * BK + c, x.unsafe_load[width=4]((row0 + r) * ldx + k0 + c))
        var base = (col0 + wr) * (ldx // 4) + (k0 + wc) // 4
        var scale = ws[(col0 + wr) * (ldx // G) + (k0 + wc) // G].cast[DType.float32]()
        comptime for h in range(2):
            var word = wq[base + h]
            comptime for j in range(4):
                var q = Int32((word >> UInt32(8 * j)) & 255) ^ 128
                sb.unsafe_store(wr * BK + wc + h * 4 + j, Float32(q - 128) * scale)
        barrier()
        comptime for kk in range(0, BK, K):
            var at = CoopMatrix[DType.float32, 64, K, MATRIX_A].load(sa.unsafe_offset(sr * BK + kk), BK)
            var bt = CoopMatrix[DType.float32, K, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(sc * BK + kk), BK)
            acc = at.multiply_add(bt, acc)
        barrier()
    acc.store(out, ldy)
