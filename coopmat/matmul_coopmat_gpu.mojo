# Matmul with KHR cooperative matrices (SPV_KHR_cooperative_matrix), compiled by Mojo's own SPIR-V target:
#   mojo build --emit asm --target-accelerator adreno840 ...   (see coopmat/check.sh)
# One subgroup per 16x16 tile of C; fp16 inputs, fp32 accumulation. Compile-only here: the Adreno 710's
# drivers (Turnip and stock) do not expose VK_KHR_cooperative_matrix (coopmat/vk_coopmat_probe.c).
from max.gpu import block_idx
from max.gpu.host import DeviceContext
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime TILE = 16


def matmul_coopmat(a: UnsafePointer[Float16, MutAnyOrigin], b: UnsafePointer[Float16, MutAnyOrigin],
                   c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    # C = A x B, all n x n row-major; C in fp32.
    var dim = Int(n)
    var row = Int(block_idx.y) * TILE
    var col = Int(block_idx.x) * TILE
    var acc = CoopMatrix[DType.float32, TILE, TILE, ACCUMULATOR].zero()
    for k in range(0, dim, TILE):
        var at = CoopMatrix[DType.float16, TILE, TILE, MATRIX_A].load(a.unsafe_offset(row * dim + k), dim)
        var bt = CoopMatrix[DType.float16, TILE, TILE, MATRIX_B].load(b.unsafe_offset(k * dim + col), dim)
        acc = at.multiply_add(bt, acc)
    acc.store(c.unsafe_offset(row * dim + col), dim)


def matmul_coopmat_bt_f16(a: UnsafePointer[Float16, MutAnyOrigin], b: UnsafePointer[Float16, MutAnyOrigin],
                          c: UnsafePointer[Float16, MutAnyOrigin], n: Int64):
    # C = A x B^T with B stored n x n row-major (a column-major load), accumulated in fp32, stored as fp16.
    var dim = Int(n)
    var row = Int(block_idx.y) * TILE
    var col = Int(block_idx.x) * TILE
    var acc = CoopMatrix[DType.float32, TILE, TILE, ACCUMULATOR].zero()
    for k in range(0, dim, TILE):
        var at = CoopMatrix[DType.float16, TILE, TILE, MATRIX_A].load(a.unsafe_offset(row * dim + k), dim)
        var bt = CoopMatrix[DType.float16, TILE, TILE, MATRIX_B].load[row_major=False](
            b.unsafe_offset(col * dim + k), dim)
        acc = at.multiply_add(bt, acc)
    acc.cast[DType.float16]().store(c.unsafe_offset(row * dim + col), dim)


def main() raises:
    comptime n = 256
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float16](n * n)
    var b = ctx.enqueue_create_buffer[DType.float16](n * n)
    var c = ctx.enqueue_create_buffer[DType.float32](n * n)
    var c16 = ctx.enqueue_create_buffer[DType.float16](n * n)
    ctx.enqueue_function[matmul_coopmat](a, b, c, Int64(n), grid_dim=(n // TILE, n // TILE), block_dim=64)
    ctx.enqueue_function[matmul_coopmat_bt_f16](a, b, c16, Int64(n), grid_dim=(n // TILE, n // TILE), block_dim=64)
    ctx.synchronize()
