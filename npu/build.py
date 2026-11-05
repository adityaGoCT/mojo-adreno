"""Builds npu/ for the phone, in build/npu/phone:

  python3 npu/build.py tool      # npu_tool: npu_prefill.cpp on its own (compile, time, dump)
  python3 npu/build.py hybrid    # hybrid: npu/hybrid.mojo (NPU prefill, then llama/model.mojo's GPU decode)
  python3 npu/build.py decode    # npu_decode: npu_decode.cpp (prefill and decode both on the NPU)
  python3 npu/build.py pi0tool   # build/npu/pi0phone: pi0npu_tool (pi0_prefix.cpp on its own) and pi0_f16
  python3 npu/build.py pi0       # build/npu/pi0phone: pi0npu (pi0/pi0npu.mojo: π0's prefix on the NPU)

Both link ONNX Runtime for Android with the QNN execution provider (Maven Central's
com.microsoft.onnxruntime:onnxruntime-android-qnn) and stage Qualcomm's QNN runtime next to the executable
(com.qualcomm.qti:qnn-runtime): the HTP backend, its compiler (libQnnHtpPrepare.so) and the V81 stub and skel
of the Snapdragon 8 Elite Gen 5. The two AARs are unpacked under build/npu/dl (ORT_AAR_DIR, QNN_AAR_DIR).
hybrid also stages MAX's runtime and the Vulkan driver plugin, as android/build.py llama does.
"""

import importlib.util
import os
import pathlib
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = ROOT / "build/npu/phone"
ORT = pathlib.Path(os.environ.get("ORT_AAR_DIR", ROOT / "build/npu/dl/ort/x"))
QNN = pathlib.Path(os.environ.get("QNN_AAR_DIR", ROOT / "build/npu/dl/qnn/x"))
NDK = pathlib.Path(os.environ.get("ANDROID_NDK", "/opt/homebrew/share/android-ndk")).resolve()
CXX = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android33-clang++"
STRIP = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip"
QNN_LIBS = ["libQnnHtp.so", "libQnnHtpPrepare.so", "libQnnHtpV81Stub.so", "libQnnHtpV81Skel.so", "libQnnSystem.so"]


def sh(*cmd):
    print("$", " ".join(map(str, cmd))[:300], flush=True)
    if subprocess.run([str(c) for c in cmd]).returncode:
        sys.exit("failed")


def stage_npu(out=OUT):
    out.mkdir(parents=True, exist_ok=True)
    for lib in [ORT / "jni/arm64-v8a/libonnxruntime.so"] + [QNN / "jni/arm64-v8a" / n for n in QNN_LIBS]:
        dst = out / lib.name
        if not dst.exists() or dst.stat().st_mtime < lib.stat().st_mtime:
            shutil.copy2(lib, dst)


def compile_shim(extra=(), src="npu_prefill.cpp", out=OUT):
    return [CXX, "-O2", "-std=c++17", f"-I{ORT / 'headers'}", *extra, HERE / src,
            f"-L{out}", "-lonnxruntime", "-Wl,-rpath,$ORIGIN"]


def tool():
    stage_npu()
    sh(*compile_shim(["-DNPU_TOOL"]), "-static-libstdc++", "-o", OUT / "npu_tool")


def decode():
    """npu_decode: Llama entirely on the NPU, npu_decode.cpp with npu_prefill.cpp's prefill."""
    stage_npu()
    sh(CXX, "-O2", "-std=c++17", f"-I{ORT / 'headers'}", HERE / "npu_decode.cpp", HERE / "npu_prefill.cpp",
       f"-L{OUT}", "-lonnxruntime", "-Wl,-rpath,$ORIGIN", "-static-libstdc++", "-o", OUT / "npu_decode")


def hybrid():
    """npu/hybrid.mojo, compiled by android/build.py's Mojo for Android (kernels as adreno840 SPIR-V inside),
    linked with npu_prefill.cpp and staged with MAX's runtime and the driver plugin."""
    spec = importlib.util.spec_from_file_location("android_build", ROOT / "android/build.py")
    ab = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ab)
    stage_npu()
    ab.mojo_object(HERE / "hybrid.mojo", OUT / "hybrid.o",
                   includes=[ROOT / "llama", ROOT / "llama/kernels", ROOT / "llama/kernels/prefill"])
    sh(*compile_shim(), OUT / "hybrid.o", f"-L{ab.BUILD / 'runtime'}", "-lKGENCompilerRTShared", "-ldl",
       "-o", OUT / "hybrid")
    ab.stage(OUT)


PI0 = ROOT / "build/npu/pi0phone"


def pi0tool():
    """pi0npu_tool (pi0_prefix.cpp: compile a part, run the prefix on reference.py's embeddings, dump K/V) and
    pi0_f16 (the fp16 gemma.bin from the checkpoint, on the phone)."""
    stage_npu(PI0)
    sh(*compile_shim(["-DNPU_TOOL"], "pi0_prefix.cpp", PI0), "-static-libstdc++", "-o", PI0 / "pi0npu_tool")
    sh(CXX.with_name("aarch64-linux-android33-clang"), "-O2", HERE / "pi0_f16.c", "-o", PI0 / "pi0_f16")


def pi0():
    """pi0/pi0npu.mojo: π0 with its prefix on the NPU (pi0_prefix.cpp) and the rest on the Adreno (pi0/model.mojo),
    staged with MAX's runtime and the driver plugin."""
    spec = importlib.util.spec_from_file_location("android_build", ROOT / "android/build.py")
    ab = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ab)
    stage_npu(PI0)
    ab.mojo_object(ROOT / "pi0/pi0npu.mojo", PI0 / "pi0npu.o",
                   includes=[ROOT / "pi0", ROOT / "vla", ROOT / "vla/kernels"])
    sh(*compile_shim((), "pi0_prefix.cpp", PI0), PI0 / "pi0npu.o", f"-L{ab.BUILD / 'runtime'}",
       "-lKGENCompilerRTShared", "-ldl", "-o", PI0 / "pi0npu")
    ab.stage(PI0)


def main():
    steps = {"tool": tool, "hybrid": hybrid, "decode": decode, "pi0tool": pi0tool, "pi0": pi0}
    for name in sys.argv[1:] or ["tool"]:
        if name not in steps:
            sys.exit(f"unknown step {name}: one of {' '.join(steps)}")
        steps[name]()


if __name__ == "__main__":
    main()
