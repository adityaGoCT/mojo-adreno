# Host code shared by SmolVLA (smolvla/model.mojo) and π0 (pi0/model.mojo): the checkpoint's weights as device
# buffers, and the launches of vla/kernels' projections and attention.
from std.collections import Dict
from std.memory import bitcast
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

from safetensors import Checkpoint
import vattn
import vgemm
from vgemm import NONE

comptime NATIVE = 0  # bf16 stays bf16 and fp32 stays fp32 (W16 = float16: both rounded to fp16)
comptime WIDE = 1  # always fp32: biases, norms, position embeddings (exactly, from bf16)
comptime AUTO = 2  # fp32 tensors whose values bf16 holds exactly become bf16, the rest stay fp32
comptime NARROW = 1024  # staged projections up to this n get 64 x 128 blocks: twice the workgroups
comptime SK_TARGET = 96  # the workgroups the split-k path aims for


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


def one(name: String) -> List[String]:
    return [name]


struct Weights[W16: DType, MMA16: Bool](Movable):
    """Device tensors by name: 16-bit ones (W16: uint16 = bf16 bits, or float16) in `halves`, fp32 ones in
    `floats`. MMA16: projections on the fp16 matrix units (vgemm.gemm16), whose weights get zero rows up to a
    multiple of 128."""

    var ctx: DeviceContext
    var halves: Dict[String, DeviceBuffer[Self.W16]]
    var floats: Dict[String, DeviceBuffer[DType.float32]]
    var bytes: Int  # read from the checkpoint
    var narrowed: Int  # AUTO: fp32 tensors stored as bf16
    var kept: Int  # AUTO: fp32 tensors kept in fp32

    def __init__(out self, ctx: DeviceContext):
        self.ctx = ctx
        self.halves = Dict[String, DeviceBuffer[Self.W16]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.bytes = 0
        self.narrowed = 0
        self.kept = 0

    def upload(mut self, ck: Checkpoint, f: FileHandle, key: String, names: List[String], cols: Int = 0,
               mode: Int = NATIVE) raises:
        """The tensors `names` (one dtype), concatenated by rows, as the device buffer `key`, stored as `mode`
        says. `cols` > 0 marks a projection's weight (its k), padded for gemm16."""
        var dt = ck.dtypes[names[0]]
        var total = 0
        for nm in names:
            if ck.dtypes[nm] != dt:
                raise Error("mixed dtypes in " + key)
            total += ck.sizes[nm]
        if dt != "BF16" and dt != "F32":
            raise Error(key + ": unsupported dtype " + dt)
        self.bytes += total
        var count = total // (2 if dt == "BF16" else 4)
        var parts = List[List[UInt8]]()
        for nm in names:
            parts.append(ck.read(f, nm))
        var wide = mode == WIDE or (dt == "F32" and mode == NATIVE)
        comptime if Self.W16 == DType.float16:
            wide = mode == WIDE
        if dt == "F32" and mode == AUTO:  # bf16 when every value is one
            var exact = True
            for i in range(len(parts)):
                var src = parts[i].unsafe_ptr().unsafe_bitcast[UInt32]()
                for j in range(len(parts[i]) // 4):
                    if src[j] & 0xFFFF != 0:
                        exact = False
                        break
                if not exact:
                    break
            comptime if Self.W16 != DType.uint16:
                exact = False
            wide = not exact
            if exact:
                self.narrowed += 1
            else:
                self.kept += 1
        if wide:
            var buf = self.ctx.enqueue_create_buffer[DType.float32](count)
            var at = 0
            for i in range(len(parts)):
                var n = len(parts[i]) // (2 if dt == "BF16" else 4)
                var h = List[Float32](length=n, fill=0)
                if dt == "BF16":
                    var src = parts[i].unsafe_ptr().unsafe_bitcast[UInt16]()
                    for j in range(n):
                        h[j] = bitcast[DType.float32](UInt32(src[j]) << 16)
                else:
                    var src = parts[i].unsafe_ptr().unsafe_bitcast[Float32]()
                    for j in range(n):
                        h[j] = src[j]
                self.ctx.enqueue_copy(buf.create_sub_buffer[DType.float32](at, n), h.unsafe_ptr())
                self.ctx.synchronize()
                at += n
            self.floats[key] = buf
            return
        var padded = count
        comptime if Self.MMA16:
            if cols > 0:
                padded = (count // cols + 127) // 128 * 128 * cols
        var buf = self.ctx.enqueue_create_buffer[Self.W16](padded)
        if padded > count:
            self.ctx.enqueue_memset(buf, Scalar[Self.W16](0))
        var at = 0
        for i in range(len(parts)):
            var n = len(parts[i]) // (2 if dt == "BF16" else 4)
            var h = List[Scalar[Self.W16]](length=n, fill=0)
            if dt == "BF16":
                var src = parts[i].unsafe_ptr().unsafe_bitcast[UInt16]()
                comptime if Self.W16 == DType.uint16:
                    for j in range(n):
                        h[j] = rebind[Scalar[Self.W16]](src[j])
                else:
                    for j in range(n):
                        h[j] = bitcast[DType.float32](UInt32(src[j]) << 16).cast[Self.W16]()
            else:
                var src = parts[i].unsafe_ptr().unsafe_bitcast[Float32]()
                comptime if Self.W16 == DType.uint16:  # AUTO, exact: the high half
                    var bits = parts[i].unsafe_ptr().unsafe_bitcast[UInt32]()
                    for j in range(n):
                        h[j] = rebind[Scalar[Self.W16]]((bits[j] >> 16).cast[DType.uint16]())
                else:
                    for j in range(n):
                        h[j] = src[j].cast[Self.W16]()
            self.ctx.enqueue_copy(buf.create_sub_buffer[Self.W16](at, n), h.unsafe_ptr())
            self.ctx.synchronize()
            at += n
        self.halves[key] = buf


struct Scratch(Movable):
    """The projections' scratch buffers: split-k's activated input and partial sums; gemm16's fp16 input and
    output."""

    var xa: DeviceBuffer[DType.float32]
    var part: DeviceBuffer[DType.float32]
    var xh: DeviceBuffer[DType.float16]
    var yh: DeviceBuffer[DType.float16]
    var xa_size: Int
    var part_size: Int
    var sk_rows: Int  # projections of at most this many rows take the split-k path
    var staged_target: Int  # split-k on the staged path: the workgroups to aim for (0: never)
    var split_below: Int  # ... for projections of fewer blocks than this (and k >= 2048)
    var act_first: Int  # staged projections with an activation and k >= this activate X once first (0: never)

    def __init__(out self, ctx: DeviceContext, xa_size: Int, part_size: Int, half_size: Int, sk_rows: Int,
                 staged_target: Int = 0, split_below: Int = 0, act_first: Int = 0) raises:
        self.xa = ctx.enqueue_create_buffer[DType.float32](xa_size)
        self.part = ctx.enqueue_create_buffer[DType.float32](part_size)
        self.xh = ctx.enqueue_create_buffer[DType.float16](max(half_size, 64))
        self.yh = ctx.enqueue_create_buffer[DType.float16](max(half_size, 64))
        self.xa_size = xa_size
        self.part_size = part_size
        self.sk_rows = sk_rows
        self.staged_target = staged_target
        self.split_below = split_below
        self.act_first = act_first


def lin[W16: DType, MMA16: Bool, ACT: Int, BIAS: Bool, RES: Bool](
    w: Weights[W16, MMA16], s: Scratch, wname: String, bname: String, x: DeviceBuffer[DType.float32],
    y: DeviceBuffer[DType.float32], rows: Int, n: Int, k: Int, ldx: Int, ldy: Int, xoff: Int = 0,
    alpha: Float32 = 1.0,
) raises:
    """y[:rows, :n] = alpha act(x) W^T (+ b) (+ y), W the device tensor `wname` (n x k, rows k apart), b the fp32
    tensor `bname`. Short X (rows <= s.sk_rows) takes split-k (vgemm.gemm_sk, reduce_sk), the rest the staged
    vgemm.gemm; MMA16: vgemm.gemm16 on the fp16 matrix units."""
    var ctx = w.ctx
    var b = w.floats[bname] if BIAS else s.xa
    comptime if MMA16:
        var w16 = rebind[DeviceBuffer[DType.float16]](w.halves[wname])
        ctx.enqueue_function[vgemm.to_half[ACT]](x, s.xh, Int32(k), Int32(ldx), Int32(xoff), alpha, Int32(rows * k),
                                                 grid_dim=groups(rows * k, 256), block_dim=256)
        if rows % 128 == 0:
            ctx.enqueue_function[vgemm.gemm16[2, 2]](s.xh, w16, s.yh, Int32(n), Int32(k), Int32(ldy),
                                                     grid_dim=Dim(groups(n, 128), rows // 128), block_dim=256)
        else:
            ctx.enqueue_function[vgemm.gemm16[1, 2]](s.xh, w16, s.yh, Int32(n), Int32(k), Int32(ldy),
                                                     grid_dim=Dim(groups(n, 128), rows // 64), block_dim=128)
        ctx.enqueue_function[vgemm.finish16[BIAS, RES]](s.yh, b, y, Int32(n), Int32(ldy), Int32(rows * n),
                                                        grid_dim=groups(rows * n, 256), block_dim=256)
        return
    if wname in w.floats:
        _lin[DType.float32, ACT, BIAS, RES](ctx, s, w.floats[wname], b, x, y, rows, n, k, ldx, ldy, xoff, alpha)
    else:
        _lin[W16, ACT, BIAS, RES](ctx, s, w.halves[wname], b, x, y, rows, n, k, ldx, ldy, xoff, alpha)


def _lin[WT: DType, ACT: Int, BIAS: Bool, RES: Bool](
    ctx: DeviceContext, s: Scratch, w: DeviceBuffer[WT], b: DeviceBuffer[DType.float32], x: DeviceBuffer[DType.float32],
    y: DeviceBuffer[DType.float32], rows: Int, n: Int, k: Int, ldx: Int, ldy: Int, xoff: Int, alpha: Float32,
) raises:
    if rows > s.sk_rows:  # staged: 128 x 128 blocks, or 64 x 128 for narrow projections and odd rows
        comptime if ACT != NONE:
            # A long k with an activation (Gemma's GeGLU down projection: k = 16384): every column block would
            # re-read both of X's halves and recompute the activation; activate X once instead.
            if s.act_first > 0 and k >= s.act_first and rows * k <= s.xa_size:
                ctx.enqueue_function[vgemm.act_rows[ACT]](x, s.xa, Int32(k), Int32(ldx), Int32(xoff),
                                                          Int32(rows * k), grid_dim=groups(rows * k, 256),
                                                          block_dim=256)
                _lin[WT, NONE, BIAS, RES](ctx, s, w, b, s.xa, y, rows, n, k, k, ldy, 0, alpha)
                return
        var wide = rows % 128 == 0 and n > NARROW
        var tiles = groups(n, 128) * rows // (128 if wide else 64)
        var splits = 1
        if tiles < s.split_below and k >= 2048:  # long k, very few blocks: split k, then reduce_sk
            splits = min(groups(s.staged_target, tiles), k // 1024)
        if splits > 1:
            var kc = groups(groups(k, 16), splits) * 16
            splits = groups(k, kc)
            var ldp = groups(n, 64) * 64
            var plane = rows * ldp
            if splits * plane > s.part_size:
                raise Error("lin: partial sums too large")
            if wide:
                ctx.enqueue_function[vgemm.gemm[WT, 2, 2, ACT, False, False, True]](
                    x, w, b, s.part, Int32(n), Int32(k), Int32(ldx), Int32(k), Int32(ldp), Int32(xoff), Float32(1),
                    Int32(kc), Int32(plane), grid_dim=Dim(groups(n, 128), rows // 128, splits), block_dim=256)
            else:
                ctx.enqueue_function[vgemm.gemm[WT, 1, 2, ACT, False, False, True]](
                    x, w, b, s.part, Int32(n), Int32(k), Int32(ldx), Int32(k), Int32(ldp), Int32(xoff), Float32(1),
                    Int32(kc), Int32(plane), grid_dim=Dim(groups(n, 128), rows // 64, splits), block_dim=128)
            ctx.enqueue_function[vgemm.reduce_sk[BIAS, RES]](s.part, b, y, Int32(splits), Int32(n), Int32(ldp),
                                                             Int32(plane), Int32(ldy), alpha, Int32(rows * n),
                                                             grid_dim=groups(rows * n, 256), block_dim=256)
            return
        if wide:
            ctx.enqueue_function[vgemm.gemm[WT, 2, 2, ACT, BIAS, RES]](
                x, w, b, y, Int32(n), Int32(k), Int32(ldx), Int32(k), Int32(ldy), Int32(xoff), alpha, Int32(0),
                Int32(0), grid_dim=Dim(groups(n, 128), rows // 128), block_dim=256)
        else:
            ctx.enqueue_function[vgemm.gemm[WT, 1, 2, ACT, BIAS, RES]](
                x, w, b, y, Int32(n), Int32(k), Int32(ldx), Int32(k), Int32(ldy), Int32(xoff), alpha, Int32(0),
                Int32(0), grid_dim=Dim(groups(n, 128), rows // 64), block_dim=128)
        return
    var xin = x
    var lx = ldx
    comptime if ACT != NONE:  # split-k reads X straight from memory: activate it first
        if rows * k > s.xa_size:
            raise Error("lin: activation scratch too small")
        ctx.enqueue_function[vgemm.act_rows[ACT]](x, s.xa, Int32(k), Int32(ldx), Int32(xoff), Int32(rows * k),
                                                  grid_dim=groups(rows * k, 256), block_dim=256)
        xin = s.xa
        lx = k
    var tiles = groups(n, 128) * (rows // 64)
    var splits = max(1, min(groups(SK_TARGET, tiles), k // 128))
    var kc = groups(groups(k, 16), splits) * 16
    splits = groups(k, kc)
    var ldp = groups(n, 64) * 64
    var plane = rows * ldp
    if splits * plane > s.part_size:
        raise Error("lin: partial sums too large")
    ctx.enqueue_function[vgemm.gemm_sk[WT, 2]](xin, w, s.part, Int32(n), Int32(k), Int32(lx), Int32(k), Int32(kc),
                                               Int32(ldp), Int32(plane),
                                               grid_dim=Dim(groups(n, 128), rows // 64, splits), block_dim=128)
    ctx.enqueue_function[vgemm.reduce_sk[BIAS, RES]](s.part, b, y, Int32(splits), Int32(n), Int32(ldp), Int32(plane),
                                                     Int32(ldy), alpha, Int32(rows * n),
                                                     grid_dim=groups(rows * n, 256), block_dim=256)


def attend[MASK: Bool, HD: Int](
    ctx: DeviceContext, q: DeviceBuffer[DType.float32], k: DeviceBuffer[DType.float32], v: DeviceBuffer[DType.float32],
    o: DeviceBuffer[DType.float32], klev: DeviceBuffer[DType.float32], qlev: DeviceBuffer[DType.float32], ldq: Int,
    ldk: Int, ldo: Int, kcol: Int, vcol: Int, nk: Int, heads: Int, group: Int, qrows: Int, batches: Int,
    batch_rows: Int, scale: Float32,
) raises:
    """vattn.attention for heads of HD: 64 in one launch (Q hoisted), 72 as 64 + 16 columns, 256 as four chunks
    of 64 in one launch. K and V share their leading dimension."""
    comptime if HD == 64:
        ctx.enqueue_function[vattn.attention[MASK, 64, 64, True]](
            q, k, v, o, klev, qlev, Int32(ldq), Int32(ldk), Int32(ldk), Int32(ldo), Int32(0), Int32(kcol), Int32(vcol),
            Int32(0), Int32(nk), Int32(group), scale, Int32(batch_rows), Int32(batch_rows), Int32(0), Int32(1),
            Int32(1), o, o, grid_dim=Dim(heads, qrows // 64, batches), block_dim=64)
    elif HD == 72:
        ctx.enqueue_function[vattn.attention[MASK, 72, 64, False]](
            q, k, v, o, klev, qlev, Int32(ldq), Int32(ldk), Int32(ldk), Int32(ldo), Int32(0), Int32(kcol), Int32(vcol),
            Int32(0), Int32(nk), Int32(group), scale, Int32(batch_rows), Int32(batch_rows), Int32(0), Int32(1),
            Int32(1), o, o, grid_dim=Dim(heads, qrows // 64, batches), block_dim=64)
        ctx.enqueue_function[vattn.attention[MASK, 72, 16, False]](
            q, k, v, o, klev, qlev, Int32(ldq), Int32(ldk), Int32(ldk), Int32(ldo), Int32(0), Int32(kcol), Int32(vcol),
            Int32(0), Int32(nk), Int32(group), scale, Int32(batch_rows), Int32(batch_rows), Int32(64), Int32(1),
            Int32(1), o, o, grid_dim=Dim(heads, qrows // 64, batches), block_dim=64)
    else:
        comptime assert HD % 64 == 0, "heads of 64, 72 or a multiple of 64"
        ctx.enqueue_function[vattn.attention[MASK, HD, 64, False]](
            q, k, v, o, klev, qlev, Int32(ldq), Int32(ldk), Int32(ldk), Int32(ldo), Int32(0), Int32(kcol), Int32(vcol),
            Int32(0), Int32(nk), Int32(group), scale, Int32(batch_rows), Int32(batch_rows), Int32(0), Int32(HD // 64),
            Int32(1), o, o, grid_dim=Dim(heads, qrows // 64, batches * (HD // 64)), block_dim=64)


def attend_split[MASK: Bool, HD: Int](
    ctx: DeviceContext, q: DeviceBuffer[DType.float32], k: DeviceBuffer[DType.float32], v: DeviceBuffer[DType.float32],
    o: DeviceBuffer[DType.float32], klev: DeviceBuffer[DType.float32], qlev: DeviceBuffer[DType.float32],
    part: DeviceBuffer[DType.float32], ml: DeviceBuffer[DType.float32], ldq: Int, ldk: Int, ldo: Int, kcol: Int,
    vcol: Int, nk: Int, heads: Int, group: Int, nsplit: Int, scale: Float32,
) raises:
    """attend for one block of 64 query rows against many keys (the action expert's), the keys split nsplit ways
    (vattn.attention[SPLIT]) and merged (vattn.attention_combine): heads x HD / 64 x nsplit workgroups instead of
    heads x HD / 64. part: heads x HD x 64 x nsplit floats; ml: heads x HD / 64 x nsplit x 128."""
    comptime assert HD % 64 == 0, "heads of a multiple of 64"
    comptime CH = HD // 64
    if heads * CH * nsplit * 64 * 64 > len(part) or heads * CH * nsplit * 128 > len(ml):
        raise Error("attend_split: scratch too small")
    ctx.enqueue_function[vattn.attention[MASK, HD, 64, False, True]](
        q, k, v, o, klev, qlev, Int32(ldq), Int32(ldk), Int32(ldk), Int32(ldo), Int32(0), Int32(kcol), Int32(vcol),
        Int32(0), Int32(nk), Int32(group), scale, Int32(0), Int32(0), Int32(0), Int32(CH), Int32(nsplit), part, ml,
        grid_dim=Dim(heads, 1, CH * nsplit), block_dim=64)
    ctx.enqueue_function[vattn.attention_combine[64]](part, ml, o, Int32(ldo), Int32(0), Int32(HD), Int32(0),
                                                      Int32(CH), Int32(nsplit), grid_dim=Dim(heads * CH, 64),
                                                      block_dim=64)
