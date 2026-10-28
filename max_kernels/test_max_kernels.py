"""Run MAX's own GPU kernels, compiled by the native adreno710 target, on the phone and check them.

MAX's graph compiler builds the kernels (compile-only, for a virtual Vulkan device) and the target
embeds a launch description in each SPIR-V module: which storage-buffer binding and which params
slot every pointer and scalar of the kernel's arguments goes to, and the workgroup size as
specialization constants. This script plays the part of MAX's runtime for a few kernel families:
it fills in the arguments MAX's host code would pass, lays them out as the description says, runs
the kernel with runner/vk_launch.c on Mesa Turnip, and compares the result with NumPy.

  python3 max_kernels/test_max_kernels.py --compile     # compile the test graphs, then run
  python3 max_kernels/test_max_kernels.py add matmul    # some tests, from the last compile

The compile step runs MAX's compile-only coverage test in a source build of modular/modular with
the target (MOJO_SRC, default ../modular; branch adreno-spirv-target of adityaGoCT/modular).
"""

import argparse
import json
import math
import os
import pathlib
import struct
import subprocess
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
BUILD = ROOT / "build/max_kernels"
MOJO_SRC = pathlib.Path(os.environ.get("MOJO_SRC", ROOT.parent / "modular"))
NDK = pathlib.Path(os.environ.get("ANDROID_NDK", "/opt/homebrew/share/android-ndk"))
CC = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang"
DEV = "/data/local/tmp/mojo/maxk"
TURNIP = "/data/local/tmp/turnip"
os.environ.setdefault("ANDROID_SERIAL", os.environ.get("ADB_WIFI", "192.168.1.7:5555"))
rng = np.random.default_rng(0)


def sh(*cmd, env=None, check=True):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, env=env)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout[-3000:]}{r.stderr[-3000:]}")
    return r


def adb(*args, check=True):
    return sh("adb", *args, check=check)


# --- the launch description embedded in the SPIR-V --------------------------------------------

def description(spv):
    """The `OpModuleProcessed "mojo.vulkan.abi <json>"` of a module."""
    words = np.frombuffer(spv.read_bytes(), dtype="<u4")
    at = 5
    while at < len(words):
        count, opcode = int(words[at]) >> 16, int(words[at]) & 0xFFFF
        if opcode == 330:  # OpModuleProcessed
            text = words[at + 1:at + count].tobytes().split(b"\0", 1)[0].decode()
            if text.startswith("mojo.vulkan.abi "):
                return json.loads(text[len("mojo.vulkan.abi "):])
        at += count
    sys.exit(f"{spv.name}: no mojo.vulkan.abi description (compiled before the target embedded one?)")


SCALAR_FORMATS = {"i1": "<B", "i8": "<b", "i16": "<h", "i32": "<i", "i64": "<q", "half": "<e",
                  "float": "<f", "double": "<d"}


def leaves(desc):
    """The kernel's pointer and scalar leaves in argument order: (kind, entry)."""
    entries = [("buffer", b) for b in desc["buffers"]]
    if desc["params"]:
        entries += [("scalar", s) for s in desc["params"]["slots"] if "arg" in s]
    return sorted(entries, key=lambda e: (e[1]["arg"], e[1]["offset"]))


def launch(name, spv, desc, values, groups, block):
    """Runs the kernel with `values`, one per leaf in argument order (a NumPy array for a pointer,
    a number for a scalar), and returns the buffers it writes, as arrays like the given ones."""
    entries = leaves(desc)
    if len(values) != len(entries):
        sys.exit(f"{name}: {len(values)} values for {len(entries)} kernel argument leaves")
    local = BUILD / "launch" / name
    local.mkdir(parents=True, exist_ok=True)
    for f in local.iterdir():
        f.unlink()
    (local / "kernel.spv").write_bytes(spv.read_bytes())
    lines = [f"groups {' '.join(map(str, groups))}", f"block {' '.join(map(str, block))}"]
    outputs = {}
    slots = {}
    for (kind, entry), value in zip(entries, values):
        if kind == "buffer":
            data = np.ascontiguousarray(value)
            (local / f"b{entry['binding']}.bin").write_bytes(data.tobytes())
            lines.append(f"buffer {entry['binding']} {data.nbytes} b{entry['binding']}.bin")
            if entry["access"] in ("write", "read_write"):
                lines.append(f"out {entry['binding']} out{entry['binding']}.bin")
                outputs[entry["binding"]] = data
        else:
            fmt = SCALAR_FORMATS[entry["type"]]
            slots[id(entry)] = struct.pack(fmt, value).ljust(8, b"\0")
    if desc["params"]:
        params = b""
        for slot in desc["params"]["slots"]:
            if "arg" in slot:
                params += slots[id(slot)]
            else:  # block_dim.x / .y / .z
                params += struct.pack("<q", block["xyz".index(slot["value"][-1])])
        (local / "params.bin").write_bytes(params)
        lines.append(f"buffer {desc['params']['binding']} {len(params)} params.bin")
    lines.append("reps 5")
    (local / "launch.txt").write_text("\n".join(lines) + "\n")

    remote = f"{DEV}/{name}"
    adb("shell", f"rm -rf {remote} && mkdir -p {remote}")
    adb("push", *sorted(local.iterdir()), remote)
    r = adb("shell", f"cd {remote} && LD_LIBRARY_PATH={TURNIP} {DEV}/vk_launch .", check=False)
    if r.returncode:
        return None, (r.stdout + r.stderr).strip().splitlines()[-1]
    results = {}
    for binding, like in outputs.items():
        adb("pull", f"{remote}/out{binding}.bin", local)
        results[binding] = np.frombuffer((local / f"out{binding}.bin").read_bytes(),
                                         dtype=like.dtype).reshape(like.shape)
    timing = r.stdout.strip().splitlines()[-1].split("submit+wait ")[-1]
    return results, timing


# --- kernel families: the arguments MAX's host code passes ------------------------------------

def foreach_values(tensors, shape, simd_width):
    """MAX's grid-stride elementwise kernel (algorithm/backend/gpu/elementwise.mojo): a closure
    holding each tensor (pointer, shape, strides) in capture order, then the shape, the number
    of packed SIMD elements, the unpacked tail length and the packed region length."""
    length = math.prod(shape)
    packed, tail = divmod(length, simd_width)
    values = []
    for array, strides in tensors:
        values += [array, *shape, *strides]
    values += [*shape, packed, tail, length - tail]
    groups = max(1, -(-packed // 256))
    return values, (groups, 1, 1), (256, 1, 1)


def gelu(x):
    erf = np.vectorize(math.erf)
    return (0.5 * x * (1 + erf(x / math.sqrt(2)))).astype(np.float32)


UNARY = {"exp": np.exp, "tanh": np.tanh, "relu": lambda x: np.maximum(x, 0),
         "sigmoid": lambda x: 1 / (1 + np.exp(-x)), "silu": lambda x: x / (1 + np.exp(-x)), "gelu": gelu}


def elementwise_test(case, op):
    def run(spv, desc):
        n = 1024
        simd_width = 8 if "_w8_" in spv.name else 4
        inputs = [rng.standard_normal(n).astype(np.float32) for _ in range(2 if op in ("add", "mul") else 1)]
        out_dtype = np.float16 if op == "cast" else np.float32
        out = np.full(n, np.nan, dtype=out_dtype)
        # Capture order: the output is the buffer the kernel writes; inputs follow in order.
        it = iter(inputs)
        tensors = [(out if b["access"] in ("write", "read_write") else next(it), [1]) for b in desc["buffers"]]
        values, groups, block = foreach_values(tensors, [n], simd_width)
        expected = {"add": lambda: inputs[0] + inputs[1], "mul": lambda: inputs[0] * inputs[1],
                    "cast": lambda: inputs[0].astype(np.float16)}.get(op, lambda: UNARY[op](inputs[0]))()
        # GLSL.std.450 exp and friends are a few ulp; a cast rounds to nearest.
        return values, groups, block, expected, (1e-3 if op == "cast" else 1e-4, 1e-5)
    return case, "mogg.foreach", run


def transpose_test():
    def run(spv, desc):
        x = rng.standard_normal((64, 128)).astype(np.float32)
        out = np.full((128, 64), np.nan, dtype=np.float32)
        # The output, and the input viewed with swapped dimensions (a strided view, no copy).
        tensors = [(out, [64, 1]) if b["access"] in ("write", "read_write") else (x, [1, 128])
                   for b in desc["buffers"]]
        values, groups, block = foreach_values(tensors, [128, 64], 4)
        return values, groups, block, x.T, (0, 0)
    return "transpose", "mogg.foreach", run


def matmul_test(case, m, n, k, dtype):
    def run(spv, desc):
        a = rng.standard_normal((m, k)).astype(dtype)
        b = rng.standard_normal((k, n)).astype(dtype)
        c = np.full((m, n), np.nan, dtype=dtype)
        # enqueue_matmul_kernel_naive: (c, a, b, m, n, k), grid (m/16, n/16), block (16, 16).
        values = [c, a, b, m, n, k]
        expected = a.astype(np.float64) @ b.astype(np.float64)
        # Sums of k products: float32 rounding grows like sqrt(k); float16 outputs round to 11 bits.
        tol = (1e-2, 0.1) if dtype == np.float16 else (1e-4, 1e-5 * math.sqrt(k))
        return values, (-(-m // 16), -(-n // 16), 1), (16, 16, 1), expected, tol
    return case, "matmul_kernel_naive", run


TESTS = {
    "add": elementwise_test("add", "add"),
    "mul": elementwise_test("mul", "mul"),
    "relu": elementwise_test("relu", "relu"),
    "exp": elementwise_test("exp", "exp"),
    "tanh": elementwise_test("tanh", "tanh"),
    "gelu": elementwise_test("gelu", "gelu"),
    "sigmoid": elementwise_test("sigmoid", "sigmoid"),
    "silu": elementwise_test("silu", "silu"),
    "cast": elementwise_test("cast f32->f16", "cast"),
    "transpose": transpose_test(),
    "matmul": matmul_test("matmul f32 256x256", 256, 256, 256, np.float32),
    "matmul_f16": matmul_test("matmul f16 256x256", 256, 256, 256, np.float16),
    "gemv": matmul_test("matmul (gemv) 1x2048x2048", 1, 2048, 2048, np.float32),
}


def case_dir(case):
    return BUILD / "spv" / "".join(c if c.isalnum() else "_" for c in case)


def compile_cases(cases):
    """MAX's compile test for each graph, keeping every kernel's SPIR-V (no MOJO_SPIRV_LOCAL_SIZE:
    the workgroup size is each launch's block size)."""
    for case in cases:
        out = case_dir(case)
        out.mkdir(parents=True, exist_ok=True)
        for f in out.glob("*.spv"):
            f.unlink()
        env = {k: v for k, v in os.environ.items() if k != "MOJO_SPIRV_LOCAL_SIZE"}
        env["MOJO_SPIRV_SAVE_DIR"] = str(out)
        r = sh(MOJO_SRC / "bazelw", "run", "--config=disable-lint", "//max/examples/vulkan_coverage:coverage",
               "--", "--case", case, env=env, check=False)
        status = next((l for l in r.stdout.splitlines() if l.startswith("RESULT|")), "RESULT|CRASH|")
        print(f"compiled {case:28s} {status.split('|')[1]:5s} {len(list(out.glob('*.spv')))} kernels", flush=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tests", nargs="*", help=f"some of: {' '.join(TESTS)} (default: all)")
    ap.add_argument("--compile", action="store_true", help="compile the test graphs first")
    a = ap.parse_args()
    tests = a.tests or list(TESTS)
    if unknown := [t for t in tests if t not in TESTS]:
        sys.exit(f"unknown tests: {' '.join(unknown)}")
    if a.compile:
        compile_cases(sorted({TESTS[t][0] for t in tests}))
    BUILD.mkdir(parents=True, exist_ok=True)
    sh(CC, "-O2", "-o", BUILD / "vk_launch", ROOT / "runner/vk_launch.c", "-ldl")
    adb("shell", f"mkdir -p {DEV}")
    adb("push", BUILD / "vk_launch", f"{DEV}/")
    print(f"phone: {os.environ['ANDROID_SERIAL']}")
    passed = failed = 0
    for test in tests:
        case, prefix, run = TESTS[test]
        spvs = sorted(f for f in case_dir(case).glob("*.spv") if f.name.split("-", 1)[1].startswith(prefix))
        if not spvs:
            print(f"{test:10s} no {prefix} kernel compiled for '{case}' (run with --compile)")
            failed += 1
            continue
        for spv in spvs:
            desc = description(spv)
            values, groups, block, expected, (rtol, atol) = run(spv, desc)
            name = f"{test}-{spv.name.split('-', 1)[0]}"
            results, timing = launch(name, spv, desc, values, groups, block)
            kernel = spv.name.split("-", 1)[1][:-4]
            if results is None:
                print(f"{test:10s} {kernel[:48]:48s} ERROR {timing}")
                failed += 1
                continue
            got = next(iter(results.values())).astype(np.float64)
            want = np.asarray(expected, dtype=np.float64)
            ok = bool(np.allclose(got, want, rtol=rtol, atol=atol))
            err = float(np.max(np.abs(got - want)))
            print(f"{test:10s} {kernel[:48]:48s} {'PASS' if ok else 'FAIL'}  max error {err:.2e}  {timing}")
            passed += ok
            failed += not ok
    print(f"\n{passed} passed, {failed} failed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
