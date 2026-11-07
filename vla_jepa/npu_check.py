"""VLA-JEPA's NPU outputs (graph_tool run -o, or chain's <graph>_<name>.f32) against the official model's fp32
tensors; the released bf16 model's actions for scale.

  build/turbovla/venv/bin/python vla_jepa/npu_check.py <dir with tokens.f32 / deepstack.f32 / embodied.f32 / x.f32,
                                                          or 0_tokens.f32 ...>
"""

import pathlib
import sys

import numpy as np

REF = pathlib.Path(__file__).resolve().parents[1] / "build/vla_jepa/ref"


def err(got, want):
    got, want = np.asarray(got, np.float32).ravel(), np.asarray(want, np.float32).ravel()
    rel = np.linalg.norm(got - want) / np.linalg.norm(want)
    return f"max abs {np.abs(got - want).max():.3g} (largest reference value {np.abs(want).max():.3g}), relative L2 {rel:.3g}"


def find(d, name, g):
    for f in (d / f"{g}_{name}.f32", d / f"{name}.f32"):
        if f.exists():
            return np.fromfile(f, np.float32)
    return None


def main():
    d = pathlib.Path(sys.argv[1])
    rd = lambda n: np.fromfile(REF / n, np.float32)
    t = find(d, "tokens", 0)
    if t is not None:
        print("vision tokens (128 x 2048):", err(t, rd("vit_merger.f32")))
    ds = find(d, "deepstack", 0)
    if ds is not None:
        for k in range(3):
            print(f"DeepStack {k}:", err(ds.reshape(3, -1)[k], rd(f"vit_deepstack{k}.f32")))
    e = find(d, "embodied", 1)
    if e is not None:
        print("embodied rows (32 x 2048):", err(e, rd("embodied_hidden.f32")))
    x = find(d, "x", 2)
    if x is not None:
        print("actions (7 x 7, normalized):", err(x, rd("actions_norm.f32")))
        print("  the released bf16 model, for scale:", err(rd("bf16_actions_norm.f32"), rd("actions_norm.f32")))


if __name__ == "__main__":
    main()
