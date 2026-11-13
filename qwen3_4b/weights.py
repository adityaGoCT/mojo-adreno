"""Qwen3-4B's weights for the reference and the export: the bf16 checkpoint (Qwen/Qwen3-4B, three safetensors shards),
read from Hugging Face by HTTP range request when a tensor is asked for (the Mac keeps none of the 8 GB), and the same
tensors as the phone stores them (q4: ggml's Q4_0 for every projection, Q6_K for the tied embedding / head),
quantized by convert.c's own functions (loaded as a library) and dequantized as ggml does.

  headers()          every tensor's shard, offsets, dtype and shape (fetched once into build/qwen3_4b/headers.json)
  Bf16Weights()      get(name) -> the fp32 tensor (bf16 widened, exact), embed_rows(ids), prefetch(names)
  quantized(name, w) -> w as the phone holds it, dequantized (fp32)
"""

import ctypes
import importlib.util
import json
import pathlib
import subprocess
import sys
import threading
import urllib.request
from concurrent.futures import ThreadPoolExecutor

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("lfm2_weights", ROOT / "lfm2/weights.py")
_lfm2 = importlib.util.module_from_spec(_spec)
_path = list(sys.path)
_spec.loader.exec_module(_lfm2)
sys.path[:] = _path  # (lfm2/weights.py puts lfm2/ first on the path: its run.py would shadow ours)
dequant_q4_0, dequant_q6_k = _lfm2.dequant_q4_0, _lfm2.dequant_q6_k  # ggml's dequantizers (lfm2/weights.py)

REPO = "Qwen/Qwen3-4B"
REV = "1cfa9a7208912126459214e8b04321603b3df60c"
SHARDS = [f"model-0000{i}-of-00003.safetensors" for i in (1, 2, 3)]
BUILD = ROOT / "build/qwen3_4b"
HF = BUILD / "hf"  # config.json, the tokenizer's files


def url(path):
    return f"https://huggingface.co/{REPO}/resolve/{REV}/{path}"


def config():
    from transformers import Qwen3Config
    cfg = Qwen3Config(**json.loads((HF / "config.json").read_text()))
    cfg._attn_implementation = "eager"
    return cfg


def _range(path, a, b, tries=8):
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(url(path), headers={"Range": f"bytes={a}-{b - 1}"})
            with urllib.request.urlopen(req, timeout=120) as r:
                data = r.read()
            if len(data) == b - a:
                return data
            last = f"short read {len(data)} of {b - a}"
        except Exception as e:  # noqa: BLE001 (retry any network error)
            last = e
    raise RuntimeError(f"{path} range {a}-{b}: {last}")


def headers():
    """{name: {shard, dtype, shape, abs: (start, end)}} with absolute byte offsets in the shard file."""
    p = BUILD / "headers.json"
    if p.exists():
        return json.loads(p.read_text())
    out = {}
    for i, s in enumerate(SHARDS):
        n = int(np.frombuffer(_range(s, 0, 8), np.uint64)[0])
        h = json.loads(_range(s, 8, 8 + n))
        for name, t in h.items():
            if name == "__metadata__":
                continue
            a, b = t["data_offsets"]
            out[name] = dict(shard=i, dtype=t["dtype"], shape=t["shape"], abs=[8 + n + a, 8 + n + b])
    BUILD.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(out, indent=0))
    return out


class Bf16Weights:
    """The checkpoint's tensors as fp32, each read from Hugging Face when asked for (64 MB ranges, a few in parallel);
    prefetch() starts reading a list of tensors in the background, get() waits for one."""

    def __init__(self, workers=6):
        self.h = headers()
        self.pool = ThreadPoolExecutor(workers)
        self.pending = {}
        self.done = {}
        self.lock = threading.Lock()
        self.bytes = 0

    def _read(self, name):
        t = self.h[name]
        assert t["dtype"] == "BF16", name
        a, b = t["abs"]
        CH = 64 << 20
        path = SHARDS[t["shard"]]
        parts = [(s, min(s + CH, b)) for s in range(a, b, CH)]
        data = b"".join(self.pool.map(lambda r: _range(path, *r), parts)) if len(parts) > 1 else _range(path, a, b)
        self.bytes += len(data)
        u = np.frombuffer(data, np.uint16).astype(np.uint32) << 16
        return torch.from_numpy(u.view(np.float32)).reshape(t["shape"])

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

    def embed_rows(self, ids):
        t = self.h["model.embed_tokens.weight"]
        D = t["shape"][1]
        a = t["abs"][0]
        path = SHARDS[t["shard"]]
        rows = list(self.pool.map(lambda i: _range(path, a + i * D * 2, a + (i + 1) * D * 2), ids))
        u = np.frombuffer(b"".join(rows), np.uint16).astype(np.uint32) << 16
        return torch.from_numpy(u.view(np.float32).copy()).reshape(len(ids), D)


_lib = None


def lib():
    """convert.c as a macOS library (built here when missing or older than the source)."""
    global _lib
    if _lib is None:
        src = ROOT / "qwen3_4b/convert.c"
        so = BUILD / "libq4bquant.dylib"
        if not so.exists() or so.stat().st_mtime < src.stat().st_mtime:
            BUILD.mkdir(parents=True, exist_ok=True)
            subprocess.run(["cc", "-O2", "-ffp-contract=off", "-shared", "-fPIC", "-o", str(so), str(src)], check=True)
        _lib = ctypes.CDLL(str(so))
        for f in (_lib.q4b_q4_0, _lib.q4b_q6_k):
            f.argtypes = [ctypes.c_void_p, ctypes.c_longlong, ctypes.c_void_p]
            f.restype = None
    return _lib


def quant_blocks(w, kind, threads=8):
    """w (fp32, rows of a multiple of 32 / 256) -> ggml's Q4_0 or Q6_K blocks (bytes), rows split across threads."""
    x = np.ascontiguousarray(w.numpy() if isinstance(w, torch.Tensor) else w, np.float32)
    rows, cols = x.shape
    bs, bb = (32, 18) if kind == "q4" else (256, 210)
    out = np.empty(rows * (cols // bs) * bb, np.uint8)
    f = lib().q4b_q4_0 if kind == "q4" else lib().q4b_q6_k
    rb = (cols // bs) * bb

    def part(r0, r1):
        f(x[r0:r1].ctypes.data, (r1 - r0) * cols, out[r0 * rb:r1 * rb].ctypes.data)

    step = -(-rows // threads)
    with ThreadPoolExecutor(threads) as ex:
        list(ex.map(lambda r: part(r, min(rows, r + step)), range(0, rows, step)))
    return out.tobytes()


def quantized(name, w):
    """The tensor `name` as the phone's q4 storage holds it, dequantized as ggml does (fp32): Q6_K for the tied
    embedding / head, Q4_0 for every other matrix, the norms as they are."""
    if w.dim() == 1:
        return w
    rows, cols = w.shape
    if name == "model.embed_tokens.weight":
        return torch.from_numpy(dequant_q6_k(quant_blocks(w, "q6"), rows, cols))
    return torch.from_numpy(dequant_q4_0(quant_blocks(w, "q4"), rows, cols))


def layer_names(i):
    p = f"model.layers.{i}."
    return [p + n for n in ("input_layernorm.weight", "post_attention_layernorm.weight", "self_attn.q_proj.weight",
                            "self_attn.k_proj.weight", "self_attn.v_proj.weight", "self_attn.o_proj.weight",
                            "self_attn.q_norm.weight", "self_attn.k_norm.weight", "mlp.gate_proj.weight",
                            "mlp.up_proj.weight", "mlp.down_proj.weight")]
