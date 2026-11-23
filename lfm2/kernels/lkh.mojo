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
#      along N, a K step at a time, with no fp16 copy of W at all.
# The 840 rounds every partial sum of an fp16 cooperative product to fp16 (2.7% error over 4096 products), so K is split
# into chunks of CH: grid z = chunk, each writing its fp16 partial C, and sum_parts adds them in fp32.
#
# gemm_hq needs the fork's SPIR-V backend from 2026-11-23 or later: before, it addressed shared arrays with
# OpInBoundsAccessChain, which the 840's driver resolves for 16-bit types as if each element took twice its size (every
# other half of a tile written with plain stores went missing); it now emits OpAccessChain, and types a shared array of
# halves written 8 bytes at a time as <4 x half> (one store per 4 halves). See coopmat/smem_pack.mojo.
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime F32 = UnsafePointer[Float32, MutAnyOrigin]
comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
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


def gemm_hq[WM: Int, WN: Int, CH: Int, BKS: Int, RG: Int, ALONG_K: Bool](
    xa: F16, wq: U32, ws: F16, part: F16, n: Int32, k: Int32, rows: Int32
):
    """part[z] (rows x n, fp16) = X[:, z CH .. z CH + CH] W[:, same]^T with W unpacked from lk's int4 rows inside the
    product: a workgroup of WM x WN subgroups, each computing 64 x 64 of C, unpacks the workgroup's BKS x 64 WN slice of
    W^T into shared memory (fp16, rows along N) a K step at a time, then each subgroup multiplies its A tiles (loaded
    from xa's R tiles) by its 16 x 64 B tiles from shared memory. An unpack unit is RG rows of W x 8 k (one word a row):
    RG fp16 scale and word loads, then 8 stores of RG halves (one k each, along N). Neighbouring threads take
    neighbouring words of the same rows (ALONG_K: the loads coalesce) or neighbouring rows (the stores do). Launch with
    grid (n / (64 WN), rows / (64 WM), ceil(k / CH)) and 64 WM WN threads; CH and k multiples of BKS."""
    comptime BN = 64 * WN
    comptime T = 64 * WM * WN
    comptime KW = BKS // 8  # words of a row a K step
    comptime UNITS = (BN // RG) * KW
    comptime PER = (UNITS + T - 1) // T
    var sb = stack_allocation[BKS * BN, DType.float16, address_space=AddressSpace.SHARED]()
    var kk = Int(k)
    var nn = Int(n)
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * 64 * WM + (sg // WN) * 64
    var colw = Int(block_idx.x) * BN
    var sc = (sg % WN) * 64
    var k_lo = Int(block_idx.z) * CH
    var k_hi = min(k_lo + CH, kk)
    var abase = xa + (row0 // 64) * (kk // 16) * 1024
    var c0 = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    for kb in range(k_lo, k_hi, BKS):
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
                var r = colw + rg * RG  # the first row of W (column of C)
                var kx = kb + 8 * kw
                var w = SIMD[DType.uint32, RG]()
                var sv = SIMD[DType.float16, RG]()
                comptime for j in range(RG):
                    w[j] = wq[(r + j) * (kk // 8) + kx // 8]
                    sv[j] = ws[(r + j) * (kk // G) + kx // G]
                comptime for e in range(8):
                    var q = (((w >> UInt32(4 * e)) & 15) ^ 8).cast[DType.int32]() - 8
                    sb.unsafe_store((8 * kw + e) * BN + rg * RG, q.cast[DType.float16]() * sv)
        barrier()
        comptime for s in range(BKS // 16):
            var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(abase + (kb // 16 + s) * 1024, 16)
            var bt = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load(sb.unsafe_offset(16 * s * BN + sc), BN)
            c0 = at.multiply_add(bt, c0)
        barrier()
    c0.store(part + Int(block_idx.z) * Int(rows) * nn + row0 * nn + colw + sc, nn)


def sum_parts(part: F16, y: F32, total: Int32, chunks: Int32):
    """y = the sum of the chunks' fp16 partials, in fp32 (total = rows n); 8 values a thread."""
    var e = global_idx.x * 8
    if e >= Int(total):
        return
    var acc = SIMD[DType.float32, 8](0)
    for z in range(Int(chunks)):
        acc += part.load[width=8](z * Int(total) + e).cast[DType.float32]()
    y.store(e, acc)
