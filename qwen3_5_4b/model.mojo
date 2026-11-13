# Qwen3.5-4B (text; unsloth/Qwen3.5-4B-GGUF's Q4_0 file, repacked on the phone by convert.c) as MAX DeviceContext
# launches. The sizes and tensors come from export.py's manifest. 32 layers: 24 linear-attention (Gated DeltaNet) and
# 8 full-attention ones (every 4th), each followed by a SwiGLU MLP, with pre-norms. Weights: Q4_0 projections as lk's
# int4 words + fp16 scales, the GGUF's Q4_1 (ffn_down of layers 0-3) and Q5_K (linear attention out_proj) matrices in
# q35k's affine storage, the Q6_K tied embedding / head, fp32 vectors. Activations, the K/V cache (8 layers x
# [context + PAD] rows of 4 heads x 256), the conv states (3 x 8192 a layer) and the recurrent states (32 x 128 x 128
# a layer) are fp32.
#
# Token ids live on the GPU (ids[position]): the embedding reads them there and the argmax writes the next one, so a
# decode step never waits on the host for its input. step() runs one position; prefill() a batch of prompt rows: its
# projections on the matrix units (lk.gemm_q4, q35k.gemm_aff), the full attention too (g4k), the linear attention's
# recurrence a row after another with each head's state in registers (q35k.delta_rule).
from std.collections import Dict
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import g4k
import lk
import q4bk
import q35k

comptime PMAX = 512  # prompt rows a prefill batch holds (a multiple of gemm_q4's 128)
comptime PAD = 128  # cache rows past the context: prefill's matrix-unit attention reads up to a block's 64-aligned end
comptime HD = 256
comptime CONV = q35k.CONV  # 8192: q | k | v of the linear attention
comptime NVD = 4096  # 32 value heads x 128
comptime STATE = 32 * 128 * 128


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


struct Qwen35(Movable):
    var ctx: DeviceContext
    var D: Int
    var L: Int
    var H: Int
    var KVH: Int
    var F: Int
    var V: Int
    var CAP: Int  # positions the K/V cache holds
    var QKVG: Int  # full attention's fused row: q | k | v | gate (10240)
    var QKVZ: Int  # linear attention's fused row: q | k | v | z (12288)
    var types: String  # a letter a layer: L (linear attention) or F (full attention)
    var slot: List[Int]  # layer -> its index among the layers of its type (caches, states)
    var words: Dict[String, DeviceBuffer[DType.uint32]]
    var halves: Dict[String, DeviceBuffer[DType.float16]]
    var floats: Dict[String, DeviceBuffer[DType.float32]]
    var bytes: Int
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]
    var conv: List[DeviceBuffer[DType.float32]]  # [3, 8192]: the conv inputs of the last three positions (slot p % 3)
    var S: List[DeviceBuffer[DType.float32]]  # [32 heads, 128 v, 128 k]
    var rope: DeviceBuffer[DType.float32]
    var ids: DeviceBuffer[DType.int32]  # [CAP + PMAX]: the token at each position
    var x: DeviceBuffer[DType.float32]  # rows of PMAX: the residual stream
    var xn: DeviceBuffer[DType.float32]
    var mix: DeviceBuffer[DType.float32]  # the fused projection rows (q|k|v|z or q|k|v|gate)
    var cq: DeviceBuffer[DType.float32]  # conv_qk's rows: q, k normed, v (8192)
    var ab: DeviceBuffer[DType.float32]  # in_proj_a | in_proj_b rows (64)
    var gb: DeviceBuffer[DType.float32]  # decay | beta rows (64)
    var o: DeviceBuffer[DType.float32]  # the delta rule's output rows (4096)
    var att: DeviceBuffer[DType.float32]  # the token mixer's output rows before its projection (4096)
    var tmp: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]
    var act: DeviceBuffer[DType.float32]
    var pv: DeviceBuffer[DType.float32]  # decode attention in chunks of 32 positions: [chunks, 16 heads, 256]
    var pm: DeviceBuffer[DType.float32]  # [chunks, 32]: each head's highest score, then its sum of exp
    var pscores: DeviceBuffer[DType.float32]  # prefill: [PMAX rows, 16 heads, CAP + PAD] (g4k)
    var logits: DeviceBuffer[DType.float32]
    var dump: String  # prefill: append each layer's residual stream rows (fp32) to this file (stage checks)
    var prof: Bool  # wait after each launch and add its time to times[kind] (QWEN35_PROFILE)
    var times: Dict[String, Float64]
    var mark: Float64
    var dnc: Int  # prefill: value columns a 16-lane group of the delta rule takes (1, 2 or 4; QWEN35_DNC)

    def __init__(out self, ctx: DeviceContext, dir: String, bin: String, cap: Int) raises:
        """dir: export.py's manifest.txt (q4/) with rope.f32 one level up; bin: convert.c's weight file; cap: the
        context (positions) the K/V cache holds."""
        self.ctx = ctx
        var lines = open(dir + "/manifest.txt", "r").read().split("\n")
        var head = lines[0].split(" ")
        if len(head) < 2 or head[0] != "qwen35":
            raise Error(dir + "/manifest.txt: not a qwen35 manifest")
        var cfg = Dict[String, String]()
        for i in range(2, len(head) - 1, 2):
            cfg[String(head[i])] = String(head[i + 1])
        self.D = Int(cfg["D"])
        self.L = Int(cfg["L"])
        self.H = Int(cfg["H"])
        self.KVH = Int(cfg["KVH"])
        self.F = Int(cfg["F"])
        self.V = Int(cfg["V"])
        self.types = cfg["TYPES"]
        if Int(cfg["HD"]) != HD or self.H != q35k.H or self.KVH != q35k.KVH or Int(cfg["NK"]) != q35k.NK or Int(
                cfg["NV"]) != q35k.NV or Int(cfg["DK"]) != q35k.DK or Int(cfg["ROT"]) != q35k.ROT:
            raise Error("q35k's shapes: 16 query / 4 KV heads of 256 (64 rotated), 16 key / 32 value heads of 128")
        if self.types.byte_length() != self.L:
            raise Error("manifest: TYPES needs a letter a layer")
        self.QKVG = (self.H + 2 * self.KVH) * HD + self.H * HD
        self.QKVZ = CONV + NVD
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
        self.conv = List[DeviceBuffer[DType.float32]]()
        self.S = List[DeviceBuffer[DType.float32]]()
        self.slot = List[Int]()
        var lin = self.types.as_bytes()
        for l in range(self.L):
            if lin[l] == UInt8(ord("L")):
                self.slot.append(len(self.S))
                self.conv.append(ctx.enqueue_create_buffer[DType.float32](3 * CONV))
                self.S.append(ctx.enqueue_create_buffer[DType.float32](STATE))
            else:
                self.slot.append(len(self.kc))
                self.kc.append(ctx.enqueue_create_buffer[DType.float32]((self.CAP + PAD) * row))
                self.vc.append(ctx.enqueue_create_buffer[DType.float32]((self.CAP + PAD) * row))
        self.rope = ctx.enqueue_create_buffer[DType.float32](rope_rows * q35k.ROT)
        self.ids = ctx.enqueue_create_buffer[DType.int32](self.CAP + PMAX)
        self.x = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.mix = ctx.enqueue_create_buffer[DType.float32](PMAX * max(self.QKVG, self.QKVZ))
        self.cq = ctx.enqueue_create_buffer[DType.float32](PMAX * CONV)
        self.ab = ctx.enqueue_create_buffer[DType.float32](PMAX * 64)
        self.gb = ctx.enqueue_create_buffer[DType.float32](PMAX * 64)
        self.o = ctx.enqueue_create_buffer[DType.float32](PMAX * NVD)
        self.att = ctx.enqueue_create_buffer[DType.float32](PMAX * NVD)
        self.tmp = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.gu = ctx.enqueue_create_buffer[DType.float32](PMAX * 2 * self.F)
        self.act = ctx.enqueue_create_buffer[DType.float32](PMAX * self.F)
        self.pv = ctx.enqueue_create_buffer[DType.float32](groups(self.CAP, q35k.CH) * self.H * HD)
        self.pm = ctx.enqueue_create_buffer[DType.float32](groups(self.CAP, q35k.CH) * 2 * self.H)
        self.pscores = ctx.enqueue_create_buffer[DType.float32](PMAX * self.H * (self.CAP + PAD))
        self.logits = ctx.enqueue_create_buffer[DType.float32](self.V)
        self.dump = ""
        self.prof = False
        self.times = Dict[String, Float64]()
        self.mark = 0
        self.dnc = 2
        self.reset()
        self.load(dir, bin)

    def linear(self, l: Int) -> Bool:
        return self.types.as_bytes()[l] == UInt8(ord("L"))

    def reset(self) raises:
        """A new sequence: zero the caches and states (prefill's P V reads rows past the prompt), ids and the padding
        rows the matrix products read."""
        for i in range(len(self.kc)):
            self.kc[i].enqueue_fill(0)
            self.vc[i].enqueue_fill(0)
        for i in range(len(self.S)):
            self.S[i].enqueue_fill(0)
            self.conv[i].enqueue_fill(0)
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
        """y = W x for one row: W Q4_0 (lk) or in the affine storage (q35k), as the manifest has it."""
        if name + ".s" in self.halves:
            self.ctx.enqueue_function[lk.gemv_q4[True]](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                        Int32(cols), grid_dim=rows, block_dim=64)
        elif name + ".h" in self.words:
            self.ctx.enqueue_function[q35k.gemv_aff[True]](self.words[name + ".q"], self.words[name + ".h"],
                                                           self.floats[name + ".d"], self.floats[name + ".c"], x, y,
                                                           Int32(cols), grid_dim=rows, block_dim=64)
        else:
            self.ctx.enqueue_function[q35k.gemv_aff[False]](self.words[name + ".q"], self.words[name + ".q"],
                                                            self.floats[name + ".d"], self.floats[name + ".c"], x, y,
                                                            Int32(cols), grid_dim=rows, block_dim=64)

    def gemm(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], n: Int, k: Int,
             rows: Int) raises:
        """y[rows, n] = x[rows, k] W^T on the matrix units, W as gemv() reads it. rows: a multiple of 64; whole 128s
        through lk.gemm_q4 / q35k.gemm_aff, a last 64 through q35k.gemm64."""
        var full = rows // 128 * 128
        var q4 = name + ".s" in self.halves
        var hi = name + ".h" in self.words
        if full:
            var g = Dim(n // 128, full // 128)
            if q4:
                self.ctx.enqueue_function[lk.gemm_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                      Int64(n), Int64(k), grid_dim=g, block_dim=256)
            elif hi:
                self.ctx.enqueue_function[q35k.gemm_aff[True]](self.words[name + ".q"], self.words[name + ".h"],
                                                               self.floats[name + ".d"], self.floats[name + ".c"], x,
                                                               y, Int64(n), Int64(k), grid_dim=g, block_dim=256)
            else:
                self.ctx.enqueue_function[q35k.gemm_aff[False]](self.words[name + ".q"], self.words[name + ".q"],
                                                                self.floats[name + ".d"], self.floats[name + ".c"], x,
                                                                y, Int64(n), Int64(k), grid_dim=g, block_dim=256)
        if rows > full:
            var wq = self.words[name + ".q"]
            if q4:
                self.ctx.enqueue_function[q35k.gemm64[0]](wq, self.halves[name + ".s"], wq, self.rope, self.rope, x,
                                                          y, Int64(n), Int64(k), Int64(full), grid_dim=n // 128,
                                                          block_dim=128)
            elif hi:
                self.ctx.enqueue_function[q35k.gemm64[2]](wq, self.halves["embed.d"], self.words[name + ".h"],
                                                          self.floats[name + ".d"], self.floats[name + ".c"], x, y,
                                                          Int64(n), Int64(k), Int64(full), grid_dim=n // 128,
                                                          block_dim=128)
            else:
                self.ctx.enqueue_function[q35k.gemm64[1]](wq, self.halves["embed.d"], wq, self.floats[name + ".d"],
                                                          self.floats[name + ".c"], x, y, Int64(n), Int64(k),
                                                          Int64(full), grid_dim=n // 128, block_dim=128)

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

    def tick(mut self, kind: String) raises:
        """Profiling: wait for the launches so far and charge their time to `kind`."""
        if not self.prof:
            return
        self.ctx.synchronize()
        var t = Float64(perf_counter_ns()) / 1e6
        self.times[kind] = self.times.get(kind, 0.0) + (t - self.mark)
        self.mark = t

    # ---- the token mixers, for `count` rows from position p0 (decode: one row) -----------------------------------

    def linear_attention(mut self, l: Int, p0: Int, count: Int, rows: Int) raises:
        """Layer l's Gated DeltaNet over xn's rows into tmp: the q|k|v|z and a|b projections, the conv + SiLU + q/k L2
        norms + decay / beta, the delta rule a row after another, the gated norm, out_proj. rows: 0 for decode (one
        row, matrix-vector products), else the batch's rows padded to 64 (matrix units)."""
        var ctx = self.ctx
        var D = self.D
        var n = "l" + String(l) + "."
        var i = self.slot[l]
        if rows == 0:
            self.gemv(n + "qkvz", self.xn, self.mix, D, self.QKVZ)
        else:
            self.gemm(n + "qkvz", self.xn, self.mix, self.QKVZ, D, rows)
        self.tick("linear: q|k|v|z")
        ctx.enqueue_function[q35k.gemv_f32](self.floats[n + "ab"], self.xn, self.ab, Int32(D), Int32(64),
                                            grid_dim=Dim(64, count), block_dim=64)
        self.tick("linear: a|b")
        ctx.enqueue_function[q35k.conv_qk](self.mix, self.floats[n + "conv"], self.conv[i], self.cq, self.ab,
                                           self.floats[n + "dt"], self.floats[n + "a"], self.gb, Int32(p0),
                                           Int32(self.QKVZ), Int32(1 if rows == 0 else 0),
                                           grid_dim=Dim(64, count), block_dim=64)
        if rows:
            ctx.enqueue_function[q35k.conv_state](self.mix, self.conv[i], Int32(p0), Int32(count), Int32(self.QKVZ),
                                                  grid_dim=groups(3 * CONV, 64), block_dim=64)
        self.tick("linear: conv, norms")
        var nc = self.dnc if rows else 1  # decode: one row, the most workgroups
        if nc == 4:
            ctx.enqueue_function[q35k.delta_rule[4]](self.cq, self.gb, self.S[i], self.o, Int32(count),
                                                     grid_dim=Dim(q35k.NV, q35k.DK // 16), block_dim=64)
        elif nc == 2:
            ctx.enqueue_function[q35k.delta_rule[2]](self.cq, self.gb, self.S[i], self.o, Int32(count),
                                                     grid_dim=Dim(q35k.NV, q35k.DK // 8), block_dim=64)
        else:
            ctx.enqueue_function[q35k.delta_rule[1]](self.cq, self.gb, self.S[i], self.o, Int32(count),
                                                     grid_dim=Dim(q35k.NV, q35k.DK // 4), block_dim=64)
        self.tick("linear: delta rule")
        ctx.enqueue_function[q35k.gated_norm](self.o, self.mix, self.floats[n + "gnorm"], self.att, Int32(self.QKVZ),
                                              Int32(CONV), grid_dim=Dim(q35k.NV, count), block_dim=64)
        self.tick("linear: gated norm")
        if rows == 0:
            self.gemv(n + "out", self.att, self.tmp, NVD, D)
        else:
            self.gemm(n + "out", self.att, self.tmp, D, NVD, rows)
        self.tick("linear: out_proj")

    def full_attention(mut self, l: Int, p0: Int, count: Int, rows: Int) raises:
        """Layer l's gated attention over xn's rows into tmp: q|k|v|gate, q/k norms + RoPE + K/V cache rows, softmax
        (q K^T / 16) V, times sigmoid(gate), o_proj."""
        var ctx = self.ctx
        var D = self.D
        var n = "l" + String(l) + "."
        var i = self.slot[l]
        var H = self.H
        var KVH = self.KVH
        if rows == 0:
            self.gemv(n + "qkvg", self.xn, self.mix, D, self.QKVG)
        else:
            self.gemm(n + "qkvg", self.xn, self.mix, self.QKVG, D, rows)
        self.tick("full: q|k|v|gate")
        ctx.enqueue_function[q35k.qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                self.rope, self.kc[i], self.vc[i], Int32(p0), Int32(self.QKVG),
                                                grid_dim=Dim(H + 2 * KVH, count), block_dim=64)
        if rows == 0:
            ctx.enqueue_function[q35k.attn_part](self.mix, self.kc[i], self.vc[i], self.pv, self.pm, Int32(p0),
                                                 grid_dim=Dim(KVH, groups(p0 + 1, q35k.CH)), block_dim=64)
            ctx.enqueue_function[q35k.attn_combine](self.pv, self.pm, self.mix, self.att, Int32(p0), grid_dim=H,
                                                    block_dim=64)
        else:
            var kcap = self.CAP + PAD
            var nq = Int32(H // KVH)
            ctx.enqueue_function[g4k.p_scores_mma[HD]](self.mix, self.kc[i], self.pscores, Int32(p0), Int32(0), nq,
                                                       Int32(KVH), Int32(self.QKVG), Int32(H), Int32(kcap),
                                                       grid_dim=Dim(rows // 64, H), block_dim=64)
            ctx.enqueue_function[g4k.p_softmax](self.pscores, Int32(p0), Int32(count), Int32(0), Int32(H), Int32(kcap),
                                                grid_dim=Dim(H, rows), block_dim=64)
            ctx.enqueue_function[g4k.p_values_mma[HD]](self.pscores, self.vc[i], self.att, Int32(p0), Int32(0), nq,
                                                       Int32(KVH), Int32(H), Int32(kcap),
                                                       grid_dim=Dim(rows // 64, H * (HD // 64)), block_dim=64)
            ctx.enqueue_function[q35k.gate_mul](self.att, self.mix, Int32(count), Int32(self.QKVG),
                                                grid_dim=groups(count * H * HD, 64), block_dim=64)
        self.tick("full: norms, RoPE, attention")
        if rows == 0:
            self.gemv(n + "o", self.att, self.tmp, H * HD, D)
        else:
            self.gemm(n + "o", self.att, self.tmp, D, H * HD, rows)
        self.tick("full: o_proj")

    def mlp(mut self, l: Int, count: Int, rows: Int) raises:
        """xn's rows through layer l's SwiGLU MLP into tmp."""
        var ctx = self.ctx
        var D = self.D
        var n = "l" + String(l) + "."
        if rows == 0:
            ctx.enqueue_function[lk.gate_up_q4[True]](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.xn,
                                                      self.act, Int32(D), Int32(self.F), grid_dim=self.F,
                                                      block_dim=64)
            self.tick("mlp: gate/up + SiLU")
            self.gemv(n + "down", self.act, self.tmp, self.F, D)
        else:
            self.gemm(n + "gu", self.xn, self.gu, 2 * self.F, D, rows)
            ctx.enqueue_function[lk.silu_mul](self.gu, self.act, Int32(self.F), Int32(count),
                                              grid_dim=groups(count * self.F, 64), block_dim=64)
            self.tick("mlp: gate/up + SiLU")
            self.gemm(n + "down", self.act, self.tmp, D, self.F, rows)
        self.tick("mlp: down")

    def layer(mut self, l: Int, p0: Int, count: Int, rows: Int) raises:
        var D = self.D
        var n = "l" + String(l) + "."
        if self.linear(l):
            self.linear_attention(l, p0, count, rows)
        else:
            self.full_attention(l, p0, count, rows)
        self.ctx.enqueue_function[q4bk.add_norm](self.x, self.tmp, self.floats[n + "post_norm"], self.xn, Int32(D),
                                                 Int32(1), grid_dim=count, block_dim=64)
        self.tick("residual adds + norms")
        self.mlp(l, count, rows)
        self.ctx.enqueue_function[q4bk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn, Int32(D),
                                                 Int32(1), grid_dim=count, block_dim=64)
        self.tick("residual adds + norms")

    # ---- a token -----------------------------------------------------------------------------------------------------

    def step(mut self, pos: Int, head: Bool = True) raises:
        """The token ids[pos] through the model: logits, and their argmax into ids[pos + 1] (head; a prompt token but
        the last needs neither, and its next id is the prompt's)."""
        if self.prof:
            self.ctx.synchronize()
            self.mark = Float64(perf_counter_ns()) / 1e6
        self.embed(pos, 1)
        self.tick("embed + norm")
        for l in range(self.L):
            self.layer(l, pos, 1, 0)
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
        var Rr = groups(count, 64) * 64  # rows the matrix products compute (gemm: 128s and a last 64)
        if p0 + Rr > self.CAP + PAD:
            raise Error("prefill past the context")
        if self.prof:
            self.ctx.synchronize()
            self.mark = Float64(perf_counter_ns()) / 1e6
        self.embed(p0, count)
        self.tick("embed + norm")
        var out = FileHandle()
        var rows = List[Float32]()
        if self.dump:
            out = open(self.dump, "w")
            rows = List[Float32](length=count * self.D, fill=0)
            self.write_rows(out, rows, count)
        for l in range(self.L):
            self.layer(l, p0, count, Rr)
            if self.dump:
                self.write_rows(out, rows, count)
        if self.dump:
            out.close()
        if last:
            self.head(count - 1, p0 + count)
            self.tick("head + argmax")
