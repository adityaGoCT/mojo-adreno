# vla_jepa: VLA-JEPA (LIBERO) through MAX's DeviceContext: vla_jepa/model.mojo's forward pass on an Adreno, here the X2
# Elite laptop's X2-90 behind vla/x2's Vulkan server (vla_jepa/build_mac.sh). It loads the bf16 checkpoint, runs
# vla_jepa/reference.py's example (VLA-Adapter's LIBERO-Spatial sample, both views, seeded noise) and checks every
# stage against the official PyTorch model in fp32; then times action chunks.
#
#   VK_REMOTE_PORT=<port> MODULAR_DRIVER_PLUGINS=vulkan@<plugin> VJ_REMOTE=<the official .pt on the laptop> \
#       VJ_REMOTE_INDEX=build/vla_jepa/pt_offsets.txt vla_jepa <vla_jepa.safetensors> <ref dir> [runs]
#
# VJ_REPLAY=<k>: a chunk on the laptop's own clock (OP_RECORD / OP_REPLAY), five times over. VJ_MMA16=1: the ViT,
# mergers and LLM on the fp16 matrix units. GPU+NPU: VJ_NPU_VISION / VJ_NPU_LLM name compiled graphs on the laptop
# (vla_jepa/export_npu.py; the server is vk_server_npu.exe); those stages run on the NPU, the rest on the GPU.
from std.os import getenv
from std.sys import argv
from max.gpu.host import DeviceContext

from check import cool_down, Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import (AH, AX, D, DD, HD, LL, NE, NP, NV, SP, STEPS, VD, VLAJEPA, sub)


def replay(mut m: VLAJEPA, ctx: DeviceContext, k: Int) raises -> Float64:
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


def two(i: Int) -> String:
    return ("0" if i < 10 else "") + String(i)


def x_check(ctx: DeviceContext, m: VLAJEPA, r: String, what: String) raises:
    """The final x (7 x 7, normalized) against the reference's last step."""
    var xr = read_f32(r + "x.f32")
    var a = fetch(ctx, m.act, AH * AX)
    var c = Check()
    for i in range(AH):
        for j in range(AH):
            c.add(a[i * AX + j], xr[((STEPS - 1) * AH + i) * AH + j])
    show("actions (7 x 7, normalized)" + what, c)


def gpu_npu(mut m: VLAJEPA, ctx: DeviceContext, r: String, runs: Int) raises:
    """GPU+NPU: the vision and/or LLM graphs on the NPU, the rest on the GPU; checked, then timed."""
    if m.npu_vision >= 0:
        m.vision_npu()
        show("merger from the NPU (2 x 64 x 2048)", compare(fetch(ctx, m.vis, 128 * D), D,
                                                            read_f32(r + "vit_merger.f32"), D, span(128), D))
        for k in range(3):
            show("DeepStack " + String(k) + " from the NPU", compare(fetch(ctx, m.ds[k], 128 * D), D,
                                                                    read_f32(r + "vit_deepstack" + String(k) + ".f32"),
                                                                    D, span(128), D))
        print("NPU vision graph:", round(m.npu_time(), 1), "ms (server clock)")
    else:
        m.vit()
    m.embed()
    if m.npu_llm >= 0:
        m.llm_npu()
        show("embodied hidden states from the NPU (32 x 2048)", compare(fetch(ctx, m.vl, NE * D), D,
                                                                        read_f32(r + "embodied_hidden.f32"), D,
                                                                        span(NE), D))
        print("NPU LLM graph:", round(m.npu_time(), 1), "ms (server clock)")
    else:
        m.llm()
    m.head()
    x_check(ctx, m, r, ", GPU+NPU")
    for run in range(runs):
        var a0 = now_ms()
        m.chunk()
        ctx.synchronize()
        print("run", run, ": chunk", round(now_ms() - a0, 1), "ms (Mac clock)")
    if getenv("VJ_REPLAY"):
        cool_down()
        var k = Int(getenv("VJ_REPLAY"))
        var line = String("replay: chunk, ") + String(k) + " chunks a replay, ms a chunk (server clock):"
        for _ in range(5):
            line += " " + String(round(replay(m, ctx, k), 1))
        print(line)
    print("done")


def main() raises:
    var args = argv()
    if len(args) < 3:
        raise Error("usage: vla_jepa <vla_jepa.safetensors> <ref dir> [runs]")
    var r = String(args[2]) + "/"
    var runs = Int(args[3]) if len(args) > 3 else 2
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t0 = now_ms()
    var m = VLAJEPA(ctx, String(args[1]))
    print("weights:", Float64(m.bytes) / 1e9, "GB (bf16), loaded in", round((now_ms() - t0) / 1e3, 2), "s;",
          "fp16 matrix units" if m.mma16 else "baseline")
    var ids = read_i32(r + "input_ids.i32")
    var S = len(ids)
    var imgp = read_i32(r + "image_token_positions.i32")
    var img0 = List[Int]()
    img0.append(Int(imgp[0]))
    img0.append(Int(imgp[64]))
    var emb0 = Int(read_i32(r + "embodied_token_positions.i32")[0])
    m.set_inputs(read_f32(r + "pixel_values.f32"), ids, S, img0, emb0, read_i32(r + "position_ids.i32"),
                 read_f32(r + "state_raw.f32"), read_f32(r + "noise.f32"))
    print("prompt", S, "rows; images at", img0[0], img0[1], "; embodied tokens at", emb0)
    if m.npu_vision >= 0 or m.npu_llm >= 0:  # GPU+NPU
        gpu_npu(m, ctx, r, runs)
        return

    var tc = now_ms()
    show("ViT position grid (256 x 1024)", compare(fetch(ctx, m.posemb, NP * VD), VD, read_f32(r + "vit_pos_embed.f32"),
                                                   VD, span(NP), VD))
    show("ViT RoPE cos (256 x 32)", compare(fetch(ctx, m.vcos, NP * 32), 32, read_f32(r + "vit_rope_cos.f32"), 64,
                                            span(NP), 32))
    show("LLM RoPE cos (S x 64)", compare(fetch(ctx, m.lcos, S * HD // 2), HD // 2, read_f32(r + "llm_rope_cos.f32"), HD,
                                          span(S), HD // 2))
    m.vit()
    var vb = read_f32(r + "vit_blocks.f32")
    var last = List[Float32](length=NV * NP * VD, fill=0)
    for i in range(NV * NP * VD):
        last[i] = vb[23 * NV * NP * VD + i]
    show("ViT block 23 (2 x 256 x 1024)", compare(fetch(ctx, m.vx, NV * NP * VD), VD, last, VD, span(NV * NP), VD))
    show("merger (2 x 64 x 2048)", compare(fetch(ctx, m.vis, 128 * D), D, read_f32(r + "vit_merger.f32"), D, span(128), D))
    for k in range(3):
        show("DeepStack " + String(k), compare(fetch(ctx, m.ds[k], 128 * D), D,
                                                read_f32(r + "vit_deepstack" + String(k) + ".f32"), D, span(128), D))
    m.embed()
    show("LLM input (S x 2048)", compare(fetch(ctx, m.x, S * D), D, read_f32(r + "llm_input_embeds.f32"), D, span(S), D))
    for l in range(LL):
        m.llm_layer(l)
        if l < 3:
            show("LLM layer " + String(l) + " + DeepStack", compare(fetch(ctx, m.x, S * D), D,
                                                                     read_f32(r + "llm_layer" + two(l) + "_deepstack.f32"),
                                                                     D, span(S), D))
        elif l == 13 or l == LL - 1:
            show("LLM layer " + String(l), compare(fetch(ctx, m.x, S * D), D, read_f32(r + "llm_layer" + two(l) + ".f32"),
                                                   D, span(S), D))
    m.copy(sub(m.vl, 0, NE * D), sub(m.x, m.emb0 * D, NE * D))
    show("embodied hidden states (32 x 2048)", compare(fetch(ctx, m.vl, NE * D), D, read_f32(r + "embodied_hidden.f32"),
                                                       D, span(NE), D))
    m.head_start()
    show("state token (768)", compare(fetch(ctx, m.srow, DD), DD, read_f32(r + "state_token.f32"), DD, span(1), DD))
    var xr = read_f32(r + "x.f32")
    var vr = read_f32(r + "velocity.f32")
    for s in range(STEPS):
        m.step(s)
        var a = fetch(ctx, m.act, AH * AX)
        var c = Check()
        for i in range(AH):
            for j in range(AH):
                c.add(a[i * AX + j], xr[(s * AH + i) * AH + j])
        show("x after step " + String(s) + " (7 x 7)", c)
    var a = fetch(ctx, m.act, AH * AX)
    var amin = read_f32(r + "action_min.f32")
    var amax = read_f32(r + "action_max.f32")
    var au = read_f32(r + "actions.f32")
    var cu = Check()
    for i in range(AH):
        for j in range(AH):
            var v = min(max(a[i * AX + j], Float32(-1)), Float32(1))
            var u = Float32(0.5) * (v + 1) * (amax[j] - amin[j]) + amin[j] if j < 6 else (Float32(1) if v >= 0.5 else Float32(0))
            cu.add(u, au[i * AH + j])
    show("actions (7 x 7, LIBERO units)", cu)
    x_check(ctx, m, r, "")
    print("checked in", round((now_ms() - tc) / 1e3, 2), "s")

    for run in range(runs):
        var a0 = now_ms()
        m.vit()
        ctx.synchronize()
        var b = now_ms()
        m.embed()
        m.llm()
        ctx.synchronize()
        var c2 = now_ms()
        m.head()
        ctx.synchronize()
        var d = now_ms()
        print("run", run, ": ViT", round(b - a0, 1), "ms, LLM", round(c2 - b, 1), "ms, head (4 steps)", round(d - c2, 1),
              "ms (Mac clock)")
    if getenv("VJ_REPLAY"):
        cool_down()
        var k = Int(getenv("VJ_REPLAY"))
        var line = String("replay: chunk, ") + String(k) + " chunks a replay, ms a chunk (server clock):"
        for _ in range(5):
            line += " " + String(round(replay(m, ctx, k), 1))
        print(line)
    print("done")
