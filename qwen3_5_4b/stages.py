"""The phone's residual stream after the embedding and after each layer (QWEN35_DUMP, a batched prefill) against
transformers' on the same GGUF weights (reference.py --dump), a layer at a time: where a wrong kernel first shows.

  build/vla/venv/bin/python qwen3_5_4b/reference.py --ids-file I --views q4 --out build/qwen3_5_4b/runs/stage/NAME --dump
  build/vla/venv/bin/python qwen3_5_4b/stages.py --ids-file I --name NAME [--token-by-token]
"""

import argparse
import pathlib
import sys

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "qwen3_5_4b"))
from run import PHONE, RUNS, adb  # noqa: E402

TYPES = "LLLF" * 8


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ids-file", required=True)
    ap.add_argument("--name", required=True)
    a = ap.parse_args()
    ids = pathlib.Path(a.ids_file).read_text().split()
    T = len(ids)
    stage = RUNS / "stage"
    adb("push", a.ids_file, f"{PHONE}/runs/stage_ids.txt")
    env = (f"LD_LIBRARY_PATH={PHONE}/qwen3_5_4b MODULAR_DRIVER_PLUGINS=vulkan@{PHONE}/qwen3_5_4b/libM_driver_vulkan.so "
           f"QWEN35_PREFILL=1 QWEN35_DUMP={PHONE}/runs/dump.f32")
    adb("shell", f"cd {PHONE}; {env} ./qwen3_5_4b/qwen3_5_4b {PHONE}/q4 {PHONE}/q4/qwen3_5_4b_q4.bin 2 "
                 f"@{PHONE}/runs/stage_ids.txt > runs/stage_log.txt 2>&1; echo exit $? >> runs/stage_log.txt")
    log = adb("shell", f"cat {PHONE}/runs/stage_log.txt")
    if "exit 0" not in log:
        sys.exit("phone run failed:\n" + log)
    adb("pull", f"{PHONE}/runs/dump.f32", str(stage / f"{a.name}_phone.f32"))
    phone = np.fromfile(stage / f"{a.name}_phone.f32", np.float32).reshape(-1, T, 2560)
    ref = np.load(stage / f"{a.name}_q4_hidden.npy")
    print(f"{len(phone) - 1} layers, {T} rows; tokens: {[l for l in log.splitlines() if l.startswith('tok')]}")
    for i in range(min(len(phone), len(ref))):
        d = np.abs(phone[i] - ref[i])
        what = "embedding" if i == 0 else f"layer {i - 1} ({'linear' if TYPES[i - 1] == 'L' else 'full'})"
        print(f"{what:20s} max |phone - ref| {d.max():.3e} (row {int(d.max(axis=1).argmax())}), "
              f"max |ref| {np.abs(ref[i]).max():.2f}")


if __name__ == "__main__":
    main()
