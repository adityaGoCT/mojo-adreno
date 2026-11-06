# Evo-1 (MINT-SJTU/Evo1_LIBERO, 0.77B, bf16) as MAX DeviceContext launches: a 50 x 24 action chunk (7 dims used) from
# three 448 x 448 views (agent, wrist, a masked zero view), an instruction and a state, by 32 flow-matching steps.
# evo1/reference.py runs the official PyTorch code in fp32 (FlashAttention-2's masking emulated); every stage below
# matches one of its tensors.
#   vision()   InternViT-300M on the 3 views (1025 rows each, padded to 1088): 24 layers of 1024 with LayerScale; then
#              InternVL's pixel shuffle (32 x 32 patches -> 16 x 16 tokens of 4096) and mlp1 (LN, 4096 -> 896, GELU,
#              896 -> 896): 256 tokens a view
#   llm()      Qwen2.5-0.5B's first 14 layers over the fixed 1024-row prompt (the image slots filled), FlashAttention-2
#              semantics: masked rows' attention output is zero, valid rows see valid keys causally; the final RMSNorm:
#              the head's context rows 0 .. 1023
#   head()     the state token (24 -> 1024 -> 896) as context row 1024; 32 Euler steps of the action head: the action
#              encoder (50 tokens), 8 cross-attention blocks (8 heads of 112) with the time embedding before the
#              feed-forward, norm_out, the 44,800 -> 896 pooling projection, the MLP to 1200: x += v / 32
#
# Weights: the checkpoint's bf16 tensors (evo1.safetensors from evo1/reference.py --export): matrices stay bf16, vectors
# are widened to fp32. EVO1_REMOTE names the same file on the executor's disk (M_driver_remote_file). Rows padded to 64.
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.math import cos, sin, sqrt
from std.os import getenv
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

from host import Scratch, Weights, attend, groups, lin
from safetensors import Checkpoint
import ek
import vak
import vattn
import vgemm
import vrow
from vgemm import GELU_ERF, NONE, SILU_MUL

comptime IMG = 448
comptime PATCH = 14
comptime NPATCH = 1024
comptime KP = 3 * PATCH * PATCH  # 588
comptime NV = 3
comptime VT = NPATCH + 1  # 1025
comptime VR = 1088  # a view's rows, padded
comptime VROWS = NV * VR
comptime VD = 1024
comptime VF = 4096
comptime VL = 24
comptime VH = 16
comptime MT = 256  # tokens a view after the pixel shuffle
comptime MROWS = NV * MT  # 768
comptime PS = 4 * VD  # 4096
comptime D = 896
comptime LL = 14
comptime QH = 14
comptime KVH = 2
comptime HD = 64
comptime QKV = (QH + 2 * KVH) * HD  # 1152
comptime FF = 4864
comptime S = 1024
comptime CTX = S + 1  # 1025: the LLM's rows and the state token
comptime CR = 1088  # context rows, padded
comptime H = 50  # actions
comptime HR = 64
comptime AD = 24
comptime HB = 8
comptime HHEADS = 8
comptime HHD = 112
comptime HFF = 3584
comptime POOL = H * D  # 44800
comptime MH = 1024
comptime OUT = H * AD  # 1200
comptime STEPS = 32
comptime EPS6: Float32 = 1e-6
comptime EPS5: Float32 = 1e-5
comptime INF: Float32 = 1e30

comptime VM = "embedder.model.vision_model."
comptime ML = "embedder.model.mlp1."
comptime LM = "embedder.model.language_model.model."
comptime AH = "action_head."


def plugin_path() raises -> String:
    var spec = getenv("MODULAR_DRIVER_PLUGINS")
    var at = spec.find("@")
    if at < 0:
        raise Error("MODULAR_DRIVER_PLUGINS=vulkan@<path of the driver plugin> is needed")
    return String(spec[byte=at + 1:])


def sub(b: DeviceBuffer[DType.float32], off: Int, n: Int) raises -> DeviceBuffer[DType.float32]:
    return b.create_sub_buffer[DType.float32](off, n)


def flag(name: String) -> Bool:
    var v = getenv(name)
    return v != "" and v != "0"


def is_matrix(name: String) -> Bool:
    """Tensors the projections read (kept bf16): linear and convolution weights, the embedding table."""
    if not (name.endswith(".weight") or name.endswith("in_proj_weight")):
        return False
    if "norm" in name or name.startswith(ML + "0."):
        return False
    return True


def cols_of(name: String) -> Int:
    """A matrix's k, by name (VLA-Adapter's halve() pattern, for EVO1_MMA16)."""
    if name.startswith(VM):
        return VF if "fc2" in name else VD
    if name.startswith(ML):
        return PS if ".1." in name else D
    return FF if "down_proj" in name else D


struct Evo1(Movable):
    var ctx: DeviceContext
    var w: Weights[DType.uint16, False]
    var s: Scratch
    var wv: Weights[DType.float16, True]  # EVO1_MMA16: the ViT's, mlp1's and LLM's matrices in fp16
    var s16: Scratch
    var mma16: Bool
    var opt: Bool
    var lib: OwnedDLHandle
    var bytes: Int
    var profiling: Bool
    var tag: String
    # inputs
    var pix: DeviceBuffer[DType.float32]  # [3, 3, 448, 448]
    var ids: DeviceBuffer[DType.int32]
    var slots: List[Int]  # each view's first image slot
    var state: DeviceBuffer[DType.float32]  # [64, 24]: row 0
    var noise: DeviceBuffer[DType.float32]  # [50, 24]
    var amask: DeviceBuffer[DType.float32]  # [24]
    # vision
    var xp: DeviceBuffer[DType.float32]
    var vx: DeviceBuffer[DType.float32]
    var vxn: DeviceBuffer[DType.float32]
    var vqkv: DeviceBuffer[DType.float32]
    var vatt: DeviceBuffer[DType.float32]
    var vh: DeviceBuffer[DType.float32]
    var vklev: DeviceBuffer[DType.float32]
    var zlev: DeviceBuffer[DType.float32]
    var shuf: DeviceBuffer[DType.float32]
    var shufn: DeviceBuffer[DType.float32]
    var m1: DeviceBuffer[DType.float32]
    var mout: DeviceBuffer[DType.float32]  # [768, 896]: the views' tokens
    # LLM
    var x: DeviceBuffer[DType.float32]
    var xn: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]
    var kc: DeviceBuffer[DType.float32]
    var vc: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]
    var lklev: DeviceBuffer[DType.float32]
    var lqlev: DeviceBuffer[DType.float32]
    var lpos: DeviceBuffer[DType.int32]
    var rcos: DeviceBuffer[DType.float32]
    var rsin: DeviceBuffer[DType.float32]
    # head
    var ctxb: DeviceBuffer[DType.float32]  # [1088, 896]: the context
    var sh: DeviceBuffer[DType.float32]
    var hk: List[DeviceBuffer[DType.float32]]  # each block's context K and V (1088 x 896)
    var hv: List[DeviceBuffer[DType.float32]]
    var act: DeviceBuffer[DType.float32]  # [64, 24]: x (rows 0 .. 49)
    var ain: DeviceBuffer[DType.float32]  # x * mask
    var ax: DeviceBuffer[DType.float32]  # [64, 896]: the action tokens
    var axn: DeviceBuffer[DType.float32]
    var aq: DeviceBuffer[DType.float32]
    var aatt: DeviceBuffer[DType.float32]
    var aff: DeviceBuffer[DType.float32]
    var flat: DeviceBuffer[DType.float32]  # [64, 44800]: row 0 = norm_out's 50 rows
    var pooled: DeviceBuffer[DType.float32]
    var mh: DeviceBuffer[DType.float32]
    var vel: DeviceBuffer[DType.float32]  # [64, 1200]: row 0
    var xs: DeviceBuffer[DType.float32]  # x after each step (32 x 1200), for the check
    var record: Bool
    var tindex: List[Int]

    def __init__(out self, ctx: DeviceContext, path: String) raises:
        self.ctx = ctx
        self.w = Weights[DType.uint16, False](ctx)
        self.s = Scratch(ctx, 64 * POOL, 64 * POOL * 4, 0, 64)
        self.mma16 = flag("EVO1_MMA16")
        self.opt = flag("EVO1_OPT")
        self.wv = Weights[DType.float16, True](ctx)
        self.s16 = Scratch(ctx, 64, 64, VROWS * VF if self.mma16 else 64, 64)
        self.lib = OwnedDLHandle(plugin_path())
        self.bytes = 0
        self.profiling = False
        self.tag = ""
        self.slots = List[Int]()
        self.record = True
        self.tindex = List[Int]()
        for i in range(STEPS):
            self.tindex.append(Int(Float64(i) / Float64(STEPS) * 1000.0))
        self.pix = ctx.enqueue_create_buffer[DType.float32](NV * 3 * IMG * IMG)
        self.ids = ctx.enqueue_create_buffer[DType.int32](S)
        self.state = ctx.enqueue_create_buffer[DType.float32](HR * AD)
        self.noise = ctx.enqueue_create_buffer[DType.float32](H * AD)
        self.amask = ctx.enqueue_create_buffer[DType.float32](AD)
        self.xp = ctx.enqueue_create_buffer[DType.float32](NV * NPATCH * KP)
        self.vx = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vxn = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vqkv = ctx.enqueue_create_buffer[DType.float32](VROWS * 3 * VD)
        self.vatt = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vh = ctx.enqueue_create_buffer[DType.float32](VROWS * VF)
        self.vklev = ctx.enqueue_create_buffer[DType.float32](VROWS)
        self.zlev = ctx.enqueue_create_buffer[DType.float32](VROWS)
        self.shuf = ctx.enqueue_create_buffer[DType.float32](MROWS * PS)
        self.shufn = ctx.enqueue_create_buffer[DType.float32](MROWS * PS)
        self.m1 = ctx.enqueue_create_buffer[DType.float32](MROWS * D)
        self.mout = ctx.enqueue_create_buffer[DType.float32](MROWS * D)
        self.x = ctx.enqueue_create_buffer[DType.float32](S * D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](S * D)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](S * QKV)
        self.kc = ctx.enqueue_create_buffer[DType.float32](S * KVH * HD)
        self.vc = ctx.enqueue_create_buffer[DType.float32](S * KVH * HD)
        self.att = ctx.enqueue_create_buffer[DType.float32](S * D)
        self.gu = ctx.enqueue_create_buffer[DType.float32](S * 2 * FF)
        self.lklev = ctx.enqueue_create_buffer[DType.float32](S)
        self.lqlev = ctx.enqueue_create_buffer[DType.float32](S)
        self.lpos = ctx.enqueue_create_buffer[DType.int32](S)
        self.rcos = ctx.enqueue_create_buffer[DType.float32](S * HD // 2)
        self.rsin = ctx.enqueue_create_buffer[DType.float32](S * HD // 2)
        self.ctxb = ctx.enqueue_create_buffer[DType.float32](CR * D)
        self.sh = ctx.enqueue_create_buffer[DType.float32](HR * MH)
        self.hk = List[DeviceBuffer[DType.float32]]()
        self.hv = List[DeviceBuffer[DType.float32]]()
        for _ in range(HB):
            self.hk.append(ctx.enqueue_create_buffer[DType.float32](CR * D))
            self.hv.append(ctx.enqueue_create_buffer[DType.float32](CR * D))
        self.act = ctx.enqueue_create_buffer[DType.float32](HR * AD)
        self.ain = ctx.enqueue_create_buffer[DType.float32](HR * AD)
        self.ax = ctx.enqueue_create_buffer[DType.float32](HR * D)
        self.axn = ctx.enqueue_create_buffer[DType.float32](HR * D)
        self.aq = ctx.enqueue_create_buffer[DType.float32](HR * D)
        self.aatt = ctx.enqueue_create_buffer[DType.float32](HR * D)
        self.aff = ctx.enqueue_create_buffer[DType.float32](HR * HFF)
        self.flat = ctx.enqueue_create_buffer[DType.float32](HR * POOL)
        self.pooled = ctx.enqueue_create_buffer[DType.float32](HR * D)
        self.mh = ctx.enqueue_create_buffer[DType.float32](HR * MH)
        self.vel = ctx.enqueue_create_buffer[DType.float32](HR * OUT)
        self.xs = ctx.enqueue_create_buffer[DType.float32](STEPS * OUT)
        for buf in [self.vx, self.vxn, self.vqkv, self.vatt, self.vh, self.x, self.xn, self.qkv, self.att, self.gu,
                    self.ctxb, self.sh, self.act, self.ain, self.ax, self.axn, self.aq, self.aatt, self.aff, self.flat,
                    self.pooled, self.mh, self.vel, self.state]:
            ctx.enqueue_memset(buf, Float32(0))
        self.load(path)
        self.tables()

    # weights
    def load(mut self, path: String) raises:
        var ck = Checkpoint(path)
        var remote = getenv("EVO1_REMOTE")
        # EVO1_REMOTE_INDEX: the tensors' byte offsets in another file on the executor (the official DeepSpeed .pt,
        # which the laptop downloads itself: its 4 storages are stored uncompressed, every tensor a contiguous slice)
        var at = Dict[String, Int]()
        var index = getenv("EVO1_REMOTE_INDEX")
        if index:
            for line in open(index, "r").read().splitlines():
                var parts = line.split(" ")
                if len(parts) == 2:
                    at[String(parts[0])] = Int(String(parts[1]))
        var names = List[String]()
        for e in ck.sizes.items():
            names.append(e.key)
        var f = open(path, "r")
        for name in names:
            var dt = ck.dtypes[name]
            if dt != "BF16":
                raise Error(name + ": " + dt + " (the LIBERO checkpoint is all bf16)")
            var bytes = ck.sizes[name]
            var raw = self.ctx.enqueue_create_buffer[DType.uint16](bytes // 2)  # the stored bytes
            if remote:
                var off = at[name] if index else ck.offsets[name]
                if self.lib.call["M_driver_remote_file", Int32](UInt64(Int(raw.unsafe_ptr())), UInt64(bytes),
                                                                remote.as_c_string_span().unsafe_ptr(),
                                                                UInt64(off)) != 0:
                    raise Error("M_driver_remote_file failed for " + name)
            else:
                var data = ck.read(f, name)
                self.ctx.enqueue_copy(raw, data.unsafe_ptr().unsafe_bitcast[UInt16]())
                self.ctx.synchronize()
            self.bytes += bytes
            if is_matrix(name):
                self.w.halves[name] = raw
            else:
                var n = bytes // 2
                var wide = self.ctx.enqueue_create_buffer[DType.float32](n)
                self.ctx.enqueue_function[vak.widen](raw, wide, Int32(n), grid_dim=groups(n, 256), block_dim=256)
                self.w.floats[name] = wide
        f.close()
        self.ctx.synchronize()
        for l in range(LL):
            var p = LM + "layers." + String(l) + "."
            self.cat16(p + "qkv.weight", [p + "self_attn.q_proj.weight", p + "self_attn.k_proj.weight",
                                          p + "self_attn.v_proj.weight"])
            self.cat32(p + "qkv.bias", [p + "self_attn.q_proj.bias", p + "self_attn.k_proj.bias",
                                        p + "self_attn.v_proj.bias"])
            self.cat16(p + "gate_up.weight", [p + "mlp.gate_proj.weight", p + "mlp.up_proj.weight"])
        for b in range(HB):  # nn.MultiheadAttention's packed in_proj: q, k, v rows
            var p = AH + "transformer_blocks." + String(b) + ".attn."
            var wq = self.w.halves[p + "in_proj_weight"]
            self.w.halves[p + "q.weight"] = wq.create_sub_buffer[DType.uint16](0, D * D)
            self.w.halves[p + "k.weight"] = wq.create_sub_buffer[DType.uint16](D * D, D * D)
            self.w.halves[p + "v.weight"] = wq.create_sub_buffer[DType.uint16](2 * D * D, D * D)
            var bq = self.w.floats[p + "in_proj_bias"]
            self.w.floats[p + "q.bias"] = sub(bq, 0, D)
            self.w.floats[p + "k.bias"] = sub(bq, D, D)
            self.w.floats[p + "v.bias"] = sub(bq, 2 * D, D)
        if self.mma16:
            self.halve()
        self.ctx.synchronize()

    def halve(mut self) raises:
        """EVO1_MMA16: the ViT's, mlp1's and LLM's matrices in fp16 (exact from bf16), rows padded to 128."""
        var names = List[String]()
        for e in self.w.halves.items():
            var nm = e.key
            if "embed_tokens" in nm or "patch_embedding" in nm:
                continue
            if nm.startswith(VM + "encoder.") or nm.startswith(ML):
                names.append(nm)
            elif nm.startswith(LM + "layers.") and ("qkv" in nm or "o_proj" in nm or "gate_up" in nm or "down_proj" in nm):
                names.append(nm)
        for nm in names:
            var src = self.w.halves[nm]
            var n = len(src)
            var cols = cols_of(nm)
            var padded = (n // cols + 127) // 128 * 128 * cols
            var dst = self.ctx.enqueue_create_buffer[DType.float16](padded)
            self.ctx.enqueue_memset(dst, Float16(0))
            self.ctx.enqueue_function[vak.to_f16_from_bf16](src, dst, Int32(n), grid_dim=groups(n, 256), block_dim=256)
            self.wv.halves[nm] = dst
        self.ctx.synchronize()

    def cat16(mut self, key: String, names: List[String]) raises:
        var total = 0
        for nm in names:
            total += len(self.w.halves[nm])
        var buf = self.ctx.enqueue_create_buffer[DType.uint16](total)
        var at = 0
        for nm in names:
            var src = self.w.halves[nm]
            self.ctx.enqueue_copy(buf.create_sub_buffer[DType.uint16](at, len(src)), src)
            at += len(src)
        self.w.halves[key] = buf

    def cat32(mut self, key: String, names: List[String]) raises:
        var total = 0
        for nm in names:
            total += len(self.w.floats[nm])
        var buf = self.ctx.enqueue_create_buffer[DType.float32](total)
        var at = 0
        for nm in names:
            var src = self.w.floats[nm]
            self.ctx.enqueue_copy(sub(buf, at, len(src)), src)
            at += len(src)
        self.w.floats[key] = buf

    def tables(mut self) raises:
        """The ViT's key mask (a view's padding rows), the LLM's RoPE (theta 1e6, as transformers computes it)."""
        var kl = List[Float32](length=VROWS, fill=0)
        for r in range(VROWS):
            if r % VR >= VT:
                kl[r] = INF
        self.ctx.enqueue_copy(self.vklev, kl.unsafe_ptr())
        self.ctx.enqueue_memset(self.zlev, Float32(0))
        var c = List[Float32](length=S * HD // 2, fill=0)
        var s = List[Float32](length=S * HD // 2, fill=0)
        for i in range(HD // 2):
            var inv = Float32(1.0 / (1.0e6 ** (Float64(Float32(2 * i) / Float32(HD)))))
            for pos in range(S):
                var f = Float32(pos) * inv
                c[pos * HD // 2 + i] = Float32(cos(Float64(f)))
                s[pos * HD // 2 + i] = Float32(sin(Float64(f)))
        self.ctx.enqueue_copy(self.rcos, c.unsafe_ptr())
        self.ctx.enqueue_copy(self.rsin, s.unsafe_ptr())
        var pos = List[Int32](length=S, fill=0)
        for i in range(S):
            pos[i] = Int32(i)
        self.ctx.enqueue_copy(self.lpos, pos.unsafe_ptr())
        self.ctx.synchronize()

    def set_inputs(mut self, pixels: List[Float32], ids: List[Int32], mask: List[Int32], slots: List[Int],
                   state: List[Float32], noise: List[Float32], amask: List[Float32]) raises:
        """pixel_values [3, 3, 448, 448]; the 1024 token ids and the LLM's mask (1 valid; the masked view's slots 0);
        each view's first slot; the normalized state (24), the initial noise (50 x 24), the action mask (24)."""
        self.ctx.enqueue_copy(self.pix, pixels.unsafe_ptr())
        self.ctx.enqueue_copy(self.ids, ids.unsafe_ptr())
        self.slots = slots.copy()
        var kl = List[Float32](length=S, fill=0)
        var ql = List[Float32](length=S, fill=0)
        for i in range(S):  # FlashAttention-2: masked rows see nothing (zero output) and are seen by no one
            kl[i] = Float32(i) if mask[i] != 0 else INF
            ql[i] = Float32(i) if mask[i] != 0 else Float32(-1)
        self.ctx.enqueue_copy(self.lklev, kl.unsafe_ptr())
        self.ctx.enqueue_copy(self.lqlev, ql.unsafe_ptr())
        var st = List[Float32](length=HR * AD, fill=0)
        for i in range(AD):
            st[i] = state[i]
        self.ctx.enqueue_copy(self.state, st.unsafe_ptr())
        self.ctx.enqueue_copy(self.noise, noise.unsafe_ptr())
        self.ctx.enqueue_copy(self.amask, amask.unsafe_ptr())
        self.ctx.synchronize()

    def tick(self, what: String) raises:
        if self.profiling:
            self.ctx.synchronize()
            print("mark", self.tag + " | " + what)

    # launches
    def proj[BIAS: Bool, RES: Bool, ACT: Int = NONE](self, wname: String, bname: String,
                                                     x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
                                                     rows: Int, n: Int, k: Int, ldx: Int, ldy: Int,
                                                     xoff: Int = 0) raises:
        lin[DType.uint16, False, ACT, BIAS, RES](self.w, self.s, wname, bname, x, y, rows, n, k, ldx, ldy, xoff)
        self.tick("proj " + String(rows) + "x" + String(n) + "x" + String(k))

    def hproj[BIAS: Bool, RES: Bool, ACT: Int = NONE](self, wname: String, bname: String,
                                                      x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
                                                      rows: Int, n: Int, k: Int, ldx: Int, ldy: Int,
                                                      xoff: Int = 0) raises:
        """A heavy projection (ViT, mlp1, LLM): proj, or EVO1_MMA16's fp16 matrix units (fp16 sums)."""
        if not self.mma16:
            self.proj[BIAS, RES, ACT](wname, bname, x, y, rows, n, k, ldx, ldy, xoff)
            return
        var b = self.w.floats[bname] if BIAS else self.s16.xa
        var ctx = self.ctx
        var w16 = self.wv.halves[wname]
        ctx.enqueue_function[vgemm.to_half[ACT]](x, self.s16.xh, Int32(k), Int32(ldx), Int32(xoff), Float32(1),
                                                 Int32(rows * k), grid_dim=groups(rows * k, 256), block_dim=256)
        if rows % 128 == 0:
            ctx.enqueue_function[vgemm.gemm16[2, 2]](self.s16.xh, w16, self.s16.yh, Int32(n), Int32(k), Int32(ldy),
                                                     grid_dim=Dim(groups(n, 128), rows // 128), block_dim=256)
        else:
            ctx.enqueue_function[vgemm.gemm16[1, 2]](self.s16.xh, w16, self.s16.yh, Int32(n), Int32(k), Int32(ldy),
                                                     grid_dim=Dim(groups(n, 128), rows // 64), block_dim=128)
        ctx.enqueue_function[vgemm.finish16[BIAS, RES]](self.s16.yh, b, y, Int32(n), Int32(ldy), Int32(rows * n),
                                                        grid_dim=groups(rows * n, 256), block_dim=256)
        self.tick("proj16 " + String(rows) + "x" + String(n) + "x" + String(k))

    def ln(self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], name: String, rows: Int, d: Int,
           eps: Float32) raises:
        self.ctx.enqueue_function[vrow.layernorm[DType.float32]](
            x, self.w.floats[name + ".weight"], self.w.floats[name + ".bias"], y, Int32(d), Int32(d), Int32(d), eps,
            grid_dim=rows, block_dim=64)
        self.tick("layernorm")

    def rms(self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], name: String) raises:
        self.ctx.enqueue_function[vrow.rmsnorm[DType.float32]](x, self.w.floats[name], y, Int32(D), Int32(D), Int32(D),
                                                               EPS6, Float32(0), grid_dim=S, block_dim=64)
        self.tick("rmsnorm")

    def relu(self, x: DeviceBuffer[DType.float32], rows: Int, n: Int) raises:
        self.ctx.enqueue_function[vak.relu_rows](x, Int32(n), Int32(n), Int32(rows * n), grid_dim=groups(rows * n, 256),
                                                 block_dim=256)
        self.tick("relu")

    def copy(self, dst: DeviceBuffer[DType.float32], src: DeviceBuffer[DType.float32]) raises:
        self.ctx.enqueue_copy(dst, src)

    # vision
    def vit(mut self) raises:
        """InternViT-300M on the 3 views: rows v 1088 + (CLS, 1024 patches) plus the position embedding; 24 layers.
        The output (no final norm) in vx."""
        self.tag = "vit"
        var ctx = self.ctx
        ctx.enqueue_function[vrow.patchify](self.pix, self.xp, Int32(IMG), Int32(PATCH), Int32(NV * NPATCH * KP),
                                            grid_dim=groups(NV * NPATCH * KP, 256), block_dim=256)
        var pe = VM + "embeddings."
        for v in range(NV):
            self.copy(sub(self.vx, v * VR * VD, VT * VD), self.w.floats[pe + "position_embedding"])
            self.proj[True, True](pe + "patch_embedding.weight", pe + "patch_embedding.bias",
                                  sub(self.xp, v * NPATCH * KP, NPATCH * KP), sub(self.vx, (v * VR + 1) * VD, NPATCH * VD),
                                  NPATCH, VD, KP, KP, VD)
            ctx.enqueue_function[ek.add_row](sub(self.vx, v * VR * VD, VD), self.w.floats[pe + "class_embedding"],
                                             Int32(0), Int32(VD), Int32(VD), grid_dim=groups(VD, 256), block_dim=256)
        for i in range(VL):
            self.vit_layer(i)

    def vit_layer(mut self, i: Int) raises:
        var ctx = self.ctx
        if True:
            var p = VM + "encoder.layers." + String(i) + "."
            self.ln(self.vx, self.vxn, p + "norm1", VROWS, VD, EPS6)
            self.hproj[True, False](p + "attn.qkv.weight", p + "attn.qkv.bias", self.vxn, self.vqkv, VROWS, 3 * VD, VD,
                                    VD, 3 * VD)
            attend[True, 64](ctx, self.vqkv, self.vqkv, self.vqkv, self.vatt, self.vklev, self.zlev, 3 * VD, 3 * VD,
                             VD, VD, 2 * VD, VR, VH, 1, VR, NV, VR, Float32(0.125))
            self.tick("attention")
            self.hproj[True, False](p + "attn.proj.weight", p + "attn.proj.bias", self.vatt, self.vxn, VROWS, VD, VD,
                                    VD, VD)
            ctx.enqueue_function[vak.scale_add](self.vx, self.vxn, self.w.floats[p + "ls1"], Int32(VD),
                                                Int32(VROWS * VD), grid_dim=groups(VROWS * VD, 256), block_dim=256)
            self.ln(self.vx, self.vxn, p + "norm2", VROWS, VD, EPS6)
            self.hproj[True, False](p + "mlp.fc1.weight", p + "mlp.fc1.bias", self.vxn, self.vh, VROWS, VF, VD, VD, VF)
            self.hproj[True, False, GELU_ERF](p + "mlp.fc2.weight", p + "mlp.fc2.bias", self.vh, self.vxn, VROWS, VD,
                                              VF, VF, VD)
            ctx.enqueue_function[vak.scale_add](self.vx, self.vxn, self.w.floats[p + "ls2"], Int32(VD),
                                                Int32(VROWS * VD), grid_dim=groups(VROWS * VD, 256), block_dim=256)

    def mlp1(mut self) raises:
        """The pixel shuffle and mlp1: mout (3 x 256 rows of 896)."""
        self.tag = "mlp1"
        self.ctx.enqueue_function[ek.pixel_shuffle](self.vx, self.shuf, Int32(VR), Int32(VD), Int32(MROWS * PS),
                                                    grid_dim=groups(MROWS * PS, 256), block_dim=256)
        self.ln(self.shuf, self.shufn, ML + "0", MROWS, PS, EPS5)
        self.hproj[True, False](ML + "1.weight", ML + "1.bias", self.shufn, self.m1, MROWS, D, PS, PS, D)
        self.hproj[True, False, GELU_ERF](ML + "3.weight", ML + "3.bias", self.m1, self.mout, MROWS, D, D, D, D)

    def vision(mut self) raises:
        self.vit()
        self.mlp1()

    # the language model
    def embed(mut self) raises:
        """The 1024 token rows, then each view's 256 slots overwritten by its tokens."""
        self.tag = "embed"
        self.ctx.enqueue_function[vrow.embed_rows[DType.uint16]](self.w.halves[LM + "embed_tokens.weight"], self.ids,
                                                                 self.x, Int32(D), Int32(D), Float32(1), grid_dim=S,
                                                                 block_dim=64)
        for v in range(NV):
            self.copy(sub(self.x, self.slots[v] * D, MT * D), sub(self.mout, v * MT * D, MT * D))

    def llm(mut self) raises:
        """The 14 layers (FlashAttention-2 masking through the levels), then the final RMSNorm into the context."""
        self.tag = "llm"
        for l in range(LL):
            self.llm_layer(l)
        self.rms(self.x, sub(self.ctxb, 0, S * D), LM + "norm.weight")

    def llm_layer(mut self, l: Int) raises:
        var ctx = self.ctx
        if True:
            var p = LM + "layers." + String(l) + "."
            self.rms(self.x, self.xn, p + "input_layernorm.weight")
            self.hproj[True, False](p + "qkv.weight", p + "qkv.bias", self.xn, self.qkv, S, QKV, D, D, QKV)
            ctx.enqueue_function[vrow.rope_qk](self.qkv, self.rcos, self.rsin, self.lpos, self.kc, self.vc,
                                               Int32(QKV), Int32(QH), Int32(KVH), Int32(KVH * HD), Int32(0), Int32(HD),
                                               grid_dim=S, block_dim=64)
            self.tick("rope")
            attend[True, HD](ctx, self.qkv, self.kc, self.vc, self.att, self.lklev, self.lqlev, QKV, KVH * HD, D, 0, 0,
                             S, QH, QH // KVH, S, 1, 0, Float32(0.125))
            self.tick("attention")
            self.hproj[False, True](p + "self_attn.o_proj.weight", "", self.att, self.x, S, D, D, D, D)
            self.rms(self.x, self.xn, p + "post_attention_layernorm.weight")
            self.hproj[False, False](p + "gate_up.weight", "", self.xn, self.gu, S, 2 * FF, D, D, 2 * FF)
            self.hproj[False, True, SILU_MUL](p + "mlp.down_proj.weight", "", self.gu, self.x, S, D, FF, 2 * FF, D,
                                              xoff=FF)

    # the action head
    def head_start(mut self) raises:
        """The state token (context row 1024) and every block's context K and V (the context does not change over
        the steps); x = the noise."""
        self.tag = "head"
        self.proj[True, False](AH + "state_encoder.fc1.linear.weight", AH + "state_encoder.fc1.linear.bias", self.state,
                               self.sh, HR, MH, AD, AD, MH)
        self.relu(self.sh, HR, MH)
        var tmp = self.ctx.enqueue_create_buffer[DType.float32](HR * D)
        self.proj[True, False](AH + "state_encoder.fc2.linear.weight", AH + "state_encoder.fc2.linear.bias", self.sh,
                               tmp, HR, D, MH, MH, D)
        self.copy(sub(self.ctxb, S * D, D), sub(tmp, 0, D))
        for b in range(HB):
            var p = AH + "transformer_blocks." + String(b) + ".attn."
            self.proj[True, False](p + "k.weight", p + "k.bias", self.ctxb, self.hk[b], CR, D, D, D, D)
            self.proj[True, False](p + "v.weight", p + "v.bias", self.ctxb, self.hv[b], CR, D, D, D, D)
        self.copy(sub(self.act, 0, H * AD), self.noise)

    def step(mut self, i: Int) raises:
        """One Euler step: the action encoder on x * mask, 8 blocks, norm_out, pooling, the MLP; x += v / 32."""
        var ctx = self.ctx
        ctx.enqueue_function[ek.masked](self.act, self.amask, self.ain, Int32(AD), Int32(H * AD),
                                        grid_dim=groups(H * AD, 256), block_dim=256)
        var ae = AH + "action_encoder."
        self.proj[True, False](ae + "W1.linear.weight", ae + "W1.linear.bias", self.ain, self.ax, HR, D, AD, AD, D)
        ctx.enqueue_function[ek.relu_add](self.ax, self.w.floats[ae + "pos_encoding.pe"], Int32(D), Int32(H * D),
                                          grid_dim=groups(H * D, 256), block_dim=256)
        self.proj[True, False](ae + "W2.linear.weight", ae + "W2.linear.bias", self.ax, self.axn, HR, D, D, D, D)
        self.relu(self.axn, HR, D)
        self.proj[True, False](ae + "W3.linear.weight", ae + "W3.linear.bias", self.axn, self.ax, HR, D, D, D, D)
        var toff = self.tindex[i] * D
        for b in range(HB):
            var p = AH + "transformer_blocks." + String(b) + "."
            self.ln(self.ax, self.axn, p + "norm1", HR, D, EPS5)
            self.proj[True, False](p + "attn.q.weight", p + "attn.q.bias", self.axn, self.aq, HR, D, D, D, D)
            ctx.enqueue_function[ek.cross_attention](self.aq, self.hk[b], self.hv[b], self.aatt, Int32(D), Int32(D),
                                                     Int32(D), Int32(CTX), Float32(1 / sqrt(Float64(HHD))),
                                                     grid_dim=Dim(HHEADS, H), block_dim=64)
            self.tick("cross-attention")
            self.proj[True, True](p + "attn.out_proj.weight", p + "attn.out_proj.bias", self.aatt, self.ax, HR, D, D, D,
                                  D)
            self.ln(self.ax, self.axn, p + "norm2", HR, D, EPS5)
            ctx.enqueue_function[ek.add_row](self.axn, self.w.floats[AH + "time_pos_enc.pe"], Int32(toff), Int32(D),
                                             Int32(H * D), grid_dim=groups(H * D, 256), block_dim=256)
            self.proj[True, False](p + "ff.0.weight", p + "ff.0.bias", self.axn, self.aff, HR, HFF, D, D, HFF)
            self.proj[True, True, GELU_ERF](p + "ff.2.weight", p + "ff.2.bias", self.aff, self.ax, HR, D, HFF, HFF, D)
        self.ln(self.ax, self.axn, AH + "norm_out", HR, D, EPS5)
        self.copy(sub(self.flat, 0, POOL), sub(self.axn, 0, POOL))
        self.proj[True, False](AH + "seq_pool_proj.weight", AH + "seq_pool_proj.bias", self.flat, self.pooled, HR, D,
                               POOL, POOL, D)
        self.proj[True, False](AH + "mlp_head.fc1.linear.weight", AH + "mlp_head.fc1.linear.bias", self.pooled,
                               self.mh, HR, MH, D, D, MH)
        self.relu(self.mh, HR, MH)
        self.proj[True, False](AH + "mlp_head.fc2.linear.weight", AH + "mlp_head.fc2.linear.bias", self.mh, self.vel,
                               HR, OUT, MH, MH, OUT)
        ctx.enqueue_function[ek.euler](self.act, self.vel, Float32(1.0 / Float64(STEPS)), Int32(OUT),
                                       grid_dim=groups(OUT, 256), block_dim=256)
        self.tick("euler")
        if self.record:
            self.copy(sub(self.xs, i * OUT, OUT), sub(self.act, 0, OUT))

    def head(mut self) raises:
        self.head_start()
        for i in range(STEPS):
            self.step(i)

    def chunk(mut self) raises:
        """One action chunk: vision, the prompt rows, the LLM, the head. Enqueued only."""
        self.vision()
        self.embed()
        self.llm()
        self.head()
