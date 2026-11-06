"""Ternary Qwen3-8B on the phone with its prompt prefilled on the Hexagon NPU (npu/export_qwen3.py's w4a16 graphs)
and decoded on the Adreno (npu/hybrid_qwen3), timed against Qwen3.prefill on the GPU (qwen3/qwen3.mojo with
QWEN3_PREFILL), the way npu/run.py does it for Llama.

  PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python
  ANDROID_SERIAL=<lab phone> PYTHONPATH=build/npu/pydeps $PY npu/run_qwen3.py [--setup] [--kv] [--baseline]

--setup, on a phone without the model: it downloads the checkpoint from Hugging Face (SHA-256 checked), writes the
GPU's weights (qwen3_convert, a context of 1024) and the NPU graphs' weights (qwen3_lpbq, SHA-256 checked against
the Mac's export), and takes the GPU program (build/android/qwen3). Then: the graphs pushed and compiled (a part a
process), --kv (npu_tool's prefill timed alone, its K/V and logits against PyTorch: npu/qwen3_check.py's references),
the hybrid run, and --baseline (the all-GPU run). The prompt is build/qwen3/long_llama.txt (408 tokens).
"""

import argparse
import os
import pathlib
import re
import subprocess
import sys
import time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
DEV = os.environ.get("NPU_DEV", "/data/local/tmp/npu")
Q = "/data/local/tmp/qwen3"
LD = f"LD_LIBRARY_PATH={DEV}:/system/lib64:/vendor/lib64"
URL = "https://huggingface.co/prism-ml/Ternary-Bonsai-8B-mlx-2bit/resolve/main/model.safetensors"
SHA = "f43270cbae86830b7eecb25bb8a0a0a005a81f180b68868dc39c755cebfff362"


def sh(*cmd, check=True):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r


def adb_run(cmd, out):
    sh("adb", "shell", f"{cmd} > {out} 2>&1; echo exit $? >> {out}", check=False)
    return sh("adb", "shell", f"cat {out}").stdout


def skin():
    text = sh("adb", "shell", "dumpsys thermalservice").stdout.split("Current temperatures from HAL")[-1]
    vals = [float(v) for v in re.findall(r"mValue=([\d.]+), mType=3, mName=SKIN", text)]
    return max(vals) if vals else 0.0


def cool(limit):
    t = skin()
    while t >= limit:
        print(f"  phone SKIN {t:.1f} C, waiting for < {limit} C", flush=True)
        time.sleep(30)
        t = skin()
    return t


def show(out):
    print("\n".join("  " + l for l in out.splitlines() if not l.startswith(("tok ", "[ort", "check "))))


def setup(graphs, gdir):
    sh("adb", "shell", f"mkdir -p {Q}/ckpt {Q}/model1024 {Q}/mojo {gdir} {DEV}")
    gpu = ROOT / "build/android/qwen3"
    sh("adb", "push", *sorted(p for p in gpu.iterdir() if p.suffix != ".o" and p.name != "qwen3_convert"),
       f"{Q}/mojo/")
    sh("adb", "push", gpu / "qwen3_convert", ROOT / "build/npu/phone/qwen3_lpbq", ROOT / "build/qwen3/rope1024.f32",
       f"{Q}/")
    have = sh("adb", "shell", f"sha256sum {Q}/ckpt/model.safetensors", check=False).stdout.split()
    if not have or have[0] != SHA:
        print("phone: downloading model.safetensors (2.3 GB) ...", flush=True)
        print(adb_run(f"cd {Q}/ckpt; curl -4 --connect-timeout 30 --retry 3 -sSL -o model.safetensors {URL}; "
                      f"sha256sum model.safetensors", f"{Q}/curl.txt"))
        if SHA not in sh("adb", "shell", f"sha256sum {Q}/ckpt/model.safetensors").stdout:
            sys.exit("the phone's checkpoint is not the expected one")
    form = graphs.name.split("-")[-1]
    print(adb_run(f"cd {Q}; ./qwen3_convert ckpt/model.safetensors rope1024.f32 model1024; "
                  f"./qwen3_lpbq ckpt/model.safetensors {gdir} {form}", f"{Q}/conv.txt")[-300:])
    want = sh("shasum", "-a", "256", graphs / "weights.bin").stdout.split()[0]
    if want not in sh("adb", "shell", f"sha256sum {gdir}/weights.bin").stdout:
        sys.exit(f"{gdir}/weights.bin differs from {graphs}/weights.bin")
    print("phone: the NPU graphs' weights byte for byte the Mac's export")


def push(graphs, gdir):
    sh("adb", "shell", f"mkdir -p {DEV} {gdir}")
    have = set(sh("adb", "shell", f"ls {DEV}").stdout.split())
    phone = ROOT / "build/npu/phone"
    files = [p for p in phone.iterdir() if p.suffix != ".o" and p.name != "qwen3_lpbq"
             and (p.name not in have or p.name in ("hybrid_qwen3", "npu_tool"))]
    if files:
        sh("adb", "push", *files, f"{DEV}/")
    if "npu.txt" not in sh("adb", "shell", f"ls {gdir}").stdout.split():
        sh("adb", "push", graphs / "npu.txt", *sorted(graphs.glob("part*.onnx")), f"{gdir}/")
    parts = int((graphs / "npu.txt").read_text().split()[4])
    have = sh("adb", "shell", f"ls {gdir}").stdout.split()
    for i in [i for i in range(parts) if f"part{i}_ctx.onnx" not in have]:
        print(f"compiling part {i} for the HTP ...", flush=True)
        show(adb_run(f"cd {DEV}; {LD} ./npu_tool compile {gdir} {i}", f"{DEV}/compile{i}.txt"))


def tokens(out):
    return [int(l.split()[1]) for l in out.splitlines() if l.startswith("tok ")]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--graphs", type=pathlib.Path, default=ROOT / "build/npu/qwen3-pc4")
    ap.add_argument("--ids", type=pathlib.Path, default=ROOT / "build/qwen3/long_llama.txt")
    ap.add_argument("--max-new", type=int, default=80)
    ap.add_argument("--setup", action="store_true")
    ap.add_argument("--kv", action="store_true")
    ap.add_argument("--baseline", action="store_true")
    ap.add_argument("--cool", type=float, default=40.0)
    a = ap.parse_args()
    gdir = f"{Q}/npu-{a.graphs.name.split('-')[-1]}"
    ids = a.ids.read_text().split()
    id_str = " ".join(ids)
    print(f"prompt: {len(ids)} tokens")
    if a.setup:
        setup(a.graphs, gdir)
    push(a.graphs, gdir)

    if a.kv:
        print(f"\nnpu_tool (SKIN {cool(a.cool):.1f} C):", flush=True)
        sh("adb", "shell", f"mkdir -p {DEV}/dump-qwen3")
        show(adb_run(f"cd {DEV}; {LD} ./npu_tool {gdir} {Q}/model1024 5 dump-qwen3 {id_str}", f"{DEV}/tool_q3.txt"))
        dump = ROOT / "build/npu/dump-qwen3"
        dump.mkdir(parents=True, exist_ok=True)
        sh("adb", "pull", f"{DEV}/dump-qwen3/kv.f16", f"{DEV}/dump-qwen3/logits.f32", dump)
        r = subprocess.run([sys.executable, HERE / "qwen3_check.py", "compare", "--graphs", a.graphs, "--ids", a.ids,
                            "--dump", dump], capture_output=True, text=True)
        print(r.stdout + r.stderr)

    print(f"\nhybrid: NPU prefill + GPU decode (SKIN {cool(a.cool):.1f} C):", flush=True)
    out = adb_run(f"cd {DEV}; {LD} MODULAR_DRIVER_PLUGINS=vulkan@{DEV}/libM_driver_vulkan.so NPU_RUNS=3 "
                  f"QWEN3_LOGITS={DEV}/logits_q3.bin ./hybrid_qwen3 {Q}/model1024 {gdir} {a.max_new} {id_str}",
                  f"{DEV}/hybrid_q3.txt")
    show(out)
    got = tokens(out)
    (ROOT / "build/npu/qwen3_hybrid_tokens.txt").write_text(" ".join(map(str, got)) + "\n")

    if a.baseline:
        print(f"\nall-GPU: qwen3.mojo, Qwen3.prefill on the Adreno (SKIN {cool(a.cool):.1f} C):", flush=True)
        out = adb_run(f"cd {Q}; MODULAR_DRIVER_PLUGINS=vulkan@{Q}/mojo/libM_driver_vulkan.so QWEN3_PREFILL=1 "
                      f"mojo/qwen3 model1024 {a.max_new} {id_str}", f"{Q}/gpu.txt")
        show(out)
        ref = tokens(out)
        (ROOT / "build/npu/qwen3_gpu_tokens.txt").write_text(" ".join(map(str, ref)) + "\n")
        same = next((i for i, (x, y) in enumerate(zip(got, ref)) if x != y), min(len(got), len(ref)))
        print(f"  tokens: hybrid {len(got)}, all-GPU {len(ref)}, identical for the first {same}")


if __name__ == "__main__":
    main()
