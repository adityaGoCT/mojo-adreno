"""Checks π0's prefix graphs (npu/export_pi0.py) against pi0/reference.py's K/V cache.

  PYTHONPATH=build/npu/pydeps python3 npu/pi0_check.py --graphs build/npu/pi0        # ONNX Runtime on the Mac's CPU
  PYTHONPATH=build/npu/pydeps python3 npu/pi0_check.py --dump <kv.f16>               # the phone's (pi0npu_tool)
  ... --graphs build/npu/pi0 --save-kv kv_cpu.f32   then build/vla/venv/bin/python pi0/reference.py --kv kv_cpu.f32

The inputs are the reference's own prefix embeddings (prefix.f32), positions (cumsum of the pad mask, minus 1) and
RoPE table, as npu/pi0_prefix.cpp builds them on the phone. The K/V errors are over the valid rows (783 of 816): the
padded language rows are never read, since their keys are masked.
"""

import argparse
import pathlib
import time

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
D, L, HD, PLEN, VROWS = 2048, 18, 256, 816, 768


def inputs(ref, rows, dtype):
    x = np.zeros((rows, D), np.float32)
    x[:PLEN] = np.fromfile(ref / "prefix.f32", np.float32).reshape(PLEN, D)
    pad = np.concatenate([np.ones(VROWS, np.int32), np.fromfile(ref / "lang_mask.i32", np.int32)]) != 0
    pos = np.zeros(rows, np.int64)
    pos[:PLEN] = np.maximum(np.cumsum(pad) - 1, 0)
    rope = np.fromfile(ref / "rope.f32", np.float32).reshape(2, 1024, HD // 2)
    cos = np.concatenate([rope[0][pos], rope[0][pos]], 1)[:, None, :]
    sin = np.concatenate([rope[1][pos], rope[1][pos]], 1)[:, None, :]
    mask = np.full((1, rows), -30000, np.float32)
    mask[0, :PLEN][pad] = 0
    return {"x": x.astype(dtype), "cos": cos.astype(dtype), "sin": sin.astype(dtype), "mask": mask.astype(dtype)}, pad


def compare(ref, kv, pad):
    """kv[l] = (K, V) [>= 816, 256]: the worst layer's max abs error, and the relative (Frobenius) error."""
    worst = {}
    for l in range(L):
        for w, name in enumerate("kv"):
            want = np.fromfile(ref / f"{name}{l}.f32", np.float32).reshape(PLEN, HD)[pad]
            got = np.asarray(kv[l][w], np.float32)[:PLEN][pad]
            err = float(np.abs(got - want).max())
            rel = float(np.linalg.norm(got - want) / np.linalg.norm(want))
            print(f"  layer {l:2d} {name.upper()}: max abs error {err:.4f} (largest value {np.abs(want).max():.1f}), "
                  f"relative {rel:.1e}")
            if err > worst.get(name, (0, 0, 0, 0))[0]:
                worst[name] = (err, rel, l, float(np.abs(want).max()))
    for name, (err, rel, l, big) in worst.items():
        print(f"{name.upper()}, worst layer ({l}): max abs error {err:.4f} (largest value {big:.1f}), relative {rel:.1e}")


def run_graphs(graphs, ref, save_kv=None):
    import onnxruntime as ort

    meta = (graphs / "npu.txt").read_text().split()
    rows, parts = int(meta[2]), int(meta[4])
    fp32 = meta[-1] == "fp32"
    feed, pad = inputs(ref, rows, np.float32 if fp32 else np.float16)
    kv = {}
    so = ort.SessionOptions()
    for i in range(parts):
        t = time.time()
        s = ort.InferenceSession(str(graphs / f"part{i}.onnx"), so, providers=["CPUExecutionProvider"])
        names = [o.name for o in s.get_outputs()]
        out = dict(zip(names, s.run(None, feed)))
        for n in names:
            if n[0] in "kv" and n[1:].isdigit():
                kv.setdefault(int(n[1:]), [None, None])["kv".index(n[0])] = out[n]
        if "x_out" in out:
            feed["x"] = out["x_out"]
            print(f"part {i}: {time.time() - t:.1f} s, residual stream max {np.abs(out['x_out'].astype(np.float32)).max():.0f}",
                  flush=True)
        del s
    print(f"ONNX Runtime CPU, {'fp32' if fp32 else 'fp16'} graphs ({graphs}):")
    compare(ref, kv, pad)
    if save_kv:  # fp32 [layer][k, v][816][256], for pi0/reference.py --kv
        np.stack([np.stack([kv[l][0][:PLEN], kv[l][1][:PLEN]]) for l in range(L)]).astype(np.float32).tofile(save_kv)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ref", type=pathlib.Path, default=ROOT / "build/vla/pi0/ref")
    ap.add_argument("--graphs", type=pathlib.Path)
    ap.add_argument("--dump", type=pathlib.Path, help="pi0npu_tool's kv.f16: [layer][k, v][rows][256]")
    ap.add_argument("--rows", type=int, default=832)
    ap.add_argument("--save-kv", type=pathlib.Path, help="the K/V (--graphs' or --dump's) as fp32 [layer][k, v][816][256], for reference.py --kv")
    a = ap.parse_args()
    if a.graphs:
        run_graphs(a.graphs, a.ref, a.save_kv)
    if a.dump:
        _, pad = inputs(a.ref, a.rows, np.float32)
        d = np.fromfile(a.dump, np.float16).reshape(L, 2, -1, HD)
        print(f"the NPU's K/V ({a.dump}):")
        compare(a.ref, {l: (d[l, 0], d[l, 1]) for l in range(L)}, pad)
        if a.save_kv:
            d[:, :, :PLEN].astype(np.float32).tofile(a.save_kv)


if __name__ == "__main__":
    main()
