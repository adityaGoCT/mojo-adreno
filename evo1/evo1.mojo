# evo1: Evo-1 (LIBERO) through MAX's DeviceContext: evo1/model.mojo's forward pass on an Adreno, here the X2 Elite
# laptop's X2-90 behind vla/x2's Vulkan server (evo1/build_mac.sh). It loads the bf16 checkpoint, runs
# evo1/reference.py's example (VLA-Adapter's LIBERO-Spatial sample observation, a masked third view, seeded noise) and
# checks every stage against the official PyTorch model in fp32 (FlashAttention-2 masking); then times action chunks.
#
#   VK_REMOTE_PORT=<port> MODULAR_DRIVER_PLUGINS=vulkan@<plugin> EVO1_REMOTE=<the weights on the laptop> \
#       evo1 <evo1.safetensors> <ref dir> [runs]
#
# EVO1_MMA16=1: the ViT, mlp1 and the LLM on the fp16 matrix units. EVO1_REPLAY=<k>: a chunk on the laptop's own clock
# (OP_RECORD / OP_REPLAY), five times over. GPU+NPU: EVO1_NPU_VISION / EVO1_NPU_LLM name compiled graphs on the laptop
# (evo1/export_npu.py; the server is vk_server_npu.exe); those stages run on the NPU, the rest on the GPU.
from std.os import getenv
from std.sys import argv
from max.gpu.host import DeviceContext

from check import Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import (AD, CTX, D, H, LL, MT, NV, OUT, S, STEPS, VD, VR, VT, Evo1)


def replay(mut m: Evo1, ctx: DeviceContext, k: Int) raises -> Float64:
    ctx.synchronize()
    if m.lib.call["M_driver_remote_record", Int32](Int32(1)) != 0:
        raise Error("M_driver_remote_record failed")
    m.chunk()
    _ = m.lib.call["M_driver_remote_record", Int32](Int32(0))
    ctx.synchronize()
    var ms = m.lib.call["M_driver_remote_replay", Float64](Int32(k))
    if ms < 0:
        raise Error("M_driver_remote_replay failed")
    return ms / Float64(k)


def actions_check(ctx: DeviceContext, m: Evo1, r: String, what: String) raises:
    var a = fetch(ctx, m.act, OUT)
    var an = read_f32(r + "actions_norm.f32")
    var c = Check()
    for j in range(OUT):
        if j % AD < 7:
            c.add(a[j], an[j])
    show("actions (50 x 7, normalized)" + what, c)


def gpu_npu(mut m: Evo1, ctx: DeviceContext, r: String, runs: Int) raises:
    """GPU+NPU: the vision and/or LLM graphs on the NPU, the rest on the GPU; checked, then timed."""
    if m.npu_vision >= 0:
        m.vision_npu()
        show("views' tokens from the NPU (3 x 256 x 896)", compare(fetch(ctx, m.mout, NV * MT * D), D,
                                                                   read_f32(r + "mlp1_out.f32"), D, span(NV * MT), D))
        print("NPU vision graph:", round(m.npu_time(), 1), "ms (server clock)")
    else:
        m.vision()
    m.embed()
    if m.npu_llm >= 0:
        m.llm_npu()
        m.head_start()
        show("head context from the NPU (1025 x 896)", compare(fetch(ctx, m.ctxb, CTX * D), D,
                                                                read_f32(r + "context.f32"), D, span(CTX), D))
        print("NPU LLM graph:", round(m.npu_time(), 1), "ms (server clock)")
        for i in range(STEPS):
            m.step(i)
    else:
        m.llm()
        m.head()
    actions_check(ctx, m, r, ", GPU+NPU")
    m.record = False
    for run in range(runs):
        var a0 = now_ms()
        m.chunk()
        ctx.synchronize()
        print("run", run, ": chunk", round(now_ms() - a0, 1), "ms (Mac clock)")
    if getenv("EVO1_REPLAY"):
        var k = Int(getenv("EVO1_REPLAY"))
        var line = String("replay: chunk, ") + String(k) + " chunks a replay, ms a chunk (server clock):"
        for _ in range(5):
            line += " " + String(round(replay(m, ctx, k), 1))
        print(line)
    print("done")


def main() raises:
    var args = argv()
    if len(args) < 3:
        raise Error("usage: evo1 <evo1.safetensors> <ref dir> [runs]")
    var r = String(args[2]) + "/"
    var runs = Int(args[3]) if len(args) > 3 else 2
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t0 = now_ms()
    var m = Evo1(ctx, String(args[1]))
    print("weights:", Float64(m.bytes) / 1e9, "GB (bf16), loaded in", round((now_ms() - t0) / 1e3, 2), "s;",
          "fp16 matrix units" if m.mma16 else "baseline")
    var slots_all = read_i32(r + "image_slots.i32")
    var slots = List[Int]()
    for v in range(NV):
        slots.append(Int(slots_all[v * MT]))
    var amask = List[Float32]()
    for v in read_i32(r + "action_mask.i32"):
        amask.append(Float32(v))
    m.set_inputs(read_f32(r + "pixel_values.f32"), read_i32(r + "input_ids.i32"), read_i32(r + "attention_mask.i32"),
                 slots, read_f32(r + "state_norm.f32"), read_f32(r + "noise.f32"), amask)
    var ti = read_i32(r + "time_index.i32")
    for i in range(STEPS):
        if Int(ti[i]) != m.tindex[i]:
            raise Error("time index " + String(i) + ": " + String(m.tindex[i]) + " vs the reference's " + String(ti[i]))
    if m.npu_vision >= 0 or m.npu_llm >= 0:  # GPU+NPU
        gpu_npu(m, ctx, r, runs)
        return

    var tc = now_ms()
    var vrows = List[Int]()
    for v in range(NV):
        for i in range(VT):
            vrows.append(v * VR + i)
    m.vit()
    show("InternViT output (3 x 1025 x 1024)", compare(fetch(ctx, m.vx, NV * VR * VD), VD, read_f32(r + "vit_out.f32"), VD,
                                                       vrows, VD))
    m.mlp1()
    show("mlp1 (3 x 256 x 896)", compare(fetch(ctx, m.mout, NV * MT * D), D, read_f32(r + "mlp1_out.f32"), D,
                                         span(NV * MT), D))
    m.embed()
    show("LLM input (1024 x 896)", compare(fetch(ctx, m.x, S * D), D, read_f32(r + "llm_input_embeds.f32"), D, span(S), D))
    for l in range(LL):
        m.llm_layer(l)
        if l == 0 or l == 6 or l == LL - 1:
            show("LLM layer " + String(l), compare(fetch(ctx, m.x, S * D), D,
                                                   read_f32(r + "llm_layer" + ("0" if l < 10 else "") + String(l) + ".f32"),
                                                   D, span(S), D))
    m.rms(m.x, m.xn, "embedder.model.language_model.model.norm.weight")
    m.copy(m.ctxb.create_sub_buffer[DType.float32](0, S * D), m.xn)
    m.head_start()
    show("head context (1025 x 896: LLM + state token)", compare(fetch(ctx, m.ctxb, CTX * D), D,
                                                                 read_f32(r + "context.f32"), D, span(CTX), D))
    var xr = read_f32(r + "x.f32")
    var worst = Check()
    for i in range(STEPS):
        m.step(i)
        var xs = fetch(ctx, m.act, OUT)
        var c = Check()
        for j in range(OUT):
            if j % AD < 7:
                c.add(xs[j], xr[i * OUT + j])
                worst.add(xs[j], xr[i * OUT + j])
        if i == 0 or i == STEPS - 1:
            show("x after step " + String(i) + " (the 7 used dims)", c)
    show("x, worst of 32 steps (the 7 used dims)", worst)
    var a = fetch(ctx, m.act, OUT)
    var an = read_f32(r + "actions_norm.f32")
    var c = Check()
    for j in range(OUT):
        if j % AD < 7:
            c.add(a[j], an[j])
    show("actions (50 x 7, normalized)", c)
    var amin = read_f32(r + "action_min.f32")
    var amax = read_f32(r + "action_max.f32")
    var au = read_f32(r + "actions.f32")
    var cu = Check()
    for t in range(H):
        for d in range(7):
            var v = (a[t * AD + d] + 1) / 2 * (amax[d] - amin[d] + Float32(1e-8)) + amin[d]
            cu.add(v, au[t * 7 + d])
    show("actions (50 x 7, LIBERO units)", cu)
    print("checked in", round((now_ms() - tc) / 1e3, 2), "s")

    m.record = False
    for run in range(runs):
        var a0 = now_ms()
        m.vision()
        ctx.synchronize()
        var b = now_ms()
        m.embed()
        m.llm()
        ctx.synchronize()
        var c2 = now_ms()
        m.head()
        ctx.synchronize()
        var d = now_ms()
        print("run", run, ": vision", round(b - a0, 1), "ms, LLM", round(c2 - b, 1), "ms, head (32 steps)",
              round(d - c2, 1), "ms (Mac clock)")
    if getenv("EVO1_REPLAY"):
        var k = Int(getenv("EVO1_REPLAY"))
        var line = String("replay: chunk, ") + String(k) + " chunks a replay, ms a chunk (server clock):"
        for _ in range(5):
            line += " " + String(round(replay(m, ctx, k), 1))
        print(line)
    print("done")
