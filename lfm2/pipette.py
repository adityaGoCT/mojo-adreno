"""LFM2.5-2.6B on the phone under Pipette's protocol (pipette.liquid.ai, Pipette v1; docs/methodology/
performance-methodology), to compare with its Galaxy S26 Ultra rows (llama.cpp b11988, android-arm64-v8a, CPU):

  prompt              synthesized to exactly 1024 tokens; greedy decoding
  Prefill (1024)      prompt tokens / prefill time
  TTFT (1024)         the prefill time (Pipette's dashboard label for it: no tokenization, no first-token delivery)
  Decode (1024->100)  output tokens after the first / their time, over 100 output tokens
  E2E (1024->256)     from the start of the prefill to the 256th output token, everything on the way included (for
                      GPU+NPU: releasing the NPU and loading the GPU's weights; for all-NPU: the context swap)
  repetitions         5 a configuration, mean and sample standard deviation; before each, a readiness wait (battery
                      at or below 31 C, 20 s idle, no other model process); warm-up excluded (an untimed prompt first)
  Peak RAM (1024)     one run, 1024 tokens and one output token: the process's high-water resident memory (VmHWM)
                      plus swap, as Pipette's Android path counts it; and, sampled from the Mac, the GPU's page
                      allocations above their idle level (kgsl page_alloc), since GPU buffers sit outside VmHWM

Ours differs in one way: Decode (1024->100) and E2E (1024->256) come from the same 1024 -> 256 run, decode over output
tokens 1 .. 100 (the same positions a 1024 -> 100 run decodes).

The phone is a Galaxy Z Fold (SM-F976U): the S26 Ultra's Snapdragon 8 Elite Gen 5 (SM8850), 12 GB. The weights are
Pipette's q4_0 file, LFM2.5-2.6B-Q4_0.gguf (SHA-256 e1a61bf9...), staged in /data/local/tmp/lfm2/plain (stage
commands in lfm2/README.md). Another phone writes its results apart (PIPETTE_OUT=build/lfm2/pipette/<name>, a name
in PHONES); one whose battery reads a fixed temperature waits on a thermal zone instead (PIPETTE_ZONE=gpuss-0
PIPETTE_TEMP_MAX=45 on Qualcomm Device Cloud's QRD).

  build/vla/venv/bin/python lfm2/pipette.py [gpu] [hybrid] [npu] [spec] [--reps 5]   # build/lfm2/pipette/<config>.json

spec is the int4 GPU with the DSpark drafter (speculative decoding: the same greedy tokens). Its program reports only a
whole generation's decode time, so each of its repetitions is two runs: 1024 -> 100 for the decode throughput, 1024 ->
256 for E2E; its TTFT includes the drafter's context of the prompt.
  build/vla/venv/bin/python lfm2/pipette.py --table                            # all results against Pipette's

--model 8b measures LFM2.5-8B-A1B (Liquid AI's mixture of experts, lfm2moe/) the same way, on the GPU only, from
Pipette's LFM2.5-8B-A1B-Q4_0.gguf in /data/local/tmp/lfm2/plain8b; results in build/lfm2moe/pipette/.
  build/vla/venv/bin/python lfm2/pipette.py gpu --model 8b --input 1024
"""

import argparse
import json
import os
import pathlib
import re
import statistics
import subprocess
import sys
import threading
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lfm2"))
MODEL = "2.6b"  # --model: 2.6b (lfm2/: gpu, hybrid, npu, spec) or 8b (LFM2.5-8B-A1B, lfm2moe/: gpu)
BASES = {"2.6b": ROOT / "build/lfm2/pipette", "8b": ROOT / "build/lfm2moe/pipette"}
OUT = BASES[MODEL]  # PIPETTE_OUT: another phone's directory (set in main)
D = "/data/local/tmp/lfm2"
D8 = f"{D}/plain8b"  # the 8B: bin/ (build/android/lfm2moe), q4_0.gguf, rope.f32, q4/{manifest,recipe}.txt, lfm2moe_q4.bin
P = 1024  # input tokens (--input)
DECODE = 100
E2E = 256  # output tokens a timed run generates (--new); decode is timed over outputs 1 .. 100 of it
TEMP_MAX = float(os.environ.get("PIPETTE_TEMP_MAX", 31.0))  # with PIPETTE_ZONE, that zone's limit

# Pipette's rows for LFM2.5-2.6B (pipette.liquid.ai/results, read 2026-11-07; llama.cpp b11988)
PIPETTE = [
    ("Galaxy S26 Ultra", "llama.cpp CPU", "q4_0", 34, 150, 6844, 13995, 1.87),
    ("Galaxy S26 Ultra", "llama.cpp CPU", "q4_k_m", 31, 104, 9864, 17593, 1.95),
    ("Galaxy S26 Ultra", "llama.cpp CPU", "q5_k_m", 22, 79, 12998, 24120, 2.20),
    ("iPhone 17 Pro", "llama.cpp GPU", "q4_0", 39, 967, 1059, 7687, 1.86),
]


# Pipette's context sweep for the q4_0 row (its leaderboard's data, pipette.liquid.ai/api/query?q=explore for "Galaxy
# S26 Ultra / llama.cpp:android-arm64-v8a", read 2026-11-07; llama.cpp b11988, CPU, 4 threads, flash attention off):
# input -> (prefill tok/s, TTFT ms, decode tok/s over 100 outputs, E2E ms for 256 outputs, peak RAM MB)
PIPETTE_SWEEP = {256: (184.50, 1387.52, 36.56, 8578.80, 1832.50), 512: (174.35, 2936.65, 35.00, 10290.06, 1887.60),
                 1024: (149.62, 6844.13, 34.00, 13994.56, 1919.14), 2048: (136.31, 15024.80, 26.66, 22124.44, 2033.54),
                 4096: (112.40, 36442.26, 22.67, 44138.78, 2261.37)}

# The same for LFM2.5-8B-A1B (8,468M parameters, 1,500M active; LiquidAI/LFM2.5-8B-A1B-GGUF): its S26 Ultra rows and
# the iPhone 17 Pro's (llama.cpp:ios, q4_0), at 1,024 tokens, and the q4_0 sweep (the leaderboard's data, read
# 2026-11-08; llama.cpp b11988). Peak RAM in GiB, as Pipette shows it.
PIPETTE_8B = [
    ("Galaxy S26 Ultra", "llama.cpp CPU", "q4_0", 49, 96, 10664, 15178, 4.90),
    ("Galaxy S26 Ultra", "llama.cpp CPU", "q4_k_m", 39, 77, 13284, 19089, 5.19),
    ("Galaxy S26 Ultra", "llama.cpp CPU", "q5_k_m", 29, 50, 20520, 27228, 6.00),
    ("iPhone 17 Pro", "llama.cpp GPU", "q4_0", 56, 1320, 776, 5521, 4.88),
]
PIPETTE_SWEEP_8B = {256: (111.29, 2300.38, 52.79, 7401.36, 4919.68), 512: (108.92, 4700.80, 51.62, 9814.17, 4964.08),
                    1024: (96.03, 10663.50, 49.15, 15177.85, 5014.15), 2048: (88.35, 23180.92, 37.16, 28422.35, 5124.52),
                    4096: (76.88, 53275.43, 32.64, 58486.64, 5344.66)}


def adb(*args, check=True):
    r = subprocess.run(["adb", *args], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"adb {' '.join(args)}: {r.stderr}")
    return r.stdout


def prompt_ids():
    """Exactly P tokens: the start-of-text token and the first P - 1 of the repo's long passages, then its BLOG.md and
    BLOG-COOPMAT.md (one token list for every length, each shorter prompt a prefix of the longer; kept in
    build/lfm2/pipette/ids<P>.txt, so later edits to those files don't change them)."""
    f = ROOT / f"build/lfm2/pipette/ids{P}.txt"  # the same prompts on every phone
    if f.exists():
        return [int(t) for t in f.read_text().split()]
    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained(ROOT / "build/lfm2")
    text = (ROOT / "gemma4/prompts/long.txt").read_text() + "\n\n" + (ROOT / "llama/prompts/long.txt").read_text()
    more = (ROOT / "BLOG.md").read_text() + "\n\n" + (ROOT / "BLOG-COOPMAT.md").read_text()  # beyond 1,293 tokens
    ids = [tok.bos_token_id] + tok(text, add_special_tokens=False)["input_ids"]
    ids += tok("\n\n" + more, add_special_tokens=False)["input_ids"]
    assert len(ids) >= P, len(ids)
    return ids[:P]


ZONE = os.environ.get("PIPETTE_ZONE")  # a thermal zone to wait on instead of the battery (the QRD's reads a fixed 39 C)
_zone = []


def temperature():
    if ZONE:
        if not _zone:
            found = adb("shell", f"grep -lx {ZONE} /sys/class/thermal/thermal_zone*/type").split()
            _zone.append(found[0].rsplit("/", 1)[0] + "/temp")
        return int(adb("shell", f"cat {_zone[0]}").strip()) / 1000
    m = re.search(r"temperature: (\d+)", adb("shell", "dumpsys battery"))
    return int(m.group(1)) / 10 if m else 0.0


def ready(last_end):
    """Pipette's readiness check, as far as a lab phone allows: no other model process, 20 s since the last run, battery
    at or below TEMP_MAX (waiting up to 5 minutes)."""
    t0 = time.time()
    while True:
        busy = adb("shell", "ps -A", check=False)
        others = [l for l in busy.splitlines() if re.search(r"lfm2|graph_tool|vk_server", l)]
        temp = temperature()
        if not others and time.time() - last_end >= 20 and temp <= TEMP_MAX:
            return temp
        if time.time() - t0 > 300 and not others:
            print(f"  readiness: still {temp:.1f} C after 5 minutes; running anyway")
            return temp
        time.sleep(5)


def command(config, new, ids_file, peak=False):
    if MODEL == "8b":
        return (f"cd {D8}; LD_LIBRARY_PATH={D8}/bin MODULAR_DRIVER_PLUGINS=vulkan@{D8}/bin/libM_driver_vulkan.so "
                f"LFM2MOE_PREFILL=1 LFM2MOE_WARM={0 if peak else 1} ./bin/lfm2moe {D8}/q4 {D8}/lfm2moe_q4.bin {new} "
                f"@{ids_file}")
    env = f"LFM2_PREFILL=1 LFM2_WARM={0 if peak else 1}"
    if config in ("gpu", "spec"):
        if config == "spec":
            env += f" LFM2_DSPARK={D}/dspark"
        return (f"cd {D}; LD_LIBRARY_PATH={D}/lfm2 MODULAR_DRIVER_PLUGINS=vulkan@{D}/lfm2/libM_driver_vulkan.so {env} "
                f"./lfm2/lfm2 {D}/plain/q4 {D}/plain/q4/lfm2_q4.bin {new} @{ids_file}")
    q = f"{D}/qnn"
    npu_env = (f"LD_LIBRARY_PATH={q}:/system/lib64:/vendor/lib64 ADSP_LIBRARY_PATH={q} "
               f"MODULAR_DRIVER_PLUGINS=vulkan@{q}/libM_driver_vulkan.so {npu_graphs()} "
               f"NPU_RUNS={1 if peak else 2}")
    if config == "hybrid":
        return (f"cd {D}/plain/npu; {npu_env} {q}/lfm2_hybrid {D}/plain/npu {D}/plain/q4_0.gguf {D}/plain/q4 "
                f"{D}/plain/q4/lfm2_q4.bin {new} @{ids_file}")
    return f"cd {D}/plain/npu; {npu_env} {q}/lfm2_npu {D}/plain/npu {D}/plain/q4_0.gguf {new} @{ids_file}"


def others_running():
    """Model processes on the phone that are not this benchmark's (ours read from .../plain/ or .../plain8b/)."""
    out = adb("shell", "ps -A -o PID,ARGS", check=False)  # a bracketed name with no arguments: one of ours exiting
    return [l for l in out.splitlines() if re.search(r"lfm2|graph_tool|vk_server|hybrid", l)
            and not re.search(r"/plain8?b?/", l) and "ps -A" not in l
            and not re.fullmatch(r"\s*\d+ \[(lfm2|lfm2_hybrid|lfm2_npu|lfm2moe)\]\s*", l)]


def npu_graphs():
    """Which NPU graphs serve an input of P tokens: one-pass prefill graphs of P rows up to 1024 (r<P>_p*, 1024: p*),
    512-row chunks beyond (c_p*); decode graphs with 1280 cache slots up to 1024 inputs (d*), 4352 beyond (dl_d*)."""
    if P <= 1024:
        pre = "p" if P == 1024 else f"r{P}_p"
        return f"LFM2_ROWS={P} LFM2_SLOTS=1280 LFM2_PGRAPH={pre} LFM2_DGRAPH=d"
    return "LFM2_ROWS=512 LFM2_SLOTS=4352 LFM2_CHUNK=512 LFM2_PAST=3584 LFM2_PGRAPH=c_p LFM2_DGRAPH=dl_d"


def run(config, new, ids_file, peak=False, watch=None):
    """One run on the phone. watch (a list): filled with any other model process seen while it ran (polled every 5 s)."""
    log = f"{D}/runs/pipette_{config}.log"
    stop = threading.Event()

    def monitor():
        while not stop.wait(5):
            o = others_running()
            if o and watch is not None:
                watch.extend(o)

    th = threading.Thread(target=monitor)
    th.start()
    try:
        adb("shell", f"{command(config, new, ids_file, peak)} > {log} 2>&1; echo exit $? >> {log}")
    finally:
        stop.set()
        th.join()
    text = adb("shell", f"cat {log}")
    if "exit 0" not in text:
        sys.exit(f"{config} failed:\n{text[-3000:]}")
    return text


def parse(config, text):
    """TTFT (prefill ms), the per-token ms of outputs 2 .. n, and the ms between prefill and the first decode step."""
    toks = [float(x) for x in re.findall(r"^tok \d+ ([\d.]+)", text, re.M)]
    if config == "gpu":
        ttft = float(re.search(r"prompt: \d+ tokens in ([\d.]+) ms", text).group(1))
        gap = 0.0
    else:
        runs = [float(x) for x in re.findall(r"^prefill \d+ ?: \d+ tokens in ([\d.]+) ms", text, re.M)]
        ttft = runs[-1]  # the decode continues from the last prefill (the first is the cold one)
        if config == "hybrid":
            rel, cp = re.search(r"NPU contexts released in ([\d.]+) ms; K/V and conv states into the GPU in ([\d.]+) ms",
                                text).groups()
            load = float(re.search(r"gpu: weights [\d.]+ GB loaded in ([\d.]+) s", text).group(1)) * 1000
            gap = float(rel) + float(cp) + load
        else:
            gap = float(re.search(r"handoff: .* in ([\d.]+) s", text).group(1)) * 1000
    steps = toks[1:]  # outputs 2 ..: their own step times
    return ttft, steps, gap


def measure_spec(reps, ids_file):
    """spec: each repetition a 1024 -> 100 run (decode throughput, TTFT) and a 1024 -> 256 run (E2E)."""
    res = []
    last = 0.0
    r = retries = 0
    while r < reps:
        out = {}
        bad = False
        for new in (DECODE, E2E):
            temp = ready(last)
            seen = []
            text = run("spec", new, ids_file, watch=seen)
            last = time.time()
            bad |= bool(seen)
            ttft = float(re.search(r"prompt: \d+ tokens in ([\d.]+) ms", text).group(1))
            n, ms = re.search(r"decode: (\d+) steps, ([\d.]+) ms/token", text).groups()
            passes = re.search(r"tokens: ([\d.]+) tokens a pass", text)
            out[new] = (ttft, int(n), float(ms), float(passes.group(1)) if passes else 0.0, temp)
        if bad and retries < 6:
            retries += 1
            print(f"  rep {r}: another model process ran meanwhile; discarded, repeating", flush=True)
            continue
        ttft, n, ms, tpp, temp = out[DECODE]
        e_ttft, e_n, e_ms, _, _ = out[E2E]
        dec = 1000 / ms
        e2e = e_ttft + e_n * e_ms
        res.append(dict(ttft_ms=ttft, prefill_tps=P / ttft * 1000, decode_tps=dec, e2e_ms=e2e, handoff_ms=0.0,
                        battery_c=temp, tokens_per_pass=tpp))
        print(f"  rep {r}: prefill {P / ttft * 1000:.0f} tok/s (TTFT {ttft:.0f} ms), decode {dec:.1f} tok/s "
              f"({tpp:.2f} tokens a pass), E2E {e2e:.0f} ms, battery {temp:.1f} C", flush=True)
        r += 1
    return res


def measure(config, reps, ids_file):
    if config == "spec":
        return measure_spec(reps, ids_file)
    res = []
    last = 0.0
    r = 0
    retries = 0
    while r < reps:
        temp = ready(last)
        seen = []
        text = run(config, E2E, ids_file, watch=seen)
        last = time.time()
        if seen and retries < 6:
            retries += 1
            print(f"  rep {r}: another model process ran meanwhile ({seen[0].strip()[:80]}); discarded, repeating",
                  flush=True)
            continue
        ttft, steps, gap = parse(config, text)
        if len(steps) < E2E - 1:
            sys.exit(f"{config}: only {len(steps) + 1} outputs")
        dec = (DECODE - 1) / (sum(steps[:DECODE - 1]) / 1000)
        e2e = ttft + gap + sum(steps[:E2E - 1])
        res.append(dict(ttft_ms=ttft, prefill_tps=P / ttft * 1000, decode_tps=dec, e2e_ms=e2e, handoff_ms=gap,
                        battery_c=temp))
        print(f"  rep {r}: prefill {P / ttft * 1000:.0f} tok/s (TTFT {ttft:.0f} ms), decode {dec:.1f} tok/s, "
              f"E2E {e2e:.0f} ms (handoff {gap:.0f} ms), battery {temp:.1f} C", flush=True)
        r += 1
    return res


def peak_memory(config, ids_file):
    """One run of 1024 tokens and one output token: VmHWM + VmSwap from the program; the GPU's page allocations above
    their idle level, sampled every ~0.2 s from the Mac."""
    ready(0)
    base = int(adb("shell", "cat /sys/class/kgsl/kgsl/page_alloc").strip())
    peak = [base]
    stop = threading.Event()

    hwm = [0, 0]  # VmHWM, VmSwap (kB), sampled
    name = "lfm2moe" if MODEL == "8b" else {"gpu": "lfm2", "spec": "lfm2", "hybrid": "lfm2_hybrid", "npu": "lfm2_npu"}[config]

    def sample():
        """One adb call a second (a lab bridge drops under a stream of adb calls during a long GPU run)."""
        pid = None
        while not stop.wait(1.0):
            if pid is None:
                found = adb("shell", f"pidof {name}", check=False).split()
                pid = found[0] if found else None
            cmd = "cat /sys/class/kgsl/kgsl/page_alloc" + (f" /proc/{pid}/status" if pid else "")
            out = adb("shell", cmd, check=False)
            first = out.split("\n", 1)[0].strip()
            if first.isdigit():
                peak[0] = max(peak[0], int(first))
            m = re.search(r"VmHWM:\s+(\d+) kB", out)
            w = re.search(r"VmSwap:\s+(\d+) kB", out)
            if m:
                hwm[0] = max(hwm[0], int(m.group(1)))
            if w:
                hwm[1] = max(hwm[1], int(w.group(1)))

    th = threading.Thread(target=sample)
    th.start()
    text = run(config, 1, ids_file, peak=True)
    stop.set()
    th.join()
    kb = {k: int(v) for k, v in re.findall(r"mem: (\w+):\s+(\d+) kB", text)}
    kb["VmHWM"] = max(kb.get("VmHWM", 0), hwm[0])  # the program's own reading at exit, or the Mac's samples
    kb["VmSwap"] = max(kb.get("VmSwap", 0), hwm[1])
    host = (kb["VmHWM"] + kb["VmSwap"]) * 1024
    g = re.search(r"mem: GpuPages: (\d+)", text)  # the program's reading before exit, every GPU buffer still held
    gpu = max(peak[0], int(g.group(1)) if g else 0) - base
    print(f"  peak memory: host {host / 2**30:.2f} GiB (VmHWM {kb.get('VmHWM', 0) / 2**20:.2f} GiB + swap "
          f"{kb.get('VmSwap', 0) / 2**20:.2f}), GPU pages {gpu / 2**30:.2f} GiB above idle "
          f"(RssAnon {kb.get('RssAnon', 0) / 2**20:.2f}, RssFile {kb.get('RssFile', 0) / 2**20:.2f}, "
          f"RssShmem {kb.get('RssShmem', 0) / 2**20:.2f} GiB)")
    return dict(host_bytes=host, gpu_bytes=gpu, status_kb=kb)


def summary(res):
    out = {}
    for k in ("prefill_tps", "ttft_ms", "decode_tps", "e2e_ms", "handoff_ms"):
        v = [r[k] for r in res]
        out[k] = [statistics.mean(v), statistics.stdev(v) if len(v) > 1 else 0.0]
    return out


# The phones results came from: the default directory, and one per other phone (PIPETTE_OUT=<default>/<name>)
PHONES = [("", "Galaxy Z Fold SM-F976U"), ("qrd", "SM8850 QRD (Qualcomm Device Cloud)")]


def results(c, n):
    """(phone, result) for every phone with a <c>_<n>.json, in PHONES' order."""
    base = BASES[MODEL]
    return [(name, json.loads((base / d / f"{c}_{n}.json").read_text())) for d, name in PHONES
            if (base / d / f"{c}_{n}.json").exists()]


def sweep_table():
    names = {"gpu": "GPU (int4)"} if MODEL == "8b" else {"gpu": "GPU (int4)", "hybrid": "GPU + NPU prefill", "npu": "NPU"}
    print("| Input tokens | Phone | llama.cpp CPU (Pipette, S26 Ultra): TTFT, decode, E2E (→256) | " +
          " | ".join(f"{v}: TTFT, decode, E2E (→256)" for v in names.values()) + " |")
    print("|---|---|---|" + "---|" * len(names))
    for n, (pre, ttft, dec, e2e, ram) in (PIPETTE_SWEEP_8B if MODEL == "8b" else PIPETTE_SWEEP).items():
        for d, phone in PHONES:
            cells = []
            for c in names:
                r = dict(results(c, n)).get(phone)
                s = r["summary"] if r else None
                cells.append(f"{s['ttft_ms'][0]:,.0f} ms, {s['decode_tps'][0]:.1f} tok/s, {s['e2e_ms'][0]:,.0f} ms"
                             if s else "")
            if any(cells):
                print(f"| {n:,} | {phone} | {ttft:,.0f} ms, {dec:.1f} tok/s, {e2e:,.0f} ms | " + " | ".join(cells) + " |")


def table():
    names = {"gpu": "Mojo, Adreno 840 GPU (int4)", "hybrid": "Mojo GPU + Hexagon NPU prefill (w8a16)",
             "npu": "Hexagon NPU (w8a16)", "spec": "Mojo GPU (int4) + DSpark speculative decoding"}
    print("| Device, engine | Quant | Decode (1024→100) | Prefill (1024) | TTFT (1024) | E2E (1024→256) | Peak RAM |")
    print("|---|---|---|---|---|---|---|")
    for dev, eng, q, dec, pre, ttft, e2e, ram in (PIPETTE_8B if MODEL == "8b" else PIPETTE):
        print(f"| {dev}, {eng} (Pipette) | {q} | {dec} tok/s | {pre} tok/s | {ttft:,} ms | {e2e:,} ms | {ram:.2f} GB |")
    for c in ("gpu", "hybrid", "npu", "spec"):
        for phone, r in results(c, 1024):
            s, m = r["summary"], r.get("memory", {})
            ram = (f"{m['host_bytes'] / 2**30:.2f} GB host + {m['gpu_bytes'] / 2**30:.2f} GB GPU" if m else "")
            print(f"| {phone}, {names[c]} (ours) | q4_0 | {s['decode_tps'][0]:.1f} ± {s['decode_tps'][1]:.1f} "
                  f"tok/s | {s['prefill_tps'][0]:.0f} ± {s['prefill_tps'][1]:.0f} tok/s | {s['ttft_ms'][0]:,.0f} ± "
                  f"{s['ttft_ms'][1]:.0f} ms | {s['e2e_ms'][0]:,.0f} ± {s['e2e_ms'][1]:.0f} ms | {ram} |")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("configs", nargs="*", help="gpu, hybrid, npu, spec")
    ap.add_argument("--reps", type=int, default=5)
    ap.add_argument("--table", action="store_true")
    ap.add_argument("--no-memory", action="store_true")
    ap.add_argument("--memory-only", action="store_true", help="redo only the peak-memory run of <config>_<input>.json")
    ap.add_argument("--input", type=int, default=1024)
    ap.add_argument("--new", type=int, default=256)
    ap.add_argument("--model", choices=["2.6b", "8b"], default="2.6b")
    a = ap.parse_args()
    global P, E2E, MODEL, OUT
    P, E2E, MODEL = a.input, a.new, a.model
    OUT = pathlib.Path(os.environ["PIPETTE_OUT"]) if os.environ.get("PIPETTE_OUT") else BASES[MODEL]
    for c in a.configs:
        if c not in (("gpu",) if MODEL == "8b" else ("gpu", "hybrid", "npu", "spec")):
            sys.exit(f"unknown configuration {c} for {MODEL}")
    if a.table:
        table()
        print()
        return sweep_table()
    OUT.mkdir(parents=True, exist_ok=True)
    ids = prompt_ids()
    f = ROOT / f"build/lfm2/pipette/ids{P}.txt"
    f.write_text(" ".join(map(str, ids)) + "\n")
    ids_file = f"{D}/runs/ids{P}.txt"
    adb("push", str(f), ids_file)
    for c in a.configs:
        if a.memory_only:
            rec = json.loads((OUT / f"{c}_{P}.json").read_text())
            rec["memory"] = peak_memory(c, ids_file)
            (OUT / f"{c}_{P}.json").write_text(json.dumps(rec, indent=1))
            continue
        print(f"{c}: {a.reps} repetitions of {P} -> {E2E}", flush=True)
        res = measure(c, a.reps, ids_file)
        rec = dict(config=c, reps=res, summary=summary(res))
        if not a.no_memory:
            rec["memory"] = peak_memory(c, ids_file)
        rec.update(input=P, new=E2E, phone=adb("shell", "getprop ro.build.fingerprint").strip())
        name = f"{c}_{P}.json"
        (OUT / name).write_text(json.dumps(rec, indent=1))
        s = rec["summary"]
        print(f"{c}: prefill {s['prefill_tps'][0]:.0f} ± {s['prefill_tps'][1]:.0f} tok/s, TTFT {s['ttft_ms'][0]:.0f} ms, "
              f"decode {s['decode_tps'][0]:.1f} ± {s['decode_tps'][1]:.1f} tok/s, E2E {s['e2e_ms'][0]:.0f} ± "
              f"{s['e2e_ms'][1]:.0f} ms", flush=True)


if __name__ == "__main__":
    main()
