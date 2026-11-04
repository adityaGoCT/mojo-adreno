# qwen3: ternary Qwen3-8B decode on the phone's Adreno, qwen3/model.mojo's forward pass through MAX's
# DeviceContext and the Vulkan driver plugin, built for Android by android/build.py qwen3. It takes
# qwen3_vk's arguments and prints its lines.
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so qwen3 <model dir> <max new> <prompt token ids...>
#     QWEN3_REF=<reference.f32>  compare all logits after the prompt and after each token with the
#                                exporter's MLX reference; runs max_new steps even past the stop tokens
#     QWEN3_PREFILL=<anything>   the whole prompt at once (Qwen3.prefill: the projections and attention on
#                                cooperative matrices); otherwise one token at a time through the decode path
#
# Then up to <max new> tokens greedily (argmax on the CPU) until <|im_end|> or <|endoftext|>. Output:
# "tok <id> <ms>" lines.
from std.math import sqrt
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceContext

from model import Qwen3, V

comptime EOS = 151645
comptime EOS2 = 151643


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def main() raises:
    var args = argv()
    if len(args) < 4:
        raise Error("usage: qwen3 <model dir> <max new tokens> <prompt token ids...>")
    var max_new = Int(args[2])
    var prompt = List[Int]()
    for i in range(3, len(args)):
        prompt.append(Int(args[i]))

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t_load = now_ms()
    var model = Qwen3(ctx, String(args[1]))
    print("loaded in", round((now_ms() - t_load) / 1e3, 1), "s")
    if len(prompt) + max_new > model.capacity:
        raise Error("prompt + new tokens > context " + String(model.capacity))
    var ref_path = getenv("QWEN3_REF")
    var reference = open(ref_path, "r") if ref_path else open("/dev/null", "r")
    var logits = List[Float32](length=V, fill=0)

    var prefill = getenv("QWEN3_PREFILL") != ""
    for t in prompt:
        if t < 0 or t >= V:
            raise Error("token " + String(t) + " out of range")
    var tok = 0
    var ngen = 0
    var failed = False
    var worst = 0.0
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
        ctx.enqueue_copy(logits.unsafe_ptr(), model.logits)
        ctx.synchronize()
        if p < len(prompt) - 1:
            continue
        var next = 0
        for i in range(1, V):
            if logits[i] > logits[next]:
                next = i
        var ms = now_ms() - ts
        if p == len(prompt) - 1:
            print("prompt:", len(prompt), "tokens in", Int(now_ms() - t0), "ms",
                  "(batched prefill)" if prefill else "(one token at a time)")
        else:
            tgen += ms
        if ref_path:
            var expect = reference.read_bytes(V * 4)
            if len(expect) != V * 4:
                raise Error("reference has only " + String(ngen) + " steps")
            var e = expect.unsafe_ptr().unsafe_bitcast[Float32]()
            var maxerr = 0.0
            var d2 = 0.0
            var r2 = 0.0
            var rbest = 0
            for i in range(V):
                var err = abs(Float64(logits[i]) - Float64(e[i]))
                maxerr = max(maxerr, err)
                d2 += err * err
                r2 += Float64(e[i]) * Float64(e[i])
                if e[i] > e[rbest]:
                    rbest = i
            failed = failed or next != rbest
            worst = max(worst, maxerr)
            print("check", ngen, ": token", next, "reference", rbest, " max abs", round(maxerr, 6), " rel L2",
                  round(sqrt(d2 / r2), 8), "OK" if next == rbest else "MISMATCH")
        tok = next
        print("tok", tok, round(ms, 1))
        ngen += 1
        if ngen >= max_new or (not ref_path and (tok == EOS or tok == EOS2)):
            break
    if ngen > 1:
        print("decode:", ngen - 1, "tokens,", round(tgen / Float64(ngen - 1), 1), "ms/token (" +
              String(round(Float64(ngen - 1) * 1e3 / tgen, 2)) + " tokens/s)")
    if ref_path:
        print("validation:", ngen, "steps, max abs logit error", round(worst, 6), ",",
              "FAILED" if failed else "all greedy ids match")
    print("done")
