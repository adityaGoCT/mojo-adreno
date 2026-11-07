"""The reference for LFM2-MoE (LFM2.5-8B-A1B, LFM2.5-24B-A2B): transformers' own Lfm2Moe pieces, run a decoder layer
at a time in fp32 on the Mac.

  --weights gguf   the device's 4-bit GGUF, dequantized exactly as ggml does (weights.py GGUFWeights): the exact
                   reference for the device's int4 path
  --weights bf16   the bf16 source checkpoint (weights.py BF16Weights)

Both are read from Hugging Face a layer at a time (nothing kept on disk), so several sequences share one pass (--jobs).
What is transformers' code: Lfm2MoeRotaryEmbedding, masking_utils.create_causal_mask, every Lfm2MoeDecoderLayer (its
Lfm2MoeShortConv or Lfm2MoeAttention, its Lfm2MoeMLP or Lfm2MoeSparseMoeBlock with the sigmoid router, expert bias and
normalized top-k weights, and the Lfm2MoeRMSNorms), the final norm; the head is the tied embedding (Lfm2MoeForCausalLM).
--trace records each MoE layer's router choice for every token ([L, T, k] expert ids and weights), for cache studies.

  LFM2MOE=8b build/vla/venv/bin/python lfm2moe/reference.py --prompt "..." --out logits.npy
  LFM2MOE=8b build/vla/venv/bin/python lfm2moe/reference.py --jobs jobs.json     # [{ids, start, out, dump, trace}]
  build/vla/venv/bin/python lfm2moe/reference.py --selftest   # this driver against Lfm2MoeForCausalLM, tiny random
"""

import argparse
import json
import pathlib
import sys
import time

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2moe"))
from weights import BUILD, BF16Weights, GGUFWeights, config, layer_names  # noqa: E402


def tokenizer():
    from transformers import AutoTokenizer
    return AutoTokenizer.from_pretrained(BUILD)


def chat_ids(tok, text):
    ids = tok.apply_chat_template([{"role": "user", "content": text}], tokenize=True, add_generation_prompt=True)
    return list(ids if isinstance(ids, list) else ids["input_ids"])


def forward(cfg, W, seqs, dump=False, trace=False, log=print):
    """seqs: [(ids, start)]. Returns, per sequence, a dict: logits at positions start .. len(ids) - 1 ([n, V] fp32);
    with dump, hidden ([L + 1, T, D]: after the embedding and after each layer) and final (the final-normed rows);
    with trace, experts [L, T, k] (int64, -1 in dense layers) and weights [L, T, k] (the router's normalized weights)."""
    from transformers.masking_utils import create_causal_mask
    from transformers.models.lfm2_moe.modeling_lfm2_moe import (Lfm2MoeDecoderLayer, Lfm2MoeRMSNorm,
                                                                Lfm2MoeRotaryEmbedding)

    cfg._attn_implementation = "eager"
    L, D, k = cfg.num_hidden_layers, cfg.hidden_size, cfg.num_experts_per_tok
    pre = getattr(W, "prefetch", None)
    if pre:
        pre(layer_names(cfg, 0))
    with torch.no_grad():
        uniq = sorted({t for ids, _ in seqs for t in ids})
        table = W.embed_rows(uniq)
        index = {t: i for i, t in enumerate(uniq)}
        rot = Lfm2MoeRotaryEmbedding(cfg)
        hs, ctxs, res = [], [], []
        for ids, _ in seqs:
            x = table[torch.tensor([index[t] for t in ids])][None]
            pos = torch.arange(len(ids))[None]
            mask = create_causal_mask(config=cfg, inputs_embeds=x, attention_mask=None, past_key_values=None,
                                      position_ids=pos)
            hs.append(x)
            ctxs.append((pos, mask, rot(x, pos)))
            r = {}
            if dump:
                r["hidden"] = [x[0].clone()]
            if trace:
                r["experts"] = torch.full((L, len(ids), k), -1, dtype=torch.int64)
                r["weights"] = torch.zeros(L, len(ids), k)
            res.append(r)
        t0 = time.time()
        for i in range(L):
            if pre and i + 1 < L:
                pre(layer_names(cfg, i + 1))
            with torch.device("meta"):
                layer = Lfm2MoeDecoderLayer(cfg, i)
            layer = layer.to_empty(device="cpu")
            sd = {}
            for key in layer.state_dict():
                sd[key] = W.get(f"model.layers.{i}.{key}")
            layer.load_state_dict(sd, strict=True)
            del sd
            moe = hasattr(layer.feed_forward, "gate")
            seen = {}
            if trace and moe:
                hook = layer.feed_forward.gate.register_forward_hook(lambda m, a, out: seen.__setitem__("logits", out))
            attn = cfg.layer_types[i] == "full_attention"
            for s, (pos, mask, pe) in enumerate(ctxs):
                hs[s] = layer(hs[s], attention_mask=mask if attn else None, position_embeddings=pe,
                              position_ids=pos, past_key_values=None)
                if dump:
                    res[s]["hidden"].append(hs[s][0].clone())
                if trace and moe:
                    sel, w = layer.feed_forward.route_tokens_to_experts(seen["logits"])
                    res[s]["experts"][i], res[s]["weights"][i] = sel, w
            if trace and moe:
                hook.remove()
            del layer
            log(f"reference: layer {i} ({cfg.layer_types[i]}{', moe' if moe else ''}) at {time.time() - t0:.0f} s")
        norm = Lfm2MoeRMSNorm(D, eps=cfg.norm_eps)
        norm.weight.copy_(W.get("model.embedding_norm.weight"))
        head = W.head()
        for s, (ids, start) in enumerate(seqs):
            hn = norm(hs[s][0])
            res[s]["logits"] = hn[start:] @ head.T
            if dump:
                res[s]["hidden"] = torch.stack(res[s]["hidden"])
                res[s]["final"] = hn
    return res


def save(r, out=None, dump=None, trace=None):
    if out:
        np.save(out, r["logits"].numpy().astype(np.float32))
        print("wrote", out, tuple(r["logits"].shape))
    if dump:
        np.save(dump, r["hidden"].numpy())
        np.save(str(dump).replace(".npy", "_final.npy"), r["final"].numpy())
        print("wrote", dump, tuple(r["hidden"].shape))
    if trace:
        np.savez(trace, experts=r["experts"].numpy().astype(np.int16), weights=r["weights"].numpy())
        print("wrote", trace, tuple(r["experts"].shape))


def selftest():
    """forward() against transformers' whole Lfm2MoeForCausalLM on a tiny random model with LFM2-MoE's structure
    (dense then MoE layers, conv and attention, GQA, expert bias, tied head) and against its incremental decode."""
    from transformers import Lfm2MoeConfig, Lfm2MoeForCausalLM

    torch.manual_seed(0)
    cfg = Lfm2MoeConfig(vocab_size=300, hidden_size=64, intermediate_size=96, moe_intermediate_size=48,
                        num_hidden_layers=6, num_dense_layers=2, num_experts=8, num_experts_per_tok=3,
                        num_attention_heads=4, num_key_value_heads=2, max_position_embeddings=256,
                        layer_types=["conv", "conv", "full_attention", "conv", "conv", "full_attention"],
                        conv_L_cache=3, tie_word_embeddings=True, use_expert_bias=True, norm_topk_prob=True,
                        rope_parameters={"rope_theta": 1e7, "rope_type": "default"}, norm_eps=1e-5)
    model = Lfm2MoeForCausalLM(cfg).eval()
    with torch.no_grad():
        for n, p in model.named_parameters():  # norms away from 1, experts and gate random, so a slip shows
            if "norm" in n:
                p.uniform_(0.5, 1.5)
            elif "experts" in n or "gate" in n:
                p.normal_(0, 0.1)
        for n, b in model.named_buffers():
            if n.endswith("expert_bias"):
                b.uniform_(-0.3, 0.3)
    sd = {k: v.float() for k, v in model.state_dict().items()}

    class W:
        get = staticmethod(lambda n: sd[n])
        embed_rows = staticmethod(lambda ids: sd["model.embed_tokens.weight"][ids])
        head = staticmethod(lambda: sd["model.embed_tokens.weight"])

    ids = torch.randint(0, 300, (37,)).tolist()
    with torch.no_grad():
        ref = model(torch.tensor([ids])).logits[0]
        r = forward(cfg, W, [(ids, 0)], trace=True, log=lambda *a: None)[0]
        print(f"selftest: driver vs Lfm2MoeForCausalLM: max |diff| {float((ref - r['logits']).abs().max()):.3g}")
        print(f"selftest: trace experts layer 3 token 0: {r['experts'][3, 0].tolist()}, dense layer 0: "
              f"{r['experts'][0, 0].tolist()}")
        out = model(torch.tensor([ids[:20]]), use_cache=True)
        cache, inc = out.past_key_values, [out.logits[0, -1]]
        for t in ids[20:]:
            out = model(torch.tensor([[t]]), past_key_values=cache, use_cache=True)
            cache = out.past_key_values
            inc.append(out.logits[0, -1])
        inc = torch.stack(inc[:-1])
        print(f"selftest: incremental decode vs the driver: max |diff| "
              f"{float((inc - r['logits'][19:-1]).abs().max()):.3g}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", choices=["gguf", "bf16"], default="gguf")
    ap.add_argument("--prompt", help="a user message, through the chat template")
    ap.add_argument("--ids", type=int, nargs="*")
    ap.add_argument("--ids-file")
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--out")
    ap.add_argument("--dump", help="hidden states after each layer (.npy, [L+1, T, D]) and final-normed rows")
    ap.add_argument("--trace", help="router choices (.npz: experts, weights [L, T, k])")
    ap.add_argument("--jobs", help="json [{ids, start, out, dump, trace}]: several sequences in one pass")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    cfg = config()
    W = GGUFWeights() if a.weights == "gguf" else BF16Weights()
    t0 = time.time()
    if a.jobs:
        jobs = json.loads(pathlib.Path(a.jobs).read_text())
        res = forward(cfg, W, [(j["ids"], j.get("start", 0)) for j in jobs],
                      dump=any(j.get("dump") for j in jobs), trace=any(j.get("trace") for j in jobs))
        for j, r in zip(jobs, res):
            save(r, j.get("out"), j.get("dump"), j.get("trace"))
    else:
        if a.prompt:
            ids = chat_ids(tokenizer(), a.prompt)
        else:
            ids = a.ids or [int(w) for w in pathlib.Path(a.ids_file).read_text().split()]
        r = forward(cfg, W, [(ids, a.start)], dump=bool(a.dump), trace=bool(a.trace))[0]
        save(r, a.out, a.dump, a.trace)
        top = r["logits"][-1].topk(5)
        print("last position top 5:", top.indices.tolist(), [round(float(v), 3) for v in top.values])
    print(f"done in {time.time() - t0:.0f} s, {W.src.bytes / 1e9 if hasattr(W, 'src') else 0:.2f} GB read")


if __name__ == "__main__":
    main()
