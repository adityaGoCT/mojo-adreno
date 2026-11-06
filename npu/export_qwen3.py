"""Ternary Qwen3-8B's prompt prefill as w4a16 ONNX graphs for the Hexagon NPU (HTP), the same way npu/export.py
writes Llama's: LPBQ int4 weights in FullyConnected form (inputs split into chunks of 2048), uint16 activations
around every projection, the rest float (fp16 on the HTP).

  PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python
  PYTHONPATH=build/npu/pydeps $PY npu/export_qwen3.py --checkpoint <dir with model.safetensors> \\
      --rope build/qwen3/rope1024.f32 --out build/npu/qwen3-w4a16

The checkpoint is prism-ml/Ternary-Bonsai-8B-mlx-2bit: every projection and the head are MLX 2-bit groups of 128
with bias == -scale, so a weight is t * s with t in {-1, 0, +1} and s an fp16 scale per 128. As int4 with
per-block scales that is exact, but the HTP's block quantization (LPBQ, npu/quant.py) has scales c * u, c fp32 per
output channel and u 4-bit: so the weight becomes q * c * u with q = t * k, and each group of 128 takes the k in 1
.. 7 and u in 1 .. 15 whose product k * u is nearest to s / c. c is chosen per row (and chunk of 2048 inputs) among
s_max / P for the products P near the top, to minimize the row's worst relative error. That error is reported.

The reference is a float Qwen3 forward in PyTorch (fp32), run a layer at a time from the checkpoint (8B fp32
weights do not fit the Mac's memory at once), with the exact ternary weights or the graphs' LPBQ ones. It records
the activation ranges (calibration, on npu/calib.txt's prompts) and the K/V and logits of a prompt.
"""

import argparse
import json
import pathlib
import struct
import sys
import time

import numpy as np
import onnx
from onnx import TensorProto, helper

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import export  # noqa: E402
import quant  # noqa: E402

D, L, H, KVH, HD, F, V = 4096, 36, 32, 8, 128, 12288, 151669
QKV = (H + 2 * KVH) * HD
EPS = 1e-6
HEAD_CHUNKS = 4
OPSET = 23
PROJ = {"qkv": (QKV, D), "o": (D, D), "gu": (2 * F, D), "down": (D, F)}


# --- the checkpoint -------------------------------------------------------------------------------------------

class Checkpoint:
    """model.safetensors, memory-mapped."""

    def __init__(self, path):
        with open(path, "rb") as f:
            n = struct.unpack("<Q", f.read(8))[0]
            self.meta = json.loads(f.read(n))
        self.base = 8 + n
        self.mm = np.memmap(path, np.uint8, "r")

    def get(self, name):
        m = self.meta[name]
        dt = {"U32": np.uint32, "F16": np.float16, "BF16": np.uint16, "F32": np.float32}[m["dtype"]]
        a, b = m["data_offsets"]
        x = np.frombuffer(self.mm, np.uint8, b - a, self.base + a).view(dt).reshape(m["shape"])
        if m["dtype"] == "BF16":
            x = (x.astype(np.uint32) << 16).view(np.float32)
        return x

    def ternary(self, prefix, rows=slice(None)):
        """(t int8 [n, k] in -1..1, s fp32 [n, k / 128]) of a 2-bit projection."""
        w = np.asarray(self.get(prefix + ".weight")[rows])
        s = np.asarray(self.get(prefix + ".scales")[rows]).astype(np.float32)
        b = np.asarray(self.get(prefix + ".biases")[rows]).astype(np.float32)
        if not np.array_equal(b, -s):
            raise SystemExit(f"{prefix}: not ternary (bias != -scale)")
        codes = (w[..., None] >> (2 * np.arange(16, dtype=np.uint32))) & 3
        t = codes.reshape(w.shape[0], -1).astype(np.int8) - 1
        assert t.max() <= 1, prefix
        return t, s

    def norm(self, name):
        return np.asarray(self.get(name)).astype(np.float32)


def fused(ck, l, name):
    """(t, s) of a fused projection: qkv, o, gu or down of layer l."""
    p = f"model.layers.{l}."
    parts = {"qkv": ["self_attn.q_proj", "self_attn.k_proj", "self_attn.v_proj"], "o": ["self_attn.o_proj"],
             "gu": ["mlp.gate_proj", "mlp.up_proj"], "down": ["mlp.down_proj"]}[name]
    ts, ss = zip(*(ck.ternary(p + n) for n in parts))
    return np.concatenate(ts), np.concatenate(ss)


def embed_rows(ck, ids):
    """Rows of the 2-bit embedding (code * scale + bias), fp32, as qwen3/model.mojo dequantizes them."""
    w = np.asarray(ck.get("model.embed_tokens.weight")[ids])
    s = np.asarray(ck.get("model.embed_tokens.scales")[ids]).astype(np.float32)
    b = np.asarray(ck.get("model.embed_tokens.biases")[ids]).astype(np.float32)
    codes = ((w[..., None] >> (2 * np.arange(16, dtype=np.uint32))) & 3).reshape(len(ids), D).astype(np.float32)
    return codes * np.repeat(s, 128, 1) + np.repeat(b, 128, 1)


# --- ternary as LPBQ ------------------------------------------------------------------------------------------

def _products():
    p = sorted({k * u for k in range(1, 8) for u in range(1, quant.UMAX + 1)})
    best = {}
    for k in range(1, 8):  # the factorization with the largest k (so u is small and the int4 range used)
        for u in range(1, quant.UMAX + 1):
            best[k * u] = (k, u)
    return np.array(p, np.float32), best


PRODUCTS, FACTOR = _products()


def ternary_lpbq(t, s):
    """t int8 [n, k] (-1..1), s fp32 [n, k / 128] -> (q int8 [n, k], c fp32 [n], u uint8 [n, k / 64], worst
    relative scale error per row): s * t ~ q * c * u for blocks of 64, q = t * kk, kk * u the product nearest s / c."""
    n, k = t.shape
    smax = s.max(1)
    smax = np.where(smax > 0, smax, 1)
    m = s / smax[:, None]  # (0, 1]
    best_err = np.full(n, np.inf, np.float32)
    best_top = np.zeros(n, np.float32)
    for top in PRODUCTS[PRODUCTS >= 40]:
        target = m * top
        i = np.clip(np.searchsorted(PRODUCTS, target), 1, len(PRODUCTS) - 1)
        lo, hi = PRODUCTS[i - 1], PRODUCTS[i]
        near = np.where(np.abs(lo - target) <= np.abs(hi - target), lo, hi)
        near = np.where(target < PRODUCTS[0], PRODUCTS[0], near)
        err = np.where(s > 0, np.abs(near / target - 1), 0).max(1)
        take = err < best_err
        best_err, best_top = np.where(take, err, best_err), np.where(take, top, best_top)
    c = (smax / best_top).astype(np.float32)
    target = s / c[:, None]
    i = np.clip(np.searchsorted(PRODUCTS, target), 1, len(PRODUCTS) - 1)
    lo, hi = PRODUCTS[i - 1], PRODUCTS[i]
    near = np.where(np.abs(lo - target) <= np.abs(hi - target), lo, hi).astype(int)
    kk = np.vectorize(lambda p: FACTOR[p][0])(near).astype(np.int8)
    uu = np.vectorize(lambda p: FACTOR[p][1])(near).astype(np.uint8)
    kk = np.where(s > 0, kk, 1)
    q = (t.reshape(n, k // 128, 128) * kk[..., None]).reshape(n, k).astype(np.int8)
    u = np.repeat(np.where(s > 0, uu, 1), 2, 1).astype(np.uint8)  # groups of 128 = two blocks of 64
    return q, c, u, best_err


def ternary_pc4(t, s, iters=4):
    """t int8 [n, k], s fp32 [n, k / 128] -> (q int8 [n, k] in -7..7, c fp32 [n], worst relative scale error per
    row): per-channel int4, s * t ~ q * c with q = t * kk, kk in 1..7 a group. Per row, from c = max s / top for top
    in 5..7, Lloyd steps (kk = round(s / c), then the least-squares c) and the best of the three. The sums are in
    float64, where they are exact (s is fp16), so npu/qwen3_lpbq.cpp gets the same bytes in any order."""
    n, k = t.shape
    smax = s.max(1)
    smax = np.where(smax > 0, smax, np.float32(1)).astype(np.float32)
    s64 = s.astype(np.float64)
    best = None
    for top in (5, 6, 7):
        c = (smax / np.float32(top)).astype(np.float32)
        for _ in range(iters):
            kk = np.clip(np.rint(s / c[:, None]), 1, 7)
            c = ((kk * s64).sum(1) / (kk * kk).sum(1)).astype(np.float32)
        kk = np.clip(np.rint(s / c[:, None]), 1, 7)
        e = np.square(kk * c[:, None].astype(np.float64) - s64).sum(1)
        if best is None:
            best = [c, kk, e]
        else:
            take = e < best[2]
            best = [np.where(take, c, best[0]), np.where(take[:, None], kk, best[1]), np.where(take, e, best[2])]
    c, kk = best[0].astype(np.float32), best[1]
    err = np.where(s > 0, np.abs(kk * c[:, None] / np.where(s > 0, s, 1) - 1), 0).max(1)
    q = (t.reshape(n, k // 128, 128) * kk.astype(np.int8)[..., None]).reshape(n, k).astype(np.int8)
    return q, c, err


def write_pc4(data, name, t, s):
    q, c, err = ternary_pc4(t, s)
    data.add(name + ".q", quant.pack_int4(q))
    data.add(name + ".c", c)
    return float(err.max()), float(np.median(err))


def write_lpbq(data, name, t, s):
    """Data.matrix's "fc" layout for a ternary matrix, chunks of KMAX inputs (c per row and chunk)."""
    n, k = t.shape
    worst = 0.0
    for j in range(k // quant.KMAX):
        cols = slice(j * quant.KMAX, (j + 1) * quant.KMAX)
        q, c, u, err = ternary_lpbq(t[:, cols], s[:, j * quant.KMAX // 128:(j + 1) * quant.KMAX // 128])
        pre = f"{name}.k{j}"
        data.add(pre + ".q", quant.pack_int4(q))
        data.add(pre + ".u", u)
        data.add(pre + ".c", c)
        worst = max(worst, float(err.max()))
    return worst


def quantize_weights(ck, out, form):
    """form "pc4": per-channel int4 (ternary_pc4); "fc": LPBQ in FullyConnected chunks (ternary_lpbq)."""
    data = quant.Data(out, f"qwen3-w4a16 4096 36 32 8 128 12288 151669 form {form} keep -")
    worst, medians = 0.0, []

    def write(name, t, s):
        nonlocal worst
        if form == "pc4":
            w, m = write_pc4(data, name, t, s)
            medians.append(m)
        else:
            w = write_lpbq(data, name, t, s)
        worst = max(worst, w)

    for l in range(L):
        p = f"model.layers.{l}."
        data.add(f"l{l}.in_norm", ck.norm(p + "input_layernorm.weight"))
        data.add(f"l{l}.post_norm", ck.norm(p + "post_attention_layernorm.weight"))
        data.add(f"l{l}.q_norm", ck.norm(p + "self_attn.q_norm.weight"))
        data.add(f"l{l}.k_norm", ck.norm(p + "self_attn.k_norm.weight"))
        for name in PROJ:
            write(f"l{l}.{name}", *fused(ck, l, name))
        print(f"  layer {l} written, worst scale error so far {worst:.2e}", flush=True)
    data.add("final_norm", ck.norm("model.norm.weight"))
    for c, rows in enumerate(head_chunks()):
        write(f"head.{c}", *ck.ternary("lm_head", rows))
    data.close()
    if medians:
        print(f"median over matrices of the median row's worst scale error: {np.median(medians):.2e}")
    return worst


def head_chunks():
    b = [round(i * V / HEAD_CHUNKS) for i in range(HEAD_CHUNKS + 1)]
    return [slice(b[i], b[i + 1]) for i in range(HEAD_CHUNKS)]


# --- the reference (PyTorch, fp32, a layer at a time) ---------------------------------------------------------

def dense(ck, l, name, lpbq_dir=None):
    """A layer's fused weight [out, in] as fp32: exact ternary, or the graphs' LPBQ weights."""
    if lpbq_dir is not None:
        return lpbq_dir.matrix(f"l{l}.{name}", *PROJ[name])
    t, s = fused(ck, l, name)
    return t.astype(np.float32) * np.repeat(s, 128, 1)


def reference(ck, prompts, rope, lpbq_dir=None, ranges=None, keep_kv=False, head=True):
    """Every prompt (lists of ids) through the model: logits of each prompt's last row, the K/V of each layer if
    keep_kv ([layer] -> (k, v) [8, n, 128] of prompt 0), and the activation ranges (into `ranges`)."""
    import torch

    torch.set_num_threads(8)
    tt = lambda a: torch.from_numpy(np.ascontiguousarray(a))  # noqa: E731
    xs = [tt(embed_rows(ck, ids)) for ids in prompts]
    kv = {}
    tab = tt(rope)

    def seen(key, t):
        if ranges is not None:
            lo, hi = float(t.min()), float(t.max())
            old = ranges.get(key, (lo, hi))
            ranges[key] = (min(lo, old[0]), max(hi, old[1]))

    def rms(x, w):
        return x * torch.rsqrt(x.pow(2).mean(-1, keepdim=True) + EPS) * w

    def proj(x, w, key):  # x [n, in] @ w^T, with the input, output and chunk-product ranges
        seen(key + ".in", x)
        y = x @ w.T
        seen(key + ".out", y)
        if ranges is not None and w.shape[1] > quant.KMAX:
            for j in range(w.shape[1] // quant.KMAX):
                cols = slice(j * quant.KMAX, (j + 1) * quant.KMAX)
                seen(f"{key}.k{j}.out", x[:, cols] @ w[:, cols].T)
        return y

    def rotate(t, n):  # t [heads, n, 128]: rotate-half RoPE with the table's cos | sin (YaRN factor included)
        cos, sin = tab[:n, :64], tab[:n, 64:]
        a, b = t[..., :64], t[..., 64:]
        return torch.cat([a * cos - b * sin, b * cos + a * sin], -1)

    with torch.no_grad():
        for l in range(L):
            t0 = time.time()
            p = f"model.layers.{l}."
            w = {name: tt(dense(ck, l, name, lpbq_dir)) for name in PROJ}
            nin, npost = tt(ck.norm(p + "input_layernorm.weight")), tt(ck.norm(p + "post_attention_layernorm.weight"))
            nq, nk = tt(ck.norm(p + "self_attn.q_norm.weight")), tt(ck.norm(p + "self_attn.k_norm.weight"))
            for i, x in enumerate(xs):
                n = x.shape[0]
                seen(f"l{l}.resid", x)
                qkv = proj(rms(x, nin), w["qkv"], f"l{l}.qkv")
                q = rotate(rms(qkv[:, :H * HD].reshape(n, H, HD), nq).transpose(0, 1), n)
                k = rotate(rms(qkv[:, H * HD:(H + KVH) * HD].reshape(n, KVH, HD), nk).transpose(0, 1), n)
                v = qkv[:, (H + KVH) * HD:].reshape(n, KVH, HD).transpose(0, 1)
                if keep_kv and i == 0:
                    kv[l] = (k.numpy().copy(), v.numpy().copy())
                qg = q.reshape(KVH, H // KVH, n, HD).reshape(KVH, H // KVH * n, HD) / np.sqrt(HD)
                sc = qg @ k.transpose(1, 2)  # [8, 4n, n]
                mask = torch.triu(torch.full((n, n), float("-inf")), 1).repeat(H // KVH, 1)
                o = torch.softmax(sc + mask, -1) @ v  # [8, 4n, 128]
                o = o.reshape(H, n, HD).transpose(0, 1).reshape(n, D)
                x = x + proj(o, w["o"], f"l{l}.o")
                gu = proj(rms(x, npost), w["gu"], f"l{l}.gu")
                act = torch.nn.functional.silu(gu[:, :F]) * gu[:, F:]
                x = x + proj(act, w["down"], f"l{l}.down")
                xs[i] = x
            print(f"  reference layer {l}: {time.time() - t0:.1f} s, |x| <= {max(float(x.abs().max()) for x in xs):.0f}",
                  flush=True)
        if not head:
            return None, kv
        fn = tt(ck.norm("model.norm.weight"))
        last = torch.stack([rms(x[-1], fn) for x in xs])
        logits = []
        for c, rows in enumerate(head_chunks()):
            if lpbq_dir is not None:
                wh = tt(lpbq_dir.matrix(f"head.{c}", rows.stop - rows.start, D))
            else:
                t, s = ck.ternary("lm_head", rows)
                wh = tt(t.astype(np.float32) * np.repeat(s, 128, 1))
            logits.append(proj(last, wh, "head"))
        return torch.cat(logits, 1).numpy(), kv


# --- the graphs -----------------------------------------------------------------------------------------------

def layer(g, l, x, rows, cos, sin, mask, scale):
    p = f"l{l}."
    xn = g.op("RMSNormalization", x, g.norm(p + "in_norm", D), axis=-1, epsilon=EPS)
    qkv = g.gemm(xn, p + "qkv", [QKV, D], p + "qkv")
    q, k, v = g.ops("Split", [qkv, g.const("split_qkv", np.array([H * HD, KVH * HD, KVH * HD], np.int64))], 3,
                    axis=1)

    def heads(t, n, norm):  # [rows, n*128] -> (q/k norm) -> [n, rows, 128]
        t = g.op("Reshape", t, g.const(f"shape_{n}", np.array([rows, n, HD], np.int64)))
        if norm:
            # q/k RMS norm per head, written out: ONNX Runtime 1.29 gives every QNN RmsNorm one shared dummy beta
            # tensor ("_beta_dummy", sized by the first, D), so a 128-wide RmsNorm fails validation (4096 != 128).
            # Pre-scaled by 1/8 (epsilon by 1/64): the same result, and x * x stays far from fp16's limit.
            xs = g.op("Mul", t, g.const("eighth", np.array(0.125, np.float32)))
            ms = g.op("ReduceMean", g.op("Mul", xs, xs), g.const("axes_last", np.array([-1], np.int64)), keepdims=1)
            rms = g.op("Sqrt", g.op("Add", ms, g.const("eps_64", np.array(EPS / 64, np.float32))))
            t = g.op("Mul", g.op("Div", xs, rms), g.norm(norm, HD))
        return g.op("Transpose", t, perm=[1, 0, 2])

    def rope(t):
        t1, t2 = g.ops("Split", [t, g.const("split_half", np.array([HD // 2, HD // 2], np.int64))], 2, axis=-1)
        rot = g.op("Concat", g.op("Neg", t2), t1, axis=-1)
        return g.op("Add", g.op("Mul", t, cos), g.op("Mul", rot, sin))

    q = rope(heads(q, H, p + "q_norm"))
    k = rope(heads(k, KVH, p + "k_norm"))
    v = heads(v, KVH, None)
    g.output(f"k{l}", g.to_io(k))
    g.output(f"v{l}", g.to_io(v))
    qg = g.op("Mul", g.op("Reshape", q, g.const("shape_qg", np.array([KVH, H // KVH * rows, HD], np.int64))), scale)
    s = g.op("Add", g.op("MatMul", qg, g.op("Transpose", k, perm=[0, 2, 1])), mask)
    o = g.op("MatMul", g.op("Softmax", s, axis=-1), v)
    o = g.op("Reshape", g.op("Transpose", g.op("Reshape", o, g.const("shape_o", np.array([H, rows, HD], np.int64))),
                             perm=[1, 0, 2]), g.const("shape_x", np.array([rows, D], np.int64)))
    x = g.op("Add", x, g.gemm(o, p + "o", [D, D], p + "o"))
    xn = g.op("RMSNormalization", x, g.norm(p + "post_norm", D), axis=-1, epsilon=EPS)
    gu = g.gemm(xn, p + "gu", [2 * F, D], p + "gu")
    gate, up = g.ops("Split", [gu, g.const("split_gu", np.array([F, F], np.int64))], 2, axis=1)
    act = g.op("Mul", g.op("Mul", gate, g.op("Sigmoid", gate)), up)
    return g.op("Add", x, g.gemm(act, p + "down", [D, F], p + "down"))


def part(rope, first, last, rows, head, qman, calib, form):
    g = export.Graph(None, True, qman, calib, form)
    tab = rope[:rows]
    cos = g.const("rope_cos", np.concatenate([tab[:, :64], tab[:, :64]], 1)[None].astype(np.float32))
    sin = g.const("rope_sin", np.concatenate([tab[:, 64:], tab[:, 64:]], 1)[None].astype(np.float32))
    mask = np.where(np.tril(np.ones((rows, rows), bool)), 0, -30000).astype(np.float32)
    mask = g.const("mask", np.tile(mask, (H // KVH, 1))[None])
    scale = g.const("scale", np.array(1 / np.sqrt(HD), np.float32))
    inputs = [helper.make_tensor_value_info("x", g.io, [rows, D])]
    x = g.op("Cast", "x", to=g.f)
    outputs = []
    for l in range(first, last):
        x = layer(g, l, x, rows, cos, sin, mask, scale)
        outputs += [helper.make_tensor_value_info(f"{kv}{l}", g.io, [KVH, rows, HD]) for kv in "kv"]
    if head:
        inputs.append(helper.make_tensor_value_info("last", TensorProto.INT32, [1]))
        xl = g.op("RMSNormalization", g.op("Gather", x, "last", axis=0), g.norm("final_norm", D), axis=-1,
                  epsilon=EPS)
        chunks = [g.gemm(xl, f"head.{c}", [r.stop - r.start, D], "head") for c, r in enumerate(head_chunks())]
        g.output("logits", g.to_io(g.op("Concat", *chunks, axis=1)))
        outputs.append(helper.make_tensor_value_info("logits", g.io, [1, V]))
    else:
        g.output("x_out", g.to_io(x))
        outputs.append(helper.make_tensor_value_info("x_out", g.io, [rows, D]))
    graph = helper.make_graph(g.nodes, f"qwen3_prefill_l{first}_{last}", inputs, outputs, g.inits)
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", OPSET)], producer_name="mojo-adreno/npu")
    model.ir_version = 10
    return model


def chat_ids(tok, text):
    """Qwen3's chat template around `text` (no thinking), as ids: the Qwen2.5 tokenizer has the same vocabulary for
    text, and the special tokens are written out (<|im_start|> 151644, <|im_end|> 151645, <think> 151667,
    </think> 151668), as in build/qwen3/long_llama.txt."""
    return ([151644, 872, 198] + tok.encode(text, add_special_tokens=False)
            + [151645, 198, 151644, 77091, 198, 151667, 271, 151668, 271])


def calib_prompts(path, rows):
    """npu/calib.txt's prompts, then all of them in one message (cut to `rows` tokens)."""
    from transformers import AutoTokenizer

    tok = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-1.5B-Instruct")
    texts = [t.strip() for t in pathlib.Path(path).read_text().split("\n---\n")]
    return [chat_ids(tok, text)[:rows] for text in texts + ["\n\n".join(texts)]]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--checkpoint", type=pathlib.Path, required=True, help="dir with model.safetensors")
    ap.add_argument("--rope", type=pathlib.Path, default=pathlib.Path("build/qwen3/rope1024.f32"),
                    help="MLX's YaRN table (rows of cos | sin, 128 floats), at least --rows rows")
    ap.add_argument("--out", type=pathlib.Path, default=pathlib.Path("build/npu/qwen3-w4a16"))
    ap.add_argument("--rows", type=int, default=416)
    ap.add_argument("--parts", type=int, default=6)
    ap.add_argument("--bounds", default="0 6 12 18 24 30 33 36",
                    help="the parts' first layers and the end (overrides --parts): six layers a part, but the last "
                         "six with the head in two parts, as compiling them in one runs the phone out of memory")
    ap.add_argument("--calib", type=pathlib.Path, default=HERE / "calib.txt")
    ap.add_argument("--form", choices=["pc4", "fc"], default="pc4",
                    help="per-channel int4 (approximate group scales), or LPBQ FullyConnected chunks (which QNN 2.42 "
                         "builds only for 2048 x 2048)")
    a = ap.parse_args()
    ck = Checkpoint(a.checkpoint / "model.safetensors")
    rope = np.fromfile(a.rope, np.float32).reshape(-1, HD)
    assert len(rope) >= a.rows, "the RoPE table is shorter than --rows"
    a.out.mkdir(parents=True, exist_ok=True)
    if not (a.out / "manifest.txt").exists():
        print(f"ternary -> LPBQ int4 -> {a.out}/weights.bin", flush=True)
        worst = quantize_weights(ck, a.out, a.form)
        print(f"worst relative error of a group's scale: {worst:.2e}")
    qman = quant.read_manifest(a.out)[1]
    if not (a.out / "calib.json").exists():
        ranges = {}
        reference(ck, calib_prompts(a.calib, a.rows), rope, quant.Reader(a.out), ranges, head=True)
        quant.save_calib(a.out / "calib.json", ranges)
    calib = quant.load_calib(a.out / "calib.json")
    bounds = list(map(int, a.bounds.split())) if a.bounds else [round(i * L / a.parts) for i in range(a.parts + 1)]
    assert bounds[0] == 0 and bounds[-1] == L and bounds == sorted(bounds), bounds
    a.parts = len(bounds) - 1
    for i in range(a.parts):
        m = part(rope, bounds[i], bounds[i + 1], a.rows, i == a.parts - 1, qman, calib, quant.Reader(a.out).form)
        onnx.save(m, a.out / f"part{i}.onnx")
        print(f"part{i}.onnx: layers {bounds[i]} .. {bounds[i + 1] - 1}, {len(m.graph.node)} nodes, "
              f"{(a.out / f'part{i}.onnx').stat().st_size / 1e3:.0f} KB")
    (a.out / "npu.txt").write_text(f"qwen3-prefill rows {a.rows} parts {a.parts} layers "
                                   + " ".join(map(str, bounds)) + " w4a16\n")


if __name__ == "__main__":
    main()
