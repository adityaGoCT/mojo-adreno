# The first Mojo host program on the phone: an ordinary DeviceContext vector add, compiled for
# aarch64-linux-android with its kernel as adreno840 SPIR-V inside, running on the Adreno through
# MAX's HAL DeviceContext and driver/libM_driver_vulkan.so (MODULAR_DRIVER_PLUGINS).
from std.time import perf_counter_ns
from max.gpu import global_idx
from max.gpu.host import DeviceContext


def vecadd(a: Pointer[Float32, MutAnyOrigin], b: Pointer[Float32, MutAnyOrigin],
           c: Pointer[Float32, MutAnyOrigin], n: Int64):
    var i = global_idx.x
    if Int64(i) < n:
        c[unsafe_offset=i] = a[unsafe_offset=i] + b[unsafe_offset=i]


def main() raises:
    comptime n = 1 << 20
    comptime launches = 721  # as many as one Bonsai token
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name(), "| arch:", ctx.arch_name())
    var a = ctx.enqueue_create_buffer[DType.float32](n)
    var b = ctx.enqueue_create_buffer[DType.float32](n)
    var c = ctx.enqueue_create_buffer[DType.float32](n)
    with a.map_to_host() as ha, b.map_to_host() as hb:
        for i in range(n):
            ha[i] = Float32(i % 1000)
            hb[i] = Float32(2 * (i % 1000))
    ctx.enqueue_function[vecadd](a, b, c, Int64(n), grid_dim=n // 256, block_dim=256)
    ctx.synchronize()
    with c.map_to_host() as hc:
        var bad = 0
        for i in range(n):
            if hc[i] != Float32(3 * (i % 1000)):
                bad += 1
        print("vecadd of", n, "floats: c[5] =", hc[5], "| mismatches:", bad)
    var start = perf_counter_ns()
    for _ in range(launches):
        ctx.enqueue_function[vecadd](a, b, c, Int64(n), grid_dim=n // 256, block_dim=256)
    var enqueued = perf_counter_ns()
    ctx.synchronize()
    var done = perf_counter_ns()
    print(launches, "launches: enqueued in", Float64(enqueued - start) / 1e6, "ms, done in",
          Float64(done - start) / 1e6, "ms")
    # The same, 256 elements a launch: what a launch costs on the CPU.
    start = perf_counter_ns()
    for _ in range(launches):
        ctx.enqueue_function[vecadd](a, b, c, Int64(256), grid_dim=1, block_dim=256)
    enqueued = perf_counter_ns()
    ctx.synchronize()
    done = perf_counter_ns()
    print(launches, "launches of 256 elements: enqueued in", Float64(enqueued - start) / 1e6, "ms, done in",
          Float64(done - start) / 1e6, "ms")
