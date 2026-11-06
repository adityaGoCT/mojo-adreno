# Octo's own kernels, next to vla/kernels' projections (vgemm), flash attention (vattn) and row kernels (vrow):
# the SmallStem's 3 x 3 stride-2 convolutions as im2col + projection, GroupNorm with ReLU, T5's attention with its
# relative position bias, row copies and adds, and the diffusion head: its input staging, its DDPM update, and
# (GPU optimized) the whole 20-step denoising of one row in one launch. fp32 throughout. Reductions go through
# shared memory and barriers, as vla/kernels do.
from std.math import exp, rsqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace

from vrow import block_sum

comptime F32P = UnsafePointer[Float32, MutAnyOrigin]
comptime I32P = UnsafePointer[Int32, MutAnyOrigin]
comptime NEG: Float32 = -3.0e38


def im2col(x: F32P, y: F32P, h: Int32, w: Int32, cin: Int32, ldc: Int32, kpad: Int32, total: Int32):
    """3 x 3, stride 2, padding 1: y[(img, oy, ox), (ky 3 + kx) cin + ci] = x[(img, 2 oy - 1 + ky, 2 ox - 1 + kx),
    ci] (zeros outside the image and past 9 cin, up to kpad). x: NHWC rows of ldc floats; y: rows of kpad."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var kp = Int(kpad)
    var row = e // kp
    var kk = e % kp
    var c = Int(cin)
    var ho = Int(h) // 2
    var wo = Int(w) // 2
    var v = Float32(0)
    if kk < 9 * c:
        var tap = kk // c
        var ci = kk % c
        var img = row // (ho * wo)
        var p = row % (ho * wo)
        var iy = 2 * (p // wo) - 1 + tap // 3
        var ix = 2 * (p % wo) - 1 + tap % 3
        if iy >= 0 and iy < Int(h) and ix >= 0 and ix < Int(w):
            v = x[((img * Int(h) + iy) * Int(w) + ix) * Int(ldc) + ci]
    y[e] = v


def pad_cols(src: F32P, dst: F32P, k: Int32, kpad: Int32, total: Int32):
    """dst (rows of kpad) = src (rows of k), zeros past k: the first convolution's 54 taps padded to 56."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var r = e // Int(kpad)
    var c = e % Int(kpad)
    dst[e] = src[r * Int(k) + c] if c < Int(k) else Float32(0)


def groupnorm_relu(x: F32P, g: F32P, b: F32P, hw: Int32, c: Int32, ldc: Int32, eps: Float32):
    """In place, x = relu(GroupNorm(x) g + b) for group block_idx.x of image block_idx.y (32 groups of c / 32
    channels over the image's hw pixels; flax's statistics: mean and E[x^2] - mean^2). A 64-thread workgroup."""
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var cg = Int(c) // 32
    var c0 = Int(block_idx.x) * cg
    var base = Int(block_idx.y) * Int(hw) * Int(ldc)
    var n = Int(hw) * cg
    var s = Float32(0)
    var s2 = Float32(0)
    for e in range(t, n, 64):
        var v = x[base + (e // cg) * Int(ldc) + c0 + e % cg]
        s += v
        s2 += v * v
    var mean = block_sum(red, t, s) / Float32(n)
    var var_ = max(block_sum(red, t, s2) / Float32(n) - mean * mean, Float32(0))
    var r = rsqrt(var_ + eps)
    for e in range(t, n, 64):
        var ch = c0 + e % cg
        var i = base + (e // cg) * Int(ldc) + ch
        x[i] = max((x[i] - mean) * r * g[ch] + b[ch], Float32(0))


def add_rows(x: F32P, src: F32P, ldx: Int32, d: Int32, total: Int32):
    """x[r, :d] += src[r, :d] (src packed)."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var r = e // Int(d)
    x[r * Int(ldx) + e % Int(d)] += src[e]


def t5_attention(q: F32P, k: F32P, v: F32P, o: F32P, bias: F32P, keymask: I32P, ld: Int32, ldo: Int32, qcol: Int32,
                 kcol: Int32, vcol: Int32, nk: Int32, hd: Int32):
    """T5's self-attention for query row block_idx.y of head block_idx.x: softmax(Q K^T + bias[h, i, :]) V, no
    1 / sqrt(d) scaling, keys with keymask 0 hidden (T5's padding). bias: heads x nk x nk. nk <= 64."""
    var s = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var i = Int(block_idx.y)
    var t = Int(thread_idx.x)
    var d = Int(hd)
    var n = Int(nk)
    var sc = NEG
    if t < n and keymask[t] != 0:
        var qp = q.unsafe_offset(i * Int(ld) + Int(qcol) + h * d)
        var kp = k.unsafe_offset(t * Int(ld) + Int(kcol) + h * d)
        var acc = Float32(0)
        for c in range(d):
            acc += qp[c] * kp[c]
        sc = acc + bias[(h * n + i) * n + t]
    s[t] = sc
    red[t] = sc
    barrier()
    comptime for stage in range(6):
        if t < 32 >> stage:
            red[t] = max(red[t], red[t + (32 >> stage)])
        barrier()
    var m = red[0]
    barrier()
    var p = Float32(0)
    if s[t] > NEG:
        p = exp(s[t] - m)
    var total = block_sum(red, t, p)
    s[t] = p / total
    barrier()
    for c in range(t, d, 64):
        var acc = Float32(0)
        for j in range(n):
            acc += s[j] * v[j * Int(ld) + Int(vcol) + h * d + c]
        o[i * Int(ldo) + h * d + c] = acc


def stage_head(cond: F32P, emb: F32P, x: F32P, y: F32P, step: Int32, td: Int32, d: Int32, ad: Int32):
    """The score network's input row: [cond (time embedding of `step`), emb (the readout), x (the noisy
    actions)]: td + d + ad values into row 0 of y. One workgroup."""
    var t = Int(thread_idx.x)
    var a = Int(td)
    var b = Int(d)
    for j in range(t, a + b + Int(ad), 256):
        if j < a:
            y[j] = cond[Int(step) * a + j]
        elif j < a + b:
            y[j] = emb[j - a]
        else:
            y[j] = x[j - a - b]


def ddpm_update(x: F32P, eps: F32P, z: F32P, zoff: Int32, c1: Float32, c2: Float32, sigma: Float32, clip: Float32,
                n: Int32):
    """x = clip(c1 (x - c2 eps) + sigma z[zoff ..], +-clip): Octo's DDPM step (sigma 0 at the last). One
    workgroup. (z by offset: a binding's offset must be a multiple of 64 bytes.)"""
    var t = Int(thread_idx.x)
    if t < Int(n):
        var v = c1 * (x[t] - c2 * eps[t])
        v = v + sigma * z[Int(zoff) + t]
        x[t] = min(max(v, -clip), clip)


@always_inline
def swish(v: Float32) -> Float32:
    return v / (1.0 + exp(-v))


@always_inline
def gemv[ACT: Bool](xs: UnsafePointer[Float32, MutUntrackedOrigin, address_space=AddressSpace.SHARED],
                    wt: F32P, b: F32P, res: UnsafePointer[Float32, MutUntrackedOrigin, address_space=AddressSpace.SHARED],
                    k: Int, n: Int, t: Int):
    """res[j] = sum_i act(xs[i]) wt[i n + j] + b[j] for this thread's outputs j = t, t + 256, ... (wt: k x n,
    W transposed, so the threads read consecutive floats)."""
    for j in range(t, n, 256):
        var acc = b[j]
        for i in range(k):
            var v = xs[i]
            comptime if ACT:
                v = swish(v)
            acc += v * wt[i * n + j]
        res[j] = acc


def diffusion_head(wt_in: F32P, b_in: F32P, ln_g: F32P, ln_b: F32P, wt_up: F32P, b_up: F32P, wt_dn: F32P, b_dn: F32P,
                   wt_out: F32P, b_out: F32P, cond: F32P, emb: F32P, x: F32P, z: F32P, sched: F32P, xs_out: F32P,
                   d: Int32, steps: Int32):
    """GPU optimized: all of Octo's denoising for one row in one workgroup of 256 threads. Per step t = steps - 1
    .. 0: in = [cond[t] (32), emb (d), x (28)]; h = in Win + b; three blocks h += swish(LN(h) Wup + b) Wdn + b;
    eps = swish(h) Wout + b; x = clip(c1 (x - c2 eps) + sigma z_t, +-5). The weights transposed (k x n);
    ln_g / ln_b / wt_up ... hold the three blocks back to back. sched: per step c1, c2, sigma. x (28) is updated
    in place; xs_out gets every step's x (steps x 28)."""
    comptime TD = 32
    comptime AD = 28
    comptime H = 256
    comptime HX = 1024
    var t = Int(thread_idx.x)
    var dd = Int(d)
    var inp = stack_allocation[1024, Float32, address_space=AddressSpace.SHARED]()  # TD + d + AD <= 1024
    var h = stack_allocation[H, Float32, address_space=AddressSpace.SHARED]()
    var hn = stack_allocation[H, Float32, address_space=AddressSpace.SHARED]()
    var hx = stack_allocation[HX, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[256, Float32, address_space=AddressSpace.SHARED]()
    var k_in = TD + dd + AD
    for j in range(t, dd, 256):
        inp[TD + j] = emb[j]
    if t < AD:
        inp[TD + dd + t] = x[t]
    for step in range(Int(steps) - 1, -1, -1):
        if t < TD:
            inp[t] = cond[step * TD + t]
        barrier()
        gemv[False](inp, wt_in, b_in, h, k_in, H, t)
        barrier()
        for blk in range(3):
            # LayerNorm(256), eps 1e-6: one value a thread
            var v = h[t]
            red[t] = v
            barrier()
            comptime for stage in range(8):
                if t < 128 >> stage:
                    red[t] = red[t] + red[t + (128 >> stage)]
                barrier()
            var mean = red[0] / Float32(H)
            barrier()
            var e = v - mean
            red[t] = e * e
            barrier()
            comptime for stage in range(8):
                if t < 128 >> stage:
                    red[t] = red[t] + red[t + (128 >> stage)]
                barrier()
            var r = rsqrt(red[0] / Float32(H) + Float32(1e-6))
            barrier()
            hn[t] = e * r * ln_g[blk * H + t] + ln_b[blk * H + t]
            barrier()
            gemv[False](hn, wt_up.unsafe_offset(blk * H * HX), b_up.unsafe_offset(blk * HX), hx, H, HX, t)
            for j in range(t, HX, 256):
                hx[j] = swish(hx[j])
            barrier()
            # h += swish(hx) Wdn + b, this thread's column t
            var acc = b_dn[blk * H + t]
            var wd = wt_dn.unsafe_offset(blk * HX * H)
            for i in range(HX):
                acc += hx[i] * wd[i * H + t]
            barrier()
            h[t] = h[t] + acc
            barrier()
        gemv[True](h, wt_out, b_out, hn, H, AD, t)  # eps in hn[0 .. 27]
        barrier()
        if t < AD:
            var c1 = sched[step * 3]
            var c2 = sched[step * 3 + 1]
            var sg = sched[step * 3 + 2]
            var nv = c1 * (inp[TD + dd + t] - c2 * hn[t])
            nv = nv + sg * z[step * AD + t]
            nv = min(max(nv, Float32(-5)), Float32(5))
            inp[TD + dd + t] = nv
            xs_out[step * AD + t] = nv
        barrier()
    if t < AD:
        x[t] = inp[TD + dd + t]


def relu_rows(x: F32P, ld: Int32, n: Int32, total: Int32):
    """x[r, :n] = max(x[r, :n], 0) in place: T5's feed-forward."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var i = (e // Int(n)) * Int(ld) + e % Int(n)
    x[i] = max(x[i], Float32(0))


def transpose(src: F32P, dst: F32P, rows: Int32, cols: Int32, total: Int32):
    """dst (cols x rows) = src (rows x cols) transposed: the fused head's weights, k x n."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var r = e // Int(cols)
    var c = e % Int(cols)
    dst[c * Int(rows) + r] = src[e]


def to_f16(src: F32P, dst: UnsafePointer[Float16, MutAnyOrigin], total: Int32):
    var e = global_idx.x
    if e >= Int(total):
        return
    dst[e] = src[e].cast[DType.float16]()
