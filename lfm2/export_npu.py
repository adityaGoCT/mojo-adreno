"""LFM2.5-2.6B on the Hexagon NPU (HTP): ONNX graphs for ONNX Runtime's QNN execution provider, run by npu/graph.cpp.

The weights are w8a16, as the HTP builds them fast (npu/README.md): every matrix int8 per output channel with an fp32
scale (export.py's npu storage, npu_w8.bin, which lfm2_convert writes on the phone from the GGUF's own numbers), and
each projection between a uint16 QuantizeLinear / DequantizeLinear pair calibrated per tensor. The exception is the
MLPs' down projections, fp16 and float in and out: their inputs carry outliers (layer 4's reach -17 where most values
are ~0.01), and a per-tensor uint16 grid over that range moved the final hidden state by 3.3% (the 11 other
projections' together: well under 1%). Everything else (norms,
the short convolution, RoPE, attention, SwiGLU, the residual stream) is float: the graphs compute in fp32, which the HTP
runs in fp16. fp16 weights would be 5.4 GB of HTP contexts, more than this 11 GB phone holds next to anything else.
The initializers point into npu_w8.bin (external data), which sits next to the graphs.

Graphs (graph.cpp feeds fp32 / int32 inputs, reads fp32 outputs):
  p<i>.onnx    prefill, layers of part i over R rows (the prompt zero-padded at the end; causal, so padding never
               reaches a real row). In: x [R, D] (part 0: the prompt's embedding rows), sel [2] int32 (rows n - 2,
               n - 1). Out: x [R, D] (the last part: the final row x[n - 1] [1, D] instead, picked by sel[1]); per
               attention layer k<l>, v<l> [KVH, R, 64] (k normed and rotated); per conv layer s<l> [2, D] (Bx at rows
               n - 2, n - 1: the conv state).
  d<i>.onnx    decode, one token at position p. In: x [1, D], cos, sin [1, 32] (row p of the table), mask [1, C]
               (0 below p, -30000 from p: cache slots not yet written); per attention layer kc<l>, vc<l> [KVH, C, 64]
               (the cache, rows < p valid); per conv layer s<l> [2, D] (Bx at p - 2, p - 1). Out: x [1, D]; per
               attention layer k<l>, v<l> [KVH, 1, 64] (row p for the cache); per conv layer b<l> [1, D] (Bx at p).
  head.onnx    the final norm and the tied head (int8, 4 chunks): x [1, D] -> logits [1, V]; prefill and decode.

  PYTHONPATH=build/npu/pydeps build/vla/venv/bin/python lfm2/export_npu.py calibrate    # build/lfm2/npu/calib.json
  PYTHONPATH=build/npu/pydeps build/vla/venv/bin/python lfm2/export_npu.py export       # build/lfm2/npu/graphs
  PYTHONPATH=build/npu/pydeps build/vla/venv/bin/python lfm2/export_npu.py check        # the graphs on the Mac's CPU
"""

import argparse
import json
import math
import pathlib
import sys

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2"))
sys.path.insert(0, str(ROOT / "npu"))
from weights import BUILD, GGUFWeights, config  # noqa: E402

NPU = BUILD / "npu"
R = 416  # prefill rows: the 415-token prompt, padded to a multiple of 32
C = 512  # decode: cache slots (prompt + generated tokens)
PARTS = [(0, 6), (6, 12), (12, 18), (18, 24), (24, 30)]
HEAD_CHUNKS = 4
EPS = 1e-5
NEG = -30000.0


# ---- the w8 weights, as lfm2_convert writes them (for calibration and the PyTorch side of the checks) -----------------

def w8(w):
    """int8 per output channel, as convert.c's c8 line: c = max |w| / 127 (fp32), q = rint(w / c) clamped."""
    w = np.asarray(w, np.float32)
    m = np.abs(w).max(axis=1)
    c = np.where(m > 0, m / np.float32(127), np.float32(1)).astype(np.float32)
    q = np.clip(np.rint(w / c[:, None]), -127, 127)
    return q.astype(np.int8), c


class W8Weights(GGUFWeights):
    """The GGUF's weights as the NPU graphs hold them: matrices (and the head) int8 per channel, dequantized to fp32,
    the down projections fp16; the input embedding rows exact (the NPU driver dequantizes the GGUF's Q6_K rows on the
    CPU)."""

    def get(self, name):
        w = super().get(name)
        if name.endswith("feed_forward.w2.weight"):
            return w.half().float()
        if w.dim() == 2:
            q, c = w8(w.numpy())
            return torch.from_numpy(q.astype(np.float32) * c[:, None])
        return w


MARGIN = float(__import__("os").environ.get("LFM2_MARGIN", "1.1"))  # calibrated ranges widened 10%


def act_params(lo, hi, margin=None):
    """uint16 scale and zero point for a tensor seen in [lo, hi] (widened by `margin`; 0 representable)."""
    margin = MARGIN if margin is None else margin
    lo, hi = min(float(lo), 0.0) * margin, max(float(hi), 0.0) * margin
    scale = (hi - lo) / 65535 if hi > lo else 1.0
    zp = int(np.clip(np.rint(-lo / scale), 0, 65535))
    return np.float32(scale), np.uint16(zp)


# ---- calibration --------------------------------------------------------------------------------------------------

def calib_prompts(tok):
    from run import chat_ids
    texts = [t.strip() for t in (ROOT / "npu/calib.txt").read_text().split("---") if t.strip()]
    seqs = [chat_ids(tok, t) for t in texts]
    seqs.append(sum(seqs, [])[:R])  # their concatenation, cut at R rows
    return [s[:R] for s in seqs]


def calibrate():
    """Each projection's input and output range over the calibration prompts (npu/calib.txt in LFM2's chat
    template, not the test prompt), on the model with the w8 weights: transformers' layers, hooked."""
    from reference import forward
    from run import tokenizer
    cfg = config()
    seqs = calib_prompts(tokenizer())
    ranges = {}

    def note(key, t):
        lo, hi = float(t.min()), float(t.max())
        a, b = ranges.get(key, (lo, hi))
        ranges[key] = (min(a, lo), max(b, hi))

    names = {"conv.in_proj": "in", "conv.out_proj": "out", "self_attn.q_proj": "qkv", "self_attn.k_proj": "qkv",
             "self_attn.v_proj": "qkv", "self_attn.out_proj": "o", "feed_forward.w1": "gu", "feed_forward.w3": "gu",
             "feed_forward.w2": "down"}

    def hook(i, layer):
        for mod_name, mod in layer.named_modules():
            if mod_name in names:
                key = f"l{i}.{names[mod_name]}"
                def seen(m, inp, out, key=key):  # returns None: the output stays the module's
                    note(key + ".in", inp[0])
                    note(key + ".out", out)
                mod.register_forward_hook(seen)

    res = forward(cfg, W8Weights(), [(s, 0) for s in seqs], dump=True, hook=hook)
    for logits, _, hn in res:
        note("head.in", hn)
        note("head.out", logits)
    NPU.mkdir(parents=True, exist_ok=True)
    (NPU / "calib.json").write_text(json.dumps({k: [a, b] for k, (a, b) in ranges.items()}, indent=0))
    print(f"calib.json: {len(ranges)} ranges over {len(seqs)} prompts ({sum(map(len, seqs))} rows)")
    for k in ("l0.in.in", "l0.gu.out", "l0.down.in", "l2.qkv.out", "l29.down.in", "head.in", "head.out"):
        print(" ", k, [round(v, 2) for v in ranges[k]])


# ---- graphs -------------------------------------------------------------------------------------------------------

class Graph:
    def __init__(self, man, calib):
        from onnx import TensorProto
        self.T = TensorProto
        self.man, self.calib = man, calib
        self.nodes, self.inits, self.inputs, self.outputs = [], [], [], []
        self.n = 0
        self.names = set()

    def op(self, op, *inputs, n_out=1, **attrs):
        from onnx import helper
        self.n += 1
        outs = [f"{op.lower()}_{self.n}_{i}" for i in range(n_out)]
        self.nodes.append(helper.make_node(op, list(inputs), outs, **attrs))
        return outs[0] if n_out == 1 else outs

    def const(self, name, array):
        import onnx
        if name not in self.names:
            self.names.add(name)
            self.inits.append(onnx.numpy_helper.from_array(np.ascontiguousarray(array), name))
        return name

    def f(self, v):  # an fp32 scalar constant
        return self.const(f"c_{v!r}", np.array(v, np.float32))

    def i64(self, name, v):
        return self.const("c_" + name, np.array(v, np.int64))

    def external(self, name, dtype, dims):
        """The tensor `name` of npu_w8.bin (next to the graph)."""
        if name in self.names:
            return name
        off, nbytes, _ = self.man[name]
        from onnx import TensorProto
        t = TensorProto(name=name, data_type=dtype, dims=dims, data_location=TensorProto.EXTERNAL)
        for k, v in (("location", "npu_w8.bin"), ("offset", str(off)), ("length", str(nbytes))):
            e = t.external_data.add()
            e.key, e.value = k, v
        self.inits.append(t)
        self.names.add(name)
        return name

    def input(self, name, dims, dtype=None):
        from onnx import helper
        self.inputs.append(helper.make_tensor_value_info(name, dtype or self.T.FLOAT, dims))
        return name

    def output(self, name, value, dims):
        """Names `value` `name` (a graph output), renamed in place: QNN takes no Identity node."""
        from onnx import helper
        for node in self.nodes:
            for io in (node.input, node.output):
                for i, v in enumerate(io):
                    if v == value:
                        io[i] = name
        self.outputs.append(helper.make_tensor_value_info(name, self.T.FLOAT, dims))
        return name

    def save(self, path, name):
        import onnx
        from onnx import helper
        g = helper.make_graph(self.nodes, name, self.inputs, self.outputs, self.inits)
        m = helper.make_model(g, opset_imports=[helper.make_opsetid("", 21)], producer_name="lfm2/export_npu.py")
        m.ir_version = 10
        onnx.save(m, str(path))

    # building blocks

    def qdq(self, x, key):
        scale, zp = act_params(*self.calib[key])
        s = self.const(key + ".scale", np.array(scale, np.float32))
        z = self.const(key + ".zp", np.array(zp, np.uint16))
        return self.op("DequantizeLinear", self.op("QuantizeLinear", x, s, z), s, z)

    def gemm(self, x, name, key, rows=None, cols=None):
        """x [rows, in] W^T for npu_w8.bin's int8 matrix `name` [out, in] (an fp32 scale a row), between uint16
        Q/DQ pairs: ONNX Runtime's QDQ Gemm, a QNN FullyConnected with int8 per-channel weights. rows/cols: a slice
        of W's rows (the head's chunks)."""
        if name + ".h" in self.man:  # fp16, float in and out
            dims = self.man[name + ".h"][2]
            w = self.op("Cast", self.external(name + ".h", self.T.FLOAT16, dims), to=self.T.FLOAT)
            return self.op("Gemm", x, w, transB=1)
        off, nbytes, shape = self.man[name + ".q"]
        out, n = shape
        if rows is not None:  # rows a .. b of W: a sub-tensor of the file
            a, b = rows
            qn, cn = f"{name}.q.{a}", f"{name}.c.{a}"
            self.man[qn] = (off + a * n, (b - a) * n, [b - a, n])
            co, _, _ = self.man[name + ".c"]
            self.man[cn] = (co + a * 4, (b - a) * 4, [b - a])
            q = self.external(qn, self.T.INT8, [b - a, n])
            c = self.external(cn, self.T.FLOAT, [b - a])
            out = b - a
        else:
            q = self.external(name + ".q", self.T.INT8, [out, n])
            c = self.external(name + ".c", self.T.FLOAT, [out])
        z = self.const(f"zp_i8_{out}", np.zeros(out, np.int8))
        w = self.op("DequantizeLinear", q, c, z, axis=0)
        return self.qdq(self.op("Gemm", self.qdq(x, key + ".in"), w, transB=1), key + ".out")

    def gemm3(self, x3, name, key, k, n):
        """A projection of blocks of rows: x3 [R / 32, 32, k] through a 2-D [R, k] view, back to [R / 32, 32, n]. The
        HTP runs element-wise ops on such blocks several times faster than on one long [R, c] tensor (the gate/up
        product and SiLU of a layer: 3.5 ms against 18 ms)."""
        y = self.gemm(self.op("Reshape", x3, self.i64(f"shape_r{k}", [R, k])), name, key)
        return self.op("Reshape", y, self.i64(f"shape_b{n}", [R // 32, 32, n]))

    def rms(self, x, w, width, axis=-1):
        """npu/htp_norms.py's rms16 written out: the row scaled to a fixed maximum k first (the HTP flushes fp16
        subnormals), eps carried as (k sqrt(eps) / m)^2; tensor / tensor divisions (QNN mis-sizes Reciprocal)."""
        k = 4.0 if width <= 2048 else 2.0
        ax = self.i64(f"axes{axis}", [axis])
        m = self.op("Max", self.op("ReduceMax", self.op("Abs", x), ax, keepdims=1), self.f(1e-3))
        z = self.op("Div", x, self.op("Mul", m, self.f(1.0 / k)))
        e = self.op("Div", self.op("Add", self.op("Mul", m, self.f(0.0)), self.f(k * math.sqrt(EPS))), m)
        ms = self.op("ReduceMean", self.op("Mul", z, z), ax, keepdims=1)
        r = self.op("Sqrt", self.op("Add", ms, self.op("Mul", e, e)))
        return self.op("Mul", self.op("Div", z, r), w)

    def wvec(self, name, dims):
        return self.external(name, self.T.FLOAT, dims)

    def rope(self, t, cos, sin):
        """t * cos + rotate_half(t) * sin over the last axis (64), cos / sin of the first half [rows, 32]."""
        t1 = self.op("Slice", t, self.i64("s0", [0]), self.i64("s32", [32]), self.i64("ax_1", [-1]))
        t2 = self.op("Slice", t, self.i64("s32", [32]), self.i64("s64", [64]), self.i64("ax_1", [-1]))
        o1 = self.op("Sub", self.op("Mul", t1, cos), self.op("Mul", t2, sin))
        o2 = self.op("Add", self.op("Mul", t2, cos), self.op("Mul", t1, sin))
        return self.op("Concat", o1, o2, axis=-1)


def manifest():
    """npu_w8.bin's tensors: name -> (offset, bytes, shape)."""
    out = {}
    for line in (NPU / "manifest.txt").read_text().splitlines()[1:]:
        f = line.split()
        if f[0] == "layer":
            continue
        out[f[0]] = (int(f[1]), int(f[2]), [int(d) for d in f[4].split("x")])
    return out


def mlp(g, x, l, blocks):
    """x + SwiGLU(rmsnorm(x)): x [1, D] (decode) or blocks of rows [R / 32, 32, D] (prefill)."""
    n = f"l{l}."
    h = g.rms(x, g.wvec(n + "ffn_norm", [2048]), 2048)
    if blocks:
        gu = g.gemm3(h, n + "gu", n + "gu", 2048, 21504)
    else:
        gu = g.gemm(h, n + "gu", n + "gu")
    gt, up = g.op("Split", gu, g.i64("split_ff", [10752, 10752]), axis=-1, n_out=2)
    a = g.op("Mul", g.op("Mul", gt, g.op("Sigmoid", gt)), up)
    d = g.gemm3(a, n + "down", n + "down", 10752, 2048) if blocks else g.gemm(a, n + "down", n + "down")
    return g.op("Add", x, d)


def conv_taps(g, l):
    """The conv taps [2048, 3] as three [2048] rows (transposed and split; ORT folds this at load)."""
    w = g.op("Transpose", g.wvec(f"l{l}.conv", [2048, 3]), perm=[1, 0])
    return g.op("Split", w, g.i64("split_3", [1, 1, 1]), axis=0, n_out=3)


def prefill_part(man, calib, cfg, first, last, final):
    g = Graph(man, calib)
    x = g.input("x", [R, 2048])
    sel = g.input("sel", [2], g.T.INT32)
    tab = np.fromfile(BUILD / "rope.f32", np.float32).reshape(-1, 64)[:R]
    cos, sin = g.const("cos", tab[:, :32]), g.const("sin", tab[:, 32:])
    mask = g.const("mask", np.triu(np.full((R, R), NEG, np.float32), 1))
    B = R // 32
    outs = []
    x = g.op("Reshape", x, g.i64("shape_blocks", [B, 32, 2048]))  # blocks of 32 rows (gemm3)
    for l in range(first, last):
        n = f"l{l}."
        h = g.rms(x, g.wvec(n + "in_norm", [2048]), 2048)
        if cfg.layer_types[l] == "full_attention":
            qkv = g.gemm(g.op("Reshape", h, g.i64("shape_r2048", [R, 2048])), n + "qkv", n + "qkv")
            q, k, v = g.op("Split", qkv, g.i64("split_qkv", [2048, 512, 512]), axis=1, n_out=3)
            q = g.op("Transpose", g.op("Reshape", q, g.i64("shape_q", [R, 32, 64])), perm=[1, 0, 2])
            k = g.op("Transpose", g.op("Reshape", k, g.i64("shape_k", [R, 8, 64])), perm=[1, 0, 2])
            v = g.op("Transpose", g.op("Reshape", v, g.i64("shape_k", [R, 8, 64])), perm=[1, 0, 2])
            q = g.rope(g.rms(q, g.wvec(n + "q_norm", [64]), 64), cos, sin)
            k = g.rope(g.rms(k, g.wvec(n + "k_norm", [64]), 64), cos, sin)
            outs += [(f"k{l}", k, [8, R, 64]), (f"v{l}", v, [8, R, 64])]
            qg = g.op("Reshape", g.op("Mul", q, g.f(0.125)), g.i64("shape_qg", [8, 4 * R, 64]))
            s = g.op("MatMul", qg, g.op("Transpose", k, perm=[0, 2, 1]))
            s = g.op("Add", g.op("Reshape", s, g.i64("shape_s4", [8, 4, R, R])), mask)
            p = g.op("Reshape", g.op("Softmax", s, axis=-1), g.i64("shape_s", [8, 4 * R, R]))
            o = g.op("Reshape", g.op("MatMul", p, v), g.i64("shape_o", [32, R, 64]))
            o = g.op("Reshape", g.op("Transpose", o, perm=[1, 0, 2]), g.i64("shape_x", [R, 2048]))
            x = g.op("Add", x, g.op("Reshape", g.gemm(o, n + "o", n + "o"), g.i64("shape_b2048", [B, 32, 2048])))
        else:
            bcx = g.gemm3(h, n + "in", n + "in", 2048, 6144)
            b, c, xx = g.op("Split", bcx, g.i64("split_bcx", [2048, 2048, 2048]), axis=2, n_out=3)
            bx = g.op("Mul", b, xx)
            bx2 = g.op("Reshape", bx, g.i64("shape_r2048", [R, 2048]))  # rows in order, for the shifts
            outs.append((f"s{l}", g.op("Gather", bx2, sel, axis=0), [2, 2048]))
            pad = g.op("Concat", g.const("zeros2", np.zeros((2, 2048), np.float32)), bx2, axis=0)
            w0, w1, w2 = conv_taps(g, l)
            sh = [g.op("Reshape", g.op("Slice", pad, g.i64(f"s{j}", [j]), g.i64(f"e{j}", [R + j]), g.i64("ax0", [0])),
                       g.i64("shape_b2048", [B, 32, 2048])) for j in range(3)]
            conv = g.op("Add", g.op("Add", g.op("Mul", sh[0], w0), g.op("Mul", sh[1], w1)), g.op("Mul", sh[2], w2))
            x = g.op("Add", x, g.gemm3(g.op("Mul", c, conv), n + "out", n + "out", 2048, 2048))
        x = mlp(g, x, l, True)
    x = g.op("Reshape", x, g.i64("shape_r2048", [R, 2048]))
    if final:
        last_row = g.op("Slice", sel, g.i64("one", [1]), g.i64("two", [2]), g.i64("ax0", [0]))
        g.output("xl", g.op("Gather", x, last_row, axis=0), [1, 2048])
    else:
        g.output("x_out", x, [R, 2048])
    for name, v, dims in outs:
        g.output(name, v, dims)
    return g


def decode_part(man, calib, cfg, first, last):
    g = Graph(man, calib)
    x = g.input("x", [1, 2048])
    cos = g.input("cos", [1, 32])
    sin = g.input("sin", [1, 32])
    mask = g.input("mask", [1, C])
    outs = []
    for l in range(first, last):
        n = f"l{l}."
        h = g.rms(x, g.wvec(n + "in_norm", [2048]), 2048)
        if cfg.layer_types[l] == "full_attention":
            kc = g.input(f"kc{l}", [8, C, 64])
            vc = g.input(f"vc{l}", [8, C, 64])
            qkv = g.gemm(h, n + "qkv", n + "qkv")
            q, k, v = g.op("Split", qkv, g.i64("split_qkv", [2048, 512, 512]), axis=1, n_out=3)
            q = g.op("Reshape", q, g.i64("shape_q1", [32, 1, 64]))
            k = g.op("Reshape", k, g.i64("shape_k1", [8, 1, 64]))
            v = g.op("Reshape", v, g.i64("shape_k1", [8, 1, 64]))
            q = g.rope(g.rms(q, g.wvec(n + "q_norm", [64]), 64), cos, sin)
            k = g.rope(g.rms(k, g.wvec(n + "k_norm", [64]), 64), cos, sin)
            outs += [(f"k{l}", k, [8, 1, 64]), (f"v{l}", v, [8, 1, 64])]
            qg = g.op("Reshape", g.op("Mul", q, g.f(0.125)), g.i64("shape_qg1", [8, 4, 64]))
            sc = g.op("Add", g.op("MatMul", qg, g.op("Transpose", kc, perm=[0, 2, 1])), mask)  # [8, 4, C]
            ss = g.op("MatMul", qg, g.op("Transpose", k, perm=[0, 2, 1]))  # [8, 4, 1]
            p = g.op("Softmax", g.op("Concat", sc, ss, axis=-1), axis=-1)
            pc = g.op("Slice", p, g.i64("s0", [0]), g.i64("sC", [C]), g.i64("ax_1", [-1]))
            ps = g.op("Slice", p, g.i64("sC", [C]), g.i64("sC1", [C + 1]), g.i64("ax_1", [-1]))
            o = g.op("Add", g.op("MatMul", pc, vc), g.op("MatMul", ps, v))  # [8, 4, 64]
            x = g.op("Add", x, g.gemm(g.op("Reshape", o, g.i64("shape_x1", [1, 2048])), n + "o", n + "o"))
        else:
            st = g.input(f"s{l}", [2, 2048])
            bcx = g.gemm(h, n + "in", n + "in")
            b, c, xx = g.op("Split", bcx, g.i64("split_bcx", [2048, 2048, 2048]), axis=1, n_out=3)
            bx = g.op("Mul", b, xx)
            outs.append((f"b{l}", bx, [1, 2048]))
            s0 = g.op("Slice", st, g.i64("s0", [0]), g.i64("one", [1]), g.i64("ax0", [0]))
            s1 = g.op("Slice", st, g.i64("one", [1]), g.i64("two", [2]), g.i64("ax0", [0]))
            w0, w1, w2 = conv_taps(g, l)
            conv = g.op("Add", g.op("Add", g.op("Mul", s0, w0), g.op("Mul", s1, w1)), g.op("Mul", bx, w2))
            x = g.op("Add", x, g.gemm(g.op("Mul", c, conv), n + "out", n + "out"))
        x = mlp(g, x, l, False)
    g.output("x_out", x, [1, 2048])
    for name, v, dims in outs:
        g.output(name, v, dims)
    return g


def head_graph(man, calib, V):
    g = Graph(man, calib)
    x = g.input("x", [1, 2048])
    h = g.rms(x, g.wvec("final_norm", [2048]), 2048)
    step = V // HEAD_CHUNKS
    parts = [g.gemm(h, "head", "head", rows=(i * step, (i + 1) * step)) for i in range(HEAD_CHUNKS)]
    g.output("logits", g.op("Concat", *parts, axis=1), [1, V])
    return g


def export():
    cfg = config()
    man = manifest()
    calib = {k: tuple(v) for k, v in json.loads((NPU / "calib.json").read_text()).items()}
    out = NPU  # next to npu_w8.bin: ONNX Runtime reads external data only from the graph's own directory
    for i, (a, b) in enumerate(PARTS):
        prefill_part(man, calib, cfg, a, b, i == len(PARTS) - 1).save(out / f"p{i}.onnx", f"lfm2_p{i}")
        decode_part(man, calib, cfg, a, b).save(out / f"d{i}.onnx", f"lfm2_d{i}")
        print(f"part {i}: layers {a}..{b - 1}")
    head_graph(man, calib, cfg.vocab_size).save(out / "head.onnx", "lfm2_head")
    print("graphs in", out, [p.name for p in sorted(out.glob("*.onnx"))])


def embed_rows(ids, rows=R):
    """The prompt's embedding rows (the GGUF's Q6_K, exact), zero-padded to `rows`: part 0's input x."""
    x = np.zeros((rows, 2048), np.float32)
    x[:len(ids)] = GGUFWeights().embed_rows(ids).numpy()
    return x


def ref_states(ids, W):
    """The PyTorch model (transformers' layers on W) over ids: each attention layer's K (normed, rotated) and V
    [8, n, 64], each conv layer's Bx at the last two rows [2, D], the hidden state after each layer, the last row's
    logits."""
    from reference import forward
    cfg = config()
    tab = np.fromfile(BUILD / "rope.f32", np.float32).reshape(-1, 64)[:len(ids)]
    cos, sin = tab[:, :32], tab[:, 32:]
    st = {}

    def hook(i, layer):
        if cfg.layer_types[i] == "full_attention":
            def kn(m, inp, out, i=i):
                k = out[0].numpy()  # [n, 8, 64]
                k1, k2 = k[..., :32], k[..., 32:]
                st[f"k{i}"] = np.concatenate([k1 * cos[:, None] - k2 * sin[:, None],
                                              k2 * cos[:, None] + k1 * sin[:, None]], -1).transpose(1, 0, 2)
            def vp(m, inp, out, i=i):
                st[f"v{i}"] = out[0].numpy().reshape(len(ids), 8, 64).transpose(1, 0, 2)
            layer.self_attn.k_layernorm.register_forward_hook(kn)
            layer.self_attn.v_proj.register_forward_hook(vp)
        else:
            def ip(m, inp, out, i=i):
                b = out[0].numpy()
                st[f"s{i}"] = (b[:, :2048] * b[:, 4096:])[-2:]
            layer.conv.in_proj.register_forward_hook(ip)

    logits, hs, _ = forward(cfg, W, [(ids, len(ids) - 1)], dump=True, hook=hook, log=lambda *a: None)[0]
    return st, hs.numpy(), logits[-1].numpy()


def check():
    """The prefill graphs and the head on the Mac's CPU (ONNX Runtime, no graph optimizations: the int8 weights
    stay int8 until each Gemm) on the 415-token prompt, against PyTorch with the same w8 weights (the graphs' only
    other difference: the uint16 activations) and with the GGUF's."""
    import onnxruntime as ort
    from run import chat_ids, softmax_kl, tokenizer
    ids = chat_ids(tokenizer(), (ROOT / "lfm2/prompts/long.txt").read_text())
    n = len(ids)
    so = ort.SessionOptions()
    so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_DISABLE_ALL
    x = embed_rows(ids)
    sel = np.array([n - 2, n - 1], np.int32)
    got = {}
    for i in range(len(PARTS)):
        s = ort.InferenceSession(str(NPU / f"p{i}.onnx"), so, providers=["CPUExecutionProvider"])
        outs = s.run(None, {"x": x, "sel": sel})
        for o, v in zip(s.get_outputs(), outs):
            got[o.name] = v
        x = outs[0]
        got[f"x{i}"] = x
        print(f"p{i}: ran", flush=True)
    s = ort.InferenceSession(str(NPU / "head.onnx"), so, providers=["CPUExecutionProvider"])
    logits = s.run(None, {"x": got["xl"]})[0][0]
    for label, W in (("w8 weights", W8Weights()), ("GGUF weights", GGUFWeights())):
        st, hs, ref = ref_states(ids, W)
        def rel(a, b):
            return float(np.linalg.norm(a - b) / np.linalg.norm(b))
        kv = max(rel(got[k][:, :n], st[k]) for k in st if k[0] in "kv")
        ss = max(rel(got[k], st[k]) for k in st if k[0] == "s")
        xs = [rel(got[f"x{i}"][:n], hs[b][:n]) for i, (a, b) in enumerate(PARTS[:-1])]
        print(f"vs PyTorch with the {label}: K/V rel {kv:.2e} (worst layer), conv states {ss:.2e}, "
              f"parts' x {', '.join(f'{v:.1e}' for v in xs)}; logits max |diff| {np.abs(logits - ref).max():.3f} "
              f"(range {ref.min():.1f} .. {ref.max():.1f}), argmax {int(logits.argmax())} vs {int(ref.argmax())}, "
              f"KL {softmax_kl(ref, logits):.2e}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("step", choices=["calibrate", "export", "check"])
    a = ap.parse_args()
    {"calibrate": calibrate, "export": export, "check": check}[a.step]()


if __name__ == "__main__":
    main()
