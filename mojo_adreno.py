"""mojo_adreno: one command from a Mojo GPU kernel to a verified run on the phone's Adreno 710.

  python3 mojo_adreno.py src/vecadd_gpu.mojo                  # all backends
  python3 mojo_adreno.py src/vecadd_gpu.mojo --backend turnip  # one backend

Pipeline (Mojo 1.2 has no Adreno/SPIR-V target, so the kernel is taken from Mojo's own LLVM IR):
  1. mojo build --emit llvm --target-accelerator sm_80     -> per-kernel LLVM IR sidecar (NVPTX flavor)
  2a. mojo2vk.py  -> Vulkan compute SPIR-V (LLVM 22 SPIR-V backend)
        turnip: SPIR-V 1.6, Vulkan 1.3, Mesa Turnip        stock: SPIR-V 1.4, Vulkan 1.1 + VK_KHR_spirv_1_4, int32 indices
  2b. mojo2cl.py  -> OpenCL C, compiled on the phone by Qualcomm's OpenCL driver
  3. adb push + run (runner/vk_run, runner/cl_run): C[i] = A[i] + B[i] checked element by element
Also: --backend cpu builds src/vecadd_cpu.mojo for aarch64 Android and runs it on the phone's CPU.
The turnip backend needs Mesa Turnip in /data/local/tmp/turnip (see README); without it, it is skipped.
"""

import argparse
import os
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOJO = pathlib.Path(os.environ.get("MOJO", HERE / ".venv-mojo/bin/mojo"))
NDK = pathlib.Path(os.environ.get("ANDROID_NDK", "/opt/homebrew/share/android-ndk"))
CC = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang"
DEV = "/data/local/tmp/mojo"
TURNIP = "/data/local/tmp/turnip"
os.environ.setdefault("ANDROID_SERIAL", os.environ.get("ADB_WIFI", "192.168.1.7:5555"))


def sh(*cmd, check=True):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r


def adb(*args):
    return sh("adb", *args, check=False)


def build_runners(build):
    sh(CC, "-O2", "-o", build / "vk_run", HERE / "runner/vk_run.c", "-ldl", "-lm")  # Vulkan headers: NDK sysroot
    sh(CC, "-O2", "-o", build / "cl_run", HERE / "runner/cl_run.c", "-ldl")
    adb("shell", f"mkdir -p {DEV}")
    adb("push", build / "vk_run", build / "cl_run", f"{DEV}/")


def kernel_ir(src, build):
    out = build / "kernel"
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob("*.ll"):
        f.unlink()
    sh(MOJO, "build", "--emit", "llvm", "-O3", "--target-accelerator", "sm_80", "-o", out / "host.ll", src)
    side = sorted(out.glob("*.nvptx.ll"))
    if len(side) != 1:
        sys.exit(f"expected one kernel sidecar, found {side}")
    return side[0]


def run(backend, ir, build, n, local):
    groups = (n + local - 1) // local
    if backend == "turnip" and adb("shell", f"test -e {TURNIP}/libvulkan.so").returncode:
        return None, f"SKIP: no Mesa Turnip in {TURNIP} (see README)"
    if backend in ("turnip", "stock"):
        spv = build / f"vecadd_{backend}.spv"
        flags = ["--vulkan", "1.3"] if backend == "turnip" else ["--vulkan", "1.1", "--i32"]
        sh(sys.executable, HERE / "mojo2vk.py", ir, "--local", str(local), "-o", spv, *flags)
        adb("push", spv, f"{DEV}/")
        env = f"LD_LIBRARY_PATH={TURNIP} VK_RUN_API=1.3 " if backend == "turnip" else ""
        r = adb("shell", f"cd {DEV} && {env}./vk_run {spv.name} main {n} {groups}")
    elif backend == "opencl":
        cl = build / "vecadd.cl"
        sh(sys.executable, HERE / "mojo2cl.py", ir, "--name", "vecadd", "-o", cl)
        adb("push", cl, f"{DEV}/")
        r = adb("shell", f"cd {DEV} && ./cl_run src {cl.name} vecadd {n} {local}")
    else:  # cpu
        obj = build / "vecadd_cpu.o"
        sh(MOJO, "build", "--emit", "object", "--target-triple", "aarch64-unknown-linux-android34",
           "--target-cpu", "cortex-a78", "-o", obj, HERE / "src/vecadd_cpu.mojo")
        sh(CC, "-O2", "-o", build / "mojo_cpu_vecadd", HERE / "runner/cpu_main.c", obj)
        adb("push", build / "mojo_cpu_vecadd", f"{DEV}/")
        r = adb("shell", f"{DEV}/mojo_cpu_vecadd {n}")
    out = r.stdout.strip()
    ok = out.endswith("PASS")
    return ok, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src", nargs="?", default=str(HERE / "src/vecadd_gpu.mojo"))
    ap.add_argument("--backend", nargs="+", default=["turnip", "stock", "opencl", "cpu"],
                    choices=["turnip", "stock", "opencl", "cpu"])
    ap.add_argument("--n", type=int, default=1000003)
    ap.add_argument("--local", type=int, default=64)
    a = ap.parse_args()
    build = HERE / "build"
    build.mkdir(parents=True, exist_ok=True)
    print(f"phone: {os.environ['ANDROID_SERIAL']}")
    build_runners(build)
    ir = kernel_ir(a.src, build) if set(a.backend) - {"cpu"} else None
    if ir:
        print(f"Mojo kernel IR: {ir.name}")
    results = {}
    for b in a.backend:
        ok, out = run(b, ir, build, a.n, a.local)
        results[b] = ok
        print(f"\n== {b}\n{out}")
    print("\nsummary: " + "  ".join(f"{b}={'SKIP' if ok is None else 'PASS' if ok else 'FAIL'}" for b, ok in results.items()))
    sys.exit(0 if all(ok is not False for ok in results.values()) else 1)


if __name__ == "__main__":
    main()
