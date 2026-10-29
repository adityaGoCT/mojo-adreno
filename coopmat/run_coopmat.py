"""Run the cooperative-matrix matmuls of coopmat/matmul_coopmat_gpu.mojo on a phone with an Adreno 8xx
and check them against NumPy.

  MOJO_SRC=~/runix/modular COOPMAT_N=64 coopmat/check.sh     # compile for adreno840
  ANDROID_SERIAL=localhost:33687 COOPMAT_N=64 python3 coopmat/run_coopmat.py 256 1024

With `--max DIR`, runs MAX's own cooperative-matrix matmul instead, as compiled for three graphs of
MAX's compile test (the SPIR-V it saves with MOJO_SPIRV_SAVE_DIR=DIR):
  MOJO_SPIRV_SAVE_DIR=DIR ./bazelw run //max/examples/vulkan_coverage:coverage -- --arch=adreno840

Lays out each kernel's arguments as its launch description says (max_kernels/test_max_kernels.py)
and runs it with runner/vk_launch.c at a required subgroup size of 64. Every adb command is plain:
Samsung's Remote Test Lab bridge drops the connection on a shell command with `&&` or `&`.
"""

import math
import os
import pathlib
import struct
import subprocess
import sys

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "max_kernels"))
from test_max_kernels import CC, description, leaves, SCALAR_FORMATS  # noqa: E402

BUILD = ROOT / "build/coopmat"
DEV = "/data/local/tmp/coopmat"
M, N = 64, int(os.environ.get("COOPMAT_N", 64))  # the tile of C each subgroup computes
WM, WN = int(os.environ.get("COOPMAT_WM", 2)), int(os.environ.get("COOPMAT_WN", 2))  # subgroups, staged
KERNELS = {  # name: (dtype, B transposed, block rows, block columns, threads)
    "matmul_coopmat_f32": (np.float32, False, M, N, 64),
    "matmul_coopmat_f16": (np.float16, False, M, N, 64),
    "matmul_coopmat_bt_f16": (np.float16, True, M, N, 64),
    "matmul_coopmat_smem_f32": (np.float32, False, 64 * WM, 64 * WN, 64 * WM * WN),
    "matmul_coopmat_smem_f16": (np.float16, False, 64 * WM, 64 * WN, 64 * WM * WN),
}
MAX_N = 64  # COOPMAT_N in MAX's max/kernels/src/linalg/matmul/gpu/adreno/coopmat_matmul.mojo
MAX_KERNELS = {  # graph: (matmul_kernel_adreno_coopmat_{c}_{a}_{b}_{transpose_b}, dtype, B transposed, m, n, k)
    "matmul f32 256x256": ("float32_float32_float32_False", np.float32, False, 256, 256, 256),
    "matmul f16 256x256": ("float16_float16_float16_False", np.float16, False, 256, 256, 256),
    "matmul f16 a @ b.T": ("float16_float16_float16_True", np.float16, True, 256, 64, 128),
}


def max_kernel(max_dir, suffix, k):
    """The saved module of that kernel whose layouts have A's row stride, k: other graphs (a GEMV,
    ResNet-18's classifier) compile the same kernel name with other static shapes."""
    for spv in sorted(max_dir.glob(f"*matmul_kernel_adreno_coopmat_{suffix}_*.spv")):
        if f"%uint_{k} " in run("spirv-dis", spv).stdout:
            return spv
    sys.exit(f"{max_dir}: no matmul_kernel_adreno_coopmat_{suffix} with row stride {k}")
rng = np.random.default_rng(0)


def run(*cmd, check=True):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout[-3000:]}{r.stderr[-3000:]}")
    return r


def adb(*args, check=True):
    return run("adb", *args, check=check)


def launch(name, spv, values, groups, block=(64, 1, 1), subgroup=64):
    """Runs one kernel; returns ({binding: array} for the buffers it writes, timing line) or (None, error)."""
    desc = description(spv)
    entries = leaves(desc)
    assert len(values) == len(entries), f"{name}: {len(values)} values for {len(entries)} leaves"
    local = BUILD / "launch" / name
    local.mkdir(parents=True, exist_ok=True)
    for f in local.iterdir():
        f.unlink()
    (local / "kernel.spv").write_bytes(spv.read_bytes())
    lines = [f"groups {' '.join(map(str, groups))}", f"block {' '.join(map(str, block))}", "reps 20"]
    if subgroup:
        lines.append(f"subgroup {subgroup}")
    outputs, slots = {}, {}
    for (kind, entry), value in zip(entries, values):
        if kind == "buffer":
            data = np.ascontiguousarray(value)
            (local / f"b{entry['binding']}.bin").write_bytes(data.tobytes())
            lines.append(f"buffer {entry['binding']} {data.nbytes} b{entry['binding']}.bin")
            if entry["access"] in ("write", "read_write"):
                lines.append(f"out {entry['binding']} out{entry['binding']}.bin")
                outputs[entry["binding"]] = data
        else:
            slots[id(entry)] = struct.pack(SCALAR_FORMATS[entry["type"]], value).ljust(8, b"\0")
    if desc["params"]:
        params = b""
        for slot in desc["params"]["slots"]:
            params += slots[id(slot)] if "arg" in slot else struct.pack("<q", block["xyz".index(slot["value"][-1])])
        (local / "params.bin").write_bytes(params)
        lines.append(f"buffer {desc['params']['binding']} {len(params)} params.bin")
    (local / "launch.txt").write_text("\n".join(lines) + "\n")

    remote = f"{DEV}/{name}"
    adb("shell", "rm", "-rf", remote)
    adb("shell", "mkdir", "-p", remote)
    adb("push", *sorted(local.iterdir()), remote)
    r = adb("shell", f"{DEV}/vk_launch", remote, check=False)
    if r.returncode:
        return None, f"exit {r.returncode}: " + " | ".join((r.stdout + r.stderr).strip().splitlines()[-3:])
    results = {}
    for binding, like in outputs.items():
        adb("pull", f"{remote}/out{binding}.bin", local)
        results[binding] = np.frombuffer((local / f"out{binding}.bin").read_bytes(), dtype=like.dtype).reshape(like.shape)
    return results, r.stdout.strip().splitlines()[-1].split("submit+wait ")[-1]


def fp16_model(a, b):
    """a @ b with every product and running sum rounded to fp16, in order of k."""
    acc = np.zeros((a.shape[0], b.shape[1]), np.float16)
    for k in range(a.shape[1]):
        acc = (acc + np.outer(a[:, k], b[k, :]).astype(np.float16)).astype(np.float16)
    return acc.astype(np.float64)


def check(label, dtype, bt, a, b, c_out, timing):
    """Prints one result line; returns whether it passed."""
    if c_out is None:
        print(f"{label:34} FAIL  {timing}")
        return False
    bb = b.T if bt else b
    expected = a.astype(np.float64) @ bb.astype(np.float64)
    got = c_out.astype(np.float64)
    if dtype == np.float16:
        # The 840 rounds every product and running sum to fp16; compare with that, on some rows.
        rows = rng.choice(a.shape[0], min(64, a.shape[0]), replace=False)
        model = fp16_model(a[rows], bb)
        rms = lambda x: math.sqrt((x**2).mean())
        ok = rms(got[rows] - expected[rows]) <= 1.25 * rms(model - expected[rows]) + 1e-3 and np.isfinite(got).all()
        result = f"rms err {rms(got[rows] - expected[rows]):.3g} (fp16 model {rms(model - expected[rows]):.3g})"
    else:
        err = np.abs(got - expected).max() if np.isfinite(got).all() else math.inf
        tol = 1e-5 * math.sqrt(a.shape[1])
        ok = err <= tol
        result = f"max err {err:.3g} (tol {tol:.3g})"
    best = float(timing.split(" ms")[0])
    flops = 2 * a.shape[0] * a.shape[1] * bb.shape[1]
    print(f"{label:34} {'PASS' if ok else 'FAIL'}  {result}  {best:.3f} ms best of 20, {flops / best / 1e6:.1f} GFLOP/s")
    return ok


def main():
    args = sys.argv[1:]
    max_dir = None
    if "--max" in args:
        at = args.index("--max")
        max_dir = pathlib.Path(args[at + 1])
        del args[at:at + 2]
    sizes = [int(a) for a in args] or [256]
    print(f"device {os.environ.get('ANDROID_SERIAL', '(adb default)')}")
    run(CC, "-O2", "-o", ROOT / "build/vk_launch", ROOT / "runner/vk_launch.c", "-ldl")
    adb("shell", "mkdir", "-p", DEV)
    adb("push", ROOT / "build/vk_launch", DEV)
    failed = 0
    if max_dir:
        for case, (suffix, dtype, bt, m, n, k) in MAX_KERNELS.items():
            spv = max_kernel(max_dir, suffix, k)
            a = rng.uniform(-1, 1, (m, k)).astype(dtype)
            b = rng.uniform(-1, 1, (n, k) if bt else (k, n)).astype(dtype)
            c = np.full((m, n), np.nan, dtype=dtype)
            # enqueue_adreno_coopmat_matmul: (c, a, b, m, n, k), grid (n / N, m / 64), one subgroup each.
            results, timing = launch("max_" + case.replace(" ", "_").replace("@", "at"), spv, [c, a, b, m, n, k], (n // MAX_N, m // M, 1))
            failed += not check(f"MAX {case} ({m}x{n}x{k})", dtype, bt, a, b,
                                None if results is None else results[0], timing)
        sys.exit(1 if failed else 0)
    only = os.environ.get("COOPMAT_ONLY")  # a substring of the kernel names to run
    kernels = {k: v for k, v in KERNELS.items() if not only or only in k}
    spvs = {k: next(BUILD.glob(f"*_{k}_*.spv")) for k in kernels}
    for n in sizes:
        for name, (dtype, bt, bm, bn, threads) in kernels.items():
            assert n % bm == 0 and n % bn == 0, f"n = {n}: a multiple of {bm} and {bn}"
            a = rng.uniform(-1, 1, (n, n)).astype(dtype)
            b = rng.uniform(-1, 1, (n, n)).astype(dtype)
            c = np.full((n, n), np.nan, dtype=dtype)
            results, timing = launch(f"{name}_{n}", spvs[name], [a, b, c, n], (n // bn, n // bm, 1),
                                     block=(threads, 1, 1))
            failed += not check(f"{name} {bm}x{bn} n={n}", dtype, bt, a, b,
                                None if results is None else results[2], timing)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
