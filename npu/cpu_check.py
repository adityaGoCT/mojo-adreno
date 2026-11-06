"""Runs npu/export.py's prefill graphs on the Mac's CPU (ONNX Runtime) and compares their KV cache and logits with
PyTorch: the fp16 model (fp32 math on the fp16 weights), and for w4a16 graphs also the model with the graphs' own
dequantized int4 weights (which separates the weights' error from the activations').

  PYTHONPATH=build/npu/pydeps $PY npu/cpu_check.py --graphs build/npu/graphs-w4a16 --hf <snapshot>
"""

import argparse
import pathlib
import sys
import time

import numpy as np
import onnxruntime as ort
import torch

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "llama"))
import export  # noqa: E402
import run as llama_run  # noqa: E402

D, L, CHUNKS, V = export.D, export.L, export.CHUNKS, export.V


def embed_rows(model_dir, ids, rows):
    man = export.manifest(model_dir)
    mm = np.memmap(model_dir / "weights.bin", np.uint8, "r")
    x = np.zeros((rows, D), np.float16)
    per = V // CHUNKS
    for t, i in enumerate(ids):
        off, _ = man[f"embed.{i // per}"]
        x[t] = np.frombuffer(mm, np.float16, D, off + (i % per) * D * 2)
    return x


def run_graphs(gdir, x, last):
    meta = (gdir / "npu.txt").read_text().split()
    parts = int(meta[4])
    bounds = list(map(int, meta[6:7 + parts]))
    kv, logits = {}, None
    so = ort.SessionOptions()
    for i in range(parts):
        t = time.time()
        s = ort.InferenceSession(str(gdir / f"part{i}.onnx"), so, providers=["CPUExecutionProvider"])
        feeds = {"x": x.astype(np.float16) if s.get_inputs()[0].type == "tensor(float16)" else x.astype(np.float32)}
        if i == parts - 1:
            feeds["last"] = np.array([last], np.int32)
        names = [o.name for o in s.get_outputs()]
        outs = dict(zip(names, s.run(names, feeds)))
        for l in range(bounds[i], bounds[i + 1]):
            kv[l] = (outs[f"k{l}"].astype(np.float32), outs[f"v{l}"].astype(np.float32))
        if "x_out" in outs:
            x = outs["x_out"]
        else:
            logits = outs["logits"][0].astype(np.float32)
        print(f"  part {i}: {time.time() - t:.1f} s", flush=True)
    return kv, logits


@torch.no_grad()
def torch_cache(model, ids):
    out = model(torch.tensor([ids]), use_cache=True)
    pkv = out.past_key_values
    layers = []
    for l in range(L):
        try:
            k, v = pkv.layers[l].keys[0], pkv.layers[l].values[0]
        except AttributeError:
            k, v = pkv[l][0][0], pkv[l][1][0]
        layers.append((k.numpy(), v.numpy()))
    return layers, out.logits[0, -1].numpy()


def compare(name, kv, logits, ref, ref_logits, n, verbose):
    worst = 0.0
    for l in range(L):
        k, v = kv[l][0][:, :n], kv[l][1][:, :n]
        rk = np.linalg.norm(k - ref[l][0]) / np.linalg.norm(ref[l][0])
        rv = np.linalg.norm(v - ref[l][1]) / np.linalg.norm(ref[l][1])
        worst = max(worst, rk, rv)
        if verbose:
            print(f"    layer {l:2d}: K rel {rk:.1e} (max |err| {np.abs(k - ref[l][0]).max():.3f}), "
                  f"V rel {rv:.1e} (max |err| {np.abs(v - ref[l][1]).max():.3f})")
    top = np.argsort(-ref_logits)[:5]
    print(f"  vs {name}: K/V relative error at most {worst:.1e}; logits max |err| "
          f"{np.abs(logits - ref_logits).max():.3f}, argmax {logits.argmax()} ({ref_logits.argmax()}), "
          f"top 5 same: {set(np.argsort(-logits)[:5]) == set(top)}")
    return worst


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--graphs", type=pathlib.Path, default=pathlib.Path("build/npu/graphs-w4a16"))
    ap.add_argument("--model", type=pathlib.Path, default=pathlib.Path("build/llama/model"))
    ap.add_argument("--hf", required=True)
    ap.add_argument("--prompt-file", default=str(HERE.parent / "llama/prompts/long.txt"))
    ap.add_argument("--verbose", action="store_true")
    a = ap.parse_args()
    from transformers import AutoTokenizer

    tok = AutoTokenizer.from_pretrained(a.hf)
    text = pathlib.Path(a.prompt_file).read_text().strip()
    ids = tok.apply_chat_template([{"role": "user", "content": text}], add_generation_prompt=True)
    ids = list(ids["input_ids"] if hasattr(ids, "keys") else ids)
    n = len(ids)
    rows = int((a.graphs / "npu.txt").read_text().split()[2])
    print(f"prompt: {n} tokens, graphs of {rows} rows ({a.graphs})")
    kv, logits = run_graphs(a.graphs, embed_rows(a.model, ids, rows), n - 1)
    model = llama_run.load_model(a.hf)
    ref, ref_logits = torch_cache(model, ids)
    compare("PyTorch, fp16 weights", kv, logits, ref, ref_logits, n, a.verbose)
    if (a.graphs / "calib.json").exists():
        export.apply_w4a16_weights(model, a.graphs)
        ref, ref_logits = torch_cache(model, ids)
        compare("PyTorch, the graphs' int4 weights", kv, logits, ref, ref_logits, n, a.verbose)


if __name__ == "__main__":
    main()
