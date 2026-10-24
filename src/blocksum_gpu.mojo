# mojo_adreno: check=blocksum local=64
from max.gpu import global_idx, thread_idx, barrier
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from std.memory import stack_allocation


def blocksum(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
             c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    # tree reduction of a + b over each 64-thread block, through shared memory
    var sh = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var t = thread_idx.x
    var i = global_idx.x
    var v = Float32(0)
    if Int64(i) < n:
        v = a[i] + b[i]
    sh[t] = v
    barrier()
    var s = 32
    while s > 0:
        if t < s:
            sh[t] = sh[t] + sh[t + s]
        barrier()
        s //= 2
    if Int64(i) < n:
        c[i] = sh[0]


def main() raises:
    comptime n = 1024
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float32](n)
    var b = ctx.enqueue_create_buffer[DType.float32](n)
    var c = ctx.enqueue_create_buffer[DType.float32](n)
    ctx.enqueue_function[blocksum](a, b, c, Int64(n), grid_dim=n // 64, block_dim=64)
    ctx.synchronize()
