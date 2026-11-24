# Gemma 4's prompt attention on the Adreno 850's matrix units (LKH_850=1): g4k's three kernels (scores, softmax,
# P V) with the products in fp16 instead of fp32. The 850 runs fp32 cooperative matrices on its ALUs; fp16 ones on its
# matrix units. Gemma 4's head dims (256 sliding, 512 full) need more 64 x 64 accumulators than a subgroup can hold on
# the 850 (two hang it), so this is not a one-pass flash attention: the scores still go through memory. Gemma's
# attention scale is 1 on q/k-normed vectors, so scores are large: q k^T accumulates in fp32 (fp16 inputs, fp32
# accumulator, which the 850's matrix units also run).
#
# Operands, all K-minor (each lane's row or column contiguous along the product's k):
#   qh   fp16 copy of the batch's q rows, [rows][heads HD] (A of q k^T, row-major)
#   kh   fp16 copy of a layer's K cache, [position][kvh HD] (B of q k^T, column-major: a key's dims contiguous)
#   vt   V cache transposed, [kvh HD][capacity] (B of P V, column-major: a dim's positions contiguous)
#   ph   P in fp16, [row][head][capacity] (A of P V, row-major), from p_softmax_h
from std.math import exp
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]


def to_h(src: F32, dst: U32, rows: Int32, cols: Int32, src_stride: Int32, dst_stride: Int32):
    """dst[r, c] = fp16(src[r, c]) for rows x cols (cols even, strides in elements, dst's even), two values a thread
    written as one word (grid: rows cols / 2 / 256, 256 threads)."""
    var i = global_idx.x
    var half_cols = Int(cols) // 2
    if i >= Int(rows) * half_cols:
        return
    var r = i // half_cols
    var c = (i % half_cols) * 2
    var v = src.load[width=2](r * Int(src_stride) + c).cast[DType.float16]()
    dst[(r * Int(dst_stride) + c) // 2] = bitcast[DType.uint32, 1](v)[0]


def vt_h(vc: F32, vt: U32, keys: Int32, width: Int32, capacity: Int32):
    """vt[d, t] = fp16(vc[t, d]) for positions t < keys (even) and d < width (kvh HD): the V cache transposed, a
    dim's positions contiguous (rows `capacity` apart). Two positions of one dim a thread (grid: width keys / 2 /
    256, 256 threads; neighbouring threads take neighbouring dims, so the reads coalesce)."""
    var i = global_idx.x
    var w = Int(width)
    if i >= w * (Int(keys) // 2):
        return
    var d = i % w
    var t = (i // w) * 2
    var v = SIMD[DType.float16, 2](vc[t * w + d].cast[DType.float16](), vc[(t + 1) * w + d].cast[DType.float16]())
    vt[(d * Int(capacity) + t) // 2] = bitcast[DType.uint32, 1](v)[0]


@always_inline
def _key_lo(pa: Int, window: Int) -> Int:
    """g4k._key_lo: the first key a 64-row block starting at position pa reads, 64-aligned."""
    return (max(0, pa - window + 1) // 64) * 64 if window > 0 else 0


def p_scores_h[HD: Int](qh: F16, kh: F16, y: F32, p0: Int32, window: Int32, nq: Int32, kvh: Int32, heads: Int32,
                        capacity: Int32):
    """g4k.p_scores_mma on the matrix units: S = Q K^T (scale 1), fp16 operands and an fp32 accumulator, for head
    block_idx.y, rows 64 block_idx.x .., keys 64 block_idx.z .. (blocks the rows never read exit at once). Scores
    [row][head][capacity] fp32, as g4k.p_softmax reads them. Grid (rows / 64, heads, the last key / 64 + 1), 64
    threads."""
    var h = Int(block_idx.y)
    var i0 = Int(block_idx.x) * 64
    var j0 = Int(block_idx.z) * 64
    var pa = Int(p0) + i0
    if j0 < _key_lo(pa, Int(window)) or j0 >= pa + 64:
        return
    var nh = Int(heads)
    var ld = nh * Int(capacity)
    var row = Int(kvh) * HD
    var g = h // Int(nq)
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    comptime for k in range(0, HD, 16):
        var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(qh.unsafe_offset(i0 * nh * HD + h * HD + k), nh * HD)
        var bt = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load[row_major=False](
            kh.unsafe_offset(j0 * row + g * HD + k), row)
        acc = at.multiply_add(bt, acc)
    acc.store(y.unsafe_offset(i0 * ld + h * Int(capacity) + j0), ld)


def p_softmax_h(scores: F32, ph: U32, p0: Int32, count: Int32, window: Int32, heads: Int32, capacity: Int32):
    """g4k.p_softmax writing the probabilities to ph in fp16 (same [row][head][capacity] layout; pairs as words):
    head block_idx.x, row block_idx.y; zeros for the block's other keys and for padding rows."""
    var sp = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var lane = Int(thread_idx.x)
    var r = Int(block_idx.y)
    var base = r * Int(heads) * Int(capacity) + Int(block_idx.x) * Int(capacity)
    var s = scores + base
    var w = Int(window)
    var p = Int(p0) + r
    var pa = Int(p0) + (r // 64) * 64
    var lo = _key_lo(pa, w)
    var first = max(0, p - w + 1) if w > 0 else 0
    var last = p if r < Int(count) else first - 1  # no keys for a padding row
    var highest: Float32 = -3.402823e38
    for t0 in range(first, last + 1, 64):
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
    for t0 in range(first, last + 1, 64):
        if t0 + lane <= last:
            total += exp(s[t0 + lane] - highest)
    sp[lane] = total
    barrier()
    comptime for stage in range(6):
        if lane < 32 >> stage:
            sp[lane] += sp[lane + (32 >> stage)]
        barrier()
    var inv = 1 / sp[0] if last >= first else Float32(0)
    for t0 in range(lo, pa + 64, 128):
        var t = t0 + 2 * lane
        if t < pa + 64:
            var v = SIMD[DType.float32, 2](0)
            comptime for e in range(2):
                if t + e >= first and t + e <= last:
                    v[e] = exp(s[t + e] - highest) * inv
            ph[(base + t) // 2] = bitcast[DType.uint32, 1](v.cast[DType.float16]())[0]


def p_values_h[HD: Int](ph: F16, vt: F16, y: F32, p0: Int32, window: Int32, nq: Int32, kvh: Int32, heads: Int32,
                        capacity: Int32):
    """g4k.p_values_mma on the matrix units: the attention output for rows 64 block_idx.x .. and dims 64 (block_idx.y %
    (HD / 64)) .. of head block_idx.y / (HD / 64), P (fp16) times V (from vt) over the keys the block reads, an fp32
    accumulator. Output rows of heads HD fp32. Grid (rows / 64, heads HD / 64), 64 threads."""
    comptime C = HD // 64
    var h = Int(block_idx.y) // C
    var c = Int(block_idx.y) % C
    var i0 = Int(block_idx.x) * 64
    var pa = Int(p0) + i0
    var cap = Int(capacity)
    var ld = Int(heads) * cap
    var g = h // Int(nq)
    var vb = vt + (g * HD + c * 64) * cap
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for t0 in range(_key_lo(pa, Int(window)), pa + 64, 16):
        var a = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(ph.unsafe_offset(i0 * ld + h * cap + t0), ld)
        var b = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load[row_major=False](vb.unsafe_offset(t0), cap)
        acc = a.multiply_add(b, acc)
    var oy = Int(heads) * HD
    acc.store(y.unsafe_offset(i0 * oy + h * HD + c * 64), oy)
