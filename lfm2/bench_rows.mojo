# Microbenchmark of the few-row products a speculative verify needs: y[m, r] = W[r] . x[m] for m < count (up to 10),
# W int4 (Q4_0's layout), on the phone's Adreno. Times each candidate on gate/up's shape (21504 x 2048) and down's
# (2048 x 10752) against decode's one-row gemv_q4: ms a launch and the weights' read rate. dsk.rows_q4 (8 weight rows a
# workgroup, 4 groups of 16 lanes splitting x's rows, FMA chains) is what the verify uses; the others are the designs it
# was chosen over.
#
#   bench_rows [count] [reps]
from std.memory import stack_allocation
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu import barrier, block_idx, thread_idx
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR
from max.gpu.host import DeviceBuffer, DeviceContext
from max.gpu.memory import AddressSpace
from max.gpu.primitives.warp import sum as warp_sum

import dsk
import lk

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
comptime MR = dsk.MR
comptime NB = 16
comptime KS = 32


def rows_mma(wq: U32, ws: F16, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """Y^T = W X^T on the matrix units (M 64, N 16): a subgroup takes 64 weight rows; per k step of 32, each lane
    unpacks a block of its row into shared memory (fp32, k-major), x's slice is staged (zeros past count), four
    64 x 8 by 8 x 16 products add into a 64 x 16 accumulator, stored transposed. y holds 16 rows."""
    var sw = stack_allocation[64 * KS, Float32, address_space=AddressSpace.SHARED]()
    var sx = stack_allocation[NB * KS, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var r0 = Int(block_idx.x) * 64
    var k = Int(cols)
    var blocks = k // 32
    var wr = wq + (r0 + t) * (k // 8)
    var acc = CoopMatrix[DType.float32, 64, NB, ACCUMULATOR].zero()
    for b in range(blocks):
        var w4 = wr.load[width=4](b * 4)
        var s = ws[(r0 + t) * blocks + b].cast[DType.float32]()
        comptime for kk in range(4):
            comptime for j in range(8):
                sw[(kk * 8 + j) * 64 + t] = Float32((Int32((w4[kk] >> UInt32(4 * j)) & 15) ^ 8) - 8) * s
        var m = t // 4
        var c = (t % 4) * 8
        var v = SIMD[DType.float32, 8](0)
        if m < Int(count):
            v = x.load[width=8](m * k + b * KS + c)
        sx.store(m * KS + c, v)
        barrier()
        comptime for kk in range(0, KS, 8):
            var at = CoopMatrix[DType.float32, 64, 8, MATRIX_A].load[row_major=False](sw.unsafe_offset(kk * 64), 64)
            var bt = CoopMatrix[DType.float32, 8, NB, MATRIX_B].load[row_major=False](sx.unsafe_offset(kk), KS)
            acc = at.multiply_add(bt, acc)
        barrier()
    acc.store[row_major=False](y.unsafe_offset(r0), Int(n))


def rows_lane(wq: U32, ws: F16, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """A lane a weight row (64 a workgroup), every lane reading the same x element (broadcast loads): no shared memory,
    no barriers, but row-strided weight loads."""
    var r = Int(block_idx.x) * 64 + Int(thread_idx.x)
    var k = Int(cols)
    var cnt = Int(count)
    var blocks = k // 32
    var wr = wq + r * (k // 8)
    var acc = SIMD[DType.float32, 16](0)
    for b in range(blocks):
        var w4 = wr.load[width=4](b * 4)
        var s = ws[r * blocks + b].cast[DType.float32]()
        var wv = SIMD[DType.float32, 32]()
        comptime for kk in range(4):
            comptime for j in range(8):
                wv[kk * 8 + j] = Float32((Int32((w4[kk] >> UInt32(4 * j)) & 15) ^ 8) - 8)
        comptime for m in range(MR):
            if m < cnt:
                var xm = x + (m * k + b * 32)
                var part = Float32(0)
                comptime for kk in range(4):
                    part += (wv.slice[8, offset=kk * 8]() * xm.load[width=8](kk * 8)).reduce_add()
                acc[m] += part * s
    comptime for m in range(MR):
        if m < cnt:
            y[m * Int(n) + r] = acc[m]


def rows_warp2(wq: U32, ws: F16, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """Decode's coalesced order (64 lanes across k) for 2 weight rows a workgroup, each x load serving both."""
    var r0 = Int(block_idx.x) * 2
    var t = Int(thread_idx.x)
    var k = Int(cols)
    var cnt = Int(count)
    var words = k // 8
    var blocks = k // 32
    var acc = SIMD[DType.float32, 32](0)
    for i in range((words + 63) // 64):
        var wi = i * 64 + t
        if wi < words:
            var w = SIMD[DType.float32, 16]()
            comptime for j in range(2):
                var word = wq[(r0 + j) * words + wi]
                var s = ws[(r0 + j) * blocks + wi // 4].cast[DType.float32]()
                comptime for e in range(8):
                    w[j * 8 + e] = Float32((Int32((word >> UInt32(4 * e)) & 15) ^ 8) - 8) * s
            comptime for m in range(MR):
                if m < cnt:
                    var xv = x.load[width=8](m * k + wi * 8)
                    comptime for j in range(2):
                        acc[j * 16 + m] += (w.slice[8, offset=j * 8]() * xv).reduce_add()
    comptime for j in range(2):
        comptime for m in range(MR):
            var tot = warp_sum(acc[j * 16 + m])
            if t == 0 and m < cnt:
                y[m * Int(n) + r0 + j] = tot


def rows_xq[XQ: Int](wq: U32, ws: F16, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """dsk.rows_q4 with XQ x-row slots a lane (count <= 4 XQ): fewer FMAs for a narrower verify."""
    var sp = stack_allocation[64 * 8 * 3, Float32, address_space=AddressSpace.SHARED]()
    var r0 = Int(block_idx.x) * 8
    var t = Int(thread_idx.x)
    var g = t // 16
    var u = t % 16
    var k = Int(cols)
    var cnt = Int(count)
    var words = k // 8
    var blocks = k // 32
    var acc = SIMD[DType.float32, 32](0)
    for i in range(words // 16):
        var wi = i * 16 + u
        var x0 = SIMD[DType.float32, 8](0)
        var x1 = SIMD[DType.float32, 8](0)
        var x2 = SIMD[DType.float32, 8](0)
        if g < cnt:
            x0 = x.load[width=8](g * k + wi * 8)
        comptime if XQ >= 2:
            if g + 4 < cnt:
                x1 = x.load[width=8]((g + 4) * k + wi * 8)
        comptime if XQ >= 3:
            if g + 8 < cnt:
                x2 = x.load[width=8]((g + 8) * k + wi * 8)
        comptime for j in range(8):
            var word = wq[(r0 + j) * words + wi]
            var s = ws[(r0 + j) * blocks + wi // 4].cast[DType.float32]()
            var a0 = acc[j * 4]
            var a1 = acc[j * 4 + 1]
            var a2 = acc[j * 4 + 2]
            comptime for e in range(8):
                var w = Float32((Int32((word >> UInt32(4 * e)) & 15) ^ 8) - 8) * s
                a0 += w * x0[e]
                comptime if XQ >= 2:
                    a1 += w * x1[e]
                comptime if XQ >= 3:
                    a2 += w * x2[e]
            acc[j * 4] = a0
            acc[j * 4 + 1] = a1
            acc[j * 4 + 2] = a2
    comptime for j in range(8):
        comptime for q in range(3):
            sp[(j * 3 + q) * 64 + t] = acc[j * 4 + q]
    barrier()
    for o in range(t, 8 * 12, 64):
        var j = o // 12
        var m = o % 12
        if m < cnt:
            var tot = Float32(0)
            for uu in range(16):
                tot += sp[(j * 3 + m // 4) * 64 + (m % 4) * 16 + uu]
            y[m * Int(n) + r0 + j] = tot


def rows_t16(wq: U32, ws: F16, x: F32, y: F32, cols: Int32, n: Int32, count: Int32):
    """dsk.rows_q4's tile with 16 weight rows a workgroup and 2 x slots a lane (count <= 8): half the x traffic."""
    var sp = stack_allocation[64 * 16 * 2, Float32, address_space=AddressSpace.SHARED]()
    var r0 = Int(block_idx.x) * 16
    var t = Int(thread_idx.x)
    var g = t // 16
    var u = t % 16
    var k = Int(cols)
    var cnt = Int(count)
    var words = k // 8
    var blocks = k // 32
    var acc = SIMD[DType.float32, 32](0)  # [16 rows][2]
    for i in range(words // 16):
        var wi = i * 16 + u
        var x0 = SIMD[DType.float32, 8](0)
        var x1 = SIMD[DType.float32, 8](0)
        if g < cnt:
            x0 = x.load[width=8](g * k + wi * 8)
        if g + 4 < cnt:
            x1 = x.load[width=8]((g + 4) * k + wi * 8)
        comptime for j in range(16):
            var word = wq[(r0 + j) * words + wi]
            var s = ws[(r0 + j) * blocks + wi // 4].cast[DType.float32]()
            var a0 = acc[j * 2]
            var a1 = acc[j * 2 + 1]
            comptime for e in range(8):
                var w = Float32((Int32((word >> UInt32(4 * e)) & 15) ^ 8) - 8) * s
                a0 += w * x0[e]
                a1 += w * x1[e]
            acc[j * 2] = a0
            acc[j * 2 + 1] = a1
    comptime for j in range(16):
        comptime for q in range(2):
            sp[(j * 2 + q) * 64 + t] = acc[j * 2 + q]
    barrier()
    for o in range(t, 16 * 8, 64):
        var j = o // 8
        var m = o % 8
        if m < cnt:
            var tot = Float32(0)
            for uu in range(16):
                tot += sp[(j * 2 + m // 4) * 64 + (m % 4) * 16 + uu]
            y[m * Int(n) + r0 + j] = tot


def names() -> List[String]:
    return ["gemv_q4 (decode, 1 row)", "matrix units (64 x 16)", "a lane a weight row", "64 lanes across k, 2 rows",
            "dsk.rows_q4 (8 rows, 3 x slots)", "8 rows, 2 x slots (count <= 8)", "8 rows, 1 x slot (count <= 4)",
            "16 rows, 2 x slots (count <= 8)"]


def launch(ctx: DeviceContext, v: Int, wq: DeviceBuffer[DType.uint32], ws: DeviceBuffer[DType.float16],
           x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], k: Int, n: Int, count: Int) raises:
    if v == 0:
        ctx.enqueue_function[lk.gemv_q4[True]](wq, ws, x, y, Int32(k), grid_dim=n, block_dim=64)
    elif v == 1:
        ctx.enqueue_function[rows_mma](wq, ws, x, y, Int32(k), Int32(n), Int32(count), grid_dim=n // 64,
                                       block_dim=64)
    elif v == 2:
        ctx.enqueue_function[rows_lane](wq, ws, x, y, Int32(k), Int32(n), Int32(count), grid_dim=n // 64,
                                        block_dim=64)
    elif v == 3:
        ctx.enqueue_function[rows_warp2](wq, ws, x, y, Int32(k), Int32(n), Int32(count), grid_dim=n // 2,
                                         block_dim=64)
    elif v == 4:
        ctx.enqueue_function[dsk.rows_q4[3]](wq, ws, x, y, Int32(k), Int32(n), Int32(count), grid_dim=n // dsk.TR,
                                             block_dim=64)
    elif v == 5:
        ctx.enqueue_function[rows_xq[2]](wq, ws, x, y, Int32(k), Int32(n), Int32(min(count, 8)), grid_dim=n // 8,
                                         block_dim=64)
    elif v == 6:
        ctx.enqueue_function[rows_xq[1]](wq, ws, x, y, Int32(k), Int32(n), Int32(min(count, 4)), grid_dim=n // 8,
                                         block_dim=64)
    else:
        ctx.enqueue_function[rows_t16](wq, ws, x, y, Int32(k), Int32(n), Int32(min(count, 8)), grid_dim=n // 16,
                                       block_dim=64)


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def main() raises:
    var args = argv()
    var count = Int(args[1]) if len(args) > 1 else 10
    var reps = Int(args[2]) if len(args) > 2 else 20
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name(), "; rows of x:", count, "; reps:", reps)
    var labels = names()
    for shape in range(2):
        var n = 21504 if shape == 0 else 2048
        var k = 2048 if shape == 0 else 10752
        var wq = ctx.enqueue_create_buffer[DType.uint32](n * k // 8)
        var ws = ctx.enqueue_create_buffer[DType.float16](n * k // 32)
        var x = ctx.enqueue_create_buffer[DType.float32](16 * k)
        var y = ctx.enqueue_create_buffer[DType.float32](16 * n)
        var hw = List[UInt32](length=n * k // 8, fill=0)  # random words: constant ones may compress in memory
        var state = UInt32(2463534242)
        for i in range(len(hw)):
            state ^= state << 13
            state ^= state >> 17
            state ^= state << 5
            hw[i] = state
        ctx.enqueue_copy(wq, hw.unsafe_ptr())
        var hx = List[Float32](length=16 * k, fill=0)
        for i in range(len(hx)):
            hx[i] = Float32((i * 7919) % 1000) / 1000.0 - 0.5
        ctx.enqueue_copy(x, hx.unsafe_ptr())
        ws.enqueue_fill(Float16(0.01))
        ctx.synchronize()
        var gb = Float64(n * k // 2 + n * k // 16) / 1e9
        print("shape", n, "x", k, ":", round(gb * 1e3, 1), "MB of weights")
        for v in range(len(labels)):
            for _ in range(3):  # warm-up: the pipeline's first use
                launch(ctx, v, wq, ws, x, y, k, n, count)
            ctx.synchronize()
            var t0 = now_ms()
            for _ in range(reps):
                launch(ctx, v, wq, ws, x, y, k, n, count)
            ctx.synchronize()
            var ms = (now_ms() - t0) / Float64(reps)
            print("  ", labels[v], ":", round(ms, 3), "ms,", round(gb / ms * 1e3, 1), "GB/s")
