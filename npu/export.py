"""Llama 3.2 1B's prompt prefill as ONNX graphs for the Hexagon NPU (ONNX Runtime's QNN execution provider,
HTP backend). The graphs carry no weights: each initializer points into the weights.bin that llama/run.py
exports and llama/st2bin.c writes on the phone, at manifest.txt's offset, so the phone needs only the graphs
(2 MB each) next to a hard link to its own weights.bin.

  PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python
  PYTHONPATH=build/npu/pydeps $PY npu/export.py --model build/llama/model --out build/npu/graphs

Every part runs `rows` prompt rows at once (positions 0 .. rows-1; a shorter prompt is zero-padded at the
end, and the causal mask keeps the padding out of the real rows):

  part i:    x [rows, 2048] fp16  ->  k<l>, v<l> [8, 512, 64] fp16 for its layers, x_out [rows, 2048]
  last part: x, last int32 [1]    ->  k<l>, v<l> for its layers, logits [1, 128256] fp16 of row `last`

k<l> is RoPE'd, so k<l> and v<l> are llama/model.mojo's KV cache of layer l in fp16: [kv head][position][64] with
all 512 (MAXPOS) positions, the first `rows` written and the rest zero (--kv-slots 512, a Pad on each output).
npu_decode binds the decode graphs' own fp16 cache as these outputs, so the prefill writes the cache directly. The
embedding rows (x of part 0) are gathered on the CPU.

All math is fp16, the HTP's float type. RMSNorm is ONNX's RMSNormalization (QNN's RmsNorm): the residual
stream reaches 410, whose square overflows fp16, so x * x / D cannot be written out in fp16 ops.

--fp32 writes the same graphs with the weights cast to fp32, for checking the graph on the Mac's CPU.

--quant w4a16 writes w4a16 graphs (npu/quant.py): every projection and the lm_head take int4 weights with
low-power block quantization (blocks of 64) and uint16 activations, each Gemm between a QuantizeLinear /
DequantizeLinear pair calibrated per tensor. The rest of the graph (RMSNorm, RoPE, attention, SwiGLU, residual)
is float: fp32 in the graph, which the HTP runs in fp16 (QNN's scales must be fp32, so Q/DQ cannot sit on fp16
tensors). The inputs and outputs stay fp16 (Casts at the edges), so npu_prefill.cpp reads either kind. These
graphs read their own weights.bin, written next to them (the fp16 one is only read here, to quantize). Layer 1's
down projection stays fp16 (--keep): its input carries the massive activation (-1093), too wide for uint16.

  PYTHONPATH=build/npu/pydeps $PY npu/export.py --quant w4a16 --hf <Llama-3.2-1B-Instruct snapshot>
"""

import argparse
import os
import pathlib

import numpy as np
import onnx
from onnx import TensorProto, helper

import quant

D, L, H, KVH, HD, F, V, CHUNKS = 2048, 16, 32, 8, 64, 8192, 128256, 4
QKV = (H + 2 * KVH) * HD
EPS = 1e-5
OPSET = 23  # RMSNormalization


def manifest(model_dir):
    lines = (model_dir / "manifest.txt").read_text().splitlines()
    assert lines[0].split()[:8] == ["llama", "2048", "16", "32", "8", "64", "8192", "128256"], lines[0]
    return {f[0]: (int(f[1]), int(f[2])) for f in (line.split() for line in lines[1:]) if len(f) == 3}


class Graph:
    def __init__(self, man, fp32, qman=None, calib=None, form="matmul"):
        self.man, self.fp32 = man, fp32
        self.qman, self.calib = qman, calib  # w4a16: the quantized weights.bin's manifest, activation ranges
        self.form = form  # w4a16: "matmul" or "fc" (npu/quant.py)
        fp32 = fp32 or qman is not None
        self.f = TensorProto.FLOAT if fp32 else TensorProto.FLOAT16
        self.np = np.float32 if fp32 else np.float16
        self.io = TensorProto.FLOAT16 if qman is not None else self.f  # the graph's inputs and outputs
        self.nodes, self.inits, self.n = [], [], 0
        self.weights, self.consts = {}, set()
        self.leaf_kv = False
        self.kv_slots = 0  # > rows: K/V outputs zero-padded to [8, kv_slots, 64], a KV cache's layout

    def op(self, op, *inputs, **attrs):
        self.n += 1
        out = f"{op.lower()}_{self.n}"
        self.nodes.append(helper.make_node(op, list(inputs), [out], **attrs))
        return out

    def ops(self, op, inputs, n_out, **attrs):
        self.n += 1
        outs = [f"{op.lower()}_{self.n}_{i}" for i in range(n_out)]
        self.nodes.append(helper.make_node(op, list(inputs), outs, **attrs))
        return outs

    def const(self, name, array):
        if name not in self.consts:
            self.consts.add(name)
            self.inits.append(onnx.numpy_helper.from_array(np.ascontiguousarray(array), name))
        return name

    def weight(self, name, dims):
        """The fp16 tensor `name` of weights.bin, as an external initializer (cast to fp32 with --fp32)."""
        if name in self.weights:
            return self.weights[name]
        off, nbytes = self.man[name]
        assert nbytes == 2 * int(np.prod(dims)), (name, dims, nbytes)
        t = TensorProto(name=name, data_type=TensorProto.FLOAT16, dims=dims, data_location=TensorProto.EXTERNAL)
        for k, v in (("location", "weights.bin"), ("offset", str(off)), ("length", str(nbytes))):
            e = t.external_data.add()
            e.key, e.value = k, v
        self.inits.append(t)
        self.weights[name] = self.op("Cast", name, to=TensorProto.FLOAT) if self.fp32 else name
        return self.weights[name]

    def external(self, name, dtype, dims):
        """The tensor `name` of the quantized weights.bin (next to the graph)."""
        off, nbytes = self.qman[name]
        t = TensorProto(name=name, data_type=dtype, dims=dims, data_location=TensorProto.EXTERNAL)
        for k, v in (("location", "weights.bin"), ("offset", str(off)), ("length", str(nbytes))):
            e = t.external_data.add()
            e.key, e.value = k, v
        self.inits.append(t)
        return name

    def norm(self, name, dim=D):
        if self.qman is None:
            return self.weight(name, [dim])
        return self.external(name, TensorProto.FLOAT, [dim])

    def qdq(self, x, key):
        """x through a uint16 QuantizeLinear / DequantizeLinear pair with key's calibrated range."""
        scale, zp = quant.act_params(*self.calib[key])
        s = self.const(key + ".scale", np.array(scale, np.float32))
        z = self.const(key + ".zp", np.array(zp, np.uint16))
        return self.op("DequantizeLinear", self.op("QuantizeLinear", x, s, z), s, z)

    def gemm(self, x, name, dims, key):
        """x [rows, in] times the weight `name` [out, in] transposed. w4a16: the LPBQ pattern of ONNX Runtime's
        QNN execution provider, DQ(x) -> MatMul(DQ(q int4 [in, out], DQ(u uint8, c))) -> Q, one QNN MatMul with
        block-quantized weights on the HTP (npu/quant.py: the Gemm form crashes QNN for in > 2048)."""
        if self.qman is None:
            return self.op("Gemm", x, self.weight(name, dims), transB=1)
        if name in self.qman:  # kept in fp16 (--keep): a float Gemm, no Q/DQ
            w = self.op("Cast", self.external(name, TensorProto.FLOAT16, dims), to=TensorProto.FLOAT)
            return self.op("Gemm", x, w, transB=1)
        if self.form == "fc":
            return self.fc(x, name, dims, key)
        if self.form in ("pc8", "pc4"):  # per-channel int8 / int4: ONNX Runtime's plain QDQ Gemm, a QNN FC
            out, n = dims
            dt = TensorProto.INT8 if self.form == "pc8" else TensorProto.INT4
            q = self.external(name + ".q", dt, [out, n])
            c = self.external(name + ".c", TensorProto.FLOAT, [out])
            zq = f"zp_{self.form}_{out}"
            if zq not in self.consts:
                self.consts.add(zq)
                self.inits.append(helper.make_tensor(zq, dt, [out], bytes(out if dt == TensorProto.INT8 else (out + 1) // 2),
                                                     raw=True))
            w = self.op("DequantizeLinear", q, c, zq, axis=0)
            return self.qdq(self.op("Gemm", self.qdq(x, key + ".in"), w, transB=1), key + ".out")
        out, n = dims
        nb = n // quant.BLOCK
        q = self.external(name + ".q", TensorProto.INT4, [n, out])
        u = self.external(name + ".u", TensorProto.UINT8, [nb, out])
        c = self.external(name + ".c", TensorProto.FLOAT, [out])
        zu = self.const(f"zp_u{out}", np.zeros(out, np.uint8))
        zq = f"zp_q{nb}x{out}"
        if zq not in self.consts:
            self.consts.add(zq)
            self.inits.append(helper.make_tensor(zq, TensorProto.INT4, [nb, out], bytes(out * nb // 2), raw=True))
        scales = self.op("DequantizeLinear", u, c, zu, axis=1)
        w = self.op("DequantizeLinear", q, scales, zq, axis=0, block_size=quant.BLOCK)
        y = self.op("MatMul", self.qdq(x, key + ".in"), w)
        return self.qdq(y, key + ".out")

    def fc(self, x, name, dims, key):
        """Form "fc": DQ(x) -> Gemm(DQ(q int4 [out, in], DQ(u uint8, c)), transB) -> Q, a QNN FullyConnected with
        LPBQ weights; an input wider than quant.KMAX is split into chunks, their products added in float."""
        out, n = dims
        if n > quant.KMAX:
            k = n // quant.KMAX
            xs = self.ops("Split", [x, self.const(f"split_k{n}", np.full(k, quant.KMAX, np.int64))], k, axis=1)
            ys = [self.fc_chunk(xs[j], f"{name}.k{j}", out, quant.KMAX, key + ".in", f"{key}.k{j}.out")
                  for j in range(k)]
            y = ys[0]
            for t in ys[1:]:
                y = self.op("Add", y, t)
            return y
        return self.fc_chunk(x, name, out, n, key + ".in", key + ".out")

    def fc_chunk(self, x, name, out, n, key_in, key_out):
        nb = n // quant.BLOCK
        q = self.external(name + ".q", TensorProto.INT4, [out, n])
        u = self.external(name + ".u", TensorProto.UINT8, [out, nb])
        c = self.external(name + ".c", TensorProto.FLOAT, [out])
        zu = self.const(f"zp_u{out}", np.zeros(out, np.uint8))
        zq = f"zp_q{out}x{nb}"
        if zq not in self.consts:
            self.consts.add(zq)
            self.inits.append(helper.make_tensor(zq, TensorProto.INT4, [out, nb], bytes(out * nb // 2), raw=True))
        scales = self.op("DequantizeLinear", u, c, zu, axis=0)
        w = self.op("DequantizeLinear", q, scales, zq, axis=1, block_size=quant.BLOCK)
        return self.qdq(self.op("Gemm", self.qdq(x, key_in), w, transB=1), key_out)

    def to_io(self, value):
        return self.op("Cast", value, to=self.io) if self.io != self.f else value

    def output(self, name, value):
        """Names `value` `name` (a graph output): renamed in place, as QNN takes no Identity node."""
        for node in self.nodes:
            for io in (node.input, node.output):
                for i, v in enumerate(io):
                    if v == value:
                        io[i] = name
        return name


def rope_tables(model_dir, man, rows):
    """cos and sin [1, rows, 64] (each half the table's 32 frequencies), from weights.bin's fp32 tables."""
    out = []
    with open(model_dir / "weights.bin", "rb") as f:
        for name in ("rope.cos", "rope.sin"):
            off, nbytes = man[name]
            f.seek(off)
            t = np.frombuffer(f.read(nbytes), np.float32).reshape(-1, HD // 2)[:rows]
            out.append(np.concatenate([t, t], 1)[None])
    return out


def layer(g, l, x, rows, cos, sin, mask, scale):
    p = f"l{l}."
    xn = g.op("RMSNormalization", x, g.norm(p + "attn_norm"), axis=-1, epsilon=EPS)
    qkv = g.gemm(xn, p + "wqkv", [QKV, D], p + "qkv")
    q, k, v = g.ops("Split", [qkv, g.const(p + "split_qkv", np.array([H * HD, KVH * HD, KVH * HD], np.int64))], 3,
                    axis=1)

    def heads(t, n):  # [rows, n*64] -> [n, rows, 64]
        return g.op("Transpose", g.op("Reshape", t, g.const(f"shape_{n}", np.array([rows, n, HD], np.int64))),
                    perm=[1, 0, 2])

    def rope(t):  # t * cos + rotate_half(t) * sin, rotate_half(t) = [-t2, t1]
        t1, t2 = g.ops("Split", [t, g.const("split_half", np.array([HD // 2, HD // 2], np.int64))], 2, axis=-1)
        rot = g.op("Concat", g.op("Neg", t2), t1, axis=-1)
        return g.op("Add", g.op("Mul", t, cos), g.op("Mul", rot, sin))

    q = rope(heads(q, H))
    k = rope(heads(k, KVH))
    v = heads(v, KVH)
    if g.leaf_kv:  # outputs of their own Reshape, [8, rows * 64], not consumed inside the graph
        flat = g.const("shape_kv_out", np.array([KVH, rows * HD], np.int64))
        g.output(f"k{l}", g.op("Reshape", k, flat))
        g.output(f"v{l}", g.op("Reshape", v, flat))
    elif g.kv_slots > rows or g.io != g.f:
        # outputs [8, kv_slots, 64] (the decode cache itself can be the output buffer), and fp16 copies of
        # quantized graphs' fp32 K/V
        pads = g.const("pads_kv", np.array([0, 0, 0, 0, g.kv_slots - rows, 0], np.int64)) if g.kv_slots > rows else None
        for name, t in ((f"k{l}", k), (f"v{l}", v)):
            g.output(name, g.to_io(g.op("Pad", t, pads) if pads else t))
    else:
        k = g.output(f"k{l}", k)
        v = g.output(f"v{l}", v)
    # grouped-query attention: query heads 4j .. 4j+3 read KV head j, so [32, rows, 64] -> [8, 4 rows, 64]
    qg = g.op("Mul", g.op("Reshape", q, g.const("shape_qg", np.array([KVH, H // KVH * rows, HD], np.int64))), scale)
    s = g.op("MatMul", qg, g.op("Transpose", k, perm=[0, 2, 1]))  # [8, 4 rows, rows]
    s = g.op("Add", s, mask)
    o = g.op("MatMul", g.op("Softmax", s, axis=-1), v)  # [8, 4 rows, 64]
    o = g.op("Reshape", g.op("Transpose", g.op("Reshape", o, g.const("shape_o", np.array([H, rows, HD], np.int64))),
                             perm=[1, 0, 2]), g.const("shape_x", np.array([rows, D], np.int64)))
    x = g.op("Add", x, g.gemm(o, p + "wo", [D, D], p + "o"))
    xn = g.op("RMSNormalization", x, g.norm(p + "mlp_norm"), axis=-1, epsilon=EPS)
    gu = g.gemm(xn, p + "wgu", [2 * F, D], p + "gu")
    gate, up = g.ops("Split", [gu, g.const("split_gu", np.array([F, F], np.int64))], 2, axis=1)
    act = g.op("Mul", g.op("Mul", gate, g.op("Sigmoid", gate)), up)
    return g.op("Add", x, g.gemm(act, p + "wdown", [D, F], p + "down"))


def part(model_dir, man, first, last, rows, head, fp32, leaf_kv, kv_slots=0, qman=None, calib=None, form="matmul"):
    g = Graph(man, fp32, qman, calib, form)
    g.leaf_kv = leaf_kv
    g.kv_slots = kv_slots
    cos, sin = rope_tables(model_dir, man, rows)
    cos, sin = g.const("rope_cos", cos.astype(g.np)), g.const("rope_sin", sin.astype(g.np))
    mask = np.where(np.tril(np.ones((rows, rows), bool)), 0, -30000).astype(g.np)  # [rows, rows], tiled 4 times
    mask = g.const("mask", np.tile(mask, (H // KVH, 1))[None])  # [1, 4 rows, rows]
    scale = g.const("scale", np.array(0.125, g.np))
    inputs = [helper.make_tensor_value_info("x", g.io, [rows, D])]
    x = g.op("Cast", "x", to=g.f) if g.io != g.f else "x"
    outputs = []
    for l in range(first, last):
        x = layer(g, l, x, rows, cos, sin, mask, scale)
        kv_shape = [KVH, rows * HD] if leaf_kv else [KVH, max(rows, kv_slots), HD]
        outputs += [helper.make_tensor_value_info(f"{kv}{l}", g.io, kv_shape) for kv in "kv"]
    if head:
        inputs.append(helper.make_tensor_value_info("last", TensorProto.INT32, [1]))
        xl = g.op("RMSNormalization", g.op("Gather", x, "last", axis=0), g.norm("final_norm"), axis=-1,
                  epsilon=EPS)
        if qman is None:
            chunks = [g.gemm(xl, f"embed.{c}", [V // CHUNKS, D], None) for c in range(CHUNKS)]
        else:  # the lm_head's int4 copy of the tied embedding, its 4 chunks sharing one input and output range
            chunks = [g.gemm(xl, f"lm.{c}", [V // CHUNKS, D], "head") for c in range(CHUNKS)]
        g.output("logits", g.to_io(g.op("Concat", *chunks, axis=1)))
        outputs.append(helper.make_tensor_value_info("logits", g.io, [1, V]))
    else:
        g.output("x_out", g.to_io(x))
        outputs.append(helper.make_tensor_value_info("x_out", g.io, [rows, D]))
    graph = helper.make_graph(g.nodes, f"llama_prefill_l{first}_{last}", inputs, outputs, g.inits)
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", OPSET)], producer_name="mojo-adreno/npu")
    model.ir_version = 10
    return model


def quantize_weights(model_dir, man, out, keep, form):
    """The w4a16 graphs' weights.bin (npu/quant.py): LPBQ int4 projections and lm_head, fp32 norms. The
    projections in `keep` (names like l1.wdown) stay fp16: their activations' range is too wide for uint16."""
    mm = np.memmap(model_dir / "weights.bin", np.uint8, "r")

    def f32(name, shape):
        off, nbytes = man[name]
        return np.frombuffer(mm, np.float16, nbytes // 2, off).reshape(shape).astype(np.float32)

    data = quant.Data(out, f"llama-w4a16 2048 16 32 8 64 8192 128256 form {form} keep "
                      + (",".join(sorted(keep)) or "-"))

    def matrix(name, shape, src=None):
        src = src or name
        if name in keep:
            data.add(name, f32(src, shape).astype(np.float16), f"f16 {name} {src}")
        else:
            data.matrix(name, f32(src, shape), form, src)

    def norm(name):
        data.add(name, f32(name, [D]), f"f32 {name} {name}")

    for l in range(L):
        p = f"l{l}."
        norm(p + "attn_norm")
        matrix(p + "wqkv", [QKV, D])
        matrix(p + "wo", [D, D])
        norm(p + "mlp_norm")
        matrix(p + "wgu", [2 * F, D])
        matrix(p + "wdown", [D, F])
        print(f"  layer {l} quantized", flush=True)
    norm("final_norm")
    for c in range(CHUNKS):
        matrix(f"lm.{c}", [V // CHUNKS, D], f"embed.{c}")
    data.close()


def apply_w4a16_weights(model, qdir):
    """Gives a PyTorch LlamaForCausalLM the w4a16 graphs' dequantized weights (the lm_head untied from the fp16
    embedding, as on the HTP)."""
    import torch

    r = quant.Reader(qdir)
    t = lambda a: torch.from_numpy(np.ascontiguousarray(a))  # noqa: E731

    def matrix(name, out, n):  # int4, or fp16 when kept
        if name in r.man:
            return np.asarray(r.raw(name)).view(np.float16).reshape(out, n).astype(np.float32)
        return r.matrix(name, out, n)

    with torch.no_grad():
        for l, layer in enumerate(model.model.layers):
            p, at, mlp = f"l{l}.", layer.self_attn, layer.mlp
            q, k, v = np.split(matrix(p + "wqkv", QKV, D), [H * HD, (H + KVH) * HD])
            at.q_proj.weight.data, at.k_proj.weight.data, at.v_proj.weight.data = t(q), t(k), t(v)
            at.o_proj.weight.data = t(matrix(p + "wo", D, D))
            gate, up = np.split(matrix(p + "wgu", 2 * F, D), 2)
            mlp.gate_proj.weight.data, mlp.up_proj.weight.data = t(gate), t(up)
            mlp.down_proj.weight.data = t(matrix(p + "wdown", D, F))
        head = np.concatenate([r.matrix(f"lm.{c}", V // CHUNKS, D) for c in range(CHUNKS)])
        model.lm_head.weight = torch.nn.Parameter(t(head), requires_grad=False)
    return model


def calibrate(hf, qdir, prompts, rows):
    """The input and output range of every projection (fused as in the graph: qkv, o, gu, down, head) over the
    prompts, in PyTorch on the model with the w4a16 graphs' weights."""
    import sys

    import torch
    from transformers import AutoTokenizer

    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "llama"))
    import run as llama_run

    model = apply_w4a16_weights(llama_run.load_model(hf), qdir)
    tok = AutoTokenizer.from_pretrained(hf)
    ranges = {}

    def hook(key, inp):
        def f(mod, args, out):
            seen = [(key + ".in", args[0]), (key + ".out", out)][0 if inp else 1:]
            x = args[0]
            if x.shape[-1] > quant.KMAX:  # form "fc": the products of the input's chunks of KMAX
                for j in range(x.shape[-1] // quant.KMAX):
                    cols = slice(j * quant.KMAX, (j + 1) * quant.KMAX)
                    seen.append((f"{key}.k{j}.out", x[..., cols] @ mod.weight[:, cols].T))
            for k, t in seen:
                lo, hi = float(t.min()), float(t.max())
                old = ranges.get(k, (lo, hi))
                ranges[k] = (min(lo, old[0]), max(hi, old[1]))
        return f

    for l, layer in enumerate(model.model.layers):
        at, mlp, p = layer.self_attn, layer.mlp, f"l{l}."
        for mod, key, inp in ((at.q_proj, "qkv", True), (at.k_proj, "qkv", False), (at.v_proj, "qkv", False),
                              (at.o_proj, "o", True), (mlp.gate_proj, "gu", True), (mlp.up_proj, "gu", False),
                              (mlp.down_proj, "down", True)):
            mod.register_forward_hook(hook(p + key, inp))
    model.lm_head.register_forward_hook(hook("head", True))
    texts = [t.strip() for t in pathlib.Path(prompts).read_text().split("\n---\n")]
    with torch.no_grad():  # each prompt, then all of them in one message (positions up to `rows`)
        for i, text in enumerate(texts + ["\n\n".join(texts)]):
            ids = tok.apply_chat_template([{"role": "user", "content": text}], add_generation_prompt=True)
            ids = list(ids["input_ids"] if hasattr(ids, "keys") else ids)[:rows]
            model(torch.tensor([ids]))
            print(f"  calibration prompt {i}: {len(ids)} tokens", flush=True)
    return ranges


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", type=pathlib.Path, default=pathlib.Path("build/llama/model"),
                    help="llama/run.py's fp16 export (manifest.txt, weights.bin)")
    ap.add_argument("--out", type=pathlib.Path, help="default build/npu/graphs (graphs-w4a16 with --quant w4a16)")
    ap.add_argument("--rows", type=int, default=448, help="prompt rows a prefill runs (the prompt is padded)")
    ap.add_argument("--parts", type=int, default=4, help="graphs, each a contiguous range of layers")
    ap.add_argument("--fp32", action="store_true", help="fp32 math, for checking on the Mac's CPU")
    ap.add_argument("--leaf-kv", action="store_true",
                    help="K/V outputs through a Reshape of their own ([8, rows * 64]), not tensors the graph reads")
    ap.add_argument("--kv-slots", type=int, default=512,
                    help="pad the K/V outputs to [8, kv_slots, 64], the decode cache's layout (npu_decode binds its "
                         "cache as the output); 0: [8, rows, 64]")
    ap.add_argument("--quant", choices=["fp16", "w4a16"], default="fp16",
                    help="w4a16: LPBQ int4 weights, uint16 activations around every projection (npu/quant.py)")
    ap.add_argument("--hf", help="Llama-3.2-1B-Instruct snapshot, for the w4a16 calibration")
    ap.add_argument("--calib", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parent / "calib.txt",
                    help="calibration prompts, separated by --- lines (not the test prompt)")
    ap.add_argument("--form", choices=["matmul", "fc", "pc8", "pc4"], default="matmul",
                    help="the quantized weights: LPBQ int4 (blocks of 64) as MatMul or FullyConnected (Gemm, inputs "
                         "over 2048 split; QNN 2.42 builds it only for 2048 x 2048), or per-channel int8 (pc8, "
                         "w8a16) or int4 (pc4) as FullyConnected")
    ap.add_argument("--keep", default="l1.wdown",
                    help="w4a16: projections left in fp16 (comma-separated, - for none): layer 1's down projection "
                         "reads the massive activation (-1093), too wide a range for uint16")
    a = ap.parse_args()
    man = manifest(a.model)
    w4 = a.quant == "w4a16"
    a.out = a.out or pathlib.Path("build/npu/graphs-w4a16" if w4 else "build/npu/graphs")
    a.out.mkdir(parents=True, exist_ok=True)
    qman = calib = None
    if w4:
        keep = set() if a.keep in ("", "-") else set(a.keep.split(","))
        have = quant.read_manifest(a.out)[0].split() if (a.out / "manifest.txt").exists() else []
        if have[-4:] != ["form", a.form, "keep", ",".join(sorted(keep)) or "-"]:
            print(f"quantizing the weights (LPBQ int4, blocks of {quant.BLOCK}, form {a.form}; fp16: {sorted(keep)}) "
                  f"-> {a.out}/weights.bin", flush=True)
            quantize_weights(a.model, man, a.out, keep, a.form)
            (a.out / "calib.json").unlink(missing_ok=True)
        qman = quant.read_manifest(a.out)[1]
        if not (a.out / "calib.json").exists():
            if not a.hf:
                raise SystemExit("--hf <snapshot> needed to calibrate the activations")
            quant.save_calib(a.out / "calib.json", calibrate(a.hf, a.out, a.calib, a.rows))
        calib = quant.load_calib(a.out / "calib.json")
    else:
        link = a.out / "weights.bin"  # a hard link: ONNX Runtime refuses external data reached through a symlink
        if link.is_symlink() or (link.exists() and not link.samefile(a.model / "weights.bin")):
            link.unlink()
        if not link.exists():
            os.link(a.model / "weights.bin", link)
    bounds = [round(i * L / a.parts) for i in range(a.parts + 1)]
    for i in range(a.parts):
        m = part(a.model, man, bounds[i], bounds[i + 1], a.rows, i == a.parts - 1, a.fp32, a.leaf_kv, a.kv_slots,
                 qman, calib, a.form)
        onnx.save(m, a.out / f"part{i}.onnx")
        print(f"part{i}.onnx: layers {bounds[i]} .. {bounds[i + 1] - 1}, {len(m.graph.node)} nodes, "
              f"{(a.out / f'part{i}.onnx').stat().st_size / 1e3:.0f} KB")
    tag = " w4a16\n" if w4 else " fp32\n" if a.fp32 else "\n"
    (a.out / "npu.txt").write_text(f"llama-prefill rows {a.rows} parts {a.parts} layers " + " ".join(map(str, bounds))
                                   + tag)


if __name__ == "__main__":
    main()
