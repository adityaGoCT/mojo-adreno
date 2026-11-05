# π0 (lerobot/pi0_base, lerobot's port of openpi's PyTorch π0) on the Adreno as MAX DeviceContext launches of the
# kernels in vla/kernels: the forward pass of lerobot's PI0Pytorch.sample_actions, in Mojo. Weights straight from
# the checkpoint's model.safetensors (fp32): every tensor whose values bf16 holds exactly (SigLIP's, Gemma's and the
# expert's matrices) is stored in bf16 and widened as the matmuls stage it, the rest stay fp32 (host.AUTO), so the
# arithmetic is the fp32 checkpoint's. Activations, attention, norms and the K/V cache are fp32.
#
#   vision()   three cameras' 224 x 224 images through SigLIP So400m (27 layers of 1152, heads of 72, 256 patches
#              each), batched as 768 rows; attention per image
#   embed()    the multimodal projector (1152 -> 2048): 256 tokens an image; the task's 48 language rows (Gemma's
#              embedding, gathered on the CPU from the checkpoint, times sqrt(2048)): 816 prefix rows
#   prefix()   the prefix through Gemma 2B's 18 layers (MQA: 8 heads of 256, one K/V head; GeGLU MLP of 16384),
#              filling every layer's K/V cache (K after RoPE); synchronized after each layer, since the driver
#              plugin's submissions of 64 launches (driver/README.md) would outlast the GPU's watchdog
#   step(s)    one Euler step: the expert (Gemma 300M: 18 layers of 1024, the same heads) runs the suffix (50 action
#              tokens and the state token) against the prefix's cache and its own K/V, every layer; v_t comes from
#              its last 50 rows; x_t += -0.1 v_t
#
# Rows are padded: the prefix to 896 (128 x 128 blocks), the suffix to 64 (actions in rows 0..49, the state in row
# 50: attention masks and positions are per row, so the order is free). Masks are levels (vla/kernels/vattn.mojo):
# prefix 0, the state 1, the actions 2 (they see each other), padding never visible.
from std.collections import Dict
from std.math import cos, sin, sqrt
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

from host import AUTO, WIDE, Scratch, Weights, attend, attend_split, groups, lin, one
from safetensors import Checkpoint
import vrow
from vgemm import GELU, GELU_MUL, NONE, SILU

comptime IMG = 224
comptime PATCH = 14
comptime GRID = IMG // PATCH  # 16
comptime NPATCH = GRID * GRID  # 256
comptime NCAM = 3
comptime VROWS = NCAM * NPATCH  # 768
comptime KP = 3 * PATCH * PATCH  # 588: a patch
comptime VD = 1152
comptime VF = 4304
comptime VFP = 4352  # VF rounded up to 64
comptime VL = 27
comptime VH = 16
comptime VHD = 72
comptime D = 2048
comptime L = 18
comptime H = 8
comptime HD = 256
comptime QKV = (H + 2) * HD  # 2560
comptime F = 16384
comptime NLANG = 48
comptime PLEN = VROWS + NLANG  # 816
comptime PROWS = 896  # PLEN rounded up to 128: the matmuls' 128 x 128 blocks (832 rows took 64 x 128, 2.5x slower)
comptime ED = 1024
comptime EF = 4096
comptime CHUNK = 50
comptime AROWS = 64
comptime STATE_ROW = CHUNK  # the suffix's state token
comptime ADIM = 32
comptime STEPS = 10
comptime KVROWS = PROWS + AROWS  # 896
comptime MAXPOS = 1024
comptime EPS_V: Float32 = 1e-6
comptime EPS_G: Float32 = 1e-6
comptime INF: Float32 = 1e30
comptime XA_SIZE = PROWS * F  # the activated input of Gemma's down projection
comptime PART_SIZE = 4 * PROWS * D  # split-k's partial sums: Gemma's down projection in 4 splits
comptime SPLIT_TARGET = 448  # split-k on the staged path: aim for this many workgroups...
comptime SPLIT_BELOW = 64  # ... for projections of fewer blocks (SigLIP's fc2: 54 -> 4 splits; Gemma's 112+ stay whole)
comptime ACT_FIRST = 8192  # Gemma's down projection (k = 16384): gelu(gate) * up computed once, not per column block
comptime KSPLIT = 5  # the expert's attention: its 15 key blocks split 5 ways (vattn.attention[SPLIT])
comptime MAXSPLIT = 15
comptime SK_ROWS = 256

comptime VP = "paligemma_with_expert.paligemma.model.vision_tower.vision_model."
comptime GP = "paligemma_with_expert.paligemma.model.language_model."
comptime EP = "paligemma_with_expert.gemma_expert.model."
comptime EMBED = "paligemma_with_expert.paligemma.lm_head.weight"  # tied: the language embedding


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


struct Pi0(Movable):
    var ctx: DeviceContext
    var w: Weights[DType.uint16, False]
    var s: Scratch
    var path: String
    var embed_offset: Int  # the embedding in the checkpoint: rows read on the CPU
    # inputs
    var pix: DeviceBuffer[DType.float32]
    var lang: List[Float32]  # the language rows, gathered on the CPU
    var st: DeviceBuffer[DType.float32]  # [64, 32]: the state in row 0
    var xt: DeviceBuffer[DType.float32]  # [64, 32]: x_t
    # vision
    var xp: DeviceBuffer[DType.float32]
    var vx: DeviceBuffer[DType.float32]
    var vxn: DeviceBuffer[DType.float32]
    var vqkv: DeviceBuffer[DType.float32]
    var vatt: DeviceBuffer[DType.float32]
    var vh: DeviceBuffer[DType.float32]
    # prefix
    var tx: DeviceBuffer[DType.float32]
    var txn: DeviceBuffer[DType.float32]
    var tqkv: DeviceBuffer[DType.float32]
    var tatt: DeviceBuffer[DType.float32]
    var tgu: DeviceBuffer[DType.float32]
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]
    # expert
    var sp: DeviceBuffer[DType.float32]
    var at: DeviceBuffer[DType.float32]
    var eh: DeviceBuffer[DType.float32]
    var xe: DeviceBuffer[DType.float32]
    var xen: DeviceBuffer[DType.float32]
    var eqkv: DeviceBuffer[DType.float32]
    var eatt: DeviceBuffer[DType.float32]
    var egu: DeviceBuffer[DType.float32]
    var vt: DeviceBuffer[DType.float32]
    # tables and masks
    var rcos: DeviceBuffer[DType.float32]
    var rsin: DeviceBuffer[DType.float32]
    var temb: DeviceBuffer[DType.float32]
    var klev: DeviceBuffer[DType.float32]
    var qlev: DeviceBuffer[DType.float32]
    var eqlev: DeviceBuffer[DType.float32]
    var ppos: DeviceBuffer[DType.int32]
    var epos: DeviceBuffer[DType.int32]
    var prefix_valid: Int
    var ksplit: Int  # the expert's attention: key splits (0: one workgroup a head and chunk)
    var apart: DeviceBuffer[DType.float32]  # its partial O, row maxima and sums
    var aml: DeviceBuffer[DType.float32]
    var prof: Dict[String, Float64]
    var profiling: Bool
    var last: Float64

    def __init__(out self, ctx: DeviceContext, path: String) raises:
        self.ctx = ctx
        self.w = Weights[DType.uint16, False](ctx)
        self.s = Scratch(ctx, XA_SIZE, PART_SIZE, 0, SK_ROWS, SPLIT_TARGET, SPLIT_BELOW, ACT_FIRST)
        self.path = path
        self.embed_offset = 0
        self.pix = ctx.enqueue_create_buffer[DType.float32](NCAM * 3 * IMG * IMG)
        self.lang = List[Float32](length=NLANG * D, fill=0)
        self.st = ctx.enqueue_create_buffer[DType.float32](AROWS * ADIM)
        self.xt = ctx.enqueue_create_buffer[DType.float32](AROWS * ADIM)
        self.xp = ctx.enqueue_create_buffer[DType.float32](VROWS * KP)
        self.vx = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vxn = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vqkv = ctx.enqueue_create_buffer[DType.float32](VROWS * 3 * VD + 64)  # + 64: the last head's 16-column V
        self.vatt = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vh = ctx.enqueue_create_buffer[DType.float32](VROWS * VFP)
        self.tx = ctx.enqueue_create_buffer[DType.float32](PROWS * D)
        self.txn = ctx.enqueue_create_buffer[DType.float32](PROWS * D)
        self.tqkv = ctx.enqueue_create_buffer[DType.float32](PROWS * QKV)
        self.tatt = ctx.enqueue_create_buffer[DType.float32](PROWS * H * HD)
        self.tgu = ctx.enqueue_create_buffer[DType.float32](PROWS * 2 * F)
        self.kc = List[DeviceBuffer[DType.float32]]()
        self.vc = List[DeviceBuffer[DType.float32]]()
        for l in range(L):
            self.kc.append(ctx.enqueue_create_buffer[DType.float32](KVROWS * HD))
            self.vc.append(ctx.enqueue_create_buffer[DType.float32](KVROWS * HD))
            ctx.enqueue_memset(self.kc[l], Float32(0))
            ctx.enqueue_memset(self.vc[l], Float32(0))
        self.sp = ctx.enqueue_create_buffer[DType.float32](AROWS * ED)
        self.at = ctx.enqueue_create_buffer[DType.float32](AROWS * 2 * ED)
        self.eh = ctx.enqueue_create_buffer[DType.float32](AROWS * ED)
        self.xe = ctx.enqueue_create_buffer[DType.float32](AROWS * ED)
        self.xen = ctx.enqueue_create_buffer[DType.float32](AROWS * ED)
        self.eqkv = ctx.enqueue_create_buffer[DType.float32](AROWS * QKV)
        self.eatt = ctx.enqueue_create_buffer[DType.float32](AROWS * H * HD)
        self.egu = ctx.enqueue_create_buffer[DType.float32](AROWS * 2 * EF)
        self.vt = ctx.enqueue_create_buffer[DType.float32](AROWS * 64)
        self.rcos = ctx.enqueue_create_buffer[DType.float32](MAXPOS * HD // 2)
        self.rsin = ctx.enqueue_create_buffer[DType.float32](MAXPOS * HD // 2)
        self.temb = ctx.enqueue_create_buffer[DType.float32](STEPS * ED)
        self.klev = ctx.enqueue_create_buffer[DType.float32](KVROWS)
        self.qlev = ctx.enqueue_create_buffer[DType.float32](PROWS)
        self.eqlev = ctx.enqueue_create_buffer[DType.float32](AROWS)
        self.ppos = ctx.enqueue_create_buffer[DType.int32](PROWS)
        self.epos = ctx.enqueue_create_buffer[DType.int32](AROWS)
        self.prefix_valid = 0
        self.ksplit = KSPLIT
        self.apart = ctx.enqueue_create_buffer[DType.float32](H * (HD // 64) * MAXSPLIT * 64 * 64)
        self.aml = ctx.enqueue_create_buffer[DType.float32](H * (HD // 64) * MAXSPLIT * 128)
        self.prof = Dict[String, Float64]()
        self.profiling = False
        self.last = 0
        for buf in [self.st, self.xt, self.at, self.eh, self.xe, self.xen, self.eqkv, self.eatt, self.egu, self.tx]:
            ctx.enqueue_memset(buf, Float32(0))
        self.load(path)
        self.time_embedding()

    # ---- weights -------------------------------------------------------------------------------------------

    def load(mut self, path: String) raises:
        var ck = Checkpoint(path)
        var f = open(path, "r")
        var pe = VP + "embeddings."
        self.w.upload(ck, f, "patch.w", one(pe + "patch_embedding.weight"), KP, mode=AUTO)
        self.w.upload(ck, f, "patch.b", one(pe + "patch_embedding.bias"), mode=WIDE)
        self.w.upload(ck, f, "pos", one(pe + "position_embedding.weight"), mode=WIDE)
        for l in range(VL):
            var p = VP + "encoder.layers." + String(l) + "."
            var v = "v" + String(l) + "."
            for nm in ["layer_norm1.weight", "layer_norm1.bias", "layer_norm2.weight", "layer_norm2.bias",
                       "self_attn.out_proj.bias", "mlp.fc1.bias", "mlp.fc2.bias"]:
                self.w.upload(ck, f, v + String(nm), one(p + String(nm)), mode=WIDE)
            self.w.upload(ck, f, v + "qkv.w", [p + "self_attn.q_proj.weight", p + "self_attn.k_proj.weight",
                                          p + "self_attn.v_proj.weight"], VD, mode=AUTO)
            self.w.upload(ck, f, v + "qkv.b", [p + "self_attn.q_proj.bias", p + "self_attn.k_proj.bias",
                                          p + "self_attn.v_proj.bias"], mode=WIDE)
            self.w.upload(ck, f, v + "o.w", one(p + "self_attn.out_proj.weight"), VD, mode=AUTO)
            self.w.upload(ck, f, v + "fc1.w", one(p + "mlp.fc1.weight"), VD, mode=AUTO)
            self.w.upload(ck, f, v + "fc2.w", one(p + "mlp.fc2.weight"), VF, mode=AUTO)
        self.w.upload(ck, f, "post.w", one(VP + "post_layernorm.weight"), mode=WIDE)
        self.w.upload(ck, f, "post.b", one(VP + "post_layernorm.bias"), mode=WIDE)
        var mm = "paligemma_with_expert.paligemma.model.multi_modal_projector.linear."
        self.w.upload(ck, f, "proj.w", one(mm + "weight"), VD, mode=AUTO)
        self.w.upload(ck, f, "proj.b", one(mm + "bias"), mode=WIDE)
        for l in range(L):
            for which in range(2):  # Gemma 2B, then the expert
                var p = (GP if which == 0 else EP) + "layers." + String(l) + "."
                var t = ("g" if which == 0 else "e") + String(l) + "."
                var width = D if which == 0 else ED
                self.w.upload(ck, f, t + "in", one(p + "input_layernorm.weight"), mode=WIDE)
                self.w.upload(ck, f, t + "post", one(p + "post_attention_layernorm.weight"), mode=WIDE)
                self.w.upload(ck, f, t + "qkv", [p + "self_attn.q_proj.weight", p + "self_attn.k_proj.weight",
                                            p + "self_attn.v_proj.weight"], width, mode=AUTO)
                self.w.upload(ck, f, t + "o", one(p + "self_attn.o_proj.weight"), H * HD, mode=AUTO)
                self.w.upload(ck, f, t + "gate", one(p + "mlp.gate_proj.weight"), width, mode=AUTO)
                self.w.upload(ck, f, t + "up", one(p + "mlp.up_proj.weight"), width, mode=AUTO)
                self.w.upload(ck, f, t + "down", one(p + "mlp.down_proj.weight"), F if which == 0 else EF, mode=AUTO)
        self.w.upload(ck, f, "enorm", one(EP + "norm.weight"), mode=WIDE)
        var kdim: List[Int] = [ADIM, ADIM, ED, 2 * ED, ED]
        var projs: List[String] = ["state_proj", "action_in_proj", "action_out_proj", "action_time_mlp_in",
                                   "action_time_mlp_out"]
        for i in range(len(projs)):
            self.w.upload(ck, f, projs[i] + ".w", one(projs[i] + ".weight"), kdim[i], mode=AUTO)
            self.w.upload(ck, f, projs[i] + ".b", one(projs[i] + ".bias"), mode=WIDE)
        f.close()
        if ck.dtypes[EMBED] != "F32":
            raise Error("the embedding is not fp32")
        self.embed_offset = ck.offsets[EMBED]

    def time_embedding(mut self) raises:
        """Each Euler step's time embedding, as lerobot's create_sinusoidal_pos_embedding computes it on the CPU
        (float64; t = 1 + s * -0.1 rounded to fp32 first), min period 4e-3, max period 4."""
        var host = List[Float32](length=STEPS * ED, fill=0)
        comptime HALF = ED // 2
        for s in range(STEPS):
            var t = Float64(Float32(1.0 + Float64(s) * (-1.0 / Float64(STEPS))))
            for i in range(HALF):
                var step = 1.0 / Float64(HALF - 1)
                var frac = Float64(i) * step if i < HALF // 2 else 1.0 - Float64(HALF - 1 - i) * step
                var period = 0.004 * (4.0 / 0.004) ** frac
                var x = 1.0 / period * 2.0 * 3.141592653589793 * t
                host[s * ED + i] = Float32(sin(x))
                host[s * ED + HALF + i] = Float32(cos(x))
        self.ctx.enqueue_copy(self.temb, host.unsafe_ptr())
        self.ctx.synchronize()

    # ---- inputs --------------------------------------------------------------------------------------------

    def set_inputs(mut self, pixels: List[Float32], tokens: List[Int32], lang_mask: List[Int32], state: List[Float32],
                   noise: List[Float32], rope: List[Float32]) raises:
        """The example: the images in [-1, 1], the task's token ids and mask, the state (32), the noise (50 x 32), and
        Gemma's RoPE table. The language rows are read from the checkpoint's embedding and scaled here; positions
        and mask levels follow from the language mask."""
        var ctx = self.ctx
        ctx.enqueue_copy(self.pix, pixels.unsafe_ptr())
        ctx.enqueue_copy(self.st.create_sub_buffer[DType.float32](0, ADIM), state.unsafe_ptr())
        ctx.enqueue_copy(self.xt.create_sub_buffer[DType.float32](0, CHUNK * ADIM), noise.unsafe_ptr())
        ctx.enqueue_copy(self.rcos, rope.unsafe_ptr())
        ctx.enqueue_copy(self.rsin, rope.unsafe_ptr() + MAXPOS * HD // 2)
        var f = open(self.path, "r")
        var scale = Float32(sqrt(Float64(D)))  # GemmaTextScaledWordEmbedding's embed_scale, fp32
        for r in range(NLANG):
            _ = f.seek(self.embed_offset + Int(tokens[r]) * D * 4)
            var row = f.read_bytes(D * 4)
            var src = row.unsafe_ptr().unsafe_bitcast[Float32]()
            for j in range(D):
                self.lang[r * D + j] = src[j] * scale
        f.close()
        var klev = List[Float32](length=KVROWS, fill=INF)
        var qlev = List[Float32](length=PROWS, fill=-1)
        var ppos = List[Int32](length=PROWS, fill=0)
        var valid = 0
        for r in range(PLEN):  # cumsum(pad_masks) - 1
            var ok = r < VROWS or lang_mask[r - VROWS] != 0
            if ok:
                valid += 1
                klev[r] = 0
                qlev[r] = 0
            ppos[r] = Int32(max(valid - 1, 0))
        var eqlev = List[Float32](length=AROWS, fill=-1)
        var epos = List[Int32](length=AROWS, fill=0)
        for i in range(AROWS):  # the actions in rows 0..49 (positions after the state's), the state in row 50
            if i < CHUNK:
                epos[i] = Int32(valid + 1 + i)
                eqlev[i] = 2
                klev[PROWS + i] = 2
            elif i == STATE_ROW:
                epos[i] = Int32(valid)
                eqlev[i] = 1
                klev[PROWS + i] = 1
            else:
                epos[i] = Int32(valid + i)
        ctx.enqueue_copy(self.klev, klev.unsafe_ptr())
        ctx.enqueue_copy(self.qlev, qlev.unsafe_ptr())
        ctx.enqueue_copy(self.eqlev, eqlev.unsafe_ptr())
        ctx.enqueue_copy(self.ppos, ppos.unsafe_ptr())
        ctx.enqueue_copy(self.epos, epos.unsafe_ptr())
        ctx.synchronize()
        self.prefix_valid = valid

    # ---- launches ------------------------------------------------------------------------------------------

    def lin[ACT: Int, BIAS: Bool, RES: Bool](self, w: String, b: String, x: DeviceBuffer[DType.float32],
                                             y: DeviceBuffer[DType.float32], rows: Int, n: Int, k: Int, ldx: Int,
                                             ldy: Int, xoff: Int = 0) raises:
        lin[DType.uint16, False, ACT, BIAS, RES](self.w, self.s, w, b, x, y, rows, n, k, ldx, ldy, xoff)

    def rmsnorm(self, x: DeviceBuffer[DType.float32], w: String, y: DeviceBuffer[DType.float32], rows: Int,
                d: Int) raises:
        """Gemma's RMSNorm: x / rms(x) * (1 + w)."""
        self.ctx.enqueue_function[vrow.rmsnorm[DType.float32]](x, self.w.floats[w], y, Int32(d), Int32(d), Int32(d),
                                                               EPS_G, Float32(1), grid_dim=rows, block_dim=64)

    def layernorm(self, x: DeviceBuffer[DType.float32], w: String, b: String, y: DeviceBuffer[DType.float32]) raises:
        self.ctx.enqueue_function[vrow.layernorm[DType.float32]](x, self.w.floats[w], self.w.floats[b], y, Int32(VD),
                                                                 Int32(VD), Int32(VD), EPS_V, grid_dim=VROWS,
                                                                 block_dim=64)

    def tick(mut self, label: String) raises:
        """Profiling: wait for the launches so far and charge their time to `label`."""
        if not self.profiling:
            return
        self.ctx.synchronize()
        var t = now_ms()
        self.prof[label] = self.prof.get(label, 0.0) + t - self.last
        self.last = t

    # ---- the forward pass ----------------------------------------------------------------------------------

    def vision(mut self) raises:
        """The images through SigLIP So400m; the post-layernorm output in self.vxn."""
        var ctx = self.ctx
        ctx.enqueue_function[vrow.patchify](self.pix, self.xp, Int32(IMG), Int32(PATCH), Int32(VROWS * KP),
                                            grid_dim=groups(VROWS * KP, 256), block_dim=256)
        self.lin[NONE, True, False]("patch.w", "patch.b", self.xp, self.vx, VROWS, VD, KP, KP, VD)
        ctx.enqueue_function[vrow.add_rows[DType.float32]](self.vx, self.w.floats["pos"], Int32(NPATCH), Int32(VD),
                                                           Int32(VROWS * VD), grid_dim=groups(VROWS * VD, 256),
                                                           block_dim=256)
        self.tick("v.patch")
        var scale = Float32(1 / sqrt(Float64(VHD)))
        for l in range(VL):
            var v = "v" + String(l) + "."
            self.layernorm(self.vx, v + "layer_norm1.weight", v + "layer_norm1.bias", self.vxn)
            self.tick("v.norm")
            self.lin[NONE, True, False](v + "qkv.w", v + "qkv.b", self.vxn, self.vqkv, VROWS, 3 * VD, VD, VD, 3 * VD)
            self.tick("v.qkv")
            attend[False, VHD](ctx, self.vqkv, self.vqkv, self.vqkv, self.vatt, self.klev, self.qlev, 3 * VD,
                               3 * VD, VD, VD, 2 * VD, NPATCH, VH, 1, NPATCH, NCAM, NPATCH, scale)
            self.tick("v.attention")
            self.lin[NONE, True, True](v + "o.w", v + "self_attn.out_proj.bias", self.vatt, self.vx, VROWS, VD, VD, VD,
                                       VD)
            self.tick("v.o")
            self.layernorm(self.vx, v + "layer_norm2.weight", v + "layer_norm2.bias", self.vxn)
            self.tick("v.norm")
            self.lin[NONE, True, False](v + "fc1.w", v + "mlp.fc1.bias", self.vxn, self.vh, VROWS, VF, VD, VD, VFP)
            self.tick("v.fc1")
            self.lin[GELU, True, True](v + "fc2.w", v + "mlp.fc2.bias", self.vh, self.vx, VROWS, VD, VF, VFP, VD)
            self.tick("v.fc2")
        self.layernorm(self.vx, "post.w", "post.b", self.vxn)
        self.tick("v.norm")

    def embed(mut self) raises:
        """The prefix rows in self.tx: each camera's 256 image tokens (the projector), the 48 language rows."""
        self.lin[NONE, True, False]("proj.w", "proj.b", self.vxn, self.tx, VROWS, D, VD, VD, D)
        self.ctx.enqueue_copy(self.tx.create_sub_buffer[DType.float32](VROWS * D, NLANG * D), self.lang.unsafe_ptr())
        self.tick("c.projector+language")

    def prefix(mut self) raises:
        """The prefix through Gemma 2B's 18 layers: every layer's K (after RoPE) and V in rows 0..895 of
        self.kc / self.vc."""
        var ctx = self.ctx
        for l in range(L):
            var g = "g" + String(l) + "."
            self.rmsnorm(self.tx, g + "in", self.txn, PROWS, D)
            self.tick("g.norm")
            self.lin[NONE, False, False](g + "qkv", "", self.txn, self.tqkv, PROWS, QKV, D, D, QKV)
            self.tick("g.qkv")
            ctx.enqueue_function[vrow.rope_qk](self.tqkv, self.rcos, self.rsin, self.ppos, self.kc[l], self.vc[l],
                                               Int32(QKV), Int32(H), Int32(1), Int32(HD), Int32(0), Int32(HD),
                                               grid_dim=PROWS, block_dim=64)
            self.tick("g.rope")
            if l == L - 1:
                break  # the last layer's output is not used, only its K and V
            attend[True, HD](ctx, self.tqkv, self.kc[l], self.vc[l], self.tatt, self.klev, self.qlev, QKV, HD, H * HD,
                             0, 0, PROWS, H, H, PROWS, 1, 0, Float32(0.0625))
            self.tick("g.attention")
            self.lin[NONE, False, True](g + "o", "", self.tatt, self.tx, PROWS, D, H * HD, H * HD, D)
            self.tick("g.o")
            self.rmsnorm(self.tx, g + "post", self.txn, PROWS, D)
            self.tick("g.norm")
            self.lin[NONE, False, False](g + "gate", "", self.txn, self.tgu, PROWS, F, D, D, 2 * F)
            self.lin[NONE, False, False](g + "up", "", self.txn, self.tgu.create_sub_buffer[DType.float32](F, (PROWS - 1) * 2 * F + F),
                                         PROWS, F, D, D, 2 * F)
            self.tick("g.gate_up")
            self.lin[GELU_MUL, False, True](g + "down", "", self.tgu, self.tx, PROWS, D, F, 2 * F, D, xoff=F)
            self.tick("g.down")
            ctx.synchronize()  # one layer a submission: 64 of these launches outlast the GPU watchdog

    def step(mut self, s: Int) raises:
        """Euler step s: the expert's velocity for x_t at t = 1 - s / 10 into self.vt, then x_t += -0.1 v_t."""
        var ctx = self.ctx
        self.lin[NONE, True, False]("action_in_proj.w", "action_in_proj.b", self.xt, self.at, AROWS, ED, ADIM, ADIM,
                                    2 * ED)
        ctx.enqueue_function[vrow.fill_cols](self.at, self.temb, Int32(2 * ED), Int32(ED), Int32(ED), Int32(s * ED),
                                             Int32(AROWS * ED), grid_dim=groups(AROWS * ED, 256), block_dim=256)
        self.lin[NONE, True, False]("action_time_mlp_in.w", "action_time_mlp_in.b", self.at, self.eh, AROWS, ED,
                                    2 * ED, 2 * ED, ED)
        self.lin[SILU, True, False]("action_time_mlp_out.w", "action_time_mlp_out.b", self.eh, self.xe, AROWS, ED,
                                    ED, ED, ED)
        self.lin[NONE, True, False]("state_proj.w", "state_proj.b", self.st, self.sp, AROWS, ED, ADIM, ADIM, ED)
        ctx.enqueue_copy(self.xe.create_sub_buffer[DType.float32](STATE_ROW * ED, ED),
                         self.sp.create_sub_buffer[DType.float32](0, ED))
        self.tick("e.suffix")
        for l in range(L):
            var e = "e" + String(l) + "."
            self.rmsnorm(self.xe, e + "in", self.xen, AROWS, ED)
            self.tick("e.norm")
            self.lin[NONE, False, False](e + "qkv", "", self.xen, self.eqkv, AROWS, QKV, ED, ED, QKV)
            self.tick("e.qkv")
            ctx.enqueue_function[vrow.rope_qk](self.eqkv, self.rcos, self.rsin, self.epos, self.kc[l], self.vc[l],
                                               Int32(QKV), Int32(H), Int32(1), Int32(HD), Int32(PROWS), Int32(HD),
                                               grid_dim=AROWS, block_dim=64)
            self.tick("e.rope")
            if self.ksplit > 0:  # 64 query rows against 960 keys: split the keys across workgroups
                attend_split[True, HD](ctx, self.eqkv, self.kc[l], self.vc[l], self.eatt, self.klev, self.eqlev,
                                       self.apart, self.aml, QKV, HD, H * HD, 0, 0, KVROWS, H, H, self.ksplit,
                                       Float32(0.0625))
            else:
                attend[True, HD](ctx, self.eqkv, self.kc[l], self.vc[l], self.eatt, self.klev, self.eqlev, QKV, HD,
                                 H * HD, 0, 0, KVROWS, H, H, AROWS, 1, 0, Float32(0.0625))
            self.tick("e.attention")
            self.lin[NONE, False, True](e + "o", "", self.eatt, self.xe, AROWS, ED, H * HD, H * HD, ED)
            self.tick("e.o")
            self.rmsnorm(self.xe, e + "post", self.xen, AROWS, ED)
            self.tick("e.norm")
            self.lin[NONE, False, False](e + "gate", "", self.xen, self.egu, AROWS, EF, ED, ED, 2 * EF)
            self.lin[NONE, False, False](e + "up", "", self.xen,
                                         self.egu.create_sub_buffer[DType.float32](EF, (AROWS - 1) * 2 * EF + EF),
                                         AROWS, EF, ED, ED, 2 * EF)
            self.tick("e.gate_up")
            self.lin[GELU_MUL, False, True](e + "down", "", self.egu, self.xe, AROWS, ED, EF, 2 * EF, ED, xoff=EF)
            self.tick("e.down")
        self.rmsnorm(self.xe, "enorm", self.xen, AROWS, ED)
        self.lin[NONE, True, False]("action_out_proj.w", "action_out_proj.b", self.xen, self.vt, AROWS, ADIM, ED, ED,
                                    64)
        ctx.enqueue_function[vrow.euler](self.xt, self.vt, Int32(ADIM), Int32(64), Int32(ADIM), Float32(-0.1),
                                         Int32(CHUNK * ADIM), grid_dim=groups(CHUNK * ADIM, 256), block_dim=256)
        self.tick("e.out")
