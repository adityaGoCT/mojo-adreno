# The prefill products of every model's *_GEMM=q path on the Adreno 850 (matrix units): one call in place of
# lkh.gemm_hq's K chunks. LKH_850=1 turns it on: lkh.gemm_k (B K-minor in shared memory, loaded column-major; one fp16
# accumulator over the whole K, which the 850's matrix units round once per 16-deep product) writes part's first chunk,
# and the caller adds "chunks = 1" with its usual sum_parts (or fused glue). The tiling follows llama/bench_k.mojo's
# sweep at Llama 3.2 3B's shapes (512 rows): K steps of 128 when k allows, 4 x 1 subgroups for long K (down), 2 x 2 for
# wide N (gate|up), else 2 x 1.
from std.collections import Dict
from std.os import getenv
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import lkh


def on850() -> Bool:
    return getenv("LKH_850") == "1"


def fa_on() -> Bool:
    """LKH_FA=1: a model's prompt attention as llama/kernels/l85.fa (fp16 tiles, flash attention). Opt-in: its q k^T
    accumulates in fp16, which moved LFM2.5-2.6B's logits (q/k-normed, larger scores) to KL 1.7e-3 from 3.2e-4."""
    return on850() and getenv("LKH_FA") == "1"


def gemm[GS: Int, FMT: Int](ctx: DeviceContext, xa: DeviceBuffer[DType.float16], wq: DeviceBuffer[DType.uint32],
                            ws: DeviceBuffer[DType.float16], part: DeviceBuffer[DType.float16], n: Int, k: Int,
                            rows: Int) raises -> Int:
    """part[0] (rows x n, fp16) = X W^T, X in xa's R tiles (pack_x), W the rows wq (int4 / int8 with a scale per GS
    in ws, or fp16 pairs: FMT). rows a multiple of 128, n of 64. Returns the number of K chunks: 1."""
    if n % 64 != 0 or rows % 128 != 0 or k % 64 != 0 or k % GS != 0:
        raise Error("lk850.gemm: n % 64, rows % 128, k % 64 and k % GS must be 0")
    if rows * n > len(part) or rows * k > len(xa):
        raise Error("lk850.gemm: a buffer is too small")
    var w4 = rows % 256 == 0
    var nn = Int32(n)
    var kk = Int32(k)
    var rr = Int32(rows)
    if k >= 6144 and k % 128 == 0:  # down-like
        if w4:
            ctx.enqueue_function[lkh.gemm_k[4, 1, 128, 1, True, GS, FMT]](
                xa, wq, ws, part, nn, kk, rr, grid_dim=Dim(n // 64, rows // 256), block_dim=256)
        else:
            ctx.enqueue_function[lkh.gemm_k[2, 1, 128, 1, True, GS, FMT]](
                xa, wq, ws, part, nn, kk, rr, grid_dim=Dim(n // 64, rows // 128), block_dim=128)
    elif n >= 8192 and n % 128 == 0:  # gate|up-like
        ctx.enqueue_function[lkh.gemm_k[2, 2, 64, 1, True, GS, FMT]](
            xa, wq, ws, part, nn, kk, rr, grid_dim=Dim(n // 128, rows // 128), block_dim=256)
    elif k % 128 == 0:
        ctx.enqueue_function[lkh.gemm_k[2, 1, 128, 1, True, GS, FMT]](
            xa, wq, ws, part, nn, kk, rr, grid_dim=Dim(n // 64, rows // 128), block_dim=128)
    else:
        ctx.enqueue_function[lkh.gemm_k[2, 1, 64, 1, True, GS, FMT]](
            xa, wq, ws, part, nn, kk, rr, grid_dim=Dim(n // 64, rows // 128), block_dim=128)
    return 1


# ---- int4 weights dequantized in registers (LKH_REG=1 with LKH_850; off by default) -----------------------------------
# A second copy of every int4 projection, repacked once at load into lkh.repack_q4's panels (a lane's 4 words of a
# 32-deep K step next to its neighbours'), so lkh.gemm_k's REG + PANEL path builds each B matrix in registers
# (CoopMatrix.construct) without shared memory: Llama 3.2 3B's products (a scale per 64) went from ~13-14 to 14.6-16.5
# TFLOP/s, but with a scale per 32 (Qwen3.5-4B, LFM2.5) whole prefills were 2-8% slower than the shared-memory path.


def reg_on() -> Bool:
    return on850() and getenv("LKH_REG") == "1"


struct Panels(Movable):
    var w: Dict[String, DeviceBuffer[DType.uint32]]  # by tensor name (without ".q")
    var s: Dict[String, DeviceBuffer[DType.float16]]

    def __init__(out self):
        self.w = Dict[String, DeviceBuffer[DType.uint32]]()
        self.s = Dict[String, DeviceBuffer[DType.float16]]()


def experts_reg_on() -> Bool:
    """A mixture of experts' grouped products (lkh.gemm_kg) from panels, B in registers (LKH_REG_EXPERTS=0: B through
    shared memory). A work tile is one expert's 64 rows, so B staged in shared memory serves one row block:
    LFM2.5-8B-A1B's 414-token prefill went from 361 to 218 ms with the same logits (the panels add 4.3 GB)."""
    return on850() and getenv("LKH_REG_EXPERTS") != "0"


def make_panels[GS: Int](ctx: DeviceContext, words: Dict[String, DeviceBuffer[DType.uint32]],
                         halves: Dict[String, DeviceBuffer[DType.float16]], manifest: String) raises -> Panels:
    """Panels of every int4 matrix the manifest lists ("<name>.q <offset> <bytes> u32 <n>x<k/8>") that has a scale per
    GS ("<name>.s"), 64 | n and 32 | k, except embeddings and heads (other kernels read those): the dense ones with
    reg_on(), the grouped experts' with experts_reg_on()."""
    var p = Panels()
    var experts = experts_reg_on()
    if not reg_on() and not experts:
        return p^
    for line in open(manifest, "r").read().splitlines():
        var f = line.split(" ")
        if len(f) < 5 or not f[0].endswith(".q") or f[3] != "u32":
            continue
        var full = String(f[0])
        var name = String(full[byte=0:full.byte_length() - 2])
        var expert = name.find(".egu") >= 0 or name.find(".edown") >= 0
        if (name.startswith("embed") or name.startswith("lm") or name.startswith("head") or (expert and not experts)
                or not (name + ".q" in words) or not (name + ".s" in halves)):
            continue
        if not expert and not reg_on():
            continue
        var dims = f[4].split("x")
        var n = Int(dims[0])
        var k = Int(dims[1]) * 8
        if n % 64 != 0 or k % 32 != 0 or k % GS != 0 or len(halves[name + ".s"]) != n * k // GS:
            continue
        var wp = ctx.enqueue_create_buffer[DType.uint32](n * k // 8)
        var sp = ctx.enqueue_create_buffer[DType.float16](n * k // GS)
        ctx.enqueue_function[lkh.repack_q4[4, GS]](words[name + ".q"], halves[name + ".s"], wp, sp, Int32(n), Int32(k),
                                                  Int32(0), Int32(128), grid_dim=(n * k // 32 + 255) // 256,
                                                  block_dim=256)
        p.w[name] = wp
        p.s[name] = sp
    ctx.synchronize()
    print("lk850: panels of", len(p.w), "int4 matrices")
    return p^


def gemm_p[GS: Int](ctx: DeviceContext, pan: Panels, name: String, xa: DeviceBuffer[DType.float16],
                    wq: DeviceBuffer[DType.uint32], ws: DeviceBuffer[DType.float16], part: DeviceBuffer[DType.float16],
                    n: Int, k: Int, rows: Int) raises -> Int:
    """gemm for int4 matrix `name`: from its panels with B in registers (4 x 2 or 2 x 2 subgroups, K steps of 32)
    when make_panels made them, else gemm's shared-memory product. Returns the number of K chunks: 1."""
    if name in pan.w and rows % 128 == 0 and n % 64 == 0:
        if rows * n > len(part) or rows * k > len(xa):
            raise Error("lk850.gemm_p: a buffer is too small")
        var wp = pan.w[name]
        var sp = pan.s[name]
        var a = (Int32(n), Int32(k), Int32(rows))
        if n % 128 == 0 and rows % 256 == 0:
            ctx.enqueue_function[lkh.gemm_k[4, 2, 32, 1, True, GS, lkh.Q4, 8, True, True]](
                xa, wp, sp, part, a[0], a[1], a[2], grid_dim=Dim(n // 128, rows // 256), block_dim=512)
        elif n % 128 == 0:
            ctx.enqueue_function[lkh.gemm_k[2, 2, 32, 1, True, GS, lkh.Q4, 8, True, True]](
                xa, wp, sp, part, a[0], a[1], a[2], grid_dim=Dim(n // 128, rows // 128), block_dim=256)
        else:
            ctx.enqueue_function[lkh.gemm_k[2, 1, 32, 1, True, GS, lkh.Q4, 8, True, True]](
                xa, wp, sp, part, a[0], a[1], a[2], grid_dim=Dim(n // 64, rows // 128), block_dim=128)
        return 1
    return gemm[GS, lkh.Q4](ctx, xa, wq, ws, part, n, k, rows)


def mlp[GS: Int](ctx: DeviceContext, pan: Panels, gu: String, xn: DeviceBuffer[DType.float32],
                 xa: DeviceBuffer[DType.float16], xb: DeviceBuffer[DType.float16], gq: DeviceBuffer[DType.uint32],
                 gs: DeviceBuffer[DType.float16], dq: DeviceBuffer[DType.uint32], ds: DeviceBuffer[DType.float16],
                 down: String, part: DeviceBuffer[DType.float16], y: DeviceBuffer[DType.float32], f: Int, d: Int,
                 rows: Int) raises:
    """y[rows, d] = W_down (silu(gate) up) for the MLP of xn's rows, W_gu = [gate; up] (2f x d) and W_down (d x f)
    int4 with a scale per GS: xn packed (pack_x), gate|up with SiLU in its epilogue writing down's packed X into xb
    (lkh.gemm_k_swiglu: no fp32 gate|up, no silu_mul pass, no pack_x for down), down, then its sum into y. rows a
    multiple of 128."""
    if rows % 128 != 0 or f % 64 != 0 or d % 64 != 0 or rows * f > len(xb) or rows * d > len(xa):
        raise Error("lk850.mlp: shapes or buffers")
    ctx.enqueue_function[lkh.pack_x](xn, xa.create_sub_buffer[DType.uint32](0, rows * d // 2), Int32(d),
                                     Int32(rows * d // 8), grid_dim=(rows * d // 8 + 255) // 256, block_dim=256)
    var xb32 = xb.create_sub_buffer[DType.uint32](0, rows * f // 2)
    if gu in pan.w:
        ctx.enqueue_function[lkh.gemm_k_swiglu[2, 32, 1, True, GS, lkh.Q4, 8, True, True]](
            xa, pan.w[gu], pan.s[gu], xb32, Int32(f), Int32(d), grid_dim=Dim(f // 64, rows // 128), block_dim=256)
    else:
        ctx.enqueue_function[lkh.gemm_k_swiglu[2, 64, 1, True, GS]](
            xa, gq, gs, xb32, Int32(f), Int32(d), grid_dim=Dim(f // 64, rows // 128), block_dim=256)
    var c = gemm_p[GS](ctx, pan, down, xb, dq, ds, part, d, f, rows)
    ctx.enqueue_function[lkh.sum_parts](part, y, Int32(rows * d), Int32(c), grid_dim=(rows * d // 8 + 255) // 256,
                                        block_dim=256)
