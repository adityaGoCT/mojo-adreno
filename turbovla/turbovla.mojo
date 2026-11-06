# turbovla: TurboVLA (H-EmbodVis/TurboVLA, LIBERO) through MAX's DeviceContext: turbovla/model.mojo's forward pass on
# an Adreno, here the X2 Elite laptop's X2-90 behind vla/x2's Vulkan server (turbovla/build_mac.sh), or a phone's.
# It loads the fp32 checkpoint, runs turbovla/reference.py's example (two views, "put the bowl on the plate", a state)
# and checks every stage against PyTorch's tensors; then times action chunks.
#
#   VK_REMOTE_PORT=<port> MODULAR_DRIVER_PLUGINS=vulkan@<plugin> TURBOVLA_REMOTE=<the weights on the laptop> \
#       turbovla <turbovla.safetensors> <ref dir> [runs]
#
# A chunk's stages, each synchronized: vision (DINOv3 and the projection), text (BERT; once per instruction, so the
# chunk is timed without it too), fusion, action (state, decoder, MLP); then the whole chunk with one synchronize.
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from check import Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import (ADIM, BD, HD, HID, MEM, NF, NPATCH, NQ, NV, NVT, PREFIX, T, VD, VR, VTOK, TurboVLA)


def rows_of(view_rows: Int) -> List[Int]:
    """The patch rows of the vision buffer (v * 320 + 5 + p), in the reference's order."""
    var r = List[Int]()
    for v in range(NV):
        for p in range(NPATCH):
            r.append(v * view_rows + PREFIX + p)
    return r^


def main() raises:
    var args = argv()
    if len(args) < 3:
        raise Error("usage: turbovla <turbovla.safetensors> <ref dir> [runs]")
    var path = String(args[1])
    var refdir = String(args[2])
    var runs = Int(args[3]) if len(args) > 3 else 3
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t0 = now_ms()
    var m = TurboVLA(ctx, path)
    print("weights:", Float64(m.bytes) / 1e9, "GB (fp32), loaded in", round((now_ms() - t0) / 1e3, 2), "s")
    var meta = open(refdir + "/meta.json", "r").read()
    var g = meta.find('"text_group": ')
    var group = Int(String(meta[byte = g + 14 : meta.find(",", g)]))
    m.set_inputs(read_f32(refdir + "/pixels.f32"), read_i32(refdir + "/text_ids.i32"), read_i32(refdir + "/text_pos.i32"),
                 read_i32(refdir + "/text_mask.i32"), read_i32(refdir + "/text_keypad.i32"), read_f32(refdir + "/state.f32"),
                 group)
    print("instruction: BERT group", group, "of", T, "text tokens; memory", MEM, "rows")

    # the check, stage by stage (the first run also creates the pipelines)
    var tc = now_ms()
    if getenv("TURBOVLA_DEBUG"):  # DINOv3 layer by layer against build/turbovla/ref/dbg (dino_layers.py)
        var vrows = List[Int]()
        for v in range(NV):
            for r in range(VTOK):
                vrows.append(v * VR + r)
        show("RoPE cos", compare(fetch(ctx, m.rcos, NPATCH * HD), HD, read_f32(refdir + "/dbg/rope.f32"), HD,
                                 span(NPATCH), HD))
        m.embed()
        var xe = fetch(ctx, m.x, NV * VR * VD)
        var emb = read_f32(refdir + "/dbg/emb.f32")
        show("embeddings", compare(xe, VD, emb, VD, vrows, VD))
        for v in range(NV):
            for part in range(3):
                var lo = [0, 1, PREFIX][part]
                var hi = [1, PREFIX, VTOK][part]
                var c = Check()
                for r in range(lo, hi):
                    for j in range(VD):
                        c.add(xe[(v * VR + r) * VD + j], emb[(v * VTOK + r) * VD + j])
                show("  view " + String(v) + " rows " + String(lo) + ".." + String(hi - 1), c)
        var xp = fetch(ctx, m.xp, NVT * VD)
        var px = read_f32(refdir + "/pixels.f32")
        var c2 = Check()
        for r in range(2):  # patch (0, 0) and (0, 1) of view 0: c * 256 + ky * 16 + kx
            for j in range(VD):
                var ch = j // 256
                var ky = (j % 256) // 16
                var kx = j % 16
                c2.add(xp[r * VD + j], px[(ch * 256 + ky) * 256 + r * 16 + kx])
        show("  patchify, first patches", c2)
        for i in range(12):
            m.vlayer(i)
            show("DINOv3 layer " + String(i), compare(fetch(ctx, m.x, NV * VR * VD), VD,
                                                      read_f32(refdir + "/dbg/layer" + String(i) + ".f32"), VD, vrows, VD))
    m.vision()
    show("DINOv3 (2 x 256 patches x 768, final LayerNorm)",
         compare(fetch(ctx, m.xn, NV * VR * VD), VD, read_f32(refdir + "/dinov3.f32"), VD, rows_of(VR), VD))
    m.project()
    show("vision tokens (512 x 256)", compare(fetch(ctx, m.mem, NVT * HID), HID, read_f32(refdir + "/vision_tokens.f32"),
                                              HID, span(NVT), HID))
    m.text()
    show("BERT (21 x 768, zero-extended)", compare(fetch(ctx, m.tx, T * BD), BD, read_f32(refdir + "/bert_hidden.f32"), BD,
                                                   span(T), BD))
    show("text tokens (21 x 256)", compare(fetch(ctx, m.l, T * HID), HID, read_f32(refdir + "/text_tokens.f32"), HID,
                                           span(T), HID))
    for i in range(NF):
        m.fusion(i)
        var tag = String(i)
        show("fusion " + tag + " vision", compare(fetch(ctx, m.mem, NVT * HID), HID,
                                                  read_f32(refdir + "/fusion" + tag + "_v.f32"), HID, span(NVT), HID))
        show("text layer " + tag, compare(fetch(ctx, m.l, T * HID), HID, read_f32(refdir + "/text" + tag + ".f32"), HID,
                                          span(T), HID))
    m.action()
    var memory = fetch(ctx, m.mem, MEM * HID)
    show("memory (535 x 256)", compare(memory, HID, read_f32(refdir + "/memory.f32"), HID, span(MEM), HID))
    show("actions (12 x 7)", compare(fetch(ctx, m.actions, NQ * ADIM), ADIM, read_f32(refdir + "/actions.f32"), ADIM,
                                     span(NQ), ADIM))
    print("checked in", round((now_ms() - tc) / 1e3, 2), "s")

    for r in range(runs):
        var a = now_ms()
        m.vision()
        m.project()
        ctx.synchronize()
        var b = now_ms()
        m.text()
        ctx.synchronize()
        var c = now_ms()
        ctx.enqueue_copy(m.l, m.l0)
        for i in range(NF):
            m.fusion(i)
        ctx.synchronize()
        var d = now_ms()
        m.action()
        ctx.synchronize()
        var e = now_ms()
        m.chunk(False)
        ctx.synchronize()
        var f = now_ms()
        print("run", r, ": vision", round(b - a, 1), "ms, text (BERT)", round(c - b, 1), "ms, fusion", round(d - c, 1),
              "ms, action", round(e - d, 1), "ms; chunk without text", round(f - e, 1), "ms")
    if getenv("TURBOVLA_PROFILE"):  # one more chunk, synchronized after each operation: VK_SERVER_SEGMENTS times each
        ctx.enqueue_copy(m.l, m.l0)
        ctx.synchronize()
        m.profiling = True
        print("profile: one chunk, each operation waited for alone")
        m.chunk(False)
        m.profiling = False
    print("done")
