# Llama 3.x of any size on the Adreno 840 as MAX DeviceContext launches: llama/model.mojo's forward pass with every size
# read from the manifest ("llama D L H KVH HD F V MAXPOS CHUNKS"; llama/model.mojo has Llama 3.2 1B's compiled in).
# Weights from llama/run3.py's export: int4 projections and head (an fp16 scale per 64) or fp16; fp32 activations and
# KV cache. Decode: llama/kernels' matrix-vector products, llama/kernels/lg.mojo's kernels of any size, and gemma4's
# attention values. prefill(): the whole prompt at once, the products on cooperative matrices (kernels/prefill's fp32
# ones, or lkh's fp16 ones with LLAMA_GEMM=q, as llama/model.mojo) and gemma4's attention on the matrix units. The KV
# cache is position-major ([position][KVH HD]), as those attention kernels read it.
from std.collections import Dict
from std.math import sqrt
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import g4k
import gemv
import gemv_add
import gemv_add_q4
import gemv_q4
import lg
import lk
import lkh
import p_gemm
import p_gemm_q4

comptime GCH = 1024  # lkh's K chunks, as llama/model.mojo (2048 flipped Llama 3.2 1B's near-tied first token)


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


struct Llama3(Movable):
    var ctx: DeviceContext
    var D: Int
    var L: Int
    var H: Int
    var KVH: Int
    var HD: Int
    var F: Int
    var V: Int
    var CAP: Int  # positions the KV cache holds
    var CHUNKS: Int  # the embedding (and head) in this many tensors
    var CROWS: Int
    var QKV: Int
    var halves: Dict[String, DeviceBuffer[DType.float16]]  # fp16 tensors and int4 scales
    var words: Dict[String, DeviceBuffer[DType.uint32]]  # int4 weights, 8 a word
    var floats: Dict[String, DeviceBuffer[DType.float32]]  # the RoPE tables
    var q4: Bool
    var gemmq: Bool  # LLAMA_GEMM=q (at construction)
    var x: DeviceBuffer[DType.float32]
    var xn: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]
    var act: DeviceBuffer[DType.float32]
    var scores: DeviceBuffer[DType.float32]  # decode: [H, CAP]
    var logits: DeviceBuffer[DType.float32]
    var logit_chunks: List[DeviceBuffer[DType.float32]]
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]
    var xa: DeviceBuffer[DType.float16]  # lkh's X: fp16 R tiles of up to CAP rows of the widest k
    var part: DeviceBuffer[DType.float16]  # lkh's fp16 partial products, a K chunk each

    def __init__(out self, ctx: DeviceContext, dir: String, gemmq: Bool = False) raises:
        self.ctx = ctx
        var lines = open(dir + "/manifest.txt", "r").read().split("\n")
        var h = lines[0].split(" ")
        if len(h) != 10 or h[0] != "llama":
            raise Error("manifest.txt: not a llama manifest")
        self.D = Int(h[1])
        self.L = Int(h[2])
        self.H = Int(h[3])
        self.KVH = Int(h[4])
        self.HD = Int(h[5])
        self.F = Int(h[6])
        self.V = Int(h[7])
        self.CAP = Int(h[8])
        self.CHUNKS = Int(h[9])
        self.CROWS = self.V // self.CHUNKS
        self.QKV = (self.H + 2 * self.KVH) * self.HD
        var nq = self.H // self.KVH
        if (self.HD != 64 and self.HD != 128) or self.H % self.KVH != 0 or (nq != 3 and nq != 4 and nq != 8):
            raise Error("head dim 64 or 128, and 3, 4 or 8 query heads a KV head")
        if self.CAP % 128 != 0:
            raise Error("MAXPOS: a multiple of 128")
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.q4 = False
        self.gemmq = gemmq
        var D = self.D
        self.x = ctx.enqueue_create_buffer[DType.float32](D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](D)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](self.QKV)
        self.att = ctx.enqueue_create_buffer[DType.float32](self.H * self.HD)
        self.gu = ctx.enqueue_create_buffer[DType.float32](2 * self.F)
        self.act = ctx.enqueue_create_buffer[DType.float32](self.F)
        self.scores = ctx.enqueue_create_buffer[DType.float32](self.H * self.CAP)
        self.logits = ctx.enqueue_create_buffer[DType.float32](self.V)
        self.logit_chunks = List[DeviceBuffer[DType.float32]]()
        for c in range(self.CHUNKS):
            self.logit_chunks.append(self.logits.create_sub_buffer[DType.float32](c * self.CROWS, self.CROWS))
        self.kc = List[DeviceBuffer[DType.float32]]()
        self.vc = List[DeviceBuffer[DType.float32]]()
        for _ in range(self.L):  # zeroed: the prompt's P V reads padding positions (times probability 0)
            var k = ctx.enqueue_create_buffer[DType.float32](self.CAP * self.KVH * self.HD)
            var v = ctx.enqueue_create_buffer[DType.float32](self.CAP * self.KVH * self.HD)
            k.enqueue_fill(0)
            v.enqueue_fill(0)
            self.kc.append(k)
            self.vc.append(v)
        var kmax = max(D, self.F, self.H * self.HD)
        var nmax = max(groups(D, GCH) * max(self.QKV, 2 * self.F), groups(max(self.F, self.H * self.HD), GCH) * D)
        self.xa = ctx.enqueue_create_buffer[DType.float16](self.CAP * kmax if gemmq else 1)
        self.part = ctx.enqueue_create_buffer[DType.float16](self.CAP * nmax if gemmq else 1)
        self.load(dir)

    def load(mut self, dir: String) raises:
        """weights.bin's tensors, as manifest.txt lists them ("<name> <offset> <bytes>"), each in a device buffer of
        its element type."""
        var lines = open(dir + "/manifest.txt", "r").read().split("\n")
        var weights = open(dir + "/weights.bin", "r")
        var total = 0
        for i in range(1, len(lines)):
            var f = lines[i].split(" ")
            if len(f) != 3:
                continue
            var name = String(f[0])
            var bytes = Int(f[2])
            _ = weights.seek(Int(f[1]))
            var data = weights.read_bytes(bytes)
            if len(data) != bytes:
                raise Error("weights.bin: short read of " + name)
            if name.endswith(".q"):
                var b = self.ctx.enqueue_create_buffer[DType.uint32](bytes // 4)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[UInt32]())
                self.words[name] = b
                self.q4 = True
            elif name.startswith("rope."):
                var b = self.ctx.enqueue_create_buffer[DType.float32](bytes // 4)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[Float32]())
                self.floats[name] = b
            else:
                var b = self.ctx.enqueue_create_buffer[DType.float16](bytes // 2)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[Float16]())
                self.halves[name] = b
            self.ctx.synchronize()  # `data` goes away
            total += bytes
        print("weights:", len(self.halves) + len(self.words) + len(self.floats), "tensors,",
              Float64(total) / 1e9, "GB;", self.L, "layers, hidden", self.D, ", heads", self.H, "/", self.KVH, "of",
              self.HD, "(int4 projections and head)" if self.q4 else "")

    # ---- a token --------------------------------------------------------------------------------------------------

    def proj(self, add: Bool, rows: Int, name: String, x: DeviceBuffer[DType.float32],
             y: DeviceBuffer[DType.float32], cols: Int) raises:
        """y = W x (add: y += W x), with W the tensor `name` in fp16 or int4: a 64-lane workgroup a row."""
        if self.q4:
            var q = self.words[name + ".q"]
            var s = self.halves[name + ".s"]
            if add:
                self.ctx.enqueue_function[gemv_add_q4.gemv_add_q4](q, s, x, y, Int64(cols), grid_dim=rows, block_dim=64)
            else:
                self.ctx.enqueue_function[gemv_q4.gemv_q4](q, s, x, y, Int64(cols), grid_dim=rows, block_dim=64)
        elif add:
            self.ctx.enqueue_function[gemv_add.gemv_add](self.halves[name], x, y, Int64(cols), grid_dim=rows, block_dim=64)
        else:
            self.ctx.enqueue_function[gemv.gemv](self.halves[name], x, y, Int64(cols), grid_dim=rows, block_dim=64)

    def norm(self, x: DeviceBuffer[DType.float32], w: String, y: DeviceBuffer[DType.float32], rows: Int) raises:
        self.ctx.enqueue_function[lg.rmsnorm](x, self.halves[w], y, Int32(self.D), grid_dim=rows, block_dim=lg.T)

    def rope(self, qkv: DeviceBuffer[DType.float32], l: Int, p0: Int, rows: Int) raises:
        var scale = Float32(1.0 / sqrt(Float64(self.HD)))
        var g = Dim(groups((self.H + self.KVH) * self.HD // 2, 64), rows)
        if self.HD == 64:
            self.ctx.enqueue_function[lg.rope[64]](qkv, self.floats["rope.cos"], self.floats["rope.sin"], self.kc[l],
                                                   self.vc[l], Int32(p0), Int32(self.H), Int32(self.KVH),
                                                   Int32(self.QKV), scale, grid_dim=g, block_dim=64)
        else:
            self.ctx.enqueue_function[lg.rope[128]](qkv, self.floats["rope.cos"], self.floats["rope.sin"], self.kc[l],
                                                    self.vc[l], Int32(p0), Int32(self.H), Int32(self.KVH),
                                                    Int32(self.QKV), scale, grid_dim=g, block_dim=64)

    def attention(self, l: Int, pos: Int) raises:
        """att = attention of qkv's q (scaled) over the cache's positions 0 .. pos."""
        var nq = self.H // self.KVH
        var g = groups(self.KVH * (pos + 1), 64)
        var pp = Int32(pos)
        var kvh = Int32(self.KVH)
        var hd = Int32(self.HD)
        var cap = Int32(self.CAP)
        if nq == 3:
            self.ctx.enqueue_function[lg.attn_scores[3]](self.qkv, self.kc[l], self.scores, pp, kvh, hd, cap,
                                                         grid_dim=g, block_dim=64)
        elif nq == 4:
            self.ctx.enqueue_function[lg.attn_scores[4]](self.qkv, self.kc[l], self.scores, pp, kvh, hd, cap,
                                                         grid_dim=g, block_dim=64)
        else:
            self.ctx.enqueue_function[lg.attn_scores[8]](self.qkv, self.kc[l], self.scores, pp, kvh, hd, cap,
                                                         grid_dim=g, block_dim=64)
        self.ctx.enqueue_function[g4k.attn_values](self.scores, self.vc[l], self.att, Int32(pos), Int32(0), Int32(nq),
                                                   Int32(self.KVH), Int32(self.HD), Int32(self.CAP),
                                                   grid_dim=self.H * self.HD // 64, block_dim=64)

    def forward(self, token: Int, pos: Int) raises:
        """Enqueues one token at position `pos`; its logits end in `self.logits`."""
        var ctx = self.ctx
        var D = self.D
        ctx.enqueue_function[lg.embed](self.halves["embed." + String(token // self.CROWS)], self.x,
                                       Int32(token % self.CROWS), Int32(D), grid_dim=groups(D, 64), block_dim=64)
        for l in range(self.L):
            var p = "l" + String(l) + "."
            self.norm(self.x, p + "attn_norm", self.xn, 1)
            self.proj(False, self.QKV, p + "wqkv", self.xn, self.qkv, D)
            self.rope(self.qkv, l, pos, 1)
            self.attention(l, pos)
            self.proj(True, D, p + "wo", self.att, self.x, self.H * self.HD)
            self.norm(self.x, p + "mlp_norm", self.xn, 1)
            self.proj(False, 2 * self.F, p + "wgu", self.xn, self.gu, D)
            ctx.enqueue_function[lk.silu_mul](self.gu, self.act, Int32(self.F), Int32(1),
                                              grid_dim=groups(self.F, 64), block_dim=64)
            self.proj(True, D, p + "wdown", self.act, self.x, self.F)
        self.head()

    def head(self) raises:
        """The logits of `self.x`: the final norm, then the head (the tied embedding; int4: its own copy)."""
        self.norm(self.x, "final_norm", self.xn, 1)
        for c in range(self.CHUNKS):
            self.proj(False, self.CROWS, ("lm." if self.q4 else "embed.") + String(c), self.xn, self.logit_chunks[c],
                      self.D)

    # ---- the prompt -------------------------------------------------------------------------------------------------

    def pproj(self, n: Int, k: Int, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
              rows: Int) raises:
        """Y = X W^T for `rows` rows (a multiple of 128), W the tensor `name` (n x k) in fp16 or int4: kernels/prefill's
        fp32 cooperative products, or with LLAMA_GEMM=q lkh's fp16 ones (pack_x, gemm_hq, sum_parts)."""
        if self.gemmq:
            var chunks = groups(k, GCH)
            if rows * k > len(self.xa) or chunks * rows * n > len(self.part):
                raise Error("lkh: a buffer is too small")
            self.ctx.enqueue_function[lkh.pack_x](x, self.xa.create_sub_buffer[DType.uint32](0, rows * k // 2),
                                                  Int32(k), Int32(rows * k // 8), grid_dim=groups(rows * k // 8, 256),
                                                  block_dim=256)
            var g = Dim(n // 64, rows // 128, chunks)
            if self.q4:
                self.ctx.enqueue_function[lkh.gemm_hq[2, 1, GCH, 64, 4, False, 64, lkh.Q4]](
                    self.xa, self.words[name + ".q"], self.halves[name + ".s"], self.part, Int32(n), Int32(k),
                    Int32(rows), grid_dim=g, block_dim=128)
            else:  # the fp16 rows as pairs of halves; no scales
                var w = self.halves[name]
                self.ctx.enqueue_function[lkh.gemm_hq[2, 1, GCH, 64, 4, False, 64, lkh.FP16]](
                    self.xa, w.create_sub_buffer[DType.uint32](0, n * k // 2), w, self.part, Int32(n), Int32(k),
                    Int32(rows), grid_dim=g, block_dim=128)
            self.ctx.enqueue_function[lkh.sum_parts](self.part, y, Int32(rows * n), Int32(chunks),
                                                     grid_dim=groups(rows * n // 8, 256), block_dim=256)
            return
        var grid = Dim(n // 128, rows // 128)
        if self.q4:
            self.ctx.enqueue_function[p_gemm_q4.p_gemm_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                           Int64(n), Int64(k), grid_dim=grid, block_dim=256)
        else:
            self.ctx.enqueue_function[p_gemm.p_gemm](self.halves[name], x, y, Int64(n), Int64(k), grid_dim=grid,
                                                     block_dim=256)

    def prefill(mut self, tokens: List[Int]) raises:
        """Enqueues the whole prompt at once, at positions 0 .. len(tokens) - 1 (padded to 128 rows): per layer the
        decode steps for every row, attention on the matrix units; then the last row's logits in `self.logits`."""
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var HD = self.HD
        var n = len(tokens)
        var rows = groups(n, 128) * 128
        if rows > self.CAP:
            raise Error("prefill: " + String(rows) + " padded prompt rows > " + String(self.CAP))
        var xr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var xnr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var qkvr = ctx.enqueue_create_buffer[DType.float32](rows * self.QKV)
        var attr = ctx.enqueue_create_buffer[DType.float32](rows * H * HD)
        var gur = ctx.enqueue_create_buffer[DType.float32](rows * 2 * self.F)
        var actr = ctx.enqueue_create_buffer[DType.float32](rows * self.F)
        var yr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var pscores = ctx.enqueue_create_buffer[DType.float32](rows * H * self.CAP)
        xr.enqueue_fill(0)  # the padding rows
        for t in range(n):
            ctx.enqueue_function[lg.embed](self.halves["embed." + String(tokens[t] // self.CROWS)],
                                           xr.create_sub_buffer[DType.float32](t * D, D),
                                           Int32(tokens[t] % self.CROWS), Int32(D), grid_dim=groups(D, 64),
                                           block_dim=64)
        var nq = Int32(H // self.KVH)
        var cap = Int32(self.CAP)
        for l in range(self.L):
            var p = "l" + String(l) + "."
            self.norm(xr, p + "attn_norm", xnr, rows)
            self.pproj(self.QKV, D, p + "wqkv", xnr, qkvr, rows)
            self.rope(qkvr, l, 0, n)
            if HD == 64:
                ctx.enqueue_function[g4k.p_scores_mma[64]](qkvr, self.kc[l], pscores, Int32(0), Int32(0), nq,
                                                           Int32(self.KVH), Int32(self.QKV), Int32(H), cap,
                                                           grid_dim=Dim(rows // 64, H), block_dim=64)
            else:
                ctx.enqueue_function[g4k.p_scores_mma[128]](qkvr, self.kc[l], pscores, Int32(0), Int32(0), nq,
                                                            Int32(self.KVH), Int32(self.QKV), Int32(H), cap,
                                                            grid_dim=Dim(rows // 64, H), block_dim=64)
            ctx.enqueue_function[g4k.p_softmax](pscores, Int32(0), Int32(n), Int32(0), Int32(H), cap,
                                                grid_dim=Dim(H, rows), block_dim=64)
            if HD == 64:
                ctx.enqueue_function[g4k.p_values_mma[64]](pscores, self.vc[l], attr, Int32(0), Int32(0), nq,
                                                           Int32(self.KVH), Int32(H), cap,
                                                           grid_dim=Dim(rows // 64, H), block_dim=64)
            else:
                ctx.enqueue_function[g4k.p_values_mma[128]](pscores, self.vc[l], attr, Int32(0), Int32(0), nq,
                                                            Int32(self.KVH), Int32(H), cap,
                                                            grid_dim=Dim(rows // 64, H * 2), block_dim=64)
            self.pproj(D, H * HD, p + "wo", attr, yr, rows)
            ctx.enqueue_function[lg.p_add](xr, yr, Int32(n * D), grid_dim=groups(n * D, 256), block_dim=256)
            self.norm(xr, p + "mlp_norm", xnr, rows)
            self.pproj(2 * self.F, D, p + "wgu", xnr, gur, rows)
            ctx.enqueue_function[lk.silu_mul](gur, actr, Int32(self.F), Int32(rows),
                                              grid_dim=groups(rows * self.F, 64), block_dim=64)
            self.pproj(D, self.F, p + "wdown", actr, yr, rows)
            ctx.enqueue_function[lg.p_add](xr, yr, Int32(n * D), grid_dim=groups(n * D, 256), block_dim=256)
        ctx.enqueue_copy(self.x, xr.create_sub_buffer[DType.float32]((n - 1) * D, D))  # the last prompt row
        self.head()
