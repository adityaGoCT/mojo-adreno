"""One Qwen3-30B-A3B layer as an fp16 ONNX graph for the Hexagon NPU (ONNX Runtime's QNN execution provider): a
prefill of T tokens at positions 0 .. T-1, to measure what the NPU does with this mixture of experts.

  PYTHONPATH=build/npu/pydeps python3 qwen3moe/npu/export_layer.py [--layer 0] [--tokens 128 256] [--out build/qwen3moe/npu]

Writes layer<l>.recipe for convert.c (the layer's bf16 weights to fp16 layer<l>.bin, on the laptop) and
layer<l>_t<T>.onnx, whose initializers point into layer<l>.bin. The graph's one input is x [T, 2048] fp16 (the
residual stream entering the layer); its output x_out [T, 2048] the stream leaving it.

  attention   RMSNorm, q/k/v (Gemm), QK norm (RMSNormalization over each head), RoPE (theta 1e7; cos and sin of
              positions 0 .. T-1 are constants), grouped-query attention as [4, 8T, 128] x [4, 128, T] with a causal
              mask, o (Gemm) plus the residual
  experts     RMSNorm, the router (Gemm, 128 logits), TopK(8): a dense [T, 128] weight, softmax over each token's 8
              (Qwen3-MoE's renormalized top 8) and 0 elsewhere. Then all 128 experts for every token, because an HTP
              graph is static and cannot gather a token's experts: gate/up as one Gemm [T, 2048] x [2048, 128 * 1536],
              SiLU, times the routing weight, and down as a batched MatMul [128, T, 768] x [128, 768, 2048] summed
              over the experts. That is 16x the arithmetic the 8 chosen experts need.
"""

import argparse
import json
import pathlib
import sys

import numpy as np
import onnx
from onnx import TensorProto, helper

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE.parent))
import export as qx  # noqa: E402  qwen3moe/export.py: the shards' headers

D, H, KVH, HD, E, TOPK, F = 2048, 32, 4, 128, 128, 8, 768
THETA = 10000000.0


class Lay:
    def __init__(self, index, cache):
        self.where = index["weight_map"]
        self.cache = cache
        self.recipe, self.man, self.pos, self.shard = [], {}, 0, None

    def src(self, tensor):
        shard = self.where[tensor]
        h = qx.header(shard, self.cache)
        if shard != self.shard:
            self.recipe.append(f"src {shard}")
            self.shard = shard
        e = h[tensor]
        return e["shape"], h["__base__"] + e["data_offsets"][0]

    def put(self, name, tensors, transpose=False):
        """bf16 tensors, concatenated (each transposed with `transpose`), as one fp16 block."""
        start = self.pos
        for t in tensors:
            shape, off = self.src(t)
            n = int(np.prod(shape))
            if transpose:
                self.recipe.append(f"f16t {self.pos} {off} {shape[0]} {shape[1]}")
            else:
                self.recipe.append(f"f16 {self.pos} {off} {n}")
            self.pos += 2 * n
        self.man[name] = (start, self.pos - start)
        self.pos = (self.pos + 4095) // 4096 * 4096


class G:
    def __init__(self, man, file):
        self.man, self.file = man, file
        self.nodes, self.inits, self.n = [], [], 0

    def op(self, op, *inputs, **attrs):
        self.n += 1
        out = f"{op.lower()}_{self.n}"
        self.nodes.append(helper.make_node(op, list(inputs), [out], **attrs))
        return out

    def ops(self, op, inputs, k, **attrs):
        self.n += 1
        outs = [f"{op.lower()}_{self.n}_{i}" for i in range(k)]
        self.nodes.append(helper.make_node(op, list(inputs), outs, **attrs))
        return outs

    def const(self, name, a):
        self.inits.append(onnx.numpy_helper.from_array(np.ascontiguousarray(a), name))
        return name

    def w(self, name, dims):
        off, nbytes = self.man[name]
        assert nbytes == 2 * int(np.prod(dims)), (name, dims, nbytes)
        t = TensorProto(name=name, data_type=TensorProto.FLOAT16, dims=dims, data_location=TensorProto.EXTERNAL)
        for k, v in (("location", self.file), ("offset", str(off)), ("length", str(nbytes))):
            e = t.external_data.add()
            e.key, e.value = k, v
        self.inits.append(t)
        return name


def graph(man, file, T):
    g = G(man, file)
    f16 = np.float16
    shape = lambda n, d: g.const(n, np.array(d, np.int64))  # noqa: E731
    inv = (1.0 / THETA ** (np.arange(0, HD, 2, dtype=np.float64) / HD)).astype(np.float32)
    ang = np.arange(T, dtype=np.float32)[:, None] * inv[None]
    cos = g.const("cos", np.concatenate([np.cos(ang), np.cos(ang)], 1)[:, None].astype(f16))
    sin = g.const("sin", np.concatenate([np.sin(ang), np.sin(ang)], 1)[:, None].astype(f16))
    mask = np.where(np.tril(np.ones((T, T), bool)), 0, -30000).astype(f16)
    mask = g.const("mask", np.tile(mask, (H // KVH, 1))[None])  # [1, 8T, T]

    def rope(t):
        a, b = g.ops("Split", [t, shape("half", [HD // 2, HD // 2])], 2, axis=-1)
        return g.op("Add", g.op("Mul", t, cos), g.op("Mul", g.op("Concat", g.op("Neg", b), a, axis=-1), sin))

    x = "x"
    xn = g.op("RMSNormalization", x, g.w("in_norm", [D]), axis=-1, epsilon=1e-6)
    q = g.op("Gemm", xn, g.w("q", [H * HD, D]), transB=1)
    k = g.op("Gemm", xn, g.w("k", [KVH * HD, D]), transB=1)
    v = g.op("Gemm", xn, g.w("v", [KVH * HD, D]), transB=1)
    def head_norm(t, w):
        """RMS norm over each head's 128 as an L2 normalization times sqrt(128) (the 1e-6 epsilon aside): QNN's RmsNorm
        refuses heads of 128 on the HTP (error 3110; the norms over 2048 pass), and squares written out in fp16
        underflow for small values or overflow for large ones."""
        return g.op("Mul", g.op("LpNormalization", t, axis=-1, p=2),
                    g.op("Mul", w, g.const("sqrt128", np.array(HD ** 0.5, f16))))

    q = rope(head_norm(g.op("Reshape", q, shape("s_q", [T, H, HD])), g.w("q_norm", [HD])))
    k = rope(head_norm(g.op("Reshape", k, shape("s_k", [T, KVH, HD])), g.w("k_norm", [HD])))
    q = g.op("Reshape", g.op("Transpose", q, perm=[1, 0, 2]), shape("s_qg", [KVH, (H // KVH) * T, HD]))
    k = g.op("Transpose", k, perm=[1, 2, 0])  # [4, 128, T]
    v = g.op("Transpose", g.op("Reshape", v, shape("s_v", [T, KVH, HD])), perm=[1, 0, 2])  # [4, T, 128]
    s = g.op("Add", g.op("MatMul", g.op("Mul", q, g.const("scale", np.array(HD ** -0.5, f16))), k), mask)
    o = g.op("MatMul", g.op("Softmax", s, axis=-1), v)  # [4, 8T, 128]
    o = g.op("Reshape", g.op("Transpose", g.op("Reshape", o, shape("s_o", [H, T, HD])), perm=[1, 0, 2]),
             shape("s_x", [T, H * HD]))
    x = g.op("Add", x, g.op("Gemm", o, g.w("o", [D, H * HD]), transB=1))
    xn = g.op("RMSNormalization", x, g.w("post_norm", [D]), axis=-1, epsilon=1e-6)
    r = g.op("Gemm", xn, g.w("router", [E, D]), transB=1)  # [T, 128]
    top, _ = g.ops("TopK", [r, g.const("k8", np.array([TOPK], np.int64))], 2, axis=-1)
    hi = g.op("Slice", top, g.const("s0", np.array([0], np.int64)), g.const("s1", np.array([1], np.int64)),
              g.const("ax", np.array([1], np.int64)))
    lo = g.op("Slice", top, g.const("s7", np.array([TOPK - 1], np.int64)), g.const("s8", np.array([TOPK], np.int64)),
              "ax")
    chosen = g.op("Cast", g.op("GreaterOrEqual", r, lo), to=TensorProto.FLOAT16)
    ew = g.op("Mul", g.op("Exp", g.op("Sub", r, hi)), chosen)
    wts = g.op("Div", ew, g.op("ReduceSum", ew, g.const("axl", np.array([-1], np.int64)), keepdims=1))  # [T, 128]
    gu = g.op("Reshape", g.op("Gemm", xn, g.w("gate_up", [E * 2 * F, D]), transB=1), shape("s_gu", [T, E, 2 * F]))
    gate, up = g.ops("Split", [gu, shape("s_half", [F, F])], 2, axis=-1)
    act = g.op("Mul", g.op("Mul", g.op("Mul", gate, g.op("Sigmoid", gate)), up),
               g.op("Unsqueeze", wts, g.const("axu", np.array([-1], np.int64))))  # [T, 128, 768]
    d = g.op("MatMul", g.op("Transpose", act, perm=[1, 0, 2]), g.w("down_t", [E, F, D]))  # [128, T, 2048]
    d = g.op("ReduceSum", d, g.const("ax0", np.array([0], np.int64)), keepdims=0)
    x = g.op("Add", x, d)
    for node in g.nodes:  # the last value is the output, named in place
        for i, val in enumerate(node.output):
            if val == x:
                node.output[i] = "x_out"
    gr = helper.make_graph(g.nodes, f"qwen3moe_layer_t{T}", [helper.make_tensor_value_info("x", TensorProto.FLOAT16,
                                                                                          [T, D])],
                           [helper.make_tensor_value_info("x_out", TensorProto.FLOAT16, [T, D])], g.inits)
    m = helper.make_model(gr, opset_imports=[helper.make_opsetid("", 23)], producer_name="mojo-adreno/qwen3moe")
    m.ir_version = 10
    return m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--layer", type=int, default=0)
    ap.add_argument("--tokens", type=int, nargs="+", default=[128, 256])
    ap.add_argument("--out", type=pathlib.Path, default=ROOT / "build/qwen3moe/npu")
    a = ap.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    cache = ROOT / "build/qwen3moe/headers"
    lay = Lay(json.loads((ROOT / "build/qwen3moe/model.safetensors.index.json").read_text()), cache)
    p = f"model.layers.{a.layer}."
    lay.put("in_norm", [p + "input_layernorm.weight"])
    lay.put("post_norm", [p + "post_attention_layernorm.weight"])
    lay.put("q_norm", [p + "self_attn.q_norm.weight"])
    lay.put("k_norm", [p + "self_attn.k_norm.weight"])
    for w in "qkvo":
        lay.put(w, [p + f"self_attn.{w}_proj.weight"])
    lay.put("router", [p + "mlp.gate.weight"])
    lay.put("gate_up", [p + f"mlp.experts.{e}.{w}_proj.weight" for e in range(E) for w in ("gate", "up")])
    lay.put("down_t", [p + f"mlp.experts.{e}.down_proj.weight" for e in range(E)], transpose=True)
    file = f"layer{a.layer}.bin"
    (a.out / f"layer{a.layer}.recipe").write_text(f"size {lay.pos}\n" + "\n".join(lay.recipe) + "\n")
    print(f"{file}: {lay.pos / 1e9:.2f} GB fp16")
    for T in a.tokens:
        m = graph(lay.man, file, T)
        onnx.save(m, a.out / f"layer{a.layer}_t{T}.onnx")
        print(f"layer{a.layer}_t{T}.onnx: {len(m.graph.node)} nodes")


if __name__ == "__main__":
    main()
