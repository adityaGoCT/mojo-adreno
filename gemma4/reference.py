"""The reference for the GPU: transformers' own Gemma 4 text model, run a decoder layer at a time in fp32 on the Mac.

By default it runs the GPU's weights: every int4 matrix of gemma4.bin dequantized, the rest (norms, layer scalars,
the bf16 embedding rows) as the GPU has them. With --bf16 it runs the checkpoint's original bf16 weights instead
(widened to fp32), for the check against the unquantized model. Neither needs the whole model in memory: each layer
is built from transformers' Gemma4TextDecoderLayer, given its weights, run over the whole token list and dropped.
The K/V that later layers share stays in the shared_kv_states dict that transformers' layers fill and read.

What is transformers' code here: the scaled embeddings (Gemma4TextScaledWordEmbedding, on just the rows of the tokens
used), Gemma4TextModel.project_per_layer_inputs, Gemma4TextRotaryEmbedding, the causal and sliding-window masks of
masking_utils, every Gemma4TextDecoderLayer, the final Gemma4RMSNorm. The head is the tied embedding (int4 or bf16)
with Gemma 4's final logit soft-cap, as Gemma4ForCausalLM computes it.

  build/vla/venv/bin/python gemma4/reference.py --model e2b --ids 2 105 ... --start 18 --out logits.npy [--bf16]
  build/vla/venv/bin/python gemma4/reference.py --selftest     # this driver against Gemma4ForCausalLM, tiny config
"""

import argparse
import json
import pathlib
import sys
import time

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "gemma4"))
from export import MODELS  # noqa: E402
from fetch import Sparse  # noqa: E402

P = "model.language_model."


def forward(tc, get, rows, ids, start, log=print):
    """Logits at positions start .. len(ids) - 1, transformers' Gemma 4 text layers one at a time (fp32).
    get(name): a language-model tensor by its checkpoint name below `model.language_model.` (fp32);
    rows(table, ids): rows of the token embedding ("embed") or the per-layer embedding ("ple"), fp32."""
    from transformers.masking_utils import create_causal_mask, create_sliding_window_causal_mask
    from transformers.models.gemma4.modeling_gemma4 import (Gemma4RMSNorm, Gemma4TextDecoderLayer, Gemma4TextModel,
                                                            Gemma4TextRotaryEmbedding, Gemma4TextScaledWordEmbedding)

    tc._attn_implementation = "eager"
    T, L, D, PL = len(ids), tc.num_hidden_layers, tc.hidden_size, tc.hidden_size_per_layer_input
    uniq = sorted(set(ids))
    remap = torch.tensor([uniq.index(t) for t in ids])[None]
    with torch.no_grad():
        emb = Gemma4TextScaledWordEmbedding(len(uniq), D, None, embed_scale=D**0.5)
        emb.weight.copy_(rows("embed", uniq))
        x = emb(remap)
        ple = Gemma4TextScaledWordEmbedding(len(uniq), L * PL, None, embed_scale=PL**0.5)
        ple.weight.copy_(rows("ple", uniq))
        ple_raw = ple(remap).reshape(1, T, L, PL)

        with torch.device("meta"):
            tm = Gemma4TextModel(tc)
        tm.per_layer_model_projection = torch.nn.Linear(D, L * PL, bias=False)
        tm.per_layer_model_projection.weight.copy_(get("per_layer_model_projection.weight"))
        tm.per_layer_projection_norm = Gemma4RMSNorm(PL, eps=tc.rms_norm_eps)
        tm.per_layer_projection_norm.weight.copy_(get("per_layer_projection_norm.weight"))
        pli = tm.project_per_layer_inputs(x, ple_raw)

        pos = torch.arange(T)[None]
        rot = Gemma4TextRotaryEmbedding(tc)
        pe = {t: rot(x, pos, t) for t in set(tc.layer_types)}
        kw = dict(config=tc, inputs_embeds=x, attention_mask=None, past_key_values=None, position_ids=pos)
        masks = {"full_attention": create_causal_mask(**kw), "sliding_attention": create_sliding_window_causal_mask(**kw)}
        shared = {}
        h = x
        t0 = time.time()
        for i in range(L):
            with torch.device("meta"):
                layer = Gemma4TextDecoderLayer(tc, i)
            layer = layer.to_empty(device="cpu")
            layer.load_state_dict({k: get(f"layers.{i}.{k}") for k in layer.state_dict()}, strict=True)
            h = layer(h, pli[:, :, i, :], shared_kv_states=shared, position_embeddings=pe[tc.layer_types[i]],
                      attention_mask=masks[tc.layer_types[i]], position_ids=pos, past_key_values=None)
            del layer
        log(f"reference: {L} layers over {T} tokens in {time.time() - t0:.1f} s")
        norm = Gemma4RMSNorm(D, eps=tc.rms_norm_eps)
        norm.weight.copy_(get("norm.weight"))
        hn = norm(h[0, start:])
        head = get("embed_tokens.weight")
        logits = hn @ head.T
        cap = tc.final_logit_softcapping
        if cap is not None:
            logits = torch.tanh(logits / cap) * cap
    return logits


class Gemma4Weights:
    """A checkpoint's language-model tensors for forward(): the GPU's (int4 dequantized from gemma4.bin) or bf16."""

    def __init__(self, model, bf16, binpath=None, keep=()):
        self.keep = set(keep)  # int4 groups read as bf16 instead (an ablation): head, ple, attn, mlp
        self.dir = ROOT / "build/gemma4" / model
        self.sparse = Sparse(model)
        self.header = json.loads((self.dir / "header.json").read_text())
        self.bf16 = bf16
        self.tensors, self.tables, self.layers = {}, {}, {}
        lines = (self.dir / "manifest.txt").read_text().splitlines()
        f = lines[0].split()
        self.cfg = {f[i]: f[i + 1] for i in range(2, len(f), 2)}
        for line in lines[1:]:
            f = line.split()
            if f[0] == "layer":
                self.layers[int(f[1])] = (f[2] == "sliding", int(f[3]), int(f[4]), int(f[5]))
            elif f[0] == "table":
                self.tables[f[1]] = (int(f[2]), int(f[3]), int(f[4]))
            else:
                self.tensors[f[0]] = (int(f[1]), int(f[2]), f[3], [int(s) for s in f[4].split("x")])
        self.bin = None
        if not bf16:
            self.bin = np.memmap(binpath or self.dir / "gemma4.bin", np.uint8, "r")
        self.H, self.KVH = int(self.cfg["H"]), int(self.cfg["KVH"])

    def ckpt(self, name):
        e = self.header[P + name]
        assert e["dtype"] == "BF16", name
        a, b = e["data_offsets"]
        raw = np.frombuffer(self.sparse.read(self.header["__base__"] + a, b - a), np.uint16)
        return torch.from_numpy((raw.astype(np.uint32) << 16).view(np.float32).reshape(e["shape"]).copy())

    def q4(self, name):
        off, n, _, (rows, words) = self.tensors[name + ".q"]
        q = np.frombuffer(self.bin, np.uint32, rows * words, off).reshape(rows, words)
        soff, sn, _, (_, groups) = self.tensors[name + ".s"]
        s = np.frombuffer(self.bin, np.float16, rows * groups, soff).reshape(rows, groups).astype(np.float32)
        nib = ((q[:, :, None] >> (4 * np.arange(8, dtype=np.uint32))) & 15).astype(np.int32)
        w = ((nib ^ 8) - 8).astype(np.float32).reshape(rows, words * 8)
        w = (w.reshape(rows, groups, -1) * s[:, :, None]).reshape(rows, words * 8)
        return torch.from_numpy(w)

    def group(self, name):
        if name == "embed_tokens.weight":
            return "head"
        if "per_layer" in name:
            return "ple"
        if "self_attn" in name:
            return "attn"
        if "mlp" in name:
            return "mlp"
        return None

    def get(self, name):
        if self.bf16 or self.group(name) in self.keep:
            return self.ckpt(name)
        if name == "embed_tokens.weight":
            return self.q4("head")
        if name == "per_layer_model_projection.weight":
            return self.q4("ple_proj")
        if name.startswith("layers."):
            _, i, rest = name.split(".", 2)
            i = int(i)
            _, f, _, hd = self.layers[i]
            simple = {"self_attn.o_proj.weight": "o", "mlp.down_proj.weight": "down",
                      "per_layer_input_gate.weight": "pg", "per_layer_projection.weight": "pp"}
            if rest in simple:
                return self.q4(f"l{i}.{simple[rest]}")
            if rest in ("self_attn.q_proj.weight", "self_attn.k_proj.weight", "self_attn.v_proj.weight"):
                qkv = self.q4(f"l{i}.qkv")
                hq, hk = self.H * hd, self.KVH * hd
                return {"q": qkv[:hq], "k": qkv[hq:hq + hk], "v": qkv[hq + hk:hq + 2 * hk]}[rest[10]]
            if rest in ("mlp.gate_proj.weight", "mlp.up_proj.weight"):
                gu = self.q4(f"l{i}.gu")
                return gu[:f] if "gate" in rest else gu[f:]
        return self.ckpt(name)  # norms and layer scalars: the GPU's fp32 copies are these bf16 values, widened

    def rows(self, table, ids):
        off, n, cols = self.tables[table]
        out = np.empty((len(ids), cols), np.float32)
        for j, t in enumerate(ids):
            raw = np.frombuffer(self.sparse.read(off + t * cols * 2, cols * 2), np.uint16)
            out[j] = (raw.astype(np.uint32) << 16).view(np.float32)
        return torch.from_numpy(out)


def selftest():
    """This layer-at-a-time driver against transformers' whole Gemma4ForCausalLM, on a tiny random model with E2B's
    structure: sliding and full layers, head dims 32 and 64, proportional RoPE, KV shared by the last layers, a
    double-wide MLP there, per-layer inputs, layer scalars, soft-capped logits, and a prompt longer than the window."""
    from transformers.models.gemma4.configuration_gemma4 import Gemma4TextConfig
    from transformers.models.gemma4.modeling_gemma4 import Gemma4ForCausalLM

    torch.manual_seed(0)
    types = ["sliding_attention", "sliding_attention", "full_attention", "sliding_attention", "full_attention",
             "sliding_attention", "sliding_attention", "full_attention"]
    tc = Gemma4TextConfig(vocab_size=300, vocab_size_per_layer_input=300, hidden_size=128, intermediate_size=192,
                          num_hidden_layers=8, num_attention_heads=4, num_key_value_heads=2, head_dim=32,
                          global_head_dim=64, layer_types=types, num_kv_shared_layers=3, sliding_window=5,
                          hidden_size_per_layer_input=16, use_double_wide_mlp=True, final_logit_softcapping=30.0,
                          rope_parameters={"full_attention": {"partial_rotary_factor": 0.25, "rope_theta": 1e6,
                                                              "rope_type": "proportional"},
                                           "sliding_attention": {"rope_theta": 1e4, "rope_type": "default"}},
                          tie_word_embeddings=True)
    tc._attn_implementation = "eager"
    m = Gemma4ForCausalLM(tc).eval()
    with torch.no_grad():
        for name, p in m.named_parameters():
            if "norm" in name:
                p.copy_(1 + 0.3 * torch.randn_like(p))
        for layer in m.model.layers:
            layer.layer_scalar.fill_(0.5 + torch.rand(()).item())
    ids = torch.randint(0, 300, (1, 13))
    with torch.no_grad():
        want = m(ids).logits[0]
    sd = m.state_dict()
    got = forward(tc, lambda n: sd["model." + n], lambda t, u: sd["model.embed_tokens" + ("_per_layer" if t == "ple" else "") + ".weight"][u],
                  ids[0].tolist(), 0, log=lambda s: None)
    err = (got - want).abs().max().item()
    print(f"selftest: max |driver - Gemma4ForCausalLM| = {err:.2e} over {tuple(want.shape)} logits (range "
          f"{want.min().item():.2f} .. {want.max().item():.2f})")
    assert err < 1e-4


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", choices=MODELS, default="e2b")
    ap.add_argument("--ids", type=int, nargs="*")
    ap.add_argument("--ids-file", type=pathlib.Path)
    ap.add_argument("--start", type=int, default=0, help="first position whose logits are kept")
    ap.add_argument("--bf16", action="store_true", help="the checkpoint's bf16 weights instead of the GPU's int4")
    ap.add_argument("--keep", default="", help="int4 groups to read as bf16 instead: head,ple,attn,mlp")
    ap.add_argument("--bin", type=pathlib.Path, help="gemma4.bin (default build/gemma4/<model>/gemma4.bin)")
    ap.add_argument("--out", type=pathlib.Path)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        selftest()
        return
    from transformers import AutoConfig

    ids = a.ids if a.ids else [int(t) for t in a.ids_file.read_text().split()]
    w = Gemma4Weights(a.model, a.bf16, a.bin, [k for k in a.keep.split(",") if k])
    tc = AutoConfig.from_pretrained(w.dir).get_text_config()
    torch.set_num_threads(8)
    logits = forward(tc, w.get, w.rows, ids, a.start)
    if a.out:
        np.save(a.out, logits.numpy())
    am = logits.argmax(-1).tolist()
    print("argmax:", " ".join(map(str, am)))


if __name__ == "__main__":
    main()
