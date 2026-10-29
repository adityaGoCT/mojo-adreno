"""Compile the Llama decode kernels: Mojo (MAX gpu module) -> gfx90a kernel IR -> Vulkan SPIR-V.

  python3 llama/build_kernels.py                  # -> build/llama/{stock,turnip}/<kernel>.spv
  python3 llama/build_kernels.py --flavor native  # -> build/llama/native/<kernel>.spv
  python3 llama/build_kernels.py --flavor prefill840  # -> build/llama/prefill840/<kernel>.spv

stock: SPIR-V 1.4 for Qualcomm's Vulkan 1.1 driver (int32 indices, padded 16-bit shared arrays);
turnip: SPIR-V 1.6 for Mesa Turnip;
native: SPIR-V 1.6 for Mesa Turnip straight from a source-built Mojo with the Vulkan SPIR-V target
(--target-accelerator adreno710, MOJO_SRC), no retargeter;
prefill840: the batched prompt kernels of kernels/prefill (all prompt tokens at once, the matmuls on
KHR cooperative matrices) from the same compiler for --target-accelerator adreno840.
"""

import argparse
import os
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
MOJO = ROOT / ".venv-mojo/bin/mojo"
KERNELS = {"embed": 256, "rmsnorm": 256, "gemv": 64, "gemv_add": 64, "rope_kv": 256, "attention": 64, "silu_mul": 256}
FLAVORS = {"stock": ["--vulkan", "1.1", "--i32", "--pad-shared"], "turnip": ["--vulkan", "1.3"]}
MOJO_SRC = pathlib.Path(os.environ.get("MOJO_SRC", ROOT.parent / "modular"))  # modular/modular with the SPIR-V target
PREFILL = {  # name: (source in kernels/prefill, workgroup size, defines)
    "p_rmsnorm": ("p_rmsnorm", 256, {}), "p_gemm": ("p_gemm", 256, {}), "p_add": ("p_add", 256, {}),
    "p_rope_kv": ("p_rope_kv", 256, {}), "p_attention": ("p_attention", 64, {}), "p_silu_mul": ("p_silu_mul", 256, {}),
}


def sh(*cmd, env=None):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, env=env)
    if r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r.stdout


def build_native(out, flavor="native"):
    bazel_bin = MOJO_SRC / "bazel-bin"
    (out / flavor).mkdir(parents=True, exist_ok=True)
    jobs = ({name: (HERE / "kernels" / f"{name}.mojo", local, {}) for name, local in KERNELS.items()}
            if flavor == "native" else
            {name: (HERE / "kernels/prefill" / f"{src}.mojo", local, defs) for name, (src, local, defs) in PREFILL.items()})
    arch = "adreno710" if flavor == "native" else "adreno840"
    for name, (source, local, defs) in jobs.items():
        side = out / f"{flavor}-sidecars" / name
        side.mkdir(parents=True, exist_ok=True)
        for f in side.glob("*.spv"):
            f.unlink()
        # the MAX gate only checks that a MAX install exists; the compile never loads it
        env = dict(os.environ, MOJO_SPIRV_LOCAL_SIZE=str(local),
                   MODULAR_MAX_PACKAGE_ROOT=str(ROOT / ".venv-mojo/lib/python3.12/site-packages/modular"))
        sh(bazel_bin / "Mojo/tools/mojo/mojo", "build", "--emit", "asm", "-O3", "--target-accelerator", arch,
           *[f"-D{k}={v}" for k, v in defs.items()],
           "-I", bazel_bin / "Mojo/stdlib/std", "-I", bazel_bin / "max/mojo/max", "-o", side / "host.s",
           source, env=env)
        spv = out / flavor / f"{name}.spv"
        spv.write_bytes(next(side.glob("*.spv")).read_bytes())
        r = subprocess.run(["spirv-val", "--target-env", "vulkan1.3", str(spv)], capture_output=True, text=True)
        print(f"{flavor} {name:11s} {spv}: {spv.stat().st_size} bytes, spirv-val "
              f"{'OK' if r.returncode == 0 else 'FAILED: ' + r.stderr.strip()}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--flavor", nargs="+", default=list(FLAVORS), choices=[*FLAVORS, "native", "prefill840"])
    a = ap.parse_args()
    out = ROOT / "build/llama"
    for flavor in ("native", "prefill840"):
        if flavor in a.flavor:
            build_native(out, flavor)
    flavors = {f: FLAVORS[f] for f in a.flavor if f in FLAVORS}
    for name, local in KERNELS.items() if flavors else ():
        ir = out / "ir" / name
        ir.mkdir(parents=True, exist_ok=True)
        for f in ir.glob("*.ll"):
            f.unlink()
        sh(MOJO, "build", "--emit", "llvm", "-O3", "--target-accelerator", "gfx90a", "-o", ir / "host.ll",
           HERE / "kernels" / f"{name}.mojo")
        side = next(ir.glob("*.amdgcn.ll"))
        for flavor, flags in flavors.items():
            (out / flavor).mkdir(exist_ok=True)
            spv = out / flavor / f"{name}.spv"
            msg = sh(sys.executable, ROOT / "mojo2vk.py", side, "--local", str(local), "-o", spv, *flags).strip().splitlines()[-1]
            print(f"{flavor:6s} {name:9s} {msg.split(': ', 1)[1]}")


if __name__ == "__main__":
    main()
