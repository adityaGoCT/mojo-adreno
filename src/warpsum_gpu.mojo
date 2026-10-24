# mojo_adreno: check=warpsum
from max.gpu import global_idx
from max.gpu.host import DeviceContext
from max.gpu.primitives.warp import sum as warp_sum


def warpsum(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
            c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    # every lane gets the sum of a + b over its warp (WARP_SIZE lanes: 32 on NVIDIA, 64 on AMD CDNA)
    var i = global_idx.x
    var v = Float32(0)
    if Int64(i) < n:
        v = a[i] + b[i]
    var s = warp_sum(v)  # all lanes take part in the shuffles
    if Int64(i) < n:
        c[i] = s


def main() raises:
    comptime n = 1024
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float32](n)
    var b = ctx.enqueue_create_buffer[DType.float32](n)
    var c = ctx.enqueue_create_buffer[DType.float32](n)
    ctx.enqueue_function[warpsum](a, b, c, Int64(n), grid_dim=n // 64, block_dim=64)
    ctx.synchronize()
