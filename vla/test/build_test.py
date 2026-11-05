"""Builds vla/test/test_gemm.mojo and test_attn.mojo (or those named) for the phone with android/build.py's functions:
build/android/vlatest/."""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "android"))
import build  # noqa: E402

out = build.BUILD / "vlatest"
out.mkdir(parents=True, exist_ok=True)
for name in sys.argv[1:] or ["test_gemm", "test_attn"]:
    build.mojo_object(ROOT / f"vla/test/{name}.mojo", out / f"{name}.o", includes=[ROOT / "vla/kernels"])
    build.link(out, name, [out / f"{name}.o"])
