# TurboVLA's own kernels, next to vla/kernels' projections (vgemm), flash attention (vattn) and row kernels (vrow):
# the exact-erf GELU and ReLU, tanh, DINOv3's 2-D RoPE on patch tokens, LayerScale and "normalized" residuals, BERT's
# embeddings, and a small attention for the few-row parts (BERT and the text layers over 21 tokens with their
# sub-sentence mask, the bidirectional vision <-> text attention, the action decoder's 12 queries). fp32 throughout.
# Reductions go through shared memory and barriers, as vla/kernels do.
from std.math import exp
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace

comptime F32P = UnsafePointer[Float32, MutAnyOrigin]
comptime I32P = UnsafePointer[Int32, MutAnyOrigin]
comptime MAXK = 640  # keys attn_small holds in shared memory
comptime NEG: Float32 = -3.0e38


@always_inline
def erf32(x: Float32) -> Float32:
    """erf through erfc's Chebyshev fit (Numerical Recipes' erfcc): relative error of erfc below 1.2e-7."""
    var z = abs(x)
    var t = 1.0 / (1.0 + 0.5 * z)
    var r = t * exp(-z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (0.09678418 + t * (
        -0.18628806 + t * (0.27886807 + t * (-1.13520398 + t * (1.48851587 + t * (-0.82215223 + t * 0.17087277)))))))))
    var erfc = r if x >= 0 else 2.0 - r
    return 1.0 - erfc


@always_inline
def tanh32(x: Float32) -> Float32:
    var e = exp(-2.0 * abs(x))
    var r = (1.0 - e) / (1.0 + e)
    return r if x >= 0 else -r


@always_inline
def block_sum(red: UnsafePointer[Float32, MutUntrackedOrigin, address_space=AddressSpace.SHARED], t: Int,
              v: Float32) -> Float32:
    red[t] = v
    barrier()
    comptime for stage in range(6):
        if t < 32 >> stage:
            red[t] = red[t] + red[t + (32 >> stage)]
        barrier()
    var total = red[0]
    barrier()
    return total


@always_inline
def block_max(red: UnsafePointer[Float32, MutUntrackedOrigin, address_space=AddressSpace.SHARED], t: Int,
              v: Float32) -> Float32:
    red[t] = v
    barrier()
    comptime for stage in range(6):
        if t < 32 >> stage:
            red[t] = max(red[t], red[t + (32 >> stage)])
        barrier()
    var m = red[0]
    barrier()
    return m


def gelu_rows(x: F32P, ld: Int32, n: Int32, total: Int32):
    """x[r, :n] = gelu(x[r, :n]) in place, exact (erf) form: 0.5 x (1 + erf(x / sqrt 2)); total = rows * n."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var i = (e // Int(n)) * Int(ld) + e % Int(n)
    var v = x[i]
    x[i] = 0.5 * v * (1.0 + erf32(v * 0.7071067811865476))


def relu_rows(x: F32P, ld: Int32, n: Int32, total: Int32):
    var e = global_idx.x
    if e >= Int(total):
        return
    var i = (e // Int(n)) * Int(ld) + e % Int(n)
    x[i] = max(x[i], Float32(0))


def tanh_rows(x: F32P, y: F32P, total: Int32):
    var e = global_idx.x
    if e >= Int(total):
        return
    y[e] = tanh32(x[e])


def scale_add(x: F32P, d: F32P, g: F32P, n: Int32, total: Int32):
    """x += g * d, g per column (DINOv3's LayerScale on a residual branch); rows n apart."""
    var e = global_idx.x
    if e >= Int(total):
        return
    x[e] = x[e] + g[e % Int(n)] * d[e]


def ln_plus(y: F32P, ln: F32P, d: F32P, g: F32P, n: Int32, total: Int32):
    """y = ln + g * d: the fusion block's "normalized" residual, LayerNorm(x) + gamma delta."""
    var e = global_idx.x
    if e >= Int(total):
        return
    y[e] = ln[e] + g[e % Int(n)] * d[e]


def add_view(x: F32P, emb: F32P, per: Int32, n: Int32, total: Int32):
    """x[r, :] += emb[r / per, :]: each view's embedding on its tokens."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var nn = Int(n)
    x[e] = x[e] + emb[(e // nn) // Int(per) * nn + e % nn]


def rope_patches(qkv: F32P, cos: F32P, sin: F32P, ld: Int32, vrows: Int32, prefix: Int32, npatch: Int32,
                 qk: Int32, hd: Int32):
    """DINOv3's RoPE (rotate-half, cos/sin tables of hd values a patch) on the patch tokens of q (columns 0 .. qk-1)
    and k (qk .. 2 qk - 1), a view's rows vrows apart: its CLS and register tokens (the first `prefix`) and padding
    rows are left alone. Grid: the rows; block 64."""
    var row = Int(block_idx.x)
    var p = row % Int(vrows) - Int(prefix)
    if p < 0 or p >= Int(npatch):
        return
    var d = Int(hd)
    var half = d // 2
    var src = qkv.unsafe_offset(row * Int(ld))
    var c = cos.unsafe_offset(p * d)
    var s = sin.unsafe_offset(p * d)
    for e in range(Int(thread_idx.x), Int(qk), 64):  # (q and k heads) x half pairs
        var h = e // half
        var i = e % half
        var base = h * d
        var a = src[base + i]
        var b = src[base + i + half]
        src[base + i] = a * c[i] - b * s[i]
        src[base + i + half] = b * c[i + half] + a * s[i + half]


def gather_rows(x: F32P, y: F32P, vrows: Int32, prefix: Int32, npatch: Int32, d: Int32, total: Int32):
    """y[v npatch + p, :] = x[v vrows + prefix + p, :]: the patch tokens, CLS and registers dropped."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var dd = Int(d)
    var r = e // dd
    var v = r // Int(npatch)
    var p = r % Int(npatch)
    y[e] = x[(v * Int(vrows) + Int(prefix) + p) * dd + e % dd]


def bert_embed(ids: I32P, pos: I32P, word: F32P, posemb: F32P, typ: F32P, y: F32P, d: Int32):
    """y[r] = word[ids[r]] + position[pos[r]] + token_type[0]: BERT's embeddings before their LayerNorm."""
    var r = Int(block_idx.x)
    var dd = Int(d)
    var wi = Int(ids[r]) * dd
    var pi = Int(pos[r]) * dd
    for j in range(Int(thread_idx.x), dd, 64):
        y[r * dd + j] = word[wi + j] + posemb[pi + j] + typ[j]


def zero_from(x: F32P, start: Int32, total: Int32):
    var e = global_idx.x
    if e >= Int(total):
        return
    x[Int(start) + e] = 0


def attn_small[MK: Int](q: F32P, k: F32P, v: F32P, o: F32P, mask: I32P, ldq: Int32, ldk: Int32, ldv: Int32,
                        ldo: Int32, qcol: Int32, kcol: Int32, vcol: Int32, ocol: Int32, nk: Int32, hd: Int32,
                        scale: Float32):
    """O = softmax(scale Q K^T) V for one query row and one head: grid (heads, query rows), block 64. Head h uses
    columns qcol / kcol / vcol / ocol + h hd. Masks (MK): 0 none; 1 a key-padding mask, mask[j] != 0 hides key j;
    2 a matrix, mask[i nk + j] != 0 lets query i see key j. A query with no visible key gets zeros. nk <= MAXK."""
    var s = stack_allocation[MAXK, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var i = Int(block_idx.y)
    var t = Int(thread_idx.x)
    var d = Int(hd)
    var n = Int(nk)
    var qp = q.unsafe_offset(i * Int(ldq) + Int(qcol) + h * d)
    var mx = NEG
    for j in range(t, n, 64):
        var ok = True
        comptime if MK == 1:
            ok = mask[j] == 0
        elif MK == 2:
            ok = mask[i * n + j] != 0
        var sc = NEG
        if ok:
            var kp = k.unsafe_offset(j * Int(ldk) + Int(kcol) + h * d)
            var acc = Float32(0)
            for c in range(d):
                acc += qp[c] * kp[c]
            sc = acc * scale
        s[j] = sc
        mx = max(mx, sc)
    var m = block_max(red, t, mx)
    var part = Float32(0)
    for j in range(t, n, 64):
        var p = Float32(0)
        if s[j] > NEG:
            p = exp(s[j] - m)
        s[j] = p
        part += p
    var total = block_sum(red, t, part)
    var inv = Float32(0)
    if total > 0:
        inv = 1.0 / total
    for c in range(t, d, 64):
        var acc = Float32(0)
        var vp = v.unsafe_offset(Int(vcol) + h * d + c)
        for j in range(n):
            acc += s[j] * vp[j * Int(ldv)]
        o[i * Int(ldo) + Int(ocol) + h * d + c] = acc * inv


def scale_rows(w: F32P, g: F32P, k: Int32, total: Int32):
    """w[r, :] *= g[r] (rows k long): LayerScale folded into the projection before it (its weight and bias)."""
    var e = global_idx.x
    if e >= Int(total):
        return
    w[e] = w[e] * g[e // Int(k)]


def to_f16(src: F32P, dst: UnsafePointer[Float16, MutAnyOrigin], total: Int32):
    var e = global_idx.x
    if e >= Int(total):
        return
    dst[e] = src[e].cast[DType.float16]()
