# pi0npu: π0 (lerobot/pi0_base) with Gemma 2B's prefix on the Hexagon NPU and the rest on the Adreno. SigLIP, the
# projector and the expert's 10 denoising steps are pi0/model.mojo's DeviceContext launches, as in pi0.mojo. The prefix
# is npu/export_pi0.py's fp16 graphs, which npu/pi0_prefix.cpp runs through ONNX Runtime's QNN execution provider
# (HTP backend). Each part's K/V (fp16) are converted to fp32 and copied into the expert's cache (kc / vc, rows 0..815)
# while the NPU runs the next parts. The GPU holds no Gemma 2B weights (Pi0(gemma=False)). Built by npu/build.py pi0.
#
# Built for a Snapdragon X2 Elite laptop instead (vla/x2/build_mac.sh pi0npu: -D PI0NPU_REMOTE), it runs on the Mac and
# drives the laptop's GPU through the remote driver plugin, and npu/pi0_prefix.cpp runs inside the laptop's Vulkan
# server (vk_server_npu.exe): the plugin's M_driver_remote_npu_* ask it to read the embeddings from the GPU's buffer and
# write each layer's K/V into kc / vc there, so the 30 MB of K/V never cross the tunnel. <graph dir> is then a path
# on the laptop.
#
#   pi0npu <model.safetensors> <ref dir> <graph dir> [runs]
#     PI0_OUT=<f>   the action chunk (50 x 32 fp32) to a file
#     PI0_KV=<f>    the K/V handed to the expert (fp32 [layer][k, v][816][256]) to a file, for pi0/reference.py --kv
#
# <graph dir> holds the compiled parts (pi0npu_tool compile <dir> <i>, once a part a process) and gemma.bin.
from std.ffi import OwnedDLHandle, external_call
from std.os import getenv
from std.sys import argv, is_defined
from max.gpu.host import DeviceContext

from check import Check, compare, fetch, now_ms, read_f32, read_i32, show, span
from model import ADIM, CHUNK, D, HD, L, PLEN, STEPS, VD, VROWS, Pi0

comptime REMOTE = is_defined["PI0NPU_REMOTE"]()  # the NPU is in the remote device's server (vla/x2)


def plugin_path() raises -> String:
    """The driver plugin MAX loaded: MODULAR_DRIVER_PLUGINS=vulkan@<path of libM_driver_vulkan_remote>."""
    var spec = getenv("MODULAR_DRIVER_PLUGINS")
    var at = spec.find("@")
    if at < 0:
        raise Error("MODULAR_DRIVER_PLUGINS=vulkan@<path of libM_driver_vulkan_remote> is needed")
    return String(spec[byte=at + 1:])


struct Npu(Movable):
    """The prefix's graphs on the NPU: npu/pi0_prefix.cpp in this process (the phone), or in the remote device's
    vk_server_npu, reached through the driver plugin (REMOTE)."""

    var lib: OwnedDLHandle  # REMOTE: the driver plugin, for M_driver_remote_npu_*
    var rows: Int
    var parts: Int
    var load_ms: Float64

    def __init__(out self, graphs: String) raises:
        var dir = graphs
        self.load_ms = 0
        var rows = Int32(0)
        var parts = Int32(0)
        comptime if REMOTE:
            self.lib = OwnedDLHandle(plugin_path())
            if self.lib.call["M_driver_remote_npu_open", Int32](dir.as_c_string_span().unsafe_ptr(),
                                                                Pointer(to=self.load_ms), Pointer(to=rows),
                                                                Pointer(to=parts)) != 0:
                raise Error("M_driver_remote_npu_open failed: is the server vk_server_npu.exe, run from its DLLs?")
        else:
            self.lib = OwnedDLHandle()
            if external_call["pi0npu_open", Int32](dir.as_c_string_span(), Pointer(to=self.load_ms)) != 0:
                raise Error("pi0npu_open failed")
            rows = external_call["pi0npu_rows", Int32]()
            parts = external_call["pi0npu_parts", Int32]()
        self.rows = Int(rows)
        self.parts = Int(parts)

    def set_rope(self, rope: List[Float32], pos: List[Int32], ok: List[Int32]) raises:
        """Each prefix row's position and whether keys may attend to it."""
        comptime if REMOTE:
            if self.lib.call["M_driver_remote_npu_rope", Int32](rope.unsafe_ptr(), pos.unsafe_ptr(), ok.unsafe_ptr(),
                                                                Int32(PLEN)) != 0:
                raise Error("M_driver_remote_npu_rope failed")
        else:
            if external_call["pi0npu_set_rope", Int32](rope.unsafe_ptr(), pos.unsafe_ptr(), ok.unsafe_ptr(),
                                                       Int32(PLEN)) != 0:
                raise Error("pi0npu_set_rope failed")

    def prefix(self, ctx: DeviceContext, model: Pi0, mut x: List[Float32], mut stage: List[Float32]) raises -> Float64:
        """The prefix on the NPU, from the embeddings in model.tx to every layer's K/V in model.kc / model.vc.
        On the phone: the embeddings read back from the GPU (fp32 -> fp16), then the parts, each part's K/V handed to
        the GPU as soon as it is written; the copies are enqueued, not waited for. Returns the NPU's time.
        REMOTE: one request, which the server runs once the GPU's work before it is done, the launches after it
        queuing behind it; nothing crosses the tunnel but the buffers' names. Returns 0: the NPU's time is time()'s."""
        comptime if REMOTE:
            var k = List[UInt64]()
            var v = List[UInt64]()
            for l in range(L):
                k.append(UInt64(Int(model.kc[l].unsafe_ptr())))
                v.append(UInt64(Int(model.vc[l].unsafe_ptr())))
            if self.lib.call["M_driver_remote_npu_prefix", Int32](UInt64(Int(model.tx.unsafe_ptr())), Int32(PLEN),
                                                                  k.unsafe_ptr(), v.unsafe_ptr(), Int32(L)) != 0:
                raise Error("M_driver_remote_npu_prefix failed")
            return 0
        else:
            ctx.enqueue_copy(x.unsafe_ptr(), model.tx.create_sub_buffer[DType.float32](0, PLEN * D))
            ctx.synchronize()
            if external_call["pi0npu_set_x", Int32](x.unsafe_ptr(), Int32(PLEN)) != 0:
                raise Error("pi0npu_set_x failed")
            if external_call["pi0npu_start", Int32]() != 0:
                raise Error("pi0npu_start failed")
            for i in range(self.parts):
                if external_call["pi0npu_part_wait", Int32](Int32(i)) != 0:
                    raise Error("the NPU's part " + String(i) + " failed")
                handoff(ctx, model, stage, Int(external_call["pi0npu_part_first", Int32](Int32(i))),
                        Int(external_call["pi0npu_part_first", Int32](Int32(i + 1))))
            var ms = Float64(0)
            if external_call["pi0npu_finish", Int32](Pointer(to=ms)) != 0:
                raise Error("pi0npu_finish failed")
            return ms

    def time(self) raises -> Tuple[Float64, Float64, Float64]:
        """REMOTE: the last prefix on the server's clock (ms): the embeddings to fp16, the graphs, and all of it through
        the last K/V written. A round trip: call it outside what is timed."""
        var convert = Float64(0)
        var graphs = Float64(0)
        var total = Float64(0)
        comptime if REMOTE:
            if self.lib.call["M_driver_remote_npu_time", Int32](Pointer(to=convert), Pointer(to=graphs),
                                                                Pointer(to=total)) != 0:
                raise Error("the NPU's prefix failed")
        return (convert, graphs, total)

    def close(self):
        comptime if not REMOTE:
            external_call["pi0npu_close", NoneType]()


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
    var npu = Npu(graphs)
    print("npu:", npu.parts, "parts (fp16, HTP) loaded in", round(npu.load_ms / 1e3, 2), "s;", npu.rows,
          "rows a prefix", "(in the remote device's vk_server_npu)" if REMOTE else "")

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
    npu.set_rope(rope, pos, ok)
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
    var npu_ms = npu.prefix(ctx, model, x, stage)
    ctx.synchronize()
    comptime if REMOTE:
        var t = npu.time()
        print("prefix on the NPU (cold, the server's clock):", round(t[1], 1), "ms; embeddings to fp16",
              round(t[0], 1), "ms, through the last K/V written", round(t[2], 1), "ms")
    else:
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

    comptime if REMOTE:
        print("the times below include the tunnel's round trips (one a synchronize); the laptop's own are",
              "vk_server's segments (VK_SERVER_SEGMENTS=1)")
    for r in range(runs):
        model.set_inputs(pixels, tokens, mask, state, noise, rope)
        var a = now_ms()
        model.vision()
        ctx.synchronize()
        var b = now_ms()
        model.embed()
        ctx.synchronize()
        var c = now_ms()
        var npu_ms1 = npu.prefix(ctx, model, x, stage)
        ctx.synchronize()
        var d = now_ms()
        var prefix_ms = d - c
        comptime if REMOTE:  # the server's NPU time, asked before the steps start
            npu_ms1 = npu.time()[1]
            d = now_ms()
        for s in range(STEPS):
            model.step(s)
        ctx.synchronize()
        var e = now_ms()
        model.set_inputs(pixels, tokens, mask, state, noise, rope)
        var f0 = now_ms()
        model.vision()
        model.embed()
        var npu_ms2 = npu.prefix(ctx, model, x, stage)  # on the phone, synchronizes the GPU first: it reads back x
        for s in range(STEPS):
            model.step(s)
        ctx.synchronize()
        var g = now_ms()
        comptime if REMOTE:  # the NPU's times of the chunk's prefix, on the server's clock
            var t = npu.time()
            npu_ms2 = t[1]
        print("run", r, ": vision", round(b - a, 1), "ms, projector+embed", round(c - b, 1), "ms, prefix",
              round(prefix_ms, 1), "ms (NPU", round(npu_ms1, 1), "ms), 10 steps", round(e - d, 1), "ms (",
              round((e - d) / 10, 1), "ms/step ); chunk", round(g - f0, 1), "ms (NPU", round(npu_ms2, 1), "ms)")
    npu.close()


def main() raises:
    var args = argv()
    if len(args) < 4:
        raise Error("usage: pi0npu <model.safetensors> <ref dir> <graph dir> [runs]")
    var runs = Int(args[4]) if len(args) > 4 else 3
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    run(ctx, String(args[1]), String(args[2]), String(args[3]), runs)
    print("done")
