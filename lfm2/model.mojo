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

import lk

comptime PMAX = 512  # prompt rows a prefill batch holds (a multiple of gemm_q4's 128)


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
    var dump: String  # prefill: append each layer's residual stream rows (fp32) to this file (stage checks)
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
        self.prof = False
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
        if self.q4:
            self.ctx.enqueue_function[lk.gemv_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y,
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
                                                    Int32(pos), Int32(1), Int32(D), Int32(1),
                                                    grid_dim=groups(D, 64), block_dim=64)
                self.tick("short conv")
                self.gemv(n + "out", self.att, self.tmp, D, D)
                self.tick("out_proj (conv layers)")
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[n + "ffn_norm"], self.xn, Int32(D),
                                              Int32(1), grid_dim=1, block_dim=64)
            self.tick("residual adds + norms")
            if self.q4:
                ctx.enqueue_function[lk.gate_up_q4](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.xn,
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

    def prefill(self, p0: Int, count: Int) raises:
        """Positions p0 .. p0 + count - 1 (ids set) in batches of up to PMAX rows; the last row's logits and argmax as
        step() leaves them (into ids[p0 + count])."""
        var c0 = 0
        while c0 < count:
            var c = min(PMAX, count - c0)
            self.prefill_batch(p0 + c0, c, c0 + c == count)
            c0 += c

    def prefill_batch(self, p0: Int, count: Int, last: Bool) raises:
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var KVH = self.KVH
        var R = groups(count, 128) * 128
        var c = Int32(count)
        self.embed(p0, count)
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
                ctx.enqueue_function[lk.qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      self.rope, self.kc[l], self.vc[l], Int32(p0), Int32(H),
                                                      Int32(KVH), Float32(0.125), grid_dim=Dim(H + 2 * KVH, count),
                                                      block_dim=64)
                ctx.enqueue_function[lk.attention](self.mix, self.kc[l], self.vc[l], self.att, Int32(p0), Int32(H),
                                                   Int32(KVH), grid_dim=Dim(H, count), block_dim=64)
                self.gemm(n + "o", self.att, self.tmp, D, H * lk.HD, R)
            else:
                self.gemm(n + "in", self.xn, self.mix, 3 * D, D, R)
                ctx.enqueue_function[lk.short_conv](self.mix, self.floats[n + "conv"], self.cs[l], self.att,
                                                    Int32(p0), c, Int32(D), Int32(0),
                                                    grid_dim=groups(count * D, 64), block_dim=64)
                ctx.enqueue_function[lk.conv_state](self.mix, self.cs[l], Int32(p0), c, Int32(D),
                                                    grid_dim=groups(2 * D, 64), block_dim=64)
                self.gemm(n + "out", self.att, self.tmp, D, D, R)
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[n + "ffn_norm"], self.xn, Int32(D),
                                              Int32(1), grid_dim=count, block_dim=64)
            self.gemm(n + "gu", self.xn, self.gu, 2 * self.F, D, R)
            ctx.enqueue_function[lk.silu_mul](self.gu, self.act, Int32(self.F), c,
                                              grid_dim=groups(count * self.F, 64), block_dim=64)
            self.gemm(n + "down", self.act, self.tmp, D, self.F, R)
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn, Int32(D),
                                              Int32(1), grid_dim=count, block_dim=64)
            if self.dump:
                self.write_rows(out, rows, count)
        if self.dump:
            out.close()
        if last:
            self.head(count - 1, p0 + count)
