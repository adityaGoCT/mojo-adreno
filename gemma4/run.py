"""Gemma 4 E2B / E4B on the phone's Adreno: tokenize a chat prompt, run gemma4 (the Mojo program, on the phone), print
the text and the phone's timings, and check it against reference.py on the Mac (transformers' Gemma 4 layers, a layer at
a time, on the same int4 weights; --bf16 also on the checkpoint's own bf16 weights).

  build/vla/venv/bin/python gemma4/run.py --model e2b [--prompt TEXT | --prompt-file F] [--tokens 48] [--prefill]
                                          [--check] [--bf16]

The phone (ANDROID_SERIAL) holds /data/local/tmp/gemma4: gemma4/ (android/build.py gemma4's directory) and <model>/:
model.safetensors (downloaded there), gemma4.bin (gemma4_convert's), manifest.txt and the rope tables (export.py's).
--check pulls the logits the phone wrote after the prompt and after each generated token, and compares them with
the reference's at the same positions: the largest difference, and whether each generated token is the reference's
argmax. --bf16 runs the original bf16 weights on the same tokens (teacher-forced) and counts where their greedy choice
agrees with the phone's tokens, and the mean KL divergence between the two models' next-token distributions.
"""

import argparse
import pathlib
import re
import subprocess
import sys
import time

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "gemma4"))
from export import MODELS  # noqa: E402

PHONE = "/data/local/tmp/gemma4"
PY = str(ROOT / "build/vla/venv/bin/python")


def adb(*args, check=True):
    r = subprocess.run(["adb", *args], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"adb {' '.join(args)}: {r.stderr}")
    return r.stdout


def tokenize(model, text):
    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained(ROOT / "build/gemma4" / model)
    ids = tok.apply_chat_template([{"role": "user", "content": text}], tokenize=True, add_generation_prompt=True)
    if not isinstance(ids, list):
        ids = ids["input_ids"]
    return tok, list(ids)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", choices=MODELS, default="e2b")
    ap.add_argument("--prompt", default="Explain in two sentences why the sky is blue.")
    ap.add_argument("--prompt-file", type=pathlib.Path)
    ap.add_argument("--tokens", type=int, default=48)
    ap.add_argument("--prefill", action="store_true", help="the prompt in batches (GEMMA4_PREFILL)")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--bf16", action="store_true")
    ap.add_argument("--rows", type=int, default=8, help="logit rows the phone keeps for --check (1 MB each)")
    ap.add_argument("--no-eos", action="store_true", help="generate --tokens even past an end of turn")
    a = ap.parse_args()
    text = a.prompt_file.read_text() if a.prompt_file else a.prompt
    tok, ids = tokenize(a.model, text)
    P = len(ids)
    print(f"prompt: {P} tokens ({text[:60]!r}{'...' if len(text) > 60 else ''})")

    d = f"{PHONE}/{a.model}"
    env = [f"MODULAR_DRIVER_PLUGINS=vulkan@{PHONE}/gemma4/libM_driver_vulkan.so"]
    if not a.no_eos:
        env.append("GEMMA4_EOS=1,106,50")
    every = max(1, -(-a.tokens // a.rows))
    if a.check or a.bf16:
        env.append(f"GEMMA4_LOGITS={d}/logits.f32")
        env.append(f"GEMMA4_LOGITS_EVERY={every}")
        adb("shell", f"rm -f {d}/logits.f32")
    if a.prefill:
        env.append("GEMMA4_PREFILL=1")
    # one plain command per adb shell line (the lab's bridge drops lines with && or a bare &, and a long prompt's
    # ids on the line dropped it too: they go in a file)
    idfile = ROOT / "build/gemma4" / a.model / "prompt.ids"
    idfile.write_text(" ".join(map(str, ids)) + "\n")
    adb("push", str(idfile), f"{d}/prompt.ids")
    adb("shell", f"cd {PHONE}/gemma4; {' '.join(env)} ./gemma4 {d} {d}/model.safetensors {a.tokens} @{d}/prompt.ids "
                 f"> {d}/run.log 2>&1; echo exit $? >> {d}/run.log")
    log = adb("shell", f"cat {d}/run.log")
    for line in log.splitlines():
        if not line.startswith("tok "):
            print("phone:", line)
    gen = [int(m.group(1)) for m in re.finditer(r"^tok (\d+)", log, re.M)]
    if "exit 0" not in log or not gen:
        sys.exit("the phone's run failed")
    print("output:", repr(tok.decode(gen)))
    if not (a.check or a.bf16):
        return

    local = ROOT / "build/gemma4" / a.model / "phone_logits.f32"
    adb("pull", f"{d}/logits.f32", str(local))
    V = 262144
    phone = np.fromfile(local, np.float32).reshape(-1, V)
    n = len(gen)  # the reference's logits after the prompt and after each generated token but the last
    rows = list(range(0, n, every))  # the positions whose logits the phone kept
    assert phone.shape[0] == len(rows), (phone.shape, len(rows))
    seq = ids + gen[:n - 1]
    (local.parent / "check.ids").write_text(" ".join(map(str, seq)))
    runs = [("int4", [])] + ([("bf16", ["--bf16"])] if a.bf16 else [])
    for name, extra in runs:
        out = local.parent / f"ref_{name}.npy"
        t0 = time.time()
        r = subprocess.run([PY, str(ROOT / "gemma4/reference.py"), "--model", a.model, "--ids-file",
                            str(local.parent / "check.ids"), "--start", str(P - 1), "--out", str(out), *extra],
                           capture_output=True, text=True)
        if r.returncode:
            sys.exit(r.stdout + r.stderr)
        ref = np.load(out)
        assert ref.shape == (n, V), (ref.shape, n)
        am = ref.argmax(-1)
        same = int((am == np.array(gen[:n])).sum())
        if name == "int4":
            err = np.abs(ref[rows] - phone).max(-1)
            print(f"int4: phone logits within {err.max():.2e} of the reference's at {len(rows)} positions (all "
                  f"{V} logits; range {ref[rows].min():.1f} .. {ref[rows].max():.1f}; median position "
                  f"{np.median(err):.2e}), reference in {time.time() - t0:.0f} s")
            print(f"greedy: {same} of {n} phone tokens are the int4 reference's argmax")
            bad = [i for i in range(n) if am[i] != gen[i]]
            for i in bad[:5]:
                top = np.argsort(-ref[i])[:2]
                print(f"  position {P - 1 + i}: phone {gen[i]}, reference {am[i]} (reference top-2 margin "
                      f"{ref[i, top[0]] - ref[i, top[1]]:.4f})")
        else:
            q = np.load(local.parent / "ref_int4.npy")

            def logp(z):
                z = z - z.max(-1, keepdims=True)
                return z - np.log(np.exp(z).sum(-1, keepdims=True))
            lp, lq = logp(ref.astype(np.float64)), logp(q.astype(np.float64))
            kl = (np.exp(lp) * (lp - lq)).sum(-1)
            first = next((i for i in range(n) if am[i] != gen[i]), None)
            print(f"bf16: the original model's greedy choice agrees with the phone's token at {same} of {n} positions "
                  f"(teacher-forced on the phone's tokens; first difference: "
                  f"{'none' if first is None else f'position {P - 1 + first}'}); mean KL(bf16 || int4) {kl.mean():.4f}")

if __name__ == "__main__":
    main()
