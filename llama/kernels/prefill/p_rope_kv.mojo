# Prefill RoPE: rope_kv.mojo for every prompt token, token t at position t (grid 5 x tokens, 256
# threads): q rotated in place in row t of qkv, k rotated and stored with v into the KV cache.
from max.gpu import block_idx, thread_idx
from max.gpu.host import DeviceContext

comptime H = 32
comptime KVH = 8
comptime HD = 64
comptime HALF = HD // 2
comptime QKV = (H + 2 * KVH) * HD
comptime MAXPOS = 512


def p_rope_kv(qkv: UnsafePointer[Float32, MutAnyOrigin], cos: UnsafePointer[Float32, MutAnyOrigin],
              sin: UnsafePointer[Float32, MutAnyOrigin], kc: UnsafePointer[Float32, MutAnyOrigin],
              vc: UnsafePointer[Float32, MutAnyOrigin]):
    var t = Int(block_idx.x) * 256 + Int(thread_idx.x)
    var p = Int(block_idx.y)
    var row = p * QKV
    var isq = t < H * HALF
    var e = t if isq else t - H * HALF
    var h = e // HALF
    var i = e % HALF
    var off = row + (0 if isq else H * HD) + h * HD + i
    var a = qkv[off]
    var b = qkv[off + HALF]
    var c = cos[p * HALF + i]
    var s = sin[p * HALF + i]
    var ra = a * c - b * s
    var rb = b * c + a * s
    if isq:
        qkv[off] = ra
        qkv[off + HALF] = rb
    else:
        var dst = (h * MAXPOS + p) * HD + i
        kc[dst] = ra
        kc[dst + HALF] = rb
        vc[dst] = qkv[row + (H + KVH) * HD + h * HD + i]
        vc[dst + HALF] = qkv[row + (H + KVH) * HD + h * HD + i + HALF]


def main() raises:
    var ctx = DeviceContext()
    var qkv = ctx.enqueue_create_buffer[DType.float32](4 * QKV)
    var cs = ctx.enqueue_create_buffer[DType.float32](MAXPOS * HALF)
    var sn = ctx.enqueue_create_buffer[DType.float32](MAXPOS * HALF)
    var kc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    var vc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    ctx.enqueue_function[p_rope_kv](qkv, cs, sn, kc, vc, grid_dim=(5, 4), block_dim=256)
    ctx.synchronize()
