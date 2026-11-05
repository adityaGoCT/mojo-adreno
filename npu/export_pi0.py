"""π0's Gemma 2B prefix (lerobot/pi0_base) as fp16 ONNX graphs for the Hexagon NPU, in parts of a few layers each,
run through ONNX Runtime's QNN execution provider by npu/pi0_prefix.cpp. pi0/model.mojo's prefix() and lerobot 0.6.1's
PI0Pytorch compute the same thing on the GPU and in PyTorch.

  PYTHONPATH=build/npu/pydeps python3 npu/export_pi0.py [--checkpoint build/vla/hf/pi0_base/model.safetensors]
      [--out build/npu/pi0] [--rows 832] [--parts 6] [--fp32]

The graphs carry no matrices. Each one points into gemma.bin, an fp16 copy of Gemma's 18 layers that npu/pi0_f16.c
writes from the checkpoint (fp32, but bf16-exact) by recipe.txt; the phone converts its own copy of the checkpoint, so
only the graphs (about 30 KB each) and the recipe cross the cable. The RMSNorm scales (1 + w) are rounded to fp16
in the graphs themselves.

Every part runs `rows` prefix rows at once: the 816 rows of SigLIP's 768 image tokens and the 48 language rows,
zero-padded to `rows`. Inputs and outputs, all fp16:

  x     [rows, 2048]     the residual stream entering the part (part 0: the prefix embeddings)
  cos   [rows, 1, 256]   RoPE's cos and sin at each row's position (cumsum(pad mask) - 1), from the host
  sin   [rows, 1, 256]
  mask  [1, rows]        0 for a valid key row, -30000 for a padded one (bidirectional attention)
  ->    k<l>, v<l> [rows, 256] for each layer l of the part (K after RoPE): the expert's prefix cache
        x_out [rows, 2048] for the next part (not the last part)

The last layer (17) stops after its K and V, as on the GPU: only its K/V projection is computed.

fp16 holds the prefix: on the reference example the residual stream peaks at 3,360 entering layer 17 (and 4,580 after
it, which is not computed), gelu(gate) * up at 2,200, the attention scores at 35. RMSNormalization (QNN's RmsNorm)
squares in fp32, so x * x need not fit fp16. gelu_tanh is written as x * sigmoid(u * (1.5957691 + 0.0713548 u^2)) with
u = clip(x, -10, 10): the same function (0.5 (1 + tanh z) = sigmoid(2 z)), but u^3 does not overflow fp16 when the
gate reaches 43.

--fp32 writes the same graphs computing in fp32 (the fp16 weights cast up), for checking on the Mac's CPU.
"""

import argparse
import json
import pathlib
import struct
import sys

import numpy as np
import onnx
from onnx import TensorProto, helper

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))
from export import Graph  # noqa: E402  npu/export.py's graph builder (Llama's prefill)

D, L, H, HD, F = 2048, 18, 8, 256, 16384
QKV = (H + 2) * HD
EPS = 1e-6
OPSET = 23  # RMSNormalization
GP = "paligemma_with_expert.paligemma.model.language_model.layers."
WEIGHTS = "gemma.bin"
ALIGN = 4096


class Checkpoint:
    """model.safetensors' header: each tensor's dtype, shape and absolute file offset."""

    def __init__(self, path):
        self.path = path
        with open(path, "rb") as f:
            n = struct.unpack("<Q", f.read(8))[0]
            self.header = json.loads(f.read(n))
        self.base = 8 + n

    def offset(self, name):
        e = self.header[name]
        assert e["dtype"] == "F32", (name, e["dtype"])
        return self.base + e["data_offsets"][0], e["shape"]

    def read(self, name):
        off, shape = self.offset(name)
        with open(self.path, "rb") as f:
            f.seek(off)
            return np.frombuffer(f.read(4 * int(np.prod(shape))), np.float32).reshape(shape)


def layout(ck):
    """gemma.bin's tensors: (name, [out, in], [(checkpoint tensor, offset, elements)...]), each fused matrix the
    concatenation of its sources' rows, so one fp16 [out, in] block."""
    out = []
    for l in range(L):
        def add(name, dims, *srcs):
            out.append((f"g{l}.{name}", dims, [f"{GP}{l}.{s}.weight" for s in srcs]))

        if l < L - 1:
            add("qkv", [QKV, D], "self_attn.q_proj", "self_attn.k_proj", "self_attn.v_proj")
            add("o", [D, H * HD], "self_attn.o_proj")
            add("gate", [F, D], "mlp.gate_proj")
            add("up", [F, D], "mlp.up_proj")
            add("down", [D, F], "mlp.down_proj")
        else:  # the last layer: only its K and V
            add("kv", [2 * HD, D], "self_attn.k_proj", "self_attn.v_proj")
    return out


def write_recipe(ck, out):
    """recipe.txt for npu/pi0_f16.c (fp32 checkpoint ranges -> fp16 gemma.bin) and manifest.txt (name, offset,
    bytes in gemma.bin)."""
    recipe, manifest = [], {}
    pos = 0
    for name, dims, srcs in layout(ck):
        start = pos
        for s in srcs:
            off, shape = ck.offset(s)
            n = int(np.prod(shape))
            recipe.append(f"conv {pos} {off} {n}")
            pos += 2 * n
        assert pos - start == 2 * int(np.prod(dims)), name
        manifest[name] = (start, pos - start)
        pos = (pos + ALIGN - 1) // ALIGN * ALIGN
    (out / "recipe.txt").write_text(f"size {pos}\n" + "\n".join(recipe) + "\n")
    (out / "manifest.txt").write_text("pi0-gemma\n" + "".join(f"{k} {o} {n}\n" for k, (o, n) in manifest.items()))
    return manifest, pos


class PGraph(Graph):
    def weight(self, name, dims):
        """The fp16 tensor `name` of gemma.bin, as an external initializer (cast to fp32 with --fp32)."""
        if name in self.weights:
            return self.weights[name]
        off, nbytes = self.man[name]
        assert nbytes == 2 * int(np.prod(dims)), (name, dims, nbytes)
        t = TensorProto(name=name, data_type=TensorProto.FLOAT16, dims=dims, data_location=TensorProto.EXTERNAL)
        for k, v in (("location", WEIGHTS), ("offset", str(off)), ("length", str(nbytes))):
            e = t.external_data.add()
            e.key, e.value = k, v
        self.inits.append(t)
        self.weights[name] = self.op("Cast", name, to=TensorProto.FLOAT) if self.fp32 else name
        return self.weights[name]


def norm_scale(ck, l, which):
    """Gemma's RMSNorm scale (1 + w), in fp32, then the graph's float type."""
    return (1.0 + ck.read(f"{GP}{l}.{which}.weight").astype(np.float32))


def rope(g, t, cos, sin):
    """t * cos + rotate_half(t) * sin over the last axis (256), rotate_half(t) = [-t2, t1]."""
    t1, t2 = g.ops("Split", [t, g.const("split_half", np.array([HD // 2, HD // 2], np.int64))], 2, axis=-1)
    rot = g.op("Concat", g.op("Neg", t2), t1, axis=-1)
    return g.op("Add", g.op("Mul", t, cos), g.op("Mul", rot, sin))


def layer(g, ck, l, x, rows, cos, sin, mask):
    p = f"g{l}."
    shape = lambda name, dims: g.const(name, np.array(dims, np.int64))  # noqa: E731
    xn = g.op("RMSNormalization", x, g.const(p + "in", norm_scale(ck, l, "input_layernorm").astype(g.np)),
              axis=-1, epsilon=EPS)
    if l == L - 1:
        kv = g.op("Gemm", xn, g.weight(p + "kv", [2 * HD, D]), transB=1)
        k, v = g.ops("Split", [kv, g.const("split_kv", np.array([HD, HD], np.int64))], 2, axis=1)
    else:
        qkv = g.op("Gemm", xn, g.weight(p + "qkv", [QKV, D]), transB=1)
        q, k, v = g.ops("Split", [qkv, g.const("split_qkv", np.array([H * HD, HD, HD], np.int64))], 3, axis=1)
    k = g.op("Reshape", rope(g, g.op("Reshape", k, shape("shape_r1", [rows, 1, HD])), cos, sin),
             shape("shape_r", [rows, HD]))
    k = g.output(f"k{l}", k)
    v = g.output(f"v{l}", v)
    if l == L - 1:
        return None
    # multi-query attention: the 8 query heads against the one K/V head, as [8 rows, 256] x [256, rows]
    q = rope(g, g.op("Reshape", q, shape("shape_rh", [rows, H, HD])), cos, sin)
    q = g.op("Reshape", g.op("Transpose", q, perm=[1, 0, 2]), shape("shape_hr", [H * rows, HD]))
    q = g.op("Mul", q, g.const("scale", np.array(HD ** -0.5, g.np)))
    s = g.op("Add", g.op("MatMul", q, g.op("Transpose", k, perm=[1, 0])), mask)  # [8 rows, rows]
    o = g.op("MatMul", g.op("Softmax", s, axis=-1), v)  # [8 rows, 256]
    o = g.op("Reshape", g.op("Transpose", g.op("Reshape", o, shape("shape_h_r", [H, rows, HD])), perm=[1, 0, 2]),
             shape("shape_x", [rows, D]))
    x = g.op("Add", x, g.op("Gemm", o, g.weight(p + "o", [D, H * HD]), transB=1))
    xn = g.op("RMSNormalization", x, g.const(p + "post", norm_scale(ck, l, "post_attention_layernorm").astype(g.np)),
              axis=-1, epsilon=EPS)
    gate = g.op("Gemm", xn, g.weight(p + "gate", [F, D]), transB=1)
    up = g.op("Gemm", xn, g.weight(p + "up", [F, D]), transB=1)
    u = g.op("Clip", gate, g.const("gelu_lo", np.array(-10, g.np)), g.const("gelu_hi", np.array(10, g.np)))
    z = g.op("Mul", u, g.op("Add", g.op("Mul", g.op("Mul", u, u), g.const("gelu_c3", np.array(0.0713548, g.np))),
                            g.const("gelu_c1", np.array(1.5957691, g.np))))
    act = g.op("Mul", g.op("Mul", gate, g.op("Sigmoid", z)), up)
    return g.op("Add", x, g.op("Gemm", act, g.weight(p + "down", [D, F]), transB=1))


def part(ck, man, first, last, rows, fp32):
    g = PGraph(man, fp32)
    inputs = [helper.make_tensor_value_info("x", g.f, [rows, D]),
              helper.make_tensor_value_info("cos", g.f, [rows, 1, HD]),
              helper.make_tensor_value_info("sin", g.f, [rows, 1, HD]),
              helper.make_tensor_value_info("mask", g.f, [1, rows])]
    outputs = []
    x = "x"
    for l in range(first, last):
        x = layer(g, ck, l, x, rows, "cos", "sin", "mask")
        outputs += [helper.make_tensor_value_info(f"{kv}{l}", g.f, [rows, HD]) for kv in "kv"]
    if x is not None:
        g.output("x_out", x)
        outputs.append(helper.make_tensor_value_info("x_out", g.f, [rows, D]))
    graph = helper.make_graph(g.nodes, f"pi0_prefix_l{first}_{last}", inputs, outputs, g.inits)
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", OPSET)], producer_name="mojo-adreno/npu")
    model.ir_version = 10
    return model


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--checkpoint", type=pathlib.Path, default=ROOT / "build/vla/hf/pi0_base/model.safetensors")
    ap.add_argument("--out", type=pathlib.Path, default=ROOT / "build/npu/pi0")
    ap.add_argument("--rows", type=int, default=832, help="prefix rows a part runs (816, zero-padded)")
    ap.add_argument("--parts", type=int, default=6, help="graphs, each a contiguous range of layers")
    ap.add_argument("--fp32", action="store_true", help="fp32 math, for checking on the Mac's CPU")
    a = ap.parse_args()
    assert a.rows >= 816
    ck = Checkpoint(a.checkpoint)
    a.out.mkdir(parents=True, exist_ok=True)
    man, size = write_recipe(ck, a.out)
    print(f"gemma.bin: {size / 1e9:.2f} GB fp16 ({len(man)} tensors); recipe.txt for npu/pi0_f16.c")
    bounds = [round(i * L / a.parts) for i in range(a.parts + 1)]
    for i in range(a.parts):
        m = part(ck, man, bounds[i], bounds[i + 1], a.rows, a.fp32)
        onnx.save(m, a.out / f"part{i}.onnx")
        print(f"part{i}.onnx: layers {bounds[i]} .. {bounds[i + 1] - 1}, {len(m.graph.node)} nodes, "
              f"{(a.out / f'part{i}.onnx').stat().st_size / 1e3:.0f} KB")
    (a.out / "npu.txt").write_text(f"pi0-prefix rows {a.rows} parts {a.parts} layers "
                                   + " ".join(map(str, bounds)) + (" fp32\n" if a.fp32 else "\n"))


if __name__ == "__main__":
    main()
