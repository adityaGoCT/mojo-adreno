"""Qwen3-30B-A3B in PyTorch, the reference for qwen3moe: transformers' own Qwen3MoeDecoderLayer, RMSNorm and rotary
embedding, run a layer at a time (the 61 GB bf16 model fits neither the Mac's 17 GB nor the laptop's 33.6 GB at
once), in fp32 math.

  python reference.py --hf <shard dir> --bin qwen3moe.bin --manifest manifest.txt --tokens <ids> --prompt-len <n>
      [--bf16] [--out logits.f32]

The weights are the GPU's own by default: qwen3moe.bin's int4 projections and experts dequantized (q * scale, a scale
per 64 or 128), its embedding, norms and router (fp32, exact). With --bf16 they are the checkpoint's (the shards), to see what int4 changes.
The sequence (the prompt, then the tokens to check) runs once, teacher-forced with a causal mask: the logits at
position p are the model's prediction of token p + 1, so greedy decoding agrees with a generated sequence when each
generated token is the argmax of the position before it. Prints that, and writes the logits of the positions from
prompt-len - 1 on (fp32 [k][151936]).
"""

import argparse
import json
import pathlib
import time

import numpy as np
import torch
from transformers import AutoConfig
from transformers.models.qwen3_moe import modeling_qwen3_moe as qm


class Weights:
    def __init__(self, a):
        self.bf16 = a.bf16
        self.hf = pathlib.Path(a.hf)
        if a.bf16:
            from safetensors import safe_open
            self.where = json.loads((self.hf / "model.safetensors.index.json").read_text())["weight_map"]
            self.files = {}
            self.open = lambda f: self.files.setdefault(f, safe_open(self.hf / f, "pt"))
        else:
            self.bin = np.memmap(a.bin, np.uint8, "r")
            self.man = {}
            for line in pathlib.Path(a.manifest).read_text().splitlines()[1:]:
                name, off, n, kind, shape = line.split()
                self.man[name] = (int(off), int(n), kind, [int(s) for s in shape.split("x")])

    def hf_tensor(self, name):
        return self.open(self.where[name]).get_tensor(name).float()

    def plain(self, name, hf):
        if self.bf16:
            return self.hf_tensor(hf)
        off, n, kind, shape = self.man[name]
        dt = {"f16": np.float16, "f32": np.float32}[kind]
        return torch.from_numpy(np.array(self.bin[off:off + n].view(dt).reshape(shape), np.float32))

    def int4(self, name, r0=0, rows=None):
        """Rows r0 .. r0 + rows of the int4 matrix `name`, dequantized (q * scale) to fp32."""
        off, n, _, shape = self.man[name + ".q"]
        rows = rows or shape[0]
        words = shape[1]
        q = self.bin[off + r0 * words * 4: off + (r0 + rows) * words * 4].view(np.uint32).reshape(rows, words)
        soff, _, _, sshape = self.man[name + ".s"]
        s = self.bin[soff + r0 * sshape[1] * 2: soff + (r0 + rows) * sshape[1] * 2].view(np.float16)
        s = s.reshape(rows, sshape[1]).astype(np.float32)
        nib = (q[:, :, None] >> (np.arange(8, dtype=np.uint32) * 4)) & 15
        w = ((nib.astype(np.int32) ^ 8) - 8).reshape(rows, words * 8).astype(np.float32)
        w = (w.reshape(rows, sshape[1], -1) * s[:, :, None]).reshape(rows, words * 8)
        return torch.from_numpy(w)

    def layer(self, l, cfg):
        """Layer l's state dict for Qwen3MoeDecoderLayer."""
        p = f"model.layers.{l}."
        sd = {}
        for ours, hf in (("in_norm", "input_layernorm"), ("post_norm", "post_attention_layernorm"),
                         ("q_norm", "self_attn.q_norm"), ("k_norm", "self_attn.k_norm"), ("router", "mlp.gate")):
            sd[hf + ".weight"] = self.plain(f"l{l}.{ours}", p + hf + ".weight")
        hq, hkv = cfg.num_attention_heads * cfg.head_dim, cfg.num_key_value_heads * cfg.head_dim
        F = cfg.moe_intermediate_size
        if self.bf16:
            for w in ("q", "k", "v", "o"):
                sd[f"self_attn.{w}_proj.weight"] = self.hf_tensor(p + f"self_attn.{w}_proj.weight")
            for e in range(cfg.num_experts):
                for w in ("gate", "up", "down"):
                    sd[f"mlp.experts.{e}.{w}_proj.weight"] = self.hf_tensor(p + f"mlp.experts.{e}.{w}_proj.weight")
            return sd
        qkv = self.int4(f"l{l}.qkv")
        sd["self_attn.q_proj.weight"], sd["self_attn.k_proj.weight"], sd["self_attn.v_proj.weight"] = \
            qkv[:hq], qkv[hq:hq + hkv], qkv[hq + hkv:]
        sd["self_attn.o_proj.weight"] = self.int4(f"l{l}.o")
        for e in range(cfg.num_experts):
            gu = self.int4(f"l{l}.gu", e * 2 * F, 2 * F)
            sd[f"mlp.experts.{e}.gate_proj.weight"], sd[f"mlp.experts.{e}.up_proj.weight"] = gu[:F], gu[F:]
            sd[f"mlp.experts.{e}.down_proj.weight"] = self.int4(f"l{l}.down", e * cfg.hidden_size, cfg.hidden_size)
        return sd


@torch.no_grad()
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hf", required=True, help="the checkpoint's directory (config.json; the shards for --bf16)")
    ap.add_argument("--bin", help="qwen3moe.bin")
    ap.add_argument("--manifest", help="export.py's manifest.txt")
    ap.add_argument("--tokens", required=True, help="comma-separated: the prompt, then the tokens to check")
    ap.add_argument("--prompt-len", type=int, required=True)
    ap.add_argument("--bf16", action="store_true", help="the checkpoint's bf16 weights instead of qwen3moe.bin's")
    ap.add_argument("--out", help="the logits from position prompt-len - 1 on, fp32")
    a = ap.parse_args()
    torch.set_num_threads(torch.get_num_threads())
    cfg = AutoConfig.from_pretrained(a.hf)
    cfg._attn_implementation = "eager"
    w = Weights(a)
    ids = [int(t) for t in a.tokens.split(",")]
    T = len(ids)
    t0 = time.time()
    if a.bf16:
        x = w.hf_tensor("model.embed_tokens.weight")[ids][None]
    else:
        off, n, _, shape = w.man["embed"]
        x = torch.from_numpy(np.array(w.bin[off:off + n].view(np.float32).reshape(shape)[ids]))[None]
    pos = torch.arange(T)[None]
    rot = qm.Qwen3MoeRotaryEmbedding(config=cfg)
    cos, sin = rot(x, pos)
    mask = torch.full((T, T), float("-inf")).triu(1)[None, None]
    for l in range(cfg.num_hidden_layers):
        with torch.device("meta"):
            layer = qm.Qwen3MoeDecoderLayer(cfg, l)
        layer.load_state_dict(w.layer(l, cfg), strict=True, assign=True)
        layer.eval()
        out = layer(x, attention_mask=mask, position_ids=pos, position_embeddings=(cos, sin))
        x = out[0] if isinstance(out, tuple) else out
        del layer
        print(f"layer {l}: max |x| {float(x.abs().max()):.1f} ({time.time() - t0:.0f} s)", flush=True)
    norm = qm.Qwen3MoeRMSNorm(cfg.hidden_size, eps=cfg.rms_norm_eps)
    norm.weight.copy_(w.plain("final_norm", "model.norm.weight"))
    xn = norm(x)[0]
    head = w.hf_tensor("lm_head.weight") if a.bf16 else w.int4("head")
    k0 = a.prompt_len - 1
    logits = xn[k0:] @ head.T  # [T - k0, V]
    best = logits.argmax(-1).tolist()
    agree = 0
    for i in range(T - 1 - k0):
        if best[i] != ids[k0 + 1 + i]:
            break
        agree += 1
    print("reference argmax:", ",".join(map(str, best)))
    print(f"greedy: {agree} of {T - 1 - k0} given tokens are the reference's argmax"
          f"{'' if agree == T - 1 - k0 else f' (first difference at generated token {agree})'}")
    if a.out:
        logits.float().numpy().astype(np.float32).tofile(a.out)
    print(f"done in {time.time() - t0:.0f} s")


if __name__ == "__main__":
    main()
