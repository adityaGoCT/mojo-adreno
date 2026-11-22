"""fp32 reference for a converted Hugging Face decoder LLM, with the weights the phone uses (Q4_0-dequantized or
fp16-rounded linears and embedding; fp32 norms and biases), through transformers' own model class. The model-agnostic
counterpart of ../llama3b/ref.py (needs torch + transformers: the llm-mlc env here).
  python ref_hf.py tokens HF_DIR OUT.bin             int32 ids of ../../BLOG-ABLAS.md etc. (ref.py's prompt text)
  python ref_hf.py run HF_DIR q4_0|f16 TOKENS N DIR  -> DIR/logits.npy (last token), DIR/hidden.npy (final norm)
  python ref_hf.py cmp DIR DEVDIR N                  compare plan_run -o's logits.bin / hidden.bin
"""
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))


def tokens(hf, out):
    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained(hf)
    root = HERE.parents[1]
    text = "\n\n".join(open(root / f).read() for f in ("BLOG-ABLAS.md", "BLOG-COOPMAT.md", "BLOG.md"))
    ids = tok(text).input_ids[:4096]
    np.array(ids, np.int32).tofile(out)
    print(len(ids), "tokens; first", ids[:8], repr(tok.decode(ids[:24])))


def run(hf, fmt, tpath, n, out):
    import torch
    from q4ref import dequant_q4_0, quant_q4_0
    from transformers import AutoModelForCausalLM
    m = AutoModelForCausalLM.from_pretrained(hf, dtype=torch.float32, attn_implementation="eager").eval()
    with torch.no_grad():
        for name, p in m.model.named_parameters():
            if p.dim() == 2:  # the linears and the (tied) embedding: as the phone holds them
                w = p.data.numpy()
                p.data.copy_(torch.from_numpy(dequant_q4_0(*quant_q4_0(w)) if fmt == "q4_0" else w.astype(np.float16).astype(np.float32)))
        ids = torch.from_numpy(np.fromfile(tpath, np.int32)[:n].astype(np.int64))[None]
        hid = m.model(input_ids=ids).last_hidden_state[0]
        logits = m.lm_head(hid[-1])
    d = pathlib.Path(out)
    d.mkdir(parents=True, exist_ok=True)
    np.save(d / "logits.npy", logits.numpy())
    np.save(d / "hidden.npy", hid.numpy())
    print("saved", d, "top5", torch.topk(logits, 5).indices.tolist())


def cmp(ref, dev, n):
    rl, rh = np.load(pathlib.Path(ref) / "logits.npy"), np.load(pathlib.Path(ref) / "hidden.npy")
    dl = np.fromfile(pathlib.Path(dev) / "logits.bin", np.float32)
    dh = np.fromfile(pathlib.Path(dev) / "hidden.bin", np.float32).reshape(n, -1)
    cos = lambda a, b: float((a * b).sum() / np.linalg.norm(a) / np.linalg.norm(b))  # noqa: E731
    rows = (dh * rh).sum(1) / np.linalg.norm(dh, axis=1) / np.linalg.norm(rh, axis=1)
    t5r, t5d = np.argsort(-rl)[:5], np.argsort(-dl)[:5]
    p = np.exp(rl - rl.max()); p /= p.sum()  # noqa: E702
    q = np.exp(dl - dl.max()); q /= q.sum()  # noqa: E702
    kl = float((p * (np.log(p + 1e-30) - np.log(q + 1e-30))).sum())
    print(f"N={n}: logits cos {cos(rl, dl):.5f}, max |diff| {np.abs(rl - dl).max():.3f}, top-1 ref {t5r[0]} dev {t5d[0]}, "
          f"top-5 overlap {len(set(t5r) & set(t5d))}/5, KL(ref||dev) {kl:.4f}; hidden rows cos min {rows.min():.4f} "
          f"(row {rows.argmin()}) mean {rows.mean():.5f}")


if __name__ == "__main__":
    a = sys.argv
    if a[1] == "tokens":
        tokens(a[2], a[3])
    elif a[1] == "run":
        run(a[2], a[3], a[4], int(a[5]), a[6])
    else:
        cmp(a[2], a[3], int(a[4]))
