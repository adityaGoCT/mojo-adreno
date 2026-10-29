# Bonsai 2 2B batched prefill: all prompt tokens at once, from position 0 (zero state), built for
# the Adreno 840 (--target-accelerator adreno840).
#
# Most kernels here are the decode kernels of kernels.mojo, unchanged, run for every prompt row at
# once: the grid's second dimension is the row, and each wrapper offsets that row's pointers by
# block_idx.y and calls the decode kernel, whose global_idx.x then indexes within the row exactly as
# in decode (positions are the row numbers). New here:
#   p_gemm_t2     the packed ternary projections as fp32 cooperative-matrix products
#   p_conv        the causal depthwise conv over all rows, leaving the last three in the history
#   p_delta_scan  the DeltaNet recurrence over all rows, each thread's state slice in registers
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.primitives.warp import shuffle_xor
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR
import kernels

comptime F32 = Pointer[Float32, MutAnyOrigin]


def p_embedding(w: Pointer[UInt32, MutAnyOrigin], params: Pointer[Float16, MutAnyOrigin],
                tokens: Pointer[Int32, MutAnyOrigin], y: F32):
    var row = Int(block_idx.y)
    kernels.embedding(w, params, y.unsafe_offset(row * 2048), tokens[unsafe_offset=row])


def p_hadamard(x: F32, signs: F32, y: F32, q: Pointer[UInt32, MutAnyOrigin], width: Int32, inverse: Int32):
    var row = Int(block_idx.y) * Int(width)
    kernels.hadamard(x.unsafe_offset(row), signs, y.unsafe_offset(row), q.unsafe_offset(row // 2), width, 0,
                     inverse)


def p_rms_partials(x: F32, partials: F32):
    var row = Int(block_idx.y)
    kernels.rms_partials(x.unsafe_offset(row * 2048), partials.unsafe_offset(row * 32))


def p_rms_norm(x: F32, w: F32, y: F32, partials: F32):
    var row = Int(block_idx.y)
    kernels.rms_norm(x.unsafe_offset(row * 2048), w, y.unsafe_offset(row * 2048), partials.unsafe_offset(row * 32))


def p_gate_partials(x: F32, a: F32, b: F32, partials: F32):
    var row = Int(block_idx.y)
    kernels.gate_partials(x.unsafe_offset(row * 2048), a, b, partials.unsafe_offset(row * 1024))


def p_delta_gates(partials: F32, constants: F32, y: F32):
    var row = Int(block_idx.y)
    kernels.delta_gates(partials.unsafe_offset(row * 1024), constants, y.unsafe_offset(row * 32))


def p_normalize_qk(x: F32, y: F32):
    var row = Int(block_idx.y)
    kernels.normalize_qk(x.unsafe_offset(row * 6144), y.unsafe_offset(row * 6144))


def p_gated_norm(x: F32, z: F32, w: F32, y: F32):
    var row = Int(block_idx.y) * 2048
    kernels.gated_norm(x.unsafe_offset(row), z.unsafe_offset(row), w, y.unsafe_offset(row))


def p_head_norm(x: F32, w: F32, y: F32, mode: Int32):
    # mode 0: queries (4096 a row, query and gate per head) -> 2048; mode 1: keys, 512 -> 512
    var row = Int(block_idx.y)
    var xs = 4096 if mode == 0 else 512
    var ys = 2048 if mode == 0 else 512
    kernels.head_norm(x.unsafe_offset(row * xs), w, y.unsafe_offset(row * ys), mode)


def p_rope(x: F32, table: F32, width: Int32):
    var row = Int(block_idx.y)
    kernels.rope(x.unsafe_offset(row * Int(width)), table, width, Int32(row))


def p_cache_kv(k: F32, v: F32, kc: F32, vc: F32):
    var row = Int(block_idx.y)
    kernels.cache_kv(k.unsafe_offset(row * 512), v.unsafe_offset(row * 512), kc, vc, Int32(row))


def p_attention_scores(q: F32, kc: F32, y: F32, capacity: Int32):
    var row = Int(block_idx.y)
    kernels.attention_scores(q.unsafe_offset(row * 2048), kc, y.unsafe_offset(row * 8 * Int(capacity)), Int32(row),
                             capacity)


def p_attention_values(scores: F32, vc: F32, qg: F32, y: F32, capacity: Int32):
    var row = Int(block_idx.y)
    kernels.attention_values(scores.unsafe_offset(row * 8 * Int(capacity)), vc, qg.unsafe_offset(row * 4096),
                             y.unsafe_offset(row * 2048), Int32(row), capacity)


def p_residual(x: F32, y: F32):
    var row = Int(block_idx.y) * 2048
    kernels.residual(x.unsafe_offset(row), y.unsafe_offset(row))


def p_swiglu(gate: F32, up: F32):
    var row = Int(block_idx.y) * 6144
    kernels.swiglu(gate.unsafe_offset(row), up.unsafe_offset(row))


def p_conv(x: F32, w: F32, history: F32, y: F32, count: Int32):
    """kernels.convolve for every row: earlier rows instead of the history (zero before the prompt);
    the last three rows become the history the decode steps continue from."""
    var row = Int(block_idx.y)
    var c = global_idx.x
    if c < 6144:
        var value = x[unsafe_offset=row * 6144 + c] * w[unsafe_offset=3 * 6144 + c]
        for t in range(3):
            if row - 3 + t >= 0:
                value += x[unsafe_offset=(row - 3 + t) * 6144 + c] * w[unsafe_offset=t * 6144 + c]
        y[unsafe_offset=row * 6144 + c] = value * kernels.sigmoid(value)
        var n = Int(count)
        if row >= n - 3:
            history[unsafe_offset=(row - n + 3) * 6144 + c] = x[unsafe_offset=row * 6144 + c]


def p_delta_scan(qkv: F32, gates: F32, state: F32, y: F32, count: Int32):
    """kernels.delta_update for rows 0 .. count - 1 in order, in one dispatch: the same lanes own the
    same sixteen state rows of one column, kept in registers from the first row to the last."""
    var lane = global_idx.x % 64
    var part = lane // 8
    var i = (global_idx.x // 64) * 8 + lane % 8
    var h = i // 128
    var d = i % 128
    var s = SIMD[DType.float32, 16](0)
    comptime for step in range(16):
        s[step] = state[unsafe_offset=(h * 128 + part * 16 + step) * 128 + d]
    for t in range(Int(count)):
        var row = qkv.unsafe_offset(t * 6144)
        var decay = gates[unsafe_offset=t * 32 + h * 2]
        var beta = gates[unsafe_offset=t * 32 + h * 2 + 1]
        var k = row.unsafe_load[width=16](2048 + h * 128 + part * 16)
        var predicted = (s * decay * k).reduce_add()
        predicted += shuffle_xor(predicted, UInt32(8))
        predicted += shuffle_xor(predicted, UInt32(16))
        predicted += shuffle_xor(predicted, UInt32(32))
        var delta = (row[unsafe_offset=4096 + i] - predicted) * beta
        s = s * decay + k * delta
        var value = (s * row.unsafe_load[width=16](h * 128 + part * 16)).reduce_add()
        value += shuffle_xor(value, UInt32(8))
        value += shuffle_xor(value, UInt32(16))
        value += shuffle_xor(value, UInt32(32))
        if part == 0:
            y[unsafe_offset=t * 2048 + i] = value
    comptime for step in range(16):
        state[unsafe_offset=(h * 128 + part * 16 + step) * 128 + d] = s[step]


comptime BM = 128
comptime BN = 128
comptime BK = 16  # one 32-bit word of codes per column of W
comptime KC = 8  # the 840's fp32 product: 64 x 64 x 8
comptime THREADS = 256


def p_gemm_t2(x: F32, w: Pointer[UInt32, MutAnyOrigin], params: Pointer[Float16, MutAnyOrigin], y: F32, n: Int32,
              k: Int32):
    """Y = X W^T for all rows, W packed as kernels.packed_linear reads it: word (k / 16) * n + col holds
    the 2-bit codes of k .. k + 15 for output col, weight (code - 1) * scale, one fp16 scale per 128 k
    of a column at params[(k / 128) * n + col]. X: rows x k fp32 (the Hadamard-rotated input), Y: rows x
    n fp32. A 256-thread workgroup (2 x 2 subgroups of 64) computes a 128 x 128 block of Y: per K step
    of 16 it stages X's slice and W's slice, unpacked to fp32, in shared memory (W's as rows of W, so
    B = W^T is read column-major), and each subgroup multiplies its 64 x 64 tile on the matrix units.
    rows, n and k: multiples of 128, 128 and 16 (as llama/kernels/prefill/p_gemm_q4)."""
    var sa = stack_allocation[BM * BK, Float32, address_space=AddressSpace.SHARED]()  # X: BM rows of BK
    var sb = stack_allocation[BN * BK, Float32, address_space=AddressSpace.SHARED]()  # W: BN rows of BK
    var ldy = Int(n)
    var ldx = Int(k)
    var t = Int(thread_idx.x)
    var sg = t // 64
    var row0 = Int(block_idx.y) * BM
    var col0 = Int(block_idx.x) * BN
    var sr = (sg // 2) * 64  # this subgroup's tile of the block
    var sc = (sg % 2) * 64
    var out = y.unsafe_offset((row0 + sr) * ldy + col0 + sc)
    var wn = t % BN  # the column of W this thread unpacks (consecutive threads, consecutive words)
    var wh = t // BN * 8  # and which eight of the word's sixteen codes
    comptime assert BN * 2 == THREADS, "two threads per word of W"
    var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
    for k0 in range(0, ldx, BK):
        comptime for i in range(BM * BK // 4 // THREADS):
            var v = i * THREADS + t
            var r = v // (BK // 4)
            var c = v % (BK // 4) * 4
            sa.unsafe_store(r * BK + c, x.unsafe_load[width=4]((row0 + r) * ldx + k0 + c))
        var word = w[unsafe_offset=(k0 // 16) * ldy + col0 + wn] >> UInt32(2 * wh)
        var scale = params[unsafe_offset=(k0 // 128) * ldy + col0 + wn].cast[DType.float32]()
        comptime for half in range(2):
            var v = SIMD[DType.float32, 4](0)
            comptime for j in range(4):
                v[j] = (Float32((word >> UInt32(2 * (half * 4 + j))) & 3) - 1) * scale
            sb.unsafe_store(wn * BK + wh + half * 4, v)
        barrier()
        comptime for kk in range(0, BK, KC):
            var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(sa.unsafe_offset(sr * BK + kk), BK)
            var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](
                sb.unsafe_offset(sc * BK + kk), BK)
            acc = at.multiply_add(bt, acc)
        barrier()
    acc.store(out, ldy)


def p_scale(x: F32, width: Int32, scale: Float32):
    """x *= scale for every row (width elements a row)."""
    var i = global_idx.x
    if i < Int(width):
        x[unsafe_offset=Int(block_idx.y) * Int(width) + i] *= scale


def p_scores_mma(q: F32, kc: F32, y: F32, capacity: Int32):
    """kernels.attention_scores for every row at once, on the matrix units: for head block_idx.y and
    the 64 rows from 64 block_idx.x, S = Q K^T for every 64 cached positions up to the diagonal, with
    q pre-scaled by 1 / 16 (p_scale; exact). K is read column-major straight from the KV cache, two
    query heads per KV head; S goes to the rows' scores as kernels.attention_scores leaves them.
    Tiles past a row's position hold values attention_values never reads."""
    var h = Int(block_idx.y)
    var i0 = Int(block_idx.x) * 64
    var ld = 8 * Int(capacity)
    for j0 in range(0, i0 + 64, 64):
        var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
        comptime for k in range(0, 256, KC):
            var at = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(q.unsafe_offset(i0 * 2048 + h * 256 + k), 2048)
            var bt = CoopMatrix[DType.float32, KC, 64, MATRIX_B].load[row_major=False](
                kc.unsafe_offset(j0 * 512 + (h // 4) * 256 + k), 512)
            acc = at.multiply_add(bt, acc)
        acc.store(y.unsafe_offset(i0 * ld + h * Int(capacity) + j0), ld)
