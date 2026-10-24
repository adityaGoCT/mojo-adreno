# mojo_adreno: check=matmul dim=1024 local=256
from max.gpu import block_idx, thread_idx, barrier
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from std.memory import stack_allocation

comptime TILE = 16


def matmul_tiled_f16(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
                     c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    # matmul_tiled_gpu.mojo with the A and B tiles held in shared memory as Float16 (half the bytes):
    # products in fp16, accumulation in fp32. Global inputs and output stay fp32.
    var sa = stack_allocation[TILE * TILE, Float16, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[TILE * TILE, Float16, address_space=AddressSpace.SHARED]()
    var dim = Int(n)
    var t = Int(thread_idx.x)
    var ty = t // TILE
    var tx = t % TILE
    var tiles = dim // TILE
    var row = (Int(block_idx.x) // tiles) * TILE + ty
    var col = (Int(block_idx.x) % tiles) * TILE + tx
    var acc = Float32(0)
    for k0 in range(0, dim, TILE):
        sa[t] = a[row * dim + k0 + tx].cast[DType.float16]()
        sb[t] = b[(k0 + ty) * dim + col].cast[DType.float16]()
        barrier()
        for k in range(TILE):
            acc += (sa[ty * TILE + k] * sb[k * TILE + tx]).cast[DType.float32]()
        barrier()
    c[row * dim + col] = acc


def main() raises:
    comptime n = 256
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float32](n * n)
    var b = ctx.enqueue_create_buffer[DType.float32](n * n)
    var c = ctx.enqueue_create_buffer[DType.float32](n * n)
    ctx.enqueue_function[matmul_tiled_f16](a, b, c, Int64(n), grid_dim=(n // TILE) * (n // TILE), block_dim=TILE * TILE)
    ctx.synchronize()
