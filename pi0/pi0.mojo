# pi0: π0 (lerobot/pi0_base) on the phone's Adreno, pi0/model.mojo's forward pass through MAX's DeviceContext and
# the Vulkan driver plugin, built for Android by android/build.py pi0. It loads the checkpoint as Hugging Face
# serves it (fp32; bf16-exact tensors stored in bf16), runs pi0/reference.py's example and checks every stage
# against PyTorch's tensors; then times the action chunk.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so pi0 <model.safetensors> <ref dir> [runs]
#     PI0_PROFILE=1   one more run, synchronized after every launch: the time of each kind of launch
#     PI0_OUT=<f>     the action chunk (50 x 32 fp32) to a file
from std.os import getenv
from std.sys import argv
from max.gpu.host import DeviceContext

from check import Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import ADIM, CHUNK, D, HD, L, NLANG, PLEN, STEPS, VD, VROWS, Pi0


def run(ctx: DeviceContext, path: String, refdir: String, runs: Int) raises:
    var t0 = now_ms()
    var model = Pi0(ctx, path)
    print("weights:", Float64(model.w.bytes) / 1e9, "GB read from the checkpoint;", model.w.narrowed,
          "tensors stored as bf16 (exactly),", model.w.kept, "kept in fp32; loaded in",
          round((now_ms() - t0) / 1e3, 1), "s")
    var pixels = read_f32(refdir + "/pixels.f32")
    var tokens = read_i32(refdir + "/tokens.i32")
    var mask = read_i32(refdir + "/lang_mask.i32")
    var state = read_f32(refdir + "/state.f32")
    var noise = read_f32(refdir + "/noise.f32")
    var rope = read_f32(refdir + "/rope.f32")
    model.set_inputs(pixels, tokens, mask, state, noise, rope)
    var valid = List[Int]()
    for r in range(PLEN):
        if r < VROWS or mask[r - VROWS] != 0:
            valid.append(r)
    print("prefix:", PLEN, "rows,", len(valid), "valid; chunk", CHUNK, "x", ADIM, ",", STEPS, "steps")

    var tc = now_ms()
    model.vision()
    show("vision (SigLIP So400m, 3 x 256 x 1152)", compare(fetch(ctx, model.vxn, VROWS * VD), VD,
                                                           read_f32(refdir + "/vision.f32"), VD, span(VROWS), VD))
    model.embed()
    var tx = fetch(ctx, model.tx, PLEN * D)
    show("image tokens (projector)", compare(tx, D, read_f32(refdir + "/image.f32"), D, span(VROWS), D))
    var prefix_ref = read_f32(refdir + "/prefix.f32")
    var want = List[Float32]()
    for r in valid:
        for j in range(D):
            want.append(prefix_ref[r * D + j])
    show("prefix embeddings (valid rows)", compare(tx, D, want, D, valid, D))
    model.prefix()
    var kworst = Check()
    var vworst = Check()
    var kl = 0
    for l in range(L):
        var kref = read_f32(refdir + "/k" + String(l) + ".f32")
        var vref = read_f32(refdir + "/v" + String(l) + ".f32")
        var kg = fetch(ctx, model.kc[l], PLEN * HD)
        var vg = fetch(ctx, model.vc[l], PLEN * HD)
        var kw = List[Float32]()
        var vw = List[Float32]()
        for r in valid:
            for j in range(HD):
                kw.append(kref[r * HD + j])
                vw.append(vref[r * HD + j])
        var ck = compare(kg, HD, kw, HD, valid, HD)
        var cv = compare(vg, HD, vw, HD, valid, HD)
        if ck.err > kworst.err:
            kworst = ck.copy()
            kl = l
        if cv.err > vworst.err:
            vworst = cv.copy()
    show("prefix K cache, worst of 18 layers (layer " + String(kl) + ")", kworst)
    show("prefix V cache, worst of 18 layers", vworst)
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
        else:
            show("step " + String(s) + " x_t", compare(xt, ADIM, read_f32(refdir + "/x_t" + String(s) + ".f32"), ADIM,
                                                       span(CHUNK), ADIM))
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
        print("run", r, ": vision", round(b - a, 1), "ms, projector+embed", round(c - b, 1), "ms, prefix",
              round(d - c, 1), "ms, 10 steps", round(e - d, 1), "ms (", round((e - d) / 10, 1), "ms/step ); chunk",
              round(g - f0, 1), "ms")
    if getenv("PI0_PROFILE") != "":
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
        raise Error("usage: pi0 <model.safetensors> <ref dir> [runs]")
    var runs = Int(args[3]) if len(args) > 3 else 2
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    run(ctx, String(args[1]), String(args[2]), runs)
    print("done")
