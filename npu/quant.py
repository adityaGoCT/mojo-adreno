"""Quantized weights for the HTP: low-power block quantization (LPBQ), the one form of block-quantized int4
weights that ONNX Runtime 1.29's QNN execution provider hands to QNN (QNN_QUANTIZATION_ENCODING_BLOCKWISE_EXPANSION,
its LowPowerBlockQuantized{Gemm,MatMul}Fusion). A weight [out, in] in blocks of 64 along `in` is

    w[o, i] = q[o, i] * c[o] * u[o, i // 64]      q int4 (-8 .. 7), c fp32 per output channel, u 4-bit (1 .. 15)

In ONNX it is two DequantizeLinear nodes feeding a MatMul's right operand, stored [in, out]: u (uint8 [in/64, out])
with scale c and axis 1 gives the block scales, which a second DequantizeLinear (block_size 64, axis 0) applies to q
(INT4 [in, out], zero point 0). The MatMul form becomes a QNN MatMul. The Gemm form (weights [out, in], transB=1),
which becomes a FullyConnected, crashes QNN 2.42's HTP backend (a segmentation fault while it adds the weight)
whenever in > 2048, whatever the number of blocks; it works at in = 2048. A plain
DequantizeLinear with fp16 block scales (llama/run.py --quant q4's format) is not mapped: QNN's own BQ encoding
has no caller in that execution provider, and its per-channel path would misread the scales. So the weights are
quantized again here, from the fp16 weights, to scales of that form: each block takes the u in ceil(s/c) - 1 ..
ceil(s/c) + 1 that minimizes its squared error, where s = max |w| / 7 is the block's own scale and c the row's
largest s over 15.

Activations are uint16 per tensor (asymmetric), calibrated in PyTorch on prompts other than the test prompt, on
the model with these weights: the input and output range of every projection.

The quantized graphs read their own weights.bin (int4 weights, uint8 block scales, fp32 channel scales, fp32 norms)
written here with a manifest.txt of "<name> <offset> <bytes>" lines; the graphs sit next to it.
"""

import json
import pathlib

import numpy as np

BLOCK = 64
UMAX = 15  # 4-bit block scales (blockScaleBitwidth 4 for int4 weights)
KMAX = 2048  # the widest input of a FullyConnected with LPBQ weights that QNN 2.42 builds (form "fc")


def lpbq(w, block=BLOCK):
    """w fp32 [out, in] -> (q int8 [out, in] in -8..7, c fp32 [out], u uint8 [out, in / block] in 1..15)."""
    out, n = w.shape
    wb = w.reshape(out, n // block, block)
    s = np.abs(wb).max(-1) / np.float32(7)
    c = (s.max(-1) / np.float32(UMAX)).astype(np.float32)
    c = np.where(c > 0, c, np.float32(1))
    base = np.ceil(s / c[:, None] - np.float32(1e-4))
    best_u = best_q = best_e = None
    for du in (-1, 0, 1):
        u = np.clip(base + du, 1, UMAX).astype(np.float32)
        sc = (c[:, None] * u)[..., None]
        q = np.clip(np.rint(wb / sc), -8, 7)
        e = np.square(q * sc - wb).sum(-1)
        if best_e is None:
            best_u, best_q, best_e = u, q, e
        else:
            take = e < best_e
            best_u = np.where(take, u, best_u)
            best_q = np.where(take[..., None], q, best_q)
            best_e = np.where(take, e, best_e)
    return best_q.reshape(out, n).astype(np.int8), c, best_u.astype(np.uint8)


def perchannel(w, bits):
    """Symmetric per-output-channel quantization of w fp32 [out, in]: (q int8 [out, in], c fp32 [out]), int8 in
    -127..127 or int4 in -8..7 with c = max |row| / 127 or / 7. npu/pc_convert.cpp does the same on the phone."""
    qmax = np.float32(127 if bits == 8 else 7)
    c = (np.abs(w).max(1) / qmax).astype(np.float32)
    c = np.where(c > 0, c, np.float32(1))
    q = np.clip(np.rint(w / c[:, None]), -127 if bits == 8 else -8, qmax).astype(np.int8)
    return q, c


def dequant(q, c, u, block=BLOCK):
    """The fp32 weight the graph's two DequantizeLinear nodes compute: q * (u * c)."""
    out, n = q.shape
    s = (u.astype(np.float32) * c[:, None]).astype(np.float32)
    return (q.reshape(out, n // block, block).astype(np.float32) * s[..., None]).reshape(out, n)


def pack_int4(q):
    """ONNX INT4: element 2j in the low nibble of byte j, 2j+1 in the high one (llama/run.py's packing too)."""
    flat = q.reshape(-1).astype(np.int16) & 0xF
    return (flat[0::2] | (flat[1::2] << 4)).astype(np.uint8)


def unpack_int4(b, shape):
    lo = (b & 0xF).astype(np.int8)
    hi = (b >> 4).astype(np.int8)
    q = np.empty(b.size * 2, np.int8)
    q[0::2], q[1::2] = lo, hi
    q = np.where(q > 7, q - 16, q).astype(np.int8)
    return q.reshape(shape)


class Data:
    """Writes a weights.bin (256-byte aligned tensors) and its manifest.txt."""

    def __init__(self, out_dir, header):
        self.dir = pathlib.Path(out_dir)
        self.dir.mkdir(parents=True, exist_ok=True)
        self.f = open(self.dir / "weights.bin.tmp", "wb")
        self.lines = [header]
        self.recipe = [header]  # how npu/pc_convert.cpp writes the same file from the fp16 weights.bin

    def add(self, name, a, recipe=None):
        a = np.ascontiguousarray(a)
        self.f.write(b"\0" * (-self.f.tell() % 256))
        self.lines.append(f"{name} {self.f.tell()} {a.nbytes}")
        self.f.write(a.tobytes())
        if recipe:
            self.recipe.append(recipe)

    def matrix(self, name, w, form, src=None):
        """Forms "pc8" and "pc4": per-channel int8 or int4 for a Gemm (transB), q [out, in] and c [out]."""
        if form in ("pc8", "pc4"):
            q, c = perchannel(w, 8 if form == "pc8" else 4)
            self.add(name + ".q", q if form == "pc8" else pack_int4(q),
                     f"{form} {name} {src} {w.shape[0]} {w.shape[1]}" if src else None)
            self.add(name + ".c", c)
            return q.astype(np.float32) * c[:, None]
        return self.lpbq_matrix(name, w, form)

    def lpbq_matrix(self, name, w, form):
        """w [out, in]. Form "matmul": MatMul's right operand, q INT4 [in, out], u [in / 64, out], c [out]. Form
        "fc": Gemm's (transB), q [out, in], u [out, in / 64], c [out]; an input wider than KMAX is split into
        chunks of KMAX (<name>.k<j>.q/u/c), each its own FullyConnected."""
        if form == "fc" and w.shape[1] > KMAX:
            return np.concatenate([self.lpbq_matrix(f"{name}.k{j}", w[:, j * KMAX:(j + 1) * KMAX], form)
                                   for j in range(w.shape[1] // KMAX)], 1)
        q, c, u = lpbq(w)
        t = (lambda a: np.ascontiguousarray(a.T)) if form == "matmul" else np.ascontiguousarray
        self.add(name + ".q", pack_int4(t(q)))
        self.add(name + ".u", t(u))
        self.add(name + ".c", c)
        return dequant(q, c, u)

    def close(self):
        self.f.close()
        (self.dir / "weights.bin.tmp").rename(self.dir / "weights.bin")
        (self.dir / "manifest.txt").write_text("\n".join(self.lines) + "\n")
        (self.dir / "recipe.txt").write_text("\n".join(self.recipe) + "\n")


def read_manifest(d):
    lines = (pathlib.Path(d) / "manifest.txt").read_text().splitlines()
    return lines[0], {f[0]: (int(f[1]), int(f[2])) for f in (l.split() for l in lines[1:]) if len(f) == 3}


class Reader:
    """Tensors of a Data file, by name."""

    def __init__(self, d):
        self.dir = pathlib.Path(d)
        self.header, self.man = read_manifest(d)
        h = self.header.split()
        self.form = h[h.index("form") + 1] if "form" in h else "matmul"
        self.mm = np.memmap(self.dir / "weights.bin", np.uint8, "r")

    def raw(self, name):
        off, n = self.man[name]
        return self.mm[off:off + n]

    def matrix(self, name, out, n):
        """The dequantized weight [out, in] of Data.matrix (the header's "form" says which)."""
        if name + ".k0.q" in self.man:
            return np.concatenate([self.matrix(f"{name}.k{j}", out, KMAX) for j in range(n // KMAX)], 1)
        c = np.asarray(self.raw(name + ".c")).view(np.float32)
        if self.form in ("pc8", "pc4"):
            raw = np.asarray(self.raw(name + ".q"))
            q = raw.view(np.int8).reshape(out, n) if self.form == "pc8" else unpack_int4(raw, (out, n))
            return q.astype(np.float32) * c[:, None]
        if self.form == "matmul":
            q = unpack_int4(np.asarray(self.raw(name + ".q")), (n, out)).T
            u = np.asarray(self.raw(name + ".u")).reshape(n // BLOCK, out).T
        else:
            q = unpack_int4(np.asarray(self.raw(name + ".q")), (out, n))
            u = np.asarray(self.raw(name + ".u")).reshape(out, n // BLOCK)
        return dequant(np.ascontiguousarray(q), c, np.ascontiguousarray(u))


def act_params(lo, hi, margin=1.1):
    """uint16 scale and zero point for a tensor seen in [lo, hi] (widened by `margin`; 0 representable)."""
    lo, hi = min(float(lo), 0.0) * margin, max(float(hi), 0.0) * margin
    scale = (hi - lo) / 65535 if hi > lo else 1.0
    zp = int(np.clip(np.rint(-lo / scale), 0, 65535))
    return np.float32(scale), np.uint16(zp)


def save_calib(path, ranges):
    pathlib.Path(path).write_text(json.dumps({k: [float(a), float(b)] for k, (a, b) in ranges.items()}, indent=0))


def load_calib(path):
    return {k: tuple(v) for k, v in json.loads(pathlib.Path(path).read_text()).items()}
