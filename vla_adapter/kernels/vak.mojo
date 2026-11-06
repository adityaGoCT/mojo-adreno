# VLA-Adapter's own kernels, next to vla/kernels' projections (vgemm), flash attention (vattn) and row kernels
# (vrow): bf16 tensors widened to fp32, LayerScale and ReLU, the two ViTs' patch features side by side for the
# projector, and the policy's pieces: its RoPE (pairs (2i, 2i + 1) rotated with the half-split tables' entries 2i and
# 2i + 1, as VLA-Adapter's apply_rope does) and its attention, one softmax over self, adapter and task keys with the
# task logits scaled by tanh(gate). fp32 throughout; reductions through shared memory and barriers, as vla/kernels do.
from std.math import exp
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace

from vrow import block_sum

comptime F32P = UnsafePointer[Float32, MutAnyOrigin]
comptime U16P = UnsafePointer[UInt16, MutAnyOrigin]
comptime NEG: Float32 = -3.0e38
comptime PHD = 112  # the policy's heads
comptime MAXK = 640  # the policy's keys: 8 + 65 + 512


def widen(src: U16P, dst: F32P, total: Int32):
    """dst = src (bf16 bits) as fp32, exactly."""
    var e = global_idx.x
    if e >= Int(total):
        return
    dst[e] = bitcast[DType.float32](UInt32(src[e]) << 16)


def scale_add(x: F32P, d: F32P, g: F32P, n: Int32, total: Int32):
    """x += d * g (columns of n): LayerScale on the residual."""
    var e = global_idx.x
    if e >= Int(total):
        return
    x[e] += d[e] * g[e % Int(n)]


def relu_rows(x: F32P, ld: Int32, n: Int32, total: Int32):
    var e = global_idx.x
    if e >= Int(total):
        return
    var i = (e // Int(n)) * Int(ld) + e % Int(n)
    x[i] = max(x[i], Float32(0))


def fuse_cols(dino: F32P, sig: F32P, f: F32P, drows: Int32, prefix: Int32, npatch: Int32, dd: Int32, ds: Int32,
              total: Int32):
    """f[v npatch + p] = [DINOv2's patch p of image v (row v drows + prefix + p) | SigLIP's (row v npatch + p)]."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var w = Int(dd) + Int(ds)
    var r = e // w
    var c = e % w
    var v = r // Int(npatch)
    var p = r % Int(npatch)
    if c < Int(dd):
        f[e] = dino[(v * Int(drows) + Int(prefix) + p) * Int(dd) + c]
    else:
        f[e] = sig[r * Int(ds) + c - Int(dd)]


def rope_policy(x: F32P, cos: F32P, sin: F32P, ld: Int32, heads: Int32):
    """In place, row block_idx.x of x (its position): each head's pairs (2i, 2i + 1) become
    (a cos[2i] - b sin[2i], b cos[2i + 1] + a sin[2i + 1]), the tables' rows 112 wide by position."""
    var row = Int(block_idx.x)
    var t = Int(thread_idx.x)
    var xr = x.unsafe_offset(row * Int(ld))
    var cr = cos.unsafe_offset(row * PHD)
    var sr = sin.unsafe_offset(row * PHD)
    for e in range(t, Int(heads) * (PHD // 2), 64):
        var h = e // (PHD // 2)
        var j = h * PHD + 2 * (e % (PHD // 2))
        var jj = 2 * (e % (PHD // 2))
        var a = xr[j]
        var b = xr[j + 1]
        xr[j] = a * cr[jj] - b * sr[jj]
        xr[j + 1] = b * cr[jj + 1] + a * sr[jj + 1]


@always_inline
def dot112(a: F32P, b: F32P) -> Float32:
    var acc = Float32(0)
    for c in range(PHD):
        acc += a[c] * b[c]
    return acc


def policy_attention(q: F32P, ks: F32P, vs: F32P, ka: F32P, va: F32P, kt: F32P, vt: F32P, o: F32P, ld: Int32,
                     n1: Int32, n2: Int32, n3: Int32, ratio: Float32, scale: Float32):
    """Query row block_idx.y, head block_idx.x (112 wide): softmax over [q ks^T (n1), q ka^T (n2), ratio q kt^T
    (n3)] * scale, then the same-ordered V rows. All rows ld apart; n1 + n2 + n3 <= 640."""
    var s = stack_allocation[MAXK, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var i = Int(block_idx.y)
    var t = Int(thread_idx.x)
    var l = Int(ld)
    var a = Int(n1)
    var b = a + Int(n2)
    var n = b + Int(n3)
    var qp = q.unsafe_offset(i * l + h * PHD)
    var mx = NEG
    for j in range(t, n, 64):
        var sc: Float32
        if j < a:
            sc = dot112(qp, ks.unsafe_offset(j * l + h * PHD))
        elif j < b:
            sc = dot112(qp, ka.unsafe_offset((j - a) * l + h * PHD))
        else:
            sc = dot112(qp, kt.unsafe_offset((j - b) * l + h * PHD)) * ratio
        sc = sc * scale
        s[j] = sc
        mx = max(mx, sc)
    red[t] = mx
    barrier()
    comptime for stage in range(6):
        if t < 32 >> stage:
            red[t] = max(red[t], red[t + (32 >> stage)])
        barrier()
    var m = red[0]
    barrier()
    var part = Float32(0)
    for j in range(t, n, 64):
        var p = exp(s[j] - m)
        s[j] = p
        part += p
    var total = block_sum(red, t, part)
    var inv = 1.0 / total
    for c in range(t, PHD, 64):
        var acc = Float32(0)
        for j in range(n):
            var vp: F32P
            if j < a:
                vp = vs.unsafe_offset(j * l)
            elif j < b:
                vp = va.unsafe_offset((j - a) * l)
            else:
                vp = vt.unsafe_offset((j - b) * l)
            acc += s[j] * vp[h * PHD + c]
        o[i * l + h * PHD + c] = acc * inv


def to_f16_from_bf16(src: U16P, dst: UnsafePointer[Float16, MutAnyOrigin], total: Int32):
    """OPT/F16: bf16 weights rounded to fp16."""
    var e = global_idx.x
    if e >= Int(total):
        return
    dst[e] = bitcast[DType.float32](UInt32(src[e]) << 16).cast[DType.float16]()
