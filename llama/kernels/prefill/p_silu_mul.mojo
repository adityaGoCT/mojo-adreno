# Prefill MLP activation: silu_mul.mojo for every prompt token (grid F/256 x tokens, 256 threads).
from max.gpu import block_idx, thread_idx
from max.gpu.host import DeviceContext
from std.math import exp

comptime F = 8192


def p_silu_mul(gu: UnsafePointer[Float32, MutAnyOrigin], a: UnsafePointer[Float32, MutAnyOrigin]):
    var i = Int(block_idx.x) * 256 + Int(thread_idx.x)
    var r = Int(block_idx.y)
    var g = gu[r * 2 * F + i]
    a[r * F + i] = g / (1.0 + exp(-g)) * gu[r * 2 * F + F + i]


def main() raises:
    var ctx = DeviceContext()
    var gu = ctx.enqueue_create_buffer[DType.float32](4 * 2 * F)
    var a = ctx.enqueue_create_buffer[DType.float32](4 * F)
    ctx.enqueue_function[p_silu_mul](gu, a, grid_dim=(F // 256, 4), block_dim=256)
    ctx.synchronize()
