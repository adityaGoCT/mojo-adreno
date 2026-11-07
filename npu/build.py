"""Builds npu/ for the phone, in build/npu/phone:

  python3 npu/build.py tool      # npu_tool: npu_prefill.cpp on its own (compile, time, dump)
  python3 npu/build.py hybrid    # hybrid: npu/hybrid.mojo (NPU prefill, then llama/model.mojo's GPU decode)
  python3 npu/build.py decode    # npu_decode: npu_decode.cpp (prefill and decode both on the NPU)
  python3 npu/build.py pi0tool   # build/npu/pi0phone: pi0npu_tool (pi0_prefix.cpp on its own) and pi0_f16
  python3 npu/build.py pi0       # build/npu/pi0phone: pi0npu (pi0/pi0npu.mojo: π0's prefix on the NPU)
  python3 npu/build.py hybrid_qwen3  # hybrid_qwen3: ternary Qwen3-8B, NPU prefill and GPU decode
  python3 npu/build.py convert   # pc_convert, qwen3_lpbq: the quantized graphs' weights, written on the phone
  python3 npu/build.py graphtool # graph_tool: graph.cpp (any static graph: compile, run, chain) for the phone
  python3 npu/build.py lfm2npu   # lfm2_npu: LFM2.5-2.6B all on the NPU (lfm2/npu_lfm2.cpp on graph.cpp)
  python3 npu/build.py lfm2hybrid  # lfm2_hybrid: lfm2/hybrid.mojo (NPU prefill, lfm2/model.mojo's GPU decode)

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


def graphtool():
    """graph_tool (graph.cpp with -DNPU_TOOL): compile, run and chain static ONNX graphs on the phone's HTP."""
    stage_npu()
    sh(*compile_shim(["-DNPU_TOOL"], "graph.cpp"), "-static-libstdc++", "-o", OUT / "graph_tool")


def lfm2npu():
    """lfm2_npu: lfm2/npu_lfm2.cpp's prefill and decode on the HTP (export_npu.py's graphs), on graph.cpp."""
    stage_npu()
    sh(CXX, "-O2", "-std=c++17", f"-I{ORT / 'headers'}", "-DLFM2_NPU_MAIN", ROOT / "lfm2/npu_lfm2.cpp",
       HERE / "graph.cpp", f"-L{OUT}", "-lonnxruntime", "-Wl,-rpath,$ORIGIN", "-static-libstdc++",
       "-o", OUT / "lfm2_npu")


def lfm2hybrid():
    """lfm2/hybrid.mojo (NPU prefill of LFM2.5-2.6B, then lfm2/model.mojo's GPU decode), linked with npu_lfm2.cpp and
    graph.cpp, staged with QNN, MAX's runtime and the driver plugin, as hybrid is."""
    spec = importlib.util.spec_from_file_location("android_build", ROOT / "android/build.py")
    ab = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ab)
    stage_npu()
    ab.mojo_object(ROOT / "lfm2/hybrid.mojo", OUT / "lfm2_hybrid.o", includes=[ROOT / "lfm2", ROOT / "lfm2/kernels"])
    sh(CXX, "-O2", "-std=c++17", f"-I{ORT / 'headers'}", ROOT / "lfm2/npu_lfm2.cpp", HERE / "graph.cpp",
       OUT / "lfm2_hybrid.o", f"-L{OUT}", "-lonnxruntime", f"-L{ab.BUILD / 'runtime'}", "-lKGENCompilerRTShared",
       "-ldl", "-Wl,-rpath,$ORIGIN", "-o", OUT / "lfm2_hybrid")
    ab.stage(OUT)


def convert():
    """The quantized graphs' weights.bin, written on the phone instead of pushed: pc_convert (npu/export.py's
    per-channel forms, from the fp16 weights.bin and export.py's recipe.txt) and qwen3_lpbq (npu/export_qwen3.py's,
    from the checkpoint). Their float32 operations are the Mac's, so their output is byte for byte the same."""
    OUT.mkdir(parents=True, exist_ok=True)
    for name in ("pc_convert", "qwen3_lpbq"):
        sh(CXX, "-std=c++17", "-O2", "-ffp-contract=off", "-static-libstdc++", "-o", OUT / name, HERE / f"{name}.cpp")


def main():
    steps = {"tool": tool, "hybrid": hybrid, "decode": decode, "pi0tool": pi0tool, "pi0": pi0,
             "hybrid_qwen3": hybrid_qwen3, "convert": convert, "graphtool": graphtool, "lfm2npu": lfm2npu, "lfm2hybrid": lfm2hybrid}
    for name in sys.argv[1:] or ["tool"]:
        if name not in steps:
            sys.exit(f"unknown step {name}: one of {' '.join(steps)}")
        steps[name]()


if __name__ == "__main__":
    main()
