# The DSpark drafter (LiquidAI/LFM2.5-2.6B-DSpark) on the Adreno, lfm2/dspark_ref.py's algorithm: 5 attention layers
# that draft 9 tokens at once from the target's tapped residual streams, the target's embedding and head, and a Markov
# head that corrects each draft by the one before it. Its bf16 weights are read in place from the checkpoint
# (manifest.txt: offsets in model.safetensors); norms are widened to fp32 on the host. q|k|v, gate|up and (for the
# context) k|v are fused at load.
#
# Per step at anchor position p (the target's newest token in ids[p]): draft() writes d_0 .. d_(nd-1) into ids[p + 1 ..
# p + nd], where the target's verify() reads them; add_context() then stores the accepted positions' K/V, from the
# taps the verify kept, in the drafter's cache.
from std.collections import Dict
from std.memory import bitcast
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import dsk
import lk
from model import LFM2, PMAX

comptime NL = 5
comptime DD = 2048
comptime DF = 6144
comptime GAMMA = 9
comptime MASK = 125017


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


struct DSpark(Movable):
    var ctx: DeviceContext
    var w: Dict[String, DeviceBuffer[DType.uint16]]
    var f: Dict[String, DeviceBuffer[DType.float32]]
    var kd: List[DeviceBuffer[DType.float32]]
    var vd: List[DeviceBuffer[DType.float32]]
    var nctx: Int  # positions in the context cache
    var bytes: Int
    var ctxh: DeviceBuffer[DType.float32]  # [PMAX, D]: fc of the taps
    var ctxn: DeviceBuffer[DType.float32]  # hidden_norm of those
    var kvt: DeviceBuffer[DType.float32]  # [PMAX, 1024]
    var dids: DeviceBuffer[DType.int32]  # the block's ids: the anchor, MASK x 8
    var x: DeviceBuffer[DType.float32]  # [MR, D]
    var h: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]  # [MR, 3072]
    var kb: DeviceBuffer[DType.float32]  # [MR, 512]
    var vb: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var tmp: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]  # [MR, 2 F]
    var act: DeviceBuffer[DType.float32]
    var base: DeviceBuffer[DType.float32]  # [MR, V]: the head's logits of the block rows
    var cand_v: DeviceBuffer[DType.float32]  # a step's best value of each markov_best workgroup
    var cand_i: DeviceBuffer[DType.int32]
    var V: Int

    def __init__(out self, ctx: DeviceContext, dir: String, cap: Int, vocab: Int) raises:
        """dir: manifest.txt (dspark_ref.py --export) and model.safetensors."""
        self.ctx = ctx
        self.V = vocab
        self.w = Dict[String, DeviceBuffer[DType.uint16]]()
        self.f = Dict[String, DeviceBuffer[DType.float32]]()
        self.kd = List[DeviceBuffer[DType.float32]]()
        self.vd = List[DeviceBuffer[DType.float32]]()
        self.nctx = 0
        self.bytes = 0
        for _ in range(NL):
            var k = ctx.enqueue_create_buffer[DType.float32](cap * 8 * 64)
            var v = ctx.enqueue_create_buffer[DType.float32](cap * 8 * 64)
            k.enqueue_fill(0)
            v.enqueue_fill(0)
            self.kd.append(k)
            self.vd.append(v)
        self.ctxh = ctx.enqueue_create_buffer[DType.float32](PMAX * DD)
        self.ctxn = ctx.enqueue_create_buffer[DType.float32](PMAX * DD)
        self.kvt = ctx.enqueue_create_buffer[DType.float32](PMAX * 1024)
        self.dids = ctx.enqueue_create_buffer[DType.int32](16)
        self.x = ctx.enqueue_create_buffer[DType.float32](dsk.MR * DD)
        self.h = ctx.enqueue_create_buffer[DType.float32](dsk.MR * DD)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](dsk.MR * 3072)
        self.kb = ctx.enqueue_create_buffer[DType.float32](dsk.MR * 512)
        self.vb = ctx.enqueue_create_buffer[DType.float32](dsk.MR * 512)
        self.att = ctx.enqueue_create_buffer[DType.float32](dsk.MR * DD)
        self.tmp = ctx.enqueue_create_buffer[DType.float32](dsk.MR * DD)
        self.gu = ctx.enqueue_create_buffer[DType.float32](dsk.MR * 2 * DF)
        self.act = ctx.enqueue_create_buffer[DType.float32](dsk.MR * DF)
        self.base = ctx.enqueue_create_buffer[DType.float32](dsk.MR * vocab)
        self.cand_v = ctx.enqueue_create_buffer[DType.float32](groups(vocab, dsk.MV))
        self.cand_i = ctx.enqueue_create_buffer[DType.int32](groups(vocab, dsk.MV))
        var ids = List[Int32](length=16, fill=Int32(MASK))
        ctx.enqueue_copy(self.dids, ids.unsafe_ptr())
        ctx.synchronize()
        self.load(dir)

    def load(mut self, dir: String) raises:
        var where = Dict[String, Int]()
        var size = Dict[String, Int]()
        var lines = open(dir + "/manifest.txt", "r").read().splitlines()
        if not lines[0].startswith("dspark"):
            raise Error(dir + "/manifest.txt: not a DSpark manifest")
        for i in range(1, len(lines)):
            var p = lines[i].split(" ")
            where[String(p[0])] = Int(p[1])
            size[String(p[0])] = Int(p[2])
        var f = open(dir + "/model.safetensors", "r")
        self.matrix(f, where, size, "fc", ["fc.weight"])
        self.matrix(f, where, size, "w1", ["markov_head.markov_w1.weight"])
        self.matrix(f, where, size, "w2", ["markov_head.markov_w2.weight"])
        self.vector(f, where, size, "hidden_norm", "hidden_norm.weight")
        self.vector(f, where, size, "norm", "norm.weight")
        for i in range(NL):
            var l = "layers." + String(i) + "."
            var a = l + "self_attn."
            var k = String(i)
            self.matrix(f, where, size, "qkv" + k, [a + "q_proj.weight", a + "k_proj.weight", a + "v_proj.weight"])
            self.matrix(f, where, size, "kv" + k, [a + "k_proj.weight", a + "v_proj.weight"])
            self.matrix(f, where, size, "o" + k, [a + "o_proj.weight"])
            self.matrix(f, where, size, "gu" + k, [l + "mlp.gate_proj.weight", l + "mlp.up_proj.weight"])
            self.matrix(f, where, size, "down" + k, [l + "mlp.down_proj.weight"])
            self.vector(f, where, size, "qn" + k, a + "q_norm.weight")
            self.vector(f, where, size, "kn" + k, a + "k_norm.weight")
            self.vector(f, where, size, "in" + k, l + "input_layernorm.weight")
            self.vector(f, where, size, "post" + k, l + "post_attention_layernorm.weight")
        f.close()

    def matrix(mut self, mut f: FileHandle, where: Dict[String, Int], size: Dict[String, Int], key: String,
               names: List[String]) raises:
        """The tensors `names` (bf16 rows), one after another, as one device matrix `key`."""
        var total = 0
        for n in names:
            total += size[n]
        var all = List[UInt8](capacity=total)
        for n in names:
            _ = f.seek(where[n])
            var data = f.read_bytes(size[n])
            if len(data) != size[n]:
                raise Error("model.safetensors: short read of " + n)
            all.extend(data^)
        var b = self.ctx.enqueue_create_buffer[DType.uint16](total // 2)
        self.ctx.enqueue_copy(b, all.unsafe_ptr().unsafe_bitcast[UInt16]())
        self.ctx.synchronize()
        self.w[key] = b
        self.bytes += total

    def vector(mut self, mut f: FileHandle, where: Dict[String, Int], size: Dict[String, Int], key: String,
               name: String) raises:
        """A bf16 vector (a norm's weight), widened to fp32."""
        _ = f.seek(where[name])
        var raw = f.read_bytes(size[name])
        var n = len(raw) // 2
        var vals = List[Float32](length=n, fill=0)
        var h = raw.unsafe_ptr().unsafe_bitcast[UInt16]()
        for i in range(n):
            vals[i] = bitcast[DType.float32](UInt32(h[i]) << 16)
        var b = self.ctx.enqueue_create_buffer[DType.float32](n)
        self.ctx.enqueue_copy(b, vals.unsafe_ptr())
        self.ctx.synchronize()
        self.f[key] = b

    def rows(self, key: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], cols: Int, n: Int,
             count: Int) raises:
        var a = (Int32(cols), Int32(n), Int32(count))
        if count <= 4:
            self.ctx.enqueue_function[dsk.rows_bf[1]](self.w[key], x, y, a[0], a[1], a[2], grid_dim=n // dsk.TR,
                                                      block_dim=64)
        elif count <= 8:
            self.ctx.enqueue_function[dsk.rows_bf[2]](self.w[key], x, y, a[0], a[1], a[2], grid_dim=n // dsk.TR,
                                                      block_dim=64)
        else:
            self.ctx.enqueue_function[dsk.rows_bf[3]](self.w[key], x, y, a[0], a[1], a[2], grid_dim=n // dsk.TR,
                                                      block_dim=64)

    def add_context(mut self, model: LFM2, p0: Int, count: Int) raises:
        """Positions p0 .. p0 + count - 1 into the context cache, from the target's taps (rows 0 .. count - 1 of
        model.taps): fc, hidden_norm, then each layer's k|v projection, K norm and interleaved RoPE."""
        if p0 != self.nctx:
            raise Error("the drafter's context ends at " + String(self.nctx) + ", not " + String(p0))
        var ctx = self.ctx
        if count <= dsk.MR:
            self.rows("fc", model.taps, self.ctxh, 5 * DD, DD, count)
        else:
            ctx.enqueue_function[dsk.gemm_bf](self.w["fc"], model.taps, self.ctxh, Int32(DD), Int32(5 * DD),
                                              grid_dim=Dim(DD // 64, groups(count, 64)), block_dim=256)
        ctx.enqueue_function[lk.add_norm](self.ctxh, self.ctxh, self.f["hidden_norm"], self.ctxn, Int32(DD), Int32(0),
                                          grid_dim=count, block_dim=64)
        for i in range(NL):
            var k = String(i)
            if count <= dsk.MR:
                self.rows("kv" + k, self.ctxn, self.kvt, DD, 1024, count)
            else:
                ctx.enqueue_function[dsk.gemm_bf](self.w["kv" + k], self.ctxn, self.kvt, Int32(1024), Int32(DD),
                                                  grid_dim=Dim(1024 // 64, groups(count, 64)), block_dim=256)
            ctx.enqueue_function[dsk.ctx_kv_write](self.kvt, self.f["kn" + k], model.rope, self.kd[i], self.vd[i],
                                                   Int32(p0), grid_dim=Dim(16, count), block_dim=64)
        self.nctx = p0 + count

    def draft(self, mut model: LFM2, p: Int, nd: Int) raises:
        """Drafts for positions p + 1 .. p + nd (nd <= 9) into model.ids, from the anchor ids[p] and the context (< p).
        The block is always the anchor and 8 masks (what the drafter was trained on: its attention over the block is
        not causal, so every row shapes the others); only the first nd rows go through the head and the Markov steps."""
        if p != self.nctx:
            raise Error("draft at " + String(p) + " with a context of " + String(self.nctx))
        var ctx = self.ctx
        var G = GAMMA
        ctx.enqueue_function[dsk.copy_id](model.ids, Int32(p), self.dids, Int32(0), grid_dim=1, block_dim=64)
        ctx.enqueue_function[lk.embed_q6](self.dids, Int32(0), model.words["embed.q"], model.halves["embed.d"], self.x,
                                          Int32(DD), grid_dim=G, block_dim=64)
        ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.f["in0"], self.h, Int32(DD), Int32(0), grid_dim=G,
                                          block_dim=64)
        model.tick("d: embed")
        for i in range(NL):
            var k = String(i)
            self.rows("qkv" + k, self.h, self.qkv, DD, 3072, G)
            model.tick("d: layers' products")
            ctx.enqueue_function[dsk.draft_qk_norm_rope](self.qkv, self.f["qn" + k], self.f["kn" + k], model.rope,
                                                         self.kb, self.vb, Int32(p), Float32(0.125),
                                                         grid_dim=Dim(48, G), block_dim=64)
            ctx.enqueue_function[dsk.draft_attention](self.qkv, self.kd[i], self.vd[i], self.kb, self.vb, self.att,
                                                      Int32(p), Int32(G), grid_dim=Dim(32, G), block_dim=64)
            model.tick("d: q/k norms, RoPE, attention")
            self.rows("o" + k, self.att, self.tmp, DD, DD, G)
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.f["post" + k], self.h, Int32(DD), Int32(1),
                                              grid_dim=G, block_dim=64)
            self.rows("gu" + k, self.h, self.gu, DD, 2 * DF, G)
            ctx.enqueue_function[lk.silu_mul](self.gu, self.act, Int32(DF), Int32(G), grid_dim=groups(G * DF, 64),
                                              block_dim=64)
            self.rows("down" + k, self.act, self.tmp, DF, DD, G)
            var nxt = "in" + String(i + 1) if i + 1 < NL else "norm"
            ctx.enqueue_function[lk.add_norm](self.x, self.tmp, self.f[nxt], self.h, Int32(DD), Int32(1),
                                              grid_dim=G, block_dim=64)
            model.tick("d: layers' products")
        model.head_rows(self.h, self.base, nd)
        model.tick("d: head")
        var nc = groups(self.V, dsk.MV)
        for j in range(nd):  # each step's token is the next step's previous one: nd steps in order
            ctx.enqueue_function[dsk.markov_best](self.base.create_sub_buffer[DType.float32](j * self.V, self.V),
                                                  self.w["w1"], self.w["w2"], model.ids, Int32(p + j), self.cand_v,
                                                  self.cand_i, Int32(self.V), grid_dim=nc, block_dim=64)
            ctx.enqueue_function[dsk.best_of](self.cand_v, self.cand_i, Int32(nc), model.ids, Int32(p + 1 + j),
                                              grid_dim=1, block_dim=256)
            model.tick("d: Markov steps")