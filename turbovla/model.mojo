# TurboVLA (H-EmbodVis/TurboVLA, LIBERO checkpoint: 216M parameters) as MAX DeviceContext launches: one action chunk
# (12 x 7) from two 256 x 256 views, an instruction and an 8-dim state, in one forward pass. turbovla/reference.py
# is the same model in PyTorch; every stage below matches one of its tensors.
#   vision()   DINOv3 ViT-B/16 on both views as 2 x 320 rows (CLS, 4 registers, 256 patches, 59 rows of padding a
#              view; attention per view, the padding keys masked): 12 layers of 768 with 2-D RoPE on the patches and
#              LayerScale, the final LayerNorm; then the projection to 256 (LN, MLP with a skip, LN) and the view
#              embedding: 512 vision tokens
#   text()     BERT-base over the instruction's 21 tokens with its sub-sentence mask, the tokens past the
#              instruction's padding group zeroed (TurboVLA zero-extends them), then the projection to 256. The
#              instruction is fixed for an episode, so this runs once per instruction.
#   fusion()   6 x (bidirectional vision <-> text attention, 4 heads of 256, "normalized" residuals LN(x) + g delta;
#              then a text self-attention layer, post-norm, 4 heads of 64)
#   action()   the state's 2 tokens; memory = 512 vision + 21 text + 2 state tokens (535); the ACT decoder (3
#              pre-norm layers of 256, 8 heads of 32, 12 learned queries); MLP and tanh: the 12 x 7 actions
#
# Weights: fp32, from the checkpoint as turbovla/reference.py --export writes it (turbovla.safetensors). With a remote
# GPU (the X2 Elite laptop behind vla/x2's server), TURBOVLA_REMOTE names the same file on the executor's disk and the
# plugin's M_driver_remote_file reads each tensor there; the program parses only the header of its own copy.
# Rows are padded to the matmuls' 64.
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.math import cos, sin
from std.os import getenv
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

from host import Scratch, Weights, attend, groups, lin
from safetensors import Checkpoint
import tk
import vgemm
import vrow
from vgemm import GELU_ERF, NONE

comptime IMG = 256
comptime PATCH = 16
comptime GRID = 16
comptime NPATCH = GRID * GRID  # 256
comptime PREFIX = 5  # CLS + 4 registers
comptime VTOK = PREFIX + NPATCH  # 261
comptime VR = 320  # a view's rows, padded
comptime NV = 2
comptime VROWS = NV * VR
comptime VD = 768
comptime VF = 3072
comptime VL = 12
comptime VH = 12
comptime HD = 64
comptime T = 21  # text tokens
comptime TR = 64
comptime BD = 768
comptime BF = 3072
comptime BL = 12
comptime HID = 256
comptime INNER = 1024
comptime FH = 4
comptime FHD = INNER // FH  # 256
comptime NF = 6
comptime TLF = 1024
comptime NVT = NV * NPATCH  # 512 vision tokens
comptime MEM = NVT + T + 2  # 535
comptime MR = 576
comptime NQ = 12
comptime QR = 64
comptime DHEADS = 8
comptime DHD = HID // DHEADS  # 32
comptime DF = 2048
comptime DL = 3
comptime MLPH = 512
comptime ADIM = 7
comptime SDIM = 8
comptime SLD = 16  # the state's rows, padded for the matmul's 16-wide tiles
comptime EPS: Float32 = 1e-5
comptime EPS_BERT: Float32 = 1e-12
comptime INF: Float32 = 1e30

comptime VB = "vision_encoder.backbone."
comptime TB = "text_encoder.bert."
comptime FU = "vision_language_interaction.fusion_layers."
comptime TX = "vision_language_interaction.text_layers."
comptime AH = "action_head."
comptime DEC = "action_head.decoder.decoder.layers."


def plugin_path() raises -> String:
    var spec = getenv("MODULAR_DRIVER_PLUGINS")
    var at = spec.find("@")
    if at < 0:
        raise Error("MODULAR_DRIVER_PLUGINS=vulkan@<path of the driver plugin> is needed")
    return String(spec[byte=at + 1:])


def sub(b: DeviceBuffer[DType.float32], off: Int, n: Int) raises -> DeviceBuffer[DType.float32]:
    return b.create_sub_buffer[DType.float32](off, n)


struct TurboVLA(Movable):
    var ctx: DeviceContext
    var w: Weights[DType.float16, False]  # every tensor fp32, in w.floats
    var s: Scratch
    var wv: Weights[DType.float16, True]  # TURBOVLA_MMA16: DINOv3's layer weights, for the fp16 matrix units
    var s16: Scratch
    # inputs
    var pix: DeviceBuffer[DType.float32]  # [2, 3, 256, 256], normalized
    var tids: DeviceBuffer[DType.int32]  # [64]
    var tpos: DeviceBuffer[DType.int32]  # [64]
    var tmask: DeviceBuffer[DType.int32]  # [21, 21]: 1 = may attend
    var tkeypad: DeviceBuffer[DType.int32]  # [21]: 1 = a padding key
    var group: Int  # the instruction's BERT padding group (its tokens past this are zeroed)
    # vision
    var xp: DeviceBuffer[DType.float32]
    var x: DeviceBuffer[DType.float32]
    var xn: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var hbuf: DeviceBuffer[DType.float32]
    var klev: DeviceBuffer[DType.float32]
    var qlev: DeviceBuffer[DType.float32]
    var rcos: DeviceBuffer[DType.float32]
    var rsin: DeviceBuffer[DType.float32]
    var vp: DeviceBuffer[DType.float32]
    var vpn: DeviceBuffer[DType.float32]
    var vh: DeviceBuffer[DType.float32]
    # vision tokens (memory rows 0 .. 511) and fusion
    var mem: DeviceBuffer[DType.float32]  # [576, 256]: vision | text | state tokens | zeros
    var v: DeviceBuffer[DType.float32]  # rows 0 .. 511 of mem
    var vn: DeviceBuffer[DType.float32]
    var qv: DeviceBuffer[DType.float32]
    var valv: DeviceBuffer[DType.float32]
    var ov: DeviceBuffer[DType.float32]
    var dv: DeviceBuffer[DType.float32]
    # text
    var tx: DeviceBuffer[DType.float32]
    var tq: DeviceBuffer[DType.float32]
    var tatt: DeviceBuffer[DType.float32]
    var th: DeviceBuffer[DType.float32]
    var l0: DeviceBuffer[DType.float32]  # BERT's tokens, projected: the fusion's text input
    var l: DeviceBuffer[DType.float32]
    var lnb: DeviceBuffer[DType.float32]
    var kl: DeviceBuffer[DType.float32]
    var vall: DeviceBuffer[DType.float32]
    var ol: DeviceBuffer[DType.float32]
    var dl: DeviceBuffer[DType.float32]
    var tqkv: DeviceBuffer[DType.float32]
    var tatt2: DeviceBuffer[DType.float32]
    var th2: DeviceBuffer[DType.float32]
    # state and decoder
    var st: DeviceBuffer[DType.float32]
    var stn: DeviceBuffer[DType.float32]
    var sh: DeviceBuffer[DType.float32]
    var so: DeviceBuffer[DType.float32]
    var xd: DeviceBuffer[DType.float32]
    var xdn: DeviceBuffer[DType.float32]
    var dqkv: DeviceBuffer[DType.float32]
    var datt: DeviceBuffer[DType.float32]
    var dq: DeviceBuffer[DType.float32]
    var dkv: DeviceBuffer[DType.float32]
    var dh: DeviceBuffer[DType.float32]
    var m1: DeviceBuffer[DType.float32]
    var m2: DeviceBuffer[DType.float32]
    var a: DeviceBuffer[DType.float32]
    var actions: DeviceBuffer[DType.float32]  # [12, 7]
    var bytes: Int
    var opt: Bool  # TURBOVLA_OPT: fused q/k/v, LayerScale folded into the weights
    var f16: Bool  # TURBOVLA_F16: the projections' weights rounded to fp16 (fp32 matrix units)
    var mma16: Bool  # TURBOVLA_MMA16: DINOv3's projections on the fp16 matrix units (fp16 sums)
    var profiling: Bool  # synchronize after each operation and print its label, for the server's segments
    var tag: String
    var lib: OwnedDLHandle  # the driver plugin: M_driver_remote_file, M_driver_remote_npug_*
    var npu_vision: Int  # TURBOVLA_NPU_VISION (the compiled vision graph on the laptop): its handle there, or -1
    var npu_ms: Float64  # the NPU's time for the last vision run (server clock)

    def __init__(out self, ctx: DeviceContext, path: String) raises:
        self.ctx = ctx
        self.w = Weights[DType.float16, False](ctx)
        self.s = Scratch(ctx, TR * VF, TR * VF * 16, 0, TR)
        self.wv = Weights[DType.float16, True](ctx)
        self.s16 = Scratch(ctx, 64, 64, VROWS * VF, TR)
        self.pix = ctx.enqueue_create_buffer[DType.float32](NV * 3 * IMG * IMG)
        self.tids = ctx.enqueue_create_buffer[DType.int32](TR)
        self.tpos = ctx.enqueue_create_buffer[DType.int32](TR)
        self.tmask = ctx.enqueue_create_buffer[DType.int32](T * T)
        self.tkeypad = ctx.enqueue_create_buffer[DType.int32](TR)
        self.group = T
        self.xp = ctx.enqueue_create_buffer[DType.float32](NVT * VD)
        self.x = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.xn = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](VROWS * 3 * VD)
        self.att = ctx.enqueue_create_buffer[DType.float32](VROWS * VD)
        self.hbuf = ctx.enqueue_create_buffer[DType.float32](VROWS * VF)
        self.klev = ctx.enqueue_create_buffer[DType.float32](VROWS)
        self.qlev = ctx.enqueue_create_buffer[DType.float32](VROWS)
        self.rcos = ctx.enqueue_create_buffer[DType.float32](NPATCH * HD)
        self.rsin = ctx.enqueue_create_buffer[DType.float32](NPATCH * HD)
        self.vp = ctx.enqueue_create_buffer[DType.float32](NVT * VD)
        self.vpn = ctx.enqueue_create_buffer[DType.float32](NVT * VD)
        self.vh = ctx.enqueue_create_buffer[DType.float32](NVT * INNER)
        self.mem = ctx.enqueue_create_buffer[DType.float32](MR * HID)
        self.v = sub(self.mem, 0, NVT * HID)
        self.vn = ctx.enqueue_create_buffer[DType.float32](NVT * HID)
        self.qv = ctx.enqueue_create_buffer[DType.float32](NVT * INNER)
        self.valv = ctx.enqueue_create_buffer[DType.float32](NVT * INNER)
        self.ov = ctx.enqueue_create_buffer[DType.float32](NVT * INNER)
        self.dv = ctx.enqueue_create_buffer[DType.float32](NVT * HID)
        self.tx = ctx.enqueue_create_buffer[DType.float32](TR * BD)
        self.tq = ctx.enqueue_create_buffer[DType.float32](TR * 3 * BD)
        self.tatt = ctx.enqueue_create_buffer[DType.float32](TR * BD)
        self.th = ctx.enqueue_create_buffer[DType.float32](TR * BF)
        self.l0 = ctx.enqueue_create_buffer[DType.float32](TR * HID)
        self.l = ctx.enqueue_create_buffer[DType.float32](TR * HID)
        self.lnb = ctx.enqueue_create_buffer[DType.float32](TR * HID)
        self.kl = ctx.enqueue_create_buffer[DType.float32](TR * INNER)
        self.vall = ctx.enqueue_create_buffer[DType.float32](TR * INNER)
        self.ol = ctx.enqueue_create_buffer[DType.float32](TR * INNER)
        self.dl = ctx.enqueue_create_buffer[DType.float32](TR * HID)
        self.tqkv = ctx.enqueue_create_buffer[DType.float32](TR * 3 * HID)
        self.tatt2 = ctx.enqueue_create_buffer[DType.float32](TR * HID)
        self.th2 = ctx.enqueue_create_buffer[DType.float32](TR * TLF)
        self.st = ctx.enqueue_create_buffer[DType.float32](QR * SLD)
        self.stn = ctx.enqueue_create_buffer[DType.float32](QR * SLD)
        self.sh = ctx.enqueue_create_buffer[DType.float32](QR * HID)
        self.so = ctx.enqueue_create_buffer[DType.float32](QR * 2 * HID)
        self.xd = ctx.enqueue_create_buffer[DType.float32](QR * HID)
        self.xdn = ctx.enqueue_create_buffer[DType.float32](QR * HID)
        self.dqkv = ctx.enqueue_create_buffer[DType.float32](QR * 3 * HID)
        self.datt = ctx.enqueue_create_buffer[DType.float32](QR * HID)
        self.dq = ctx.enqueue_create_buffer[DType.float32](QR * HID)
        self.dkv = ctx.enqueue_create_buffer[DType.float32](MR * 2 * HID)
        self.dh = ctx.enqueue_create_buffer[DType.float32](QR * DF)
        self.m1 = ctx.enqueue_create_buffer[DType.float32](QR * MLPH)
        self.m2 = ctx.enqueue_create_buffer[DType.float32](QR * MLPH)
        self.a = ctx.enqueue_create_buffer[DType.float32](QR * ADIM)
        self.actions = ctx.enqueue_create_buffer[DType.float32](NQ * ADIM)
        self.bytes = 0
        self.profiling = False
        self.opt = getenv("TURBOVLA_OPT") != "" and getenv("TURBOVLA_OPT") != "0"
        self.f16 = getenv("TURBOVLA_F16") != "" and getenv("TURBOVLA_F16") != "0"
        self.mma16 = getenv("TURBOVLA_MMA16") != "" and getenv("TURBOVLA_MMA16") != "0"
        self.tag = ""
        self.lib = OwnedDLHandle(plugin_path())
        self.npu_vision = -1
        self.npu_ms = 0
        for buf in [self.x, self.xn, self.att, self.tx, self.tatt, self.l, self.lnb, self.tatt2, self.st, self.stn,
                    self.mem, self.xd, self.xdn, self.datt]:
            ctx.enqueue_memset(buf, Float32(0))
        self.load(path)
        self.tables()
        var graph = getenv("TURBOVLA_NPU_VISION")
        if graph:
            var ms = Float64(0)
            var h = self.lib.call["M_driver_remote_npug_open", Int32](graph.as_c_string_span().unsafe_ptr(),
                                                                      Pointer(to=ms))
            if h < 0:
                raise Error("M_driver_remote_npug_open failed: is the server vk_server_npu.exe, run from its DLLs?")
            self.npu_vision = Int(h)
            print("NPU: the vision graph", graph, "opened in", round(ms, 1), "ms")

    def load(mut self, path: String) raises:
        """Every tensor of the checkpoint (fp32) as a device buffer; the MultiheadAttention's in_proj split into
        its q and k|v rows for the decoder's cross-attention."""
        var ck = Checkpoint(path)
        var remote = getenv("TURBOVLA_REMOTE")
        var names = List[String]()
        for e in ck.sizes.items():
            names.append(e.key)
        if remote:
            for name in names:
                if "pooler" in name or "mask_token" in name:
                    continue
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
                if "pooler" in name or "mask_token" in name:
                    continue
                var data = ck.read(f, name)
                var buf = self.ctx.enqueue_create_buffer[DType.float32](len(data) // 4)
                self.ctx.enqueue_copy(buf, data.unsafe_ptr().unsafe_bitcast[Float32]())
                self.ctx.synchronize()
                self.w.floats[name] = buf
                self.bytes += len(data)
        if self.opt:
            self.fuse()
        if self.f16:
            self.halve()
        for l in range(DL):
            var p = DEC + String(l) + ".multihead_attn."
            var bq = self.w.floats[p + "in_proj_bias"]
            self.w.floats[p + "q.bias"] = sub(bq, 0, HID)
            self.w.floats[p + "kv.bias"] = sub(bq, HID, 2 * HID)
            if self.f16:
                var wq = self.w.halves[p + "in_proj_weight"]
                self.w.halves[p + "q.weight"] = wq.create_sub_buffer[DType.float16](0, HID * HID)
                self.w.halves[p + "kv.weight"] = wq.create_sub_buffer[DType.float16](HID * HID, 2 * HID * HID)
            else:
                var wq = self.w.floats[p + "in_proj_weight"]
                self.w.floats[p + "q.weight"] = sub(wq, 0, HID * HID)
                self.w.floats[p + "kv.weight"] = sub(wq, HID * HID, 2 * HID * HID)

    def cat(mut self, key: String, names: List[String], n: Int) raises:
        """A device tensor made of the tensors `names` (n floats each, rows concatenated); "" for zeros."""
        var buf = self.ctx.enqueue_create_buffer[DType.float32](len(names) * n)
        for i in range(len(names)):
            if names[i] == "":
                self.ctx.enqueue_memset(sub(buf, i * n, n), Float32(0))
            else:
                self.ctx.enqueue_copy(sub(buf, i * n, n), self.w.floats[names[i]])
        self.w.floats[key] = buf

    def fold(mut self, wname: String, bname: String, gname: String, n: Int, k: Int) raises:
        """LayerScale g into the projection's rows: W <- diag(g) W, b <- g b."""
        var g = self.w.floats[gname]
        self.ctx.enqueue_function[tk.scale_rows](self.w.floats[wname], g, Int32(k), Int32(n * k),
                                                 grid_dim=groups(n * k, 256), block_dim=256)
        self.ctx.enqueue_function[tk.scale_rows](self.w.floats[bname], g, Int32(1), Int32(n),
                                                 grid_dim=groups(n, 256), block_dim=256)

    def fuse(mut self) raises:
        """GPU optimized: q/k/v as one projection (DINOv3: k has no bias, zeros), LayerScale folded into o and down."""
        for i in range(VL):
            var p = VB + "layer." + String(i) + "."
            var a = p + "attention."
            self.cat(a + "qkv.weight", [a + "q_proj.weight", a + "k_proj.weight", a + "v_proj.weight"], VD * VD)
            self.cat(a + "qkv.bias", [a + "q_proj.bias", "", a + "v_proj.bias"], VD)
            self.fold(a + "o_proj.weight", a + "o_proj.bias", p + "layer_scale1.lambda1", VD, VD)
            self.fold(p + "mlp.down_proj.weight", p + "mlp.down_proj.bias", p + "layer_scale2.lambda1", VD, VF)
        for i in range(BL):
            var a = TB + "encoder.layer." + String(i) + ".attention.self."
            self.cat(a + "qkv.weight", [a + "query.weight", a + "key.weight", a + "value.weight"], BD * BD)
            self.cat(a + "qkv.bias", [a + "query.bias", a + "key.bias", a + "value.bias"], BD)
        self.ctx.synchronize()

    def halve(mut self) raises:
        """Every projection's weight to fp16 (w.halves); norms, biases, embeddings and tokens stay fp32."""
        var names = List[String]()
        for e in self.w.floats.items():
            var nm = e.key
            if not (nm.endswith("weight") or nm.endswith("in_proj_weight")):
                continue
            if "norm" in nm or "LayerNorm" in nm or "embeddings." in nm or "action_queries" in nm:
                if "patch_embeddings" not in nm:
                    continue
            if len(e.value) < HID * 8:  # the state's LayerNorm and other vectors
                continue
            names.append(nm)
        for nm in names:
            var src = self.w.floats[nm]
            var n = len(src)
            var dst = self.ctx.enqueue_create_buffer[DType.float16](n)
            self.ctx.enqueue_function[tk.to_f16](src, dst, Int32(n), grid_dim=groups(n, 256), block_dim=256)
            if self.mma16 and nm.startswith(VB + "layer."):
                self.wv.halves[nm] = dst
            else:
                self.w.halves[nm] = dst
            _ = self.w.floats.pop(nm)
        self.ctx.synchronize()

    def tables(mut self) raises:
        """DINOv3's RoPE for the 16 x 16 patches: angle 2 pi coord * 100^(-f / 16) for the patch center's y (f < 16)
        and x (16 .. 31), coordinates in [-1, 1]; tiled twice to the head's 64. And the attention's key levels: a
        view's padding rows never visible."""
        var c = List[Float32](length=NPATCH * HD, fill=0)
        var s = List[Float32](length=NPATCH * HD, fill=0)
        for py in range(GRID):
            for px in range(GRID):
                var p = py * GRID + px
                var coord = [Float32(2.0 * (Float64(py) + 0.5) / GRID - 1.0),
                             Float32(2.0 * (Float64(px) + 0.5) / GRID - 1.0)]
                for a in range(2):
                    for f in range(HD // 4):
                        var inv = Float32(1.0 / (100.0 ** (Float64(f) * 4.0 / Float64(HD))))
                        var ang = (Float32(6.283185307179586) * coord[a]) * inv
                        for rep in range(2):
                            var j = rep * (HD // 2) + a * (HD // 4) + f
                            c[p * HD + j] = Float32(cos(Float64(ang)))
                            s[p * HD + j] = Float32(sin(Float64(ang)))
        self.ctx.enqueue_copy(self.rcos, c.unsafe_ptr())
        self.ctx.enqueue_copy(self.rsin, s.unsafe_ptr())
        var kl = List[Float32](length=VROWS, fill=0)
        for r in range(VROWS):
            if r % VR >= VTOK:
                kl[r] = INF
        self.ctx.enqueue_copy(self.klev, kl.unsafe_ptr())
        self.ctx.enqueue_memset(self.qlev, Float32(0))
        self.ctx.synchronize()

    def set_inputs(mut self, pixels: List[Float32], ids: List[Int32], pos: List[Int32], mask: List[Int32],
                   keypad: List[Int32], state: List[Float32], group: Int) raises:
        self.ctx.enqueue_copy(self.pix, pixels.unsafe_ptr())
        var i64 = List[Int32](length=TR, fill=0)
        var p64 = List[Int32](length=TR, fill=0)
        var k64 = List[Int32](length=TR, fill=1)
        for i in range(T):
            i64[i] = ids[i]
            p64[i] = pos[i]
            k64[i] = keypad[i]
        self.ctx.enqueue_copy(self.tids, i64.unsafe_ptr())
        self.ctx.enqueue_copy(self.tpos, p64.unsafe_ptr())
        self.ctx.enqueue_copy(self.tkeypad, k64.unsafe_ptr())
        self.ctx.enqueue_copy(self.tmask, mask.unsafe_ptr())
        var s = List[Float32](length=QR * SLD, fill=0)
        for i in range(SDIM):
            s[i] = state[i]
        self.ctx.enqueue_copy(self.st, s.unsafe_ptr())
        self.group = group
        self.ctx.synchronize()

    def tick(self, what: String) raises:
        """Profiling: wait for the operation just enqueued and name it; the server's segment for this wait (laptop
        clock, VK_SERVER_SEGMENTS=1) is its time."""
        if self.profiling:
            self.ctx.synchronize()
            print("mark", self.tag + " | " + what)

    # launches
    def proj[BIAS: Bool, RES: Bool, ACT: Int = NONE](self, wname: String, bname: String,
                                                     x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
                                                     rows: Int, n: Int, k: Int, ldx: Int, ldy: Int,
                                                     xoff: Int = 0) raises:
        """y = act(x) W^T (+ b) (+ y); ACT applies to x as the matmul stages it (GELU_ERF: the GELU before W)."""
        lin[DType.float16, False, ACT, BIAS, RES](self.w, self.s, wname, bname, x, y, rows, n, k, ldx, ldy, xoff)
        self.tick("proj " + String(rows) + "x" + String(n) + "x" + String(k))

    def proj16[BIAS: Bool, RES: Bool, ACT: Int = NONE](self, wname: String, bname: String,
                                                       x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
                                                       rows: Int, n: Int, k: Int, ldx: Int, ldy: Int) raises:
        """proj on the fp16 matrix units (vgemm.gemm16: X and W in fp16, fp16 sums), for DINOv3's layers; the bias
        (fp32, in w) and the residual added in fp32."""
        var b = self.w.floats[bname] if BIAS else self.s16.xa
        var ctx = self.ctx
        var w16 = self.wv.halves[wname]
        ctx.enqueue_function[vgemm.to_half[ACT]](x, self.s16.xh, Int32(k), Int32(ldx), Int32(0), Float32(1),
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
           ldx: Int, ldy: Int, eps: Float32) raises:
        self.ctx.enqueue_function[vrow.layernorm[DType.float32]](
            x, self.w.floats[name + ".weight"], self.w.floats[name + ".bias"], y, Int32(ldx), Int32(ldy), Int32(d),
            eps, grid_dim=rows, block_dim=64)
        self.tick("layernorm")

    def gelu(self, x: DeviceBuffer[DType.float32], rows: Int, n: Int, ld: Int) raises:
        self.ctx.enqueue_function[tk.gelu_rows](x, Int32(ld), Int32(n), Int32(rows * n),
                                                grid_dim=groups(rows * n, 256), block_dim=256)
        self.tick("gelu")

    def relu(self, x: DeviceBuffer[DType.float32], rows: Int, n: Int, ld: Int) raises:
        self.ctx.enqueue_function[tk.relu_rows](x, Int32(ld), Int32(n), Int32(rows * n),
                                                grid_dim=groups(rows * n, 256), block_dim=256)
        self.tick("relu")

    def small[MK: Int](self, q: DeviceBuffer[DType.float32], k: DeviceBuffer[DType.float32],
                       v: DeviceBuffer[DType.float32], o: DeviceBuffer[DType.float32], mask: DeviceBuffer[DType.int32],
                       ldq: Int, ldk: Int, ldv: Int, ldo: Int, qcol: Int, kcol: Int, vcol: Int, nq: Int, nk: Int,
                       heads: Int, hd: Int, scale: Float32) raises:
        self.ctx.enqueue_function[tk.attn_small[MK]](
            q, k, v, o, mask, Int32(ldq), Int32(ldk), Int32(ldv), Int32(ldo), Int32(qcol), Int32(kcol), Int32(vcol),
            Int32(0), Int32(nk), Int32(hd), scale, grid_dim=Dim(heads, nq), block_dim=64)
        self.tick("attention " + String(nq) + "x" + String(nk))

    def scale_add(self, gname: String) raises:
        self.ctx.enqueue_function[tk.scale_add](self.x, self.xn, self.w.floats[gname], Int32(VD), Int32(VROWS * VD),
                                                grid_dim=groups(VROWS * VD, 256), block_dim=256)
        self.tick("layerscale + residual")

    def vision(mut self) raises:
        """DINOv3 on both views, its final LayerNorm in xn (rows v * 320 + 5 + p are the patches)."""
        self.tag = "vision"
        self.embed()
        for i in range(VL):
            self.vlayer(i)
        self.ln(self.x, self.xn, VB + "norm", VROWS, VD, VD, VD, EPS)

    def embed(mut self) raises:
        """Patches through the patch embedding, the CLS and register tokens before them: x, a view's rows 320 apart."""
        var ctx = self.ctx
        ctx.enqueue_function[vrow.patchify](self.pix, self.xp, Int32(IMG), Int32(PATCH), Int32(NVT * VD),
                                            grid_dim=groups(NVT * VD, 256), block_dim=256)
        self.tick("patchify")
        for vw in range(NV):
            self.proj[True, False](VB + "embeddings.patch_embeddings.weight", VB + "embeddings.patch_embeddings.bias",
                                   sub(self.xp, vw * NPATCH * VD, NPATCH * VD),
                                   sub(self.x, (vw * VR + PREFIX) * VD, NPATCH * VD), NPATCH, VD, VD, VD, VD)
            ctx.enqueue_copy(sub(self.x, vw * VR * VD, VD), self.w.floats[VB + "embeddings.cls_token"])
            ctx.enqueue_copy(sub(self.x, (vw * VR + 1) * VD, 4 * VD), self.w.floats[VB + "embeddings.register_tokens"])

    def vlayer(mut self, i: Int) raises:
        var ctx = self.ctx
        if True:
            var p = VB + "layer." + String(i) + "."
            self.ln(self.x, self.xn, p + "norm1", VROWS, VD, VD, VD, EPS)
            if self.mma16:
                self.proj16[True, False](p + "attention.qkv.weight", p + "attention.qkv.bias", self.xn, self.qkv,
                                         VROWS, 3 * VD, VD, VD, 3 * VD)
            elif self.opt:
                self.proj[True, False](p + "attention.qkv.weight", p + "attention.qkv.bias", self.xn, self.qkv, VROWS,
                                       3 * VD, VD, VD, 3 * VD)
            else:
                self.proj[True, False](p + "attention.q_proj.weight", p + "attention.q_proj.bias", self.xn,
                                       sub(self.qkv, 0, VROWS * 3 * VD), VROWS, VD, VD, VD, 3 * VD)
                self.proj[False, False](p + "attention.k_proj.weight", "", self.xn,
                                        sub(self.qkv, VD, VROWS * 3 * VD - VD), VROWS, VD, VD, VD, 3 * VD)
                self.proj[True, False](p + "attention.v_proj.weight", p + "attention.v_proj.bias", self.xn,
                                       sub(self.qkv, 2 * VD, VROWS * 3 * VD - 2 * VD), VROWS, VD, VD, VD, 3 * VD)
            ctx.enqueue_function[tk.rope_patches](self.qkv, self.rcos, self.rsin, Int32(3 * VD), Int32(VR),
                                                  Int32(PREFIX), Int32(NPATCH), Int32(VD), Int32(HD),
                                                  grid_dim=VROWS, block_dim=64)
            self.tick("rope")
            attend[True, HD](ctx, self.qkv, self.qkv, self.qkv, self.att, self.klev, self.qlev, 3 * VD, 3 * VD, VD,
                             VD, 2 * VD, VR, VH, 1, VR, NV, VR, Float32(0.125))
            self.tick("attention (vattn)")
            if self.mma16:
                self.proj16[True, True](p + "attention.o_proj.weight", p + "attention.o_proj.bias", self.att, self.x,
                                        VROWS, VD, VD, VD, VD)
            elif self.opt:  # LayerScale folded into o: straight onto the residual
                self.proj[True, True](p + "attention.o_proj.weight", p + "attention.o_proj.bias", self.att, self.x,
                                      VROWS, VD, VD, VD, VD)
            else:
                self.proj[True, False](p + "attention.o_proj.weight", p + "attention.o_proj.bias", self.att, self.xn,
                                       VROWS, VD, VD, VD, VD)
                self.scale_add(p + "layer_scale1.lambda1")
            self.ln(self.x, self.xn, p + "norm2", VROWS, VD, VD, VD, EPS)
            if self.mma16:
                self.proj16[True, False](p + "mlp.up_proj.weight", p + "mlp.up_proj.bias", self.xn, self.hbuf, VROWS,
                                         VF, VD, VD, VF)
            else:
                self.proj[True, False](p + "mlp.up_proj.weight", p + "mlp.up_proj.bias", self.xn, self.hbuf, VROWS,
                                       VF, VD, VD, VF)
            if self.mma16:
                self.proj16[True, True, GELU_ERF](p + "mlp.down_proj.weight", p + "mlp.down_proj.bias", self.hbuf,
                                                  self.x, VROWS, VD, VF, VF, VD)
            elif self.opt:  # the GELU as the down projection stages its input
                self.proj[True, True, GELU_ERF](p + "mlp.down_proj.weight", p + "mlp.down_proj.bias", self.hbuf,
                                                self.x, VROWS, VD, VF, VF, VD)
            else:
                self.gelu(self.hbuf, VROWS, VF, VF)
                self.proj[True, False](p + "mlp.down_proj.weight", p + "mlp.down_proj.bias", self.hbuf, self.xn,
                                       VROWS, VD, VF, VF, VD)
                self.scale_add(p + "layer_scale2.lambda1")

    def project(mut self) raises:
        """The patches through the vision projection, plus the view embedding: rows 0 .. 511 of mem."""
        var ctx = self.ctx
        self.tag = "projection"
        ctx.enqueue_function[tk.gather_rows](self.xn, self.vp, Int32(VR), Int32(PREFIX), Int32(NPATCH), Int32(VD),
                                             Int32(NVT * VD), grid_dim=groups(NVT * VD, 256), block_dim=256)
        self.tick("gather")
        self.ln(self.vp, self.vpn, "vision_projection.input_norm", NVT, VD, VD, VD, EPS)
        self.proj[True, False]("vision_projection.mlp.0.weight", "vision_projection.mlp.0.bias", self.vpn, self.vh, NVT,
                               INNER, VD, VD, INNER)
        self.gelu(self.vh, NVT, INNER, INNER)
        self.proj[False, False]("vision_projection.skip.weight", "", self.vp, self.v, NVT, HID, VD, VD, HID)
        self.proj[True, True]("vision_projection.mlp.3.weight", "vision_projection.mlp.3.bias", self.vh, self.v, NVT,
                              HID, INNER, INNER, HID)
        self.ln(self.v, self.v, "vision_projection.output_norm", NVT, HID, HID, HID, EPS)
        ctx.enqueue_function[tk.add_view](self.v, self.w.floats["view_embedding"], Int32(NPATCH), Int32(HID),
                                          Int32(NVT * HID), grid_dim=groups(NVT * HID, 256), block_dim=256)
        self.tick("view embedding")

    def text(mut self) raises:
        """BERT over the instruction (once per instruction), its rows past the padding group zeroed, then the
        projection to 256: l (rows 0 .. 20)."""
        var ctx = self.ctx
        self.tag = "bert"
        ctx.enqueue_function[tk.bert_embed](self.tids, self.tpos, self.w.floats[TB + "embeddings.word_embeddings.weight"],
                                            self.w.floats[TB + "embeddings.position_embeddings.weight"],
                                            self.w.floats[TB + "embeddings.token_type_embeddings.weight"], self.tx,
                                            Int32(BD), grid_dim=TR, block_dim=64)
        self.tick("embeddings")
        self.ln(self.tx, self.tx, TB + "embeddings.LayerNorm", TR, BD, BD, BD, EPS_BERT)
        for i in range(BL):
            var p = TB + "encoder.layer." + String(i) + "."
            if self.opt:
                self.proj[True, False](p + "attention.self.qkv.weight", p + "attention.self.qkv.bias", self.tx, self.tq,
                                       TR, 3 * BD, BD, BD, 3 * BD)
            else:
                self.proj[True, False](p + "attention.self.query.weight", p + "attention.self.query.bias", self.tx,
                                       sub(self.tq, 0, TR * 3 * BD), TR, BD, BD, BD, 3 * BD)
                self.proj[True, False](p + "attention.self.key.weight", p + "attention.self.key.bias", self.tx,
                                       sub(self.tq, BD, TR * 3 * BD - BD), TR, BD, BD, BD, 3 * BD)
                self.proj[True, False](p + "attention.self.value.weight", p + "attention.self.value.bias", self.tx,
                                       sub(self.tq, 2 * BD, TR * 3 * BD - 2 * BD), TR, BD, BD, BD, 3 * BD)
            self.small[2](self.tq, self.tq, self.tq, self.tatt, self.tmask, 3 * BD, 3 * BD, 3 * BD, BD, 0, BD, 2 * BD,
                          T, T, 12, 64, Float32(0.125))
            self.proj[True, True](p + "attention.output.dense.weight", p + "attention.output.dense.bias", self.tatt,
                                  self.tx, TR, BD, BD, BD, BD)
            self.ln(self.tx, self.tx, p + "attention.output.LayerNorm", TR, BD, BD, BD, EPS_BERT)
            self.proj[True, False](p + "intermediate.dense.weight", p + "intermediate.dense.bias", self.tx, self.th, TR,
                                   BF, BD, BD, BF)
            self.gelu(self.th, TR, BF, BF)
            self.proj[True, True](p + "output.dense.weight", p + "output.dense.bias", self.th, self.tx, TR, BD, BF, BF,
                                  BD)
            self.ln(self.tx, self.tx, p + "output.LayerNorm", TR, BD, BD, BD, EPS_BERT)
        ctx.enqueue_function[tk.zero_from](self.tx, Int32(self.group * BD), Int32((TR - self.group) * BD),
                                           grid_dim=groups((TR - self.group) * BD, 256), block_dim=256)
        self.tick("zero")
        self.proj[True, False]("text_encoder.text_projection.weight", "text_encoder.text_projection.bias", self.tx,
                               self.l0, TR, HID, BD, BD, HID)
        ctx.enqueue_copy(self.l, self.l0)

    def fusion(mut self, i: Int) raises:
        """Fusion layer i (bidirectional attention, normalized residuals) and text layer i."""
        var ctx = self.ctx
        self.tag = "fusion"
        var p = FU + String(i) + "."
        self.ln(self.v, self.vn, p + "layer_norm_v", NVT, HID, HID, HID, EPS)
        self.ln(self.l, self.lnb, p + "layer_norm_l", TR, HID, HID, HID, EPS)
        self.proj[True, False](p + "attn.v_proj.weight", p + "attn.v_proj.bias", self.vn, self.qv, NVT, INNER, HID,
                               HID, INNER)
        self.proj[True, False](p + "attn.values_v_proj.weight", p + "attn.values_v_proj.bias", self.vn, self.valv, NVT,
                               INNER, HID, HID, INNER)
        self.proj[True, False](p + "attn.l_proj.weight", p + "attn.l_proj.bias", self.lnb, self.kl, TR, INNER, HID,
                               HID, INNER)
        self.proj[True, False](p + "attn.values_l_proj.weight", p + "attn.values_l_proj.bias", self.lnb, self.vall, TR,
                               INNER, HID, HID, INNER)
        # vision queries over the text keys (padding keys hidden); text queries over the vision keys
        self.small[1](self.qv, self.kl, self.vall, self.ov, self.tkeypad, INNER, INNER, INNER, INNER, 0, 0, 0, NVT, T,
                      FH, FHD, Float32(0.0625))
        self.small[0](self.kl, self.qv, self.valv, self.ol, self.tkeypad, INNER, INNER, INNER, INNER, 0, 0, 0, T, NVT,
                      FH, FHD, Float32(0.0625))
        self.proj[True, False](p + "attn.out_v_proj.weight", p + "attn.out_v_proj.bias", self.ov, self.dv, NVT, HID,
                               INNER, INNER, HID)
        self.proj[True, False](p + "attn.out_l_proj.weight", p + "attn.out_l_proj.bias", self.ol, self.dl, TR, HID,
                               INNER, INNER, HID)
        ctx.enqueue_function[tk.ln_plus](self.v, self.vn, self.dv, self.w.floats[p + "gamma_v"], Int32(HID),
                                         Int32(NVT * HID), grid_dim=groups(NVT * HID, 256), block_dim=256)
        self.tick("normalized residual")
        ctx.enqueue_function[tk.ln_plus](self.l, self.lnb, self.dl, self.w.floats[p + "gamma_l"], Int32(HID),
                                         Int32(TR * HID), grid_dim=groups(TR * HID, 256), block_dim=256)
        self.tick("normalized residual")
        self.tag = "text layer"
        var q = TX + String(i) + "."
        self.proj[True, False](q + "self_attn.in_proj_weight", q + "self_attn.in_proj_bias", self.l, self.tqkv, TR,
                               3 * HID, HID, HID, 3 * HID)
        self.small[2](self.tqkv, self.tqkv, self.tqkv, self.tatt2, self.tmask, 3 * HID, 3 * HID, 3 * HID, HID, 0, HID,
                      2 * HID, T, T, 4, 64, Float32(0.125))
        self.proj[True, True](q + "self_attn.out_proj.weight", q + "self_attn.out_proj.bias", self.tatt2, self.l, TR,
                              HID, HID, HID, HID)
        self.ln(self.l, self.l, q + "norm1", TR, HID, HID, HID, EPS)
        self.proj[True, False](q + "linear1.weight", q + "linear1.bias", self.l, self.th2, TR, TLF, HID, HID, TLF)
        self.relu(self.th2, TR, TLF, TLF)
        self.proj[True, True](q + "linear2.weight", q + "linear2.bias", self.th2, self.l, TR, HID, TLF, TLF, HID)
        self.ln(self.l, self.l, q + "norm2", TR, HID, HID, HID, EPS)

    def action(mut self) raises:
        """Memory (vision | text | the state's two tokens), the ACT decoder, the MLP and tanh: actions [12, 7]."""
        var ctx = self.ctx
        self.tag = "state"
        ctx.enqueue_copy(sub(self.mem, NVT * HID, T * HID), sub(self.l, 0, T * HID))
        var sp = AH + "state_projection."
        self.ln(self.st, self.stn, sp + "net.0", 1, SDIM, SLD, SLD, EPS)
        self.proj[True, False](sp + "net.1.weight", sp + "net.1.bias", self.stn, self.sh, QR, HID, SDIM, SLD, HID)
        self.gelu(self.sh, 1, HID, HID)
        self.proj[True, False](sp + "net.4.weight", sp + "net.4.bias", self.sh, self.so, QR, 2 * HID, HID, HID,
                               2 * HID)
        var stok = sub(self.mem, (NVT + T) * HID, 2 * HID)
        ctx.enqueue_copy(stok, sub(self.so, 0, 2 * HID))
        ctx.enqueue_function[vrow.add_rows[DType.float32]](stok, self.w.floats[sp + "position"], Int32(2), Int32(HID),
                                                           Int32(2 * HID), grid_dim=groups(2 * HID, 256), block_dim=256)
        self.tick("position")
        self.ln(stok, stok, sp + "output_norm", 2, HID, HID, HID, EPS)
        ctx.enqueue_copy(sub(self.xd, 0, NQ * HID), self.w.floats[AH + "decoder.action_queries.weight"])
        var scale = Float32(0.17677669529663687)  # 1 / sqrt(32)
        self.tag = "decoder"
        for i in range(DL):
            var p = DEC + String(i) + "."
            self.ln(self.xd, self.xdn, p + "norm1", NQ, HID, HID, HID, EPS)
            self.proj[True, False](p + "self_attn.in_proj_weight", p + "self_attn.in_proj_bias", self.xdn, self.dqkv,
                                   QR, 3 * HID, HID, HID, 3 * HID)
            self.small[0](self.dqkv, self.dqkv, self.dqkv, self.datt, self.tkeypad, 3 * HID, 3 * HID, 3 * HID, HID, 0,
                          HID, 2 * HID, NQ, NQ, DHEADS, DHD, scale)
            self.proj[True, True](p + "self_attn.out_proj.weight", p + "self_attn.out_proj.bias", self.datt, self.xd,
                                  QR, HID, HID, HID, HID)
            self.ln(self.xd, self.xdn, p + "norm2", NQ, HID, HID, HID, EPS)
            self.proj[True, False](p + "multihead_attn.q.weight", p + "multihead_attn.q.bias", self.xdn, self.dq, QR,
                                   HID, HID, HID, HID)
            self.proj[True, False](p + "multihead_attn.kv.weight", p + "multihead_attn.kv.bias", self.mem, self.dkv,
                                   MR, 2 * HID, HID, HID, 2 * HID)
            self.small[0](self.dq, self.dkv, self.dkv, self.datt, self.tkeypad, HID, 2 * HID, 2 * HID, HID, 0, 0, HID,
                          NQ, MEM, DHEADS, DHD, scale)
            self.proj[True, True](p + "multihead_attn.out_proj.weight", p + "multihead_attn.out_proj.bias", self.datt,
                                  self.xd, QR, HID, HID, HID, HID)
            self.ln(self.xd, self.xdn, p + "norm3", NQ, HID, HID, HID, EPS)
            self.proj[True, False](p + "linear1.weight", p + "linear1.bias", self.xdn, self.dh, QR, DF, HID, HID, DF)
            self.relu(self.dh, NQ, DF, DF)
            self.proj[True, True](p + "linear2.weight", p + "linear2.bias", self.dh, self.xd, QR, HID, DF, DF, HID)
        self.tag = "mlp"
        var mp = AH + "decoder.action_projection.layers."
        self.proj[True, False](mp + "0.weight", mp + "0.bias", self.xd, self.m1, QR, MLPH, HID, HID, MLPH)
        self.relu(self.m1, NQ, MLPH, MLPH)
        self.proj[True, False](mp + "1.weight", mp + "1.bias", self.m1, self.m2, QR, MLPH, MLPH, MLPH, MLPH)
        self.relu(self.m2, NQ, MLPH, MLPH)
        self.proj[True, False](mp + "2.weight", mp + "2.bias", self.m2, self.a, QR, ADIM, MLPH, MLPH, ADIM)
        ctx.enqueue_function[tk.tanh_rows](self.a, self.actions, Int32(NQ * ADIM), grid_dim=1, block_dim=128)
        self.tick("tanh")

    def vision_npu(mut self) raises:
        """GPU+NPU: the vision graph (DINOv3, the projection, the view embedding) on the laptop's NPU, inside
        vk_server_npu: the pixels read from the GPU's buffer, the 512 vision tokens written into mem."""
        var ins = [UInt64(Int(self.pix.unsafe_ptr()))]
        var inb = [UInt64(NV * 3 * IMG * IMG * 4)]
        var outs = [UInt64(Int(self.v.unsafe_ptr()))]
        var outb = [UInt64(NVT * HID * 4)]
        if self.lib.call["M_driver_remote_npug_run", Int32](Int32(self.npu_vision), Int32(1), ins.unsafe_ptr(),
                                                            inb.unsafe_ptr(), Int32(1), outs.unsafe_ptr(),
                                                            outb.unsafe_ptr()) != 0:
            raise Error("M_driver_remote_npug_run failed")
        self.tick("NPU vision graph")

    def npu_time(mut self) raises -> Float64:
        var ms = Float64(0)
        if self.lib.call["M_driver_remote_npug_time", Int32](Pointer(to=ms)) != 0:
            raise Error("the NPU graph failed (M_driver_remote_npug_time)")
        return ms

    def chunk(mut self, with_text: Bool) raises:
        """One action chunk: vision, (text,) fusion, action. Enqueued only; the caller synchronizes."""
        if self.npu_vision >= 0:
            self.vision_npu()
        else:
            self.vision()
            self.project()
        if with_text:
            self.text()
        else:
            self.ctx.enqueue_copy(self.l, self.l0)
        for i in range(NF):
            self.fusion(i)
        self.action()
