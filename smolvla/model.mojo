# SmolVLA (lerobot/smolvla_base) on the Adreno as MAX DeviceContext launches of the kernels in vla/kernels: the
# forward pass of lerobot's VLAFlowMatching.sample_actions, in Mojo. Weights straight from the checkpoint's
# model.safetensors (vla/safetensors.mojo). Three precisions:
#   bf16   (W16 = uint16, MMA16 = False) bf16 tensors stay bf16 and are widened exactly as the matmuls stage them,
#          fp32 ones stay fp32; the matrix units multiply and sum in fp32
#   fp16w  (W16 = float16, MMA16 = False) every weight rounded to fp16 at load; fp32 matrix units
#   fp16   (W16 = float16, MMA16 = True) fp16 weights, and every projection on the fp16 matrix units: its input
#          rounded to fp16, products and sums in fp16 (the 840 has no fp16 x fp16 -> fp32), then converted to
#          fp32 for the bias and the residual (vgemm.gemm16)
# Activations between kernels, attention, norms and the K/V cache are fp32 in all three.
#
#   vision()   three cameras' 512 x 512 images through SigLIP (12 layers of 768, 1024 patches each), batched as
#              3072 rows; attention per image
#   embed()    the connector (pixel shuffle 4, a projection to 960) times sqrt(960): 64 tokens an image; the
#              task's 48 tokens (padding included) times sqrt(960); the state's projection: 241 prefix rows
#   prefix()   the prefix through SmolLM2's first 16 layers, filling every layer's K/V cache (K after RoPE);
#              the cross-attention layers' K/V for the expert (its k_proj / v_proj of that cache)
#   step(s)    one Euler step of flow matching: the action expert (16 layers of 720, self-attention to the
#              prefix and the actions on even layers, cross-attention to the prefix's K/V on odd ones) gives
#              the velocity v_t of the 50 x 32 action chunk x_t at t = 1 - s / 10; x_t += -0.1 v_t
#
# Rows are padded to the matmuls' 64: the prefix to 256 (rows 241..255 zero), the chunk to 64 (rows 50..63
# zero). Attention masks are levels (vla/kernels/vattn.mojo): images and language 0, the state 1, action i
# 2 + i, padding never visible; queries see keys of their own level or lower, as make_att_2d_masks does.
from std.collections import Dict
from std.math import cos, sin, sqrt
from std.memory import bitcast
from std.time import perf_counter_ns
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

from host import NATIVE, WIDE, Scratch, Weights, attend, groups, lin, one
from safetensors import Checkpoint
import vrow
from vgemm import GELU, NONE, SILU, SILU_MUL

comptime IMG = 512
comptime PATCH = 16
comptime GRID = 32  # patches a side
comptime NPATCH = GRID * GRID
comptime NCAM = 3
comptime VROWS = NCAM * NPATCH
comptime VD = 768
comptime VF = 3072
comptime VL = 12
comptime VH = 12
comptime SHUFFLE = 4
comptime NIMG = NPATCH // (SHUFFLE * SHUFFLE)  # tokens an image: 64
comptime SD = VD * SHUFFLE * SHUFFLE  # 12288
comptime TD = 960
comptime TL = 16  # SmolVLA keeps the first 16 of SmolLM2's 32 layers
comptime TH = 15
comptime TKV = 5
comptime HD = 64
comptime TQKV = (TH + 2 * TKV) * HD  # 1600
comptime TF = 2560
comptime NLANG = 48
comptime PLEN = NCAM * NIMG + NLANG + 1  # 241 prefix rows
comptime PROWS = 256
comptime ED = 720
comptime EDP = 768  # the expert's rows, ED rounded up to the matmuls' 64
comptime EF = 2048
comptime CHUNK = 50
comptime AROWS = 64
comptime ADIM = 32
comptime STEPS = 10
comptime KVROWS = PROWS + AROWS  # a layer's cache: the prefix, then the actions (self-attention layers)
comptime KVD = TKV * HD  # 320
comptime MAXPOS = 512
comptime EPS_V: Float32 = 1e-6
comptime EPS_T: Float32 = 1e-5
comptime SCALE: Float32 = 0.125  # 1 / sqrt(64)
comptime INF: Float32 = 1e30
comptime SK_ROWS = 256  # projections of at most this many rows take the split-k path (vgemm.gemm_sk)
comptime XA_SIZE = VROWS * VF
comptime PART_SIZE = VROWS * VF

comptime VP = "model.vlm_with_expert.vlm.model.vision_model."
comptime TP = "model.vlm_with_expert.vlm.model.text_model."
comptime EP = "model.vlm_with_expert.lm_expert."


def now_ms() -> Float64:
    return Float64(perf_counter_ns()) / 1e6


struct SmolVLA[W16: DType, MMA16: Bool](Movable):
    """W16: the 16-bit weights' device type, DType.uint16 (bf16 bits, as in the checkpoint) or DType.float16;
    MMA16: the projections on the fp16 matrix units (W16 = float16)."""

    var ctx: DeviceContext
    var w: Weights[Self.W16, Self.MMA16]
    var s: Scratch
    # inputs
    var pix: DeviceBuffer[DType.float32]  # [3, 3, 512, 512]
    var tokens: DeviceBuffer[DType.int32]  # [48]
    var st: DeviceBuffer[DType.float32]  # [64, 32]: the state in row 0
    var xt: DeviceBuffer[DType.float32]  # [64, 32]: x_t, the noise to start with
    # vision
    var xp: DeviceBuffer[DType.float32]
    var vx: DeviceBuffer[DType.float32]
    var vxn: DeviceBuffer[DType.float32]
    var vqkv: DeviceBuffer[DType.float32]
    var vatt: DeviceBuffer[DType.float32]
    var vh: DeviceBuffer[DType.float32]
    var xs: DeviceBuffer[DType.float32]
    # language
    var tx: DeviceBuffer[DType.float32]
    var txn: DeviceBuffer[DType.float32]
    var tqkv: DeviceBuffer[DType.float32]
    var tatt: DeviceBuffer[DType.float32]
    var tgu: DeviceBuffer[DType.float32]
    var sp: DeviceBuffer[DType.float32]
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]
    var ck: List[DeviceBuffer[DType.float32]]  # the cross-attention layers' K and V (odd layers; even: unused)
    var cv: List[DeviceBuffer[DType.float32]]
    # expert
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
    var temb: DeviceBuffer[DType.float32]  # [10, 720]: each step's time embedding
    var klev: DeviceBuffer[DType.float32]  # [320]: the cache rows' levels
    var qlev: DeviceBuffer[DType.float32]  # [256]: the prefix rows'
    var eqlev: DeviceBuffer[DType.float32]  # [64]: the actions' in self-attention
    var cqlev: DeviceBuffer[DType.float32]  # [64]: the actions' in cross-attention
    var ppos: DeviceBuffer[DType.int32]
    var epos: DeviceBuffer[DType.int32]
    var cpos: DeviceBuffer[DType.int32]
    var prefix_valid: Int
    var prof: Dict[String, Float64]  # profiling: ms per kind of launch
    var profiling: Bool
    var last: Float64

    def __init__(out self, ctx: DeviceContext, path: String) raises:
        self.ctx = ctx
        self.w = Weights[Self.W16, Self.MMA16](ctx)
        self.s = Scratch(ctx, XA_SIZE, PART_SIZE, VROWS * VF if Self.MMA16 else 0, SK_ROWS)

        self.pix = ctx.enqueue_create_buffer[DType.float32](NCAM * 3 * IMG * IMG)
        self.tokens = ctx.enqueue_create_buffer[DType.int32](NLANG)
        self.st = ctx.enqueue_create_buffer[DType.float32](AROWS * ADIM)
        self.xt = ctx.enqueue_create_buffer[DType.float32](AROWS * ADIM)
        self.xp = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vx = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vxn = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vqkv = ctx.enqueue_create_buffer[DType.float32](VROWS * 3 * VD)
        self.vatt = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vh = ctx.enqueue_create_buffer[DType.float32](VROWS * VF)
        self.xs = ctx.enqueue_create_buffer[DType.float32](NCAM * NIMG * SD)
        self.tx = ctx.enqueue_create_buffer[DType.float32](PROWS * TD)
        self.txn = ctx.enqueue_create_buffer[DType.float32](PROWS * TD)
        self.tqkv = ctx.enqueue_create_buffer[DType.float32](PROWS * TQKV)
        self.tatt = ctx.enqueue_create_buffer[DType.float32](PROWS * TD)
        self.tgu = ctx.enqueue_create_buffer[DType.float32](PROWS * 2 * TF)
        self.sp = ctx.enqueue_create_buffer[DType.float32](AROWS * TD)
        self.kc = List[DeviceBuffer[DType.float32]]()
        self.vc = List[DeviceBuffer[DType.float32]]()
        self.ck = List[DeviceBuffer[DType.float32]]()
        self.cv = List[DeviceBuffer[DType.float32]]()
        for l in range(TL):
            self.kc.append(ctx.enqueue_create_buffer[DType.float32](KVROWS * KVD))
            self.vc.append(ctx.enqueue_create_buffer[DType.float32](KVROWS * KVD))
            ctx.enqueue_memset(self.kc[l], Float32(0))  # rows never written stay finite: P V reads them
            ctx.enqueue_memset(self.vc[l], Float32(0))
            var cross = l % 2 == 1
            self.ck.append(ctx.enqueue_create_buffer[DType.float32](PROWS * KVD if cross else 64))
            self.cv.append(ctx.enqueue_create_buffer[DType.float32](PROWS * KVD if cross else 64))
        self.at = ctx.enqueue_create_buffer[DType.float32](AROWS * 2 * ED)
        self.eh = ctx.enqueue_create_buffer[DType.float32](AROWS * EDP)
        self.xe = ctx.enqueue_create_buffer[DType.float32](AROWS * EDP)
        self.xen = ctx.enqueue_create_buffer[DType.float32](AROWS * EDP)
        self.eqkv = ctx.enqueue_create_buffer[DType.float32](AROWS * TQKV)
        self.eatt = ctx.enqueue_create_buffer[DType.float32](AROWS * TD)
        self.egu = ctx.enqueue_create_buffer[DType.float32](AROWS * 2 * EF)
        self.vt = ctx.enqueue_create_buffer[DType.float32](AROWS * 64)
        self.rcos = ctx.enqueue_create_buffer[DType.float32](MAXPOS * 32)
        self.rsin = ctx.enqueue_create_buffer[DType.float32](MAXPOS * 32)
        self.temb = ctx.enqueue_create_buffer[DType.float32](STEPS * ED)
        self.klev = ctx.enqueue_create_buffer[DType.float32](KVROWS)
        self.qlev = ctx.enqueue_create_buffer[DType.float32](PROWS)
        self.eqlev = ctx.enqueue_create_buffer[DType.float32](AROWS)
        self.cqlev = ctx.enqueue_create_buffer[DType.float32](AROWS)
        self.ppos = ctx.enqueue_create_buffer[DType.int32](PROWS)
        self.epos = ctx.enqueue_create_buffer[DType.int32](AROWS)
        self.cpos = ctx.enqueue_create_buffer[DType.int32](AROWS)
        self.prefix_valid = 0
        self.prof = Dict[String, Float64]()
        self.profiling = False
        self.last = 0
        for buf in [self.st, self.xt, self.at, self.eh, self.xe, self.xen, self.eqkv, self.eatt, self.egu]:
            ctx.enqueue_memset(buf, Float32(0))
        self.load(path)
        self.time_embedding()

    # ---- weights -------------------------------------------------------------------------------------------

    def load(mut self, path: String) raises:
        var ck = Checkpoint(path)
        var f = open(path, "r")

        var pe = VP + "embeddings."
        self.w.upload(ck, f, "patch.w", one(pe + "patch_embedding.weight"), VD)
        self.w.upload(ck, f, "patch.b", one(pe + "patch_embedding.bias"), mode=WIDE)
        self.w.upload(ck, f, "pos", one(pe + "position_embedding.weight"), mode=WIDE)
        for l in range(VL):
            var p = VP + "encoder.layers." + String(l) + "."
            var v = "v" + String(l) + "."
            self.w.upload(ck, f, v + "ln1.w", one(p + "layer_norm1.weight"), mode=WIDE)
            self.w.upload(ck, f, v + "ln1.b", one(p + "layer_norm1.bias"), mode=WIDE)
            self.w.upload(ck, f, v + "ln2.w", one(p + "layer_norm2.weight"), mode=WIDE)
            self.w.upload(ck, f, v + "ln2.b", one(p + "layer_norm2.bias"), mode=WIDE)
            self.w.upload(ck, f, v + "qkv.w", [p + "self_attn.q_proj.weight", p + "self_attn.k_proj.weight",
                                             p + "self_attn.v_proj.weight"], VD)
            self.w.upload(ck, f, v + "qkv.b", [p + "self_attn.q_proj.bias", p + "self_attn.k_proj.bias",
                                               p + "self_attn.v_proj.bias"], mode=WIDE)
            self.w.upload(ck, f, v + "o.w", one(p + "self_attn.out_proj.weight"), VD)
            self.w.upload(ck, f, v + "o.b", one(p + "self_attn.out_proj.bias"), mode=WIDE)
            self.w.upload(ck, f, v + "fc1.w", one(p + "mlp.fc1.weight"), VD)
            self.w.upload(ck, f, v + "fc1.b", one(p + "mlp.fc1.bias"), mode=WIDE)
            self.w.upload(ck, f, v + "fc2.w", one(p + "mlp.fc2.weight"), VF)
            self.w.upload(ck, f, v + "fc2.b", one(p + "mlp.fc2.bias"), mode=WIDE)
        self.w.upload(ck, f, "post.w", one(VP + "post_layernorm.weight"), mode=WIDE)
        self.w.upload(ck, f, "post.b", one(VP + "post_layernorm.bias"), mode=WIDE)
        self.w.upload(ck, f, "conn.w", one("model.vlm_with_expert.vlm.model.connector.modality_projection.proj.weight"), SD)
        self.w.upload(ck, f, "embed", one(TP + "embed_tokens.weight"))
        for l in range(TL):
            var p = TP + "layers." + String(l) + "."
            var t = "t" + String(l) + "."
            self.w.upload(ck, f, t + "in", one(p + "input_layernorm.weight"), mode=WIDE)
            self.w.upload(ck, f, t + "post", one(p + "post_attention_layernorm.weight"), mode=WIDE)
            self.w.upload(ck, f, t + "qkv", [p + "self_attn.q_proj.weight", p + "self_attn.k_proj.weight",
                                           p + "self_attn.v_proj.weight"], TD)
            self.w.upload(ck, f, t + "o", one(p + "self_attn.o_proj.weight"), TD)
            self.w.upload(ck, f, t + "gu", [p + "mlp.gate_proj.weight", p + "mlp.up_proj.weight"], TD)
            self.w.upload(ck, f, t + "down", one(p + "mlp.down_proj.weight"), TF)
        for l in range(TL):
            var p = EP + "layers." + String(l) + "."
            var e = "e" + String(l) + "."
            self.w.upload(ck, f, e + "in", one(p + "input_layernorm.weight"), mode=WIDE)
            self.w.upload(ck, f, e + "post", one(p + "post_attention_layernorm.weight"), mode=WIDE)
            if l % 2 == 0:
                self.w.upload(ck, f, e + "qkv", [p + "self_attn.q_proj.weight", p + "self_attn.k_proj.weight",
                                               p + "self_attn.v_proj.weight"], ED)
            else:
                self.w.upload(ck, f, e + "qkv", one(p + "self_attn.q_proj.weight"), ED)
                self.w.upload(ck, f, e + "ck", one(p + "self_attn.k_proj.weight"), KVD)
                self.w.upload(ck, f, e + "cv", one(p + "self_attn.v_proj.weight"), KVD)
            self.w.upload(ck, f, e + "o", one(p + "self_attn.o_proj.weight"), TD)
            self.w.upload(ck, f, e + "gu", [p + "mlp.gate_proj.weight", p + "mlp.up_proj.weight"], ED)
            self.w.upload(ck, f, e + "down", one(p + "mlp.down_proj.weight"), EF)
        self.w.upload(ck, f, "enorm", one(EP + "norm.weight"), mode=WIDE)
        var kdim: List[Int] = [ADIM, ADIM, ED, 2 * ED, ED]
        var projs: List[String] = ["state_proj", "action_in_proj", "action_out_proj", "action_time_mlp_in",
                                   "action_time_mlp_out"]
        for i in range(len(projs)):
            var nm = projs[i]
            self.w.upload(ck, f, nm + ".w", one("model." + nm + ".weight"), kdim[i])
            self.w.upload(ck, f, nm + ".b", one("model." + nm + ".bias"), mode=WIDE)
        f.close()

    def time_embedding(mut self) raises:
        """Each Euler step's time embedding, as lerobot's create_sinusoidal_pos_embedding computes it on the CPU
        (float64; t = 1 + s * -0.1 rounded to fp32 first), min period 4e-3, max period 4."""
        var host = List[Float32](length=STEPS * ED, fill=0)
        comptime HALF = ED // 2
        for s in range(STEPS):
            var t = Float64(Float32(1.0 + Float64(s) * (-1.0 / Float64(STEPS))))
            for i in range(HALF):
                var step = 1.0 / Float64(HALF - 1)  # torch.linspace(0, 1, 360), float64
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
        """The example: the preprocessed images, the task's tokens and mask, the state (32), the noise (50 x 32);
        and apply_rope's table. Positions and mask levels follow from the language mask."""
        var ctx = self.ctx
        ctx.enqueue_copy(self.pix, pixels.unsafe_ptr())
        ctx.enqueue_copy(self.tokens, tokens.unsafe_ptr())
        ctx.enqueue_copy(self.st.create_sub_buffer[DType.float32](0, ADIM), state.unsafe_ptr())
        ctx.enqueue_copy(self.xt.create_sub_buffer[DType.float32](0, CHUNK * ADIM), noise.unsafe_ptr())
        ctx.enqueue_copy(self.rcos, rope.unsafe_ptr())
        ctx.enqueue_copy(self.rsin, rope.unsafe_ptr() + MAXPOS * 32)
        var klev = List[Float32](length=KVROWS, fill=INF)
        var qlev = List[Float32](length=PROWS, fill=-1)
        var ppos = List[Int32](length=PROWS, fill=0)
        var valid = 0
        for r in range(PLEN):  # cumsum(pad_masks) - 1; padding keeps the previous position
            var ok = r < NCAM * NIMG or r == PLEN - 1 or lang_mask[r - NCAM * NIMG] != 0
            if ok:
                valid += 1
            ppos[r] = Int32(max(valid - 1, 0))
            var level = Float32(1) if r == PLEN - 1 else Float32(0)
            if ok:
                klev[r] = level
                qlev[r] = level
        var eqlev = List[Float32](length=AROWS, fill=-1)
        var cqlev = List[Float32](length=AROWS, fill=-1)
        var epos = List[Int32](length=AROWS, fill=0)
        var cpos = List[Int32](length=AROWS, fill=0)
        for i in range(AROWS):
            epos[i] = Int32(valid + i)  # prefix_offsets + cumsum(suffix_pad) - 1
            cpos[i] = Int32(i)  # the cross layers' positions start from 0
            if i < CHUNK:
                klev[PROWS + i] = Float32(2 + i)
                eqlev[i] = Float32(2 + i)
                cqlev[i] = 1  # the whole valid prefix, state included
        ctx.enqueue_copy(self.klev, klev.unsafe_ptr())
        ctx.enqueue_copy(self.qlev, qlev.unsafe_ptr())
        ctx.enqueue_copy(self.eqlev, eqlev.unsafe_ptr())
        ctx.enqueue_copy(self.cqlev, cqlev.unsafe_ptr())
        ctx.enqueue_copy(self.ppos, ppos.unsafe_ptr())
        ctx.enqueue_copy(self.epos, epos.unsafe_ptr())
        ctx.enqueue_copy(self.cpos, cpos.unsafe_ptr())
        ctx.synchronize()
        self.prefix_valid = valid

    # ---- launches ------------------------------------------------------------------------------------------

    def lin[ACT: Int, BIAS: Bool, RES: Bool](self, w: String, b: String, x: DeviceBuffer[DType.float32],
                                             y: DeviceBuffer[DType.float32], rows: Int, n: Int, k: Int, ldx: Int,
                                             ldy: Int, xoff: Int = 0, alpha: Float32 = 1.0) raises:
        """y[:rows, :n] = act(alpha x) W^T (+ b) (+ y): host.lin."""
        lin[Self.W16, Self.MMA16, ACT, BIAS, RES](self.w, self.s, w, b, x, y, rows, n, k, ldx, ldy, xoff, alpha)

    def layernorm(self, x: DeviceBuffer[DType.float32], w: String, b: String, y: DeviceBuffer[DType.float32],
                  rows: Int, ld: Int, d: Int, eps: Float32) raises:
        self.ctx.enqueue_function[vrow.layernorm[DType.float32]](x, self.w.floats[w], self.w.floats[b], y, Int32(ld),
                                                                 Int32(ld),
                                                            Int32(d), eps, grid_dim=rows, block_dim=64)

    def rmsnorm(self, x: DeviceBuffer[DType.float32], w: String, y: DeviceBuffer[DType.float32], rows: Int, ld: Int,
                d: Int) raises:
        self.ctx.enqueue_function[vrow.rmsnorm[DType.float32]](x, self.w.floats[w], y, Int32(ld), Int32(ld), Int32(d),
                                                               EPS_T,
                                                          Float32(0),
                                                          grid_dim=rows, block_dim=64)

    def attention[MASK: Bool](self, q: DeviceBuffer[DType.float32], k: DeviceBuffer[DType.float32],
                              v: DeviceBuffer[DType.float32], o: DeviceBuffer[DType.float32],
                              klev: DeviceBuffer[DType.float32], qlev: DeviceBuffer[DType.float32], ldq: Int, ldk: Int,
                              ldo: Int, kcol: Int, vcol: Int, nk: Int, heads: Int, group: Int, qrows: Int,
                              batches: Int, batch_rows: Int) raises:
        attend[MASK, HD](self.ctx, q, k, v, o, klev, qlev, ldq, ldk, ldo, kcol, vcol, nk, heads, group, qrows, batches,
                         batch_rows, SCALE)

    def elementwise_grid(self, total: Int) -> Int:
        return groups(total, 256)

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
        """The images (self.pix) through SigLIP; the post-layernorm output in self.vxn."""
        var ctx = self.ctx
        ctx.enqueue_function[vrow.patchify](self.pix, self.xp, Int32(IMG), Int32(PATCH), Int32(VROWS * VD),
                                            grid_dim=groups(VROWS * VD, 256), block_dim=256)
        self.tick("v.patch")
        self.lin[NONE, True, False]("patch.w", "patch.b", self.xp, self.vx, VROWS, VD, VD, VD, VD)
        self.tick("v.patch")
        ctx.enqueue_function[vrow.add_rows[DType.float32]](self.vx, self.w.floats["pos"], Int32(NPATCH), Int32(VD),
                                                      Int32(VROWS * VD), grid_dim=groups(VROWS * VD, 256),
                                                      block_dim=256)
        self.tick("v.patch")
        for l in range(VL):
            var v = "v" + String(l) + "."
            self.layernorm(self.vx, v + "ln1.w", v + "ln1.b", self.vxn, VROWS, VD, VD, EPS_V)
            self.tick("v.norm")
            self.lin[NONE, True, False](v + "qkv.w", v + "qkv.b", self.vxn, self.vqkv, VROWS, 3 * VD, VD, VD, 3 * VD)
            self.tick("v.qkv")
            self.attention[False](self.vqkv, self.vqkv, self.vqkv, self.vatt, self.klev, self.qlev, 3 * VD, 3 * VD,
                                  VD, VD, 2 * VD, NPATCH, VH, 1, NPATCH, NCAM, NPATCH)
            self.tick("v.attention")
            self.lin[NONE, True, True](v + "o.w", v + "o.b", self.vatt, self.vx, VROWS, VD, VD, VD, VD)
            self.tick("v.o")
            self.layernorm(self.vx, v + "ln2.w", v + "ln2.b", self.vxn, VROWS, VD, VD, EPS_V)
            self.tick("v.norm")
            self.lin[NONE, True, False](v + "fc1.w", v + "fc1.b", self.vxn, self.vh, VROWS, VF, VD, VD, VF)
            self.tick("v.fc1")
            self.lin[GELU, True, True](v + "fc2.w", v + "fc2.b", self.vh, self.vx, VROWS, VD, VF, VF, VD)
            self.tick("v.fc2")
        self.layernorm(self.vx, "post.w", "post.b", self.vxn, VROWS, VD, VD, EPS_V)
        self.tick("v.norm")

    def embed(mut self) raises:
        """The prefix rows in self.tx: each camera's 64 image tokens, the 48 language rows, the state."""
        var ctx = self.ctx
        var root = Float32(sqrt(Float64(TD)))
        ctx.enqueue_memset(self.tx, Float32(0))
        ctx.enqueue_function[vrow.pixel_shuffle](self.vxn, self.xs, Int32(GRID), Int32(VD), Int32(SHUFFLE),
                                                 Int32(NCAM * NIMG * SD), grid_dim=groups(NCAM * NIMG * SD, 256),
                                                 block_dim=256)
        self.tick("c.shuffle")
        self.lin[NONE, False, False]("conn.w", "", self.xs, self.tx, NCAM * NIMG, TD, SD, SD, TD, alpha=root)
        self.tick("c.projection")
        ctx.enqueue_function[vrow.embed_rows[Self.W16]](
            self.w.halves["embed"], self.tokens, self.tx.create_sub_buffer[DType.float32](NCAM * NIMG * TD, NLANG * TD),
            Int32(TD), Int32(TD), root, grid_dim=NLANG, block_dim=64)
        self.lin[NONE, True, False]("state_proj.w", "state_proj.b", self.st, self.sp, AROWS, TD, ADIM, ADIM, TD)
        ctx.enqueue_copy(self.tx.create_sub_buffer[DType.float32]((PLEN - 1) * TD, TD),
                         self.sp.create_sub_buffer[DType.float32](0, TD))
        self.tick("c.language+state")

    def prefix(mut self) raises:
        """The prefix through the 16 language layers: every layer's K (after RoPE) and V in rows 0..255 of
        self.kc / self.vc; then the cross-attention layers' K and V for the expert in self.ck / self.cv."""
        var ctx = self.ctx
        for l in range(TL):
            var t = "t" + String(l) + "."
            self.rmsnorm(self.tx, t + "in", self.txn, PROWS, TD, TD)
            self.tick("t.norm")
            self.lin[NONE, False, False](t + "qkv", "", self.txn, self.tqkv, PROWS, TQKV, TD, TD, TQKV)
            self.tick("t.qkv")
            ctx.enqueue_function[vrow.rope_qk](self.tqkv, self.rcos, self.rsin, self.ppos, self.kc[l], self.vc[l],
                                               Int32(TQKV), Int32(TH), Int32(TKV), Int32(KVD), Int32(0), Int32(HD),
                                               grid_dim=PROWS, block_dim=64)
            self.tick("t.rope")
            if l == TL - 1:
                break  # the last layer's output is not used, only its K and V
            self.attention[True](self.tqkv, self.kc[l], self.vc[l], self.tatt, self.klev, self.qlev, TQKV, KVD, TD,
                                 0, 0, PROWS, TH, TH // TKV, PROWS, 1, 0)
            self.tick("t.attention")
            self.lin[NONE, False, True](t + "o", "", self.tatt, self.tx, PROWS, TD, TD, TD, TD)
            self.tick("t.o")
            self.rmsnorm(self.tx, t + "post", self.txn, PROWS, TD, TD)
            self.tick("t.norm")
            self.lin[NONE, False, False](t + "gu", "", self.txn, self.tgu, PROWS, 2 * TF, TD, TD, 2 * TF)
            self.tick("t.gate_up")
            self.lin[SILU_MUL, False, True](t + "down", "", self.tgu, self.tx, PROWS, TD, TF, 2 * TF, TD, xoff=TF)
            self.tick("t.down")
        for l in range(1, TL, 2):
            var e = "e" + String(l) + "."
            self.lin[NONE, False, False](e + "ck", "", self.kc[l], self.ck[l], PROWS, KVD, KVD, KVD, KVD)
            self.lin[NONE, False, False](e + "cv", "", self.vc[l], self.cv[l], PROWS, KVD, KVD, KVD, KVD)
            self.tick("t.cross_kv")

    def step(mut self, s: Int) raises:
        """Euler step s: the expert's velocity for x_t at t = 1 - s / 10 into self.vt, then x_t += -0.1 v_t."""
        var ctx = self.ctx
        self.lin[NONE, True, False]("action_in_proj.w", "action_in_proj.b", self.xt, self.at, AROWS, ED, ADIM, ADIM,
                                    2 * ED)
        ctx.enqueue_function[vrow.fill_cols](self.at, self.temb, Int32(2 * ED), Int32(ED), Int32(ED), Int32(s * ED),
                                             Int32(AROWS * ED), grid_dim=groups(AROWS * ED, 256), block_dim=256)
        self.tick("e.action_time")
        self.lin[NONE, True, False]("action_time_mlp_in.w", "action_time_mlp_in.b", self.at, self.eh, AROWS, ED,
                                    2 * ED, 2 * ED, EDP)
        self.lin[SILU, True, False]("action_time_mlp_out.w", "action_time_mlp_out.b", self.eh, self.xe, AROWS, ED,
                                    ED, EDP, EDP)
        self.tick("e.action_time")
        for l in range(TL):
            var e = "e" + String(l) + "."
            self.rmsnorm(self.xe, e + "in", self.xen, AROWS, EDP, ED)
            self.tick("e.norm")
            if l % 2 == 0:  # self-attention: the prefix's cache and the actions' own K/V (rows 256..319)
                self.lin[NONE, False, False](e + "qkv", "", self.xen, self.eqkv, AROWS, TQKV, ED, EDP, TQKV)
                self.tick("e.qkv")
                ctx.enqueue_function[vrow.rope_qk](self.eqkv, self.rcos, self.rsin, self.epos, self.kc[l], self.vc[l],
                                                   Int32(TQKV), Int32(TH), Int32(TKV), Int32(KVD), Int32(PROWS), Int32(HD),
                                                   grid_dim=AROWS, block_dim=64)
                self.tick("e.rope")
                self.attention[True](self.eqkv, self.kc[l], self.vc[l], self.eatt, self.klev, self.eqlev, TQKV, KVD,
                                     TD, 0, 0, KVROWS, TH, TH // TKV, AROWS, 1, 0)
                self.tick("e.self_attention")
            else:  # cross-attention to the prefix's K/V, projected
                self.lin[NONE, False, False](e + "qkv", "", self.xen, self.eqkv, AROWS, TH * HD, ED, EDP, TQKV)
                self.tick("e.qkv")
                ctx.enqueue_function[vrow.rope_qk](self.eqkv, self.rcos, self.rsin, self.cpos, self.kc[l], self.vc[l],
                                                   Int32(TQKV), Int32(TH), Int32(0), Int32(KVD), Int32(0), Int32(HD),
                                                   grid_dim=AROWS, block_dim=64)
                self.tick("e.rope")
                self.attention[True](self.eqkv, self.ck[l], self.cv[l], self.eatt, self.klev, self.cqlev, TQKV, KVD,
                                     TD, 0, 0, PROWS, TH, TH // TKV, AROWS, 1, 0)
                self.tick("e.cross_attention")
            self.lin[NONE, False, True](e + "o", "", self.eatt, self.xe, AROWS, ED, TD, TD, EDP)
            self.tick("e.o")
            self.rmsnorm(self.xe, e + "post", self.xen, AROWS, EDP, ED)
            self.tick("e.norm")
            self.lin[NONE, False, False](e + "gu", "", self.xen, self.egu, AROWS, 2 * EF, ED, EDP, 2 * EF)
            self.tick("e.gate_up")
            self.lin[SILU_MUL, False, True](e + "down", "", self.egu, self.xe, AROWS, ED, EF, 2 * EF, EDP, xoff=EF)
            self.tick("e.down")
        self.rmsnorm(self.xe, "enorm", self.xen, AROWS, EDP, ED)
        self.lin[NONE, True, False]("action_out_proj.w", "action_out_proj.b", self.xen, self.vt, AROWS, ADIM, ED, EDP,
                                    64)
        ctx.enqueue_function[vrow.euler](self.xt, self.vt, Int32(ADIM), Int32(64), Int32(ADIM), Float32(-0.1),
                                         Int32(CHUNK * ADIM), grid_dim=groups(CHUNK * ADIM, 256), block_dim=256)
        self.tick("e.out")

