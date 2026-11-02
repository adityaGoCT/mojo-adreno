# llama: Llama 3.2 1B decode on the phone's Adreno, llama/model.mojo's forward pass through MAX's
# DeviceContext and the Vulkan driver plugin, built for Android by android/build.py llama. It takes
# llama_vk's arguments and prints its lines, so llama/run.py --runner mojo runs and checks it.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so llama <model dir> <max new> <prompt token ids...>
#     LLAMA_EOS=128001,128009   stop tokens          LLAMA_LOGITS=<file>   logits after the prompt (fp32)
#
# The prompt runs one token at a time through the decode path, then up to <max new> tokens are
# generated greedily (argmax on the CPU). Output: "tok <id> <ms>" for each generated token.
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import Llama, MAXPOS, V


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def main() raises:
    var args = argv()
    if len(args) < 4:
        raise Error("usage: llama <model dir> <max new tokens> <prompt token ids...>")
    var max_new = Int(args[2])
    var prompt = List[Int]()
    for i in range(3, len(args)):
        prompt.append(Int(args[i]))
    if len(prompt) + max_new > MAXPOS:
        raise Error("prompt + new tokens > " + String(MAXPOS))
    var eos = List[Int]()
    var eos_list = getenv("LLAMA_EOS")
    if eos_list:
        for s in eos_list.split(","):
            eos.append(Int(s))

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = Llama(ctx, String(args[1]))
    print("loaded in", round((now_ms() - t_load) / 1e3, 1), "s")
    var logits = List[Float32](length=V, fill=0)

    var tok = prompt[0]
    var ngen = 0
    var t0 = now_ms()
    var tgen = 0.0
    for p in range(len(prompt) + max_new):
        var ts = now_ms()
        if p < len(prompt):
            tok = prompt[p]
        model.forward(tok, p)
        if p < len(prompt) - 1:
            continue  # the prompt's launches run on while the next token's are enqueued
        ctx.enqueue_copy(logits.unsafe_ptr(), model.logits)
        ctx.synchronize()
        if p == len(prompt) - 1:
            print("prompt:", len(prompt), "tokens in", Int(now_ms() - t0), "ms")
            var path = getenv("LLAMA_LOGITS")
            if path:
                var f = open(path, "w")
                f.write_bytes(Span(unsafe_ptr=logits.unsafe_ptr().unsafe_bitcast[UInt8](), length=V * 4))
                f.close()
        var best = 0
        for i in range(1, V):
            if logits[i] > logits[best]:
                best = i
        var ms = now_ms() - ts
        if p >= len(prompt):
            tgen += ms
        tok = best
        print("tok", tok, round(ms, 1))
        ngen += 1
        var stop = ngen >= max_new
        for e in eos:
            stop = stop or tok == e
        if stop:
            break
    if ngen > 1:
        print("decode:", ngen - 1, "tokens,", round(tgen / Float64(ngen - 1), 1), "ms/token (" +
              String(round(Float64(ngen - 1) * 1e3 / tgen, 2)) + " tokens/s)")
    print("done")
