"""mojo_adreno: one command from a Mojo GPU kernel to a verified run on the phone's Adreno 710.

  python3 mojo_adreno.py src/vecadd_gpu.mojo                  # all backends
  python3 mojo_adreno.py src/vecadd_gpu.mojo --backend turnip  # one backend
  python3 mojo_adreno.py src/warpsum_gpu.mojo --accel sm_80    # NVIDIA flavor (32-lane warps)

Pipeline (Mojo 1.2 has no Adreno/SPIR-V target, so the kernel is taken from Mojo's own LLVM IR):
  1. mojo build --emit llvm --target-accelerator gfx90a    -> per-kernel LLVM IR sidecar (unoptimized)
       gfx90a (AMD CDNA2, default): WARP_SIZE = 64, the Adreno 710's subgroup size; sm_80: WARP_SIZE = 32
  2a. mojo2vk.py  -> Vulkan compute SPIR-V (opt -O3, then LLVM 22's SPIR-V backend)
        turnip: SPIR-V 1.6, Vulkan 1.3, Mesa Turnip        stock: SPIR-V 1.4, Vulkan 1.1 + VK_KHR_spirv_1_4, int32 indices
  2b. mojo2cl.py  -> OpenCL C, compiled on the phone by Qualcomm's OpenCL driver
  3. adb push + run (runner/vk_run, runner/cl_run): C[i] = A[i] + B[i] checked element by element, or
     what the kernel's marker line asks for (runner/check.h):
       # mojo_adreno: check=warpsum                     sums over WARP_SIZE lanes
       # mojo_adreno: check=blocksum local=64           sums over each workgroup
       # mojo_adreno: check=matmul dim=1024 local=256   C = A @ B for dim x dim matrices
     outputs=K in the marker: each thread writes K outputs, so the launch is n / (local * K) workgroups
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
ACCEL = {"gfx90a": ("amdgcn", 64), "sm_80": ("nvptx", 32)}  # --target-accelerator -> (sidecar flavor, WARP_SIZE)
MOJO_SRC = pathlib.Path(os.environ.get("MOJO_SRC", HERE.parent / "modular"))  # modular/modular built with the SPIR-V target
os.environ.setdefault("ANDROID_SERIAL", os.environ.get("ADB_WIFI", "192.168.1.7:5555"))


def sh(*cmd, check=True, env=None):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, env=env)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r


def adb(*args):
    return sh("adb", *args, check=False)


def build_runners(build):
    sh(CC, "-O2", "-o", build / "vk_run", HERE / "runner/vk_run.c", "-ldl", "-lm")  # Vulkan headers: NDK sysroot
    sh(CC, "-O2", "-o", build / "cl_run", HERE / "runner/cl_run.c", "-ldl", "-lm")
    adb("shell", f"mkdir -p {DEV}")
    adb("push", build / "vk_run", build / "cl_run", f"{DEV}/")


def kernel_ir(src, build, accel):
    out = build / "kernel"
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob("*.ll"):
        f.unlink()
    sh(MOJO, "build", "--emit", "llvm", "-O3", "--target-accelerator", accel, "-o", out / "host.ll", src)
    side = sorted(out.glob(f"*.{ACCEL[accel][0]}.ll"))
    if len(side) != 1:
        sys.exit(f"expected one kernel sidecar, found {side}")
    return side[0]


def native_spv(src, build, local):
    """The kernel compiled by a source-built Mojo with the Vulkan SPIR-V target (no retargeter):
    `--target-accelerator adreno710 --emit asm` writes one .spv sidecar per kernel."""
    out = build / "native"
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob("*.spv"):
        f.unlink()
    bazel_bin = MOJO_SRC / "bazel-bin"
    # the MAX gate only checks that a MAX install exists; the compile never loads it
    env = dict(os.environ, MOJO_SPIRV_LOCAL_SIZE=str(local),
               MODULAR_MAX_PACKAGE_ROOT=str(HERE / ".venv-mojo/lib/python3.12/site-packages/modular"))
    sh(bazel_bin / "Mojo/tools/mojo/mojo", "build", "--emit", "asm", "-O3", "--target-accelerator", "adreno710",
       "-I", bazel_bin / "Mojo/stdlib/std", "-I", bazel_bin / "max/mojo/max", "-o", out / "host.s", src, env=env)
    side = sorted(out.glob("*.spv"))
    if len(side) != 1:
        sys.exit(f"expected one SPIR-V sidecar, found {side}")
    return side[0]


def run(backend, ir, build, n, local, check, opt, reps, int32, outputs=1, src=None):
    groups = (n + local * outputs - 1) // (local * outputs)
    if backend in ("turnip", "native") and adb("shell", f"test -e {TURNIP}/libvulkan.so").returncode:
        return None, f"SKIP: no Mesa Turnip in {TURNIP} (see README)"
    if backend == "cpu" and check:
        return None, "SKIP: the CPU path runs src/vecadd_cpu.mojo, not this kernel"
    env = (f"RUN_CHECK={check} " if check else "") + (f"RUN_REPS={reps} " if reps > 1 else "")
    if backend in ("turnip", "stock"):
        spv = build / f"vecadd_{backend}.spv"
        flags = ["--vulkan", "1.3"] + (["--i32"] if int32 else []) if backend == "turnip" else ["--vulkan", "1.1", "--i32", "--pad-shared"]
        sh(sys.executable, HERE / "mojo2vk.py", ir, "--local", str(local), "--opt", opt, "-o", spv, *flags)
        adb("push", spv, f"{DEV}/")
        env += f"LD_LIBRARY_PATH={TURNIP} VK_RUN_API=1.3 " if backend == "turnip" else ""
        r = adb("shell", f"cd {DEV} && {env}./vk_run {spv.name} main {n} {groups}")
    elif backend == "native":  # Mojo's own SPIR-V target, run on Turnip (Vulkan 1.3)
        spv = build / "native_kernel.spv"
        spv.write_bytes(native_spv(src, build, local).read_bytes())
        adb("push", spv, f"{DEV}/")
        r = adb("shell", f"cd {DEV} && {env}LD_LIBRARY_PATH={TURNIP} VK_RUN_API=1.3 ./vk_run {spv.name} main {n} {groups}")
    elif backend == "opencl":
        cl = build / "vecadd.cl"
        sh(sys.executable, HERE / "mojo2cl.py", ir, "--name", "vecadd", "--local", str(local), "-o", cl)
        adb("push", cl, f"{DEV}/")
        r = adb("shell", f"cd {DEV} && {env}./cl_run src {cl.name} vecadd {n} {local} {groups}")
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
                    choices=["turnip", "stock", "opencl", "cpu", "native"],
                    help="native: compiled by a source-built Mojo with the Vulkan SPIR-V target (MOJO_SRC), on Turnip")
    ap.add_argument("--n", type=int, default=1000003, help="elements (matmul kernels: dim * dim)")
    ap.add_argument("--dim", type=int, help="matrix size for check=matmul kernels (default: the marker's dim)")
    ap.add_argument("--local", type=int, help="workgroup size (default: the marker's local, else 64)")
    ap.add_argument("--reps", type=int, default=1, help="timed dispatches per run (best and median are printed)")
    ap.add_argument("--int32", action="store_true",
                    help="turnip: narrow 64-bit integers to 32 bits like the stock path (faster index math on Adreno, "
                         "which has no native int64; only for kernels without 64-bit data)")
    ap.add_argument("--accel", default="gfx90a", choices=list(ACCEL),
                    help="Mojo target whose kernel IR is retargeted (sets WARP_SIZE: gfx90a 64, sm_80 32)")
    ap.add_argument("--opt", default="O3", choices=["O3", "O2", "O1", "none"], help="LLVM opt before llc (Vulkan)")
    a = ap.parse_args()
    build = HERE / "build"
    build.mkdir(parents=True, exist_ok=True)
    m = re.search(r"#\s*mojo_adreno:(.*)", pathlib.Path(a.src).read_text())
    mark = dict(re.findall(r"(\w+)=(\w+)", m.group(1))) if m else {}
    a.local = a.local or int(mark.get("local", 64))
    check = {"warpsum": f"warpsum:{ACCEL[a.accel][1]}", "blocksum": f"blocksum:{a.local}"}.get(mark.get("check"), "")
    if mark.get("check") == "matmul":
        a.dim = a.dim or int(mark.get("dim", 256))
        a.n, check = a.dim * a.dim, f"matmul:{a.dim}"
    print(f"phone: {os.environ['ANDROID_SERIAL']}  accel: {a.accel} (WARP_SIZE {ACCEL[a.accel][1]})  check: {check or 'add'}")
    build_runners(build)
    ir = kernel_ir(a.src, build, a.accel) if set(a.backend) - {"cpu", "native"} else None
    if ir:
        print(f"Mojo kernel IR: {ir.name}")
    results = {}
    for b in a.backend:
        ok, out = run(b, ir, build, a.n, a.local, check, a.opt, a.reps, a.int32, int(mark.get("outputs", 1)), a.src)
        results[b] = ok
        print(f"\n== {b}\n{out}")
    print("\nsummary: " + "  ".join(f"{b}={'SKIP' if ok is None else 'PASS' if ok else 'FAIL'}" for b, ok in results.items()))
    sys.exit(0 if all(ok is not False for ok in results.values()) else 1)


if __name__ == "__main__":
    main()
