# Llama 3.2 3B's prefill projections (512 rows, int4 with a scale per 64) on the Adreno 850: the 840-tuned lkh.gemm_hq
# (K in chunks of 1024 added in fp32, B N-major in shared memory) against lkh.gemm_k (B K-minor in shared memory, one
# fp16 accumulator over the whole K: the 850's layouts). Each variant is checked against llama's fp32 kernel p_gemm_q4
# (the largest difference over the largest output) and timed with pack_x and sum_parts (as the model runs it) and alone.
#
#   bench_k [reps] [shape 0-3] [variant]
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import lkh
import p_gemm_q4

comptime ROWS = 512
comptime GS = 64


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


struct Bufs(Movable):
    var wq: DeviceBuffer[DType.uint32]
    var ws: DeviceBuffer[DType.float16]
    var x: DeviceBuffer[DType.float32]
    var xa: DeviceBuffer[DType.float16]
    var y: DeviceBuffer[DType.float32]
    var part: DeviceBuffer[DType.float16]
    var ss: DeviceBuffer[DType.float32]
    var xo: DeviceBuffer[DType.float16]
    var wp: DeviceBuffer[DType.uint32]  # repack_q4's panels (K steps of 32)
    var sp: DeviceBuffer[DType.float16]

    def __init__(out self, ctx: DeviceContext, n: Int, k: Int) raises:
        self.wq = ctx.enqueue_create_buffer[DType.uint32](n * k // 8)
        self.ws = ctx.enqueue_create_buffer[DType.float16](n * k // GS)
        self.x = ctx.enqueue_create_buffer[DType.float32](ROWS * k)
        self.xa = ctx.enqueue_create_buffer[DType.float16](ROWS * k)
        self.y = ctx.enqueue_create_buffer[DType.float32](ROWS * n)
        self.part = ctx.enqueue_create_buffer[DType.float16]((k + 1023) // 1024 * ROWS * n)
        self.ss = ctx.enqueue_create_buffer[DType.float32](ROWS * n // 64)
        self.xo = ctx.enqueue_create_buffer[DType.float16](ROWS * n // 2)
        self.wp = ctx.enqueue_create_buffer[DType.uint32](n * k // 8)
        self.sp = ctx.enqueue_create_buffer[DType.float16](n * k // GS)


def pack(ctx: DeviceContext, b: Bufs, k: Int) raises:
    ctx.enqueue_function[lkh.pack_x](b.x, b.xa.create_sub_buffer[DType.uint32](0, ROWS * k // 2), Int32(k),
                                     Int32(ROWS * k // 8), grid_dim=(ROWS * k // 8 + 255) // 256, block_dim=256)


def sums(ctx: DeviceContext, b: Bufs, n: Int, chunks: Int) raises:
    ctx.enqueue_function[lkh.sum_parts](b.part, b.y, Int32(ROWS * n), Int32(chunks),
                                        grid_dim=(ROWS * n // 8 + 255) // 256, block_dim=256)


def hq[CH: Int, BKS: Int](ctx: DeviceContext, b: Bufs, n: Int, k: Int, mode: Int) raises:
    """mode 0: pack_x + product + sum_parts; 1: the product alone."""
    if mode == 0:
        pack(ctx, b, k)
    var chunks = (k + CH - 1) // CH
    ctx.enqueue_function[lkh.gemm_hq[2, 1, CH, BKS, 4, False, GS, lkh.Q4]](
        b.xa, b.wq, b.ws, b.part, Int32(n), Int32(k), Int32(ROWS), grid_dim=Dim(n // 64, ROWS // 128, chunks),
        block_dim=128)
    if mode == 0:
        sums(ctx, b, n, chunks)


def gk[WM: Int, WN: Int, BKS: Int, RG: Int, ALONG_K: Bool, PAD: Int = 8, REG: Bool = False, PANEL: Bool = False](
    ctx: DeviceContext, b: Bufs, n: Int, k: Int, mode: Int
) raises:
    if mode == 0:
        pack(ctx, b, k)
    var wq = b.wp if PANEL else b.wq
    var ws = b.sp if PANEL else b.ws
    ctx.enqueue_function[lkh.gemm_k[WM, WN, BKS, RG, ALONG_K, GS, lkh.Q4, PAD, REG, PANEL]](
        b.xa, wq, ws, b.part, Int32(n), Int32(k), Int32(ROWS), grid_dim=Dim(n // (64 * WN), ROWS // (64 * WM)),
        block_dim=64 * WM * WN)
    if mode == 0:
        sums(ctx, b, n, 1)


def gka[WM: Int, WN: Int, BKS: Int, REG: Bool = False, PANEL: Bool = False](
    ctx: DeviceContext, b: Bufs, n: Int, k: Int, mode: Int
) raises:
    """gemm_k_add: y += X W^T (and the sums of squares); y zeroed first in mode 0."""
    if mode == 0:
        pack(ctx, b, k)
        b.y.enqueue_fill(0)
    ctx.enqueue_function[lkh.gemm_k_add[WM, WN, BKS, 1, True, REG=REG, PANEL=PANEL]](
        b.xa, b.wp if PANEL else b.wq, b.sp if PANEL else b.ws, b.y, b.ss, Int32(n), Int32(k), Int32(ROWS), grid_dim=Dim(n // (64 * WN), ROWS // (64 * WM)),
        block_dim=64 * WM * WN)


def gks[WM: Int, BKS: Int, REG: Bool = False, PANEL: Bool = False](
    ctx: DeviceContext, b: Bufs, n: Int, k: Int, mode: Int
) raises:
    """gemm_k_swiglu (no error check: its output is silu(gate) up packed)."""
    if mode == 0:
        pack(ctx, b, k)
    ctx.enqueue_function[lkh.gemm_k_swiglu[WM, BKS, 1, True, REG=REG, PANEL=PANEL]](
        b.xa, b.wp if PANEL else b.wq, b.sp if PANEL else b.ws, b.xo.create_sub_buffer[DType.uint32](0, ROWS * n // 4), Int32(n // 2), Int32(k),
        grid_dim=Dim(n // 128, ROWS // (64 * WM)), block_dim=128 * WM)


comptime NV = 42


def launch(ctx: DeviceContext, v: Int, b: Bufs, n: Int, k: Int, mode: Int) raises:
    if v == 0:
        ctx.enqueue_function[p_gemm_q4.p_gemm_q4](b.wq, b.ws, b.x, b.y, Int64(n), Int64(k),
                                                  grid_dim=Dim(n // 128, ROWS // 128), block_dim=256)
    elif v == 1:
        if k > 4096:
            hq[1024, 128](ctx, b, n, k, mode)
        else:
            hq[1024, 64](ctx, b, n, k, mode)
    elif v == 2:
        hq[8192, 64](ctx, b, n, k, mode)
    elif v == 3:
        gk[2, 1, 64, 1, True](ctx, b, n, k, mode)
    elif v == 4:
        gk[2, 1, 64, 1, False](ctx, b, n, k, mode)
    elif v == 5:
        gk[4, 1, 64, 1, True](ctx, b, n, k, mode)
    elif v == 6:
        gk[2, 2, 64, 1, True](ctx, b, n, k, mode)
    elif v == 7:
        gk[4, 2, 64, 1, True](ctx, b, n, k, mode)
    elif v == 8:
        gk[2, 1, 128, 1, True](ctx, b, n, k, mode)
    elif v == 9:
        gk[4, 1, 128, 1, True](ctx, b, n, k, mode)
    elif v == 10:
        gk[2, 1, 64, 1, True, 0](ctx, b, n, k, mode)
    elif v == 11:
        gk[2, 1, 64, 2, True](ctx, b, n, k, mode)
    elif v == 12:
        gk[1, 1, 64, 1, True](ctx, b, n, k, mode)
    elif v == 13:
        gka[4, 1, 128](ctx, b, n, k, mode)
    elif v == 14:
        gka[4, 1, 64](ctx, b, n, k, mode)
    elif v == 15:
        gka[2, 2, 64](ctx, b, n, k, mode)
    elif v == 16:
        gka[2, 1, 128](ctx, b, n, k, mode)
    elif v == 17:
        gks[2, 64](ctx, b, n, k, mode)
    elif v == 18:
        gks[1, 64](ctx, b, n, k, mode)
    elif v == 19:
        gks[2, 128](ctx, b, n, k, mode)
    elif v == 20:
        gk[2, 2, 32, 1, True, 8, True](ctx, b, n, k, mode)
    elif v == 21:
        gk[4, 2, 32, 1, True, 8, True](ctx, b, n, k, mode)
    elif v == 22:
        gk[2, 2, 16, 1, True, 8, True](ctx, b, n, k, mode)
    elif v == 23:
        gk[2, 1, 32, 1, True, 8, True](ctx, b, n, k, mode)
    elif v == 24:
        gk[1, 1, 32, 1, True, 8, True](ctx, b, n, k, mode)
    elif v == 25:
        gk[4, 1, 32, 1, True, 8, True](ctx, b, n, k, mode)
    elif v == 26:
        gk[2, 2, 64, 1, True, 8, True](ctx, b, n, k, mode)
    elif v == 27:
        gk[1, 4, 32, 1, True, 8, True](ctx, b, n, k, mode)
    elif v == 28:
        gka[2, 2, 32, True](ctx, b, n, k, mode)
    elif v == 29:
        gks[2, 32, True](ctx, b, n, k, mode)
    elif v == 30:
        gks[1, 32, True](ctx, b, n, k, mode)
    elif v == 31:
        gk[2, 2, 32, 1, True, 8, True, True](ctx, b, n, k, mode)
    elif v == 32:
        gk[4, 2, 32, 1, True, 8, True, True](ctx, b, n, k, mode)
    elif v == 33:
        gk[2, 1, 32, 1, True, 8, True, True](ctx, b, n, k, mode)
    elif v == 34:
        gk[1, 1, 32, 1, True, 8, True, True](ctx, b, n, k, mode)
    elif v == 35:
        gk[4, 1, 32, 1, True, 8, True, True](ctx, b, n, k, mode)
    elif v == 36:
        gk[1, 4, 32, 1, True, 8, True, True](ctx, b, n, k, mode)
    elif v == 37:
        gk[2, 4, 32, 1, True, 8, True, True](ctx, b, n, k, mode)
    elif v == 38:
        gka[2, 2, 32, True, True](ctx, b, n, k, mode)
    elif v == 39:
        gks[2, 32, True, True](ctx, b, n, k, mode)
    elif v == 40:
        gka[2, 1, 32, True, True](ctx, b, n, k, mode)
    elif v == 41:
        gka[4, 1, 32, True, True](ctx, b, n, k, mode)


def main() raises:
    var args = argv()
    var reps = Int(args[1]) if len(args) > 1 else 10
    var only = Int(args[2]) if len(args) > 2 else -1
    var onlyv = Int(args[3]) if len(args) > 3 else -1
    var labels: List[String] = ["fp32 p_gemm_q4", "hq 840 config (CH 1024)", "hq one chunk", "k w2x1 b64 alongK",
                                "k w2x1 b64 alongN", "k w4x1 b64 alongK", "k w2x2 b64 alongK", "k w4x2 b64 alongK",
                                "k w2x1 b128 alongK", "k w4x1 b128 alongK", "k w2x1 b64 nopad", "k w2x1 b64 rg2",
                                "k w1x1 b64 alongK", "k_add w4x1 b128", "k_add w4x1 b64", "k_add w2x2 b64",
                                "k_add w2x1 b128", "k_swiglu w2 b64", "k_swiglu w1 b64", "k_swiglu w2 b128",
                                "REG w2x2 k32", "REG w4x2 k32", "REG w2x2 k16", "REG w2x1 k32", "REG w1x1 k32",
                                "REG w4x1 k32", "REG w2x2 k64", "REG w1x4 k32", "REG add w2x2 k32",
                                "REG swiglu w2 k32", "REG swiglu w1 k32", "P w2x2", "P w4x2", "P w2x1", "P w1x1",
                                "P w4x1", "P w1x4", "P w2x4", "P add w2x2", "P swiglu w2", "P add w2x1",
                                "P add w4x1"]
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name(), "; rows:", ROWS, "; reps:", reps)
    var shapes: List[Tuple[Int, Int, String]] = [(5120, 3072, "3b q|k|v"), (3072, 3072, "3b o"),
                                                 (16384, 3072, "3b gate|up"), (3072, 8192, "3b down")]
    for si in range(len(shapes)):
        if only >= 0 and si != only:
            continue
        var n = shapes[si][0]
        var k = shapes[si][1]
        var b = Bufs(ctx, n, k)
        var state = UInt32(2463534242)
        var hw = List[UInt32](length=n * k // 8, fill=0)
        for i in range(len(hw)):
            state ^= state << 13
            state ^= state >> 17
            state ^= state << 5
            hw[i] = state
        ctx.enqueue_copy(b.wq, hw.unsafe_ptr())
        var hs = List[Float16](length=n * k // GS, fill=0)
        for i in range(len(hs)):
            hs[i] = Float16(Float32(0.5 + Float32((i * 2654435761) % 1000) / 1000.0) / 16.0)
        ctx.enqueue_copy(b.ws, hs.unsafe_ptr())
        var hx = List[Float32](length=ROWS * k, fill=0)
        for i in range(len(hx)):
            hx[i] = Float32((i * 7919) % 2001) / 1000.0 - 1.0
        ctx.enqueue_copy(b.x, hx.unsafe_ptr())
        ctx.enqueue_function[lkh.repack_q4[4]](b.wq, b.ws, b.wp, b.sp, Int32(n), Int32(k),
                                              grid_dim=(n * k // 32 + 255) // 256, block_dim=256)
        ctx.synchronize()
        var gflop = 2.0 * Float64(ROWS) * Float64(n) * Float64(k) / 1e9
        print("shape", shapes[si][2], n, "x", k, ":", round(gflop, 2), "GFLOP")
        var refv = List[Float32](length=ROWS * n, fill=0)
        var got = List[Float32](length=ROWS * n, fill=0)
        launch(ctx, 0, b, n, k, 0)
        ctx.synchronize()
        ctx.enqueue_copy(refv.unsafe_ptr(), b.y)
        ctx.synchronize()
        for v in range(NV):
            if onlyv >= 0 and v != onlyv:
                continue
            b.y.enqueue_fill(0)
            launch(ctx, v, b, n, k, 0)
            ctx.synchronize()
            var err = Float64(0)
            if v != 0 and (v < 17 or (v >= 20 and v < 29) or (v >= 31 and v < 39) or v >= 40):
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
                launch(ctx, v, b, n, k, 0)
            ctx.synchronize()
            var t0 = now_ms()
            for _ in range(reps):
                launch(ctx, v, b, n, k, 0)
            ctx.synchronize()
            var ms = (now_ms() - t0) / Float64(reps)
            var t1 = now_ms()
            for _ in range(reps):
                launch(ctx, v, b, n, k, 1)
            ctx.synchronize()
            var ms2 = (now_ms() - t1) / Float64(reps)
            print("  ", v, labels[v], ":", round(ms, 3), "ms", round(gflop / ms, 2), "TFLOP/s ; product alone",
                  round(ms2, 3), "ms", round(gflop / ms2, 2), "TFLOP/s ; err", err)
