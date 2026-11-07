# lfm2: LFM2.5-2.6B generating text on the phone's Adreno, model.mojo's forward pass through MAX's DeviceContext and
# the Vulkan driver plugin. Built for Android by android/build.py lfm2.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so lfm2 <storage dir> <weights.bin> <max new> @<ids file>
#     LFM2_PREFILL=1        the prompt in batches (LFM2.prefill); otherwise a token at a time
#     LFM2_LOGITS=<file>    the logits after the prompt and after generated tokens, appended (fp32)
#     LFM2_LOGITS_EVERY=k   only every k-th of those (the 1st, the k+1st, ...): 0.5 MB a row crosses a slow bridge
#     LFM2_EOS=7,124900     stop after one of these tokens
#     LFM2_DUMP=<file>      with LFM2_PREFILL: the residual stream after the embedding and after each layer (fp32)
#     LFM2_WARM=n           run the prompt n times untimed first (the pipelines and clocks warm up)
#     LFM2_PROFILE=1        decode steps wait after each launch; prints the time per kind of launch (ms a token)
#     LFM2_PROFILE=prefill  the same for the prompt
#     LFM2_GEMV=word        int4 decode with a word (8 weights) a lane a step instead of a block of 32 (dot_q4b)
#
# Greedy decode; the argmax is the GPU's. Prints "tok <id> <ms>" per generated token and the prompt's and decode's
# times on the phone's clock.
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import LFM2


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def run_prompt(mut model: LFM2, P: Int, prefill: Bool) raises:
    if prefill:
        model.prefill(0, P)
    else:
        for p in range(P):
            model.step(p, p == P - 1)


def main() raises:
    var args = argv()
    if len(args) < 5:
        raise Error("usage: lfm2 <storage dir> <weights.bin> <max new tokens> <prompt token ids... | @file>")
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
    var eos_list = getenv("LFM2_EOS")
    if eos_list:
        for s in eos_list.split(","):
            eos.append(Int(s))
    var logits_path = getenv("LFM2_LOGITS")
    var every = Int(getenv("LFM2_LOGITS_EVERY", "1"))
    var prefill = getenv("LFM2_PREFILL") != ""
    var warm = Int(getenv("LFM2_WARM", "0"))

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = LFM2(ctx, String(args[1]), String(args[2]))
    model.wide = getenv("LFM2_GEMV") != "word"
    print("weights:", round(Float64(model.bytes) / 1e9, 3), "GB in", round((now_ms() - t_load) / 1e3, 1), "s;",
          model.L, "layers, hidden", model.D, ", storage", "q4" if model.q4 else "f16", ", context", model.CAP)
    var P = len(prompt)
    if P + max_new > model.CAP:
        raise Error("prompt + new tokens > " + String(model.CAP))

    for w in range(warm):
        model.set_ids(0, prompt)
        var tw = now_ms()
        run_prompt(model, P, prefill)
        ctx.synchronize()
        print("warm-up", w, ":", round(now_ms() - tw, 1), "ms")
        model.reset()

    var logits = List[Float32](length=model.V, fill=0)
    var tok = List[Int32](length=1, fill=0)
    var out = FileHandle()
    if logits_path:
        out = open(logits_path, "w")

    model.set_ids(0, prompt)
    model.dump = getenv("LFM2_DUMP")
    model.prof = getenv("LFM2_PROFILE") == "prefill"
    var t0 = now_ms()
    run_prompt(model, P, prefill)
    ctx.enqueue_copy(tok.unsafe_ptr(), model.ids.create_sub_buffer[DType.int32](P, 1))
    ctx.synchronize()
    var t_prompt = now_ms() - t0
    model.dump = ""
    print("prompt:", P, "tokens in", round(t_prompt, 1), "ms (", round(Float64(P) * 1000.0 / t_prompt, 1),
          "tokens/s,", "batched prefill )" if prefill else "a token at a time )")

    if model.prof:
        for e in model.times.items():
            print("profile:", e.key, round(e.value, 1), "ms (the prompt)")
    model.prof = getenv("LFM2_PROFILE") == "1"
    var gen = 0
    var t_dec = 0.0
    var ms = t_prompt
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
        model.step(P + i)
        ctx.enqueue_copy(tok.unsafe_ptr(), model.ids.create_sub_buffer[DType.int32](P + i + 1, 1))
        ctx.synchronize()
        ms = now_ms() - ts
        t_dec += ms
    if logits_path:
        out.close()
    if gen > 1:
        print("decode:", gen - 1, "steps,", round(t_dec / Float64(gen - 1), 2), "ms/token (",
              round(Float64(gen - 1) * 1000.0 / t_dec, 2), "tokens/s )")
        if model.prof:
            for e in model.times.items():
                print("profile:", e.key, round(e.value / Float64(gen - 1), 2), "ms a token")
