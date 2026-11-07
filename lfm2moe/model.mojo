# LFM2-MoE (LFM2.5-8B-A1B on the phone, LFM2.5-24B-A2B on the laptop) as MAX DeviceContext launches: lfm2/kernels'
# short conv, attention, norms, int4 products and Q6_K head (lk.mojo), gemma4's matrix-unit prefill attention (g4k),
# and the router and routed experts (lfm2moe/kernels/mk.mojo). The first layers are dense SwiGLU MLPs, the rest a
# mixture of E experts (top K, sigmoid router with an expert bias, normalized weights); sizes, layer types and tensors
# from export.py's manifest; weights from lfm2/convert.c's file (the GGUF's own int4 and Q6_K numbers).
# Activations, the K/V cache and the conv state (a ring of 3 rows) are fp32.
#
# Token ids live on the GPU: the embedding reads them there and the argmax writes the next one, and the router's
# choices stay on the GPU too, so a decode step never waits on the host. step() runs one position; prefill() a batch.
#
# remote (LFM2MOE_REMOTE=1): the device is behind MAX's remote driver plugin (the QDC laptop): the weight file is on
# the executor's side and its own executor reads each tensor into its buffer (M_driver_remote_file).
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.os import getenv
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import g4k
import lk
import mk

comptime PMAX = 512  # prompt rows a prefill batch holds (a multiple of 128)
comptime PAD = 128  # cache rows past the context: prefill's matrix-unit attention reads up to a block's 64-aligned end
comptime SCORE_MAX = 4096  # prompts up to this many positions use the matrix-unit prefill attention (g4k)


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


def plugin_path() raises -> String:
    """The driver plugin MAX loaded: MODULAR_DRIVER_PLUGINS=vulkan@<path>."""
    var spec = getenv("MODULAR_DRIVER_PLUGINS")
    var at = spec.find("@")
    if at < 0:
        raise Error("MODULAR_DRIVER_PLUGINS=vulkan@<path of libM_driver_vulkan_remote> is needed")
    return String(spec[byte=at + 1:])


struct LFM2Moe(Movable):
    var ctx: DeviceContext
    var D: Int
    var L: Int
    var H: Int
    var KVH: Int
    var F: Int  # the dense layers' SwiGLU width
    var FE: Int  # an expert's
    var E: Int
    var V: Int
    var CAP: Int
    var MAXG: Int  # grouped prefill rows: PMAX K pairs plus each expert's padding to TM
    var attn: List[Bool]
    var moe: List[Bool]
    var words: Dict[String, DeviceBuffer[DType.uint32]]
    var halves: Dict[String, DeviceBuffer[DType.float16]]
    var floats: Dict[String, DeviceBuffer[DType.float32]]
    var bytes: Int
    var kc: Dict[Int, DeviceBuffer[DType.float32]]
    var vc: Dict[Int, DeviceBuffer[DType.float32]]
    var cs: Dict[Int, DeviceBuffer[DType.float32]]
    var rope: DeviceBuffer[DType.float32]
    var ids: DeviceBuffer[DType.int32]  # [CAP + PMAX]: the token at each position
    var x: DeviceBuffer[DType.float32]  # rows of PMAX: the residual stream
    var xn: DeviceBuffer[DType.float32]
    var mix: DeviceBuffer[DType.float32]  # the conv's B | C | x rows, or the attention's q | k | v rows
    var att: DeviceBuffer[DType.float32]
    var tmp: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]  # dense layers
    var act: DeviceBuffer[DType.float32]
    var rlog: DeviceBuffer[DType.float32]  # router logits [PMAX, E]
    var rids: DeviceBuffer[DType.int32]  # chosen experts [PMAX, K]
    var rwts: DeviceBuffer[DType.float32]  # their weights [PMAX, K]
    var ea: DeviceBuffer[DType.float32]  # decode: the K experts' SwiGLU outputs [K, FE]
    var slot: DeviceBuffer[DType.int32]  # prefill: each (token, choice)'s grouped row [PMAX, K]
    var src: DeviceBuffer[DType.int32]  # each grouped row's token (-1: padding) [MAXG]
    var tiles: DeviceBuffer[DType.int32]  # work tiles (expert, first grouped row) [MAXG / TM, 2]
    var ntiles: DeviceBuffer[DType.int32]
    var xg: DeviceBuffer[DType.float32]  # grouped rows [MAXG, D]
    var ggu: DeviceBuffer[DType.float32]  # [MAXG, 2 FE]
    var gact: DeviceBuffer[DType.float32]  # [MAXG, FE]
    var gdown: DeviceBuffer[DType.float32]  # [MAXG, D]
    var logits: DeviceBuffer[DType.float32]
    var attn_mma: Bool
    var rows_r: Int  # decode: weight rows a workgroup (LFM2MOE_ROWS: 1 = lk's kernels, 4, 8)
    var head_r: Int  # the head's rows a workgroup (LFM2MOE_HEAD_ROWS: 1 or 4)
    var down_f: Bool  # experts' down products with the lanes over all K experts' blocks (LFM2MOE_DOWN=flat)
    var wave: Bool  # scalar grouped products with one-subgroup workgroups (LFM2MOE_WAVE=1, tm 16)
    var tm: Int  # prefill: rows a grouped work tile (64 on the matrix units; LFM2MOE_TM=64, 32 or 16 scalar)
    var mma: Bool  # prefill products on the cooperative matrices (LFM2MOE_SCALAR=1: none, as the X1-85 has)
    var pscores: DeviceBuffer[DType.float32]
    var score_cap: Int
    var dump: String  # prefill: append each layer's residual stream rows (fp32) to this file (stage checks)
    var skip: String  # timing by ablation (LFM2MOE_SKIP): decode leaves out these kinds of launch (",conv,attn,router,
    # experts,dense,norms,head,"): the output is wrong, the replayed time is the rest's
    var prof: Bool  # wait after each launch and add its time to times[kind] (LFM2MOE_PROFILE)
    var times: Dict[String, Float64]
    var mark: Float64

    def __init__(out self, ctx: DeviceContext, dir: String, bin: String) raises:
        """dir: export.py's q4/manifest.txt (rope.f32 in its parent); bin: convert's weight file (on the executor's
        side when remote)."""
        self.ctx = ctx
        var lines = open(dir + "/manifest.txt", "r").read().splitlines()
        var head = lines[0].split(" ")
        if len(head) < 2 or head[0] != "lfm2moe":
            raise Error(dir + "/manifest.txt: not an lfm2moe manifest")
        var cfg = Dict[String, String]()
        for i in range(2, len(head) - 1, 2):
            cfg[String(head[i])] = String(head[i + 1])
        self.D = Int(cfg["D"])
        self.L = Int(cfg["L"])
        self.H = Int(cfg["H"])
        self.KVH = Int(cfg["KVH"])
        self.F = Int(cfg["F"])
        self.FE = Int(cfg["FE"])
        self.E = Int(cfg["E"])
        self.V = Int(cfg["V"])
        self.CAP = Int(cfg["CAP"])
        if Int(cfg["HD"]) != lk.HD or Int(cfg["K"]) != mk.K or self.E > 64:
            raise Error("head dim 64, top 4, at most 64 experts")
        self.MAXG = groups(PMAX * mk.K + self.E * (mk.TM - 1), mk.TM) * mk.TM
        self.attn = List[Bool]()
        self.moe = List[Bool]()
        for i in range(1, len(lines)):
            var f = lines[i].split(" ")
            if f[0] == "layer":
                self.attn.append(f[2] == "attn")
                self.moe.append(f[3] == "moe")
        if len(self.attn) != self.L:
            raise Error("manifest.txt: " + String(len(self.attn)) + " layers")
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.bytes = 0
        self.kc = Dict[Int, DeviceBuffer[DType.float32]]()
        self.vc = Dict[Int, DeviceBuffer[DType.float32]]()
        self.cs = Dict[Int, DeviceBuffer[DType.float32]]()
        var D = self.D
        var row = self.KVH * lk.HD
        for l in range(self.L):
            if self.attn[l]:
                self.kc[l] = ctx.enqueue_create_buffer[DType.float32]((self.CAP + PAD) * row)
                self.vc[l] = ctx.enqueue_create_buffer[DType.float32]((self.CAP + PAD) * row)
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
        self.rlog = ctx.enqueue_create_buffer[DType.float32](PMAX * self.E)
        self.rids = ctx.enqueue_create_buffer[DType.int32](PMAX * mk.K)
        self.rwts = ctx.enqueue_create_buffer[DType.float32](PMAX * mk.K)
        self.ea = ctx.enqueue_create_buffer[DType.float32](mk.K * self.FE)
        self.slot = ctx.enqueue_create_buffer[DType.int32](PMAX * mk.K)
        self.src = ctx.enqueue_create_buffer[DType.int32](self.MAXG)
        self.tiles = ctx.enqueue_create_buffer[DType.int32](2 * (self.MAXG // mk.TM))
        self.ntiles = ctx.enqueue_create_buffer[DType.int32](1)
        self.xg = ctx.enqueue_create_buffer[DType.float32](self.MAXG * D)
        self.ggu = ctx.enqueue_create_buffer[DType.float32](self.MAXG * 2 * self.FE)
        self.gact = ctx.enqueue_create_buffer[DType.float32](self.MAXG * self.FE)
        self.gdown = ctx.enqueue_create_buffer[DType.float32](self.MAXG * D)
        self.logits = ctx.enqueue_create_buffer[DType.float32](self.V)
        self.attn_mma = True
        self.mma = True
        self.rows_r = 1
        self.tm = mk.TM
        self.wave = False
        self.head_r = 1
        self.down_f = False
        self.pscores = ctx.enqueue_create_buffer[DType.float32](1)
        self.score_cap = 0
        self.dump = ""
        self.skip = ""
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
        device buffer of its type; and the RoPE table. Remote: the executor reads each from its own copy of bin."""
        var remote = getenv("LFM2MOE_REMOTE") != ""
        var lines = open(dir + "/manifest.txt", "r").read().splitlines()
        var lib = OwnedDLHandle(plugin_path()) if remote else OwnedDLHandle()
        var f = FileHandle() if remote else open(bin, "r")
        var path = bin  # a mutable copy: its C string goes to the plugin
        for i in range(1, len(lines)):
            var p = lines[i].split(" ")
            if len(p) != 5:
                continue
            var name = String(p[0])
            var off = Int(p[1])
            var n = Int(p[2])
            var addr: Int
            if p[3] == "u32":
                var b = self.ctx.enqueue_create_buffer[DType.uint32](n // 4)
                addr = Int(b.unsafe_ptr())
                self.words[name] = b
            elif p[3] == "f16":
                var b = self.ctx.enqueue_create_buffer[DType.float16](n // 2)
                addr = Int(b.unsafe_ptr())
                self.halves[name] = b
            else:
                var b = self.ctx.enqueue_create_buffer[DType.float32](n // 4)
                addr = Int(b.unsafe_ptr())
                self.floats[name] = b
            if remote:
                if lib.call["M_driver_remote_file", Int32](UInt64(addr), UInt64(n), path.as_c_string_span().unsafe_ptr(),
                                                          UInt64(off)) != 0:
                    raise Error("M_driver_remote_file failed for " + name)
            else:
                _ = f.seek(off)
                var data = f.read_bytes(n)
                if len(data) != n:
                    raise Error(bin + ": short read of " + name)
                if p[3] == "u32":
                    self.ctx.enqueue_copy(self.words[name], data.unsafe_ptr().unsafe_bitcast[UInt32]())
                elif p[3] == "f16":
                    self.ctx.enqueue_copy(self.halves[name], data.unsafe_ptr().unsafe_bitcast[Float16]())
                else:
                    self.ctx.enqueue_copy(self.floats[name], data.unsafe_ptr().unsafe_bitcast[Float32]())
                self.ctx.synchronize()  # `data` goes away
            self.bytes += n
        if not remote:
            f.close()
        self.ctx.synchronize()  # a remote read's error arrives here
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

    # ---- pieces ------------------------------------------------------------------------------------------------------

    def gemv(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], cols: Int,
             rows: Int) raises:
        var wq = self.words[name + ".q"]
        var ws = self.halves[name + ".s"]
        if self.rows_r == 8:
            self.ctx.enqueue_function[mk.gemv_q4r[8]](wq, ws, x, y, Int32(cols), grid_dim=rows // 8, block_dim=64)
        elif self.rows_r == 4:
            self.ctx.enqueue_function[mk.gemv_q4r[4]](wq, ws, x, y, Int32(cols), grid_dim=rows // 4, block_dim=64)
        else:
            self.ctx.enqueue_function[lk.gemv_q4[True]](wq, ws, x, y, Int32(cols), grid_dim=rows, block_dim=64)

    def gemm(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], n: Int, k: Int,
             rows: Int) raises:
        """y[rows, n] = x[rows, k] W^T (rows: a multiple of 128)."""
        if not self.mma and self.wave:
            self.ctx.enqueue_function[mk.gemm_q4w](self.words[name + ".q"], self.halves[name + ".s"], x, y, Int32(n),
                                                   Int32(k), grid_dim=Dim(n // 64, rows // 16), block_dim=64)
            return
        if not self.mma:
            self.ctx.enqueue_function[mk.gemm_q4v](self.words[name + ".q"], self.halves[name + ".s"], x, y, Int32(n),
                                                   Int32(k), grid_dim=Dim(n // 64, rows // 64), block_dim=256)
            return
        self.ctx.enqueue_function[lk.gemm_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y, Int64(n),
                                              Int64(k), grid_dim=Dim(n // 128, rows // 128), block_dim=256)

    def embed(self, slot0: Int, count: Int) raises:
        """x rows = the embedding rows of ids[slot0 ..], and xn = layer 0's operator norm of them."""
        self.ctx.enqueue_function[lk.embed_q6](self.ids, Int32(slot0), self.words["embed.q"], self.halves["embed.d"],
                                               self.x, Int32(self.D), grid_dim=count, block_dim=64)
        self.ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats["l0.in_norm"], self.xn, Int32(self.D),
                                               Int32(0), grid_dim=count, block_dim=64)

    def head(self, row: Int, slot: Int) raises:
        """The logits of xn's row `row` (final-normed), and their argmax into ids[slot]."""
        if row == 0 and self.head_r == 4:  # no sub-buffer: a decode step stays replayable (OP_RECORD keeps handles)
            self.ctx.enqueue_function[mk.head_q6r[4]](self.words["embed.q"], self.halves["embed.d"], self.xn,
                                                      self.logits, Int32(self.D), grid_dim=self.V // 4, block_dim=64)
        elif row == 0:
            self.ctx.enqueue_function[lk.head_q6](self.words["embed.q"], self.halves["embed.d"], self.xn, self.logits,
                                                  Int32(self.D), grid_dim=self.V, block_dim=64)
        else:
            var x = self.xn.create_sub_buffer[DType.float32](row * self.D, self.D)
            self.ctx.enqueue_function[lk.head_q6](self.words["embed.q"], self.halves["embed.d"], x, self.logits,
                                                  Int32(self.D), grid_dim=self.V, block_dim=64)
        self.ctx.enqueue_function[lk.argmax](self.logits, Int32(self.V), self.ids, Int32(slot), grid_dim=1,
                                             block_dim=256)

    def gate_up(self, name: String, f: Int, experts: Bool) raises:
        """Decode: silu(gate . xn) * (up . xn) for the K chosen experts' fused matrix (experts: into ea, a row of f
        each) or the dense layer's (into act)."""
        var wq = self.words[name + ".q"]
        var ws = self.halves[name + ".s"]
        var out = self.ea if experts else self.act
        var k = mk.K if experts else 1
        var e = Int32(1 if experts else 0)
        if self.rows_r == 8:
            self.ctx.enqueue_function[mk.gate_up_q4r[8]](wq, ws, self.xn, out, Int32(self.D), Int32(f), self.rids, e,
                                                         grid_dim=Dim(f // 8, k), block_dim=64)
        elif self.rows_r == 4:
            self.ctx.enqueue_function[mk.gate_up_q4r[4]](wq, ws, self.xn, out, Int32(self.D), Int32(f), self.rids, e,
                                                         grid_dim=Dim(f // 4, k), block_dim=64)
        elif experts:
            self.ctx.enqueue_function[mk.moe_gate_up](wq, ws, self.rids, self.xn, out, Int32(self.D), Int32(f),
                                                      grid_dim=Dim(f, k), block_dim=64)
        else:
            self.ctx.enqueue_function[lk.gate_up_q4[True]](wq, ws, self.xn, out, Int32(self.D), Int32(f), grid_dim=f,
                                                           block_dim=64)

    def route(self, n: String, count: Int) raises:
        """The router's choices for xn's first `count` rows: rids, rwts."""
        self.ctx.enqueue_function[mk.router](self.floats[n + "router"], self.xn, self.rlog, Int32(self.D),
                                             Int32(self.E), grid_dim=Dim(self.E, count), block_dim=64)
        self.ctx.enqueue_function[mk.route](self.rlog, self.floats[n + "ebias"], self.rids, self.rwts, Int32(self.E),
                                            grid_dim=count, block_dim=64)

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
        """The token ids[pos] through the model: logits, and their argmax into ids[pos + 1] (head)."""
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
            if self.attn[l] and self.skip.find(",attn,") >= 0:
                pass
            elif not self.attn[l] and self.skip.find(",conv,") >= 0:
                pass
            elif self.attn[l]:
                self.gemv(n + "qkv", self.xn, self.mix, D, (H + 2 * KVH) * lk.HD)
                ctx.enqueue_function[lk.qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      self.rope, self.kc[l], self.vc[l], Int32(pos), Int32(H),
                                                      Int32(KVH), Float32(0.125), grid_dim=Dim(H + 2 * KVH, 1),
                                                      block_dim=64)
                ctx.enqueue_function[lk.attention](self.mix, self.kc[l], self.vc[l], self.att, Int32(pos), Int32(H),
                                                   Int32(KVH), grid_dim=Dim(H, 1), block_dim=64)
                self.gemv(n + "o", self.att, self.tmp, H * lk.HD, D)
                self.tick("attention layers")
            else:
                self.gemv(n + "in", self.xn, self.mix, D, 3 * D)
                ctx.enqueue_function[lk.short_conv](self.mix, self.floats[n + "conv"], self.cs[l], self.att,
                                                    Int32(pos), Int32(1), Int32(D), Int32(1), self.att,
                                                    grid_dim=groups(D, 64), block_dim=64)
                self.gemv(n + "out", self.att, self.tmp, D, D)
                self.tick("conv layers")
            if self.skip.find(",norms,") < 0:
                ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[n + "ffn_norm"], self.xn, Int32(D),
                                                  Int32(1), grid_dim=1, block_dim=64)
            if self.moe[l] and self.skip.find(",experts,") >= 0:
                if self.skip.find(",router,") < 0:
                    self.route(n, 1)
            elif not self.moe[l] and self.skip.find(",dense,") >= 0:
                pass
            elif self.moe[l]:
                if self.skip.find(",router,") < 0:
                    self.route(n, 1)
                self.tick("router")
                self.gate_up(n + "egu", self.FE, True)
                var dq = self.words[n + "edown.q"]
                var ds = self.halves[n + "edown.s"]
                if self.down_f and self.rows_r == 4:
                    ctx.enqueue_function[mk.moe_down_f[4]](dq, ds, self.rids, self.rwts, self.ea, self.tmp,
                                                           Int32(self.FE), Int32(D), grid_dim=D // 4, block_dim=64)
                elif self.down_f:
                    ctx.enqueue_function[mk.moe_down_f[2]](dq, ds, self.rids, self.rwts, self.ea, self.tmp,
                                                           Int32(self.FE), Int32(D), grid_dim=D // 2, block_dim=64)
                elif self.rows_r == 8:
                    ctx.enqueue_function[mk.moe_down_r[8]](dq, ds, self.rids, self.rwts, self.ea, self.tmp,
                                                           Int32(self.FE), Int32(D), grid_dim=D // 8, block_dim=64)
                elif self.rows_r == 4:
                    ctx.enqueue_function[mk.moe_down_r[4]](dq, ds, self.rids, self.rwts, self.ea, self.tmp,
                                                           Int32(self.FE), Int32(D), grid_dim=D // 4, block_dim=64)
                else:
                    ctx.enqueue_function[mk.moe_down](dq, ds, self.rids, self.rwts, self.ea, self.tmp, Int32(self.FE),
                                                      Int32(D), grid_dim=D, block_dim=64)
                self.tick("experts")
            else:
                self.gate_up(n + "gu", self.F, False)
                self.gemv(n + "down", self.act, self.tmp, self.F, D)
                self.tick("dense MLPs")
            if self.skip.find(",norms,") < 0:
                ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn, Int32(D),
                                                  Int32(1), grid_dim=1, block_dim=64)
            self.tick("norms")
        if head and self.skip.find(",head,") < 0:
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

    def grouped(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], n: Int,
                k: Int) raises:
        """Every work tile's rows of x times its expert's matrix `name` (n rows of k a expert) into y."""
        var nt = self.MAXG // self.tm
        var wq = self.words[name + ".q"]
        var ws = self.halves[name + ".s"]
        if self.mma:
            self.ctx.enqueue_function[mk.p_gemm_q4g](wq, ws, x, y, Int64(n), Int64(k), self.tiles, self.ntiles,
                                                     grid_dim=Dim(n // mk.BN, nt), block_dim=mk.GT)
        elif self.tm == 16 and self.wave:
            self.ctx.enqueue_function[mk.p_gemm_q4gw](wq, ws, x, y, Int32(n), Int32(k), self.tiles, self.ntiles,
                                                      grid_dim=Dim(n // 64, nt), block_dim=64)
        elif self.tm == 16:
            self.ctx.enqueue_function[mk.p_gemm_q4gv[16]](wq, ws, x, y, Int32(n), Int32(k), self.tiles, self.ntiles,
                                                          grid_dim=Dim(n // 64, nt), block_dim=256)
        elif self.tm == 32:
            self.ctx.enqueue_function[mk.p_gemm_q4gv[32]](wq, ws, x, y, Int32(n), Int32(k), self.tiles, self.ntiles,
                                                          grid_dim=Dim(n // 64, nt), block_dim=256)
        else:
            self.ctx.enqueue_function[mk.p_gemm_q4gv[64]](wq, ws, x, y, Int32(n), Int32(k), self.tiles, self.ntiles,
                                                          grid_dim=Dim(n // 64, nt), block_dim=256)

    def experts(mut self, n: String, count: Int) raises:
        """The routed experts of xn's first `count` rows, weighted and summed, into tmp."""
        var ctx = self.ctx
        var D = self.D
        var FE = self.FE
        self.route(n, count)
        if self.skip.find(",group,") >= 0:
            return
        self.src.enqueue_fill(-1)
        ctx.enqueue_function[mk.p_group](self.rids, self.slot, self.src, self.tiles, self.ntiles, Int32(count),
                                         Int32(self.E), Int32(self.tm), grid_dim=1, block_dim=64)
        ctx.enqueue_function[mk.p_gather](self.xn, self.src, self.xg, self.ntiles, Int32(D), Int32(self.tm),
                                          grid_dim=self.MAXG, block_dim=64)
        self.tick("p: router + grouping")
        if self.skip.find(",eprod,") >= 0:
            return
        self.grouped(n + "egu", self.xg, self.ggu, 2 * FE, D)
        ctx.enqueue_function[mk.p_silu_mul](self.ggu, self.gact, self.ntiles, Int32(FE), Int32(self.tm),
                                            grid_dim=groups(self.MAXG * FE, 64), block_dim=64)
        self.tick("p: experts gate/up")
        self.grouped(n + "edown", self.gact, self.gdown, D, FE)
        self.tick("p: experts down")
        ctx.enqueue_function[mk.p_combine](self.gdown, self.slot, self.rwts, self.tmp, Int32(count), Int32(D),
                                           grid_dim=groups(count * D, 64), block_dim=64)
        self.tick("p: combine")

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
            if (self.attn[l] and self.skip.find(",attn,") >= 0) or (not self.attn[l] and self.skip.find(",conv,") >= 0):
                pass
            elif self.attn[l]:
                var w = (H + 2 * KVH) * lk.HD
                self.gemm(n + "qkv", self.xn, self.mix, w, D, R)
                ctx.enqueue_function[lk.qk_norm_rope](self.mix, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      self.rope, self.kc[l], self.vc[l], Int32(p0), Int32(H),
                                                      Int32(KVH), Float32(0.125), grid_dim=Dim(H + 2 * KVH, count),
                                                      block_dim=64)
                if p0 + R <= SCORE_MAX + PAD and self.attn_mma and self.mma:
                    # the scores' row length: the keys this batch reads (64-aligned past the context), rounded up
                    # to 1024; grown when a longer prompt needs it (the 4096-position size is 277 MB: the phone has
                    # about 5 GB free for the 8B's 4.8 GB of weights and everything else)
                    var need = groups(p0 + R + PAD, 1024) * 1024
                    if self.score_cap < need:
                        self.pscores = ctx.enqueue_create_buffer[DType.float32](PMAX * H * need)
                        self.score_cap = need
                    var kcap = self.score_cap
                    var nq = Int32(H // KVH)
                    ctx.enqueue_function[g4k.p_scores_mma[64]](self.mix, self.kc[l], self.pscores, Int32(p0), Int32(0),
                                                               nq, Int32(KVH), Int32(w), Int32(H), Int32(kcap),
                                                               grid_dim=Dim(R // 64, H), block_dim=64)
                    ctx.enqueue_function[g4k.p_softmax](self.pscores, Int32(p0), c, Int32(0), Int32(H), Int32(kcap),
                                                        grid_dim=Dim(H, R), block_dim=64)
                    ctx.enqueue_function[g4k.p_values_mma[64]](self.pscores, self.vc[l], self.att, Int32(p0), Int32(0),
                                                               nq, Int32(KVH), Int32(H), Int32(kcap),
                                                               grid_dim=Dim(R // 64, H), block_dim=64)
                else:
                    ctx.enqueue_function[lk.attention](self.mix, self.kc[l], self.vc[l], self.att, Int32(p0), Int32(H),
                                                       Int32(KVH), grid_dim=Dim(H, count), block_dim=64)
                self.gemm(n + "o", self.att, self.tmp, D, H * lk.HD, R)
                self.tick("p: attention layers")
            else:
                self.gemm(n + "in", self.xn, self.mix, 3 * D, D, R)
                ctx.enqueue_function[lk.short_conv](self.mix, self.floats[n + "conv"], self.cs[l], self.att,
                                                    Int32(p0), c, Int32(D), Int32(0), self.att,
                                                    grid_dim=groups(count * D, 64), block_dim=64)
                ctx.enqueue_function[lk.conv_state](self.mix, self.cs[l], Int32(p0), c, Int32(D),
                                                    grid_dim=groups(2 * D, 64), block_dim=64)
                self.gemm(n + "out", self.att, self.tmp, D, D, R)
                self.tick("p: conv layers")
            if self.skip.find(",norms,") < 0:
                ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[n + "ffn_norm"], self.xn, Int32(D),
                                                  Int32(1), grid_dim=count, block_dim=64)
            if self.moe[l] and self.skip.find(",experts,") >= 0:
                pass
            elif self.moe[l]:
                self.experts(n, count)
            elif self.skip.find(",dense,") >= 0:
                pass
            else:
                self.gemm(n + "gu", self.xn, self.gu, 2 * self.F, D, R)
                ctx.enqueue_function[lk.silu_mul](self.gu, self.act, Int32(self.F), c,
                                                  grid_dim=groups(count * self.F, 64), block_dim=64)
                self.gemm(n + "down", self.act, self.tmp, D, self.F, R)
                self.tick("p: dense MLPs")
            if self.skip.find(",norms,") < 0:
                ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.floats[self.next_norm(l)], self.xn, Int32(D),
                                                  Int32(1), grid_dim=count, block_dim=64)
            if self.dump:
                self.write_rows(out, rows, count)
            self.tick("p: norms")
        if self.dump:
            out.close()
        if last:
            self.head(count - 1, p0 + count)
            self.tick("p: head")
