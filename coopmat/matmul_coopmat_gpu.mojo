# Matmul with KHR cooperative matrices (SPV_KHR_cooperative_matrix), compiled by Mojo's own SPIR-V target:
#   mojo build --emit asm --target-accelerator adreno840 ...   (see coopmat/check.sh)
# One subgroup of 64 per M x N tile of C, in the shapes the Adreno 840's driver offers
# (coopmat/vk_coopmat_probe.c on a Galaxy S26 Ultra): M = 64, N = 16, 32 or 64, and
#   fp32 x fp32 -> fp32 with K = 8,  fp16 x fp16 -> fp16 with K = 16  (no fp16 x fp16 -> fp32).
# N comes from `-D COOPMAT_N=...` (coopmat/check.sh); coopmat/run_coopmat.py runs the kernels on a
# phone and checks them against NumPy.
from std.sys import get_defined_int
from max.gpu import block_idx
from max.gpu.host import DeviceContext
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime M = 64
comptime N = get_defined_int["COOPMAT_N", 64]()


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
    ctx.synchronize()
