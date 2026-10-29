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

*Update, October 25:* the pipeline now compiles Mojo for an AMD GPU (`gfx90a`) instead of NVIDIA, so warp operations use 64 lanes like the Adreno's subgroups. It also runs LLVM's `opt -O3` on the kernel IR and maps warp shuffles. See [the update](#update-october-25-optimized-ir-and-a-better-proxy-target). A [second update](#update-october-25-later-shared-memory-and-barriers) adds shared memory and barriers, with a tiled SGEMM, and a [third](#update-october-25-third-register-tiling) adds register tiling: 66 GFLOP/s. A [fourth](#update-october-27-llama-32-1b-on-the-phone) runs Llama 3.2 1B on the phone with these kernels, at 3.5 tokens/s on both drivers.

*Update, October 28:* Mojo's compiler is open source now, so I also added a native `adreno710` Vulkan target to it, with no retargeter ([branch `adreno-spirv-target`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target); results in [the README](README.md#native-spir-v-target)). A 27-slide presentation with speaker notes covers the whole experiment: [view it online](https://claude.ai/artifact/9HodHBDh22HuBYoo5UxTN6), or as a [PDF](docs/presentation/mojo-and-max-on-adreno.pdf).

*Update, October 29:* [Part 4](BLOG-COOPMAT.md) covers that target in depth and adds the GPU's matrix units: KHR cooperative matrices from Mojo, run on a Snapdragon 8 Elite Gen 5 (Adreno 840), and Llama 3.2 1B's prompt processed on them, 28x faster than one token at a time.

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

Anything else target-specific (`@llvm.nvvm.*`, `@llvm.amdgcn.*`) or any call to a non-intrinsic function stops the tool with an error rather than producing a wrong shader. Then `llc -O2 -filetype=obj` writes SPIR-V and `spirv-val` checks it. Since the [update](#update-october-25-optimized-ir-and-a-better-proxy-target), `opt -O3` runs first.

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
elif backend == "opencl":
    cl = build / "vecadd.cl"
    sh(sys.executable, HERE / "mojo2cl.py", ir, "--name", "vecadd", "--local", str(local), "-o", cl)
    adb("push", cl, f"{DEV}/")
    r = adb("shell", f"cd {DEV} && {env}./cl_run src {cl.name} vecadd {n} {local} {groups}")
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

## Update, October 25: optimized IR and a better proxy target

Two questions came up after the first version. Does retargeting from LLVM IR lose Mojo's optimizations? And could the pipeline start earlier, from Mojo's own MLIR dialects (KGEN, POP, LIT), and lower those to SPIR-V? Checking both changed the default target.

### The sidecar is unoptimized, and `opt -O3` restores the missing passes

`mojo build --help` describes the output this pipeline takes:

```
llvm (amdgpu, host, metal, nvptx)  - unoptimized LLVM IR; GPU targets also emit one IR sidecar file per kernel
```

The sidecar comes after Mojo's own stage: comptime parameters are resolved, generics specialized and calls inlined. But it comes before LLVM's optimization pipeline. Its empty blocks give it away: block `21` of `vecadd` holds only `br label %22`, which LLVM's `simplifycfg` would have removed. So [`mojo2vk.py`](mojo2vk.py) now runs `opt -O3` (at first on the retargeted Vulkan IR before `llc`; since the [second update](#update-october-25-later-shared-memory-and-barriers), on the kernel IR before retargeting). It fully unrolls the four-iteration loop of `vecadd4`, and the result passes `spirv-val` and the phone.

It bought no measurable speed on these kernels. Over 15 interleaved rounds, `vecadd4` on the stock driver took 6.05 ms at best without `opt` and 6.27 ms with it; Turnip was too noisy to call. These kernels are bound by memory, and the drivers' own compilers optimize the SPIR-V again. One catch: `opt` forms `llvm.usub.sat`, which LLVM 22's SPIR-V backend cannot select, so a small legalize step expands it to a compare and a select.

### Mojo's MLIR is not reachable

- `--emit` offers `llvm`, `asm`, `object`, `air` and executables; there is no MLIR output.
- MLIR's `print-ir-after-all` family is compiled into the `mojo` binary, but nothing on the command line passes it through. `MODULAR_DEBUG` accepts only runtime `max-debug.*` options.
- The binary holds about 100 op names each for `kgen.*`, `pop.*` and `lit.*`. None are documented, and they can change with every release.
- Mojo links LLVM's NVPTX, AMDGPU, AArch64 and X86 backends, and no SPIR-V backend.

KGEN also sits before comptime evaluation, so lowering from it would mean re-implementing much of Mojo's front end. An MLIR-level path would help with Vulkan's structured control flow and logical addressing, but it has to come from Modular as a real target.

### What the NVIDIA build really costs: `WARP_SIZE`

Compiling for `sm_80` bakes NVIDIA's warp width into the kernel. A kernel that stores `WARP_SIZE` shows it in the IR:

| `--target-accelerator` | kernel IR |
| --- | --- |
| `sm_80` | `store i32 32` |
| `gfx90a` | `store i32 64` |
| `apple-m1` | `store i32 32` |

The runner now prints the device's subgroup size: 64 on the stock driver, 128 on Turnip. AMD's CDNA2 (`gfx90a`) matches the stock driver's 64, so it is now the default: `mojo_adreno.py --accel gfx90a`, with `--accel sm_80` still available.

### AMD as the proxy target

The AMD sidecar differs from the NVIDIA one in two places. Thread and workgroup ids are `llvm.amdgcn.workitem.id` and `workgroup.id`. The block size is not a register but a 16-bit load at byte 12 of `llvm.amdgcn.implicitarg.ptr`, which the retargeters fold to the workgroup size. Warp operations differ more. For MAX's `warp.sum` in [`src/warpsum_gpu.mojo`](src/warpsum_gpu.mojo), `sm_80` emits five `shfl.sync.bfly` calls with clamp 31, so it reduces within 32-lane segments. `gfx90a` emits four DPP moves and then two `ds.bpermute` hops across the 64-lane wave:

```llvm
  %17 = call i32 @llvm.amdgcn.update.dpp.i32(i32 0, i32 %16, i32 177, i32 15, i32 15, i1 true)   ; quad_perm [1,0,3,2]
  ...
  %32 = call i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0)
  %33 = call i32 @llvm.amdgcn.mbcnt.hi(i32 -1, i32 %32)                                      ; lane in the wave
  %34 = xor i32 %33, 16
  ...
  %41 = call i32 @llvm.amdgcn.ds.bpermute(i32 %39, i32 %40)                                  ; read lane %39 / 4
```

Every one of these is a read from another lane, so on Vulkan each becomes `llvm.spv.wave.readlane`, which LLVM lowers to `OpGroupNonUniformShuffle`. The source lane is computed per instruction: the DPP pattern decoded (`quad_perm`, `row_shl`/`row_shr`/`row_ror`, `row_mirror`, `row_half_mirror`), `mbcnt` turned into the lane within its 64-lane wave, and `ds.bpermute`'s byte address turned into a lane of the same wave:

```python
out += [lane(res), f"  {res}.base = and i32 {res}.lane, -64", f"  {res}.w = lshr i32 {addr}, 2",
        f"  {res}.wi = and i32 {res}.w, 63", f"  {res}.src = or i32 {res}.base, {res}.wi", readlane(res, "i32", val, f"{res}.src")]
```

Keeping each shuffle inside its aligned 64-lane wave (32-lane segment for NVPTX) makes the mapping correct for any hardware subgroup that is a multiple of the warp width, which covers Turnip's 128 as well. OpenCL has no general shuffle on this phone: Qualcomm offers `cl_khr_subgroups` and the vendor `cl_qcom_subgroup_shuffle`. So [`mojo2cl.py`](mojo2cl.py) runs warp ops on a virtual subgroup whose lanes are local ids, passing each value through `__local` memory:

```python
return [f"_shf[_lane] = as_uint({v});", "barrier(CLK_LOCAL_MEM_FENCE);",
        f"{dst} = as_{CTYPE[ty]}(_shf[{src}]);", "barrier(CLK_LOCAL_MEM_FENCE);"]
```

The runners check the result against the warp width of the target, and against the other target's width as a control. n = 1,000,003, A[i] + B[i] = 3i:

| kernel IR | checked as 32-lane sums | checked as 64-lane sums |
| --- | --- | --- |
| `gfx90a` | 1,000,000 mismatches on all three GPU backends | **0** on turnip, stock and opencl |
| `sm_80` | **0** on turnip, stock and opencl | 1,000,000 mismatches on all three |

The 3 elements that agree are the last, partial group. `vecadd` and `vecadd4` also pass through `gfx90a` on all four backends.

So the NVIDIA build was not wrong. Mapped to 32-lane segments, it treats each 64-lane subgroup as two warps, and its warp-level work covers half of the hardware. The AMD build matches the stock driver's subgroup. Neither helps kernels that branch on the vendor (`is_nvidia_gpu()`, `is_amd_gpu()`) to use matrix-core or async-copy intrinsics: those have no SPIR-V counterpart, and the retargeters stop with an error.

## Update, October 25 (later): shared memory and barriers

A tiled kernel needs two things the retargeters did not have: memory shared by a workgroup, and barriers. [`src/matmul_tiled_gpu.mojo`](src/matmul_tiled_gpu.mojo) is the textbook SGEMM: each 256-thread workgroup computes one 16 × 16 tile of C and stages tiles of A and B through shared memory.

```mojo
    var sa = stack_allocation[TILE * TILE, Float32, address_space=AddressSpace.SHARED]()
    var sb = stack_allocation[TILE * TILE, Float32, address_space=AddressSpace.SHARED]()
    ...
    for k0 in range(0, dim, TILE):
        sa[t] = a[row * dim + k0 + tx]
        sb[t] = b[(k0 + ty) * dim + col]
        barrier()
        for k in range(TILE):
            acc += sa[ty * TILE + k] * sb[k * TILE + tx]
        barrier()
    c[row * dim + col] = acc
```

In the IR, each shared buffer is a module-level `addrspace(3)` array indexed with ordinary GEPs. `barrier()` depends on the target:

```llvm
@..._global_alloc_0._gpu_shared_mem = internal addrspace(3) global [256 x float] undef, align 4
  call void @llvm.nvvm.barrier.cta.sync.aligned.all(i32 0)          ; sm_80
  fence syncscope("workgroup") release                              ; gfx90a
  call void @llvm.amdgcn.s.barrier()
  fence syncscope("workgroup") acquire
```

Both map cleanly. On Vulkan a shared array becomes a `Workgroup` variable and the barrier becomes `OpControlBarrier`. On OpenCL they become a `__local` array and `barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE)`. Getting LLVM 22 to produce valid SPIR-V for that took four fixes.

**Clean up Mojo's IR first.** The strided `range(0, dim, TILE)` loop compiles to unoptimized IR full of iterator machinery: private `alloca`s, `addrspacecast`s to generic pointers, `Optional` aggregates built with `insertvalue`, `llvm.lifetime` markers. SROA and instcombine remove all of it, so the kernel IR now goes through `opt` first. The triple is removed for that step, which keeps it target-neutral. Homebrew's LLVM 22 also cannot parse Mojo's `amdgpu9.0a` triple spelling.

**Run `opt -O3` before retargeting, not after.** After retargeting, `opt -O3` rebuilt the shared-array accesses as byte-offset chains (`getelementptr i8, ptr addrspace(3) %1, i64 4`), which Vulkan's logical addressing cannot express. Run before retargeting, it optimizes raw pointer arithmetic that the retargeter then folds: every pointer is tracked as (buffer or shared array, element index) through GEP chains.

```python
if bidx is not None:  # GEP chain: offsets add up
    out.append(f"  {res}.ix = add i32 {bidx}, {idx}")
    idx = f"{res}.ix"
ptrs[res] = (k, idx)
if k in shared:
    out.append(f"  {res} = getelementptr inbounds [{shared[k][0]} x {e}], ptr addrspace(3) {k}, i32 0, i32 {idx}")
```

**Disable loop strength reduction in `llc`.** A shared-array load inside a loop crashed the SPIR-V backend in `SPIRVLegalizePointerCast`. I narrowed it with hand-written shaders: straight-line loads and storage-buffer loads in loops were fine, and only a shared-array index that comes from a loop phi crashed. `or i32 %i, 0` on the index avoided the crash where `add i32 %i, 0` did not. That pointed at LSR, which sees through `add`: it turns the index into a pointer induction variable, a pointer phi that logical addressing cannot express. `llc -disable-lsr` fixes it.

**Patch the barrier's memory semantics.** LLVM 22's only barrier intrinsic, `llvm.spv.group.memory.barrier.with.group.sync`, lowers to `OpControlBarrier Workgroup Workgroup SequentiallyConsistent` with no storage class, and spirv-val rejects that for Vulkan (VUID-10866). The OpenCL builtin `__spirv_ControlBarrier` is not recognized in the Vulkan environment. So `mojo2vk.py` disassembles the module, swaps in AcquireRelease | UniformMemory | WorkgroupMemory (328), and reassembles:

```python
for line in dis.splitlines():
    line = re.sub(r"^(\s*OpControlBarrier %\S+ %\S+) %\S+\s*$", rf"\1 {sem}", line)
    out.append(line)
    if re.match(r"\s*%uint = OpTypeInt 32 0\s*$", line):
        out.append(f"{sem} = OpConstant %uint 328")
```

Like `__syncthreads()`, the barrier then orders global memory as well as shared memory. On the stock driver it costs nothing over WorkgroupMemory alone: 293.4 ms against 294.5 ms.

### Results

Three new kernels join the earlier ones:
- `blocksum_gpu`: a shared-memory tree reduction per 64-thread block.
- `matmul_naive_gpu`: the same SGEMM reading only from global memory.
- `matmul_tiled_gpu`: the tiled SGEMM above.

The SGEMM inputs are small integers (A[i] = i mod 7 − 3, B[i] = i mod 5 − 2), so every one of the 1,048,576 outputs of a 1024³ product must match a double-precision reference exactly. All six GPU kernels pass on turnip, stock and opencl, for both `--accel gfx90a` and `--accel sm_80`: 36 combinations, 0 mismatches. As a control, I removed the barriers from the tiled SGEMM and about 99.5% of its outputs came out wrong on all three backends.

Timing the two SGEMMs (best of 10 dispatches, 3 interleaved rounds, wall clock):

| backend | `matmul_naive_gpu` | `matmul_tiled_gpu` |
| --- | --- | --- |
| turnip | 669 ms (3.2 GFLOP/s); 409 ms with `--int32` | 232 ms (9.2 GFLOP/s) |
| stock | 200 ms (10.7 GFLOP/s) | 293 ms (7.3 GFLOP/s) |
| opencl | 409 ms (5.2 GFLOP/s) | 397 ms (5.4 GFLOP/s) |

Tiling makes the kernel 2.9x faster on Turnip, but not on Qualcomm's own compilers, which run the naive kernel well. With one output per thread the tiled kernel does two shared-memory loads per FMA, and all of these are a long way from the 368 GFLOP/s fp32 peak measured in Part 2. Register tiling, several outputs per thread as in Part 2's schedules, is what the next kernel needs.

One more lesson: Mojo's `Int` is 64-bit, and the Adreno has no native 64-bit integers. The stock path always narrows to int32. On Turnip the new `--int32` flag does the same and makes the naive SGEMM 1.6x faster; it is opt-in because it is only safe for kernels without 64-bit data.

### fp16 tiles, and a stock-driver bug

Shared memory can hold fp16 too. [`src/matmul_tiled_f16_gpu.mojo`](src/matmul_tiled_f16_gpu.mojo) keeps the A and B tiles as `Float16`, multiplies in fp16 and accumulates in fp32. Global inputs and the output stay fp32, so the runners need no changes. Workgroup memory of 16-bit type needs only `shaderFloat16`, which both drivers have; the 16-bit storage features cover buffers.

Turnip and OpenCL got it right the first time. The stock driver got 1,041,577 of 1,048,576 outputs wrong, and the identical SPIR-V passed on Turnip. A minimal kernel narrowed it down. It stores two 256-element `half` shared arrays and reads its own elements back, and on the stock driver 1,024 of 2,048 results come out wrong. The pairing is `sa[128 + j]` with `sb[j]`: the two arrays overlap. A single array is fine, and so is padding each array to 512 elements. So `mojo2vk.py --pad-shared` gives every 8- or 16-bit shared array 4 bytes per element, and `mojo_adreno.py` uses it for the stock backend:

```python
size = int(n) * max(1, 4 // SIZE[t]) if pad_shared and t in SIZE else int(n)
```

| backend | fp32 tiles | fp16 tiles |
| --- | --- | --- |
| turnip | 233 ms | 213 ms |
| stock | 293 ms | 293 ms (padded) |
| opencl | 396 ms | 343 ms |

fp16 tiles help a little, by 9% on Turnip and 14% on OpenCL. This kernel is bound by how many shared-memory loads it issues per FMA, not by their size. fp16 pays off with more outputs per thread and packed `half2` math, which is the register-tiling step.

## Update, October 25 (third): register tiling

The tiled SGEMM did two shared-memory loads per FMA. Register tiling gives each thread a block of C to keep in registers: per k step it loads TM values of A and TN of B and does TM × TN FMAs. [`src/matmul_regtile_gpu.mojo`](src/matmul_regtile_gpu.mojo) makes the tile sizes and the thread mapping compile-time constants. With 8 × 8 per thread, a step costs 16 loads for 64 FMAs:

```mojo
    var acc = stack_allocation[TM * TN, Float32]()  # registers once SROA has run
    ...
        for k in range(BK):
            comptime for i in range(TM):
                af[i] = As[k * BM + ty * VM + offm(i)]
            comptime for j in range(TN):
                bf[j] = Bs[k * BN + tx * VN + offn(j)]
            comptime for i in range(TM):
                comptime for j in range(TN):
                    acc[i * TN + j] += af[i] * bf[j]
```

`comptime for` unrolls at compile time, so every index into `acc`, `af` and `bf` is a constant and SROA turns the arrays into registers. `InlineArray` would be the obvious type, but it cannot be imported from `std.collections` in Mojo 1.2. Each thread now writes 64 outputs, so a kernel's marker line can say `outputs=64` and `mojo_adreno.py` launches n / (256 × 64) workgroups.

The first build failed in `llc` with "unable to legalize" on a 16-value instruction. The target-neutral `opt -O3` had SLP-vectorized the outer product into `<16 x float>` math, and Vulkan vectors stop at four lanes. The drivers vectorize for the real hardware anyway, so the vectorizers are now off in that step.

Then I swept five settings of the constants. All of them are correct on all three backends (1024³, best of 10 dispatches, 3 interleaved rounds):

| variant | workgroup tile, BK | per thread | mapping | turnip | stock | opencl |
| --- | --- | --- | --- | --- | --- | --- |
| A | 64², 16 | 4 × 4 | contiguous | 46.5 ms | 117 ms | 111 ms |
| C | 128², 8 | 8 × 8 | strided | 52.8 ms | **56.0 ms** | **57.9 ms** |
| E | 128², 16 | 8 × 8 | contiguous | 35.3 ms | 91.7 ms | 87.3 ms |
| F | 128², 16 | 8 × 8 | chunks of 4, strided | 32.8 ms | 66.6 ms | 65.6 ms |
| G | 128², 8 | 8 × 8 | chunks of 4, strided | **32.5 ms** | 65.7 ms | 67.0 ms |

The drivers disagree. Mesa's compiler merges a thread's consecutive shared-memory loads into vector loads, so it wants contiguous rows and columns. Qualcomm's two compilers do best when neighbouring threads take neighbouring columns (strided, variant C). Chunks of 4, strided across the tile, are the compromise. G is the committed default: 66 GFLOP/s on Turnip, within 15% of the best on the stock driver and on OpenCL.

The index form mattered as much as the mapping. My first version of the mapping computed each thread's row as a helper, `ty * VM + offm(i)`, and then added `k * BM`. `opt` hoisted the four row offsets out of the k loop as separate registers, Mesa no longer saw consecutive addresses, and the same configuration ran 2.4x slower on Turnip (110 ms instead of 46 ms). The fix is to write `k * BM + ty * VM + offm(i)`: a runtime base first, then a compile-time constant. `opt` keeps that as one base pointer plus constant offsets:

```llvm
  %139 = load float, ptr addrspace(3) %138, align 4
  %140 = getelementptr inbounds nuw i8, ptr addrspace(3) %138, i32 4
  %141 = load float, ptr addrspace(3) %140, align 4
```

Against the earlier fp32 kernels:

| backend | naive | tiled, 1 output per thread | register-tiled (G) |
| --- | --- | --- | --- |
| turnip | 669 ms | 233 ms | 32.5 ms (66 GFLOP/s) |
| stock | 200 ms | 293 ms | 65.7 ms (33 GFLOP/s) |
| opencl | 409 ms | 396 ms | 67.0 ms (32 GFLOP/s) |

That is 4.5 to 7.2x over the tiled kernel. `--int32` no longer matters, because the index math is spread over 64 FMAs. 66 GFLOP/s is still only 18% of the 368 GFLOP/s fp32 peak from Part 2. The rest is the same ground Part 2 covered for fp16: vectorized global loads, double buffering, `half2` math, and a tuner that picks the constants per driver.

## Update, October 27: Llama 3.2 1B on the phone

The kernels so far were benchmarks. [`llama/`](llama/README.md) puts them to work: Meta's Llama-3.2-1B-Instruct generating text on the Adreno 710, with every GPU kernel written in Mojo and compiled through this pipeline.

MAX's graph compiler and runtime have no Android build and no SPIR-V output, so MAX cannot run a model on this phone by itself. The demo keeps Mojo and MAX's `gpu` module for the part that reaches the device, the kernels, and replaces the rest. Seven Mojo kernels cover decode: embedding, RMSNorm, fp16-weight GEMV (plain and with the residual add), RoPE with the KV-cache write, grouped-query attention, and SiLU-multiply. [`llama/llama_vk.c`](llama/llama_vk.c) is a small Vulkan program on the phone. It loads the fp16 weights, with the embedding split into 125 MB chunks because the stock driver binds at most 128 MB per buffer, and pre-records the 150 dispatches of one token. Then it runs the prompt and decodes greedily. [`llama/run.py`](llama/run.py) on the Mac exports the weights, runs PyTorch on the same fp16-rounded weights as the reference, builds, pushes, and compares:

```
  prompt: 46 tokens in 11457 ms
The sky appears blue because of a phenomenon called Rayleigh scattering, in which shorter wavelengths
of light, such as blue and violet, are scattered more than longer wavelengths, like red and orange,
by the tiny molecules of gases in the atmosphere.
  decode: 47 tokens, 285.3 ms/token (3.50 tokens/s)

logits after the prompt: max |phone - PyTorch| = 6.20e-05 (logit range -7.1 .. 27.0)
tokens: phone 48, PyTorch 48, identical for the first 48
```

That is the stock Qualcomm driver; Mesa Turnip runs at the same speed, 282 ms per token. Both are at 55% of the DRAM bandwidth limit for reading 2.47 GB of weights per token.

The stock driver did not start there. Its first run took 1,392 ms per token, with the GEMVs at a third of Turnip's speed, and packed 32-bit loads or four rows per workgroup changed nothing. The question was whether the driver or the route through LLVM IR was to blame, so I wrote the same GEMV in GLSL, compiled it with `glslc`, and swapped it in ([`llama/ab/`](llama/ab/)). Per dispatch of the 64 MB gate/up GEMV on the stock driver:

| variant | ms | result |
| --- | --- | --- |
| Mojo route, warp sum as 6 generic subgroup shuffles | 46.5 | correct |
| GLSL, 6 generic `subgroupShuffle` | 45.6 | correct |
| GLSL, 6 `subgroupShuffleXor` | 14.6 | wrong |
| GLSL, `subgroupAdd` | 13.7 | correct |
| Mojo route, warp sum as one `OpGroupNonUniformFAdd` | 14.7 | correct |

The route was to blame, and specifically one lowering. LLVM 22's SPIR-V backend has a single shuffle intrinsic, `llvm.spv.wave.readlane`, which becomes a generic `OpGroupNonUniformShuffle`, and Qualcomm's compiler runs generic shuffles slowly. The xor form is fast but wrong there, because the driver does not reconverge a subgroup after a loop and offers no extension that would make it. A native reduction is both fast and correct. So `mojo2vk.py` now recognizes Mojo's warp sum, the six butterfly steps of DPP moves and `ds.bpermute` hops each followed by an add, and emits one `llvm.spv.wave.reduce.sum` when the workgroup has at most 64 threads. Decode went from 1,392 to 285 ms per token, and all 48 kernel builds stay exact.

Getting there surfaced four more problems in the pipeline, beyond the shuffle lowering:

- **Float literals.** Mojo's LLVM prints `f0x3FB8AA3B` and `-1.000000e+30`, and LLVM 22 rejects both. `mojo2vk.py` now rewrites them, and maps Mojo's AMD `exp` and `rsqrt` intrinsics to portable ones.
- **Narrowing to int32.** The stock path's int32 narrowing clamped a bit mask, `0x7FFFFFFE00` from Mojo's index arithmetic, to `INT32_MAX`. Attention then read the wrong KV-cache slots. Constants now wrap in bitwise and wrapping arithmetic, and are clamped only in compares, selects and min/max.
- **Reconvergence.** On the stock driver attention first hung: the GPU was declared lost after 4 to 12 s. The threads ran different numbers of score-loop iterations right before the warp shuffles. With the same trip count for every thread it no longer hung, but came out exactly 64 times too small. The shuffles read inactive lanes and returned each lane's own value, and six doublings make 64. Vulkan does not promise that a subgroup reconverges after divergent control flow, so attention now reduces through shared memory with barriers.
- **Structured control flow.** An `if / elif / elif` whose branches share one exit produced invalid structured control flow from LLVM 22. `rope_kv` became a single `if / else`.

## What did not work

| attempt | outcome |
| --- | --- |
| Mojo GPU target for Adreno / SPIR-V | none: accelerators are NVIDIA `sm_*`, AMD `gfx*`, Apple `apple-m*` only |
| OpenCL with SPIR-V IL (`clCreateProgramWithIL`) | `-59 CL_INVALID_OPERATION`: Qualcomm OpenCL 3.0 reports no IL version and no `cl_khr_il_program` (`probes/cl_probe.c`) |
| Running the kernel on the Mac's GPU for reference | needs Xcode's `metal` compiler (`xcrun metal` missing); not needed: the phone runners check every element |
| `ptr null` as the resource name in `handlefrombinding` | crashes LLVM 22's SPIR-V instruction selector; a name string per buffer works (adds the Int8 capability; both drivers have shaderInt8) |
| SPIR-V 1.3 for Vulkan 1.1 | LLVM 22's Vulkan output starts at SPIR-V 1.4; the stock driver accepts it via `VK_KHR_spirv_1_4` |
| Numbered entry block | Mojo's unlabeled entry block is `%<#args>`; phis name it, so retargeted bodies keep that label |
| Lowering from Mojo's MLIR (KGEN / POP / LIT) | not exposed in 1.2 (no `--emit mlir`, MLIR print flags unreachable, `MODULAR_DEBUG` is runtime-only); undocumented dialects; no SPIR-V backend in Mojo |
| `opt -O3` output straight into `llc` | `llvm.usub.sat` cannot be selected by LLVM 22's SPIR-V backend; expanded to compare + select |
| LLVM 22's barrier intrinsic as is | SequentiallyConsistent semantics without a storage class: invalid in Vulkan; patched to 0x148 |
| `__spirv_ControlBarrier` in a Vulkan shader | not recognized for the Vulkan environment: an external function (`Linkage` capability) |
| Shared-array loads in loops with plain `llc` | loop strength reduction builds pointer induction variables; crash in `SPIRVLegalizePointerCast`; `-disable-lsr` |
| `opt -O3` after retargeting | rebuilds byte-offset GEP chains on shared arrays; `opt` now runs before retargeting |
| Two 16-bit shared arrays on the stock driver | they overlap (`a[N/2 + j]` aliases `b[j]`); identical SPIR-V passes on Turnip; `--pad-shared` |
| LLVM's vectorizers in the pre-retarget `opt` | SLP turns a register tile into `<16 x float>` math; Vulkan vectors stop at 4 lanes; vectorizers off |
| Register-tile indices computed as `ty * VM + i` first | `opt` hoists the row offsets as separate registers and Mesa no longer merges the loads: 2.4x slower on Turnip |
| Retargeting Mojo's IR without cleanup | strided `range()` loops leave allocas, `Optional` aggregates and lifetime markers; SROA + instcombine first |
| `uv pip install mojo` / `max` | hung after downloading twice; a clean retry (`-v`) installed both |

## Limits

The retargeters cover the instruction subset of simple kernels: integer and float arithmetic, compares, casts, min and max, GEP, load and store, branches and phis. Since the updates they also cover warp shuffles, static shared memory and barriers. Not yet covered: atomics, ballot and vote, dynamic shared memory, pointer phis or selects on Vulkan, multi-dimensional workgroups, element types other than float in the runners, and GPU timestamps. The pipeline also launches one thread per element whatever the kernel does. `vecadd4` is correct with that grid, but three quarters of its threads exit at the bound check.

## Reproduce it

```bash
scripts/setup.sh                      # LLVM, spirv-tools, NDK, adb, .venv-mojo (Mojo 1.2.0 + MAX 26.7.0)
export ANDROID_SERIAL=<phone ip>:5555  # adb devices
python3 mojo_adreno.py src/vecadd_gpu.mojo
python3 mojo_adreno.py src/vecadd4_gpu.mojo
python3 mojo_adreno.py src/warpsum_gpu.mojo                   # MAX warp.sum, 64-lane warps (gfx90a)
python3 mojo_adreno.py src/warpsum_gpu.mojo --accel sm_80     # the same from the NVIDIA build, 32-lane warps
python3 mojo_adreno.py src/blocksum_gpu.mojo                  # shared memory + barriers
python3 mojo_adreno.py src/matmul_tiled_gpu.mojo --reps 10    # 1024^3 SGEMM, best of 10 dispatches
python3 mojo_adreno.py src/matmul_regtile_gpu.mojo --reps 10  # register-tiled: 8 x 8 outputs per thread
python3 mojo_adreno.py src/vecadd_gpu.mojo --backend turnip   # one backend (needs Turnip on the phone)
```

Outputs, including the intermediate `*.vk.ll` and `vecadd.cl`, land in `build/`.

## What's next

- **The rest of the SGEMM:** vectorized global loads, double buffering, `half2` math, GPU timestamps instead of wall-clock timing, and per-driver constants from a tuner.
- **A Mojo GEMM** through the same path, timed with [Part 2](https://github.com/adityaGoCT/iree-adreno-genai-tuner/blob/main/BLOG-GEMM.md)'s harness and compared with the tuned GLSL kernels.
- **Grid-from-kernel:** derive the dispatch size from the kernel's launch parameters instead of one thread per element.
