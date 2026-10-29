"""Run Bonsai 2 2B on the phone's Adreno 840: bonsai_vk with the port's Mojo kernels as Vulkan SPIR-V.

  python bonsai/run.py --model M --hf H --push            # build, upload, validate against M's reference
  python bonsai/run.py --model M --hf H --prompt 'Reply with only one word: hello.' --tokens 16
  python bonsai/run.py --model M --hf H --prefill        # the prompt at once, on cooperative matrices

M: the output of the port's prepare.py (weights.bin, manifest.json, reference.f32); H: the checkpoint
(prism-ml/Ternary-Bonsai-2-2B-mlx-2bit at 1c6cbae2), for its tokenizer and chat template. Run with
the Python environment of bonsai/requirements.txt (transformers). Kernels: bonsai/build_kernels.py.
Tokenization and decoding run on the Mac; every model step runs on the phone's GPU.
"""

import argparse
import json
import os
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
BUILD = ROOT / "build/bonsai"
NDK = pathlib.Path(os.environ.get("ANDROID_NDK", "/opt/homebrew/share/android-ndk"))
CC = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang"
DIR = "/data/local/tmp/bonsai"


def sh(*cmd, **kw):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, **kw)
    if r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", type=pathlib.Path, required=True)
    ap.add_argument("--hf", type=pathlib.Path, required=True)
    ap.add_argument("--serial", default=os.environ.get("ANDROID_SERIAL"))
    ap.add_argument("--push", action="store_true", help="upload the weights (gzip) and the reference")
    ap.add_argument("--prompt", help="generate for this prompt instead of validating")
    ap.add_argument("--prompt-file", type=pathlib.Path, help="the prompt from a file")
    ap.add_argument("--prefill", action="store_true", help="batched prefill (Adreno 8xx cooperative matrices)")
    ap.add_argument("--tokens", type=int, default=32)
    ap.add_argument("--profile", action="store_true")
    a = ap.parse_args()
    if a.prompt_file:
        a.prompt = a.prompt_file.read_text().strip()
    adb = ["adb"] + (["-s", a.serial] if a.serial else [])
    manifest = json.loads((a.model / "manifest.json").read_text())

    (BUILD / "bin").mkdir(parents=True, exist_ok=True)
    sh(CC, "-O2", "-o", BUILD / "bin/bonsai_vk", HERE / "bonsai_vk.c", "-ldl", "-lm")
    spv = sorted(BUILD.glob("*.spv"))
    pspv = sorted((BUILD / "prefill").glob("*.spv"))
    if len(spv) != 21 or (a.prefill and len(pspv) != 20):
        sys.exit("run bonsai/build_kernels.py first")
    sh(*adb, "shell", f"mkdir -p {DIR}/k {DIR}/kp")
    sh(*adb, "push", BUILD / "bin/bonsai_vk", f"{DIR}/")
    sh(*adb, "push", *spv, f"{DIR}/k/")
    if a.prefill:
        sh(*adb, "push", *pspv, f"{DIR}/kp/")
    if a.push:  # the weights depend on the context capacity only through the rope table
        gz = BUILD / "weights.bin.gz"
        if not gz.exists() or gz.stat().st_mtime < (a.model / "weights.bin").stat().st_mtime:
            with open(gz, "wb") as f:
                subprocess.run(["gzip", "-1", "-c", a.model / "weights.bin"], stdout=f, check=True)
        sh(*adb, "push", gz, f"{DIR}/")
        sh(*adb, "shell", f"cd {DIR}; gunzip -f weights.bin.gz")
    if a.prompt is None:  # this model's reference, for any weights with enough context
        sh(*adb, "push", a.model / "reference.f32", f"{DIR}/")

    from transformers import AutoTokenizer  # the exporter's environment
    tok = AutoTokenizer.from_pretrained(str(a.hf))
    env = ""
    if a.prompt is None:  # the exporter's prompt and its FP32 reference
        ids, steps = manifest["prompt_ids"], manifest["generation_tokens"]
        env = "BONSAI_REF=reference.f32 "
        print(f"prompt: {manifest['prompt']!r}, {len(ids)} tokens; checking {steps} steps")
    else:
        text = tok.apply_chat_template([dict(role="user", content=a.prompt)], tokenize=False,
                                       add_generation_prompt=True, enable_thinking=False)
        ids, steps = tok.encode(text, add_special_tokens=False), a.tokens
        print(f"prompt: {a.prompt!r}, {len(ids)} tokens")
    if a.prefill:
        env += "BONSAI_PREFILL=kp "
    if a.profile:
        env += "BONSAI_PROFILE=1 "
    # plain commands only: the remote-lab bridge drops on '&&' and '&'
    out = sh(*adb, "shell", f"cd {DIR}; {env}./bonsai_vk weights.bin k {steps} {' '.join(map(str, ids))}")
    gen = []
    for line in out.splitlines():
        m = re.match(r"tok (\d+) ", line)
        if m:
            gen.append(int(m.group(1)))
        else:
            print(line)
    if a.prompt is None and gen != manifest["expected_ids"][:len(gen)]:
        print(f"greedy ids differ from the reference: {gen} vs {manifest['expected_ids']}")
    print("output:", repr(tok.decode(gen)))


if __name__ == "__main__":
    main()
