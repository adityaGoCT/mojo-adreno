"""Llama 3.2 1B on the phone with its prompt prefilled on the Hexagon NPU and decoded on the Adreno (npu/hybrid),
checked against PyTorch and timed against the all-GPU path (llama/llama.mojo with LLAMA_PREFILL).

  PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python
  PYTHONPATH=build/npu/pydeps $PY npu/run.py --model <HF snapshot dir> [--quant q4] [--kv] [--baseline]

1. reference: llama/run.py's greedy decode in PyTorch (fp32 math on the fp16-rounded weights). With --quant q4
   the GPU decodes with the int4 weights while the NPU prefilled with fp16 ones, so the reference does the same:
   the fp16 model's KV cache after the prompt, then int4 decode.
2. graphs: npu/export.py's prefill graphs (build/npu/graphs), pushed next to the phone's own
   /data/local/tmp/llama/model/weights.bin, which they read; npu/build.py hybrid's program and libraries
   (--setup first, on a wiped phone: the phone downloads and converts the checkpoint).
3. --kv: npu_tool runs the prefill alone and dumps K/V and logits; compared with PyTorch's cache, layer by layer.
   After the hybrid run, PyTorch also decodes from the NPU's own K/V: the phone must generate exactly that (a test
   of the handoff and GPU decode that the fp16 prefill's error cannot blur at a near-tie).
4. hybrid: NPU prefill, handoff, GPU decode; tokens and logits against the reference.
5. --baseline: the same prompt through llama.mojo's all-GPU batched prefill, then decode.
6. --all-npu: prefill and decode both on the NPU (npu_decode; npu/export_decode.py's graphs, compiled once).
Before each timed run the phone cools to SKIN < --cool C (dumpsys thermalservice).
"""

import argparse
import os
import pathlib
import re
import subprocess
import sys
import time

import numpy as np
import torch

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(ROOT / "llama"))
import run as llama_run  # noqa: E402  llama/run.py: load_model, reference, quantize_model4, CONFIG_1B

DEV = "/data/local/tmp/npu"
LLAMA = "/data/local/tmp/llama"
GRAPHS = f"{LLAMA}/model"  # the NPU graphs and their compiled contexts, next to the fp16 weights.bin they read
# system libraries before vendor ones: otherwise libbinder_ndk binds the vendor libbinder and the HTP stub fails
LD = f"LD_LIBRARY_PATH={DEV}:/system/lib64:/vendor/lib64"


def sh(*cmd, check=True):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r


def adb_run(cmd, out):
    """Runs `cmd` on the phone with its output in the file `out` there, then returns that output (the bridge
    drops long-lived adb shell streams and any line with && or &)."""
    sh("adb", "shell", f"{cmd} > {out} 2>&1; echo exit $? >> {out}", check=False)
    return sh("adb", "shell", f"cat {out}").stdout


def skin():
    text = sh("adb", "shell", "dumpsys thermalservice").stdout
    cur = text.split("Current temperatures from HAL")[-1]
    vals = [float(v) for v in re.findall(r"mValue=([\d.]+), mType=3, mName=SKIN", cur)]
    return max(vals) if vals else 0.0


def cool(limit):
    t = skin()
    while t >= limit:
        print(f"  phone SKIN {t:.1f} C, waiting for < {limit} C", flush=True)
        time.sleep(30)
        t = skin()
    return t


@torch.no_grad()
def reference_mixed(model, ids, max_new, eos):
    """The fp16 model's prompt pass (as the NPU's), then greedy int4 decode (as the GPU's q4 weights)."""
    out = model(torch.tensor([ids]), use_cache=True)
    first = out.logits[0, -1].float().numpy()
    past, nxt = out.past_key_values, int(out.logits[0, -1].argmax())
    llama_run.quantize_model4(model)
    toks = []
    for _ in range(max_new):
        toks.append(nxt)
        if nxt in eos or len(toks) == max_new:
            break
        out = model(torch.tensor([[nxt]]), past_key_values=past, use_cache=True)
        past, nxt = out.past_key_values, int(out.logits[0, -1].argmax())
    return toks, first


@torch.no_grad()
def prompt_cache(model, ids):
    out = model(torch.tensor([ids]), use_cache=True)
    pkv = out.past_key_values
    layers = []
    for l in range(len(model.model.layers)):
        try:
            k, v = pkv.layers[l].keys[0], pkv.layers[l].values[0]
        except AttributeError:
            k, v = pkv[l][0][0], pkv[l][1][0]
        layers.append((k.numpy(), v.numpy()))
    return layers


def setup():
    """A wiped lab phone: the phone downloads Llama's checkpoint from Hugging Face and converts it with
    llama/st2bin.c (fp16 and int4, checked by SHA-256 against the Mac's export), and the GPU program is pushed."""
    sh("adb", "shell", f"mkdir -p {LLAMA}/conv {LLAMA}/conv-q4 {LLAMA}/model {LLAMA}/model-q4 {LLAMA}/mojo {DEV}")
    b = ROOT / "build/llama"
    sh("adb", "push", *(b / "conv" / f for f in ("recipe.txt", "rope.cos", "rope.sin")), b / "st2bin", f"{LLAMA}/conv/")
    sh("adb", "push", *(b / "conv-q4" / f for f in ("recipe.txt", "rope.cos", "rope.sin")), f"{LLAMA}/conv-q4/")
    sh("adb", "push", b / "model/manifest.txt", f"{LLAMA}/model/")
    sh("adb", "push", b / "model-q4/manifest.txt", f"{LLAMA}/model-q4/")
    gpu = ROOT / "build/android/llama"
    sh("adb", "push", *sorted(p for p in gpu.iterdir() if p.suffix != ".o"), f"{LLAMA}/mojo/")
    url = "https://huggingface.co/unsloth/Llama-3.2-1B-Instruct/resolve/main/model.safetensors"
    print("phone: downloading model.safetensors (2.47 GB) and converting it ...", flush=True)
    out = adb_run(f"cd {LLAMA}; curl -4 --connect-timeout 30 --retry 3 -sSL -o model.safetensors {url}; "
                  f"conv/st2bin model.safetensors conv/recipe.txt conv model/weights.bin; "
                  f"conv/st2bin model.safetensors conv-q4/recipe.txt conv-q4 model-q4/weights.bin; "
                  f"rm model.safetensors; sha256sum model/weights.bin model-q4/weights.bin", f"{LLAMA}/setup.txt")
    print(out)
    for d in ("model", "model-q4"):
        want = sh("shasum", "-a", "256", b / d / "weights.bin").stdout.split()[0]
        if f"{want}  {d}/weights.bin" not in out:
            sys.exit(f"{d}/weights.bin on the phone differs from the Mac's export")
    print("phone: weights byte for byte the Mac's export")


def push(graphs, push_graphs):
    """The NPU runtime and programs to DEV; the graphs next to the phone's model/weights.bin (their external data
    is "weights.bin" in the graph's own directory; a lab phone may refuse a hard link to it)."""
    sh("adb", "shell", f"mkdir -p {DEV}")
    have = set(sh("adb", "shell", f"ls {DEV}").stdout.split())
    phone = ROOT / "build/npu/phone"
    files = [p for p in phone.iterdir()
             if p.suffix != ".o" and (p.name not in have or p.name in ("hybrid", "npu_tool"))]
    if files:
        sh("adb", "push", *files, f"{DEV}/")
    if push_graphs or "npu.txt" not in sh("adb", "shell", f"ls {GRAPHS}").stdout.split():
        sh("adb", "shell", f"rm -f {GRAPHS}/part*")  # the old graphs and their compiled contexts
        sh("adb", "push", graphs / "npu.txt", *sorted(graphs.glob("part*.onnx")), f"{GRAPHS}/")


def compile_graphs(graphs):
    """The one-time step: each part compiled for the HTP by QNN on the phone and its context binary saved, a part a
    process (compiling holds several copies of a part's weights; all four in one process exhaust the phone)."""
    parts = int((graphs / "npu.txt").read_text().split()[4])
    have = sh("adb", "shell", f"ls {GRAPHS}").stdout.split()
    todo = [i for i in range(parts) if f"part{i}_ctx.onnx" not in have]
    if not todo:
        return
    print(f"\ncompiling parts {todo} for the HTP (once; QNN's graph finalization mode 3) ...", flush=True)
    for i in todo:
        out = adb_run(f"cd {DEV}; {LD} ./npu_tool compile {GRAPHS} {i}", f"{DEV}/compile{i}.txt")
        print("\n".join("  " + l for l in out.splitlines() if not l.startswith("[ort")))


@torch.no_grad()
def replay(model, kv, first, max_new, eos):
    """Greedy decode in PyTorch from the NPU's own KV cache (kv [layer][k, v][8][n][64]) and first token: what the GPU
    should generate after the handoff, whatever the fp16 prefill's error."""
    from transformers import DynamicCache

    past = DynamicCache()
    for l in range(kv.shape[0]):
        past.update(torch.from_numpy(kv[l, 0])[None], torch.from_numpy(kv[l, 1])[None], l)
    toks, nxt = [], first
    for _ in range(max_new):
        toks.append(nxt)
        if nxt in eos or len(toks) == max_new:
            break
        out = model(torch.tensor([[nxt]]), past_key_values=past, use_cache=True)
        past, nxt = out.past_key_values, int(out.logits[0, -1].argmax())
    return toks


def all_npu(a, ids, eos, ref, tok):
    """Prefill and decode both on the NPU: npu_decode, with the decode parts compiled once, a part a process."""
    have = sh("adb", "shell", f"ls {GRAPHS}").stdout.split()
    parts = int((a.decode_graphs / "decode.txt").read_text().split()[4])
    if a.push_graphs or "decode.txt" not in have:
        sh("adb", "shell", f"rm -f {GRAPHS}/decode*")
        sh("adb", "push", a.decode_graphs / "decode.txt", *sorted(a.decode_graphs.glob("decode*.onnx")), f"{GRAPHS}/")
        have = sh("adb", "shell", f"ls {GRAPHS}").stdout.split()
    for i in range(parts):
        if f"decode{i}_ctx.onnx" not in have:
            out = adb_run(f"cd {DEV}; {LD} ./npu_decode compile {GRAPHS} {i}", f"{DEV}/dcompile{i}.txt")
            print("\n".join("  " + l for l in out.splitlines() if not l.startswith("[ort")))
    print(f"\nall-NPU: prefill and decode on the HTP, fp16 (SKIN {cool(a.cool):.1f} C):", flush=True)
    out = adb_run(f"cd {DEV}; {LD} LLAMA_EOS={','.join(map(str, eos))} ./npu_decode {GRAPHS} {a.max_new} "
                  f"{' '.join(map(str, ids))}", f"{DEV}/allnpu.txt")
    print("\n".join("  " + l for l in out.splitlines() if not l.startswith(("tok ", "[ort"))))
    got = parse(out)
    match = next((i for i, (x, y) in enumerate(zip(got, ref)) if x != y), min(len(got), len(ref)))
    print(f"  tokens: phone {len(got)}, PyTorch {len(ref)}, identical for the first {match}")
    if match < min(len(got), len(ref)):
        print("  phone:  ", repr(tok.decode(got, skip_special_tokens=True)))
        print("  PyTorch:", repr(tok.decode(ref, skip_special_tokens=True)))


def parse(out):
    toks = [int(l.split()[1]) for l in out.splitlines() if l.startswith("tok ")]
    return toks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, help="Hugging Face snapshot dir of Llama-3.2-1B-Instruct")
    ap.add_argument("--prompt-file", default=str(ROOT / "llama/prompts/long.txt"))
    ap.add_argument("--max-new", type=int, default=80)
    ap.add_argument("--quant", choices=["fp16", "q4"], default="fp16", help="the GPU decode's weights")
    ap.add_argument("--graphs", type=pathlib.Path, default=ROOT / "build/npu/graphs")
    ap.add_argument("--push-graphs", action="store_true", help="replace the phone's graphs (and their contexts)")
    ap.add_argument("--kv", action="store_true", help="check the NPU's K/V against PyTorch's (npu_tool)")
    ap.add_argument("--baseline", action="store_true", help="also time the all-GPU path (llama.mojo, LLAMA_PREFILL)")
    ap.add_argument("--runs", type=int, default=3, help="NPU prefills in the hybrid run (first cold)")
    ap.add_argument("--cool", type=float, default=40.0)
    ap.add_argument("--setup", action="store_true", help="a wiped phone: download, convert and push everything")
    ap.add_argument("--compile-only", action="store_true", help="compile the graphs on the phone and stop")
    ap.add_argument("--all-npu", action="store_true",
                    help="also run prefill and decode both on the NPU (npu_decode, npu/export_decode.py's graphs)")
    ap.add_argument("--decode-graphs", type=pathlib.Path, default=ROOT / "build/npu/decode")
    ap.add_argument("--no-hybrid", action="store_true", help="skip the NPU prefill + GPU decode run")
    a = ap.parse_args()
    from transformers import AutoTokenizer

    tok = AutoTokenizer.from_pretrained(a.model)
    prompt = pathlib.Path(a.prompt_file).read_text().strip()
    ids = tok.apply_chat_template([{"role": "user", "content": prompt}], add_generation_prompt=True)
    ids = list(ids["input_ids"] if hasattr(ids, "keys") else ids)
    eos = list(llama_run.CONFIG_1B["eos_token_id"])
    model = llama_run.load_model(a.model)
    print(f"prompt: {len(ids)} tokens")
    cache = prompt_cache(model, ids) if a.kv else None
    t = time.time()
    if a.quant == "q4":
        ref, ref_logits = reference_mixed(model, ids, a.max_new, eos)
    else:
        ref, ref_logits = llama_run.reference(model, ids, a.max_new, eos)
    print(f"reference (PyTorch fp32 on the Mac): {len(ref)} tokens in {time.time() - t:.1f} s")

    if a.setup:
        setup()
    push(a.graphs, a.push_graphs)
    compile_graphs(a.graphs)
    if a.compile_only:
        return
    gdir = "model-q4" if a.quant == "q4" else "model"
    id_str = " ".join(map(str, ids))
    eos_env = f"LLAMA_EOS={','.join(map(str, eos))}"

    if a.kv:
        print(f"\nnpu_tool (SKIN {cool(a.cool):.1f} C):", flush=True)
        sh("adb", "shell", f"mkdir -p {DEV}/dump")
        out = adb_run(f"cd {DEV}; {LD} ./npu_tool {GRAPHS} {LLAMA}/model 3 dump {id_str}", f"{DEV}/tool.txt")
        print("\n".join("  " + l for l in out.splitlines() if not l.startswith("[ort")))
        build = ROOT / "build/npu"
        sh("adb", "pull", f"{DEV}/dump/kv.f16", f"{DEV}/dump/logits.f32", build)
        n = len(ids)
        kv = np.fromfile(build / "kv.f16", np.float16).astype(np.float32).reshape(16, 2, 8, n, 64)
        worst = 0.0
        for l, (k, v) in enumerate(cache):
            ek, ev = np.abs(kv[l, 0] - k).max(), np.abs(kv[l, 1] - v).max()
            rk = np.linalg.norm(kv[l, 0] - k) / np.linalg.norm(k)
            rv = np.linalg.norm(kv[l, 1] - v) / np.linalg.norm(v)
            worst = max(worst, rk, rv)
            print(f"  layer {l:2d}: K max |err| {ek:.3f} (|K| <= {np.abs(k).max():.1f}), rel {rk:.1e}; "
                  f"V max |err| {ev:.3f} (|V| <= {np.abs(v).max():.2f}), rel {rv:.1e}")
        lg = np.fromfile(build / "logits.f32", np.float32)
        print(f"  K/V relative error (Frobenius) at most {worst:.1e}; logits max |err| "
              f"{np.abs(lg - ref_logits).max():.3f}, argmax {lg.argmax()} (PyTorch {ref_logits.argmax()})")

    if a.all_npu:
        if a.quant != "fp16":
            sys.exit("--all-npu: the NPU decode graphs are fp16")
        all_npu(a, ids, eos, ref, tok)
    if a.no_hybrid:
        return

    print(f"\nhybrid: NPU prefill + GPU decode, {a.quant} decode weights (SKIN {cool(a.cool):.1f} C):", flush=True)
    out = adb_run(f"cd {DEV}; {LD} MODULAR_DRIVER_PLUGINS=vulkan@{DEV}/libM_driver_vulkan.so NPU_RUNS={a.runs} "
                  f"{eos_env} LLAMA_LOGITS={DEV}/logits.bin ./hybrid {LLAMA}/{gdir} {GRAPHS} {a.max_new} {id_str}",
                  f"{DEV}/hybrid.txt")
    print("\n".join("  " + l for l in out.splitlines() if not l.startswith(("tok ", "[ort"))))
    got = parse(out)
    sh("adb", "pull", f"{DEV}/logits.bin", ROOT / "build/npu/logits_hybrid.bin")
    lg = np.fromfile(ROOT / "build/npu/logits_hybrid.bin", np.float32)
    match = next((i for i, (x, y) in enumerate(zip(got, ref)) if x != y), min(len(got), len(ref)))
    print(f"  first-token logits from the NPU: max |NPU - PyTorch| = {np.abs(lg - ref_logits).max():.3f} "
          f"(logit range {ref_logits.min():.1f} .. {ref_logits.max():.1f})")
    print(f"  tokens: phone {len(got)}, PyTorch {len(ref)}, identical for the first {match}")
    print("  phone:  ", repr(tok.decode(got, skip_special_tokens=True)))
    if match < min(len(got), len(ref)):
        print("  PyTorch:", repr(tok.decode(ref, skip_special_tokens=True)))
    if a.kv and got:  # the model holds the decode's weights now (int4 after reference_mixed)
        again = replay(model, kv, got[0], a.max_new, eos)
        same = next((i for i, (x, y) in enumerate(zip(got, again)) if x != y), min(len(got), len(again)))
        print(f"  PyTorch decode from the NPU's own K/V: identical to the phone for the first {same} of {len(again)}")

    if a.baseline:
        print(f"\nall-GPU: llama.mojo, batched prefill on the Adreno (SKIN {cool(a.cool):.1f} C):", flush=True)
        out = adb_run(f"cd {LLAMA}; MODULAR_DRIVER_PLUGINS=vulkan@{LLAMA}/mojo/libM_driver_vulkan.so LLAMA_PREFILL=1 "
                      f"{eos_env} mojo/llama {gdir} {a.max_new} {id_str}", f"{DEV}/gpu.txt")
        print("\n".join("  " + l for l in out.splitlines() if not l.startswith("tok ")))
        got = parse(out)
        if a.quant == "q4":  # all int4 on the GPU: against PyTorch with int4 weights throughout (the model is int4 now)
            ref = llama_run.reference(model, ids, a.max_new, eos)[0]
        match = next((i for i, (x, y) in enumerate(zip(got, ref)) if x != y), min(len(got), len(ref)))
        print(f"  tokens: phone {len(got)}, PyTorch {len(ref)}, identical for the first {match}")


if __name__ == "__main__":
    main()
