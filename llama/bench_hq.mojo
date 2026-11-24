# Prefill projections with a scale per 64 weights (llama's and gemma4's storage) on the phone's Adreno 840: the fp32
# cooperative-matrix kernels the models use (llama's p_gemm_q4 and p_gemm, gemma4's p_gemm_q8) against lkh.gemm_hq,
# which unpacks the same rows into fp16 shared memory inside an fp16 cooperative product, K in chunks added in fp32
# (pack_x: X into fp16 R tiles first). At a 512-row prompt and the shapes of Llama 3.2 1B (q|k|v 3072 x 2048, o
# 2048 x 2048, gate|up 16384 x 2048, down 2048 x 8192) and Gemma 4 E2B (q|k|v 2560 x 1536, o 1536 x 2048, gate|up
# 12288 x 1536, down 1536 x 6144). Each variant is checked against the fp32 kernel's output (the largest difference
# over the largest output, and NaNs) and timed with and without pack_x.
#
#   bench_hq [reps] [format] [shape] [variant]   format: 0 int4, 1 int8, 2 fp16; shape 0-11 (8-11: Llama 3.2 3B);
#                                                variant 0-7 (5-7: two accumulators a subgroup, TN = 2)
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import lkh
import p_gemm
import p_gemm_q4
import p_gemm_q8

comptime ROWS = 512
comptime GS = 64


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


struct Bufs(Movable):
    var wq: DeviceBuffer[DType.uint32]  # int4 or int8 words, or fp16 weights as pairs
    var wh: DeviceBuffer[DType.float16]  # fp16 weights (the same bytes as wq for fp16)
    var ws: DeviceBuffer[DType.float16]
    var x: DeviceBuffer[DType.float32]
    var xa: DeviceBuffer[DType.float16]
    var y: DeviceBuffer[DType.float32]
    var part: DeviceBuffer[DType.float16]

    def __init__(out self, ctx: DeviceContext, n: Int, k: Int) raises:
        self.wh = ctx.enqueue_create_buffer[DType.float16](n * k)
        self.wq = self.wh.create_sub_buffer[DType.uint32](0, n * k // 2)
        self.ws = ctx.enqueue_create_buffer[DType.float16](n * k // GS)
        self.x = ctx.enqueue_create_buffer[DType.float32](ROWS * k)
        self.xa = ctx.enqueue_create_buffer[DType.float16](ROWS * k)
        self.y = ctx.enqueue_create_buffer[DType.float32](ROWS * n)
        self.part = ctx.enqueue_create_buffer[DType.float16]((k + 1023) // 1024 * ROWS * n)  # chunks of 1024 or more


def hq[WM: Int, CH: Int, RG: Int, ALONG_K: Bool, FMT: Int, TN: Int = 1, BKS: Int = 64, WN: Int = 1](
    ctx: DeviceContext, b: Bufs, n: Int, k: Int, prep: Bool
) raises:
    if prep:
        ctx.enqueue_function[lkh.pack_x](b.x, b.xa.create_sub_buffer[DType.uint32](0, ROWS * k // 2), Int32(k),
                                         Int32(ROWS * k // 8), grid_dim=(ROWS * k // 8 + 255) // 256, block_dim=256)
    var chunks = (k + CH - 1) // CH
    ctx.enqueue_function[lkh.gemm_hq[WM, WN, CH, BKS, RG, ALONG_K, GS, FMT, TN]](
        b.xa, b.wq, b.ws, b.part, Int32(n), Int32(k), Int32(ROWS),
        grid_dim=Dim(n // (64 * TN * WN), ROWS // (64 * WM), chunks), block_dim=64 * WM * WN)
    ctx.enqueue_function[lkh.sum_parts](b.part, b.y, Int32(ROWS * n), Int32(chunks),
                                        grid_dim=(ROWS * n // 8 + 255) // 256, block_dim=256)


def variant[FMT: Int](ctx: DeviceContext, v: Int, b: Bufs, n: Int, k: Int, prep: Bool) raises:
    if v == 0:
        var grid = Dim(n // 128, ROWS // 128)
        comptime if FMT == lkh.Q4:
            ctx.enqueue_function[p_gemm_q4.p_gemm_q4](b.wq, b.ws, b.x, b.y, Int64(n), Int64(k), grid_dim=grid,
                                                      block_dim=256)
        elif FMT == lkh.Q8:
            ctx.enqueue_function[p_gemm_q8.p_gemm_q8](b.wq, b.ws, b.x, b.y, Int64(n), Int64(k), grid_dim=grid,
                                                      block_dim=256)
        else:
            ctx.enqueue_function[p_gemm.p_gemm](b.wh, b.x, b.y, Int64(n), Int64(k), grid_dim=grid, block_dim=256)
    elif v == 1:
        hq[2, 2048, 4, False, FMT](ctx, b, n, k, prep)
    elif v == 2:
        hq[2, 2048, 4, True, FMT](ctx, b, n, k, prep)
    elif v == 3:
        hq[4, 2048, 4, False, FMT](ctx, b, n, k, prep)
    elif v == 4:
        hq[2, 1024, 4, False, FMT](ctx, b, n, k, prep)
    elif v == 5:
        hq[2, 1024, 4, False, FMT, 2](ctx, b, n, k, prep)
    elif v == 6:
        hq[4, 1024, 4, False, FMT, 2](ctx, b, n, k, prep)
    elif v == 7:
        hq[2, 2048, 4, False, FMT, 2](ctx, b, n, k, prep)
    elif v == 8:
        hq[2, 1024, 4, True, FMT](ctx, b, n, k, prep)
    elif v == 9:
        hq[2, 1024, 4, False, FMT, 1, 128](ctx, b, n, k, prep)
    elif v == 10:
        hq[2, 1024, 4, True, FMT, 1, 128](ctx, b, n, k, prep)
    elif v == 11:
        hq[2, 1024, 4, False, FMT, 1, 64, 2](ctx, b, n, k, prep)
    elif v == 12:
        hq[2, 1024, 8, True, FMT](ctx, b, n, k, prep)


def launch(ctx: DeviceContext, fmt: Int, v: Int, b: Bufs, n: Int, k: Int, prep: Bool) raises:
    if fmt == 0:
        variant[lkh.Q4](ctx, v, b, n, k, prep)
    elif fmt == 1:
        variant[lkh.Q8](ctx, v, b, n, k, prep)
    else:
        variant[lkh.FP16](ctx, v, b, n, k, prep)


comptime NV = 13


def main() raises:
    var args = argv()
    var reps = Int(args[1]) if len(args) > 1 else 10
    var fmt = Int(args[2]) if len(args) > 2 else 0
    var only = Int(args[3]) if len(args) > 3 else -1
    var onlyv = Int(args[4]) if len(args) > 4 else -1
    var fmts: List[String] = ["int4", "int8", "fp16"]
    var labels: List[String] = ["fp32 coopmat (the model's)", "hq w2 c2048 rg4 alongN", "hq w2 c2048 rg4 alongK",
                                "hq w4 c2048 rg4 alongN", "hq w2 c1024 rg4 alongN", "hq w2 c1024 TN2",
                                "hq w4 c1024 TN2", "hq w2 c2048 TN2", "hq w2 c1024 alongK", "hq w2 c1024 k128 alongN",
                                "hq w2 c1024 k128 alongK", "hq w2x2 c1024 alongN", "hq w2 c1024 rg8 alongK"]
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name(), "; rows:", ROWS, "; reps:", reps, "; weights:", fmts[fmt])
    var shapes: List[Tuple[Int, Int, String]] = [
        (3072, 2048, "llama q|k|v"), (2048, 2048, "llama o"), (16384, 2048, "llama gate|up"),
        (2048, 8192, "llama down"), (2560, 1536, "e2b q|k|v"), (1536, 2048, "e2b o"), (12288, 1536, "e2b gate|up"),
        (1536, 6144, "e2b down"), (5120, 3072, "3b q|k|v"), (3072, 3072, "3b o"), (16384, 3072, "3b gate|up"),
        (3072, 8192, "3b down")]
    for si in range(len(shapes)):
        if only >= 0 and si != only:
            continue
        var n = shapes[si][0]
        var k = shapes[si][1]
        var b = Bufs(ctx, n, k)
        var state = UInt32(2463534242)
        if fmt == 2:  # fp16 weights in [-1/16, 1/16]
            var hw = List[Float16](length=n * k, fill=0)
            for i in range(len(hw)):
                state ^= state << 13
                state ^= state >> 17
                state ^= state << 5
                hw[i] = Float16((Float32(state % 2001) / 1000.0 - 1.0) / 16.0)
            ctx.enqueue_copy(b.wh, hw.unsafe_ptr())
        else:  # random words: int4 -8..7 or int8 -128..127
            var hw = List[UInt32](length=n * k // 2, fill=0)
            for i in range(len(hw)):
                state ^= state << 13
                state ^= state >> 17
                state ^= state << 5
                hw[i] = state
            ctx.enqueue_copy(b.wq, hw.unsafe_ptr())
        var hs = List[Float16](length=n * k // GS, fill=0)
        var unit = Float32(1.0 / 16.0) if fmt == 0 else Float32(1.0 / 256.0)
        for i in range(len(hs)):
            hs[i] = Float16(Float32(0.5 + Float32((i * 2654435761) % 1000) / 1000.0) * unit)
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
        launch(ctx, fmt, 0, b, n, k, True)  # the reference: the fp32 kernel's output
        ctx.synchronize()
        ctx.enqueue_copy(refv.unsafe_ptr(), b.y)
        ctx.synchronize()
        for v in range(NV):
            if onlyv >= 0 and v != onlyv:
                continue
            launch(ctx, fmt, v, b, n, k, True)
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
                launch(ctx, fmt, v, b, n, k, True)
            ctx.synchronize()
            var t0 = now_ms()
            for _ in range(reps):
                launch(ctx, fmt, v, b, n, k, True)
            ctx.synchronize()
            var ms = (now_ms() - t0) / Float64(reps)
            var t1 = now_ms()
            for _ in range(reps):
                launch(ctx, fmt, v, b, n, k, False)
            ctx.synchronize()
            var ms2 = (now_ms() - t1) / Float64(reps)
            print("  ", labels[v], ":", round(ms, 2), "ms", round(gflop / ms, 2), "TFLOP/s ; without pack_x",
                  round(ms2, 2), "ms", round(gflop / ms2, 2), "TFLOP/s ; err", err)
