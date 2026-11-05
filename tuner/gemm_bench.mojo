# gemm_bench: times candidates of bonsai/kernels/prefill.mojo's ternary matrix kernel (p_gemm_t2v) on
# the phone, through MAX's DeviceContext and the Vulkan driver plugin: the device side of tuner/'s
# runner. runner.py writes a round's candidates into a copy of this file (the line `# CANDIDATES`
# and the call after it become one `b.add[...]("name")` call each), builds it for Android and runs it:
#
#   MODULAR_DRIVER_PLUGINS=vulkan@<dir>/libM_driver_vulkan.so gemm_bench <rounds> <n,k,rows> ...
#
# For each matrix shape: random X, W and scales; the reference is p_gemm_t2 (the tile shape every
# model ran so far, checked against PyTorch and MLX end to end). Each candidate runs once and must
# match it to 1e-5 of Y's largest value; a candidate the driver rejects or that mismatches is out.
# Then `rounds` rounds over the candidates in turn (so a clock change hits all of them alike), each
# timing enough back-to-back launches for about 40 ms. Output, per candidate:
#   RESULT <n> <k> <rows> <name> <median ms> <TFLOP/s>     or     FAILED <n> <k> <rows> <name> <why>
from std.sys import argv
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import prefill


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


struct Bench(Movable):
    var ctx: DeviceContext
    var x: DeviceBuffer[DType.float32]
    var w: DeviceBuffer[DType.uint32]
    var s: DeviceBuffer[DType.float16]
    var y: DeviceBuffer[DType.float32]
    var expect: List[Float32]
    var got: List[Float32]
    var n: Int
    var k: Int
    var rows: Int
    var reps: Int
    var names: List[String]
    var times: List[List[Float64]]
    var timing: Bool  # False: check each candidate; True: time the ones that passed
    var index: Int

    def __init__(out self, ctx: DeviceContext, max_x: Int, max_w: Int, max_s: Int, max_y: Int) raises:
        self.ctx = ctx
        self.x = ctx.enqueue_create_buffer[DType.float32](max_x)
        self.w = ctx.enqueue_create_buffer[DType.uint32](max_w)
        self.s = ctx.enqueue_create_buffer[DType.float16](max_s)
        self.y = ctx.enqueue_create_buffer[DType.float32](max_y)
        self.expect = List[Float32]()
        self.got = List[Float32]()
        self.n = 0
        self.k = 0
        self.rows = 0
        self.reps = 1
        self.names = List[String]()
        self.times = List[List[Float64]]()
        self.timing = False
        self.index = 0

    def shape(mut self, n: Int, k: Int, rows: Int) raises:
        """Random X (-1 .. 1), W (any codes) and scales (0.01 .. 0.05), then the reference Y."""
        self.n = n
        self.k = k
        self.rows = rows
        var seed: UInt32 = UInt32(n * 31 + k * 7 + rows)
        var hx = List[Float32](length=rows * k, fill=0)
        for i in range(rows * k):
            seed = seed * 1664525 + 1013904223
            hx[i] = Float32(Int(seed >> 8)) / Float32(1 << 23) - 1
        var hw = List[UInt32](length=k // 16 * n, fill=0)
        for i in range(k // 16 * n):
            seed = seed * 1664525 + 1013904223
            hw[i] = seed
        var hs = List[Float16](length=k // 128 * n, fill=0)
        for i in range(k // 128 * n):
            seed = seed * 1664525 + 1013904223
            hs[i] = Float16(0.01 + 0.04 * Float32(Int(seed >> 8)) / Float32(1 << 24))
        self.ctx.enqueue_copy(self.x.create_sub_buffer[DType.float32](0, rows * k), hx.unsafe_ptr())
        self.ctx.enqueue_copy(self.w.create_sub_buffer[DType.uint32](0, k // 16 * n), hw.unsafe_ptr())
        self.ctx.enqueue_copy(self.s.create_sub_buffer[DType.float16](0, k // 128 * n), hs.unsafe_ptr())
        self.expect = List[Float32](length=rows * n, fill=0)
        self.got = List[Float32](length=rows * n, fill=0)
        self.ctx.enqueue_memset(self.y, Float32(0))
        self.launch[2, 2, 1, 1, 16, 0, 1, False, False]()
        self.ctx.enqueue_copy(self.expect.unsafe_ptr(), self.y.create_sub_buffer[DType.float32](0, rows * n))
        self.ctx.synchronize()
        var t0 = now_ms()
        self.launch[2, 2, 1, 1, 16, 0, 1, False, False]()
        self.ctx.synchronize()
        var ms = now_ms() - t0
        self.reps = max(2, min(20, Int(40 / max(ms, 0.1)) + 1))
        self.names = List[String]()
        self.times = List[List[Float64]]()

    def launch[WM: Int, WN: Int, TM: Int, TN: Int, BK: Int, PAD: Int, STAGES: Int, PF: Bool, XG: Bool](
        mut self
    ) raises:
        self.ctx.enqueue_function[prefill.p_gemm_t2v[WM, WN, TM, TN, BK, PAD, STAGES, PF, XG]](
            self.x, self.w, self.s, self.y, Int32(self.n), Int32(self.k),
            grid_dim=Dim(self.n // (WN * TN * 64), self.rows // (WM * TM * 64)), block_dim=WM * WN * 64)

    def add[WM: Int, WN: Int, TM: Int, TN: Int, BK: Int, PAD: Int, STAGES: Int, PF: Bool, XG: Bool](
        mut self, name: String
    ) raises:
        """Check (first pass) or time (later passes) one candidate, if the shape divides its tiles."""
        if self.rows % (WM * TM * 64) != 0 or self.n % (WN * TN * 64) != 0 or self.k % BK != 0:
            return
        if not self.timing:
            try:
                self.ctx.enqueue_memset(self.y, Float32(0))
                self.launch[WM, WN, TM, TN, BK, PAD, STAGES, PF, XG]()
                self.ctx.enqueue_copy(self.got.unsafe_ptr(), self.y.create_sub_buffer[DType.float32](0, self.rows * self.n))
                self.ctx.synchronize()
            except e:
                print("FAILED", self.n, self.k, self.rows, name, "launch:", e)
                return
            var worst: Float32 = 0
            var top: Float32 = 0
            for i in range(self.rows * self.n):
                worst = max(worst, abs(self.got[i] - self.expect[i]))
                top = max(top, abs(self.expect[i]))
            if not (worst <= top * 1e-5):
                print("FAILED", self.n, self.k, self.rows, name, "max abs error", worst, "of", top)
                return
            self.names.append(name)
            self.times.append(List[Float64]())
            return
        if self.index >= len(self.names) or self.names[self.index] != name:
            return  # failed its check
        var t0 = now_ms()
        for _ in range(self.reps):
            self.launch[WM, WN, TM, TN, BK, PAD, STAGES, PF, XG]()
        self.ctx.synchronize()
        self.times[self.index].append((now_ms() - t0) / Float64(self.reps))
        self.index += 1

    def report(self):
        var flop = 2.0 * Float64(self.rows) * Float64(self.n) * Float64(self.k)
        for i in range(len(self.names)):
            var t = self.times[i].copy()
            sort(t)
            var ms = t[len(t) // 2]
            print("RESULT", self.n, self.k, self.rows, self.names[i], round(ms, 4), round(flop / ms / 1e9, 3))


def candidates(mut b: Bench) raises:
    # CANDIDATES
    b.add[2, 2, 1, 1, 16, 0, 1, False, False]("2x2-1x1-k16-p0-s1")


def main() raises:
    var args = argv()
    var rounds = Int(args[1])
    var shapes = List[List[Int]]()
    var mx = 0
    var mw = 0
    var ms = 0
    var my = 0
    for i in range(2, len(args)):
        var f = String(args[i]).split(",")
        var n = Int(f[0])
        var k = Int(f[1])
        var rows = Int(f[2])
        shapes.append([n, k, rows])
        mx = max(mx, rows * k)
        mw = max(mw, k // 16 * n)
        ms = max(ms, k // 128 * n)
        my = max(my, rows * n)
    var ctx = DeviceContext(api="vulkan")
    print("device:", ctx.name())
    var b = Bench(ctx, mx, mw, ms, my)
    for sh in shapes:
        var t0 = now_ms()
        b.shape(sh[0], sh[1], sh[2])
        b.timing = False
        candidates(b)
        b.timing = True
        for _ in range(rounds):
            b.index = 0
            candidates(b)
        b.report()
        print("SHAPE", sh[0], sh[1], sh[2], len(b.names), "candidates passed,", b.reps, "launches a timing,",
              round((now_ms() - t0) / 1e3, 1), "s")
