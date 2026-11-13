# Qwen3-4B (Qwen/Qwen3-4B, bf16 checkpoint quantized on the phone by convert.c) as MAX DeviceContext launches. The sizes
# and tensors come from export.py's manifest; the weights from convert.c's file: ggml's Q4_0 for every projection
# (lfm2/kernels/lk.mojo's int4 storage), one Q6_K copy of the tied embedding / head, fp32 norms. Activations and the
# K/V cache (36 layers x [context + PAD] rows of 8 heads x 128) are fp32.
#
# Token ids live on the GPU (ids[position]): the embedding reads them there and the argmax writes the next one, so a
# decode step never waits on the host for its input. step() runs one position; prefill() a batch of prompt rows, its
# projections on the matrix units (lk.gemm_q4) and its attention too (g4k's p_scores_mma, p_softmax, p_values_mma).
from std.collections import Dict
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import g4k
import lk
import q4bk
import qwen3k

comptime PMAX = 512  # prompt rows a prefill batch holds (a multiple of gemm_q4's 128)
comptime PAD = 128  # cache rows past the context: prefill's matrix-unit attention reads up to a block's 64-aligned end
comptime HD = 128


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


struct Qwen3(Movable):
    var ctx: DeviceContext
    var D: Int
    var L: Int
    var H: Int
    var KVH: Int
    var F: Int
    var V: Int
    var CAP: Int  # positions the K/V cache holds
    var QKV: Int
    var words: Dict[String, DeviceBuffer[DType.uint32]]
    var halves: Dict[String, DeviceBuffer[DType.float16]]
    var floats: Dict[String, DeviceBuffer[DType.float32]]
    var bytes: Int
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]
    var rope: DeviceBuffer[DType.float32]
    var ids: DeviceBuffer[DType.int32]  # [CAP + PMAX]: the token at each position
    var x: DeviceBuffer[DType.float32]  # rows of PMAX: the residual stream
    var xn: DeviceBuffer[DType.float32]
    var mix: DeviceBuffer[DType.float32]  # q | k | v rows
    var att: DeviceBuffer[DType.float32]  # attention output rows (32 x 128)
    var tmp: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]
    var act: DeviceBuffer[DType.float32]
    var scores: DeviceBuffer[DType.float32]  # decode: [32 heads, CAP] (qwen3k.attn_scores)
    var pv: DeviceBuffer[DType.float32]  # decode, in chunks of 64 positions: [chunks, 32 heads, 128] (q4bk.attn_part)
    var pm: DeviceBuffer[DType.float32]  # [chunks, 64]: each head's highest score, then its sum of exp
    var chunked: Bool  # decode attention in chunks of positions (q4bk); QWEN3_ATTN=qwen3k: qwen3k's two kernels
    var pscores: DeviceBuffer[DType.float32]  # prefill: [PMAX rows, 32 heads, CAP + PAD] (g4k)
    var logits: DeviceBuffer[DType.float32]
    var dump: String  # prefill: append each layer's residual stream rows (fp32) to this file (stage checks)
    var prof: Bool  # step(): wait after each launch and add its time to times[kind] (QWEN3_PROFILE)
    var times: Dict[String, Float64]
    var mark: Float64
    var skip: String  # decode: kinds of launch left out (QWEN3_SKIP=qkv,attn,o,gu,down,norm,head: timing ablations)

    def __init__(out self, ctx: DeviceContext, dir: String, bin: String, cap: Int) raises:
        """dir: export.py's manifest.txt (q4/) with rope.f32 one level up; bin: convert.c's weight file; cap: the
        context (positions) the K/V cache holds."""
        self.ctx = ctx
        var lines = open(dir + "/manifest.txt", "r").read().split("\n")
        var head = lines[0].split(" ")
        if len(head) < 2 or head[0] != "qwen3":
            raise Error(dir + "/manifest.txt: not a qwen3 manifest")
        var cfg = Dict[String, String]()
        for i in range(2, len(head) - 1, 2):
            cfg[String(head[i])] = String(head[i + 1])
        self.D = Int(cfg["D"])
        self.L = Int(cfg["L"])
        self.H = Int(cfg["H"])
        self.KVH = Int(cfg["KVH"])
        self.F = Int(cfg["F"])
        self.V = Int(cfg["V"])
        self.QKV = (self.H + 2 * self.KVH) * HD
        if Int(cfg["HD"]) != HD or self.H != 32 or self.KVH != 8:
            raise Error("qwen3k's attention: 32 query and 8 KV heads of 128")
        var rope_rows = Int(cfg["ROPE"])
        self.CAP = min(cap, rope_rows)
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.bytes = 0
        var D = self.D
        var row = self.KVH * HD
        self.kc = List[DeviceBuffer[DType.float32]]()
        self.vc = List[DeviceBuffer[DType.float32]]()
        for _ in range(self.L):
            self.kc.append(ctx.enqueue_create_buffer[DType.float32]((self.CAP + PAD) * row))
            self.vc.append(ctx.enqueue_create_buffer[DType.float32]((self.CAP + PAD) * row))
        self.rope = ctx.enqueue_create_buffer[DType.float32](rope_rows * HD)
        self.ids = ctx.enqueue_create_buffer[DType.int32](self.CAP + PMAX)
        self.x = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.mix = ctx.enqueue_create_buffer[DType.float32](PMAX * self.QKV)
        self.att = ctx.enqueue_create_buffer[DType.float32](PMAX * self.H * HD)
        self.tmp = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.gu = ctx.enqueue_create_buffer[DType.float32](PMAX * 2 * self.F)
        self.act = ctx.enqueue_create_buffer[DType.float32](PMAX * self.F)
        self.scores = ctx.enqueue_create_buffer[DType.float32](self.H * self.CAP)
        self.pv = ctx.enqueue_create_buffer[DType.float32](groups(self.CAP, q4bk.CH) * self.H * HD)
        self.pm = ctx.enqueue_create_buffer[DType.float32](groups(self.CAP, q4bk.CH) * 2 * self.H)
        self.chunked = True
        self.pscores = ctx.enqueue_create_buffer[DType.float32](PMAX * self.H * (self.CAP + PAD))
        self.logits = ctx.enqueue_create_buffer[DType.float32](self.V)
        self.dump = ""
        self.prof = False
        self.times = Dict[String, Float64]()
        self.mark = 0
        self.skip = ""
        self.reset()
        self.load(dir, bin)

    def reset(self) raises:
        """A new sequence: zero the caches (prefill's P V reads rows past the prompt), ids and the padding rows the
        matrix products read."""
        for l in range(self.L):
            self.kc[l].enqueue_fill(0)
            self.vc[l].enqueue_fill(0)
        self.ids.enqueue_fill(0)
        self.xn.enqueue_fill(0)
        self.att.enqueue_fill(0)
        self.act.enqueue_fill(0)
        self.ctx.synchronize()

    def load(mut self, dir: String, bin: String) raises:
        """The weight file's tensors, as the manifest lists them ("<name> <offset> <bytes> <dtype> <shape>"), each in a
        device buffer of its type; and the RoPE table."""
        var lines = open(dir + "/manifest.txt", "r").read().split("\n")
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
        if len(r) != len(self.rope) * 4:
            raise Error("rope.f32: not the manifest's ROPE rows")
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

    # ---- pieces ------------------------------------------------------------------------------------------------------

    def gemv(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], cols: Int,
             rows: Int) raises:
        self.ctx.enqueue_function[lk.gemv_q4[True]](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                    Int32(cols), grid_dim=rows, block_dim=64)

    def gemm(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], n: Int, k: Int,
             rows: Int) raises:
        """y[rows, n] = x[rows, k] W^T (rows: a multiple of 128) on the matrix units."""
        self.ctx.enqueue_function[lk.gemm_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y, Int64(n),
                                              Int64(k), grid_dim=Dim(n // 128, rows // 128), block_dim=256)

    def embed(self, slot0: Int, count: Int) raises:
        """x rows = the embedding rows of ids[slot0 ..], and xn = layer 0's input norm of them."""
        self.ctx.enqueue_function[lk.embed_q6](self.ids, Int32(slot0), self.words["embed.q"], self.halves["embed.d"],
                                               self.x, Int32(self.D), grid_dim=count, block_dim=64)
        self.ctx.enqueue_function[q4bk.add_norm](self.x, self.tmp, self.floats["l0.in_norm"], self.xn, Int32(self.D),
                                                 Int32(0), grid_dim=count, block_dim=64)

    def head(self, row: Int, slot: Int) raises:
        """The logits of xn's row `row` (final-normed), and their argmax into ids[slot]."""
        var x = self.xn.create_sub_buffer[DType.float32](row * self.D, self.D)
        self.ctx.enqueue_function[lk.head_q6](self.words["embed.q"], self.halves["embed.d"], x, self.logits,
                                              Int32(self.D), grid_dim=self.V, block_dim=64)
        self.ctx.enqueue_function[lk.argmax](self.logits, Int32(self.V), self.ids, Int32(slot), grid_dim=1,
                                             block_dim=256)

    def next_norm(self, l: Int) -> String:
        return "l" + String(l + 1) + ".in_norm" if l + 1 < self.L else "final_norm"

    def write_rows(self, mut out: FileHandle, mut rows: List[Float32], count: Int) raises:
        self.ctx.enqueue_copy(rows.unsafe_ptr(), self.x.create_sub_buffer[DType.float32](0, count * self.D))
        self.ctx.synchronize()
        out.write_bytes(Span(unsafe_ptr=rows.unsafe_ptr().unsafe_bitcast[UInt8](), length=count * self.D * 4))

    def on(self, kind: String) -> Bool:
        return not self.skip or self.skip.find(kind) < 0

    def tick(mut self, kind: String) raises:
        """Profiling: wait for the launches so far and charge their time to `kind`."""
        if not self.prof:
            return
        self.ctx.synchronize()
        var t = Float64(perf_counter_ns()) / 1e6
        self.times[kind] = self.times.get(kind, 0.0) + (t - self.mark)
        self.mark = t

    # ---- a token -----------------------------------------------------------------------------------------------------

    def step(mut self, pos: Int, head: Bool = True) raises:
        """The token ids[pos] through the model: logits, and their argmax into ids[pos + 1] (head; a prompt token but
        the last needs neither, and its next id is the prompt's)."""
        var ctx = self.ctx
        var D = self.D
        if self.prof:
            ctx.synchronize()
            self.mark = Float64(perf_counter_ns()) / 1e6
        self.embed(pos, 1)
        self.tick("embed + norm")
        for l in range(self.L):
            var n = "l" + String(l) + "."
            if self.on("qkv"):
                self.gemv(n + "qkv", self.xn, self.mix, D, self.QKV)
            self.tick("q/k/v")
            if self.on("attn"):
                self.attend(l, pos)
            self.tick("q/k norm, RoPE, attention")
            if self.on("o"):
                self.gemv(n + "o", self.att, self.tmp, self.H * HD, D)
            self.tick("o")
            if self.on("norm"):
                ctx.enqueue_function[q4bk.add_norm](self.x, self.tmp, self.floats[n + "post_norm"], self.xn, Int32(D),
                                                    Int32(1), grid_dim=1, block_dim=64)
            self.tick("residual adds + norms")
            if self.on("gu"):
                ctx.enqueue_function[lk.gate_up_q4[True]](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.xn,
                                                          self.act, Int32(D), Int32(self.F), grid_dim=self.F,
                                                          block_dim=64)
            self.tick("gate/up + SiLU")
            if self.on("down"):
                self.gemv(n + "down", self.act, self.tmp, self.F, D)
            self.tick("down")
            if self.on("norm"):
                ctx.enqueue_function[q4bk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn,
                                                    Int32(D), Int32(1), grid_dim=1, block_dim=64)
            self.tick("residual adds + norms")
        if head and self.on("head"):
            self.head(0, pos + 1)
            self.tick("head + argmax")

    def attend(self, l: Int, pos: Int) raises:
        """One token's attention in layer l: q/k norms, RoPE, the K/V cache rows, then softmax(q K^T / sqrt(128)) V."""
        var ctx = self.ctx
        var n = "l" + String(l) + "."
        ctx.enqueue_function[qwen3k.qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                  self.rope, self.kc[l], self.vc[l], Int32(pos),
                                                  grid_dim=self.H + 2 * self.KVH, block_dim=64)
        if self.chunked:
            ctx.enqueue_function[q4bk.attn_part](self.mix, self.kc[l], self.vc[l], self.pv, self.pm, Int32(pos),
                                                 grid_dim=Dim(self.KVH, groups(pos + 1, q4bk.CH)), block_dim=64)
            ctx.enqueue_function[q4bk.attn_combine](self.pv, self.pm, self.att, Int32(pos), grid_dim=self.H,
                                                    block_dim=64)
            return
        ctx.enqueue_function[qwen3k.attn_scores](self.mix, self.kc[l], self.scores, Int32(pos), Int32(self.CAP),
                                                 grid_dim=groups(self.KVH * (pos + 1), 64), block_dim=64)
        ctx.enqueue_function[qwen3k.attn_values](self.scores, self.vc[l], self.att, Int32(pos), Int32(self.CAP),
                                                 grid_dim=self.H * 2, block_dim=64)

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
        var Rr = groups(count, 128) * 128
        var c = Int32(count)
        var kcap = self.CAP + PAD
        if p0 + Rr > kcap:
            raise Error("prefill past the context")
        if self.prof:
            ctx.synchronize()
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
            self.gemm(n + "qkv", self.xn, self.mix, self.QKV, D, Rr)
            self.tick("p: q/k/v")
            ctx.enqueue_function[q4bk.p_qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      self.rope, self.kc[l], self.vc[l], Int32(p0),
                                                      grid_dim=Dim(H + 2 * KVH, count), block_dim=64)
            self.tick("p: q/k norm, RoPE")
            # on the matrix units: Q K^T per 64 rows and 64 keys, the softmax of each row, then P V; q carries the scale
            var nq = Int32(H // KVH)
            ctx.enqueue_function[g4k.p_scores_mma[HD]](self.mix, self.kc[l], self.pscores, Int32(p0), Int32(0), nq,
                                                       Int32(KVH), Int32(self.QKV), Int32(H), Int32(kcap),
                                                       grid_dim=Dim(Rr // 64, H), block_dim=64)
            ctx.enqueue_function[g4k.p_softmax](self.pscores, Int32(p0), c, Int32(0), Int32(H), Int32(kcap),
                                                grid_dim=Dim(H, Rr), block_dim=64)
            ctx.enqueue_function[g4k.p_values_mma[HD]](self.pscores, self.vc[l], self.att, Int32(p0), Int32(0), nq,
                                                       Int32(KVH), Int32(H), Int32(kcap),
                                                       grid_dim=Dim(Rr // 64, H * (HD // 64)), block_dim=64)
            self.tick("p: attention")
            self.gemm(n + "o", self.att, self.tmp, D, H * HD, Rr)
            self.tick("p: o")
            ctx.enqueue_function[q4bk.add_norm](self.x, self.tmp, self.floats[n + "post_norm"], self.xn, Int32(D),
                                                Int32(1), grid_dim=count, block_dim=64)
            self.tick("p: adds + norms")
            self.gemm(n + "gu", self.xn, self.gu, 2 * self.F, D, Rr)
            self.tick("p: gate/up")
            ctx.enqueue_function[lk.silu_mul](self.gu, self.act, Int32(self.F), c,
                                              grid_dim=groups(count * self.F, 64), block_dim=64)
            self.tick("p: SiLU product")
            self.gemm(n + "down", self.act, self.tmp, D, self.F, Rr)
            self.tick("p: down")
            ctx.enqueue_function[q4bk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn, Int32(D),
                                                Int32(1), grid_dim=count, block_dim=64)
            self.tick("p: adds + norms")
            if self.dump:
                self.write_rows(out, rows, count)
        if self.dump:
            out.close()
        if last:
            self.head(count - 1, p0 + count)
            self.tick("p: head")
