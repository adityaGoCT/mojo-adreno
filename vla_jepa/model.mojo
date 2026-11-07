# VLA-JEPA (ginwind/VLA-JEPA, LIBERO: Qwen3-VL-2B and a GR00T-style flow-matching DiT, 2.3B of its 3.1B parameters
# used at inference, bf16) as MAX DeviceContext launches: a 7 x 7 action chunk from two 256 x 256 views, an
# instruction and an 8-dim state, by 4 Euler steps. vla_jepa/reference.py runs the official PyTorch code in fp32;
# every stage below matches one of its tensors.
#   vit()      Qwen3-VL's ViT on both views (256 patches of 1536 each, in the processor's 2 x 2 merge order): the patch
#              projection plus the learned 48 x 48 position grid interpolated to 16 x 16, 24 blocks of 1024 with 2-D
#              RoPE (tanh GELU); DeepStack taps after blocks 5, 11, 17 and the final merger: LN, 2 x 2 -> 4096, fc1,
#              GELU, fc2 to 2048: 64 tokens a view, and three DeepStack sets
#   llm()      Qwen3 (28 layers of 2048, 16 heads of 128, 8 KV heads, q/k RMSNorm, interleaved 3-D RoPE theta 5e6)
#              over the prompt (S rows, padded to 256, causal), the DeepStack sets added at the image rows after
#              layers 0, 1, 2; the 32 embodied-action rows of layer 27's output (before the final norm) are the head's
#              context
#   head()     4 Euler steps of the DiT (16 blocks of 768, 12 heads of 64: even blocks cross-attend to the 32 context
#              rows, odd ones self-attend; adaptive LayerNorm from the timestep) over [state, 32 future tokens, 7
#              action tokens]; the decoder's last 7 rows are the velocity: x += v / 4
#
# Weights: the checkpoint's bf16 tensors (vla_jepa.safetensors from reference.py --export): matrices stay bf16, the rest
# are widened to fp32. VJ_REMOTE names the official .pt on the executor and VJ_REMOTE_INDEX the tensors' offsets in it
# (build/vla_jepa/pt_offsets.txt): the laptop downloads the checkpoint itself.
#
# VJ_MMA16=1: the ViT's, mergers' and LLM's matrices in fp16 (exact from bf16) on the fp16 matrix units (fp16 sums);
# the DiT stays fp32. GPU+NPU: VJ_NPU_VISION / VJ_NPU_LLM name graphs compiled on the laptop (vla_jepa/export_npu.py),
# run inside vk_server_npu on this program's buffers.
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.math import cos, exp, floor, log, sin, sqrt
from std.os import getenv
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

from host import Scratch, Weights, attend, groups, lin
from safetensors import Checkpoint
import jk
import ok
import tk
import vak
import vgemm
import vrow
from vgemm import GELU, GELU_ERF, NONE, SILU, SILU_MUL

comptime NV = 2
comptime NP = 256  # patches a view
comptime VROWS = NV * NP
comptime KP = 1536
comptime VD = 1024
comptime VF = 4096
comptime VL = 24
comptime VH = 16
comptime MROWS = VROWS // 4  # 128 merged tokens
comptime D = 2048
comptime LL = 28
comptime QH = 16
comptime KVH = 8
comptime HD = 128
comptime QKV = (QH + 2 * KVH) * HD  # 4096
comptime FF = 6144
comptime SP = 256  # the prompt's rows, padded
comptime PRE = 4  # the NPU LLM graph's rows start here (rows 0 .. 3, the same for every input, are constants there)
comptime NEG: Float32 = -30000.0  # the NPU graphs' masked logit (fp16)
comptime NE = 32  # embodied-action tokens
comptime DD = 768  # the DiT
comptime DB = 16
comptime DH = 12
comptime DFF = 3072
comptime DR = 64  # its rows, padded (40 used)
comptime DT = 40
comptime DOUT = 1024
comptime AH = 7  # actions
comptime AX = 8  # their columns, padded for the matmuls' k
comptime STEPS = 4
comptime EPS6: Float32 = 1e-6
comptime EPS5: Float32 = 1e-5
comptime INF: Float32 = 1e30

comptime VQ = "qwen_vl_interface.model.model.visual."
comptime LQ = "qwen_vl_interface.model.model.language_model."
comptime AM = "action_model."
comptime DM = "action_model.model."


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


def cols_of(name: String) -> Int:
    """A heavy matrix's k (VJ_MMA16)."""
    if name.startswith(VQ):
        if "patch_embed" in name:
            return KP
        if "merger" in name or "linear_fc2" in name:
            return VF
        return VD
    return FF if "down_proj" in name else D


def is_matrix(name: String) -> Bool:
    """Tensors the projections read, kept bf16."""
    if not name.endswith(".weight"):
        return False
    for tail in [".norm.weight", "norm1.weight", "norm2.weight", "layernorm.weight", "q_norm.weight", "k_norm.weight"]:
        if name.endswith(tail):
            return False
    for frag in ["pos_embed", "position_embedding", "future_tokens", "action_encoder.layer1"]:
        if frag in name:
            return False
    return True


struct VLAJEPA(Movable):
    var ctx: DeviceContext
    var w: Weights[DType.uint16, False]
    var s: Scratch
    var lib: OwnedDLHandle
    var bytes: Int
    var profiling: Bool
    var tag: String
    var S: Int
    var img0: List[Int]  # each view's first image row in the prompt
    var emb0: Int  # the first embodied-action row
    # inputs
    var pix: DeviceBuffer[DType.float32]  # [512, 1536]
    var ids: DeviceBuffer[DType.int32]
    var state: DeviceBuffer[DType.float32]  # [64, 8]: row 0
    var noise: DeviceBuffer[DType.float32]  # [7, 8]
    # vision
    var vx: DeviceBuffer[DType.float32]
    var vxn: DeviceBuffer[DType.float32]
    var vqkv: DeviceBuffer[DType.float32]
    var vkc: DeviceBuffer[DType.float32]
    var vvc: DeviceBuffer[DType.float32]
    var vatt: DeviceBuffer[DType.float32]
    var vh: DeviceBuffer[DType.float32]
    var vpos: DeviceBuffer[DType.int32]
    var vcos: DeviceBuffer[DType.float32]
    var vsin: DeviceBuffer[DType.float32]
    var posemb: DeviceBuffer[DType.float32]  # [256, 1024]
    var zlev: DeviceBuffer[DType.float32]
    var mn: DeviceBuffer[DType.float32]
    var mh: DeviceBuffer[DType.float32]
    var vis: DeviceBuffer[DType.float32]  # [128, 2048]
    var ds: List[DeviceBuffer[DType.float32]]  # the three DeepStack sets
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
    var lcos: DeviceBuffer[DType.float32]
    var lsin: DeviceBuffer[DType.float32]
    var vl: DeviceBuffer[DType.float32]  # [64, 2048]: the 32 context rows
    # head
    var h: DeviceBuffer[DType.float32]  # [64, 768]
    var hn: DeviceBuffer[DType.float32]
    var hq: DeviceBuffer[DType.float32]
    var hk: DeviceBuffer[DType.float32]
    var hv: DeviceBuffer[DType.float32]
    var hatt: DeviceBuffer[DType.float32]
    var hff: DeviceBuffer[DType.float32]
    var ck: List[DeviceBuffer[DType.float32]]  # even blocks' context K and V (64 x 768)
    var cv: List[DeviceBuffer[DType.float32]]
    var mods: List[DeviceBuffer[DType.float32]]  # each block's AdaLN modulation per step (rows of 1536)
    var outmod: DeviceBuffer[DType.float32]
    var tau: DeviceBuffer[DType.float32]  # the action encoder's sinusoid per step (rows of 768)
    var zeros: DeviceBuffer[DType.float32]
    var srow: DeviceBuffer[DType.float32]  # the state token
    var ae: DeviceBuffer[DType.float32]  # [64, 1536]
    var ae2: DeviceBuffer[DType.float32]
    var af: DeviceBuffer[DType.float32]
    var dout: DeviceBuffer[DType.float32]
    var dec: DeviceBuffer[DType.float32]
    var vel: DeviceBuffer[DType.float32]  # [64, 64]
    var act: DeviceBuffer[DType.float32]  # [64, 8]: x (rows 0 .. 6)
    var mask0: DeviceBuffer[DType.int32]
    var wv: Weights[DType.float16, True]  # VJ_MMA16: the ViT's, mergers' and LLM's matrices in fp16
    var s16: Scratch
    var mma16: Bool
    # GPU+NPU
    var dsall: DeviceBuffer[DType.float32]  # the three DeepStack sets, contiguous (ds[k] are its sub-buffers)
    var ncos: DeviceBuffer[DType.float32]  # the NPU LLM graph's RoPE tables (rows 4 .. 255, 128 columns) and mask
    var nsin: DeviceBuffer[DType.float32]
    var nmask: DeviceBuffer[DType.float32]
    var npu_vision: Int  # VJ_NPU_VISION (vision_ctx.onnx on the laptop): its handle there, or -1
    var npu_llm: Int  # VJ_NPU_LLM (llm_ctx.onnx)

    def __init__(out self, ctx: DeviceContext, path: String) raises:
        self.ctx = ctx
        self.w = Weights[DType.uint16, False](ctx)
        self.s = Scratch(ctx, 64 * FF * 2, 64 * FF * 16, 0, 64)
        self.mma16 = flag("VJ_MMA16")
        self.wv = Weights[DType.float16, True](ctx)
        self.s16 = Scratch(ctx, 64, 64, SP * 2 * FF if self.mma16 else 64, 64)
        self.npu_vision = -1
        self.npu_llm = -1
        self.dsall = ctx.enqueue_create_buffer[DType.float32](3 * MROWS * D)
        self.ncos = ctx.enqueue_create_buffer[DType.float32]((SP - PRE) * HD)
        self.nsin = ctx.enqueue_create_buffer[DType.float32]((SP - PRE) * HD)
        self.nmask = ctx.enqueue_create_buffer[DType.float32]((SP - PRE) * SP)
        self.lib = OwnedDLHandle(plugin_path())
        self.bytes = 0
        self.profiling = False
        self.tag = ""
        self.S = 0
        self.img0 = List[Int]()
        self.emb0 = 0
        self.pix = ctx.enqueue_create_buffer[DType.float32](VROWS * KP)
        self.ids = ctx.enqueue_create_buffer[DType.int32](SP)
        self.state = ctx.enqueue_create_buffer[DType.float32](64 * 8)
        self.noise = ctx.enqueue_create_buffer[DType.float32](AH * AX)
        self.vx = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vxn = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vqkv = ctx.enqueue_create_buffer[DType.float32](VROWS * 3 * VD)
        self.vkc = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vvc = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vatt = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.vh = ctx.enqueue_create_buffer[DType.float32](VROWS * VF)
        self.vpos = ctx.enqueue_create_buffer[DType.int32](VROWS)
        self.vcos = ctx.enqueue_create_buffer[DType.float32](NP * 32)
        self.vsin = ctx.enqueue_create_buffer[DType.float32](NP * 32)
        self.posemb = ctx.enqueue_create_buffer[DType.float32](NP * VD)
        self.zlev = ctx.enqueue_create_buffer[DType.float32](VROWS)
        self.mn = ctx.enqueue_create_buffer[DType.float32](MROWS * VF)
        self.mh = ctx.enqueue_create_buffer[DType.float32](MROWS * VF)
        self.vis = ctx.enqueue_create_buffer[DType.float32](MROWS * D)
        self.ds = List[DeviceBuffer[DType.float32]]()
        for _ in range(3):
            self.ds.append(self.dsall.create_sub_buffer[DType.float32](len(self.ds) * MROWS * D, MROWS * D))
        self.x = ctx.enqueue_create_buffer[DType.float32](SP * D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](SP * D)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](SP * QKV)
        self.kc = ctx.enqueue_create_buffer[DType.float32](SP * KVH * HD)
        self.vc = ctx.enqueue_create_buffer[DType.float32](SP * KVH * HD)
        self.att = ctx.enqueue_create_buffer[DType.float32](SP * D)
        self.gu = ctx.enqueue_create_buffer[DType.float32](SP * 2 * FF)
        self.lklev = ctx.enqueue_create_buffer[DType.float32](SP)
        self.lqlev = ctx.enqueue_create_buffer[DType.float32](SP)
        self.lpos = ctx.enqueue_create_buffer[DType.int32](SP)
        self.lcos = ctx.enqueue_create_buffer[DType.float32](SP * HD // 2)
        self.lsin = ctx.enqueue_create_buffer[DType.float32](SP * HD // 2)
        self.vl = ctx.enqueue_create_buffer[DType.float32](64 * D)
        self.h = ctx.enqueue_create_buffer[DType.float32](DR * DD)
        self.hn = ctx.enqueue_create_buffer[DType.float32](DR * DD)
        self.hq = ctx.enqueue_create_buffer[DType.float32](DR * DD)
        self.hk = ctx.enqueue_create_buffer[DType.float32](DR * DD)
        self.hv = ctx.enqueue_create_buffer[DType.float32](DR * DD)
        self.hatt = ctx.enqueue_create_buffer[DType.float32](DR * DD)
        self.hff = ctx.enqueue_create_buffer[DType.float32](DR * DFF)
        self.ck = List[DeviceBuffer[DType.float32]]()
        self.cv = List[DeviceBuffer[DType.float32]]()
        for _ in range(DB // 2):
            self.ck.append(ctx.enqueue_create_buffer[DType.float32](64 * DD))
            self.cv.append(ctx.enqueue_create_buffer[DType.float32](64 * DD))
        self.mods = List[DeviceBuffer[DType.float32]]()
        for _ in range(DB):
            self.mods.append(ctx.enqueue_create_buffer[DType.float32](64 * 2 * DD))
        self.outmod = ctx.enqueue_create_buffer[DType.float32](64 * 2 * DD)
        self.tau = ctx.enqueue_create_buffer[DType.float32](STEPS * DD)
        self.zeros = ctx.enqueue_create_buffer[DType.float32](2 * DD)
        self.srow = ctx.enqueue_create_buffer[DType.float32](64 * DD)
        self.ae = ctx.enqueue_create_buffer[DType.float32](64 * 2 * DD)
        self.ae2 = ctx.enqueue_create_buffer[DType.float32](64 * DD)
        self.af = ctx.enqueue_create_buffer[DType.float32](64 * DD)
        self.dout = ctx.enqueue_create_buffer[DType.float32](DR * DOUT)
        self.dec = ctx.enqueue_create_buffer[DType.float32](DR * DOUT)
        self.vel = ctx.enqueue_create_buffer[DType.float32](DR * 64)
        self.act = ctx.enqueue_create_buffer[DType.float32](64 * AX)
        self.mask0 = ctx.enqueue_create_buffer[DType.int32](64)
        for buf in [self.vx, self.vxn, self.vqkv, self.vatt, self.vh, self.x, self.xn, self.qkv, self.att, self.gu,
                    self.vl, self.h, self.hn, self.hq, self.hk, self.hv, self.hatt, self.hff, self.zeros, self.srow,
                    self.ae, self.ae2, self.af, self.dout, self.dec, self.vel, self.act, self.state]:
            ctx.enqueue_memset(buf, Float32(0))
        ctx.enqueue_memset(self.mask0, Int32(0))
        self.load(path)
        self.tables()
        self.npu_vision = self.npug_open("VJ_NPU_VISION")
        self.npu_llm = self.npug_open("VJ_NPU_LLM")

    # weights
    def load(mut self, path: String) raises:
        var ck = Checkpoint(path)
        var remote = getenv("VJ_REMOTE")
        var at = Dict[String, Int]()
        var index = getenv("VJ_REMOTE_INDEX")
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
            if ck.dtypes[name] != "BF16":
                raise Error(name + ": " + ck.dtypes[name])
            var bytes = ck.sizes[name]
            var raw = self.ctx.enqueue_create_buffer[DType.uint16](bytes // 2)
            if remote:
                var off = at[name] if index else ck.offsets[name]
                if self.lib.call["M_driver_remote_file", Int32](UInt64(Int(raw.unsafe_ptr())), UInt64(bytes),
                                                                remote.as_c_string_span().unsafe_ptr(), UInt64(off)) != 0:
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
            var p = LQ + "layers." + String(l) + "."
            self.cat16(p + "qkv.weight", [p + "self_attn.q_proj.weight", p + "self_attn.k_proj.weight",
                                          p + "self_attn.v_proj.weight"])
            self.cat16(p + "gate_up.weight", [p + "mlp.gate_proj.weight", p + "mlp.up_proj.weight"])
        # the action encoder's first layer (768 x 7) padded to k = 8, in fp32
        var a1 = self.ctx.enqueue_create_buffer[DType.float32](DD * AX)
        self.ctx.enqueue_function[ok.pad_cols](self.w.floats[AM + "action_encoder.layer1.weight"], a1, Int32(AH), Int32(AX),
                                               Int32(DD * AX), grid_dim=groups(DD * AX, 256), block_dim=256)
        self.w.floats[AM + "action_encoder.layer1.weight8"] = a1
        self.ctx.synchronize()
        if self.mma16:
            self.halve()

    def halve(mut self) raises:
        """VJ_MMA16: the ViT's, mergers' and LLM's matrices in fp16 (exact from bf16), rows padded to 128."""
        var names = List[String]()
        for e in self.w.halves.items():
            var nm = e.key
            if nm.startswith(VQ):
                names.append(nm)
            elif nm.startswith(LQ + "layers.") and ("qkv" in nm or "o_proj" in nm or "gate_up" in nm or
                                                     "down_proj" in nm):
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
            # the bf16 original is no longer read (these projections go through hproj): freed as we go, so the fp16
            # copies do not double the weights' memory (VLA-JEPA's would not fit on an 11 GB phone)
            self.ctx.synchronize()
            _ = self.w.halves.pop(nm)
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
        # the parts are read only through the concatenation: freed, or the LLM's matrices would be held twice (1.9 GB
        # for VLA-JEPA, too much beside the fp16 copies on an 11 GB phone)
        self.ctx.synchronize()
        for nm in names:
            _ = self.w.halves.pop(nm)

    def tables(mut self) raises:
        """The ViT's position grid (Qwen3-VL's bilinear interpolation of the 48 x 48 table to 16 x 16, in the merge
        order) and 2-D RoPE (theta 1e4, 16 frequencies of the row then 16 of the column); the DiT's per-step
        tables: the timestep embedding's modulations and the action encoder's sinusoid."""
        var ctx = self.ctx
        var idx = List[Int32](length=NP * 4, fill=0)
        var wts = List[Float32](length=NP * 4, fill=0)
        var vc = List[Float32](length=NP * 32, fill=0)
        var vs = List[Float32](length=NP * 32, fill=0)
        for p in range(NP):  # merge order: ((h2 8 + w2) 2 + dh) 2 + dw
            var g = p // 4
            var hh = (g // 8) * 2 + (p % 4) // 2
            var ww = (g % 8) * 2 + p % 2
            var hf = Float32(hh) * (Float32(47) / Float32(15))
            var wf = Float32(ww) * (Float32(47) / Float32(15))
            var h0 = Int(hf)
            var w0 = Int(wf)
            var h1 = min(h0 + 1, 47)
            var w1 = min(w0 + 1, 47)
            var dh = hf - Float32(h0)
            var dw = wf - Float32(w0)
            idx[4 * p] = Int32(h0 * 48 + w0)
            idx[4 * p + 1] = Int32(h0 * 48 + w1)
            idx[4 * p + 2] = Int32(h1 * 48 + w0)
            idx[4 * p + 3] = Int32(h1 * 48 + w1)
            wts[4 * p] = (1 - dh) * (1 - dw)
            wts[4 * p + 1] = (1 - dh) * dw
            wts[4 * p + 2] = dh * (1 - dw)
            wts[4 * p + 3] = dh * dw
            for i in range(16):
                var inv = Float32(1.0 / (10000.0 ** (Float64(Float32(2 * i) / Float32(32)))))
                var fh = Float32(hh) * inv
                var fw = Float32(ww) * inv
                vc[p * 32 + i] = Float32(cos(Float64(fh)))
                vs[p * 32 + i] = Float32(sin(Float64(fh)))
                vc[p * 32 + 16 + i] = Float32(cos(Float64(fw)))
                vs[p * 32 + 16 + i] = Float32(sin(Float64(fw)))
        var bidx = ctx.enqueue_create_buffer[DType.int32](NP * 4)
        var bw = ctx.enqueue_create_buffer[DType.float32](NP * 4)
        ctx.enqueue_copy(bidx, idx.unsafe_ptr())
        ctx.enqueue_copy(bw, wts.unsafe_ptr())
        ctx.enqueue_function[jk.pos_bilinear](self.w.floats[VQ + "pos_embed.weight"], self.posemb, bidx, bw, Int32(VD),
                                              Int32(NP * VD), grid_dim=groups(NP * VD, 256), block_dim=256)
        ctx.enqueue_copy(self.vcos, vc.unsafe_ptr())
        ctx.enqueue_copy(self.vsin, vs.unsafe_ptr())
        var vp = List[Int32](length=VROWS, fill=0)
        for r in range(VROWS):
            vp[r] = Int32(r % NP)
        ctx.enqueue_copy(self.vpos, vp.unsafe_ptr())
        ctx.enqueue_memset(self.zlev, Float32(0))
        # the DiT's timestep tables: Timesteps(256, flip_sin_to_cos, shift 1) of t = 0, 250, 500, 750, then
        # TimestepEmbedding; SiLU; each block's AdaLN linear and proj_out_1
        var tp = List[Float32](length=64 * 256, fill=0)
        var ta = List[Float32](length=STEPS * DD, fill=0)
        for s in range(STEPS):
            var t = Float32(s * 1000 // STEPS)
            for i in range(128):
                var e = exp(-Float32(log(10000.0)) * Float32(i) / Float32(127))
                var f = t * e
                tp[s * 256 + i] = Float32(cos(Float64(f)))
                tp[s * 256 + 128 + i] = Float32(sin(Float64(f)))
            for i in range(DD // 2):  # the action encoder's sinusoid: [sin, cos]
                var e = exp(-Float32(i) * (Float32(log(10000.0)) / Float32(DD // 2)))
                var f = t * e
                ta[s * DD + i] = Float32(sin(Float64(f)))
                ta[s * DD + DD // 2 + i] = Float32(cos(Float64(f)))
        var btp = ctx.enqueue_create_buffer[DType.float32](64 * 256)
        ctx.enqueue_copy(btp, tp.unsafe_ptr())
        ctx.enqueue_copy(self.tau, ta.unsafe_ptr())
        var t1 = ctx.enqueue_create_buffer[DType.float32](64 * DD)
        var temb = ctx.enqueue_create_buffer[DType.float32](64 * DD)
        var te = DM + "timestep_encoder.timestep_embedder."
        self.proj[True, False](te + "linear_1.weight", te + "linear_1.bias", btp, t1, 64, DD, 256, 256, DD)
        self.proj[True, False, SILU](te + "linear_2.weight", te + "linear_2.bias", t1, temb, 64, DD, DD, DD, DD)
        for b in range(DB):
            var p = DM + "transformer_blocks." + String(b) + ".norm1.linear."
            self.proj[True, False, SILU](p + "weight", p + "bias", temb, self.mods[b], 64, 2 * DD, DD, DD, 2 * DD)
        self.proj[True, False, SILU](DM + "proj_out_1.weight", DM + "proj_out_1.bias", temb, self.outmod, 64, 2 * DD, DD,
                                     DD, 2 * DD)
        ctx.synchronize()

    def set_inputs(mut self, pixels: List[Float32], ids: List[Int32], S: Int, img0: List[Int], emb0: Int,
                   pos3: List[Int32], state: List[Float32], noise: List[Float32]) raises:
        """The processor's patches [512, 1536], the S token ids, each view's first image row, the first embodied
        row, the 3-D position ids (t, h, w; 3 x S), the raw state (8), the noise (7 x 7)."""
        var ctx = self.ctx
        self.S = S
        self.img0 = img0.copy()
        self.emb0 = emb0
        ctx.enqueue_copy(self.pix, pixels.unsafe_ptr())
        var r = List[Int32](length=SP, fill=0)
        for i in range(S):
            r[i] = ids[i]
        ctx.enqueue_copy(self.ids, r.unsafe_ptr())
        var kl = List[Float32](length=SP, fill=0)
        var ql = List[Float32](length=SP, fill=0)
        var lp = List[Int32](length=SP, fill=0)
        for i in range(SP):
            kl[i] = Float32(i) if i < S else INF
            ql[i] = Float32(i) if i < S else Float32(0)
            lp[i] = Int32(i)
        ctx.enqueue_copy(self.lklev, kl.unsafe_ptr())
        ctx.enqueue_copy(self.lqlev, ql.unsafe_ptr())
        ctx.enqueue_copy(self.lpos, lp.unsafe_ptr())
        # interleaved MRoPE (sections 24, 20, 20): frequency j takes h's position when j % 3 == 1 and j < 60, w's
        # when j % 3 == 2 and j < 60, t's otherwise; theta 5e6; a row per sequence position
        var c = List[Float32](length=SP * HD // 2, fill=0)
        var sn = List[Float32](length=SP * HD // 2, fill=0)
        for j in range(HD // 2):
            var inv = Float32(1.0 / (5.0e6 ** (Float64(Float32(2 * j) / Float32(HD)))))
            var dim = 0
            if j < 60 and j % 3 == 1:
                dim = 1
            elif j < 60 and j % 3 == 2:
                dim = 2
            for i in range(S):
                var f = Float32(pos3[dim * S + i]) * inv
                c[i * HD // 2 + j] = Float32(cos(Float64(f)))
                sn[i * HD // 2 + j] = Float32(sin(Float64(f)))
        ctx.enqueue_copy(self.lcos, c.unsafe_ptr())
        ctx.enqueue_copy(self.lsin, sn.unsafe_ptr())
        # the NPU LLM graph's forms (export_npu.py): full 128-column tables from row 4, and its additive mask (row
        # 4 + i sees keys 0 .. 4 + i; padding rows see key 0)
        var n = SP - PRE
        var c2 = List[Float32](length=n * HD, fill=0)
        var s2 = List[Float32](length=n * HD, fill=0)
        for i in range(PRE, S):
            for j in range(HD):
                c2[(i - PRE) * HD + j] = c[i * HD // 2 + j % (HD // 2)]
                s2[(i - PRE) * HD + j] = sn[i * HD // 2 + j % (HD // 2)]
        var ma = List[Float32](length=n * SP, fill=NEG)
        for i in range(n):
            if PRE + i < S:
                for j in range(PRE + i + 1):
                    ma[i * SP + j] = 0
            else:
                ma[i * SP] = 0
        ctx.enqueue_copy(self.ncos, c2.unsafe_ptr())
        ctx.enqueue_copy(self.nsin, s2.unsafe_ptr())
        ctx.enqueue_copy(self.nmask, ma.unsafe_ptr())
        var st = List[Float32](length=64 * 8, fill=0)
        for i in range(8):
            st[i] = state[i]
        ctx.enqueue_copy(self.state, st.unsafe_ptr())
        var nz = List[Float32](length=AH * AX, fill=0)
        for i in range(AH):
            for j in range(AH):
                nz[i * AX + j] = noise[i * AH + j]
        ctx.enqueue_copy(self.noise, nz.unsafe_ptr())
        ctx.synchronize()

    def npug_open(self, env: String) raises -> Int:
        var graph = getenv(env)
        if not graph:
            return -1
        var ms = Float64(0)
        var h = self.lib.call["M_driver_remote_npug_open", Int32](graph.as_c_string_span().unsafe_ptr(), Pointer(to=ms))
        if h < 0:
            raise Error("M_driver_remote_npug_open failed for " + graph + ": the server must be vk_server_npu.exe")
        print("NPU:", graph, "opened in", round(ms, 1), "ms")
        return Int(h)

    def npug_run(mut self, h: Int, ins: List[UInt64], inb: List[UInt64], outs: List[UInt64],
                 outb: List[UInt64]) raises:
        """A compiled graph on the laptop's NPU, inside vk_server_npu: inputs read from and outputs written to GPU
        buffers (device pointers and byte sizes, in the graph's order)."""
        if self.lib.call["M_driver_remote_npug_run", Int32](Int32(h), Int32(len(ins)), ins.unsafe_ptr(),
                                                            inb.unsafe_ptr(), Int32(len(outs)), outs.unsafe_ptr(),
                                                            outb.unsafe_ptr()) != 0:
            raise Error("M_driver_remote_npug_run failed")
        self.tick("NPU graph")

    def npu_time(mut self) raises -> Float64:
        var ms = Float64(0)
        if self.lib.call["M_driver_remote_npug_time", Int32](Pointer(to=ms)) != 0:
            raise Error("the NPU graph failed (M_driver_remote_npug_time)")
        return ms

    def vision_npu(mut self) raises:
        """GPU+NPU: the ViT, DeepStack mergers and the merger on the NPU: vis and the DeepStack sets."""
        self.npug_run(self.npu_vision, [UInt64(Int(self.pix.unsafe_ptr()))], [UInt64(VROWS * KP * 4)],
                      [UInt64(Int(self.vis.unsafe_ptr())), UInt64(Int(self.dsall.unsafe_ptr()))],
                      [UInt64(MROWS * D * 4), UInt64(3 * MROWS * D * 4)])

    def llm_npu(mut self) raises:
        """GPU+NPU: Qwen3's 28 layers on the NPU over rows 4 .. 255 of x (the image rows taken from vis, DeepStack
        added inside): the 32 embodied rows into vl."""
        var n = SP - PRE
        var emb = sub(self.x, PRE * D, n * D)
        self.npug_run(self.npu_llm, [UInt64(Int(emb.unsafe_ptr())), UInt64(Int(self.vis.unsafe_ptr())),
                                     UInt64(Int(self.dsall.unsafe_ptr())), UInt64(Int(self.ncos.unsafe_ptr())),
                                     UInt64(Int(self.nsin.unsafe_ptr())), UInt64(Int(self.nmask.unsafe_ptr()))],
                      [UInt64(n * D * 4), UInt64(MROWS * D * 4), UInt64(3 * MROWS * D * 4), UInt64(n * HD * 4),
                       UInt64(n * HD * 4), UInt64(n * SP * 4)], [UInt64(Int(self.vl.unsafe_ptr()))],
                      [UInt64(NE * D * 4)])

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
        """A heavy projection (ViT, mergers, LLM): proj, or VJ_MMA16's fp16 matrix units (fp16 sums)."""
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
                                                               EPS6, Float32(0), grid_dim=SP, block_dim=64)
        self.tick("rmsnorm")

    def adaln(self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], mod: DeviceBuffer[DType.float32],
              soff: Int, hoff: Int, eps: Float32) raises:
        self.ctx.enqueue_function[jk.adaln](x, y, mod, Int32(soff), Int32(hoff), Int32(DD), eps, grid_dim=DR,
                                            block_dim=64)
        self.tick("adaln")

    def copy(self, dst: DeviceBuffer[DType.float32], src: DeviceBuffer[DType.float32]) raises:
        self.ctx.enqueue_copy(dst, src)

    # vision
    def vit(mut self) raises:
        """The ViT on both views (rows v 256 + p), the DeepStack sets after blocks 5, 11, 17, the merger: vis."""
        self.tag = "vit"
        var ctx = self.ctx
        for v in range(NV):
            self.copy(sub(self.vx, v * NP * VD, NP * VD), self.posemb)
        self.hproj[True, True](VQ + "patch_embed.proj.weight", VQ + "patch_embed.proj.bias", self.pix, self.vx, VROWS,
                              VD, KP, KP, VD)
        for i in range(VL):
            var p = VQ + "blocks." + String(i) + "."
            self.ln(self.vx, self.vxn, p + "norm1", VROWS, VD, EPS6)
            self.hproj[True, False](p + "attn.qkv.weight", p + "attn.qkv.bias", self.vxn, self.vqkv, VROWS, 3 * VD, VD, VD,
                                   3 * VD)
            ctx.enqueue_function[vrow.rope_qk](self.vqkv, self.vcos, self.vsin, self.vpos, self.vkc, self.vvc,
                                               Int32(3 * VD), Int32(VH), Int32(VH), Int32(VD), Int32(0), Int32(64),
                                               grid_dim=VROWS, block_dim=64)
            self.tick("rope")
            attend[False, 64](ctx, self.vqkv, self.vkc, self.vvc, self.vatt, self.zlev, self.zlev, 3 * VD, VD, VD, 0, 0,
                              NP, VH, 1, NP, NV, NP, Float32(0.125))
            self.tick("attention")
            self.hproj[True, True](p + "attn.proj.weight", p + "attn.proj.bias", self.vatt, self.vx, VROWS, VD, VD, VD, VD)
            self.ln(self.vx, self.vxn, p + "norm2", VROWS, VD, EPS6)
            self.hproj[True, False](p + "mlp.linear_fc1.weight", p + "mlp.linear_fc1.bias", self.vxn, self.vh, VROWS, VF,
                                   VD, VD, VF)
            self.hproj[True, True, GELU](p + "mlp.linear_fc2.weight", p + "mlp.linear_fc2.bias", self.vh, self.vx, VROWS,
                                        VD, VF, VF, VD)
            if i == 5 or i == 11 or i == 17:
                self.merge(VQ + "deepstack_merger_list." + String((i - 5) // 6) + ".", self.vx, True,
                           self.ds[(i - 5) // 6])
        self.merge(VQ + "merger.", self.vx, False, self.vis)

    def merge(self, p: String, src: DeviceBuffer[DType.float32], post: Bool,
              dst: DeviceBuffer[DType.float32]) raises:
        """A patch merger: 2 x 2 consecutive patches (merge order) as one row of 4096, LN after the concatenation
        (DeepStack) or per patch before it (the final merger), fc1, exact GELU, fc2 to 2048."""
        if post:
            self.ln(src, self.mn, p + "norm", MROWS, VF, EPS6)
        else:
            self.ln(src, self.mn, p + "norm", VROWS, VD, EPS6)
        self.hproj[True, False](p + "linear_fc1.weight", p + "linear_fc1.bias", self.mn, self.mh, MROWS, VF, VF, VF, VF)
        self.hproj[True, False, GELU_ERF](p + "linear_fc2.weight", p + "linear_fc2.bias", self.mh, dst, MROWS, D, VF, VF,
                                         D)

    # the language model
    def embed(mut self) raises:
        """The prompt's rows, the views' 64 tokens each at their image rows."""
        self.tag = "embed"
        self.ctx.enqueue_function[vrow.embed_rows[DType.uint16]](self.w.halves[LQ + "embed_tokens.weight"], self.ids,
                                                                 self.x, Int32(D), Int32(D), Float32(1), grid_dim=SP,
                                                                 block_dim=64)
        for v in range(NV):
            self.copy(sub(self.x, self.img0[v] * D, 64 * D), sub(self.vis, v * 64 * D, 64 * D))

    def llm(mut self) raises:
        self.tag = "llm"
        for l in range(LL):
            self.llm_layer(l)
        self.copy(sub(self.vl, 0, NE * D), sub(self.x, self.emb0 * D, NE * D))

    def llm_layer(mut self, l: Int) raises:
        var ctx = self.ctx
        var p = LQ + "layers." + String(l) + "."
        self.rms(self.x, self.xn, p + "input_layernorm.weight")
        self.hproj[False, False](p + "qkv.weight", "", self.xn, self.qkv, SP, QKV, D, D, QKV)
        ctx.enqueue_function[jk.head_rms](self.qkv, self.w.floats[p + "self_attn.q_norm.weight"], Int32(QKV), Int32(0),
                                          Int32(HD), EPS6, grid_dim=Dim(SP, QH), block_dim=64)
        ctx.enqueue_function[jk.head_rms](self.qkv, self.w.floats[p + "self_attn.k_norm.weight"], Int32(QKV),
                                          Int32(QH * HD), Int32(HD), EPS6, grid_dim=Dim(SP, KVH), block_dim=64)
        self.tick("q/k norms")
        ctx.enqueue_function[vrow.rope_qk](self.qkv, self.lcos, self.lsin, self.lpos, self.kc, self.vc, Int32(QKV),
                                           Int32(QH), Int32(KVH), Int32(KVH * HD), Int32(0), Int32(HD), grid_dim=SP,
                                           block_dim=64)
        self.tick("rope")
        attend[True, HD](ctx, self.qkv, self.kc, self.vc, self.att, self.lklev, self.lqlev, QKV, KVH * HD, QH * HD, 0, 0,
                         SP, QH, QH // KVH, SP, 1, 0, Float32(1 / sqrt(Float64(HD))))
        self.tick("attention")
        self.hproj[False, True](p + "self_attn.o_proj.weight", "", self.att, self.x, SP, D, QH * HD, QH * HD, D)
        self.rms(self.x, self.xn, p + "post_attention_layernorm.weight")
        self.hproj[False, False](p + "gate_up.weight", "", self.xn, self.gu, SP, 2 * FF, D, D, 2 * FF)
        self.hproj[False, True, SILU_MUL](p + "mlp.down_proj.weight", "", self.gu, self.x, SP, D, FF, 2 * FF, D, xoff=FF)
        if l < 3:  # DeepStack
            for v in range(NV):
                var rows = sub(self.x, self.img0[v] * D, 64 * D)
                ctx.enqueue_function[ok.add_rows](rows, sub(self.ds[l], v * 64 * D, 64 * D), Int32(D), Int32(D),
                                                  Int32(64 * D), grid_dim=groups(64 * D, 256), block_dim=256)
            self.tick("deepstack")

    # the action head
    def head_start(mut self) raises:
        """The state token, the future tokens, the even blocks' context K and V; x = the noise."""
        self.tag = "head"
        var se = AM + "state_encoder."
        var t = self.ctx.enqueue_create_buffer[DType.float32](64 * DOUT)
        self.proj[True, False](se + "layer1.weight", se + "layer1.bias", self.state, t, 64, DOUT, 8, 8, DOUT)
        self.ctx.enqueue_function[vak.relu_rows](t, Int32(DOUT), Int32(DOUT), Int32(64 * DOUT),
                                                 grid_dim=groups(64 * DOUT, 256), block_dim=256)
        self.proj[True, False](se + "layer2.weight", se + "layer2.bias", t, self.srow, 64, DD, DOUT, DOUT, DD)
        for b in range(0, DB, 2):
            var p = DM + "transformer_blocks." + String(b) + ".attn1."
            self.proj[True, False](p + "to_k.weight", p + "to_k.bias", self.vl, self.ck[b // 2], 64, DD, D, D, DD)
            self.proj[True, False](p + "to_v.weight", p + "to_v.bias", self.vl, self.cv[b // 2], 64, DD, D, D, DD)
        self.copy(sub(self.act, 0, AH * AX), self.noise)

    def step(mut self, s: Int) raises:
        """One Euler step: the DiT's input rows [state, future tokens, action tokens], 16 blocks, the output
        modulation, proj_out_2, the decoder; x += v / 4."""
        var ctx = self.ctx
        var ae = AM + "action_encoder."
        self.proj[True, False](ae + "layer1.weight8", ae + "layer1.bias", self.act, self.ae, 64, DD, AX, AX, 2 * DD)
        ctx.enqueue_function[vrow.fill_cols](self.ae, self.tau, Int32(2 * DD), Int32(DD), Int32(DD), Int32(s * DD),
                                             Int32(64 * DD), grid_dim=groups(64 * DD, 256), block_dim=256)
        self.proj[True, False](ae + "layer2.weight", ae + "layer2.bias", self.ae, self.ae2, 64, DD, 2 * DD, 2 * DD, DD)
        self.copy(sub(self.af, 0, AH * DD), sub(self.w.floats[AM + "position_embedding.weight"], 0, AH * DD))
        self.proj[True, True, SILU](ae + "layer3.weight", ae + "layer3.bias", self.ae2, self.af, 64, DD, DD, DD, DD)
        self.copy(sub(self.h, 0, DD), sub(self.srow, 0, DD))
        self.copy(sub(self.h, DD, NE * DD), self.w.floats[AM + "future_tokens.weight"])
        self.copy(sub(self.h, (1 + NE) * DD, AH * DD), sub(self.af, 0, AH * DD))
        for b in range(DB):
            var p = DM + "transformer_blocks." + String(b) + "."
            self.adaln(self.h, self.hn, sub(self.mods[b], s * 2 * DD, 2 * DD), 0, DD, EPS5)
            self.proj[True, False](p + "attn1.to_q.weight", p + "attn1.to_q.bias", self.hn, self.hq, DR, DD, DD, DD, DD)
            var kb = self.ck[b // 2]
            var vb = self.cv[b // 2]
            var nk = NE
            if b % 2 == 1:
                self.proj[True, False](p + "attn1.to_k.weight", p + "attn1.to_k.bias", self.hn, self.hk, DR, DD, DD, DD,
                                       DD)
                self.proj[True, False](p + "attn1.to_v.weight", p + "attn1.to_v.bias", self.hn, self.hv, DR, DD, DD, DD,
                                       DD)
                kb = self.hk
                vb = self.hv
                nk = DT
            ctx.enqueue_function[tk.attn_small[0]](self.hq, kb, vb, self.hatt, self.mask0, Int32(DD), Int32(DD),
                                                   Int32(DD), Int32(DD), Int32(0), Int32(0), Int32(0), Int32(0),
                                                   Int32(nk), Int32(64), Float32(0.125), grid_dim=Dim(DH, DT),
                                                   block_dim=64)
            self.tick("attention")
            self.proj[True, True](p + "attn1.to_out.0.weight", p + "attn1.to_out.0.bias", self.hatt, self.h, DR, DD, DD,
                                  DD, DD)
            self.adaln(self.h, self.hn, self.zeros, 0, DD, EPS5)
            self.proj[True, False](p + "ff.net.0.proj.weight", p + "ff.net.0.proj.bias", self.hn, self.hff, DR, DFF, DD,
                                   DD, DFF)
            self.proj[True, True, GELU](p + "ff.net.2.weight", p + "ff.net.2.bias", self.hff, self.h, DR, DD, DFF, DFF,
                                        DD)
        self.adaln(self.h, self.hn, sub(self.outmod, s * 2 * DD, 2 * DD), DD, 0, EPS6)
        self.proj[True, False](DM + "proj_out_2.weight", DM + "proj_out_2.bias", self.hn, self.dout, DR, DOUT, DD, DD,
                               DOUT)
        var dc = AM + "action_decoder."
        self.proj[True, False](dc + "layer1.weight", dc + "layer1.bias", self.dout, self.dec, DR, DOUT, DOUT, DOUT, DOUT)
        ctx.enqueue_function[vak.relu_rows](self.dec, Int32(DOUT), Int32(DOUT), Int32(DR * DOUT),
                                            grid_dim=groups(DR * DOUT, 256), block_dim=256)
        self.proj[True, False](dc + "layer2.weight", dc + "layer2.bias", self.dec, self.vel, DR, AH, DOUT, DOUT, 64)
        ctx.enqueue_function[vrow.euler](self.act, sub(self.vel, (DT - AH) * 64, AH * 64), Int32(AX), Int32(64),
                                         Int32(AH), Float32(1.0 / Float64(STEPS)), Int32(AH * AH),
                                         grid_dim=groups(AH * AH, 64), block_dim=64)
        self.tick("euler")

    def head(mut self) raises:
        self.head_start()
        for s in range(STEPS):
            self.step(s)

    def chunk(mut self) raises:
        """One action chunk: the ViT, the prompt rows, the LLM, the head (GPU+NPU: vision and the LLM on the NPU).
        Enqueued only."""
        if self.npu_vision >= 0:
            self.vision_npu()
        else:
            self.vit()
        self.embed()
        if self.npu_llm >= 0:
            self.llm_npu()
        else:
            self.llm()
        self.head()
