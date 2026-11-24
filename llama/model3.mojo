# Llama 3.x of any size on the Adreno 840 as MAX DeviceContext launches: llama/model.mojo's forward pass with every size
# read from the manifest ("llama D L H KVH HD F V MAXPOS CHUNKS"; llama/model.mojo has Llama 3.2 1B's compiled in).
# Weights from llama/run3.py's export: int4 projections and head (an fp16 scale per 64) or fp16; fp32 activations and
# KV cache. Decode: llama/kernels' matrix-vector products, llama/kernels/lg.mojo's kernels of any size, and gemma4's
# attention values. prefill(): the whole prompt at once, the products on cooperative matrices (kernels/prefill's fp32
# ones, or lkh's fp16 ones with LLAMA_GEMM=q, as llama/model.mojo) and gemma4's attention on the matrix units. The KV
# cache is position-major ([position][KVH HD]), as those attention kernels read it.
from std.collections import Dict
from std.math import sqrt
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import g4k
import l85
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
    var nsc: DeviceBuffer[DType.float32]  # lg.norm_scale's per-row scales (CAP rows)
    var fuse: Bool  # LLAMA_GEMM=q's prompt layers with the glue fused (layer_q; LLAMA_FUSE=0: each projection alone)
    var norm_tiled: Bool  # layer_q's norms: lg.norm_scale + lg.norm_pack_t (LLAMA_NORM=row: lg.rmsnorm_pack)
    var ch2: Bool  # LLAMA_CH=2048: layer_q's products in K chunks of 2048 (faster, less accurate: GCH's comment)
    var k850: Bool  # LLAMA_GEMM=k: layer_q's products with lkh.gemm_k (the Adreno 850: B K-minor, one K chunk)
    var prof: Bool  # LLAMA_PROFILE=1: the prompt waits after each kind of launch and adds its time to times[kind]
    var times: Dict[String, Float64]
    var mark: Float64
    var fa: List[DeviceBuffer[DType.float16]]  # LLAMA_GEMM=k's prompt q, k and v^T tiles (l85)
    var xb: DeviceBuffer[DType.float16]  # LLAMA_GEMM=k: silu(gate) up packed for down (gate|up reads xa)
    var ss: DeviceBuffer[DType.float32]  # LLAMA_GEMM=k: the residual epilogues' sums of squares, D / 64 a row
    var qkvt: Int  # LLAMA_QKV: q|k|v with the RoPE epilogue, tiling 21 / 22 / 42 (WM WN); 0: unfused
    var reg: Bool  # LLAMA_GEMM=k's products with the int4 weights dequantized in registers, from panels (LLAMA_REG=0: off)
    var pw: Dict[String, DeviceBuffer[DType.uint32]]  # lkh.repack_q4's panels of the projections (reg)
    var ps: Dict[String, DeviceBuffer[DType.float16]]  # and their scales

    def __init__(out self, ctx: DeviceContext, dir: String, gemmq: Bool = False, synth: Bool = False) raises:
        """dir: run3.py's manifest.txt and weights.bin. synth: no weights.bin, every tensor filled on the GPU with
        random int4 words and plain fp16 scales, norms and embeddings (LLAMA_SYNTH: timing without the weights)."""
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
        self.nsc = ctx.enqueue_create_buffer[DType.float32](self.CAP)
        self.fuse = True
        self.norm_tiled = True
        self.ch2 = False
        self.k850 = False
        self.prof = False
        self.times = Dict[String, Float64]()
        self.mark = 0
        self.fa = List[DeviceBuffer[DType.float16]]()
        self.xb = ctx.enqueue_create_buffer[DType.float16](self.CAP * kmax if gemmq else 1)
        self.ss = ctx.enqueue_create_buffer[DType.float32](self.CAP * (D // 64))
        self.reg = False
        self.qkvt = 22
        self.pw = Dict[String, DeviceBuffer[DType.uint32]]()
        self.ps = Dict[String, DeviceBuffer[DType.float16]]()
        if synth:
            self.synthesize(dir)
        else:
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

    def synthesize(mut self, dir: String) raises:
        """The manifest's tensors, each filled on the GPU (lg.fill) instead of read from weights.bin: int4 words
        random, scales 0.01, norm weights 1, embedding rows random in 2^-7 .. 2^-6, RoPE tables 0.5."""
        var lines = open(dir + "/manifest.txt", "r").read().split("\n")
        var total = 0
        var seed = UInt32(1)
        for i in range(1, len(lines)):
            var f = lines[i].split(" ")
            if len(f) != 3:
                continue
            var name = String(f[0])
            var bytes = Int(f[2])
            var w: DeviceBuffer[DType.uint32]
            var mask = UInt32(0)
            var bits = UInt32(0)
            if name.endswith(".q"):
                w = self.ctx.enqueue_create_buffer[DType.uint32](bytes // 4)
                self.words[name] = w
                self.q4 = True
                mask = 0xFFFFFFFF
            elif name.startswith("rope."):
                var b = self.ctx.enqueue_create_buffer[DType.float32](bytes // 4)
                self.floats[name] = b
                w = b.create_sub_buffer[DType.uint32](0, bytes // 4)
                bits = 0x3F000000
            else:
                var b = self.ctx.enqueue_create_buffer[DType.float16](bytes // 2)
                self.halves[name] = b
                w = b.create_sub_buffer[DType.uint32](0, bytes // 4)
                if name.endswith(".s"):
                    bits = 0x211F211F
                elif name.startswith("embed."):
                    mask = 0x03FF03FF
                    bits = 0x20002000
                else:
                    bits = 0x3C003C00
            var n = bytes // 4
            self.ctx.enqueue_function[lg.fill](w, Int32(n), seed, mask, bits, grid_dim=groups(n, 256),
                                               block_dim=256)
            seed += 1
            total += bytes
        self.ctx.synchronize()
        print("weights: synthetic,", Float64(total) / 1e9, "GB;", self.L, "layers, hidden", self.D, ", heads", self.H,
              "/", self.KVH, "of", self.HD)

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

    def tick(mut self, kind: String) raises:
        """LLAMA_PROFILE: wait for what is enqueued and add the time since the last tick to times[kind]."""
        if not self.prof:
            return
        self.ctx.synchronize()
        var now = Float64(perf_counter_ns()) / 1e6
        self.times[kind] = self.times.get(kind, 0.0) + now - self.mark
        self.mark = now

    def report(self) raises:
        var total = 0.0
        for e in self.times.items():
            total += e.value
        for e in self.times.items():
            print("profile:", e.key, round(e.value, 1), "ms (" + String(round(100 * e.value / total, 1)) + "%)")
        print("profile: total", round(total, 1), "ms")

    def pproj(mut self, n: Int, k: Int, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
              rows: Int, kind: String) raises:
        """Y = X W^T for `rows` rows (a multiple of 128), W the tensor `name` (n x k) in fp16 or int4: kernels/prefill's
        fp32 cooperative products, or with LLAMA_GEMM=q lkh's fp16 ones (pack_x, gemm_hq, sum_parts)."""
        if self.gemmq:
            var chunks = groups(k, GCH)
            if rows * k > len(self.xa) or chunks * rows * n > len(self.part):
                raise Error("lkh: a buffer is too small")
            self.ctx.enqueue_function[lkh.pack_x](x, self.xa.create_sub_buffer[DType.uint32](0, rows * k // 2),
                                                  Int32(k), Int32(rows * k // 8), grid_dim=groups(rows * k // 8, 256),
                                                  block_dim=256)
            self.tick("pack_x")
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
            self.tick(kind)
            self.ctx.enqueue_function[lkh.sum_parts](self.part, y, Int32(rows * n), Int32(chunks),
                                                     grid_dim=groups(rows * n // 8, 256), block_dim=256)
            self.tick("sum_parts")
            return
        var grid = Dim(n // 128, rows // 128)
        if self.q4:
            self.ctx.enqueue_function[p_gemm_q4.p_gemm_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                           Int64(n), Int64(k), grid_dim=grid, block_dim=256)
        else:
            self.ctx.enqueue_function[p_gemm.p_gemm](self.halves[name], x, y, Int64(n), Int64(k), grid_dim=grid,
                                                     block_dim=256)
        self.tick(kind)

    def gemm_q(mut self, n: Int, k: Int, name: String, rows: Int, kind: String) raises -> Int:
        """LLAMA_GEMM=q's product alone: part (k / chunk fp16 partials of rows x n) = xa (X, already packed) W^T, W the
        int4 or fp16 tensor `name` (n x k). Returns the number of chunks."""
        var chunks: Int
        if self.k850 and self.q4:
            chunks = self.gemm_k850(n, k, name, rows)
        elif self.ch2:
            chunks = self.gemm_c[2 * GCH](n, k, name, rows)
        else:
            chunks = self.gemm_c[GCH](n, k, name, rows)
        self.tick(kind)
        return chunks

    def gemm_k850(mut self, n: Int, k: Int, name: String, rows: Int) raises -> Int:
        """The Adreno 850's product (lkh.gemm_k): part = xa W^T in one chunk, the tiling tuned per shape at 512 rows
        (llama/bench_k.mojo): K steps of 128 for q|k|v and down, 4 x 1 subgroups for o and down, 2 x 2 for gate|up."""
        if rows * k > len(self.xa) or rows * n > len(self.part):
            raise Error("lkh: a buffer is too small")
        var q = self.words[name + ".q"]
        var s = self.halves[name + ".s"]
        var w4 = rows % 256 == 0
        if k > 4 * GCH:  # down
            if w4:
                self.ctx.enqueue_function[lkh.gemm_k[4, 1, 128, 1, True]](
                    self.xa, q, s, self.part, Int32(n), Int32(k), Int32(rows), grid_dim=Dim(n // 64, rows // 256),
                    block_dim=256)
            else:
                self.ctx.enqueue_function[lkh.gemm_k[2, 1, 128, 1, True]](
                    self.xa, q, s, self.part, Int32(n), Int32(k), Int32(rows), grid_dim=Dim(n // 64, rows // 128),
                    block_dim=128)
        elif n == 2 * self.F:  # gate|up
            self.ctx.enqueue_function[lkh.gemm_k[2, 2, 64, 1, True]](
                self.xa, q, s, self.part, Int32(n), Int32(k), Int32(rows), grid_dim=Dim(n // 128, rows // 128),
                block_dim=256)
        elif n == self.QKV:
            self.ctx.enqueue_function[lkh.gemm_k[2, 1, 128, 1, True]](
                self.xa, q, s, self.part, Int32(n), Int32(k), Int32(rows), grid_dim=Dim(n // 64, rows // 128),
                block_dim=128)
        elif w4:  # o
            self.ctx.enqueue_function[lkh.gemm_k[4, 1, 64, 1, True]](
                self.xa, q, s, self.part, Int32(n), Int32(k), Int32(rows), grid_dim=Dim(n // 64, rows // 256),
                block_dim=256)
        else:
            self.ctx.enqueue_function[lkh.gemm_k[2, 2, 64, 1, True]](
                self.xa, q, s, self.part, Int32(n), Int32(k), Int32(rows), grid_dim=Dim(n // 128, rows // 128),
                block_dim=256)
        return 1

    def gemm_c[CH: Int](mut self, n: Int, k: Int, name: String, rows: Int) raises -> Int:
        var chunks = groups(k, CH)
        if rows * k > len(self.xa) or chunks * rows * n > len(self.part):
            raise Error("lkh: a buffer is too small")
        var g = Dim(n // 64, rows // 128, chunks)
        if self.q4 and k > 4 * GCH:  # down (k 8192): 128-deep K steps, 6% faster there (64 elsewhere)
            self.ctx.enqueue_function[lkh.gemm_hq[2, 1, CH, 128, 4, False, 64, lkh.Q4]](
                self.xa, self.words[name + ".q"], self.halves[name + ".s"], self.part, Int32(n), Int32(k),
                Int32(rows), grid_dim=g, block_dim=128)
        elif self.q4:
            self.ctx.enqueue_function[lkh.gemm_hq[2, 1, CH, 64, 4, False, 64, lkh.Q4]](
                self.xa, self.words[name + ".q"], self.halves[name + ".s"], self.part, Int32(n), Int32(k),
                Int32(rows), grid_dim=g, block_dim=128)
        else:
            var w = self.halves[name]
            self.ctx.enqueue_function[lkh.gemm_hq[2, 1, CH, 64, 4, False, 64, lkh.FP16]](
                self.xa, w.create_sub_buffer[DType.uint32](0, n * k // 2), w, self.part, Int32(n), Int32(k),
                Int32(rows), grid_dim=g, block_dim=128)
        return chunks

    def norm_q(mut self, xr: DeviceBuffer[DType.float32], w: String, rows: Int) raises:
        """xa = the packed fp16 X of RMSNorm(xr) w, for the projection that follows."""
        var xa32 = self.xa.create_sub_buffer[DType.uint32](0, len(self.xa) // 2)
        if self.norm_tiled:
            self.ctx.enqueue_function[lg.norm_scale](xr, self.nsc, Int32(self.D), grid_dim=rows, block_dim=lg.T)
            self.ctx.enqueue_function[lg.norm_pack_t](xr, self.halves[w], self.nsc, xa32, Int32(self.D),
                                                      grid_dim=Dim(self.D // 64, rows // 64), block_dim=256)
        else:
            self.ctx.enqueue_function[lg.rmsnorm_pack](xr, self.halves[w], xa32, Int32(self.D), grid_dim=rows,
                                                       block_dim=lg.T)
        self.tick("norms")

    def layer_q(mut self, l: Int, n: Int, rows: Int, xr: DeviceBuffer[DType.float32],
                qkvr: DeviceBuffer[DType.float32], attr: DeviceBuffer[DType.float32],
                pscores: DeviceBuffer[DType.float32], qp: DeviceBuffer[DType.float32]) raises:
        """A layer of the prompt with LLAMA_GEMM=q, the glue fused: the norms write the projections' packed fp16 X
        (lg.rmsnorm_pack), o's and down's partials are added into the residual stream (lkh.sum_parts_add), and gate|up's
        into silu(gate) up packed for down (lkh.swiglu_pack_t); q and k^T also go to p_scores_packed's layouts
        (lg.rope_pack)."""
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var p = "l" + String(l) + "."
        var xa32 = self.xa.create_sub_buffer[DType.uint32](0, len(self.xa) // 2)
        self.norm_q(xr, p + "attn_norm", rows)
        var c = self.gemm_q(self.QKV, D, p + "wqkv", rows, "q/k/v")
        ctx.enqueue_function[lkh.sum_parts](self.part, qkvr, Int32(rows * self.QKV), Int32(c),
                                            grid_dim=groups(rows * self.QKV // 8, 256), block_dim=256)
        self.tick("sum_parts")
        var scale = Float32(1.0 / sqrt(Float64(self.HD)))
        var g = Dim(groups((H + self.KVH) * self.HD // 2, 64), n)
        if self.HD == 64:
            ctx.enqueue_function[lg.rope_pack[64]](qkvr, self.floats["rope.cos"], self.floats["rope.sin"], self.kc[l],
                                                   self.vc[l], qp, Int32(H), Int32(self.KVH), Int32(self.QKV),
                                                   Int32(rows), scale, grid_dim=g, block_dim=64)
        else:
            ctx.enqueue_function[lg.rope_pack[128]](qkvr, self.floats["rope.cos"], self.floats["rope.sin"], self.kc[l],
                                                    self.vc[l], qp, Int32(H), Int32(self.KVH), Int32(self.QKV),
                                                    Int32(rows), scale, grid_dim=g, block_dim=64)
        self.tick("rope")
        self.attention_p(l, n, rows, qp, attr, pscores)
        self.tick("attention")
        ctx.enqueue_function[lkh.pack_t](attr, xa32, Int32(H * self.HD), grid_dim=Dim(H * self.HD // 64, rows // 64),
                                         block_dim=256)
        self.tick("pack_x")
        c = self.gemm_q(D, H * self.HD, p + "wo", rows, "o")
        ctx.enqueue_function[lkh.sum_parts_add](self.part, xr, Int32(n * D), Int32(c), Int32(rows * D),
                                                grid_dim=groups(n * D // 8, 256), block_dim=256)
        self.tick("sum_parts + add")
        self.mlp_q(l, n, rows, xr)

    def mlp_q(mut self, l: Int, n: Int, rows: Int, xr: DeviceBuffer[DType.float32]) raises:
        """layer_q's MLP: the norm, gate|up, silu(gate) up packed for down, down added into the residual."""
        var ctx = self.ctx
        var D = self.D
        var p = "l" + String(l) + "."
        var xa32 = self.xa.create_sub_buffer[DType.uint32](0, len(self.xa) // 2)
        self.norm_q(xr, p + "mlp_norm", rows)
        var c = self.gemm_q(2 * self.F, D, p + "wgu", rows, "gate/up")
        ctx.enqueue_function[lkh.swiglu_pack_t](self.part, Int32(c), Int32(rows), Int32(self.F), xa32,
                                                grid_dim=Dim(self.F // 64, rows // 64), block_dim=256)
        self.tick("swiglu_pack")
        c = self.gemm_q(D, self.F, p + "wdown", rows, "down")
        ctx.enqueue_function[lkh.sum_parts_add](self.part, xr, Int32(n * D), Int32(c), Int32(rows * D),
                                                grid_dim=groups(n * D // 8, 256), block_dim=256)
        self.tick("sum_parts + add")

    def make_panels(mut self) raises:
        """reg: every layer's projections repacked into lkh.repack_q4's panels (K steps of 32), a second copy of the
        int4 weights next to decode's rows (1.4 GB for Llama 3.2 3B)."""
        var D = self.D
        var hd = self.H * self.HD
        var shapes: List[Tuple[String, Int, Int]] = [("wqkv", self.QKV, D), ("wo", D, hd), ("wgu", 2 * self.F, D),
                                                     ("wdown", D, self.F)]
        for l in range(self.L):
            for sh in shapes:
                var name = "l" + String(l) + "." + sh[0]
                var n = sh[1]
                var k = sh[2]
                var wp = self.ctx.enqueue_create_buffer[DType.uint32](n * k // 8)
                var sp = self.ctx.enqueue_create_buffer[DType.float16](n * k // 64)
                # q|k|v: the q and k rows of each head as 0, 64, 1, 65, .. (lkh.gemm_k_rope)
                var perm = (self.H + self.KVH) * self.HD if sh[0] == "wqkv" and self.qkvt != 0 else 0
                self.ctx.enqueue_function[lkh.repack_q4[4]](self.words[name + ".q"], self.halves[name + ".s"], wp, sp,
                                                           Int32(n), Int32(k), Int32(perm), Int32(self.HD),
                                                           grid_dim=groups(n * k // 32, 256), block_dim=256)
                self.pw[name] = wp
                self.ps[name] = sp
        self.ctx.synchronize()
        self.reg = True

    def layer_k(mut self, l: Int, n: Int, rows: Int, xr: DeviceBuffer[DType.float32],
                qkvr: DeviceBuffer[DType.float32]) raises:
        """A layer of the prompt with LLAMA_GEMM=k (the Adreno 850): AdrenoBLAS's layer in Mojo. The norms write
        packed fp16 X (their row scales from the previous residual epilogue's sums of squares), q|k|v (lkh.gemm_k),
        RoPE into fp16 tiles and flash attention (l85) writing o's packed X, o and down adding into the residual
        stream in their epilogues (lkh.gemm_k_add), gate|up with SwiGLU in its epilogue (lkh.gemm_k_swiglu)."""
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var p = "l" + String(l) + "."
        var xa32 = self.xa.create_sub_buffer[DType.uint32](0, len(self.xa) // 2)
        var xb32 = self.xb.create_sub_buffer[DType.uint32](0, len(self.xb) // 2)
        var w4 = rows % 256 == 0
        if l == 0:
            self.norm_q(xr, p + "attn_norm", rows)
        else:
            self.norm_ss(xr, p + "attn_norm", rows)
        var c = 1
        if self.reg and self.qkvt != 0:  # q|k|v with RoPE and the attention layouts in its epilogue
            var wq = p + "wqkv"
            var qt32 = self.fa[0].create_sub_buffer[DType.uint32](0, len(self.fa[0]) // 2)
            var kt32 = self.fa[1].create_sub_buffer[DType.uint32](0, len(self.fa[1]) // 2)
            var vt32 = self.fa[2].create_sub_buffer[DType.uint32](0, len(self.fa[2]) // 2)
            var scale = Float32(1.0 / sqrt(Float64(self.HD)))
            var nheads = H + 2 * self.KVH
            if self.HD == 128:
                self.qkv_rope[128](l, wq, rows, qt32, kt32, vt32, scale)
            else:
                self.qkv_rope[64](l, wq, rows, qt32, kt32, vt32, scale)
            self.tick("q/k/v + rope")
            self.flash(l, rows)
        elif self.reg:
            var wq = p + "wqkv"
            if w4:
                ctx.enqueue_function[lkh.gemm_k[4, 2, 32, 1, True, 64, lkh.Q4, 8, True, True]](
                    self.xa, self.pw[wq], self.ps[wq], self.part, Int32(self.QKV), Int32(D), Int32(rows),
                    grid_dim=Dim(self.QKV // 128, rows // 256), block_dim=512)
            else:
                ctx.enqueue_function[lkh.gemm_k[2, 2, 32, 1, True, 64, lkh.Q4, 8, True, True]](
                    self.xa, self.pw[wq], self.ps[wq], self.part, Int32(self.QKV), Int32(D), Int32(rows),
                    grid_dim=Dim(self.QKV // 128, rows // 128), block_dim=256)
            self.tick("q/k/v")
        else:
            c = self.gemm_q(self.QKV, D, p + "wqkv", rows, "q/k/v")
        if not (self.reg and self.qkvt != 0):
            ctx.enqueue_function[lkh.sum_parts](self.part, qkvr, Int32(rows * self.QKV), Int32(c),
                                                grid_dim=groups(rows * self.QKV // 8, 256), block_dim=256)
            self.tick("sum_parts")
            self.attention_fa(l, rows, qkvr, Float32(1.0 / sqrt(Float64(self.HD))))
        var wo = p + "wo"
        if self.reg:
            self.add_reg(wo, self.xa, D, H * self.HD, n, rows, xr)
        elif w4:
            ctx.enqueue_function[lkh.gemm_k_add[4, 1, 64, 1, True]](
                self.xa, self.words[wo + ".q"], self.halves[wo + ".s"], xr, self.ss, Int32(D), Int32(H * self.HD),
                Int32(n), grid_dim=Dim(D // 64, rows // 256), block_dim=256)
        else:
            ctx.enqueue_function[lkh.gemm_k_add[2, 2, 64, 1, True]](
                self.xa, self.words[wo + ".q"], self.halves[wo + ".s"], xr, self.ss, Int32(D), Int32(H * self.HD),
                Int32(n), grid_dim=Dim(D // 128, rows // 128), block_dim=256)
        self.tick("o + add")
        self.norm_ss(xr, p + "mlp_norm", rows)
        var wgu = p + "wgu"
        if self.reg:
            ctx.enqueue_function[lkh.gemm_k_swiglu[2, 32, 1, True, REG=True, PANEL=True]](
                self.xa, self.pw[wgu], self.ps[wgu], xb32, Int32(self.F), Int32(D),
                grid_dim=Dim(self.F // 64, rows // 128), block_dim=256)
        else:
            ctx.enqueue_function[lkh.gemm_k_swiglu[2, 64, 1, True]](
                self.xa, self.words[wgu + ".q"], self.halves[wgu + ".s"], xb32, Int32(self.F), Int32(D),
                grid_dim=Dim(self.F // 64, rows // 128), block_dim=256)
        self.tick("gate/up + swiglu")
        var wd = p + "wdown"
        if self.reg:
            self.add_reg(wd, self.xb, D, self.F, n, rows, xr)
        elif w4:
            ctx.enqueue_function[lkh.gemm_k_add[4, 1, 128, 1, True]](
                self.xb, self.words[wd + ".q"], self.halves[wd + ".s"], xr, self.ss, Int32(D), Int32(self.F),
                Int32(n), grid_dim=Dim(D // 64, rows // 256), block_dim=256)
        else:
            ctx.enqueue_function[lkh.gemm_k_add[2, 1, 128, 1, True]](
                self.xb, self.words[wd + ".q"], self.halves[wd + ".s"], xr, self.ss, Int32(D), Int32(self.F),
                Int32(n), grid_dim=Dim(D // 64, rows // 128), block_dim=128)
        self.tick("down + add")

    def qkv_rope[HD: Int](self, l: Int, wq: String, rows: Int, qt32: DeviceBuffer[DType.uint32],
                          kt32: DeviceBuffer[DType.uint32], vt32: DeviceBuffer[DType.uint32], scale: Float32) raises:
        """lkh.gemm_k_rope for head dim HD, tiling self.qkvt (subgroups WM WN)."""
        var ctx = self.ctx
        var H = self.H
        var cs = self.floats["rope.cos"]
        var sn = self.floats["rope.sin"]
        var ncol = (H + 2 * self.KVH) * HD
        var w4 = rows % 256 == 0
        var a = (Int32(H), Int32(self.KVH), Int32(self.D), Int32(rows))
        if self.qkvt == 42 and w4:
            ctx.enqueue_function[lkh.gemm_k_rope[4, 2, 32, HD=HD]](
                self.xa, self.pw[wq], self.ps[wq], qt32, kt32, vt32, self.kc[l], self.vc[l], cs, sn, a[0], a[1], a[2],
                a[3], scale, grid_dim=Dim(ncol // 128, rows // 256), block_dim=512)
        elif self.qkvt == 22 or self.qkvt == 42:
            ctx.enqueue_function[lkh.gemm_k_rope[2, 2, 32, HD=HD]](
                self.xa, self.pw[wq], self.ps[wq], qt32, kt32, vt32, self.kc[l], self.vc[l], cs, sn, a[0], a[1], a[2],
                a[3], scale, grid_dim=Dim(ncol // 128, rows // 128), block_dim=256)
        else:
            ctx.enqueue_function[lkh.gemm_k_rope[2, 1, 32, HD=HD]](
                self.xa, self.pw[wq], self.ps[wq], qt32, kt32, vt32, self.kc[l], self.vc[l], cs, sn, a[0], a[1], a[2],
                a[3], scale, grid_dim=Dim(ncol // 64, rows // 128), block_dim=128)

    def add_reg(self, name: String, x: DeviceBuffer[DType.float16], d: Int, k: Int, n: Int, rows: Int,
                xr: DeviceBuffer[DType.float32]) raises:
        """xr += x W^T (the residual epilogue) with W's panels dequantized in registers. 4 x 1 or 2 x 1 subgroups:
        2 x 2 gives wrong sums with this epilogue on the 850 (driver E17.52.10.04; with B from shared memory it is
        right)."""
        if rows % 256 == 0:
            self.ctx.enqueue_function[lkh.gemm_k_add[4, 1, 32, 1, True, 64, lkh.Q4, 8, True, True]](
                x, self.pw[name], self.ps[name], xr, self.ss, Int32(d), Int32(k), Int32(n),
                grid_dim=Dim(d // 64, rows // 256), block_dim=256)
        else:
            self.ctx.enqueue_function[lkh.gemm_k_add[2, 1, 32, 1, True, 64, lkh.Q4, 8, True, True]](
                x, self.pw[name], self.ps[name], xr, self.ss, Int32(d), Int32(k), Int32(n),
                grid_dim=Dim(d // 64, rows // 128), block_dim=128)

    def norm_ss(mut self, xr: DeviceBuffer[DType.float32], w: String, rows: Int) raises:
        """xa = the packed fp16 X of RMSNorm(xr) w, the row scales from self.ss (a residual epilogue's)."""
        var xa32 = self.xa.create_sub_buffer[DType.uint32](0, len(self.xa) // 2)
        self.ctx.enqueue_function[l85.norm_pack_ss](xr, self.halves[w], self.ss, Int32(self.D // 64), xa32,
                                                    Int32(self.D), grid_dim=Dim(self.D // 64, rows // 64),
                                                    block_dim=256)
        self.tick("norms")

    def attention_fa(mut self, l: Int, rows: Int, qkvr: DeviceBuffer[DType.float32], scale: Float32) raises:
        """LLAMA_GEMM=k's attention (l85): RoPE into fp16 q and k tiles (and the fp32 cache), v^T tiles, then flash
        attention writing the o product's packed X (xa)."""
        var ctx = self.ctx
        var H = self.H
        var KVH = self.KVH
        if self.HD != 128 and self.HD != 64:
            raise Error("LLAMA_GEMM=k: head dim 64 or 128")
        var qt = self.fa[0]
        var kt = self.fa[1]
        var vt = self.fa[2]
        var qt32 = qt.create_sub_buffer[DType.uint32](0, len(qt) // 2)
        var kt32 = kt.create_sub_buffer[DType.uint32](0, len(kt) // 2)
        var vt32 = vt.create_sub_buffer[DType.uint32](0, len(vt) // 2)
        var cs = self.floats["rope.cos"]
        var sn = self.floats["rope.sin"]
        var a = (Int32(H), Int32(KVH), Int32(self.QKV), Int32(rows))
        if self.HD == 128:
            ctx.enqueue_function[l85.rope_fa[128]](qkvr, cs, sn, self.kc[l], qt32, kt32, a[0], a[1], a[2], a[3], scale,
                                                   grid_dim=Dim(groups((H + KVH) * 32, 64), rows), block_dim=64)
            ctx.enqueue_function[l85.v_fa[128]](qkvr, self.vc[l], vt32, a[0], a[1], a[2], a[3],
                                                grid_dim=Dim(groups(KVH * 128, 64), rows // 2), block_dim=64)
        else:
            ctx.enqueue_function[l85.rope_fa[64]](qkvr, cs, sn, self.kc[l], qt32, kt32, a[0], a[1], a[2], a[3], scale,
                                                  grid_dim=Dim(groups((H + KVH) * 16, 64), rows), block_dim=64)
            ctx.enqueue_function[l85.v_fa[64]](qkvr, self.vc[l], vt32, a[0], a[1], a[2], a[3],
                                               grid_dim=Dim(groups(KVH * 64, 64), rows // 2), block_dim=64)
        self.tick("rope")
        self.flash(l, rows)

    def flash(mut self, l: Int, rows: Int) raises:
        """l85.fa over self.fa's tiles, writing the o product's packed X (xa)."""
        var ctx = self.ctx
        var H = self.H
        var KVH = self.KVH
        var qt = self.fa[0]
        var kt = self.fa[1]
        var vt = self.fa[2]
        var xa32 = self.xa.create_sub_buffer[DType.uint32](0, len(self.xa) // 2)
        var nq = H // KVH
        var g = Dim(rows // 64, H)
        var hd = Int32(H * self.HD)
        var r = Int32(rows)
        if self.HD == 128 and nq == 3:
            ctx.enqueue_function[l85.fa[3, 128]](qt, kt, vt, xa32, r, hd, grid_dim=g, block_dim=128)
        elif self.HD == 128 and nq == 4:
            ctx.enqueue_function[l85.fa[4, 128]](qt, kt, vt, xa32, r, hd, grid_dim=g, block_dim=128)
        elif self.HD == 128:
            ctx.enqueue_function[l85.fa[8, 128]](qt, kt, vt, xa32, r, hd, grid_dim=g, block_dim=128)
        elif nq == 3:
            ctx.enqueue_function[l85.fa[3, 64]](qt, kt, vt, xa32, r, hd, grid_dim=g, block_dim=128)
        elif nq == 4:
            ctx.enqueue_function[l85.fa[4, 64]](qt, kt, vt, xa32, r, hd, grid_dim=g, block_dim=128)
        else:
            ctx.enqueue_function[l85.fa[8, 64]](qt, kt, vt, xa32, r, hd, grid_dim=g, block_dim=128)
        self.tick("attention")

    def attention_p(mut self, l: Int, n: Int, rows: Int, qp: DeviceBuffer[DType.float32],
                    attr: DeviceBuffer[DType.float32], pscores: DeviceBuffer[DType.float32]) raises:
        """The prompt's attention on the matrix units (lg's p_scores, p_softmax, p_values: gemma4's kernels with the
        scores [head][row][key] and a workgroup a score tile): S = Q K^T, each row's softmax, then P V, into attr."""
        var ctx = self.ctx
        var H = self.H
        var nq = Int32(H // self.KVH)
        var cap = Int32(self.CAP)
        var r = Int32(rows)
        if self.HD == 64:
            ctx.enqueue_function[lg.p_scores_packed[64]](qp, self.kc[l], pscores, nq, Int32(self.KVH), r, cap,
                                                         grid_dim=Dim(rows // 64, H, rows // 64), block_dim=64)
        else:
            ctx.enqueue_function[lg.p_scores_packed[128]](qp, self.kc[l], pscores, nq, Int32(self.KVH), r, cap,
                                                          grid_dim=Dim(rows // 64, H, rows // 64), block_dim=64)
        self.tick("attention: Q K^T")
        ctx.enqueue_function[lg.p_softmax](pscores, Int32(n), r, cap, grid_dim=Dim(H, rows), block_dim=64)
        self.tick("attention: softmax")
        if self.HD == 64:
            ctx.enqueue_function[lg.p_values[64]](pscores, self.vc[l], attr, nq, Int32(self.KVH), Int32(H), r, cap,
                                                  grid_dim=Dim(rows // 64, H), block_dim=64)
        else:
            ctx.enqueue_function[lg.p_values[128]](pscores, self.vc[l], attr, nq, Int32(self.KVH), Int32(H), r, cap,
                                                   grid_dim=Dim(rows // 64, H * 2), block_dim=64)
        self.tick("attention: P V")

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
        var qp = ctx.enqueue_create_buffer[DType.float32](rows * H * HD if self.gemmq else 1)  # lg.rope_pack's q
        if self.k850:
            self.fa = [ctx.enqueue_create_buffer[DType.float16](rows * H * HD),
                       ctx.enqueue_create_buffer[DType.float16](rows * self.KVH * HD),
                       ctx.enqueue_create_buffer[DType.float16](rows * self.KVH * HD)]
        if self.prof:
            ctx.synchronize()
            self.times = Dict[String, Float64]()  # this prefill's times only
            self.mark = Float64(perf_counter_ns()) / 1e6
        xr.enqueue_fill(0)  # the padding rows
        var one = self.k850 and self.CHUNKS <= 6
        if one:  # one launch (chunks past the last are never read: pass the first again)
            var idl = List[Int32](length=n, fill=0)
            for t in range(n):
                idl[t] = Int32(tokens[t])
            var ids = ctx.enqueue_create_buffer[DType.int32](n)
            ctx.enqueue_copy(ids, idl.unsafe_ptr())
            var e = List[DeviceBuffer[DType.float16]]()
            for c in range(6):
                e.append(self.halves["embed." + String(c if c < self.CHUNKS else 0)])
            ctx.enqueue_function[l85.embed6](e[0], e[1], e[2], e[3], e[4], e[5], ids, xr, Int32(self.CROWS), Int32(D),
                                             Int32(n), grid_dim=groups(n * D // 8, 256), block_dim=256)
            ctx.synchronize()  # idl goes away
        for t in range(0 if one else n):
            ctx.enqueue_function[lg.embed](self.halves["embed." + String(tokens[t] // self.CROWS)],
                                           xr.create_sub_buffer[DType.float32](t * D, D),
                                           Int32(tokens[t] % self.CROWS), Int32(D), grid_dim=groups(D, 64),
                                           block_dim=64)
        var nq = Int32(H // self.KVH)
        var cap = Int32(self.CAP)
        self.tick("embed")
        for l in range(self.L):
            if self.k850:
                self.layer_k(l, n, rows, xr, qkvr)
                continue
            if self.gemmq and self.fuse:
                self.layer_q(l, n, rows, xr, qkvr, attr, pscores, qp)
                continue
            var p = "l" + String(l) + "."
            self.norm(xr, p + "attn_norm", xnr, rows)
            self.tick("norms")
            self.pproj(self.QKV, D, p + "wqkv", xnr, qkvr, rows, "q/k/v")
            self.rope(qkvr, l, 0, n)
            self.tick("rope")
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
            self.tick("attention")
            self.pproj(D, H * HD, p + "wo", attr, yr, rows, "o")
            ctx.enqueue_function[lg.p_add](xr, yr, Int32(n * D), grid_dim=groups(n * D, 256), block_dim=256)
            self.tick("adds")
            self.norm(xr, p + "mlp_norm", xnr, rows)
            self.tick("norms")
            self.pproj(2 * self.F, D, p + "wgu", xnr, gur, rows, "gate/up")
            ctx.enqueue_function[lk.silu_mul](gur, actr, Int32(self.F), Int32(rows),
                                              grid_dim=groups(rows * self.F, 64), block_dim=64)
            self.tick("silu")
            self.pproj(D, self.F, p + "wdown", actr, yr, rows, "down")
            ctx.enqueue_function[lg.p_add](xr, yr, Int32(n * D), grid_dim=groups(n * D, 256), block_dim=256)
            self.tick("adds")
        ctx.enqueue_copy(self.x, xr.create_sub_buffer[DType.float32]((n - 1) * D, D))  # the last prompt row
        self.head()
        self.tick("head")
        if self.prof:
            self.report()
