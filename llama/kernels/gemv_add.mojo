# y[r] += sum_c W[r, c] x[c] (the residual add) for fp16 W (rows x cols, row-major), fp32 x and y. One 64-thread workgroup (one 64-lane warp
# on gfx90a) per row, then a warp sum. Per load instruction the 64 threads read 64 consecutive weights
# (128 contiguous bytes): Qualcomm's compiler does not merge a thread's consecutive 16-bit loads, so
# 4 consecutive weights per thread wasted most of each transaction (3.3x slower on the stock driver).
from max.gpu import block_idx, thread_idx
from max.gpu.host import DeviceContext
from max.gpu.primitives.warp import sum as warp_sum

comptime T = 64
comptime V = 4


def gemv_add(w: UnsafePointer[Float16, MutAnyOrigin], x: UnsafePointer[Float32, MutAnyOrigin],
         y: UnsafePointer[Float32, MutAnyOrigin], cols: Int64):
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var n = Int(cols)
    var acc = Float32(0)
    for i in range(n // (T * V)):
        var c = i * (T * V) + t
        comptime for j in range(V):
            acc += w[r * n + c + j * T].cast[DType.float32]() * x[c + j * T]
    var s = warp_sum(acc)
    if t == 0:
        y[r] = y[r] + s


def main() raises:
    var ctx = DeviceContext()
    var w = ctx.enqueue_create_buffer[DType.float16](2048 * 2048)
    var x = ctx.enqueue_create_buffer[DType.float32](2048)
    var y = ctx.enqueue_create_buffer[DType.float32](2048)
    ctx.enqueue_function[gemv_add](w, x, y, Int64(2048), grid_dim=2048, block_dim=T)
    ctx.synchronize()
