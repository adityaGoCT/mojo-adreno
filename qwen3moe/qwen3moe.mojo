# qwen3moe: Qwen3-30B-A3B (int4, 16.7 GB) generating greedily on a remote GPU, qwen3moe/model.mojo's decode through
# MAX's DeviceContext and the remote driver plugin; the weights are read by the executor from qwen3moe.bin on its own
# side (the X2 Elite laptop). Built by qwen3moe/build_mac.sh; run by qwen3moe/run.py, which tokenizes and checks.
#
#   VK_REMOTE_PORT=<port> MODULAR_DRIVER_PLUGINS=vulkan@<libM_driver_vulkan_remote.dylib> \
#     qwen3moe <manifest.txt> <qwen3moe.bin on the executor's side> <new tokens> <prompt token ids...>
#   QWEN3MOE_LOGITS=<file>   each generated position's logits (fp32 [new tokens][151936]) to a file
#   QWEN3MOE_SYNC=1          synchronize after every token (its time, with the transport's round trip)
#   QWEN3MOE_PREFILL=0 / 1   the prompt a token at a time (decode steps) / in batches of up to 256 tokens; by
#                            default batches from 32 tokens on (shorter prompts leave most of the GPU idle)
#   QWEN3MOE_REPLAY=<k>      then time a decode step on the server's own clock: the server keeps the step's requests
#                            and runs them k more times (vla/x2's vk_server: OP_RECORD / OP_REPLAY), so the launches
#                            do not stream through the transport
from std.os import getenv
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext

from model import CAP, PMAX, V, Qwen3Moe


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def main() raises:
    var args = argv()
    if len(args) < 5:
        raise Error("usage: qwen3moe <manifest.txt> <qwen3moe.bin path on the executor> <new tokens> <prompt ids...>")
    var manifest = String(args[1])
    var weights = String(args[2])
    var new = Int(args[3])
    var prompt = List[Int32]()
    for i in range(4, len(args)):
        prompt.append(Int32(Int(args[i])))
    var n = len(prompt)
    if n + new > CAP:
        raise Error("prompt + new tokens > " + String(CAP))
    var logits_path = getenv("QWEN3MOE_LOGITS")
    var per_token = getenv("QWEN3MOE_SYNC") != ""

    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var t0 = now_ms()
    var model = Qwen3Moe(ctx, manifest, weights)
    print("weights:", len(model.words) + len(model.halves) + len(model.floats), "tensors,",
          round(Float64(model.bytes) / 1e9, 2), "GB read on the device's side in", round((now_ms() - t0) / 1e3, 1), "s")

    var keep = ctx.enqueue_create_buffer[DType.float32](max(new, 1) * V) if logits_path else ctx.enqueue_create_buffer[
        DType.float32](1)
    model.set_prompt(prompt)
    ctx.synchronize()
    var t1 = now_ms()
    var mode = getenv("QWEN3MOE_PREFILL")
    if mode == "0" or (mode != "1" and n < 32):
        for p in range(n):  # the prompt, a token at a time; the last one's argmax is the first new token
            model.step(p, p == n - 1)
    else:
        for c0 in range(0, n, PMAX):  # in batches: each expert's weights read once a batch
            var cnt = min(PMAX, n - c0)
            model.prefill(c0, cnt, c0 + cnt == n)
    if logits_path:
        ctx.enqueue_copy(keep.create_sub_buffer[DType.float32](0, V), model.logits)
    ctx.synchronize()
    var t2 = now_ms()
    print("prompt:", n, "tokens in", round(t2 - t1, 1), "ms (", round((t2 - t1) / Float64(n), 1), "ms/token )")
    for k in range(1, new):
        var ts = now_ms()
        model.step(n + k - 1, True)
        if logits_path:
            ctx.enqueue_copy(keep.create_sub_buffer[DType.float32](k * V, V), model.logits)
        if per_token:
            ctx.synchronize()
            print("token", k, round(now_ms() - ts, 1), "ms")
    ctx.synchronize()
    var t3 = now_ms()
    if new > 1:
        print("decode:", new - 1, "tokens in", round(t3 - t2, 1), "ms (", round((t3 - t2) / Float64(new - 1), 1),
              "ms/token,", round(Float64(new - 1) * 1e3 / (t3 - t2), 2), "tokens/s )")
    var replay = getenv("QWEN3MOE_REPLAY")
    if replay:  # the last position's step again, kept by the server and run k more times there
        var k = Int(replay)
        if model.lib.call["M_driver_remote_record", Int32](Int32(1)) != 0:
            raise Error("M_driver_remote_record failed")
        model.step(n + new - 1, False)
        _ = model.lib.call["M_driver_remote_record", Int32](Int32(0))
        ctx.synchronize()
        var ms = model.lib.call["M_driver_remote_replay", Float64](Int32(k))
        if ms < 0:
            raise Error("M_driver_remote_replay failed")
        print("server clock:", k, "decode steps in", round(ms, 1), "ms (", round(ms / Float64(k), 2), "ms/token,",
              round(Float64(k) * 1e3 / ms, 1), "tokens/s ), at position", n + new - 1)
    var toks = List[Int32](length=CAP + 1, fill=0)
    ctx.enqueue_copy(toks.unsafe_ptr(), model.tokens)
    ctx.synchronize()
    var line = String("ids:")
    for i in range(n, n + new):
        line += " " + String(toks[i])
    print(line)
    if logits_path:
        var host = List[Float32](length=new * V, fill=0)
        ctx.enqueue_copy(host.unsafe_ptr(), keep)
        ctx.synchronize()
        var f = open(logits_path, "w")
        f.write_bytes(Span(unsafe_ptr=host.unsafe_ptr().unsafe_bitcast[UInt8](), length=new * V * 4))
        f.close()
    print("done")
