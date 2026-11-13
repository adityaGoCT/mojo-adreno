"""The phone's weight file for Qwen3.5-4B, laid out from the Q4_0 GGUF's tensor table (read from Hugging Face by range
request): recipe.txt for convert.c (which writes qwen3_5_4b_q4.bin on the phone from the GGUF the phone downloads),
manifest.txt for the Mojo program, and the RoPE table.

Every number is the GGUF's own (2.66 GB):
  Q4_0 matrices      int4 words + fp16 scales (lfm2/kernels/lk.mojo's gemv_q4 / gemm_q4), fused per layer:
                       linear attention   qkvz = attn_qkv (q 2048 | k 2048 | v 4096) | attn_gate (z, 4096): 12288 rows
                       full attention     qkvg = q (16 heads x 256) | k (4 x 256) | v (4 x 256) | gate (16 x 256): the
                                          GGUF's attn_q holds each head's q and gate rows together (512 a head); they
                                          are split here, so the q heads and the gates are each contiguous
                       MLP                gu = gate | up (18432 rows); down (layers 4-31); attn_output (o)
  Q4_1, Q5_K         ffn_down of layers 0-3 and every linear-attention out_proj (ssm_out): convert.c's affine storage
                     (int4 low bits, [a word of high bits], fp32 d and c a block of 32), q35k.gemv_aff / gemm_aff
  Q8_0               in_proj_a | in_proj_b (ssm_alpha, ssm_beta: 64 x 2560) as fp32 (exact)
  Q6_K               the tied embedding / head, repacked to lk's 208-byte super-blocks + fp16 d's
  fp32               norms (the GGUF stores 1 + w for the zero-centred ones, which the kernels use as it is), conv
                     taps (8192 x 4), dt_bias, ssm_a = -exp(A_log), the gated norm's weight
The linear attention's value heads stay in the GGUF's tiled order (head i reads key head i % 16): every per-head
tensor of a layer uses that order, and the head-to-head map never needs undoing on the phone.

  build/vla/venv/bin/python qwen3_5_4b/export.py    # build/qwen3_5_4b/q4/{recipe,manifest}.txt, build/qwen3_5_4b/rope.f32
"""

import os
import pathlib
import sys

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "qwen3_5_4b"))
from weights import BUILD, GGUF, config, gguf_tensors  # noqa: E402

ROPE_ROWS = int(os.environ.get("QWEN35_ROPE_ROWS", "8192"))  # positions the RoPE table holds (the program's limit)
ALIGN = 4096
BYTES = {"Q4_0": 18, "Q4_1": 20, "Q8_0": 34}  # a block of 32


def rope_table(cfg, rows=ROPE_ROWS):
    """transformers' Qwen3_5TextRotaryEmbedding (text positions: the same position for its three sections) in fp32:
    row p = cos | sin of the rotated part's first half (32 + 32; the first 64 of a head's 256 dimensions rotate)."""
    from transformers.models.qwen3_5.modeling_qwen3_5 import Qwen3_5TextRotaryEmbedding
    rot = Qwen3_5TextRotaryEmbedding(cfg)
    x = torch.zeros(1, rows, cfg.hidden_size)
    cos, sin = rot(x, torch.arange(rows)[None])
    rd = cos.shape[-1]
    assert rd == 64 and torch.equal(cos[..., :rd // 2], cos[..., rd // 2:])
    return torch.cat([cos[0, :, :rd // 2], sin[0, :, :rd // 2]], dim=1).numpy().astype(np.float32)


class Layout:
    def __init__(self, t):
        self.t = t
        self.off = 0
        self.recipe = []
        self.manifest = []
        self.kinds = {}

    def alloc(self, nbytes):
        o = self.off
        self.off = (self.off + nbytes + ALIGN - 1) // ALIGN * ALIGN
        return o

    def rows_of(self, gname, r0=0, n=None):
        """(absolute offset of row r0, rows, cols) of a GGUF matrix (ggml dims: ne0 = cols, ne1 = rows)."""
        t = self.t[gname]
        cols, rows = t["dims"]
        n = rows - r0 if n is None else n
        return t["abs"] + r0 * (t["nbytes"] // rows), n, cols

    def q4(self, name, parts):
        """Rows of GGUF Q4_0 tensors, parts = [(gguf name, first row, rows)], in order, as one matrix `name`."""
        cols = self.rows_of(parts[0][0])[2]
        rows = sum(n for _, _, n in parts)
        q = self.alloc(rows * cols // 2)
        s = self.alloc(rows * cols // 32 * 2)
        r = 0
        for g, r0, n in parts:
            assert self.t[g]["type"] == "Q4_0", g
            src, _, c = self.rows_of(g, r0, n)
            assert c == cols
            self.recipe.append(f"q4 {src} {n} {cols} {q + r * cols // 2} {s + r * cols // 16}")
            r += n
        self.manifest.append(f"{name}.q {q} {rows * cols // 2} u32 {rows}x{cols // 8}")
        self.manifest.append(f"{name}.s {s} {rows * cols // 16} f16 {rows}x{cols // 32}")
        self.kinds[name] = "q4"

    def affine(self, name, g):
        """A Q4_1 or Q5_K matrix in the affine storage."""
        typ = self.t[g]["type"]
        src, rows, cols = self.rows_of(g)
        nb = rows * cols // 32
        q = self.alloc(rows * cols // 2)
        h = self.alloc(nb * 4) if typ == "Q5_K" else None
        d = self.alloc(nb * 4)
        c = self.alloc(nb * 4)
        if typ == "Q5_K":
            self.recipe.append(f"a5k {src} {rows} {cols} {q} {h} {d} {c}")
        else:
            assert typ == "Q4_1", g
            self.recipe.append(f"a41 {src} {rows} {cols} {q} {d} {c}")
        self.manifest.append(f"{name}.q {q} {rows * cols // 2} u32 {rows}x{cols // 8}")
        if h is not None:
            self.manifest.append(f"{name}.h {h} {nb * 4} u32 {rows}x{cols // 32}")
        self.manifest.append(f"{name}.d {d} {nb * 4} f32 {rows}x{cols // 32}")
        self.manifest.append(f"{name}.c {c} {nb * 4} f32 {rows}x{cols // 32}")
        self.kinds[name] = "a5" if h is not None else "a4"

    def matrix(self, name, g):
        """A whole GGUF matrix in its own storage: Q4_0 as int4, Q4_1 / Q5_K as affine."""
        if self.t[g]["type"] == "Q4_0":
            self.q4(name, [(g, 0, self.t[g]["dims"][1])])
        else:
            self.affine(name, g)

    def q8f(self, name, parts):
        """Q8_0 matrices, rows in order, as one fp32 matrix."""
        cols = self.rows_of(parts[0])[2]
        rows = sum(self.t[g]["dims"][1] for g in parts)
        o = self.alloc(rows * cols * 4)
        r = 0
        for g in parts:
            assert self.t[g]["type"] == "Q8_0", g
            src, n, _ = self.rows_of(g)
            self.recipe.append(f"q8f {src} {n} {cols} {o + r * cols * 4}")
            r += n
        self.manifest.append(f"{name} {o} {rows * cols * 4} f32 {rows}x{cols}")

    def embed(self, name, g):
        t = self.t[g]
        assert t["type"] == "Q6_K"
        cols, rows = t["dims"]
        nb = cols // 256
        q = self.alloc(rows * nb * 208)
        d = self.alloc(rows * nb * 2)
        self.recipe.append(f"q6 {t['abs']} {rows} {cols} {q} {d}")
        self.manifest.append(f"{name}.q {q} {rows * nb * 208} u32 {rows}x{nb * 52}")
        self.manifest.append(f"{name}.d {d} {rows * nb * 2} f16 {rows}x{nb}")

    def f32(self, name, g):
        t = self.t[g]
        assert t["type"] == "F32", g
        n = int(np.prod(t["dims"]))
        o = self.alloc(n * 4)
        self.recipe.append(f"f32 {t['abs']} {n} {o}")
        self.manifest.append(f"{name} {o} {n * 4} f32 {n}")


def main():
    cfg = config()
    t = gguf_tensors()["tensors"]
    D, F, L = cfg.hidden_size, cfg.intermediate_size, cfg.num_hidden_layers
    H, KVH, HD = cfg.num_attention_heads, cfg.num_key_value_heads, cfg.head_dim
    NK, NV, DK = cfg.linear_num_key_heads, cfg.linear_num_value_heads, cfg.linear_key_head_dim
    assert cfg.tie_word_embeddings and "output.weight" not in t
    assert cfg.attn_output_gate and cfg.linear_value_head_dim == DK and cfg.linear_conv_kernel_dim == 4
    lay = Layout(t)
    lay.embed("embed", "token_embd.weight")
    lay.f32("final_norm", "output_norm.weight")
    types = ""
    for i in range(L):
        b = f"blk.{i}."
        n = f"l{i}."
        lay.f32(n + "in_norm", b + "attn_norm.weight")
        lay.f32(n + "post_norm", b + "post_attention_norm.weight")
        if cfg.layer_types[i] == "linear_attention":
            types += "L"
            lay.q4(n + "qkvz", [(b + "attn_qkv.weight", 0, 2 * NK * DK + NV * DK), (b + "attn_gate.weight", 0, NV * DK)])
            lay.q8f(n + "ab", [b + "ssm_alpha.weight", b + "ssm_beta.weight"])
            lay.f32(n + "conv", b + "ssm_conv1d.weight")
            lay.f32(n + "dt", b + "ssm_dt.bias")
            lay.f32(n + "a", b + "ssm_a")
            lay.f32(n + "gnorm", b + "ssm_norm.weight")
            lay.matrix(n + "out", b + "ssm_out.weight")
        else:
            types += "F"
            q = b + "attn_q.weight"  # rows: head h's q at 512 h, its gate at 512 h + 256
            lay.q4(n + "qkvg", [(q, 2 * HD * h, HD) for h in range(H)] + [(b + "attn_k.weight", 0, KVH * HD),
                                                                          (b + "attn_v.weight", 0, KVH * HD)]
                   + [(q, 2 * HD * h + HD, HD) for h in range(H)])
            lay.f32(n + "q_norm", b + "attn_q_norm.weight")
            lay.f32(n + "k_norm", b + "attn_k_norm.weight")
            lay.matrix(n + "o", b + "attn_output.weight")
        lay.q4(n + "gu", [(b + "ffn_gate.weight", 0, F), (b + "ffn_up.weight", 0, F)])
        lay.matrix(n + "down", b + "ffn_down.weight")
    out = BUILD / "q4"
    out.mkdir(parents=True, exist_ok=True)
    (out / "recipe.txt").write_text(f"size {lay.off}\n" + "\n".join(lay.recipe) + "\n")
    rope = cfg.rope_parameters
    head = (f"qwen35 v1 D {D} L {L} H {H} KVH {KVH} HD {HD} F {F} V {cfg.vocab_size} NK {NK} NV {NV} DK {DK} "
            f"ROPE {ROPE_ROWS} ROT {int(HD * rope['partial_rotary_factor'])} EPS {cfg.rms_norm_eps} "
            f"THETA {rope['rope_theta']} TYPES {types} STORAGE q4 GGUF {GGUF}")
    (out / "manifest.txt").write_text(head + "\n" + "\n".join(lay.manifest) + "\n")
    kinds = {}
    for k, v in lay.kinds.items():
        kinds.setdefault(v, []).append(k)
    print(f"q4: {lay.off / 1e9:.3f} GB, {len(lay.recipe)} recipe lines -> {out}")
    print("  affine:", {k: v for k, v in kinds.items() if k != "q4"})
    rope_table(cfg).tofile(BUILD / "rope.f32")
    print("rope.f32:", ROPE_ROWS, "x 64")


if __name__ == "__main__":
    main()
