# Llama prefill kernels for the Adreno 850's matrix units (fp16 cooperative matrices, K-minor operands): the prompt's
# attention as one flash-attention kernel (adrenoblas ablas/llama3b/kernels/fa3.comp, ported), with q, k and v^T as
# fp16 tiles that rope_fa / v_fa write from the q|k|v product, and the output written as the o product's packed X.
#
# Layouts (halves; M = the prompt's padded rows, a multiple of 64; head dim 128):
#   Q   [H][M/64][128/16][64][16]    a head's rows as R tiles (row = position, k = head dim), scaled by 1/sqrt(128)
#   K   [KVH][M/64][128/16][64][16]  the same for keys: as a 16 x 64 B tile loaded column-major, each key's 16 dims are
#                                    contiguous (K-minor)
#   V^T [KVH][128/64][M/16][64][16]  v transposed into R tiles (row = dim, k = position): for P V, B tiles of 16
#                                    positions x 64 dims, column-major
#   O   lkh's R tiles of the [M, H 128] attention output (pack_x's layout), the o product's X
# The fp32 position-major KV cache (decode's) is written too.
from std.math import exp, sqrt
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]


@always_inline
def r_tile(r: Int, c: Int, kk: Int) -> Int:
    """Where element (r, c) of a matrix with rows of kk goes in R tiles (halves)."""
    return ((r // 64) * (kk // 16) + c // 16) * 1024 + (r % 64) * 16 + c % 16


def rope_fa[HD: Int](qkv: F32, cos: F32, sin: F32, kc: F32, qt: U32, kt: U32, h: Int32, kvh: Int32, stride: Int32,
                     rows: Int32, scale: Float32):
    """RoPE of the prompt's q and k (positions 0 .., row = position) from the q|k|v product's fp32 rows: q (scaled)
    into Q tiles, k into K tiles and the fp32 cache. A thread rotates dims i, i + 1 and i + 64, i + 65 of one head of one
    row (grid: ((h + kvh) HD / 4 / 64, rows), 64 threads)."""
    comptime HALF = HD // 2
    var t = global_idx.x
    var nh = Int(h)
    var nkv = Int(kvh)
    if t >= (nh + nkv) * (HALF // 2):
        return
    var row = Int(block_idx.y)
    var nr = Int(rows)
    var hh = t // (HALF // 2)
    var i = (t % (HALF // 2)) * 2
    var isq = hh < nh
    var off = row * Int(stride) + hh * HD + i
    var a = qkv.load[width=2](off)
    var b = qkv.load[width=2](off + HALF)
    var c = cos.load[width=2](row * HALF + i)
    var s = sin.load[width=2](row * HALF + i)
    var ra = a * c - b * s
    var rb = b * c + a * s
    if isq:
        ra *= scale
        rb *= scale
        var base = hh * nr * HD
        qt[(base + r_tile(row, i, HD)) // 2] = bitcast[DType.uint32, 1](ra.cast[DType.float16]())[0]
        qt[(base + r_tile(row, i + HALF, HD)) // 2] = bitcast[DType.uint32, 1](rb.cast[DType.float16]())[0]
    else:
        var g = hh - nh
        var dst = row * nkv * HD + g * HD + i
        kc.store(dst, ra)
        kc.store(dst + HALF, rb)
        var base = g * nr * HD
        kt[(base + r_tile(row, i, HD)) // 2] = bitcast[DType.uint32, 1](ra.cast[DType.float16]())[0]
        kt[(base + r_tile(row, i + HALF, HD)) // 2] = bitcast[DType.uint32, 1](rb.cast[DType.float16]())[0]


def v_fa[HD: Int](qkv: F32, vc: F32, vt: U32, h: Int32, kvh: Int32, stride: Int32, rows: Int32):
    """v of two adjacent rows (positions) into V^T tiles (one 32-bit store of the pair) and the fp32 cache. A thread
    per (kv head, dim) and row pair (grid: (kvh HD / 64, rows / 2), 64 threads)."""
    var t = global_idx.x
    var nkv = Int(kvh)
    if t >= nkv * HD:
        return
    var r0 = Int(block_idx.y) * 2
    var nr = Int(rows)
    var g = t // HD
    var d = t % HD
    var src = r0 * Int(stride) + (Int(h) + nkv) * HD + t
    var v0 = qkv[src]
    var v1 = qkv[src + Int(stride)]
    var dst = r0 * nkv * HD + t
    vc[dst] = v0
    vc[dst + nkv * HD] = v1
    var base = g * HD * nr  # this kv head's V^T: HD rows of nr
    var e = base + r_tile(d, r0, nr)
    vt[e // 2] = bitcast[DType.uint32, 1](SIMD[DType.float16, 2](v0.cast[DType.float16](), v1.cast[DType.float16]()))[0]


comptime SH16 = UnsafePointer[Float16, MutUntrackedOrigin, address_space=AddressSpace.SHARED]
comptime LDS = 68  # the staging tiles' row stride in halves (17 x 8 bytes: no bank conflicts)


def fa[NQ: Int, HD: Int](qt: F16, kt: F16, vt: F16, o: U32, m_rows: Int32, ocols: Int32):
    """Causal flash attention of head block_idx.y for query rows 64 (M / 64 - 1 - block_idx.x) .. (the longest rows
    first), two subgroups: in pass 1 they take alternate 64-key blocks and keep each row's running max and sum (a lane
    a row, the 64 x 64 score tile staged in shared memory), then combine them; in pass 2 they recompute the scores of
    a pair of key blocks and write P (fp16) to shared memory. Head dim 128: each subgroup multiplies both P tiles into
    its 64 of the 128 output dims. Head dim 64: each multiplies its own P tile into a partial output, and the two
    partials are added at the end. The output goes to o as R tiles of the [M, ocols] attention output. Every
    cooperative-matrix op runs unconditionally (the 850's compiler crashes on multiplies under per-subgroup branches):
    a subgroup without a key block redoes the last one and ignores it. Grid (M / 64, heads), 128 threads; NQ query
    heads a KV head."""
    comptime assert HD == 64 or HD == 128, "fa: head dim 64 or 128"
    comptime KS = HD // 16  # 16-deep steps of q k^T
    var M = Int(m_rows)
    var z = Int(block_idx.y)
    var g = z // NQ
    var t = Int(thread_idx.x)
    var sg = t // 64
    var l = t % 64
    var qb = M // 64 - 1 - Int(block_idx.x)
    var row0 = qb * 64
    var qa = qt + z * M * HD + qb * 64 * HD
    var kbase = kt + g * M * HD
    var vbase = vt + g * HD * M + (sg * (M // 16) * 1024 if HD == 128 else 0)
    var sh = stack_allocation[2 * 64 * LDS, DType.float16, address_space=AddressSpace.SHARED]()
    var stat = stack_allocation[256, DType.float32, address_space=AddressSpace.SHARED]()
    var sb = sg * 64 * LDS
    var sr = sb + l * LDS
    var m: Float32 = -1e30
    var lsum: Float32 = 0
    var npairs = qb // 2 + 1
    for kp in range(npairs):
        var valid = 2 * kp + sg <= qb
        var kb = min(2 * kp + sg, qb)
        var s = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
        comptime for kk in range(KS):
            var a = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(qa + kk * 1024, 16)
            var b = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load[row_major=False](kbase + (kb * KS + kk) * 1024, 16)
            s = a.multiply_add(b, s)
        s.store(sh.unsafe_offset(sb), LDS)
        barrier()
        var lim = l if kb == qb else 63
        if valid:
            var bm: Float32 = -1e30
            comptime for j in range(16):
                var v = sh.load[width=4](sr + 4 * j).cast[DType.float32]()
                comptime for i in range(4):
                    if 4 * j + i <= lim:
                        bm = max(bm, v[i])
            var mn = max(m, bm)
            lsum *= exp(m - mn)
            comptime for j in range(16):
                var v = sh.load[width=4](sr + 4 * j).cast[DType.float32]()
                comptime for i in range(4):
                    if 4 * j + i <= lim:
                        lsum += exp(v[i] - mn)
            m = mn
        barrier()
    stat[sg * 128 + 2 * l] = m
    stat[sg * 128 + 2 * l + 1] = lsum
    barrier()
    var om = stat[(1 - sg) * 128 + 2 * l]
    var ol = stat[(1 - sg) * 128 + 2 * l + 1]
    var mm = max(m, om)
    var inv = 1 / (lsum * exp(m - mm) + ol * exp(om - mm))
    m = mm
    var acc = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    for kp in range(npairs):
        var valid = 2 * kp + sg <= qb
        var kb = min(2 * kp + sg, qb)
        var s = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
        comptime for kk in range(KS):
            var a = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(qa + kk * 1024, 16)
            var b = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load[row_major=False](kbase + (kb * KS + kk) * 1024, 16)
            s = a.multiply_add(b, s)
        s.store(sh.unsafe_offset(sb), LDS)
        barrier()
        var lim = l if kb == qb else 63
        comptime for j in range(16):
            var v = sh.load[width=4](sr + 4 * j).cast[DType.float32]()
            var p = SIMD[DType.float32, 4](0)
            comptime for i in range(4):
                if valid and 4 * j + i <= lim:
                    p[i] = exp(v[i] - m) * inv
            sh.store(sr + 4 * j, p.cast[DType.float16]())
        barrier()
        comptime if HD == 128:
            comptime for tt in range(2):
                var kt2 = min(2 * kp + tt, qb)  # past the diagonal that P tile is all zero
                comptime for kc in range(4):
                    var pa = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(
                        sh.unsafe_offset(tt * 64 * LDS + kc * 16), LDS)
                    var vb = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load[row_major=False](
                        vbase + (kt2 * 4 + kc) * 1024, 16)
                    acc = pa.multiply_add(vb, acc)
        else:  # this subgroup's own key block (its P tile; all zero past the diagonal)
            comptime for kc in range(4):
                var pa = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(sh.unsafe_offset(sb + kc * 16), LDS)
                var vb = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load[row_major=False](
                    vbase + (kb * 4 + kc) * 1024, 16)
                acc = pa.multiply_add(vb, acc)
        barrier()
    acc.store(sh.unsafe_offset(sb), LDS)
    barrier()
    comptime if HD == 128:
        var ob = r_tile(row0 + l, z * HD + sg * 64, Int(ocols))
        comptime for c in range(4):
            comptime for hh in range(2):
                var x = sh.load[width=8](sr + c * 16 + hh * 8)
                var w = bitcast[DType.uint32, 4](x)
                var dst = (ob + c * 1024 + hh * 8) // 2
                comptime for e in range(4):
                    o[dst + e] = w[e]
    else:  # the two partials added; subgroup 0 takes columns 0 .. 31 of its row, subgroup 1 32 .. 63
        var ob = r_tile(row0 + l, z * HD + sg * 32, Int(ocols))
        comptime for c in range(2):
            comptime for hh in range(2):
                var off = l * LDS + sg * 32 + c * 16 + hh * 8
                var x = (sh.load[width=8](off).cast[DType.float32]() + sh.load[width=8](64 * LDS + off).cast[
                    DType.float32]()).cast[DType.float16]()
                var w = bitcast[DType.uint32, 4](x)
                var dst = (ob + c * 1024 + hh * 8) // 2
                comptime for e in range(4):
                    o[dst + e] = w[e]

comptime I32 = UnsafePointer[Int32, MutAnyOrigin]
comptime EPS = Float32(1e-5)


def embed6(e0: F16, e1: F16, e2: F16, e3: F16, e4: F16, e5: F16, ids: I32, x: F32, crows: Int32, d: Int32, n: Int32):
    """The prompt's embedding rows in one launch: x[t] = row ids[t] of the embedding (in six chunks of crows rows),
    fp32; 8 values a thread (grid: n d / 8 / 256, 256 threads)."""
    var i = global_idx.x
    var dd = Int(d)
    if i >= Int(n) * (dd // 8):
        return
    var tt = i // (dd // 8)
    var c = (i % (dd // 8)) * 8
    var id = Int(ids[tt])
    var ch = id // Int(crows)
    var off = (id % Int(crows)) * dd + c
    var v: SIMD[DType.float16, 8]
    if ch == 0:
        v = e0.load[width=8](off)
    elif ch == 1:
        v = e1.load[width=8](off)
    elif ch == 2:
        v = e2.load[width=8](off)
    elif ch == 3:
        v = e3.load[width=8](off)
    elif ch == 4:
        v = e4.load[width=8](off)
    else:
        v = e5.load[width=8](off)
    x.store(tt * dd + c, v.cast[DType.float32]())


def norm_pack_ss(x: F32, w: F16, ss: F32, parts: Int32, xa: U32, d: Int32):
    """lg.norm_pack_t with each row's scale from the sums of squares a gemm_k_add epilogue left (ss: `parts` partial
    sums a row): x / rms(x) w for a 64 x 64 block as R tiles. Grid (d / 64, rows / 64), 256 threads."""
    var sb = stack_allocation[2048, DType.uint32, address_space=AddressSpace.SHARED]()
    var sp = stack_allocation[256, DType.float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var n = Int(d)
    var cb = Int(block_idx.x)
    var rb = Int(block_idx.y)
    var np = Int(parts)
    var q = np // 4  # four threads a row, `q` partial sums each
    var acc = Float32(0)
    var base = (64 * rb + t // 4) * np + (t % 4) * q
    for j in range(q):
        acc += ss[base + j]
    sp[t] = acc
    barrier()
    comptime for half in range(2):
        var r = t // 8 + 32 * half
        var tot = sp[4 * r] + sp[4 * r + 1] + sp[4 * r + 2] + sp[4 * r + 3]
        var sc = 1.0 / sqrt(tot / Float32(n) + EPS)
        var c = (t % 8) * 8
        var y = x.load[width=8]((64 * rb + r) * n + 64 * cb + c) * sc * w.load[width=8](64 * cb + c).cast[
            DType.float32]()
        var v = bitcast[DType.uint32, 4](y.cast[DType.float16]())
        comptime for e in range(4):
            sb[r * 32 + c // 2 + e] = v[e]
    barrier()
    var dst = xa + ((rb * (n // 16) + cb * 4) * 1024) // 2
    comptime for j in range(8):
        var qq = t + 256 * j
        dst[qq] = sb[(qq % 512) // 8 * 32 + (qq // 512) * 8 + qq % 8]


def tiles_qk[HD: Int](q: F32, kc: F32, qt: U32, kt: U32, h: Int32, kvh: Int32, stride: Int32, rows: Int32,
                      count: Int32):
    """fa's Q and K tiles from a model's own prefill layouts (positions 0 ..): q (normed, rotated, scaled) in rows of
    `stride` floats, k in the fp32 position-major cache; rows >= count are zeros. A thread converts 8 dims of one head
    of one row (grid: ((h + kvh) HD / 8 / 64, rows), 64 threads)."""
    var t = global_idx.x
    var nh = Int(h)
    var nkv = Int(kvh)
    if t >= (nh + nkv) * (HD // 8):
        return
    var row = Int(block_idx.y)
    var hh = t // (HD // 8)
    var d = (t % (HD // 8)) * 8
    var v = SIMD[DType.float32, 8](0)
    var nr = Int(rows)
    if row < Int(count):
        if hh < nh:
            v = q.load[width=8](row * Int(stride) + hh * HD + d)
        else:
            v = kc.load[width=8](row * nkv * HD + (hh - nh) * HD + d)
    var w = bitcast[DType.uint32, 4](v.cast[DType.float16]())
    var dst = qt if hh < nh else kt
    var base = (hh if hh < nh else hh - nh) * nr * HD
    var e = (base + r_tile(row, d, HD)) // 2
    comptime for i in range(4):
        dst[e + i] = w[i]


def tiles_v[HD: Int](vc: F32, vt: U32, kvh: Int32, rows: Int32, count: Int32):
    """fa's V^T tiles from the fp32 position-major cache (positions 0 ..; rows >= count zeros): two positions of one
    dim a thread (grid: (kvh HD / 64, rows / 2), 64 threads)."""
    var t = global_idx.x
    var nkv = Int(kvh)
    if t >= nkv * HD:
        return
    var r0 = Int(block_idx.y) * 2
    var nr = Int(rows)
    var g = t // HD
    var d = t % HD
    var v0 = vc[r0 * nkv * HD + t] if r0 < Int(count) else Float32(0)
    var v1 = vc[(r0 + 1) * nkv * HD + t] if r0 + 1 < Int(count) else Float32(0)
    var e = g * HD * nr + r_tile(d, r0, nr)
    vt[e // 2] = bitcast[DType.uint32, 1](SIMD[DType.float16, 2](v0.cast[DType.float16](), v1.cast[DType.float16]()))[0]
