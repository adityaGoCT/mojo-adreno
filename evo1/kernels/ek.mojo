# Evo-1's own kernels, next to vla/kernels (vgemm, vattn, vrow) and VLA-Adapter's (vak: widen, scale_add, relu_rows):
# InternVL's pixel shuffle (v2) of the ViT's 32 x 32 patches into 16 x 16 tokens of 4096, row broadcasts (the time
# embedding, the action encoder's position encoding after ReLU), the head's cross-attention (8 heads of 112 over the
# 1025 context rows), and the Euler step with the action mask. fp32 throughout.
from std.math import exp
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace

from vrow import block_sum

comptime F32P = UnsafePointer[Float32, MutAnyOrigin]
comptime NEG: Float32 = -3.0e38
comptime MAXK = 1088
comptime HHD = 112


def pixel_shuffle(vit: F32P, dst: F32P, img_rows: Int32, d: Int32, total: Int32):
    """InternVL's extract_feature, ps_version v2, scale 0.5: token t = 16 y2 + x2 of image n, channel
    (2 dy + dx) d + c, from patch (2 y2 + dy, 2 x2 + dx), i.e. ViT row 1 + 32 (2 y2 + dy) + 2 x2 + dx of the image's
    block (img_rows apart; row 0 is CLS)."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var dd = Int(d)
    var w = 4 * dd
    var r = e // w
    var ch = e % w
    var n = r // 256
    var t = r % 256
    var y2 = t // 16
    var x2 = t % 16
    var q = ch // dd
    var c = ch % dd
    var dy = q // 2
    var dx = q % 2
    var src = n * Int(img_rows) + 1 + 32 * (2 * y2 + dy) + 2 * x2 + dx
    dst[e] = vit[src * dd + c]


def add_row(x: F32P, v: F32P, voff: Int32, n: Int32, total: Int32):
    """x[r, :n] += v[voff + :n] (rows packed): the time embedding on every action token."""
    var e = global_idx.x
    if e >= Int(total):
        return
    x[e] += v[Int(voff) + e % Int(n)]


def relu_add(x: F32P, pe: F32P, n: Int32, total: Int32):
    """x = relu(x) + pe (both rows of n, packed): the action encoder's W1, then its position encoding."""
    var e = global_idx.x
    if e >= Int(total):
        return
    x[e] = max(x[e], Float32(0)) + pe[e]


def masked(a: F32P, mask: F32P, dst: F32P, n: Int32, total: Int32):
    """out = a * mask (the mask per column of n): the head's input each step."""
    var e = global_idx.x
    if e >= Int(total):
        return
    dst[e] = a[e] * mask[e % Int(n)]


def euler(a: F32P, v: F32P, dt: Float32, total: Int32):
    """a += dt v: one flow-matching step (the actions unmasked, as Evo-1 keeps them)."""
    var e = global_idx.x
    if e >= Int(total):
        return
    a[e] = a[e] + dt * v[e]


def cross_attention(q: F32P, k: F32P, v: F32P, o: F32P, ldq: Int32, ldk: Int32, ldo: Int32, nk: Int32,
                    scale: Float32):
    """Query row block_idx.y, head block_idx.x (112 wide): softmax(scale q K^T) V over the nk context rows, no mask
    (Evo-1's nn.MultiheadAttention). nk <= 1088."""
    var s = stack_allocation[MAXK, Float32, address_space=AddressSpace.SHARED]()
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var h = Int(block_idx.x)
    var i = Int(block_idx.y)
    var t = Int(thread_idx.x)
    var n = Int(nk)
    var qp = q.unsafe_offset(i * Int(ldq) + h * HHD)
    var mx = NEG
    for j in range(t, n, 64):
        var kp = k.unsafe_offset(j * Int(ldk) + h * HHD)
        var acc = Float32(0)
        for c in range(HHD):
            acc += qp[c] * kp[c]
        acc = acc * scale
        s[j] = acc
        mx = max(mx, acc)
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
    for c in range(t, HHD, 64):
        var acc = Float32(0)
        for j in range(n):
            acc += s[j] * v[j * Int(ldk) + h * HHD + c]
        o[i * Int(ldo) + h * HHD + c] = acc * inv
