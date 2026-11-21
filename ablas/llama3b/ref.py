"""fp32 reference for the Llama 3.2 3B prefill benchmark, with the weights the phone uses (fp16-rounded or
Q4_0-dequantized linears and embedding; fp32 norms), built from transformers' own LlamaDecoderLayer /
LlamaRotaryEmbedding / LlamaRMSNorm, one layer in memory at a time (an fp32 3B model does not fit beside the rest).
  python ref.py tokens                -> ref/tokens.bin (int32, 4096 tokens of this repo's blog posts)
  python ref.py f16|q4 M              -> ref/<fmt>_<M>/logits.npy (last token), hidden.npy (final norm, [M, D])
  python ref.py cmp f16|q4 M DIR      -> compare DIR/logits.bin, DIR/hidden.bin (from llama3b -o) to the reference
"""
import glob, pathlib, sys
import numpy as np
import torch
from safetensors import safe_open

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
SNAP = glob.glob(str(pathlib.Path.home() / ".cache/huggingface/hub/models--unsloth--Llama-3.2-3B-Instruct/snapshots/*"))[0]
OUT = HERE / "ref"

def weights():
    idx = {}
    for f in sorted(glob.glob(SNAP + "/*.safetensors")):
        with safe_open(f, framework="pt") as s:
            for k in s.keys():
                idx[k] = f
    def get(name):
        with safe_open(idx[name], framework="pt") as s:
            return s.get_tensor(name).float()
    return get

def device_weight(w, fmt):
    if fmt == "f16":
        return w.half().float()
    from q4ref import quant_q4_0, dequant_q4_0
    q, d = quant_q4_0(w.numpy())
    return torch.from_numpy(dequant_q4_0(q, d))

def tokens():
    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained(SNAP)
    root = HERE.parents[1]
    text = "\n\n".join(open(root / f).read() for f in ("BLOG-ABLAS.md", "BLOG-COOPMAT.md", "BLOG.md"))
    ids = tok(text).input_ids
    assert len(ids) >= 4096, len(ids)
    OUT.mkdir(exist_ok=True)
    np.array(ids[:4096], np.int32).tofile(OUT / "tokens.bin")
    print(len(ids), "tokens; first", ids[:8], repr(tok.decode(ids[:24])))

@torch.no_grad()
def run(fmt, M):
    from transformers import LlamaConfig
    from transformers.models.llama.modeling_llama import LlamaDecoderLayer, LlamaRotaryEmbedding, LlamaRMSNorm
    import json
    cfg = LlamaConfig(**json.load(open(SNAP + "/config.json")))
    cfg._attn_implementation = "eager"
    get = weights()
    ids = torch.from_numpy(np.fromfile(OUT / "tokens.bin", np.int32)[:M].astype(np.int64))
    emb = device_weight(get("model.embed_tokens.weight"), fmt)
    h = emb[ids][None]                                     # [1, M, D]
    pos = torch.arange(M)[None]
    cos, sin = LlamaRotaryEmbedding(cfg)(h, pos)
    mask = torch.full((M, M), float("-inf")).triu(1)[None, None]
    xs = []
    for i in range(cfg.num_hidden_layers):
        layer = LlamaDecoderLayer(cfg, i).float().eval()
        sd = {}
        p = f"model.layers.{i}."
        for k in layer.state_dict():
            w = get(p + k)
            sd[k] = w if "norm" in k else device_weight(w, fmt)
        layer.load_state_dict(sd)
        out = layer(h, attention_mask=mask, position_ids=pos, position_embeddings=(cos, sin))
        h = out[0] if isinstance(out, tuple) else out
        xs.append(h[0].half().numpy())
        print("layer", i, float(h.abs().max()), flush=True)
    norm = LlamaRMSNorm(cfg.hidden_size, cfg.rms_norm_eps)
    norm.weight.copy_(get("model.norm.weight"))
    hid = norm(h)[0]
    logits = hid[-1] @ emb.T
    d = OUT / f"{fmt}_{M}"
    d.mkdir(parents=True, exist_ok=True)
    np.save(d / "logits.npy", logits.numpy())
    np.save(d / "hidden.npy", hid.numpy())
    np.save(d / "x_layers.npy", np.stack(xs))  # residual after each layer (fp16 to keep it small)
    print("saved", d, "top5", torch.topk(logits, 5).indices.tolist())

def cmp(fmt, M, ddir):
    d = OUT / f"{fmt}_{M}"
    rl, rh = np.load(d / "logits.npy"), np.load(d / "hidden.npy")
    dl = np.fromfile(pathlib.Path(ddir) / "logits.bin", np.float32)
    dh = np.fromfile(pathlib.Path(ddir) / "hidden.bin", np.float32).reshape(M, -1)
    cos = lambda a, b: float((a * b).sum() / np.linalg.norm(a) / np.linalg.norm(b))
    rows = (dh * rh).sum(1) / np.linalg.norm(dh, axis=1) / np.linalg.norm(rh, axis=1)
    # next-token agreement on every position would need all logits; compare top-1 on the last token + top-5 overlap
    t5r, t5d = np.argsort(-rl)[:5], np.argsort(-dl)[:5]
    p = np.exp(rl - rl.max()); p /= p.sum(); q = np.exp(dl - dl.max()); q /= q.sum()
    kl = float((p * (np.log(p + 1e-30) - np.log(q + 1e-30))).sum())
    print(f"{fmt} M={M}: logits cos {cos(rl, dl):.5f}, max |diff| {np.abs(rl - dl).max():.3f}, top-1 ref {t5r[0]} dev {t5d[0]}, "
          f"top-5 overlap {len(set(t5r) & set(t5d))}/5, KL(ref||dev) {kl:.4f}; hidden rows cos min {rows.min():.4f} "
          f"mean {rows.mean():.5f}")

if __name__ == "__main__":
    if sys.argv[1] == "tokens":
        tokens()
    elif sys.argv[1] == "cmp":
        cmp(sys.argv[2], int(sys.argv[3]), sys.argv[4])
    else:
        run(sys.argv[1], int(sys.argv[2]))
