"""Compile Bonsai 2 2B's Mojo kernels to Vulkan SPIR-V for the Adreno 840.

  python3 bonsai/build_kernels.py    # -> build/bonsai/<kernel>.spv

bonsai/kernels/kernels.mojo is the kernel file of mav3ri3k/modular's Android OpenCL port
(max/examples/android-llm/bonsai, branch android-publication, 03de9211), unchanged. There it
runs through OpenCL C; here a source-built Mojo with the Vulkan SPIR-V target (MOJO_SRC, branch
adreno-spirv-target, --target-accelerator adreno840) compiles each kernel from a generated
main() that only enqueues it. Pointer arguments become storage buffers in order, scalar
arguments 64-bit slots of a params buffer bound last (bonsai_vk.c fills them).
"""

import os
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
MOJO_SRC = pathlib.Path(os.environ.get("MOJO_SRC", ROOT.parent / "modular"))
F32, U32, F16 = "float32", "uint32", "float16"
# name: (workgroup size, pointer element types, number of Int32 scalars)
KERNELS = {
    "hadamard": (64, [F32, F32, F32, U32], 3), "packed_linear": (64, [U32, U32, F16, F32], 2),
    "packed_reduce": (64, [F32, F32], 2), "packed_head": (128, [U32, U32, F16, F32, F32], 3),
    "embedding": (64, [U32, F16, F32], 1), "rms_partials": (64, [F32, F32], 0), "rms_norm": (64, [F32] * 4, 0),
    "gate_partials": (64, [F32] * 4, 0), "convolve": (64, [F32] * 4, 0), "normalize_qk": (64, [F32] * 2, 0),
    "delta_gates": (64, [F32] * 3, 0), "delta_update": (64, [F32] * 4, 0), "gated_norm": (64, [F32] * 4, 0),
    "head_norm": (64, [F32] * 3, 1), "rope": (64, [F32] * 2, 2), "cache_kv": (64, [F32] * 4, 1),
    "attention_scores": (64, [F32] * 3, 2), "attention_values": (64, [F32] * 4, 2), "residual": (64, [F32] * 2, 0),
    "swiglu": (64, [F32] * 2, 0), "copy": (64, [F32] * 2, 0),
}


def wrapper(name, types, scalars, local):
    bufs = [f"    var b{i} = ctx.enqueue_create_buffer[DType.{t}](1024)" for i, t in enumerate(types)]
    args = ", ".join([f"b{i}" for i in range(len(types))] + ["Int32(0)"] * scalars)
    return "\n".join(["from max.gpu.host import DeviceContext", "import kernels", "", "", "def main() raises:",
                      "    var ctx = DeviceContext()", *bufs,
                      f"    ctx.enqueue_function[kernels.{name}]({args}, grid_dim=1, block_dim={local})",
                      "    ctx.synchronize()", ""])


def main():
    bazel_bin = MOJO_SRC / "bazel-bin"
    out = ROOT / "build/bonsai"
    gen = out / "gen"
    gen.mkdir(parents=True, exist_ok=True)
    for name, (local, types, scalars) in KERNELS.items():
        src = gen / f"k_{name}.mojo"
        src.write_text(wrapper(name, types, scalars, local))
        side = gen / name
        side.mkdir(exist_ok=True)
        for f in side.glob("*.spv"):
            f.unlink()
        env = dict(os.environ, MOJO_SPIRV_LOCAL_SIZE=str(local),
                   MODULAR_MAX_PACKAGE_ROOT=str(ROOT / ".venv-mojo/lib/python3.12/site-packages/modular"))
        r = subprocess.run([str(bazel_bin / "Mojo/tools/mojo/mojo"), "build", "--emit", "asm", "-O3",
                            "--target-accelerator", "adreno840", "-I", str(bazel_bin / "Mojo/stdlib/std"),
                            "-I", str(bazel_bin / "max/mojo/max"), "-I", str(HERE / "kernels"),
                            "-o", str(side / "host.s"), str(src)], capture_output=True, text=True, env=env)
        spvs = list(side.glob(f"*kernels_{name}_*.spv"))
        if r.returncode or not spvs:
            print(f"{name}: FAILED\n{r.stdout}{r.stderr}"[-3000:])
            continue
        spv = out / f"{name}.spv"
        spv.write_bytes(spvs[0].read_bytes())
        v = subprocess.run(["spirv-val", "--target-env", "vulkan1.3", str(spv)], capture_output=True, text=True)
        print(f"{name:17s} {spv.stat().st_size:7d} bytes, spirv-val "
              f"{'OK' if v.returncode == 0 else 'FAILED: ' + v.stderr.strip()[:300]}")


if __name__ == "__main__":
    sys.exit(main())
