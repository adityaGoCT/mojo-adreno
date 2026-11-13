"""The reference: transformers' own Qwen3 (Qwen3ForCausalLM's pieces), run a decoder layer at a time in fp32 on the Mac,
on two sets of weights from one pass over the checkpoint (streamed from Hugging Face by range request; the Mac keeps
none of its 8 GB):
  bf16   the checkpoint as published, widened to fp32 (exact): the model itself
  q4     the same tensors as the phone stores them (weights.quantized: Q4_0 projections, Q6_K tied embedding / head,
         convert.c's quantizers), dequantized as ggml does: the exact reference for the phone's int4 path

What is transformers' code: the embedding lookup (nn.Embedding on the rows used), Qwen3RotaryEmbedding,
masking_utils.create_causal_mask, every Qwen3DecoderLayer (Qwen3Attention with its q/k norms, Qwen3MLP, the RMS norms),
the final Qwen3RMSNorm; the head is the tied embedding, as in Qwen3ForCausalLM. Each layer is built on the meta device,
given its weights, run over every sequence and dropped.

  build/vla/venv/bin/python qwen3_4b/reference.py --selftest   # this driver against Qwen3ForCausalLM, tiny random config
  build/vla/venv/bin/python qwen3_4b/reference.py --ids 151644 ... --start 18 --views q4 --out logits.npy
"""

import argparse
import pathlib
import sys
import time

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "qwen3_4b"))
from weights import Bf16Weights, config, layer_names, quant_blocks, dequant_q6_k, quantized  # noqa: E402

EMBED = "model.embed_tokens.weight"


def identity(name, w):
    return w


def head_logits(hn, E, view, chunk=16384):
    """hn [n, D] @ E^T, E [V, D] fp32 as stored (bf16) or as the phone's Q6_K holds it (q4), a block of rows at a time
    (the dequantized head never exists whole)."""
    if view == "bf16":
        return hn @ E.T
    out = []
    for r0 in range(0, E.shape[0], chunk):
        e = E[r0:r0 + chunk]
        eq = torch.from_numpy(dequant_q6_k(quant_blocks(e, "q6"), e.shape[0], e.shape[1]))
        out.append(hn @ eq.T)
    return torch.cat(out, dim=1)


def forward(cfg, W, seqs, views=("bf16", "q4"), dump=False, log=print):
    """seqs: [(ids, start)]. Returns {view: [logits at positions start .. len(ids) - 1 ([n, V] fp32) per sequence]};
    with dump, also {view + "_hidden": [[L + 1, T, D] per sequence]} (after the embedding and after each layer).
    W: get(name) -> the bf16 tensor as fp32, embed_rows(ids), prefetch(names) (optional)."""
    from transformers.masking_utils import create_causal_mask
    from transformers.models.qwen3.modeling_qwen3 import Qwen3DecoderLayer, Qwen3RMSNorm, Qwen3RotaryEmbedding

    tf = {"bf16": identity, "q4": quantized}
    L, D = cfg.num_hidden_layers, cfg.hidden_size
    pre = getattr(W, "prefetch", None)
    if pre:
        pre(layer_names(0))
    res = {}
    with torch.no_grad():
        uniq = sorted({t for ids, _ in seqs for t in ids})
        rows = W.embed_rows(uniq)
        index = {t: i for i, t in enumerate(uniq)}
        rot = Qwen3RotaryEmbedding(cfg)
        hs, ctxs, dumps = {}, [], {}
        for ids, _ in seqs:
            pos = torch.arange(len(ids))[None]
            x0 = torch.zeros(1, len(ids), D)
            mask = create_causal_mask(config=cfg, inputs_embeds=x0, attention_mask=None, past_key_values=None,
                                      position_ids=pos)
            ctxs.append((pos, mask, rot(x0, pos)))
        for v in views:
            emb = torch.nn.Embedding(len(uniq), D)
            emb.weight.copy_(tf[v](EMBED, rows))  # the Q6_K rows: each row is quantized on its own
            hs[v] = [emb(torch.tensor([index[t] for t in ids])[None]) for ids, _ in seqs]
            dumps[v] = [[h[0].clone()] for h in hs[v]] if dump else None
        t0 = time.time()
        for i in range(L):
            if pre and i + 1 < L:
                pre(layer_names(i + 1))
            raw = {n: W.get(n) for n in layer_names(i)}
            for v in views:
                with torch.device("meta"):
                    layer = Qwen3DecoderLayer(cfg, i)
                layer = layer.to_empty(device="cpu")
                layer.load_state_dict({k: tf[v](f"model.layers.{i}.{k}", raw[f"model.layers.{i}.{k}"])
                                       for k in layer.state_dict()}, strict=True)
                for s, (pos, mask, pe) in enumerate(ctxs):
                    hs[v][s] = layer(hs[v][s], attention_mask=mask, position_embeddings=pe, position_ids=pos,
                                     past_key_values=None)
                    if dump:
                        dumps[v][s].append(hs[v][s][0].clone())
                del layer
            del raw
            log(f"reference: layer {i} at {time.time() - t0:.0f} s ({W.bytes / 1e9:.1f} GB read)")
        norm = Qwen3RMSNorm(D, eps=cfg.rms_norm_eps)
        norm.weight.copy_(W.get("model.norm.weight"))
        E = W.get(EMBED)
        for v in views:
            res[v] = [head_logits(norm(hs[v][s][0, start:]), E, v) for s, (_, start) in enumerate(seqs)]
            if dump:
                res[v + "_hidden"] = [torch.stack(d) for d in dumps[v]]
    return res


def selftest():
    """forward() against transformers' whole Qwen3ForCausalLM on a tiny random model with Qwen3's structure (GQA, q/k
    norms, tied head), on the bf16 view (the weights as given)."""
    from transformers import Qwen3Config, Qwen3ForCausalLM

    torch.manual_seed(0)
    cfg = Qwen3Config(vocab_size=300, hidden_size=64, intermediate_size=96, num_hidden_layers=3, num_attention_heads=4,
                      num_key_value_heads=2, head_dim=32, max_position_embeddings=256, tie_word_embeddings=True,
                      rope_theta=1e6, rms_norm_eps=1e-6)
    cfg._attn_implementation = "eager"
    model = Qwen3ForCausalLM(cfg).eval()
    with torch.no_grad():
        for n, p in model.named_parameters():  # norms away from 1 so a missing weight shows
            if "norm" in n:
                p.uniform_(0.5, 1.5)
    sd = {k: v.float() for k, v in model.state_dict().items()}

    class W:
        bytes = 0
        get = staticmethod(lambda n: sd[n])
        embed_rows = staticmethod(lambda ids: sd[EMBED][ids])

    import weights
    weights_layer_names = weights.layer_names
    ids = torch.randint(0, 300, (37,)).tolist()
    with torch.no_grad():
        ref = model(torch.tensor([ids])).logits[0]
        mine = forward(cfg, W, [(ids, 0)], views=("bf16",), log=lambda *a: None)["bf16"][0]
    print(f"selftest: driver vs Qwen3ForCausalLM: max |diff| {float((ref - mine).abs().max()):.3g} "
          f"(logits up to {float(ref.abs().max()):.2f}); layer names {len(weights_layer_names(0))}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ids", type=int, nargs="*")
    ap.add_argument("--ids-file")
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--views", default="bf16,q4")
    ap.add_argument("--out", help="<out>_<view>.npy")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    ids = a.ids or [int(w) for w in pathlib.Path(a.ids_file).read_text().split()]
    res = forward(config(), Bf16Weights(), [(ids, a.start)], views=tuple(a.views.split(",")))
    for v, lg in res.items():
        top = lg[0][-1].topk(5)
        print(f"{v}: last position top 5:", top.indices.tolist(), [round(float(x), 3) for x in top.values])
        if a.out:
            np.save(f"{a.out}_{v}.npy", lg[0].numpy().astype(np.float32))


if __name__ == "__main__":
    main()
