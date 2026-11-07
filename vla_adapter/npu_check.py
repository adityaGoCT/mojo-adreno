"""VLA-Adapter's NPU outputs against the official model's fp32 tensors, and where the actions' error comes from: the
policy in fp32 (export_npu.py's written-out module, PyTorch on the Mac's CPU) on the reference's taps or the NPU's.
The NPU's outputs come from graph_tool on the laptop (run -o, or chain's <graph>_<name>.f32).

  build/turbovla/venv/bin/python vla_adapter/npu_check.py <dir with vision.f32 and/or taps.f32 and/or actions.f32>
"""

import json
import pathlib
import sys

import numpy as np
import torch

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import export_npu as E  # noqa: E402

REF = E.B / "ref"


def err(got, want):
    got, want = np.asarray(got, np.float32), np.asarray(want, np.float32)
    rel = np.linalg.norm(got - want) / np.linalg.norm(want)
    return f"{np.abs(got - want).max():.3g} (largest reference value {np.abs(want).max():.3g}), relative L2 {rel:.3g}"


def find(d, name, g):
    """name.f32 (graph_tool run -o) or g_name.f32 (graph_tool chain: graph g's output)."""
    for f in (d / f"{g}_{name}.f32", d / f"{name}.f32"):
        if f.exists():
            return f
    return None


def main():
    d = pathlib.Path(sys.argv[1])
    meta = json.loads((REF / "meta.json").read_text())
    L, S = meta["L"], meta["S"]
    rd = lambda n: np.fromfile(REF / n, np.float32)
    idx = np.concatenate([np.arange(512), np.arange(L + 511, L + 575)])
    taps_ref = np.stack([rd(f"llm_hidden_{j:02d}.f32").reshape(S, 896)[idx] for j in range(1, 25)])
    act_ref = rd("policy_actions_norm.f32").reshape(8, 7)
    if find(d, "vision", 0):
        print("vision tokens (NPU):", err(np.fromfile(find(d, "vision", 0), np.float32).reshape(512, 896),
                                          rd("projector.f32").reshape(512, 896)))
    policy = E.Policy(E.W())
    prop = torch.from_numpy(rd("proprio_norm.f32").reshape(1, 8))
    if find(d, "taps", 1):
        taps = np.fromfile(find(d, "taps", 1), np.float32).reshape(24, 576, 896)
        for j in (0, 11, 22, 23):
            print(f"LLM tap {j + 1} (NPU):", err(taps[j], taps_ref[j]))
        with torch.no_grad():
            a = policy(torch.from_numpy(taps), prop).numpy()
        print("policy in fp32 on the NPU's taps: actions", err(a, act_ref))
    if find(d, "actions", 2):
        print("actions (NPU):", err(np.fromfile(find(d, "actions", 2), np.float32).reshape(8, 7), act_ref))
        print("  the released bf16 model, for scale:", err(rd("actions_norm_bf16.f32").reshape(8, 7), act_ref))


if __name__ == "__main__":
    main()
