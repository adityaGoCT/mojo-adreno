from max.gpu import global_idx
from max.gpu.host import DeviceContext


def vecadd4(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
            c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    # each thread adds 4 consecutive elements (a loop with a bound check per element)
    var base = Int64(global_idx.x) * 4
    for k in range(4):
        var j = base + Int64(k)
        if j < n:
            c[j] = a[j] + b[j]


def main() raises:
    comptime n = 1024
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float32](n)
    var b = ctx.enqueue_create_buffer[DType.float32](n)
    var c = ctx.enqueue_create_buffer[DType.float32](n)
    ctx.enqueue_function[vecadd4](a, b, c, Int64(n), grid_dim=n // 256, block_dim=64)
    ctx.synchronize()
