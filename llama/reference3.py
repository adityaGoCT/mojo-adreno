"""The reference for llama/run3.py: a Llama 3.x checkpoint on run3.py's int4 weights, in fp32 on the Mac, a decoder layer
at a time (Llama 3.2 3B in fp32 would not fit next to everything else in the Mac's 17 GB).

The weights are the phone's: dequantized from build/llama/<name>-q4/weights.bin (int4 words and fp16 scales, exactly
as run.py's quantize4 dequantizes them), the embedding and norms in fp16. Each layer is transformers' own
LlamaDecoderLayer (eager attention, a causal mask), with LlamaRotaryEmbedding's cos and sin; then the final norm and
the int4 head. The ids are the prompt and the phone's generated tokens (teacher forcing), so one pass gives the logits
at every position from --first on.

  $PY llama/reference3.py --model <snapshot> --weights build/llama/llama3b-q4 --ids 128000,... --first 430 \\
      --out build/llama/llama3b_ref.npy
"""

import argparse
import json
import pathlib

import numpy as np
import torch
from transformers import LlamaConfig
from transformers.models.llama.modeling_llama import LlamaDecoderLayer, LlamaRMSNorm, LlamaRotaryEmbedding


class Weights:
    def __init__(self, d):
        d = pathlib.Path(d)
        lines = (d / "manifest.txt").read_text().splitlines()
        self.header = [int(x) for x in lines[0].split()[1:]]
        self.where = {l.split()[0]: (int(l.split()[1]), int(l.split()[2])) for l in lines[1:] if l.strip()}
        self.blob = np.memmap(d / "weights.bin", np.uint8, "r")

    def raw(self, name, dtype):
        off, n = self.where[name]
        return np.frombuffer(self.blob[off:off + n], dtype)

    def f16(self, name):
        return torch.from_numpy(self.raw(name, np.float16).astype(np.float32))

    def q4(self, name, cols):
        """The int4 matrix `name` (rows of `cols`), dequantized: q (two's complement nibbles, low first) times its
        fp16 scale per 64; 1024 rows at a time, so the temporaries stay small."""
        words = self.raw(name + ".q", np.uint32).reshape(-1, cols // 8)
        scales = self.raw(name + ".s", np.float16).reshape(words.shape[0], cols // 64)
        out = np.empty((words.shape[0], cols), np.float32)
        shifts = 4 * np.arange(8, dtype=np.uint32)
        for r0 in range(0, words.shape[0], 1024):
            nib = ((words[r0:r0 + 1024, :, None] >> shifts) & 0xF).astype(np.int8)
            q = np.where(nib >= 8, nib - 16, nib).astype(np.float32).reshape(-1, cols // 64, 64)
            out[r0:r0 + 1024] = (q * scales[r0:r0 + 1024].astype(np.float32)[..., None]).reshape(-1, cols)
        return torch.from_numpy(out)


@torch.no_grad()
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, help="the Hugging Face snapshot (config.json)")
    ap.add_argument("--weights", required=True, help="run3.py's export directory")
    ap.add_argument("--ids", required=True, help="comma-separated token ids: the prompt and the generated tokens")
    ap.add_argument("--first", type=int, required=True, help="the first position whose logits are kept")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    cfg = LlamaConfig(**json.loads((pathlib.Path(a.model) / "config.json").read_text()))
    cfg._attn_implementation = "eager"
    w = Weights(a.weights)
    D, L, H, KVH, HD, F, V, _, CHUNKS = w.header
    ids = [int(x) for x in a.ids.split(",")]
    T = len(ids)
    rows = V // CHUNKS
    h = torch.from_numpy(np.stack([w.raw(f"embed.{t // rows}", np.float16).reshape(rows, D)[t % rows]
                                   for t in ids]).astype(np.float32))[None]
    pos = torch.arange(T)[None]
    cos, sin = LlamaRotaryEmbedding(config=cfg)(h, pos)
    mask = torch.full((T, T), float("-inf")).triu(1)[None, None]
    for l in range(L):
        layer = LlamaDecoderLayer(cfg, l).float().eval()
        qkv = w.q4(f"l{l}.wqkv", D)
        gu = w.q4(f"l{l}.wgu", D)
        layer.load_state_dict({
            "input_layernorm.weight": w.f16(f"l{l}.attn_norm"),
            "self_attn.q_proj.weight": qkv[: H * HD],
            "self_attn.k_proj.weight": qkv[H * HD: (H + KVH) * HD],
            "self_attn.v_proj.weight": qkv[(H + KVH) * HD:],
            "self_attn.o_proj.weight": w.q4(f"l{l}.wo", H * HD),
            "post_attention_layernorm.weight": w.f16(f"l{l}.mlp_norm"),
            "mlp.gate_proj.weight": gu[:F],
            "mlp.up_proj.weight": gu[F:],
            "mlp.down_proj.weight": w.q4(f"l{l}.wdown", F),
        })
        out = layer(h, attention_mask=mask, position_ids=pos, position_embeddings=(cos, sin))
        h = out[0] if isinstance(out, tuple) else out
        del layer, qkv, gu, out
        print(f"reference3: layer {l}", end="\r", flush=True)
    norm = LlamaRMSNorm(D, eps=cfg.rms_norm_eps)
    norm.weight.copy_(w.f16("final_norm"))
    x = norm(h[0, a.first:])
    np.save(a.out, torch.cat([x @ w.q4(f"lm.{c}", D).T for c in range(CHUNKS)], dim=1).numpy().astype(np.float32))
    print(f"reference3: logits at {T - a.first} positions -> {a.out}")


if __name__ == "__main__":
    main()
