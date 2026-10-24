# mojo_adreno: check=matmul dim=1024 local=256 outputs=64
from max.gpu import block_idx, thread_idx, barrier
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from std.memory import stack_allocation

comptime BM = 128  # workgroup tile of C: BM x BN, staged BK deep through shared memory
comptime BN = 128
comptime BK = 8
comptime TM = 8  # per-thread register tile of C: TM x TN (256 threads = BM / TM x BN / TN)
comptime TN = 8
comptime VM = 4  # a thread's rows (columns) come in contiguous chunks of VM (VN), strided across the
comptime VN = 4  # tile: VM = TM is fully contiguous, VM = 1 fully strided
comptime TY = BM // TM
comptime TX = BN // TN
comptime THREADS = TY * TX


# Thread row ty owns rows ty * VM + offm(i) for i < TM. Indices are written as (runtime base) +
# (compile-time offset), in that order: opt then keeps a thread's VM rows as one base plus constant
# offsets, which Mesa's compiler merges into vector shared-memory loads (2.4x on Turnip).
@always_inline
def offm(i: Int) -> Int:
    return (i // VM) * (TY * VM) + i % VM


@always_inline
def offn(j: Int) -> Int:
    return (j // VN) * (TX * VN) + j % VN


def matmul_regtile(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
                   c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    # C = A @ B for n x n row-major matrices, n a multiple of 128. Each thread keeps a TM x TN block of
    # C in registers: per k step it loads TM values of A and TN of B from shared memory and does
    # TM * TN FMAs (16 loads per 64 FMAs, against 2 loads per FMA in matmul_tiled_gpu.mojo).
    var As = stack_allocation[BK * BM, Float32, address_space=AddressSpace.SHARED]()  # k-major
    var Bs = stack_allocation[BK * BN, Float32, address_space=AddressSpace.SHARED]()
    var acc = stack_allocation[TM * TN, Float32]()  # registers once SROA has run
    var af = stack_allocation[TM, Float32]()
    var bf = stack_allocation[TN, Float32]()
    var dim = Int(n)
    var t = Int(thread_idx.x)
    var ty = t // TX
    var tx = t % TX
    var tiles = dim // BN
    var row0 = (Int(block_idx.x) // tiles) * BM
    var col0 = (Int(block_idx.x) % tiles) * BN
    comptime for i in range(TM * TN):
        acc[i] = 0
    for k0 in range(0, dim, BK):
        comptime for l in range(BM * BK // THREADS):  # each thread stages 4 elements of A and of B
            var e = t + l * THREADS
            As[(e % BK) * BM + e // BK] = a[(row0 + e // BK) * dim + k0 + e % BK]
            Bs[e] = b[(k0 + e // BN) * dim + col0 + e % BN]
        barrier()
        for k in range(BK):
            comptime for i in range(TM):
                af[i] = As[k * BM + ty * VM + offm(i)]
            comptime for j in range(TN):
                bf[j] = Bs[k * BN + tx * VN + offn(j)]
            comptime for i in range(TM):
                comptime for j in range(TN):
                    acc[i * TN + j] += af[i] * bf[j]
        barrier()
    comptime for i in range(TM):
        comptime for j in range(TN):
            c[(row0 + ty * VM + offm(i)) * dim + col0 + tx * VN + offn(j)] = acc[i * TN + j]


def main() raises:
    comptime n = 256
    var ctx = DeviceContext()
    var a = ctx.enqueue_create_buffer[DType.float32](n * n)
    var b = ctx.enqueue_create_buffer[DType.float32](n * n)
    var c = ctx.enqueue_create_buffer[DType.float32](n * n)
    ctx.enqueue_function[matmul_regtile](a, b, c, Int64(n), grid_dim=(n // BM) * (n // BN), block_dim=THREADS)
    ctx.synchronize()
