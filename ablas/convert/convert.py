#!/usr/bin/env python3
"""lt-convert (v0): a model's files -> an AdrenoBLASLt plan and its packed weights, run on the phone by plan_run.

  python convert.py MODEL -o OUTDIR [--type q4_0|f16] [--layers L] [--plan-only]

MODEL is a .gguf file (read with llama.cpp's gguf-py: $GGUF_PY, default ~/runix/llama.cpp/gguf-py) or a Hugging
Face directory (config.json + *.safetensors, read from the safetensors headers: numpy only, no torch). OUTDIR gets
  model.plan   the program, as text: the weights index, the activation buffers (bytes linear in M, the prompt's rows
               padded to 64), host steps (RoPE table, embedding rows) and one AdrenoBLASLt call per line (README.md)
  weights.bin  every weight the plan names, page-aligned, in AdrenoBLAS's formats (ablasLtWeightPack's output, so
               the phone maps or reads it without any transform)

The stages, each a function below:
  source   GGUFSource / HFSource: metadata -> Cfg, tensors under one naming (GGUF's), GGUF Llama's Q/K rows back
           in the rotate-half order AdrenoBLASLt's RoPE uses
  IR       decoder_llm(): the family template, unfused (embedding, RMSNorm, Linear, RoPE, attention, residual add,
           GLU, LM head on the last rows)
  fusion   fuse_qkv_rope, fuse_glu, fuse_residual, lower: the fusions ../lt/llama_lt.c makes by hand (q;k;v + RoPE
           into ROPE_QKV, gate|up + SwiGLU/GeGLU, o/down + RESIDUAL whose row sums feed the next RMSNorm)
  planner  layouts (fp32 rows for the residual stream, tiles between calls), buffers by liveness, workspace
  packer   pack_weights(): fp16 tiles or Q4_0 (requantized with ggml's reference rounding, or ggml Q4_0 blocks
           repacked as they are), the GATE_UP row order, 4 KB alignment
  writer   write_plan()
"""
import argparse
import glob
import json
import math
import os
import pathlib
import struct
import sys
import time
from collections import defaultdict
from dataclasses import dataclass

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import formats as fm  # noqa: E402

GGUF_PY = os.environ.get("GGUF_PY", str(pathlib.Path.home() / "runix/llama.cpp/gguf-py"))
ALIGN = 4096
PLAN_VERSION = 0


# ---- sources --------------------------------------------------------------------------------------------------------

@dataclass
class Cfg:
    arch: str
    n_layers: int
    dim: int
    n_heads: int
    n_kv_heads: int
    head_dim: int
    ffn: int
    vocab: int
    eps: float
    act: str            # GLU activation: silu (SwiGLU) or gelu_tanh (GeGLU)
    tied: bool          # LM head = the token embedding
    inv_freq: np.ndarray  # RoPE frequencies (float32 [head_dim / 2]), any scaling applied
    q_prescale: float = 1.0  # a power of two of the softmax scale folded into W_q, b_q: fa3 forms Q K^T in fp16


def rope_inv_freq(base, dim):
    return (np.float32(1) / (np.float32(base) ** (np.arange(0, dim, 2).astype(np.float32) / np.float32(dim)))).astype(np.float32)


def llama3_scaling(inv, rs):
    """transformers' _compute_llama3_parameters, in float32."""
    factor, lo, hi = np.float32(rs["factor"]), np.float32(rs["low_freq_factor"]), np.float32(rs["high_freq_factor"])
    old = np.float32(rs["original_max_position_embeddings"])
    lw, hw = old / lo, old / hi
    wl = np.float32(2 * math.pi) / inv
    il = np.where(wl > lw, inv / factor, inv).astype(np.float32)
    sm = ((old / wl - lo) / (hi - lo)).astype(np.float32)
    smoothed = ((1 - sm) * il / factor + sm * il).astype(np.float32)
    return np.where(~(wl < hw) & ~(wl > lw), smoothed, il).astype(np.float32)


class GGUFSource:
    """A GGUF file. Tensor names are GGUF's without '.weight' (token_embd, blk.0.attn_q, output_norm, ...)."""
    ARCHS = {"llama"}            # validated; others need their template checks first
    PERMUTED_ROPE = {"llama"}    # convert_hf_to_gguf.py permutes these archs' Q/K rows for ggml's interleaved RoPE

    def __init__(self, path):
        sys.path.insert(0, GGUF_PY)
        import gguf
        self.gguf, self.path = gguf, pathlib.Path(path)
        self.r = gguf.GGUFReader(str(path))
        self.t = {t.name.removesuffix(".weight"): t for t in self.r.tensors}
        a = self.arch = self.meta("general.architecture")
        if a not in self.ARCHS:
            raise SystemExit(f"{path}: architecture {a!r} has no template yet (v0: {sorted(self.ARCHS)})")
        heads = int(self.meta(f"{a}.attention.head_count"))
        dim = int(self.meta(f"{a}.embedding_length"))
        hd = int(self.meta(f"{a}.attention.key_length", dim // heads))
        rdim = int(self.meta(f"{a}.rope.dimension_count", hd))
        if rdim != hd:
            raise SystemExit(f"partial RoPE ({rdim} of {hd} dims) is not supported")
        inv = rope_inv_freq(self.meta(f"{a}.rope.freq_base", 10000.0), rdim)
        if "rope_freqs" in self.t:  # llama3 scaling as divisors (convert_hf_to_gguf.py's rope_factors)
            inv = (inv / np.asarray(self.t["rope_freqs"].data, np.float32)).astype(np.float32)
        ffn = self.meta(f"{a}.feed_forward_length")
        if isinstance(ffn, list):
            raise SystemExit("per-layer FFN sizes are not supported")
        self.cfg = Cfg(arch=a, n_layers=int(self.meta(f"{a}.block_count")), dim=dim, n_heads=heads,
                       n_kv_heads=int(self.meta(f"{a}.attention.head_count_kv", heads)), head_dim=hd, ffn=int(ffn),
                       vocab=self.shape("token_embd")[0], eps=float(self.meta(f"{a}.attention.layer_norm_rms_epsilon")),
                       act="silu", tied="output" not in self.t, inv_freq=inv)

    def meta(self, key, default=None):
        f = self.r.fields.get(key)
        return default if f is None else f.contents()

    def has(self, name):
        return name in self.t

    def shape(self, name):
        return tuple(int(s) for s in reversed(self.t[name].shape))  # ggml ne is [K, N]; ours is [N, K]

    def kind(self, name):
        return self.t[name].tensor_type.name.lower()

    def row_perm(self, name):
        """Row i of the rotate-half weight is row perm[i] of the GGUF one (inverse of HF -> GGUF's permute)."""
        if self.arch not in self.PERMUTED_ROPE or not (name.endswith(".attn_q") or name.endswith(".attn_k")):
            return None
        n, hd = self.shape(name)[0], self.cfg.head_dim
        i = np.arange(hd // 2)
        head = np.concatenate([2 * i, 2 * i + 1])  # first half <- even rows, second half <- odd rows
        return (np.arange(n // hd)[:, None] * hd + head[None]).ravel()

    def rows(self, name, idx=None):
        t = self.t[name]
        d = t.data if idx is None else t.data[idx]
        if t.tensor_type.name in ("F32", "F16"):
            return np.asarray(d, np.float32)
        return self.gguf.quants.dequantize(np.asarray(d), t.tensor_type).astype(np.float32)

    def q4_0_rows(self, name, idx):
        return np.asarray(self.t[name].data[idx], np.uint8)


class HFSource:
    """A Hugging Face directory: config.json + *.safetensors. Names mapped to GGUF's."""
    MODEL_TYPES = {"llama", "qwen2"}  # qwen2: biases on q, k, v

    def __init__(self, d):
        d = self.path = pathlib.Path(d)
        c = json.load(open(d / "config.json"))
        if c.get("model_type") not in self.MODEL_TYPES:
            raise SystemExit(f"{d}: model_type {c.get('model_type')!r} has no template yet (v0: {sorted(self.MODEL_TYPES)})")
        if (c.get("attention_bias") and c["model_type"] != "qwen2") or c.get("mlp_bias"):
            raise SystemExit("biases are not in the llama template yet")
        self.t = {}
        for f in sorted(glob.glob(str(d / "*.safetensors"))):
            mm = np.memmap(f, np.uint8, mode="r")
            n = struct.unpack("<Q", bytes(mm[:8]))[0]
            for k, v in json.loads(bytes(mm[8:8 + n])).items():
                if k == "__metadata__":
                    continue
                s, e = v["data_offsets"]
                self.t[self._name(k)] = (mm[8 + n + s:8 + n + e], v["dtype"], tuple(v["shape"]))
        heads, dim = c["num_attention_heads"], c["hidden_size"]
        hd = c.get("head_dim") or dim // heads
        rp = c.get("rope_parameters") or {}
        inv = rope_inv_freq(c.get("rope_theta", rp.get("rope_theta", 10000.0)), hd)
        rs = c.get("rope_scaling") or rp
        if rs and rs.get("rope_type", rs.get("type")) == "llama3":
            inv = llama3_scaling(inv, rs)
        elif rs and rs.get("rope_type", rs.get("type")) not in (None, "default"):
            raise SystemExit(f"RoPE scaling {rs} is not supported")
        if c.get("hidden_act", "silu") != "silu":
            raise SystemExit(f"activation {c['hidden_act']} is not in the llama template")
        self.arch = c["model_type"]
        self.cfg = Cfg(arch=self.arch, n_layers=c["num_hidden_layers"], dim=dim, n_heads=heads,
                       n_kv_heads=c.get("num_key_value_heads", heads), head_dim=hd, ffn=c["intermediate_size"],
                       vocab=c["vocab_size"], eps=float(np.float32(c["rms_norm_eps"])), act="silu",
                       tied=bool(c.get("tie_word_embeddings", False)) or "output" not in self.t, inv_freq=inv,
                       # Qwen2's K bias makes raw Q K^T reach 2.7e5 (Qwen2.5-1.5B, layer 0): past fp16
                       q_prescale=1 / 16 if self.arch == "qwen2" else 1.0)

    HF = {"self_attn.q_proj": "attn_q", "self_attn.k_proj": "attn_k", "self_attn.v_proj": "attn_v",
          "self_attn.o_proj": "attn_output", "mlp.gate_proj": "ffn_gate", "mlp.up_proj": "ffn_up",
          "mlp.down_proj": "ffn_down", "input_layernorm": "attn_norm", "post_attention_layernorm": "ffn_norm"}

    def _name(self, k):
        if k.endswith(".bias"):  # GGUF's naming: blk.0.attn_q.bias
            return self._name(k[:-len(".bias")]) + ".bias"
        k = k.removesuffix(".weight")
        if k == "model.embed_tokens":
            return "token_embd"
        if k == "model.norm":
            return "output_norm"
        if k == "lm_head":
            return "output"
        if k.startswith("model.layers."):
            l, rest = k[len("model.layers."):].split(".", 1)
            return f"blk.{l}.{self.HF.get(rest, rest)}"
        return k

    def has(self, name):
        return name in self.t

    def shape(self, name):
        return self.t[name][2]

    def kind(self, name):
        return self.t[name][1].lower()

    def row_perm(self, name):
        return None

    def rows(self, name, idx=None):
        raw, dt, shape = self.t[name]
        if dt == "BF16":
            a = raw.view("<u2").reshape(shape)
            a = a if idx is None else a[idx]
            return (a.astype(np.uint32) << 16).view(np.float32)
        a = raw.view({"F16": "<f2", "F32": "<f4"}[dt]).reshape(shape)
        return np.asarray(a if idx is None else a[idx], np.float32)

    def q4_0_rows(self, name, idx):
        raise NotImplementedError


def open_source(path):
    p = pathlib.Path(path)
    return HFSource(p) if p.is_dir() else GGUFSource(p)


# ---- model IR ------------------------------------------------------------------------------------------------------

class Lin:
    """a * M + b + c * T. M: a run's row count (the prompt padded to its bucket); T: the first row of the 64-row tile
    that holds the prompt's last token (M - 64 when the bucket is the prompt padded to 64)."""
    __slots__ = ("a", "b", "c")

    def __init__(self, a=0, b=0, c=0):
        self.a, self.b, self.c = a, b, c

    def __add__(self, o):
        o = o if isinstance(o, Lin) else Lin(0, o)
        return Lin(self.a + o.a, self.b + o.b, self.c + o.c)

    def __sub__(self, o):
        o = o if isinstance(o, Lin) else Lin(0, o)
        return Lin(self.a - o.a, self.b - o.b, self.c - o.c)

    def __mul__(self, k):
        return Lin(self.a * k, self.b * k, self.c * k)

    def __eq__(self, o):
        return isinstance(o, Lin) and (self.a, self.b, self.c) == (o.a, o.b, o.c)

    def __hash__(self):
        return hash((self.a, self.b, self.c))

    def __str__(self):
        terms = [("" if k == 1 else "-" if k == -1 else f"{k}*") + v for k, v in ((self.a, "M"), (self.c, "T")) if k]
        if self.b or not terms:
            terms.append(str(self.b))
        return "+".join(terms).replace("+-", "-")


M, T = Lin(1, 0), Lin(0, 0, 1)


class Val:
    """An activation. fmt (set when lowered): row | tiled | heads (Q/K tiles [n][M, hd]) | vt (V^T tiles) | rope."""

    def __init__(self, role, dtype, rows, cols, base=None, row0=None):
        self.role, self.dtype, self.rows, self.cols = role, dtype, rows, cols
        self.base, self.row0 = base, row0  # a view: rows [row0, row0 + rows) of base, no storage of its own
        self.fmt, self.row_bytes = None, None

    def layout(self):
        return f"{self.dtype}:{self.fmt}:{self.rows}:{self.cols}"

    def __repr__(self):
        return f"%{self.role}<{self.dtype} [{self.rows}, {self.cols}]>"


class Wt:
    """A weight of the IR: source tensors' rows concatenated, laid out for `use` (plain | gate_up), or a constant."""

    def __init__(self, name, parts, use="plain", vector=False, const=None, scales=None):
        self.name, self.parts, self.use, self.vector, self.const = name, parts, use, vector, const
        self.scales = scales or [1.0] * len(parts)  # per part (exact powers of two)


class Node:
    def __init__(self, op, ins, outs, **attrs):
        self.op, self.ins, self.outs, self.attrs = op, ins, outs, attrs

    def __repr__(self):
        return f"{self.op}{self.attrs} {self.ins} -> {self.outs}"


def decoder_llm(cfg, src, layers=None):
    """The decoder-LLM family template (Llama): unfused ops over the prompt's M rows. Returns nodes, outputs."""
    nodes = []
    D, H, KV, HD, F = cfg.dim, cfg.n_heads, cfg.n_kv_heads, cfg.head_dim, cfg.ffn

    def node(op, ins, outs, **a):
        nodes.append(Node(op, ins, outs, **a))

    def W(name):
        if not src.has(name):
            raise SystemExit(f"missing tensor {name}")
        return Wt(name, [name], vector=len(src.shape(name)) == 1)

    def linear(x, wname, dtype="f16"):
        y = Val("y", dtype, x.rows, src.shape(wname)[0])
        ins = {"x": x, "w": W(wname)}
        if src.has(wname + ".bias"):
            ins["b"] = W(wname + ".bias")
        node("linear", ins, {"out": y})
        return y

    def rmsnorm(x, wname):
        h = Val("h", "f16", x.rows, D)
        node("rmsnorm", {"x": x, "weight": W(wname)}, {"out": h}, eps=cfg.eps)
        return h

    def add(x, y):
        x2 = Val("x", "f32", x.rows, D)
        node("add", {"x": x, "y": y}, {"out": x2})
        return x2

    x = Val("x", "f32", M, D)
    node("embed", {"table": W("token_embd")}, {"out": x})
    cs = Val("cs", "f32", M, HD)
    node("rope_table", {"inv_freq": Wt("rope.inv_freq", [], vector=True, const=cfg.inv_freq)}, {"out": cs}, dim=HD)
    for l in range(cfg.n_layers if layers is None else layers):
        p = f"blk.{l}."
        h = rmsnorm(x, p + "attn_norm")
        q, k, v = linear(h, p + "attn_q"), linear(h, p + "attn_k"), linear(h, p + "attn_v")
        qr, kr = Val("q", "f16", M, H * HD), Val("k", "f16", M, KV * HD)
        node("rope", {"q": q, "k": k, "table": cs}, {"q": qr, "k": kr}, heads=H, kv_heads=KV, head_dim=HD)
        o = Val("attn", "f16", M, H * HD)
        node("attention", {"q": qr, "k": kr, "v": v}, {"out": o}, heads=H, kv_heads=KV, head_dim=HD,
             scale=float(np.float32(1) / np.sqrt(np.float32(HD))), causal=True)
        x = add(x, linear(o, p + "attn_output"))
        h = rmsnorm(x, p + "ffn_norm")
        a = Val("act", "f16", M, F)
        node("glu", {"gate": linear(h, p + "ffn_gate"), "up": linear(h, p + "ffn_up")}, {"out": a}, act=cfg.act)
        x = add(x, linear(a, p + "ffn_down"))
    h = rmsnorm(x, "output_norm")
    last = Val("h_last", "f16", Lin(0, 64), D, base=h, row0=T)  # the LM head: only the tile with the last token
    logits = linear(last, "token_embd" if cfg.tied else "output", dtype="f32")
    logits.role = "logits"
    return nodes, {"logits": (logits, T), "hidden": (h, Lin())}


# ---- fusion -------------------------------------------------------------------------------------------------------

def uses(nodes):
    prod, users = {}, defaultdict(list)
    for n in nodes:
        for v in n.outs.values():
            prod[v] = n
        for v in n.ins.values():
            if isinstance(v, Val):
                users[v].append(n)
                if v.base is not None:
                    users[v.base].append(n)
    return prod, users


def replace(nodes, old, new, at):
    """Remove `old` nodes, put `new` where `at` was."""
    i = nodes.index(at)
    nodes[i] = new
    for o in old:
        if o is not at:
            nodes.remove(o)


def fuse_qkv_rope(nodes, q_prescale=1.0):
    """linear q, k, v of one input + RoPE + attention -> ROPE_QKV (W = q;k;v rows) feeding the attention."""
    prod, users = uses(nodes)
    for r in [n for n in nodes if n.op == "rope"]:
        lq, lk = prod[r.ins["q"]], prod[r.ins["k"]]
        att = users[r.outs["q"]]
        if len(att) != 1 or att[0].op != "attention" or att[0].ins["k"] is not r.outs["k"]:
            continue
        att = att[0]
        lv = prod[att.ins["v"]]
        x = lq.ins["x"]
        if not all(n.op == "linear" and n.ins["x"] is x and len(users[n.outs["out"]]) == 1 for n in (lq, lk, lv)):
            continue
        a = r.attrs
        wq, wk, wv = lq.ins["w"], lk.ins["w"], lv.ins["w"]
        nb = sum("b" in n.ins for n in (lq, lk, lv))
        if nb not in (0, 3):
            raise SystemExit("q/k/v with only some biases: not supported")
        sc = [q_prescale, 1.0, 1.0]
        w = Wt(wq.name.replace("attn_q", "attn_qkv"), wq.parts + wk.parts + wv.parts, scales=sc)
        if q_prescale != 1.0:
            att.attrs["scale"] = float(np.float32(att.attrs["scale"]) / np.float32(q_prescale))
        q, k = r.outs["q"], r.outs["k"]
        vt = Val("vt", "f16", M, a["kv_heads"] * a["head_dim"])
        q.fmt, q.row_bytes = "heads", a["heads"] * a["head_dim"] * 2
        k.fmt, k.row_bytes = "heads", a["kv_heads"] * a["head_dim"] * 2
        vt.fmt, vt.row_bytes = "vt", a["kv_heads"] * a["head_dim"] * 2
        ins = {"A": x, "W": w, "rope": r.ins["table"]}
        if nb:  # ROPE_QKV's general form adds q;k;v biases (fp32 [N])
            ins["bias"] = Wt(w.name + ".bias", [n.ins["b"].name for n in (lq, lk, lv)], vector=True, scales=sc)
        new = Node("matmul", ins, {"q": q, "k": k, "vt": vt}, epi="rope_qkv",
                   heads=a["heads"], kv_heads=a["kv_heads"], head_dim=a["head_dim"])
        replace(nodes, [lq, lk, lv, r], new, r)
        att.ins = {"q": q, "k": k, "vt": vt}


def fuse_glu(nodes):
    """linear gate, up of one input + silu/gelu(gate) * up -> SWIGLU / GEGLU (W = gate|up, GATE_UP layout)."""
    prod, users = uses(nodes)
    for g in [n for n in nodes if n.op == "glu"]:
        lg, lu = prod[g.ins["gate"]], prod[g.ins["up"]]
        x = lg.ins["x"]
        if not all(n.op == "linear" and n.ins["x"] is x and len(users[n.outs["out"]]) == 1 for n in (lg, lu)):
            continue
        wg, wu = lg.ins["w"], lu.ins["w"]
        w = Wt(wg.name.replace("ffn_gate", "ffn_gate_up"), wg.parts + wu.parts, use="gate_up")
        epi = {"silu": "swiglu", "gelu_tanh": "geglu"}[g.attrs["act"]]
        replace(nodes, [lg, lu, g], Node("matmul", {"A": x, "W": w}, {"D": g.outs["out"]}, epi=epi), g)


def fuse_residual(nodes):
    """x + linear(a) -> RESIDUAL (x += a W^T in place), with the row sums of squares the next RMSNorm can take."""
    prod, users = uses(nodes)
    for ad in [n for n in nodes if n.op == "add"]:
        ly = prod.get(ad.ins["y"])
        if ly is None or ly.op != "linear" or len(users[ad.ins["y"]]) != 1:
            continue
        x2 = ad.outs["out"]
        ss = Val("ss", "f32", x2.rows, x2.cols // 64)
        replace(nodes, [ly, ad], Node("matmul", {"A": ly.ins["x"], "W": ly.ins["w"], "D": ad.ins["x"]},
                                      {"D": x2, "aux": ss}, epi="residual", inplace="D"), ad)


def lower(nodes):
    """The rest to AdrenoBLASLt calls; RMSNorm takes a residual's row sums; every value gets its layout."""
    out = []
    prod, users = uses(nodes)
    for n in nodes:
        if n.op == "linear":
            if "b" in n.ins:
                raise SystemExit(f"no AdrenoBLASLt form for a Linear with a bias here: {n}")
            n = Node("matmul", {"A": n.ins["x"], "W": n.ins["w"]}, {"D": n.outs["out"]}, epi="default")
        elif n.op == "rmsnorm":
            p = prod.get(n.ins["x"])
            if p is not None and p.op == "matmul" and p.attrs["epi"] == "residual":
                n.ins["sumsq"] = p.outs["aux"]
        elif n.op == "attention":
            a = n.attrs
            if not a["causal"] or a["head_dim"] != 128 or "vt" not in n.ins:
                raise SystemExit(f"v0 lowers only causal attention over ROPE_QKV's heads of 128: {n}")
        elif n.op in ("add", "glu", "rope"):
            raise SystemExit(f"no AdrenoBLASLt form for an unfused {n.op}: {n}")
        out.append(n)
    # a residual whose row sums nobody reads computes them into the workspace instead
    _, users = uses(out)
    for n in out:
        if n.op == "matmul" and "aux" in n.outs and not users[n.outs["aux"]]:
            del n.outs["aux"]
    for n in out:
        for v in list(n.ins.values()) + list(n.outs.values()):
            if isinstance(v, Val) and v.fmt is None:
                b = v.base if v.base is not None else v
                if b.fmt is None:
                    b.fmt = "rope" if b.role == "cs" else "row" if b.dtype == "f32" else "tiled"
                    b.row_bytes = b.cols * (4 if b.dtype == "f32" else 2)
                v.fmt, v.row_bytes = b.fmt, b.row_bytes
        check_layouts(n)
    return out


def check_layouts(n):
    """The operand layouts AdrenoBLASLt accepts (ablasLt.h)."""
    i, o, epi = n.ins, n.outs, n.attrs.get("epi")
    ok = True
    if n.op == "matmul":
        A = i["A"]
        ok = (A.dtype, A.fmt) in (("f16", "tiled"), ("f32", "row"), ("f16", "row"))
        if epi == "residual":
            ok &= (o["D"].dtype, o["D"].fmt) == ("f32", "row") and A.fmt == "tiled"
        elif epi in ("swiglu", "geglu"):
            ok &= (o["D"].dtype, o["D"].fmt) == ("f16", "tiled") and A.fmt == "tiled"
    elif n.op == "rmsnorm":
        ok = (i["x"].dtype, i["x"].fmt, n.outs["out"].fmt) == ("f32", "row", "tiled")
    elif n.op == "attention":
        ok = (i["q"].fmt, i["k"].fmt, i["vt"].fmt, o["out"].fmt) == ("heads", "heads", "vt", "tiled")
    if not ok:
        raise SystemExit(f"layout not supported by AdrenoBLASLt: {n}")


# ---- planner: buffers -----------------------------------------------------------------------------------------------

class Buffer:
    def __init__(self, name, per_m, fixed):
        self.name, self.per_m, self.fixed = name, per_m, fixed


def plan_buffers(nodes, outputs):
    """Storage for every value: views use their base's; RESIDUAL's D is its input's; values whose lifetimes do not
    overlap share a buffer of the same size (linear scan; a call's outputs never share with its inputs)."""
    parent = {}

    def find(v):
        v = v.base if v.base is not None else v
        while parent.get(v, v) is not v:
            v = parent[v]
        return v

    for n in nodes:
        if n.attrs.get("inplace"):
            parent[find(n.outs[n.attrs["inplace"]])] = find(n.ins[n.attrs["inplace"]])
    last = {}
    for i, n in enumerate(nodes):
        for v in list(n.ins.values()) + list(n.outs.values()):
            if isinstance(v, Val):
                last[find(v)] = i
    for v, _ in outputs.values():
        last[find(v)] = len(nodes)
    free, bufs, of, names = defaultdict(list), [], {}, defaultdict(int)
    for i, n in enumerate(nodes):
        for v in n.outs.values():
            g = find(v)
            if g in of:
                continue
            size = g.rows * g.row_bytes
            assert not size.c, g
            cls = (size.a, size.b)
            if free[cls]:  # the buffer this role had before, else the last freed
                same = [b for b in free[cls] if b.role == g.role]
                of[g] = same[0] if same else free[cls][-1]
                free[cls].remove(of[g])
            else:
                names[g.role] += 1
                b = Buffer(g.role if names[g.role] == 1 else f"{g.role}{names[g.role]}", size.a, size.b)
                b.role = g.role
                bufs.append(b)
                of[g] = b
        for v in list(n.ins.values()) + list(n.outs.values()):
            if isinstance(v, Val):
                g = find(v)
                if last[g] == i and g in of and of[g] not in free[(of[g].per_m, of[g].fixed)]:
                    free[(of[g].per_m, of[g].fixed)].append(of[g])
    return bufs, lambda v: (of[find(v)], (v.row0 * v.row_bytes) if v.base is not None else Lin())


def needs_workspace(n):
    if n.op == "rmsnorm":
        return "sumsq" not in n.ins
    if n.op == "matmul":
        return n.ins["A"].fmt != "tiled" or n.attrs["epi"] == "rope_qkv" or (n.attrs["epi"] == "residual" and "aux" not in n.outs)
    return False


# ---- packer -----------------------------------------------------------------------------------------------------

def weights_of(nodes):
    seen = {}
    for n in nodes:
        for w in n.ins.values():
            if isinstance(w, Wt):
                if w.name in seen and (seen[w.name].parts, seen[w.name].use) != (w.parts, w.use):
                    raise SystemExit(f"two weights named {w.name}")
                seen.setdefault(w.name, w)
    return list(seen.values())


def weight_entry(w, src, wtype):
    """(type, rows, cols, use, bytes) of a weight in weights.bin."""
    if w.const is not None:
        return "f32", 1, w.const.size, "plain", w.const.size * 4
    if w.vector:
        n = sum(src.shape(p)[0] for p in w.parts)
        return "f32", 1, n, "plain", n * 4
    K = src.shape(w.parts[0])[1]
    N = sum(src.shape(p)[0] for p in w.parts)
    if any(src.shape(p)[1] != K for p in w.parts) or N % 64 or K % 64 or (w.use == "gate_up" and N % 128):
        raise SystemExit(f"{w.name}: [{N}, {K}] does not fit AdrenoBLAS's 64-row panels")
    return wtype, N, K, w.use, fm.packed_size(wtype, N, K)


def pack_weights(entries, src, path, wtype, log):
    """Writes weights.bin: each weight at its offset, packed in chunks of whole 64-row panels."""
    stats = defaultdict(int)
    with open(path, "wb") as f:
        for w, (t, N, K, use, nbytes, off) in entries:
            t0 = time.time()
            if t == "f32":
                data = w.const if w.const is not None else np.concatenate(
                    [src.rows(p) * np.float32(sc) for p, sc in zip(w.parts, w.scales)])
                f.seek(off)
                f.write(np.asarray(data, "<f4").tobytes())
                continue
            # where each row of the packed weight comes from: (part, source row), in the use's row order
            part = np.concatenate([np.full(src.shape(p)[0], i) for i, p in enumerate(w.parts)])
            srow = np.concatenate([src.row_perm(p) if src.row_perm(p) is not None else np.arange(src.shape(p)[0])
                                   for p in w.parts])
            if use == "gate_up":
                g = fm.gate_up_rows(N)
                part, srow = part[g], srow[g]
            raw = t == "q4_0" and all(src.kind(p) == "q4_0" for p in w.parts) and all(x == 1.0 for x in w.scales)
            lossy = t == "q4_0" and not raw and any(src.kind(p) not in ("f32", "f16", "bf16") for p in w.parts)
            stats["repacked ggml Q4_0" if raw else "requantized (lossy: from another quant)" if lossy else
                  f"from {src.kind(w.parts[0])}"] += 1
            chunk = max(64, (32 << 20) // K // 64 * 64)
            for r0 in range(0, N, chunk):
                r1 = min(N, r0 + chunk)
                pi, pr = part[r0:r1], srow[r0:r1]
                cols = K // 32 * 18 if raw else K
                rows = np.empty((r1 - r0, cols), np.uint8 if raw else np.float32)
                for i in np.unique(pi):
                    m = pi == i
                    rows[m] = src.q4_0_rows(w.parts[i], pr[m]) if raw else src.rows(w.parts[i], pr[m])
                    if w.scales[i] != 1.0:
                        rows[m] *= np.float32(w.scales[i])
                a, b = fm.pack_chunk(t, q4_blocks=rows) if raw else fm.pack_chunk(t, rows=rows)
                f.seek(off + r0 * (K // 2 if t == "q4_0" else K * 2))
                f.write(a)
                if b:
                    f.seek(off + N * K // 2 + r0 * K // 16)
                    f.write(b)
            log(f"  {w.name:24s} {t} [{N}, {K}] {use:7s} {nbytes / 1e6:8.1f} MB  {time.time() - t0:5.1f} s")
        f.truncate(entries[-1][1][5] + entries[-1][1][4] if entries else 0)
    return dict(stats)


# ---- writer ---------------------------------------------------------------------------------------------------------

def write_plan(path, src, cfg, wtype, nodes, outputs, bufs, where, entries, layers):
    def op(v):
        if v is None:
            return "-"
        if isinstance(v, Wt):
            return v.name
        b, off = where(v)
        return b.name if off == Lin() else f"{b.name}@{off}"

    L = []
    L.append(f"ltplan {PLAN_VERSION}")
    L.append(f"# lt-convert v0 from {src.path.name}: {cfg.arch}, {layers} layers, weights {wtype}")
    L.append(f"model arch={cfg.arch} wtype={wtype} layers={layers} dim={cfg.dim} heads={cfg.n_heads} "
             f"kv_heads={cfg.n_kv_heads} head_dim={cfg.head_dim} ffn={cfg.ffn} vocab={cfg.vocab} row_align=64")
    total = entries[-1][1][5] + entries[-1][1][4] if entries else 0
    L.append(f"weights weights.bin {total}")
    L.append("# weight <name> <type> <rows> <cols> <use> <offset> <bytes>")
    for w, (t, N, K, use, nbytes, off) in entries:
        L.append(f"weight {w.name} {t} {N} {K} {use} {off} {nbytes}")
    L.append("# buffer <name> <bytes per row of M> <fixed bytes>; workspace: sized by plan_run from the calls")
    for b in bufs:
        L.append(f"buffer {b.name} {b.per_m} {b.fixed}")
    L.append("workspace ws")
    layer = -1
    for n in nodes:
        a, i, o = n.attrs, n.ins, n.outs
        w = [x for x in i.values() if isinstance(x, Wt)]
        if w and w[0].name.startswith("blk."):
            l = int(w[0].name.split(".")[1])
            if l != layer:
                layer = l
                L.append(f"# layer {l}")
        elif w and layer >= 0 and n.op != "embed":
            layer = -1
            L.append("# head")
        ws = "ws" if needs_workspace(n) else "-"
        if n.op == "embed":
            L.append(f"host embed out={op(o['out'])} table={op(i['table'])}")
        elif n.op == "rope_table":
            L.append(f"host rope_table out={op(o['out'])} inv_freq={op(i['inv_freq'])} dim={a['dim']}")
        elif n.op == "rmsnorm":
            x = i["x"]
            L.append(f"call rmsnorm M={x.rows} D={x.cols} x={op(x)} sumsq={op(i.get('sumsq'))} weight={op(i['weight'])} "
                     f"eps={a['eps']!r} out={op(o['out'])} ws={ws}")
        elif n.op == "attention":
            L.append(f"call attention M={i['q'].rows} heads={a['heads']} kv_heads={a['kv_heads']} scale={a['scale']!r} "
                     f"q={op(i['q'])} k={op(i['k'])} vt={op(i['vt'])} out={op(o['out'])}")
        elif n.op == "matmul":
            A = i["A"]
            s = f"call matmul epi={a['epi']} A={op(A)} a={A.layout()} W={op(i['W'])}"
            if a["epi"] == "rope_qkv":
                s += (f" heads={a['heads']} kv_heads={a['kv_heads']} rope={op(i['rope'])} q={op(o['q'])} k={op(o['k'])}"
                      f" vt={op(o['vt'])}" + (f" bias={op(i['bias'])}" if "bias" in i else ""))
            else:
                s += f" D={op(o['D'])} d={o['D'].layout()}"
                if "aux" in o:
                    s += f" aux={op(o['aux'])}"
            L.append(s + f" ws={ws}")
        else:
            raise SystemExit(f"cannot write {n}")
    lg, row0 = outputs["logits"]
    L.append(f"output logits buf={op(lg)} layout={lg.layout()} row0={row0}")
    h, _ = outputs["hidden"]
    L.append(f"output hidden buf={op(h)} layout={h.layout()}")
    pathlib.Path(path).write_text("\n".join(L) + "\n")


# ---- main -----------------------------------------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("model", help=".gguf file or Hugging Face directory")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--type", default="q4_0", choices=fm.TYPES, help="the linear weights' format (default q4_0)")
    ap.add_argument("--layers", type=int, help="only the first L layers (tests)")
    ap.add_argument("--plan-only", action="store_true", help="write model.plan, not weights.bin")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args()
    log = print
    t0 = time.time()
    src = open_source(args.model)
    cfg = src.cfg
    layers = cfg.n_layers if args.layers is None else min(args.layers, cfg.n_layers)
    log(f"{src.path.name}: {cfg.arch}, {cfg.n_layers} layers, dim {cfg.dim}, heads {cfg.n_heads}/{cfg.n_kv_heads} of "
        f"{cfg.head_dim}, ffn {cfg.ffn}, vocab {cfg.vocab}, {'tied' if cfg.tied else 'untied'} LM head")

    nodes, outputs = decoder_llm(cfg, src, layers)
    n_ir = len(nodes)
    fuse_qkv_rope(nodes, cfg.q_prescale)
    fuse_glu(nodes)
    fuse_residual(nodes)
    nodes = lower(nodes)
    bufs, where = plan_buffers(nodes, outputs)
    kinds = defaultdict(int)
    for n in nodes:
        kinds[n.op + ("." + n.attrs["epi"] if "epi" in n.attrs else "")] += 1
    log(f"IR: {n_ir} ops -> {len(nodes)} after fusion: " + ", ".join(f"{k} {v}" for k, v in kinds.items()))
    log("buffers: " + ", ".join(f"{b.name} {b.per_m}*M+{b.fixed}" if b.fixed else f"{b.name} {b.per_m}*M" for b in bufs))

    ws = weights_of(nodes)
    entries, off = [], 0
    for w in ws:
        t, N, K, use, nbytes = weight_entry(w, src, args.type)
        entries.append((w, (t, N, K, use, nbytes, off)))
        off = (off + nbytes + ALIGN - 1) // ALIGN * ALIGN
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    write_plan(out / "model.plan", src, cfg, args.type, nodes, outputs, bufs, where, entries, layers)
    log(f"wrote {out / 'model.plan'}: {len(nodes)} calls, {len(entries)} weights, "
        f"{(entries[-1][1][5] + entries[-1][1][4]) / 1e9:.3f} GB")
    if not args.plan_only:
        stats = pack_weights(entries, src, out / "weights.bin", args.type, log if args.verbose else lambda s: None)
        log(f"wrote {out / 'weights.bin'}: " + ", ".join(f"{v} {k}" for k, v in stats.items()) +
            f"; {time.time() - t0:.0f} s")


if __name__ == "__main__":
    main()
