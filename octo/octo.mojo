# octo: Octo-Small 1.5 through MAX's DeviceContext: octo/model.mojo's forward pass on an Adreno, here the X2 Elite
# laptop's X2-90 behind vla/x2's Vulkan server (octo/build_mac.sh). It loads the fp32 checkpoint, runs
# octo/reference.py's example (two frames of both cameras, "put the eggplant in the basket", JAX's noise) and checks
# every stage against Octo's own JAX tensors; then times action chunks.
#
#   VK_REMOTE_PORT=<port> MODULAR_DRIVER_PLUGINS=vulkan@<plugin> OCTO_REMOTE=<the weights on the laptop> \
#       octo <octo_small.safetensors> <ref dir> [runs]
#
# OCTO_OPT=1: q/k/v as one projection, the GELU fused into the down projection, the 20 denoising steps in one
# launch; OCTO_F16=1: the trunk's and stems' projection weights in fp16; OCTO_MMA16=1: the trunk on the fp16 matrix
# units. A chunk's stages, each synchronized: stems (both cameras, both frames), tokens, trunk, head; then the whole
# chunk with one synchronize. T5 runs once per instruction, so the chunk is timed without it too.
# OCTO_REPLAY=<k>: a chunk on the laptop's own clock, without the tunnel (OP_RECORD / OP_REPLAY), five times over.
from std.os import getenv
from std.sys import argv
from max.gpu.host import DeviceContext

from check import cool_down, Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import (AD, D, EMB, N, NP, NPR, NT, NWR, PER, READOUT, STEPS, TD, TDIM, W, L, Octo, sub)


def read_u8(path: String) raises -> List[UInt8]:
    var data = open(path, "r").read_bytes()
    var out = List[UInt8](length=len(data), fill=0)
    for i in range(len(data)):
        out[i] = data[i]
    return out^


def last_frame(v: List[Float32], steps: Int) -> List[Float32]:
    """(steps, W, 28) -> the last frame's (steps, 28)."""
    var out = List[Float32](length=steps * AD, fill=0)
    for s in range(steps):
        for i in range(AD):
            out[s * AD + i] = v[(s * W + W - 1) * AD + i]
    return out^


def nhwc(ctx: DeviceContext, m: Octo, stage: Int, want: List[Float32]) raises -> Check:
    """Stem stage `stage` of primary frame 0 (rows of ld floats) against the reference (packed NHWC)."""
    var feats = [32, 96, 192, 384]
    var lds = [64, 128, 192, 384]
    var hw = (128 >> stage) * (128 >> stage)
    var bufs = [m.a1, m.a2, m.a3, m.a4]
    var got = fetch(ctx, bufs[stage], hw * lds[stage])
    return compare(got, lds[stage], want, feats[stage], span(hw), feats[stage])


def replay(mut m: Octo, ctx: DeviceContext, k: Int, with_text: Bool) raises -> Float64:
    """One chunk kept by the server and run k more times there: its milliseconds a chunk on the server's clock."""
    ctx.synchronize()
    if m.lib.call["M_driver_remote_record", Int32](Int32(1)) != 0:
        raise Error("M_driver_remote_record failed")
    m.chunk(with_text)
    _ = m.lib.call["M_driver_remote_record", Int32](Int32(0))
    ctx.synchronize()
    var ms = m.lib.call["M_driver_remote_replay", Float64](Int32(k))
    if ms < 0:
        raise Error("M_driver_remote_replay failed")
    return ms / Float64(k)


def replays(mut m: Octo, ctx: DeviceContext) raises:
    cool_down()
    var k = Int(getenv("OCTO_REPLAY"))
    for with_text in [False, True]:
        var line = String("replay: chunk ") + ("with" if with_text else "without") + " T5, " + String(k) + \
                   " chunks a replay, ms a chunk (server clock):"
        for _ in range(5):
            line += " " + String(round(replay(m, ctx, k, with_text), 1))
        print(line)


def main() raises:
    var args = argv()
    if len(args) < 3:
        raise Error("usage: octo <octo_small.safetensors> <ref dir> [runs]")
    var path = String(args[1])
    var r = String(args[2]) + "/"
    var runs = Int(args[3]) if len(args) > 3 else 3
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t0 = now_ms()
    var m = Octo(ctx, path)
    print("weights:", Float64(m.bytes) / 1e9, "GB (fp32), loaded in", round((now_ms() - t0) / 1e3, 2), "s;",
          "opt" if m.opt else "baseline", "| f16" if m.f16 else "", "| mma16" if m.mma16 else "")
    m.set_inputs(read_u8(r + "image_primary.u8"), read_u8(r + "image_wrist.u8"), read_i32(r + "input_ids.i32"),
                 read_i32(r + "attention_mask.i32"), last_frame(read_f32(r + "diff_noise.f32"), 1),
                 last_frame(read_f32(r + "diff_z.f32"), STEPS), read_f32(r + "sched_betas.f32"),
                 read_f32(r + "sched_alphas.f32"), read_f32(r + "sched_alpha_hats.f32"))

    if m.npu >= 0:  # GPU+NPU: T5 and the head on the GPU, the stems and the trunk on the NPU
        m.text()
        m.obs_trunk_npu()
        var rr = read_f32(r + "readout.f32")
        var last = List[Float32](length=D, fill=0)
        for j in range(D):
            last[j] = rr[D + j]
        show("readout from the NPU (last frame, 384)", compare(fetch(ctx, m.xn, N * D), D, last, D, [READOUT], D))
        print("NPU obs + trunk graph:", round(m.npu_time(), 1), "ms (server clock)")
        m.head()
        show("actions (4 x 7, normalized), GPU+NPU", compare(fetch(ctx, m.ax, AD), AD, read_f32(r + "actions_norm.f32"),
                                                             AD, span(1), AD))
        m.record = False
        for run in range(runs):
            var a0 = now_ms()
            m.chunk(False)
            ctx.synchronize()
            print("run", run, ": chunk without T5", round(now_ms() - a0, 1), "ms (Mac clock); NPU", round(m.npu_time(), 1),
                  "ms")
        if getenv("OCTO_REPLAY"):
            replays(m, ctx)
        print("done")
        return

    # the check, stage by stage (the first run also creates the pipelines)
    var tc = now_ms()
    var rows = List[Int]()  # the reference's step s is time 19 - s
    for s in range(STEPS):
        rows.append(STEPS - 1 - s)
    show("time conditioning (20 x 32)", compare(fetch(ctx, m.condtab, STEPS * TDIM), TDIM,
                                                read_f32(r + "diff_cond.f32"), TDIM, rows, TDIM))
    m.text()
    show("T5 (16 x 768)", compare(fetch(ctx, m.t5n, NT * TD), TD, read_f32(r + "t5_hidden.f32"), TD, span(NT), TD))
    m.stem("primary")
    for i in range(4):
        show("primary stem stage " + String(i) + ", frame 0", nhwc(ctx, m, i, read_f32(r + "stem" + String(i) + ".f32")))
    show("primary tokens (2 x 256 x 512)", compare(fetch(ctx, m.emb_p, W * NPR * EMB), EMB,
                                                   read_f32(r + "tokens_primary.f32"), EMB, span(W * NPR), EMB))
    m.stem("wrist")
    show("wrist tokens (2 x 64 x 512)", compare(fetch(ctx, m.emb_w, W * NWR * EMB), EMB,
                                                read_f32(r + "tokens_wrist.f32"), EMB, span(W * NWR), EMB))
    m.tokens()
    show("trunk input (690 x 384)", compare(fetch(ctx, m.x, N * D), D, read_f32(r + "trunk_input.f32"), D, span(N), D))
    # the mask the levels express against Octo's own
    var mask = read_u8(r + "attn_mask.u8")
    var bad = 0
    for i in range(N):
        for j in range(N):
            var ti = -1 if i < NT else (i - NT) // PER
            var tj = -1 if j < NT else (j - NT) // PER
            var ri = i >= NT and (i - NT) % PER == PER - 1
            var rj = j >= NT and (j - NT) % PER == PER - 1
            var visible = tj <= ti and (not rj or ri)
            if visible != (mask[i * N + j] != 0):
                bad += 1
    print("check trunk mask (levels vs Octo's):", bad, "of", N * N, "entries differ")
    for i in range(L):
        m.block(i)
        show("block " + String(i), compare(fetch(ctx, m.x, N * D), D, read_f32(r + "block" + String(i) + ".f32"), D,
                                           span(N), D))
    m.ln(m.x, m.xn, "octo_transformer.BlockTransformer_0.Transformer_0.encoder_norm", NP, D, D, D)
    show("final LayerNorm (690 x 384)", compare(fetch(ctx, m.xn, N * D), D, read_f32(r + "final_norm.f32"), D, span(N),
                                                D))
    show("readout tokens (2 x 384)", compare(fetch(ctx, m.xn, N * D), D, read_f32(r + "readout.f32"), D,
                                             [NT + PER - 1, READOUT], D))
    m.head()
    var xs = fetch(ctx, m.xs, STEPS * AD)
    var xr = last_frame(read_f32(r + "diff_x.f32"), STEPS)  # scan order: time 19 first
    var worst = Check()
    for s in range(STEPS):
        var c = Check()
        for i in range(AD):
            c.add(xs[(STEPS - 1 - s) * AD + i], xr[s * AD + i])
            worst.add(xs[(STEPS - 1 - s) * AD + i], xr[s * AD + i])
        if s == 0 or s == STEPS - 1:
            show("denoising step " + String(s) + " (time " + String(STEPS - 1 - s) + ")", c)
    show("denoising, worst of 20 steps", worst)
    var a = fetch(ctx, m.ax, AD)
    show("actions (4 x 7, normalized)", compare(a, AD, read_f32(r + "actions_norm.f32"), AD, span(1), AD))
    var mean = read_f32(r + "stats_mean.f32")
    var std = read_f32(r + "stats_std.f32")
    var smask = read_u8(r + "stats_mask.u8")
    var au = List[Float32](length=AD, fill=0)
    for i in range(AD):
        var c = i % 7
        au[i] = a[i] * std[c] + mean[c] if smask[c] != 0 else a[i]
    show("actions (4 x 7, Bridge units)", compare(au, AD, read_f32(r + "actions.f32"), AD, span(1), AD))
    print("checked in", round((now_ms() - tc) / 1e3, 2), "s")

    m.record = False
    for run in range(runs):
        var a0 = now_ms()
        m.stem("primary")
        m.stem("wrist")
        ctx.synchronize()
        var b = now_ms()
        m.tokens()
        m.trunk()
        ctx.synchronize()
        var c = now_ms()
        m.head()
        ctx.synchronize()
        var d = now_ms()
        m.chunk(False)
        ctx.synchronize()
        var e = now_ms()
        print("run", run, ": stems", round(b - a0, 1), "ms, tokens + trunk", round(c - b, 1), "ms, head",
              round(d - c, 1), "ms; chunk without T5", round(e - d, 1), "ms")
    if getenv("OCTO_REPLAY"):
        replays(m, ctx)
    if getenv("OCTO_PROFILE"):
        m.profiling = True
        print("profile: one chunk, each operation waited for alone")
        m.chunk(False)
        m.profiling = False
    print("done")
