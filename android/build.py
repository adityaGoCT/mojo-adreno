"""Mojo host code on the phone: programs that use MAX's DeviceContext, compiled for Android ARM64 with
their kernels as adreno840 SPIR-V inside, linked against MAX's runtime cross-built for Android, and
run on the Adreno through driver/libM_driver_vulkan.so.

  python3 android/build.py runtime     # MAX's runtime for Android (Bazel, --config=android-arm64)
  python3 android/build.py vecadd      # build/android/vecadd/: android/vecadd.mojo
  python3 android/build.py bonsai      # build/android/bonsai/: the Android port's Bonsai model.mojo,
                                       # and bonsai_convert for its weights

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
    """std, and MAX's package with the HAL DeviceContext, for the host compiler: max/mojo/max with
    device_context_hal/_dcc_overlay.mojo as max/gpu/host/_overlay.mojo (as
    //max/mojo/max/_driver/max_license:max_srcs_hal stages it), precompiled by the host compiler
    of bazel-bin, without Bazel: the Android build's changes would make Bazel rebuild it."""
    out = BUILD / "packages"
    if (out / "max.mojoc").exists():
        return out
    out.mkdir(parents=True, exist_ok=True)
    shutil.copy2(MOJO_SRC / "bazel-bin/Mojo/stdlib/std/std.mojoc", out / "std.mojoc")
    stage = BUILD / "hal_max/max"
    shutil.rmtree(stage.parent, ignore_errors=True)
    src = MOJO_SRC / "max/mojo/max"
    for f in src.rglob("*.mojo"):
        (stage / f.relative_to(src)).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, stage / f.relative_to(src))
    shutil.copy2(src / "_driver/max_license/device_context_hal/_dcc_overlay.mojo", stage / "gpu/host/_overlay.mojo")
    (stage / "gpu/host/_legacy/device_graph.mojo").unlink()
    sh(MOJO_SRC / "bazel-bin/Mojo/tools/mojo/mojo", "precompile", "-I", out, stage, "-o", out / "max.mojoc",
       env=dict(os.environ, MODULAR_MAX_PACKAGE_ROOT=str(ROOT / ".venv-mojo/lib/python3.12/site-packages/modular")))
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
    steps = {"runtime": runtime, "vecadd": vecadd, "bonsai": bonsai}
    wanted = sys.argv[1:] or ["runtime", "vecadd"]
    for name in wanted:
        if name not in steps:
            sys.exit(f"unknown step {name}: one of {' '.join(steps)}")
    for name in wanted:
        steps[name]()


if __name__ == "__main__":
    main()
