"""Every recorded run (build/lfm2/runs/<name>.json, written by run.py --check --name) against the fp32 QAD model, the
checkpoint the GGUF was quantized from: reference.py's layers on qad/model.safetensors, streamed from Hugging Face in one
pass for all runs (10.8 GB; the Mac keeps none of it).

For each run, teacher-forced on the phone's own tokens:
  greedy agreement   at how many generated positions the fp32 model's argmax is the phone's token
  KL(fp32 || phone)  mean over the positions whose logits the phone wrote
and, for scale, the same two numbers for the GGUF's own int4 model (reference.py on the GGUF) on the same tokens:
what Q4_0 itself costs, before any device.

  build/vla/venv/bin/python lfm2/fp32_check.py [names...]     # default: every run; writes build/lfm2/runs/fp32.json
"""

import json
import pathlib
import sys

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2"))
from reference import forward  # noqa: E402
from run import RUNS, softmax_kl  # noqa: E402
from weights import Fp32Weights, GGUFWeights, config  # noqa: E402


def main():
    names = sys.argv[1:] or sorted(p.stem for p in RUNS.glob("*.json") if p.stem != "fp32")
    runs = [json.loads((RUNS / f"{n}.json").read_text()) for n in names]
    seqs, index = [], {}
    for r in runs:  # one forward per distinct sequence
        key = tuple(r["ids"] + r["tokens"][:-1])
        if key not in index:
            index[key] = len(seqs)
            seqs.append((list(key), len(r["ids"]) - 1))
    cfg = config()
    print(f"{len(runs)} runs, {len(seqs)} distinct sequences; the GGUF's int4 model first, then fp32 (streamed)")
    q4 = [lg.numpy() for lg in forward(cfg, GGUFWeights(), seqs, log=lambda *a: None)]
    W = Fp32Weights()
    fp = [lg.numpy() for lg in forward(cfg, W, seqs)]
    print(f"fp32: {W.bytes / 1e9:.1f} GB read")
    out = {}
    for r in runs:
        s = index[tuple(r["ids"] + r["tokens"][:-1])]
        toks = r["tokens"]
        phone = np.load(r["logits"])
        rows = r["rows_at"][:len(phone)]
        agree = sum(int(fp[s][i].argmax() == t) for i, t in enumerate(toks))
        kl = float(np.mean([softmax_kl(fp[s][i], phone[j]) for j, i in enumerate(rows)]))
        agree_q4 = sum(int(fp[s][i].argmax() == q4[s][i].argmax()) for i in range(len(toks)))
        kl_q4 = float(np.mean([softmax_kl(fp[s][i], q4[s][i]) for i in rows]))
        first = next((i for i, t in enumerate(toks) if fp[s][i].argmax() != t), None)
        out[r["name"]] = dict(config=r["config"], agree=[agree, len(toks)], kl=kl, first_diff=first,
                              gguf_agree=[agree_q4, len(toks)], gguf_kl=kl_q4)
        print(f"{r['name']} ({r['config']}): fp32's greedy choice agrees at {agree} of {len(toks)} positions "
              f"(first difference: {first}); mean KL(fp32 || phone) {kl:.4f} | the GGUF's int4 model on the same "
              f"tokens: {agree_q4} of {len(toks)}, KL {kl_q4:.4f}")
    (RUNS / "fp32.json").write_text(json.dumps(out, indent=1))


if __name__ == "__main__":
    main()
