# Gemma 4 E2B / E4B (google/gemma-4-E2B-it, -E4B-it) text decode as MAX DeviceContext launches of gemma4/kernels.
# One program for both: the sizes come from export.py's manifest. int4 or int8 projections and head (gemma4.bin, each
# matrix as export.py's storage picks), fp32 activations and KV cache. The token embedding and the per-layer
# embedding stay in the checkpoint's model.safetensors (bf16): the host reads a token's two rows from there and copies
# them to the GPU.
#
# Per token: the per-layer inputs (per_layer_model_projection of the scaled embedding, normed, plus the token's
# per-layer embedding row), then 35 (E2B) or 42 (E4B) layers of 12 launches, the soft-capped head and argmax. Layers
# past num_hidden_layers - num_kv_shared_layers compute no K and V: they attend over the cache of the last earlier
# layer of their type (sliding or full), which that layer filled earlier in the same step.
from std.collections import Dict
from std.math import sqrt
from std.memory import bitcast
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import g4k
import p_gemm_q4
import p_gemm_q8

comptime PL = 256  # the per-layer input's width
comptime PMAX = 512  # prompt rows a prefill batch holds (a multiple of p_gemm_q4's 128)
comptime PAD = 128  # positions past the context that a padded prefill batch touches


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


@fieldwise_init
struct LayerPlan(Copyable, Movable):
    var sliding: Bool
    var f: Int  # MLP width
    var src: Int  # the layer whose K/V cache this one reads (itself unless shared)
    var hd: Int  # head dim


struct Gemma4(Movable):
    var ctx: DeviceContext
    var D: Int
    var L: Int
    var H: Int
    var KVH: Int
    var V: Int
    var CAP: Int
    var WIN: Int
    var softcap: Float32
    var plan: List[LayerPlan]
    var checkpoint: String  # model.safetensors
    var embed_offset: Int
    var ple_offset: Int
    var words: Dict[String, DeviceBuffer[DType.uint32]]
    var halves: Dict[String, DeviceBuffer[DType.float16]]
    var floats: Dict[String, DeviceBuffer[DType.float32]]
    var int8: Dict[String, Bool]  # the matrices stored as int8 (the rest are int4)
    var bytes: Int
    var kc: Dict[Int, DeviceBuffer[DType.float32]]
    var vc: Dict[Int, DeviceBuffer[DType.float32]]
    var rope_s: DeviceBuffer[DType.float32]
    var rope_f: DeviceBuffer[DType.float32]
    var xin: DeviceBuffer[DType.float32]  # [CAP, D]: each position's scaled token embedding
    var plein: DeviceBuffer[DType.float32]  # [CAP, L * PL]: each position's per-layer embedding row
    var x: DeviceBuffer[DType.float32]
    var xn: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var tmp: DeviceBuffer[DType.float32]
    var act: DeviceBuffer[DType.float32]
    var proj: DeviceBuffer[DType.float32]
    var ple: DeviceBuffer[DType.float32]
    var pga: DeviceBuffer[DType.float32]
    var scores: DeviceBuffer[DType.float32]
    var logits: DeviceBuffer[DType.float32]
    var tok: DeviceBuffer[DType.int32]
    # prefill: rows of up to PMAX tokens
    var px: DeviceBuffer[DType.float32]
    var pxn: DeviceBuffer[DType.float32]
    var pqkv: DeviceBuffer[DType.float32]
    var patt: DeviceBuffer[DType.float32]
    var ptmp: DeviceBuffer[DType.float32]
    var pgu: DeviceBuffer[DType.float32]
    var pa: DeviceBuffer[DType.float32]
    var pproj: DeviceBuffer[DType.float32]
    var pple: DeviceBuffer[DType.float32]
    var ppg: DeviceBuffer[DType.float32]
    var ppa: DeviceBuffer[DType.float32]
    var pscores: DeviceBuffer[DType.float32]  # [PMAX rows, H, CAP + PAD keys]

    def __init__(out self, ctx: DeviceContext, dir: String, checkpoint: String) raises:
        """dir: export.py's manifest.txt, rope tables and convert's gemma4.bin; checkpoint: model.safetensors."""
        self.ctx = ctx
        self.checkpoint = checkpoint
        var lines = open(dir + "/manifest.txt", "r").read().splitlines()
        var head = lines[0].split(" ")
        if len(head) < 2 or head[0] != "gemma4":
            raise Error(dir + "/manifest.txt: not a gemma4 manifest")
        var cfg = Dict[String, String]()
        for i in range(2, len(head) - 1, 2):
            cfg[String(head[i])] = String(head[i + 1])
        self.D = Int(cfg["D"])
        self.L = Int(cfg["L"])
        self.H = Int(cfg["H"])
        self.KVH = Int(cfg["KVH"])
        self.V = Int(cfg["V"])
        self.CAP = Int(cfg["CAP"])
        self.WIN = Int(cfg["WINDOW"])
        self.softcap = Float32(Float64(cfg["SOFTCAP"]))
        self.plan = List[LayerPlan]()
        self.embed_offset = -1
        self.ple_offset = -1
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.int8 = Dict[String, Bool]()
        self.bytes = 0
        self.kc = Dict[Int, DeviceBuffer[DType.float32]]()
        self.vc = Dict[Int, DeviceBuffer[DType.float32]]()
        var maxhd = 0
        var maxf = 0
        for i in range(1, len(lines)):
            var f = lines[i].split(" ")
            if f[0] == "layer":
                var lp = LayerPlan(f[2] == "sliding", Int(f[3]), Int(f[4]), Int(f[5]))
                maxhd = max(maxhd, lp.hd)
                maxf = max(maxf, lp.f)
                self.plan.append(lp^)
            elif f[0] == "table":
                if f[1] == "embed":
                    self.embed_offset = Int(f[2])
                else:
                    self.ple_offset = Int(f[2])
        if len(self.plan) != self.L or self.embed_offset < 0 or self.ple_offset < 0:
            raise Error("manifest.txt: layers or tables missing")
        var D = self.D
        for l in range(self.L):
            if self.plan[l].src == l:  # zeroed: prefill's P V reads V rows past the prompt (times probability 0)
                var n = (self.CAP + PAD) * self.KVH * self.plan[l].hd
                self.kc[l] = ctx.enqueue_create_buffer[DType.float32](n)
                self.vc[l] = ctx.enqueue_create_buffer[DType.float32](n)
                self.kc[l].enqueue_fill(0)
                self.vc[l].enqueue_fill(0)
        self.rope_s = ctx.enqueue_create_buffer[DType.float32](self.CAP * 256)
        self.rope_f = ctx.enqueue_create_buffer[DType.float32](self.CAP * 512)
        # PMAX rows past the context: a prefill batch's padding rows (p_gemm_q4 reads rows in 128s)
        self.xin = ctx.enqueue_create_buffer[DType.float32]((self.CAP + PMAX) * D)
        self.plein = ctx.enqueue_create_buffer[DType.float32]((self.CAP + PMAX) * self.L * PL)
        self.x = ctx.enqueue_create_buffer[DType.float32](D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](D)
        self.qkv = ctx.enqueue_create_buffer[DType.float32]((self.H + 2 * self.KVH) * maxhd)
        self.att = ctx.enqueue_create_buffer[DType.float32](self.H * maxhd)
        self.tmp = ctx.enqueue_create_buffer[DType.float32](D)
        self.act = ctx.enqueue_create_buffer[DType.float32](maxf)
        self.proj = ctx.enqueue_create_buffer[DType.float32](self.L * PL)
        self.ple = ctx.enqueue_create_buffer[DType.float32](self.L * PL)
        self.pga = ctx.enqueue_create_buffer[DType.float32](PL)
        self.scores = ctx.enqueue_create_buffer[DType.float32](self.H * self.CAP)
        self.logits = ctx.enqueue_create_buffer[DType.float32](self.V)
        self.tok = ctx.enqueue_create_buffer[DType.int32](4)
        self.px = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.pxn = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.pqkv = ctx.enqueue_create_buffer[DType.float32](PMAX * (self.H + 2 * self.KVH) * maxhd)
        self.patt = ctx.enqueue_create_buffer[DType.float32](PMAX * self.H * maxhd)
        self.ptmp = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.pgu = ctx.enqueue_create_buffer[DType.float32](PMAX * 2 * maxf)
        self.pa = ctx.enqueue_create_buffer[DType.float32](PMAX * maxf)
        self.pproj = ctx.enqueue_create_buffer[DType.float32](PMAX * self.L * PL)
        self.pple = ctx.enqueue_create_buffer[DType.float32](PMAX * self.L * PL)
        self.ppg = ctx.enqueue_create_buffer[DType.float32](PMAX * PL)
        self.ppa = ctx.enqueue_create_buffer[DType.float32](PMAX * PL)
        self.pscores = ctx.enqueue_create_buffer[DType.float32](PMAX * self.H * (self.CAP + PAD))
        self.load(dir)

    def load(mut self, dir: String) raises:
        """gemma4.bin's tensors, as the manifest lists them ("<name> <offset> <bytes> <dtype> <shape>"), each in a
        device buffer of its type (int8 weights as uint32 words, like int4's); and the two RoPE tables."""
        var lines = open(dir + "/manifest.txt", "r").read().splitlines()
        var f = open(dir + "/gemma4.bin", "r")
        for i in range(1, len(lines)):
            var p = lines[i].split(" ")
            if len(p) != 5 or p[0] == "layer" or p[0] == "table":
                continue
            var name = String(p[0])
            var n = Int(p[2])
            _ = f.seek(Int(p[1]))
            var data = f.read_bytes(n)
            if len(data) != n:
                raise Error("gemma4.bin: short read of " + name)
            if p[3] == "u32" or p[3] == "i8":  # int4 or int8 weights, as uint32 words
                var b = self.ctx.enqueue_create_buffer[DType.uint32](n // 4)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[UInt32]())
                self.words[name] = b
                if p[3] == "i8":
                    self.int8[String(name[byte=:name.byte_length() - 2])] = True
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
        for which in range(2):
            var path = dir + ("/rope_sliding.f32" if which == 0 else "/rope_full.f32")
            var width = 256 if which == 0 else 512
            var data = open(path, "r").read_bytes()
            if len(data) != self.CAP * width * 4:
                raise Error(path + ": not " + String(self.CAP) + " rows")
            self.ctx.enqueue_copy(self.rope_s if which == 0 else self.rope_f,
                                  data.unsafe_ptr().unsafe_bitcast[Float32]())
            self.ctx.synchronize()

    def upload(self, p0: Int, ids: List[Int]) raises:
        """The rows of tokens ids (at positions p0 ..) from model.safetensors: the token embedding times sqrt(D), as
        Gemma4TextScaledWordEmbedding computes it in fp32, and the per-layer embedding row (its scale, 16, is
        ple_prep's)."""
        var n = len(ids)
        if p0 + n > self.CAP:
            raise Error("positions beyond " + String(self.CAP))
        var D = self.D
        var W = self.L * PL
        var xs = List[Float32](length=n * D, fill=0)
        var ps = List[Float32](length=n * W, fill=0)
        var scale = Float32(sqrt(Float64(D)))
        var f = open(self.checkpoint, "r")
        for i in range(n):
            if ids[i] < 0 or ids[i] >= self.V:
                raise Error("token id out of range")
            _ = f.seek(self.embed_offset + ids[i] * D * 2)
            var e = f.read_bytes(D * 2)
            _ = f.seek(self.ple_offset + ids[i] * W * 2)
            var p = f.read_bytes(W * 2)
            if len(e) != D * 2 or len(p) != W * 2:
                raise Error("model.safetensors: short read")
            var eh = e.unsafe_ptr().unsafe_bitcast[UInt16]()
            for j in range(D):
                xs[i * D + j] = bitcast[DType.float32](UInt32(eh[j]) << 16) * scale
            var ph = p.unsafe_ptr().unsafe_bitcast[UInt16]()
            for j in range(W):
                ps[i * W + j] = bitcast[DType.float32](UInt32(ph[j]) << 16)
        f.close()
        self.ctx.enqueue_copy(self.xin.create_sub_buffer[DType.float32](p0 * D, n * D), xs.unsafe_ptr())
        self.ctx.enqueue_copy(self.plein.create_sub_buffer[DType.float32](p0 * W, n * W), ps.unsafe_ptr())
        self.ctx.synchronize()

    def gemv(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], cols: Int,
             rows: Int) raises:
        """y = W x for the int4 or int8 matrix `name` (rows x cols): a workgroup a row."""
        if name in self.int8:
            self.ctx.enqueue_function[g4k.gemv[True]](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                      Int32(cols), grid_dim=rows, block_dim=64)
        else:
            self.ctx.enqueue_function[g4k.gemv[False]](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                       Int32(cols), grid_dim=rows, block_dim=64)

    def head(self, x: DeviceBuffer[DType.float32]) raises:
        """The soft-capped logits of x (a final-normed row), and their argmax into tok[0]."""
        if "head" in self.int8:
            self.ctx.enqueue_function[g4k.head[True]](self.words["head.q"], self.halves["head.s"], x, self.logits,
                                                      Int32(self.D), self.softcap, grid_dim=self.V, block_dim=64)
        else:
            self.ctx.enqueue_function[g4k.head[False]](self.words["head.q"], self.halves["head.s"], x, self.logits,
                                                       Int32(self.D), self.softcap, grid_dim=self.V, block_dim=64)
        self.ctx.enqueue_function[g4k.argmax](self.logits, Int32(self.V), self.tok, Int32(0), grid_dim=1,
                                              block_dim=256)

    def step(self, pos: Int) raises:
        """The token at `pos` (its rows uploaded) through the model: logits, and their argmax into tok[0]."""
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var KVH = self.KVH
        var W = self.L * PL
        var p = Int32(pos)
        var xin = self.xin.create_sub_buffer[DType.float32](pos * D, D)
        var raw = self.plein.create_sub_buffer[DType.float32](pos * W, W)
        self.gemv("ple_proj", xin, self.proj, D, W)
        ctx.enqueue_function[g4k.ple_prep](self.proj, raw, self.floats["ple_norm"], self.ple,
                                           Float32(1.0 / sqrt(Float64(D))), grid_dim=self.L, block_dim=64)
        ctx.enqueue_function[g4k.start](xin, self.x, self.floats["l0.in_norm"], self.xn, Int32(D), grid_dim=1,
                                        block_dim=64)
        for l in range(self.L):
            var n = "l" + String(l) + "."
            var hd = self.plan[l].hd
            var f = self.plan[l].f
            var src = self.plan[l].src
            var own = src == l
            var heads = (H + 2 * KVH) if own else H
            var qn = self.floats[n + "q_norm"]
            var kn = self.floats[n + "k_norm"] if own else qn
            self.gemv(n + "qkv", self.xn, self.qkv, D, heads * hd)
            var table = self.rope_s if self.plan[l].sliding else self.rope_f
            var kc = self.kc[src]
            var vc = self.vc[src]
            ctx.enqueue_function[g4k.qk_norm_rope](self.qkv, qn, kn, table, kc, vc, p, Int32(H), Int32(KVH), Int32(hd),
                                                   grid_dim=heads, block_dim=64)
            var first = max(0, pos - self.WIN + 1) if self.plan[l].sliding else 0
            var span = KVH * (pos - first + 1)
            if H // KVH == 8:
                ctx.enqueue_function[g4k.attn_scores[8]](self.qkv, kc, self.scores, p, Int32(first), Int32(KVH),
                                                         Int32(hd), Int32(self.CAP), grid_dim=groups(span, 64),
                                                         block_dim=64)
            elif H // KVH == 4:
                ctx.enqueue_function[g4k.attn_scores[4]](self.qkv, kc, self.scores, p, Int32(first), Int32(KVH),
                                                         Int32(hd), Int32(self.CAP), grid_dim=groups(span, 64),
                                                         block_dim=64)
            else:
                raise Error("query heads per KV head: 4 or 8")
            ctx.enqueue_function[g4k.attn_values](self.scores, vc, self.att, p, Int32(first), Int32(H // KVH),
                                                  Int32(KVH), Int32(hd), Int32(self.CAP), grid_dim=H * hd // 64,
                                                  block_dim=64)
            self.gemv(n + "o", self.att, self.tmp, H * hd, D)
            var sc = self.floats[n + "scalar"]
            ctx.enqueue_function[g4k.norm_add](self.x, self.tmp, self.floats[n + "post_attn_norm"], sc,
                                               self.floats[n + "pre_ff_norm"], self.xn, Int32(D), Int32(2),
                                               grid_dim=1, block_dim=64)
            if n + "gu" in self.int8:
                ctx.enqueue_function[g4k.gate_up_gelu[True]](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.xn,
                                                             self.act, Int32(D), Int32(f), grid_dim=f, block_dim=64)
            else:
                ctx.enqueue_function[g4k.gate_up_gelu[False]](self.words[n + "gu.q"], self.halves[n + "gu.s"],
                                                              self.xn, self.act, Int32(D), Int32(f), grid_dim=f,
                                                              block_dim=64)
            self.gemv(n + "down", self.act, self.tmp, f, D)
            ctx.enqueue_function[g4k.norm_add](self.x, self.tmp, self.floats[n + "post_ff_norm"], sc, sc, self.xn,
                                               Int32(D), Int32(0), grid_dim=1, block_dim=64)
            if n + "pg" in self.int8:
                ctx.enqueue_function[g4k.ple_gate[True]](self.words[n + "pg.q"], self.halves[n + "pg.s"], self.x,
                                                         self.ple, Int32(l * PL), self.pga, Int32(D), grid_dim=PL,
                                                         block_dim=64)
            else:
                ctx.enqueue_function[g4k.ple_gate[False]](self.words[n + "pg.q"], self.halves[n + "pg.s"], self.x,
                                                          self.ple, Int32(l * PL), self.pga, Int32(D), grid_dim=PL,
                                                          block_dim=64)
            self.gemv(n + "pp", self.pga, self.tmp, PL, D)
            var wn = self.floats["l" + String(l + 1) + ".in_norm"] if l + 1 < self.L else self.floats["final_norm"]
            ctx.enqueue_function[g4k.norm_add](self.x, self.tmp, self.floats[n + "ple_norm"], sc, wn, self.xn,
                                               Int32(D), Int32(3), grid_dim=1, block_dim=64)
        self.head(self.xn)

    def gemm(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], n: Int, k: Int,
             rows: Int) raises:
        """y[rows, n] = x[rows, k] W^T for the int4 or int8 matrix `name` (n x k), on cooperative matrices."""
        if name in self.int8:
            self.ctx.enqueue_function[p_gemm_q8.p_gemm_q8](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                           Int64(n), Int64(k), grid_dim=Dim(n // 128, rows // 128),
                                                           block_dim=256)
        else:
            self.ctx.enqueue_function[p_gemm_q4.p_gemm_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                           Int64(n), Int64(k), grid_dim=Dim(n // 128, rows // 128),
                                                           block_dim=256)

    def prefill(self, p0: Int, count: Int) raises:
        """Positions p0 .. p0 + count - 1 (rows uploaded) in batches of up to PMAX rows: each projection one matrix
        product on the matrix units, attention a workgroup per head and row over the KV cache (which the batch fills
        first). The last row's logits and argmax as step() leaves them."""
        var c0 = 0
        while c0 < count:
            var c = min(PMAX, count - c0)
            self.prefill_batch(p0 + c0, c)
            c0 += c

    def prefill_batch(self, p0: Int, count: Int) raises:
        var ctx = self.ctx
        var D = self.D
        var H = self.H
        var KVH = self.KVH
        var W = self.L * PL
        var R = groups(count, 128) * 128
        var c = Int32(count)
        var xin = self.xin.create_sub_buffer[DType.float32](p0 * D, R * D)
        var raw = self.plein.create_sub_buffer[DType.float32](p0 * W, R * W)
        self.gemm("ple_proj", xin, self.pproj, W, D, R)
        ctx.enqueue_function[g4k.p_ple_prep](self.pproj, raw, self.floats["ple_norm"], self.pple,
                                             Float32(1.0 / sqrt(Float64(D))), Int32(self.L),
                                             grid_dim=Dim(self.L, count), block_dim=64)
        ctx.enqueue_function[g4k.p_start](xin, self.px, self.floats["l0.in_norm"], self.pxn, Int32(D),
                                          grid_dim=count, block_dim=64)
        for l in range(self.L):
            var n = "l" + String(l) + "."
            var hd = self.plan[l].hd
            var f = self.plan[l].f
            var src = self.plan[l].src
            var own = src == l
            var heads = (H + 2 * KVH) if own else H
            var stride = heads * hd
            var qn = self.floats[n + "q_norm"]
            var kn = self.floats[n + "k_norm"] if own else qn
            var kc = self.kc[src]
            var vc = self.vc[src]
            self.gemm(n + "qkv", self.pxn, self.pqkv, stride, D, R)
            var table = self.rope_s if self.plan[l].sliding else self.rope_f
            ctx.enqueue_function[g4k.p_qk_norm_rope](self.pqkv, qn, kn, table, kc, vc, Int32(p0), Int32(H),
                                                     Int32(KVH), Int32(hd), Int32(stride),
                                                     grid_dim=Dim(heads, count), block_dim=64)
            var win = Int32(self.WIN if self.plan[l].sliding else 0)
            var kcap = Int32(self.CAP + PAD)
            var nq = Int32(H // KVH)
            if hd == 256:
                ctx.enqueue_function[g4k.p_scores_mma[256]](self.pqkv, kc, self.pscores, Int32(p0), win, nq,
                                                            Int32(KVH), Int32(stride), Int32(H), kcap,
                                                            grid_dim=Dim(R // 64, H), block_dim=64)
            elif hd == 512:
                ctx.enqueue_function[g4k.p_scores_mma[512]](self.pqkv, kc, self.pscores, Int32(p0), win, nq,
                                                            Int32(KVH), Int32(stride), Int32(H), kcap,
                                                            grid_dim=Dim(R // 64, H), block_dim=64)
            else:
                raise Error("head dim: 256 or 512")
            ctx.enqueue_function[g4k.p_softmax](self.pscores, Int32(p0), c, win, Int32(H), kcap,
                                                grid_dim=Dim(H, R), block_dim=64)
            if hd == 256:
                ctx.enqueue_function[g4k.p_values_mma[256]](self.pscores, vc, self.patt, Int32(p0), win, nq,
                                                            Int32(KVH), Int32(H), kcap,
                                                            grid_dim=Dim(R // 64, H * 4), block_dim=64)
            else:
                ctx.enqueue_function[g4k.p_values_mma[512]](self.pscores, vc, self.patt, Int32(p0), win, nq,
                                                            Int32(KVH), Int32(H), kcap,
                                                            grid_dim=Dim(R // 64, H * 8), block_dim=64)
            self.gemm(n + "o", self.patt, self.ptmp, D, H * hd, R)
            var sc = self.floats[n + "scalar"]
            ctx.enqueue_function[g4k.p_norm_add](self.px, self.ptmp, self.floats[n + "post_attn_norm"], sc,
                                                 self.floats[n + "pre_ff_norm"], self.pxn, Int32(D), Int32(2),
                                                 grid_dim=count, block_dim=64)
            self.gemm(n + "gu", self.pxn, self.pgu, 2 * f, D, R)
            ctx.enqueue_function[g4k.p_gelu_mul](self.pgu, self.pa, Int32(f), c, grid_dim=groups(count * f, 64),
                                                 block_dim=64)
            self.gemm(n + "down", self.pa, self.ptmp, D, f, R)
            ctx.enqueue_function[g4k.p_norm_add](self.px, self.ptmp, self.floats[n + "post_ff_norm"], sc, sc, self.pxn,
                                                 Int32(D), Int32(0), grid_dim=count, block_dim=64)
            self.gemm(n + "pg", self.px, self.ppg, PL, D, R)
            ctx.enqueue_function[g4k.p_ple_gate_mul](self.ppg, self.pple, Int32(l * PL), self.ppa, c,
                                                     Int32(self.L), grid_dim=groups(count * PL, 64), block_dim=64)
            self.gemm(n + "pp", self.ppa, self.ptmp, D, PL, R)
            var wn = self.floats["l" + String(l + 1) + ".in_norm"] if l + 1 < self.L else self.floats["final_norm"]
            ctx.enqueue_function[g4k.p_norm_add](self.px, self.ptmp, self.floats[n + "ple_norm"], sc, wn, self.pxn,
                                                 Int32(D), Int32(3), grid_dim=count, block_dim=64)
        self.head(self.pxn.create_sub_buffer[DType.float32]((count - 1) * D, D))
