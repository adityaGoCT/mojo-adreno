# Llama decode attention for one new token at position pos, grouped-query (32 heads over 8 KV heads).
# One 64-thread workgroup per head: scores for positions 0..pos go to shared memory, then a max, exp,
# sum, and each thread (one head dimension) sums p_s * v_s. The max and sum are shared-memory tree
# reductions with barriers, not warp shuffles: Vulkan does not promise that a subgroup reconverges after
# divergent control flow, and on Qualcomm's driver shuffles after the masked score loop read inactive
# lanes (or, with per-thread trip counts, hang).
from max.gpu import block_idx, thread_idx, barrier
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from std.math import exp
from std.memory import stack_allocation

comptime H = 32
comptime KVH = 8
comptime HD = 64
comptime MAXPOS = 512
comptime SCALE: Float32 = 0.125  # 1 / sqrt(HD)


def attention(qkv: UnsafePointer[Float32, MutAnyOrigin], kc: UnsafePointer[Float32, MutAnyOrigin],
              vc: UnsafePointer[Float32, MutAnyOrigin], y: UnsafePointer[Float32, MutAnyOrigin], pos: Int64):
    var sc = stack_allocation[MAXPOS, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[HD, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var n = Int(pos) + 1
    var kv = (h // (H // KVH)) * MAXPOS
    var steps = (n + HD - 1) // HD
    var m = Float32(-1e30)
    for j in range(steps):
        var s = j * HD + t
        if s < n:
            var dot = Float32(0)
            for d in range(HD):
                dot += qkv[h * HD + d] * kc[(kv + s) * HD + d]
            dot *= SCALE
            sc[s] = dot
            m = max(m, dot)
    red[t] = m
    barrier()
    var w = HD // 2
    while w > 0:
        if t < w:
            red[t] = max(red[t], red[t + w])
        barrier()
        w //= 2
    var mx = red[0]
    barrier()
    var l = Float32(0)
    for j in range(steps):
        var s = j * HD + t
        if s < n:
            var e = exp(sc[s] - mx)
            sc[s] = e
            l += e
    red[t] = l
    barrier()
    w = HD // 2
    while w > 0:
        if t < w:
            red[t] = red[t] + red[t + w]
        barrier()
        w //= 2
    var total = red[0]
    var o = Float32(0)
    for s in range(n):
        o += sc[s] * vc[(kv + s) * HD + t]
    y[h * HD + t] = o / total


def main() raises:
    var ctx = DeviceContext()
    var qkv = ctx.enqueue_create_buffer[DType.float32]((H + 2 * KVH) * HD)
    var kc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    var vc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    var o = ctx.enqueue_create_buffer[DType.float32](H * HD)
    ctx.enqueue_function[attention](qkv, kc, vc, o, Int64(3), grid_dim=H, block_dim=HD)
    ctx.synchronize()
