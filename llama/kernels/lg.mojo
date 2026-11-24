# Llama 3.x kernels of any size, for llama/model3.mojo. llama/kernels and kernels/prefill compile Llama 3.2 1B's shapes
# in (llama_vk.c shares them); these take the sizes as arguments, and the head dim HD and the query heads a KV head as
# parameters. The KV cache is position-major ([position][kvh HD]), as gemma4/kernels' attention reads it, and q is
# scaled by 1 / sqrt(HD) as it is rotated (those kernels' scores leave the scale out).
from std.math import sqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime EPS = Float32(1e-5)
comptime T = 256  # rmsnorm's threads


def embed(e: F16, x: F32, row: Int32, d: Int32):
    """x = row `row` of an fp16 embedding chunk (d wide)."""
    var i = global_idx.x
    if i < Int(d):
        x[i] = e[Int(row) * Int(d) + i].cast[DType.float32]()


def rmsnorm(x: F32, w: F16, y: F32, d: Int32):
    """y = x / sqrt(mean(x^2) + eps) w for row block_idx.x of x and y (rows of d), 256 threads a row; the sums in
    llama/kernels/rmsnorm.mojo's order."""
    var ss = stack_allocation[T, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var n = Int(d)
    var base = Int(block_idx.x) * n
    var acc = Float32(0)
    for i in range(t, n, T):
        var v = x[base + i]
        acc += v * v
    ss[t] = acc
    barrier()
    var s = T // 2
    while s > 0:
        if t < s:
            ss[t] = ss[t] + ss[t + s]
        barrier()
        s //= 2
    var scale = 1.0 / sqrt(ss[0] / Float32(n) + EPS)
    for i in range(t, n, T):
        y[base + i] = x[base + i] * scale * w[i].cast[DType.float32]()


def rope[HD: Int](qkv: F32, cos: F32, sin: F32, kc: F32, vc: F32, p0: Int32, h: Int32, kvh: Int32, stride: Int32,
                  scale: Float32):
    """RoPE for row block_idx.y of qkv (rows `stride` floats apart: h q heads | kvh k heads | kvh v heads of HD), at
    position p0 + row: q rotated in place and times `scale`; k rotated and, with v, stored at that position of the
    cache ([position][kvh HD]). A thread a rotated pair (grid: (h + kvh) HD / 2 threads by rows). The tables: [position]
    [HD / 2] (transformers' cos and sin, whose two halves are equal)."""
    comptime HALF = HD // 2
    var t = global_idx.x
    var nh = Int(h)
    var nkv = Int(kvh)
    if t >= (nh + nkv) * HALF:
        return
    var row = Int(block_idx.y)
    var p = Int(p0) + row
    var base = row * Int(stride)
    var isq = t < nh * HALF
    var e = t if isq else t - nh * HALF
    var hh = e // HALF
    var i = e % HALF
    var off = base + (0 if isq else nh * HD) + hh * HD + i
    var a = qkv[off]
    var b = qkv[off + HALF]
    var c = cos[p * HALF + i]
    var s = sin[p * HALF + i]
    var ra = a * c - b * s
    var rb = b * c + a * s
    if isq:
        qkv[off] = ra * scale
        qkv[off + HALF] = rb * scale
    else:
        var dst = p * nkv * HD + hh * HD + i
        kc[dst] = ra
        kc[dst + HALF] = rb
        var vo = base + (nh + nkv) * HD + hh * HD + i
        vc[dst] = qkv[vo]
        vc[dst + HALF] = qkv[vo + HALF]


def attn_scores[NQ: Int](q: F32, kc: F32, y: F32, pos: Int32, kvh: Int32, hd: Int32, capacity: Int32):
    """gemma4's g4k.attn_scores for any number of query heads a KV head (its SIMD accumulator is NQ wide, and a SIMD
    width must be a power of two: Llama 3.2 3B has 3): q . k (q already scaled) for cached positions 0 .. pos, a
    thread per KV head g and position t for its NQ query heads. Head h's scores at y[h capacity + t]."""
    comptime W = 1 if NQ == 1 else (2 if NQ == 2 else (4 if NQ <= 4 else 8))
    var i = global_idx.x
    var length = Int(pos) + 1
    var n = Int(hd)
    if i < Int(kvh) * length:
        var g = i // length
        var t = i % length
        var k = kc + (t * Int(kvh) * n + g * n)
        var qg = q + g * NQ * n
        var acc = SIMD[DType.float32, W](0)
        for d in range(0, n, 4):
            var kv = k.load[width=4](d)
            comptime for j in range(NQ):
                acc[j] += (qg.load[width=4](j * n + d) * kv).reduce_add()
        comptime for j in range(NQ):
            y[(NQ * g + j) * Int(capacity) + t] = acc[j]


def p_add(x: F32, y: F32, total: Int32):
    """x += y for the first `total` values (the residual stream)."""
    var i = global_idx.x
    if i < Int(total):
        x[i] = x[i] + y[i]
