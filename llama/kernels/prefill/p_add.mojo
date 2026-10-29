# Prefill residual: x += y for every prompt token (grid D/256 x tokens, 256 threads).
from max.gpu import block_idx, thread_idx
from max.gpu.host import DeviceContext

comptime D = 2048


def p_add(x: UnsafePointer[Float32, MutAnyOrigin], y: UnsafePointer[Float32, MutAnyOrigin]):
    var i = Int(block_idx.y) * D + Int(block_idx.x) * 256 + Int(thread_idx.x)
    x[i] = x[i] + y[i]


def main() raises:
    var ctx = DeviceContext()
    var x = ctx.enqueue_create_buffer[DType.float32](4 * D)
    var y = ctx.enqueue_create_buffer[DType.float32](4 * D)
    ctx.enqueue_function[p_add](x, y, grid_dim=(D // 256, 4), block_dim=256)
    ctx.synchronize()
