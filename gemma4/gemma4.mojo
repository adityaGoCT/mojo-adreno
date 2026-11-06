# gemma4: Gemma 4 E2B or E4B generating text on the phone's Adreno, model.mojo's forward pass through MAX's
# DeviceContext and the Vulkan driver plugin. Built for Android by android/build.py gemma4.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so gemma4 <model dir> <model.safetensors> <max new> <ids...>
#   (or @<file> for the ids: a long prompt's ids on one adb shell line can drop a remote lab's bridge)
#     GEMMA4_LOGITS=<file>    the logits after the prompt and after each generated token but the last, appended (fp32)
#     GEMMA4_LOGITS_EVERY=k   only every k-th of those (the 1st, the k+1st, ...): 1 MB a row crosses a slow bridge
#     GEMMA4_EOS=1,106        stop after one of these tokens
#     GEMMA4_PREFILL=1        the prompt in batches (Gemma4.prefill); otherwise a token at a time
#
# Greedy decode; the argmax is the GPU's. Prints "tok <id> <ms>" per generated token and the prompt's and decode's
# times on the phone's clock.
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import Gemma4


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def main() raises:
    var args = argv()
    if len(args) < 5:
        raise Error("usage: gemma4 <model dir> <model.safetensors> <max new tokens> <prompt token ids...>")
    var max_new = Int(args[3])
    var prompt = List[Int]()
    for i in range(4, len(args)):
        var a = String(args[i])
        if a.startswith("@"):
            for w in open(String(a[byte=1:]), "r").read().split():
                prompt.append(Int(w))
        else:
            prompt.append(Int(a))
    var eos = List[Int]()
    var eos_list = getenv("GEMMA4_EOS")
    if eos_list:
        for s in eos_list.split(","):
            eos.append(Int(s))
    var logits_path = getenv("GEMMA4_LOGITS")
    var every = Int(getenv("GEMMA4_LOGITS_EVERY", "1"))
    var prefill = getenv("GEMMA4_PREFILL") != ""

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = Gemma4(ctx, String(args[1]), String(args[2]))
    print("weights:", round(Float64(model.bytes) / 1e9, 3), "GB in", round((now_ms() - t_load) / 1e3, 1), "s;",
          model.L, "layers, hidden", model.D, ", context", model.CAP)
    var P = len(prompt)
    if P + max_new > model.CAP:
        raise Error("prompt + new tokens > " + String(model.CAP))

    var logits = List[Float32](length=model.V, fill=0)
    var tok = List[Int32](length=4, fill=0)
    var out = FileHandle()
    if logits_path:
        out = open(logits_path, "w")

    var t0 = now_ms()
    model.upload(0, prompt)
    if prefill:
        model.prefill(0, P)
    else:
        for p in range(P):
            model.step(p)
    ctx.enqueue_copy(tok.unsafe_ptr(), model.tok)
    ctx.synchronize()
    var t_prompt = now_ms() - t0
    print("prompt:", P, "tokens in", round(t_prompt, 1), "ms (", round(t_prompt / Float64(P), 2), "ms/token,",
          "batched prefill )" if prefill else "one token at a time )")

    var gen = 0
    var t_dec = 0.0
    var ms = t_prompt  # the time that produced the token: the prompt's, then each decode step's
    for i in range(max_new):
        if logits_path and i % every == 0:
            ctx.enqueue_copy(logits.unsafe_ptr(), model.logits)
            ctx.synchronize()
            out.write_bytes(Span(unsafe_ptr=logits.unsafe_ptr().unsafe_bitcast[UInt8](), length=model.V * 4))
        var t = Int(tok[0])
        print("tok", t, round(ms, 2))
        gen += 1
        var stop = i == max_new - 1
        for e in eos:
            if t == e:
                stop = True
        if stop:
            break
        var ts = now_ms()
        model.upload(P + i, [t])
        model.step(P + i)
        ctx.enqueue_copy(tok.unsafe_ptr(), model.tok)
        ctx.synchronize()
        ms = now_ms() - ts
        t_dec += ms
    if logits_path:
        out.close()
    if gen > 1:
        print("decode:", gen - 1, "steps,", round(t_dec / Float64(gen - 1), 2), "ms/token (",
              round(Float64(gen - 1) * 1000.0 / t_dec, 2), "tokens/s )")
