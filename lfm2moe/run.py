"""LFM2-MoE on a device: tokenize a chat prompt, run lfm2moe (on the phone for LFM2.5-8B-A1B, on the QDC laptop through
the remote plugin for LFM2.5-24B-A2B), print the text and the device's timings, and check against reference.py.

  LFM2MOE=8b  build/vla/venv/bin/python lfm2moe/run.py --target phone  [--prompt sky|long|TEXT] [--tokens 64] [--check]
  LFM2MOE=24b build/vla/venv/bin/python lfm2moe/run.py --target laptop [...]

--check compares the residual stream after every layer of the prompt (LFM2MOE_DUMP) with the reference's dump and the
logits after the prompt with the reference's (build/lfm2moe/<model>/ref/<prompt>_*.npy, from reference.py's jobs), and
writes build/lfm2moe/<model>/runs/<name>.json (prompt, generated ids) for a teacher-forced check of the generated tokens.

The phone holds /data/local/tmp/lfm2moe: bin/ (lfm2moe/build_android.py's directory), <model>/q4_0.gguf (downloaded
there), <model>/rope.f32, <model>/q4/{manifest,recipe}.txt and lfm2_convert's lfm2moe_q4.bin. The laptop holds
C:\\Users\\HCKTest\\lfm2moe\\<model>\\{qad_q4_0.gguf, recipe.txt, lfm2moe_q4.bin}; vk_server.exe runs there with its port
forwarded to 7790 (lfm2moe/README.md).
"""

import argparse
import json
import os
import pathlib
import re
import subprocess
import sys

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2moe"))
from weights import BUILD, MODEL  # noqa: E402

PHONE = "/data/local/tmp/lfm2moe"
LAPTOP = "C:/Users/HCKTest/lfm2moe"
X2 = ROOT / "build/lfm2moe/x2"
EOS = (124900, 7)
PROMPTS = {"sky": "Explain in two sentences why the sky is blue.", "long": (ROOT / "lfm2/prompts/long.txt")}


def adb(*args, check=True):
    r = subprocess.run(["adb", *args], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"adb {' '.join(args)}: {r.stderr}")
    return r.stdout


def softmax_kl(p, q):
    a, b = p.astype(np.float64), q.astype(np.float64)
    la = a - a.max() - np.log(np.exp(a - a.max()).sum())
    lb = b - b.max() - np.log(np.exp(b - b.max()).sum())
    return float((np.exp(la) * (la - lb)).sum())


def run(target, ids, tokens, env, dump=False, logits=False):
    """Runs lfm2moe; returns (log, dump array or None, logits rows or None)."""
    runs = BUILD / "runs"
    runs.mkdir(parents=True, exist_ok=True)
    (runs / "ids.txt").write_text(" ".join(map(str, ids)) + "\n")
    env = dict(env)
    env["LFM2MOE_EOS"] = ",".join(map(str, EOS))
    if target == "phone":
        adb("push", str(runs / "ids.txt"), f"{PHONE}/runs/ids.txt")
        if dump:
            env["LFM2MOE_DUMP"] = f"{PHONE}/runs/dump.f32"
        if logits:
            env["LFM2MOE_LOGITS"] = f"{PHONE}/runs/logits.f32"
            env["LFM2MOE_LOGITS_EVERY"] = "1000000"  # the prompt's row only
        e = " ".join(f"{k}={v}" for k, v in env.items())
        m = f"{PHONE}/{MODEL}"
        cmd = (f"cd {PHONE}; LD_LIBRARY_PATH={PHONE}/bin MODULAR_DRIVER_PLUGINS=vulkan@{PHONE}/bin/libM_driver_vulkan.so "
               f"{e} ./bin/lfm2moe {m}/q4 {m}/lfm2moe_q4.bin {tokens} @{PHONE}/runs/ids.txt > runs/log.txt 2>&1; "
               f"echo exit $? >> runs/log.txt")
        adb("shell", cmd)
        log = adb("shell", f"cat {PHONE}/runs/log.txt")
        D = adb("pull", f"{PHONE}/runs/dump.f32", str(runs / "dump.f32")) if dump else None
        L = adb("pull", f"{PHONE}/runs/logits.f32", str(runs / "logits.f32")) if logits else None
    else:
        if dump:
            env["LFM2MOE_DUMP"] = str(runs / "dump.f32")
        if logits:
            env["LFM2MOE_LOGITS"] = str(runs / "logits.f32")
            env["LFM2MOE_LOGITS_EVERY"] = "1000000"
        full = dict(os.environ, VK_REMOTE_PORT="7790", LFM2MOE_REMOTE="1",
                    MODULAR_DRIVER_PLUGINS=f"vulkan@{X2 / 'libM_driver_vulkan_remote.dylib'}", **env)
        r = subprocess.run([str(X2 / "lfm2moe"), str(BUILD / "q4"), f"{LAPTOP}/{MODEL}/lfm2moe_q4.bin", str(tokens),
                            f"@{runs / 'ids.txt'}"], capture_output=True, text=True, env=full)
        log = r.stdout + r.stderr + f"\nexit {r.returncode}\n"
        D = L = None
    if "exit 0" not in log:
        sys.exit("run failed:\n" + log[-4000:])
    d = np.fromfile(runs / "dump.f32", np.float32) if dump else None
    lg = np.fromfile(runs / "logits.f32", np.float32).reshape(-1, 128000) if logits else None
    _ = D, L
    return log, d, lg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", choices=["phone", "laptop"], default="phone" if MODEL == "8b" else "laptop")
    ap.add_argument("--prompt", default="sky")
    ap.add_argument("--tokens", type=int, default=64)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--warm", type=int, default=1)
    ap.add_argument("--env", nargs="*", default=[], help="extra KEY=VALUE for lfm2moe")
    ap.add_argument("--name")
    a = ap.parse_args()
    from reference import chat_ids, tokenizer
    tok = tokenizer()
    p = PROMPTS.get(a.prompt, a.prompt)
    text = p.read_text() if isinstance(p, pathlib.Path) else p
    ids = chat_ids(tok, text)
    print(f"prompt: {len(ids)} tokens ({text[:60]!r}{'...' if len(text) > 60 else ''}), target {a.target}")
    env = dict(kv.split("=", 1) for kv in a.env)
    if a.warm:
        env["LFM2MOE_WARM"] = str(a.warm)
    log, dump, logits = run(a.target, ids, a.tokens, env, dump=a.check, logits=a.check)
    for line in log.splitlines():
        if line.startswith(("device", "weights", "prompt", "decode", "warm", "profile", "server", "mem")):
            print("device:", line)
    toks = [int(m) for m in re.findall(r"^tok (\d+)", log, re.M)]
    print("output:", repr(tok.decode(toks)))
    if a.check:
        ref = BUILD / "ref"
        name = a.prompt if a.prompt in PROMPTS else None
        if name and (ref / f"{name}_hidden.npy").exists():
            rh = np.load(ref / f"{name}_hidden.npy")
            dh = dump.reshape(rh.shape)
            for i in range(rh.shape[0]):
                err = float(np.abs(dh[i] - rh[i]).max() / np.abs(rh[i]).max())
                print(f"check: {'embedding' if i == 0 else f'layer {i - 1}'} residual max |diff| / max {err:.2e}")
        if name and (ref / f"{name}_logits.npy").exists():
            rl = np.load(ref / f"{name}_logits.npy")[-1]
            dl = logits[0]
            print(f"check: logits after the prompt: max |diff| {float(np.abs(dl - rl).max()):.3g} "
                  f"(max |logit| {float(np.abs(rl).max()):.1f}), argmax {int(dl.argmax())} vs {int(rl.argmax())}, "
                  f"KL {softmax_kl(rl, dl):.2e}")
        runs = BUILD / "runs"
        nm = a.name or f"{a.target}_{name or 'custom'}"
        (runs / f"{nm}.json").write_text(json.dumps(dict(prompt=ids, generated=toks)))
        print("wrote", runs / f"{nm}.json")


if __name__ == "__main__":
    main()
