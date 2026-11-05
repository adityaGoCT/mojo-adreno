"""Builds npu/ for the phone, in build/npu/phone:

  python3 npu/build.py tool      # npu_tool: npu_prefill.cpp on its own (compile, time, dump)
  python3 npu/build.py hybrid    # hybrid: npu/hybrid.mojo (NPU prefill, then llama/model.mojo's GPU decode)
  python3 npu/build.py decode    # npu_decode: npu_decode.cpp (prefill and decode both on the NPU)
  python3 npu/build.py hybrid_qwen3  # hybrid_qwen3: ternary Qwen3-8B, NPU prefill and GPU decode
  python3 npu/build.py convert   # pc_convert, qwen3_lpbq: the quantized graphs' weights, written on the phone

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


def stage_npu():
    OUT.mkdir(parents=True, exist_ok=True)
    for lib in [ORT / "jni/arm64-v8a/libonnxruntime.so"] + [QNN / "jni/arm64-v8a" / n for n in QNN_LIBS]:
        dst = OUT / lib.name
        if not dst.exists() or dst.stat().st_mtime < lib.stat().st_mtime:
            shutil.copy2(lib, dst)


def compile_shim(extra=()):
    return [CXX, "-O2", "-std=c++17", f"-I{ORT / 'headers'}", *extra, HERE / "npu_prefill.cpp",
            f"-L{OUT}", "-lonnxruntime", "-Wl,-rpath,$ORIGIN"]


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


def hybrid_qwen3():
    """npu/hybrid_qwen3.mojo (NPU prefill of ternary Qwen3-8B, then qwen3/model.mojo's GPU decode), linked with
    npu_prefill.cpp and staged like hybrid."""
    spec = importlib.util.spec_from_file_location("android_build", ROOT / "android/build.py")
    ab = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ab)
    stage_npu()
    ab.mojo_object(HERE / "hybrid_qwen3.mojo", OUT / "hybrid_qwen3.o",
                   includes=[ROOT / "bonsai/kernels", ROOT / "qwen3/kernels", ROOT / "qwen3"])
    sh(*compile_shim(), OUT / "hybrid_qwen3.o", f"-L{ab.BUILD / 'runtime'}", "-lKGENCompilerRTShared", "-ldl",
       "-o", OUT / "hybrid_qwen3")
    ab.stage(OUT)


def convert():
    """The quantized graphs' weights.bin, written on the phone instead of pushed: pc_convert (npu/export.py's
    per-channel forms, from the fp16 weights.bin and export.py's recipe.txt) and qwen3_lpbq (npu/export_qwen3.py's,
    from the checkpoint). Their float32 operations are the Mac's, so their output is byte for byte the same."""
    OUT.mkdir(parents=True, exist_ok=True)
    for name in ("pc_convert", "qwen3_lpbq"):
        sh(CXX, "-std=c++17", "-O2", "-ffp-contract=off", "-static-libstdc++", "-o", OUT / name, HERE / f"{name}.cpp")


def main():
    steps = {"tool": tool, "hybrid": hybrid, "decode": decode, "hybrid_qwen3": hybrid_qwen3, "convert": convert}
    for name in sys.argv[1:] or ["tool"]:
        if name not in steps:
            sys.exit(f"unknown step {name}: one of {' '.join(steps)}")
        steps[name]()


if __name__ == "__main__":
    main()
