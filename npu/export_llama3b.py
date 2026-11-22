"""Llama 3.2 3B's prompt prefill on the Hexagon NPU (HTP) as ONNX graphs for ONNX Runtime's QNN execution provider,
run by npu/graph.cpp (graph_tool chain). Written for the Adreno 850 phone (SM8975, Hexagon V85) to compare its NPU
with AdrenoBLAS's prefill on its GPU (../ablas/llama3b).

The weights are the F16 GGUF's own bytes (llama.cpp's convert_hf_to_gguf --outtype f16): every initializer is
external data at the tensor's offset in the GGUF, which sits next to the graphs on the phone. So nothing but the
graphs (a few MB) is pushed. The graphs are fp16 throughout, as npu/export.py's 1B graphs; only the inputs and
outputs are fp32 (Casts at the edges), for graph.cpp. (A first version in fp32, run in fp16 by
enable_htp_fp16_precision, with RMSNorm written out and llama.cpp's interleaved RoPE, took 112 ms for 4 layers.)

Weight rearrangements are constant subgraphs, which ONNX Runtime folds once at load:
- llama.cpp stores q_proj / k_proj rows permuted for its interleaved RoPE (within a head, GGUF row 2i + t is HF row
  t * 64 + i): a Gather puts them back in HF's order, so RoPE is rotate_half on two 64-wide halves;
- q, k, v are concatenated into one [5120, 3072] projection, gate and up into one [16384, 3072].

Graphs (graph.cpp feeds fp32 / int32 inputs and reads fp32 outputs):
  p<i>.onnx    layers of part i over R rows (positions 0 .. R - 1; a shorter prompt is padded at the end and the
               causal mask keeps the padding out of real rows). In: x [R, 3072]. Out: x_out [R, 3072].
  head.onnx    the final RMSNorm and the tied LM head in 4 chunks. In: x [R, 3072], sel [1] int32 (the last real
               row). Out: hidden [R, 3072] (the normed rows, for checking against ../ablas/llama3b/ref.py), logits
               [1, V] of row sel.
No K/V outputs: the prefill is timed like ../ablas/llama3b's, which keeps no KV cache either.

Measured 2026-11-22 on a QDC SM8975 QRD (Hexagon V85, QNN 2.52, ONNX Runtime 1.29), 512 tokens, phone started at
40 C: 299-305 ms (1,710 tok/s), 40-42 ms a part of 4 layers (~10 TFLOP/s, the HTP's fp16 matmul rate) and 14-17 ms
for the head; logits cos 1.00000 and KL 0.0000 against ../ablas/llama3b/ref.py's fp32 reference. Compiling takes
~9 min a part on the phone (run_llama3b.sh compile).

  PYTHONPATH=build/npu/pydeps:~/runix/llama.cpp/gguf-py .venv-iree312/bin/python npu/export_llama3b.py \\
      --gguf ~/runix/llama.cpp-gguf/Llama-3.2-3B-Instruct-F16.gguf --out build/npu/llama3b
also writes x.bin (the embedding rows of ../ablas/llama3b/ref/tokens.bin's first R tokens) and sel.bin.
"""

import argparse
import math
import pathlib

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
D, L, H, KVH, HD, F, V = 3072, 28, 24, 8, 128, 8192, 128256
EPS, NEG = 1e-5, -30000.0


class Graph:
    """A small ONNX builder (as lfm2/export_npu.py's): fp32 values, fp16 weights from the GGUF as external data."""

    def __init__(self, man, gguf_name):
        from onnx import TensorProto
        self.T, self.man, self.gguf_name = TensorProto, man, gguf_name
        self.nodes, self.inits, self.inputs, self.outputs, self.names, self.n = [], [], [], [], set(), 0

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

    def f(self, v):  # an fp16 scalar constant
        return self.const(f"c_{v!r}", np.array(v, np.float16))

    def i64(self, name, v):
        return self.const("c_" + name, np.array(v, np.int64))

    def external(self, name, rows=None):
        """The GGUF tensor `name` (rows a .. b of it with rows=(a, b)), as an initializer of its own type."""
        off, nbytes, shape, ggml_type = self.man[name]
        key = name if rows is None else f"{name}.{rows[0]}"
        if key in self.names:
            return key
        dtype = {0: self.T.FLOAT, 1: self.T.FLOAT16}[ggml_type]
        esize = 4 if ggml_type == 0 else 2
        if rows is not None:
            a, b = rows
            off, nbytes, shape = off + a * shape[1] * esize, (b - a) * shape[1] * esize, [b - a, shape[1]]
        from onnx import TensorProto
        t = TensorProto(name=key, data_type=dtype, dims=shape, data_location=TensorProto.EXTERNAL)
        for k, v in (("location", self.gguf_name), ("offset", str(off)), ("length", str(nbytes))):
            e = t.external_data.add()
            e.key, e.value = k, v
        self.inits.append(t)
        self.names.add(key)
        return key

    def input(self, name, dims, dtype=None):
        from onnx import helper
        self.inputs.append(helper.make_tensor_value_info(name, dtype or self.T.FLOAT, dims))
        return name

    def output(self, name, value, dims):
        """`value` (fp16) as the fp32 graph output `name`: the Cast is named so, as QNN takes no Identity node."""
        from onnx import helper
        value = self.op("Cast", value, to=self.T.FLOAT)
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
        m = helper.make_model(g, opset_imports=[helper.make_opsetid("", 23)], producer_name="npu/export_llama3b.py")
        m.ir_version = 10
        onnx.save(m, str(path))

    # building blocks

    def w16(self, name):
        """A GGUF tensor as fp16 (norm weights are fp32 there: Cast, folded at load)."""
        t = self.external(name)
        return t if self.man[name][3] == 1 else self.op("Cast", t, to=self.T.FLOAT16)

    def rows_hf(self, name, heads):
        """q_proj / k_proj rows back in HF's order (a Gather of the GGUF's rows, folded at load)."""
        j = np.arange(heads * HD)
        h, d = j // HD, j % HD
        perm = h * HD + 2 * (d % (HD // 2)) + d // (HD // 2)
        return self.op("Gather", self.w16(name), self.const(f"perm_{heads}", perm.astype(np.int64)), axis=0)

    def gemm(self, x, w):
        return self.op("Gemm", x, w, transB=1)

    def rms(self, x, wname):
        return self.op("RMSNormalization", x, self.w16(wname), axis=-1, epsilon=EPS)

    def rope(self, t, cos, sin):
        """t * cos + rotate_half(t) * sin, rotate_half(t) = [-t2, t1] over the head dim (cos / sin [R, 128])."""
        t1, t2 = self.op("Split", t, self.i64("split_half", [HD // 2, HD // 2]), axis=-1, n_out=2)
        return self.op("Add", self.op("Mul", t, cos), self.op("Mul", self.op("Concat", self.op("Neg", t2), t1, axis=-1), sin))


def manifest(gguf_path):
    """GGUF tensors: name -> (file offset, bytes, [rows, cols] row-major, ggml type 0 f32 / 1 f16)."""
    import gguf
    r = gguf.GGUFReader(str(gguf_path))
    out = {}
    for t in r.tensors:
        shape = [int(d) for d in reversed(t.shape.tolist())]  # ggml ne0 is the contiguous dimension
        out[t.name] = (int(t.data_offset), int(t.n_bytes), shape if len(shape) == 2 else [shape[0]], int(t.tensor_type))
    return out


def rope_table(R):
    """cos / sin [R, 128] of position * inv_freq, each half the same (Llama 3's scaled frequencies, as
    ../ablas/llama3b/export.py stored them: its weights' inv_freq)."""
    wdir = ROOT / "ablas/llama3b/weights"
    for line in (wdir / "llama3b_f16.idx").read_text().splitlines():
        name, off, nbytes = line.split()
        if name == "inv_freq":
            inv = np.fromfile(wdir / "llama3b_f16.bin", np.float32, count=int(nbytes) // 4, offset=int(off))
    ang = np.arange(R, dtype=np.float32)[:, None] * inv[None, :]
    ang = np.concatenate([ang, ang], axis=1)
    return np.cos(ang).astype(np.float16), np.sin(ang).astype(np.float16)


def part(man, gguf_name, first, last, R):
    g = Graph(man, gguf_name)
    x = g.op("Cast", g.input("x", [R, D]), to=g.T.FLOAT16)
    c, s = rope_table(R)
    cos, sin = g.const("cos", c), g.const("sin", s)
    grp = H // KVH
    mask = np.where(np.tril(np.ones((R, R), bool)), 0, NEG).astype(np.float16)
    mask = g.const("mask", np.tile(mask, (grp, 1))[None])  # [1, 3 R, R]: the 3 query heads of a KV head stacked
    scale = g.f(1.0 / math.sqrt(HD))

    def heads(t, n):  # [R, n * 128] -> [n, R, 128]
        return g.op("Transpose", g.op("Reshape", t, g.i64(f"shape_h{n}", [R, n, HD])), perm=[1, 0, 2])

    for l in range(first, last):
        n = f"blk.{l}."
        wqkv = g.op("Concat", g.rows_hf(n + "attn_q.weight", H), g.rows_hf(n + "attn_k.weight", KVH),
                    g.w16(n + "attn_v.weight"), axis=0)
        qkv = g.gemm(g.rms(x, n + "attn_norm.weight"), wqkv)
        q, k, v = g.op("Split", qkv, g.i64("split_qkv", [H * HD, KVH * HD, KVH * HD]), axis=1, n_out=3)
        q, k, v = g.rope(heads(q, H), cos, sin), g.rope(heads(k, KVH), cos, sin), heads(v, KVH)
        # grouped-query attention: query heads 3j .. 3j + 2 read KV head j, so [24, R, 128] -> [8, 3 R, 128]
        qg = g.op("Mul", g.op("Reshape", q, g.i64("shape_qg", [KVH, grp * R, HD])), scale)
        sc = g.op("Add", g.op("MatMul", qg, g.op("Transpose", k, perm=[0, 2, 1])), mask)
        o = g.op("MatMul", g.op("Softmax", sc, axis=-1), v)
        o = g.op("Reshape", g.op("Transpose", g.op("Reshape", o, g.i64("shape_o", [H, R, HD])), perm=[1, 0, 2]),
                 g.i64("shape_x", [R, D]))
        x = g.op("Add", x, g.gemm(o, g.w16(n + "attn_output.weight")))
        wgu = g.op("Concat", g.w16(n + "ffn_gate.weight"), g.w16(n + "ffn_up.weight"), axis=0)
        gu = g.gemm(g.rms(x, n + "ffn_norm.weight"), wgu)
        gate, up = g.op("Split", gu, g.i64("split_gu", [F, F]), axis=1, n_out=2)
        act = g.op("Mul", g.op("Mul", gate, g.op("Sigmoid", gate)), up)
        x = g.op("Add", x, g.gemm(act, g.w16(n + "ffn_down.weight")))
    g.output("x_out", x, [R, D])
    return g


def head(man, gguf_name, R, chunks=4):
    g = Graph(man, gguf_name)
    x = g.op("Cast", g.input("x", [R, D]), to=g.T.FLOAT16)
    sel = g.input("sel", [1], g.T.INT32)
    hn = g.rms(x, "output_norm.weight")
    xl = g.op("Gather", hn, sel, axis=0)
    step = V // chunks
    logits = g.op("Concat", *[g.gemm(xl, g.external("token_embd.weight", (i * step, (i + 1) * step)))
                              for i in range(chunks)], axis=1)
    g.output("hidden", hn, [R, D])
    g.output("logits", logits, [1, V])
    return g


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gguf", type=pathlib.Path, required=True)
    ap.add_argument("--out", type=pathlib.Path, default=ROOT / "build/npu/llama3b")
    ap.add_argument("--rows", type=int, default=512)
    ap.add_argument("--parts", type=int, default=7)
    a = ap.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    man = manifest(a.gguf)
    bounds = [round(i * L / a.parts) for i in range(a.parts + 1)]
    for i in range(a.parts):
        part(man, a.gguf.name, bounds[i], bounds[i + 1], a.rows).save(a.out / f"p{i}.onnx", f"llama3b_p{i}")
        print(f"p{i}.onnx: layers {bounds[i]} .. {bounds[i + 1] - 1}", flush=True)
    head(man, a.gguf.name, a.rows).save(a.out / "head.onnx", "llama3b_head")
    # inputs: the embedding rows of the benchmark's tokens (fp16 GGUF rows as fp32), and the last row
    tok = np.fromfile(ROOT / "ablas/llama3b/ref/tokens.bin", np.int32)[: a.rows]
    off, _, shape, _ = man["token_embd.weight"]
    emb = np.memmap(a.gguf, np.float16, "r", offset=off, shape=tuple(shape))
    emb[tok].astype(np.float32).tofile(a.out / "x.bin")
    np.array([a.rows - 1], np.int32).tofile(a.out / "sel.bin")
    print(f"wrote {a.parts} parts + head, x.bin ({len(tok)} tokens), sel.bin in {a.out}")


if __name__ == "__main__":
    main()
