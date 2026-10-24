# mojo-adreno

Run Mojo GPU kernels on a phone's **Adreno 710** GPU, even though Mojo has no target for it.

Mojo 1.2 (Modular) has GPU targets for NVIDIA, AMD and Apple only: no SPIR-V, Vulkan, OpenCL or
Adreno. This repo gets ordinary Mojo GPU code (MAX `gpu` module, `global_idx`, `DeviceContext`)
running on the Adreno 710 of a moto g stylus 5G (2024) anyway, by taking the kernel from **Mojo's own
LLVM IR** and retargeting it. Mojo compiles the kernel for an AMD CDNA2 GPU (`gfx90a`), whose 64-lane
warps match the Adreno's subgroups; the IR then goes to Vulkan SPIR-V or OpenCL C. One command, four
verified backends:

```
$ python3 mojo_adreno.py src/vecadd_gpu.mojo
summary: turnip=PASS  stock=PASS  opencl=PASS  cpu=PASS
```

Write-up, code first: **[Running Mojo GPU Kernels on an Adreno Phone GPU](BLOG.md)**. It is Part 3 of a
series whose Parts 1 and 2 (PyTorch → IREE → Adreno, and an fp16 GEMM tuner) live in
[adityaGoCT/iree-adreno-genai-tuner](https://github.com/adityaGoCT/iree-adreno-genai-tuner).

| backend | path | `vecadd_gpu` | `vecadd4_gpu` (loop) | `warpsum_gpu` (warp shuffles) |
|---|---|---|---|---|
| `turnip` | Mojo IR → `mojo2vk.py` → `opt -O3` → LLVM 22 SPIR-V backend (SPIR-V 1.6) → Vulkan 1.3 on Mesa Turnip | PASS | PASS | PASS |
| `stock` | same, SPIR-V 1.4 + `VK_KHR_spirv_1_4`, int64 narrowed to int32 → Qualcomm Vulkan 1.1 driver | PASS | PASS | PASS |
| `opencl` | Mojo IR → `mojo2cl.py` → OpenCL C → Qualcomm OpenCL 3.0 compiler on the phone | PASS | PASS | PASS |
| `cpu` | `mojo build --emit object --target-triple aarch64-unknown-linux-android34` → NDK link | PASS | (same CPU kernel) | n/a |

n = 1,000,003 elements, 0 mismatches everywhere; every element is checked on the phone. All of it
passes with `--accel gfx90a` (default) and with `--accel sm_80`.

## Quickstart

Host: macOS on Apple silicon (Linux works with path changes). Phone: any Android device with adb;
results above are from an Adreno 710 on Android 14, no root.

```bash
scripts/setup.sh                        # brew: llvm, spirv-tools, android-ndk, adb; uv: .venv-mojo (Mojo 1.2.0 + MAX 26.7.0)
export ANDROID_SERIAL=<phone ip>:5555   # or a USB serial; adb devices
python3 mojo_adreno.py src/vecadd_gpu.mojo
python3 mojo_adreno.py src/vecadd4_gpu.mojo --backend stock opencl   # some backends
python3 mojo_adreno.py src/warpsum_gpu.mojo --accel sm_80             # NVIDIA flavour: 32-lane warps
```

Outputs, including the intermediate Vulkan IR (`*.vk.ll`), SPIR-V and OpenCL C, land in `build/`;
phone-side files in `/data/local/tmp/mojo`.

The `turnip` backend needs Mesa Turnip (with its `libvulkan.so` shim) in `/data/local/tmp/turnip`,
built by `scripts/build_turnip.sh --push` in
[iree-adreno-genai-tuner](https://github.com/adityaGoCT/iree-adreno-genai-tuner). Without it, that
backend reports `SKIP` and the others still run.

Options: `--accel gfx90a|sm_80` (the Mojo target whose kernel IR is retargeted), `--opt O3|O2|O1|none`
(LLVM `opt` before `llc`), `--n`, `--local` (workgroup size). Environment overrides: `ANDROID_SERIAL`
(or `ADB_WIFI`), `ANDROID_NDK` (default
`/opt/homebrew/share/android-ndk`), `MOJO` (default `.venv-mojo/bin/mojo`), `LLVM_BIN` (default
`/opt/homebrew/opt/llvm/bin`; needs LLVM 22 or later for the SPIR-V resource intrinsics).

## How it works

1. `mojo build --emit llvm --target-accelerator gfx90a vecadd_gpu.mojo` writes the host IR plus one
   **LLVM IR sidecar per kernel**, before LLVM's optimization passes (`--emit llvm` is "unoptimized
   LLVM IR"). AMD flavour: `llvm.amdgcn.workitem.id` / `workgroup.id`, block size loaded from
   `llvm.amdgcn.implicitarg.ptr` + 12. NVPTX flavour (`--accel sm_80`): `llvm.nvvm.read.ptx.sreg.*`.
2. **`mojo2vk.py`** rewrites that kernel into a Vulkan compute shader for LLVM's SPIR-V backend:
   pointer arg *k* → storage buffer `(set 0, binding k)` via `llvm.spv.resource.handlefrombinding`;
   each GEP on it → `llvm.spv.resource.getpointer` (logical addressing, `addrspace(11)`);
   scalar args → int64 slots of a params buffer; thread / workgroup ids → `llvm.spv.thread.id.in.group` /
   `llvm.spv.group.id`, block size → the fixed workgroup size, block count → `llvm.spv.num.workgroups`;
   warp ops → `llvm.spv.wave.readlane` (`OpGroupNonUniformShuffle`) on the subgroup lane;
   `hlsl.shader="compute"` + `hlsl.numthreads`; then `opt -O3`, `llc` and `spirv-val`.
   `--i32 --vulkan 1.1` targets the stock driver (no shaderInt64, SPIR-V ≤ 1.4).
3. **`mojo2cl.py`** translates the same IR to OpenCL C (one variable per SSA value, labels + goto,
   phis resolved on edges; byte-addressed `__global uchar*` pointers; thread ids →
   `get_local_id/get_group_id/get_local_size/get_num_groups`; warp ops through `__local` memory).
4. `runner/vk_run.c` / `runner/cl_run.c` (phone side, `dlopen` of `libvulkan.so` / `libOpenCL.so`):
   A[i] = i, B[i] = 2i, C poisoned with NaN, one dispatch, every element checked (`runner/check.h`).

## Warp operations and the proxy target

Mojo bakes the target's warp width into the kernel at compile time: `WARP_SIZE` is 32 for `sm_80`
and `apple-m1`, 64 for `gfx90a`. The Adreno 710's subgroups are 64 lanes on the stock driver; Mesa
Turnip reports 128. That is why `gfx90a` is the default. `src/warpsum_gpu.mojo` calls MAX's
`warp.sum`, and the two targets lower it differently:

| `--accel` | warp sum in the kernel IR | mapped to |
|---|---|---|
| `gfx90a` | 4 `llvm.amdgcn.update.dpp` + 2 `llvm.amdgcn.ds.bpermute`, lane from `mbcnt` | shuffles within each 64-lane wave of the subgroup |
| `sm_80` | 5 `llvm.nvvm.shfl.sync.bfly` (clamp 31) | shuffles within each 32-lane segment of the subgroup |

On Vulkan the shuffles are `OpGroupNonUniformShuffle`. Qualcomm's OpenCL has no general shuffle
(only `cl_khr_subgroups` and the vendor `cl_qcom_subgroup_shuffle`), so `mojo2cl.py` runs warp ops
on a virtual 64-lane subgroup: lanes are local ids, values pass through `__local` memory between
barriers. Each target's result is checked against its own warp width, and against the other's as a
control (n = 1,000,003):

| kernel IR | checked as 32-lane sums | checked as 64-lane sums |
|---|---|---|
| `gfx90a` | 1,000,000 mismatches (all three GPU backends) | **0** on turnip, stock, opencl |
| `sm_80` | **0** on turnip, stock, opencl | 1,000,000 mismatches (all three) |

Both are correct for the warp width they were compiled with. The NVIDIA flavour simply treats a
64-lane subgroup as two 32-lane warps, so warp-level work covers half of it. Kernels that branch on
the vendor (`is_nvidia_gpu()`, `is_amd_gpu()`) and use matrix-core or async-copy intrinsics are not
retargetable either way.

Kernels can also skip MAX and read SPIR-V builtins directly from Mojo:
`llvm_intrinsic["llvm.spv.thread.id", Int32](Int32(0))` (`src/vecadd_spv.mojo`), compiled for the host
target; `mojo2vk.py` and `mojo2cl.py` take that IR as well (PASS on Turnip and OpenCL):

```bash
.venv-mojo/bin/mojo build --emit llvm -O3 -o build/spv/vecadd_spv.ll src/vecadd_spv.mojo
python3 mojo2vk.py build/spv/vecadd_spv.ll --kernel vecadd --local 64 -o build/spv/vecadd_spv.spv
python3 mojo2cl.py build/spv/vecadd_spv.ll --kernel vecadd -o build/spv/vecadd_spv.cl
```

## What did not work (and why)

| attempt | outcome |
|---|---|
| Mojo GPU target for Adreno / SPIR-V | none: accelerators are NVIDIA `sm_*`, AMD `gfx*`, Apple `apple-m*` only |
| OpenCL with SPIR-V IL (`clCreateProgramWithIL`) | `-59 CL_INVALID_OPERATION`: Qualcomm OpenCL 3.0 reports no IL version and no `cl_khr_il_program` (`probes/cl_probe.c`) |
| Running the kernel on the Mac's GPU for reference | needs Xcode's `metal` compiler (`xcrun metal` missing); not needed: the phone runners check every element |
| `ptr null` as the resource name in `handlefrombinding` | crashes LLVM 22's SPIR-V instruction selector; a name string per buffer works (adds the Int8 capability; both drivers have shaderInt8) |
| SPIR-V 1.3 for Vulkan 1.1 | LLVM 22's Vulkan output starts at SPIR-V 1.4; the stock driver accepts it via `VK_KHR_spirv_1_4` |
| Numbered entry block | Mojo's unlabeled entry block is `%<#args>`; phis name it, so retargeted bodies keep that label |
| Lowering from Mojo's MLIR (KGEN / POP / LIT) instead of LLVM IR | not exposed in 1.2: no `--emit mlir`, MLIR print flags unreachable, `MODULAR_DEBUG` only takes runtime `max-debug.*` options; the dialects are undocumented and Mojo links no SPIR-V backend |
| `opt -O3` output straight into `llc` | `llvm.usub.sat` (formed from the `mbcnt.hi` mapping) cannot be selected by LLVM 22's SPIR-V backend; `mojo2vk.py` expands saturating add/sub to compare + select |
| `uv pip install mojo` / `max` | hung after downloading twice; a clean retry (`-v`) installed both |

## Files

```
mojo_adreno.py     one-command pipeline (build Mojo IR, retarget, push, run, verify)
mojo2vk.py         Mojo kernel IR -> Vulkan compute SPIR-V
mojo2cl.py         Mojo kernel IR -> OpenCL C
src/               vecadd_gpu.mojo (MAX gpu), vecadd4_gpu.mojo (loop), warpsum_gpu.mojo (warp.sum),
                   vecadd_spv.mojo (SPIR-V intrinsic), vecadd_cpu.mojo
runner/            vk_run.c, cl_run.c, check.h (result check), cpu_main.c (phone side)
probes/cl_probe.c  OpenCL platform / IL capability probe
ref/               hand-written Vulkan IR, reference OpenCL kernel
scripts/setup.sh   host tools and the Mojo venv
BLOG.md            the write-up
```

Versions used: Mojo 1.2.0, MAX 26.7.0, Homebrew LLVM 22.1.2, SPIRV-Tools v2026.1, Android NDK r30
(its sysroot provides the Vulkan headers), adb 37.

## Limits

The retargeters cover the instruction subset of simple kernels (integer/float arithmetic, compares,
casts, GEP/load/store, branches, phis) plus warp shuffles (NVPTX `shfl.sync` with a full mask and
`laneid`; AMDGPU `ds.bpermute`, `update.dpp` with full row/bank masks, `mbcnt`). Not yet: shared
memory, barriers, atomics, ballot/vote, non-float element types in the runners, and timing beyond
wall-clock submit+wait. The pipeline launches one thread per element whatever the kernel does.

## License

Apache-2.0, see [`LICENSE`](LICENSE). Mojo and MAX are Modular's and are installed from PyPI under
their own license; nothing from them is redistributed here.
