# int4 (Q4_0) prefill projections, Y[rows, n] = X[rows, k] W^T, on the Adreno 840's fp16 cooperative matrices
# (64 x 64 x 16), with the operands in the layouts its driver reads fastest (adreno-gemm-worklog, kernels 13 and 14).
# lk.gemm_q4 does the same on fp32 cooperative matrices (64 x 64 x 8), whose ceiling on the 840 is half the fp16 one.
#
# The 840 has no matrix unit: its driver turns a cooperative multiply-add into ALU instructions in which lane r computes
# row r of C from row r of A, with B staged into shared memory along N. So:
#   A  X in fp16 as R tiles, [rows/64][k/16][64][16]: lane r's 16 values of a K step are 32 contiguous bytes
#      (pack_x writes them from lk's fp32 rows).
#   B  W^T in fp16 as 16 x 64 tiles with N contiguous, the K tiles of a column block adjacent, [n/64][k/16][16][64]
#      (deq_w writes them from lk's int4 rows before each product, so the int4 rows stay the only copy of the weights,
#      shared with decode's gemv_q4); or gemm_hq unpacks lk's int4 rows into shared memory inside the product, B rows
#      along N, a K step at a time, with no fp16 copy of W at all. gemm_hq also takes llama's and gemma4's storage
#      (int4 or int8 with a scale per 64: GS, FMT) and fp16 rows (llama's fp16 weights).
# The 840 rounds every partial sum of an fp16 cooperative product to fp16 (2.7% error over 4096 products), so K is split
# into chunks of CH: grid z = chunk, each writing its fp16 partial C, and sum_parts adds them in fp32.
#
# gemm_hq needs the fork's SPIR-V backend from 2026-11-23 or later: before, it addressed shared arrays with
# OpInBoundsAccessChain, which the 840's driver resolves for 16-bit types as if each element took twice its size (every
# other half of a tile written with plain stores went missing); it now emits OpAccessChain, and types a shared array of
# halves written 8 bytes at a time as <4 x half> (one store per 4 halves). See coopmat/smem_pack.mojo.
from std.math import exp
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
comptime I32 = UnsafePointer[Int32, MutAnyOrigin]
comptime G = 32  # weights per Q4_0 scale


def pack_x(x: F32, xa: U32, k: Int32, total: Int32):
    """X (rows x k fp32, rows k apart) -> R tiles of fp16 (xa as pairs of halves: this backend splits a vector store
    into single elements, and 32-bit ones are half as many); a thread converts 8 consecutive values of a row."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var kk = Int(k)
    var r = e // (kk // 8)
    var c = (e % (kk // 8)) * 8
    var v = x.load[width=8](r * kk + c).cast[DType.float16]()
    xa.store((((r // 64) * (kk // 16) + c // 16) * 1024 + (r % 64) * 16 + c % 16) // 2, bitcast[DType.uint32, 4](v))


def deq_w(wq: U32, ws: F16, wd: U32, n: Int32, k: Int32, total: Int32):
    """lk's int4 rows (n x k/8 words, low nibble first, two's complement; an fp16 scale per 32) -> fp16 B tiles (wd as
    pairs of halves). A thread takes 8 rows x 32 k (four words and a scale of each row) and writes 32 runs of 8
    columns; neighbouring threads take neighbouring rows, so their runs are adjacent (total = n k / 256)."""
    var v = global_idx.x
    if v >= Int(total):
        return
    var kk = Int(k)
    var nb = Int(n) // 8
    var rb = v % nb
    var kb = v // nb  # the block of 32 k
    var r = 8 * rb
    var w = SIMD[DType.uint32, 32]()
    var sv = SIMD[DType.float16, 8]()
    comptime for j in range(8):
        var w4 = wq.load[width=4]((r + j) * (kk // 8) + 4 * kb)
        comptime for i in range(4):
            w[4 * j + i] = w4[i]
        sv[j] = ws[(r + j) * (kk // G) + kb]
    var base = (r // 64) * (kk // 16) * 1024 + r % 64
    comptime for i in range(4):
        comptime for e in range(8):
            var kx = 32 * kb + 8 * i + e
            var q = SIMD[DType.int32, 8]()
            comptime for j in range(8):
                q[j] = Int32(((w[4 * j + i] >> UInt32(4 * e)) & 15) ^ 8) - 8
            var h = q.cast[DType.float16]() * sv
            wd.store((base + (kx // 16) * 1024 + (kx % 16) * 64) // 2, bitcast[DType.uint32, 4](h))


def gemm_h[WM: Int, WN: Int, TN: Int, CH: Int](xa: F16, wd: F16, part: F16, n: Int32, k: Int32, rows: Int32):
    """part[z] (rows x n, fp16) = X[:, z CH .. z CH + CH] W[:, same]^T: a workgroup of WM x WN subgroups, each computing
    64 x 64 TN of C from one A tile and TN B tiles a K step, both loaded straight from memory. Launch with grid
    (n / (64 WN TN), rows / (64 WM), ceil(k / CH)) and 64 WM WN threads."""
    var kk = Int(k)
    var nn = Int(n)
    var sg = Int(thread_idx.x) // 64
    var row0 = Int(block_idx.y) * 64 * WM + (sg // WN) * 64
    var col0 = Int(block_idx.x) * 64 * WN * TN + (sg % WN) * 64 * TN
    var k_lo = Int(block_idx.z) * CH
    var k_hi = min(k_lo + CH, kk)
    var abase = xa + (row0 // 64) * (kk // 16) * 1024
    var bbase = wd + (col0 // 64) * (kk // 16) * 1024
    var c0 = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    var c1 = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    for kb in range(k_lo, k_hi, 16):
        var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(abase + (kb // 16) * 1024, 16)
        var b0 = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load(bbase + (kb // 16) * 1024, 64)
        c0 = at.multiply_add(b0, c0)
        comptime if TN == 2:
            var b1 = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load(bbase + (kk // 16 + kb // 16) * 1024, 64)
            c1 = at.multiply_add(b1, c1)
    var out = part + Int(block_idx.z) * Int(rows) * nn + row0 * nn + col0
    c0.store(out, nn)
    comptime if TN == 2:
        c1.store(out + 64, nn)


comptime Q4 = 0  # gemm_hq's weight formats: int4, 8 a word, low nibble first, an fp16 scale per GS (lk, llama, gemma4)
comptime Q8 = 1  # int8, 4 a word, low byte first, an fp16 scale per GS (gemma4's int8 storage)
comptime FP16 = 2  # fp16 rows, read as pairs of halves; no scales (llama's fp16 weights)


comptime SH16 = UnsafePointer[Float16, MutUntrackedOrigin, address_space=AddressSpace.SHARED]


@always_inline
def unpack_w[BN: Int, T: Int, BKS: Int, RG: Int, ALONG_K: Bool, GS: Int, FMT: Int](
    sb: SH16, wq: U32, ws: F16, wrow0: Int, kb: Int, kk: Int, t: Int
):
    """Thread t's share of W rows wrow0 .. wrow0 + BN - 1, k kb .. kb + BKS - 1, into sb as fp16 W^T (BKS rows of BN):
    gemm_hq's and gemm_hqg's unpack of a K step, T threads. An unpack unit is RG rows of W x 8 k (a word a row for
    int4, two for int8, four for fp16): RG scale and word loads, then 8 stores of RG halves (one k each, along N).
    Neighbouring threads take neighbouring 8 k of the same rows (ALONG_K: the loads coalesce) or neighbouring rows
    (the stores do). kk: W's row length."""
    comptime KW = BKS // 8  # units of 8 k of a row a K step
    comptime UNITS = (BN // RG) * KW
    comptime PER = (UNITS + T - 1) // T
    comptime WPU = 1 if FMT == Q4 else (2 if FMT == Q8 else 4)  # words of a row a unit
    comptime assert FMT == Q4 or FMT == Q8 or FMT == FP16, "FMT: Q4, Q8 or FP16"
    comptime for i in range(PER):
        var u = i * T + t
        if UNITS % T == 0 or u < UNITS:
            var kw: Int
            var rg: Int
            comptime if ALONG_K:
                kw = u % KW
                rg = u // KW
            else:
                rg = u % (BN // RG)
                kw = u // (BN // RG)
            var r = wrow0 + rg * RG  # the first row of W (column of C)
            var kx = kb + 8 * kw
            var w = SIMD[DType.uint32, RG * WPU]()  # row j's words at WPU j ..
            var sv = SIMD[DType.float16, RG]()
            comptime for j in range(RG):
                comptime if WPU == 1:
                    w[j] = wq[(r + j) * (kk // 8) + kx // 8]
                else:
                    var wv = wq.load[width=WPU]((r + j) * (kk * WPU // 8) + kx * WPU // 8)
                    comptime for h in range(WPU):
                        w[WPU * j + h] = wv[h]
                comptime if FMT != FP16:
                    sv[j] = ws[(r + j) * (kk // GS) + kx // GS]
            comptime for e in range(8):
                var h: SIMD[DType.float16, RG]
                comptime if FMT == Q4:
                    var we = SIMD[DType.uint32, RG]()
                    comptime for j in range(RG):
                        we[j] = w[j]
                    var q = (((we >> UInt32(4 * e)) & 15) ^ 8).cast[DType.int32]() - 8
                    h = q.cast[DType.float16]() * sv
                elif FMT == Q8:
                    var we = SIMD[DType.uint32, RG]()
                    comptime for j in range(RG):
                        we[j] = w[2 * j + e // 4]
                    var q = (((we >> UInt32(8 * (e % 4))) & 255) ^ 128).cast[DType.int32]() - 128
                    h = q.cast[DType.float16]() * sv
                else:
                    h = SIMD[DType.float16, RG]()
                    comptime for j in range(RG):
                        h[j] = bitcast[DType.float16, 2](w[4 * j + e // 2])[e % 2]
                sb.unsafe_store((8 * kw + e) * BN + rg * RG, h)


def gemm_hq[WM: Int, WN: Int, CH: Int, BKS: Int, RG: Int, ALONG_K: Bool, GS: Int = G, FMT: Int = Q4, TN: Int = 1](
    xa: F16, wq: U32, ws: F16, part: F16, n: Int32, k: Int32, rows: Int32
):
    """part[z] (rows x n, fp16) = X[:, z CH .. z CH + CH] W[:, same]^T with W unpacked from its rows (int4, int8 or
    fp16: FMT) inside the product: a workgroup of WM x WN subgroups, each computing 64 x 64 TN of C (TN accumulators,
    so each A tile it loads feeds TN products), unpacks the workgroup's BKS x 64 WN TN slice of W^T into shared memory
    (fp16, rows along N) a K step at a time (unpack_w), then each subgroup multiplies its A tiles (loaded from xa's R
    tiles) by its 16 x 64 B tiles from shared memory. Launch with grid (n / (64 WN TN), rows / (64 WM), ceil(k / CH))
    and 64 WM WN threads; CH and k multiples of BKS, and of GS for int4 and int8; BKS x 64 WN TN halves of shared
    memory at most 16 KB."""
    comptime BN = 64 * WN * TN
    comptime T = 64 * WM * WN
    comptime assert TN == 1 or TN == 2, "TN: 1 or 2"
    var sb = stack_allocation[BKS * BN, DType.float16, address_space=AddressSpace.SHARED]()
    var kk = Int(k)
    var nn = Int(n)
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * 64 * WM + (sg // WN) * 64
    var colw = Int(block_idx.x) * BN
    var sc = (sg % WN) * 64 * TN
    var k_lo = Int(block_idx.z) * CH
    var k_hi = min(k_lo + CH, kk)
    var abase = xa + (row0 // 64) * (kk // 16) * 1024
    var c0 = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    var c1 = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    for kb in range(k_lo, k_hi, BKS):
        unpack_w[BN, T, BKS, RG, ALONG_K, GS, FMT](sb, wq, ws, colw, kb, kk, t)
        barrier()
        comptime for s in range(BKS // 16):
            var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(abase + (kb // 16 + s) * 1024, 16)
            var bt = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load(sb.unsafe_offset(16 * s * BN + sc), BN)
            c0 = at.multiply_add(bt, c0)
            comptime if TN == 2:
                var b1 = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load(sb.unsafe_offset(16 * s * BN + sc + 64), BN)
                c1 = at.multiply_add(b1, c1)
        barrier()
    var out = part + Int(block_idx.z) * Int(rows) * nn + row0 * nn + colw + sc
    c0.store(out, nn)
    comptime if TN == 2:
        c1.store(out + 64, nn)


# ---- mixtures of experts: the batch's (token, choice) pairs grouped by expert ----------------------------------------
# A model groups the pairs (lfm2moe's mk.p_group, or group below): each expert's rows together, padded to 64, and work
# tiles (expert, first grouped row) of 64 rows. pack_gather packs the grouped rows of X; gemm_hqg multiplies every
# tile by its expert's gate|up rows (expert e's at e 2 FE: gate rows, then up rows) in one launch; swiglu_pack turns
# the fp16 partials into silu(gate) up, packed for the down product (expert e's rows at e D); gemm_hqg again; combine
# adds each token's K outputs with the router's weights.


def group[K: Int](ids: I32, slot: I32, src: I32, tiles: I32, ntiles: I32, rows: Int32, e: Int32, tm: Int32):
    """One 128-lane workgroup, e <= 128 experts. Expert x (lane x) takes the pairs i = t K + k with ids[i] == x, in
    order: their grouped rows are x's segment, starting at offs[x] (the segments in expert order, each padded to tm
    rows): slot[i] = that row, src[row] = t. Work tiles of tm rows (expert, first row) into tiles; their number into
    ntiles. src's padding rows must hold -1 already (the caller fills it)."""
    var lane = Int(thread_idx.x)
    var cnt = stack_allocation[128, Int32, address_space=AddressSpace.SHARED]()
    var offs = stack_allocation[128, Int32, address_space=AddressSpace.SHARED]()
    var n = Int(rows) * K
    var c = 0
    if lane < Int(e):
        for i in range(n):
            if Int(ids[i]) == lane:
                c += 1
    cnt[lane] = Int32(c)
    barrier()
    var T = Int(tm)
    if lane == 0:
        var off = 0
        var nt = 0
        for x in range(Int(e)):
            offs[x] = Int32(off)
            var m = Int(cnt[x])
            var t0 = 0
            while t0 < m:
                tiles[2 * nt] = Int32(x)
                tiles[2 * nt + 1] = Int32(off + t0)
                nt += 1
                t0 += T
            off += (m + T - 1) // T * T
        ntiles[0] = Int32(nt)
    barrier()
    if lane < Int(e):
        var p = Int(offs[lane])
        for i in range(n):
            if Int(ids[i]) == lane:
                slot[i] = Int32(p)
                src[p] = Int32(i // K)
                p += 1


@always_inline
def r_tile(r: Int, c: Int, kk: Int) -> Int:
    """Where X[r, c] goes in pack_x's R tiles (in halves)."""
    return ((r // 64) * (kk // 16) + c // 16) * 1024 + (r % 64) * 16 + c % 16


def pack_gather(x: F32, src: I32, xa: U32, k: Int32, ntiles: I32, tm: Int32):
    """Grouped row r = x[src[r]] (zeros where src[r] < 0) as fp16 R tiles (pack_x's layout), the work tiles' rows
    only; a thread converts 8 values (grid: the grouped buffer's rows x k / 8)."""
    var i = global_idx.x
    var kk = Int(k)
    var r = i // (kk // 8)
    if r >= Int(ntiles[0]) * Int(tm):
        return
    var c = (i % (kk // 8)) * 8
    var s = Int(src[r])
    var v = SIMD[DType.float16, 8](0)
    if s >= 0:
        v = x.load[width=8](s * kk + c).cast[DType.float16]()
    xa.store(r_tile(r, c, kk) // 2, bitcast[DType.uint32, 4](v))


def gemm_hqg[WN: Int, CH: Int, BKS: Int, RG: Int, ALONG_K: Bool, GS: Int = G, FMT: Int = Q4](
    xa: F16, wq: U32, ws: F16, part: F16, n: Int32, k: Int32, rows: Int32, tiles: I32, ntiles: I32
):
    """Grouped products: work tile block y (expert e = tiles[2 y], grouped rows r0 = tiles[2 y + 1] .. r0 + 63) times
    expert e's matrix (its rows e n .. e n + n - 1): part[z][r0 + i, c] = X[r0 + i] . W_e[c] over K chunk z, for the
    64 WN columns c of block x. gemm_hq with one row of WN subgroups (64 x 64 of C each) and W's rows offset to the
    tile's expert. Launch with grid (n / (64 WN), the most tiles, ceil(k / CH)) and 64 WN threads; rows: the grouped
    buffer's (part's chunk stride)."""
    var it = Int(block_idx.y)
    if it >= Int(ntiles[0]):
        return
    comptime BN = 64 * WN
    comptime T = 64 * WN
    var sb = stack_allocation[BKS * BN, DType.float16, address_space=AddressSpace.SHARED]()
    var e = Int(tiles[2 * it])
    var row0 = Int(tiles[2 * it + 1])
    var kk = Int(k)
    var nn = Int(n)
    var t = Int(thread_idx.x)
    var sc = (t // 64) * 64
    var colw = Int(block_idx.x) * BN
    var k_lo = Int(block_idx.z) * CH
    var k_hi = min(k_lo + CH, kk)
    var abase = xa + (row0 // 64) * (kk // 16) * 1024
    var c0 = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    for kb in range(k_lo, k_hi, BKS):
        unpack_w[BN, T, BKS, RG, ALONG_K, GS, FMT](sb, wq, ws, e * nn + colw, kb, kk, t)
        barrier()
        comptime for s in range(BKS // 16):
            var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(abase + (kb // 16 + s) * 1024, 16)
            var bt = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load(sb.unsafe_offset(16 * s * BN + sc), BN)
            c0 = at.multiply_add(bt, c0)
        barrier()
    c0.store(part + Int(block_idx.z) * Int(rows) * nn + row0 * nn + colw + sc, nn)


def swiglu_pack(part: F16, chunks: Int32, rows: Int32, fe: Int32, xa: U32, ntiles: I32, tm: Int32):
    """The work tiles' rows of silu(gate) up, from gemm_hqg's gate|up partials (part: rows x 2 fe a chunk, added in
    fp32), as fp16 R tiles with k = fe (the down product's X); 8 values a thread (grid: rows x fe / 8)."""
    var i = global_idx.x
    var f = Int(fe)
    var r = i // (f // 8)
    if r >= Int(ntiles[0]) * Int(tm):
        return
    var c = (i % (f // 8)) * 8
    var g = SIMD[DType.float32, 8](0)
    var u = SIMD[DType.float32, 8](0)
    for z in range(Int(chunks)):
        var base = (z * Int(rows) + r) * 2 * f
        g += part.load[width=8](base + c).cast[DType.float32]()
        u += part.load[width=8](base + f + c).cast[DType.float32]()
    var a = g / (1 + exp(-g)) * u
    xa.store(r_tile(r, c, f) // 2, bitcast[DType.uint32, 4](a.cast[DType.float16]()))


# ---- the same, tiled: a workgroup writes whole R tiles ---------------------------------------------------------------
# pack_x and swiglu_pack give each thread 8 values of a row, so neighbouring threads write 32-byte pieces of R tiles
# 2 KB apart. These take a 64-row x 64-column block a workgroup (256 threads): they read its rows coalesced, stage the
# fp16 block in shared memory, and write its four 64 x 16 R tiles (8 KB) contiguously. Grid: (k / 64, rows / 64).

comptime SH32 = UnsafePointer[UInt32, MutUntrackedOrigin, address_space=AddressSpace.SHARED]


@always_inline
def _block_out(sb: SH32, xa: U32, rb: Int, cb: Int, kk: Int, t: Int):
    """The staged 64 x 64 fp16 block (sb: rows of 32 words) as its four R tiles: thread t writes words t + 256 j."""
    var dst = xa + ((rb * (kk // 16) + cb * 4) * 1024) // 2
    comptime for j in range(8):
        var q = t + 256 * j  # a word of the block's 2048, in R-tile order
        var tile = q // 512
        var r = (q % 512) // 8
        var c2 = q % 8  # a pair of halves within the tile's 16 columns
        dst[q] = sb[r * 32 + tile * 8 + c2]


def pack_t(x: F32, xa: U32, k: Int32):
    """pack_x, tiled: X (rows of k fp32) into fp16 R tiles. Grid (k / 64, rows / 64), 256 threads."""
    var sb = stack_allocation[2048, DType.uint32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var kk = Int(k)
    var cb = Int(block_idx.x)
    var rb = Int(block_idx.y)
    comptime for half in range(2):
        var r = t // 8 + 32 * half
        var c = (t % 8) * 8
        var v = x.load[width=8]((64 * rb + r) * kk + 64 * cb + c).cast[DType.float16]()
        var w = bitcast[DType.uint32, 4](v)
        comptime for e in range(4):
            sb[r * 32 + c // 2 + e] = w[e]
    barrier()
    _block_out(sb, xa, rb, cb, kk, t)


def swiglu_pack_t(part: F16, chunks: Int32, rows: Int32, fe: Int32, xa: U32):
    """swiglu_pack for a dense layer, tiled: silu(gate) up from the gate|up partials (part: rows x 2 fe a chunk, added
    in fp32) into fp16 R tiles with k = fe. Grid (fe / 64, rows / 64), 256 threads."""
    var sb = stack_allocation[2048, DType.uint32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var f = Int(fe)
    var cb = Int(block_idx.x)
    var rb = Int(block_idx.y)
    comptime for half in range(2):
        var r = t // 8 + 32 * half
        var c = (t % 8) * 8
        var g = SIMD[DType.float32, 8](0)
        var u = SIMD[DType.float32, 8](0)
        for z in range(Int(chunks)):
            var base = (z * Int(rows) + 64 * rb + r) * 2 * f + 64 * cb + c
            g += part.load[width=8](base).cast[DType.float32]()
            u += part.load[width=8](base + f).cast[DType.float32]()
        var a = g / (1 + exp(-g)) * u
        var w = bitcast[DType.uint32, 4](a.cast[DType.float16]())
        comptime for e in range(4):
            sb[r * 32 + c // 2 + e] = w[e]
    barrier()
    _block_out(sb, xa, rb, cb, f, t)


def combine[K: Int, ADD: Bool](part: F16, chunks: Int32, rows: Int32, slot: I32, wts: F32, y: F32, count: Int32,
                               d: Int32):
    """y[t, c] = (ADD: y[t, c] +) sum_k wts[t, k] (the down product of t's k-th grouped row, slot[t, k], its chunks
    added in fp32), for the batch's first `count` tokens."""
    var i = global_idx.x
    var n = Int(d)
    if i >= Int(count) * n:
        return
    var t = i // n
    var c = i % n
    var acc = Float32(0)
    comptime for kq in range(K):
        var r = Int(slot[t * K + kq])
        var v = Float32(0)
        for z in range(Int(chunks)):
            v += part[(z * Int(rows) + r) * n + c].cast[DType.float32]()
        acc += wts[t * K + kq] * v
    comptime if ADD:
        y[i] = y[i] + acc
    else:
        y[i] = acc


def sum_parts(part: F16, y: F32, total: Int32, chunks: Int32):
    """y = the sum of the chunks' fp16 partials, in fp32 (total = rows n); 8 values a thread."""
    var e = global_idx.x * 8
    if e >= Int(total):
        return
    var acc = SIMD[DType.float32, 8](0)
    for z in range(Int(chunks)):
        acc += part.load[width=8](z * Int(total) + e).cast[DType.float32]()
    y.store(e, acc)


def sum_parts_add(part: F16, y: F32, total: Int32, chunks: Int32, stride: Int32):
    """y += the sum of the chunks' fp16 partials, in fp32, for y's first `total` values (a residual add); a chunk is
    `stride` values apart (its rows n); 8 values a thread."""
    var e = global_idx.x * 8
    if e >= Int(total):
        return
    var acc = y.load[width=8](e)
    for z in range(Int(chunks)):
        acc += part.load[width=8](z * Int(stride) + e).cast[DType.float32]()
    y.store(e, acc)


# ---- the Adreno 850 (matrix units): K-minor B, one accumulator over the whole K ---------------------------------------
# On the 850 a 16 x 64 B matrix holds column n in lane n and its 16 k in that lane's elements (adrenoblas
# probe/map.comp), so B wants K contiguous inside each column (column-major), A K contiguous inside each row (the R
# tiles): 4 vector loads a lane a K step instead of 16 scalar ones (adreno-gemm-worklog, K-minor tiles). Its matrix
# units round once per 16-deep product, not per multiply-add as the 840's ALUs do, so one fp16 accumulator holds the
# whole K (AdrenoBLAS does the same): no K chunks, and C is written once.


@always_inline
def unpack_wk[BN: Int, T: Int, BKS: Int, RG: Int, ALONG_K: Bool, GS: Int, FMT: Int, LD: Int, SPLIT: Bool = False](
    sb: SH16, wq: U32, ws: F16, wrow0: Int, kb: Int, kk: Int, t: Int, split: Int = 0
):
    """unpack_w with W^T stored K-minor: column c of the K step (W row wrow0 + c) has its BKS k contiguous at
    sb[c LD ..] (LD >= BKS halves, a multiple of 8: padding against bank conflicts). A unit is RG rows x 8 k; each row's
    8 values go to shared memory in one 16-byte store. SPLIT: columns 64 .. take W rows `split` further on (gate|up:
    a workgroup's 64 gate rows, then the matching 64 up rows)."""
    comptime KW = BKS // 8
    comptime UNITS = (BN // RG) * KW
    comptime PER = (UNITS + T - 1) // T
    comptime assert FMT == Q4 or FMT == Q8 or FMT == FP16, "FMT: Q4, Q8 or FP16"
    comptime for i in range(PER):
        var u = i * T + t
        if UNITS % T == 0 or u < UNITS:
            var kw: Int
            var rg: Int
            comptime if ALONG_K:
                kw = u % KW
                rg = u // KW
            else:
                rg = u % (BN // RG)
                kw = u // (BN // RG)
            var r = wrow0 + rg * RG
            comptime if SPLIT:
                if rg * RG >= 64:
                    r += split
            var kx = kb + 8 * kw
            comptime for j in range(RG):
                var h: SIMD[DType.float16, 8]
                comptime if FMT == Q4:
                    var w = wq[(r + j) * (kk // 8) + kx // 8]
                    var s = ws[(r + j) * (kk // GS) + kx // GS]
                    var sh = SIMD[DType.uint32, 8](0, 4, 8, 12, 16, 20, 24, 28)
                    var q = (((SIMD[DType.uint32, 8](w) >> sh) & 15) ^ 8).cast[DType.int32]() - 8
                    h = q.cast[DType.float16]() * SIMD[DType.float16, 8](s)
                elif FMT == Q8:
                    var wv = wq.load[width=2]((r + j) * (kk // 4) + kx // 4)
                    var s = ws[(r + j) * (kk // GS) + kx // GS]
                    var we = SIMD[DType.uint32, 8](wv[0], wv[0], wv[0], wv[0], wv[1], wv[1], wv[1], wv[1])
                    var sh = SIMD[DType.uint32, 8](0, 8, 16, 24, 0, 8, 16, 24)
                    var q = (((we >> sh) & 255) ^ 128).cast[DType.int32]() - 128
                    h = q.cast[DType.float16]() * SIMD[DType.float16, 8](s)
                else:
                    var wv = wq.load[width=4]((r + j) * (kk // 2) + kx // 2)
                    h = bitcast[DType.float16, 8](wv)
                sb.unsafe_store((rg * RG + j) * LD + 8 * kw, h)


comptime LDS = 68  # the epilogues' staging tiles: 64 rows 17 x 8 bytes apart (no bank conflicts), two at a time
comptime STAGE = 2 * 64 * LDS


@always_inline
def sb_size[BN: Int, LD: Int, REG: Bool = False]() -> Int:
    comptime if REG:
        return STAGE
    return BN * LD if BN * LD > STAGE else STAGE


@always_inline
def k_loop[WM: Int, WN: Int, BKS: Int, RG: Int, ALONG_K: Bool, GS: Int, FMT: Int, LD: Int, SPLIT: Bool = False,
           REG: Bool = False, PANEL: Bool = False](
    sb: SH16, xa: F16, wq: U32, ws: F16, kk: Int, row0: Int, colw: Int, sc: Int, t: Int, split: Int = 0
) -> CoopMatrix[DType.float16, 64, 64, ACCUMULATOR]:
    """gemm_k's product: this subgroup's 64 x 64 of X W^T over the whole K (rows row0 .., shared-memory columns sc ..
    of the workgroup's W rows colw ..). REG (int4 only, BKS <= GS): no shared memory; each lane dequantizes its own
    W row (the C column it holds in a B matrix on the 850) in registers, 16 k a B matrix, and builds the matrix with
    CoopMatrix.construct (AdrenoBLAS's Q4_0 kernel: (nibble | 0x6400) - 1032 is exact in fp16, then one rounding by
    the scale)."""
    comptime BN = 64 * WN
    comptime T = 64 * WM * WN
    var abase = xa + (row0 // 64) * (kk // 16) * 1024
    var c0 = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    comptime if REG:
        comptime assert FMT == Q4 and BKS <= GS and BKS >= 16, "REG: int4, 16 <= BKS <= GS"
        var wrow = colw + sc + t % 64
        comptime if SPLIT:
            if sc >= 64:
                wrow += split
        var wp = wq + wrow * (kk // 8)
        var sp = ws + wrow * (kk // GS)
        comptime if PANEL:  # repack_q4's panels: a lane's BKS / 8 words of a K step next to its neighbours'
            var lane = t % 64
            wp = wq + ((wrow // 64) * (kk // BKS) * 64 + lane) * (BKS // 8)
            sp = ws + (wrow // 64) * (kk // GS) * 64 + lane
        var off = SIMD[DType.float16, 2](1032)
        for kb in range(0, kk, BKS):
            var wv: SIMD[DType.uint32, BKS // 8]
            var s2: SIMD[DType.float16, 2]
            comptime if PANEL:
                wv = wp.load[width=BKS // 8]((kb // BKS) * 64 * (BKS // 8))
                s2 = SIMD[DType.float16, 2](sp[(kb // GS) * 64])
            else:
                wv = wp.load[width=BKS // 8](kb // 8)
                s2 = SIMD[DType.float16, 2](sp[kb // GS])
            comptime for st in range(BKS // 16):
                var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(abase + (kb // 16 + st) * 1024, 16)
                var e = SIMD[DType.float16, 16]()
                comptime for h in range(2):
                    var u = wv[2 * st + h] ^ 0x88888888
                    comptime for j in range(4):
                        var x = ((u >> UInt32(4 * j)) & 0x000F000F) | 0x64006400
                        var pr = (bitcast[DType.float16, 2](x) - off) * s2
                        e[8 * h + j] = pr[0]
                        e[8 * h + j + 4] = pr[1]
                var bt = CoopMatrix[DType.float16, 16, 64, MATRIX_B].construct(e)
                c0 = at.multiply_add(bt, c0)
        barrier()
        return c0
    for kb in range(0, kk, BKS):
        unpack_wk[BN, T, BKS, RG, ALONG_K, GS, FMT, LD, SPLIT](sb, wq, ws, colw, kb, kk, t, split)
        barrier()
        comptime for s in range(BKS // 16):
            var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(abase + (kb // 16 + s) * 1024, 16)
            var bt = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(sc * LD + 16 * s), LD)
            c0 = at.multiply_add(bt, c0)
        barrier()
    return c0


def gemm_k[WM: Int, WN: Int, BKS: Int, RG: Int, ALONG_K: Bool, GS: Int = 64, FMT: Int = Q4, PAD: Int = 8,
            REG: Bool = False, PANEL: Bool = False](
    xa: F16, wq: U32, ws: F16, c: F16, n: Int32, k: Int32, rows: Int32
):
    """C (rows x n, fp16) = X W^T on the 850: gemm_hq with B K-minor in shared memory (unpack_wk, loaded column-major)
    and one 64 x 64 fp16 accumulator a subgroup over the whole K. Launch with grid (n / (64 WN), rows / (64 WM)) and
    64 WM WN threads; k a multiple of BKS (and of GS); 64 WN (BKS + PAD) halves of shared memory."""
    comptime BN = 64 * WN
    comptime LD = BKS + PAD
    var sb = stack_allocation[16 if REG else BN * LD, DType.float16, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * 64 * WM + (sg // WN) * 64
    var colw = Int(block_idx.x) * BN
    var sc = (sg % WN) * 64
    var c0 = k_loop[WM, WN, BKS, RG, ALONG_K, GS, FMT, LD, REG=REG, PANEL=PANEL](sb, xa, wq, ws, Int(k), row0, colw,
                                                                                 sc, t)
    var nn = Int(n)
    c0.store(c + row0 * nn + colw + sc, nn)


def gemm_k_add[WM: Int, WN: Int, BKS: Int, RG: Int, ALONG_K: Bool, GS: Int = 64, FMT: Int = Q4, PAD: Int = 8,
                REG: Bool = False, PANEL: Bool = False](
    xa: F16, wq: U32, ws: F16, y: F32, ss: F32, n: Int32, k: Int32, count: Int32
):
    """gemm_k with the residual add fused (AdrenoBLAS's 'a' epilogue): y (rows x n, fp32) += X W^T for rows < count,
    and ss[r (n / 64) + c / 64] = the sum of squares of row r of the updated y over the 64 columns c .. (0 for rows >=
    count), for the next RMSNorm (l85.norm_pack_ss). The accumulators go through shared memory two subgroups at a
    time; then every thread of the workgroup takes 4 columns of a staged row (16 threads a row: y read and written
    256 bytes at a time) and the row's sum of squares is reduced in shared memory."""
    comptime BN = 64 * WN
    comptime LD = BKS + PAD
    comptime T = 64 * WM * WN
    comptime NR = (WM * WN + 1) // 2  # rounds of two staged tiles
    comptime TILES = 2 if WM * WN > 1 else 1
    comptime ITER = TILES * 64 * 16 // T  # staged rows x 16 column groups, T at a time
    var sb = stack_allocation[sb_size[BN, LD, REG](), DType.float16, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[T, DType.float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * 64 * WM + (sg // WN) * 64
    var colw = Int(block_idx.x) * BN
    var sc = (sg % WN) * 64
    var c0 = k_loop[WM, WN, BKS, RG, ALONG_K, GS, FMT, LD, REG=REG, PANEL=PANEL](sb, xa, wq, ws, Int(k), row0, colw,
                                                                                 sc, t)
    var nn = Int(n)
    var cnt = Int(count)
    comptime for rd in range(NR):
        if sg // 2 == rd:
            c0.store(sb.unsafe_offset((sg % 2) * 64 * LDS), LDS)
        barrier()
        comptime for it in range(ITER):
            var e = it * T + t  # (staged row, column group of 4)
            var tr = e // 16
            var cg = (e % 16) * 4
            var s2 = 2 * rd + tr // 64  # the subgroup whose tile this row is
            var r = Int(block_idx.y) * 64 * WM + (s2 // WN) * 64 + tr % 64
            var col = colw + (s2 % WN) * 64 + cg
            var part = Float32(0)
            if r < cnt:
                var v = y.load[width=4](r * nn + col) + sb.load[width=4](tr * LDS + cg).cast[DType.float32]()
                y.store(r * nn + col, v)
                part = (v * v).reduce_add()
            red[t] = part
            barrier()
            if t % 16 == 0:
                var tot = Float32(0)
                comptime for j in range(16):
                    tot += red[t + j]
                ss[r * (nn // 64) + col // 64] = tot
            barrier()


def gemm_k_swiglu[WM: Int, BKS: Int, RG: Int, ALONG_K: Bool, GS: Int = 64, FMT: Int = Q4, PAD: Int = 8,
                   REG: Bool = False, PANEL: Bool = False](
    xa: F16, wq: U32, ws: F16, xo: U32, f: Int32, k: Int32
):
    """gate|up with SwiGLU fused (AdrenoBLAS's 'g' epilogue, without interleaving the weights): a workgroup of WM x 2
    subgroups takes gate rows 64 block_idx.x .. and the matching up rows (f further on, W = [gate; up]), subgroup
    column 0 the gate, 1 the up; silu(gate) up goes to xo as R tiles with k = f (the down product's X). Grid
    (f / 64, rows / (64 WM)), 128 WM threads."""
    comptime BN = 128
    comptime LD = BKS + PAD
    var sb = stack_allocation[sb_size[BN, LD, REG](), DType.float16, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var sg = t // 64
    var l = t % 64
    var row0 = Int(block_idx.y) * 64 * WM + (sg // 2) * 64
    var colw = Int(block_idx.x) * 64
    var sc = (sg % 2) * 64
    var ff = Int(f)
    var c0 = k_loop[WM, 2, BKS, RG, ALONG_K, GS, FMT, LD, True, REG, PANEL](sb, xa, wq, ws, Int(k), row0, colw, sc,
                                                                            t, ff - 64)
    comptime for rd in range(WM):
        if sg // 2 == rd:
            c0.store(sb.unsafe_offset((sg % 2) * 64 * LDS), LDS)
        barrier()
        if sg // 2 == rd:  # the gate subgroup's lanes take columns 0 .. 31 of their row, the up subgroup's 32 .. 63
            var cb = (sg % 2) * 32
            var dst = xo + (r_tile(row0 + l, colw + cb, ff)) // 2
            comptime for tl in range(2):
                comptime for hh in range(2):
                    var o = cb + 16 * tl + 8 * hh
                    var g = sb.load[width=8](l * LDS + o).cast[DType.float32]()
                    var u = sb.load[width=8](64 * LDS + l * LDS + o).cast[DType.float32]()
                    var a = g / (1 + exp(-g)) * u
                    var w = bitcast[DType.uint32, 4](a.cast[DType.float16]())
                    comptime for e in range(4):
                        dst[tl * 512 + hh * 4 + e] = w[e]
        barrier()


def repack_q4[CKW: Int, GS: Int = 64](wq: U32, ws: F16, wp: U32, sp: F16, n: Int32, k: Int32, perm: Int32 = 0,
                                     hd: Int32 = 128):
    """int4 rows (n x k / 8 words, a scale per GS) -> AdrenoBLAS-style panels for k_loop's REG + PANEL path: per
    64-row panel and K step of 8 CKW, the 64 rows' CKW words side by side ([n / 64][k / (8 CKW)][64][CKW]); scales
    [n / 64][k / GS][64]. A thread per (row, K step); one-time, at load."""
    var i = global_idx.x
    var kk = Int(k)
    var steps = kk // (8 * CKW)
    if i >= Int(n) * steps:
        return
    var r = i // steps
    var st = i % steps
    var src = r  # perm: the first `perm` rows, heads of hd, in the order 0, hd / 2, 1, hd / 2 + 1, .. of each head
    if r < Int(perm):
        var d = Int(hd)
        src = (r // d) * d + (r % d) // 2 + (d // 2) * (r % 2)
    var dst = ((r // 64) * steps + st) * 64 * CKW + (r % 64) * CKW
    comptime for j in range(CKW):
        wp[dst + j] = wq[src * (kk // 8) + st * CKW + j]
    comptime if GS % (8 * CKW) == 0:
        if (st * 8 * CKW) % GS == 0:
            var g = st * 8 * CKW // GS
            sp[((r // 64) * (kk // GS) + g) * 64 + r % 64] = ws[src * (kk // GS) + g]


def gemm_k_rope[WM: Int, WN: Int, BKS: Int, GS: Int = 64, REG: Bool = True, PANEL: Bool = True, PAD: Int = 8,
                 HD: Int = 128](
    xa: F16, wq: U32, ws: F16, qt: U32, kt: U32, vt: U32, kc: F32, vc: F32, cos: F32, sin: F32, h: Int32,
    kvh: Int32, k: Int32, rows: Int32, scale: Float32
):
    """The prompt's q|k|v product with RoPE and the attention layouts in the epilogue (AdrenoBLAS's qkv_rope kernel).
    W's q and k rows come permuted to 0, 64, 1, 65, .. within each 128-wide head (repack_q4's perm), so each 64-column
    tile holds 32 whole rotation pairs (dims i and i + 64 side by side) and each subgroup finishes its own tile: q
    (rotated, scaled) and k (rotated) go to l85's tiles in the permuted dim order (q k^T is the same) and k also to
    the fp32 cache in the true order; v (rows unpermuted) is staged column-major, so lane d reads its dim's 64
    positions contiguously, and goes to the V^T tiles and the fp32 cache. Two subgroups stage at a time. rows: the
    padded prompt (M). Grid ((h + 2 kvh) 128 / (64 WN), rows / (64 WM)), 64 WM WN threads; head dim 128."""
    comptime BN = 64 * WN
    comptime LD = BKS + PAD
    comptime HALF = HD // 2
    comptime assert HD == 64 or HD == 128, "gemm_k_rope: head dim 64 or 128"
    var sb = stack_allocation[sb_size[BN, LD, REG](), DType.float16, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var sg = t // 64
    var l = t % 64
    var row0 = Int(block_idx.y) * 64 * WM + (sg // WN) * 64
    var colw = Int(block_idx.x) * BN
    var sc = (sg % WN) * 64
    var c0 = k_loop[WM, WN, BKS, 1, True, GS, Q4, LD, REG=REG, PANEL=PANEL](sb, xa, wq, ws, Int(k), row0, colw, sc, t)
    comptime assert WN == 1 or WN == 2, "gemm_k_rope: a workgroup within one kind of head (q, k or v)"
    var nh = Int(h)
    var nkv = Int(kvh)
    var M = Int(rows)
    var col0 = colw + sc
    # The workgroup's kind of head decides the epilogue (uniform: the two epilogues must not share a store, or LLVM
    # merges the two matrix stores into one with a run-time layout, which SPIR-V forbids); hh: this subgroup's head.
    var kind = colw // HD
    var hh = col0 // HD
    var half = (col0 % HD) // 64
    var st = (sg % 2) * 64 * LDS
    if kind >= nh + nkv:  # v: staged column-major; lane = dim d, its 64 positions are row l of the stage
        var g = hh - nh - nkv
        var d = 64 * half + l
        var vb = g * HD * M
        comptime for rd in range((WM * WN + 1) // 2):
            if sg // 2 == rd:
                c0.store[row_major=False](sb.unsafe_offset(st), LDS)
            barrier()
            if sg // 2 == rd:
                comptime for r4 in range(4):
                    var v = sb.load[width=16](st + l * LDS + 16 * r4)
                    var vf = v.cast[DType.float32]()
                    comptime for e in range(16):
                        vc[(row0 + 16 * r4 + e) * nkv * HD + g * HD + d] = vf[e]
                    var w = bitcast[DType.uint32, 8](v)
                    var ev = (vb + r_tile(d, row0 + 16 * r4, M)) // 2
                    comptime for e in range(8):
                        vt[ev + e] = w[e]
            barrier()
    else:  # q or k: lane = position; 16 permuted columns (8 rotation pairs) at a time
        var isq = kind < nh
        var g = hh if isq else hh - nh
        var base = g * M * HD
        var dt = qt if isq else kt
        comptime for rd in range((WM * WN + 1) // 2):
            if sg // 2 == rd:
                c0.store(sb.unsafe_offset(st), LDS)
            barrier()
            if sg // 2 == rd:
                var pos = row0 + l
                comptime for j in range(4):
                    var x = sb.load[width=16](st + l * LDS + 16 * j).cast[DType.float32]()
                    var ab = x.deinterleave()
                    var a = ab[0]
                    var b = ab[1]
                    var i = 32 * half + 8 * j  # the pairs' true dims i .. i + 7 (and + HALF)
                    var c = cos.load[width=8](pos * HALF + i)
                    var s = sin.load[width=8](pos * HALF + i)
                    var ra = a * c - b * s
                    var rb = b * c + a * s
                    if isq:
                        ra *= scale
                        rb *= scale
                    else:
                        var dst = pos * nkv * HD + g * HD + i
                        kc.store(dst, ra)
                        kc.store(dst + HALF, rb)
                    var w = bitcast[DType.uint32, 8](ra.interleave(rb).cast[DType.float16]())
                    var e0 = (base + r_tile(pos, 64 * half + 16 * j, HD)) // 2
                    comptime for e in range(8):
                        dt[e0 + e] = w[e]
            barrier()


def gemm_kg[WN: Int, BKS: Int, GS: Int = G, FMT: Int = Q4, PAD: Int = 8](
    xa: F16, wq: U32, ws: F16, part: F16, n: Int32, k: Int32, rows: Int32, tiles: I32, ntiles: I32
):
    """gemm_hqg on the 850: the grouped products (work tile block y = (expert e, grouped rows r0 .. r0 + 63) times
    expert e's rows e n ..) with gemm_k's product: B K-minor in shared memory, one fp16 accumulator over the whole K,
    so part holds one chunk. Grid (n / (64 WN), the most tiles), 64 WN threads."""
    var it = Int(block_idx.y)
    if it >= Int(ntiles[0]):
        return
    comptime BN = 64 * WN
    comptime LD = BKS + PAD
    var sb = stack_allocation[BN * LD, DType.float16, address_space=AddressSpace.SHARED]()
    var e = Int(tiles[2 * it])
    var row0 = Int(tiles[2 * it + 1])
    var nn = Int(n)
    var t = Int(thread_idx.x)
    var sc = (t // 64) * 64
    var colw = Int(block_idx.x) * BN
    var c0 = k_loop[1, WN, BKS, 1, True, GS, FMT, LD](sb, xa, wq, ws, Int(k), row0, e * nn + colw, sc, t)
    c0.store(part + row0 * nn + colw + sc, nn)
