# AdrenoBLAS (phase 1): fp16 GEMM on the Adreno 850's matrix units

A cuBLAS/rocBLAS-style GEMM library for Adreno GPUs, built on Vulkan cooperative matrices
(`VK_KHR_cooperative_matrix`). Phase 1 covers fp16 GEMM (fp16 accumulate) on the Adreno 850.
Kernels are generated from a parameterized template, verified and tuned on the phone, and the best
kernel per shape and layout goes into a compiled-in catalogue, the way rocBLAS ships Tensile's
logic files. Peak measurements and the assembly probe that led here: [../asm/README.md](../asm/README.md).

Measured 2026-11-21 on a Qualcomm Device Cloud QRD: SM8975, Adreno 850, stock Vulkan driver
(compiler E17.52.10.04), 1.45 GHz. Reference peak: **17.5 TFLOP/s** measured for fp16 cooperative
matrices (fresh operands every step); 8.36 TFLOP/s fp16 ALU.

## Results

**Update (2026-11-21, last): K-minor tiles, 16.55 TFLOP/s at 4096^3 (95% of peak).** The driver statistics and
disassembly of the 64-wide panel kernel showed 16 scalar 4-byte loads per K step: each lane of the matrix unit
holds one row of A and one column of B along K, and those panels put K outside the tile. Packing tiles with K
contiguous inside (A 64 x 16 row-major, B 16 x 64 column-major; layouts `R`/`C`) turns them into 4 vector loads
per step (loop 30 -> 16 instructions). Tuning harness, cooled before every config (`sweep.py --cool`):

| shape (packed operands) | 64-wide panels (`PQ`) | K-minor tiles (`RC`) |
|---|---|---|
| 4096^3 | 15.83 | **16.55** (95%) |
| 2048^3 | 13.82 | **14.83** |
| 512 x 8192 x 2048 / 2048 x 512 x 2048 | 13.26 / 15.22 | **15.28 / 15.69** |

The runtime now packs into this format (`tile_copy.comp`; `transpose64.comp` mode W = 1 for K-major sources).
PyTorch's NT case (activations [M,K], weights [N,K]) packs with plain copies and no transposes, so NT always
takes this path. Every packing path passed the reference check on the phone; a cooled library re-timing is pending.
The tables below are from earlier kernels.


**Update (2026-11-21, later): 64-wide tiles.** The 64-wide-tile hang only hits with two or more 64 x 64
accumulators per subgroup. With **one 64 x 64 tile per subgroup** and B packed as **64-wide panels**
(16 x 64 tiles, layout `Q`; `ablas_pack_b` now writes this format), the tuning harness measures:

| shape (operands in panels) | before (64 x 32 tiles) | one 64 x 64 tile per subgroup | % of 17.5 |
|---|---|---|---|
| 2048^3 | 11.38 | **13.82** | 79% |
| 4096^3 | 12.49 | **14.12** | 81% |
| 1024^3 | | 13.45 | 77% |
| 512 x 2048 x 2048 | | 13.72 | 78% |

Through the library (`ablas_test`, run shape by shape with `cool_run.sh`, which waits for the GPU to cool to
45 C with no thermal cap before each shape; every call checked against an fp32 reference). `P` = pre-packed
with `ablas_pack_a`/`ablas_pack_b` before the timed calls:

| call | TFLOP/s | % of 17.5 |
|---|---|---|
| **PP 4096^3** | **15.34** | **88%** |
| TN / NT 4096^3 (packed to panels in the call) | 13.42 / 13.20 | 75-77% |
| PP 2048^3 | 13.94 | 80% |
| TN 2048^3 (64 x 64 TN kernel) / NT 2048^3 (panels in the call) | 11.64 / 10.13 | 58-67% |
| PP 1024^3 | 13.30 | 76% |
| LLM prefill, weights pre-packed (NP): 512 x 2048 x 2048 / 512 x 8192 x 2048 / 512 x 2048 x 8192 | 11.70 / 12.69 / 13.31 | 67-76% |
| LLM prefill, both pre-packed (PP): same shapes | 13.70 / 13.24 / 16.08 | 76-92% |
| PP 2048 x 512 x 2048 | 15.65 | 89% |

Policy changes with this: B panels are 64 wide (N % 64 for the panel path); NT calls from 2^31 multiply-adds
go to panels (they transpose both operands on either path). The QDC phone throttles after long runs (we saw
636-1126 MHz caps): numbers taken without cooling came out up to 2x low. The older tables below are from the
32-wide kernels.

Through the library (`ablas_test`, GPU timestamps, best of 5 runs after warm-up, every call checked
against an fp32 CPU reference on 1,024 sampled elements). % = share of the 17.5 TFLOP/s measured peak.

| call (opA opB, M x N x K) | kernel | TFLOP/s | % |
|---|---|---|---|
| TN 1024 x 1024 x 1024 | `gTN_w2x2_t1x2_n32` | 12.42 | 71% |
| TN 2048 x 2048 x 2048 | `gTN_w2x4_t1x2_n32` | **11.02** | 63% |
| **PP 4096 x 4096 x 4096** (operands pre-packed into panels) | `gPP_w1x1_t1x2_n32` | **12.78** | **73%** |
| TN 4096 x 4096 x 4096 (packed into panels on the fly) | `gPP_w1x1_t1x2_n32` | 10.74 | 61% |
| NN / NT / TT 4096^3 (packed into panels on the fly) | `gPP_w1x1_t1x2_n32` | 10.27 / 9.81 / 9.80 | 56-59% |
| PP 2048^3 / 512 x 8192 x 2048 / 2048 x 512 x 2048 | `gPP_w1x1_t1x2_n32` | 10.94 / 11.23 / 12.16 | 63-69% |
| TN 768 x 1536 x 1024 (untuned: nearest entry) | `gTN_w2x2_t1x2_n32` | 13.39 | 77% |
| TN 512 x 2048 x 2048 (LLM prefill, 512 tokens) | `gTN_w1x2_t2x1_n32` | 11.06 | 63% |
| TN 2048 x 512 x 2048 (same, tokens as N) | `gTN_w1x2_t1x2_n32` | 12.04 | 69% |
| TN 512 x 8192 x 2048 | `gTN_w1x2_t2x1_n32` | 11.30 | 65% |
| TN 8192 x 512 x 2048 | `gTN_w1x1_t1x2_n32` | 11.19 | 64% |
| TN 512 x 2048 x 8192 | `gTN_w1x1_t1x2_n32` | 11.49 | 66% |
| NN 2048^3 (A packed to [K,M]) | `gTN_w2x4_t1x2_n32` | 9.60 | 55% |
| NN 1024^3 (direct: too small to pack A) | `gNN_w2x4_t1x2_n32` | 10.10 | 58% |
| TT 2048^3 (B packed) | `gTN_w2x4_t1x2_n32` | 9.59 | 55% |
| TT 1024^3 (B packed) | `gTN_w2x2_t1x2_n32` | 9.39 | 54% |
| NT 2048^3 (both packed) | `gTN_w2x4_t1x2_n32` | 8.52 | 49% |
| NT 1024^3 (B packed) | `gNN_w2x4_t1x2_n32` | 8.22 | 47% |
| NT 512 x 8192 x 2048 (both packed) | `gTN_w1x2_t2x1_n32` | 7.14 | 41% |
| NT 2048 x 512 x 2048 (both packed) | `gTN_w1x2_t1x2_n32` | 6.95 | 40% |

Packing runs `transpose64.comp` at 79 GB/s (96% of a plain 128-bit copy, 83 GB/s). Before it, the
32 x 32 scalar transpose (59 GB/s) gave NN 9.13, TT 8.82, NT 7.60 at 2048^3 and NT 5.87 at 512 x 8192 x 2048.
Variants and measurements: `transpose/` (an 8 x 8 register transpose with 128-bit rows reached only 15-48 GB/s:
its stores scatter 16 bytes per output row).

Tuning-harness numbers for the same kernels agree within a few percent (`results/*.json`); the best
single result is 12.27 TFLOP/s (TN 1024^3). Direct (unpacked) kernels at 2048^3: NN 8.2, TT 7.6, NT 2.4.
For LLM layers, pack the weights to [K, N] once: then only activations are packed per call (or none,
with tokens as N and activations kept as [K, tokens]).

Start of phase 1: 4.25 TFLOP/s at 2048^3 (Mojo `matmul_coopmat_smem_f16`, tuned on the Adreno 840).

## What the 850 wants (and what breaks it)

- **Panels for big GEMMs.** With plain K-major operands, 4096^3 dropped to 8.8-9.4 TFLOP/s: every 64 x 16 A
  tile spans 16 rows 8 KB apart (128 KB, ~32 pages per load). Packing both operands into panels (each
  64 x 16 A tile and 16 x 32 B tile one contiguous block, consecutive K tiles adjacent) brings 4096^3 to
  12.5-12.8, faster than 2048^3. Panel layout (`gen.py` layout `P`, element order in `sweep.make_shape`):
  A: `[M/64][K/16][16][64]`, B: `[N/32][K/16][16][32]`. Grouped workgroup order and bigger workgroup
  tiles did not help (traffic volume wasn't the limit: 96 MB minimum = 1.2 ms at 83 GB/s).

- **K-major operands.** Cooperative loads are fast when a tile's rows are long contiguous runs:
  A stored [K, M] (64 x 16 tile = 16 rows of 128 B) beats A stored [M, K] (64 rows of 32 B) by 1.3x.
  Layout ranking at 2048^3: TN 10.8 > NN 8.2 > TT 7.6 >> NT 2.4. PyTorch `Linear` weights are [N, K]
  (the NT case): pack them to [K, N] once; the runtime packs NT inputs with a transpose kernel.
- **One A tile per subgroup, two to four B tiles** (64 x 64-128 of C per subgroup), 4-8 subgroups per
  workgroup. Two A tiles per subgroup are slower; workgroups of 16 subgroups don't help.
- **Direct loads beat shared-memory staging.** Staging through shared memory is correct (see below) but
  needs a barrier per 16-wide K step and tops out at 7.8 TFLOP/s.
- No gain from software prefetch (8.7 vs 10.8) or grouped workgroup order (worse at 4096^3).

Driver E17.52.10.04 bugs found and avoided (the generator never emits these; repros and estimated gains if
fixed: [../urgent_matter.md](../urgent_matter.md)):

| pattern | result |
|---|---|
| two dependent `coopMatMulAdd` into one accumulator in a loop body (K unroll) | GPU hang (device lost) |
| `c0 + c1` on cooperative matrices (also `ma + ma` on int8 A tiles) | compiler segfault |
| fp32 accumulator converted to fp16 (`coopmat<float16_t>(c)`) | compiler segfault |
| two or more 64-wide (N = 64) accumulators per subgroup; or B kept in registers across steps | GPU hang (one 64 x 64 tile per subgroup works) |
| `coopMatLoad` from a `uint`/`uvec4` shared array | wrong data (`float16_t`/`f16vec4` arrays work) |
| dual accumulators with 4+ accumulator tiles | `vkCreateComputePipelines` fails (-13) |
| M, N, K as real specialization constants | NN kernel 2x slower; one TN kernel hangs the GPU |

The last one is why the runtime rewrites each kernel's `OpSpecConstant` M, N, K into plain `OpConstant`
values before creating the pipeline (`specialize()` in `ablas.c`; `specialize.py` is the same thing offline).

## Library

```c
#include "ablas.h"
ablas_handle h;
ablas_create(&h, physical_device, device, vkGetInstanceProcAddr, instance);
// C[M,N] = A * B, fp16, row-major; opA = T means A is stored [K,M]; opB = T means B is stored [N,K]
ablas_hgemm(h, cmd, ABLAS_OP_T, ABLAS_OP_N, M, N, K, (ablas_buf){bufA, 0}, (ablas_buf){bufB, 0},
            (ablas_buf){bufC, 0}, (ablas_buf){workspace, 0});
```

The device must enable `VK_KHR_push_descriptor`, `VK_KHR_cooperative_matrix`, `shaderFloat16`,
`storageBuffer16BitAccess`, `vulkanMemoryModel` and `cooperativeMatrix`. Shapes: M % 64, N % 32,
K % 32. Workspace: `ablas_hgemm_workspace_size()` (operands that get packed).

- Layout policy: operands are transposed into the TN layout in the workspace (`transpose64.comp`,
  79 GB/s; `transpose.comp` when a dimension isn't a multiple of 64). B stored [N,K] is always packed;
  A stored [M,K] only from 2^31 multiply-adds up (NN 1024^3: 10.1 direct vs 9.2 packed).
  `ablas_set_pack(h, 0)` turns packing off (except NT's B), `ablas_set_pack(h, 2)` always packs.
- Panels: operands passed as `ABLAS_OP_P` (packed once with `ablas_pack_a` / `ablas_pack_b`, e.g. weights)
  use the panel kernels directly; from 2^35 multiply-adds other operands are packed into panels per call
  (`panel_copy.comp` re-tiles K-major data with 128-bit copies; `transpose64.comp` transposes the rest
  straight into panels).
- Kernel choice: the tuned entry nearest in log(M, N, K) whose tile divides the shape, else the
  64 x 32 fallback kernel of that layout.
- Pipelines are built on first use of a shape (~150 ms; the driver compiles) and kept in the handle.

## Files

```
gen.py          kernel template + search space (tile shapes, layouts, staging, prefetch, order, dual acc)
sweep.py        build every config for a shape, run each on the phone in its own process, rank, save results/
build_lib.py    results/ -> ablas_kernels.h (best kernel per tuned shape, fallbacks, SPIR-V words)
ablas.h, ablas.c    the runtime (selection, pipelines per shape, push descriptors, NT packing)
transpose64.comp, transpose.comp   pack kernels (64x64 128-bit tile, optional panel output; 32x32 fallback)
panel_copy.comp K-major source -> panels
transpose/      transpose variants + benchmark (gen_transpose.py)
ablas_test.c    on-device correctness + speed test of the library
diag/           the shared-memory cooperative-load diagnosis
results/        tuning results (JSON per shape and layout)
```

Reproduce (QDC tunnel on [::1]:5037):

```
export ADB_SERVER_SOCKET='tcp:[::1]:5037' ANDROID_SERIAL=<serial>
python3 sweep.py 2048 2048 2048 --la T --lb N        # tune one shape/layout
python3 build_lib.py                                  # catalogue from results/
$NDK_CLANG -O2 -I <vulkan headers> -o build/ablas_test ablas_test.c ablas.c -ldl -lm
adb push build/ablas_test /data/local/tmp/ablas/ && adb shell /data/local/tmp/ablas/ablas_test
```

The sweep harness is `../asm/peak/vk_bench.c` (built as `../asm/peak/vk_gemm_bench`).

## Next

- Close the remaining gap to 17.5 TFLOP/s (best now 12.8 = 73%): per-iteration load cost is what's left. Ideas: B tiles from wider rows, finding a K unroll the driver survives,
  decoding the 850's matrix instructions (`../asm/README.md`) to see what the compiler emits per step.
- fp32 accumulation (blocked by the conversion crash: try an element-wise conversion).
- Edge tiles (shapes that aren't tile multiples), batched/strided GEMM, epilogues (bias, activation).
- GEMV/decode kernels (M = 1) and int8/int4 weights for LLM decode.
- Same flow on the Adreno 840 (Samsung RTL), whose cooperative-matrix shapes differ.
