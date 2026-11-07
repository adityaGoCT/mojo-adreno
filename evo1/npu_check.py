"""Evo-1's NPU outputs (graph_tool run -o, or chain's <graph>_<name>.f32) against the official model's fp32 tensors;
the released bf16 model's actions for scale.

  build/turbovla/venv/bin/python evo1/npu_check.py <dir with tokens.f32 / context.f32 / x.f32, or a chain's 0_tokens.f32 .. 4_x.f32>
"""

import pathlib
import sys

import numpy as np

REF = pathlib.Path(__file__).resolve().parents[1] / "build/evo1/ref"


def err(got, want):
    got, want = np.asarray(got, np.float32).ravel(), np.asarray(want, np.float32).ravel()
    rel = np.linalg.norm(got - want) / np.linalg.norm(want)
    return f"max abs {np.abs(got - want).max():.3g} (largest reference value {np.abs(want).max():.3g}), relative L2 {rel:.3g}"


def find(d, name, g=None):
    """name.f32 (graph_tool run -o) or <g>_name.f32 (graph_tool chain: graph g's output; the first match)."""
    if (d / f"{name}.f32").exists():
        return np.fromfile(d / f"{name}.f32", np.float32)
    hits = sorted(d.glob(f"*_{name}.f32"))
    return np.fromfile(hits[0], np.float32) if hits else None


def main():
    d = pathlib.Path(sys.argv[1])
    rd = lambda n: np.fromfile(REF / n, np.float32)
    t = find(d, "tokens")
    if (d / "0_tokens.f32").exists():  # the chain runs the vision graph once a view: graphs 0, 1, 2
        t = np.concatenate([np.fromfile(d / f"{v}_tokens.f32", np.float32) for v in range(3)])
    if t is not None:
        print("views' tokens (768 x 896):", err(t, rd("mlp1_out.f32")))
    c = find(d, "context")
    if c is not None:
        print("LLM context rows (1024 x 896):", err(c, rd("context.f32").reshape(1025, 896)[:1024]))
    x = find(d, "x")
    if x is not None:
        x = x.reshape(50, 24)[:, :7]
        print("actions (50 x 7, normalized):", err(x, rd("actions_norm.f32").reshape(50, 24)[:, :7]))
        print("  the released bf16 model, for scale:", err(rd("bf16_actions_norm.f32").reshape(50, 24)[:, :7],
                                                         rd("actions_norm.f32").reshape(50, 24)[:, :7]))


if __name__ == "__main__":
    main()
