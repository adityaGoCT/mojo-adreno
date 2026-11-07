# lfm2_hybrid: LFM2.5-2.6B with its prompt prefilled on the Hexagon NPU and decoded on the Adreno. The NPU runs
# export_npu.py's w8a16 graphs (npu_lfm2.cpp on npu/graph.cpp: ONNX Runtime's QNN execution provider); their K/V go
# into model.mojo's KV caches ([position][8 x 64] fp32 a layer, as qk_norm_rope writes them), their conv states into
# its conv state rings (slot position % 3), the last prompt row's logits give the first token, and the GPU decodes on
# from the prompt's end with LFM2.step (the int4 storage), through MAX's DeviceContext and the Vulkan driver plugin.
# Built by npu/build.py lfm2hybrid; prints lfm2.mojo's lines ("tok <id> <ms>").
#
#   lfm2_hybrid <npu dir> <model.gguf> <storage dir> <weights.bin> <max new> @<ids file>
#     NPU_RUNS=k            prefill k times (default 3): the first is cold; the decode starts from the last
#     LFM2_EOS, LFM2_LOGITS, LFM2_LOGITS_EVERY   as lfm2.mojo
#     LFM2_ROWS=416, LFM2_SLOTS=512   the graphs' prefill rows and decode cache slots (export_npu.py's R, C)
#
# One model at a time: the NPU's contexts (3.4 GB) and the GPU's weights (1.6 GB) are not loaded together (a lab
# Fold rebooted with 3.8 + 2.2 GB, npu/README.md). The NPU's outputs stay in host memory while its contexts are
# released and the GPU model loads; that load is reported apart, not as part of the prompt's time.
from std.ffi import external_call
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import LFM2

comptime PARTS = 5
comptime KVH = 8
comptime HD = 64

comptime FP = UnsafePointer[Float32, MutAnyOrigin]


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def print_memory() raises:
    var status = open("/proc/self/status", "r").read()
    for line in status.split("\n"):  # (Mojo's splitlines() also breaks at the tab after each name)
        if line.startswith("VmHWM") or line.startswith("VmRSS") or line.startswith("VmSwap") or line.startswith("Rss"):
            print("mem:", String(line))
    try:  # the GPU's page allocations now, every buffer still held (bytes, system-wide: Pipette's GPU side)
        var pages = open("/sys/class/kgsl/kgsl/page_alloc", "r").read()
        print("mem: GpuPages:", String(pages.strip()))
    except:
        pass


def fail(what: String) raises:
    var msg = external_call["lfm2n_error", UnsafePointer[UInt8, MutAnyOrigin]]()
    var s = String()
    var i = 0
    while msg[i] != 0 and i < 400:
        s += chr(Int(msg[i]))
        i += 1
    raise Error(what + ": " + s)


def main() raises:
    var args = argv()
    if len(args) < 7:
        raise Error("usage: lfm2_hybrid <npu dir> <model.gguf> <storage dir> <weights.bin> <max new> @<ids file>")
    var npu_dir = String(args[1])
    var gguf = String(args[2])
    var max_new = Int(args[5])
    var prompt = List[Int32]()
    for i in range(6, len(args)):
        var a = String(args[i])
        if a.startswith("@"):
            for w in open(String(a[byte=1:]), "r").read().split():
                prompt.append(Int32(Int(w)))
        else:
            prompt.append(Int32(Int(a)))
    var n = len(prompt)
    var runs = Int(getenv("NPU_RUNS", "3"))
    var eos = List[Int]()
    var eos_list = getenv("LFM2_EOS")
    if eos_list:
        for s in eos_list.split(","):
            eos.append(Int(s))
    var logits_path = getenv("LFM2_LOGITS")
    var every = Int(getenv("LFM2_LOGITS_EVERY", "1"))
    var R = Int(getenv("LFM2_ROWS", "416"))
    var SLOTS = Int(getenv("LFM2_SLOTS", "512"))

    if external_call["lfm2n_open", Int32](npu_dir.as_c_string_span(), gguf.as_c_string_span(), Int32(R),
                                         Int32(SLOTS), Int32(PARTS)) != 0:
        fail("lfm2n_open")
    var ms = Float64(0)
    if external_call["lfm2n_prefill_open", Int32](Pointer(to=ms)) != 0:
        fail("lfm2n_prefill_open")
    print("npu: prefill contexts loaded in", round(ms / 1e3, 2), "s")
    var best = Float64(1e30)
    for r in range(runs):
        if external_call["lfm2n_prefill", Int32](prompt.unsafe_ptr(), Int32(n), Pointer(to=ms)) != 0:
            fail("lfm2n_prefill")
        if r > 0 or runs == 1:
            best = min(best, ms)
        print("prefill", r, ":", n, "tokens in", round(ms, 1), "ms (", round(Float64(n) * 1e3 / ms, 1),
              "tokens/s )", "cold" if r == 0 else "")

    var t_hand = now_ms()
    var logits_np = external_call["lfm2n_logits", FP]()
    var tok0 = 0
    for i in range(1, 128000):
        if logits_np[i] > logits_np[tok0]:
            tok0 = i
    if external_call["lfm2n_prefill_close", Int32]() != 0 or external_call["lfm2n_head_close", Int32]() != 0:
        fail("closing the NPU's contexts")
    var t_rel = now_ms() - t_hand

    var ctx = DeviceContext(api="vulkan")
    var t_load = now_ms()
    var model = LFM2(ctx, String(args[3]), String(args[4]))
    var load_ms = now_ms() - t_load
    print("gpu: weights", round(Float64(model.bytes) / 1e9, 3), "GB loaded in", round(load_ms / 1e3, 2),
          "s (after the NPU's contexts were released)")
    if n + max_new > model.CAP:
        raise Error("prompt + new tokens > " + String(model.CAP))
    # two decode steps on a dummy token build the decode pipelines here (counted in the handoff), not in a timed step
    var t_warm = now_ms()
    model.set_ids(0, [Int(prompt[0])])
    model.step(0)
    model.step(1)
    ctx.synchronize()
    model.reset()
    var warm_ms = now_ms() - t_warm

    # the NPU's K/V [KVH][R][HD] -> the GPU cache's rows [position][KVH * HD]; conv states -> ring slots p % 3
    var t_in = now_ms()
    var row = KVH * HD
    var stride = Int(external_call["lfm2n_kv_stride", Int32]())  # rows of the NPU's K/V [KVH][stride][HD]
    var stage = List[Float32](length=n * row, fill=0)
    for l in range(model.L):
        if model.attn[l]:
            for w in range(2):
                var src = external_call["lfm2n_k", FP](Int32(l)) if w == 0 else external_call["lfm2n_v", FP](Int32(l))
                for g in range(KVH):
                    for p in range(n):
                        for d in range(HD):
                            stage[p * row + g * HD + d] = src[(g * stride + p) * HD + d]
                var cache = model.kc[l] if w == 0 else model.vc[l]
                ctx.enqueue_copy(cache.create_sub_buffer[DType.float32](0, n * row), stage.unsafe_ptr())
                ctx.synchronize()
        else:
            var s = external_call["lfm2n_state", FP](Int32(l))
            for k in range(2):
                var p = n - 2 + k
                ctx.enqueue_copy(model.cs[l].create_sub_buffer[DType.float32]((p % 3) * model.D, model.D),
                                 s + k * model.D)
            ctx.synchronize()
    var copy_ms = now_ms() - t_in
    var ids = List[Int]()
    for i in range(n):
        ids.append(Int(prompt[i]))
    ids.append(tok0)
    model.set_ids(0, ids)
    print("handoff: NPU contexts released in", round(t_rel, 1), "ms; K/V and conv states into the GPU in",
          round(copy_ms + warm_ms, 1), "ms (", round(warm_ms, 1), "ms of it building the decode pipelines )")
    print("prompt:", n, "tokens in", round(best, 1), "ms (", round(Float64(n) * 1e3 / best, 1),
          "tokens/s, NPU prefill, best warm ); + handoff", round(t_rel + copy_ms, 1), "ms (GPU load not counted)")

    var logits = List[Float32](length=model.V, fill=0)
    var out = FileHandle()
    if logits_path:
        out = open(logits_path, "w")
        out.write_bytes(Span(unsafe_ptr=logits_np.unsafe_bitcast[UInt8](), length=model.V * 4))
    var tok = List[Int32](length=1, fill=Int32(tok0))
    var gen = 0
    var t_dec = 0.0
    var step_ms = best
    for i in range(max_new):
        if logits_path and i > 0 and i % every == 0:
            ctx.enqueue_copy(logits.unsafe_ptr(), model.logits)
            ctx.synchronize()
            out.write_bytes(Span(unsafe_ptr=logits.unsafe_ptr().unsafe_bitcast[UInt8](), length=model.V * 4))
        var t = Int(tok[0])
        print("tok", t, round(step_ms, 2))
        gen += 1
        var stop = i == max_new - 1
        for e in eos:
            if t == e:
                stop = True
        if stop:
            break
        var ts = now_ms()
        model.step(n + i)
        ctx.enqueue_copy(tok.unsafe_ptr(), model.ids.create_sub_buffer[DType.int32](n + i + 1, 1))
        ctx.synchronize()
        step_ms = now_ms() - ts
        t_dec += step_ms
    if logits_path:
        out.close()
    print_memory()
    _ = model.V  # the model (its GPU buffers) lives through that reading: Mojo frees a value after its last use
    if gen > 1:
        print("decode:", gen - 1, "steps,", round(t_dec / Float64(gen - 1), 2), "ms/token (",
              round(Float64(gen - 1) * 1000.0 / t_dec, 2), "tokens/s )")
