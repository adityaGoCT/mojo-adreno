# Prefill projections on the phone's Adreno 840: lk.gemm_q4 (fp32 cooperative matrices, X and the unpacked W staged
# in shared memory) against lkh's path (pack_x: X into fp16 R tiles; deq_w: the int4 rows into fp16 B tiles; gemm_h:
# fp16 cooperative matrices from memory, K in chunks; sum_parts: the chunks added in fp32). At Qwen3-4B's shapes and a
# 512-row prompt: q|k|v (6144 x 2560), o (2560 x 4096), gate|up (19456 x 2560), down (2560 x 9728). Each variant is
# checked against gemm_q4's output (the largest difference over the largest output, and NaNs) and timed with and
# without pack_x and deq_w. Variants 9 on are lkh.gemm_hq, which unpacks the int4 rows into shared memory inside the
# product (no deq_w; "without" leaves out pack_x).
#
#   bench_q4h [reps] [shape] [variant]     shape: 0 q|k|v, 1 o, 2 gate|up, 3 down; variant: 0-24; all by default
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import lk
import lkh

comptime ROWS = 512


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


struct Bufs(Movable):
    var wq: DeviceBuffer[DType.uint32]
    var ws: DeviceBuffer[DType.float16]
    var wd: DeviceBuffer[DType.float16]
    var x: DeviceBuffer[DType.float32]
    var xa: DeviceBuffer[DType.float16]
    var y: DeviceBuffer[DType.float32]
    var part: DeviceBuffer[DType.float16]

    def __init__(out self, ctx: DeviceContext, n: Int, k: Int) raises:
        self.wq = ctx.enqueue_create_buffer[DType.uint32](n * k // 8)
        self.ws = ctx.enqueue_create_buffer[DType.float16](n * k // 32)
        self.wd = ctx.enqueue_create_buffer[DType.float16](n * k)
        self.x = ctx.enqueue_create_buffer[DType.float32](ROWS * k)
        self.xa = ctx.enqueue_create_buffer[DType.float16](ROWS * k)
        self.y = ctx.enqueue_create_buffer[DType.float32](ROWS * n)
        self.part = ctx.enqueue_create_buffer[DType.float16]((k + 1023) // 1024 * ROWS * n)  # chunks of 1024 or more


def h[WM: Int, WN: Int, TN: Int, CH: Int](ctx: DeviceContext, b: Bufs, n: Int, k: Int, prep: Bool) raises:
    if prep:
        ctx.enqueue_function[lkh.pack_x](b.x, b.xa.create_sub_buffer[DType.uint32](0, ROWS * k // 2), Int32(k), Int32(ROWS * k // 8),
                                         grid_dim=(ROWS * k // 8 + 255) // 256, block_dim=256)
        ctx.enqueue_function[lkh.deq_w](b.wq, b.ws, b.wd.create_sub_buffer[DType.uint32](0, n * k // 2), Int32(n), Int32(k), Int32(n * k // 256),
                                        grid_dim=(n * k // 256 + 255) // 256, block_dim=256)
    var chunks = (k + CH - 1) // CH
    ctx.enqueue_function[lkh.gemm_h[WM, WN, TN, CH]](
        b.xa, b.wd, b.part, Int32(n), Int32(k), Int32(ROWS), grid_dim=Dim(n // (64 * WN * TN), ROWS // (64 * WM), chunks),
        block_dim=64 * WM * WN)
    ctx.enqueue_function[lkh.sum_parts](b.part, b.y, Int32(ROWS * n), Int32(chunks), grid_dim=(ROWS * n // 8 + 255) // 256,
                                        block_dim=256)


def hq[WM: Int, WN: Int, CH: Int, BKS: Int, RG: Int, ALONG_K: Bool](ctx: DeviceContext, b: Bufs, n: Int, k: Int,
                                                                   prep: Bool) raises:
    if prep:
        ctx.enqueue_function[lkh.pack_x](b.x, b.xa.create_sub_buffer[DType.uint32](0, ROWS * k // 2), Int32(k), Int32(ROWS * k // 8),
                                         grid_dim=(ROWS * k // 8 + 255) // 256, block_dim=256)
    var chunks = (k + CH - 1) // CH
    ctx.enqueue_function[lkh.gemm_hq[WM, WN, CH, BKS, RG, ALONG_K]](
        b.xa, b.wq, b.ws, b.part, Int32(n), Int32(k), Int32(ROWS), grid_dim=Dim(n // (64 * WN), ROWS // (64 * WM), chunks),
        block_dim=64 * WM * WN)
    ctx.enqueue_function[lkh.sum_parts](b.part, b.y, Int32(ROWS * n), Int32(chunks), grid_dim=(ROWS * n // 8 + 255) // 256,
                                        block_dim=256)


comptime NV = 25


def launch(ctx: DeviceContext, v: Int, b: Bufs, n: Int, k: Int, prep: Bool) raises:
    if v == 0:
        ctx.enqueue_function[lk.gemm_q4](b.wq, b.ws, b.x, b.y, Int64(n), Int64(k), grid_dim=Dim(n // 128, ROWS // 128),
                                         block_dim=256)
    elif v == 1:
        h[2, 2, 1, 2048](ctx, b, n, k, prep)
    elif v == 2:
        h[2, 2, 2, 2048](ctx, b, n, k, prep)
    elif v == 3:
        h[2, 4, 1, 2048](ctx, b, n, k, prep)
    elif v == 4:
        h[4, 2, 1, 2048](ctx, b, n, k, prep)
    elif v == 5:
        h[1, 2, 2, 2048](ctx, b, n, k, prep)
    elif v == 6:
        h[2, 2, 1, 1024](ctx, b, n, k, prep)
    elif v == 7:
        h[2, 2, 2, 1024](ctx, b, n, k, prep)
    elif v == 8:
        h[4, 1, 2, 2048](ctx, b, n, k, prep)
    elif v == 9:
        hq[4, 1, 2048, 64, 4, True](ctx, b, n, k, prep)
    elif v == 10:
        hq[4, 1, 2048, 64, 4, False](ctx, b, n, k, prep)
    elif v == 11:
        hq[4, 1, 2048, 64, 2, True](ctx, b, n, k, prep)
    elif v == 12:
        hq[4, 1, 2048, 64, 8, True](ctx, b, n, k, prep)
    elif v == 13:
        hq[4, 1, 2048, 32, 4, True](ctx, b, n, k, prep)
    elif v == 14:
        hq[4, 2, 2048, 64, 2, True](ctx, b, n, k, prep)
    elif v == 15:
        hq[4, 2, 2048, 32, 4, True](ctx, b, n, k, prep)
    elif v == 16:
        hq[2, 2, 2048, 64, 2, True](ctx, b, n, k, prep)
    elif v == 17:
        hq[2, 2, 2048, 16, 2, True](ctx, b, n, k, prep)
    elif v == 18:
        hq[4, 1, 2048, 32, 4, False](ctx, b, n, k, prep)
    elif v == 19:
        hq[4, 1, 2048, 128, 4, False](ctx, b, n, k, prep)
    elif v == 20:
        hq[4, 1, 2048, 64, 2, False](ctx, b, n, k, prep)
    elif v == 21:
        hq[4, 1, 2048, 64, 8, False](ctx, b, n, k, prep)
    elif v == 22:
        hq[2, 1, 2048, 64, 4, False](ctx, b, n, k, prep)
    elif v == 23:
        hq[8, 1, 2048, 64, 4, False](ctx, b, n, k, prep)
    elif v == 24:
        hq[4, 1, 1024, 64, 4, False](ctx, b, n, k, prep)


def label(v: Int) -> String:
    var names: List[String] = ["lk.gemm_q4 (fp32 coopmat)", "h w2x2 t1 c2048", "h w2x2 t2 c2048", "h w2x4 t1 c2048",
                               "h w4x2 t1 c2048", "h w1x2 t2 c2048", "h w2x2 t1 c1024", "h w2x2 t2 c1024", "h w4x1 t2 c2048",
                               "hq w4x1 k64 rg4 alongK", "hq w4x1 k64 rg4 alongN", "hq w4x1 k64 rg2 alongK",
                               "hq w4x1 k64 rg8 alongK", "hq w4x1 k32 rg4 alongK", "hq w4x2 k64 rg2 alongK",
                               "hq w4x2 k32 rg4 alongK", "hq w2x2 k64 rg2 alongK", "hq w2x2 k16 rg2 alongK",
                               "hq w4x1 k32 rg4 alongN", "hq w4x1 k128 rg4 alongN", "hq w4x1 k64 rg2 alongN",
                               "hq w4x1 k64 rg8 alongN", "hq w2x1 k64 rg4 alongN", "hq w8x1 k64 rg4 alongN",
                               "hq w4x1 c1024 k64 rg4 alongN"]
    return names[v]


def main() raises:
    var args = argv()
    var reps = Int(args[1]) if len(args) > 1 else 10
    var only = Int(args[2]) if len(args) > 2 else -1
    var onlyv = Int(args[3]) if len(args) > 3 else -1
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name(), "; rows:", ROWS, "; reps:", reps)
    var shapes: List[Tuple[Int, Int, String]] = [(6144, 2560, "q|k|v"), (2560, 4096, "o"), (19456, 2560, "gate|up"),
                                                  (2560, 9728, "down")]
    for si in range(len(shapes)):
        if only >= 0 and si != only:
            continue
        var n = shapes[si][0]
        var k = shapes[si][1]
        var b = Bufs(ctx, n, k)
        var hw = List[UInt32](length=n * k // 8, fill=0)
        var state = UInt32(2463534242)
        for i in range(len(hw)):
            state ^= state << 13
            state ^= state >> 17
            state ^= state << 5
            hw[i] = state
        ctx.enqueue_copy(b.wq, hw.unsafe_ptr())
        var hs = List[Float16](length=n * k // 32, fill=0)
        for i in range(len(hs)):
            hs[i] = Float16(Float32(0.5 + Float32((i * 2654435761) % 1000) / 1000.0) / 16.0)
        ctx.enqueue_copy(b.ws, hs.unsafe_ptr())
        var hx = List[Float32](length=ROWS * k, fill=0)
        for i in range(len(hx)):
            hx[i] = Float32((i * 7919) % 2001) / 1000.0 - 1.0
        ctx.enqueue_copy(b.x, hx.unsafe_ptr())
        ctx.synchronize()
        var gflop = 2.0 * Float64(ROWS) * Float64(n) * Float64(k) / 1e9
        print("shape", shapes[si][2], n, "x", k, ":", round(gflop, 2), "GFLOP")
        var refv = List[Float32](length=ROWS * n, fill=0)
        var got = List[Float32](length=ROWS * n, fill=0)
        launch(ctx, 0, b, n, k, True)  # the reference: gemm_q4's output
        ctx.synchronize()
        ctx.enqueue_copy(refv.unsafe_ptr(), b.y)
        ctx.synchronize()
        for v in range(NV):
            if onlyv >= 0 and v != onlyv:
                continue
            launch(ctx, v, b, n, k, True)
            ctx.synchronize()
            var err = Float64(0)
            if v != 0:
                ctx.enqueue_copy(got.unsafe_ptr(), b.y)
                ctx.synchronize()
                var big = Float64(1e-30)
                var worst = Float64(0)
                var nans = 0
                for i in range(len(refv)):
                    big = max(big, abs(Float64(refv[i])))
                    var d = abs(Float64(got[i]) - Float64(refv[i]))
                    if not (d <= 1e30):
                        nans += 1
                        continue
                    worst = max(worst, d)
                err = worst / big
                if nans:
                    print("   NaN outputs:", nans)
            for _ in range(2):
                launch(ctx, v, b, n, k, True)
            ctx.synchronize()
            var t0 = now_ms()
            for _ in range(reps):
                launch(ctx, v, b, n, k, True)
            ctx.synchronize()
            var ms = (now_ms() - t0) / Float64(reps)
            var t1 = now_ms()
            for _ in range(reps):
                launch(ctx, v, b, n, k, False)
            ctx.synchronize()
            var ms2 = (now_ms() - t1) / Float64(reps)
            print("  ", label(v), ":", round(ms, 2), "ms", round(gflop / ms, 2), "TFLOP/s ; without pack_x + deq_w",
                  round(ms2, 2), "ms", round(gflop / ms2, 2), "TFLOP/s ; err", err)
