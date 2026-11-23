# An fp16 tile built in shared memory by plain stores, then read by a cooperative-matrix load, on the Adreno 840.
#
# The fork's SPIR-V backend used to address shared arrays with OpInBoundsAccessChain, which the 840's driver
# (512.842.19) resolves for 16-bit types as if each element took twice its size, while its cooperative matrices read
# the halves packed: every other half of a tile went missing (NaN in odd columns). It now emits OpAccessChain for
# shared arrays of 16-bit components (32-bit ones keep the inbounds form, which is faster there). It also
# types a shared array that fp16 cooperative matrices read, and that plain code writes 8 (or 4) bytes at a time, as
# an array of <4 x half> (or <2 x half>): a 16-byte store of 8 halves becomes 2 stores, not 8 (the matrix load counts
# its offset and stride in those vectors).
#
# One subgroup of 64 threads builds B, 16 x 128 fp16 (two 16 x 64 tiles side by side, rows 128 apart), then computes
# C (64 x 128) = A (64 x 16) x B, one 64 x 64 product per tile:
#   smem_copy:    B's halves copied from a buffer, 8 halves (4 words) a store   -> a <4 x half> array, 2 stores
#   smem_compute: B's halves computed in the kernel (as an int4 unpack would), 8 halves a store -> <4 x half>
#   smem_scalar:  B's halves computed in the kernel, one half a store (threads 1 half apart) -> a half array
# Each is checked against the product on the CPU; the values are multiples of 1/8 and 1/64, so fp16 is exact.
#
#   python3 android/build.py smempack; then on the phone: ./smem_pack
from std.memory import bitcast, stack_allocation
from max.gpu import barrier, thread_idx
from max.gpu.host import DeviceContext
from max.gpu.memory import AddressSpace
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

comptime F16 = UnsafePointer[Float16, MutAnyOrigin]
comptime U32 = UnsafePointer[UInt32, MutAnyOrigin]
comptime BW = 128  # B's width in halves: two tiles


def b_value(kr: Int, n: Int) -> Float32:
    """B[kr][n]: a multiple of 1/8 in [-1, 7/8]."""
    return Float32((kr * 7 + n * 3) % 16 - 8) * 0.125


@always_inline
def product(a: F16, sb: UnsafePointer[UInt32, MutUntrackedOrigin, address_space=AddressSpace.SHARED], c: F16):
    var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(a, 16)
    var sh = sb.unsafe_bitcast[Float16]()
    comptime for j in range(2):
        var bt = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load(sh.unsafe_offset(64 * j), BW)
        var acc = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
        acc = at.multiply_add(bt, acc)
        acc.store(c + 64 * j, BW)


def smem_copy(a: F16, b: U32, c: F16):
    var sb = stack_allocation[16 * BW // 2, DType.uint32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    comptime for i in range(16 * BW // 8 // 64):
        var v = i * 64 + t  # the v-th run of 8 halves
        sb.unsafe_store(4 * v, b.load[width=4](4 * v))
    barrier()
    product(a, sb, c)


def smem_compute(a: F16, c: F16):
    var sb = stack_allocation[16 * BW // 2, DType.uint32, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    comptime for i in range(16 * BW // 8 // 64):
        var v = i * 64 + t
        var kr = v // (BW // 8)
        var n0 = v % (BW // 8) * 8
        var q = SIMD[DType.int32, 8]()
        comptime for e in range(8):
            q[e] = Int32((kr * 7 + (n0 + e) * 3) % 16 - 8)
        var h = q.cast[DType.float16]() * SIMD[DType.float16, 8](0.125)
        sb.unsafe_store(4 * v, bitcast[DType.uint32, 4](h))
    barrier()
    product(a, sb, c)


def smem_scalar(a: F16, c: F16):
    var sb = stack_allocation[16 * BW, DType.float16, address_space=AddressSpace.SHARED]()
    var t = Int(thread_idx.x)
    comptime for i in range(16 * BW // 64):
        var e = i * 64 + t
        sb.unsafe_store(e, Float16(Int32((e // BW * 7 + e % BW * 3) % 16 - 8)) * Float16(0.125))
    barrier()
    var at = CoopMatrix[DType.float16, 64, 16, MATRIX_A].load(a, 16)
    comptime for j in range(2):
        var bt = CoopMatrix[DType.float16, 16, 64, MATRIX_B].load(sb.unsafe_offset(64 * j), BW)
        var acc = CoopMatrix[DType.float16, 64, 64, ACCUMULATOR].zero()
        acc = at.multiply_add(bt, acc)
        acc.store(c + 64 * j, BW)


def main() raises:
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var ha = List[Float16](length=64 * 16, fill=0)
    for r in range(64):
        for kr in range(16):
            ha[r * 16 + kr] = Float16(Float32((r * 5 + kr * 11) % 16 - 8) * 0.125)
    var hb = List[Float16](length=16 * BW, fill=0)
    for kr in range(16):
        for n in range(BW):
            hb[kr * BW + n] = Float16(b_value(kr, n))
    var want = List[Float32](length=64 * BW, fill=0)
    for r in range(64):
        for n in range(BW):
            var s = Float32(0)
            for kr in range(16):
                s += Float32(ha[r * 16 + kr]) * b_value(kr, n)
            want[r * BW + n] = s
    var a = ctx.enqueue_create_buffer[DType.float16](64 * 16)
    var b = ctx.enqueue_create_buffer[DType.float16](16 * BW)
    var c = ctx.enqueue_create_buffer[DType.float16](64 * BW)
    ctx.enqueue_copy(a, ha.unsafe_ptr())
    ctx.enqueue_copy(b, hb.unsafe_ptr())
    var got = List[Float16](length=64 * BW, fill=0)
    var failed = 0
    for kernel in range(3):
        var nan = List[Float16](length=64 * BW, fill=Float16(0))
        for i in range(len(nan)):
            nan[i] = bitcast[DType.float16, 1](UInt16(0x7E00))
        ctx.enqueue_copy(c, nan.unsafe_ptr())
        if kernel == 0:
            ctx.enqueue_function[smem_copy](a, b.create_sub_buffer[DType.uint32](0, 16 * BW // 2), c, grid_dim=1,
                                            block_dim=64)
        elif kernel == 1:
            ctx.enqueue_function[smem_compute](a, c, grid_dim=1, block_dim=64)
        else:
            ctx.enqueue_function[smem_scalar](a, c, grid_dim=1, block_dim=64)
        ctx.enqueue_copy(got.unsafe_ptr(), c)
        ctx.synchronize()
        var bad = 0
        var odd_bad = 0
        var worst = Float32(0)
        for i in range(64 * BW):
            var d = abs(Float32(got[i]) - want[i])
            if not (d <= 0):
                bad += 1
                if i % 2 == 1:
                    odd_bad += 1
                if d == d:
                    worst = max(worst, d)
        var name = "smem_copy" if kernel == 0 else ("smem_compute" if kernel == 1 else "smem_scalar")
        if bad:
            failed += 1
            print(name, ": FAIL,", bad, "of", 64 * BW, "wrong (", odd_bad, "in odd columns ), largest difference", worst)
            print("  C[0][0:8]:", got[0], got[1], got[2], got[3], got[4], got[5], got[6], got[7])
            print("  want     :", want[0], want[1], want[2], want[3], want[4], want[5], want[6], want[7])
        else:
            print(name, ": PASS, all", 64 * BW, "exact")
    print("ALL PASS" if failed == 0 else "FAILED")
