# Attention for the vision-language-action models (vla/): O = softmax(scale Q K^T) V for one head and 64 query
# rows a workgroup (one 64-thread subgroup), flash style with an online softmax, the two products on the 840's
# fp32 cooperative matrices (64 x 64 x 8). Heads of HD (a multiple of 8: SmolVLA's 64, SigLIP So400m's 72,
# Gemma's 256); each launch computes the CW (64 or 16) columns of O from c0, so a head of 72 takes two launches
# (64 + 16, the last 8 of those unused) and a head of 256 four, each recomputing S. For each block of 64 keys:
#   S = Q K^T (eight multiply-adds, K read column-major from memory) goes to shared memory;
#   thread r takes row r: the block's maximum, the new running maximum m, P = exp(scale S - m) in place, the
#   running sum l, and the factor exp(m_old - m) for the row's output so far;
#   P V (eight more, V's CW columns from memory) goes to shared memory, and thread c adds column c of it to its
#   column of O (64 registers), each row first scaled by its factor.
# At most one accumulator is alive at a time, which the 840's driver needs, and O never has to be rescaled
# as a matrix. 16.5 KB of shared memory.
#
# Masks (MASK): key j is visible to query i when klev[j] <= qlev[i] (key and query rows as indexed in their
# buffers, batch included). Levels express everything SmolVLA and pi0 need: padding keys +inf, the prefix's
# blocks 0 and 1 (images and language; the state), the action tokens 2, 3, ... (causal). A query with no
# visible key gets zeros. Without MASK every key 0 .. nk - 1 is visible. LV2: two levels a row (klev and qlev
# hold pairs), key j visible when both of its levels are <= the query's: Octo's readout tokens, which see
# earlier readouts that no observation token sees.
#
# Rows: queries block_idx.y * 64 .. + 63 of batch block_idx.z (qbatch rows apart), keys 0 .. nk - 1 of the
# batch (kbatch rows apart; nk a multiple of 64). Head h reads Q's columns qcol + 64 h, and K's and V's
# columns kcol / vcol + 64 (h / group) (grouped-query attention); O's columns ocol + 64 h.
from std.math import exp
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, thread_idx
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime F32P = UnsafePointer[Float32, MutAnyOrigin]
comptime KC = 8


def attention[MASK: Bool, HD: Int = 64, CW: Int = 64, HOISTQ: Bool = False, SPLIT: Bool = False, KB: Int = 64,
               LV2: Bool = False](
    q: F32P, k: F32P, v: F32P, o: F32P, klev: F32P, qlev: F32P,
    ldq: Int32, ldk: Int32, ldv: Int32, ldo: Int32, qcol: Int32, kcol: Int32, vcol: Int32, ocol: Int32,
    nk: Int32, group: Int32, scale: Float32, qbatch: Int32, kbatch: Int32, c0: Int32, nchunks: Int32,
    nsplit: Int32, part: F32P, ml: F32P,
):
    """Launch with grid (heads, query rows / 64, batches x nchunks) and block 64: block_idx.z is the batch times
    nchunks plus the chunk, whose CW columns start at c0 + chunk CW. HOISTQ (HD = 64): Q's eight 64 x 8 tiles are
    loaded once instead of for every key block.

    SPLIT (flash-decoding, for few query rows against many keys: one batch of 64 rows): the keys' blocks are split
    nsplit ways too, grid (heads, 1, nchunks x nsplit), block_idx.z = chunk nsplit + split. Each workgroup leaves
    its unnormalized O (64 x CW) in `part` and its rows' running max and sum in `ml` (64 each), at slot
    (head nchunks + chunk) nsplit + split; attention_combine merges them."""
    comptime assert HD % KC == 0, "heads of a multiple of 8"
    comptime assert CW == 64 or CW == 32 or CW == 16, "the 840's N: 64, 32 or 16"
    comptime assert KB == 64 or KB == 32, "key blocks of 64 or 32"
    comptime assert not HOISTQ or HD == 64, "hoisting Q for heads of 64"
    var s = stack_allocation[64 * 64, Float32, address_space=AddressSpace.SHARED]()
    var rs = stack_allocation[128, Float32, address_space=AddressSpace.SHARED]()  # per row: factor, then 1 / l
    var h = Int(block_idx.x)
    var zz = Int(block_idx.z)
    var split = 0
    comptime if SPLIT:
        split = zz % Int(nsplit)
        zz = zz // Int(nsplit)
    var b = zz // Int(nchunks)
    var chunk = zz % Int(nchunks)
    var t = Int(thread_idx.x)
    var lq = Int(ldq)
    var lk = Int(ldk)
    var lv = Int(ldv)
    var cc = Int(c0) + chunk * CW
    var jb = 0
    var je = Int(nk) // KB
    comptime if SPLIT:
        var per = (je + Int(nsplit) - 1) // Int(nsplit)
        jb = split * per
        je = min(je, jb + per)
    var qrow0 = b * Int(qbatch) + Int(block_idx.y) * 64
    var krow0 = b * Int(kbatch)
    var kvh = h // Int(group)
    var qbase = q.unsafe_offset(qrow0 * lq + Int(qcol) + h * HD)
    var kbase = k.unsafe_offset(Int(kcol) + kvh * HD)
    var vbase = v.unsafe_offset(Int(vcol) + kvh * HD + cc)
    var level = Float32(0)
    var level2 = Float32(0)
    comptime if MASK:
        comptime if LV2:
            level = qlev[2 * (qrow0 + t)]
            level2 = qlev[2 * (qrow0 + t) + 1]
        else:
            level = qlev[qrow0 + t]
    var m = Float32(-1e30)
    var l = Float32(0)
    var oc = SIMD[DType.float32, 64](0)  # column t of O's CW columns, rows 0 .. 63
    var q0 = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase, lq)
    var q1 = q0
    var q2 = q0
    var q3 = q0
    var q4 = q0
    var q5 = q0
    var q6 = q0
    var q7 = q0
    comptime if HOISTQ:  # Q's eight 64 x 8 tiles, loaded once
        q1 = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase.unsafe_offset(8), lq)
        q2 = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase.unsafe_offset(16), lq)
        q3 = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase.unsafe_offset(24), lq)
        q4 = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase.unsafe_offset(32), lq)
        q5 = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase.unsafe_offset(40), lq)
        q6 = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase.unsafe_offset(48), lq)
        q7 = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase.unsafe_offset(56), lq)
    for j in range(jb, je):
        var kr = krow0 + j * KB
        var sacc = CoopMatrix[DType.float32, 64, KB, ACCUMULATOR].zero()
        comptime for d in range(0, HD, KC):
            var qa: CoopMatrix[DType.float32, 64, KC, MATRIX_A]
            comptime if HOISTQ:
                qa = (q0 if d == 0 else q1 if d == 8 else q2 if d == 16 else q3 if d == 24 else q4 if d == 32 else
                      q5 if d == 40 else q6 if d == 48 else q7)
            else:
                qa = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(qbase.unsafe_offset(d), lq)
            var kb = CoopMatrix[DType.float32, KC, KB, MATRIX_B].load[row_major=False](
                kbase.unsafe_offset(kr * lk + d), lk)
            sacc = qa.multiply_add(kb, sacc)
        barrier()  # the previous block's P V has been read
        sacc.store(s, KB)
        barrier()
        var bm = Float32(-1e30)
        for i in range(KB):  # threads start at their own column: different banks
            var c = (i + t) % KB
            var visible = True
            comptime if MASK:
                comptime if LV2:
                    visible = klev[2 * (kr + c)] <= level and klev[2 * (kr + c) + 1] <= level2
                else:
                    visible = klev[kr + c] <= level
            if visible:
                bm = max(bm, s[t * KB + c] * scale)
        var mn = max(m, bm)
        var total = Float32(0)
        for i in range(KB):
            var c = (i + t) % KB
            var visible = True
            comptime if MASK:
                comptime if LV2:
                    visible = klev[2 * (kr + c)] <= level and klev[2 * (kr + c) + 1] <= level2
                else:
                    visible = klev[kr + c] <= level
            var p = Float32(0)
            if visible:
                p = exp(s[t * KB + c] * scale - mn)
            s[t * KB + c] = p
            total += p
        var factor = exp(m - mn)
        l = l * factor + total
        m = mn
        rs[t] = factor
        barrier()
        var pacc = CoopMatrix[DType.float32, 64, CW, ACCUMULATOR].zero()
        comptime for kk in range(0, KB, KC):
            var pa = CoopMatrix[DType.float32, 64, KC, MATRIX_A].load(s.unsafe_offset(kk), KB)
            var vb = CoopMatrix[DType.float32, KC, CW, MATRIX_B].load(vbase.unsafe_offset((kr + kk) * lv), lv)
            pacc = pa.multiply_add(vb, pacc)
        barrier()  # P has been read
        pacc.store(s, CW)
        barrier()
        if t < CW:
            comptime for i in range(64):
                oc[i] = oc[i] * rs[i] + s[i * CW + t]
    comptime if SPLIT:  # unnormalized, for attention_combine
        var slot = (h * Int(nchunks) + chunk) * Int(nsplit) + split
        ml[slot * 128 + t] = m
        ml[slot * 128 + 64 + t] = l
        if t < CW:
            var dst = part.unsafe_offset(slot * 64 * CW + t)
            comptime for i in range(64):
                dst[i * CW] = oc[i]
        return
    var inv = Float32(0)
    if l > 0:
        inv = 1 / l
    rs[64 + t] = inv
    barrier()
    if t < min(CW, HD - cc):
        var out = o.unsafe_offset(qrow0 * Int(ldo) + Int(ocol) + h * HD + cc + t)
        comptime for i in range(64):
            out[i * Int(ldo)] = oc[i] * rs[64 + i]


def attention_combine[CW: Int](part: F32P, ml: F32P, o: F32P, ldo: Int32, ocol: Int32, hd: Int32, c0: Int32,
                               nchunks: Int32, nsplit: Int32):
    """O for attention[SPLIT]: row block_idx.y of head block_idx.x / nchunks, chunk block_idx.x % nchunks, column
    thread_idx.x: the splits' O scaled by exp(m_s - M), over the sum of their l_s exp(m_s - M) (M the largest m_s).
    Rows that see no key get zeros. Launch with grid (heads x nchunks, 64) and block CW."""
    var t = Int(thread_idx.x)
    var i = Int(block_idx.y)
    var hc = Int(block_idx.x)
    var ns = Int(nsplit)
    var slot0 = hc * ns
    var mx = Float32(-1e30)
    for sp in range(ns):
        mx = max(mx, ml[(slot0 + sp) * 128 + i])
    var total = Float32(0)
    var acc = Float32(0)
    for sp in range(ns):
        var f = exp(ml[(slot0 + sp) * 128 + i] - mx)
        total += ml[(slot0 + sp) * 128 + 64 + i] * f
        acc += part[(slot0 + sp) * 64 * CW + i * CW + t] * f
    var h = hc // Int(nchunks)
    var cc = Int(c0) + (hc % Int(nchunks)) * CW
    if t < min(CW, Int(hd) - cc):
        var v = Float32(0)
        if total > 0:
            v = acc / total
        o[i * Int(ldo) + Int(ocol) + h * Int(hd) + cc + t] = v
