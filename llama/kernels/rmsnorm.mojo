# Llama RMSNorm: y = x / sqrt(mean(x^2) + eps) * w (w fp16). One 256-thread workgroup.
from max.gpu import thread_idx, barrier
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from std.math import sqrt
from std.memory import stack_allocation

comptime D = 2048
comptime T = 256
comptime EPS: Float32 = 1e-5


def rmsnorm(x: UnsafePointer[Float32, MutAnyOrigin], w: UnsafePointer[Float16, MutAnyOrigin],
            y: UnsafePointer[Float32, MutAnyOrigin]):
    var ss = stack_allocation[T, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var acc = Float32(0)
    for j in range(D // T):
        var v = x[t + j * T]
        acc += v * v
    ss[t] = acc
    barrier()
    var s = T // 2
    while s > 0:
        if t < s:
            ss[t] = ss[t] + ss[t + s]
        barrier()
        s //= 2
    var scale = 1.0 / sqrt(ss[0] / Float32(D) + EPS)
    for j in range(D // T):
        var i = t + j * T
        y[i] = x[i] * scale * w[i].cast[DType.float32]()


def main() raises:
    var ctx = DeviceContext()
    var x = ctx.enqueue_create_buffer[DType.float32](D)
    var w = ctx.enqueue_create_buffer[DType.float16](D)
    var o = ctx.enqueue_create_buffer[DType.float32](D)
    ctx.enqueue_function[rmsnorm](x, w, o, grid_dim=1, block_dim=T)
    ctx.synchronize()
