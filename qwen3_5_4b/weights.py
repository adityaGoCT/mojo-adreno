"""Qwen3.5-4B's weights for the reference and the export, both read from Hugging Face by HTTP range request when a
tensor is asked for (the Mac keeps neither file):

  Bf16Weights()   the published checkpoint (Qwen/Qwen3.5-4B, two safetensors shards, bf16; A_log in fp32), by
                  transformers' names: the model itself
  GGUFWeights()   unsloth/Qwen3.5-4B-GGUF's Qwen3.5-4B-Q4_0.gguf, the file the phone runs, dequantized as ggml does and
                  mapped back to transformers' names and layout: the exact reference for the phone

llama.cpp's converter changed the layout, and GGUFWeights undoes it (checked against the bf16 tensors):
  - the linear-attention value heads are tiled, not grouped: GGUF head i is transformers' head 2 (i % 16) + i // 16
    (so it reads key head i % 16), in in_proj_qkv's v rows, in_proj_z, in_proj_a / _b, A_log, dt_bias, the conv's v
    channels and out_proj's columns
  - the zero-centred RMSNorm weights are stored as 1 + w (input, post-attention, q / k head norms, final norm); the
    linear attention's gated norm is not zero-centred and is stored as it is
  - ssm_a = -exp(A_log)
The Q4_0 file is not all Q4_0: 172 Q4_0 matrices, the tied embedding / head Q6_K, ffn_down of layers 0-3 Q4_1, the
linear attention's out_proj (ssm_out) Q5_K, in_proj_a / _b (ssm_alpha / ssm_beta) Q8_0, the rest fp32.

  headers() / gguf_tensors()   the safetensors and GGUF tensor tables (fetched once into build/qwen3_5_4b/)
"""

import json
import os
import pathlib
import struct
import sys
import threading
import urllib.request
from concurrent.futures import ThreadPoolExecutor

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILD = ROOT / "build/qwen3_5_4b"
HF = BUILD / "hf"  # config.json and the tokenizer's files

REPO = "Qwen/Qwen3.5-4B"
REV = "851bf6e806efd8d0a36b00ddf55e13ccb7b8cd0a"
SHARDS = ["model.safetensors-00001-of-00002.safetensors", "model.safetensors-00002-of-00002.safetensors"]
GGUF_REPO = "unsloth/Qwen3.5-4B-GGUF"
GGUF_REV = "e87f176479d0855a907a41277aca2f8ee7a09523"
GGUF = "Qwen3.5-4B-Q4_0.gguf"
GGUF_SIZE = 2583221408
GGUF_SHA256 = "298fcb5fe7a77ccc79745ae24751560c5ac56874caff4bb39b1f2055bd72b8bb"
P = "model.language_model."
EMBED = P + "embed_tokens.weight"

GGML = {0: ("F32", 1, 4), 1: ("F16", 1, 2), 2: ("Q4_0", 32, 18), 3: ("Q4_1", 32, 20), 8: ("Q8_0", 32, 34),
        13: ("Q5_K", 256, 176), 14: ("Q6_K", 256, 210)}


def url(path):
    return f"https://huggingface.co/{REPO}/resolve/{REV}/{path}"


def gguf_url():
    return f"https://huggingface.co/{GGUF_REPO}/resolve/{GGUF_REV}/{GGUF}"


def _range(u, a, b, tries=8):
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(u, headers={"Range": f"bytes={a}-{b - 1}"})
            with urllib.request.urlopen(req, timeout=120) as r:
                data = r.read()
            if len(data) == b - a:
                return data
            last = f"short read {len(data)} of {b - a}"
        except Exception as e:  # noqa: BLE001 (retry any network error)
            last = e
    raise RuntimeError(f"{u} range {a}-{b}: {last}")


def fetch_hf_files():
    """config.json and the tokenizer's files into build/qwen3_5_4b/hf (small)."""
    HF.mkdir(parents=True, exist_ok=True)
    for f in ("config.json", "tokenizer.json", "tokenizer_config.json", "vocab.json", "merges.txt",
              "chat_template.jinja"):
        if not (HF / f).exists():
            with urllib.request.urlopen(url(f), timeout=300) as r:
                (HF / f).write_bytes(r.read())


def config():
    """transformers' Qwen3_5TextConfig from config.json's text_config (eager attention, fp32)."""
    from transformers.models.qwen3_5.configuration_qwen3_5 import Qwen3_5TextConfig
    fetch_hf_files()
    tc = json.loads((HF / "config.json").read_text())["text_config"]
    cfg = Qwen3_5TextConfig(**tc)
    cfg._attn_implementation = "eager"
    return cfg


def headers():
    """{name: {shard, dtype, shape, abs: (start, end)}} for the checkpoint, absolute byte offsets in each shard."""
    p = BUILD / "headers.json"
    if p.exists():
        return json.loads(p.read_text())
    out = {}
    for i, s in enumerate(SHARDS):
        n = struct.unpack("<Q", _range(url(s), 0, 8))[0]
        h = json.loads(_range(url(s), 8, 8 + n))
        for name, t in h.items():
            if name == "__metadata__":
                continue
            a, b = t["data_offsets"]
            out[name] = dict(shard=i, dtype=t["dtype"], shape=t["shape"], abs=[8 + n + a, 8 + n + b])
    BUILD.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(out, indent=0))
    return out


def gguf_tensors():
    """The GGUF's tensor table {name: {type, dims (ggml order: ne0 first), abs, nbytes}} and a few metadata values,
    from its first 24 MB (the tokenizer's metadata comes first)."""
    p = BUILD / "gguf.json"
    if p.exists():
        return json.loads(p.read_text())
    sys.path.insert(0, str(ROOT / "lfm2"))
    try:
        import gguf_read
    finally:
        sys.path.pop(0)
    buf = _range(gguf_url(), 0, 24 << 20)
    _, meta, tensors, _ = gguf_read.parse(buf)
    out = dict(meta={k: v for k, v in meta.items() if isinstance(v, (int, float, str)) and k != "tokenizer.chat_template"
                     or k == "qwen35.rope.dimension_sections"},
               tensors={t["name"]: dict(type=GGML[t["type"]][0], dims=t["dims"], abs=t["abs"],
                                        nbytes=t["nbytes"]) for t in tensors})
    end = max(t["abs"] + t["nbytes"] for t in out["tensors"].values())
    assert end == GGUF_SIZE, end
    BUILD.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(out, indent=0, default=lambda v: [int(x) for x in v]))
    return out


# ---- ggml's dequantizers (numpy, fp32, the same arithmetic as ggml's dequantize_row_*) ------------------------------

def dequant_q4_0(raw, rows, cols):
    """blocks of 32 = fp16 d, 16 bytes; element j = (lo nibble of byte j - 8) d, element j + 16 = (hi nibble - 8) d."""
    b = np.frombuffer(raw, np.uint8).reshape(-1, 18)
    d = b[:, :2].copy().view(np.float16).astype(np.float32)
    qs = b[:, 2:]
    q = np.concatenate([(qs & 15).astype(np.int8) - 8, (qs >> 4).astype(np.int8) - 8], axis=1)
    return (q.astype(np.float32) * d).reshape(rows, cols)


def dequant_q4_1(raw, rows, cols):
    """blocks of 32 = fp16 d, fp16 m, 16 bytes; element j = (lo nibble of byte j) d + m, j + 16 the hi nibble."""
    b = np.frombuffer(raw, np.uint8).reshape(-1, 20)
    d = b[:, 0:2].copy().view(np.float16).astype(np.float32)
    m = b[:, 2:4].copy().view(np.float16).astype(np.float32)
    qs = b[:, 4:]
    q = np.concatenate([qs & 15, qs >> 4], axis=1).astype(np.float32)
    return (q * d + m).reshape(rows, cols)


def dequant_q8_0(raw, rows, cols):
    b = np.frombuffer(raw, np.uint8).reshape(-1, 34)
    d = b[:, :2].copy().view(np.float16).astype(np.float32)
    q = b[:, 2:].copy().view(np.int8).astype(np.float32)
    return (q * d).reshape(rows, cols)


def q5k_scales(sc):
    """get_scale_min_k4 for j = 0..7 of each super-block: (scales, mins), uint8 [n, 8] each."""
    s = np.empty((sc.shape[0], 8), np.uint8)
    m = np.empty((sc.shape[0], 8), np.uint8)
    for j in range(8):
        if j < 4:
            s[:, j] = sc[:, j] & 63
            m[:, j] = sc[:, j + 4] & 63
        else:
            s[:, j] = (sc[:, j + 4] & 0xF) | ((sc[:, j - 4] >> 6) << 4)
            m[:, j] = (sc[:, j + 4] >> 4) | ((sc[:, j] >> 6) << 4)
    return s, m


def dequant_q5_k(raw, rows, cols):
    """super-blocks of 256 = fp16 d, fp16 dmin, scales[12], qh[32], qs[128]; sub-block j (32 weights) = d sc_j q -
    dmin m_j, q = 4 bits of qs (the low nibbles of bytes 32 (j / 2) .. for even j, the high for odd) + 16 qh bit j."""
    b = np.frombuffer(raw, np.uint8).reshape(-1, 176)
    d = b[:, 0:2].copy().view(np.float16).astype(np.float32)
    dmin = b[:, 2:4].copy().view(np.float16).astype(np.float32)
    s, m = q5k_scales(b[:, 4:16])
    qh, qs = b[:, 16:48], b[:, 48:176]
    out = np.empty((b.shape[0], 256), np.float32)
    for j in range(8):
        lo = qs[:, 32 * (j // 2):32 * (j // 2) + 32]
        lo = (lo & 15) if j % 2 == 0 else (lo >> 4)
        q = (lo + (((qh >> j) & 1) << 4)).astype(np.float32)
        d1 = d * s[:, j:j + 1].astype(np.float32)
        m1 = dmin * m[:, j:j + 1].astype(np.float32)
        out[:, 32 * j:32 * j + 32] = d1 * q - m1
    return out.reshape(rows, cols)


def dequant_q6_k(raw, rows, cols):
    """super-blocks of 256 = ql[128], qh[64], int8 scales[16], fp16 d; element e of a half (128) is 6 bits from ql and
    qh, minus 32, times d * scales[e / 16] (in that order, fp32)."""
    b = np.frombuffer(raw, np.uint8).reshape(-1, 210)
    ql, qh = b[:, :128], b[:, 128:192]
    sc = b[:, 192:208].copy().view(np.int8).astype(np.float32)
    d = b[:, 208:210].copy().view(np.float16).astype(np.float32)
    out = np.empty((b.shape[0], 256), np.float32)
    for h in range(2):
        L = ql[:, 64 * h:64 * h + 64]
        Hh = qh[:, 32 * h:32 * h + 32]
        q = np.concatenate([(L[:, :32] & 15) | (((Hh >> 0) & 3) << 4),
                            (L[:, 32:] & 15) | (((Hh >> 2) & 3) << 4),
                            (L[:, :32] >> 4) | (((Hh >> 4) & 3) << 4),
                            (L[:, 32:] >> 4) | (((Hh >> 6) & 3) << 4)], axis=1).astype(np.float32) - 32
        s = d * sc[:, 8 * h:8 * h + 8]
        out[:, 128 * h:128 * h + 128] = np.repeat(s, 16, axis=1) * q
    return out.reshape(rows, cols)


DEQUANT = {"Q4_0": dequant_q4_0, "Q4_1": dequant_q4_1, "Q8_0": dequant_q8_0, "Q5_K": dequant_q5_k,
           "Q6_K": dequant_q6_k}


# ---- the two weight sources -----------------------------------------------------------------------------------------

class _Streamed:
    """get(name) waits for a tensor, prefetch(names) starts reading tensors in the background (64 MB ranges, a few in
    parallel); subclasses define _read(name)."""

    def __init__(self, workers=6):
        self.pool = ThreadPoolExecutor(workers)
        self.pending = {}
        self.done = {}
        self.lock = threading.Lock()
        self.bytes = 0

    def _fetch(self, u, a, b):
        CH = 64 << 20
        parts = [(s, min(s + CH, b)) for s in range(a, b, CH)]
        data = b"".join(self.pool.map(lambda r: _range(u, *r), parts)) if len(parts) > 1 else _range(u, a, b)
        self.bytes += len(data)
        return data

    def _fetch_into(self, name):
        t = self._read(name)
        with self.lock:
            self.done[name] = t

    def prefetch(self, names):
        with self.lock:
            for n in names:
                if n not in self.pending:
                    self.pending[n] = threading.Thread(target=self._fetch_into, args=(n,))
                    self.pending[n].start()

    def get(self, name):
        with self.lock:
            th = self.pending.get(name)
        if th is None:
            return self._read(name)
        th.join()
        with self.lock:
            self.pending.pop(name)
            return self.done.pop(name)


class Bf16Weights(_Streamed):
    """The published checkpoint's tensors as fp32 (bf16 widened, exact), by transformers' names."""

    def __init__(self, workers=6):
        super().__init__(workers)
        self.h = headers()

    def _read(self, name):
        t = self.h[name]
        data = self._fetch(url(SHARDS[t["shard"]]), *t["abs"])
        if t["dtype"] == "F32":
            return torch.from_numpy(np.frombuffer(data, np.float32).copy()).reshape(t["shape"])
        assert t["dtype"] == "BF16", name
        u = np.frombuffer(data, np.uint16).astype(np.uint32) << 16
        return torch.from_numpy(u.view(np.float32)).reshape(t["shape"])

    def embed_rows(self, ids):
        t = self.h[EMBED]
        D = t["shape"][1]
        a = t["abs"][0]
        u_ = url(SHARDS[t["shard"]])
        rows = list(self.pool.map(lambda i: _range(u_, a + i * D * 2, a + (i + 1) * D * 2), ids))
        u = np.frombuffer(b"".join(rows), np.uint16).astype(np.uint32) << 16
        return torch.from_numpy(u.view(np.float32).copy()).reshape(len(ids), D)

    def head_rows(self, r0, r1):
        """Rows r0 .. r1 - 1 of the tied embedding / head (fp32)."""
        t = self.h[EMBED]
        D = t["shape"][1]
        data = self._fetch(url(SHARDS[t["shard"]]), t["abs"][0] + r0 * D * 2, t["abs"][0] + r1 * D * 2)
        u = np.frombuffer(data, np.uint16).astype(np.uint32) << 16
        return torch.from_numpy(u.view(np.float32)).reshape(r1 - r0, D)


NV, NK, HDV = 32, 16, 128  # linear attention: value heads, key heads, head dim
# transformers' value head h is GGUF head UNTILE[h] (GGUF head i = transformers' head 2 (i % 16) + i // 16)
UNTILE = [(h % 2) * NK + h // 2 for h in range(NV)]


def untile_rows(w, width=HDV):
    """Rows (or entries) in GGUF value-head order -> transformers' order: blocks of `width` per head."""
    return w.reshape(NV, width, *w.shape[1:])[UNTILE].reshape(w.shape)


class GGUFWeights(_Streamed):
    """The Q4_0 GGUF's tensors, dequantized as ggml does (fp32), by transformers' names and in transformers' layout."""

    def __init__(self, workers=6):
        super().__init__(workers)
        g = gguf_tensors()
        self.t = g["tensors"]
        self.meta = g["meta"]

    def raw(self, gname):
        t = self.t[gname]
        return t, self._fetch(gguf_url(), t["abs"], t["abs"] + t["nbytes"])

    def tensor(self, gname):
        """The GGUF tensor as stored, dequantized: [ne1, ne0] for a matrix (rows of its input width), flat for a vector."""
        t, data = self.raw(gname)
        if t["type"] == "F32":
            a = np.frombuffer(data, np.float32).copy()
            return a.reshape(t["dims"][::-1]) if len(t["dims"]) > 1 else a
        return DEQUANT[t["type"]](data, t["dims"][1], t["dims"][0])

    def _read(self, name):
        assert name.startswith(P), name
        n = name[len(P):]
        if n == "norm.weight":
            return torch.from_numpy(self.tensor("output_norm.weight") - 1)
        if n == "embed_tokens.weight":
            return torch.from_numpy(self.tensor("token_embd.weight"))
        parts = n.split(".")
        i, rest = int(parts[1]), ".".join(parts[2:])
        b = f"blk.{i}."
        plain = {"mlp.gate_proj.weight": "ffn_gate.weight", "mlp.up_proj.weight": "ffn_up.weight",
                 "mlp.down_proj.weight": "ffn_down.weight", "self_attn.q_proj.weight": "attn_q.weight",
                 "self_attn.k_proj.weight": "attn_k.weight", "self_attn.v_proj.weight": "attn_v.weight",
                 "self_attn.o_proj.weight": "attn_output.weight", "linear_attn.norm.weight": "ssm_norm.weight"}
        minus1 = {"input_layernorm.weight": "attn_norm.weight", "post_attention_layernorm.weight":
                  "post_attention_norm.weight", "self_attn.q_norm.weight": "attn_q_norm.weight",
                  "self_attn.k_norm.weight": "attn_k_norm.weight"}
        if rest in plain:
            w = self.tensor(b + plain[rest])
        elif rest in minus1:
            w = self.tensor(b + minus1[rest]) - 1
        elif rest == "linear_attn.in_proj_qkv.weight":
            w = self.tensor(b + "attn_qkv.weight")
            w = np.concatenate([w[:2 * NK * HDV], untile_rows(w[2 * NK * HDV:])])
        elif rest == "linear_attn.in_proj_z.weight":
            w = untile_rows(self.tensor(b + "attn_gate.weight"))
        elif rest == "linear_attn.in_proj_a.weight":
            w = untile_rows(self.tensor(b + "ssm_alpha.weight"), 1)
        elif rest == "linear_attn.in_proj_b.weight":
            w = untile_rows(self.tensor(b + "ssm_beta.weight"), 1)
        elif rest == "linear_attn.dt_bias":
            w = untile_rows(self.tensor(b + "ssm_dt.bias"), 1)
        elif rest == "linear_attn.A_log":
            w = untile_rows(np.log(-self.tensor(b + "ssm_a")), 1)
        elif rest == "linear_attn.conv1d.weight":
            w = self.tensor(b + "ssm_conv1d.weight")  # [8192 channels, 4 taps]
            w = np.concatenate([w[:2 * NK * HDV], untile_rows(w[2 * NK * HDV:])])[:, None, :]
        elif rest == "linear_attn.out_proj.weight":
            w = self.tensor(b + "ssm_out.weight")  # [2560, 4096]: columns in GGUF head order
            w = untile_rows(w.T).T
        else:
            raise KeyError(name)
        return torch.from_numpy(np.ascontiguousarray(w, np.float32))

    def embed_rows(self, ids):
        t = self.t["token_embd.weight"]
        cols, n = t["dims"]
        bpr = t["nbytes"] // n
        u = gguf_url()
        rows = list(self.pool.map(lambda i: _range(u, t["abs"] + i * bpr, t["abs"] + (i + 1) * bpr), ids))
        return torch.from_numpy(dequant_q6_k(b"".join(rows), len(ids), cols))

    def head_rows(self, r0, r1):
        """Rows r0 .. r1 - 1 of the Q6_K tied embedding / head, dequantized."""
        t = self.t["token_embd.weight"]
        cols, n = t["dims"]
        bpr = t["nbytes"] // n
        data = self._fetch(gguf_url(), t["abs"] + r0 * bpr, t["abs"] + r1 * bpr)
        return torch.from_numpy(dequant_q6_k(data, r1 - r0, cols))


def layer_names(cfg, i):
    p = f"{P}layers.{i}."
    common = ["input_layernorm.weight", "post_attention_layernorm.weight", "mlp.gate_proj.weight",
              "mlp.up_proj.weight", "mlp.down_proj.weight"]
    if cfg.layer_types[i] == "linear_attention":
        own = ["linear_attn." + n for n in ("in_proj_qkv.weight", "in_proj_z.weight", "in_proj_a.weight",
                                            "in_proj_b.weight", "conv1d.weight", "dt_bias", "A_log", "norm.weight",
                                            "out_proj.weight")]
    else:
        own = ["self_attn." + n for n in ("q_proj.weight", "k_proj.weight", "v_proj.weight", "o_proj.weight",
                                          "q_norm.weight", "k_norm.weight")]
    return [p + n for n in common + own]


if __name__ == "__main__":  # the GGUF's layer 0 and 3 against the bf16 checkpoint, after undoing llama.cpp's layout
    cfg = config()
    B, G = Bf16Weights(), GGUFWeights()
    for i in (0, 3):
        for n in layer_names(cfg, i):
            a, b = B.get(n), G.get(n)
            assert a.shape == b.shape, (n, a.shape, b.shape)
            rel = float((a - b).abs().max() / a.abs().max())
            print(f"{n[len(P):]:48s} {str(tuple(a.shape)):16s} max |gguf - bf16| / max |bf16| = {rel:.4f}")
