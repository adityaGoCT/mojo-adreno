# Octo-Small 1.5 (rail-berkeley/octo-small-1.5, 27M parameters and a frozen T5-base encoder) as MAX DeviceContext
# launches: a 4 x 7 action chunk from a window of two frames of a 256 x 256 primary and a 128 x 128 wrist camera and
# an instruction. octo/reference.py runs Octo's own JAX model; every stage below matches one of its tensors.
#   text()     T5-base's encoder over the instruction's 16 tokens (once per instruction), then the projection to
#              384 and the task position embedding: the 16 task tokens
#   stem(cam)  SmallStem16 on both frames of a camera, the image and the (zero) goal image as 6 channels:
#              4 x (3 x 3 stride-2 convolution as im2col + projection, GroupNorm(32), ReLU), the 1 x 1 embedding
#              to 512: 256 tokens a primary frame, 64 a wrist frame
#   tokens()   the 690 rows: 16 task tokens, then per frame 256 primary + 64 wrist (projected to 384, plus their
#              position embeddings), the 16 task tokens again and a readout token
#   trunk()    12 pre-LN ViT blocks of 384 (6 heads of 64, MLP 1536 with tanh GELU) under Octo's block-causal mask
#              (two levels a row, vattn's LV2), the final LayerNorm
#   head()     the last frame's readout through the diffusion head: 20 DDPM steps of a 3-block MLP-ResNet (256),
#              noise given; then the 4 x 7 normalized actions
#
# Weights: fp32, from Octo's checkpoint as octo/reference.py --export writes it (octo_small.safetensors: Dense
# kernels as (out, in), convolutions (O, H, W, I) already standardized). With a remote GPU (the X2 Elite laptop
# behind vla/x2's server), OCTO_REMOTE names the same file on the executor's disk (M_driver_remote_file).
# Rows are padded to the matmuls' 64.
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.math import cos, sin, sqrt
from std.os import getenv
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

from host import Scratch, Weights, groups, lin
from safetensors import Checkpoint
import ok
import vattn
import vgemm
import vrow
from vgemm import GELU, NONE, SILU

comptime W = 2  # frames in the window
comptime D = 384
comptime L = 12
comptime NH = 6
comptime HD = 64
comptime MLP = 1536
comptime NT = 16  # task (language) tokens
comptime NPR = 256  # primary tokens a frame
comptime NWR = 64  # wrist tokens a frame
comptime PER = NPR + NWR + NT + 1  # 337 rows a frame
comptime N = NT + W * PER  # 690
comptime NP = 704  # rows, padded
comptime READOUT = NT + 2 * PER - 1  # 689: the last frame's readout
comptime EMB = 512
comptime TD = 768  # T5-base
comptime TL = 12
comptime TH = 12
comptime TF = 3072
comptime TR = 64
comptime AD = 28  # 4 x 7 actions
comptime HID = 256
comptime HX = 1024
comptime TDIM = 32
comptime STEPS = 20
comptime HR = 64
comptime KIN = TDIM + D + AD  # 444
comptime LDIN = 448
comptime EPS: Float32 = 1e-6
comptime INF: Float32 = 1e30

comptime OT = "octo_transformer."
comptime TB = "octo_transformer.BlockTransformer_0.Transformer_0."
comptime T5 = "octo_transformer.task_tokenizers_language.hf_model."
comptime DM = "heads_action.diffusion_model."
comptime RN = "heads_action.diffusion_model.reverse_network."


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


struct Octo(Movable):
    var ctx: DeviceContext
    var w: Weights[DType.float16, False]  # fp32 tensors in w.floats; OCTO_F16's fp16 projections in w.halves
    var s: Scratch
    var wv: Weights[DType.float16, True]  # OCTO_MMA16: the trunk's projections for the fp16 matrix units
    var s16: Scratch
    var lib: OwnedDLHandle
    var bytes: Int
    var opt: Bool
    var f16: Bool
    var mma16: Bool
    var record: Bool  # keep every denoising step's x (xs), for the check
    var profiling: Bool
    var tag: String
    # inputs
    var pix_p: DeviceBuffer[DType.float32]  # [2, 256, 256, 6]: frame, goal; normalized
    var pix_w: DeviceBuffer[DType.float32]  # [2, 128, 128, 6]
    var ids: DeviceBuffer[DType.int32]
    var tmask: DeviceBuffer[DType.int32]
    var noise: DeviceBuffer[DType.float32]  # the last frame's initial noise (28)
    var z: DeviceBuffer[DType.float32]  # z for time t at row t (20 x 28)
    var sched: DeviceBuffer[DType.float32]  # c1, c2, sigma for time t (20 x 3)
    var c1: List[Float32]
    var c2: List[Float32]
    var sigma: List[Float32]
    # stem
    var col: DeviceBuffer[DType.float32]
    var a1: DeviceBuffer[DType.float32]
    var a2: DeviceBuffer[DType.float32]
    var a3: DeviceBuffer[DType.float32]
    var a4: DeviceBuffer[DType.float32]
    var emb_p: DeviceBuffer[DType.float32]
    var emb_w: DeviceBuffer[DType.float32]
    # T5
    var t5x: DeviceBuffer[DType.float32]
    var t5n: DeviceBuffer[DType.float32]
    var t5qkv: DeviceBuffer[DType.float32]
    var t5att: DeviceBuffer[DType.float32]
    var t5h: DeviceBuffer[DType.float32]
    var lang: DeviceBuffer[DType.float32]  # the 16 task tokens (rows 0 .. 15)
    # trunk
    var x: DeviceBuffer[DType.float32]
    var xn: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var h: DeviceBuffer[DType.float32]
    var h2: DeviceBuffer[DType.float32]
    var klev: DeviceBuffer[DType.float32]
    var qlev: DeviceBuffer[DType.float32]
    # head
    var condtab: DeviceBuffer[DType.float32]  # the time conditioning for t = 0 .. 19 (rows of 32)
    var hin: DeviceBuffer[DType.float32]
    var hh: DeviceBuffer[DType.float32]
    var hn: DeviceBuffer[DType.float32]
    var hb: DeviceBuffer[DType.float32]
    var hb2: DeviceBuffer[DType.float32]
    var eps: DeviceBuffer[DType.float32]
    var ax: DeviceBuffer[DType.float32]  # the noisy actions (28)
    var xs: DeviceBuffer[DType.float32]  # x after time t's step, row t (20 x 28)
    # GPU+NPU
    var npu: Int  # OCTO_NPU_OBS_TRUNK (the compiled obs + trunk graph on the laptop): its handle there, or -1
    var mask_add: DeviceBuffer[DType.float32]  # the trunk's mask, additive (690 x 690), for the NPU graph

    def __init__(out self, ctx: DeviceContext, path: String) raises:
        self.ctx = ctx
        self.w = Weights[DType.float16, False](ctx)
        self.s = Scratch(ctx, TR * TF, TR * TF * 16, 0, TR)
        self.wv = Weights[DType.float16, True](ctx)
        self.s16 = Scratch(ctx, 64, 64, NP * MLP, TR)
        self.lib = OwnedDLHandle(plugin_path())
        self.bytes = 0
        self.opt = flag("OCTO_OPT")
        self.f16 = flag("OCTO_F16")
        self.mma16 = flag("OCTO_MMA16")
        self.record = True
        self.profiling = False
        self.tag = ""
        self.pix_p = ctx.enqueue_create_buffer[DType.float32](W * 256 * 256 * 6)
        self.pix_w = ctx.enqueue_create_buffer[DType.float32](W * 128 * 128 * 6)
        self.ids = ctx.enqueue_create_buffer[DType.int32](TR)
        self.tmask = ctx.enqueue_create_buffer[DType.int32](TR)
        self.noise = ctx.enqueue_create_buffer[DType.float32](64)
        self.z = ctx.enqueue_create_buffer[DType.float32](STEPS * AD)
        self.sched = ctx.enqueue_create_buffer[DType.float32](STEPS * 3)
        self.c1 = List[Float32]()
        self.c2 = List[Float32]()
        self.sigma = List[Float32]()
        self.col = ctx.enqueue_create_buffer[DType.float32](W * 64 * 64 * 288)
        self.a1 = ctx.enqueue_create_buffer[DType.float32](W * 128 * 128 * 64)
        self.a2 = ctx.enqueue_create_buffer[DType.float32](W * 64 * 64 * 128)
        self.a3 = ctx.enqueue_create_buffer[DType.float32](W * 32 * 32 * 192)
        self.a4 = ctx.enqueue_create_buffer[DType.float32](W * 16 * 16 * 384)
        self.emb_p = ctx.enqueue_create_buffer[DType.float32](W * NPR * EMB)
        self.emb_w = ctx.enqueue_create_buffer[DType.float32](W * NWR * EMB)
        self.t5x = ctx.enqueue_create_buffer[DType.float32](TR * TD)
        self.t5n = ctx.enqueue_create_buffer[DType.float32](TR * TD)
        self.t5qkv = ctx.enqueue_create_buffer[DType.float32](TR * 3 * TD)
        self.t5att = ctx.enqueue_create_buffer[DType.float32](TR * TD)
        self.t5h = ctx.enqueue_create_buffer[DType.float32](TR * TF)
        self.lang = ctx.enqueue_create_buffer[DType.float32](TR * D)
        self.x = ctx.enqueue_create_buffer[DType.float32](NP * D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](NP * D)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](NP * 3 * D)
        self.att = ctx.enqueue_create_buffer[DType.float32](NP * D)
        self.h = ctx.enqueue_create_buffer[DType.float32](NP * MLP)
        self.h2 = ctx.enqueue_create_buffer[DType.float32](NP * MLP)
        self.klev = ctx.enqueue_create_buffer[DType.float32](2 * NP)
        self.qlev = ctx.enqueue_create_buffer[DType.float32](2 * NP)
        self.condtab = ctx.enqueue_create_buffer[DType.float32](HR * TDIM)
        self.hin = ctx.enqueue_create_buffer[DType.float32](HR * LDIN)
        self.hh = ctx.enqueue_create_buffer[DType.float32](HR * HID)
        self.hn = ctx.enqueue_create_buffer[DType.float32](HR * HID)
        self.hb = ctx.enqueue_create_buffer[DType.float32](HR * HX)
        self.hb2 = ctx.enqueue_create_buffer[DType.float32](HR * HX)
        self.eps = ctx.enqueue_create_buffer[DType.float32](HR * 64)
        self.ax = ctx.enqueue_create_buffer[DType.float32](64)
        self.xs = ctx.enqueue_create_buffer[DType.float32](STEPS * AD)
        for buf in [self.t5x, self.t5n, self.t5qkv, self.t5att, self.t5h, self.lang, self.x, self.xn, self.qkv,
                    self.att, self.h, self.h2, self.hin, self.hh, self.hn, self.hb, self.hb2, self.eps, self.ax]:
            ctx.enqueue_memset(buf, Float32(0))
        self.npu = -1
        self.mask_add = ctx.enqueue_create_buffer[DType.float32](N * N)
        self.load(path)
        self.tables()
        var graph = getenv("OCTO_NPU_OBS_TRUNK")
        if graph:
            var ms = Float64(0)
            var h = self.lib.call["M_driver_remote_npug_open", Int32](graph.as_c_string_span().unsafe_ptr(),
                                                                      Pointer(to=ms))
            if h < 0:
                raise Error("M_driver_remote_npug_open failed: is the server vk_server_npu.exe, run from its DLLs?")
            self.npu = Int(h)
            print("NPU: the obs + trunk graph", graph, "opened in", round(ms, 1), "ms")

    # weights
    def load(mut self, path: String) raises:
        """Every tensor of the checkpoint (fp32) as a device buffer, then the derived ones: the first
        convolution's taps padded to 56; GPU optimized: the trunk's q/k/v as one projection and the head's
        weights transposed for its one-launch denoising; OCTO_F16: projections in fp16."""
        var ck = Checkpoint(path)
        var remote = getenv("OCTO_REMOTE")
        var names = List[String]()
        for e in ck.sizes.items():
            names.append(e.key)
        if remote:
            for name in names:
                if ck.dtypes[name] != "F32":
                    raise Error(name + ": not fp32")
                var n = ck.sizes[name]
                var buf = self.ctx.enqueue_create_buffer[DType.float32](n // 4)
                if self.lib.call["M_driver_remote_file", Int32](UInt64(Int(buf.unsafe_ptr())), UInt64(n),
                                                                remote.as_c_string_span().unsafe_ptr(),
                                                                UInt64(ck.offsets[name])) != 0:
                    raise Error("M_driver_remote_file failed for " + name)
                self.w.floats[name] = buf
                self.bytes += n
            self.ctx.synchronize()
        else:
            var f = open(path, "r")
            for name in names:
                var data = ck.read(f, name)
                var buf = self.ctx.enqueue_create_buffer[DType.float32](len(data) // 4)
                self.ctx.enqueue_copy(buf, data.unsafe_ptr().unsafe_bitcast[Float32]())
                self.ctx.synchronize()
                self.w.floats[name] = buf
                self.bytes += len(data)
        for cam in ["primary", "wrist"]:
            var k = OT + "observation_tokenizers_" + cam + ".SmallStem16_0.StdConv_0.kernel"
            var padded = self.ctx.enqueue_create_buffer[DType.float32](32 * 56)
            self.ctx.enqueue_function[ok.pad_cols](self.w.floats[k], padded, Int32(54), Int32(56), Int32(32 * 56),
                                                   grid_dim=groups(32 * 56, 256), block_dim=256)
            self.w.floats[k + "56"] = padded
        if self.opt:
            self.fuse()
        if self.f16:
            self.halve()
        self.ctx.synchronize()

    def cat(mut self, key: String, names: List[String], n: Int) raises:
        """A device tensor made of the tensors `names` (n floats each, rows concatenated)."""
        var buf = self.ctx.enqueue_create_buffer[DType.float32](len(names) * n)
        for i in range(len(names)):
            self.ctx.enqueue_copy(sub(buf, i * n, n), self.w.floats[names[i]])
        self.w.floats[key] = buf

    def transposed(mut self, key: String, name: String, rows: Int, cols: Int) raises -> DeviceBuffer[DType.float32]:
        var src = self.w.floats[name]
        var dst = self.ctx.enqueue_create_buffer[DType.float32](rows * cols)
        self.ctx.enqueue_function[ok.transpose](src, dst, Int32(rows), Int32(cols), Int32(rows * cols),
                                                grid_dim=groups(rows * cols, 256), block_dim=256)
        self.w.floats[key] = dst
        return dst

    def fuse(mut self) raises:
        """GPU optimized: the trunk's q/k/v as one projection; the head's weights transposed (k x n) for
        ok.diffusion_head, the three blocks' back to back."""
        for i in range(L):
            var a = TB + "encoderblock_" + String(i) + ".MultiHeadDotProductAttention_0."
            self.cat(a + "qkv.kernel", [a + "query.kernel", a + "key.kernel", a + "value.kernel"], D * D)
            self.cat(a + "qkv.bias", [a + "query.bias", a + "key.bias", a + "value.bias"], D)
        _ = self.transposed("head.in_t", RN + "Dense_0.kernel", HID, KIN)
        _ = self.transposed("head.out_t", RN + "Dense_1.kernel", AD, HID)
        var up = List[String]()
        var dn = List[String]()
        var g = List[String]()
        var b = List[String]()
        var bu = List[String]()
        var bd = List[String]()
        for blk in range(3):
            var p = RN + "MLPResNetBlock_" + String(blk) + "."
            _ = self.transposed("head.up_t" + String(blk), p + "Dense_0.kernel", HX, HID)
            _ = self.transposed("head.dn_t" + String(blk), p + "Dense_1.kernel", HID, HX)
            up.append("head.up_t" + String(blk))
            dn.append("head.dn_t" + String(blk))
            g.append(p + "LayerNorm_0.scale")
            b.append(p + "LayerNorm_0.bias")
            bu.append(p + "Dense_0.bias")
            bd.append(p + "Dense_1.bias")
        self.cat("head.up_t", up, HID * HX)
        self.cat("head.dn_t", dn, HX * HID)
        self.cat("head.ln_g", g, HID)
        self.cat("head.ln_b", b, HID)
        self.cat("head.b_up", bu, HX)
        self.cat("head.b_dn", bd, HID)
        self.ctx.synchronize()

    def halve(mut self) raises:
        """OCTO_F16: the trunk's and the stems' projection weights in fp16 (w.halves; OCTO_MMA16: the trunk's in
        wv, for the fp16 matrix units). Norms, biases, embeddings, T5 and the head stay fp32."""
        var names = List[String]()
        for e in self.w.floats.items():
            var nm = e.key
            if not nm.endswith("kernel") and not nm.endswith("kernel56"):
                continue
            var stem = "SmallStem16_0" in nm and not nm.endswith("StdConv_0.kernel")
            var obs = nm.startswith(OT + "obs_") and nm.endswith("projection.kernel")
            if nm.startswith(TB) or stem or obs:
                names.append(nm)
        for nm in names:
            var src = self.w.floats[nm]
            var n = len(src)
            var dst = self.ctx.enqueue_create_buffer[DType.float16](n)
            self.ctx.enqueue_function[ok.to_f16](src, dst, Int32(n), grid_dim=groups(n, 256), block_dim=256)
            if self.mma16 and nm.startswith(TB):
                var cols = MLP if "Dense_1" in nm else D
                var padded = (n // cols + 127) // 128 * 128 * cols
                var dp = self.ctx.enqueue_create_buffer[DType.float16](padded)
                self.ctx.enqueue_memset(dp, Float16(0))
                self.ctx.enqueue_copy(dp.create_sub_buffer[DType.float16](0, n), dst)
                self.wv.halves[nm] = dp
            else:
                self.w.halves[nm] = dst
            _ = self.w.floats.pop(nm)
        self.ctx.synchronize()

    def tables(mut self) raises:
        """The trunk's mask as two levels a row (key j visible to query i when both of j's are <= i's): task
        (0, 0); a frame's observation tokens (t + 1, 0); its readout (t + 1, 1); padding keys never. And the head's
        time conditioning for t = 0 .. 19: cond_encoder(Fourier features of t)."""
        var kl = List[Float32](length=2 * NP, fill=0)
        var ql = List[Float32](length=2 * NP, fill=0)
        for r in range(NP):
            if r >= N:
                kl[2 * r] = INF
                kl[2 * r + 1] = INF
            elif r >= NT:
                var t = (r - NT) // PER
                var j = (r - NT) % PER
                var lv = Float32(t + 1)
                var lv2 = Float32(1) if j == PER - 1 else Float32(0)
                kl[2 * r] = lv
                kl[2 * r + 1] = lv2
                ql[2 * r] = lv
                ql[2 * r + 1] = lv2
        self.ctx.enqueue_copy(self.klev, kl.unsafe_ptr())
        self.ctx.enqueue_copy(self.qlev, ql.unsafe_ptr())
        var ma = List[Float32](length=N * N, fill=0)
        for i in range(N):
            for j in range(N):
                if not (kl[2 * j] <= ql[2 * i] and kl[2 * j + 1] <= ql[2 * i + 1]):
                    ma[i * N + j] = -30000.0
        self.ctx.enqueue_copy(self.mask_add, ma.unsafe_ptr())
        # Fourier features: f = (2 pi t) w (fp32, as JAX: (2 pi) t, then times w), [cos f, sin f]
        var wf = List[Float32](length=16, fill=0)
        self.ctx.enqueue_copy(wf.unsafe_ptr(), self.w.floats[DM + "time_preprocess.kernel"])
        self.ctx.synchronize()
        var ff = List[Float32](length=HR * TDIM, fill=0)
        for t in range(STEPS):
            var a = Float32(6.283185307179586) * Float32(t)
            for i in range(16):
                var f = a * wf[i]
                ff[t * TDIM + i] = Float32(cos(Float64(f)))
                ff[t * TDIM + 16 + i] = Float32(sin(Float64(f)))
        var ffb = self.ctx.enqueue_create_buffer[DType.float32](HR * TDIM)
        self.ctx.enqueue_copy(ffb, ff.unsafe_ptr())
        var c64 = self.ctx.enqueue_create_buffer[DType.float32](HR * 64)
        self.proj[True, False](DM + "cond_encoder.Dense_0.kernel", DM + "cond_encoder.Dense_0.bias", ffb, c64, HR,
                               64, TDIM, TDIM, 64)
        self.proj[True, False, SILU](DM + "cond_encoder.Dense_1.kernel", DM + "cond_encoder.Dense_1.bias", c64,
                                     self.condtab, HR, TDIM, 64, 64, TDIM)
        self.ctx.synchronize()

    def set_inputs(mut self, prim: List[UInt8], wrist: List[UInt8], ids: List[Int32], mask: List[Int32],
                   noise: List[Float32], z: List[Float32], betas: List[Float32], alphas: List[Float32],
                   alpha_hats: List[Float32]) raises:
        """Images (frames x h x w x 3, uint8) as the stems' 6 channels, the frame's then the zero goal image's,
        each x / 127.5 - 1 (Octo's normalize_images); T5's tokens; the last frame's noise: the initial (28) and
        z per scan step (step s is time 19 - s); the DDPM constants per time."""
        for cam in range(2):
            var size = 256 if cam == 0 else 128
            var src = prim.copy() if cam == 0 else wrist.copy()
            var px = List[Float32](length=W * size * size * 6, fill=0)
            for p in range(W * size * size):
                for c in range(3):
                    px[p * 6 + c] = Float32(src[p * 3 + c]) / Float32(127.5) - Float32(1)
                    px[p * 6 + 3 + c] = Float32(0) / Float32(127.5) - Float32(1)
            var dst = self.pix_p if cam == 0 else self.pix_w
            self.ctx.enqueue_copy(dst, px.unsafe_ptr())
        var i64 = List[Int32](length=TR, fill=0)
        var m64 = List[Int32](length=TR, fill=0)
        for i in range(NT):
            i64[i] = ids[i]
            m64[i] = mask[i]
        self.ctx.enqueue_copy(self.ids, i64.unsafe_ptr())
        self.ctx.enqueue_copy(self.tmask, m64.unsafe_ptr())
        var n64 = List[Float32](length=64, fill=0)
        for i in range(AD):
            n64[i] = noise[i]
        self.ctx.enqueue_copy(self.noise, n64.unsafe_ptr())
        var zt = List[Float32](length=STEPS * AD, fill=0)
        for s in range(STEPS):
            for i in range(AD):
                zt[(STEPS - 1 - s) * AD + i] = z[s * AD + i]
        self.ctx.enqueue_copy(self.z, zt.unsafe_ptr())
        var sc = List[Float32](length=STEPS * 3, fill=0)
        self.c1 = List[Float32]()
        self.c2 = List[Float32]()
        self.sigma = List[Float32]()
        for t in range(STEPS):
            var c1 = Float32(1) / sqrt(alphas[t])
            var c2 = (Float32(1) - alphas[t]) / sqrt(Float32(1) - alpha_hats[t])
            var sg = sqrt(betas[t]) if t > 0 else Float32(0)
            self.c1.append(c1)
            self.c2.append(c2)
            self.sigma.append(sg)
            sc[t * 3] = c1
            sc[t * 3 + 1] = c2
            sc[t * 3 + 2] = sg
        self.ctx.enqueue_copy(self.sched, sc.unsafe_ptr())
        self.ctx.synchronize()

    def tick(self, what: String) raises:
        """Profiling: wait for the operation just enqueued and name it (VK_SERVER_SEGMENTS times it)."""
        if self.profiling:
            self.ctx.synchronize()
            print("mark", self.tag + " | " + what)

    # launches
    def proj[BIAS: Bool, RES: Bool, ACT: Int = NONE](self, wname: String, bname: String,
                                                     x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
                                                     rows: Int, n: Int, k: Int, ldx: Int, ldy: Int) raises:
        """y = act(x) W^T (+ b) (+ y); ACT applies to x as the matmul stages it."""
        lin[DType.float16, False, ACT, BIAS, RES](self.w, self.s, wname, bname, x, y, rows, n, k, ldx, ldy)
        self.tick("proj " + String(rows) + "x" + String(n) + "x" + String(k))

    def tproj[BIAS: Bool, RES: Bool, ACT: Int = NONE](self, wname: String, bname: String,
                                                      x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
                                                      rows: Int, n: Int, k: Int, ldx: Int, ldy: Int) raises:
        """A trunk projection: proj, or OCTO_MMA16's fp16 matrix units (vgemm.gemm16, fp16 sums)."""
        if not self.mma16:
            self.proj[BIAS, RES, ACT](wname, bname, x, y, rows, n, k, ldx, ldy)
            return
        var b = self.w.floats[bname] if BIAS else self.s16.xa
        var ctx = self.ctx
        var w16 = self.wv.halves[wname]
        ctx.enqueue_function[vgemm.to_half[ACT]](x, self.s16.xh, Int32(k), Int32(ldx), Int32(0), Float32(1),
                                                 Int32(rows * k), grid_dim=groups(rows * k, 256), block_dim=256)
        ctx.enqueue_function[vgemm.gemm16[1, 2]](self.s16.xh, w16, self.s16.yh, Int32(n), Int32(k), Int32(ldy),
                                                 grid_dim=Dim(groups(n, 128), rows // 64), block_dim=128)
        ctx.enqueue_function[vgemm.finish16[BIAS, RES]](self.s16.yh, b, y, Int32(n), Int32(ldy), Int32(rows * n),
                                                        grid_dim=groups(rows * n, 256), block_dim=256)
        self.tick("proj16 " + String(rows) + "x" + String(n) + "x" + String(k))

    def ln(self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], name: String, rows: Int, d: Int,
           ldx: Int, ldy: Int) raises:
        self.ctx.enqueue_function[vrow.layernorm[DType.float32]](
            x, self.w.floats[name + ".scale"], self.w.floats[name + ".bias"], y, Int32(ldx), Int32(ldy), Int32(d), EPS,
            grid_dim=rows, block_dim=64)
        self.tick("layernorm")

    def rms(self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], name: String) raises:
        self.ctx.enqueue_function[vrow.rmsnorm[DType.float32]](x, self.w.floats[name], y, Int32(TD), Int32(TD),
                                                               Int32(TD), EPS, Float32(0), grid_dim=TR, block_dim=64)
        self.tick("rmsnorm")

    def act[ACT: Int](self, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32], rows: Int,
                      n: Int) raises:
        self.ctx.enqueue_function[vgemm.act_rows[ACT]](x, y, Int32(n), Int32(n), Int32(0), Int32(rows * n),
                                                       grid_dim=groups(rows * n, 256), block_dim=256)
        self.tick("activation")

    def copy(self, dst: DeviceBuffer[DType.float32], src: DeviceBuffer[DType.float32]) raises:
        self.ctx.enqueue_copy(dst, src)

    # the instruction
    def text(mut self) raises:
        """T5-base's encoder over the 16 tokens (rows 0 .. 15 of 64), the projection and the task position
        embedding: lang."""
        self.tag = "T5"
        var ctx = self.ctx
        ctx.enqueue_function[vrow.embed_rows[DType.float32]](self.w.floats[T5 + "shared.embedding"], self.ids,
                                                             self.t5x, Int32(TD), Int32(TD), Float32(1),
                                                             grid_dim=TR, block_dim=64)
        var bias = self.w.floats["t5.position_bias"]
        for l in range(TL):
            var p = T5 + "encoder.block." + String(l) + ".layer."
            self.rms(self.t5x, self.t5n, p + "0.layer_norm.weight")
            var a = p + "0.SelfAttention."
            for j in range(3):
                var nm = ["q", "k", "v"][j]
                self.proj[False, False](a + nm + ".kernel", "", self.t5n, sub(self.t5qkv, j * TD, TR * 3 * TD - j * TD),
                                        TR, TD, TD, TD, 3 * TD)
            ctx.enqueue_function[ok.t5_attention](self.t5qkv, self.t5qkv, self.t5qkv, self.t5att, bias, self.tmask,
                                                  Int32(3 * TD), Int32(TD), Int32(0), Int32(TD), Int32(2 * TD),
                                                  Int32(NT), Int32(64), grid_dim=Dim(TH, NT), block_dim=64)
            self.tick("attention")
            self.proj[False, True](a + "o.kernel", "", self.t5att, self.t5x, TR, TD, TD, TD, TD)
            self.rms(self.t5x, self.t5n, p + "1.layer_norm.weight")
            self.proj[False, False](p + "1.DenseReluDense.wi.kernel", "", self.t5n, self.t5h, TR, TF, TD, TD, TF)
            ctx.enqueue_function[ok.relu_rows](self.t5h, Int32(TF), Int32(TF), Int32(TR * TF),
                                               grid_dim=groups(TR * TF, 256), block_dim=256)
            self.tick("relu")
            self.proj[False, True](p + "1.DenseReluDense.wo.kernel", "", self.t5h, self.t5x, TR, TD, TF, TF, TD)
        self.rms(self.t5x, self.t5n, T5 + "encoder.final_layer_norm.weight")
        self.copy(sub(self.lang, 0, NT * D), self.w.floats[OT + "task_language_pos_embedding"])
        self.proj[True, True](OT + "task_language_projection.kernel", OT + "task_language_projection.bias", self.t5n,
                              self.lang, TR, D, TD, TD, D)

    # the cameras
    def stem(mut self, cam: String) raises:
        """SmallStem16 on both frames of a camera: emb_p (2 x 256 rows) or emb_w (2 x 64) of 512."""
        self.tag = "stem " + cam
        var ctx = self.ctx
        var pfx = OT + "observation_tokenizers_" + cam + ".SmallStem16_0."
        var hw = 256 if cam == "primary" else 128
        var src = self.pix_p if cam == "primary" else self.pix_w
        var ldc = 6
        var cin = 6
        var feats = [32, 96, 192, 384]
        var lds = [64, 128, 192, 384]
        var outs = [self.a1, self.a2, self.a3, self.a4]
        for i in range(4):
            var cout = feats[i]
            var ho = hw // 2
            var kp = 56 if i == 0 else 9 * cin
            var rows = W * ho * ho
            ctx.enqueue_function[ok.im2col](src, self.col, Int32(hw), Int32(hw), Int32(cin), Int32(ldc), Int32(kp),
                                            Int32(rows * kp), grid_dim=groups(rows * kp, 256), block_dim=256)
            self.tick("im2col")
            var wname = pfx + "StdConv_" + String(i) + ".kernel" + ("56" if i == 0 else "")
            self.proj[True, False](wname, pfx + "StdConv_" + String(i) + ".bias", self.col, outs[i], rows, cout, kp,
                                   kp, lds[i])
            var g = pfx + "GroupNorm_" + String(i) + "."
            ctx.enqueue_function[ok.groupnorm_relu](outs[i], self.w.floats[g + "scale"], self.w.floats[g + "bias"],
                                                    Int32(ho * ho), Int32(cout), Int32(lds[i]), EPS,
                                                    grid_dim=Dim(32, W), block_dim=64)
            self.tick("groupnorm + relu")
            src = outs[i]
            ldc = lds[i]
            cin = cout
            hw = ho
        var rows = W * hw * hw
        var dst = self.emb_p if cam == "primary" else self.emb_w
        self.proj[True, False](pfx + "embedding.kernel", pfx + "embedding.bias", self.a4, dst, rows, EMB, 384, 384,
                               EMB)

    def tokens(mut self) raises:
        """The trunk's 690 rows: task tokens; per frame the cameras' projected tokens on their position
        embeddings, the task tokens again, the readout's position embedding."""
        self.tag = "tokens"
        self.copy(sub(self.x, 0, NT * D), sub(self.lang, 0, NT * D))
        for t in range(W):
            var base = NT + t * PER
            self.copy(sub(self.x, base * D, NPR * D), sub(self.w.floats[OT + "obs_primary_pos_embedding"],
                                                          t * NPR * D, NPR * D))
            self.proj[True, True](OT + "obs_primary_projection.kernel", OT + "obs_primary_projection.bias",
                                  sub(self.emb_p, t * NPR * EMB, NPR * EMB), sub(self.x, base * D, NPR * D), NPR, D,
                                  EMB, EMB, D)
            self.copy(sub(self.x, (base + NPR) * D, NWR * D), sub(self.w.floats[OT + "obs_wrist_pos_embedding"],
                                                                  t * NWR * D, NWR * D))
            self.proj[True, True](OT + "obs_wrist_projection.kernel", OT + "obs_wrist_projection.bias",
                                  sub(self.emb_w, t * NWR * EMB, NWR * EMB), sub(self.x, (base + NPR) * D, NWR * D),
                                  NWR, D, EMB, EMB, D)
            self.copy(sub(self.x, (base + NPR + NWR) * D, NT * D), sub(self.lang, 0, NT * D))
            self.copy(sub(self.x, (base + PER - 1) * D, D),
                      sub(self.w.floats[OT + "readout_action_pos_embedding"], t * D, D))

    # the transformer
    def trunk(mut self) raises:
        self.tag = "trunk"
        for i in range(L):
            self.block(i)
        self.ln(self.x, self.xn, TB + "encoder_norm", NP, D, D, D)

    def block(mut self, i: Int) raises:
        var ctx = self.ctx
        if True:
            var p = TB + "encoderblock_" + String(i) + "."
            var a = p + "MultiHeadDotProductAttention_0."
            self.ln(self.x, self.xn, p + "LayerNorm_0", NP, D, D, D)
            if self.opt:
                self.tproj[True, False](a + "qkv.kernel", a + "qkv.bias", self.xn, self.qkv, NP, 3 * D, D, D, 3 * D)
            else:
                for j in range(3):
                    var nm = ["query", "key", "value"][j]
                    self.tproj[True, False](a + nm + ".kernel", a + nm + ".bias", self.xn,
                                            sub(self.qkv, j * D, NP * 3 * D - j * D), NP, D, D, D, 3 * D)
            ctx.enqueue_function[vattn.attention[True, 64, 64, True, False, 64, True]](
                self.qkv, self.qkv, self.qkv, self.att, self.klev, self.qlev, Int32(3 * D), Int32(3 * D), Int32(3 * D),
                Int32(D), Int32(0), Int32(D), Int32(2 * D), Int32(0), Int32(NP), Int32(1), Float32(0.125), Int32(NP),
                Int32(NP), Int32(0), Int32(1), Int32(1), self.att, self.att, grid_dim=Dim(NH, NP // 64, 1),
                block_dim=64)
            self.tick("attention (vattn)")
            self.tproj[True, True](a + "out.kernel", a + "out.bias", self.att, self.x, NP, D, D, D, D)
            self.ln(self.x, self.xn, p + "LayerNorm_1", NP, D, D, D)
            self.tproj[True, False](p + "MlpBlock_0.Dense_0.kernel", p + "MlpBlock_0.Dense_0.bias", self.xn, self.h,
                                    NP, MLP, D, D, MLP)
            if self.opt:  # the GELU as the down projection stages its input
                self.tproj[True, True, GELU](p + "MlpBlock_0.Dense_1.kernel", p + "MlpBlock_0.Dense_1.bias", self.h,
                                             self.x, NP, D, MLP, MLP, D)
            else:
                self.act[GELU](self.h, self.h2, NP, MLP)
                self.tproj[True, True](p + "MlpBlock_0.Dense_1.kernel", p + "MlpBlock_0.Dense_1.bias", self.h2,
                                       self.x, NP, D, MLP, MLP, D)

    # the action head
    def head(mut self) raises:
        """20 DDPM steps from the given noise, conditioned on the last frame's readout (xn row 689): ax."""
        self.tag = "head"
        var ctx = self.ctx
        var emb = sub(self.xn, READOUT * D, D)
        self.copy(sub(self.ax, 0, AD), sub(self.noise, 0, AD))
        if self.opt:  # all 20 steps in one launch
            ctx.enqueue_function[ok.diffusion_head](
                self.w.floats["head.in_t"], self.w.floats[RN + "Dense_0.bias"], self.w.floats["head.ln_g"],
                self.w.floats["head.ln_b"], self.w.floats["head.up_t"], self.w.floats["head.b_up"],
                self.w.floats["head.dn_t"], self.w.floats["head.b_dn"], self.w.floats["head.out_t"],
                self.w.floats[RN + "Dense_1.bias"], self.condtab, emb, self.ax, self.z, self.sched, self.xs, Int32(D),
                Int32(STEPS), grid_dim=1, block_dim=256)
            self.tick("diffusion head (20 steps)")
            return
        for t in range(STEPS - 1, -1, -1):
            ctx.enqueue_function[ok.stage_head](self.condtab, emb, self.ax, self.hin, Int32(t), Int32(TDIM), Int32(D),
                                                Int32(AD), grid_dim=1, block_dim=256)
            self.tick("stage")
            self.proj[True, False](RN + "Dense_0.kernel", RN + "Dense_0.bias", self.hin, self.hh, HR, HID, KIN, LDIN,
                                   HID)
            for blk in range(3):
                var p = RN + "MLPResNetBlock_" + String(blk) + "."
                self.ln(self.hh, self.hn, p + "LayerNorm_0", HR, HID, HID, HID)
                self.proj[True, False](p + "Dense_0.kernel", p + "Dense_0.bias", self.hn, self.hb, HR, HX, HID, HID,
                                       HX)
                self.act[SILU](self.hb, self.hb2, HR, HX)
                self.proj[True, True](p + "Dense_1.kernel", p + "Dense_1.bias", self.hb2, self.hh, HR, HID, HX, HX,
                                      HID)
            self.act[SILU](self.hh, self.hn, HR, HID)
            self.proj[True, False](RN + "Dense_1.kernel", RN + "Dense_1.bias", self.hn, self.eps, HR, AD, HID, HID, 64)
            ctx.enqueue_function[ok.ddpm_update](self.ax, self.eps, self.z, Int32(t * AD), self.c1[t], self.c2[t],
                                                 self.sigma[t], Float32(5), Int32(AD), grid_dim=1, block_dim=64)
            self.tick("ddpm update")
            if self.record:
                self.copy(sub(self.xs, t * AD, AD), sub(self.ax, 0, AD))

    def obs_trunk_npu(mut self) raises:
        """GPU+NPU: both stems and the trunk as one graph on the laptop's NPU, inside vk_server_npu: the task
        tokens, the pixels and the mask read from the GPU's buffers, the last frame's readout written into xn."""
        var bufs = [sub(self.lang, 0, NT * D), self.pix_p, self.pix_w, self.mask_add]
        var ins = List[UInt64]()
        var inb = List[UInt64]()
        for b in bufs:
            ins.append(UInt64(Int(b.unsafe_ptr())))
            inb.append(UInt64(len(b) * 4))
        var outs = [UInt64(Int(sub(self.xn, READOUT * D, D).unsafe_ptr()))]
        var outb = [UInt64(D * 4)]
        if self.lib.call["M_driver_remote_npug_run", Int32](Int32(self.npu), Int32(4), ins.unsafe_ptr(),
                                                            inb.unsafe_ptr(), Int32(1), outs.unsafe_ptr(),
                                                            outb.unsafe_ptr()) != 0:
            raise Error("M_driver_remote_npug_run failed")
        self.tick("NPU obs + trunk graph")

    def npu_time(mut self) raises -> Float64:
        var ms = Float64(0)
        if self.lib.call["M_driver_remote_npug_time", Int32](Pointer(to=ms)) != 0:
            raise Error("the NPU graph failed (M_driver_remote_npug_time)")
        return ms

    def chunk(mut self, with_text: Bool) raises:
        """One action chunk: (T5,) both stems, the tokens, the trunk, the head; GPU+NPU: the stems and the trunk
        on the NPU. Enqueued only."""
        if with_text:
            self.text()
        if self.npu >= 0:
            self.obs_trunk_npu()
        else:
            self.stem("primary")
            self.stem("wrist")
            self.tokens()
            self.trunk()
        self.head()
