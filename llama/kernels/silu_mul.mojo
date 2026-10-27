# Llama MLP activation on the fused gate/up vector: a = silu(gate) * up. One thread per element.
from max.gpu import global_idx
from max.gpu.host import DeviceContext
from std.math import exp

comptime F = 8192


def silu_mul(gu: UnsafePointer[Float32, MutAnyOrigin], a: UnsafePointer[Float32, MutAnyOrigin]):
    var i = Int(global_idx.x)
    var g = gu[i]
    a[i] = g / (1.0 + exp(-g)) * gu[F + i]


def main() raises:
    var ctx = DeviceContext()
    var gu = ctx.enqueue_create_buffer[DType.float32](2 * F)
    var a = ctx.enqueue_create_buffer[DType.float32](F)
    ctx.enqueue_function[silu_mul](gu, a, grid_dim=F // 256, block_dim=256)
    ctx.synchronize()
