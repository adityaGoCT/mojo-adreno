"""The phone's weight file for Qwen3-4B, laid out from the bf16 checkpoint's safetensors headers (read from Hugging
Face by range request): recipe.txt for convert.c (which writes qwen3_4b_q4.bin on the phone from the shards the phone
downloads), manifest.txt for the Mojo program, and the RoPE table.

The q4 storage (2.37 GB):
  every projection   ggml's Q4_0 (an fp16 scale per 32 weights, round to nearest), as int4 words (8 a uint32, 4-bit
                     two's complement, low nibble first) and the scales: lfm2/kernels/lk.mojo's gemv_q4 / gemm_q4
  embedding / head   tied (tie_word_embeddings): one copy in ggml's Q6_K, the storage llama.cpp gives a tied embedding
                     in its Q4_0 files, repacked to 208-byte super-blocks with the fp16 d's apart (lk's embed_q6 and
                     head_q6 read the same copy)
  norms              fp32 (input, post-attention, the q / k head norms of 128, the final norm)
In each layer q|k|v (4096 + 1024 + 1024 rows) and gate|up (9728 + 9728) are one matrix.

  build/vla/venv/bin/python qwen3_4b/export.py      # build/qwen3_4b/q4/{recipe,manifest}.txt, build/qwen3_4b/rope.f32
"""

import os
import pathlib
import sys

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "qwen3_4b"))
from weights import BUILD, SHARDS, config, headers  # noqa: E402

ROPE_ROWS = int(os.environ.get("QWEN3_ROPE_ROWS", "8192"))  # positions the RoPE table holds (the program's limit)
ALIGN = 4096


def rope_table(cfg, rows=ROPE_ROWS):
    """transformers' Qwen3RotaryEmbedding in fp32: row p = cos | sin of the head's first half (64 + 64)."""
    from transformers.models.qwen3.modeling_qwen3 import Qwen3RotaryEmbedding
    rot = Qwen3RotaryEmbedding(cfg)
    x = torch.zeros(1, rows, cfg.hidden_size)
    cos, sin = rot(x, torch.arange(rows)[None])
    hd = cos.shape[-1]
    assert torch.equal(cos[..., :hd // 2], cos[..., hd // 2:])
    return torch.cat([cos[0, :, :hd // 2], sin[0, :, :hd // 2]], dim=1).numpy().astype(np.float32)


class Layout:
    def __init__(self, h):
        self.h = h
        self.off = 0
        self.recipe = []
        self.manifest = []

    def alloc(self, nbytes):
        o = self.off
        self.off = (self.off + nbytes + ALIGN - 1) // ALIGN * ALIGN
        return o

    def matrix(self, name, parts):
        """Rows of the checkpoint tensors `parts` (in order) as one Q4_0 matrix `name`."""
        ts = [self.h[p] for p in parts]
        cols = ts[0]["shape"][1]
        rows = sum(t["shape"][0] for t in ts)
        q = self.alloc(rows * cols // 2)
        s = self.alloc(rows * cols // 32 * 2)
        r0 = 0
        for t in ts:
            n = t["shape"][0]
            assert t["shape"][1] == cols and t["dtype"] == "BF16"
            self.recipe.append(f"q4 {t['shard']} {t['abs'][0]} {n} {cols} {q + r0 * cols // 2} {s + r0 * cols // 16}")
            r0 += n
        self.manifest.append(f"{name}.q {q} {rows * cols // 2} u32 {rows}x{cols // 8}")
        self.manifest.append(f"{name}.s {s} {rows * cols // 16} f16 {rows}x{cols // 32}")

    def embed(self, name):
        t = self.h[name]
        rows, cols = t["shape"]
        nb = cols // 256
        q = self.alloc(rows * nb * 208)
        d = self.alloc(rows * nb * 2)
        self.recipe.append(f"q6 {t['shard']} {t['abs'][0]} {rows} {cols} {q} {d}")
        self.manifest.append(f"embed.q {q} {rows * nb * 208} u32 {rows}x{nb * 52}")
        self.manifest.append(f"embed.d {d} {rows * nb * 2} f16 {rows}x{nb}")

    def f32(self, name, src):
        t = self.h[src]
        n = int(np.prod(t["shape"]))
        o = self.alloc(n * 4)
        self.recipe.append(f"f32 {t['shard']} {t['abs'][0]} {n} {o}")
        self.manifest.append(f"{name} {o} {n * 4} f32 {n}")


def main():
    cfg = config()
    h = headers()
    D, F, L = cfg.hidden_size, cfg.intermediate_size, cfg.num_hidden_layers
    assert cfg.tie_word_embeddings and "lm_head.weight" not in h
    lay = Layout(h)
    lay.embed("model.embed_tokens.weight")
    lay.f32("final_norm", "model.norm.weight")
    for i in range(L):
        p = f"model.layers.{i}."
        n = f"l{i}."
        lay.f32(n + "in_norm", p + "input_layernorm.weight")
        lay.f32(n + "post_norm", p + "post_attention_layernorm.weight")
        lay.f32(n + "q_norm", p + "self_attn.q_norm.weight")
        lay.f32(n + "k_norm", p + "self_attn.k_norm.weight")
        lay.matrix(n + "qkv", [p + "self_attn.q_proj.weight", p + "self_attn.k_proj.weight",
                               p + "self_attn.v_proj.weight"])
        lay.matrix(n + "o", [p + "self_attn.o_proj.weight"])
        lay.matrix(n + "gu", [p + "mlp.gate_proj.weight", p + "mlp.up_proj.weight"])
        lay.matrix(n + "down", [p + "mlp.down_proj.weight"])
    out = BUILD / "q4"
    out.mkdir(parents=True, exist_ok=True)
    (out / "recipe.txt").write_text(f"size {lay.off}\n" + "\n".join(lay.recipe) + "\n")
    head = (f"qwen3 v1 D {D} L {L} H {cfg.num_attention_heads} KVH {cfg.num_key_value_heads} HD {cfg.head_dim} "
            f"F {F} V {cfg.vocab_size} ROPE {ROPE_ROWS} EPS {cfg.rms_norm_eps} "
            f"THETA {cfg.rope_parameters['rope_theta']} STORAGE q4 SHARDS {','.join(SHARDS)}")
    (out / "manifest.txt").write_text(head + "\n" + "\n".join(lay.manifest) + "\n")
    print(f"q4: {lay.off / 1e9:.3f} GB, {len(lay.recipe)} recipe lines -> {out}")
    rope_table(cfg).tofile(BUILD / "rope.f32")
    print("rope.f32:", ROPE_ROWS, "x", cfg.head_dim)


if __name__ == "__main__":
    main()
