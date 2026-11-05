# hybrid: Llama 3.2 1B with its prompt prefilled on the Hexagon NPU and decoded on the Adreno. The NPU runs
# npu/export.py's graphs through npu_prefill.cpp (ONNX Runtime's QNN execution provider, HTP backend). Their
# K/V and the last prompt row's logits are handed to llama/model.mojo's KV cache ([kv head][MAXPOS][64] fp32 a
# layer, as p_rope_kv writes it), and decode continues from the prompt's end with Llama.forward, through MAX's
# DeviceContext and the Vulkan driver plugin. Built by npu/build.py hybrid; llama/run.py's lines, so
# npu/run.py checks it against PyTorch.
#
#   hybrid <model dir> <graph dir> <max new> <prompt token ids...>
#     LLAMA_EOS=128001,128009   stop tokens          LLAMA_LOGITS=<file>   logits after the prompt (fp32)
#     NPU_RUNS=<k>              prefill k times first (default 3; the first is cold)
#
# Then the prefill and handoff are timed twice: one after the other, and overlapped (each part's layers converted
# and copied to the GPU while the NPU runs the next parts). Decode starts from the overlapped one.
#
# <model dir> is the GPU's weights (model or model-q4): the NPU graphs read the fp16 weights.bin next to them,
# and the embedding rows come from <model dir>'s.
from std.ffi import external_call
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import Llama, HD, KVH, L, MAXPOS, V


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def argmax(logits: List[Float32]) -> Int:
    var best = 0
    for i in range(1, V):
        if logits[i] > logits[best]:
            best = i
    return best


def handoff(ctx: DeviceContext, model: Llama, mut stage: List[Float32], n: Int, first: Int, last: Int) raises:
    """The NPU's K/V of layers first .. last-1, fp16 [8][rows][64], into the GPU model's fp32 [8][MAXPOS][64]
    caches: each converted on the CPU into `stage`, then copied to its device buffer."""
    for l in range(first, last):
        for w in range(2):
            var p = stage.unsafe_ptr() + (2 * l + w) * KVH * MAXPOS * HD
            external_call["npu_kv", NoneType](Int32(l), Int32(w), p, Int32(MAXPOS), Int32(n))
            ctx.enqueue_copy(model.vc[l] if w else model.kc[l], p)


def main() raises:
    var args = argv()
    if len(args) < 5:
        raise Error("usage: hybrid <model dir> <graph dir> <max new tokens> <prompt token ids...>")
    var model_dir = String(args[1])
    var graph_dir = String(args[2])
    var max_new = Int(args[3])
    var prompt = List[Int32]()
    for i in range(4, len(args)):
        prompt.append(Int32(Int(args[i])))
    var n = len(prompt)
    if n + max_new > MAXPOS:
        raise Error("prompt + new tokens > " + String(MAXPOS))
    var eos = List[Int]()
    var eos_list = getenv("LLAMA_EOS")
    if eos_list:
        for s in eos_list.split(","):
            eos.append(Int(s))
    var runs = Int(getenv("NPU_RUNS", "3"))

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = Llama(ctx, model_dir)
    print("loaded in", round((now_ms() - t_load) / 1e3, 1), "s")

    var open_ms = Float64(0)
    var compiled = Int32(0)
    if external_call["npu_open", Int32](graph_dir.as_c_string_span(), model_dir.as_c_string_span(),
                                       Pointer(to=open_ms), Pointer(to=compiled)) != 0:
        raise Error("npu_open failed")
    var rows = Int(external_call["npu_rows", Int32]())
    print("npu: graphs", "compiled" if compiled > 0 else "loaded", "in", round(open_ms / 1e3, 2), "s (" +
          String(compiled) + " parts compiled now);", rows, "rows a prefill")
    if n > rows:
        raise Error("prompt of " + String(n) + " tokens > the graphs' " + String(rows) + " rows")

    var best = Float64(1e30)
    var ms = Float64(0)
    for r in range(runs):
        if external_call["npu_prefill", Int32](prompt.unsafe_ptr(), Int32(n), Pointer(to=ms)) != 0:
            raise Error("npu_prefill failed")
        if r > 0:
            best = min(best, ms)
        print("npu prefill", r, ":", n, "tokens in", round(ms, 1), "ms (" + String(Int(Float64(n) * 1e3 / ms)) +
              " tokens/s)", "cold" if r == 0 else "")

    var stage = List[Float32](length=2 * L * KVH * MAXPOS * HD, fill=0)
    var logits = List[Float32](length=V, fill=0)

    # One after the other: the whole prefill on the NPU, then the handoff of all 16 layers.
    var t_seq = now_ms()
    if external_call["npu_prefill", Int32](prompt.unsafe_ptr(), Int32(n), Pointer(to=ms)) != 0:
        raise Error("npu_prefill failed")
    var t_hand = now_ms()
    handoff(ctx, model, stage, n, 0, L)
    external_call["npu_logits", NoneType](logits.unsafe_ptr())
    ctx.synchronize()
    var hand_ms = now_ms() - t_hand
    var seq_ms = now_ms() - t_seq
    print("one after the other: NPU prefill", round(ms, 1), "ms, then the handoff of", L, "layers and the logits",
          round(hand_ms, 1), "ms:", round(seq_ms, 1), "ms")

    # Overlapped: each part's layers are handed to the GPU while the NPU runs the next parts.
    var parts = Int(external_call["npu_parts", Int32]())
    var t_ov = now_ms()
    if external_call["npu_prefill_start", Int32](prompt.unsafe_ptr(), Int32(n)) != 0:
        raise Error("npu_prefill_start failed")
    var t_last = t_ov
    for i in range(parts):
        if external_call["npu_part_wait", Int32](Int32(i)) != 0:
            raise Error("npu prefill part " + String(i) + " failed")
        t_last = now_ms()
        handoff(ctx, model, stage, n, Int(external_call["npu_part_first", Int32](Int32(i))),
                Int(external_call["npu_part_first", Int32](Int32(i + 1))))
    if external_call["npu_prefill_finish", Int32](Pointer(to=ms)) != 0:
        raise Error("npu_prefill_finish failed")
    external_call["npu_logits", NoneType](logits.unsafe_ptr())
    ctx.synchronize()
    var ov_ms = now_ms() - t_ov
    hand_ms = ov_ms - ms
    print("overlapped: NPU prefill", round(ms, 1), "ms; the last part's handoff and the logits", round(hand_ms, 1),
          "ms after it:", round(ov_ms, 1), "ms (the last part done", round(t_last - t_ov, 1), "ms in)")
    print("prompt:", n, "tokens in", Int(ov_ms), "ms (NPU prefill" + (" best warm " + String(Int(best)) +
          " ms" if runs > 1 else "") + ", handoff overlapped)")
    var path = getenv("LLAMA_LOGITS")
    if path:
        var f = open(path, "w")
        f.write_bytes(Span(unsafe_ptr=logits.unsafe_ptr().unsafe_bitcast[UInt8](), length=V * 4))
        f.close()

    var tok = argmax(logits)
    print("tok", tok, round(hand_ms, 1))
    var ngen = 1
    var tgen = 0.0
    var stop = ngen >= max_new
    for e in eos:
        stop = stop or tok == e
    var p = n
    while not stop:
        var ts = now_ms()
        model.forward(tok, p)
        ctx.enqueue_copy(logits.unsafe_ptr(), model.logits)
        ctx.synchronize()
        tok = argmax(logits)
        var step = now_ms() - ts
        tgen += step
        print("tok", tok, round(step, 1))
        ngen += 1
        p += 1
        stop = ngen >= max_new
        for e in eos:
            stop = stop or tok == e
    if ngen > 1:
        print("decode:", ngen - 1, "tokens,", round(tgen / Float64(ngen - 1), 1), "ms/token (" +
              String(round(Float64(ngen - 1) * 1e3 / tgen, 2)) + " tokens/s)")
    external_call["npu_close", NoneType]()
    print("done")
