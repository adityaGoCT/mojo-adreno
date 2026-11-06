# VLA-Adapter (OpenHelix-Team, the Pro policy, VLA-Adapter/LIBERO-Spatial-Pro: 1.47B parameters, bf16) as MAX
# DeviceContext launches: an 8 x 7 action chunk from two 224 x 224 images (agent view, wrist), an instruction and an
# 8-dim state, in one pass. vla_adapter/reference.py runs the official PyTorch code in fp32; every stage below matches
# one of its tensors.
#   vision()   per image, DINOv2-L/14 with 4 registers (blocks 0 .. 22 of 24: the model's tap) and SigLIP-So400m/14
#              (blocks 0 .. 25 of 27), their 256 patch features side by side (2176), the 3-layer projector to 896:
#              512 vision tokens
#   llm()      Qwen2.5-0.5B over [<|im_start|>, 512 vision tokens, the rest of the prompt, 64 action queries, a stop
#              token] (S = L + 577 rows, causal), keeping each layer's rows 0 .. 511 (the "task" window) and
#              L + 511 .. L + 574 (the action-query window): 24 taps, the last after the final RMSNorm
#   policy()   the proprio projector (8 -> 896 -> 896); 24 Pro blocks over 8 rows, block i reading tap i: one
#              softmax over self (8), adapter (64 + proprio) and task (512, logits times tanh(gate)) keys, 8 heads of
#              112 with VLA-Adapter's RoPE, then ReLU(Linear(LN(attention + x))); LN and the 896 -> 7 head: the
#              normalized actions
#
# Weights: the checkpoint's bf16 tensors as vla_adapter/reference.py --export merges them (vla_adapter.safetensors):
# matrices stay bf16 (vgemm widens them as it stages them), vectors are widened to fp32. With a remote GPU (the X2
# Elite laptop), VLA_REMOTE names the same file on the executor's disk (M_driver_remote_file). Rows are padded to 64.
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.math import cos, sin, sqrt, tanh
from std.os import getenv
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

from host import Scratch, Weights, attend, groups, lin
from safetensors import Checkpoint
import vak
import vattn
import vgemm
import vrow
from vgemm import GELU_ERF, NONE, SILU_MUL

comptime IMG = 224
comptime PATCH = 14
comptime NPATCH = 256
comptime KP = 3 * PATCH * PATCH  # 588
comptime NIMG = 2
comptime DV = 1024  # DINOv2-L
comptime DF = 4096
comptime DLU = 23  # blocks used
comptime DHEADS = 16
comptime DPRE = 5  # CLS + 4 registers
comptime DR = 320  # an image's rows, padded
comptime DROWS = NIMG * DR
comptime SV = 1152  # SigLIP-So400m
comptime SF = 4304
comptime SFP = 4352
comptime SLU = 26
comptime SHEADS = 16
comptime VROWS = NIMG * NPATCH  # 512
comptime PF = DV + SV  # 2176
comptime P1 = 4 * PF  # 8704
comptime D = 896  # Qwen2.5-0.5B
comptime LL = 24
comptime QH = 14
comptime KVH = 2
comptime HD = 64
comptime QKV = (QH + 2 * KVH) * HD  # 1152
comptime FF = 4864
comptime SP = 640  # the sequence's rows, padded
comptime TAP = VROWS + 64  # a tap: the task window and the action-query window
comptime CH = 8  # the chunk's rows
comptime PR = 64  # its rows, padded
comptime PHEADS = 8
comptime PHD = 112
comptime NA = 65  # adapter keys: 64 action-query rows and the proprio token
comptime ADIM = 7
comptime PROP = 8
comptime EPS6: Float32 = 1e-6
comptime EPS5: Float32 = 1e-5
comptime INF: Float32 = 1e30

comptime VB = "vision_backbone.featurizer."
comptime SB = "vision_backbone.fused_featurizer."
comptime PJ = "projector."
comptime LM = "language_model.model."
comptime AH = "action_head.model."
comptime PP = "proprio_projector."


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
    """Tensors the projections read (kept bf16): weights of linear layers, convolutions and embeddings."""
    if not name.endswith(".weight"):
        return False
    for frag in ["norm", "ls1", "ls2", "layer_norm", "ffn.0."]:
        if frag in name:
            return False
    return True


def skipped(name: String) -> Bool:
    """Tensors inference never reads: the ViTs' last blocks and final norms (the model taps earlier blocks),
    SigLIP's attention pool, the policy's FiLM generator, the LM head."""
    if "attn_pool" in name or "film_gen" in name or "lm_head" in name:
        return True
    if name.startswith(VB + "norm.") or name.startswith(SB + "norm."):
        return True
    if name.startswith(VB + "blocks.23.") or name.startswith(SB + "blocks.26."):
        return True
    return False


def cols_of(name: String) -> Int:
    """A matrix's k (its row length), by name."""
    if name.startswith(VB):
        return DF if "fc2" in name else DV
    if name.startswith(SB):
        return SF if "fc2" in name else SV
    if name.startswith(PJ):
        return PF if "fc1" in name else (P1 if "fc2" in name else D)
    return FF if "down_proj" in name else D


struct VLAAdapter(Movable):
    var ctx: DeviceContext
    var w: Weights[DType.uint16, False]  # bf16 matrices in w.halves, fp32 vectors in w.floats
    var s: Scratch
    var wv: Weights[DType.float16, True]  # VLA_MMA16: the ViTs', projector's and LLM's matrices in fp16
    var s16: Scratch
    var mma16: Bool
    var lib: OwnedDLHandle
    var bytes: Int
    var opt: Bool
    var profiling: Bool
    var tag: String
    var L: Int  # prompt tokens
    var gates: List[Float32]  # tanh(gating_factor) per policy block
    # inputs
    var pix_d: DeviceBuffer[DType.float32]  # [2, 3, 224, 224] DINOv2-normalized
    var pix_s: DeviceBuffer[DType.float32]  # [2, 3, 224, 224] SigLIP-normalized
    var ids: DeviceBuffer[DType.int32]  # SP token ids (vision and action-query rows: 0)
    var aq_ids: DeviceBuffer[DType.int32]  # 0 .. 63
    var prop: DeviceBuffer[DType.float32]  # [64, 8]: the normalized state in row 0
    # vision
    var xp: DeviceBuffer[DType.float32]
    var dx: DeviceBuffer[DType.float32]
    var dxn: DeviceBuffer[DType.float32]
    var dqkv: DeviceBuffer[DType.float32]
    var datt: DeviceBuffer[DType.float32]
    var dh: DeviceBuffer[DType.float32]
    var sx: DeviceBuffer[DType.float32]
    var sxn: DeviceBuffer[DType.float32]
    var sqkv: DeviceBuffer[DType.float32]
    var satt: DeviceBuffer[DType.float32]
    var sh: DeviceBuffer[DType.float32]
    var fused: DeviceBuffer[DType.float32]
    var p1: DeviceBuffer[DType.float32]
    var p2: DeviceBuffer[DType.float32]
    var dklev: DeviceBuffer[DType.float32]
    var zlev: DeviceBuffer[DType.float32]
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
    var taps: DeviceBuffer[DType.float32]  # 24 x 576 x 896
    # policy
    var pcos: DeviceBuffer[DType.float32]  # 512 x 112
    var psin: DeviceBuffer[DType.float32]
    var x0: DeviceBuffer[DType.float32]  # the constant first input (8 rows)
    var px: DeviceBuffer[DType.float32]
    var pxn: DeviceBuffer[DType.float32]
    var ph: DeviceBuffer[DType.float32]  # the proprio projector's hidden row
    var ha: DeviceBuffer[DType.float32]  # adapter rows: 64 action-query rows, the proprio token (128 rows)
    var pq: DeviceBuffer[DType.float32]
    var pks: DeviceBuffer[DType.float32]
    var pvs: DeviceBuffer[DType.float32]
    var pka: DeviceBuffer[DType.float32]
    var pva: DeviceBuffer[DType.float32]
    var pkt: DeviceBuffer[DType.float32]
    var pvt: DeviceBuffer[DType.float32]
    var po: DeviceBuffer[DType.float32]
    var actions: DeviceBuffer[DType.float32]  # [64, 64]: rows 0 .. 7, columns 0 .. 6
    # GPU+NPU
    var npu_vision: Int  # VLA_NPU_VISION (vision_ctx.onnx on the laptop): its handle there, or -1
    var npu_llm: Int  # VLA_NPU_LLM (llm_ctx.onnx)
    var mask_add: DeviceBuffer[DType.float32]  # the LLM graph's additive causal mask (SP x SP)
    var idx: DeviceBuffer[DType.int32]  # the LLM graph's window rows (576)
    var npu_ms: Float64

    def __init__(out self, ctx: DeviceContext, path: String) raises:
        self.ctx = ctx
        self.w = Weights[DType.uint16, False](ctx)
        self.s = Scratch(ctx, 64 * FF * 2, 64 * FF * 16, 0, 64)
        self.mma16 = flag("VLA_MMA16")
        self.wv = Weights[DType.float16, True](ctx)
        self.s16 = Scratch(ctx, 64, 64, SP * 2 * FF if self.mma16 else 64, 64)
        self.lib = OwnedDLHandle(plugin_path())
        self.bytes = 0
        self.opt = flag("VLA_OPT")
        self.profiling = False
        self.tag = ""
        self.L = 0
        self.gates = List[Float32]()
        self.pix_d = ctx.enqueue_create_buffer[DType.float32](NIMG * 3 * IMG * IMG)
        self.pix_s = ctx.enqueue_create_buffer[DType.float32](NIMG * 3 * IMG * IMG)
        self.ids = ctx.enqueue_create_buffer[DType.int32](SP)
        self.aq_ids = ctx.enqueue_create_buffer[DType.int32](64)
        self.prop = ctx.enqueue_create_buffer[DType.float32](PR * PROP)
        self.xp = ctx.enqueue_create_buffer[DType.float32](VROWS * KP)
        self.dx = ctx.enqueue_create_buffer[DType.float32](DROWS * DV)
        self.dxn = ctx.enqueue_create_buffer[DType.float32](DROWS * DV)
        self.dqkv = ctx.enqueue_create_buffer[DType.float32](DROWS * 3 * DV)
        self.datt = ctx.enqueue_create_buffer[DType.float32](DROWS * DV)
        self.dh = ctx.enqueue_create_buffer[DType.float32](DROWS * DF)
        self.sx = ctx.enqueue_create_buffer[DType.float32](VROWS * SV)
        self.sxn = ctx.enqueue_create_buffer[DType.float32](VROWS * SV)
        self.sqkv = ctx.enqueue_create_buffer[DType.float32](VROWS * 3 * SV)
        self.satt = ctx.enqueue_create_buffer[DType.float32](VROWS * SV)
        self.sh = ctx.enqueue_create_buffer[DType.float32](VROWS * SFP)
        self.fused = ctx.enqueue_create_buffer[DType.float32](VROWS * PF)
        self.p1 = ctx.enqueue_create_buffer[DType.float32](VROWS * P1)
        self.p2 = ctx.enqueue_create_buffer[DType.float32](VROWS * D)
        self.dklev = ctx.enqueue_create_buffer[DType.float32](DROWS)
        self.zlev = ctx.enqueue_create_buffer[DType.float32](DROWS)
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
        self.rcos = ctx.enqueue_create_buffer[DType.float32](SP * HD // 2)
        self.rsin = ctx.enqueue_create_buffer[DType.float32](SP * HD // 2)
        self.taps = ctx.enqueue_create_buffer[DType.float32](LL * TAP * D)
        self.pcos = ctx.enqueue_create_buffer[DType.float32](VROWS * PHD)
        self.psin = ctx.enqueue_create_buffer[DType.float32](VROWS * PHD)
        self.x0 = ctx.enqueue_create_buffer[DType.float32](PR * D)
        self.px = ctx.enqueue_create_buffer[DType.float32](PR * D)
        self.pxn = ctx.enqueue_create_buffer[DType.float32](PR * D)
        self.ph = ctx.enqueue_create_buffer[DType.float32](PR * D)
        self.ha = ctx.enqueue_create_buffer[DType.float32](128 * D)
        self.pq = ctx.enqueue_create_buffer[DType.float32](PR * D)
        self.pks = ctx.enqueue_create_buffer[DType.float32](PR * D)
        self.pvs = ctx.enqueue_create_buffer[DType.float32](PR * D)
        self.pka = ctx.enqueue_create_buffer[DType.float32](128 * D)
        self.pva = ctx.enqueue_create_buffer[DType.float32](128 * D)
        self.pkt = ctx.enqueue_create_buffer[DType.float32](VROWS * D)
        self.pvt = ctx.enqueue_create_buffer[DType.float32](VROWS * D)
        self.po = ctx.enqueue_create_buffer[DType.float32](PR * D)
        self.actions = ctx.enqueue_create_buffer[DType.float32](PR * 64)
        for buf in [self.dx, self.dxn, self.dqkv, self.datt, self.dh, self.sh, self.x, self.xn, self.qkv, self.kc,
                    self.vc, self.att, self.gu, self.px, self.pxn, self.ph, self.ha, self.pq, self.po, self.prop]:
            ctx.enqueue_memset(buf, Float32(0))
        self.npu_vision = -1
        self.npu_llm = -1
        self.npu_ms = 0
        self.mask_add = ctx.enqueue_create_buffer[DType.float32](SP * SP)
        self.idx = ctx.enqueue_create_buffer[DType.int32](TAP)
        self.load(path)
        self.tables()
        self.npu_vision = self.npug_open("VLA_NPU_VISION")
        self.npu_llm = self.npug_open("VLA_NPU_LLM")

    # weights
    def load(mut self, paths: String) raises:
        """Every tensor inference uses, from the checkpoint files `paths` (comma-separated; VLA_REMOTE: the same
        files on the executor, in the same order), as bf16 bits on the device: matrices stay bf16 (w.halves), the
        rest are widened to fp32 (w.floats). Then the LLM's q/k/v and gate/up concatenated, and the policy gates'
        tanh read back."""
        var files = List[String]()
        for part in paths.split(","):
            files.append(String(part))
        var remotes = List[String]()
        var rem = getenv("VLA_REMOTE")
        if rem:
            for part in rem.split(","):
                remotes.append(String(part))
        for fi in range(len(files)):
            var path = String(files[fi])
            var ck = Checkpoint(path)
            var names = List[String]()
            for e in ck.sizes.items():
                if not skipped(e.key):
                    names.append(e.key)
            var f = open(path, "r")
            for name in names:
                if ck.dtypes[name] != "BF16":
                    raise Error(name + ": not bf16 (" + ck.dtypes[name] + ")")
                var n = ck.sizes[name] // 2
                var buf = self.ctx.enqueue_create_buffer[DType.uint16](n)
                if len(remotes) > 0:
                    var remote = String(remotes[fi])
                    if self.lib.call["M_driver_remote_file", Int32](UInt64(Int(buf.unsafe_ptr())), UInt64(2 * n),
                                                                    remote.as_c_string_span().unsafe_ptr(),
                                                                    UInt64(ck.offsets[name])) != 0:
                        raise Error("M_driver_remote_file failed for " + name)
                else:
                    var data = ck.read(f, name)
                    self.ctx.enqueue_copy(buf, data.unsafe_ptr().unsafe_bitcast[UInt16]())
                    self.ctx.synchronize()
                self.bytes += 2 * n
                if is_matrix(name):
                    self.w.halves[name] = buf
                else:
                    var wide = self.ctx.enqueue_create_buffer[DType.float32](n)
                    self.ctx.enqueue_function[vak.widen](buf, wide, Int32(n), grid_dim=groups(n, 256), block_dim=256)
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
        if self.mma16:
            self.halve()
        for i in range(LL):
            var g = List[Float32](length=1, fill=0)
            self.ctx.enqueue_copy(g.unsafe_ptr(), self.w.floats[AH + "mlp_resnet_blocks." + String(i) +
                                                                 ".gating_factor"])
            self.ctx.synchronize()
            self.gates.append(Float32(tanh(Float64(g[0]))))
        self.ctx.synchronize()

    def halve(mut self) raises:
        """VLA_MMA16: the ViTs', projector's and LLM's matrices (bf16) in fp16, exactly (bf16's 8-bit mantissa fits
        fp16's 10), rows padded to 128, for vgemm.gemm16."""
        var names = List[String]()
        for e in self.w.halves.items():
            var nm = e.key
            if "embed_tokens" in nm or "patch_embed" in nm or "action_queries" in nm:
                continue
            if nm.startswith(VB + "blocks.") or nm.startswith(SB + "blocks.") or nm.startswith(PJ):
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
        """Masks (DINOv2: an image's padding rows never visible as keys; the LLM: causal, by position), the LLM's
        RoPE (theta 1e6, rows by position, 32 frequencies, fp32 as transformers computes them), the policy's RoPE
        (base 1e4, 56 frequencies laid out twice: 112 a row), its aq ids, and the policy's constant first input
        ReLU(fc1(LN(zeros)))."""
        var ctx = self.ctx
        var kl = List[Float32](length=DROWS, fill=0)
        for r in range(DROWS):
            if r % DR >= DPRE + NPATCH:
                kl[r] = INF
        ctx.enqueue_copy(self.dklev, kl.unsafe_ptr())
        ctx.enqueue_memset(self.zlev, Float32(0))
        var c = List[Float32](length=SP * HD // 2, fill=0)
        var s = List[Float32](length=SP * HD // 2, fill=0)
        for i in range(HD // 2):
            var inv = Float32(1.0 / (1.0e6 ** (Float64(Float32(2 * i) / Float32(HD)))))
            for pos in range(SP):
                var f = Float32(pos) * inv
                c[pos * HD // 2 + i] = Float32(cos(Float64(f)))
                s[pos * HD // 2 + i] = Float32(sin(Float64(f)))
        ctx.enqueue_copy(self.rcos, c.unsafe_ptr())
        ctx.enqueue_copy(self.rsin, s.unsafe_ptr())
        var pc = List[Float32](length=VROWS * PHD, fill=0)
        var ps = List[Float32](length=VROWS * PHD, fill=0)
        for i in range(PHD // 2):
            var inv = Float32(1.0 / (1.0e4 ** (Float64(Float32(2 * i) / Float32(PHD)))))
            for pos in range(VROWS):
                var f = Float32(pos) * inv
                for rep in range(2):
                    pc[pos * PHD + rep * (PHD // 2) + i] = Float32(cos(Float64(f)))
                    ps[pos * PHD + rep * (PHD // 2) + i] = Float32(sin(Float64(f)))
        ctx.enqueue_copy(self.pcos, pc.unsafe_ptr())
        ctx.enqueue_copy(self.psin, ps.unsafe_ptr())
        var aq = List[Int32](length=64, fill=0)
        for i in range(64):
            aq[i] = Int32(i)
        ctx.enqueue_copy(self.aq_ids, aq.unsafe_ptr())
        # the policy's first input: LN(zeros) over 7 x 896 is LN's bias, then fc1 and ReLU (the same 8 rows)
        var z = ctx.enqueue_create_buffer[DType.float32](PR * ADIM * D)
        ctx.enqueue_memset(z, Float32(0))
        var zn = ctx.enqueue_create_buffer[DType.float32](PR * ADIM * D)
        self.ln(z, zn, AH + "layer_norm1", PR, ADIM * D)
        self.proj[True, False](AH + "fc1.weight", AH + "fc1.bias", zn, self.x0, PR, D, ADIM * D, ADIM * D, D)
        self.relu(self.x0, PR, D)
        ctx.synchronize()

    def set_inputs(mut self, pixels: List[Float32], ids: List[Int32], L: Int, prop: List[Float32]) raises:
        """pixel_values [12, 224, 224] (per image: DINOv2's 3 channels, SigLIP's 3), the prompt's L token ids, the
        normalized state (8)."""
        self.L = L
        var hw = IMG * IMG
        var d = List[Float32](length=NIMG * 3 * hw, fill=0)
        var sg = List[Float32](length=NIMG * 3 * hw, fill=0)
        for v in range(NIMG):
            for ch in range(3):
                for i in range(hw):
                    d[(v * 3 + ch) * hw + i] = pixels[(v * 6 + ch) * hw + i]
                    sg[(v * 3 + ch) * hw + i] = pixels[(v * 6 + 3 + ch) * hw + i]
        self.ctx.enqueue_copy(self.pix_d, d.unsafe_ptr())
        self.ctx.enqueue_copy(self.pix_s, sg.unsafe_ptr())
        # rows: ids[0], 512 vision rows, ids[1 .. L - 1], 64 action queries, the stop token (2); padding 0
        var r = List[Int32](length=SP, fill=0)
        r[0] = ids[0]
        for i in range(1, L):
            r[VROWS + i] = ids[i]
        r[L + VROWS + 64] = 2
        self.ctx.enqueue_copy(self.ids, r.unsafe_ptr())
        var S = L + VROWS + 65
        var kl = List[Float32](length=SP, fill=0)
        var ql = List[Float32](length=SP, fill=0)
        var pos = List[Int32](length=SP, fill=0)
        for i in range(SP):
            kl[i] = Float32(i) if i < S else INF
            ql[i] = Float32(i) if i < S else Float32(0)
            pos[i] = Int32(i) if i < S else Int32(0)
        self.ctx.enqueue_copy(self.lklev, kl.unsafe_ptr())
        self.ctx.enqueue_copy(self.lqlev, ql.unsafe_ptr())
        self.ctx.enqueue_copy(self.lpos, pos.unsafe_ptr())
        var ma = List[Float32](length=SP * SP, fill=-30000.0)  # the NPU graph's mask: causal; padding rows see row 0
        for i in range(SP):
            if i < S:
                for j in range(i + 1):
                    ma[i * SP + j] = 0
            else:
                ma[i * SP] = 0
        self.ctx.enqueue_copy(self.mask_add, ma.unsafe_ptr())
        var ix = List[Int32](length=TAP, fill=0)
        for i in range(TAP):
            ix[i] = Int32(i) if i < VROWS else Int32(L + VROWS - 1 + i - VROWS)
        self.ctx.enqueue_copy(self.idx, ix.unsafe_ptr())
        var p = List[Float32](length=PR * PROP, fill=0)
        for i in range(PROP):
            p[i] = prop[i]
        self.ctx.enqueue_copy(self.prop, p.unsafe_ptr())
        self.ctx.synchronize()

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
        """GPU+NPU: DINOv2, SigLIP and the projector on the NPU: the vision tokens into the LLM's rows 1 .. 512."""
        var vis = sub(self.x, D, VROWS * D)
        self.npug_run(self.npu_vision, [UInt64(Int(self.pix_d.unsafe_ptr())), UInt64(Int(self.pix_s.unsafe_ptr()))],
                      [UInt64(len(self.pix_d) * 4), UInt64(len(self.pix_s) * 4)], [UInt64(Int(vis.unsafe_ptr()))],
                      [UInt64(VROWS * D * 4)])

    def llm_npu(mut self) raises:
        """GPU+NPU: Qwen2.5-0.5B on the NPU, reading the embedded rows from x; the 24 taps into self.taps."""
        var vis = sub(self.x, D, VROWS * D)
        self.npug_run(self.npu_llm, [UInt64(Int(self.x.unsafe_ptr())), UInt64(Int(vis.unsafe_ptr())),
                                     UInt64(Int(self.mask_add.unsafe_ptr())), UInt64(Int(self.idx.unsafe_ptr()))],
                      [UInt64(SP * D * 4), UInt64(VROWS * D * 4), UInt64(SP * SP * 4), UInt64(TAP * 4)],
                      [UInt64(Int(self.taps.unsafe_ptr()))], [UInt64(LL * TAP * D * 4)])

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
        """A heavy projection (ViTs, projector, LLM): proj, or VLA_MMA16's fp16 matrix units (X and W in fp16, fp16
        sums; the bias and the residual added in fp32)."""
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
           eps: Float32 = EPS5) raises:
        self.ctx.enqueue_function[vrow.layernorm[DType.float32]](
            x, self.w.floats[name + ".weight"], self.w.floats[name + ".bias"], y, Int32(d), Int32(d), Int32(d), eps,
            grid_dim=rows, block_dim=64)
        self.tick("layernorm")

    def rms(self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], name: String) raises:
        self.ctx.enqueue_function[vrow.rmsnorm[DType.float32]](x, self.w.floats[name], y, Int32(D), Int32(D), Int32(D),
                                                               EPS6, Float32(0), grid_dim=SP, block_dim=64)
        self.tick("rmsnorm")

    def act[ACT: Int](self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], rows: Int, n: Int,
                      ld: Int) raises:
        self.ctx.enqueue_function[vgemm.act_rows[ACT]](x, y, Int32(n), Int32(ld), Int32(0), Int32(rows * n),
                                                       grid_dim=groups(rows * n, 256), block_dim=256)
        self.tick("activation")

    def relu(self, x: DeviceBuffer[DType.float32], rows: Int, n: Int) raises:
        self.ctx.enqueue_function[vak.relu_rows](x, Int32(n), Int32(n), Int32(rows * n), grid_dim=groups(rows * n, 256),
                                                 block_dim=256)
        self.tick("relu")

    def layerscale(self, x: DeviceBuffer[DType.float32], d: DeviceBuffer[DType.float32], g: String, rows: Int,
                   n: Int) raises:
        self.ctx.enqueue_function[vak.scale_add](x, d, self.w.floats[g], Int32(n), Int32(rows * n),
                                                 grid_dim=groups(rows * n, 256), block_dim=256)
        self.tick("layerscale")

    # vision
    def dinov2(mut self) raises:
        """DINOv2-L/14 with registers on both images: rows v 320 + (CLS, 4 registers, 256 patches); blocks 0 .. 22.
        The output (no final norm) in dx."""
        self.tag = "dinov2"
        var ctx = self.ctx
        ctx.enqueue_function[vrow.patchify](self.pix_d, self.xp, Int32(IMG), Int32(PATCH), Int32(VROWS * KP),
                                            grid_dim=groups(VROWS * KP, 256), block_dim=256)
        for v in range(NIMG):
            var rows = sub(self.dx, (v * DR + DPRE) * DV, NPATCH * DV)
            self.copy(rows, sub(self.w.floats[VB + "pos_embed"], 0, NPATCH * DV))
            self.proj[True, True](VB + "patch_embed.proj.weight", VB + "patch_embed.proj.bias",
                                  sub(self.xp, v * NPATCH * KP, NPATCH * KP), rows, NPATCH, DV, KP, KP, DV)
            self.copy(sub(self.dx, v * DR * DV, DV), self.w.floats[VB + "cls_token"])
            self.copy(sub(self.dx, (v * DR + 1) * DV, 4 * DV), self.w.floats[VB + "reg_token"])
        for i in range(DLU):
            var p = VB + "blocks." + String(i) + "."
            self.ln(self.dx, self.dxn, p + "norm1", DROWS, DV, EPS6)
            self.hproj[True, False](p + "attn.qkv.weight", p + "attn.qkv.bias", self.dxn, self.dqkv, DROWS, 3 * DV, DV,
                                   DV, 3 * DV)
            attend[True, 64](ctx, self.dqkv, self.dqkv, self.dqkv, self.datt, self.dklev, self.zlev, 3 * DV, 3 * DV,
                             DV, DV, 2 * DV, DR, DHEADS, 1, DR, NIMG, DR, Float32(0.125))
            self.tick("attention")
            self.hproj[True, False](p + "attn.proj.weight", p + "attn.proj.bias", self.datt, self.dxn, DROWS, DV, DV,
                                   DV, DV)
            self.layerscale(self.dx, self.dxn, p + "ls1.scale_factor", DROWS, DV)
            self.ln(self.dx, self.dxn, p + "norm2", DROWS, DV, EPS6)
            self.hproj[True, False](p + "mlp.fc1.weight", p + "mlp.fc1.bias", self.dxn, self.dh, DROWS, DF, DV, DV, DF)
            self.hproj[True, False, GELU_ERF](p + "mlp.fc2.weight", p + "mlp.fc2.bias", self.dh, self.dxn, DROWS, DV,
                                             DF, DF, DV)
            self.layerscale(self.dx, self.dxn, p + "ls2.scale_factor", DROWS, DV)

    def siglip(mut self) raises:
        """SigLIP-So400m/14 on both images (256 rows each), blocks 0 .. 25; the output in sx."""
        self.tag = "siglip"
        var ctx = self.ctx
        ctx.enqueue_function[vrow.patchify](self.pix_s, self.xp, Int32(IMG), Int32(PATCH), Int32(VROWS * KP),
                                            grid_dim=groups(VROWS * KP, 256), block_dim=256)
        for v in range(NIMG):
            self.copy(sub(self.sx, v * NPATCH * SV, NPATCH * SV), sub(self.w.floats[SB + "pos_embed"], 0, NPATCH * SV))
        self.proj[True, True](SB + "patch_embed.proj.weight", SB + "patch_embed.proj.bias", self.xp, self.sx, VROWS,
                              SV, KP, KP, SV)
        var scale = Float32(1 / sqrt(Float64(72)))
        for i in range(SLU):
            var p = SB + "blocks." + String(i) + "."
            self.ln(self.sx, self.sxn, p + "norm1", VROWS, SV, EPS6)
            self.hproj[True, False](p + "attn.qkv.weight", p + "attn.qkv.bias", self.sxn, self.sqkv, VROWS, 3 * SV, SV,
                                   SV, 3 * SV)
            attend[False, 72](ctx, self.sqkv, self.sqkv, self.sqkv, self.satt, self.zlev, self.zlev, 3 * SV, 3 * SV,
                              SV, SV, 2 * SV, NPATCH, SHEADS, 1, NPATCH, NIMG, NPATCH, scale)
            self.tick("attention")
            self.hproj[True, True](p + "attn.proj.weight", p + "attn.proj.bias", self.satt, self.sx, VROWS, SV, SV, SV,
                                  SV)
            self.ln(self.sx, self.sxn, p + "norm2", VROWS, SV, EPS6)
            self.hproj[True, False](p + "mlp.fc1.weight", p + "mlp.fc1.bias", self.sxn, self.sh, VROWS, SF, SV, SV, SFP)
            self.hproj[True, True, GELU_ERF](p + "mlp.fc2.weight", p + "mlp.fc2.bias", self.sh, self.sx, VROWS, SV, SF,
                                            SFP, SV)

    def projector(mut self) raises:
        """[DINOv2 | SigLIP] per patch (2176) through fc1, GELU, fc2, GELU, fc3: the LLM's rows 1 .. 512."""
        self.tag = "projector"
        self.ctx.enqueue_function[vak.fuse_cols](self.dx, self.sx, self.fused, Int32(DR), Int32(DPRE), Int32(NPATCH),
                                                 Int32(DV), Int32(SV), Int32(VROWS * PF),
                                                 grid_dim=groups(VROWS * PF, 256), block_dim=256)
        self.tick("fuse")
        self.hproj[True, False](PJ + "fc1.weight", PJ + "fc1.bias", self.fused, self.p1, VROWS, P1, PF, PF, P1)
        self.hproj[True, False, GELU_ERF](PJ + "fc2.weight", PJ + "fc2.bias", self.p1, self.p2, VROWS, D, P1, P1, D)
        self.hproj[True, False, GELU_ERF](PJ + "fc3.weight", PJ + "fc3.bias", self.p2, sub(self.x, D, VROWS * D),
                                         VROWS, D, D, D, D)

    def vision(mut self) raises:
        self.dinov2()
        self.siglip()

    # the language model
    def embed(mut self) raises:
        """The token rows (the prompt and the stop token) and the 64 action queries around the vision rows that
        projector() wrote: embed() first, then projector()."""
        self.tag = "embed"
        var ctx = self.ctx
        ctx.enqueue_function[vrow.embed_rows[DType.uint16]](self.w.halves[LM + "embed_tokens.weight"], self.ids,
                                                            self.x, Int32(D), Int32(D), Float32(1), grid_dim=SP,
                                                            block_dim=64)
        ctx.enqueue_function[vrow.embed_rows[DType.uint16]](self.w.halves["action_queries.weight"], self.aq_ids,
                                                            sub(self.x, (self.L + VROWS) * D, 64 * D), Int32(D),
                                                            Int32(D), Float32(1), grid_dim=64, block_dim=64)
        self.tick("embeddings")

    def llm(mut self) raises:
        """Qwen2.5-0.5B's 24 layers over the SP rows; after layer j, the task window (rows 0 .. 511) and the
        action-query window (rows L + 511 .. L + 574) into tap j - 1; the last tap after the final RMSNorm."""
        self.tag = "llm"
        var ctx = self.ctx
        var aq0 = self.L + VROWS - 1
        for l in range(LL):
            var p = LM + "layers." + String(l) + "."
            self.rms(self.x, self.xn, p + "input_layernorm.weight")
            self.hproj[True, False](p + "qkv.weight", p + "qkv.bias", self.xn, self.qkv, SP, QKV, D, D, QKV)
            ctx.enqueue_function[vrow.rope_qk](self.qkv, self.rcos, self.rsin, self.lpos, self.kc, self.vc,
                                               Int32(QKV), Int32(QH), Int32(KVH), Int32(KVH * HD), Int32(0), Int32(HD),
                                               grid_dim=SP, block_dim=64)
            self.tick("rope")
            attend[True, HD](ctx, self.qkv, self.kc, self.vc, self.att, self.lklev, self.lqlev, QKV, KVH * HD, D, 0, 0,
                             SP, QH, QH // KVH, SP, 1, 0, Float32(0.125))
            self.tick("attention")
            self.hproj[False, True](p + "self_attn.o_proj.weight", "", self.att, self.x, SP, D, D, D, D)
            self.rms(self.x, self.xn, p + "post_attention_layernorm.weight")
            self.hproj[False, False](p + "gate_up.weight", "", self.xn, self.gu, SP, 2 * FF, D, D, 2 * FF)
            self.hproj[False, True, SILU_MUL](p + "mlp.down_proj.weight", "", self.gu, self.x, SP, D, FF, 2 * FF, D,
                                             xoff=FF)
            var src = self.x
            if l == LL - 1:
                self.rms(self.x, self.xn, LM + "norm.weight")
                src = self.xn
            var t = l * TAP * D
            self.copy(sub(self.taps, t, VROWS * D), sub(src, 0, VROWS * D))
            self.copy(sub(self.taps, t + VROWS * D, 64 * D), sub(src, aq0 * D, 64 * D))

    # the policy
    def policy(mut self) raises:
        """The proprio token, then the 24 Pro blocks over 8 rows, LN and fc2: the normalized actions."""
        self.policy_start()
        for i in range(LL):
            self.policy_block(i)
        self.policy_end()

    def policy_start(mut self) raises:
        """The proprio projector's token (row 64 of the adapter rows) and the constant first input."""
        self.tag = "policy"
        self.proj[True, False](PP + "fc1.weight", PP + "fc1.bias", self.prop, self.ph, PR, D, PROP, PROP, D)
        self.proj[True, False, GELU_ERF](PP + "fc2.weight", PP + "fc2.bias", self.ph, self.pxn, PR, D, D, D, D)
        self.copy(sub(self.ha, 64 * D, D), sub(self.pxn, 0, D))
        self.copy(self.px, self.x0)

    def policy_block(mut self, i: Int) raises:
        """Block i over px (8 rows), reading tap i."""
        var ctx = self.ctx
        var p = AH + "mlp_resnet_blocks." + String(i) + "."
        var tap = i * TAP * D
        self.copy(sub(self.ha, 0, 64 * D), sub(self.taps, tap + VROWS * D, 64 * D))
        self.proj[True, False](p + "q_proj.weight", p + "q_proj.bias", self.px, self.pq, PR, D, D, D, D)
        self.proj[True, False](p + "k_self.weight", p + "k_self.bias", self.px, self.pks, PR, D, D, D, D)
        self.proj[True, False](p + "v_self.weight", p + "v_self.bias", self.px, self.pvs, PR, D, D, D, D)
        self.proj[True, False](p + "k_adapter.weight", p + "k_adapter.bias", self.ha, self.pka, 128, D, D, D, D)
        self.proj[True, False](p + "v_adapter.weight", p + "v_adapter.bias", self.ha, self.pva, 128, D, D, D, D)
        self.proj[True, False](p + "k_task.weight", p + "k_task.bias", sub(self.taps, tap, VROWS * D), self.pkt,
                               VROWS, D, D, D, D)
        self.proj[True, False](p + "v_task.weight", p + "v_task.bias", sub(self.taps, tap, VROWS * D), self.pvt,
                               VROWS, D, D, D, D)
        self.rope(self.pq, CH)
        self.rope(self.pks, CH)
        self.rope(self.pka, NA)
        self.rope(self.pkt, VROWS)
        ctx.enqueue_function[vak.policy_attention](self.pq, self.pks, self.pvs, self.pka, self.pva, self.pkt, self.pvt,
                                                   self.po, Int32(D), Int32(CH), Int32(NA), Int32(VROWS),
                                                   self.gates[i], Float32(1 / sqrt(Float64(PHD))),
                                                   grid_dim=Dim(PHEADS, CH), block_dim=64)
        self.tick("attention")
        self.proj[True, True](p + "o_proj.weight", p + "o_proj.bias", self.po, self.px, PR, D, D, D, D)
        self.ln(self.px, self.pxn, p + "ffn.0", PR, D)
        self.proj[True, False](p + "ffn.1.weight", p + "ffn.1.bias", self.pxn, self.px, PR, D, D, D, D)
        self.relu(self.px, PR, D)

    def policy_end(mut self) raises:
        self.ln(self.px, self.pxn, AH + "layer_norm2", PR, D)
        self.proj[True, False](AH + "fc2.weight", AH + "fc2.bias", self.pxn, self.actions, PR, ADIM, D, D, 64)

    def rope(self, x: DeviceBuffer[DType.float32], rows: Int) raises:
        """The policy's RoPE on rows 0 .. rows - 1 (their positions)."""
        self.ctx.enqueue_function[vak.rope_policy](x, self.pcos, self.psin, Int32(D), Int32(PHEADS), grid_dim=rows,
                                                   block_dim=64)
        self.tick("rope")

    def copy(self, dst: DeviceBuffer[DType.float32], src: DeviceBuffer[DType.float32]) raises:
        self.ctx.enqueue_copy(dst, src)

    def chunk(mut self) raises:
        """One action chunk: vision, projector, LLM, policy (GPU+NPU: vision and the LLM on the NPU). Enqueued
        only."""
        self.embed()
        if self.npu_vision >= 0:
            self.vision_npu()
        else:
            self.vision()
            self.projector()
        if self.npu_llm >= 0:
            self.llm_npu()
        else:
            self.llm()
        self.policy()
