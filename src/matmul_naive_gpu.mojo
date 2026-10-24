# mojo_adreno: check=matmul dim=1024 local=256
from max.gpu import block_idx, thread_idx
from max.gpu.host import DeviceContext

comptime TILE = 16


def matmul_naive(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
                 c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    # The same launch and output mapping as matmul_tiled_gpu.mojo, reading A and B from global memory.
    var dim = Int(n)
    var t = Int(thread_idx.x)
    var tiles = dim // TILE
    var row = (Int(block_idx.x) // tiles) * TILE + t // TILE
    var col = (Int(block_idx.x) % tiles) * TILE + t % TILE
    var acc = Float32(0)
    for k in range(dim):
        acc += a[row * dim + k] * b[k * dim + col]
    c[row * dim + col] = acc


def main() raises:
    comptime n = 256
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float32](n * n)
    var b = ctx.enqueue_create_buffer[DType.float32](n * n)
    var c = ctx.enqueue_create_buffer[DType.float32](n * n)
    ctx.enqueue_function[matmul_naive](a, b, c, Int64(n), grid_dim=(n // TILE) * (n // TILE), block_dim=TILE * TILE)
    ctx.synchronize()
