"""Qwen3.5-4B on the phone's Adreno: tokenize a chat prompt, run qwen3_5_4b (the Mojo program, on the phone), print the text
and the phone's timings; --name records the run (its tokens and the logit rows the phone wrote) for check.py, which
compares every recorded run with transformers on the Mac in one pass over the streamed checkpoints.

  build/vla/venv/bin/python qwen3_5_4b/run.py [--prompt TEXT | --prompt-file F] [--tokens 64] [--warm 1]
                                              [--rows 16] [--name NAME] [--no-think]

The phone (ANDROID_SERIAL) holds /data/local/tmp/q35: qwen3_5_4b/ (android/build.py qwen3_5_4b's directory), gguf/ (the
Q4_0 GGUF, downloaded there), rope.f32, and q4/ with export.py's manifest and recipe and qwen3_5_4b_convert's weight
file (stage_phone.sh).
"""

import argparse
import json
import pathlib
import re
import subprocess
import sys
import time

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "qwen3_5_4b"))
from weights import BUILD, HF, fetch_hf_files  # noqa: E402

PHONE = "/data/local/tmp/q35"
RUNS = BUILD / "runs"
EOS = (248046, 248044)  # <|im_end|>, <|endoftext|>
VOCAB = 248320
SKY = "Explain in two sentences why the sky is blue."


def adb(*args, check=True):
    r = subprocess.run(["adb", *args], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"adb {' '.join(args)}: {r.stderr}")
    return r.stdout


def battery():
    """The battery's temperature (C), dumpsys battery's tenths."""
    m = re.search(r"temperature: (\d+)", adb("shell", "dumpsys battery"))
    return int(m.group(1)) / 10


def cool(limit=30.0, every=15):
    """Waits until the battery reads <= limit C (timings drift as the phone warms: Qwen3-4B's lesson)."""
    t = battery()
    while t > limit:
        print(f"battery {t:.1f} C > {limit}: waiting", flush=True)
        time.sleep(every)
        t = battery()
    return t


def tokenizer():
    from transformers import AutoTokenizer
    fetch_hf_files()
    return AutoTokenizer.from_pretrained(HF)


def chat_ids(tok, text, think=True):
    ids = tok.apply_chat_template([{"role": "user", "content": text}], tokenize=True, add_generation_prompt=True,
                                  enable_thinking=think)
    if not isinstance(ids, list):
        ids = ids["input_ids"]
    return list(ids)


def run_phone(ids, tokens, prefill=True, warm=1, rows=0, eos=True, extra_env=()):
    """Runs qwen3_5_4b on the phone; returns (tokens, prompt ms, decode ms/token, logit rows, every, log)."""
    RUNS.mkdir(parents=True, exist_ok=True)
    (RUNS / "ids.txt").write_text(" ".join(str(i) for i in ids) + "\n")
    adb("shell", f"mkdir -p {PHONE}/runs")
    adb("push", str(RUNS / "ids.txt"), f"{PHONE}/runs/ids.txt")
    every = max(1, -(-tokens // rows)) if rows else 0
    env = [f"LD_LIBRARY_PATH={PHONE}/qwen3_5_4b",
           f"MODULAR_DRIVER_PLUGINS=vulkan@{PHONE}/qwen3_5_4b/libM_driver_vulkan.so"]
    if eos:
        env.append("QWEN35_EOS=" + ",".join(str(e) for e in EOS))
    if prefill:
        env.append("QWEN35_PREFILL=1")
    if warm:
        env.append(f"QWEN35_WARM={warm}")
    if rows:
        env += [f"QWEN35_LOGITS={PHONE}/runs/logits.f32", f"QWEN35_LOGITS_EVERY={every}"]
        adb("shell", f"rm -f {PHONE}/runs/logits.f32")
    env += list(extra_env)
    cmd = (f"cd {PHONE}; {' '.join(env)} ./qwen3_5_4b/qwen3_5_4b {PHONE}/q4 {PHONE}/q4/qwen3_5_4b_q4.bin {tokens} "
           f"@{PHONE}/runs/ids.txt > runs/log.txt 2>&1; echo exit $? >> runs/log.txt")
    adb("shell", cmd)
    log = adb("shell", f"cat {PHONE}/runs/log.txt")
    if "exit 0" not in log:
        sys.exit("phone run failed:\n" + log)
    toks = [int(m) for m in re.findall(r"^tok (\d+)", log, re.M)]
    pm = re.search(r"prompt: \d+ tokens in ([\d.]+) ms", log)
    dm = re.search(r"decode: \d+ steps, ([\d.]+) ms/token", log)
    logits = None
    if rows:
        adb("pull", f"{PHONE}/runs/logits.f32", str(RUNS / "logits.f32"))
        logits = np.fromfile(RUNS / "logits.f32", np.float32).reshape(-1, VOCAB)
    return toks, float(pm.group(1)), float(dm.group(1)) if dm else None, logits, every, log


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt", default=SKY)
    ap.add_argument("--prompt-file", type=pathlib.Path)
    ap.add_argument("--tokens", type=int, default=64)
    ap.add_argument("--token-by-token", action="store_true", help="the prompt a token at a time (no QWEN35_PREFILL)")
    ap.add_argument("--warm", type=int, default=1, help="untimed runs of the prompt first")
    ap.add_argument("--rows", type=int, default=0, help="logit rows the phone keeps (1 MB each) for check.py")
    ap.add_argument("--no-eos", action="store_true")
    ap.add_argument("--no-think", action="store_true", help="the chat template's enable_thinking=False")
    ap.add_argument("--env", nargs="*", default=[], help="extra QWEN35_* settings for the phone")
    ap.add_argument("--name", help="build/qwen3_5_4b/runs/<name>.json for check.py")
    ap.add_argument("--cool", type=float, default=30.0, help="wait for the battery to read <= this (C); 0: don't")
    a = ap.parse_args()
    tok = tokenizer()
    text = a.prompt_file.read_text() if a.prompt_file else a.prompt
    ids = chat_ids(tok, text, think=not a.no_think)
    P = len(ids)
    print(f"prompt: {P} tokens ({text[:60]!r}{'...' if len(text) > 60 else ''})")
    if a.cool:
        print(f"battery {cool(a.cool):.1f} C")
    toks, prompt_ms, dec_ms, logits, every, log = run_phone(ids, a.tokens, not a.token_by_token, a.warm, a.rows,
                                                            eos=not a.no_eos, extra_env=a.env)
    for line in log.splitlines():
        if line.startswith(("weights", "prompt", "decode", "warm", "mem", "profile")):
            print("phone:", line)
    print("output:", repr(tok.decode(toks)))
    if a.name:
        rows_at = list(range(0, len(toks), every))[:len(logits)] if logits is not None else []
        if logits is not None:
            np.save(RUNS / f"{a.name}_logits.npy", logits)
        rec = dict(name=a.name, prefill=not a.token_by_token, ids=ids, tokens=toks, rows_at=rows_at,
                   prompt_ms=prompt_ms, decode_ms=dec_ms, env=a.env,
                   logits=str(RUNS / f"{a.name}_logits.npy") if logits is not None else None)
        (RUNS / f"{a.name}.json").write_text(json.dumps(rec, indent=1))
        print("wrote", RUNS / f"{a.name}.json")


if __name__ == "__main__":
    main()
