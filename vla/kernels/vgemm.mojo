# Y = act(X) W^T for the vision-language-action models (vla/): one kernel for every projection of
# SigLIP, the language backbone and the action expert, on the 840's fp32 cooperative matrices
# (64 x 64 x 8). X: fp32 rows (ldx apart), W: n x k in its checkpoint's type, read as rows ldw apart:
# bf16 (as uint16 bits, widened exactly), fp16 or fp32. Options, all comptime:
#   ACT       applied to X as it is staged: GELU (tanh form), SILU, SILU_MUL, silu(x) * the value xoff
#             further along the row (a row of gate | up), or GELU_MUL, gelu(x) * that value (Gemma's GeGLU).
#   BIAS      + bias[col] (fp32): one more k step, with X's column 1 and W's column the bias. The 840's driver
#             cannot create a pipeline whose accumulator starts as a loaded matrix, so the bias and the
#             residual go through the multiply-add instead.
#   RES       Y += ...: Y's tile is added as identity x Y (eight 64 x 64 x 8 steps), then stored over it.
# alpha scales X. A workgroup of WM x WN subgroups computes a (64 WM) x (64 WN) block of Y; per k step of 16
# it stages X's and W's slices, widened to fp32, in shared memory, as llama/kernels/prefill/p_gemm does.
# n needs no rounding: W's rows past n stage as zeros, and subgroups whose 64 columns start at or past n
# (rounded up to 64) store nothing, so Y needs ldy >= n rounded up to 64, and its columns from n to that
# get zeros. k: a multiple of 4 (slices past k stage as zeros); Y's and X's rows: a multiple of 64 WM (the
# padding rows finite).
# One accumulator a subgroup and 16 KB of shared memory, as the 840's driver needs.
from std.math import exp
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime F32P = UnsafePointer[Float32, MutAnyOrigin]
comptime NONE = 0
comptime GELU = 1
comptime SILU = 2
comptime SILU_MUL = 3
comptime GELU_MUL = 4
comptime BK = 16
comptime KC = 8  # the 840's fp32 product: 64 x 64 x 8
comptime SHARED = 4096  # floats, 16 KB: the X and W slices, then the residual's 64 x 64 identity


@always_inline
def widen[WT: DType, width: SIMDLength](v: SIMD[WT, width]) -> SIMD[DType.float32, width]:
    """Weights to fp32: bf16 (uint16 bits) by a shift, exactly; fp16 and fp32 by conversion."""
    comptime if WT == DType.uint16:
        return bitcast[DType.float32, width](v.cast[DType.uint32]() << 16)
    else:
        return v.cast[DType.float32]()


@always_inline
def widen1[WT: DType](v: Scalar[WT]) -> Float32:
    return widen[WT, 1](v)[0]


@always_inline
def gelu_tanh[width: SIMDLength](x: SIMD[DType.float32, width]) -> SIMD[DType.float32, width]:
    """gelu_pytorch_tanh: 0.5 x (1 + tanh(sqrt(2 / pi) (x + 0.044715 x^3))), tanh through exp."""
    var u = Float32(0.7978845608028654) * (x + Float32(0.044715) * x * x * x)
    return Float32(0.5) * x * (2 - 2 / (exp(2 * u) + 1))


@always_inline
def silu[width: SIMDLength](x: SIMD[DType.float32, width]) -> SIMD[DType.float32, width]:
    return x / (1 + exp(-x))


def gemm[WT: DType, WM: Int, WN: Int, ACT: Int, BIAS: Bool, RES: Bool, SPLIT: Bool = False](
    x: F32P, w: UnsafePointer[Scalar[WT], MutAnyOrigin], bias: F32P, y: F32P,
    n: Int32, k: Int32, ldx: Int32, ldw: Int32, ldy: Int32, xoff: Int32, alpha: Float32, kc: Int32, plane: Int32,
):
    """Launch with grid (ceil(n / (64 WN)), rows / (64 WM)) and block 64 WM WN. SPLIT (split-k, for long k and
    few blocks): grid z splits k into ranges of kc (a multiple of 16), and workgroup z writes its partial product
    to plane z of y (plane floats apart), for reduce_sk to sum with the bias and the residual."""
    comptime assert not SPLIT or (not BIAS and not RES), "split-k: reduce_sk adds the bias and the residual"
    comptime BM = WM * 64
    comptime BN = WN * 64
    comptime THREADS = WM * WN * 64
    comptime assert (BM + BN) * BK <= SHARED, "the slices fit the shared buffer"
    var sh = stack_allocation[SHARED, Float32, address_space=AddressSpace.SHARED]()
    var sa = sh  # X: BM rows of BK
    var sb = sh.unsafe_offset(BM * BK)  # W: BN rows of BK (B = W^T, read column-major)
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * BM
    var col0 = Int(block_idx.x) * BN
    var sr = (sg // WN) * 64  # this subgroup's tile of the block
    var sc = (sg % WN) * 64
    var nn = Int(n)
    var kk_ = Int(k)
    var lx = Int(ldx)
    var lw = Int(ldw)
    var ly = Int(ldy)
    var live = col0 + sc < (nn + 63) // 64 * 64  # the same for the whole subgroup
    var kb = 0
    comptime if SPLIT:
        kb = Int(block_idx.z) * Int(kc)
        kk_ = min(kk_, kb + Int(kc))
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for k0 in range(kb, kk_, BK):
        comptime for i in range(BM * BK // 4 // THREADS):
            var v = i * THREADS + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            var xi = (row0 + r) * lx + k0 + c
            var xv = SIMD[DType.float32, 4](0)
            if k0 + c < kk_:
                xv = x.unsafe_load[width=4](xi)
                comptime if ACT == GELU:
                    xv = gelu_tanh(xv)
                elif ACT == SILU:
                    xv = silu(xv)
                elif ACT == SILU_MUL:
                    xv = silu(xv) * x.unsafe_load[width=4](xi + Int(xoff))
                elif ACT == GELU_MUL:
                    xv = gelu_tanh(xv) * x.unsafe_load[width=4](xi + Int(xoff))
            sa.unsafe_store(r * BK + c, xv * alpha)
        comptime for i in range(BN * BK // 4 // THREADS):
            var v = i * THREADS + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            var wv = SIMD[DType.float32, 4](0)
            if col0 + r < nn and k0 + c < kk_:
                wv = widen(w.unsafe_load[width=4]((col0 + r) * lw + k0 + c))
            sb.unsafe_store(r * BK + c, wv)
        barrier()
        comptime for kk in range(0, BK, KC):
            var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sa.unsafe_offset(sr * BK + kk), BK)
            var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(sc * BK + kk), BK)
            acc = at.multiply_add(bt, acc)
        barrier()
    comptime if BIAS:  # one more k step: X's column of ones times W's column of the bias
        comptime for i in range(BM * BK // 4 // THREADS):
            var v = i * THREADS + t
            var c = v % (BK // 4) * 4
            var one = SIMD[DType.float32, 4](0)
            if c == 0:
                one[0] = 1
            sa.unsafe_store((v // (BK // 4)) * BK + c, one)
        comptime for i in range(BN * BK // 4 // THREADS):
            var v = i * THREADS + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            var bv = SIMD[DType.float32, 4](0)
            if c == 0 and col0 + r < nn:
                bv[0] = bias[col0 + r]
            sb.unsafe_store(r * BK + c, bv)
        barrier()
        var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sa.unsafe_offset(sr * BK), BK)
        var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](sb.unsafe_offset(sc * BK), BK)
        acc = at.multiply_add(bt, acc)
        barrier()
    comptime if RES:  # the 64 x 64 identity, row-major
        comptime for i in range(64 * 64 // THREADS):
            var v = i * THREADS + t
            var one = Float32(0)
            if v // 64 == v % 64:
                one = 1
            sh[v] = one
        barrier()
    if live:
        var out = y.unsafe_offset((row0 + sr) * ly + col0 + sc)
        comptime if SPLIT:
            out = out.unsafe_offset(Int(block_idx.z) * Int(plane))
        comptime if RES:
            comptime for kk in range(0, 64, KC):
                var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sh.unsafe_offset(kk), 64)
                var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load(out.unsafe_offset(kk * ly), ly)
                acc = at.multiply_add(bt, acc)
        acc.store(out, ly)


comptime F16P = UnsafePointer[Float16, MutAnyOrigin]
comptime KH = 16  # the 840's fp16 product: 64 x 64 x 16, summed in fp16


def to_half[ACT: Int](x: F32P, xh: F16P, k: Int32, ldx: Int32, xoff: Int32, alpha: Float32, total: Int32):
    """xh (rows x k, packed) = act(alpha x) in fp16: the input of gemm16, as gemm stages it."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var kk = Int(k)
    var xi = (e // kk) * Int(ldx) + e % kk
    var v = SIMD[DType.float32, 1](x[xi])
    comptime if ACT == GELU:
        v = gelu_tanh(v)
    elif ACT == SILU:
        v = silu(v)
    elif ACT == SILU_MUL:
        v = silu(v) * x[xi + Int(xoff)]
    elif ACT == GELU_MUL:
        v = gelu_tanh(v) * x[xi + Int(xoff)]
    xh[e] = (v[0] * alpha).cast[DType.float16]()


def gemm16[WM: Int, WN: Int](x: F16P, w: F16P, y: F16P, n: Int32, k: Int32, ldy: Int32):
    """gemm on the 840's fp16 matrix units: Y = X W^T with X (rows x k), W (n x k, its rows zero-padded to a
    multiple of 64 WN) and Y all fp16, every product and running sum in fp16. X and W are read straight from
    memory (fp16 elements of shared memory are addressed wrongly by the 840's driver). finish16 adds the bias
    and the residual in fp32: converting the accumulator to fp32 in this kernel crashes the driver's compiler.
    Launch as gemm."""
    comptime BN = WN * 64
    var sg = Int(thread_idx.x) // 64
    var row0 = Int(block_idx.y) * WM * 64
    var col0 = Int(block_idx.x) * BN
    var sr = (sg // WN) * 64
    var sc = (sg % WN) * 64
    var kk_ = Int(k)
    var acc = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
    var xa = x.unsafe_offset((row0 + sr) * kk_)
    var wb = w.unsafe_offset((col0 + sc) * kk_)
    for k0 in range(0, kk_, KH):
        var at = CoopMatrix[DType.float16, 64, KH, MATRIX_A].load(xa.unsafe_offset(k0), kk_)
        var bt = CoopMatrix[DType.float16, KH, 64, MATRIX_B].load[row_major=False](wb.unsafe_offset(k0), kk_)
        acc = at.multiply_add(bt, acc)
    if col0 + sc < (Int(n) + 63) // 64 * 64:
        acc.store(y.unsafe_offset((row0 + sr) * Int(ldy) + col0 + sc), Int(ldy))


def finish16[BIAS: Bool, RES: Bool](yh: F16P, bias: F32P, y: F32P, n: Int32, ldy: Int32, total: Int32):
    """y = yh in fp32 (+ bias) (+ y), for gemm16's output (rows x n, ldy apart)."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var c = e % Int(n)
    var i = (e // Int(n)) * Int(ldy) + c
    var v = yh[i].cast[DType.float32]()
    comptime if BIAS:
        v += bias[c]
    comptime if RES:
        v += y[i]
    y[i] = v


def act_rows[ACT: Int](x: F32P, y: F32P, k: Int32, ldx: Int32, xoff: Int32, total: Int32):
    """y (rows x k, packed) = act(x): the input of gemm_sk, which reads X straight from memory."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var kk = Int(k)
    var xi = (e // kk) * Int(ldx) + e % kk
    var v = SIMD[DType.float32, 1](x[xi])
    comptime if ACT == GELU:
        v = gelu_tanh(v)
    elif ACT == SILU:
        v = silu(v)
    elif ACT == SILU_MUL:
        v = silu(v) * x[xi + Int(xoff)]
    elif ACT == GELU_MUL:
        v = gelu_tanh(v) * x[xi + Int(xoff)]
    y[e] = v[0]


def gemm_sk[WT: DType, WN: Int, XG: Bool = True, DB: Bool = True](
    x: F32P, w: UnsafePointer[Scalar[WT], MutAnyOrigin], p: F32P, n: Int32, k: Int32, ldx: Int32, ldw: Int32,
    kc: Int32, ldp: Int32, plane: Int32,
):
    """Split-k Y = X W^T for short X (the expert's 64 rows, the prefix's 256): workgroup (x, y, z) computes the
    64 x (64 WN) block (y, x) of Y over k from z kc to (z + 1) kc, into partial plane z of p (rows x ldp, plane
    floats apart); reduce_sk sums the planes. XG: X read straight from memory as matrix tiles (else staged);
    DB: W's slices of 16 k, widened to fp32, alternate between two shared buffers, the next one fetched into
    registers while this one is multiplied, one barrier a step. Launch with grid (ceil(n / (64 WN)),
    rows / 64, splits) and block 64 WN. kc: a multiple of 16."""
    comptime BN = WN * 64
    comptime THREADS = WN * 64
    comptime WV = BN * BK // 4 // THREADS  # W's slice in four-value loads, per thread
    comptime XV = 64 * BK // 4 // THREADS
    comptime NB = 2 if DB else 1
    var sh = stack_allocation[NB * BN * BK + 64 * BK, Float32, address_space=AddressSpace.SHARED]()
    var sb = sh
    var sa = sh.unsafe_offset(NB * BN * BK)
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * 64
    var col0 = Int(block_idx.x) * BN
    var sc = sg * 64
    var nn = Int(n)
    var lx = Int(ldx)
    var lw = Int(ldw)
    var kb = Int(block_idx.z) * Int(kc)
    var ke = min(Int(k), kb + Int(kc))
    var xa = x.unsafe_offset(row0 * lx)
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    var buf = 0
    for k0 in range(kb, ke, BK):
        var base = buf * BN * BK
        comptime for i in range(WV):
            var v = i * THREADS + t
            var row = v // (BK // 4)
            var wv = SIMD[DType.float32, 4](0)
            if col0 + row < nn and k0 + v % (BK // 4) * 4 < ke:
                wv = widen(w.unsafe_load[width=4]((col0 + row) * lw + k0 + v % (BK // 4) * 4))
            sb.unsafe_store(base + row * BK + v % (BK // 4) * 4, wv)
        comptime if not XG:
            comptime for i in range(XV):
                var v = i * THREADS + t
                var r = v // (BK // 4)
                var c = v % (BK // 4) * 4
                sa.unsafe_store(r * BK + c, xa.unsafe_load[width=4](r * lx + k0 + c))
        barrier()
        comptime for kk in range(0, BK, KC):
            var at: CoopMatrix[DType.float32, 64, KC, MATRIX_A]
            comptime if XG:
                at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(xa.unsafe_offset(k0 + kk), lx)
            else:
                at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sa.unsafe_offset(kk), BK)
            var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(base + sc * BK + kk), BK)
            acc = at.multiply_add(bt, acc)
        comptime if DB:
            buf = 1 - buf
        else:
            barrier()
    if col0 + sc < (nn + 63) // 64 * 64:
        acc.store(p.unsafe_offset(Int(block_idx.z) * Int(plane) + row0 * Int(ldp) + col0 + sc), Int(ldp))


def reduce_sk[BIAS: Bool, RES: Bool](
    p: F32P, bias: F32P, y: F32P, splits: Int32, n: Int32, ldp: Int32,
    plane: Int32, ldy: Int32, alpha: Float32, total: Int32,
):
    """y = alpha (the sum of gemm_sk's planes) (+ bias) (+ y), for rows x n."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var r = e // Int(n)
    var c = e % Int(n)
    var pi = r * Int(ldp) + c
    var v = p[pi]
    for s in range(1, Int(splits)):
        v += p[s * Int(plane) + pi]
    v *= alpha
    comptime if BIAS:
        v += bias[c]
    var yi = r * Int(ldy) + c
    comptime if RES:
        v += y[yi]
    y[yi] = v
