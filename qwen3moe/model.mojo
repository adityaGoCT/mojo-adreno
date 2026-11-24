# Qwen3-30B-A3B (Qwen/Qwen3-30B-A3B-Instruct-2507) decode as MAX DeviceContext launches: 48 layers of grouped-query
# attention (32 query and 4 KV heads of 128, QK norm, RoPE theta 1e7) and a mixture of 128 experts (top-8, SwiGLU of
# 768), int4 projections and experts (export.py's qwen3moe.bin: 15.7 GB on the GPU), fp32 activations and KV cache.
#
# The weights never cross to the host program: export.py's manifest names each tensor's place in qwen3moe.bin, a file
# on the device that runs the executor (the X2 Elite laptop, behind the remote driver plugin), and the plugin's
# M_driver_remote_file has the executor read it into the device buffer. The fp32 embedding stays in the file: each step
# has the executor copy the row of its token, which it reads from the GPU's token list (the prompt, then each argmax),
# with M_driver_remote_gather. So a whole generation is enqueued without the host waiting for any token.
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.math import cos, sin
from std.os import getenv
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import gemv_add_q4
import gemv_q4
import lkh
import moek

comptime D = 2048
comptime L = 48
comptime H = 32
comptime KVH = 4
comptime HD = 128
comptime QKV = (H + 2 * KVH) * HD  # 5120
comptime E = 128
comptime TOPK = 8
comptime FE = 768
comptime V = 151936
comptime CAP = 512  # positions a KV cache holds
comptime PMAX = 256  # prompt tokens a prefill runs at once
comptime THETA: Float64 = 10000000.0
# QWEN3MOE_GEMM=q: the prefill's products on fp16 cooperative matrices (lfm2/kernels/lkh.mojo) instead of a matrix row
# a lane against 8 tokens in fp32. q/k/v and o: X packed into fp16 R tiles (pack_x), the int4 rows unpacked into fp16
# shared memory inside the product (gemm_hq), K in chunks of GCH added in fp32 (sum_parts, sum_parts_add). Experts: the
# (token, choice) pairs grouped by expert into tiles of TMG rows (lkh.group), the grouped rows packed (pack_gather),
# every tile's gate|up product in one gemm_hqg launch, silu(gate) up packed (swiglu_pack), gemm_hqg for down, and
# each token's 8 outputs weighted into the residual stream (combine). A cooperative matrix is 64 rows, so an expert's
# tile is mostly padding (a 256-token batch gives an expert about 16 rows). The 840's family rounds every partial sum
# of an fp16 product to fp16.
comptime GCH = 2048
comptime TMG = 64
comptime GWN = 2  # gemm_hqg's tiles: 64 rows x 64 GWN columns (128: 20 ms against 25 for a 256-token batch's experts)
comptime MAXG = (PMAX * TOPK + E * (TMG - 1) + TMG - 1) // TMG * TMG  # grouped rows, each expert's padding included


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


def plugin_path() raises -> String:
    """The driver plugin MAX loaded: MODULAR_DRIVER_PLUGINS=vulkan@<path>."""
    var spec = getenv("MODULAR_DRIVER_PLUGINS")
    var at = spec.find("@")
    if at < 0:
        raise Error("MODULAR_DRIVER_PLUGINS=vulkan@<path of libM_driver_vulkan_remote> is needed")
    return String(spec[byte=at + 1:])


struct Qwen3Moe(Movable):
    var ctx: DeviceContext
    var lib: OwnedDLHandle  # the driver plugin, for M_driver_remote_file and M_driver_remote_gather
    var path: String  # qwen3moe.bin on the executor's side
    var embed_offset: Int
    var words: Dict[String, DeviceBuffer[DType.uint32]]
    var halves: Dict[String, DeviceBuffer[DType.float16]]
    var floats: Dict[String, DeviceBuffer[DType.float32]]
    var bytes: Int
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]
    var table: DeviceBuffer[DType.float32]  # RoPE: cos | sin rows of 64 per position
    var tokens: DeviceBuffer[DType.int32]  # the prompt, then the generated tokens
    var x: DeviceBuffer[DType.float32]
    var xn: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var scores: DeviceBuffer[DType.float32]
    var rlog: DeviceBuffer[DType.float32]
    var ids: DeviceBuffer[DType.int32]
    var wts: DeviceBuffer[DType.float32]
    var a: DeviceBuffer[DType.float32]
    var logits: DeviceBuffer[DType.float32]
    # prefill: rows of up to PMAX tokens
    var px: DeviceBuffer[DType.float32]
    var pxn: DeviceBuffer[DType.float32]
    var pqkv: DeviceBuffer[DType.float32]
    var patt: DeviceBuffer[DType.float32]
    var prl: DeviceBuffer[DType.float32]
    var pids: DeviceBuffer[DType.int32]
    var pwts: DeviceBuffer[DType.float32]
    var pa: DeviceBuffer[DType.float32]
    var ppart: DeviceBuffer[DType.float32]
    var plists: DeviceBuffer[DType.int32]
    var pcounts: DeviceBuffer[DType.int32]
    var pitems: DeviceBuffer[DType.int32]
    var pnitems: DeviceBuffer[DType.int32]
    var gemmq: Bool  # QWEN3MOE_GEMM=q (set at construction)
    var xa: DeviceBuffer[DType.float16]  # lkh's X: fp16 R tiles (a batch's rows, or the grouped rows)
    var part: DeviceBuffer[DType.float16]  # lkh's fp16 partial products, a K chunk each
    var slot: DeviceBuffer[DType.int32]  # each (token, choice)'s grouped row [PMAX, TOPK]
    var src: DeviceBuffer[DType.int32]  # each grouped row's token (-1: padding) [MAXG]
    var tiles: DeviceBuffer[DType.int32]  # work tiles (expert, first grouped row) [MAXG / TMG, 2]
    var ntiles: DeviceBuffer[DType.int32]

    def __init__(out self, ctx: DeviceContext, manifest: String, weights: String, gemmq: Bool = False) raises:
        """manifest: export.py's manifest.txt (a copy on this side); weights: qwen3moe.bin's path on the executor's
        side. gemmq: the prefill's products on lkh's fp16 cooperative matrices (the fp32 path's expert buffers are
        then left out: the GPU's heap has about 0.25 GB to spare)."""
        self.ctx = ctx
        self.lib = OwnedDLHandle(plugin_path())
        self.path = weights
        self.embed_offset = -1
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.bytes = 0
        self.kc = List[DeviceBuffer[DType.float32]]()
        self.vc = List[DeviceBuffer[DType.float32]]()
        for _ in range(L):
            self.kc.append(ctx.enqueue_create_buffer[DType.float32](CAP * KVH * HD))
            self.vc.append(ctx.enqueue_create_buffer[DType.float32](CAP * KVH * HD))
        self.table = ctx.enqueue_create_buffer[DType.float32](CAP * HD)
        self.tokens = ctx.enqueue_create_buffer[DType.int32](CAP + 1)
        self.x = ctx.enqueue_create_buffer[DType.float32](D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](D)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](QKV)
        self.att = ctx.enqueue_create_buffer[DType.float32](H * HD)
        self.scores = ctx.enqueue_create_buffer[DType.float32](H * CAP)
        self.rlog = ctx.enqueue_create_buffer[DType.float32](E)
        self.ids = ctx.enqueue_create_buffer[DType.int32](TOPK)
        self.wts = ctx.enqueue_create_buffer[DType.float32](TOPK)
        self.a = ctx.enqueue_create_buffer[DType.float32](TOPK * FE)
        self.logits = ctx.enqueue_create_buffer[DType.float32](V)
        self.px = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.pxn = ctx.enqueue_create_buffer[DType.float32](PMAX * D)
        self.pqkv = ctx.enqueue_create_buffer[DType.float32](PMAX * QKV)
        self.patt = ctx.enqueue_create_buffer[DType.float32](PMAX * H * HD)
        self.prl = ctx.enqueue_create_buffer[DType.float32](PMAX * E)
        self.pids = ctx.enqueue_create_buffer[DType.int32](PMAX * TOPK)
        self.pwts = ctx.enqueue_create_buffer[DType.float32](PMAX * TOPK)
        self.gemmq = gemmq
        var q = 0 if gemmq else 1  # with gemmq, a 1-element stand-in for each buffer only one path uses
        self.pa = ctx.enqueue_create_buffer[DType.float32](max(1, q * PMAX * TOPK * FE))
        self.ppart = ctx.enqueue_create_buffer[DType.float32](max(1, q * PMAX * TOPK * D))
        self.plists = ctx.enqueue_create_buffer[DType.int32](max(1, q * E * PMAX))
        var nxa = max(MAXG * max(D, FE), PMAX * max(D, H * HD))
        var npart = max(MAXG * max(groups(D, GCH) * 2 * FE, groups(FE, GCH) * D),
                        PMAX * max(groups(D, GCH) * QKV, groups(H * HD, GCH) * D))
        self.xa = ctx.enqueue_create_buffer[DType.float16](max(1, (1 - q) * nxa))
        self.part = ctx.enqueue_create_buffer[DType.float16](max(1, (1 - q) * npart))
        self.slot = ctx.enqueue_create_buffer[DType.int32](max(1, (1 - q) * PMAX * TOPK))
        self.src = ctx.enqueue_create_buffer[DType.int32](max(1, (1 - q) * MAXG))
        self.tiles = ctx.enqueue_create_buffer[DType.int32](max(1, (1 - q) * 2 * (MAXG // TMG)))
        self.ntiles = ctx.enqueue_create_buffer[DType.int32](1)
        self.pcounts = ctx.enqueue_create_buffer[DType.int32](E)
        self.pitems = ctx.enqueue_create_buffer[DType.int32](2 * (PMAX + E))
        self.pnitems = ctx.enqueue_create_buffer[DType.int32](1)
        self.load(manifest)
        self.rope_table()

    def load(mut self, manifest: String) raises:
        var lines = open(manifest, "r").read().splitlines()
        for i in range(1, len(lines)):
            var f = lines[i].split(" ")
            if len(f) < 4:
                continue
            var name = String(f[0])
            var off = Int(f[1])
            var n = Int(f[2])
            var kind = String(f[3])
            if name == "embed":  # stays in the file: step() gathers its rows
                self.embed_offset = off
                continue
            var addr: Int
            if kind == "u32":
                var b = self.ctx.enqueue_create_buffer[DType.uint32](n // 4)
                addr = Int(b.unsafe_ptr())
                self.words[name] = b
            elif kind == "f16":
                var b = self.ctx.enqueue_create_buffer[DType.float16](n // 2)
                addr = Int(b.unsafe_ptr())
                self.halves[name] = b
            else:
                var b = self.ctx.enqueue_create_buffer[DType.float32](n // 4)
                addr = Int(b.unsafe_ptr())
                self.floats[name] = b
            if self.lib.call["M_driver_remote_file", Int32](UInt64(addr), UInt64(n),
                                                           self.path.as_c_string_span().unsafe_ptr(), UInt64(off)) != 0:
                raise Error("M_driver_remote_file failed for " + name)
            self.bytes += n
        if self.embed_offset < 0:
            raise Error(manifest + ": no embed")
        self.ctx.synchronize()  # a read's error arrives here

    def rope_table(mut self) raises:
        """cos | sin of position * inv_freq, as transformers' default RoPE computes them in fp32."""
        var host = List[Float32](length=CAP * HD, fill=0)
        for i in range(HD // 2):
            var inv = Float32(1.0) / (Float32(THETA) ** (Float32(2 * i) / Float32(HD)))
            for p in range(CAP):
                var f = Float32(p) * inv
                host[p * HD + i] = Float32(cos(Float64(f)))
                host[p * HD + HD // 2 + i] = Float32(sin(Float64(f)))
        self.ctx.enqueue_copy(self.table, host.unsafe_ptr())
        self.ctx.synchronize()

    def set_prompt(self, prompt: List[Int32]) raises:
        var host = List[Int32](length=CAP + 1, fill=0)
        for i in range(len(prompt)):
            host[i] = prompt[i]
        self.ctx.enqueue_copy(self.tokens, host.unsafe_ptr())

    def step(mut self, pos: Int, write: Bool) raises:
        """The token at `pos` (from the token list) through the model; its argmax into tokens[pos + 1] if `write`."""
        var ctx = self.ctx
        var p = Int32(pos)
        if self.lib.call["M_driver_remote_gather", Int32](UInt64(Int(self.x.unsafe_ptr())),
                                                          UInt64(Int(self.tokens.unsafe_ptr()) + 4 * pos),
                                                          self.path.as_c_string_span().unsafe_ptr(),
                                                          UInt64(self.embed_offset), UInt64(4 * D)) != 0:
            raise Error("M_driver_remote_gather failed")
        for l in range(L):
            var n = "l" + String(l) + "."
            ctx.enqueue_function[moek.rmsnorm](self.x, self.floats[n + "in_norm"], self.xn, Int32(D), grid_dim=1,
                                               block_dim=64)
            ctx.enqueue_function[gemv_q4.gemv_q4](self.words[n + "qkv.q"], self.halves[n + "qkv.s"], self.xn, self.qkv,
                                                  Int64(D), grid_dim=QKV, block_dim=64)
            ctx.enqueue_function[moek.qk_norm_rope](self.qkv, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                    self.table, self.kc[l], self.vc[l], p, grid_dim=H + 2 * KVH,
                                                    block_dim=64)
            ctx.enqueue_function[moek.attn_scores](self.qkv, self.kc[l], self.scores, p, Int32(CAP),
                                                   grid_dim=groups(KVH * (pos + 1), 64), block_dim=64)
            ctx.enqueue_function[moek.attn_values](self.scores, self.vc[l], self.att, p, Int32(CAP),
                                                   grid_dim=2 * H, block_dim=64)
            ctx.enqueue_function[gemv_add_q4.gemv_add_q4](self.words[n + "o.q"], self.halves[n + "o.s"], self.att,
                                                          self.x, Int64(H * HD), grid_dim=D, block_dim=64)
            ctx.enqueue_function[moek.rmsnorm](self.x, self.floats[n + "post_norm"], self.xn, Int32(D), grid_dim=1,
                                               block_dim=64)
            ctx.enqueue_function[moek.gemv_f32](self.floats[n + "router"], self.xn, self.rlog, Int32(D), grid_dim=E,
                                                block_dim=64)
            ctx.enqueue_function[moek.route](self.rlog, self.ids, self.wts, grid_dim=1, block_dim=64)
            ctx.enqueue_function[moek.moe_gate_up](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.ids, self.xn,
                                                   self.a, grid_dim=Dim(FE, TOPK), block_dim=64)
            ctx.enqueue_function[moek.moe_down](self.words[n + "down.q"], self.halves[n + "down.s"], self.ids, self.wts,
                                                self.a, self.x, grid_dim=D, block_dim=64)
        ctx.enqueue_function[moek.rmsnorm](self.x, self.floats["final_norm"], self.xn, Int32(D), grid_dim=1,
                                           block_dim=64)
        ctx.enqueue_function[gemv_q4.gemv_q4](self.words["head.q"], self.halves["head.s"], self.xn, self.logits,
                                              Int64(D), grid_dim=V, block_dim=64)
        ctx.enqueue_function[moek.argmax](self.logits, Int32(V), self.tokens, p, Int32(1 if write else 0), grid_dim=1,
                                          block_dim=256)

    def gemm(self, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], n: Int, k: Int,
             count: Int, add: Bool) raises:
        """y[t] = (add: y[t] +) W x[t] for the batch's first `count` rows, W the int4 matrix `name` (n x k, a scale per
        64), on lkh's fp16 cooperative matrices: the rows padded to 128 (x and y hold PMAX)."""
        var rows = groups(count, 128) * 128
        var chunks = groups(k, GCH)
        if rows > PMAX or rows * k > len(self.xa) or chunks * rows * n > len(self.part):
            raise Error("lkh: a buffer is too small")
        self.ctx.enqueue_function[lkh.pack_x](x, self.xa.create_sub_buffer[DType.uint32](0, rows * k // 2), Int32(k),
                                              Int32(rows * k // 8), grid_dim=groups(rows * k // 8, 256),
                                              block_dim=256)
        self.ctx.enqueue_function[lkh.gemm_hq[2, 1, GCH, 64, 4, False, 64]](
            self.xa, self.words[name + ".q"], self.halves[name + ".s"], self.part, Int32(n), Int32(k), Int32(rows),
            grid_dim=Dim(n // 64, rows // 128, chunks), block_dim=128)
        if add:
            self.ctx.enqueue_function[lkh.sum_parts_add](self.part, y, Int32(count * n), Int32(chunks),
                                                         Int32(rows * n), grid_dim=groups(count * n // 8, 256),
                                                         block_dim=256)
        else:
            self.ctx.enqueue_function[lkh.sum_parts](self.part, y, Int32(rows * n), Int32(chunks),
                                                     grid_dim=groups(rows * n // 8, 256), block_dim=256)

    def experts_q(self, n: String, count: Int) raises:
        """The routed experts of pxn's first `count` rows (pids, pwts chosen), weighted, added into px: the pairs
        grouped by expert, both products one gemm_hqg launch each, silu(gate) up packed between them."""
        var ctx = self.ctx
        var tm = Int32(TMG)
        var c1 = groups(D, GCH)
        var c2 = groups(FE, GCH)
        self.src.enqueue_fill(-1)
        ctx.enqueue_function[lkh.group[TOPK]](self.pids, self.slot, self.src, self.tiles, self.ntiles, Int32(count),
                                              Int32(E), tm, grid_dim=1, block_dim=128)
        ctx.enqueue_function[lkh.pack_gather](self.pxn, self.src, self.xa.create_sub_buffer[DType.uint32](
            0, MAXG * D // 2), Int32(D), self.ntiles, tm, grid_dim=groups(MAXG * D // 8, 256), block_dim=256)
        ctx.enqueue_function[lkh.gemm_hqg[GWN, GCH, 64, 4, False, moek.GE]](
            self.xa, self.words[n + "gu.q"], self.halves[n + "gu.s"], self.part, Int32(2 * FE), Int32(D), Int32(MAXG),
            self.tiles, self.ntiles, grid_dim=Dim(2 * FE // (64 * GWN), MAXG // TMG, c1), block_dim=64 * GWN)
        ctx.enqueue_function[lkh.swiglu_pack](self.part, Int32(c1), Int32(MAXG), Int32(FE),
                                              self.xa.create_sub_buffer[DType.uint32](0, MAXG * FE // 2), self.ntiles,
                                              tm, grid_dim=groups(MAXG * FE // 8, 256), block_dim=256)
        ctx.enqueue_function[lkh.gemm_hqg[GWN, GCH, 64, 4, False, moek.GE]](
            self.xa, self.words[n + "down.q"], self.halves[n + "down.s"], self.part, Int32(D), Int32(FE), Int32(MAXG),
            self.tiles, self.ntiles, grid_dim=Dim(D // (64 * GWN), MAXG // TMG, c2), block_dim=64 * GWN)
        ctx.enqueue_function[lkh.combine[TOPK, True]](self.part, Int32(c2), Int32(MAXG), self.slot, self.pwts, self.px,
                                                      Int32(count), Int32(D), grid_dim=groups(count * D, 64),
                                                      block_dim=64)

    def prefill(mut self, p0: Int, count: Int, write: Bool) raises:
        """Tokens p0 .. p0 + count - 1 of the token list at once (count <= PMAX; positions p0 on): each matrix row is
        read once for all of them, each expert's rows once for the tokens that chose it. The last token's argmax goes
        into tokens[p0 + count] if `write`."""
        if count < 1 or count > PMAX or p0 + count > CAP:
            raise Error("prefill: " + String(count) + " tokens at " + String(p0))
        var ctx = self.ctx
        var c = Int32(count)
        for t in range(count):
            if self.lib.call["M_driver_remote_gather", Int32](UInt64(Int(self.px.unsafe_ptr()) + 4 * D * t),
                                                              UInt64(Int(self.tokens.unsafe_ptr()) + 4 * (p0 + t)),
                                                              self.path.as_c_string_span().unsafe_ptr(),
                                                              UInt64(self.embed_offset), UInt64(4 * D)) != 0:
                raise Error("M_driver_remote_gather failed")
        for l in range(L):
            var n = "l" + String(l) + "."
            ctx.enqueue_function[moek.p_rmsnorm](self.px, self.floats[n + "in_norm"], self.pxn, Int32(D),
                                                 grid_dim=count, block_dim=64)
            if self.gemmq:
                self.gemm(n + "qkv", self.pxn, self.pqkv, QKV, D, count, False)
            else:
                ctx.enqueue_function[moek.t_gemv_q4](self.words[n + "qkv.q"], self.halves[n + "qkv.s"], self.pxn,
                                                     self.pqkv, Int32(D), Int32(QKV), c, Int32(0),
                                                     grid_dim=Dim(QKV // 64, groups(count, moek.TT)), block_dim=64)
            ctx.enqueue_function[moek.p_qk_norm_rope](self.pqkv, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      self.table, self.kc[l], self.vc[l], Int32(p0),
                                                      grid_dim=Dim(H + 2 * KVH, count), block_dim=64)
            ctx.enqueue_function[moek.p_attention](self.pqkv, self.kc[l], self.vc[l], self.patt, Int32(p0),
                                                   grid_dim=Dim(H, count), block_dim=64)
            if self.gemmq:
                self.gemm(n + "o", self.patt, self.px, D, H * HD, count, True)
            else:
                ctx.enqueue_function[moek.t_gemv_q4](self.words[n + "o.q"], self.halves[n + "o.s"], self.patt, self.px,
                                                     Int32(H * HD), Int32(D), c, Int32(1),
                                                     grid_dim=Dim(D // 64, groups(count, moek.TT)), block_dim=64)
            ctx.enqueue_function[moek.p_rmsnorm](self.px, self.floats[n + "post_norm"], self.pxn, Int32(D),
                                                 grid_dim=count, block_dim=64)
            ctx.enqueue_function[moek.p_gemv_f32](self.floats[n + "router"], self.pxn, self.prl, Int32(D), Int32(E), c,
                                                  grid_dim=E, block_dim=64)
            ctx.enqueue_function[moek.p_route](self.prl, self.pids, self.pwts, grid_dim=count, block_dim=64)
            if self.gemmq:
                self.experts_q(n, count)
                continue
            ctx.enqueue_function[moek.p_expert_lists](self.pids, self.plists, self.pcounts, c, grid_dim=E, block_dim=64)
            ctx.enqueue_function[moek.p_expert_items](self.pcounts, self.pitems, self.pnitems, grid_dim=1,
                                                      block_dim=64)
            var items = groups(count * TOPK, moek.TT) + E  # at most: work items of 8 (expert, token) pairs
            ctx.enqueue_function[moek.t_moe_gate_up](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.pitems,
                                                     self.pnitems, self.plists, self.pcounts, self.pxn, self.pa,
                                                     grid_dim=Dim(FE // 64, items), block_dim=64)
            ctx.enqueue_function[moek.t_moe_down](self.words[n + "down.q"], self.halves[n + "down.s"], self.pitems,
                                                  self.pnitems, self.plists, self.pcounts, self.pa, self.ppart,
                                                  grid_dim=Dim(D // 64, items), block_dim=64)
            ctx.enqueue_function[moek.p_moe_sum](self.ppart, self.pwts, self.px, c, grid_dim=groups(count * D, 64),
                                                 block_dim=64)
        var last = self.px.create_sub_buffer[DType.float32]((count - 1) * D, D)
        ctx.enqueue_function[moek.rmsnorm](last, self.floats["final_norm"], self.xn, Int32(D), grid_dim=1,
                                           block_dim=64)
        ctx.enqueue_function[gemv_q4.gemv_q4](self.words["head.q"], self.halves["head.s"], self.xn, self.logits,
                                              Int64(D), grid_dim=V, block_dim=64)
        ctx.enqueue_function[moek.argmax](self.logits, Int32(V), self.tokens, Int32(p0 + count - 1),
                                          Int32(1 if write else 0), grid_dim=1, block_dim=256)
