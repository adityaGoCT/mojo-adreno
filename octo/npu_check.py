"""Octo's NPU outputs against Octo's own JAX tensors, and where the all-NPU actions' error comes from: the head graph
(ONNX Runtime on the Mac's CPU, fp32) run on the JAX readout or the NPU's, and the trunk graph (fp32) on the JAX
tokens or the NPU's. The NPU's outputs are graph_tool's (-o, or chain's <graph>_<name>.f32) from the laptop.

  build/turbovla/venv/bin/python octo/npu_check.py <dir with the NPU's task.f32, primary_tokens.f32,
      wrist_tokens.f32, readout.f32 (from trunk.onnx on the NPU's tokens) and actions.f32>
"""

import pathlib
import sys

import numpy as np
import onnxruntime as ort

ROOT = pathlib.Path(__file__).resolve().parents[1]
N = ROOT / "build/octo/npu"
REF = ROOT / "build/octo/ref"
NT, NPR, NWR, PER, D = 16, 256, 64, 337, 384


def rd(p, shape, dt=np.float32):
    return np.fromfile(p, dt).reshape(shape)


def err(got, want):
    return f"{np.abs(got - want).max():.2g} (largest reference value {np.abs(want).max():.3g})"


def main():
    d = pathlib.Path(sys.argv[1])
    ti = rd(REF / "trunk_input.f32", (690, D))
    task = rd(d / "task.f32", (1, NT, D))
    prim = rd(d / "primary_tokens.f32", (2, NPR, D))
    wrist = rd(d / "wrist_tokens.f32", (2, NWR, D))
    ref_prim = np.stack([ti[NT + t * PER:NT + t * PER + NPR] for t in range(2)])
    ref_wrist = np.stack([ti[NT + t * PER + NPR:NT + t * PER + NPR + NWR] for t in range(2)])
    print("task tokens (T5 on the NPU):", err(task[0], ti[:NT]))
    print("primary tokens (stems on the NPU):", err(prim, ref_prim))
    print("wrist tokens:", err(wrist, ref_wrist))
    readout_ref = rd(REF / "readout.f32", (2, D))[1:2]
    readout = rd(d / "readout.f32", (1, D))
    print("readout (trunk on the NPU, on the NPU's tokens):", err(readout, readout_ref))
    mask = rd(N / "in/mask.f32", (690, 690))
    trunk = ort.InferenceSession(str(N / "trunk.onnx"), providers=["CPUExecutionProvider"])
    r32 = trunk.run(None, {"task": task, "primary_tokens": prim, "wrist_tokens": wrist, "mask": mask})[0]
    print("readout, trunk in fp32 on the NPU's tokens:", err(r32, readout_ref))
    head = ort.InferenceSession(str(N / "head.onnx"), providers=["CPUExecutionProvider"])
    noise, z = rd(N / "in/noise.f32", (1, 28)), rd(N / "in/z.f32", (20, 28))
    a_ref = rd(REF / "actions_norm.f32", (1, 28))
    for name, r in (("JAX's readout", readout_ref), ("the NPU's readout", readout)):
        a = head.run(None, {"readout": r, "noise": noise, "z": z})[0]
        print(f"head (fp32, CPU) on {name}: actions within {err(a, a_ref)}")
    if (d / "actions.f32").exists():
        print("all-NPU actions (normalized):", err(rd(d / "actions.f32", (1, 28)), a_ref))


if __name__ == "__main__":
    main()
