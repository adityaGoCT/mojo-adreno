"""Checks for npu/export_qwen3.py, on the Mac:

  PYTHONPATH=build/npu/pydeps $PY npu/qwen3_check.py --checkpoint build/qwen3-ckpt mlx
      the PyTorch reference against MLX's logits (qwen3/export.py's reference.f32, the 19-token prompt)
  ... reference --ids build/qwen3/long_llama.txt [--graphs build/npu/qwen3-w4a16]
      K/V and logits of a prompt: the exact ternary model, and the graphs' int4 weights (saved as .npz)
  ... compare --ids ... --dump build/npu/dump-qwen3 [--graphs ...]
      the NPU's kv.f16 and logits.f32 (npu_tool's dump) against both
  ... cpu --dump build/npu/dump-qwen3-cpu
      the graphs on the Mac's CPU (ONNX Runtime), dumped like npu_tool (then compare --dump ...)
"""

import argparse
import pathlib
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import export_qwen3 as q3  # noqa: E402
import quant  # noqa: E402

ROOT = HERE.parent


def ids_of(path):
    return [int(t) for t in pathlib.Path(path).read_text().split()]


def ref_path(graphs, ids_file, kind):
    return graphs / f"ref_{pathlib.Path(ids_file).stem}_{kind}.npz"


def reference(a, ck, rope):
    ids = ids_of(a.ids)
    for kind, reader in (("exact", None), ("graphs", quant.Reader(a.graphs))):
        out = ref_path(a.graphs, a.ids, kind)
        if out.exists():
            continue
        print(f"{kind}: {len(ids)} tokens", flush=True)
        logits, kv = q3.reference(ck, [ids], rope, reader, keep_kv=True)
        np.savez(out, logits=logits[0], k=np.stack([kv[l][0] for l in range(q3.L)]),
                 v=np.stack([kv[l][1] for l in range(q3.L)]))


def compare(a):
    ids = ids_of(a.ids)
    n = len(ids)
    kv = np.fromfile(a.dump / "kv.f16", np.float16).astype(np.float32).reshape(q3.L, 2, q3.KVH, n, q3.HD)
    lg = np.fromfile(a.dump / "logits.f32", np.float32)
    for kind in ("exact", "graphs"):
        r = np.load(ref_path(a.graphs, a.ids, kind))
        worst, rows = 0.0, []
        for l in range(q3.L):
            rk = np.linalg.norm(kv[l, 0] - r["k"][l]) / np.linalg.norm(r["k"][l])
            rv = np.linalg.norm(kv[l, 1] - r["v"][l]) / np.linalg.norm(r["v"][l])
            worst = max(worst, rk, rv)
            rows.append(f"    layer {l:2d}: K rel {rk:.1e} (max |err| {np.abs(kv[l, 0] - r['k'][l]).max():.3f}, "
                        f"|K| <= {np.abs(r['k'][l]).max():.1f}), V rel {rv:.1e}")
        if a.verbose:
            print("\n".join(rows))
        ref = r["logits"]
        print(f"  vs PyTorch ({'exact ternary weights' if kind == 'exact' else 'the graphs int4 weights'}): K/V "
              f"relative error at most {worst:.1e}; logits max |err| {np.abs(lg - ref).max():.3f} (range "
              f"{ref.min():.1f} .. {ref.max():.1f}), argmax {lg.argmax()} ({ref.argmax()}), top 5 same: "
              f"{set(np.argsort(-lg)[:5]) == set(np.argsort(-ref)[:5])}")


def cpu(a, ck):
    """The graphs on the Mac's CPU (ONNX Runtime), written as npu_tool's dump (kv.f16, logits.f32) to --dump."""
    import onnxruntime as ort

    ids = ids_of(a.ids)
    n = len(ids)
    meta = (a.graphs / "npu.txt").read_text().split()
    rows, parts = int(meta[2]), int(meta[4])
    bounds = list(map(int, meta[6:7 + parts]))
    x = np.zeros((rows, q3.D), np.float16)
    x[:n] = q3.embed_rows(ck, ids).astype(np.float16)
    a.dump.mkdir(parents=True, exist_ok=True)
    kv = np.zeros((q3.L, 2, q3.KVH, n, q3.HD), np.float16)
    for i in range(parts):
        s = ort.InferenceSession(str(a.graphs / f"part{i}.onnx"), providers=["CPUExecutionProvider"])
        feeds = {"x": x}
        if i == parts - 1:
            feeds["last"] = np.array([n - 1], np.int32)
        names = [o.name for o in s.get_outputs()]
        outs = dict(zip(names, s.run(names, feeds)))
        for l in range(bounds[i], bounds[i + 1]):
            kv[l, 0], kv[l, 1] = outs[f"k{l}"][:, :n], outs[f"v{l}"][:, :n]
        x = outs.get("x_out", x)
        print(f"  part {i} on the CPU", flush=True)
        del s
    kv.tofile(a.dump / "kv.f16")
    outs["logits"][0].astype(np.float32).tofile(a.dump / "logits.f32")


def mlx_check(ck, rope):
    ids = ids_of(ROOT / "build/qwen3/model/prompt.txt")
    ref = np.fromfile(ROOT / "build/qwen3/model/reference.f32", np.float32, q3.V)
    logits, _ = q3.reference(ck, [ids], rope)
    lg = logits[0]
    print(f"PyTorch reference vs MLX after the {len(ids)}-token prompt: max |err| {np.abs(lg - ref).max():.4f}, "
          f"argmax {lg.argmax()} ({ref.argmax()})")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("what", choices=["mlx", "reference", "compare", "cpu"])
    ap.add_argument("--checkpoint", type=pathlib.Path, default=ROOT / "build/qwen3-ckpt")
    ap.add_argument("--rope", type=pathlib.Path, default=ROOT / "build/qwen3/rope1024.f32")
    ap.add_argument("--graphs", type=pathlib.Path, default=ROOT / "build/npu/qwen3-w4a16")
    ap.add_argument("--ids", default=str(ROOT / "build/qwen3/long_llama.txt"))
    ap.add_argument("--dump", type=pathlib.Path, default=ROOT / "build/npu/dump-qwen3")
    ap.add_argument("--verbose", action="store_true")
    a = ap.parse_args()
    rope = np.fromfile(a.rope, np.float32).reshape(-1, q3.HD)
    if a.what == "compare":
        return compare(a)
    ck = q3.Checkpoint(a.checkpoint / "model.safetensors")
    if a.what == "mlx":
        mlx_check(ck, rope)
    elif a.what == "cpu":
        cpu(a, ck)
    else:
        reference(a, ck, rope)


if __name__ == "__main__":
    main()
