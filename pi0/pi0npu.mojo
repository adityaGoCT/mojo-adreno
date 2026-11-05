# pi0npu: π0 (lerobot/pi0_base) with Gemma 2B's prefix on the Hexagon NPU and the rest on the Adreno. SigLIP, the
# projector and the expert's 10 denoising steps are pi0/model.mojo's DeviceContext launches, as in pi0.mojo. The prefix
# is npu/export_pi0.py's fp16 graphs, which npu/pi0_prefix.cpp runs through ONNX Runtime's QNN execution provider
# (HTP backend). Each part's K/V (fp16) are converted to fp32 and copied into the expert's cache (kc / vc, rows 0..815)
# while the NPU runs the next parts. The GPU holds no Gemma 2B weights (Pi0(gemma=False)). Built by npu/build.py pi0.
#
#   pi0npu <model.safetensors> <ref dir> <graph dir> [runs]
#     PI0_OUT=<f>   the action chunk (50 x 32 fp32) to a file
#     PI0_KV=<f>    the K/V handed to the expert (fp32 [layer][k, v][816][256]) to a file, for pi0/reference.py --kv
#
# <graph dir> holds the compiled parts (pi0npu_tool compile <dir> <i>, once a part a process) and gemma.bin.
from std.ffi import external_call
from std.os import getenv
from std.sys import argv
from max.gpu.host import DeviceContext

from check import Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import ADIM, CHUNK, D, HD, L, PLEN, STEPS, VD, VROWS, Pi0


def handoff(ctx: DeviceContext, model: Pi0, mut stage: List[Float32], first: Int, last: Int) raises:
    """The NPU's K and V of layers first .. last-1 (fp16 [816][256]) into the expert's cache: converted to fp32 in
    `stage` on the CPU, then copied to rows 0..815 of kc[l] / vc[l]."""
    for l in range(first, last):
        for w in range(2):
            var p = stage.unsafe_ptr().unsafe_offset((2 * l + w) * PLEN * HD)
            external_call["pi0npu_kv", NoneType](Int32(l), Int32(w), p, Int32(PLEN))
            if w == 0:
                ctx.enqueue_copy(model.kc[l].create_sub_buffer[DType.float32](0, PLEN * HD), p)
            else:
                ctx.enqueue_copy(model.vc[l].create_sub_buffer[DType.float32](0, PLEN * HD), p)


def prefix_npu(ctx: DeviceContext, model: Pi0, mut x: List[Float32], mut stage: List[Float32]) raises -> Float64:
    """The prefix on the NPU: the embeddings read back from the GPU (fp32 -> fp16), then the parts, each part's K/V
    handed to the GPU as soon as it is written. The copies are enqueued, not waited for. Returns the NPU's time."""
    ctx.enqueue_copy(x.unsafe_ptr(), model.tx.create_sub_buffer[DType.float32](0, PLEN * D))
    ctx.synchronize()
    if external_call["pi0npu_set_x", Int32](x.unsafe_ptr(), Int32(PLEN)) != 0:
        raise Error("pi0npu_set_x failed")
    if external_call["pi0npu_start", Int32]() != 0:
        raise Error("pi0npu_start failed")
    var parts = Int(external_call["pi0npu_parts", Int32]())
    for i in range(parts):
        if external_call["pi0npu_part_wait", Int32](Int32(i)) != 0:
            raise Error("the NPU's part " + String(i) + " failed")
        handoff(ctx, model, stage, Int(external_call["pi0npu_part_first", Int32](Int32(i))),
                Int(external_call["pi0npu_part_first", Int32](Int32(i + 1))))
    var ms = Float64(0)
    if external_call["pi0npu_finish", Int32](Pointer(to=ms)) != 0:
        raise Error("pi0npu_finish failed")
    return ms


def relative(got: List[Float32], want: List[Float32]) -> Float64:
    """Frobenius norm of got - want over want's."""
    var e = Float64(0)
    var w = Float64(0)
    for i in range(len(want)):
        var d = Float64(got[i]) - Float64(want[i])
        e += d * d
        w += Float64(want[i]) * Float64(want[i])
    return (e / w) ** 0.5


def run(ctx: DeviceContext, path: String, refdir: String, graphs: String, runs: Int) raises:
    var t0 = now_ms()
    var model = Pi0(ctx, path, gemma=False)
    print("weights:", Float64(model.w.bytes) / 1e9, "GB read from the checkpoint (no Gemma 2B layers: the prefix is",
          "on the NPU);", model.w.narrowed, "tensors stored as bf16 (exactly),", model.w.kept, "kept in fp32; loaded in",
          round((now_ms() - t0) / 1e3, 1), "s")
    var open_ms = Float64(0)
    var gdir = graphs
    if external_call["pi0npu_open", Int32](gdir.as_c_string_span(), Pointer(to=open_ms)) != 0:
        raise Error("pi0npu_open failed")
    var rows = Int(external_call["pi0npu_rows", Int32]())
    print("npu:", Int(external_call["pi0npu_parts", Int32]()), "parts (fp16, HTP) loaded in", round(open_ms / 1e3, 2),
          "s;", rows, "rows a prefix")

    var pixels = read_f32(refdir + "/pixels.f32")
    var tokens = read_i32(refdir + "/tokens.i32")
    var mask = read_i32(refdir + "/lang_mask.i32")
    var state = read_f32(refdir + "/state.f32")
    var noise = read_f32(refdir + "/noise.f32")
    var rope = read_f32(refdir + "/rope.f32")
    model.set_inputs(pixels, tokens, mask, state, noise, rope)
    var valid = List[Int]()
    var ok = List[Int32](length=PLEN, fill=0)
    var pos = List[Int32](length=PLEN, fill=0)
    for r in range(PLEN):  # positions: cumsum(pad mask) - 1, as set_inputs gives the GPU
        if r < VROWS or mask[r - VROWS] != 0:
            valid.append(r)
            ok[r] = 1
        pos[r] = Int32(max(len(valid) - 1, 0))
    if external_call["pi0npu_set_rope", Int32](rope.unsafe_ptr(), pos.unsafe_ptr(), ok.unsafe_ptr(), Int32(PLEN)) != 0:
        raise Error("pi0npu_set_rope failed")
    print("prefix:", PLEN, "rows,", len(valid), "valid; chunk", CHUNK, "x", ADIM, ",", STEPS, "steps")
    var x = List[Float32](length=PLEN * D, fill=0)
    var stage = List[Float32](length=2 * L * PLEN * HD, fill=0)

    # The check: every stage against reference.py's tensors (the first run also creates the GPU pipelines).
    var tc = now_ms()
    model.vision()
    show("vision (SigLIP So400m, 3 x 256 x 1152)", compare(fetch(ctx, model.vxn, VROWS * VD), VD,
                                                           read_f32(refdir + "/vision.f32"), VD, span(VROWS), VD))
    model.embed()
    var tx = fetch(ctx, model.tx, PLEN * D)
    var prefix_ref = read_f32(refdir + "/prefix.f32")
    var want = List[Float32]()
    for r in valid:
        for j in range(D):
            want.append(prefix_ref[r * D + j])
    show("prefix embeddings (valid rows)", compare(tx, D, want, D, valid, D))
    var npu_ms = prefix_npu(ctx, model, x, stage)
    ctx.synchronize()
    print("prefix on the NPU (cold):", round(npu_ms, 1), "ms")
    var kworst = Check()
    var vworst = Check()
    var kl = 0
    var vl = 0
    var krel = Float64(0)
    var vrel = Float64(0)
    var kv_all = List[Float32]()
    for l in range(L):
        var kref = read_f32(refdir + "/k" + String(l) + ".f32")
        var vref = read_f32(refdir + "/v" + String(l) + ".f32")
        var kg = fetch(ctx, model.kc[l], PLEN * HD)
        var vg = fetch(ctx, model.vc[l], PLEN * HD)
        kv_all.extend(kg.copy())
        kv_all.extend(vg.copy())
        var kw = List[Float32]()
        var vw = List[Float32]()
        var kgv = List[Float32]()
        var vgv = List[Float32]()
        for r in valid:
            for j in range(HD):
                kw.append(kref[r * HD + j])
                vw.append(vref[r * HD + j])
                kgv.append(kg[r * HD + j])
                vgv.append(vg[r * HD + j])
        var ck = compare(kg, HD, kw, HD, valid, HD)
        var cv = compare(vg, HD, vw, HD, valid, HD)
        if ck.err > kworst.err:
            kworst = ck.copy()
            kl = l
        if cv.err > vworst.err:
            vworst = cv.copy()
            vl = l
        krel = max(krel, relative(kgv, kw))
        vrel = max(vrel, relative(vgv, vw))
    show("prefix K cache (NPU, fp16), worst of 18 layers (layer " + String(kl) + ")", kworst)
    show("prefix V cache (NPU, fp16), worst of 18 layers (layer " + String(vl) + ")", vworst)
    print("check prefix K/V relative error (Frobenius), worst layer: K", krel, ", V", vrel)
    var kvpath = getenv("PI0_KV")
    if kvpath:
        var f = open(kvpath, "w")
        f.write_bytes(Span(unsafe_ptr=kv_all.unsafe_ptr().unsafe_bitcast[UInt8](), length=len(kv_all) * 4))
        f.close()
    for s in range(STEPS):
        model.step(s)
        var vt = fetch(ctx, model.vt, CHUNK * 64)
        var xt = fetch(ctx, model.xt, CHUNK * ADIM)
        show("step " + String(s) + " v_t", compare(vt, 64, read_f32(refdir + "/v_t" + String(s) + ".f32"), ADIM,
                                                   span(CHUNK), ADIM))
        if s == STEPS - 1:
            show("actions (50 x 32)", compare(xt, ADIM, read_f32(refdir + "/actions.f32"), ADIM, span(CHUNK), ADIM))
            var out = getenv("PI0_OUT")
            if out:
                var f = open(out, "w")
                f.write_bytes(Span(unsafe_ptr=xt.unsafe_ptr().unsafe_bitcast[UInt8](), length=CHUNK * ADIM * 4))
                f.close()
    print("checked in", round((now_ms() - tc) / 1e3, 2), "s (first run: pipelines created)")

    for r in range(runs):
        model.set_inputs(pixels, tokens, mask, state, noise, rope)
        var a = now_ms()
        model.vision()
        ctx.synchronize()
        var b = now_ms()
        model.embed()
        ctx.synchronize()
        var c = now_ms()
        var npu = prefix_npu(ctx, model, x, stage)
        ctx.synchronize()
        var d = now_ms()
        for s in range(STEPS):
            model.step(s)
        ctx.synchronize()
        var e = now_ms()
        model.set_inputs(pixels, tokens, mask, state, noise, rope)
        var f0 = now_ms()
        model.vision()
        model.embed()
        var npu2 = prefix_npu(ctx, model, x, stage)  # synchronizes the GPU first: it reads back the embeddings
        for s in range(STEPS):
            model.step(s)
        ctx.synchronize()
        var g = now_ms()
        print("run", r, ": vision", round(b - a, 1), "ms, projector+embed", round(c - b, 1), "ms, prefix",
              round(d - c, 1), "ms (NPU", round(npu, 1), "ms), 10 steps", round(e - d, 1), "ms (", round((e - d) / 10, 1),
              "ms/step ); chunk", round(g - f0, 1), "ms (NPU", round(npu2, 1), "ms)")


def main() raises:
    var args = argv()
    if len(args) < 4:
        raise Error("usage: pi0npu <model.safetensors> <ref dir> <graph dir> [runs]")
    var runs = Int(args[4]) if len(args) > 4 else 3
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    run(ctx, String(args[1]), String(args[2]), String(args[3]), runs)
    external_call["pi0npu_close", NoneType]()
    print("done")
