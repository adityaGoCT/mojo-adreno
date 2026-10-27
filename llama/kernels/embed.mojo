# Llama 3.2 1B: x = row `row` of an fp16 embedding-table chunk, as fp32. One thread per element.
from max.gpu import global_idx
from max.gpu.host import DeviceContext

comptime D = 2048


def embed(e: UnsafePointer[Float16, MutAnyOrigin], x: UnsafePointer[Float32, MutAnyOrigin], row: Int64):
    var i = Int(global_idx.x)
    x[i] = e[Int(row) * D + i].cast[DType.float32]()


def main() raises:
    var ctx = DeviceContext()
    var e = ctx.enqueue_create_buffer[DType.float16](4 * D)
    var x = ctx.enqueue_create_buffer[DType.float32](D)
    ctx.enqueue_function[embed](e, x, Int64(1), grid_dim=D // 256, block_dim=256)
    ctx.synchronize()
