"""The runner: builds gemm_bench with a round's candidates, runs it on the phone, and keeps every
measurement in build/tuner/<device>/measurements.jsonl.

The phone is the one adb picks (ANDROID_SERIAL). A remote lab's adb bridge can drop a long shell, so
each prompt length runs on its own with its output in a file on the phone, and a run that fails is
retried once; the database keeps what finished. Before each, the runner waits until the phone's skin
temperature is under TUNER_MAX_SKIN (40 C by default): a hot phone throttles, and while times relative
to the reference in the same run survive that, the rankings of close candidates do not. Each
measurement records the temperature it started at.
"""

import json
import os
import pathlib
import re
import subprocess
import sys
import time

from space import DEFAULT, Cand

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(ROOT / "android"))
import build as ab  # noqa: E402  android/build.py

OUT = ROOT / "build/tuner"
DIR = "/data/local/tmp/tuner"


def adb(*args, check=True):
    return subprocess.run(["adb", *args], check=check, capture_output=True, text=True).stdout


def skin():
    """The phone's skin temperature in C and its throttling status (0: none), or (None, None)."""
    text = adb("shell", "dumpsys thermalservice", check=False)
    m = re.search(r"Temperature\{mValue=([0-9.]+), mType=3, mName=SKIN, mStatus=(\d+)\}", text)
    return (float(m.group(1)), int(m.group(2))) if m else (None, None)


def cool(log=print, limit=None, wait_s=900):
    """Waits until the phone is under `limit` C and not throttling, up to wait_s."""
    limit = limit or float(os.environ.get("TUNER_MAX_SKIN", "40"))
    t0 = time.time()
    while True:
        c, status = skin()
        if c is None or (c < limit and status == 0):
            return c
        if time.time() - t0 > wait_s:
            log(f"  still {c} C (status {status}) after {wait_s} s; measuring anyway")
            return c
        log(f"  phone at {c} C (status {status}): cooling")
        time.sleep(30)


def device_key():
    model = adb("shell", "getprop ro.product.model").strip()
    build = adb("shell", "getprop ro.build.version.incremental").strip()
    if not model:
        raise SystemExit("no phone: set ANDROID_SERIAL to a connected device")
    return f"{model}-{build}"


def build(cands):
    """build/tuner/gemm_bench with these candidates, the reference first."""
    cands = [DEFAULT] + [c for c in cands if c != DEFAULT]
    OUT.mkdir(parents=True, exist_ok=True)
    src = (HERE / "gemm_bench.mojo").read_text()
    calls = "\n".join(f'    b.add[{c.mojo()}]("{c.name}")' for c in cands)
    marker = "    # CANDIDATES\n"
    assert marker in src
    src = src[:src.index(marker)] + calls + "\n" + src[src.index(marker) + len(marker):].split("\n", 1)[1]
    (OUT / "gemm_bench.mojo").write_text(src)
    t0 = time.time()
    ab.mojo_object(OUT / "gemm_bench.mojo", OUT / "gemm_bench.o", includes=[ROOT / "bonsai/kernels"])
    ab.link(OUT, "gemm_bench", [OUT / "gemm_bench.o"])
    return time.time() - t0


class DB:
    def __init__(self, key):
        self.path = OUT / key / "measurements.jsonl"
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.rows = [json.loads(l) for l in self.path.read_text().splitlines()] if self.path.exists() else []

    def add(self, recs):
        with self.path.open("a") as f:
            for r in recs:
                f.write(json.dumps(r) + "\n")
        self.rows += recs

    def ok(self):
        return [r for r in self.rows if r["status"] == "ok"]

    def samples(self, run=None):
        """(Cand, shape, time / the reference's time in the same run and shape), of one run or all."""
        ref = {(r["run"], tuple(r["shape"])): r["ms"] for r in self.ok() if r["cand"] == DEFAULT.name}
        out = []
        for r in self.ok():
            if run and r["run"] != run:
                continue
            base = ref.get((r["run"], tuple(r["shape"])))
            if base:
                out.append((Cand.parse(r["cand"]), tuple(r["shape"]), r["ms"] / base))
        return out

    def measured(self, shape):
        return {r["cand"] for r in self.rows if tuple(r["shape"]) == tuple(shape)}


def parse(text, run):
    recs = []
    for line in text.splitlines():
        f = line.split()
        if not f:
            continue
        if f[0] == "RESULT":
            recs.append({"run": run, "shape": [int(f[1]), int(f[2]), int(f[3])], "cand": f[4], "ms": float(f[5]),
                         "tflops": float(f[6]), "status": "ok"})
        elif f[0] == "FAILED":
            why = " ".join(f[5:])
            recs.append({"run": run, "shape": [int(f[1]), int(f[2]), int(f[3])], "cand": f[4], "ms": None,
                         "status": "rejected" if why.startswith("launch") else "wrong", "why": why[:200]})
    return recs


def run(shapes, rounds, run_id, log=print):
    """Runs the built bench on these shapes, one prompt length at a time. Returns the records."""
    adb("shell", f"mkdir -p {DIR}")
    adb("push", *[str(p) for p in sorted(OUT.iterdir()) if p.is_file() and p.suffix not in (".o", ".mojo")],
        f"{DIR}/")
    recs = []
    for rows in sorted({s[2] for s in shapes}):
        group = " ".join(f"{n},{k},{r}" for n, k, r in shapes if r == rows)
        out = f"{DIR}/out-{rows}.txt"
        for attempt in range(2):
            temp = cool(log)
            t0 = time.time()
            adb("shell", f"cd {DIR}; MODULAR_DRIVER_PLUGINS=vulkan@{DIR}/libM_driver_vulkan.so ./gemm_bench "
                         f"{rounds} {group} > {out} 2>&1", check=False)
            text = adb("shell", f"cat {out}", check=False)
            got = parse(text, run_id)
            for r in got:
                r["skin_c"] = temp
            done = {tuple(r["shape"]) for r in got}
            if all((n, k, r) in done for n, k, r in shapes if r == rows):
                break
            log(f"  rows {rows}: incomplete output, retrying")
        recs += got
        log(f"  rows {rows}: {sum(r['status'] == 'ok' for r in got)} timings, "
            f"{sum(r['status'] != 'ok' for r in got)} failures, {time.time() - t0:.0f} s")
    return recs
