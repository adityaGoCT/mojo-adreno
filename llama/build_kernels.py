"""Compile the Llama decode kernels: Mojo (MAX gpu module) -> gfx90a kernel IR -> Vulkan SPIR-V.

  python3 llama/build_kernels.py            # -> build/llama/{stock,turnip}/<kernel>.spv

stock: SPIR-V 1.4 for Qualcomm's Vulkan 1.1 driver (int32 indices, padded 16-bit shared arrays);
turnip: SPIR-V 1.6 for Mesa Turnip.
"""

import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
MOJO = ROOT / ".venv-mojo/bin/mojo"
KERNELS = {"embed": 256, "rmsnorm": 256, "gemv": 64, "gemv_add": 64, "rope_kv": 256, "attention": 64, "silu_mul": 256}
FLAVORS = {"stock": ["--vulkan", "1.1", "--i32", "--pad-shared"], "turnip": ["--vulkan", "1.3"]}


def sh(*cmd):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r.stdout


def main():
    out = ROOT / "build/llama"
    for name, local in KERNELS.items():
        ir = out / "ir" / name
        ir.mkdir(parents=True, exist_ok=True)
        for f in ir.glob("*.ll"):
            f.unlink()
        sh(MOJO, "build", "--emit", "llvm", "-O3", "--target-accelerator", "gfx90a", "-o", ir / "host.ll",
           HERE / "kernels" / f"{name}.mojo")
        side = next(ir.glob("*.amdgcn.ll"))
        for flavor, flags in FLAVORS.items():
            (out / flavor).mkdir(exist_ok=True)
            spv = out / flavor / f"{name}.spv"
            msg = sh(sys.executable, ROOT / "mojo2vk.py", side, "--local", str(local), "-o", spv, *flags).strip().splitlines()[-1]
            print(f"{flavor:6s} {name:9s} {msg.split(': ', 1)[1]}")


if __name__ == "__main__":
    main()
