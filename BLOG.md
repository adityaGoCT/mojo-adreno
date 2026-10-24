# Running Mojo GPU Kernels on an Adreno Phone GPU

*Part 3 of [Bringing PyTorch LLMs to a Mid-Range Adreno GPU with IREE](https://github.com/adityaGoCT/iree-adreno-genai-tuner/blob/main/BLOG.md) (Part 2: [Tuning fp16 GEMMs on a Phone GPU](https://github.com/adityaGoCT/iree-adreno-genai-tuner/blob/main/BLOG-GEMM.md)) · October 24, 2026 · Aditya*

## TL;DR

Mojo 1.2 compiles GPU kernels for NVIDIA, AMD and Apple GPUs only. It has no SPIR-V, Vulkan or OpenCL target, so it cannot target the Adreno 710 in my phone. I got ordinary Mojo GPU code running there anyway. The code uses MAX's `gpu` module, `global_idx` and `DeviceContext`. Mojo still writes LLVM IR for each kernel, and that IR is small and easy to rewrite. I take it from Mojo's NVIDIA build and retarget it twice: to a Vulkan compute shader through LLVM's own SPIR-V backend, and to OpenCL C for Qualcomm's OpenCL compiler.

One command builds, retargets, pushes and checks four backends on the phone:

```
$ python3 mojo_adreno.py src/vecadd_gpu.mojo
summary: turnip=PASS  stock=PASS  opencl=PASS  cpu=PASS
```

Three lessons carried the most weight:

1. **A missing target is not a missing compiler.** Mojo's front end and optimizer do the hard part. What separates a CUDA kernel from a Vulkan shader is the ABI: how buffers arrive and how a thread finds its index. That is a rewrite of a few dozen lines of IR, not a new backend.
2. **Take the plainest IR on offer.** The NVPTX flavour has plain `ptr` arguments and one intrinsic call per thread register, so a handful of pattern rewrites cover it.
3. **The phone decides the format, not the spec.** Qualcomm's OpenCL 3.0 driver takes no SPIR-V at all, and its Vulkan 1.1 driver has no 64-bit integers. Each of those facts shaped its own path through the retargeters.

The code is [this repo](README.md).

## Why Mojo has no Adreno target

Mojo picks a GPU with `--target-accelerator`, and `mojo build --print-supported-accelerators` lists three vendors: AMD (`gfx90a` to `gfx1250`), Apple (`apple-m1` to `apple-m5`) and NVIDIA (`sm_52` to `sm_121a`). Ask for anything else and the build fails in the standard library's GPU info table:

```
$ mojo build --emit llvm --target-accelerator spirv src/vecadd_gpu.mojo
Mojo/stdlib/std/_gpu/host/info.mojo:126:13: note: constraint failed: GPU architecture 'spirv' is not supported.
```

The Adreno 710 speaks Vulkan (Qualcomm's own Vulkan 1.1 driver, or Mesa Turnip from [Part 1](https://github.com/adityaGoCT/iree-adreno-genai-tuner/blob/main/BLOG.md) at Vulkan 1.4) and OpenCL 3.0. Neither is reachable from Mojo directly.

## The idea: keep Mojo's front end, replace the last step

`mojo build --emit llvm --target-accelerator sm_80` writes the host program's IR *and* one LLVM IR file per kernel next to it, a sidecar named `<output>_<kernel>.nvptx.ll`. That sidecar is the kernel after Mojo's optimizer and before NVIDIA's code generator. Any NVIDIA arch works; `sm_80` is arbitrary.

From there, two retargeters take over:

```
vecadd.mojo --(mojo build --emit llvm --target-accelerator sm_80)--> kernel.nvptx.ll
  kernel.nvptx.ll --mojo2vk.py--------------------> Vulkan IR --llc--> SPIR-V 1.6 --> Mesa Turnip (Vulkan 1.3 API)
  kernel.nvptx.ll --mojo2vk.py --i32 --vulkan 1.1--> Vulkan IR --llc--> SPIR-V 1.4 --> stock Qualcomm Vulkan 1.1
  kernel.nvptx.ll --mojo2cl.py--------------------> OpenCL C --------------------> Qualcomm OpenCL 3.0 compiler
```

A fourth path skips the GPU: Mojo cross-compiles a C-ABI function for `aarch64-unknown-linux-android34`, and the NDK links it into a phone binary.

## Step 1: Install

Mojo gets its own Python 3.12 venv. MAX is needed too: in 1.2 the `gpu` module moved out of Mojo's standard library into MAX. [`scripts/setup.sh`](scripts/setup.sh) installs everything:

```bash
brew install llvm spirv-tools                               # llc with the SPIR-V backend (LLVM 22.1.2), spirv-val
brew install --cask android-ndk android-platform-tools       # NDK r30 (clang + Vulkan headers), adb
uv venv .venv-mojo --python 3.12
uv pip install --python .venv-mojo/bin/python mojo==1.2.0 max==26.7.0
```

The install hung twice after downloading; a clean retry with `-v` installed both. The NDK's sysroot already has the Vulkan headers the runner needs. The phone is reached over adb (`ANDROID_SERIAL` or `ADB_WIFI`; mine is on Wi-Fi). The `turnip` backend also needs Mesa Turnip in `/data/local/tmp/turnip`, built in [Part 1](https://github.com/adityaGoCT/iree-adreno-genai-tuner/blob/main/BLOG.md) by `scripts/build_turnip.sh --push` in the companion repo. Without it, that backend reports `SKIP`.

## Step 2: A Mojo kernel and the IR it produces

The kernel is plain MAX GPU code, [`src/vecadd_gpu.mojo`](src/vecadd_gpu.mojo):

```mojo
from max.gpu import global_idx
from max.gpu.host import DeviceContext


def vecadd(a: UnsafePointer[Float32, MutAnyOrigin], b: UnsafePointer[Float32, MutAnyOrigin],
           c: UnsafePointer[Float32, MutAnyOrigin], n: Int64):
    var i = global_idx.x
    if Int64(i) < n:
        c[i] = a[i] + b[i]


def main() raises:
    comptime n = 1024
    var ctx = DeviceContext()
    ...
    ctx.enqueue_function[vecadd](a, b, c, Int64(n), grid_dim=n // 64, block_dim=64)
```

`main` is there so that `enqueue_function` instantiates the kernel. Its host code never runs on the phone. The sidecar Mojo writes for `vecadd` is this, with its declarations and metadata trimmed:

```llvm
target triple = "nvptx64-nvidia-cuda"

define dso_local ptx_kernel void @vecadd_gpu_vecadd_Pointer_Tru6A6AoA6A6AcB_c9ef990b2741a7d7(
    ptr noundef %0, ptr noundef %1, ptr noundef %2, i64 noundef %3) #0 {
  %5 = call i32 @llvm.nvvm.read.ptx.sreg.tid.x()
  %6 = zext i32 %5 to i64
  %7 = call i32 @llvm.nvvm.read.ptx.sreg.ctaid.x()
  %8 = zext i32 %7 to i64
  %9 = call i32 @llvm.nvvm.read.ptx.sreg.ntid.x()
  %10 = sext i32 %9 to i64
  %11 = mul i64 %8, %10
  %12 = add i64 %11, %6                                ; global_idx.x = ctaid * ntid + tid
  %13 = getelementptr inbounds float, ptr %1, i64 %12
  %14 = getelementptr inbounds float, ptr %0, i64 %12
  %15 = getelementptr inbounds float, ptr %2, i64 %12
  %16 = icmp slt i64 %12, %3
  br i1 %16, label %17, label %21

17:                                                    ; preds = %4
  %18 = load float, ptr %14, align 4
  %19 = load float, ptr %13, align 4
  %20 = fadd contract float %18, %19
  store float %20, ptr %15, align 4
  br label %22
...
```

Three things in it are CUDA and nothing else: raw pointer arguments, scalar arguments passed by value, and the `llvm.nvvm.read.ptx.sreg.*` thread registers. The arithmetic, compares, GEPs, loads, stores and branches are target-neutral LLVM.

## Step 3: Vulkan, by rewriting the kernel ABI

LLVM 22's SPIR-V backend can emit Vulkan compute shaders. But a Vulkan shader takes no arguments. It reaches memory through descriptor-bound storage buffers with logical addressing, so it has no raw pointers, and it reads SPIR-V builtins for its thread index. [`mojo2vk.py`](mojo2vk.py) rewrites one kernel function to fit:

| Mojo / NVPTX | Vulkan (LLVM SPIR-V backend) |
| --- | --- |
| pointer argument *k* | storage buffer at (set 0, binding *k*): `llvm.spv.resource.handlefrombinding` |
| `getelementptr T, ptr %arg_k, idx` | `llvm.spv.resource.getpointer(handle_k, idx)`, a `ptr addrspace(11)` |
| load / store through it | `addrspace(11)`, SPIR-V `StorageBuffer` |
| scalar argument *j* | int64 slot *j* of a params buffer at binding = number of pointer arguments |
| `sreg.tid` / `sreg.ctaid` | `llvm.spv.thread.id.in.group` / `llvm.spv.group.id` |
| `sreg.ntid` | the fixed workgroup size (`--local`, default 64) |
| function attributes | `"hlsl.shader"="compute"`, `"hlsl.numthreads"="64,1,1"`; entry point `@main` |

The core of it is two regex rewrites over the body. A GEP on a pointer argument becomes a resource pointer, with the index narrowed to `i32` because `getpointer` takes one:

```python
g = re.match(r"\s*(%[\w.]+) = getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr(?: addrspace\(\d+\))? (%[\w.]+), (i64|i32) (%[\w.]+|-?\d+)\s*$", line)
if g and g.group(3) in ptr_args:
    res, gty, base, ity, idx = g.groups()
    ...
    out.append(f"  {res} = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{handle_suffix(e)}({handle_type(e)} %h.{k}, i32 {i32})")
```

An NVPTX thread register becomes a SPIR-V builtin, or a constant for the block size:

```python
r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?(?:range\([^)]*\) )?i32 @llvm\.nvvm\.read\.ptx\.sreg\.(tid|ctaid|ntid)\.([xyz])\(\)", line)
if r:
    res, reg, comp = r.groups()
    if reg == "ntid":
        out.append(f"  {res} = add i32 0, {local[c]}")
    else:
        out.append(f"  {res} = call i32 @{NVPTX_REG[reg]}.i32(i32 {c})")
```

Anything else target-specific (`@llvm.nvvm.*`, `@llvm.amdgcn.*`) or any call to a non-intrinsic function stops the tool with an error rather than producing a wrong shader. Then `llc -O2 -filetype=obj` writes SPIR-V and `spirv-val` checks it.

The same kernel after the rewrite, for Turnip:

```llvm
target triple = "spirv1.6-unknown-vulkan1.3-compute"

@.buf0 = private unnamed_addr constant [5 x i8] c"buf0\00"
...
define void @main() #0 {
entry:
  %h.0 = call target("spirv.VulkanBuffer", [0 x float], 12, 1) @llvm.spv.resource.handlefrombinding...(i32 0, i32 0, i32 1, i32 0, ptr @.buf0)
  %h.1 = ...(i32 0, i32 1, i32 1, i32 0, ptr @.buf1)
  %h.2 = ...(i32 0, i32 2, i32 1, i32 0, ptr @.buf2)
  %h.params = call target("spirv.VulkanBuffer", [0 x i64], 12, 1) ...(i32 0, i32 3, i32 1, i32 0, ptr @.params)
  %sp.0 = call ptr addrspace(11) @llvm.spv.resource.getpointer...(... %h.params, i32 0)
  %sv.0 = load i64, ptr addrspace(11) %sp.0, align 8
  %v3 = add i64 %sv.0, 0                               ; was argument %3 (n)
  br label %v4
v4:                                                    ; Mojo's entry block, still named %4
  %v5 = call i32 @llvm.spv.thread.id.in.group.i32(i32 0)
  %v6 = zext i32 %v5 to i64
  %v7 = call i32 @llvm.spv.group.id.i32(i32 0)
  %v8 = zext i32 %v7 to i64
  %v9 = add i32 0, 64                                  ; was sreg.ntid.x
  %v10 = sext i32 %v9 to i64
  %v11 = mul i64 %v8, %v10
  %v12 = add i64 %v11, %v6
  %v13.i32 = trunc i64 %v12 to i32
  %v13 = call ptr addrspace(11) @llvm.spv.resource.getpointer...(... %h.1, i32 %v13.i32)
  ...
  %v16 = icmp slt i64 %v12, %v3
  br i1 %v16, label %v17, label %v21

v17:                                                   ; preds = %v4
  %v18 = load float, ptr addrspace(11) %v14, align 4
  %v19 = load float, ptr addrspace(11) %v13, align 4
  %v20 = fadd contract float %v18, %v19
  store float %v20, ptr addrspace(11) %v15, align 4
  br label %v22
...
attributes #0 = { "hlsl.numthreads"="64,1,1" "hlsl.shader"="compute" }
```

Two details matter as soon as a kernel has more than one block:

- **Every value gets a name.** LLVM numbers unnamed values in order from `%0` within a function. The rewritten function loses its four arguments and gains a prologue, so the old numbers would no longer line up. The tool renames `%N` to `%vN` everywhere.
- **The entry block keeps its number.** Mojo's entry block has no label, so LLVM implicitly calls it `%<number of arguments>`, here `%4`. Phis refer to it: the loop kernel `vecadd4_gpu.mojo` has `phi i64 [ 0, %4 ], [ %20, %31 ]`. So the original body starts under a `v4:` label, after a new `entry:` block that holds the prologue.

[`ref/vecadd_vk.ll`](ref/vecadd_vk.ll) is the same shader written by hand, a reference for the IR the SPIR-V backend accepts. One finding from it: passing `ptr null` as the resource name crashes LLVM 22's instruction selector. A name string per buffer (`@.buf0` above) works. It adds the `Int8` capability, which both drivers support.

### The stock driver: SPIR-V 1.4 and no int64

Qualcomm's own Vulkan driver on this phone is Vulkan 1.1 with `shaderInt64=0`. Two flags handle it. `--vulkan 1.1` sets the triple to `spirv-unknown-vulkan1.1-compute`. LLVM 22's Vulkan output starts at SPIR-V 1.4, which the driver accepts through `VK_KHR_spirv_1_4`; SPIR-V 1.3 was not an option. `--i32` narrows every 64-bit integer to 32 bits, which is valid while every index and length fits in int32:

```python
def narrow_i64(body):
    body = re.sub(r"\bi64\b", "i32", body)
    body = re.sub(r"(%[\w.]+) = (?:zext|sext|trunc) (?:nneg )?i32 (%[\w.]+|-?\d+) to i32", r"\1 = add i32 \2, 0", body)
    return body
```

After narrowing, a `zext i32 to i64` would become `zext i32 to i32`, which is invalid IR, so casts between equal widths become copies. The diff against the Turnip shader is the triple, the params buffer and the index math:

```diff
-  %v6 = zext i32 %v5 to i64
+  %v6 = add i32 %v5, 0
...
-  %v12 = add i64 %v11, %v6
-  %v13.i32 = trunc i64 %v12 to i32
-  %v13 = call ptr addrspace(11) @llvm.spv.resource.getpointer...(... %h.1, i32 %v13.i32)
+  %v12 = add i32 %v11, %v6
+  %v13 = call ptr addrspace(11) @llvm.spv.resource.getpointer...(... %h.1, i32 %v12)
```

## Step 4: OpenCL, by translating IR to C

Qualcomm ships OpenCL 3.0 on this phone, and the obvious route is SPIR-V through `clCreateProgramWithIL`. [`probes/cl_probe.c`](probes/cl_probe.c) shows why that fails. The symbol exists, but the device reports an empty `CL_DEVICE_IL_VERSION` and no `cl_khr_il_program`:

```
platform: QUALCOMM Snapdragon(TM)
  version   : OpenCL 3.0 Adreno(TM) 710
  opencl_c  : OpenCL C 3.0 Adreno(TM) 710
  il_version:
```

Calling it anyway with a valid OpenCL SPIR-V module returns `-59`, `CL_INVALID_OPERATION`. The driver does compile OpenCL C, so [`mojo2cl.py`](mojo2cl.py) translates the kernel IR into OpenCL C. It uses one C variable per SSA value and one label per basic block. Each phi becomes assignments on its incoming edges, followed by a `goto`:

```python
def emit_edge(src, dst):
    return [f"{d} = {v};" for d, v in phis.get((src, dst), [])] + [f"goto L_{dst.replace('.', '_')};"]
```

Pointers are carried as `__global uchar*` and offset in bytes, so typed GEPs and Mojo's byte (`i8`) GEPs translate the same way. Loads and stores cast to the element type. The NVPTX registers map to `get_local_id`, `get_group_id`, `get_local_size` and `get_num_groups`. The output for `vecadd`:

```c
// generated by mojo2cl.py from Mojo kernel @vecadd_gpu_vecadd_Pointer_Tru6A6AoA6A6AcB_c9ef990b2741a7d7
__kernel void vecadd(__global uchar* v_0, __global uchar* v_1, __global uchar* v_2, long v_3) {
  ...
L_4:;
  v_5 = (int)get_local_id(0);
  v_6 = (long)(uint)v_5;
  v_7 = (int)get_group_id(0);
  v_8 = (long)(uint)v_7;
  v_9 = (int)get_local_size(0);
  v_10 = (long)v_9;
  v_11 = v_8 * v_10;
  v_12 = v_11 + v_6;
  v_13 = v_1 + (v_12) * 4;
  v_14 = v_0 + (v_12) * 4;
  v_15 = v_2 + (v_12) * 4;
  v_16 = v_12 < v_3;
  if (v_16) { goto L_17; } else { goto L_21; }
L_17:;
  v_18 = *(__global float*)(v_14);
  v_19 = *(__global float*)(v_13);
  v_20 = v_18 + v_19;
  *(__global float*)(v_15) = v_20;
  goto L_22;
...
```

It reads like a compiler's output because it is one. Qualcomm's compiler builds it on the phone in about 35 ms.

## Step 5: The CPU path

Mojo can cross-compile host code, so the CPU path needs no retargeting. A C-ABI export in [`src/vecadd_cpu.mojo`](src/vecadd_cpu.mojo) is built as an Android object and linked by the NDK with a small `main`, [`runner/cpu_main.c`](runner/cpu_main.c):

```bash
.venv-mojo/bin/mojo build --emit object --target-triple aarch64-unknown-linux-android34 --target-cpu cortex-a78 \
    -o build/vecadd_cpu.o src/vecadd_cpu.mojo
TC=$ANDROID_NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin
$TC/aarch64-linux-android34-clang -O2 -o build/mojo_cpu_vecadd runner/cpu_main.c build/vecadd_cpu.o
```

## Step 6: Runners on the phone, and one command for all of it

Two small C runners do the phone side. [`runner/vk_run.c`](runner/vk_run.c) is 234 lines and [`runner/cl_run.c`](runner/cl_run.c) is 128. Each loads `libvulkan.so` or `libOpenCL.so` with `dlopen`, so `LD_LIBRARY_PATH` picks Turnip or the stock driver. The NDK has no OpenCL headers, so `cl_run.c` declares the 14 entry points it needs itself. Both fill A[i] = i and B[i] = 2i, poison C with NaN, dispatch once and check every element. The bindings match what `mojo2vk.py` assigns: 0 = A, 1 = B, 2 = C, 3 = params.

[`mojo_adreno.py`](mojo_adreno.py) runs the whole pipeline. It builds the runners with the NDK, gets the kernel sidecar from Mojo, retargets it per backend, pushes and runs:

```python
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
```

## Results: four backends, two kernels, zero mismatches

Re-run on October 24, 2026 with n = 1,000,003, which is not a multiple of the workgroup size, so the bound check matters:

| backend | path | `vecadd_gpu.mojo` | `vecadd4_gpu.mojo` (loop) |
| --- | --- | --- | --- |
| `turnip` | `mojo2vk.py` → SPIR-V 1.6 → Mesa Turnip, Vulkan 1.4 device | PASS, 0 mismatches | PASS, 0 mismatches |
| `stock` | `mojo2vk.py --i32 --vulkan 1.1` → SPIR-V 1.4 → Qualcomm Vulkan 1.1 | PASS, 0 mismatches | PASS, 0 mismatches |
| `opencl` | `mojo2cl.py` → OpenCL C → Qualcomm OpenCL 3.0 | PASS, 0 mismatches | PASS, 0 mismatches |
| `cpu` | `mojo build --emit object` for aarch64 Android → NDK link | PASS, 0 mismatches | (CPU path is the same `vecadd_cpu.mojo`) |

`vecadd4_gpu.mojo` makes each thread add four consecutive elements in a loop with a bound check per element. Its IR has a loop, a phi and nine basic blocks, so it exercises the entry-block naming and the phi edges that `vecadd` does not.

A third kernel skips MAX and reads the SPIR-V builtin directly: `llvm_intrinsic["llvm.spv.thread.id", Int32](Int32(0))` in [`src/vecadd_spv.mojo`](src/vecadd_spv.mojo). It is compiled for the host target, not a GPU, and the intrinsic passes through Mojo untouched. Both retargeters accept that IR too, and it passes on Turnip and on OpenCL.

The runners also print wall-clock submit-and-wait time: 3.4 to 9.7 ms per run, for the 12 MB (three float arrays of 1M elements) each kernel moves. That is one cold dispatch per run, not a benchmark, and [Part 2](https://github.com/adityaGoCT/iree-adreno-genai-tuner/blob/main/BLOG-GEMM.md) showed how far one cold run on this phone can mislead.

## What did not work

| attempt | outcome |
| --- | --- |
| Mojo GPU target for Adreno / SPIR-V | none: accelerators are NVIDIA `sm_*`, AMD `gfx*`, Apple `apple-m*` only |
| OpenCL with SPIR-V IL (`clCreateProgramWithIL`) | `-59 CL_INVALID_OPERATION`: Qualcomm OpenCL 3.0 reports no IL version and no `cl_khr_il_program` (`probes/cl_probe.c`) |
| Running the kernel on the Mac's GPU for reference | needs Xcode's `metal` compiler (`xcrun metal` missing); not needed: the phone runners check every element |
| `ptr null` as the resource name in `handlefrombinding` | crashes LLVM 22's SPIR-V instruction selector; a name string per buffer works (adds the Int8 capability; both drivers have shaderInt8) |
| SPIR-V 1.3 for Vulkan 1.1 | LLVM 22's Vulkan output starts at SPIR-V 1.4; the stock driver accepts it via `VK_KHR_spirv_1_4` |
| Numbered entry block | Mojo's unlabeled entry block is `%<#args>`; phis name it, so retargeted bodies keep that label |
| `uv pip install mojo` / `max` | hung after downloading twice; a clean retry (`-v`) installed both |

## Limits

The retargeters cover the instruction subset of simple kernels: integer and float arithmetic, compares, casts, GEP, load and store, branches, phis. Not yet covered: shared memory, barriers, atomics, subgroup operations, `nctaid` and grid-stride loops (in the Vulkan path), element types other than float in the runners, and timing beyond wall-clock submit-and-wait. The pipeline also launches one thread per element whatever the kernel does. `vecadd4` is correct with that grid, but three quarters of its threads exit at the bound check.

## Reproduce it

```bash
scripts/setup.sh                      # LLVM, spirv-tools, NDK, adb, .venv-mojo (Mojo 1.2.0 + MAX 26.7.0)
export ANDROID_SERIAL=<phone ip>:5555  # adb devices
python3 mojo_adreno.py src/vecadd_gpu.mojo
python3 mojo_adreno.py src/vecadd4_gpu.mojo
python3 mojo_adreno.py src/vecadd_gpu.mojo --backend turnip   # one backend (needs Turnip on the phone)
```

Outputs, including the intermediate `*.vk.ll` and `vecadd.cl`, land in `build/`.

## What's next

- **Shared memory and barriers** in both retargeters (`addrspace(3)` to `Workgroup` storage, `llvm.nvvm.barrier0` to a control barrier), the minimum for a tiled kernel.
- **A Mojo GEMM** through the same path, timed with [Part 2](https://github.com/adityaGoCT/iree-adreno-genai-tuner/blob/main/BLOG-GEMM.md)'s harness and compared with the tuned GLSL kernels.
- **Grid-from-kernel:** derive the dispatch size from the kernel's launch parameters instead of one thread per element.
