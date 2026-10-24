from max.gpu import global_idx
from max.gpu.host import DeviceContext


def vecadd(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
           c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    var i = global_idx.x
    if Int64(i) < n:
        c[i] = a[i] + b[i]


def main() raises:
    comptime n = 1024
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float32](n)
    var b = ctx.enqueue_create_buffer[DType.float32](n)
    var c = ctx.enqueue_create_buffer[DType.float32](n)
    with a.map_to_host() as ha, b.map_to_host() as hb:
        for i in range(n):
            ha[i] = Float32(i)
            hb[i] = Float32(2 * i)
    ctx.enqueue_function[vecadd](a, b, c, Int64(n), grid_dim=n // 64, block_dim=64)
    ctx.synchronize()
    with c.map_to_host() as hc:
        var bad = 0
        for i in range(n):
            if hc[i] != Float32(3 * i):
                bad += 1
        print("device:", ctx.name(), " c[5] =", hc[5], " mismatches:", bad)
