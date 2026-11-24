# Llama 3.x kernels of any size, for llama/model3.mojo. llama/kernels and kernels/prefill compile Llama 3.2 1B's shapes
# in (llama_vk.c shares them); these take the sizes as arguments, and the head dim HD and the query heads a KV head as
# parameters. The KV cache is position-major ([position][kvh HD]), as gemma4/kernels' attention reads it, and q is
# scaled by 1 / sqrt(HD) as it is rotated (those kernels' scores leave the scale out).
from std.math import exp, sqrt
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
comptime EPS = Float32(1e-5)
comptime T = 256  # rmsnorm's threads


def fill(b: U32, n: Int32, seed: UInt32, mask: UInt32, bits: UInt32):
    """b[i] = (a hash of i and seed) & mask | bits, for i < n: synthetic weights for timing (llama3's LLAMA_SYNTH)."""
    var i = global_idx.x
    if i < Int(n):
        var x = UInt32(i) * 2654435761 ^ seed
        x ^= x >> 16
        x *= 0x7FEB352D
        x ^= x >> 15
        x *= 0x846CA68B
        x ^= x >> 16
        b[i] = (x & mask) | bits


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


def rmsnorm_pack(x: F32, w: F16, xa: U32, d: Int32):
    """rmsnorm's y for row block_idx.x, written as fp16 straight into lkh.pack_x's R tiles (xa as pairs of halves), the
    X of the projection that follows: no fp32 copy and no separate pack_x. 256 threads a row, 8 values a thread a
    step (d: a multiple of 16)."""
    var ss = stack_allocation[T, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var n = Int(d)
    var r = Int(block_idx.x)
    var base = r * n
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
    for c in range(8 * t, n, 8 * T):
        var y = x.load[width=8](base + c) * scale * w.load[width=8](c).cast[DType.float32]()
        var at = ((r // 64) * (n // 16) + c // 16) * 1024 + (r % 64) * 16 + c % 16
        xa.store(at // 2, bitcast[DType.uint32, 4](y.cast[DType.float16]()))


def norm_scale(x: F32, sc: F32, d: Int32):
    """sc[row] = 1 / sqrt(mean(x^2) + eps) for row block_idx.x (rmsnorm's sums, in its order); 256 threads a row."""
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
    if t == 0:
        sc[Int(block_idx.x)] = 1.0 / sqrt(ss[0] / Float32(n) + EPS)


def norm_pack_t(x: F32, w: F16, sc: F32, xa: U32, d: Int32):
    """rmsnorm_pack, tiled: x sc[row] w for a 64 x 64 block (grid (d / 64, rows / 64), 256 threads), staged in shared
    memory and written as whole R tiles (lkh.pack_t's pattern)."""
    var sb = stack_allocation[2048, DType.uint32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var n = Int(d)
    var cb = Int(block_idx.x)
    var rb = Int(block_idx.y)
    comptime for half in range(2):
        var r = t // 8 + 32 * half
        var c = (t % 8) * 8
        var y = x.load[width=8]((64 * rb + r) * n + 64 * cb + c) * sc[64 * rb + r] * w.load[width=8](
            64 * cb + c).cast[DType.float32]()
        var v = bitcast[DType.uint32, 4](y.cast[DType.float16]())
        comptime for e in range(4):
            sb[r * 32 + c // 2 + e] = v[e]
    barrier()
    var dst = xa + ((rb * (n // 16) + cb * 4) * 1024) // 2
    comptime for j in range(8):
        var q = t + 256 * j
        dst[q] = sb[(q % 512) // 8 * 32 + (q // 512) * 8 + q % 8]


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


def rope_pack[HD: Int](qkv: F32, cos: F32, sin: F32, kc: F32, vc: F32, qp: F32, h: Int32, kvh: Int32,
                       stride: Int32, rows: Int32, scale: Float32):
    """rope for the prompt (positions 0 .., row = position), also writing q (scaled) as p_scores_packed's fp32 A tiles,
    [head][rows / 64][HD / 8][64][8] (each 64 x 8 tile contiguous). K and V go into the cache, as rope's.
    (Writing k transposed too, for B tiles of contiguous keys, cost more in scattered 4-byte stores than it saved.)"""
    comptime HALF = HD // 2
    var t = global_idx.x
    var nh = Int(h)
    var nkv = Int(kvh)
    if t >= (nh + nkv) * HALF:
        return
    var row = Int(block_idx.y)
    var base = row * Int(stride)
    var isq = t < nh * HALF
    var e = t if isq else t - nh * HALF
    var hh = e // HALF
    var i = e % HALF
    var off = base + (0 if isq else nh * HD) + hh * HD + i
    var a = qkv[off]
    var b = qkv[off + HALF]
    var c = cos[row * HALF + i]
    var s = sin[row * HALF + i]
    var ra = a * c - b * s
    var rb = b * c + a * s
    var nr = Int(rows)
    if isq:
        ra *= scale
        rb *= scale
        qkv[off] = ra
        qkv[off + HALF] = rb
        var tile = (hh * (nr // 64) + row // 64) * (HD // 8)
        qp[((tile + i // 8) * 64 + row % 64) * 8 + i % 8] = ra
        qp[((tile + (i + HALF) // 8) * 64 + row % 64) * 8 + (i + HALF) % 8] = rb
    else:
        var dst = row * nkv * HD + hh * HD + i
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


# ---- the prompt's attention on the matrix units, Llama's case (no window, positions from 0) -------------------------
# gemma4's p_scores_mma / p_softmax / p_values_mma with three changes. The scores are [head][row][key] (rows `capacity`
# apart, where gemma4's are [row][head][key], heads x capacity apart), so P V reads its A tiles 2 KB apart instead of
# 48 KB. A score workgroup computes one 64 x 64 tile (grid: row blocks x heads x key blocks, the blocks above the
# diagonal exiting at once), not a row block's every key block in turn: 8x the workgroups. And q comes as contiguous
# 64 x 8 A tiles, which rope_pack writes as it rotates it.


def p_scores_packed[HD: Int](qp: F32, kc: F32, y: F32, nq: Int32, kvh: Int32, rows: Int32, capacity: Int32):
    """p_scores with q from rope_pack (A tiles contiguous, 64 x 8 fp32) and K column-major from the position-major
    cache. Grid: row blocks x heads x key blocks."""
    var i = Int(block_idx.x)
    var j = Int(block_idx.z)
    if j > i:
        return
    var h = Int(block_idx.y)
    var nr = Int(rows)
    var g = h // Int(nq)
    var row = Int(kvh) * HD
    var qa = qp + (h * (nr // 64) + i) * (HD // 8) * 512
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    comptime for d in range(0, HD, 8):
        var at = CoopMatrix[DType.float32, 64, 8, MATRIX_A].load(qa.unsafe_offset((d // 8) * 512), 8)
        var bt = CoopMatrix[DType.float32, 8, 64, MATRIX_B].load[row_major=False](
            kc.unsafe_offset(64 * j * row + g * HD + d), row)
        acc = at.multiply_add(bt, acc)
    var cap = Int(capacity)
    acc.store(y.unsafe_offset((h * nr + 64 * i) * cap + 64 * j), cap)


def p_softmax(scores: F32, count: Int32, rows: Int32, capacity: Int32):
    """Head block_idx.x's scores of row block_idx.y (p_scores' layout), in place, to probabilities over keys 0 .. row,
    and zeros for the rest of its block's keys. Padding rows (row >= count) get zeros only."""
    var sp = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var r = Int(block_idx.y)
    var s = scores + (Int(block_idx.x) * Int(rows) + r) * Int(capacity)
    var last = r if r < Int(count) else -1  # no keys for a padding row
    var highest: Float32 = -3.402823e38
    for t0 in range(0, last + 1, 64):
        if t0 + lane <= last:
            highest = max(highest, s[t0 + lane])
    sp[lane] = highest
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] = max(sp[lane], sp[lane + (32 >> stage)])
        barrier()
    highest = sp[0]
    barrier()
    var total: Float32 = 0
    for t0 in range(0, last + 1, 64):  # each lane rereads only what it wrote
        if t0 + lane <= last:
            var e = exp(s[t0 + lane] - highest)
            s[t0 + lane] = e
            total += e
    sp[lane] = total
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] += sp[lane + (32 >> stage)]
        barrier()
    var inv = 1 / sp[0] if last >= 0 else Float32(0)
    for t0 in range(0, (r // 64) * 64 + 64, 64):
        var t = t0 + lane
        s[t] = s[t] * inv if t <= last else 0


def p_values[HD: Int](pr: F32, vc: F32, y: F32, nq: Int32, kvh: Int32, heads: Int32, rows: Int32, capacity: Int32):
    """Attention output for rows 64 block_idx.x .. and columns 64 (block_idx.y % (HD / 64)) of head block_idx.y /
    (HD / 64): P V over the keys up to the block's last row, P from p_softmax (rows `capacity` apart), V straight from
    the cache; fp32 cooperative products. y: rows of heads HD."""
    comptime C = HD // 64
    var h = Int(block_idx.y) // C
    var c = Int(block_idx.y) % C
    var i0 = Int(block_idx.x) * 64
    var cap = Int(capacity)
    var row = Int(kvh) * HD
    var g = h // Int(nq)
    var pbase = pr + (h * Int(rows) + i0) * cap
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for t0 in range(0, i0 + 64, 8):  # the 840's fp32 product: 64 x 64 x 8
        var a = CoopMatrix[DType.float32, 64, 8, MATRIX_A].load(pbase.unsafe_offset(t0), cap)
        var b = CoopMatrix[DType.float32, 8, 64, MATRIX_B].load(vc.unsafe_offset(t0 * row + g * HD + c * 64), row)
        acc = a.multiply_add(b, acc)
    var oy = Int(heads) * HD
    acc.store(y.unsafe_offset(i0 * oy + h * HD + c * 64), oy)
