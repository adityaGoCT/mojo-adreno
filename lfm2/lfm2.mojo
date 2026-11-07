# lfm2: LFM2.5-2.6B generating text on the phone's Adreno, model.mojo's forward pass through MAX's DeviceContext and
# the Vulkan driver plugin. Built for Android by android/build.py lfm2.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so lfm2 <storage dir> <weights.bin> <max new> @<ids file>
#     LFM2_PREFILL=1        the prompt in batches (LFM2.prefill); otherwise a token at a time
#     LFM2_LOGITS=<file>    the logits after the prompt and after generated tokens, appended (fp32)
#     LFM2_LOGITS_EVERY=k   only every k-th of those (the 1st, the k+1st, ...): 0.5 MB a row crosses a slow bridge
#     LFM2_EOS=7,124900     stop after one of these tokens
#     LFM2_DUMP=<file>      with LFM2_PREFILL: the residual stream after the embedding and after each layer (fp32)
#     LFM2_WARM=n           run the prompt and two decode steps n times untimed first (pipelines and clocks warm up)
#     LFM2_PROFILE=1        decode steps wait after each launch; prints the time per kind of launch (ms a token)
#     LFM2_PROFILE=prefill  the same for the prompt
#     LFM2_ATTN=scalar      prefill attention with lk.attention instead of the matrix units (gemma4's g4k kernels)
#     LFM2_GEMV=word        int4 decode with a word (8 weights) a lane a step instead of a block of 32 (dot_q4b)
#     LFM2_DSPARK=<dir>     speculative decoding with the DSpark drafter (its manifest.txt and model.safetensors): each
#                           step drafts up to 9 tokens and the target checks them in one pass (dspark.mojo); the
#                           prompt is prefilled in batches with the drafter's taps. LFM2_DSPARK_LOG=1: a line a step.
#                           LFM2_DSPARK_DRAFTS=n (default 7, at most 9): drafts checked a step. LFM2_HEAD8=0: the
#                           few-row heads read the Q6_K head instead of its int8 copy (model.build_head8).
#
# Greedy decode; the argmax is the GPU's. Prints "tok <id> <ms>" per generated token and the prompt's and decode's
# times on the phone's clock.
from std.collections import Dict
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from dspark import DSpark, GAMMA
from model import LFM2, PMAX


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


def run_prompt(mut model: LFM2, P: Int, prefill: Bool) raises:
    if prefill:
        model.prefill(0, P)
    else:
        for p in range(P):
            model.step(p, p == P - 1)


def speculate(mut model: LFM2, ctx: DeviceContext, dir: String, prompt: List[Int], max_new: Int, eos: List[Int],
              warm: Int) raises:
    """Greedy generation with the DSpark drafter: the same tokens as step() by step(), fewer target passes."""
    var t_load = now_ms()
    var drafter = DSpark(ctx, dir, model.CAP, model.V)
    print("drafter:", round(Float64(drafter.bytes) / 1e9, 3), "GB (bf16) in", round((now_ms() - t_load) / 1e3, 1), "s")
    var P = len(prompt)
    var log = getenv("LFM2_DSPARK_LOG") != ""
    var nd = min(GAMMA, Int(getenv("LFM2_DSPARK_DRAFTS", "7")))  # drafts checked a step
    model.tap_on = True
    if getenv("LFM2_HEAD8", "1") != "0":
        model.build_head8()
    var prof = getenv("LFM2_PROFILE") == "verify"
    var host = List[Int32](length=32, fill=0)
    for run in range(warm + 1):
        var limit = max_new if run == warm else min(max_new, 24)
        model.reset()
        drafter.nctx = 0
        model.set_ids(0, prompt)
        var t0 = now_ms()
        var c0 = 0
        while c0 < P:  # batches with the taps; the drafter's context after each
            var c = min(PMAX, P - c0)
            model.prefill_batch(c0, c, c0 + c == P)
            drafter.add_context(model, c0, c)
            c0 += c
        ctx.enqueue_copy(host.unsafe_ptr(), model.ids.create_sub_buffer[DType.int32](P, 1))
        ctx.synchronize()
        var t_prompt = now_ms() - t0
        var toks = List[Int]()
        toks.append(Int(host[0]))
        var pos = P  # the anchor's position: ids[pos] is the newest token, not yet through the target
        var steps = 0
        var accepted_total = 0
        var t_dec0 = now_ms()
        var done = False
        for e in eos:
            if toks[0] == e:
                done = True
        var t_draft = 0.0
        var t_verify = 0.0
        model.prof = prof and run == warm
        model.times = Dict[String, Float64]()
        while not done and len(toks) < limit:
            var ts = now_ms()
            if model.prof:
                ctx.synchronize()
                model.mark = now_ms()
            drafter.draft(model, pos, nd)
            if log:
                ctx.synchronize()
                t_draft += now_ms() - ts
                ts = now_ms()
            model.verify(pos, nd + 1)
            if log:
                ctx.synchronize()
                t_verify += now_ms() - ts
            ctx.enqueue_copy(host.unsafe_ptr(), model.ids.create_sub_buffer[DType.int32](pos + 1, nd))
            ctx.enqueue_copy(host.unsafe_ptr() + 16, model.vt.create_sub_buffer[DType.int32](0, nd + 1))
            ctx.synchronize()
            var a = 0
            while a < nd and host[a] == host[16 + a]:
                a += 1
            var bonus = host[16 + a]
            var fix = List[Int32](length=1, fill=bonus)
            ctx.enqueue_copy(model.ids.create_sub_buffer[DType.int32](pos + a + 1, 1), fix.unsafe_ptr())
            model.commit(pos, a)
            drafter.add_context(model, pos, a + 1)
            steps += 1
            accepted_total += a
            if log:
                print("spec: pos", pos, "accepted", a, "of", nd)
            for j in range(a + 1):
                var t = Int(host[j]) if j < a else Int(bonus)
                toks.append(t)
                for e in eos:
                    if t == e:
                        done = True
                if done or len(toks) >= limit:
                    break
            pos += a + 1
        ctx.synchronize()
        var t_dec = now_ms() - t_dec0
        if run < warm:
            print("warm-up", run, ":", len(toks), "tokens")
            continue
        print("prompt:", P, "tokens in", round(t_prompt, 1), "ms (", round(Float64(P) * 1000.0 / t_prompt, 1),
              "tokens/s, batched prefill + the drafter's context )")
        for t in toks:
            print("tok", t, 0)
        if len(toks) > 1:
            var n = len(toks) - 1
            print("decode:", n, "steps,", round(t_dec / Float64(n), 2), "ms/token (", round(Float64(n) * 1000.0 / t_dec,
                  2), "tokens/s )")
            print("speculative:", steps, "target passes for", n, "tokens:", round(Float64(n) / Float64(steps), 2),
                  "tokens a pass; mean accepted drafts", round(Float64(accepted_total) / Float64(steps), 2))
            if model.prof:
                for e in model.times.items():
                    print("profile:", e.key, round(e.value / Float64(steps), 2), "ms a step")
            if log:
                print("per step: draft", round(t_draft / Float64(steps), 1), "ms, verify", round(t_verify / Float64(steps),
                      1), "ms, the rest", round((t_dec - t_draft - t_verify) / Float64(steps), 1), "ms")


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
    model.attn_mma = getenv("LFM2_ATTN") != "scalar"
    print("weights:", round(Float64(model.bytes) / 1e9, 3), "GB in", round((now_ms() - t_load) / 1e3, 1), "s;",
          model.L, "layers, hidden", model.D, ", storage", "q4" if model.q4 else "f16", ", context", model.CAP)
    var P = len(prompt)
    if P + max_new > model.CAP:
        raise Error("prompt + new tokens > " + String(model.CAP))

    var ds = getenv("LFM2_DSPARK")
    if ds:
        speculate(model, ctx, ds, prompt, max_new, eos, warm)
        return
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
    print_memory()
    _ = model.V  # the model (its GPU buffers) lives through that reading: Mojo frees a value after its last use
    if gen > 1:
        print("decode:", gen - 1, "steps,", round(t_dec / Float64(gen - 1), 2), "ms/token (",
              round(Float64(gen - 1) * 1000.0 / t_dec, 2), "tokens/s )")
        if model.prof:
            for e in model.times.items():
                print("profile:", e.key, round(e.value / Float64(gen - 1), 2), "ms a token")
