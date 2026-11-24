# Qwen3-30B-A3B's expert layer in a prefill batch, on the phone's Adreno 840 (the model itself needs the X2 Elite
# laptop's 16 GB): the fp32 path qwen3moe/model.mojo runs by default (p_expert_lists, p_expert_items, t_moe_gate_up and
# t_moe_down: a matrix row a lane against 8 tokens, then p_moe_sum) against QWEN3MOE_GEMM=q's (lkh.group, pack_gather,
# gemm_hqg for gate|up and down on fp16 cooperative matrices, swiglu_pack, combine). Random int4 experts with the
# model's sizes (128 of SwiGLU 768 on hidden 2048, a scale per 128), random activations, and the router's top 8 of
# random logits (moek.p_route). Each batch size: the largest difference over the largest output, NaNs, and the time of
# both paths.
#
#   bench_moe [reps] [tokens]     tokens: one batch size (a multiple of 8, at most 256); 32, 64, 128, 256 by default
from std.math import exp
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import lkh
import moek

comptime D = 2048
comptime E = 128
comptime TOPK = 8
comptime FE = 768
comptime PMAX = 256
comptime GCH = 2048
comptime TMG = 64
comptime MAXG = (PMAX * TOPK + E * (TMG - 1) + TMG - 1) // TMG * TMG


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


struct Bufs(Movable):
    var guq: DeviceBuffer[DType.uint32]
    var gus: DeviceBuffer[DType.float16]
    var dq: DeviceBuffer[DType.uint32]
    var ds: DeviceBuffer[DType.float16]
    var x: DeviceBuffer[DType.float32]
    var y: DeviceBuffer[DType.float32]
    var rl: DeviceBuffer[DType.float32]
    var ids: DeviceBuffer[DType.int32]
    var wts: DeviceBuffer[DType.float32]
    # the fp32 path
    var lists: DeviceBuffer[DType.int32]
    var counts: DeviceBuffer[DType.int32]
    var items: DeviceBuffer[DType.int32]
    var nitems: DeviceBuffer[DType.int32]
    var a: DeviceBuffer[DType.float32]
    var part32: DeviceBuffer[DType.float32]
    # lkh's
    var xa: DeviceBuffer[DType.float16]
    var part: DeviceBuffer[DType.float16]
    var slot: DeviceBuffer[DType.int32]
    var src: DeviceBuffer[DType.int32]
    var tiles: DeviceBuffer[DType.int32]
    var ntiles: DeviceBuffer[DType.int32]

    def __init__(out self, ctx: DeviceContext) raises:
        self.guq = ctx.enqueue_create_buffer[DType.uint32](E * 2 * FE * D // 8)
        self.gus = ctx.enqueue_create_buffer[DType.float16](E * 2 * FE * D // moek.GE)
        self.dq = ctx.enqueue_create_buffer[DType.uint32](E * D * FE // 8)
        self.ds = ctx.enqueue_create_buffer[DType.float16](E * D * FE // moek.GE)
        self.x = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.y = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.rl = ctx.enqueue_create_buffer[DType.float32](PMAX * E)
        self.ids = ctx.enqueue_create_buffer[DType.int32](PMAX * TOPK)
        self.wts = ctx.enqueue_create_buffer[DType.float32](PMAX * TOPK)
        self.lists = ctx.enqueue_create_buffer[DType.int32](E * PMAX)
        self.counts = ctx.enqueue_create_buffer[DType.int32](E)
        self.items = ctx.enqueue_create_buffer[DType.int32](2 * (PMAX + E))
        self.nitems = ctx.enqueue_create_buffer[DType.int32](1)
        self.a = ctx.enqueue_create_buffer[DType.float32](PMAX * TOPK * FE)
        self.part32 = ctx.enqueue_create_buffer[DType.float32](PMAX * TOPK * D)
        self.xa = ctx.enqueue_create_buffer[DType.float16](MAXG * D)
        self.part = ctx.enqueue_create_buffer[DType.float16](MAXG * D)
        self.slot = ctx.enqueue_create_buffer[DType.int32](PMAX * TOPK)
        self.src = ctx.enqueue_create_buffer[DType.int32](MAXG)
        self.tiles = ctx.enqueue_create_buffer[DType.int32](2 * (MAXG // TMG))
        self.ntiles = ctx.enqueue_create_buffer[DType.int32](1)


def fp32_path(ctx: DeviceContext, b: Bufs, count: Int) raises:
    var c = Int32(count)
    b.y.enqueue_fill(0)
    ctx.enqueue_function[moek.p_expert_lists](b.ids, b.lists, b.counts, c, grid_dim=E, block_dim=64)
    ctx.enqueue_function[moek.p_expert_items](b.counts, b.items, b.nitems, grid_dim=1, block_dim=64)
    var items = groups(count * TOPK, moek.TT) + E
    ctx.enqueue_function[moek.t_moe_gate_up](b.guq, b.gus, b.items, b.nitems, b.lists, b.counts, b.x, b.a,
                                             grid_dim=Dim(FE // 64, items), block_dim=64)
    ctx.enqueue_function[moek.t_moe_down](b.dq, b.ds, b.items, b.nitems, b.lists, b.counts, b.a, b.part32,
                                          grid_dim=Dim(D // 64, items), block_dim=64)
    ctx.enqueue_function[moek.p_moe_sum](b.part32, b.wts, b.y, c, grid_dim=groups(count * D, 64), block_dim=64)


def q_path(ctx: DeviceContext, b: Bufs, count: Int) raises:
    """QWEN3MOE_GEMM=q's expert layer, with model.mojo's tiles of 64 rows x 128 columns (GWN = 2)."""
    comptime WN = 2
    var tm = Int32(TMG)
    var c1 = groups(D, GCH)
    var c2 = groups(FE, GCH)
    b.y.enqueue_fill(0)
    b.src.enqueue_fill(-1)
    ctx.enqueue_function[lkh.group[TOPK]](b.ids, b.slot, b.src, b.tiles, b.ntiles, Int32(count), Int32(E), tm,
                                          grid_dim=1, block_dim=128)
    ctx.enqueue_function[lkh.pack_gather](b.x, b.src, b.xa.create_sub_buffer[DType.uint32](0, MAXG * D // 2),
                                          Int32(D), b.ntiles, tm, grid_dim=groups(MAXG * D // 8, 256), block_dim=256)
    ctx.enqueue_function[lkh.gemm_hqg[WN, GCH, 64, 4, False, moek.GE]](
        b.xa, b.guq, b.gus, b.part, Int32(2 * FE), Int32(D), Int32(MAXG), b.tiles, b.ntiles,
        grid_dim=Dim(2 * FE // (64 * WN), MAXG // TMG, c1), block_dim=64 * WN)
    ctx.enqueue_function[lkh.swiglu_pack](b.part, Int32(c1), Int32(MAXG), Int32(FE),
                                          b.xa.create_sub_buffer[DType.uint32](0, MAXG * FE // 2), b.ntiles, tm,
                                          grid_dim=groups(MAXG * FE // 8, 256), block_dim=256)
    ctx.enqueue_function[lkh.gemm_hqg[WN, GCH, 64, 4, False, moek.GE]](
        b.xa, b.dq, b.ds, b.part, Int32(D), Int32(FE), Int32(MAXG), b.tiles, b.ntiles,
        grid_dim=Dim(D // (64 * WN), MAXG // TMG, c2), block_dim=64 * WN)
    ctx.enqueue_function[lkh.combine[TOPK, True]](b.part, Int32(c2), Int32(MAXG), b.slot, b.wts, b.y, Int32(count),
                                                  Int32(D), grid_dim=groups(count * D, 64), block_dim=64)


def fill_words(ctx: DeviceContext, buf: DeviceBuffer[DType.uint32], n: Int, seed: UInt32) raises:
    var h = List[UInt32](length=n, fill=0)
    var state = seed
    for i in range(n):
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        h[i] = state
    ctx.enqueue_copy(buf, h.unsafe_ptr())
    ctx.synchronize()


def fill_scales(ctx: DeviceContext, buf: DeviceBuffer[DType.float16], n: Int, unit: Float32) raises:
    var h = List[Float16](length=n, fill=0)
    for i in range(n):
        h[i] = Float16(Float32(0.5 + Float32((i * 2654435761) % 1000) / 1000.0) * unit)
    ctx.enqueue_copy(buf, h.unsafe_ptr())
    ctx.synchronize()


def main() raises:
    var args = argv()
    var reps = Int(args[1]) if len(args) > 1 else 10
    var sizes: List[Int] = [32, 64, 128, 256]
    if len(args) > 2:
        sizes = [Int(args[2])]
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name(), "; reps:", reps, "; experts", E, "x SwiGLU", FE, "on", D, ", top", TOPK)
    var b = Bufs(ctx)
    fill_words(ctx, b.guq, E * 2 * FE * D // 8, 2463534242)
    fill_words(ctx, b.dq, E * D * FE // 8, 88675123)
    fill_scales(ctx, b.gus, E * 2 * FE * D // moek.GE, 1.0 / 64.0)
    fill_scales(ctx, b.ds, E * D * FE // moek.GE, 1.0 / 32.0)
    var hx = List[Float32](length=PMAX * D, fill=0)
    for i in range(len(hx)):
        hx[i] = Float32((i * 7919) % 2001) / 1000.0 - 1.0
    ctx.enqueue_copy(b.x, hx.unsafe_ptr())
    var hl = List[Float32](length=PMAX * E, fill=0)
    var state = UInt32(362436069)
    for i in range(len(hl)):
        state ^= state << 13
        state ^= state >> 17
        state ^= state << 5
        hl[i] = Float32(state % 100000) / 25000.0
    ctx.enqueue_copy(b.rl, hl.unsafe_ptr())
    ctx.enqueue_function[moek.p_route](b.rl, b.ids, b.wts, grid_dim=PMAX, block_dim=64)
    ctx.synchronize()
    var refv = List[Float32](length=PMAX * D, fill=0)
    var got = List[Float32](length=PMAX * D, fill=0)
    var nt = List[Int32](length=1, fill=0)
    for count in sizes:
        fp32_path(ctx, b, count)
        ctx.synchronize()
        ctx.enqueue_copy(refv.unsafe_ptr(), b.y)
        q_path(ctx, b, count)
        ctx.synchronize()
        ctx.enqueue_copy(got.unsafe_ptr(), b.y)
        ctx.enqueue_copy(nt.unsafe_ptr(), b.ntiles)
        ctx.synchronize()
        var big = Float64(1e-30)
        var worst = Float64(0)
        var nans = 0
        for i in range(count * D):
            big = max(big, abs(Float64(refv[i])))
            var d = abs(Float64(got[i]) - Float64(refv[i]))
            if not (d <= 1e30):
                nans += 1
                continue
            worst = max(worst, d)
        var t0 = now_ms()
        for _ in range(reps):
            fp32_path(ctx, b, count)
        ctx.synchronize()
        var ms32 = (now_ms() - t0) / Float64(reps)
        var t1 = now_ms()
        for _ in range(reps):
            q_path(ctx, b, count)
        ctx.synchronize()
        var msq = (now_ms() - t1) / Float64(reps)
        var gflop = 2.0 * Float64(count * TOPK) * Float64(3 * FE * D) / 1e9
        print(count, "tokens:", Int(nt[0]), "tiles of", TMG, "rows for", count * TOPK, "pairs; fp32 path",
              round(ms32, 2), "ms (", round(gflop / ms32, 2), "TFLOP/s useful ); fp16 path", round(msq, 2), "ms (",
              round(gflop / msq, 2), "); err", worst / big, "of max", big, "; NaN", nans)
