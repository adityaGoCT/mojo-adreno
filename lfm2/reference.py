"""The reference: transformers' own LFM2 (Lfm2ForCausalLM's pieces), run a decoder layer at a time in fp32 on the Mac.

Two sets of weights (weights.py):
  --weights gguf   the GPU's: LFM2.5-2.6B-QAD-Q4_0.gguf, every Q4_0 and Q6_K tensor dequantized as ggml does, the f32
                   tensors as stored; the exact reference for the device's int4 path
  --weights fp32   the QAD fp32 source checkpoint (qad/model.safetensors) the GGUF was quantized from, streamed from
                   Hugging Face a layer at a time (10.8 GB; the Mac keeps none of it)

What is transformers' code: the embedding lookup (nn.Embedding on the rows used), Lfm2RotaryEmbedding,
masking_utils.create_causal_mask, every Lfm2DecoderLayer (its Lfm2ShortConv or Lfm2Attention, Lfm2MLP and
Lfm2RMSNorms), the final Lfm2RMSNorm (embedding_norm). The head is the tied embedding, as in Lfm2ForCausalLM.
Each layer is built on the meta device, given its weights, run over every sequence and dropped, so neither weight set
needs to fit in memory, and several sequences share one pass over the (streamed) weights.

  build/vla/venv/bin/python lfm2/reference.py --weights gguf --ids 124894 ... --start 20 --out logits.npy
  build/vla/venv/bin/python lfm2/reference.py --weights fp32 --jobs jobs.json       # several sequences, one pass
  build/vla/venv/bin/python lfm2/reference.py --selftest   # this driver against Lfm2ForCausalLM, tiny random config
"""

import argparse
import json
import pathlib
import sys
import time

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2"))
from weights import Fp32Weights, GGUFWeights, config, layer_names  # noqa: E402


def forward(cfg, W, seqs, dump=False, log=print, hook=None):
    """seqs: [(ids, start)]. Returns, per sequence, the logits at positions start .. len(ids) - 1 ([n, V] fp32) and,
    with dump, the hidden state after the embedding and after each layer ([L + 1, T, D]) and the final-normed rows.
    W: get(name) -> fp32 tensor by transformers' name, embed_rows(ids) -> [len(ids), D]; prefetch(names) optional.
    hook(i, layer): called with each built Lfm2DecoderLayer before it runs (forward hooks for calibration)."""
    from transformers.masking_utils import create_causal_mask
    from transformers.models.lfm2.modeling_lfm2 import Lfm2DecoderLayer, Lfm2RMSNorm, Lfm2RotaryEmbedding

    cfg._attn_implementation = "eager"
    L, D = cfg.num_hidden_layers, cfg.hidden_size
    pre = getattr(W, "prefetch", None)
    if pre:
        pre(layer_names(cfg, 0))
    out = []
    with torch.no_grad():
        uniq = sorted({t for ids, _ in seqs for t in ids})
        table = W.embed_rows(uniq)
        index = {t: i for i, t in enumerate(uniq)}
        hs, ctxs, dumps = [], [], []
        rot = Lfm2RotaryEmbedding(cfg)
        for ids, _ in seqs:
            emb = torch.nn.Embedding(len(uniq), D)
            emb.weight.copy_(table)
            x = emb(torch.tensor([index[t] for t in ids])[None])
            pos = torch.arange(len(ids))[None]
            mask = create_causal_mask(config=cfg, inputs_embeds=x, attention_mask=None, past_key_values=None,
                                      position_ids=pos)
            hs.append(x)
            ctxs.append((pos, mask, rot(x, pos)))
            dumps.append([x[0].clone()] if dump else None)
        t0 = time.time()
        for i in range(L):
            if pre and i + 1 < L:
                pre(layer_names(cfg, i + 1))
            with torch.device("meta"):
                layer = Lfm2DecoderLayer(cfg, i)
            layer = layer.to_empty(device="cpu")
            layer.load_state_dict({k: W.get(f"model.layers.{i}.{k}") for k in layer.state_dict()}, strict=True)
            if hook:
                hook(i, layer)
            attn = cfg.layer_types[i] == "full_attention"
            for s, (pos, mask, pe) in enumerate(ctxs):
                hs[s] = layer(hs[s], attention_mask=mask if attn else None, position_embeddings=pe,
                              position_ids=pos, past_key_values=None)
                if dump:
                    dumps[s].append(hs[s][0].clone())
            del layer
            log(f"reference: layer {i} ({cfg.layer_types[i]}) at {time.time() - t0:.0f} s")
        norm = Lfm2RMSNorm(D, eps=cfg.norm_eps)
        norm.weight.copy_(W.get("model.embedding_norm.weight"))
        head = W.get("model.embed_tokens.weight")
        for s, (ids, start) in enumerate(seqs):
            hn = norm(hs[s][0, start:])
            logits = hn @ head.T
            if dump:
                out.append((logits, torch.stack(dumps[s]), norm(hs[s][0])))
            else:
                out.append(logits)
    return out


def weights(kind):
    return GGUFWeights() if kind == "gguf" else Fp32Weights()


def selftest():
    """forward() against transformers' whole Lfm2ForCausalLM on a tiny random model with LFM2's structure (conv and
    attention layers, GQA, tied head), and against its own incremental decode (conv state and KV cache)."""
    from transformers import Lfm2Config, Lfm2ForCausalLM

    torch.manual_seed(0)
    cfg = Lfm2Config(vocab_size=300, hidden_size=64, intermediate_size=96, num_hidden_layers=5,
                     num_attention_heads=4, num_key_value_heads=2, max_position_embeddings=256,
                     layer_types=["conv", "full_attention", "conv", "conv", "full_attention"], conv_L_cache=3,
                     block_auto_adjust_ff_dim=False, tie_word_embeddings=True,
                     rope_parameters={"rope_theta": 1e7, "rope_type": "default"}, norm_eps=1e-5)
    model = Lfm2ForCausalLM(cfg).eval()
    with torch.no_grad():
        for n, p in model.named_parameters():  # norms away from 1 so a missing weight shows
            if "norm" in n:
                p.uniform_(0.5, 1.5)
    sd = {k: v.float() for k, v in model.state_dict().items()}

    class W:
        get = staticmethod(lambda n: sd[n])
        embed_rows = staticmethod(lambda ids: sd["model.embed_tokens.weight"][ids])

    ids = torch.randint(0, 300, (37,)).tolist()
    with torch.no_grad():
        ref = model(torch.tensor([ids])).logits[0]
        mine = forward(cfg, W, [(ids, 0)], log=lambda *a: None)[0]
        print(f"selftest: driver vs Lfm2ForCausalLM: max |diff| {float((ref - mine).abs().max()):.3g}")
        out = model(torch.tensor([ids[:20]]), use_cache=True)
        cache, inc = out.past_key_values, [out.logits[0, -1]]
        for t in ids[20:]:
            out = model(torch.tensor([[t]]), past_key_values=cache, use_cache=True)
            cache = out.past_key_values
            inc.append(out.logits[0, -1])
        inc = torch.stack(inc[:-1])
        print(f"selftest: incremental decode vs the driver: max |diff| {float((inc - mine[19:-1]).abs().max()):.3g}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", choices=["gguf", "fp32"], default="gguf")
    ap.add_argument("--ids", type=int, nargs="*")
    ap.add_argument("--ids-file")
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--out")
    ap.add_argument("--dump", help="hidden states after each layer (.npy, [L+1, T, D]) and final-normed rows")
    ap.add_argument("--jobs", help="json [{ids, start, out}]: several sequences in one pass over the weights")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    cfg = config()
    W = weights(a.weights)
    if a.jobs:
        jobs = json.loads(pathlib.Path(a.jobs).read_text())
        res = forward(cfg, W, [(j["ids"], j["start"]) for j in jobs])
        for j, lg in zip(jobs, res):
            np.save(j["out"], lg.numpy().astype(np.float32))
            print("wrote", j["out"], tuple(lg.shape))
        return
    ids = a.ids or [int(w) for w in pathlib.Path(a.ids_file).read_text().split()]
    res = forward(cfg, W, [(ids, a.start)], dump=bool(a.dump))[0]
    if a.dump:
        logits, hs, hn = res
        np.save(a.dump, hs.numpy())
        np.save(a.dump.replace(".npy", "_final.npy"), hn.numpy())
    else:
        logits = res
    if a.out:
        np.save(a.out, logits.numpy().astype(np.float32))
    top = logits[-1].topk(5)
    print("last position top 5:", top.indices.tolist(), [round(float(v), 3) for v in top.values])


if __name__ == "__main__":
    main()
