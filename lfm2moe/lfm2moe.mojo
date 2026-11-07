# lfm2moe: LFM2-MoE generating text, model.mojo's forward pass through MAX's DeviceContext. Two builds:
#   the phone (LFM2.5-8B-A1B): Android, the Vulkan driver plugin (android/build.py lfm2moe)
#   the QDC laptop (LFM2.5-24B-A2B): the Mac, the remote driver plugin to the laptop's vk_server (lfm2moe/build_mac.sh),
#     with LFM2MOE_REMOTE=1 (the weight file is the laptop's)
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<plugin> lfm2moe <q4 dir> <weights.bin> <max new> @<ids file>
#     LFM2MOE_PREFILL=0      the prompt a token at a time (decode steps); by default in batches (prefill)
#     LFM2MOE_LOGITS=<file>  the logits after the prompt and after generated tokens, appended (fp32)
#     LFM2MOE_LOGITS_EVERY=k only every k-th of those (the 1st, the k+1st, ...)
#     LFM2MOE_EOS=7,124900   stop after one of these tokens
#     LFM2MOE_DUMP=<file>    batched prompt: the residual stream after the embedding and after each layer (fp32)
#     LFM2MOE_WARM=n         run the prompt and two decode steps n times untimed first
#     LFM2MOE_PROFILE=1      decode steps wait after each launch; the time per kind of launch (ms a token);
#                            =prefill the same for the prompt
#     LFM2MOE_ATTN=scalar    prefill attention with lk.attention instead of the matrix units
#     LFM2MOE_ROWS=4 / 8     decode products with that many weight rows a workgroup (mk.gemv_q4r); 1: lk's, a row
#     LFM2MOE_SCALAR=1       no cooperative matrices at all (the X1-85 has none): tiled scalar int4 products
#     LFM2MOE_REPLAY=k       remote: then time a decode step on the server's clock (the server keeps the step's
#                            requests and runs them k more times: vk_server's OP_RECORD / OP_REPLAY)
#
# Greedy decode; the argmax is the GPU's. Prints "tok <id> <ms>" per generated token and the prompt's and decode's
# times on the host's clock.
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import LFM2Moe, PMAX, plugin_path


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def print_memory():
    """The process's peak and current resident memory and swap (/proc/self/status), where there is one."""
    try:
        var status = open("/proc/self/status", "r").read()
        for line in status.split("\n"):  # (Mojo's splitlines() also breaks at the tab after each name)
            if line.startswith("VmHWM") or line.startswith("VmRSS") or line.startswith("VmSwap") or line.startswith(
                    "Rss"):
                print("mem:", String(line))
    except:
        pass
    try:  # the GPU's page allocations now, every buffer still held (bytes, system-wide), where kgsl is
        var pages = open("/sys/class/kgsl/kgsl/page_alloc", "r").read()
        print("mem: GpuPages:", String(pages.strip()))
    except:
        pass


def run_prompt(mut model: LFM2Moe, P: Int, prefill: Bool) raises:
    if prefill:
        model.prefill(0, P)
    else:
        for p in range(P):
            model.step(p, p == P - 1)


def main() raises:
    var args = argv()
    if len(args) < 5:
        raise Error("usage: lfm2moe <q4 dir> <weights.bin> <max new tokens> <prompt token ids... | @file>")
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
    var eos_list = getenv("LFM2MOE_EOS")
    if eos_list:
        for s in eos_list.split(","):
            eos.append(Int(s))
    var logits_path = getenv("LFM2MOE_LOGITS")
    var every = Int(getenv("LFM2MOE_LOGITS_EVERY", "1"))
    var prefill = getenv("LFM2MOE_PREFILL") != "0"
    var warm = Int(getenv("LFM2MOE_WARM", "0"))

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = LFM2Moe(ctx, String(args[1]), String(args[2]))
    model.attn_mma = getenv("LFM2MOE_ATTN") != "scalar"
    model.mma = getenv("LFM2MOE_SCALAR") != "1"
    model.rows_r = Int(getenv("LFM2MOE_ROWS", "1"))
    if not model.mma:
        model.tm = Int(getenv("LFM2MOE_TM", "32"))
        model.wave = getenv("LFM2MOE_WAVE") == "1"
    model.head_r = Int(getenv("LFM2MOE_HEAD_ROWS", "1"))
    model.down_f = getenv("LFM2MOE_DOWN") == "flat"
    print("weights:", round(Float64(model.bytes) / 1e9, 3), "GB in", round((now_ms() - t_load) / 1e3, 1), "s;",
          model.L, "layers, hidden", model.D, ",", model.E, "experts of", model.FE, ", context", model.CAP)
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
    model.dump = getenv("LFM2MOE_DUMP")
    model.prof = getenv("LFM2MOE_PROFILE") == "prefill"
    model.skip = "," + getenv("LFM2MOE_PSKIP") + ","  # ablation of the timed prompt (wrong output)
    var t0 = now_ms()
    run_prompt(model, P, prefill)
    model.skip = ""
    ctx.enqueue_copy(tok.unsafe_ptr(), model.ids.create_sub_buffer[DType.int32](P, 1))
    ctx.synchronize()
    var t_prompt = now_ms() - t0
    model.dump = ""
    print("prompt:", P, "tokens in", round(t_prompt, 1), "ms (", round(Float64(P) * 1000.0 / t_prompt, 1),
          "tokens/s,", "batched prefill )" if prefill else "a token at a time )")
    if model.prof:
        for e in model.times.items():
            print("profile:", e.key, round(e.value, 1), "ms (the prompt)")
    model.prof = getenv("LFM2MOE_PROFILE") == "1"
    model.times = Dict[String, Float64]()
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
        var n = gen - 1
        print("decode:", n, "steps,", round(t_dec / Float64(n), 2), "ms/token (", round(Float64(n) * 1000.0 / t_dec, 2),
              "tokens/s )")
        if model.prof:
            for e in model.times.items():
                print("profile:", e.key, round(e.value / Float64(n), 2), "ms a token")
    var replay = getenv("LFM2MOE_REPLAY")
    if replay:  # the next position's step, kept by the server and run k more times there
        var k = Int(replay)
        model.skip = "," + getenv("LFM2MOE_SKIP") + ","  # ablation: only the replayed step leaves launches out
        var lib = OwnedDLHandle(plugin_path())
        if lib.call["M_driver_remote_record", Int32](Int32(1)) != 0:
            raise Error("M_driver_remote_record failed")
        model.step(P + gen - 1)
        _ = lib.call["M_driver_remote_record", Int32](Int32(0))
        ctx.synchronize()
        var rms = lib.call["M_driver_remote_replay", Float64](Int32(k))
        if rms < 0:
            raise Error("M_driver_remote_replay failed")
        print("server clock:", k, "decode steps in", round(rms, 1), "ms (", round(rms / Float64(k), 2), "ms/token,",
              round(Float64(k) * 1e3 / rms, 1), "tokens/s ), at position", P + gen - 1)
    print_memory()
    _ = model.L  # the model lives to here: freeing its buffers inside a recording would be replayed too
