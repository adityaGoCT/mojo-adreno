# Which of vla/kernels/vattn.mojo's attention variants a phone's driver can build: each is launched once on a small
# problem (pipeline creation is where the 840's Android 16 driver refuses kernels), then the next.
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so test_attn <variant 0..5>
from std.sys import argv
from max.gpu.host import DeviceContext, Dim

import vattn


def main() raises:
    var v = Int(argv()[1])
    var ctx = DeviceContext(api="vulkan")
    var q = ctx.enqueue_create_buffer[DType.float32](256 * 4096)
    var lev = ctx.enqueue_create_buffer[DType.float32](1024)
    var part = ctx.enqueue_create_buffer[DType.float32](1 << 20)
    ctx.enqueue_memset(q, Float32(0))
    ctx.enqueue_memset(lev, Float32(0))
    var names: List[String] = ["64, Q hoisted (SmolVLA)", "64, not hoisted", "72, 64 columns (SigLIP So400m)",
                               "72, 16 columns", "256 (Gemma)", "256, keys split", "64, Q hoisted, key blocks of 32",
                               "64, 32 columns", "72, 64 columns, key blocks of 32", "256, key blocks of 32",
                               "256, keys split, key blocks of 32", "72, 32 columns", "72, 32 columns, key blocks of 32"]
    if v == 0:
        ctx.enqueue_function[vattn.attention[True, 64, 64, True]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(0), Int32(1), Int32(1), q, q,
            grid_dim=Dim(2, 1, 1), block_dim=64)
    elif v == 1:
        ctx.enqueue_function[vattn.attention[True, 64, 64, False]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(0), Int32(1), Int32(1), q, q,
            grid_dim=Dim(2, 1, 1), block_dim=64)
    elif v == 2:
        ctx.enqueue_function[vattn.attention[False, 72, 64, False]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(0), Int32(1), Int32(1), q, q,
            grid_dim=Dim(2, 1, 1), block_dim=64)
    elif v == 3:
        ctx.enqueue_function[vattn.attention[False, 72, 16, False]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(64), Int32(1), Int32(1), q, q,
            grid_dim=Dim(2, 1, 1), block_dim=64)
    elif v == 4:
        ctx.enqueue_function[vattn.attention[True, 256, 64, False]](
            q, q, q, q, lev, lev, Int32(4096), Int32(4096), Int32(4096), Int32(4096), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.0625), Int32(0), Int32(0), Int32(0), Int32(4), Int32(1), q, q,
            grid_dim=Dim(2, 1, 4), block_dim=64)
    elif v == 6:
        ctx.enqueue_function[vattn.attention[True, 64, 64, True, False, 32]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(0), Int32(1), Int32(1), q, q,
            grid_dim=Dim(2, 1, 1), block_dim=64)
    elif v == 7:
        ctx.enqueue_function[vattn.attention[True, 64, 32, True]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(0), Int32(2), Int32(1), q, q,
            grid_dim=Dim(2, 1, 2), block_dim=64)
    elif v == 8:
        ctx.enqueue_function[vattn.attention[False, 72, 64, False, False, 32]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(0), Int32(1), Int32(1), q, q,
            grid_dim=Dim(2, 1, 1), block_dim=64)
    elif v == 9:
        ctx.enqueue_function[vattn.attention[True, 256, 64, False, False, 32]](
            q, q, q, q, lev, lev, Int32(4096), Int32(4096), Int32(4096), Int32(4096), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.0625), Int32(0), Int32(0), Int32(0), Int32(4), Int32(1), q, q,
            grid_dim=Dim(2, 1, 4), block_dim=64)
    elif v == 10:
        ctx.enqueue_function[vattn.attention[True, 256, 64, False, True, 32]](
            q, q, q, q, lev, lev, Int32(4096), Int32(4096), Int32(4096), Int32(4096), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.0625), Int32(0), Int32(0), Int32(0), Int32(4), Int32(2), part,
            part, grid_dim=Dim(2, 1, 8), block_dim=64)
    elif v == 11:
        ctx.enqueue_function[vattn.attention[False, 72, 32, False]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(0), Int32(2), Int32(1), q, q,
            grid_dim=Dim(2, 1, 2), block_dim=64)
    elif v == 12:
        ctx.enqueue_function[vattn.attention[False, 72, 32, False, False, 32]](
            q, q, q, q, lev, lev, Int32(1024), Int32(1024), Int32(1024), Int32(1024), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.125), Int32(0), Int32(0), Int32(0), Int32(2), Int32(1), q, q,
            grid_dim=Dim(2, 1, 2), block_dim=64)
    else:
        ctx.enqueue_function[vattn.attention[True, 256, 64, False, True]](
            q, q, q, q, lev, lev, Int32(4096), Int32(4096), Int32(4096), Int32(4096), Int32(0), Int32(0), Int32(0),
            Int32(0), Int32(128), Int32(1), Float32(0.0625), Int32(0), Int32(0), Int32(0), Int32(4), Int32(2), part,
            part, grid_dim=Dim(2, 1, 8), block_dim=64)
    ctx.synchronize()
    print("variant", v, "(heads of", names[v] + "): built and ran")
