"""Mojo host code on the phone: programs that use MAX's DeviceContext, compiled for Android ARM64 with
their kernels as adreno840 SPIR-V inside, linked against MAX's runtime cross-built for Android, and
run on the Adreno through driver/libM_driver_vulkan.so.

  python3 android/build.py runtime     # MAX's runtime for Android (Bazel, --config=android-arm64)
  python3 android/build.py vecadd      # build/android/vecadd/: android/vecadd.mojo
  python3 android/build.py llama       # build/android/llama/: llama/llama.mojo (Llama 3.2 1B)
  python3 android/build.py qwen3       # build/android/qwen3/: qwen3/qwen3.mojo (ternary Qwen3-8B), qwen3_convert
  python3 android/build.py bonsai      # build/android/bonsai/: the Android port's Bonsai model.mojo,
                                       # and bonsai_convert for its weights
  python3 android/build.py vla         # build/android/smolvla/ and pi0/: the robot models (SmolVLA, pi0) on vla/
  python3 android/build.py gemma4      # build/android/gemma4/: gemma4/gemma4.mojo (Gemma 4 E2B / E4B), gemma4_convert
  python3 android/build.py lfm2        # build/android/lfm2/: lfm2/lfm2.mojo (LFM2.5-2.6B), lfm2_convert

Each program's directory holds everything it needs on the phone: the executable, MAX's runtime
libraries, NDK libc++ and the driver plugin. Its DeviceContext loads the plugin named in
MODULAR_DRIVER_PLUGINS ("vulkan@<path>").

The runtime is //Mojo:CompilerRT of the modular fork (MOJO_SRC, branch adreno-spirv-target), built
with Bazel's android-arm64 configuration and the NDK (ANDROID_NDK). DeviceContext is MAX's HAL one
(//max/mojo/max/_driver/max_license:max): Mojo code that calls the driver plugin directly.

bonsai builds mav3ri3k/modular's max/examples/android-llm (BONSAI_PORT, at 03de9211) for our
backend: model.mojo, kernels.mojo, runner.cpp and engine.cpp unchanged, and model_runtime.mojo and
engine.cpp with "opencl" changed to "vulkan".
"""

import os
import pathlib
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
BUILD = ROOT / "build/android"
MOJO_SRC = pathlib.Path(os.environ.get("MOJO_SRC", ROOT.parent / "modular")).resolve()
PORT = pathlib.Path(os.environ.get("BONSAI_PORT", ROOT.parent / "modular-android/max/examples/android-llm")).resolve()
NDK = pathlib.Path(os.environ.get("ANDROID_NDK", "/opt/homebrew/share/android-ndk")).resolve()
NDK_BIN = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin"
TRIPLE = "aarch64-unknown-linux-android33"  # four parts: Mojo's stdlib reads the OS (linux) from the third
BAZEL = [str(MOJO_SRC / "bazelw"), "build", "--config=disable-lint"]
ANDROID = ["--compilation_mode=opt", "--config=android-arm64", f"--repo_env=ANDROID_NDK_HOME={NDK}",
           "--symlink_prefix=bazel-android-"]
RUNTIME = {  # staged name: Bazel output, under bazel-android-bin
    "libKGENCompilerRTShared.so": "Mojo/libKGENCompilerRTShared.so",
    "libAsyncRTRuntimeGlobals.so": "AsyncRT/libAsyncRTRuntimeGlobals.so",
    "libMSupportGlobals.so": "Support/libMSupportGlobals.so",
}


def sh(*cmd, env=None, cwd=None):
    print("$", " ".join(str(c) for c in cmd)[:300], flush=True)
    r = subprocess.run([str(c) for c in cmd], env=env, cwd=cwd)
    if r.returncode:
        sys.exit(f"failed: exit {r.returncode}")


def runtime():
    """MAX's runtime for Android, and the driver plugin, in build/android/runtime."""
    sh(*BAZEL, *ANDROID, "//Mojo:CompilerRT", env=dict(os.environ, BAZELISK_SKIP_WRAPPER="true"), cwd=MOJO_SRC)
    out = BUILD / "runtime"
    out.mkdir(parents=True, exist_ok=True)
    for name, path in RUNTIME.items():
        (out / name).unlink(missing_ok=True)
        shutil.copy2(MOJO_SRC / "bazel-android-bin" / path, out / name)
    libcxx = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"
    shutil.copy2(libcxx, out / "libc++_shared.so")
    sh(ROOT / "driver/build.sh")
    shutil.copy2(ROOT / "build/driver/libM_driver_vulkan.so", out / "libM_driver_vulkan.so")


def packages():
    """std, and MAX's package with the HAL DeviceContext, precompiled from the fork's sources by the host
    compiler of bazel-bin (not by Bazel: the Android build's change to Support/Log.h would make Bazel
    rebuild that compiler). The HAL package is max/mojo/max with device_context_hal/_dcc_overlay.mojo as
    max/gpu/host/_overlay.mojo, as //max/mojo/max/_driver/max_license:max_srcs_hal stages it. Both are
    rebuilt when a source is newer."""
    out = BUILD / "packages"
    out.mkdir(parents=True, exist_ok=True)
    std_src, max_src = MOJO_SRC / "Mojo/stdlib/std", MOJO_SRC / "max/mojo/max"
    newest = max(f.stat().st_mtime for d in (std_src, max_src) for f in d.rglob("*.mojo"))
    if (out / "max.mojoc").exists() and (out / "max.mojoc").stat().st_mtime > newest:
        return out
    mojo = MOJO_SRC / "bazel-bin/Mojo/tools/mojo/mojo"
    env = dict(os.environ, MODULAR_MAX_PACKAGE_ROOT=str(ROOT / ".venv-mojo/lib/python3.12/site-packages/modular"))
    for pkg in ("std.mojoc", "max.mojoc"):
        (out / pkg).unlink(missing_ok=True)
    sh(mojo, "precompile", std_src, "-o", out / "std.mojoc", env=env)
    stage = BUILD / "hal_max/max"
    shutil.rmtree(stage.parent, ignore_errors=True)
    for f in max_src.rglob("*.mojo"):
        (stage / f.relative_to(max_src)).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, stage / f.relative_to(max_src))
    shutil.copy2(max_src / "_driver/max_license/device_context_hal/_dcc_overlay.mojo", stage / "gpu/host/_overlay.mojo")
    (stage / "gpu/host/_legacy/device_graph.mojo").unlink()
    sh(mojo, "precompile", "-I", out, stage, "-o", out / "max.mojoc", env=env)
    return out


def mojo_object(src, out, includes=()):
    """`src` compiled for Android, its kernels for the adreno840 SPIR-V target inside."""
    pkgs = packages()
    env = dict(os.environ, MODULAR_MAX_PACKAGE_ROOT=str(ROOT / ".venv-mojo/lib/python3.12/site-packages/modular"))
    env.pop("MOJO_SPIRV_LOCAL_SIZE", None)  # each launch's block size is the workgroup size
    args = [MOJO_SRC / "bazel-bin/Mojo/tools/mojo/mojo", "build", "--emit", "object", "-O3",
            "--target-triple", TRIPLE, "--target-cpu", "generic", "--target-accelerator", "adreno840",
            "-I", pkgs]
    for path in includes:
        args += ["-I", path]
    sh(*args, "-o", out, src, env=env)


def stage(out):
    """The runtime and the plugin next to the executable (it finds them through rpath $ORIGIN),
    without debug info: a fifth of the size to push."""
    for lib in (BUILD / "runtime").iterdir():
        (out / lib.name).unlink(missing_ok=True)
        sh(NDK_BIN / "llvm-strip", "--strip-debug", "-o", out / lib.name, lib)


def link(out, exe, sources, defines=(), includes=()):
    cxx = NDK_BIN / "aarch64-linux-android33-clang++"
    args = [cxx, "-O2", "-std=c++17", *[f"-D{d}" for d in defines], *[f"-I{i}" for i in includes], *sources,
            f"-L{BUILD / 'runtime'}", "-lKGENCompilerRTShared", "-Wl,-rpath,$ORIGIN", "-ldl", "-o", out / exe]
    sh(*args)
    stage(out)


def vecadd():
    out = BUILD / "vecadd"
    out.mkdir(parents=True, exist_ok=True)
    mojo_object(HERE / "vecadd.mojo", out / "vecadd.o")
    link(out, "vecadd", [out / "vecadd.o"])


def llama():
    """llama/llama.mojo: llama/model.mojo's forward pass, the kernels of llama/kernels and kernels/prefill."""
    out = BUILD / "llama"
    out.mkdir(parents=True, exist_ok=True)
    mojo_object(ROOT / "llama/llama.mojo", out / "llama.o",
                includes=[ROOT / "llama", ROOT / "llama/kernels", ROOT / "llama/kernels/prefill"])
    link(out, "llama", [out / "llama.o"])


def qwen3():
    """qwen3/qwen3.mojo: qwen3/model.mojo's forward pass, the Android port's packed kernels and qwen3k; and
    qwen3_convert (qwen3/convert.cpp), which writes the weights on the phone from the checkpoint."""
    out = BUILD / "qwen3"
    out.mkdir(parents=True, exist_ok=True)
    mojo_object(ROOT / "qwen3/qwen3.mojo", out / "qwen3.o",
                includes=[ROOT / "bonsai/kernels", ROOT / "qwen3/kernels", ROOT / "qwen3"])
    link(out, "qwen3", [out / "qwen3.o"])
    sh(NDK_BIN / "aarch64-linux-android33-clang++", "-std=c++17", "-O2", "-static-libstdc++", "-o",
       out / "qwen3_convert", ROOT / "qwen3/convert.cpp")


def vla():
    """The vision-language-action models: smolvla/smolvla.mojo (SmolVLA) and pi0/pi0.mojo (pi0), each its
    model.mojo's forward pass on the kernels of vla/kernels, reading the checkpoint's model.safetensors itself
    (vla/safetensors.mojo). VLA_ONLY=smolvla or pi0 builds one."""
    for name in ("smolvla", "pi0"):
        if os.environ.get("VLA_ONLY", name) != name:
            continue
        out = BUILD / name
        out.mkdir(parents=True, exist_ok=True)
        mojo_object(ROOT / name / f"{name}.mojo", out / f"{name}.o",
                    includes=[ROOT / name, ROOT / "vla", ROOT / "vla/kernels"])
        link(out, name, [out / f"{name}.o"])


def gemma4():
    """gemma4/gemma4.mojo: gemma4/model.mojo's forward pass on gemma4/kernels (one program for E2B and E4B); and
    gemma4_convert (gemma4/convert.c), which writes gemma4.bin on the phone from the downloaded checkpoint."""
    out = BUILD / "gemma4"
    out.mkdir(parents=True, exist_ok=True)
    mojo_object(ROOT / "gemma4/gemma4.mojo", out / "gemma4.o",
                includes=[ROOT / "gemma4", ROOT / "gemma4/kernels", ROOT / "llama/kernels/prefill"])
    link(out, "gemma4", [out / "gemma4.o"])
    sh(NDK_BIN / "aarch64-linux-android33-clang", "-O2", "-ffp-contract=off", "-o", out / "gemma4_convert",
       ROOT / "gemma4/convert.c")


def lfm2():
    """lfm2/lfm2.mojo: lfm2/model.mojo's forward pass on lfm2/kernels (the QAD GGUF's int4 or the fp16 storage); and
    lfm2_convert (lfm2/convert.c), which writes the weight files on the phone from the downloaded GGUF."""
    out = BUILD / "lfm2"
    out.mkdir(parents=True, exist_ok=True)
    mojo_object(ROOT / "lfm2/lfm2.mojo", out / "lfm2.o", includes=[ROOT / "lfm2", ROOT / "lfm2/kernels"])
    link(out, "lfm2", [out / "lfm2.o"])
    sh(NDK_BIN / "aarch64-linux-android33-clang", "-O2", "-ffp-contract=off", "-o", out / "lfm2_convert",
       ROOT / "lfm2/convert.c")


def bonsai():
    out = BUILD / "bonsai"
    src = out / "src"
    src.mkdir(parents=True, exist_ok=True)
    for name in ["model.mojo", "kernels.mojo"]:
        shutil.copy2(PORT / "bonsai" / name, src / name)
    runtime_src = (PORT / "runtime/model_runtime.mojo").read_text()
    assert runtime_src.count('DeviceContext(api="opencl")') == 1
    (src / "model_runtime.mojo").write_text(runtime_src.replace('api="opencl"', 'api="vulkan"'))
    engine = (PORT / "engine.cpp").read_text()
    assert engine.count('"OpenCL@"') == 1
    (src / "engine.cpp").write_text(engine.replace('"OpenCL@"', '"vulkan@"'))
    mojo_object(src / "model_runtime.mojo", out / "model.o", includes=[src])
    port_root = PORT.parents[2]
    link(out, "runner", [PORT / "runner.cpp", src / "engine.cpp", out / "model.o"], defines=["BONSAI_MODEL"],
         includes=[PORT, port_root / "SDK/include", port_root / "Target/include"])
    # The weights, converted on the phone from the checkpoint it downloads (bonsai/convert.cpp).
    sh(NDK_BIN / "aarch64-linux-android33-clang++", "-std=c++17", "-O2", "-static-libstdc++", "-o",
       out / "bonsai_convert", ROOT / "bonsai/convert.cpp")


def main():
    steps = {"runtime": runtime, "vecadd": vecadd, "llama": llama, "qwen3": qwen3, "bonsai": bonsai,
             "vla": vla, "gemma4": gemma4, "lfm2": lfm2}
    wanted = sys.argv[1:] or ["runtime", "vecadd"]
    for name in wanted:
        if name not in steps:
            sys.exit(f"unknown step {name}: one of {' '.join(steps)}")
    for name in wanted:
        steps[name]()


if __name__ == "__main__":
    main()
