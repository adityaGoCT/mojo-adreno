"""Run Ternary-Bonsai-8B (Qwen3-8B, ternary) on the phone's Adreno 840 with qwen3_vk.

  python qwen3/run.py --model M --hf H                    # validate against M's MLX reference
  python qwen3/run.py --model M --hf H --prompt 'Explain in two sentences why the sky is blue.'

M: qwen3/export.py's output, already on the phone in /data/local/tmp/q8 (weights.bin, manifest.txt,
reference.f32); H: the checkpoint, for its tokenizer. Builds and pushes the runner and the kernels
(qwen3/build_kernels.py) first. Tokenization and decoding run on the Mac.
"""

import argparse
import json
import os
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
BUILD = HERE.parent / "build/qwen3"
NDK = pathlib.Path(os.environ.get("ANDROID_NDK", "/opt/homebrew/share/android-ndk"))
CC = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang"
DIR = "/data/local/tmp/q8"


def sh(*cmd):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", type=pathlib.Path, required=True)
    ap.add_argument("--hf", type=pathlib.Path, required=True)
    ap.add_argument("--serial", default=os.environ.get("ANDROID_SERIAL"))
    ap.add_argument("--prompt")
    ap.add_argument("--tokens", type=int, default=64)
    a = ap.parse_args()
    adb = ["adb"] + (["-s", a.serial] if a.serial else [])
    (BUILD / "bin").mkdir(parents=True, exist_ok=True)
    sh(CC, "-O2", "-o", BUILD / "bin/qwen3_vk", HERE / "qwen3_vk.c", "-ldl", "-lm")
    sh(*adb, "shell", f"mkdir -p {DIR}/k")
    sh(*adb, "push", BUILD / "bin/qwen3_vk", f"{DIR}/")
    sh(*adb, "push", *sorted(BUILD.glob("*.spv")), f"{DIR}/k/")
    manifest = json.loads((a.model / "manifest.json").read_text())
    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained(str(a.hf))
    env = ""
    if a.prompt is None:
        ids, steps, env = manifest["prompt_ids"], manifest["generation_tokens"], "QWEN3_REF=reference.f32 "
        print(f"prompt: {manifest['prompt']!r}, {len(ids)} tokens; checking {steps} steps")
    else:
        text = tok.apply_chat_template([dict(role="user", content=a.prompt)], tokenize=False,
                                       add_generation_prompt=True, enable_thinking=False)
        ids, steps = tok.encode(text, add_special_tokens=False), a.tokens
        print(f"prompt: {a.prompt!r}, {len(ids)} tokens")
    out = sh(*adb, "shell", f"cd {DIR}; {env}./qwen3_vk . k {steps} {' '.join(map(str, ids))}")
    gen = []
    for line in out.splitlines():
        m = re.match(r"tok (\d+) ", line)
        gen.append(int(m.group(1))) if m else print(line)
    print("output:", repr(tok.decode(gen)))


if __name__ == "__main__":
    main()
