# llama3: Llama 3.x of any size (Llama 3.2 3B here) on the phone's Adreno, llama/model3.mojo's forward pass through MAX's
# DeviceContext and the Vulkan driver plugin, built for Android by android/build.py llama3 and run by llama/run3.py.
# llama.mojo's arguments and lines, with the sizes from the manifest.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so llama3 <model dir> <max new> <prompt ids... | @file>
#     LLAMA_EOS=128001,128009   stop tokens          LLAMA_LOGITS=<file>   logits after the prompt (fp32)
#     LLAMA_PREFILL=<anything>  the whole prompt at once (Llama3.prefill); otherwise a token at a time
#     LLAMA_GEMM=q              the prefill's products on fp16 cooperative matrices (lfm2/kernels/lkh.mojo)
#     LLAMA_GEMM=k              the same with the Adreno 850's layouts (lkh.gemm_k: B K-minor, one K chunk), the
#                               int4 weights repacked into panels and dequantized in registers (LLAMA_REG=0: B
#                               through shared memory instead), flash attention, fused epilogues (model3.layer_k)
#     LLAMA_PROFILE=1           the prompt waits after each kind of launch: its time per kind
#     LLAMA_SYNTH=1             no weights.bin: synthetic weights filled on the GPU (timing only; the output is noise)
#     LLAMA_FUSE=0              LLAMA_GEMM=q without the fused glue (each projection packed, multiplied, summed alone)
#     LLAMA_NORM=row            the fused path's norms a row a workgroup (lg.rmsnorm_pack) instead of tiled
#     LLAMA_CH=2048             the fused path's products in K chunks of 2048 instead of 1024 (faster, less accurate)
#     LLAMA_QKV=0|21|22|42      LLAMA_GEMM=k: q|k|v without the RoPE epilogue (0), or its tiling (subgroups WM WN)
#     LLAMA_PREFILL_REPS=<r>    before the run: a warm-up prefill, then r timed prefills (and the best of them)
#
# Then up to <max new> tokens are generated greedily (argmax on the CPU). Output: "tok <id> <ms>" for each.
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model3 import Llama3


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def main() raises:
    var args = argv()
    if len(args) < 4:
        raise Error("usage: llama3 <model dir> <max new tokens> <prompt token ids... | @file>")
    var max_new = Int(args[2])
    var prompt = List[Int]()
    if String(args[3]).startswith("@"):  # a long prompt's ids on one adb shell line can drop a remote lab's bridge
        for s in open(String(args[3])[byte=1:], "r").read().split():
            prompt.append(Int(s))
    else:
        for i in range(3, len(args)):
            prompt.append(Int(args[i]))
    var eos = List[Int]()
    var eos_list = getenv("LLAMA_EOS")
    if eos_list:
        for s in eos_list.split(","):
            eos.append(Int(s))

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = Llama3(ctx, String(args[1]), gemmq=getenv("LLAMA_GEMM") == "q" or getenv("LLAMA_GEMM") == "k", synth=getenv("LLAMA_SYNTH") == "1")
    model.prof = getenv("LLAMA_PROFILE") == "1"
    model.fuse = getenv("LLAMA_FUSE") != "0"
    model.norm_tiled = getenv("LLAMA_NORM") != "row"
    model.ch2 = getenv("LLAMA_CH") == "2048"
    model.k850 = getenv("LLAMA_GEMM") == "k"
    model.qkvt = Int(getenv("LLAMA_QKV", "22"))
    if model.k850 and getenv("LLAMA_REG") != "0":
        var t_pan = now_ms()
        model.make_panels()
        print("panels in", Int(now_ms() - t_pan), "ms")
    print("loaded in", round((now_ms() - t_load) / 1e3, 1), "s")
    if len(prompt) + max_new > model.CAP:
        raise Error("prompt + new tokens > " + String(model.CAP))
    var V = model.V
    var logits = List[Float32](length=V, fill=0)

    var prefill = getenv("LLAMA_PREFILL") != ""
    var preps = Int(getenv("LLAMA_PREFILL_REPS", "0"))
    if prefill and preps > 0:  # a warm-up (pipelines are created at their first launch), then preps timed prefills
        model.prefill(prompt)
        ctx.synchronize()
        var best = 1e30
        for r in range(preps):
            var tr = now_ms()
            model.prefill(prompt)
            ctx.enqueue_copy(logits.unsafe_ptr(), model.logits)
            ctx.synchronize()
            var ms = now_ms() - tr
            best = min(best, ms)
            print("prefill run", r, ":", round(ms, 1), "ms")
        print("prefill best of", preps, ":", round(best, 1), "ms,", round(Float64(len(prompt)) * 1e3 / best, 1),
              "tokens/s")
    var tok = prompt[0]
    var ngen = 0
    var t0 = now_ms()
    var tgen = 0.0
    for p in range(len(prompt) - 1 if prefill else 0, len(prompt) + max_new):
        var ts = now_ms()
        if prefill and p == len(prompt) - 1:
            model.prefill(prompt)
        else:
            if p < len(prompt):
                tok = prompt[p]
            model.forward(tok, p)
        if p < len(prompt) - 1:
            continue  # the prompt's launches run on while the next token's are enqueued
        ctx.enqueue_copy(logits.unsafe_ptr(), model.logits)
        ctx.synchronize()
        if p == len(prompt) - 1:
            print("prompt:", len(prompt), "tokens in", Int(now_ms() - t0), "ms",
                  "(batched prefill)" if prefill else "(one token at a time)")
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
