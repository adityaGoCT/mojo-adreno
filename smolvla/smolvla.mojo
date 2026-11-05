# smolvla: SmolVLA (lerobot/smolvla_base) on the phone's Adreno, smolvla/model.mojo's forward pass through MAX's
# DeviceContext and the Vulkan driver plugin, built for Android by android/build.py smolvla. It loads the
# checkpoint as Hugging Face serves it, runs smolvla/reference.py's example (three camera images, the task's
# tokens, the state, the noise) and checks every stage against PyTorch's tensors; then times the action chunk.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so smolvla <model.safetensors> <ref dir> [runs]
#     SMOLVLA_PREC=bf16   (default) the checkpoint's bf16 and fp32 weights, fp32 matrix units
#     SMOLVLA_PREC=fp16w  every weight rounded to fp16 at load, fp32 matrix units
#     SMOLVLA_PREC=fp16   fp16 weights and the projections on the fp16 matrix units (fp16 sums)
#     SMOLVLA_PROFILE=1   one more run, synchronized after every launch: the time of each kind of launch
#     SMOLVLA_OUT=<f>   the action chunk (50 x 32 fp32) to a file
#
# Output: one line per checked stage (max abs error, and the largest reference value for scale), then per
# run the time of each stage (synchronized after each) and of the whole chunk (one synchronize at the end).
from std.math import sqrt
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext

from check import Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import (ADIM, CHUNK, KVD, NCAM, NIMG, NLANG, PLEN, STEPS, TD, TL, VD, VROWS, SmolVLA)


def run[W16: DType, MMA16: Bool](ctx: DeviceContext, path: String, refdir: String, runs: Int) raises:
    var t0 = now_ms()
    var model = SmolVLA[W16, MMA16](ctx, path)
    var sk = getenv("SMOLVLA_SK_ROWS")
    if sk:
        model.s.sk_rows = Int(sk)
    var prec = "bf16 and fp32 weights as stored, fp32 matrix units"
    comptime if W16 == DType.float16:
        prec = "fp16 weights and fp16 matrix units (fp16 sums)" if MMA16 else "fp16 weights, fp32 matrix units"
    print("weights:", Float64(model.w.bytes) / 1e9, "GB from the checkpoint;", prec, "; loaded in",
          round((now_ms() - t0) / 1e3, 2), "s")
    var pixels = read_f32(refdir + "/pixels.f32")
    var tokens = read_i32(refdir + "/tokens.i32")
    var mask = read_i32(refdir + "/lang_mask.i32")
    var state = read_f32(refdir + "/state.f32")
    var noise = read_f32(refdir + "/noise.f32")
    var rope = read_f32(refdir + "/rope.f32")
    model.set_inputs(pixels, tokens, mask, state, noise, rope)
    var valid = List[Int]()  # the prefix rows that are not padding
    for r in range(PLEN):
        if r < NCAM * NIMG or r == PLEN - 1 or mask[r - NCAM * NIMG] != 0:
            valid.append(r)
    print("prefix:", PLEN, "rows,", len(valid), "valid; chunk", CHUNK, "x", ADIM, ",", STEPS, "steps")

    # The check: stage by stage against reference.py's tensors (the first run also creates the pipelines).
    var tc = now_ms()
    model.vision()
    show("vision (SigLIP, 3 x 1024 x 768)", compare(fetch(ctx, model.vxn, VROWS * VD), VD,
                                                    read_f32(refdir + "/vision.f32"), VD, span(VROWS), VD))
    model.embed()
    var prefix_ref = read_f32(refdir + "/prefix.f32")
    var tx = fetch(ctx, model.tx, PLEN * TD)
    show("connector (image tokens x sqrt(960))", compare(tx, TD, prefix_ref, TD, span(NCAM * NIMG), TD))
    var vrows = List[Int]()
    for r in valid:
        vrows.append(r)
    var want = List[Float32]()  # prefix_ref's valid rows
    for r in valid:
        for j in range(TD):
            want.append(prefix_ref[r * TD + j])
    show("prefix embeddings (valid rows)", compare(tx, TD, want, TD, vrows, TD))
    model.prefix()
    var kworst = Check()
    var vworst = Check()
    var kl = 0
    for l in range(TL):
        var kref = read_f32(refdir + "/k" + String(l) + ".f32")
        var vref = read_f32(refdir + "/v" + String(l) + ".f32")
        var kg = fetch(ctx, model.kc[l], PLEN * KVD)
        var vg = fetch(ctx, model.vc[l], PLEN * KVD)
        var kw = List[Float32]()
        var vw = List[Float32]()
        for r in valid:
            for j in range(KVD):
                kw.append(kref[r * KVD + j])
                vw.append(vref[r * KVD + j])
        var ck = compare(kg, KVD, kw, KVD, vrows, KVD)
        var cv = compare(vg, KVD, vw, KVD, vrows, KVD)
        if ck.err > kworst.err:
            kworst = ck.copy()
            kl = l
        if cv.err > vworst.err:
            vworst = cv.copy()
    show("prefix K cache, worst of 16 layers (layer " + String(kl) + ")", kworst)
    show("prefix V cache, worst of 16 layers", vworst)
    for s in range(STEPS):
        model.step(s)
        var vt = fetch(ctx, model.vt, CHUNK * 64)
        var xt = fetch(ctx, model.xt, CHUNK * ADIM)
        show("step " + String(s) + " v_t", compare(vt, 64, read_f32(refdir + "/v_t" + String(s) + ".f32"), ADIM,
                                                   span(CHUNK), ADIM))
        if s == STEPS - 1:
            var final = compare(xt, ADIM, read_f32(refdir + "/actions.f32"), ADIM, span(CHUNK), ADIM)
            var used = compare(xt, ADIM, read_f32(refdir + "/actions.f32"), ADIM, span(CHUNK), 6)
            show("actions (50 x 32)", final)
            show("actions, the 6 the robot uses", used)
            var out = getenv("SMOLVLA_OUT")
            if out:
                var f = open(out, "w")
                f.write_bytes(Span(unsafe_ptr=xt.unsafe_ptr().unsafe_bitcast[UInt8](), length=CHUNK * ADIM * 4))
                f.close()
        else:
            show("step " + String(s) + " x_t", compare(xt, ADIM, read_f32(refdir + "/x_t" + String(s) + ".f32"), ADIM,
                                                       span(CHUNK), ADIM))
    print("checked in", round((now_ms() - tc) / 1e3, 2), "s (first run: pipelines created)")

    # Timing: each stage synchronized; then the whole chunk with one synchronize.
    for r in range(runs):
        model.set_inputs(pixels, tokens, mask, state, noise, rope)
        var a = now_ms()
        model.vision()
        ctx.synchronize()
        var b = now_ms()
        model.embed()
        ctx.synchronize()
        var c = now_ms()
        model.prefix()
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
        model.prefix()
        for s in range(STEPS):
            model.step(s)
        ctx.synchronize()
        var g = now_ms()
        print("run", r, ": vision", round(b - a, 1), "ms, connector+embed", round(c - b, 1), "ms, prefix",
              round(d - c, 1), "ms, 10 steps", round(e - d, 1), "ms (", round((e - d) / 10, 1), "ms/step ); chunk",
              round(g - f0, 1), "ms")
    if getenv("SMOLVLA_PROFILE") != "":
        model.set_inputs(pixels, tokens, mask, state, noise, rope)
        model.profiling = True
        ctx.synchronize()
        model.last = now_ms()
        model.vision()
        model.embed()
        model.prefix()
        for s in range(STEPS):
            model.step(s)
        model.profiling = False
        var total = 0.0
        for item in model.prof.items():
            total += item.value
        print("profile (synchronized after every launch):", round(total, 1), "ms")
        for item in model.prof.items():
            print("  ", item.key, round(item.value, 2), "ms")


def main() raises:
    var args = argv()
    if len(args) < 3:
        raise Error("usage: smolvla <model.safetensors> <ref dir> [runs]")
    var runs = Int(args[3]) if len(args) > 3 else 3
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var prec = getenv("SMOLVLA_PREC", "bf16")
    if prec == "fp16":
        run[DType.float16, True](ctx, String(args[1]), String(args[2]), runs)
    elif prec == "fp16w":
        run[DType.float16, False](ctx, String(args[1]), String(args[2]), runs)
    elif prec == "bf16":
        run[DType.uint16, False](ctx, String(args[1]), String(args[2]), runs)
    else:
        raise Error("SMOLVLA_PREC: bf16, fp16w or fp16")
    print("done")
