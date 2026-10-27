# Llama RoPE (rotate_half convention, cos/sin tables from the host) on the fused qkv vector:
# q (32 heads x 64) is rotated in place; k (8 heads) is rotated and stored, with v, into this layer's
# KV cache at position pos. Launch exactly 5 x 256 threads: 1024 q pairs, then 256 k pairs (each k
# thread also copies two v values). A single if/else: LLVM 22's SPIR-V structurizer emits invalid
# structured control flow for an if/elif/elif chain whose branches share one exit.
from max.gpu import global_idx
from max.gpu.host import DeviceContext

comptime H = 32
comptime KVH = 8
comptime HD = 64
comptime HALF = HD // 2
comptime MAXPOS = 512


def rope_kv(qkv: UnsafePointer[Float32, MutAnyOrigin], cos: UnsafePointer[Float32, MutAnyOrigin],
            sin: UnsafePointer[Float32, MutAnyOrigin], kc: UnsafePointer[Float32, MutAnyOrigin],
            vc: UnsafePointer[Float32, MutAnyOrigin], pos: Int64):
    var t = Int(global_idx.x)
    var p = Int(pos)
    var isq = t < H * HALF
    var e = t if isq else t - H * HALF  # pair index within q or within k
    var h = e // HALF
    var i = e % HALF
    var off = (0 if isq else H * HD) + h * HD + i
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
        vc[dst] = qkv[(H + KVH) * HD + h * HD + i]
        vc[dst + HALF] = qkv[(H + KVH) * HD + h * HD + i + HALF]


def main() raises:
    var ctx = DeviceContext()
    var qkv = ctx.enqueue_create_buffer[DType.float32]((H + 2 * KVH) * HD)
    var cs = ctx.enqueue_create_buffer[DType.float32](MAXPOS * HALF)
    var sn = ctx.enqueue_create_buffer[DType.float32](MAXPOS * HALF)
    var kc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    var vc = ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD)
    ctx.enqueue_function[rope_kv](qkv, cs, sn, kc, vc, Int64(0), grid_dim=5, block_dim=256)
    ctx.synchronize()
