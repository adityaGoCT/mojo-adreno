"""The input and the check for export_layer.py's graph (runs on the laptop, with qwen3moe's Python).

  python layer_ref.py inputs --bin ..\\qwen3moe.bin --manifest ..\\manifest.txt --ids <ids file> --tokens 128 256
      x_t<T>.f16: the embedding rows of the prompt's first T tokens (the stream entering layer 0)
  python layer_ref.py check --hf ..\\hf --layer 0 --tokens 128 --npu out_t128_x_out.bin
      transformers' Qwen3MoeDecoderLayer (the checkpoint's bf16 weights, fp32 math) on the same x, at positions
      0 .. T-1 with a causal mask, against the NPU's x_out (fp16)
"""

import argparse
import json
import pathlib

import numpy as np


def inputs(a):
    man = {}
    for line in pathlib.Path(a.manifest).read_text().splitlines()[1:]:
        name, off, n, kind, shape = line.split()
        man[name] = (int(off), int(n), [int(s) for s in shape.split("x")])
    off, n, shape = man["embed"]
    emb = np.memmap(a.bin, np.uint8, "r")[off:off + n].view(np.float32).reshape(shape)
    ids = [int(t) for t in pathlib.Path(a.ids).read_text().split()]
    for T in a.tokens:
        emb[ids[:T]].astype(np.float16).tofile(f"x_t{T}.f16")
        print(f"x_t{T}.f16: {T} tokens")


def check(a):
    import torch
    from safetensors import safe_open
    from transformers import AutoConfig
    from transformers.models.qwen3_moe import modeling_qwen3_moe as qm
    torch.set_grad_enabled(False)
    hf = pathlib.Path(a.hf)
    cfg = AutoConfig.from_pretrained(hf)
    cfg._attn_implementation = "eager"
    where = json.loads((hf / "model.safetensors.index.json").read_text())["weight_map"]
    p = f"model.layers.{a.layer}."
    sd = {}
    files = {}
    for name, shard in where.items():
        if name.startswith(p):
            f = files.setdefault(shard, safe_open(hf / shard, "pt"))
            sd[name[len(p):]] = f.get_tensor(name).float()
    with torch.device("meta"):
        layer = qm.Qwen3MoeDecoderLayer(cfg, a.layer)
    layer.load_state_dict(sd, strict=True, assign=True)
    T = a.tokens[0]
    x = torch.from_numpy(np.fromfile(f"x_t{T}.f16", np.float16).astype(np.float32).reshape(1, T, -1))
    pos = torch.arange(T)[None]
    cos, sin = qm.Qwen3MoeRotaryEmbedding(config=cfg)(x, pos)
    mask = torch.full((T, T), float("-inf")).triu(1)[None, None]
    out = layer(x, attention_mask=mask, position_ids=pos, position_embeddings=(cos, sin))
    ref = (out[0] if isinstance(out, tuple) else out)[0].numpy()
    npu = np.fromfile(a.npu, np.float16).astype(np.float32).reshape(T, -1)
    d = npu - ref
    print(f"layer {a.layer}, {T} tokens: the NPU's x_out within {np.abs(d).max():.4f} of transformers' (values up to "
          f"{np.abs(ref).max():.1f}); relative {np.linalg.norm(d) / np.linalg.norm(ref):.2e}; the layer's own "
          f"change (x_out - x) relative error {np.linalg.norm(d) / np.linalg.norm(ref - x[0].numpy()):.2e}")
    per = np.linalg.norm(d, axis=1) / np.linalg.norm(ref - x[0].numpy(), axis=1)
    # the tokens whose top 8 differ between transformers' router (fp32) and an fp16 one
    xn = layer.post_attention_layernorm(x + layer.self_attn(layer.input_layernorm(x), position_embeddings=(cos, sin),
                                                            attention_mask=mask)[0])[0]
    logits = xn @ layer.mlp.gate.weight.T
    top32 = set(map(tuple, logits.topk(8).indices.sort().values.tolist()))
    flips = sum(int(set(a.tolist()) != set(b.tolist())) for a, b in
                zip(logits.topk(8).indices, logits.half().float().topk(8).indices))
    print(f"per token: median relative error {np.median(per):.2e}, worst {per.max():.2e} (token {int(per.argmax())}); "
          f"{int((per > 0.05).sum())} of {T} tokens above 5%; fp16 router logits change the top 8 of {flips} tokens")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("what", choices=["inputs", "check"])
    ap.add_argument("--bin")
    ap.add_argument("--manifest")
    ap.add_argument("--ids")
    ap.add_argument("--hf")
    ap.add_argument("--layer", type=int, default=0)
    ap.add_argument("--tokens", type=int, nargs="+", default=[128])
    ap.add_argument("--npu")
    a = ap.parse_args()
    inputs(a) if a.what == "inputs" else check(a)


if __name__ == "__main__":
    main()
