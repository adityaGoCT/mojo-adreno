"""The device's weight file for LFM2-MoE (LFM2.5-8B-A1B on the phone, LFM2.5-24B-A2B on the laptop), laid out from the
4-bit GGUF's header: recipe.txt for lfm2/convert.c (which writes the file on the device from the GGUF the device
downloads itself), manifest.txt for the Mojo program (lfm2moe/model.mojo), and the RoPE table.

One storage, q4: the GGUF's own numbers. Every Q4_0 matrix as int4 words (8 a uint32, 4-bit two's complement, low
nibble first) and its fp16 scales (one per 32, unchanged); the Q6_K token embedding / tied head repacked to 4-byte
aligned super-blocks (ql, qh, scales; d apart), unchanged; norms, conv taps, the router and the expert bias in fp32 as
stored. In each layer q|k|v is one matrix; a dense layer's w1|w3 (gate|up) is one matrix ("gu"); a MoE layer's experts
are "egu" (expert e's gate rows then its up rows, at rows e * 2 FE ..) and "edown" (expert e's rows at e * D ..).

  LFM2MOE=8b build/vla/venv/bin/python lfm2moe/export.py    # build/lfm2moe/8b/q4/{recipe,manifest}.txt, rope.f32
  LFM2MOE_CAP=<positions>                                    # the KV cache and RoPE table's length (default 4608)
"""

import os
import pathlib
import sys

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2moe"))
from weights import BUILD, GGUFWeights, M, config  # noqa: E402

CAP = int(os.environ.get("LFM2MOE_CAP", "4608"))
ALIGN = 4096
Q4_ROW = lambda cols: cols // 32 * 18  # noqa: E731  (a Q4_0 row's bytes in the GGUF)


def rope_table(cfg, cap=CAP):
    """transformers' Lfm2MoeRotaryEmbedding in fp32: row p = cos | sin of the head's first half (32 + 32)."""
    from transformers.models.lfm2_moe.modeling_lfm2_moe import Lfm2MoeRotaryEmbedding
    rot = Lfm2MoeRotaryEmbedding(cfg)
    x = torch.zeros(1, cap, cfg.hidden_size)
    cos, sin = rot(x, torch.arange(cap)[None])
    hd = cos.shape[-1]
    assert torch.equal(cos[..., :hd // 2], cos[..., hd // 2:])
    return torch.cat([cos[0, :, :hd // 2], sin[0, :, :hd // 2]], dim=1).numpy().astype(np.float32)


class Layout:
    def __init__(self):
        self.off = 0
        self.recipe = []
        self.manifest = []

    def alloc(self, nbytes):
        o = self.off
        self.off = (self.off + nbytes + ALIGN - 1) // ALIGN * ALIGN
        return o

    def matrix(self, name, parts, cols):
        """A Q4_0 matrix `name` made of row ranges of GGUF tensors, in order: parts = [(tensor, first row, rows)]."""
        assert all(t["tname"] == "Q4_0" for t, _, _ in parts), name
        rows = sum(n for _, _, n in parts)
        q = self.alloc(rows * cols // 2)
        s = self.alloc(rows * cols // 32 * 2)
        r0 = 0
        for t, first, n in parts:
            src = t["abs"] + first * Q4_ROW(cols)
            self.recipe.append(f"q4 {src} {n} {cols} {q + r0 * cols // 2} {s + r0 * cols // 16}")
            r0 += n
        self.manifest.append(f"{name}.q {q} {rows * cols // 2} u32 {rows}x{cols // 8}")
        self.manifest.append(f"{name}.s {s} {rows * cols // 16} f16 {rows}x{cols // 32}")

    def whole(self, name, tensors, cols):
        self.matrix(name, [(t, 0, int(np.prod(t["dims"][1:]))) for t in tensors], cols)

    def embed(self, t):
        cols, rows = t["dims"]
        assert t["tname"] == "Q6_K"
        nb = cols // 256
        q = self.alloc(rows * nb * 208)
        d = self.alloc(rows * nb * 2)
        self.recipe.append(f"q6 {t['abs']} {rows} {cols} {q} {d}")
        self.manifest.append(f"embed.q {q} {rows * nb * 208} u32 {rows}x{nb * 52}")
        self.manifest.append(f"embed.d {d} {rows * nb * 2} f16 {rows}x{nb}")

    def f32(self, name, t):
        n = int(np.prod(t["dims"]))
        o = self.alloc(n * 4)
        self.recipe.append(f"f32 {t['abs']} {n} {o}")
        self.manifest.append(f"{name} {o} {n * 4} f32 {'x'.join(str(d) for d in reversed(t['dims']))}")


def main():
    cfg = config()
    t = GGUFWeights().t
    D, F, FE, E = cfg.hidden_size, cfg.intermediate_size, cfg.moe_intermediate_size, cfg.num_experts
    hd = D // cfg.num_attention_heads
    lay = Layout()
    lay.embed(t["token_embd.weight"])
    lay.f32("final_norm", t["token_embd_norm.weight"])
    layers = []
    for i in range(cfg.num_hidden_layers):
        b, n = f"blk.{i}.", f"l{i}."
        attn = cfg.layer_types[i] == "full_attention"
        dense = i < cfg.num_dense_layers
        layers.append(f"layer {i} {'attn' if attn else 'conv'} {'dense' if dense else 'moe'}")
        lay.f32(n + "in_norm", t[b + "attn_norm.weight"])
        lay.f32(n + "ffn_norm", t[b + "ffn_norm.weight"])
        if attn:
            lay.whole(n + "qkv", [t[b + "attn_q.weight"], t[b + "attn_k.weight"], t[b + "attn_v.weight"]], D)
            lay.whole(n + "o", [t[b + "attn_output.weight"]], D)
            lay.f32(n + "q_norm", t[b + "attn_q_norm.weight"])
            lay.f32(n + "k_norm", t[b + "attn_k_norm.weight"])
        else:
            lay.whole(n + "in", [t[b + "shortconv.in_proj.weight"]], D)
            lay.whole(n + "out", [t[b + "shortconv.out_proj.weight"]], D)
            lay.f32(n + "conv", t[b + "shortconv.conv.weight"])
        if dense:
            lay.whole(n + "gu", [t[b + "ffn_gate.weight"], t[b + "ffn_up.weight"]], D)
            lay.whole(n + "down", [t[b + "ffn_down.weight"]], F)
        else:
            g, u, dn = t[b + "ffn_gate_exps.weight"], t[b + "ffn_up_exps.weight"], t[b + "ffn_down_exps.weight"]
            assert g["dims"] == [D, FE, E] and dn["dims"] == [FE, D, E], (g["dims"], dn["dims"])
            lay.matrix(n + "egu", [p for e in range(E) for p in ((g, e * FE, FE), (u, e * FE, FE))], D)
            lay.whole(n + "edown", [dn], FE)
            assert t[b + "ffn_gate_inp.weight"]["dims"] == [D, E]
            lay.f32(n + "router", t[b + "ffn_gate_inp.weight"])
            lay.f32(n + "ebias", t[b + "exp_probs_b.bias"])
    out = BUILD / "q4"
    out.mkdir(parents=True, exist_ok=True)
    (out / "recipe.txt").write_text(f"size {lay.off}\n" + "\n".join(lay.recipe) + "\n")
    head = (f"lfm2moe v1 D {D} L {cfg.num_hidden_layers} H {cfg.num_attention_heads} KVH {cfg.num_key_value_heads} "
            f"HD {hd} F {F} FE {FE} E {E} K {cfg.num_experts_per_tok} V {cfg.vocab_size} CAP {CAP} "
            f"EPS {cfg.norm_eps} STORAGE q4 GGUF {M['gguf']}")
    (out / "manifest.txt").write_text(head + "\n" + "\n".join(layers + lay.manifest) + "\n")
    print(f"q4: {lay.off / 1e9:.3f} GB, {len(lay.recipe)} recipe lines -> {out}")
    rope_table(cfg).tofile(BUILD / "rope.f32")
    print("rope.f32:", CAP, "x", hd)


if __name__ == "__main__":
    main()
