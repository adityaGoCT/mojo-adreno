"""The reference: transformers' own Qwen3.5 (Qwen3_5ForCausalLM's pieces), run a decoder layer at a time in fp32 on the
Mac, on two sets of weights, each streamed from Hugging Face by range request (the Mac keeps neither file):
  bf16   Qwen/Qwen3.5-4B as published, widened to fp32 (exact): the model itself
  q4     unsloth's Q4_0 GGUF, the file the phone runs, dequantized as ggml does and mapped back to transformers' layout
         (weights.GGUFWeights): the exact reference for the phone

What is transformers' code: Qwen3_5TextRotaryEmbedding (text positions), masking_utils.create_causal_mask, every
Qwen3_5DecoderLayer (Qwen3_5GatedDeltaNet with its causal conv, chunked gated delta rule and gated norm; Qwen3_5Attention
with its q/k norms, partial RoPE and output gate; Qwen3_5MLP; the zero-centred RMS norms), the final Qwen3_5RMSNorm; the
head is the tied embedding, as in Qwen3_5ForCausalLM. Each layer is built on the meta device, given its weights, run
over every sequence and dropped. The head reads the embedding 16,384 rows at a time (the Mac has 16 GB).

  build/vla/venv/bin/python qwen3_5_4b/reference.py --selftest   # this driver against Qwen3_5ForCausalLM, tiny config
  build/vla/venv/bin/python qwen3_5_4b/reference.py --ids 248045 ... --start 20 --views q4 --out logits [--dump]
"""

import argparse
import pathlib
import sys
import time

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "qwen3_5_4b"))
from weights import EMBED, P, Bf16Weights, GGUFWeights, config, layer_names  # noqa: E402

CHUNK = 16384


def sources(views):
    return {v: (Bf16Weights() if v == "bf16" else GGUFWeights()) for v in views}


def forward(cfg, W, seqs, dump=False, log=print):
    """W: {view: weights (get(name), embed_rows(ids), head_rows(r0, r1), prefetch(names))}; seqs: [(ids, start)].
    Returns {view: [logits at positions start .. len(ids) - 1 ([n, V] fp32) per sequence]}; with dump, also
    {view + "_hidden": [[L + 1, T, D] per sequence]} (after the embedding and after each layer)."""
    from transformers.masking_utils import create_causal_mask
    from transformers.models.qwen3_5.modeling_qwen3_5 import (Qwen3_5DecoderLayer, Qwen3_5RMSNorm,
                                                              Qwen3_5TextRotaryEmbedding)

    L, D = cfg.num_hidden_layers, cfg.hidden_size
    views = list(W)
    for w in W.values():
        if hasattr(w, "prefetch"):
            w.prefetch(layer_names(cfg, 0))
    res = {}
    with torch.no_grad():
        uniq = sorted({t for ids, _ in seqs for t in ids})
        index = {t: i for i, t in enumerate(uniq)}
        rot = Qwen3_5TextRotaryEmbedding(cfg)
        hs, ctxs, dumps = {}, [], {}
        for ids, _ in seqs:
            T = len(ids)
            text_pos = torch.arange(T)[None]
            x0 = torch.zeros(1, T, D)
            mask = create_causal_mask(config=cfg, inputs_embeds=x0, attention_mask=None, past_key_values=None,
                                      position_ids=text_pos)
            ctxs.append((text_pos, mask, rot(x0, text_pos[None].expand(3, 1, T))))
        for v in views:
            rows = W[v].embed_rows(uniq)
            hs[v] = [rows[torch.tensor([index[t] for t in ids])][None] for ids, _ in seqs]
            dumps[v] = [[h[0].clone()] for h in hs[v]] if dump else None
        t0 = time.time()
        for i in range(L):
            for v in views:
                w = W[v]
                if hasattr(w, "prefetch") and i + 1 < L:
                    w.prefetch(layer_names(cfg, i + 1))
                raw = {n: w.get(n) for n in layer_names(cfg, i)}
                with torch.device("meta"):
                    layer = Qwen3_5DecoderLayer(cfg, i)
                layer = layer.to_empty(device="cpu")
                pre = f"{P}layers.{i}."
                layer.load_state_dict({k: raw[pre + k] for k in layer.state_dict()}, strict=True)
                for s, (text_pos, mask, pe) in enumerate(ctxs):
                    m = mask if cfg.layer_types[i] == "full_attention" else None
                    hs[v][s] = layer(hs[v][s], position_embeddings=pe, attention_mask=m, position_ids=text_pos,
                                     past_key_values=None)
                    if dump:
                        dumps[v][s].append(hs[v][s][0].clone())
                del layer, raw
            log(f"reference: layer {i} at {time.time() - t0:.0f} s "
                f"({sum(w.bytes for w in W.values()) / 1e9:.1f} GB read)")
        for v in views:
            norm = Qwen3_5RMSNorm(D, eps=cfg.rms_norm_eps)
            norm.weight.copy_(W[v].get(P + "norm.weight"))
            hn = [norm(hs[v][s][0, start:]) for s, (_, start) in enumerate(seqs)]
            outs = [[] for _ in seqs]
            for r0 in range(0, cfg.vocab_size, CHUNK):
                e = W[v].head_rows(r0, min(cfg.vocab_size, r0 + CHUNK))
                for s in range(len(seqs)):
                    outs[s].append(hn[s] @ e.T)
            res[v] = [torch.cat(o, dim=1) for o in outs]
            if dump:
                res[v + "_hidden"] = [torch.stack(d) for d in dumps[v]]
    return res


def tiny_config():
    from transformers.models.qwen3_5.configuration_qwen3_5 import Qwen3_5TextConfig
    cfg = Qwen3_5TextConfig(vocab_size=300, hidden_size=64, intermediate_size=96, num_hidden_layers=4,
                            num_attention_heads=4, num_key_value_heads=2, head_dim=32, linear_num_key_heads=2,
                            linear_num_value_heads=4, linear_key_head_dim=16, linear_value_head_dim=16,
                            linear_conv_kernel_dim=4, full_attention_interval=4, max_position_embeddings=256,
                            tie_word_embeddings=True, rms_norm_eps=1e-6,
                            layer_types=["linear_attention"] * 3 + ["full_attention"],
                            rope_parameters=dict(rope_type="default", rope_theta=1e7, partial_rotary_factor=0.25,
                                                 mrope_interleaved=True, mrope_section=[2, 1, 1]))
    cfg._attn_implementation = "eager"
    return cfg


def selftest():
    """forward() against transformers' whole Qwen3_5ForCausalLM on a tiny random model with Qwen3.5's structure (3
    linear-attention layers and a gated full-attention layer, GQA, partial RoPE, tied head)."""
    from transformers.models.qwen3_5.modeling_qwen3_5 import Qwen3_5ForCausalLM

    torch.manual_seed(0)
    cfg = tiny_config()
    model = Qwen3_5ForCausalLM(cfg).eval()
    with torch.no_grad():
        for n, p in model.named_parameters():  # norms and the delta rule's parameters away from their defaults
            if "norm" in n or "dt_bias" in n or "A_log" in n:
                p.uniform_(-0.5, 0.5)
    sd = {k.replace("model.", P, 1): v.float() for k, v in model.state_dict().items()}

    class W:
        bytes = 0
        get = staticmethod(lambda n: sd[n])
        embed_rows = staticmethod(lambda ids: sd[EMBED][ids])
        head_rows = staticmethod(lambda r0, r1: sd[EMBED][r0:r1])

    ids = torch.randint(0, 300, (37,)).tolist()
    with torch.no_grad():
        ref = model(torch.tensor([ids])).logits[0]
        mine = forward(cfg, {"bf16": W}, [(ids, 0)], log=lambda *a: None)["bf16"][0]
    print(f"selftest: driver vs Qwen3_5ForCausalLM: max |diff| {float((ref - mine).abs().max()):.3g} "
          f"(logits up to {float(ref.abs().max()):.2f})")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ids", type=int, nargs="*")
    ap.add_argument("--ids-file")
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--views", default="bf16,q4")
    ap.add_argument("--out", help="<out>_<view>.npy")
    ap.add_argument("--dump", action="store_true", help="also <out>_<view>_hidden.npy: [L + 1, T, D] residual streams")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    ids = a.ids or [int(w) for w in pathlib.Path(a.ids_file).read_text().split()]
    res = forward(config(), sources(a.views.split(",")), [(ids, a.start)], dump=a.dump)
    for v, lg in res.items():
        if v.endswith("_hidden"):
            if a.out:
                np.save(f"{a.out}_{v}.npy", lg[0].numpy().astype(np.float32))
            continue
        top = lg[0][-1].topk(5)
        print(f"{v}: last position top 5:", top.indices.tolist(), [round(float(x), 3) for x in top.values])
        if a.out:
            np.save(f"{a.out}_{v}.npy", lg[0].numpy().astype(np.float32))


if __name__ == "__main__":
    main()
