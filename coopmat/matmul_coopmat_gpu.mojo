# Matmul with KHR cooperative matrices (SPV_KHR_cooperative_matrix), compiled by Mojo's own SPIR-V target:
#   mojo build --emit asm --target-accelerator adreno840 ...   (see coopmat/check.sh)
# One subgroup of 64 per M x N tile of C, in the shapes the Adreno 840's driver offers
# (coopmat/vk_coopmat_probe.c on a Galaxy S26 Ultra): M = 64, N = 16, 32 or 64, and
#   fp32 x fp32 -> fp32 with K = 8,  fp16 x fp16 -> fp16 with K = 16  (no fp16 x fp16 -> fp32).
# N comes from `-D COOPMAT_N=...` (coopmat/check.sh); coopmat/run_coopmat.py runs the kernels on a
# phone and checks them against NumPy.
from std.memory import stack_allocation
from std.sys import get_defined_int
from max.gpu import barrier, block_idx, thread_idx
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime M = 64
comptime N = get_defined_int["COOPMAT_N", 64]()
# The staged kernels: a workgroup of WM x WN subgroups computes a (64 WM) x (64 WN) block of C from
# slices of A and B that it copies to shared memory once per K step (-D COOPMAT_WM, -D COOPMAT_WN).
comptime WM = get_defined_int["COOPMAT_WM", 2]()
comptime WN = get_defined_int["COOPMAT_WN", 2]()
comptime THREADS = 64 * WM * WN
comptime F16_SMEM_QUIRK = get_defined_int["COOPMAT_F16_SMEM_QUIRK", 1]() == 1


def matmul_coopmat_f32(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
                       c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    # C = A x B, all n x n row-major, in fp32.
    comptime K = 8
    var dim = Int(n)
    var row = Int(block_idx.y) * M
    var col = Int(block_idx.x) * N
    var acc = CoopMatrix[DType.float32, M, N, ACCUMULATOR].zero()
    for k in range(0, dim, K):
        var at = CoopMatrix[DType.float32, M, K, MATRIX_A].load(a.unsafe_offset(row * dim + k), dim)
        var bt = CoopMatrix[DType.float32, K, N, MATRIX_B].load(b.unsafe_offset(k * dim + col), dim)
        acc = at.multiply_add(bt, acc)
    acc.store(c.unsafe_offset(row * dim + col), dim)


def matmul_coopmat_f16(a: UnsafePointer[Float16, MutAnyOrigin], b: UnsafePointer[Float16, MutAnyOrigin],
                       c: UnsafePointer[Float16, MutAnyOrigin], n: Int64):
    # C = A x B, all n x n row-major, in fp16 (fp16 accumulation: the 840 has no fp16 -> fp32).
    comptime K = 16
    var dim = Int(n)
    var row = Int(block_idx.y) * M
    var col = Int(block_idx.x) * N
    var acc = CoopMatrix[DType.float16, M, N, ACCUMULATOR].zero()
    for k in range(0, dim, K):
        var at = CoopMatrix[DType.float16, M, K, MATRIX_A].load(a.unsafe_offset(row * dim + k), dim)
        var bt = CoopMatrix[DType.float16, K, N, MATRIX_B].load(b.unsafe_offset(k * dim + col), dim)
        acc = at.multiply_add(bt, acc)
    acc.store(c.unsafe_offset(row * dim + col), dim)


def matmul_coopmat_bt_f16(a: UnsafePointer[Float16, MutAnyOrigin], b: UnsafePointer[Float16, MutAnyOrigin],
                          c: UnsafePointer[Float16, MutAnyOrigin], n: Int64):
    # C = A x B^T with B stored n x n row-major (a column-major load), in fp16.
    comptime K = 16
    var dim = Int(n)
    var row = Int(block_idx.y) * M
    var col = Int(block_idx.x) * N
    var acc = CoopMatrix[DType.float16, M, N, ACCUMULATOR].zero()
    for k in range(0, dim, K):
        var at = CoopMatrix[DType.float16, M, K, MATRIX_A].load(a.unsafe_offset(row * dim + k), dim)
        var bt = CoopMatrix[DType.float16, K, N, MATRIX_B].load[row_major=False](
            b.unsafe_offset(col * dim + k), dim)
        acc = at.multiply_add(bt, acc)
    acc.store(c.unsafe_offset(row * dim + col), dim)


@always_inline
def f16_smem_offset(e: Int) -> Int:
    """The offset to pass for element `e` of an fp16 shared array in a cooperative-matrix load or store.

    The 840's driver (512.842.19) starts such an access at byte 4 e instead of 2 e (it lays out
    single fp16 elements of shared memory 4 bytes apart, and the matrix access inherits that base),
    while packing the matrix itself 2 bytes per element. Halving even offsets lands it at byte 2 e;
    -D COOPMAT_F16_SMEM_QUIRK=0 turns this off for a driver that addresses fp16 correctly.
    """
    comptime if F16_SMEM_QUIRK:
        return e // 2
    else:
        return e


@always_inline
def matmul_coopmat_smem[dtype: DType](a: UnsafePointer[Scalar[dtype], MutAnyOrigin],
                                      b: UnsafePointer[Scalar[dtype], MutAnyOrigin],
                                      c: UnsafePointer[Scalar[dtype], MutAnyOrigin], n: Int64):
    # C = A x B, all n x n row-major, with the A and B slices of each K step (BK = 2 K) staged in
    # shared memory. fp32 is copied 4 elements per thread at a time. Single fp16 elements of shared
    # memory are laid out unlike cooperative matrices on the 840, so fp16 tiles are copied as
    # matrices: each subgroup loads one 64 x K tile of A and one K x 64 tile of B from the buffers
    # and stores them to shared memory (15% slower than the element copy for fp32).
    comptime BM = 64 * WM
    comptime BN = 64 * WN
    comptime K = 16 if dtype == DType.float16 else 8
    comptime BK = 2 * K
    comptime KT = BK // K
    comptime assert WM * KT == WM * WN and KT * WN == WM * WN, "one A and one B tile per subgroup"

    @always_inline
    def at(e: Int) -> Int:  # the offset to pass for element e of a shared array
        comptime if dtype == DType.float16:
            return f16_smem_offset(e)
        else:
            return e

    var sa = stack_allocation[BM * BK, Scalar[dtype], address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[BK * BN, Scalar[dtype], address_space=AddressSpace.SHARED]()
    var dim = Int(n)
    var sg = Int(thread_idx.x) // 64
    var row0 = Int(block_idx.y) * BM
    var col0 = Int(block_idx.x) * BN
    var sr = (sg // WN) * 64  # this subgroup's tile of C within the block
    var sc = (sg % WN) * 64
    var ar = sg // KT * 64  # the tiles of A and B it copies
    var ak = sg % KT * K
    var bk = sg // WN * K
    var bc = sg % WN * 64
    var acc = CoopMatrix[dtype, 64, 64, ACCUMULATOR].zero()
    var t = Int(thread_idx.x)
    for k0 in range(0, dim, BK):
        comptime if dtype == DType.float16:
            CoopMatrix[dtype, 64, K, MATRIX_A].load(a.unsafe_offset((row0 + ar) * dim + k0 + ak), dim).store(
                sa.unsafe_offset(at(ar * BK + ak)), BK)
            CoopMatrix[dtype, K, 64, MATRIX_B].load(b.unsafe_offset((k0 + bk) * dim + col0 + bc), dim).store(
                sb.unsafe_offset(at(bk * BN + bc)), BN)
        else:
            comptime for i in range(BM * BK // 4 // THREADS):
                var v = i * THREADS + t
                var r = v // (BK // 4)
                var col = v % (BK // 4) * 4
                sa.unsafe_store(r * BK + col, a.unsafe_load[width=4]((row0 + r) * dim + k0 + col))
            comptime for i in range(BK * BN // 4 // THREADS):
                var v = i * THREADS + t
                var r = v // (BN // 4)
                var col = v % (BN // 4) * 4
                sb.unsafe_store(r * BN + col, b.unsafe_load[width=4]((k0 + r) * dim + col0 + col))
        barrier()
        comptime for kk in range(0, BK, K):
            var a_tile = CoopMatrix[dtype, 64, K, MATRIX_A].load(sa.unsafe_offset(at(sr * BK + kk)), BK)
            var b_tile = CoopMatrix[dtype, K, 64, MATRIX_B].load(sb.unsafe_offset(at(kk * BN + sc)), BN)
            acc = a_tile.multiply_add(b_tile, acc)
        barrier()
    acc.store(c.unsafe_offset((row0 + sr) * dim + col0 + sc), dim)


def matmul_coopmat_smem_f16(a: UnsafePointer[Float16, MutAnyOrigin], b: UnsafePointer[Float16, MutAnyOrigin],
                            c: UnsafePointer[Float16, MutAnyOrigin], n: Int64):
    matmul_coopmat_smem[DType.float16](a, b, c, n)


def matmul_coopmat_smem_f32(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
                            c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    matmul_coopmat_smem[DType.float32](a, b, c, n)


def main() raises:
    comptime n = 256
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float32](n * n)
    var b = ctx.enqueue_create_buffer[DType.float32](n * n)
    var c = ctx.enqueue_create_buffer[DType.float32](n * n)
    var a16 = ctx.enqueue_create_buffer[DType.float16](n * n)
    var b16 = ctx.enqueue_create_buffer[DType.float16](n * n)
    var c16 = ctx.enqueue_create_buffer[DType.float16](n * n)
    ctx.enqueue_function[matmul_coopmat_f32](a, b, c, Int64(n), grid_dim=(n // N, n // M), block_dim=64)
    ctx.enqueue_function[matmul_coopmat_f16](a16, b16, c16, Int64(n), grid_dim=(n // N, n // M), block_dim=64)
    ctx.enqueue_function[matmul_coopmat_bt_f16](a16, b16, c16, Int64(n), grid_dim=(n // N, n // M), block_dim=64)
    ctx.enqueue_function[matmul_coopmat_smem_f16](a16, b16, c16, Int64(n), grid_dim=(n // (64 * WN), n // (64 * WM)),
                                                  block_dim=THREADS)
    ctx.enqueue_function[matmul_coopmat_smem_f32](a, b, c, Int64(n), grid_dim=(n // (64 * WN), n // (64 * WM)),
                                                  block_dim=THREADS)
    ctx.synchronize()
