"""Llama 3.2 1B's decode step as ONNX graphs for the Hexagon NPU: one token at a time against a KV cache, for an
all-NPU run (npu/npu_decode.cpp). Like npu/export.py's prefill graphs, the initializers point into weights.bin.

  PYTHONPATH=build/npu/pydeps $PY npu/export_decode.py --model build/llama/model --out build/npu/decode

Each part takes a contiguous range of layers, one token at position p:

  inputs:  x [1, 2048] fp16 (the token's embedding row, or the previous part's x_out)
           cos, sin [1, 1, 64] (RoPE at position p), mask [1, 1, CTX + 1] (0 for cache slots < p and for the
           new token at slot CTX, -30000 for the rest)
           pk<l>, pv<l> [8, CTX, 64] fp16 for each of its layers: the cache, positions 0 .. p-1 valid
  outputs: k<l>, v<l> [8, 1, 64]: the new token's K (RoPE'd) and V, which the host writes into slot p
           x_out [1, 2048], or for the last part logits [1, 128256]

Attention runs over the cache and the new token, concatenated (CTX + 1 keys). The cache keeps the prefill graphs'
layout ([kv head][position][64]), so the prefill's K/V go straight in.
"""

import argparse
import os
import pathlib

import numpy as np
import onnx
from onnx import TensorProto, helper

from export import CHUNKS, D, EPS, F, H, HD, KVH, L, OPSET, QKV, V, Graph, manifest

CTX = 512  # cache slots: llama/model.mojo's MAXPOS


def decode_layer(g, l, x, cos, sin, mask, scale):
    p = f"l{l}."
    xn = g.op("RMSNormalization", x, g.weight(p + "attn_norm", [D]), axis=-1, epsilon=EPS)
    qkv = g.op("Gemm", xn, g.weight(p + "wqkv", [QKV, D]), transB=1)
    q, k, v = g.ops("Split", [qkv, g.const("split_qkv", np.array([H * HD, KVH * HD, KVH * HD], np.int64))], 3, axis=1)

    def heads(t, n):  # [1, n*64] -> [n, 1, 64]: one row, so a reshape
        return g.op("Reshape", t, g.const(f"shape_{n}", np.array([n, 1, HD], np.int64)))

    def rope(t):
        t1, t2 = g.ops("Split", [t, g.const("split_half", np.array([HD // 2, HD // 2], np.int64))], 2, axis=-1)
        rot = g.op("Concat", g.op("Neg", t2), t1, axis=-1)
        return g.op("Add", g.op("Mul", t, cos), g.op("Mul", rot, sin))

    q = rope(heads(q, H))
    k = g.output(f"k{l}", rope(heads(k, KVH)))
    v = g.output(f"v{l}", heads(v, KVH))
    keys = g.op("Concat", f"pk{l}", k, axis=1)  # [8, CTX + 1, 64]
    values = g.op("Concat", f"pv{l}", v, axis=1)
    qg = g.op("Mul", g.op("Reshape", q, g.const("shape_qg", np.array([KVH, H // KVH, HD], np.int64))), scale)
    s = g.op("Add", g.op("MatMul", qg, g.op("Transpose", keys, perm=[0, 2, 1])), mask)  # [8, 4, CTX + 1]
    o = g.op("MatMul", g.op("Softmax", s, axis=-1), values)  # [8, 4, 64]
    o = g.op("Reshape", o, g.const("shape_x", np.array([1, D], np.int64)))
    x = g.op("Add", x, g.op("Gemm", o, g.weight(p + "wo", [D, D]), transB=1))
    xn = g.op("RMSNormalization", x, g.weight(p + "mlp_norm", [D]), axis=-1, epsilon=EPS)
    gu = g.op("Gemm", xn, g.weight(p + "wgu", [2 * F, D]), transB=1)
    gate, up = g.ops("Split", [gu, g.const("split_gu", np.array([F, F], np.int64))], 2, axis=1)
    act = g.op("Mul", g.op("Mul", gate, g.op("Sigmoid", gate)), up)
    return g.op("Add", x, g.op("Gemm", act, g.weight(p + "wdown", [D, F]), transB=1))


def part(man, first, last, head, fp32):
    g = Graph(man, fp32)
    f = g.f
    scale = g.const("scale", np.array(0.125, g.np))
    inputs = [helper.make_tensor_value_info(n, f, s) for n, s in
              (("x", [1, D]), ("cos", [1, 1, HD]), ("sin", [1, 1, HD]), ("mask", [1, 1, CTX + 1]))]
    outputs = []
    x = "x"
    for l in range(first, last):
        inputs += [helper.make_tensor_value_info(f"p{kv}{l}", f, [KVH, CTX, HD]) for kv in "kv"]
        x = decode_layer(g, l, x, "cos", "sin", "mask", scale)
        outputs += [helper.make_tensor_value_info(f"{kv}{l}", f, [KVH, 1, HD]) for kv in "kv"]
    if head:
        xn = g.op("RMSNormalization", x, g.weight("final_norm", [D]), axis=-1, epsilon=EPS)
        chunks = [g.op("Gemm", xn, g.weight(f"embed.{c}", [V // CHUNKS, D]), transB=1) for c in range(CHUNKS)]
        g.output("logits", g.op("Concat", *chunks, axis=1))
        outputs.append(helper.make_tensor_value_info("logits", f, [1, V]))
    else:
        g.output("x_out", x)
        outputs.append(helper.make_tensor_value_info("x_out", f, [1, D]))
    graph = helper.make_graph(g.nodes, f"llama_decode_l{first}_{last}", inputs, outputs, g.inits)
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", OPSET)], producer_name="mojo-adreno/npu")
    model.ir_version = 10
    return model


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", type=pathlib.Path, default=pathlib.Path("build/llama/model"))
    ap.add_argument("--out", type=pathlib.Path, default=pathlib.Path("build/npu/decode"))
    ap.add_argument("--parts", type=int, default=4)
    ap.add_argument("--fp32", action="store_true", help="fp32 math, for checking on the Mac's CPU")
    a = ap.parse_args()
    man = manifest(a.model)
    a.out.mkdir(parents=True, exist_ok=True)
    link = a.out / "weights.bin"  # a hard link on the Mac; on the phone the graphs sit next to weights.bin
    if link.is_symlink() or (link.exists() and not link.samefile(a.model / "weights.bin")):
        link.unlink()
    if not link.exists():
        os.link(a.model / "weights.bin", link)
    bounds = [round(i * L / a.parts) for i in range(a.parts + 1)]
    for i in range(a.parts):
        m = part(man, bounds[i], bounds[i + 1], i == a.parts - 1, a.fp32)
        onnx.save(m, a.out / f"decode{i}.onnx")
        print(f"decode{i}.onnx: layers {bounds[i]} .. {bounds[i + 1] - 1}, {len(m.graph.node)} nodes, "
              f"{(a.out / f'decode{i}.onnx').stat().st_size / 1e3:.0f} KB")
    (a.out / "decode.txt").write_text(f"llama-decode ctx {CTX} parts {a.parts} layers "
                                      + " ".join(map(str, bounds)) + ("\n" if not a.fp32 else " fp32\n"))


if __name__ == "__main__":
    main()
