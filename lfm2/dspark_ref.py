"""The DSpark drafter for LFM2.5-2.6B (LiquidAI/LFM2.5-2.6B-DSpark) in PyTorch, fp32: the reference for the phone's port,
written from SGLang's implementation (python/sglang/srt/models/dspark.py and dflash.py, speculative/dspark_components;
merged in sgl-project/sglang#31041).

The drafter (327.7M parameters, bf16) is 5 Qwen3-style attention layers with the target's embedding and head:
  context   the target's residual stream after layers 2, 9, 17, 21, 27 at each committed position, concatenated
            (5 x 2048), through fc (10240 -> 2048) and hidden_norm (RMSNorm): one row a position. Each draft layer
            keeps its K (k_proj, k_norm, RoPE at the position) and V (v_proj) of those rows: the draft's KV cache.
  block     the anchor (the target's newest token, not yet through the target) and 8 mask tokens (id 125017), at
            positions p .. p + 8, embedded with the target's embedding. Each layer: RMSNorm, q/k/v, q/k RMS norms per
            head, RoPE (interleaved pairs, theta 1e7), attention over the context keys and all 9 block keys (not
            causal), o_proj, residual; RMSNorm, SwiGLU (6144), residual. Then the final norm.
  drafts    row j's hidden through the target's head gives base logits for the token at p + j + 1 (sample_from_anchor).
            The Markov head adds a bias from the token before: step j's logits = base_j + W2 W1[prev] (W1: 128000 x
            256 embedding, W2: 256 -> 128000), prev = the anchor, then each draft; greedy: d_j = argmax.
  confidence sigmoid(proj([hidden_j, W1[prev_j]])): how likely d_j is accepted (for a ragged verify; optional).
Verify: the target runs [anchor, d_0 .. d_8] at p .. p + 9; d_j is accepted while it equals the target's argmax at
p + j; the target's argmax after the last accepted token is the next anchor (the bonus token). Greedy output is
exactly the target's.

  build/vla/venv/bin/python lfm2/dspark_ref.py --simulate build/lfm2/runs/q4_long_prefill.json
      # acceptance along a finished greedy run: one target pass gives every position's features
  build/vla/venv/bin/python lfm2/dspark_ref.py --export      # build/lfm2/dspark/manifest.txt for dspark.mojo
"""

import argparse
import json
import pathlib
import sys

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2"))
from weights import BUILD, GGUFWeights, config  # noqa: E402

DS = BUILD / "dspark"
TARGET_LAYERS = [2, 9, 17, 21, 27]
MASK = 125017
GAMMA = 9
EPS = 1e-5
HD = 64


def load_drafter(path=None):
    """The checkpoint's tensors as fp32 (bf16 widened exactly)."""
    from safetensors.torch import load_file
    return {k: v.float() for k, v in load_file(str(path or DS / "model.safetensors")).items()}


def rms(x, w):
    return x * torch.rsqrt(x.pow(2).mean(-1, keepdim=True) + EPS) * w


def rope_tables(positions, theta=1e7):
    inv = 1.0 / (theta ** (torch.arange(0, HD, 2, dtype=torch.int64).float() / HD))
    f = positions.float()[:, None] * inv[None]
    return f.cos(), f.sin()  # [n, 32]


def rope_interleaved(x, cos, sin):
    """x [n, heads, 64]: pairs (2i, 2i + 1) rotated by the angle of frequency i (GPT-J style)."""
    x1, x2 = x[..., 0::2], x[..., 1::2]
    c, s = cos[:, None], sin[:, None]
    return torch.stack([x1 * c - x2 * s, x2 * c + x1 * s], -1).flatten(-2)


class Drafter:
    def __init__(self, W, embed_rows, head):
        """W: the drafter's tensors; embed_rows(ids) -> [n, 2048] (the target's embedding); head: [V, 2048] (the
        target's tied head)."""
        self.W, self.embed_rows, self.head = W, embed_rows, head
        self.L = 5

    def context(self, feats):
        """feats [n, 5 * 2048] (the target's taps) -> the context rows [n, 2048]."""
        return rms(feats @ self.W["fc.weight"].T, self.W["hidden_norm.weight"])

    def ctx_kv(self, ctx, positions):
        """Each layer's K (normed, rotated) and V [n, 8, 64] for context rows at `positions`."""
        cos, sin = rope_tables(positions)
        out = []
        for i in range(self.L):
            p = f"layers.{i}.self_attn."
            k = (ctx @ self.W[p + "k_proj.weight"].T).view(-1, 8, HD)
            v = (ctx @ self.W[p + "v_proj.weight"].T).view(-1, 8, HD)
            k = rope_interleaved(rms(k, self.W[p + "k_norm.weight"]), cos, sin)
            out.append((k, v))
        return out

    def block_hidden(self, kv_ctx, anchor, pos):
        """The 9 rows' final hidden states for the block [anchor, mask x 8] at positions pos .. pos + 8."""
        ids = [anchor] + [MASK] * (GAMMA - 1)
        x = self.embed_rows(ids)
        positions = torch.arange(pos, pos + GAMMA)
        cos, sin = rope_tables(positions)
        for i in range(self.L):
            p = f"layers.{i}."
            a = p + "self_attn."
            h = rms(x, self.W[p + "input_layernorm.weight"])
            q = (h @ self.W[a + "q_proj.weight"].T).view(-1, 32, HD)
            k = (h @ self.W[a + "k_proj.weight"].T).view(-1, 8, HD)
            v = (h @ self.W[a + "v_proj.weight"].T).view(-1, 8, HD)
            q = rope_interleaved(rms(q, self.W[a + "q_norm.weight"]), cos, sin)
            k = rope_interleaved(rms(k, self.W[a + "k_norm.weight"]), cos, sin)
            kc, vc = kv_ctx[i]
            K = torch.cat([kc, k]).repeat_interleave(4, dim=1)  # [n + 9, 32, 64]
            Vv = torch.cat([vc, v]).repeat_interleave(4, dim=1)
            s = torch.einsum("qhd,khd->hqk", q, K) / 8.0
            o = torch.einsum("hqk,khd->qhd", s.softmax(-1), Vv).reshape(-1, 2048)
            x = x + o @ self.W[a + "o_proj.weight"].T
            h = rms(x, self.W[p + "post_attention_layernorm.weight"])
            g = h @ self.W[p + "mlp.gate_proj.weight"].T
            u = h @ self.W[p + "mlp.up_proj.weight"].T
            x = x + (torch.nn.functional.silu(g) * u) @ self.W[p + "mlp.down_proj.weight"].T
        return rms(x, self.W["norm.weight"])

    def draft(self, kv_ctx, anchor, pos):
        """Greedy drafts d_0 .. d_8, their confidences, and the base logits [9, V]."""
        hid = self.block_hidden(kv_ctx, anchor, pos)
        base = hid @ self.head.T
        w1, w2 = self.W["markov_head.markov_w1.weight"], self.W["markov_head.markov_w2.weight"]
        prev, toks, prevs = anchor, [], []
        for j in range(GAMMA):
            prevs.append(prev)
            prev = int((base[j] + w2 @ w1[prev]).argmax())
            toks.append(prev)
        feat = torch.cat([hid, w1[prevs]], -1)
        conf = torch.sigmoid(feat @ self.W["confidence_head.proj.weight"].T + self.W["confidence_head.proj.bias"])
        return toks, conf[:, 0], base


def target_features(seq):
    """The GGUF target's taps for every position of seq: [n, 5 * 2048] (reference.py's layers, fp32)."""
    from reference import forward
    _, hs, _ = forward(config(), GGUFWeights(), [(seq, len(seq) - 1)], dump=True, log=lambda *a: None)[0]
    return torch.cat([hs[l + 1] for l in TARGET_LAYERS], -1)  # hs[0] is the embedding, hs[l + 1] after layer l


def simulate(run_json):
    """Acceptance along a recorded greedy run (prompt + the phone's tokens, which are the target's greedy tokens):
    at each anchor position, draft from the context before it and count the drafts that match the run."""
    r = json.loads(pathlib.Path(run_json).read_text())
    seq = r["ids"] + r["tokens"]
    P = len(r["ids"])
    feats = target_features(seq)
    g = GGUFWeights()
    head = g.get("model.embed_tokens.weight")
    d = Drafter(load_drafter(), g.embed_rows, head)
    ctx = d.context(feats)
    accepted, pos = [], P  # the anchor: the first generated token, at position P
    with torch.no_grad():
        while pos < len(seq) - 1:
            kv = d.ctx_kv(ctx[:pos], torch.arange(pos))
            toks, conf, _ = d.draft(kv, seq[pos], pos)
            a = 0
            while a < GAMMA and pos + 1 + a < len(seq) and toks[a] == seq[pos + 1 + a]:
                a += 1
            accepted.append(a)
            print(f"pos {pos}: accepted {a} of {GAMMA}; confidences {[round(float(c), 2) for c in conf]}")
            pos += a + 1
    n = len(accepted)
    print(f"{n} steps for {len(seq) - P - 1} tokens: {np.mean(accepted) + 1:.2f} tokens a step "
          f"(mean accepted drafts {np.mean(accepted):.2f})")


def export():
    """build/lfm2/dspark/manifest.txt for dspark.mojo: each tensor's absolute offset in model.safetensors (bf16, read
    in place on the phone)."""
    path = DS / "model.safetensors"
    with open(path, "rb") as f:
        n = int.from_bytes(f.read(8), "little")
        header = json.loads(f.read(n))
    lines = [f"dspark v1 L 5 D 2048 F 6144 V 128000 R 256 MASK {MASK} GAMMA {GAMMA} TAPS 2,9,17,21,27"]
    for name, t in sorted(header.items()):
        if name == "__metadata__":
            continue
        assert t["dtype"] == "BF16", name
        a, b = t["data_offsets"]
        lines.append(f"{name} {8 + n + a} {b - a} bf16 {'x'.join(str(d) for d in t['shape'])}")
    (DS / "manifest.txt").write_text("\n".join(lines) + "\n")
    print("manifest.txt:", len(lines) - 1, "tensors")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--simulate")
    ap.add_argument("--export", action="store_true")
    a = ap.parse_args()
    if a.export:
        export()
    if a.simulate:
        simulate(a.simulate)


if __name__ == "__main__":
    main()
