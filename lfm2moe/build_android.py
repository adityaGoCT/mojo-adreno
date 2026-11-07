"""lfm2moe for the phone (LFM2.5-8B-A1B): lfm2moe/lfm2moe.mojo compiled for Android ARM64 with its kernels as adreno840
SPIR-V, linked against MAX's Android runtime (android/build.py's helpers), into build/android/lfm2moe/ with the runtime
libraries and the driver plugin. The weight file is written on the phone by lfm2_convert (android/build.py lfm2).

  python3 lfm2moe/build_android.py
"""

import importlib.util
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("android_build", ROOT / "android/build.py")
ab = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ab)

out = ab.BUILD / "lfm2moe"
out.mkdir(parents=True, exist_ok=True)
ab.mojo_object(ROOT / "lfm2moe/lfm2moe.mojo", out / "lfm2moe.o",
               includes=[ROOT / "lfm2moe", ROOT / "lfm2moe/kernels", ROOT / "lfm2/kernels", ROOT / "gemma4/kernels"])
ab.link(out, "lfm2moe", [out / "lfm2moe.o"])
print("built", out)
