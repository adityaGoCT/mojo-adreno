"""LFM2.5-2.6B on the phone's Adreno: tokenize a chat prompt, run lfm2 (the Mojo program, on the phone), print the text
and the phone's timings, and check the logits against reference.py on the Mac.

  build/vla/venv/bin/python lfm2/run.py [--config gpu|hybrid|npu] [--storage q4|f16] [--prompt TEXT | --prompt-file F]
                                        [--tokens 64] [--prefill] [--warm 1] [--check] [--name NAME]

--config gpu runs lfm2 (all on the Adreno, --storage q4 or f16); hybrid runs lfm2_hybrid (the prompt on the NPU,
w8a16 graphs, decode on the Adreno, q4); npu runs lfm2_npu (prefill and decode on the NPU). The NPU programs live in
/data/local/tmp/lfm2/qnn with QNN, ONNX Runtime and MAX's runtime; their graphs and contexts in .../npu.

The phone (ANDROID_SERIAL) holds /data/local/tmp/lfm2: lfm2/ (android/build.py lfm2's directory), qad_q4_0.gguf
(downloaded there), rope.f32, and q4/ and f16/ with export.py's manifest and recipe and lfm2_convert's weight file.
--check pulls the logits the phone wrote after the prompt and after generated tokens (--rows of them, 0.5 MB each) and
compares them with reference.py's on the same weights: the GGUF's, dequantized (q4), or those rounded to fp16 (f16);
and checks that every generated token is the reference's argmax. It also writes build/lfm2/runs/<name>.json, which
fp32_check.py reads to compare every run against the fp32 QAD model in one pass over its (streamed) weights.
"""

import argparse
import json
import pathlib
import re
import subprocess
import sys

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2"))
PHONE = "/data/local/tmp/lfm2"
RUNS = ROOT / "build/lfm2/runs"
EOS = (124900, 7)  # <|im_end|>, <|endoftext|>
SKY = "Explain in two sentences why the sky is blue."


def adb(*args, check=True):
    r = subprocess.run(["adb", *args], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"adb {' '.join(args)}: {r.stderr}")
    return r.stdout


def tokenizer():
    from transformers import AutoTokenizer
    return AutoTokenizer.from_pretrained(ROOT / "build/lfm2")


def chat_ids(tok, text):
    ids = tok.apply_chat_template([{"role": "user", "content": text}], tokenize=True, add_generation_prompt=True)
    if not isinstance(ids, list):
        ids = ids["input_ids"]
    return list(ids)


def softmax_kl(p_logits, q_logits):
    """KL(p || q) of two logit rows, in float64."""
    a = p_logits.astype(np.float64)
    b = q_logits.astype(np.float64)
    la = a - a.max() - np.log(np.exp(a - a.max()).sum())
    lb = b - b.max() - np.log(np.exp(b - b.max()).sum())
    return float((np.exp(la) * (la - lb)).sum())


def run_phone(storage, ids, tokens, prefill, warm, rows, eos=True, extra_env=(), config="gpu"):
    """Runs lfm2 (or lfm2_hybrid, lfm2_npu) on the phone; returns (tokens, prompt ms, decode ms/token, logit rows,
    every, log)."""
    adb("shell", f"mkdir -p {PHONE}/runs")
    ids_file = RUNS / "ids.txt"
    RUNS.mkdir(parents=True, exist_ok=True)
    ids_file.write_text(" ".join(str(i) for i in ids) + "\n")
    adb("push", str(ids_file), f"{PHONE}/runs/ids.txt")
    every = max(1, -(-tokens // rows)) if rows else 0
    env = [f"LD_LIBRARY_PATH={PHONE}/lfm2", f"MODULAR_DRIVER_PLUGINS=vulkan@{PHONE}/lfm2/libM_driver_vulkan.so"]
    if eos:
        env.append("LFM2_EOS=" + ",".join(str(e) for e in EOS))
    if prefill:
        env.append("LFM2_PREFILL=1")
    if warm:
        env.append(f"LFM2_WARM={warm}")
    if rows:
        env.append(f"LFM2_LOGITS={PHONE}/runs/logits.f32")
        env.append(f"LFM2_LOGITS_EVERY={every}")
        adb("shell", f"rm -f {PHONE}/runs/logits.f32")
    env += list(extra_env)
    if config == "gpu":
        cmd = (f"cd {PHONE}; {' '.join(env)} ./lfm2/lfm2 {PHONE}/{storage} {PHONE}/{storage}/lfm2_{storage}.bin "
               f"{tokens} @{PHONE}/runs/ids.txt > runs/log.txt 2>&1; echo exit $? >> runs/log.txt")
    else:
        q = f"{PHONE}/qnn"
        env[0] = f"LD_LIBRARY_PATH={q}:/system/lib64:/vendor/lib64 ADSP_LIBRARY_PATH={q}"
        env[1] = f"MODULAR_DRIVER_PLUGINS=vulkan@{q}/libM_driver_vulkan.so"
        args = (f"{q}/lfm2_hybrid {PHONE}/npu {PHONE}/qad_q4_0.gguf {PHONE}/q4 {PHONE}/q4/lfm2_q4.bin" if
                config == "hybrid" else f"{q}/lfm2_npu {PHONE}/npu {PHONE}/qad_q4_0.gguf")
        cmd = (f"cd {PHONE}/npu; {' '.join(env)} {args} {tokens} @{PHONE}/runs/ids.txt > {PHONE}/runs/log.txt 2>&1; "
               f"echo exit $? >> {PHONE}/runs/log.txt")
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
        logits = np.fromfile(RUNS / "logits.f32", np.float32).reshape(-1, 128000)
    return toks, float(pm.group(1)), float(dm.group(1)) if dm else None, logits, every, log


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", choices=["gpu", "hybrid", "npu"], default="gpu")
    ap.add_argument("--storage", choices=["q4", "f16"], default="q4")
    ap.add_argument("--prompt", default=SKY)
    ap.add_argument("--prompt-file", type=pathlib.Path)
    ap.add_argument("--tokens", type=int, default=64)
    ap.add_argument("--prefill", action="store_true", help="the prompt in batches (LFM2_PREFILL)")
    ap.add_argument("--warm", type=int, default=1, help="untimed runs of the prompt first")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--rows", type=int, default=16, help="logit rows the phone keeps for --check (0.5 MB each)")
    ap.add_argument("--no-eos", action="store_true")
    ap.add_argument("--name", help="build/lfm2/runs/<name>.json for fp32_check.py")
    a = ap.parse_args()
    tok = tokenizer()
    text = a.prompt_file.read_text() if a.prompt_file else a.prompt
    ids = chat_ids(tok, text)
    P = len(ids)
    print(f"prompt: {P} tokens ({text[:60]!r}{'...' if len(text) > 60 else ''})")
    toks, prompt_ms, dec_ms, logits, every, log = run_phone(a.storage, ids, a.tokens, a.prefill, a.warm,
                                                            a.rows if a.check else 0, eos=not a.no_eos,
                                                            config=a.config)
    for line in log.splitlines():
        if line.startswith(("weights", "prompt", "decode", "warm", "npu", "prefill", "gpu", "handoff")):
            print("phone:", line)
    print("output:", repr(tok.decode(toks)))
    if not a.check:
        return
    from reference import forward
    from weights import GGUFWeights, config
    seq = ids + toks[:-1]
    W = GGUFWeights(round16=a.storage == "f16" and a.config == "gpu")
    ref = forward(config(), W, [(seq, P - 1)], log=lambda *x: None)[0].numpy()
    rows_at = list(range(0, len(toks), every))[:len(logits)]
    diff = max(float(np.abs(logits[r] - ref[i]).max()) for r, i in enumerate(rows_at))
    agree = sum(int(ref[i].argmax() == t) for i, t in enumerate(toks))
    kls = [softmax_kl(ref[i], logits[r]) for r, i in enumerate(rows_at)]
    lo, hi = float(ref.min()), float(ref.max())
    label = a.storage if a.config == "gpu" else a.config + " (vs the GGUF's int4 model)"
    print(f"{label}: phone logits within {diff:.2e} of the reference's at {len(rows_at)} positions "
          f"(range {lo:.1f} .. {hi:.1f}); mean KL {np.mean(kls):.2e}")
    print(f"greedy: {agree} of {len(toks)} phone tokens are the reference's argmax")
    if a.name:
        np.save(RUNS / f"{a.name}_logits.npy", logits)
        rec = dict(name=a.name, config=a.config if a.config != "gpu" else f"gpu-{a.storage}", storage=a.storage,
                   prefill=a.prefill, ids=ids,
                   tokens=toks, rows_at=rows_at, prompt_ms=prompt_ms, decode_ms=dec_ms, max_diff_ref=diff,
                   greedy_ref=[agree, len(toks)], logits=str(RUNS / f"{a.name}_logits.npy"))
        (RUNS / f"{a.name}.json").write_text(json.dumps(rec, indent=1))
        print("wrote", RUNS / f"{a.name}.json")


if __name__ == "__main__":
    main()
