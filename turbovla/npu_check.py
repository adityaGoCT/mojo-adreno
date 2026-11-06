"""Where the all-NPU actions' error comes from: the head graph (ONNX Runtime on the Mac's CPU, fp32) run on PyTorch's
vision and text tokens or on the NPU's, so each NPU graph's share of the error shows on its own. The NPU's outputs
are graph_tool's (-o) from the laptop: the vision graph's vision.f32 and the text graph's text.f32.

  build/turbovla/venv/bin/python turbovla/npu_check.py <the NPU's vision.f32> <the NPU's text.f32> [NPU actions.f32]
"""

import pathlib
import sys

import numpy as np
import onnxruntime as ort

ROOT = pathlib.Path(__file__).resolve().parents[1]
N = ROOT / "build/turbovla/npu"
REF = ROOT / "build/turbovla/ref"


def rd(p, shape, dt=np.float32):
    return np.fromfile(p, dt).reshape(shape)


def main():
    head = ort.InferenceSession(str(N / "head.onnx"), providers=["CPUExecutionProvider"])
    text = ort.InferenceSession(str(N / "text.onnx"), providers=["CPUExecutionProvider"])
    ids, pos = rd(N / "in/ids.i32", (1, 21), np.int32), rd(N / "in/pos.i32", (1, 21), np.int32)
    mask, keep = rd(N / "in/mask.f32", (1, 21, 21)), rd(N / "in/keep.f32", (1, 21, 1))
    key_mask, state = rd(N / "in/key_mask.f32", (1, 1, 21)), rd(N / "in/state.f32", (1, 8))
    v_ref = rd(REF / "vision_tokens.f32", (1, 512, 256))
    t_ref = text.run(None, {"ids": ids, "pos": pos, "mask": mask, "keep": keep})[0]
    a_ref = rd(REF / "actions.f32", (1, 12, 7))
    v_npu, t_npu = rd(sys.argv[1], (1, 512, 256)), rd(sys.argv[2], (1, 21, 256))
    dv, dt = np.abs(v_npu - v_ref), np.abs(t_npu - t_ref)
    print(f"vision tokens, NPU: max abs error {dv.max():.3g} (largest reference value {np.abs(v_ref).max():.3g}), "
          f"relative L2 {np.linalg.norm(v_npu - v_ref) / np.linalg.norm(v_ref):.3g}")
    print(f"text tokens, NPU: max abs error {dt.max():.3g} (largest reference value {np.abs(t_ref).max():.3g}); "
          f"by row: {' '.join(f'{x:.2g}' for x in dt[0].max(1)[:int(keep.sum())])}")
    for name, v, t in (("PyTorch's vision and text", v_ref, t_ref), ("the NPU's vision", v_npu, t_ref),
                       ("the NPU's text", v_ref, t_npu), ("the NPU's vision and text", v_npu, t_npu)):
        a = head.run(None, {"vision": v, "text": t, "key_mask": key_mask, "self_mask": mask, "state": state})[0]
        print(f"head (fp32, CPU) on {name:26s}: actions within {np.abs(a - a_ref).max():.2g}")
    if len(sys.argv) > 3:
        a = rd(sys.argv[3], (1, 12, 7))
        print(f"all-NPU actions: within {np.abs(a - a_ref).max():.2g} (largest reference value {np.abs(a_ref).max():.2g})")


if __name__ == "__main__":
    main()
