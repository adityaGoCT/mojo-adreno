"""Every recorded run (build/qwen3_4b/runs/<name>.json, written by run.py --name) against transformers, teacher-forced
on the phone's own tokens, in one pass over the checkpoint streamed from Hugging Face (reference.py, both views):

  vs q4 (the same int4 weights, dequantized)   max |logit difference| at the rows the phone wrote, and at how many
                                               generated positions the reference's argmax is the phone's token
  vs bf16 (the published model, fp32 math)     greedy agreement, max |logit difference|, mean KL(bf16 || phone)
and, for scale, what the int4 weights alone cost: the q4 reference's agreement with and KL from bf16.

  build/vla/venv/bin/python qwen3_4b/check.py [names...]     # default: every run; writes build/qwen3_4b/runs/check.json

The reference logits of each sequence are kept (build/qwen3_4b/runs/ref/<sha1 of the tokens>_{bf16,q4}.npy, 0.6 MB a
position), so a later run that generates the same tokens is checked without streaming the checkpoint again.
"""

import hashlib
import json
import pathlib
import sys

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "qwen3_4b"))
from reference import forward  # noqa: E402
from run import RUNS  # noqa: E402
from weights import Bf16Weights, config  # noqa: E402


def softmax_kl(p_logits, q_logits):
    """KL(p || q) of two logit rows, in float64."""
    a = p_logits.astype(np.float64)
    b = q_logits.astype(np.float64)
    la = a - a.max() - np.log(np.exp(a - a.max()).sum())
    lb = b - b.max() - np.log(np.exp(b - b.max()).sum())
    return float((np.exp(la) * (la - lb)).sum())


def main():
    names = sys.argv[1:] or sorted(p.stem for p in RUNS.glob("*.json") if p.stem != "check")
    runs = [json.loads((RUNS / f"{n}.json").read_text()) for n in names]
    seqs, index = [], {}
    for r in runs:  # one forward per distinct sequence
        key = tuple(r["ids"] + r["tokens"][:-1])
        if key not in index:
            index[key] = len(seqs)
            seqs.append((list(key), len(r["ids"]) - 1))
    cache = RUNS / "ref"
    cache.mkdir(parents=True, exist_ok=True)
    keys = [hashlib.sha1(json.dumps([ids, start]).encode()).hexdigest()[:16] for ids, start in seqs]
    todo = [i for i, k in enumerate(keys) if not (cache / f"{k}_q4.npy").exists()]
    print(f"{len(runs)} runs, {len(seqs)} distinct sequences, {len(todo)} not yet computed")
    if todo:
        W = Bf16Weights()
        print("one pass over the streamed checkpoint, bf16 and q4")
        new = forward(config(), W, [seqs[i] for i in todo])
        print(f"read {W.bytes / 1e9:.1f} GB")
        for n, i in enumerate(todo):
            for v in ("bf16", "q4"):
                np.save(cache / f"{keys[i]}_{v}.npy", new[v][n].numpy().astype(np.float32))
    res = {v: [np.load(cache / f"{k}_{v}.npy") for k in keys] for v in ("bf16", "q4")}
    out = {}
    for r in runs:
        s = index[tuple(r["ids"] + r["tokens"][:-1])]
        toks = r["tokens"]
        bf, q4 = res["bf16"][s], res["q4"][s]
        phone = np.load(r["logits"]) if r.get("logits") else np.zeros((0, bf.shape[1]), np.float32)
        rows = r["rows_at"][:len(phone)]
        n = len(toks)
        rec = dict(tokens=n, prompt=len(r["ids"]))
        rec["q4_agree"] = [sum(int(q4[i].argmax() == t) for i, t in enumerate(toks)), n]
        rec["bf16_agree"] = [sum(int(bf[i].argmax() == t) for i, t in enumerate(toks)), n]
        rec["q4_vs_bf16_agree"] = [sum(int(q4[i].argmax() == bf[i].argmax()) for i in range(n)), n]
        rec["first_bf16_diff"] = next((i for i, t in enumerate(toks) if bf[i].argmax() != t), None)
        if rows:
            rec["rows"] = len(rows)
            rec["q4_max_diff"] = max(float(np.abs(phone[j] - q4[i]).max()) for j, i in enumerate(rows))
            rec["q4_kl"] = float(np.mean([softmax_kl(q4[i], phone[j]) for j, i in enumerate(rows)]))
            rec["bf16_max_diff"] = max(float(np.abs(phone[j] - bf[i]).max()) for j, i in enumerate(rows))
            rec["bf16_kl"] = float(np.mean([softmax_kl(bf[i], phone[j]) for j, i in enumerate(rows)]))
            rec["q4_ref_bf16_kl"] = float(np.mean([softmax_kl(bf[i], q4[i]) for i in rows]))
            rec["logit_range"] = [float(q4[rows].min()), float(q4[rows].max())]
        out[r["name"]] = rec
        print(f"{r['name']}: {n} tokens after a {len(r['ids'])}-token prompt")
        if rows:
            print(f"  vs q4 (same int4 weights): logits within {rec['q4_max_diff']:.2e} at {len(rows)} rows "
                  f"(range {rec['logit_range'][0]:.1f} .. {rec['logit_range'][1]:.1f}), KL {rec['q4_kl']:.2e}; "
                  f"argmax = phone token at {rec['q4_agree'][0]} of {n}")
            print(f"  vs bf16: argmax = phone token at {rec['bf16_agree'][0]} of {n} (first difference at "
                  f"{rec['first_bf16_diff']}); max |logit diff| {rec['bf16_max_diff']:.2f}, KL {rec['bf16_kl']:.4f} | "
                  f"the q4 reference itself: {rec['q4_vs_bf16_agree'][0]} of {n}, KL {rec['q4_ref_bf16_kl']:.4f}")
        else:
            print(f"  argmax = phone token: q4 {rec['q4_agree'][0]} of {n}, bf16 {rec['bf16_agree'][0]} of {n}")
    prev = json.loads((RUNS / "check.json").read_text()) if (RUNS / "check.json").exists() else {}
    prev.update(out)
    (RUNS / "check.json").write_text(json.dumps(prev, indent=1))


if __name__ == "__main__":
    main()
