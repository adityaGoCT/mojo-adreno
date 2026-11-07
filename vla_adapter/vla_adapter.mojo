# vla_adapter: VLA-Adapter (Pro, LIBERO-Spatial) through MAX's DeviceContext: vla_adapter/model.mojo's forward pass
# on an Adreno, here the X2 Elite laptop's X2-90 behind vla/x2's Vulkan server (vla_adapter/build_mac.sh). It loads the
# bf16 checkpoint, runs vla_adapter/reference.py's example (the repo's LIBERO-Spatial sample observation) and checks
# every stage against the official PyTorch model in fp32; then times action chunks.
#
#   VK_REMOTE_PORT=<port> MODULAR_DRIVER_PLUGINS=vulkan@<plugin> VLA_REMOTE=<the same files on the laptop> \
#       vla_adapter <model.safetensors>,<head_bf16.safetensors> <ref dir> [runs]
#
# A chunk's stages, each synchronized: vision (DINOv2 and SigLIP), projector + embeddings, LLM, policy; then the whole
# chunk with one synchronize. VLA_REPLAY=<k>: a chunk on the laptop's own clock, without the tunnel (OP_RECORD /
# OP_REPLAY), five times over.
from std.os import getenv
from std.sys import argv
from max.gpu.host import DeviceContext

from check import cool_down, Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import (ADIM, D, DPRE, DR, DV, LL, NIMG, NPATCH, SV, TAP, VROWS, VLAAdapter)


def meta_int(meta: String, key: String) raises -> Int:
    var at = meta.find('"' + key + '": ')
    if at < 0:
        raise Error("meta.json has no " + key)
    var start = at + key.byte_length() + 4
    var end = start
    while end < meta.byte_length() and meta[byte=end] >= "0" and meta[byte=end] <= "9":
        end += 1
    return Int(String(meta[byte=start:end]))


def rows_from(start: Int, n: Int) -> List[Int]:
    var r = List[Int]()
    for i in range(n):
        r.append(start + i)
    return r^


def replay(mut m: VLAAdapter, ctx: DeviceContext, k: Int) raises -> Float64:
    """One chunk kept by the server and run k more times there: its milliseconds a chunk on the server's clock."""
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


def check_taps(ctx: DeviceContext, m: VLAAdapter, r: String, L: Int) raises:
    var taps = fetch(ctx, m.taps, LL * TAP * D)
    var worst = Check()
    var last = Check()
    for j in range(1, LL + 1):
        var h = read_f32(r + "llm_hidden_" + ("0" if j < 10 else "") + String(j) + ".f32")
        for i in range(TAP):
            var row = i if i < VROWS else L + VROWS - 1 + (i - VROWS)
            for col in range(D):
                worst.add(taps[((j - 1) * TAP + i) * D + col], h[row * D + col])
                if j == LL:
                    last.add(taps[((j - 1) * TAP + i) * D + col], h[row * D + col])
    show("LLM, worst of 24 taps", worst)
    show("LLM, the last tap (after the final norm)", last)


def gpu_npu(mut m: VLAAdapter, ctx: DeviceContext, r: String, L: Int, S: Int, runs: Int) raises:
    """GPU+NPU: the vision and/or LLM graphs on the NPU, the rest on the GPU; checked, then timed."""
    m.embed()
    if m.npu_vision >= 0:
        m.vision_npu()
        show("vision tokens from the NPU (512 x 896)", compare(fetch(ctx, m.x, (VROWS + 1) * D), D,
                                                               read_f32(r + "projector.f32"), D, rows_from(1, VROWS), D))
        print("NPU vision graph:", round(m.npu_time(), 1), "ms (server clock)")
    else:
        m.vision()
        m.projector()
    if m.npu_llm >= 0:
        m.llm_npu()
        check_taps(ctx, m, r, L)
        print("NPU LLM graph:", round(m.npu_time(), 1), "ms (server clock)")
    else:
        m.llm()
    m.policy()
    show("actions (8 x 7, normalized), GPU+NPU", compare(fetch(ctx, m.actions, 8 * 64), 64,
                                                         read_f32(r + "policy_actions_norm.f32"), ADIM, span(8), ADIM))
    for run in range(runs):
        var a0 = now_ms()
        m.chunk()
        ctx.synchronize()
        print("run", run, ": chunk", round(now_ms() - a0, 1), "ms (Mac clock)")
    if getenv("VLA_REPLAY"):
        cool_down()
        var k = Int(getenv("VLA_REPLAY"))
        var line = String("replay: chunk, ") + String(k) + " chunks a replay, ms a chunk (server clock):"
        for _ in range(5):
            line += " " + String(round(replay(m, ctx, k), 1))
        print(line)
    print("done")


def main() raises:
    var args = argv()
    if len(args) < 3:
        raise Error("usage: vla_adapter <model.safetensors>,<head_bf16.safetensors> <ref dir> [runs]")
    var r = String(args[2]) + "/"
    var runs = Int(args[3]) if len(args) > 3 else 3
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t0 = now_ms()
    var m = VLAAdapter(ctx, String(args[1]))
    print("weights:", Float64(m.bytes) / 1e9, "GB (bf16), loaded in", round((now_ms() - t0) / 1e3, 2), "s;",
          "opt" if m.opt else "baseline")
    var meta = open(r + "meta.json", "r").read()
    var L = meta_int(meta, "L")
    var S = L + VROWS + 65
    m.set_inputs(read_f32(r + "pixel_values.f32"), read_i32(r + "input_ids.i32"), L, read_f32(r + "proprio_norm.f32"))
    print("prompt", L, "tokens; sequence", S, "rows")

    if m.npu_vision >= 0 or m.npu_llm >= 0:  # GPU+NPU
        gpu_npu(m, ctx, r, L, S, runs)
        return
    var tc = now_ms()
    m.dinov2()
    var drows = List[Int]()
    for v in range(NIMG):
        for p in range(NPATCH):
            drows.append(v * DR + DPRE + p)
    var dref = read_f32(r + "dinov2_0.f32") + read_f32(r + "dinov2_1.f32")
    show("DINOv2 (2 x 256 x 1024, block 22)", compare(fetch(ctx, m.dx, NIMG * DR * DV), DV, dref, DV, drows, DV))
    m.siglip()
    var sref = read_f32(r + "siglip_0.f32") + read_f32(r + "siglip_1.f32")
    show("SigLIP (2 x 256 x 1152, block 25)", compare(fetch(ctx, m.sx, VROWS * SV), SV, sref, SV, span(VROWS), SV))
    m.embed()
    m.projector()
    show("projector (512 x 896)", compare(fetch(ctx, m.x, (VROWS + 1) * D), D, read_f32(r + "projector.f32"), D,
                                          rows_from(1, VROWS), D))
    show("LLM input (S x 896)", compare(fetch(ctx, m.x, S * D), D, read_f32(r + "llm_hidden_00.f32"), D, span(S), D))
    m.llm()
    var taps = fetch(ctx, m.taps, LL * TAP * D)
    var worst = Check()
    for j in range(1, LL + 1):
        var h = read_f32(r + "llm_hidden_" + ("0" if j < 10 else "") + String(j) + ".f32")
        var c = Check()
        for i in range(TAP):
            var row = i if i < VROWS else L + VROWS - 1 + (i - VROWS)
            for col in range(D):
                c.add(taps[((j - 1) * TAP + i) * D + col], h[row * D + col])
                worst.add(taps[((j - 1) * TAP + i) * D + col], h[row * D + col])
        if j == 1 or j == LL // 2 or j == LL - 1 or j == LL:
            show("LLM hidden_states[" + String(j) + "], the policy's windows", c)
    show("LLM, worst of 24 taps", worst)
    m.policy_start()
    show("proprio token (896)", compare(fetch(ctx, m.ha, 65 * D), D, read_f32(r + "proprio_p.f32"), D, [64], D))
    for i in range(LL):
        m.policy_block(i)
        if i == 0 or i == LL - 1:
            show("policy block " + String(i) + " (8 x 896)", compare(fetch(ctx, m.px, 8 * D), D,
                                                                   read_f32(r + "policy_block_" + ("0" if i < 10 else "") + String(i) + ".f32"),
                                                                   D, span(8), D))
    m.policy_end()
    var a = fetch(ctx, m.actions, 8 * 64)
    show("actions (8 x 7, normalized)", compare(a, 64, read_f32(r + "policy_actions_norm.f32"), ADIM, span(8), ADIM))
    var q01 = read_f32(r + "action_q01.f32")
    var q99 = read_f32(r + "action_q99.f32")
    var mask = open(r + "action_mask.u8", "r").read_bytes()
    var au = List[Float32](length=8 * ADIM, fill=0)
    for i in range(8):
        for c in range(ADIM):
            var v = a[i * 64 + c]
            au[i * ADIM + c] = Float32(0.5) * (v + 1) * (q99[c] - q01[c] + Float32(1e-8)) + q01[c] if mask[c] != 0 else v
    show("actions (8 x 7, LIBERO units)", compare(au, ADIM, read_f32(r + "actions.f32"), ADIM, span(8), ADIM))
    print("checked in", round((now_ms() - tc) / 1e3, 2), "s")

    for run in range(runs):
        var a0 = now_ms()
        m.vision()
        ctx.synchronize()
        var b = now_ms()
        m.embed()
        m.projector()
        ctx.synchronize()
        var c = now_ms()
        m.llm()
        ctx.synchronize()
        var d = now_ms()
        m.policy()
        ctx.synchronize()
        var e = now_ms()
        m.chunk()
        ctx.synchronize()
        var f = now_ms()
        print("run", run, ": vision", round(b - a0, 1), "ms, projector", round(c - b, 1), "ms, LLM", round(d - c, 1),
              "ms, policy", round(e - d, 1), "ms; chunk", round(f - e, 1), "ms")
    if getenv("VLA_REPLAY"):
        cool_down()
        var k = Int(getenv("VLA_REPLAY"))
        var line = String("replay: chunk, ") + String(k) + " chunks a replay, ms a chunk (server clock):"
        for _ in range(5):
            line += " " + String(round(replay(m, ctx, k), 1))
        print(line)
    print("done")
