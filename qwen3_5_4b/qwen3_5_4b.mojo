# qwen3_5_4b: Qwen3.5-4B (text) generating on the phone's Adreno, model.mojo's forward pass through MAX's DeviceContext
# and the Vulkan driver plugin. Built for Android by android/build.py qwen3_5_4b.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so qwen3_5_4b <q4 dir> <weights.bin> <max new> @<ids file>
#     QWEN35_PREFILL=1        the prompt in batches (Qwen35.prefill); otherwise a token at a time
#     QWEN35_CTX=n            positions the K/V cache holds (default 2048; at most the RoPE table's rows)
#     QWEN35_LOGITS=<file>    the logits after the prompt and after generated tokens, appended (fp32)
#     QWEN35_LOGITS_EVERY=k   only every k-th of those (the 1st, the k+1st, ...): 1 MB a row crosses a slow bridge
#     QWEN35_EOS=248046,248044  stop after one of these tokens
#     QWEN35_DUMP=<file>      with QWEN35_PREFILL: the residual stream after the embedding and after each layer (fp32)
#     QWEN35_WARM=n           run the prompt and two decode steps n times untimed first (pipelines and clocks warm up)
#     QWEN35_PROFILE=1        decode steps wait after each launch; prints the time per kind of launch (ms a token)
#     QWEN35_PROFILE=prefill  the same for the prompt
#     QWEN35_DNC=1|2|4        prefill's delta rule: value columns a 16-lane group takes (default 2)
#
# Greedy decode; the argmax is the GPU's. Prints "tok <id> <ms>" per generated token, the prompt's and decode's times on
# the phone's clock, and the process's memory (lfm2/pipette.py parses the same lines).
from std.collections import Dict
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import Qwen35


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def print_memory() raises:
    """The process's peak and current resident memory and swap (/proc/self/status): Pipette's Android peak memory."""
    var status = open("/proc/self/status", "r").read()
    for line in status.split("\n"):  # (Mojo's splitlines() also breaks at the tab after each name)
        if line.startswith("VmHWM") or line.startswith("VmRSS") or line.startswith("VmSwap") or line.startswith("Rss"):
            print("mem:", String(line))
    try:  # the GPU's page allocations now, every buffer still held (bytes, system-wide: Pipette's GPU side)
        var pages = open("/sys/class/kgsl/kgsl/page_alloc", "r").read()
        print("mem: GpuPages:", String(pages.strip()))
    except:
        pass


def run_prompt(mut model: Qwen35, P: Int, prefill: Bool) raises:
    if prefill:
        model.prefill(0, P)
    else:
        for p in range(P):
            model.step(p, p == P - 1)


def main() raises:
    var args = argv()
    if len(args) < 5:
        raise Error("usage: qwen3_5_4b <q4 dir> <weights.bin> <max new tokens> <prompt token ids... | @file>")
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
    var eos_list = getenv("QWEN35_EOS")
    if eos_list:
        for s in eos_list.split(","):
            eos.append(Int(s))
    var logits_path = getenv("QWEN35_LOGITS")
    var every = Int(getenv("QWEN35_LOGITS_EVERY", "1"))
    var prefill = getenv("QWEN35_PREFILL") != ""
    var warm = Int(getenv("QWEN35_WARM", "0"))

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = Qwen35(ctx, String(args[1]), String(args[2]), Int(getenv("QWEN35_CTX", "2048")))
    model.dnc = Int(getenv("QWEN35_DNC", "2"))
    print("weights:", round(Float64(model.bytes) / 1e9, 3), "GB in", round((now_ms() - t_load) / 1e3, 1), "s;",
          model.L, "layers, hidden", model.D, ", context", model.CAP)
    var P = len(prompt)
    if P + max_new > model.CAP:
        raise Error("prompt + new tokens > " + String(model.CAP))

    for w in range(warm):
        model.set_ids(0, prompt)
        var tw = now_ms()
        run_prompt(model, P, prefill)
        ctx.synchronize()
        print("warm-up", w, ":", round(now_ms() - tw, 1), "ms")
        if P + 2 < model.CAP:  # two decode steps too: their pipelines are built here, not in a timed step
            model.step(P)
            model.step(P + 1)
            ctx.synchronize()
        model.reset()

    var logits = List[Float32](length=model.V, fill=0)
    var tok = List[Int32](length=1, fill=0)
    var out = FileHandle()
    if logits_path:
        out = open(logits_path, "w")

    model.set_ids(0, prompt)
    model.dump = getenv("QWEN35_DUMP")
    model.prof = getenv("QWEN35_PROFILE") == "prefill"
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
    model.times = Dict[String, Float64]()
    model.prof = getenv("QWEN35_PROFILE") == "1"
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
    print_memory()
    _ = model.V  # the model (its GPU buffers) lives through that reading: Mojo frees a value after its last use
    if gen > 1:
        print("decode:", gen - 1, "steps,", round(t_dec / Float64(gen - 1), 2), "ms/token (",
              round(Float64(gen - 1) * 1000.0 / t_dec, 2), "tokens/s )")
        if model.prof:
            for e in model.times.items():
                print("profile:", e.key, round(e.value / Float64(gen - 1), 2), "ms a token")
