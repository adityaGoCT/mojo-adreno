# Mojo on Adreno, Part 4: A Native GPU Target, and Llama Prefill on the Matrix Units

*Part 4 of [Bringing PyTorch LLMs to a Mid-Range Adreno GPU with IREE](https://github.com/adityaGoCT/iree-adreno-genai-tuner/blob/main/BLOG.md) (Part 3: [Running Mojo GPU Kernels on an Adreno Phone GPU](BLOG.md)) · October 29, 2026 · Aditya*

## TL;DR

[Part 3](BLOG.md) got Mojo kernels onto an Adreno 710 by rewriting the LLVM IR that Mojo produces for an AMD GPU. Mojo's compiler has since been open sourced, so this part does it properly. I added a Vulkan SPIR-V target to the compiler, so `mojo build --target-accelerator adreno710` produces a Vulkan compute shader directly. On that target I taught Mojo the GPU's matrix hardware through Vulkan's cooperative-matrix extension. Then I ran Llama 3.2 1B's prompt processing on those matrix units, on a Snapdragon 8 Elite Gen 5 phone rented from a cloud test lab.

| | Adreno 710 (moto g stylus 5G) | Adreno 840 (Galaxy S26 Ultra) |
|---|---|---|
| Llama 3.2 1B decode | 285 ms/token | **41 ms/token** (24 tokens/s) |
| 431-token prompt, one token at a time | — | 17.7 s |
| 431-token prompt, batched on cooperative matrices | — | **0.63 s** (28x) |
| matmul on cooperative matrices, 2048³ | no matrix units | **3.7 TFLOP/s** fp16, **2.5 TFLOP/s** fp32 |
| tokens identical to PyTorch | 48 of 48 | 48 of 48 (logits within 6.0e-5) |
| decode with 4-bit weights | — | **13.4 ms/token** (75 tokens/s) |

*(The prefill numbers are from [the update](#update-faster-weight-staging-and-a-second-driver-build): 1.29 s with the first prefill matmul, 0.68 s with coalesced weight staging, 0.63 s with fused attention.)*

All of it is Mojo code, from the Llama kernels to the matmul that reaches 3.7 TFLOP/s. The compiler work is on the branch [`adreno-spirv-target`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target) of my fork of modular/modular. The kernels, runners and the Llama runtime are in [this repo](README.md).

What I learned:

1. **A GPU target is mostly an ABI.** The first version of the target was about 2,100 lines of C++ and 400 lines of Mojo. Most of that rewrites how a kernel receives its arguments. LLVM's SPIR-V backend does the instruction selection.
2. **New hardware features can travel as opaque calls.** Mojo has no type for "a matrix spread across a subgroup". A cooperative matrix travels as a 64-bit handle through calls to placeholder functions, which the backend rewrites late, once it knows each pointer's buffer.
3. **Ask the driver, not the reports.** The Adreno 840 offers only 64-row tiles and no fp16-to-fp32 products, and its fp16 shared memory has three quirks. Each turned up only by running small kernels on the phone. Public reports were right about the shapes and wrong about a crash.
4. **Prefill is where matrix units pay.** Decode reads every weight once per token, so it's limited by memory bandwidth. Prefill reuses each weight for every prompt token, so it's the workload matrix hardware is built for.

## 1. A Vulkan target inside Mojo's compiler

Part 3's retargeters (`mojo2vk.py`, `mojo2cl.py`) worked on text. They took the AMD build's kernel IR and rewrote its ABI with pattern matching, then ran LLVM's SPIR-V backend outside Mojo. The open-source compiler let me do the same work in-process, as a real target:

```bash
bazel-bin/Mojo/tools/mojo/mojo build --emit asm --target-accelerator adreno710 \
    -I bazel-bin/Mojo/stdlib/std -I bazel-bin/max/mojo/max -o host.s kernel.mojo
# -> one .spv per kernel, next to host.s
```

The target has five pieces ([ADRENO.md](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/ADRENO.md) has the full story):

| piece | what it does | code |
|---|---|---|
| Target identity | `adreno710` and `adreno840` with the triple `spirv1.6-unknown-vulkan1.3-compute`, 64-lane warps | [`Mojo/lib/Target/max_license/SPIRV/`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target/Mojo/lib/Target/max_license/SPIRV) |
| Lowering hooks | mark kernels, record block sizes | [`Mojo/lib/KGENToLLVM/Target/max_license/SPIRV/`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target/Mojo/lib/KGENToLLVM/Target/max_license/SPIRV) |
| Kernel ABI pass | turn a kernel into a Vulkan entry point (below) | [`VulkanKernelABI.cpp`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/Mojo/lib/Compiler/ObjectCompiler/Target/max_license/SPIRV/VulkanKernelABI.cpp) |
| stdlib and MAX plugins | SPIR-V builtins, GLSL.std.450 math, barrier, shuffles, a one-instruction warp sum | [`Mojo/stdlib/std/_plugin/spirv/`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target/Mojo/stdlib/std/_plugin/spirv), [`max/mojo/max/_plugin/spirv/`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target/max/mojo/max/_plugin/spirv) |
| LLVM | the SPIR-V backend in Mojo's LLVM build, a structurizer fix, cooperative matrices for Vulkan | [`bazel/public-patches/`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target/bazel/public-patches) |

A Vulkan compute shader takes no arguments; everything arrives through descriptor bindings. The kernel ABI pass bridges that gap:
- **Pointers and scalars:** the k-th pointer argument becomes the storage buffer at binding k, and the j-th scalar becomes 64-bit slot j of a parameters buffer.
- **Addresses:** logical SPIR-V has no pointer arithmetic, so every address is tracked as (buffer, element index).
- **Pointers that pick a buffer at run time:** concat's inputs, for example. A load reads every candidate and selects; a store branches.
- **Launch description:** each module carries one, as JSON in an `OpModuleProcessed` string. It records which binding and parameter slot each argument goes to, and whether the kernel reads or writes each buffer. A runtime lays out a launch from it, and drivers ignore it.

How it measured on the 710 with Mesa Turnip, against the Part 3 retargeter ([README](README.md#native-spir-v-target)):
- **Test kernels:** all eight pass. The native target is as fast or faster on each; block sum is 4.65 ms against 6.81, because the native `barrier()` orders shared memory only, as GLSL's does.
- **Llama 3.2 1B:** built natively, 48 of 48 tokens match PyTorch at 281 ms/token.

### MAX on the phone

MAX's own kernels compile for the target too. MAX's graph compiler has a compile-only virtual-device mode, and [`coverage.py`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/max/examples/vulkan_coverage/coverage.py) builds 26 test graphs with it. They range from elementwise ops to a full ResNet-18, and every one of the 216 kernels passes `spirv-val`.

MAX's runtime has no Android build, so it can't run on the phone. Two harnesses run its kernels there anyway:
- [`max_kernels/test_max_kernels.py`](max_kernels/test_max_kernels.py) lays out arguments from the launch descriptions and checks 43 kernels against NumPy.
- [`remote/`](remote) makes the phone a MAX device: a driver plugin forwards allocations and launches over `adb` to a Vulkan executor on the phone. ResNet-18 classifies an image in 8.3 s that way, all of it GPU time.

## 2. Cooperative matrices: matrix hardware from Mojo

The Adreno 710 has no matrix units. Newer Adrenos do, and Vulkan exposes them through [`VK_KHR_cooperative_matrix`](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_cooperative_matrix.html).

A cooperative matrix is a tile, for example 64×16, that a whole subgroup (64 threads on Adreno) loads, multiplies and stores together. The driver decides which thread holds which element. In SPIR-V it's a type, `OpTypeCooperativeMatrixKHR`, with five instructions: load, store, multiply-add, construct and convert.

Mojo can't name that type. So the Mojo side of the API is a struct holding a 64-bit handle, and each method calls a placeholder function ([`mma_spirv.mojo`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/max/mojo/max/gpu/compute/arch/mma_spirv.mojo)). This is a complete matrix multiply:

```mojo
from max.gpu.compute.arch.mma_spirv import CoopMatrix, MATRIX_A, MATRIX_B, ACCUMULATOR

var acc = CoopMatrix[DType.float32, 64, 64, ACCUMULATOR].zero()
for k in range(0, K, 8):
    var a_tile = CoopMatrix[DType.float32, 64, 8, MATRIX_A].load(a.unsafe_offset(row * K + k), K)
    var b_tile = CoopMatrix[DType.float32, 8, 64, MATRIX_B].load(b.unsafe_offset(k * N + col), N)
    acc = a_tile.multiply_add(b_tile, acc)
acc.store(c.unsafe_offset(row * N + col), N)
```

`load` becomes `external_call["__mojo_spirv_coopmat_load"]`. Its arguments are the pointer, the stride, the layout, and the element type, rows, columns and use as constants. Calls to unknown functions are opaque to LLVM's optimizer, so they survive to the backend untouched. The matrix in the K loop is just an `i64` phi.

Three layers then turn the calls into SPIR-V:
1. **The kernel ABI pass** ([`VulkanKernelABI.cpp`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/Mojo/lib/Compiler/ObjectCompiler/Target/max_license/SPIRV/VulkanKernelABI.cpp), `lowerCooperativeMatrices`). It already knows which buffer and element every pointer reaches, which is what a matrix load needs. It gives every handle its matrix type: from the constants of a load or zero, from the accumulator of a multiply-add, and from any incoming value of a phi. It then rewrites the placeholders into LLVM's `__spirv_CooperativeMatrix*KHR` builtins and switches the module to the Vulkan memory model, which the extension requires. Each builtin's result type comes from its declaration, so each signature gets its own mangled name.
2. **A 14-line LLVM patch** ([`llvm-spirv-cooperative-matrix-vulkan.patch`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/bazel/public-patches/llvm-spirv-cooperative-matrix-vulkan.patch)). LLVM's SPIR-V backend knew these builtins, but only for OpenCL. The patch lets Vulkan shaders find them and turns on the two extensions for Vulkan triples.
3. **A second target, `adreno840`** ([`targets.mojo`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/max/mojo/max/_plugin/spirv/targets.mojo)). It gives the same SPIR-V and exists so MAX can pick the matrix kernel only where the hardware has one.

## 3. Finding an Adreno 840

None of this could run on my phone: neither of the Adreno 710's drivers offers the extension. The Snapdragon 8 Elite Gen 5 (Adreno 840) does.

[Samsung's Remote Test Lab](https://developer.samsung.com/remote-test-lab) rents Galaxy S26 Ultras for free. Its Remote Debug Bridge (`rdb`, an unsigned Intel binary that macOS must be told to allow) makes the remote phone a local `adb` device, and `adb push` plus `adb shell` work as with a phone on the desk. Two surprises:
- **Commands with `&&`:** a shell command containing `&&` or `&` drops the connection. `getprop; ls` works, `cd x && y` does not, so every script here sends plain commands.
- **Upload speed:** pushes run at 2.3 MB/s, so Llama's 2.47 GB of weights take 18 minutes.

The first program on the remote phone was a 41-line probe ([`coopmat/vk_coopmat_probe.c`](coopmat/vk_coopmat_probe.c)), which asks the driver what it supports:

```
device: Adreno (TM) 840, Vulkan 1.4, driver 0x8034a013
180 extensions; VK_KHR_cooperative_matrix: yes
  M64 N64 K16  A fp16 B fp16 C fp16   scope subgroup
  M64 N64 K8   A fp32 B fp32 C fp32
  M64 N64 K32  A int8 B int8 C int32
  ... the same with N = 32 and N = 16
```

That rules out my compile-only design, 16×16 tiles of fp16 accumulating into fp32: there are no 16×16 tiles and no fp16 × fp16 → fp32. fp16 products accumulate in fp16.

Two public bug reports ([clpeak#219](https://github.com/krrishnarraj/clpeak/issues/219), [llama.cpp#29952](https://github.com/ggml-org/llama.cpp/issues/29952)) had said as much about the shapes. They also said an fp16 accumulator carried around a loop crashes this family of drivers. It didn't crash on this driver build, 512.842.19, which I checked on two S26 Ultras, an SM-S948B and an SM-S948U. Neither has `VK_QCOM_cooperative_matrix_conversion`, the Qualcomm extension that reportedly speeds up such kernels.

## 4. Tiles the hardware takes

The test kernels moved to 64-row tiles: fp32 with K = 8, and fp16 with K = 16 and an fp16 accumulator. All three were correct on the first run:
- **fp32:** within 1.6e-4 of float64 at 2048×2048×2048.
- **fp16:** matches, bit for bit, a NumPy model that rounds every product and running sum to fp16. So its larger error is fp16 arithmetic, not the kernel. The transposed version sums in another order, with the same error statistics.

Then the tile width. The driver offers N = 16, 32 and 64 ([`coopmat/run_coopmat.py`](coopmat/run_coopmat.py), `COOPMAT_N`):

| 2048×2048×2048 | N = 16 | N = 32 | N = 64 |
|---|---|---|---|
| fp32 | 374 GFLOP/s | 515 GFLOP/s | **1,334 GFLOP/s** |
| fp16 | 649 GFLOP/s | 814 GFLOP/s | **2,095 GFLOP/s** |

A 64×64 tile reuses each A tile across 64 columns instead of 16, which makes it 3.2–3.6× faster. MAX's matmul now takes a 64×64 cooperative-matrix kernel on `adreno840` when A, B and C are all fp16 or all fp32 and the sizes are multiples of the tile ([`coopmat_matmul.mojo`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/max/kernels/src/linalg/matmul/gpu/adreno/coopmat_matmul.mojo)). MAX's three test matmuls, built by its own graph compiler, pass on the phone. At 256³ they reach 183 GFLOP/s in fp32 and 210 in fp16, against 71 and 26 for MAX's naive kernel on the same phone. At that size the fixed cost of a dispatch, about 0.15 ms, is most of the time.

## 5. Shared memory, and three driver quirks

At this point each subgroup read its own tiles from main memory. The standard next step is to let a workgroup of 2×2 subgroups share them: copy each K step's slices of A and B into shared memory once, then let all four subgroups multiply from there ([`matmul_coopmat_gpu.mojo`](coopmat/matmul_coopmat_gpu.mojo), `matmul_coopmat_smem`).

Two compiler fixes came first:
- **One marker signature.** A placeholder call with a shared-memory pointer declared the marker a second time with a different signature, which LLVM rejects. `CoopMatrix` now passes every pointer as a generic pointer, and the pass traces the cast back to the shared array.
- **Element 0.** IRBuilder folds a pointer to element 0 of a shared array into the array variable itself, which a matrix load can't take. The matrix lowering now builds an explicit element pointer.

  My first version of that fix applied it to every shared-memory access. The regression compile of all 26 MAX graphs caught a crash in LLVM's SPIR-V backend on the reductions, so the fix now applies to matrix accesses only.

fp32 staging worked at once: 2.48 TFLOP/s at 2048³, 1.9× the unstaged kernel. fp16 came out as NaNs. Small diagnostic kernels on the phone, a few lines each, found three driver behaviours:

1. **fp16 single-element accesses.** Single fp16 accesses to a shared array behave as if each element were 4 bytes apart, while the driver allocates 2 bytes per element. Writing and reading back a 2,048-element array worked for the first 1,024 elements only; reads past that returned element 0. Declaring the array twice as long fixed the round trip.
2. **fp16 matrix offsets.** For element e, a fp16 matrix load or store in shared memory starts at byte 4e instead of 2e, but packs the matrix itself 2 bytes per element. A tile meant to start at element 16 landed at element 32, the start of the next row, and overwrote its neighbour. A tile at element 2048 ran past the end of the array. Halving the offset made every case exact.
3. **Mixing the two layouts.** Because of 1 and 2, values written one element at a time can't be read back as a matrix: they came back two elements apart. fp16 tiles are therefore copied as matrices, loaded from the buffer and stored to shared memory by one subgroup each, with halved offsets (`f16_smem_offset`; `-D COOPMAT_F16_SMEM_QUIRK=0` turns that off for a correct driver).

None of this affects fp32, where single elements and matrices agree.

On the second S26 Ultra, at 2048³:

| | 64×64 tile per subgroup | staged 128×128 block |
|---|---|---|
| fp16 | 2.01–2.12 TFLOP/s | **3.45–3.70 TFLOP/s** |
| fp32 | 1.31–1.34 TFLOP/s | **2.48–2.49 TFLOP/s** |

## 6. Llama 3.2 1B on the Adreno 840

The Part 3 runtime ([`llama/llama_vk.c`](llama/llama_vk.c)) is a small C program that schedules seven Mojo kernels with Vulkan, 150 dispatches per token. The weights are fp16; activations and the KV cache are fp32. It ran unchanged on the S26 Ultra with Qualcomm's own driver. A 46-token prompt took 1.83 s, against 11.5 s on the 710. Decode ran at 41.1 ms/token (24.4 tokens/s), against 285. All 48 tokens matched PyTorch, with logits within 6.1e-5.

Decode reads all 2.47 GB of weights for every token and does two flops per weight read. Matrix units can't help that; memory bandwidth decides it.

Prompt processing is different. Part 3 ran the prompt through the decode path one token at a time, so the 431-token prompt in [`prompts/long.txt`](llama/prompts/long.txt) took 17.3 s, 40 ms per token. Processed together, the prompt turns every projection into a real matrix multiply. The 973 million projection weights of the 16 layers each get reused for all 431 tokens: 0.84 TFLOP of work, or 1.0 TFLOP with the rows padded to 512.

`run.py --prefill` does exactly that. [`llama/kernels/prefill/`](llama/kernels/prefill) has batched versions of the decode kernels, built with the native target for `adreno840` (`build_kernels.py --flavor prefill840`):

| kernel | work | launch |
|---|---|---|
| [`p_gemm`](llama/kernels/prefill/p_gemm.mojo) | Y = X Wᵀ for all rows: fp32 cooperative matrices, 2×2 subgroups per 128×128 block. W's fp16 slice is converted to fp32 and transposed while it is staged in shared memory, so the math is fp32 throughout. | n/128 × rows/128 |
| [`p_attention`](llama/kernels/prefill/p_attention.mojo) | causal attention: token t attends to positions 0..t (since fused on cooperative matrices; see the update) | heads × rows |
| [`p_rope_kv`](llama/kernels/prefill/p_rope_kv.mojo) | RoPE for every row; k and v into the KV cache at the row's position | 5 × rows |
| [`p_rmsnorm`](llama/kernels/prefill/p_rmsnorm.mojo), [`p_silu_mul`](llama/kernels/prefill/p_silu_mul.mojo), [`p_add`](llama/kernels/prefill/p_add.mojo) | per row; `p_add` adds the residual | rows (× columns/256) |

The runtime embeds the prompt on the CPU, since the weights are in host-visible memory. It pads the prompt to a multiple of 128 rows and runs 176 dispatches in one submit. Then it computes the last token's logits with the decode path's final norm and lm_head, and decode continues from there.

`p_add` exists because of a fourth driver behaviour. A matmul whose accumulator starts as a matrix loaded from Y, which would give Y += X Wᵀ in one kernel, fails at pipeline creation with `VK_ERROR_UNKNOWN`. Creating each pipeline on its own with [`runner/vk_launch.c`](runner/vk_launch.c) pinned it to that one kernel.

The result, with the same 431-token prompt, run, weights and phone (the first version of `p_gemm`; [the update](#update-faster-weight-staging-and-a-second-driver-build) halves it again):

| prompt (431 tokens) | time | tokens identical to PyTorch | max logit difference |
|---|---|---|---|
| one token at a time | 17.3 s | 48 of 48 | 5.3e-5 |
| batched prefill on cooperative matrices | **1.29 s** | 48 of 48 | 8.7e-5 |

Both versions answer the question in the prompt with the same text, and that text matches PyTorch word for word. Decode afterwards is unchanged at 41.3 ms/token.

Where the 1.29 s goes (`LLAMA_PROFILE=1` runs each prefill dispatch on its own submit):

| kernel | time |
|---|---|
| `p_gemm` (64 projections) | 1,221 ms |
| `p_attention` | 97 ms |
| `p_silu_mul`, `p_add`, `p_rmsnorm`, `p_rope_kv` | 51 ms |

So the matmuls run at about 0.8 TFLOP/s, a third of the standalone fp32 kernel's 2.5. The difference is in staging W. Each thread converts its own row of the fp16 weights, so neighbouring threads read addresses 4 KB or more apart, while the standalone kernel copies contiguous runs. Coalescing that copy is the obvious next step. After that, a fused attention kernel would replace one that reads the whole KV cache once per query token.

## Update: faster weight staging, and a second driver build

**The prefill matmul, one level down.** Each `p_gemm` thread used to convert its own row of W, so neighbouring threads read addresses 4 KB or more apart. Now consecutive threads read consecutive weights, W's slice keeps its layout in shared memory, and B = Wᵀ is loaded column-major. Alone on the phone (512 rows, checked against NumPy):

| projection | before | now |
|---|---|---|
| gate/up, 16384×2048 | 1.77 TFLOP/s | 2.09 TFLOP/s |
| down, 2048×8192 | 1.10 TFLOP/s | 1.91 TFLOP/s |

The isolated numbers also correct the profile above: the large projections were never at 0.8 TFLOP/s. The average was pulled down by the small ones (q/k/v and o, only 64–96 workgroups) and by per-dispatch overhead in profile mode. A K step of 32 would read even longer runs, but it fills the 840's 32 KB of shared memory exactly, and that gave wrong results. 16 KB works.

End to end, on the Android 17 phone (below), with the same prompt:

| prompt (431 tokens) | time | tokens identical to PyTorch | max logit difference |
|---|---|---|---|
| one token at a time | 17.7 s | 48 of 48 | 5.3e-5 |
| batched prefill, first `p_gemm` | 1.29 s (on the Android 16 phone) | 48 of 48 | 8.7e-5 |
| batched prefill, coalesced `p_gemm` | 0.68 s (26x) | 48 of 48 | 8.7e-5 |
| batched prefill, and fused attention | **0.63 s** (28x) | 48 of 48 | 6.0e-5 |

`p_gemm` now takes 556–586 ms for the 64 projections, 1.7–1.8 TFLOP/s averaged over all four shapes.

**Fused attention.** The first `p_attention` ran one 64-thread workgroup per head and prompt token: each read its own keys from memory and did the dot products on the ALUs, 100 ms in all. The fused version gives one subgroup a block of 64 tokens of one head. For each block of 64 keys up to the diagonal it computes S = QKᵀ with 8 fp32 cooperative-matrix products, reading K column-major straight from the KV cache, and stores S to shared memory, where each thread owns one query row.

A first pass finds each row's softmax max and sum. A second pass recomputes S, turns it into probabilities and accumulates O += PV on the matrix units. Recomputing QKᵀ costs 1.5× its flops, but O stays a cooperative matrix that never needs rescaling row by row, which an opaque matrix cannot do. At 512 rows it takes 2.72 ms a layer against 5.81 (max error 1.0e-6 against NumPy), 46 ms for the 16 layers, and the prompt went from 0.68 s to 0.63 s.

Getting the weights there took a detour. The lab's bridge slowed to 0.16 MB/s, four hours for 2.47 GB, and the lab wipes phones between sessions. The phone has its own internet connection, though, and `curl`. So it downloaded `model.safetensors` from a public mirror with the same SHA-256 as Meta's file, at tens of MB/s. A 57-line converter ([`llama/st2bin.c`](llama/st2bin.c)) then followed a recipe written on the Mac from the same file's header ([`llama/st2bin_recipe.py`](llama/st2bin_recipe.py)). The resulting `weights.bin` is byte-identical to the Mac's export.

**Same version number, different driver.** One S26 Ultra came back from the lab updated to Android 17, and every pipeline with a matrix multiply-add failed to create, even a single one with no loop. Its driver reports the same version, 512.842.19, but it is a different file: 4,410,944 bytes against 4,409,520, and 186 extensions against 180.

A GLSL shader doing the same multiply-add worked. The difference between the two modules was one instruction: our zero accumulator was built at run time with `OpCompositeConstruct`, while glslang writes an `OpConstantComposite`. Editing that into our module made it work. LLVM's SPIR-V backend cannot emit a constant of the matrix type, so the target now rewrites such a construct, when its operands are constants, into an `OpConstantComposite` in the finished binary; the two instructions have the same operands. Every kernel passes again on both builds, MAX's included.

The lesson from section 3 holds twice over: ask the driver, and the version number is not the driver.

## Update: 4-bit weights

Decode reads every weight once per token, so it gains from smaller weights the way prefill gains from matrix units. `run.py --quant q4` quantizes every projection and the lm_head to int4, symmetric, with one fp16 scale per 64 weights of a row and 8 weights packed into each 32-bit word. The embedding lookup stays fp16. About 0.65 GB is read per token instead of 2.47 GB. [`gemv_q4`](llama/kernels/gemv_q4.mojo) unpacks 8 weights per word for decode, and [`p_gemm_q4`](llama/kernels/prefill/p_gemm_q4.mojo) unpacks them into fp32 while staging W, so prefill still multiplies in fp32 on the matrix units. The PyTorch reference uses the same dequantized weights, and the phone matches it on all 48 tokens.

| S26 Ultra, 431-token prompt | fp16 | int4 |
|---|---|---|
| decode | 43.4 ms/token | **13.4–14.9 ms/token** (2.9–3.2×) |
| prompt, batched | 0.63 s | 0.62 s |

Decode gets 2.9–3.2× from 3.8× fewer bytes; unpacking costs some arithmetic, and attention and the dispatches don't shrink. Prefill doesn't move: it was already limited by arithmetic. The int4 model words its answer differently from the fp16 one from the first token and still answers the question.

The weights were never pushed: the phone downloaded `model.safetensors` and [`st2bin.c`](llama/st2bin.c) quantized it there, byte-identical to the Mac's export.

That phone ran Android 16, and its driver build refused to link the fused attention kernel. One cut-down variant reported running out of registers. `llama_vk` now falls back to the one-workgroup-per-token kernel there (99 ms instead of 46). The same kernel links and runs on the Android 17 build, so it's another case of the version number not being the driver.

## What did not work

| attempt | outcome |
|---|---|
| 16×16 fp16 tiles with an fp32 accumulator (my compile-only design) | not among the 840's shapes: 64 rows only, fp16 accumulates in fp16 |
| `VK_QCOM_cooperative_matrix_conversion` | not exposed by the 840's driver 512.842.19, on either S26 Ultra |
| fp16 tiles staged element by element | the driver lays out single fp16 elements in shared memory differently from matrices (section 5) |
| one shared array per tile, always at offset 0 (the portable fix for the offset quirk) | LLVM merges the branches into a store through a pointer that picks the array at run time, which the pass does not yet lower for matrices |
| an explicit GEP for every shared-memory pointer | crashes LLVM's SPIR-V backend on reductions; now only for matrix accesses |
| Y += X Wᵀ with the accumulator loaded from Y | `VK_ERROR_UNKNOWN` at pipeline creation; a separate `p_add` instead |
| adb commands with `&&` on the Remote Test Lab | drop the connection; plain commands and `;` work |
| a zero matrix built at run time (`OpCompositeConstruct`) | rejected by the Android 17 build of the 840's driver; now an `OpConstantComposite` |
| a K step of 32 in `p_gemm`: 32 KB of shared memory, the reported limit | wrong results on the 840; a K step of 16 (16 KB) |
| the fused prefill attention on the 840's Android 16 driver | "Failed to link shaders"; `llama_vk` falls back to the scalar kernel |
| more workgroups for the small projections (smaller blocks, split-K, register prefetch) | all slower than, or within noise of, 128×128 blocks |

## Reproduce it

```bash
# the compiler with the target (macOS without Xcode.app: see ADRENO.md)
git clone -b adreno-spirv-target https://github.com/adityaGoCT/modular ../modular
(cd ../modular && ./bazelw build //Mojo/tools/mojo:mojo //Mojo/stdlib/std //max/mojo/max:max)

# cooperative matrices on an Adreno 8xx phone (adb device, e.g. Samsung's Remote Test Lab)
COOPMAT_N=64 coopmat/check.sh                                     # compile and spirv-val
ANDROID_SERIAL=localhost:33687 python3 coopmat/run_coopmat.py 1024 2048
MOJO_SPIRV_SAVE_DIR=$PWD/build/max840 ../modular/bazelw run //max/examples/vulkan_coverage:coverage -- --arch=adreno840
ANDROID_SERIAL=localhost:33687 python3 coopmat/run_coopmat.py --max build/max840

# Llama 3.2 1B (weights from Hugging Face; Python with torch and transformers, see llama/README.md)
ANDROID_SERIAL=localhost:33687 python3 llama/run.py --model <snapshot dir> --prompt-file llama/prompts/long.txt
ANDROID_SERIAL=localhost:33687 python3 llama/run.py --model <snapshot dir> --prompt-file llama/prompts/long.txt --prefill
```

## Where the code is

| what | where |
|---|---|
| The Vulkan SPIR-V target, cooperative matrices included (compiler, stdlib, MAX) | [adityaGoCT/modular, branch `adreno-spirv-target`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target), [ADRENO.md](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/ADRENO.md) |
| Kernel ABI pass and the cooperative-matrix lowering | [`VulkanKernelABI.cpp`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/Mojo/lib/Compiler/ObjectCompiler/Target/max_license/SPIRV/VulkanKernelABI.cpp) |
| `CoopMatrix` | [`max/mojo/max/gpu/compute/arch/mma_spirv.mojo`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/max/mojo/max/gpu/compute/arch/mma_spirv.mojo) |
| MAX's matmul on cooperative matrices, and its dispatch | [`matmul/gpu/adreno/coopmat_matmul.mojo`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/max/kernels/src/linalg/matmul/gpu/adreno/coopmat_matmul.mojo), [`matmul/gpu/__init__.mojo`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/max/kernels/src/linalg/matmul/gpu/__init__.mojo) |
| LLVM patches | [`llvm-spirv-cooperative-matrix-vulkan.patch`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/bazel/public-patches/llvm-spirv-cooperative-matrix-vulkan.patch), [`llvm-spirv-structurizer-split-headers.patch`](https://github.com/adityaGoCT/modular/blob/adreno-spirv-target/bazel/public-patches/llvm-spirv-structurizer-split-headers.patch) |
| MAX's compile test, and the phone as a MAX device | [`max/examples/vulkan_coverage/`](https://github.com/adityaGoCT/modular/tree/adreno-spirv-target/max/examples/vulkan_coverage), [`remote/`](remote) |
| Matrix test kernels (unstaged and staged), driver probe, phone runner | [`coopmat/`](coopmat), [`runner/vk_launch.c`](runner/vk_launch.c) |
| Llama 3.2 1B: decode and prefill kernels, Vulkan runtime, driver script | [`llama/kernels/`](llama/kernels), [`llama/kernels/prefill/`](llama/kernels/prefill), [`llama/llama_vk.c`](llama/llama_vk.c), [`llama/run.py`](llama/run.py), [`llama/README.md`](llama/README.md) |
| Part 3: the retargeters | [`mojo2vk.py`](mojo2vk.py), [`mojo_adreno.py`](mojo_adreno.py), [BLOG.md](BLOG.md) |
| Slides (27, with speaker notes) | [online](https://claude.ai/artifact/9HodHBDh22HuBYoo5UxTN6), [PDF](docs/presentation/mojo-and-max-on-adreno.pdf) |

## What's next

- **A faster prefill matmul.** Coalesced staging brought it to 1.8 TFLOP/s on average, against the 2.5 TFLOP/s the standalone fp32 kernel reaches; the small q/k/v and o projections need more parallelism than 64–96 workgroups.
- **The Snapdragon 8 Elite Gen 6.** The Extreme variant reportedly has dedicated matrix cores (Adreno 850). Its driver may offer fp16 → fp32 products, other shapes and the Qualcomm conversion extension, and the same probe will say.
- **MAX's matmul with staging,** so MAX graphs get the 3.5 TFLOP/s kernel and not only the 64×64 one.
- **Integer products** (the 840 offers int8 × int8 → int32): the path to quantized weights, where decode would gain from reading a quarter of the bytes.
- **Upstream.** LLVM gets the structurizer fix and the cooperative-matrix patch. Modular gets the target, once their compiler accepts outside changes.
