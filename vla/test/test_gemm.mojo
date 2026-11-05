# Checks vla/kernels/vgemm.mojo's kernels against the CPU on random data, on the phone (64 x 200 x 720, bf16 W):
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so test_gemm [variant]
# variant 1: gemm (staged); 0, 2, 3, 4: gemm_sk with X from memory or staged, W double-buffered or not.
from std.random import random_float64, seed
from std.sys import argv
from max.gpu.host import DeviceContext, Dim

import vgemm


def main() raises:
    var variant = Int(argv()[1]) if len(argv()) > 1 else 0
    var ctx = DeviceContext(api="vulkan")
    seed(1)
    var rows = 64
    var n = 200
    var k = 720
    var x = List[Float32](length=rows * k, fill=0)
    var w = List[UInt16](length=n * k, fill=0)
    for i in range(rows * k):
        x[i] = Float32(random_float64(-1, 1))
    for i in range(n * k):
        w[i] = UInt16(Int(random_float64(0, 1) * 256) + 0x3E00)  # bf16 values in [0.125, 0.25)
    var xd = ctx.enqueue_create_buffer[DType.float32](rows * k)
    var wd = ctx.enqueue_create_buffer[DType.uint16](n * k)
    var pd = ctx.enqueue_create_buffer[DType.float32](8 * rows * 256)
    var yd = ctx.enqueue_create_buffer[DType.float32](rows * 256)
    ctx.enqueue_copy(xd, x.unsafe_ptr())
    ctx.enqueue_copy(wd, w.unsafe_ptr())
    ctx.enqueue_memset(pd, Float32(0))
    ctx.enqueue_memset(yd, Float32(0))
    var splits = 5
    var kc = 144
    var ldp = 256
    var plane = rows * ldp
    if variant != 1:
        if variant == 0:
            ctx.enqueue_function[vgemm.gemm_sk[DType.uint16, 2, True, True]](
                xd, wd, pd, Int32(n), Int32(k), Int32(k), Int32(k), Int32(kc), Int32(ldp), Int32(plane),
                grid_dim=Dim(2, 1, splits), block_dim=128)
        elif variant == 2:
            ctx.enqueue_function[vgemm.gemm_sk[DType.uint16, 2, False, False]](
                xd, wd, pd, Int32(n), Int32(k), Int32(k), Int32(k), Int32(kc), Int32(ldp), Int32(plane),
                grid_dim=Dim(2, 1, splits), block_dim=128)
        elif variant == 3:
            ctx.enqueue_function[vgemm.gemm_sk[DType.uint16, 2, True, False]](
                xd, wd, pd, Int32(n), Int32(k), Int32(k), Int32(k), Int32(kc), Int32(ldp), Int32(plane),
                grid_dim=Dim(2, 1, splits), block_dim=128)
        else:
            ctx.enqueue_function[vgemm.gemm_sk[DType.uint16, 2, False, True]](
                xd, wd, pd, Int32(n), Int32(k), Int32(k), Int32(k), Int32(kc), Int32(ldp), Int32(plane),
                grid_dim=Dim(2, 1, splits), block_dim=128)
        ctx.enqueue_function[vgemm.reduce_sk[False, False]](pd, pd, yd, Int32(splits), Int32(n),
                                                                          Int32(ldp), Int32(plane), Int32(256),
                                                                          Float32(1), Int32(rows * n),
                                                                          grid_dim=(rows * n + 255) // 256,
                                                                          block_dim=256)
    else:
        ctx.enqueue_function[vgemm.gemm[DType.uint16, 1, 2, vgemm.NONE, False, False]](
            xd, wd, pd, yd, Int32(n), Int32(k), Int32(k), Int32(k), Int32(256), Int32(0), Float32(1), Int32(0), Int32(0),
            grid_dim=Dim(2, 1), block_dim=128)
    var y = List[Float32](length=rows * 256, fill=0)
    ctx.enqueue_copy(y.unsafe_ptr(), yd)
    var pp = List[Float32](length=8 * rows * 256, fill=0)
    ctx.enqueue_copy(pp.unsafe_ptr(), pd)
    ctx.synchronize()
    var nz = 0
    for i in range(len(pp)):
        if pp[i] != 0:
            nz += 1
    print("partials nonzero:", nz, "p[0]", pp[0], "p[plane]", pp[plane], "p[1]", pp[1])
    var worst = 0.0
    for r in range(rows):
        for c in range(n):
            var s = 0.0
            for j in range(k):
                var wv = vgemm.widen1[DType.uint16](w[c * k + j])
                s += Float64(x[r * k + j]) * Float64(wv)
            worst = max(worst, abs(s - Float64(y[r * 256 + c])))
    print("variant", variant, "max abs error", worst, "y[0]", y[0], "y[199]", y[199])
