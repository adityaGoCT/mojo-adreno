# Reading a reference's tensors and checking device buffers against them, for the vla/ programs.
from std.os import getenv
from std.time import perf_counter_ns, sleep
from max.gpu.host import DeviceBuffer, DeviceContext


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


def cool_down():
    """REPLAY_SLEEP=<seconds>: wait before the replay timing (a phone's clocks drop 5-12% while it is hot from the
    checks before it)."""
    var s = getenv("REPLAY_SLEEP")
    if s:
        try:
            var secs = Float64(Int(s))
            print("cooling down", Int(secs), "s before the replays")
            sleep(secs)
        except:
            pass


def read_f32(path: String) raises -> List[Float32]:
    var data = open(path, "r").read_bytes()
    var n = len(data) // 4
    var p = data.unsafe_ptr().unsafe_bitcast[Float32]()
    var out = List[Float32](length=n, fill=0)
    for i in range(n):
        out[i] = p[i]
    return out^


def read_i32(path: String) raises -> List[Int32]:
    var data = open(path, "r").read_bytes()
    var n = len(data) // 4
    var p = data.unsafe_ptr().unsafe_bitcast[Int32]()
    var out = List[Int32](length=n, fill=0)
    for i in range(n):
        out[i] = p[i]
    return out^


def fetch(ctx: DeviceContext, buf: DeviceBuffer[DType.float32], n: Int) raises -> List[Float32]:
    var host = List[Float32](length=n, fill=0)
    ctx.enqueue_copy(host.unsafe_ptr(), buf.create_sub_buffer[DType.float32](0, n))
    ctx.synchronize()
    return host^


struct Check(Copyable, Movable):
    var err: Float64
    var scale: Float64

    def __init__(out self):
        self.err = 0
        self.scale = 0

    def add(mut self, got: Float32, want: Float32):
        var e = abs(Float64(got) - Float64(want))
        if e != e:  # NaN
            e = 1e30
        self.err = max(self.err, e)
        self.scale = max(self.scale, abs(Float64(want)))


def compare(got: List[Float32], gld: Int, want: List[Float32], wld: Int, rows: List[Int], cols: Int) -> Check:
    """Max abs error of got's rows against want's (row r of `rows` is row r of want, row rows[r] of got)."""
    var c = Check()
    for r in range(len(rows)):
        for j in range(cols):
            c.add(got[rows[r] * gld + j], want[r * wld + j])
    return c^


def show(name: String, c: Check):
    print("check", name, ": max abs error", c.err, "(largest reference value", String(c.scale) + ")")


def span(n: Int) -> List[Int]:
    var r = List[Int]()
    for i in range(n):
        r.append(i)
    return r^
