"""LFM2-MoE weights (LFM2.5-8B-A1B, LFM2.5-24B-A2B) for the reference and the exports, by transformers' tensor names
and shapes (Lfm2MoeDecoderLayer's state dict: experts fused as gate_up_proj [E, 2I, D] and down_proj [E, D, I]).

  GGUFWeights  the device's 4-bit GGUF (8B: Q4_0; 24B: the QAD Q4_0 build), every Q4_0 and Q6_K tensor dequantized
               exactly as ggml does; the f32 tensors as stored. A local file (LFM2MOE_GGUF) or, by default, read from
               Hugging Face by range request a layer at a time: the Mac has less free disk than either file.
  BF16Weights  the bf16 source checkpoint the GGUF was made from, by range request too.

LFM2MOE=8b (default) or 24b picks the model; its config, tokenizer and headers live in build/lfm2moe/<model>/.
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
sys.path.append(str(ROOT / "lfm2"))  # gguf_read (after lfm2moe/: lfm2 has its own weights, reference)
import gguf_read  # noqa: E402


def _lfm2_weights():
    """lfm2/weights.py (ggml's dequantizers), loaded by path: this module has the same name."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("lfm2_weights", ROOT / "lfm2/weights.py")
    mod = importlib.util.module_from_spec(spec)
    saved = list(sys.path)
    spec.loader.exec_module(mod)
    sys.path[:] = saved  # it puts lfm2/ first (lfm2 has its own weights and reference modules)
    return mod


_L = _lfm2_weights()
dequant_q4_0, dequant_q6_k = _L.dequant_q4_0, _L.dequant_q6_k

MODELS = {
    "8b": dict(gguf_repo="LiquidAI/LFM2.5-8B-A1B-GGUF", gguf_rev="49c14831707011e64d70b2ebd8462ba08d608434",
               gguf="LFM2.5-8B-A1B-Q4_0.gguf", repo="LiquidAI/LFM2.5-8B-A1B",
               rev="dd83f5cb02aa2938b66bba9a9998d38d0517c1f3"),
    "24b": dict(gguf_repo="LiquidAI/LFM2.5-24B-A2B-GGUF", gguf_rev="7be3a8c77b010e612c42089d0dc082962cecb3a6",
                gguf="LFM2.5-24B-A2B-QAD-Q4_0.gguf", repo="LiquidAI/LFM2.5-24B-A2B",
                rev="3dc4cd09c9a2a99e1e819693e79d3aba5e9bb4f2"),
}
MODEL = os.environ.get("LFM2MOE", "8b")
M = MODELS[MODEL]
BUILD = ROOT / "build/lfm2moe" / MODEL


def hf_url(repo, rev, path):
    return f"https://huggingface.co/{repo}/resolve/{rev}/{path}"


GGUF_URL = hf_url(M["gguf_repo"], M["gguf_rev"], M["gguf"])


def config():
    """The checkpoint's config.json as transformers' Lfm2MoeConfig."""
    from transformers import Lfm2MoeConfig
    return Lfm2MoeConfig(**json.loads((BUILD / "config.json").read_text()))


class Remote:
    """Byte ranges of one Hugging Face file, split into chunks fetched in parallel, with retries."""

    def __init__(self, url, workers=8, chunk=16 << 20):
        self.url, self.chunk = url, chunk
        self.pool = ThreadPoolExecutor(workers)
        self.sem = threading.Semaphore(workers)  # requests in flight, also from prefetch threads
        self.bytes = 0

    def _one(self, a, b, tries=8):
        with self.sem:
            return self._try(a, b, tries)

    def _try(self, a, b, tries):
        last = None
        for _ in range(tries):
            try:
                req = urllib.request.Request(self.url, headers={"Range": f"bytes={a}-{b - 1}"})
                with urllib.request.urlopen(req, timeout=120) as r:
                    data = r.read()
                if len(data) == b - a:
                    return data
                last = f"short read {len(data)} of {b - a}"
            except Exception as e:  # noqa: BLE001 (retry any network error)
                last = e
        raise RuntimeError(f"{self.url} {a}-{b}: {last}")

    def read(self, a, b):
        parts = [(s, min(s + self.chunk, b)) for s in range(a, b, self.chunk)]
        data = b"".join(self.pool.map(lambda r: self._one(*r), parts)) if len(parts) > 1 else self._one(a, b)
        self.bytes += len(data)
        return data


class Local:
    def __init__(self, path):
        self.mm = np.memmap(path, np.uint8, "r")
        self.bytes = 0

    def read(self, a, b):
        self.bytes += b - a
        return bytes(self.mm[a:b])


class Prefetcher:
    """prefetch(keys) starts fetching raw items in background threads; take(key) waits for one (or fetches it)."""

    def __init__(self, fetch):
        self.fetch = fetch
        self.lock = threading.Lock()
        self.threads, self.done = {}, {}

    def prefetch(self, keys):
        with self.lock:
            for k in keys:
                if k not in self.threads and k not in self.done:
                    self.threads[k] = threading.Thread(target=self._run, args=(k,), daemon=True)
                    self.threads[k].start()

    def _run(self, k):
        v = self.fetch(k)
        with self.lock:
            self.done[k] = v

    def take(self, k):
        with self.lock:
            th = self.threads.pop(k, None)
        if th is None:
            with self.lock:
                if k in self.done:
                    return self.done.pop(k)
            return self.fetch(k)
        th.join()
        with self.lock:
            return self.done.pop(k)


LAYER_GGUF = {"operator_norm.weight": "attn_norm.weight", "ffn_norm.weight": "ffn_norm.weight",
              "feed_forward.w1.weight": "ffn_gate.weight", "feed_forward.w3.weight": "ffn_up.weight",
              "feed_forward.w2.weight": "ffn_down.weight", "conv.conv.weight": "shortconv.conv.weight",
              "conv.in_proj.weight": "shortconv.in_proj.weight", "conv.out_proj.weight": "shortconv.out_proj.weight",
              "self_attn.q_proj.weight": "attn_q.weight", "self_attn.k_proj.weight": "attn_k.weight",
              "self_attn.v_proj.weight": "attn_v.weight", "self_attn.out_proj.weight": "attn_output.weight",
              "self_attn.q_layernorm.weight": "attn_q_norm.weight",
              "self_attn.k_layernorm.weight": "attn_k_norm.weight",
              "feed_forward.gate.weight": "ffn_gate_inp.weight", "feed_forward.expert_bias": "exp_probs_b.bias",
              "feed_forward.experts.gate_up_proj": ("ffn_gate_exps.weight", "ffn_up_exps.weight"),
              "feed_forward.experts.down_proj": ("ffn_down_exps.weight",)}


def hf_to_gguf(name):
    """transformers' tensor name -> the GGUF's tensor names (llama.cpp's lfm2moe names), a tuple."""
    if name == "model.embed_tokens.weight":
        return ("token_embd.weight",)
    if name == "model.embedding_norm.weight":
        return ("token_embd_norm.weight",)
    p = name.split(".")
    assert p[0] == "model" and p[1] == "layers", name
    m = LAYER_GGUF[".".join(p[3:])]
    return tuple(f"blk.{p[2]}.{g}" for g in (m if isinstance(m, tuple) else (m,)))


def layer_names(cfg, i):
    """Lfm2MoeDecoderLayer i's state-dict names, prefixed as in the checkpoint."""
    from transformers.models.lfm2_moe.modeling_lfm2_moe import Lfm2MoeDecoderLayer
    with torch.device("meta"):
        layer = Lfm2MoeDecoderLayer(cfg, i)
    return [f"model.layers.{i}.{k}" for k in layer.state_dict()]


class GGUFWeights:
    """The 4-bit GGUF's tensors, dequantized to fp32, by transformers' names and shapes."""

    def __init__(self, path=None):
        path = path or os.environ.get("LFM2MOE_GGUF")
        self.src = Local(path) if path else Remote(GGUF_URL)
        head = BUILD / "gguf_head.bin"
        if not head.exists():
            head.write_bytes(Remote(GGUF_URL).read(0, 16 << 20))
        _, self.meta, tensors, _ = gguf_read.parse(head.read_bytes())
        self.t = {t["name"]: t for t in tensors}
        self.pf = Prefetcher(self._raw)

    def _raw(self, gname):
        t = self.t[gname]
        return self.src.read(t["abs"], t["abs"] + t["nbytes"])

    def prefetch(self, names):
        self.pf.prefetch([g for n in names for g in hf_to_gguf(n)])

    @staticmethod
    def deq(t, raw, rows, cols):
        if t["tname"] == "Q4_0":
            return dequant_q4_0(raw, rows, cols)
        if t["tname"] == "Q6_K":
            return dequant_q6_k(raw, rows, cols)
        if t["tname"] == "F32":
            return np.frombuffer(raw, np.float32).reshape(rows, cols).copy()
        raise ValueError(t["tname"])

    def _tensor(self, gname):
        t, raw = self.t[gname], self.pf.take(gname)
        dims = t["dims"]  # ggml order: ne0 (columns) first
        if len(dims) == 1:
            return torch.from_numpy(np.frombuffer(raw, np.float32).copy())
        cols, rows = dims[0], int(np.prod(dims[1:]))
        w = torch.from_numpy(self.deq(t, raw, rows, cols))
        return w.reshape(*reversed(dims[1:]), cols)  # [E, rows, cols] for the experts

    def get(self, name):
        parts = [self._tensor(g) for g in hf_to_gguf(name)]
        w = torch.cat(parts, dim=1) if len(parts) > 1 else parts[0]  # gate_up_proj: gate rows, then up rows
        if name.endswith("conv.conv.weight"):  # GGUF [3, D] (ne0 = 3 taps) -> Conv1d [D, 1, 3]
            return w.reshape(w.shape[0], 1, w.shape[1])
        return w

    def embed_rows(self, ids):
        """Rows `ids` of the (Q6_K) embedding, dequantized."""
        t = self.t["token_embd.weight"]
        cols, n = t["dims"][0], t["dims"][1]
        bpr = t["nbytes"] // n
        raws = list(ThreadPoolExecutor(8).map(
            lambda i: self.src.read(t["abs"] + i * bpr, t["abs"] + (i + 1) * bpr), ids))
        return torch.from_numpy(np.concatenate([self.deq(t, r, 1, cols) for r in raws]))

    def head(self):
        return self.get("model.embed_tokens.weight")


class BF16Weights:
    """The bf16 source checkpoint (model.safetensors or its shards), by range request, as fp32."""

    def __init__(self):
        idx = BUILD / "model.safetensors.index.json"
        self.files = (json.loads(idx.read_text())["weight_map"] if idx.exists() else None)
        self.remotes, self.headers = {}, {}
        self.pf = Prefetcher(self._read)

    def _file(self, name):
        return self.files[name] if self.files else "model.safetensors"

    def _header(self, f):
        if f not in self.headers:
            r = self.remotes.setdefault(f, Remote(hf_url(M["repo"], M["rev"], f)))
            n = struct.unpack("<Q", r.read(0, 8))[0]
            self.headers[f] = (8 + n, json.loads(r.read(8, 8 + n)))
        return self.headers[f]

    def _read(self, name):
        f = self._file(name)
        base, h = self._header(f)
        e = h[name]
        a, b = e["data_offsets"]
        raw = self.remotes[f].read(base + a, base + b)
        if e["dtype"] == "BF16":
            x = np.frombuffer(raw, np.uint16).astype(np.uint32) << 16
            return torch.from_numpy(x.view(np.float32)).reshape(e["shape"])
        assert e["dtype"] == "F32", e["dtype"]
        return torch.from_numpy(np.frombuffer(raw, np.float32).copy()).reshape(e["shape"])

    def _sources(self, name):
        """The checkpoint's tensors that make transformers' tensor `name` (experts are stored one by one)."""
        if name.endswith("experts.gate_up_proj") or name.endswith("experts.down_proj"):
            p = name.rsplit(".", 1)[0]
            E = config().num_experts
            ws = ("w1", "w3") if name.endswith("gate_up_proj") else ("w2",)
            return [[f"{p}.{e}.{w}.weight" for w in ws] for e in range(E)]
        return name

    def prefetch(self, names):
        keys = []
        for n in names:
            s = self._sources(n)
            keys += [k for grp in s for k in grp] if isinstance(s, list) else [s]
        self.pf.prefetch(keys)

    def get(self, name):
        s = self._sources(name)
        if isinstance(s, list):
            return torch.stack([torch.cat([self.pf.take(k) for k in grp], dim=0) for grp in s])
        return self.pf.take(s)

    def embed_rows(self, ids):
        f = self._file("model.embed_tokens.weight")
        base, h = self._header(f)
        e = h["model.embed_tokens.weight"]
        D = e["shape"][1]
        a = base + e["data_offsets"][0]
        r = self.remotes[f]
        raws = list(r.pool.map(lambda i: r._one(a + i * D * 2, a + (i + 1) * D * 2), ids))
        x = np.frombuffer(b"".join(raws), np.uint16).astype(np.uint32) << 16
        return torch.from_numpy(x.view(np.float32)).reshape(len(ids), D)

    def head(self):
        return self.get("model.embed_tokens.weight")
