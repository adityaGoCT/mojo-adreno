# VLA-JEPA's own kernels, next to vla/kernels (vgemm, vattn, vrow), VLA-Adapter's (vak) and TurboVLA's (tk):
# Qwen3's per-head RMSNorm of q and k, the DiT's adaptive LayerNorm (no affine; x (1 + scale) + shift from the
# timestep's modulation row), and the ViT's position embedding as Qwen3-VL interpolates it (four rows of the learned
# 48 x 48 grid, bilinear weights given). fp32; reductions through shared memory and barriers, as vla/kernels do.
from std.math import rsqrt
from std.memory import stack_allocation
from max.gpu import barrier, block_idx, global_idx, thread_idx
from max.gpu.memory import AddressSpace

from vrow import block_sum

comptime F32P = UnsafePointer[Float32, MutAnyOrigin]
comptime I32P = UnsafePointer[Int32, MutAnyOrigin]


def head_rms(x: F32P, w: F32P, ld: Int32, col0: Int32, hd: Int32, eps: Float32):
    """In place, x[row, col0 + h hd .. + hd] = rms-normalized * w (hd values): row block_idx.x, head block_idx.y."""
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var d = Int(hd)
    var xr = x.unsafe_offset(Int(block_idx.x) * Int(ld) + Int(col0) + Int(block_idx.y) * d)
    var s2 = Float32(0)
    for j in range(t, d, 64):
        s2 += xr[j] * xr[j]
    var r = rsqrt(block_sum(red, t, s2) / Float32(d) + eps)
    for j in range(t, d, 64):
        xr[j] = (xr[j] * r) * w[j]


def adaln(x: F32P, y: F32P, mod: F32P, soff: Int32, hoff: Int32, d: Int32, eps: Float32):
    """y = LN(x) (no affine) * (1 + mod[soff + c]) + mod[hoff + c] for row block_idx.x (rows of d). mod of zeros: a
    LayerNorm without affine."""
    var red = stack_allocation[64, Float32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    var dd = Int(d)
    var xr = x.unsafe_offset(Int(block_idx.x) * dd)
    var yr = y.unsafe_offset(Int(block_idx.x) * dd)
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
        yr[j] = ((xr[j] - mean) * r) * (1 + mod[Int(soff) + j]) + mod[Int(hoff) + j]


def pos_bilinear(table: F32P, dst: F32P, idx: I32P, wts: F32P, d: Int32, total: Int32):
    """dst[p] = sum over k < 4 of wts[4 p + k] table[idx[4 p + k]] (rows of d)."""
    var e = global_idx.x
    if e >= Int(total):
        return
    var dd = Int(d)
    var p = e // dd
    var c = e % dd
    var acc = Float32(0)
    for k in range(4):
        acc += wts[4 * p + k] * table[Int(idx[4 * p + k]) * dd + c]
    dst[e] = acc
