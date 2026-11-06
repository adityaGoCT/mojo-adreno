"""Where a decode step's (or, with --prefill, a batched prompt's) time goes on the phone: gemma4 run with VK_SERVER_PROFILE=2, which makes the driver plugin
submit each launch alone and wait for it ("1 commands in 1 submissions: recorded over .. ms, then waited X ms"). The
last decode step's launches are matched, in order, to model.mojo's step(): 3 launches, 12 per layer, then the head
and argmax. Each launch waited for alone pays a submission's latency too, so the sum exceeds a normal step's time.

  build/vla/venv/bin/python gemma4/step_profile.py --model e2b [--tokens 4] [--prefill]

The prompt is run.py's last (prompt.ids on the phone).
"""

import argparse
import collections
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
PHONE = "/data/local/tmp/gemma4"
PLAYER = ["q/k/v (int4, matrix units)", "q/k norm + RoPE", "attention: Q K^T (matrix units)", "attention: softmax",
          "attention: P V (matrix units)", "o (int4, matrix units)", "norms + residual",
          "gate/up (int4, matrix units)", "GELU x up", "down (int4, matrix units)", "norms + residual",
          "per-layer gate (int4, matrix units)", "GELU x per-layer input", "per-layer projection (int4, matrix units)",
          "norms + residual"]
LAYER = ["q/k/v (int4)", "q/k norm + RoPE", "attention scores", "attention values", "o (int4)", "norms + residual",
         "gate/up + GELU (int4)", "down (int4)", "norms + residual", "per-layer gate (int4)",
         "per-layer projection (int4)", "norms + residual"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="e2b")
    ap.add_argument("--tokens", type=int, default=4)
    ap.add_argument("--prefill", action="store_true")
    a = ap.parse_args()
    d = f"{PHONE}/{a.model}"
    L = int(re.search(r" L (\d+) ", (ROOT / "build/gemma4" / a.model / "manifest.txt").read_text()).group(1))
    subprocess.run(["adb", "shell", f"cd {PHONE}/gemma4; {'GEMMA4_PREFILL=1 ' if a.prefill else ''}VK_SERVER_PROFILE=2 MODULAR_DRIVER_PLUGINS=vulkan@{PHONE}/gemma4/"
                    f"libM_driver_vulkan.so ./gemma4 {d} {d}/model.safetensors {a.tokens} @{d}/prompt.ids > {d}/prof.log "
                    f"2>&1; echo exit $? >> {d}/prof.log"], check=True)
    log = subprocess.run(["adb", "shell", f"cat {d}/prof.log"], capture_output=True, text=True, check=True).stdout
    if "exit 0" not in log:
        sys.exit(log[-2000:])
    lines = log.splitlines()
    timed = r"^1 commands in 1 submissions: .* waited ([\d.]+) ms"
    if a.prefill:  # every launch of the prompt's batches: 3, 15 a layer, head and argmax per batch
        w = next(i for i, s in enumerate(lines) if s.startswith("weights:"))
        p = next(i for i, s in enumerate(lines) if s.startswith("prompt:"))
        t = [float(m.group(1)) for s in lines[w:p] if (m := re.search(timed, s))]
        names = ["per-layer projection in (int4, matrix units)", "per-layer inputs", "start"]
        for _ in range(L):
            names += PLAYER
        names += ["head (int4) + soft-cap", "argmax"]
        t = t[len(t) % len(names):]  # the uploads' copies come first
        total = collections.OrderedDict()
        for i, x in enumerate(t):
            total[names[i % len(names)]] = total.get(names[i % len(names)], 0) + x
        s = sum(t)
        print(f"{len(t)} launches ({len(t) // len(names)} batches), {s:.1f} ms waited for one at a time; "
              f"{[ln for ln in lines if ln.startswith('prompt:')]}")
        for n, x in sorted(total.items(), key=lambda kv: -kv[1]):
            print(f"  {n:44s} {x:8.1f} ms  {100 * x / s:5.1f}%")
        return
    # the last decode step: the launches between the last two "tok" lines
    toks = [i for i, s in enumerate(lines) if s.startswith("tok ")]
    step = [float(m.group(1)) for s in lines[toks[-2] + 1:toks[-1]]
            if (m := re.search(r"^1 commands in 1 submissions: .* waited ([\d.]+) ms", s))]
    names = ["per-layer projection in (int4)", "per-layer inputs", "start"]
    for _ in range(L):
        names += LAYER
    names += ["head (int4) + soft-cap", "argmax"]
    if len(step) < len(names):
        sys.exit(f"{len(step)} timed launches in the last step, expected {len(names)}")
    step = step[-len(names):]
    total = collections.OrderedDict()
    for n, t in zip(names, step):
        total[n] = total.get(n, 0) + t
    s = sum(step)
    print(f"{len(step)} launches, {s:.2f} ms waited for one at a time; normal step: "
          f"{[ln for ln in lines if ln.startswith('decode:')]}")
    for n, t in sorted(total.items(), key=lambda kv: -kv[1]):
        print(f"  {n:32s} {t:7.2f} ms  {100 * t / s:5.1f}%")


if __name__ == "__main__":
    main()
