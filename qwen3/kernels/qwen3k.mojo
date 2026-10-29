# Qwen3-8B decode kernels for qwen3_vk: what Qwen3 needs beyond the ternary projections, which are
# bonsai/kernels/kernels.mojo's packed_linear, packed_reduce and packed_head, unchanged. Hidden 4096,
# 32 query and 8 KV heads of 128. Projection inputs are fp16 pairs in 32-bit words (as the Hadamard
# kernel leaves them for Bonsai): the kernels that feed a projection pack their output so.
from std.math import exp, rsqrt
from std.memory import bitcast
from max.gpu import global_idx, thread_idx
from max.gpu.primitives.warp import shuffle_xor

comptime F32 = Pointer[Float32, MutAnyOrigin]
comptime U32 = Pointer[UInt32, MutAnyOrigin]


@always_inline
def pack(a: Float32, b: Float32) -> UInt32:
    return bitcast[.uint32, 1](SIMD[.float32, 2](a, b).cast[.float16]())


@always_inline
def lane_sum(v: Float32) -> Float32:
    var s = v
    comptime for stage in range(6):
        s += shuffle_xor(s, UInt32(1 << stage))
    return s


def rmsnorm_pack(x: F32, w: F32, q: U32, n: Int32):
    """q = rmsnorm(x) * w as fp16 pairs; one 64-lane workgroup, each lane two elements per 128."""
    var lane = Int(thread_idx.x)
    var ss: Float32 = 0
    for j in range(0, Int(n), 128):
        var a = x[unsafe_offset=j + 2 * lane]
        var b = x[unsafe_offset=j + 2 * lane + 1]
        ss += a * a + b * b
    var r = rsqrt(lane_sum(ss) / Float32(Int(n)) + Float32(1e-6))
    for j in range(0, Int(n), 128):
        var i = j + 2 * lane
        q[unsafe_offset=i // 2] = pack(x[unsafe_offset=i] * r * w[unsafe_offset=i],
                                       x[unsafe_offset=i + 1] * r * w[unsafe_offset=i + 1])


def pack_half(x: F32, q: U32, n: Int32):
    var i = global_idx.x
    if i < Int(n) // 2:
        q[unsafe_offset=i] = pack(x[unsafe_offset=2 * i], x[unsafe_offset=2 * i + 1])


def swiglu_pack(gu: F32, q: U32, n: Int32):
    """q = silu(gate) * up as fp16 pairs; gu = gate (n) | up (n)."""
    var i = global_idx.x
    if i < Int(n) // 2:
        var g0 = gu[unsafe_offset=2 * i]
        var g1 = gu[unsafe_offset=2 * i + 1]
        var a = g0 / (1 + exp(-g0)) * gu[unsafe_offset=Int(n) + 2 * i]
        var b = g1 / (1 + exp(-g1)) * gu[unsafe_offset=Int(n) + 2 * i + 1]
        q[unsafe_offset=i] = pack(a, b)


def qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, position: Int32):
    """One 64-lane workgroup per head: q heads 0-31 (RMS norm, RoPE, in place), k heads 32-39 (RMS norm,
    RoPE, into the K cache), v heads 40-47 (into the V cache). Lane d holds d and d + 64 of the head;
    RoPE rotates those pairs (cos | sin rows of 128 per position, YaRN's factor included)."""
    var h = global_idx.x // 64
    var d = global_idx.x % 64
    var pos = Int(position)
    var base = h * 128
    var a = qkv[unsafe_offset=base + d]
    var b = qkv[unsafe_offset=base + d + 64]
    if h >= 40:
        vc[unsafe_offset=pos * 1024 + (h - 40) * 128 + d] = a
        vc[unsafe_offset=pos * 1024 + (h - 40) * 128 + d + 64] = b
        return
    var w = wq if h < 32 else wk
    var r = rsqrt(lane_sum(a * a + b * b) / 128 + Float32(1e-6))
    a *= r * w[unsafe_offset=d]
    b *= r * w[unsafe_offset=d + 64]
    var c = table[unsafe_offset=pos * 128 + d]
    var s = table[unsafe_offset=pos * 128 + 64 + d]
    var ra = a * c - b * s
    var rb = b * c + a * s
    if h < 32:
        qkv[unsafe_offset=base + d] = ra
        qkv[unsafe_offset=base + d + 64] = rb
    else:
        kc[unsafe_offset=pos * 1024 + (h - 32) * 128 + d] = ra
        kc[unsafe_offset=pos * 1024 + (h - 32) * 128 + d + 64] = rb


def attn_scores(q: F32, kc: F32, y: F32, position: Int32, capacity: Int32):
    var i = global_idx.x
    var length = Int(position) + 1
    if i < 32 * length:
        var h = i // length
        var t = i % length
        var value: Float32 = 0
        for d in range(128):
            value += q[unsafe_offset=h * 128 + d] * kc[unsafe_offset=t * 1024 + (h // 4) * 128 + d]
        y[unsafe_offset=h * Int(capacity) + t] = value * Float32(0.08838834764831845)


def attn_values(scores: F32, vc: F32, y: F32, position: Int32, capacity: Int32):
    var i = global_idx.x
    if i < 4096:
        var h = i // 128
        var d = i % 128
        var highest: Float32 = -3.402823e38
        for t in range(Int(position) + 1):
            highest = max(highest, scores[unsafe_offset=h * Int(capacity) + t])
        var total: Float32 = 0
        var value: Float32 = 0
        for t in range(Int(position) + 1):
            var p = exp(scores[unsafe_offset=h * Int(capacity) + t] - highest)
            total += p
            value += p * vc[unsafe_offset=t * 1024 + (h // 4) * 128 + d]
        y[unsafe_offset=i] = value / total


def add(x: F32, y: F32, n: Int32):
    var i = global_idx.x
    if i < Int(n):
        x[unsafe_offset=i] += y[unsafe_offset=i]
