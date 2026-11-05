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
"""

import argparse
import os
import pathlib

import numpy as np
import onnx
from onnx import TensorProto, helper

D, L, H, KVH, HD, F, V, CHUNKS = 2048, 16, 32, 8, 64, 8192, 128256, 4
QKV = (H + 2 * KVH) * HD
EPS = 1e-5
OPSET = 23  # RMSNormalization


def manifest(model_dir):
    lines = (model_dir / "manifest.txt").read_text().splitlines()
    assert lines[0].split()[:8] == ["llama", "2048", "16", "32", "8", "64", "8192", "128256"], lines[0]
    return {f[0]: (int(f[1]), int(f[2])) for f in (line.split() for line in lines[1:]) if len(f) == 3}


class Graph:
    def __init__(self, man, fp32):
        self.man, self.fp32 = man, fp32
        self.f = TensorProto.FLOAT if fp32 else TensorProto.FLOAT16
        self.np = np.float32 if fp32 else np.float16
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
    norm_a = g.weight(p + "attn_norm", [D])
    xn = g.op("RMSNormalization", x, norm_a, axis=-1, epsilon=EPS)
    qkv = g.op("Gemm", xn, g.weight(p + "wqkv", [QKV, D]), transB=1)
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
    elif g.kv_slots > rows:  # outputs [8, kv_slots, 64]: the decode cache itself can be the output buffer
        pads = g.const("pads_kv", np.array([0, 0, 0, 0, g.kv_slots - rows, 0], np.int64))
        g.output(f"k{l}", g.op("Pad", k, pads))
        g.output(f"v{l}", g.op("Pad", v, pads))
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
    x = g.op("Add", x, g.op("Gemm", o, g.weight(p + "wo", [D, D]), transB=1))
    xn = g.op("RMSNormalization", x, g.weight(p + "mlp_norm", [D]), axis=-1, epsilon=EPS)
    gu = g.op("Gemm", xn, g.weight(p + "wgu", [2 * F, D]), transB=1)
    gate, up = g.ops("Split", [gu, g.const("split_gu", np.array([F, F], np.int64))], 2, axis=1)
    act = g.op("Mul", g.op("Mul", gate, g.op("Sigmoid", gate)), up)
    return g.op("Add", x, g.op("Gemm", act, g.weight(p + "wdown", [D, F]), transB=1))


def part(model_dir, man, first, last, rows, head, fp32, leaf_kv, kv_slots=0):
    g = Graph(man, fp32)
    g.leaf_kv = leaf_kv
    g.kv_slots = kv_slots
    cos, sin = rope_tables(model_dir, man, rows)
    cos, sin = g.const("rope_cos", cos.astype(g.np)), g.const("rope_sin", sin.astype(g.np))
    mask = np.where(np.tril(np.ones((rows, rows), bool)), 0, -30000).astype(g.np)  # [rows, rows], tiled 4 times
    mask = g.const("mask", np.tile(mask, (H // KVH, 1))[None])  # [1, 4 rows, rows]
    scale = g.const("scale", np.array(0.125, g.np))
    inputs = [helper.make_tensor_value_info("x", g.f, [rows, D])]
    x = "x"
    outputs = []
    for l in range(first, last):
        x = layer(g, l, x, rows, cos, sin, mask, scale)
        kv_shape = [KVH, rows * HD] if leaf_kv else [KVH, max(rows, kv_slots), HD]
        outputs += [helper.make_tensor_value_info(f"{kv}{l}", g.f, kv_shape) for kv in "kv"]
    if head:
        inputs.append(helper.make_tensor_value_info("last", TensorProto.INT32, [1]))
        xl = g.op("RMSNormalization", g.op("Gather", x, "last", axis=0), g.weight("final_norm", [D]), axis=-1,
                  epsilon=EPS)
        chunks = [g.op("Gemm", xl, g.weight(f"embed.{c}", [V // CHUNKS, D]), transB=1) for c in range(CHUNKS)]
        g.output("logits", g.op("Concat", *chunks, axis=1))
        outputs.append(helper.make_tensor_value_info("logits", g.f, [1, V]))
    else:
        g.output("x_out", x)
        outputs.append(helper.make_tensor_value_info("x_out", g.f, [rows, D]))
    graph = helper.make_graph(g.nodes, f"llama_prefill_l{first}_{last}", inputs, outputs, g.inits)
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", OPSET)], producer_name="mojo-adreno/npu")
    model.ir_version = 10
    return model


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", type=pathlib.Path, default=pathlib.Path("build/llama/model"),
                    help="llama/run.py's fp16 export (manifest.txt, weights.bin)")
    ap.add_argument("--out", type=pathlib.Path, default=pathlib.Path("build/npu/graphs"))
    ap.add_argument("--rows", type=int, default=448, help="prompt rows a prefill runs (the prompt is padded)")
    ap.add_argument("--parts", type=int, default=4, help="graphs, each a contiguous range of layers")
    ap.add_argument("--fp32", action="store_true", help="fp32 math, for checking on the Mac's CPU")
    ap.add_argument("--kv-slots", type=int, default=512,
                    help="pad the K/V outputs to [8, kv_slots, 64], the decode cache's layout (npu_decode binds its "
                         "cache as the output); 0: [8, rows, 64]")
    ap.add_argument("--leaf-kv", action="store_true",
                    help="K/V outputs through a Reshape of their own ([8, rows * 64]), not tensors the graph reads")
    a = ap.parse_args()
    man = manifest(a.model)
    a.out.mkdir(parents=True, exist_ok=True)
    link = a.out / "weights.bin"  # a hard link: ONNX Runtime refuses external data reached through a symlink
    if link.is_symlink() or (link.exists() and not link.samefile(a.model / "weights.bin")):
        link.unlink()
    if not link.exists():
        os.link(a.model / "weights.bin", link)
    bounds = [round(i * L / a.parts) for i in range(a.parts + 1)]
    for i in range(a.parts):
        m = part(a.model, man, bounds[i], bounds[i + 1], a.rows, i == a.parts - 1, a.fp32, a.leaf_kv, a.kv_slots)
        onnx.save(m, a.out / f"part{i}.onnx")
        print(f"part{i}.onnx: layers {bounds[i]} .. {bounds[i + 1] - 1}, {len(m.graph.node)} nodes, "
              f"{(a.out / f'part{i}.onnx').stat().st_size / 1e3:.0f} KB")
    (a.out / "npu.txt").write_text(f"llama-prefill rows {a.rows} parts {a.parts} layers "
                                   + " ".join(map(str, bounds)) + ("\n" if not a.fp32 else " fp32\n"))


if __name__ == "__main__":
    main()
