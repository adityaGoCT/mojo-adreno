"""LFM2.5-2.6B's weights for the reference and the exports: the GPU's QAD Q4_0 GGUF (dequantized exactly as ggml
does) or the QAD fp32 source checkpoint (qad/model.safetensors), both by transformers' tensor names.

The fp32 checkpoint is 10.8 GB and the Mac has less disk than that free, so Fp32Weights reads each tensor from Hugging
Face by HTTP range request when it is asked for, a few in parallel, and keeps nothing on disk.
"""

import json
import pathlib
import sys
import threading
import urllib.request
from concurrent.futures import ThreadPoolExecutor

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2"))
import gguf_read  # noqa: E402

REPO = "LiquidAI/LFM2.5-2.6B-GGUF"
REV = "e7caca5d835a3901a8e0d63e94009429bafafdfc"
GGUF = "LFM2.5-2.6B-QAD-Q4_0.gguf"
GGUF_SHA256 = "a247afd6414918eac8e520a9e6137dc271235461ecbe1180462221d5b8d40b03"
BUILD = ROOT / "build/lfm2"


def url(path):
    return f"https://huggingface.co/{REPO}/resolve/{REV}/{path}"


def config():
    """qad/config.json as transformers' Lfm2Config."""
    from transformers import Lfm2Config
    return Lfm2Config(**json.loads((BUILD / "config.json").read_text()))


def hf_to_gguf(name):
    """transformers' tensor name -> the GGUF's (llama.cpp's LFM2 names)."""
    if name == "model.embed_tokens.weight":
        return "token_embd.weight"
    if name == "model.embedding_norm.weight":
        return "token_embd_norm.weight"
    p = name.split(".")
    assert p[0] == "model" and p[1] == "layers", name
    i, rest = p[2], ".".join(p[3:])
    m = {"operator_norm.weight": "attn_norm.weight", "ffn_norm.weight": "ffn_norm.weight",
         "feed_forward.w1.weight": "ffn_gate.weight", "feed_forward.w3.weight": "ffn_up.weight",
         "feed_forward.w2.weight": "ffn_down.weight", "conv.conv.weight": "shortconv.conv.weight",
         "conv.in_proj.weight": "shortconv.in_proj.weight", "conv.out_proj.weight": "shortconv.out_proj.weight",
         "self_attn.q_proj.weight": "attn_q.weight", "self_attn.k_proj.weight": "attn_k.weight",
         "self_attn.v_proj.weight": "attn_v.weight", "self_attn.out_proj.weight": "attn_output.weight",
         "self_attn.q_layernorm.weight": "attn_q_norm.weight",
         "self_attn.k_layernorm.weight": "attn_k_norm.weight"}[rest]
    return f"blk.{i}.{m}"


def dequant_q4_0(raw, rows, cols):
    """ggml's dequantize_row_q4_0: blocks of 32 = fp16 d, 16 bytes; element j = (lo nibble of byte j - 8) d,
    element j + 16 = (hi nibble - 8) d (an exact fp32 product)."""
    b = np.frombuffer(raw, np.uint8).reshape(-1, 18)
    d = b[:, :2].copy().view(np.float16).astype(np.float32)
    qs = b[:, 2:]
    q = np.concatenate([(qs & 15).astype(np.int8) - 8, (qs >> 4).astype(np.int8) - 8], axis=1)
    return (q.astype(np.float32) * d).reshape(rows, cols)


def dequant_q6_k(raw, rows, cols):
    """ggml's dequantize_row_q6_K: super-blocks of 256 = ql[128], qh[64], int8 scales[16], fp16 d; element e of a
    half (128) is 6 bits from ql and qh, minus 32, times d * scales[e / 16] (in that order, fp32)."""
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
        s = d * sc[:, 8 * h:8 * h + 8]  # d * scale, a scale per 16
        out[:, 128 * h:128 * h + 128] = np.repeat(s, 16, axis=1) * q
    return out.reshape(rows, cols)


class GGUFWeights:
    """The QAD Q4_0 GGUF's tensors, dequantized to fp32, by transformers' names and shapes. round16: every matrix (and
    the embedding) rounded to fp16, as the f16 storage holds them; the norms and conv taps stay fp32."""

    def __init__(self, path=None, round16=False):
        self.round16 = round16
        self.path = pathlib.Path(path or BUILD / GGUF)
        self.mm = np.memmap(self.path, np.uint8, "r")
        _, self.meta, tensors, _ = gguf_read.parse(memoryview(self.mm[:16 << 20]))
        self.t = {t["name"]: t for t in tensors}

    def raw(self, gname):
        t = self.t[gname]
        return t, bytes(self.mm[t["abs"]:t["abs"] + t["nbytes"]])

    def rows_of(self, gname, ids):
        """Rows `ids` of a quantized [rows, cols] tensor (the embedding), dequantized."""
        t = self.t[gname]
        cols, n = t["dims"][0], t["dims"][1]
        bpr = t["nbytes"] // n
        out = []
        for i in ids:
            raw = bytes(self.mm[t["abs"] + i * bpr:t["abs"] + (i + 1) * bpr])
            out.append(self.deq(t, raw, 1, cols))
        r = np.concatenate(out)
        return torch.from_numpy(r.astype(np.float16).astype(np.float32) if self.round16 else r)

    @staticmethod
    def deq(t, raw, rows, cols):
        if t["tname"] == "Q4_0":
            return dequant_q4_0(raw, rows, cols)
        if t["tname"] == "Q6_K":
            return dequant_q6_k(raw, rows, cols)
        if t["tname"] == "F32":
            return np.frombuffer(raw, np.float32).reshape(rows, cols).copy()
        raise ValueError(t["tname"])

    def get(self, name):
        t, raw = self.raw(hf_to_gguf(name))
        dims = t["dims"]
        if len(dims) == 1:
            return torch.from_numpy(np.frombuffer(raw, np.float32).copy())
        cols, rows = dims[0], int(np.prod(dims[1:]))
        w = self.deq(t, raw, rows, cols)
        if self.round16 and t["tname"] != "F32":
            w = w.astype(np.float16).astype(np.float32)
        w = torch.from_numpy(w)
        if name.endswith("conv.conv.weight"):  # GGUF [3, 2048] (ne0 = 3 taps) -> Conv1d [2048, 1, 3]
            return w.reshape(rows, 1, cols)
        return w

    def embed_rows(self, ids):
        return self.rows_of("token_embd.weight", ids)


class Fp32Weights:
    """qad/model.safetensors' fp32 tensors, read from Hugging Face by range request (nothing kept on disk). prefetch()
    starts reading a list of tensors in the background; get() waits for one."""

    def __init__(self, workers=6):
        self.header = json.loads((BUILD / "qad_header.json").read_text())
        self.base = 8 + int(np.frombuffer((BUILD / "hlen.bin").read_bytes(), np.uint64)[0])
        self.pool = ThreadPoolExecutor(workers)
        self.pending = {}
        self.lock = threading.Lock()
        self.done = {}
        self.bytes = 0

    def _range(self, a, b, tries=6):
        last = None
        for _ in range(tries):
            try:
                req = urllib.request.Request(url("qad/model.safetensors"), headers={"Range": f"bytes={a}-{b - 1}"})
                with urllib.request.urlopen(req, timeout=120) as r:
                    data = r.read()
                if len(data) == b - a:
                    return data
                last = f"short read {len(data)} of {b - a}"
            except Exception as e:  # noqa: BLE001 (retry any network error)
                last = e
        raise RuntimeError(f"range {a}-{b}: {last}")

    def _read(self, name):
        h = self.header[name]
        assert h["dtype"] == "F32"
        a, b = h["data_offsets"]
        CH = 64 << 20
        parts = [(self.base + s, self.base + min(s + CH, b)) for s in range(a, b, CH)]
        data = b"".join(self.pool.map(lambda r: self._range(*r), parts)) if len(parts) > 1 else self._range(*parts[0])
        self.bytes += len(data)
        return torch.from_numpy(np.frombuffer(data, np.float32).copy()).reshape(h["shape"])

    def prefetch(self, names):
        with self.lock:
            for n in names:
                if n not in self.pending:
                    self.pending[n] = threading.Thread(target=self._fetch_into, args=(n,))
                    self.pending[n].start()

    def _fetch_into(self, name):
        t = self._read(name)
        with self.lock:
            self.done[name] = t

    def get(self, name):
        with self.lock:
            th = self.pending.get(name)
        if th is None:
            return self._read(name)
        th.join()
        with self.lock:
            self.pending.pop(name)
            return self.done.pop(name)

    def embed_rows(self, ids):
        h = self.header["model.embed_tokens.weight"]
        D = h["shape"][1]
        a = h["data_offsets"][0]
        rows = list(self.pool.map(lambda i: self._range(self.base + a + i * D * 4, self.base + a + (i + 1) * D * 4),
                                  ids))
        return torch.from_numpy(np.frombuffer(b"".join(rows), np.float32).copy()).reshape(len(ids), D)


def layer_names(cfg, i):
    p = f"model.layers.{i}."
    names = [p + "operator_norm.weight", p + "ffn_norm.weight", p + "feed_forward.w1.weight",
             p + "feed_forward.w2.weight", p + "feed_forward.w3.weight"]
    if cfg.layer_types[i] == "full_attention":
        names += [p + f"self_attn.{n}.weight" for n in ("q_proj", "k_proj", "v_proj", "out_proj", "q_layernorm",
                                                         "k_layernorm")]
    else:
        names += [p + "conv.conv.weight", p + "conv.in_proj.weight", p + "conv.out_proj.weight"]
    return names
