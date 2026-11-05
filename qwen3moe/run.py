"""Qwen3-30B-A3B on the Snapdragon X2 Elite laptop's GPU: tokenize a chat prompt, run qwen3moe (the Mojo program on the
Mac, driving the laptop's vk_server through the remote plugin; the weights are read on the laptop from qwen3moe.bin),
print the text, and check it against reference.py run on the laptop (transformers' Qwen3-MoE layers, a layer at a time,
on the same int4 weights; --bf16: on the checkpoint's own weights).

  build/vla/venv/bin/python qwen3moe/run.py [--prompt TEXT] [--tokens 32] [--check] [--bf16] [--port 7791]

Needs vk_server.exe (qwen3moe/build_mac.sh's) running on the laptop and forwarded to --port, and the laptop's files
under C:\\Users\\HCKTest\\qwen3moe: hf\\ (the checkpoint), qwen3moe.bin (convert.exe), manifest.txt, reference.py, and a
Python with torch and transformers (C:\\Users\\HCKTest\\py).
"""

import argparse
import os
import pathlib
import re
import subprocess
import sys
import urllib.request

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/qwen3moe"
REPO = "Qwen/Qwen3-30B-A3B-Instruct-2507"
REV = "0d7cf23991f47feeb3a57ecb4c9cee8ea4a17bfe"
V = 151936
LAPTOP = "C:\\Users\\HCKTest\\qwen3moe"
PY = "C:\\Users\\HCKTest\\py\\tools\\python.exe"
KEY = os.environ.get("QDC_KEY", str(pathlib.Path.home() / "Downloads/qdc_id_2026-10-29_1446.pem"))
SSH = ["ssh", "-o", "BatchMode=yes", "-o", "ServerAliveInterval=30", "-p", "2222", "-i", KEY]
if os.environ.get("QDC_KNOWN_HOSTS"):
    SSH[1:1] = ["-o", "UserKnownHostsFile=" + os.environ["QDC_KNOWN_HOSTS"]]


def tokenizer():
    from transformers import AutoTokenizer
    d = B / "hf"
    d.mkdir(parents=True, exist_ok=True)
    for f in ("tokenizer.json", "tokenizer_config.json", "vocab.json", "merges.txt", "config.json"):
        if not (d / f).exists():
            (d / f).write_bytes(urllib.request.urlopen(f"https://huggingface.co/{REPO}/resolve/{REV}/{f}").read())
    return AutoTokenizer.from_pretrained(d)


def laptop(cmd):
    r = subprocess.run(SSH + ["HCKTest@localhost", cmd], capture_output=True, text=True)
    return r.stdout + r.stderr


def fetch(remote, local):
    scp = ["scp"] + SSH[1:]
    scp[scp.index("-p")] = "-P"
    subprocess.run(scp + [f"HCKTest@localhost:{remote}", str(local)], check=True, capture_output=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt", default="What is the capital of France? Answer in one sentence.")
    ap.add_argument("--tokens", type=int, default=32)
    ap.add_argument("--port", type=int, default=7791)
    ap.add_argument("--check", action="store_true", help="reference.py on the laptop: the same int4 weights")
    ap.add_argument("--bf16", action="store_true", help="also the checkpoint's bf16 weights (what int4 changes)")
    a = ap.parse_args()
    tok = tokenizer()
    ids = list(tok.apply_chat_template([{"role": "user", "content": a.prompt}], add_generation_prompt=True,
                                       return_dict=True)["input_ids"])
    print(f"prompt: {a.prompt!r}, {len(ids)} tokens")
    env = dict(os.environ, VK_REMOTE_PORT=str(a.port),
               MODULAR_DRIVER_PLUGINS=f"vulkan@{B / 'x2/libM_driver_vulkan_remote.dylib'}")
    logits_path = B / "gpu_logits.f32"
    if a.check:
        env["QWEN3MOE_LOGITS"] = str(logits_path)
    cmd = [str(B / "x2/qwen3moe"), str(B / "manifest.txt"), LAPTOP + "\\qwen3moe.bin", str(a.tokens)] + list(map(str, ids))
    out = subprocess.run(cmd, env=env, capture_output=True, text=True)
    print(out.stdout + out.stderr, end="")
    m = re.search(r"^ids: (.*)$", out.stdout, re.M)
    if not m:
        sys.exit("qwen3moe failed")
    gen = [int(t) for t in m.group(1).split()]
    end = gen.index(151645) if 151645 in gen else len(gen)  # <|im_end|>: the GPU generates on past it
    print("output:", repr(tok.decode(gen[:end])), f"({end} tokens to <|im_end|>)" if end < len(gen) else "")
    if not a.check:
        return
    seq = ",".join(map(str, ids + gen[:-1]))  # the last generated token is predicted, never fed
    for bf16 in ([False, True] if a.bf16 else [False]):
        name = "bf16" if bf16 else "int4"
        print(f"reference ({name} weights) on the laptop ...", flush=True)
        text = laptop(f"cd {LAPTOP} & {PY} reference.py --hf {LAPTOP}\\hf --bin {LAPTOP}\\qwen3moe.bin --manifest "
                      f"{LAPTOP}\\manifest.txt --tokens {seq} --prompt-len {len(ids)} --out {LAPTOP}\\ref_{name}.f32"
                      + (" --bf16" if bf16 else ""))
        print("\n".join(l for l in text.splitlines() if not l.startswith("layer ")))
        fetch(f"qwen3moe/ref_{name}.f32", B / f"ref_{name}.f32")  # scp: relative to the laptop user's home
        ref = np.fromfile(B / f"ref_{name}.f32", np.float32).reshape(-1, V)
        gpu = np.fromfile(logits_path, np.float32).reshape(-1, V)
        k = min(len(ref), len(gpu))
        same = sum(int(ref[i].argmax() == gpu[i].argmax()) for i in range(k))
        err = [float(np.abs(gpu[i] - ref[i]).max()) for i in range(k)]
        print(f"{name}: GPU logits within {max(err):.4f} of the reference's (range {float(ref.min()):.1f} .. "
              f"{float(ref.max()):.1f}); same argmax at {same} of {k} positions")
        if bf16:
            ref_ids = [int(r.argmax()) for r in ref]
            agree = next((i for i in range(k) if ref_ids[i] != gen[i]), k)
            print(f"bf16 model, teacher-forced on the GPU's tokens: its greedy choice matches the first {agree} of {k}")


if __name__ == "__main__":
    main()
