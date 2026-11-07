# LFM2.5-2.6B (LiquidAI, the QAD Q4_0 GGUF) as MAX DeviceContext launches of lfm2/kernels/lk.mojo. The sizes, the
# layer types and the tensors come from export.py's manifest; the weights from convert.c's file in one of two storages:
#   q4   the GGUF's own int4 (Q4_0) matrices and Q6_K tied embedding/head (the optimized GPU path)
#   f16  every matrix dequantized to fp16 (the baseline GPU path)
# Activations, the K/V cache (8 attention layers) and the conv state (22 conv layers, a ring of 3 rows) are fp32.
#
# Token ids live on the GPU (ids[position]): the embedding reads them there and the argmax writes the next one, so a
# decode step never waits on the host for its input. step() runs one position; prefill() a batch of prompt rows,
# its projections as matrix products (q4: on the matrix units; f16: scalar tiles).
from std.collections import Dict
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import dsk
import lk

comptime PMAX = 512  # prompt rows a prefill batch holds (a multiple of gemm_q4's 128)
comptime TAPS = (2, 9, 17, 21, 27)  # the layers whose residual stream the DSpark drafter reads


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


struct LFM2(Movable):
    var ctx: DeviceContext
    var D: Int
    var L: Int
    var H: Int
    var KVH: Int
    var F: Int
    var V: Int
    var CAP: Int
    var q4: Bool
    var attn: List[Bool]
    var words: Dict[String, DeviceBuffer[DType.uint32]]
    var halves: Dict[String, DeviceBuffer[DType.float16]]
    var floats: Dict[String, DeviceBuffer[DType.float32]]
    var bytes: Int
    var kc: Dict[Int, DeviceBuffer[DType.float32]]
    var vc: Dict[Int, DeviceBuffer[DType.float32]]
    var cs: Dict[Int, DeviceBuffer[DType.float32]]
    var rope: DeviceBuffer[DType.float32]
    var ids: DeviceBuffer[DType.int32]  # [CAP + 1]: the token at each position
    var x: DeviceBuffer[DType.float32]  # rows of PMAX: the residual stream
    var xn: DeviceBuffer[DType.float32]
    var mix: DeviceBuffer[DType.float32]  # the conv's B | C | x rows, or the attention's q | k | v rows
    var att: DeviceBuffer[DType.float32]
    var tmp: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]
    var act: DeviceBuffer[DType.float32]
    var logits: DeviceBuffer[DType.float32]
    var tap_on: Bool  # prefill and verify keep the TAPS layers' rows in `taps` (for the drafter)
    var taps: DeviceBuffer[DType.float32]  # [PMAX, 5 D]
    var vbx: Dict[Int, DeviceBuffer[DType.float32]]  # verify: each conv layer's B x rows [MR, D]
    var vlog: DeviceBuffer[DType.float32]  # verify: logits rows [MR, V]
    var vt: DeviceBuffer[DType.int32]  # verify: each row's argmax
    var head8: Bool  # few-row heads read the int8 copy (build_head8)
    var hq8: DeviceBuffer[DType.uint32]  # the head as int8, 4 a word
    var hs16: DeviceBuffer[DType.float32]  # its scale per 16
    var dump: String  # prefill: append each layer's residual stream rows (fp32) to this file (stage checks)
    var wide: Bool  # decode: int4 rows a block of 32 (16 bytes) a lane a step (LFM2_GEMV=word: a word a lane)
    var prof: Bool  # step(): wait after each launch and add its time to times[kind] (LFM2_PROFILE)
    var times: Dict[String, Float64]
    var mark: Float64

    def __init__(out self, ctx: DeviceContext, dir: String, bin: String) raises:
        """dir: export.py's manifest.txt (of the storage) and rope.f32; bin: convert's weight file."""
        self.ctx = ctx
        var lines = open(dir + "/manifest.txt", "r").read().splitlines()
        var head = lines[0].split(" ")
        if len(head) < 2 or head[0] != "lfm2":
            raise Error(dir + "/manifest.txt: not an lfm2 manifest")
        var cfg = Dict[String, String]()
        for i in range(2, len(head) - 1, 2):
            cfg[String(head[i])] = String(head[i + 1])
        self.D = Int(cfg["D"])
        self.L = Int(cfg["L"])
        self.H = Int(cfg["H"])
        self.KVH = Int(cfg["KVH"])
        self.F = Int(cfg["F"])
        self.V = Int(cfg["V"])
        self.CAP = Int(cfg["CAP"])
        self.q4 = cfg["STORAGE"] == "q4"
        if Int(cfg["HD"]) != lk.HD or self.CAP > lk.KMAX:
            raise Error("head dim 64 and a context of at most 2048")
        self.attn = List[Bool]()
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.bytes = 0
        self.kc = Dict[Int, DeviceBuffer[DType.float32]]()
        self.vc = Dict[Int, DeviceBuffer[DType.float32]]()
        self.cs = Dict[Int, DeviceBuffer[DType.float32]]()
        for i in range(1, len(lines)):
            var f = lines[i].split(" ")
            if f[0] == "layer":
                self.attn.append(f[2] == "attn")
        if len(self.attn) != self.L:
            raise Error("manifest.txt: " + String(len(self.attn)) + " layers")
        var D = self.D
        var row = self.KVH * lk.HD
        for l in range(self.L):
            if self.attn[l]:
                self.kc[l] = ctx.enqueue_create_buffer[DType.float32](self.CAP * row)
                self.vc[l] = ctx.enqueue_create_buffer[DType.float32](self.CAP * row)
            else:
                self.cs[l] = ctx.enqueue_create_buffer[DType.float32](3 * D)
        self.rope = ctx.enqueue_create_buffer[DType.float32](self.CAP * lk.HD)
        self.ids = ctx.enqueue_create_buffer[DType.int32](self.CAP + PMAX)
        self.x = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.mix = ctx.enqueue_create_buffer[DType.float32](PMAX * 3 * D)
        self.att = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.tmp = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.gu = ctx.enqueue_create_buffer[DType.float32](PMAX * 2 * self.F)
        self.act = ctx.enqueue_create_buffer[DType.float32](PMAX * self.F)
        self.logits = ctx.enqueue_create_buffer[DType.float32](self.V)
        self.dump = ""
        self.tap_on = False
        self.taps = ctx.enqueue_create_buffer[DType.float32](PMAX * 5 * D)
        self.vbx = Dict[Int, DeviceBuffer[DType.float32]]()
        for l in range(self.L):
            if not self.attn[l]:
                self.vbx[l] = ctx.enqueue_create_buffer[DType.float32](dsk.MR * D)
        self.vlog = ctx.enqueue_create_buffer[DType.float32](dsk.MR * self.V)
        self.vt = ctx.enqueue_create_buffer[DType.int32](16)
        self.head8 = False
        self.hq8 = ctx.enqueue_create_buffer[DType.uint32](1)
        self.hs16 = ctx.enqueue_create_buffer[DType.float32](1)
        self.taps.enqueue_fill(0)
        self.prof = False
        self.wide = True
        self.times = Dict[String, Float64]()
        self.mark = 0
        self.reset()
        self.load(dir, bin)

    def reset(self) raises:
        """A new sequence: zero conv states, caches, ids and the padding rows the matrix products read."""
        for l in range(self.L):
            if self.attn[l]:
                self.kc[l].enqueue_fill(0)
                self.vc[l].enqueue_fill(0)
            else:
                self.cs[l].enqueue_fill(0)
        self.ids.enqueue_fill(0)
        self.xn.enqueue_fill(0)
        self.att.enqueue_fill(0)
        self.act.enqueue_fill(0)
        self.ctx.synchronize()

    def load(mut self, dir: String, bin: String) raises:
        """The weight file's tensors, as the manifest lists them ("<name> <offset> <bytes> <dtype> <shape>"), each in a
        device buffer of its type; and the RoPE table."""
        var lines = open(dir + "/manifest.txt", "r").read().splitlines()
        var f = open(bin, "r")
        for i in range(1, len(lines)):
            var p = lines[i].split(" ")
            if len(p) != 5:
                continue
            var name = String(p[0])
            var n = Int(p[2])
            _ = f.seek(Int(p[1]))
            var data = f.read_bytes(n)
            if len(data) != n:
                raise Error(bin + ": short read of " + name)
            if p[3] == "u32":
                var b = self.ctx.enqueue_create_buffer[DType.uint32](n // 4)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[UInt32]())
                self.words[name] = b
            elif p[3] == "f16":
                var b = self.ctx.enqueue_create_buffer[DType.float16](n // 2)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[Float16]())
                self.halves[name] = b
            else:
                var b = self.ctx.enqueue_create_buffer[DType.float32](n // 4)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[Float32]())
                self.floats[name] = b
            self.ctx.synchronize()  # `data` goes away
            self.bytes += n
        f.close()
        var r = open(dir + "/../rope.f32", "r").read_bytes()
        if len(r) != self.CAP * lk.HD * 4:
            raise Error("rope.f32: not " + String(self.CAP) + " rows")
        self.ctx.enqueue_copy(self.rope, r.unsafe_ptr().unsafe_bitcast[Float32]())
        self.ctx.synchronize()

    def set_ids(self, p0: Int, toks: List[Int]) raises:
        var v = List[Int32](length=len(toks), fill=0)
        for i in range(len(toks)):
            if toks[i] < 0 or toks[i] >= self.V:
                raise Error("token id out of range")
            v[i] = Int32(toks[i])
        self.ctx.enqueue_copy(self.ids.create_sub_buffer[DType.int32](p0, len(toks)), v.unsafe_ptr())
        self.ctx.synchronize()

    # ---- projections ------------------------------------------------------------------------------------------------

    def gemv(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], cols: Int,
             rows: Int) raises:
        if self.q4 and self.wide:
            self.ctx.enqueue_function[lk.gemv_q4[True]](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                        Int32(cols), grid_dim=rows, block_dim=64)
        elif self.q4:
            self.ctx.enqueue_function[lk.gemv_q4[False]](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                         Int32(cols), grid_dim=rows, block_dim=64)
        else:
            self.ctx.enqueue_function[lk.gemv_h](self.halves[name + ".h"], x, y, Int32(cols), grid_dim=rows,
                                                 block_dim=64)

    def gemm(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], n: Int, k: Int,
             rows: Int) raises:
        """y[rows, n] = x[rows, k] W^T (rows: a multiple of 128)."""
        if self.q4:
            self.ctx.enqueue_function[lk.gemm_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y, Int64(n),
                                                  Int64(k), grid_dim=Dim(n // 128, rows // 128), block_dim=256)
        else:
            self.ctx.enqueue_function[lk.gemm_h](self.halves[name + ".h"], x, y, Int32(n), Int32(k),
                                                 grid_dim=Dim(n // 64, rows // 64), block_dim=256)

    def embed(self, slot0: Int, count: Int) raises:
        """x rows = the embedding rows of ids[slot0 ..], and xn = layer 0's operator norm of them."""
        if self.q4:
            self.ctx.enqueue_function[lk.embed_q6](self.ids, Int32(slot0), self.words["embed.q"],
                                                   self.halves["embed.d"], self.x, Int32(self.D), grid_dim=count,
                                                   block_dim=64)
        else:
            self.ctx.enqueue_function[lk.embed_h](self.ids, Int32(slot0), self.halves["embed.h"], self.x,
                                                  Int32(self.D), grid_dim=count, block_dim=64)
        self.ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats["l0.in_norm"], self.xn, Int32(self.D),
                                               Int32(0), grid_dim=count, block_dim=64)

    def head(self, row: Int, slot: Int) raises:
        """The logits of xn's row `row` (final-normed), and their argmax into ids[slot]."""
        var x = self.xn.create_sub_buffer[DType.float32](row * self.D, self.D)
        if self.q4:
            self.ctx.enqueue_function[lk.head_q6](self.words["embed.q"], self.halves["embed.d"], x, self.logits,
                                                  Int32(self.D), grid_dim=self.V, block_dim=64)
        else:
            self.ctx.enqueue_function[lk.gemv_h](self.halves["embed.h"], x, self.logits, Int32(self.D),
                                                 grid_dim=self.V, block_dim=64)
        self.ctx.enqueue_function[lk.argmax](self.logits, Int32(self.V), self.ids, Int32(slot), grid_dim=1,
                                             block_dim=256)

    def write_rows(self, mut out: FileHandle, mut rows: List[Float32], count: Int) raises:
        self.ctx.enqueue_copy(rows.unsafe_ptr(), self.x.create_sub_buffer[DType.float32](0, count * self.D))
        self.ctx.synchronize()
        out.write_bytes(Span(unsafe_ptr=rows.unsafe_ptr().unsafe_bitcast[UInt8](), length=count * self.D * 4))

    def tick(mut self, kind: String) raises:
        """Profiling: wait for the launches so far and charge their time to `kind`."""
        if not self.prof:
            return
        self.ctx.synchronize()
        var t = Float64(perf_counter_ns()) / 1e6
        self.times[kind] = self.times.get(kind, 0.0) + (t - self.mark)
        self.mark = t

    def tap(self, l: Int, count: Int) raises:
        """If l is one of the drafter's TAPS and tapping is on: its residual stream rows into taps."""
        if not self.tap_on:
            return
        comptime for k in range(5):
            if l == TAPS[k]:
                self.ctx.enqueue_function[dsk.copy_tap](self.x, self.taps, Int32(k), Int32(count), Int32(self.D),
                                                        grid_dim=groups(count * self.D, 64), block_dim=64)

    def rows(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], cols: Int, n: Int,
             count: Int) raises:
        """y[count, n] = x[count, cols] W^T for up to MR rows, the int4 matrix read once (verify)."""
        var wq = self.words[name + ".q"]
        var ws = self.halves[name + ".s"]
        var a = (Int32(cols), Int32(n), Int32(count))
        if count <= 4:
            self.ctx.enqueue_function[dsk.rows_q4[1]](wq, ws, x, y, a[0], a[1], a[2], grid_dim=n // dsk.TR,
                                                      block_dim=64)
        elif count <= 8:
            self.ctx.enqueue_function[dsk.rows_q4[2]](wq, ws, x, y, a[0], a[1], a[2], grid_dim=n // dsk.TR,
                                                      block_dim=64)
        else:
            self.ctx.enqueue_function[dsk.rows_q4[3]](wq, ws, x, y, a[0], a[1], a[2], grid_dim=n // dsk.TR,
                                                      block_dim=64)

    def build_head8(mut self) raises:
        """An int8 copy of the Q6_K head (the same weights, 0.33 GB) for the few-row heads of a speculative step."""
        var D = self.D
        self.hq8 = self.ctx.enqueue_create_buffer[DType.uint32](self.V * D // 4)
        self.hs16 = self.ctx.enqueue_create_buffer[DType.float32](self.V * D // 16)
        self.ctx.enqueue_function[dsk.q6_to_q8](self.words["embed.q"], self.halves["embed.d"], self.hq8, self.hs16,
                                                Int32(D), Int32(self.V), grid_dim=groups(self.V * D // 16, 64),
                                                block_dim=64)
        self.ctx.synchronize()
        self.head8 = True

    def head_rows(self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], count: Int) raises:
        """The tied head's logits of x's first `count` rows (up to MR) into y [count, V]."""
        if self.head8:
            var a8 = (Int32(self.D), Int32(self.V), Int32(count))
            var g8 = self.V // dsk.TR
            if count <= 4:
                self.ctx.enqueue_function[dsk.head_q8_rows[1]](self.hq8, self.hs16, x, y, a8[0], a8[1], a8[2],
                                                               grid_dim=g8, block_dim=64)
            elif count <= 8:
                self.ctx.enqueue_function[dsk.head_q8_rows[2]](self.hq8, self.hs16, x, y, a8[0], a8[1], a8[2],
                                                               grid_dim=g8, block_dim=64)
            else:
                self.ctx.enqueue_function[dsk.head_q8_rows[3]](self.hq8, self.hs16, x, y, a8[0], a8[1], a8[2],
                                                               grid_dim=g8, block_dim=64)
            return
        var wq = self.words["embed.q"]
        var wd = self.halves["embed.d"]
        var a = (Int32(self.D), Int32(self.V), Int32(count))
        var grid = self.V // dsk.TR
        if count <= 4:
            self.ctx.enqueue_function[dsk.head_q6_rows[1]](wq, wd, x, y, a[0], a[1], a[2], grid_dim=grid, block_dim=64)
        elif count <= 8:
            self.ctx.enqueue_function[dsk.head_q6_rows[2]](wq, wd, x, y, a[0], a[1], a[2], grid_dim=grid, block_dim=64)
        else:
            self.ctx.enqueue_function[dsk.head_q6_rows[3]](wq, wd, x, y, a[0], a[1], a[2], grid_dim=grid, block_dim=64)

    def verify(mut self, p0: Int, count: Int) raises:
        """A speculative step's check: the tokens ids[p0 .. p0 + count - 1] (the anchor and the drafts, count <= MR)
        through the model, as a prefill batch but with the few-row kernels; each row's argmax into vt, each conv
        layer's B x rows into vbx (dsk.conv_commit keeps those of the accepted rows), the TAPS rows into taps. The
        conv states are left as they were (commit() sets them); K/V rows past the accepted ones are rewritten later."""
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var KVH = self.KVH
        var c = Int32(count)
        if not self.q4:
            raise Error("speculative decoding runs the q4 storage")
        if self.prof:
            self.ctx.synchronize()
            self.mark = Float64(perf_counter_ns()) / 1e6
        self.embed(p0, count)
        self.tick("v: embed")
        for l in range(self.L):
            var n = "l" + String(l) + "."
            if self.attn[l]:
                var w = (H + 2 * KVH) * lk.HD
                self.rows(n + "qkv", self.xn, self.mix, D, w, count)
                self.tick("v: qkv")
                ctx.enqueue_function[lk.qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      self.rope, self.kc[l], self.vc[l], Int32(p0), Int32(H),
                                                      Int32(KVH), Float32(0.125), grid_dim=Dim(H + 2 * KVH, count),
                                                      block_dim=64)
                ctx.enqueue_function[lk.attention](self.mix, self.kc[l], self.vc[l], self.att, Int32(p0), Int32(H),
                                                   Int32(KVH), grid_dim=Dim(H, count), block_dim=64)
                self.tick("v: attention")
                self.rows(n + "o", self.att, self.tmp, H * lk.HD, D, count)
                self.tick("v: o")
            else:
                self.rows(n + "in", self.xn, self.mix, D, 3 * D, count)
                self.tick("v: in")
                ctx.enqueue_function[lk.short_conv](self.mix, self.floats[n + "conv"], self.cs[l], self.att,
                                                    Int32(p0), c, Int32(D), Int32(2), self.vbx[l],
                                                    grid_dim=groups(count * D, 64), block_dim=64)
                self.tick("v: conv")
                self.rows(n + "out", self.att, self.tmp, D, D, count)
                self.tick("v: out")
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[n + "ffn_norm"], self.xn, Int32(D),
                                              Int32(1), grid_dim=count, block_dim=64)
            self.tick("v: norms")
            self.rows(n + "gu", self.xn, self.gu, D, 2 * self.F, count)
            self.tick("v: gu")
            ctx.enqueue_function[lk.silu_mul](self.gu, self.act, Int32(self.F), c,
                                              grid_dim=groups(count * self.F, 64), block_dim=64)
            self.rows(n + "down", self.act, self.tmp, self.F, D, count)
            self.tick("v: down")
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn, Int32(D),
                                              Int32(1), grid_dim=count, block_dim=64)
            self.tap(l, count)
            self.tick("v: norms")
        self.head_rows(self.xn, self.vlog, count)
        self.tick("v: head")
        ctx.enqueue_function[dsk.argmax_rows](self.vlog, Int32(self.V), self.vt, Int32(0), grid_dim=count,
                                              block_dim=256)
        self.tick("v: argmax")

    def commit(self, p0: Int, accepted: Int) raises:
        """After verify(p0, ..) kept `accepted` drafts: each conv layer's state as after position p0 + accepted."""
        for l in range(self.L):
            if not self.attn[l]:
                self.ctx.enqueue_function[dsk.conv_commit](self.vbx[l], self.cs[l], Int32(p0), Int32(accepted),
                                                           Int32(self.D), grid_dim=groups(2 * self.D, 64),
                                                           block_dim=64)

    def next_norm(self, l: Int) -> String:
        return "l" + String(l + 1) + ".in_norm" if l + 1 < self.L else "final_norm"

    # ---- a token -----------------------------------------------------------------------------------------------------

    def step(mut self, pos: Int, head: Bool = True) raises:
        """The token ids[pos] through the model: logits, and their argmax into ids[pos + 1] (head; a prompt token but
        the last needs neither, and its next id is the prompt's)."""
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var KVH = self.KVH
        if self.prof:
            self.ctx.synchronize()
            self.mark = Float64(perf_counter_ns()) / 1e6
        self.embed(pos, 1)
        self.tick("embed + norm")
        for l in range(self.L):
            var n = "l" + String(l) + "."
            if self.attn[l]:
                self.gemv(n + "qkv", self.xn, self.mix, D, (H + 2 * KVH) * lk.HD)
                self.tick("q/k/v (attention layers)")
                ctx.enqueue_function[lk.qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      self.rope, self.kc[l], self.vc[l], Int32(pos), Int32(H),
                                                      Int32(KVH), Float32(0.125), grid_dim=Dim(H + 2 * KVH, 1),
                                                      block_dim=64)
                ctx.enqueue_function[lk.attention](self.mix, self.kc[l], self.vc[l], self.att, Int32(pos), Int32(H),
                                                   Int32(KVH), grid_dim=Dim(H, 1), block_dim=64)
                self.tick("q/k norm, RoPE, attention")
                self.gemv(n + "o", self.att, self.tmp, H * lk.HD, D)
                self.tick("o (attention layers)")
            else:
                self.gemv(n + "in", self.xn, self.mix, D, 3 * D)
                self.tick("in_proj (conv layers)")
                ctx.enqueue_function[lk.short_conv](self.mix, self.floats[n + "conv"], self.cs[l], self.att,
                                                    Int32(pos), Int32(1), Int32(D), Int32(1), self.att,
                                                    grid_dim=groups(D, 64), block_dim=64)
                self.tick("short conv")
                self.gemv(n + "out", self.att, self.tmp, D, D)
                self.tick("out_proj (conv layers)")
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[n + "ffn_norm"], self.xn, Int32(D),
                                              Int32(1), grid_dim=1, block_dim=64)
            self.tick("residual adds + norms")
            if self.q4 and self.wide:
                ctx.enqueue_function[lk.gate_up_q4[True]](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.xn,
                                                          self.act, Int32(D), Int32(self.F), grid_dim=self.F,
                                                          block_dim=64)
            elif self.q4:
                ctx.enqueue_function[lk.gate_up_q4[False]](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.xn,
                                                           self.act, Int32(D), Int32(self.F), grid_dim=self.F,
                                                           block_dim=64)
            else:
                ctx.enqueue_function[lk.gate_up_h](self.halves[n + "gu.h"], self.xn, self.act, Int32(D),
                                                   Int32(self.F), grid_dim=self.F, block_dim=64)
            self.tick("gate/up + SiLU")
            self.gemv(n + "down", self.act, self.tmp, self.F, D)
            self.tick("down")
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn, Int32(D),
                                              Int32(1), grid_dim=1, block_dim=64)
            self.tick("residual adds + norms")
        if head:
            self.head(0, pos + 1)
            self.tick("head + argmax")

    # ---- the prompt --------------------------------------------------------------------------------------------------

    def prefill(mut self, p0: Int, count: Int) raises:
        """Positions p0 .. p0 + count - 1 (ids set) in batches of up to PMAX rows; the last row's logits and argmax as
        step() leaves them (into ids[p0 + count])."""
        var c0 = 0
        while c0 < count:
            var c = min(PMAX, count - c0)
            self.prefill_batch(p0 + c0, c, c0 + c == count)
            c0 += c

    def prefill_batch(mut self, p0: Int, count: Int, last: Bool) raises:
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var KVH = self.KVH
        var R = groups(count, 128) * 128
        var c = Int32(count)
        if self.prof:
            self.ctx.synchronize()
            self.mark = Float64(perf_counter_ns()) / 1e6
        self.embed(p0, count)
        self.tick("p: embed + norm")
        var out = FileHandle()
        var rows = List[Float32]()
        if self.dump:
            out = open(self.dump, "w")
            rows = List[Float32](length=count * D, fill=0)
            self.write_rows(out, rows, count)
        for l in range(self.L):
            var n = "l" + String(l) + "."
            if self.attn[l]:
                var w = (H + 2 * KVH) * lk.HD
                self.gemm(n + "qkv", self.xn, self.mix, w, D, R)
                self.tick("p: q/k/v")
                ctx.enqueue_function[lk.qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      self.rope, self.kc[l], self.vc[l], Int32(p0), Int32(H),
                                                      Int32(KVH), Float32(0.125), grid_dim=Dim(H + 2 * KVH, count),
                                                      block_dim=64)
                ctx.enqueue_function[lk.attention](self.mix, self.kc[l], self.vc[l], self.att, Int32(p0), Int32(H),
                                                   Int32(KVH), grid_dim=Dim(H, count), block_dim=64)
                self.tick("p: q/k norm, RoPE, attention")
                self.gemm(n + "o", self.att, self.tmp, D, H * lk.HD, R)
                self.tick("p: o")
            else:
                self.gemm(n + "in", self.xn, self.mix, 3 * D, D, R)
                self.tick("p: in_proj")
                ctx.enqueue_function[lk.short_conv](self.mix, self.floats[n + "conv"], self.cs[l], self.att,
                                                    Int32(p0), c, Int32(D), Int32(0), self.att,
                                                    grid_dim=groups(count * D, 64), block_dim=64)
                ctx.enqueue_function[lk.conv_state](self.mix, self.cs[l], Int32(p0), c, Int32(D),
                                                    grid_dim=groups(2 * D, 64), block_dim=64)
                self.tick("p: short conv")
                self.gemm(n + "out", self.att, self.tmp, D, D, R)
                self.tick("p: out_proj")
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[n + "ffn_norm"], self.xn, Int32(D),
                                              Int32(1), grid_dim=count, block_dim=64)
            self.tick("p: adds + norms")
            self.gemm(n + "gu", self.xn, self.gu, 2 * self.F, D, R)
            self.tick("p: gate/up")
            ctx.enqueue_function[lk.silu_mul](self.gu, self.act, Int32(self.F), c,
                                              grid_dim=groups(count * self.F, 64), block_dim=64)
            self.tick("p: SiLU product")
            self.gemm(n + "down", self.act, self.tmp, D, self.F, R)
            self.tick("p: down")
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn, Int32(D),
                                              Int32(1), grid_dim=count, block_dim=64)
            self.tap(l, count)
            if self.dump:
                self.write_rows(out, rows, count)
        if self.dump:
            out.close()
        self.tick("p: adds + norms")
        if last:
            self.head(count - 1, p0 + count)
            self.tick("p: head")
