# Prefill attention: attention.mojo for every prompt token, causal: token t attends to positions
# 0..t of the KV cache that p_rope_kv filled. Grid heads x tokens, 64 threads; per workgroup the
# scores go to shared memory, then a max, exp, sum, and each thread (one head dimension) sums p_s * v_s,
# with shared-memory tree reductions as in attention.mojo.
from max.gpu import block_idx, thread_idx, barrier
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from std.math import exp
from std.memory import stack_allocation

comptime H = 32
comptime KVH = 8
comptime HD = 64
comptime MAXPOS = 512
comptime QKV = (H + 2 * KVH) * HD
comptime SCALE: Float32 = 0.125  # 1 / sqrt(HD)


def p_attention(qkv: UnsafePointer[Float32, MutAnyOrigin], kc: UnsafePointer[Float32, MutAnyOrigin],
                vc: UnsafePointer[Float32, MutAnyOrigin], y: UnsafePointer[Float32, MutAnyOrigin]):
    var sc = stack_allocation[MAXPOS, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[HD, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var tok = Int(block_idx.y)
    var q = tok * QKV
    var n = tok + 1
    var kv = (h // (H // KVH)) * MAXPOS
    var steps = (n + HD - 1) // HD
    var m = Float32(-1e30)
    for j in range(steps):
        var s = j * HD + t
        if s < n:
            var dot = Float32(0)
            for d in range(HD):
                dot += qkv[q + h * HD + d] * kc[(kv + s) * HD + d]
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
    y[tok * H * HD + h * HD + t] = o / total


def main() raises:
    var ctx = DeviceContext()
    var qkv = ctx.enqueue_create_buffer[DType.float32](4 * QKV)
    var kc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    var vc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    var o = ctx.enqueue_create_buffer[DType.float32](4 * H * HD)
    ctx.enqueue_function[p_attention](qkv, kc, vc, o, grid_dim=(H, 4), block_dim=HD)
    ctx.synchronize()
