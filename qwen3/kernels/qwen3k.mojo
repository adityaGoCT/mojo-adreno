# Qwen3-8B decode kernels for qwen3_vk: what Qwen3 needs beyond the ternary projections, which are
# bonsai/kernels/kernels.mojo's packed_linear, packed_reduce and packed_head, unchanged. Hidden 4096,
# 32 query and 8 KV heads of 128. Projection inputs are fp16 pairs in 32-bit words (as the Hadamard
# kernel leaves them for Bonsai): the kernels that feed a projection pack their output so. The body
# of qk_norm_rope is an inline helper (_qk_norm_rope) that qwen3p.mojo's prefill row kernel shares: a
# kernel that calls another kernel does not compile for the Vulkan target.
from std.math import exp, rsqrt
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
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
    _qk_norm_rope(qkv, wq, wk, table, kc, vc, position)


@always_inline
def _qk_norm_rope(qkv: F32, wq: F32, wk: F32, table: F32, kc: F32, vc: F32, position: Int32):
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
    """Scaled q.k for positions 0 .. position, scores of head h at y[h * capacity + t]: a thread per KV head g
    and position t computes the four query heads 4g .. 4g + 3 that share g, so each cached K row is read
    once, four floats a load. Launched with 32 * capacity threads; 8 * (position + 1) work."""
    var i = global_idx.x
    var length = Int(position) + 1
    if i < 8 * length:
        var g = i // length
        var t = i % length
        var k = kc.unsafe_offset(t * 1024 + g * 128)
        var qg = q.unsafe_offset(g * 512)
        var a0 = SIMD[DType.float32, 4](0)
        var a1 = SIMD[DType.float32, 4](0)
        var a2 = SIMD[DType.float32, 4](0)
        var a3 = SIMD[DType.float32, 4](0)
        for d in range(0, 128, 4):
            var kv = k.unsafe_load[width=4](d)
            a0 += qg.unsafe_load[width=4](d) * kv
            a1 += qg.unsafe_load[width=4](128 + d) * kv
            a2 += qg.unsafe_load[width=4](256 + d) * kv
            a3 += qg.unsafe_load[width=4](384 + d) * kv
        var s = Float32(0.08838834764831845)  # 1 / sqrt(128)
        var row = y.unsafe_offset(4 * g * Int(capacity) + t)
        row[unsafe_offset=0] = a0.reduce_add() * s
        row[unsafe_offset=Int(capacity)] = a1.reduce_add() * s
        row[unsafe_offset=2 * Int(capacity)] = a2.reduce_add() * s
        row[unsafe_offset=3 * Int(capacity)] = a3.reduce_add() * s


def attn_values(scores: F32, vc: F32, y: F32, position: Int32, capacity: Int32):
    """softmax(scores) V for one query head's 64 dimensions a workgroup, two workgroups a head. The max is a
    shared-memory reduction; then the probabilities of each 64 positions are computed once, a lane a
    position, into shared memory, and every lane sums them against its dimension of V. Shared memory and
    barriers, not shuffles, after loops whose lanes diverge (see llama/kernels/attention.mojo)."""
    var sp = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var h = Int(block_idx.x) // 2
    var d = (Int(block_idx.x) % 2) * 64 + lane
    var n = Int(position) + 1
    var s = scores.unsafe_offset(h * Int(capacity))
    var highest: Float32 = -3.402823e38
    for t0 in range(0, n, 64):
        if t0 + lane < n:
            highest = max(highest, s[unsafe_offset=t0 + lane])
    sp[lane] = highest
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] = max(sp[lane], sp[lane + (32 >> stage)])
        barrier()
    highest = sp[0]
    barrier()
    var v = vc.unsafe_offset((h // 4) * 128 + d)
    var total: Float32 = 0
    var value: Float32 = 0
    for t0 in range(0, n, 64):
        sp[lane] = exp(s[unsafe_offset=t0 + lane] - highest) if t0 + lane < n else 0
        barrier()
        for k in range(min(64, n - t0)):
            var p = sp[k]
            total += p
            value += p * v[unsafe_offset=(t0 + k) * 1024]
        barrier()
    y[unsafe_offset=h * 128 + d] = value / total


def add(x: F32, y: F32, n: Int32):
    var i = global_idx.x
    if i < Int(n):
        x[unsafe_offset=i] += y[unsafe_offset=i]
