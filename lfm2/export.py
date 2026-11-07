"""The device's weight files for LFM2.5-2.6B, laid out from the QAD Q4_0 GGUF's header: recipe.txt for convert.c (which
writes the files on the phone from the GGUF the phone downloads), manifest.txt for the Mojo program, and the RoPE table.

Two storages, each a file of its own, both from the same GGUF:
  q4   (lfm2_q4.bin, 1.5 GB) the GGUF's own numbers: every Q4_0 matrix as int4 words (8 a uint32, 4-bit two's
       complement, low nibble first: llama/kernels' gemv_q4 storage) and its fp16 scales (one per 32, unchanged);
       the Q6_K token embedding / tied head repacked to 4-byte-aligned super-blocks (ql, qh, scales; d apart), unchanged
  f16  (lfm2_f16.bin, 5.4 GB) every matrix dequantized to fp16, the embedding too; for the GPU baseline and the NPU
  npu  (npu_w8.bin, 3.4 GB) every matrix and the head as int8 per output channel with an fp32 scale (from the GGUF's
       numbers, max |w| / 127 a row), but the MLPs' down projections in fp16 (their inputs' outliers make uint16
       activations too coarse): the NPU's w8a16 graphs' weights (export_npu.py points them here)
All keep the norms and the conv taps in fp32 as stored. In each layer, q|k|v and w1|w3 (gate|up) are one matrix.

  build/vla/venv/bin/python lfm2/export.py          # build/lfm2/{q4,f16}/recipe.txt, manifest.txt; build/lfm2/rope.f32
"""

import pathlib
import sys

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2"))
from weights import BUILD, GGUF, GGUFWeights, config  # noqa: E402

CAP = 2048  # positions the KV cache and the RoPE table hold
ALIGN = 4096


def rope_table(cfg, cap=CAP):
    """transformers' Lfm2RotaryEmbedding in fp32: row p = cos | sin of the head's first half (32 + 32)."""
    from transformers.models.lfm2.modeling_lfm2 import Lfm2RotaryEmbedding
    rot = Lfm2RotaryEmbedding(cfg)
    x = torch.zeros(1, cap, cfg.hidden_size)
    cos, sin = rot(x, torch.arange(cap)[None])
    hd = cos.shape[-1]
    assert torch.equal(cos[..., :hd // 2], cos[..., hd // 2:])
    return torch.cat([cos[0, :, :hd // 2], sin[0, :, :hd // 2]], dim=1).numpy().astype(np.float32)


class Layout:
    def __init__(self, storage):
        self.storage = storage
        self.off = 0
        self.recipe = []
        self.manifest = []

    def alloc(self, nbytes):
        o = self.off
        self.off = (self.off + nbytes + ALIGN - 1) // ALIGN * ALIGN
        return o

    def matrix(self, name, parts, cols):
        """Rows of the GGUF tensors `parts` (in order) as one matrix `name`."""
        rows = sum(p["dims"][1] for p in parts)
        if self.storage == "npu" and name.endswith(".down"):
            h = self.alloc(rows * cols * 2)
            self.recipe.append(f"h4 {parts[0]['abs']} {rows} {cols} {h}")
            self.manifest.append(f"{name}.h {h} {rows * cols * 2} f16 {rows}x{cols}")
        elif self.storage == "npu":
            q = self.alloc(rows * cols)
            c = self.alloc(rows * 4)
            r0 = 0
            for p in parts:
                n = p["dims"][1]
                bs = {"Q4_0": 32, "Q6_K": 256}[p["tname"]]
                self.recipe.append(f"c8 {p['abs']} {n} {cols} {q + r0 * cols} {c + r0 * 4} {bs}")
                r0 += n
            self.manifest.append(f"{name}.q {q} {rows * cols} i8 {rows}x{cols}")
            self.manifest.append(f"{name}.c {c} {rows * 4} f32 {rows}")
        elif self.storage == "q4":
            assert all(p["tname"] == "Q4_0" for p in parts), name
            q = self.alloc(rows * cols // 2)
            s = self.alloc(rows * cols // 32 * 2)
            r0 = 0
            for p in parts:
                n = p["dims"][1]
                self.recipe.append(f"q4 {p['abs']} {n} {cols} {q + r0 * cols // 2} {s + r0 * cols // 16}")
                r0 += n
            self.manifest.append(f"{name}.q {q} {rows * cols // 2} u32 {rows}x{cols // 8}")
            self.manifest.append(f"{name}.s {s} {rows * cols // 16} f16 {rows}x{cols // 32}")
        else:
            h = self.alloc(rows * cols * 2)
            r0 = 0
            for p in parts:
                n = p["dims"][1]
                op = {"Q4_0": "h4", "Q6_K": "h6"}[p["tname"]]
                self.recipe.append(f"{op} {p['abs']} {n} {cols} {h + r0 * cols * 2}")
                r0 += n
            self.manifest.append(f"{name}.h {h} {rows * cols * 2} f16 {rows}x{cols}")

    def embed(self, t):
        cols, rows = t["dims"]
        if self.storage == "npu":  # the head (the input rows come from the GGUF's Q6_K, exactly)
            self.matrix("head", [t], cols)
        elif self.storage == "q4":
            assert t["tname"] == "Q6_K"
            nb = cols // 256
            q = self.alloc(rows * nb * 208)
            d = self.alloc(rows * nb * 2)
            self.recipe.append(f"q6 {t['abs']} {rows} {cols} {q} {d}")
            self.manifest.append(f"embed.q {q} {rows * nb * 208} u32 {rows}x{nb * 52}")
            self.manifest.append(f"embed.d {d} {rows * nb * 2} f16 {rows}x{nb}")
        else:
            self.matrix("embed", [t], cols)

    def f32(self, name, t):
        n = int(np.prod(t["dims"]))
        o = self.alloc(n * 4)
        self.recipe.append(f"f32 {t['abs']} {n} {o}")
        self.manifest.append(f"{name} {o} {n * 4} f32 {'x'.join(str(d) for d in reversed(t['dims']))}")


def main():
    cfg = config()
    g = GGUFWeights()
    t = g.t
    D, F = cfg.hidden_size, cfg.intermediate_size
    hd = D // cfg.num_attention_heads
    for storage in ("q4", "f16", "npu"):
        lay = Layout(storage)
        lay.embed(t["token_embd.weight"])
        lay.f32("final_norm", t["token_embd_norm.weight"])
        layers = []
        for i in range(cfg.num_hidden_layers):
            b = f"blk.{i}."
            n = f"l{i}."
            attn = cfg.layer_types[i] == "full_attention"
            layers.append(f"layer {i} {'attn' if attn else 'conv'}")
            lay.f32(n + "in_norm", t[b + "attn_norm.weight"])
            lay.f32(n + "ffn_norm", t[b + "ffn_norm.weight"])
            if attn:
                lay.matrix(n + "qkv", [t[b + "attn_q.weight"], t[b + "attn_k.weight"], t[b + "attn_v.weight"]], D)
                lay.matrix(n + "o", [t[b + "attn_output.weight"]], D)
                lay.f32(n + "q_norm", t[b + "attn_q_norm.weight"])
                lay.f32(n + "k_norm", t[b + "attn_k_norm.weight"])
            else:
                lay.matrix(n + "in", [t[b + "shortconv.in_proj.weight"]], D)
                lay.matrix(n + "out", [t[b + "shortconv.out_proj.weight"]], D)
                lay.f32(n + "conv", t[b + "shortconv.conv.weight"])
            lay.matrix(n + "gu", [t[b + "ffn_gate.weight"], t[b + "ffn_up.weight"]], D)
            lay.matrix(n + "down", [t[b + "ffn_down.weight"]], F)
        if storage == "npu":  # the NPU driver reads the prompt's embedding rows from the GGUF's Q6_K
            e = t["token_embd.weight"]
            lay.manifest.append(f"embed_q6k {e['abs']} {e['nbytes']} q6k {e['dims'][1]}x{e['dims'][0]}")
        out = BUILD / storage
        out.mkdir(parents=True, exist_ok=True)
        (out / "recipe.txt").write_text(f"size {lay.off}\n" + "\n".join(lay.recipe) + "\n")
        head = (f"lfm2 v1 D {D} L {cfg.num_hidden_layers} H {cfg.num_attention_heads} KVH {cfg.num_key_value_heads} "
                f"HD {hd} F {F} V {cfg.vocab_size} CAP {CAP} EPS {cfg.norm_eps} STORAGE {storage} "
                f"GGUF {GGUF}")
        (out / "manifest.txt").write_text(head + "\n" + "\n".join(layers + lay.manifest) + "\n")
        print(f"{storage}: {lay.off / 1e9:.3f} GB, {len(lay.recipe)} recipe lines -> {out}")
    rope_table(cfg).tofile(BUILD / "rope.f32")
    print("rope.f32:", CAP, "x", hd)


if __name__ == "__main__":
    main()
