# hybrid_qwen3: ternary Qwen3-8B with its prompt prefilled on the Hexagon NPU and decoded on the Adreno. The NPU runs
# npu/export_qwen3.py's w4a16 graphs through npu_prefill.cpp (ONNX Runtime's QNN execution provider, HTP backend).
# Their K/V go into qwen3/model.mojo's KV cache ([position][8 x 128] fp32 a layer, as qk_norm_rope writes it), the
# last prompt row's logits give the first token, and decode continues with Qwen3.forward from the prompt's end,
# through MAX's DeviceContext and the Vulkan driver plugin. Built by npu/build.py hybrid_qwen3; qwen3/qwen3.mojo's
# lines ("tok <id> <ms>").
#
#   hybrid_qwen3 <model dir> <graph dir> <max new> <prompt token ids...>
#     NPU_RUNS=<k>          prefill k times (default 3): the first is cold; decode starts from the last
#     QWEN3_LOGITS=<file>   the logits after the prompt (fp32)
#
# <model dir> is the GPU's (qwen3_convert's weights.bin, with a context of at least prompt + max new); the NPU's
# embedding rows come from its 2-bit emb.w.
#
# One model at a time: the NPU's contexts (3.8 GB) and the GPU's weights (2.2 GB) do not fit together in an 11 GB
# phone's free memory, and the lab phone's adb link dropped each time they were both loaded. So the NPU prefills,
# its K/V and logits are converted into host memory, the NPU's contexts are released, and then the GPU model loads
# and takes the cache.
from std.ffi import external_call
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import Qwen3, L, V

comptime EOS = 151645
comptime EOS2 = 151643
comptime ROW = 1024  # floats of a cache position: 8 KV heads x 128


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def argmax(logits: List[Float32]) -> Int:
    var best = 0
    for i in range(1, V):
        if logits[i] > logits[best]:
            best = i
    return best


def main() raises:
    var args = argv()
    if len(args) < 5:
        raise Error("usage: hybrid_qwen3 <model dir> <graph dir> <max new tokens> <prompt token ids...>")
    var model_dir = String(args[1])
    var graph_dir = String(args[2])
    var max_new = Int(args[3])
    var prompt = List[Int32]()
    for i in range(4, len(args)):
        prompt.append(Int32(Int(args[i])))
    var n = len(prompt)
    var runs = Int(getenv("NPU_RUNS", "3"))

    var open_ms = Float64(0)
    var compiled = Int32(0)
    if external_call["npu_open", Int32](graph_dir.as_c_string_span(), model_dir.as_c_string_span(),
                                       Pointer(to=open_ms), Pointer(to=compiled)) != 0:
        raise Error("npu_open failed")
    var rows = Int(external_call["npu_rows", Int32]())
    if Int(external_call["npu_vocab", Int32]()) != V:
        raise Error("the graphs are not Qwen3's")
    print("npu: graphs loaded in", round(open_ms / 1e3, 2), "s;", rows, "rows a prefill")
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

    # the K/V of every layer, fp16 [8][rows][128], out of the NPU as fp32 [position][1024]: Qwen3's cache rows
    var stage = List[Float32](length=2 * L * n * ROW, fill=0)
    var logits = List[Float32](length=V, fill=0)
    var t_out = now_ms()
    for l in range(L):
        for w in range(2):
            external_call["npu_kv_rows", NoneType](Int32(l), Int32(w), stage.unsafe_ptr() + (2 * l + w) * n * ROW,
                                                   Int32(n))
    external_call["npu_logits", NoneType](logits.unsafe_ptr())
    var out_ms = now_ms() - t_out
    external_call["npu_close", NoneType]()  # the NPU's contexts go before the GPU's weights come

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = Qwen3(ctx, model_dir)
    print("loaded in", round((now_ms() - t_load) / 1e3, 1), "s (after the NPU's contexts were released)")
    if n + max_new > model.capacity:
        raise Error("prompt + new tokens > context " + String(model.capacity))
    var t_in = now_ms()
    for l in range(L):
        for w in range(2):
            var cache = model.vc[l] if w else model.kc[l]
            ctx.enqueue_copy(cache.create_sub_buffer[DType.float32](0, n * ROW),
                             stage.unsafe_ptr() + (2 * l + w) * n * ROW)
    ctx.synchronize()
    var hand_ms = out_ms + now_ms() - t_in
    print("handoff: K/V of", L, "layers and the logits out of the NPU in", round(out_ms, 1), "ms, into the GPU's",
          "cache in", round(hand_ms - out_ms, 1), "ms")
    print("prompt:", n, "tokens in", Int(ms + hand_ms), "ms (NPU prefill" + (" best warm " + String(Int(best)) +
          " ms" if runs > 1 else "") + ", handoff; the GPU model's load not counted)")
    var path = getenv("QWEN3_LOGITS")
    if path:
        var f = open(path, "w")
        f.write_bytes(Span(unsafe_ptr=logits.unsafe_ptr().unsafe_bitcast[UInt8](), length=V * 4))
        f.close()

    var tok = argmax(logits)
    print("tok", tok, round(hand_ms, 1))
    var ngen = 1
    var tgen = 0.0
    var p = n
    while ngen < max_new and tok != EOS and tok != EOS2:
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
    if ngen > 1:
        print("decode:", ngen - 1, "tokens,", round(tgen / Float64(ngen - 1), 1), "ms/token (" +
              String(round(Float64(ngen - 1) * 1e3 / tgen, 2)) + " tokens/s)")
    print("done")
