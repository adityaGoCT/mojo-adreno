# Row and element kernels for the vision-language-action models (vla/): norms, the image's patches and
# position embedding, SmolVLM's pixel shuffle, embedding rows, RoPE into the K/V cache, the time
# embedding's columns and the Euler step. fp32 activations; weights in their checkpoint's type WT (bf16 as
# uint16 bits, fp16 or fp32), widened as vgemm.widen does. Reductions go through shared memory and
# barriers (shuffles after loops whose lanes diverge are unreliable on the 840's driver).
from std.math import rsqrt, sqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace

from vgemm import widen1

comptime F32P = UnsafePointer[Float32, MutAnyOrigin]
comptime I32P = UnsafePointer[Int32, MutAnyOrigin]


@always_inline
def block_sum(red: UnsafePointer[Float32, MutUntrackedOrigin, address_space=AddressSpace.SHARED], t: Int,
              v: Float32) -> Float32:
    """The sum of v over the 64 threads of the workgroup."""
    red[t] = v
    barrier()
    comptime for stage in range(6):
        if t < 32 >> stage:
            red[t] = red[t] + red[t + (32 >> stage)]
        barrier()
    var total = red[0]
    barrier()
    return total


def layernorm[WT: DType](x: F32P, w: UnsafePointer[Scalar[WT], MutAnyOrigin],
                         b: UnsafePointer[Scalar[WT], MutAnyOrigin], y: F32P, ldx: Int32, ldy: Int32, d: Int32,
                         eps: Float32):
    """y = (x - mean) / sqrt(var + eps) * w + b over the row's first d values; one 64-thread workgroup a row."""
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var xr = x.unsafe_offset(Int(block_idx.x) * Int(ldx))
    var yr = y.unsafe_offset(Int(block_idx.x) * Int(ldy))
    var dd = Int(d)
    var s = Float32(0)
    for j in range(t, dd, 64):
        s += xr[j]
    var mean = block_sum(red, t, s) / Float32(dd)
    var s2 = Float32(0)
    for j in range(t, dd, 64):
        var e = xr[j] - mean
        s2 += e * e
    var r = rsqrt(block_sum(red, t, s2) / Float32(dd) + eps)
    for j in range(t, dd, 64):
        yr[j] = (xr[j] - mean) * r * widen1[WT](w.unsafe_load[width=1](j)) + widen1[WT](b.unsafe_load[width=1](j))


def rmsnorm[WT: DType](x: F32P, w: UnsafePointer[Scalar[WT], MutAnyOrigin], y: F32P, ldx: Int32, ldy: Int32,
                       d: Int32, eps: Float32, woff: Float32):
    """y = (w + woff) * (x / sqrt(mean(x^2) + eps)) over the row's first d values: Llama's RMSNorm (woff 0),
    Gemma's (woff 1: x * (1 + w)); a workgroup a row."""
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var xr = x.unsafe_offset(Int(block_idx.x) * Int(ldx))
    var yr = y.unsafe_offset(Int(block_idx.x) * Int(ldy))
    var dd = Int(d)
    var s2 = Float32(0)
    for j in range(t, dd, 64):
        s2 += xr[j] * xr[j]
    var r = rsqrt(block_sum(red, t, s2) / Float32(dd) + eps)
    for j in range(t, dd, 64):
        yr[j] = (xr[j] * r) * (woff + widen1[WT](w.unsafe_load[width=1](j)))


def patchify(pix: F32P, xp: F32P, size: Int32, patch: Int32, total: Int32):
    """The images' patches as rows (a convolution with stride = kernel = patch, as a matmul): pix holds
    images of 3 x size x size; row b * (size / patch)^2 + py * (size / patch) + px of xp holds patch (py, px)
    of image b, element c * patch^2 + ky * patch + kx (the conv weight's own order)."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var sz = Int(size)
    var p = Int(patch)
    var g = sz // p
    var kdim = 3 * p * p
    var row = e // kdim
    var col = e % kdim
    var c = col // (p * p)
    var ky = (col % (p * p)) // p
    var kx = col % p
    var img = row // (g * g)
    var py = (row % (g * g)) // g
    var px = row % g
    xp[e] = pix[((img * 3 + c) * sz + py * p + ky) * sz + px * p + kx]


def add_rows[WT: DType](x: F32P, pos: UnsafePointer[Scalar[WT], MutAnyOrigin], rows: Int32, d: Int32, total: Int32):
    """x[r, :] += pos[r % rows, :] (d columns, x's rows d apart): SigLIP's position embedding for every image."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var dd = Int(d)
    x[e] = x[e] + widen1[WT](pos.unsafe_load[width=1](((e // dd) % Int(rows)) * dd + e % dd))


def pixel_shuffle(v: F32P, xs: F32P, grid: Int32, d: Int32, factor: Int32, total: Int32):
    """SmolVLM's connector pixel shuffle (Idefics3 pixel_shuffle): each image's grid x grid tokens of d become
    (grid / factor)^2 tokens of d * factor^2. Token i = hq * (grid / factor) + wq, feature f takes token
    (hq * factor + f / (d * factor), wq * factor + (f % (d * factor)) / d), value f % d."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var g = Int(grid)
    var dd = Int(d)
    var s = Int(factor)
    var go = g // s
    var width = dd * s * s
    var row = e // width
    var f = e % width
    var img = row // (go * go)
    var i = row % (go * go)
    var h = (i // go) * s + f // (dd * s)
    var w = (i % go) * s + (f % (dd * s)) // dd
    xs[e] = v[(img * g * g + h * g + w) * dd + f % dd]


def embed_rows[WT: DType](emb: UnsafePointer[Scalar[WT], MutAnyOrigin], tokens: I32P, y: F32P, ldy: Int32,
                          d: Int32, scale: Float32):
    """Row r of y = row tokens[r] of the embedding, times scale; a 64-thread workgroup a row."""
    var r = Int(block_idx.x)
    var dd = Int(d)
    var src = Int(tokens[r]) * dd
    for j in range(Int(thread_idx.x), dd, 64):
        y[r * Int(ldy) + j] = widen1[WT](emb.unsafe_load[width=1](src + j)) * scale


def rope_qk(qkv: F32P, cos: F32P, sin: F32P, pos: I32P, kc: F32P, vc: F32P, ldqkv: Int32, nq: Int32, nkv: Int32,
            ldc: Int32, crow0: Int32, hd: Int32):
    """RoPE (rotate-half, heads of hd, the tables' rows by position, hd / 2 values each) for row block_idx.x of
    qkv = q heads (nq) | k heads (nkv) | v heads (nkv): q rotated in place; k rotated and v copied into row
    crow0 + row of the caches kc and vc (ldc apart). nkv = 0 rotates q only."""
    var row = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var dh = Int(hd)
    var half = dh // 2
    var p = Int(pos[row]) * half
    var src = qkv.unsafe_offset(row * Int(ldqkv))
    var dst = (Int(crow0) + row) * Int(ldc)
    var q = Int(nq)
    var kv = Int(nkv)
    for e in range(t, (q + kv) * half, 64):
        var h = e // half
        var i = e % half
        var a = src[h * dh + i]
        var b = src[h * dh + i + half]
        var c = cos[p + i]
        var s = sin[p + i]
        var ra = a * c - b * s
        var rb = b * c + a * s
        if h < q:
            src[h * dh + i] = ra
            src[h * dh + i + half] = rb
        else:
            kc[dst + (h - q) * dh + i] = ra
            kc[dst + (h - q) * dh + i + half] = rb
    for j in range(t, kv * dh, 64):
        vc[dst + j] = src[(q + kv) * dh + j]


def fill_cols(x: F32P, src: F32P, ldx: Int32, col0: Int32, d: Int32, src0: Int32, total: Int32):
    """x[r, col0 + c] = src[src0 + c] for c < d, every row: the time embedding next to the actions' embedding."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var dd = Int(d)
    x[(e // dd) * Int(ldx) + Int(col0) + e % dd] = src[Int(src0) + e % dd]


def euler(x: F32P, v: F32P, ldx: Int32, ldv: Int32, cols: Int32, dt: Float32, total: Int32):
    """x += dt * v for the action chunk (rows x cols)."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var r = e // Int(cols)
    var c = e % Int(cols)
    x[r * Int(ldx) + c] = x[r * Int(ldx) + c] + dt * v[r * Int(ldv) + c]
