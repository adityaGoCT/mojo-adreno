# y[r] = sum_c W[r, c] x[c] for int4 W (rows x cols, 8 weights per 32-bit word, low nibble first, signed -8..7) with one
# fp16 scale per 64 weights of a row; fp32 x and y. One 64-thread workgroup (one 64-lane warp) per
# row: consecutive threads read consecutive words, 4x fewer bytes than gemv's fp16 weights, then a
# warp sum (mojo2vk.py makes it one subgroup reduction).
from max.gpu import block_idx, thread_idx
from max.gpu.host import DeviceContext
from max.gpu.primitives.warp import sum as warp_sum

comptime T = 64
comptime G = 64  # weights per scale


def gemv_q4(wq: UnsafePointer[UInt32, MutAnyOrigin], ws: UnsafePointer[Float16, MutAnyOrigin],
            x: UnsafePointer[Float32, MutAnyOrigin], y: UnsafePointer[Float32, MutAnyOrigin], cols: Int64):
    var r = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var n = Int(cols)
    var words = n // 8
    var acc = Float32(0)
    for i in range(words // T):
        var wi = i * T + t
        var word = wq[r * words + wi]
        var part = Float32(0)
        comptime for j in range(8):
            var q = Int32((word >> UInt32(4 * j)) & 15) ^ 8
            part += Float32(q - 8) * x[wi * 8 + j]
        acc += part * ws[r * (n // G) + wi // (G // 8)].cast[DType.float32]()
    var s = warp_sum(acc)
    if t == 0:
        y[r] = s


def main() raises:
    var ctx = DeviceContext()
    var wq = ctx.enqueue_create_buffer[DType.uint32](2048 * 256)
    var ws = ctx.enqueue_create_buffer[DType.float16](2048 * 32)
    var x = ctx.enqueue_create_buffer[DType.float32](2048)
    var y = ctx.enqueue_create_buffer[DType.float32](2048)
    ctx.enqueue_function[gemv_q4](wq, ws, x, y, Int64(2048), grid_dim=2048, block_dim=T)
    ctx.synchronize()
