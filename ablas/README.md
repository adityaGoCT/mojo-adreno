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

**Update (inside llama.cpp): 3.5x (Q4_0) and 3.9x (F16) prefill over stock llama.cpp Vulkan.** A patch to
ggml-vulkan sends every matmul on a model weight to AdrenoBLAS (fp32 in and out: `ablas_pack_a_f32`,
`ablas_q4_0_pack_ggml`, `ablas_gemm_f32out`). Llama 3.2 3B pp512 runs at 1,439 tok/s Q4_0 (stock 417) and 1,341 F16
(stock 344), with the same perplexity and top token as stock: [llamacpp/README.md](llamacpp/README.md). It also
found driver bug #13 (push descriptors next to ordinary descriptor sets), worked around by
`ablas_use_descriptor_sets`.

**Update (LLM prefill): Q4_0 weights and fused epilogues.** `ablas_hgemm_q4_0` runs ggml-style Q4_0 weights at up
to **17.7 TFLOP/s** (Llama 3.2 3B's gate/up projection at M = 2048, with the SwiGLU epilogue), faster than fp16
because the weights stream at 0.56 bytes each and are dequantized in registers. With them, Llama 3.2 3B prefill runs
at **2,602 tokens/s (Q4_0) and 2,318 (fp16) at 512 tokens**, 5.7x llama.cpp's OpenCL backend on the same phone:
[llama3b/README.md](llama3b/README.md), section [Q4_0 weights and fused epilogues](#q4_0-weights-and-fused-epilogues)
below.

**Update (closing the last 7%): 16.67 TFLOP/s at 4096^3 (95%), 16.99 at 4096 x 4096 x 8192 (97%).** Tried, all
cooled (`--cool`), K-contiguous tiles with one 64 x 64 tile per subgroup at 4096^3:

| idea | result (TFLOP/s) |
|---|---|
| baseline `w2x2` / `w4x2` | **16.67 / 16.60** |
| K unrolled by 2 / 4 (one 64 x 64 accumulator: no hang, unlike 64 x 32 tiles) | 15.53 / 14.29 |
| 16-subgroup workgroups (`--big`), grouped order (`--sw 4 8`) | 14.1 at best |
| persistent workgroups, 2-16 tiles each (`--ps`), stride from `gl_NumWorkGroups` or constant | 5.4-7.5 |
| library, pre-packed: 4096^3 / 4096 x 4096 x 8192 / 4096 x 4096 x 16384 | 16.35 / **16.99** / 16.82 |

Efficiency rises with K, so the inner loop runs at about 97% of peak and the rest at 4096^3 is per-tile fixed
cost, mostly the store of C (32 MB, ~0.4 ms of 8.3 ms) issued by every workgroup at once. Persistent
workgroups, which would overlap one tile's store with the next tile's loop, compile to the same inner loop
(`asm/isa/dump/ps2_code.dis`) but run 3x slower on this driver.


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
takes this path (M, N, K multiples of 64). Through the library, cooled (`cool_run.sh`), every call checked:

| call | TFLOP/s | % of 17.5 |
|---|---|---|
| **pre-packed 4096^3** | **16.36** | **93%** |
| TN / NT / NN input 4096^3 (packed in the call) | 13.71 / 13.56 / 13.76 | 77-78% |
| pre-packed 2048^3 / 1024^3 | 14.71 / 13.41 | 77-84% |
| TN / NT / NN / TT input 2048^3 | 11.63 / 10.72 / 9.71 / 9.72 | 55-66% |
| LLM prefill, both pre-packed: 512 x 2048 x 2048 / 512 x 8192 x 2048 / 512 x 2048 x 8192 | 13.91 / 15.17 / 16.20 | 79-93% |
| LLM prefill, weights pre-packed (activations [M,K] as given): same shapes | 11.98 / 14.59 / 13.49 | 68-83% |

`tile_copy.comp` copies 32-row x 64-K blocks so each subgroup writes 256-byte runs; walking whole rows
scattered 32-byte writes over K/16 tiles and cost 3 TFLOP/s on 512 x 2048 x 8192. The tables below are
from earlier kernels.


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

The device must enable `VK_KHR_push_descriptor` (unless `ablas_use_descriptor_sets` is used), `VK_KHR_cooperative_matrix`, `shaderFloat16`,
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
- Inside another Vulkan program (llama.cpp): `ablas_use_descriptor_sets(h)` right after `ablas_create` (ordinary
  descriptor sets from AdrenoBLAS's own pools instead of push descriptors; driver bug #13), and
  `ablas_reset_descriptor_sets(h)` once the command buffers that used them have completed. fp32 activations in and
  out: `ablas_pack_a_f32` (fp32 [M,K] -> packed fp16, rows padded to 64), `ablas_q4_0_pack_ggml` (ggml `block_q4_0`
  rows -> AdrenoBLAS's Q4_0 layout) and `ablas_gemm_f32out` (packed A x packed fp16 or Q4_0 weight -> fp32 [M,N],
  rows < M written). `f32out_test.c` tests them, including several GEMMs per command buffer with llama.cpp-style
  dispatches in between (`REPEAT`, `BOUND_SET_BETWEEN`, `USE_SETS`, `TIME`).

## Q4_0 weights and fused epilogues

Added for LLM prefill (`llama3b/`). Both build on one finding about the 850's matrix unit (probe:
`llama3b/probe/map.comp`): a 16 x 64 B matrix holds output column n in lane n and k in element k, a 64 x 16 A matrix
holds row r in lane r, and a 64 x 64 accumulator holds row r in lane r and column e in element e.

**Q4_0** (`gen_q4.py`, `q4ref.py`): each lane loads its own column's 4-bit values (8 bytes per 16-deep step) and
fp16 scale, and fills the B matrix element by element: `((w >> 4j) & 0x000F000F) | 0x64006400` is 1024 + q as two
halves, minus 1032 is exact, times the scale rounds once. No shared memory. ggml Q4_0 semantics (blocks of 32 along
K, value (q - 8) * d) in a tiled layout; `ablas_q4_0_from_ggml` converts ggml `block_q4_0` rows (e.g. a GGUF
tensor) on the host.

```c
ablas_hgemm_q4_0(h, cmd, ABLAS_OP_P, M, N, K, A_packed, W_q4, C, (ablas_buf){0});   // C = A W^T
```

**Epilogues** (`epilogue.py`, `ablas_hgemm_ex` / `ablas_hgemm_q4_0_ex`): the accumulator is staged through padded
shared memory (reading accumulator elements directly costs ~20 clocks each) and lane l handles row l:
- `ABLAS_EPI_PACKED`: C written in the packed A format, ready to be the next GEMM's `ABLAS_OP_P` operand.
- `ABLAS_EPI_SWIGLU`: B's rows interleaved 32 gate / 32 up per 64; writes silu(gate) * up, packed.
- `ABLAS_EPI_RESIDUAL_RMS`: C is an fp32 residual stream, C += A B, and the workspace receives per-row sums of
  squares per 64 columns for the next RMSNorm.

**Tuning for LLM shapes** (`sweep_llm.py`): every one-tile-per-subgroup configuration of both families, with and
without each epilogue, at Llama 3.2 3B's projection shapes for M = 512 / 1024 / 2048 and the LM head
(`results/llm_*.json`, read by `build_lib.py`; tuned entries carry their epilogue). Best rates (TFLOP/s):

| shape (N x K) | fp16, M = 512 / 2048 | Q4_0, M = 512 / 2048 |
|---|---|---|
| qkv 5120 x 3072 | 15.8 / 16.6 | 16.3 / 17.1 |
| o 3072 x 3072 (plain; residual epilogue) | 16.7 / 16.7; 13.7 / 12.7 | 17.0 / 17.3; 14.2 / 15.0 |
| gate+up 16384 x 3072 + SwiGLU | 17.0 / 16.8 | 17.7 / 17.7 |
| down 3072 x 8192 (plain; residual epilogue) | 17.3 / 17.4; 15.9 / 15.6 | 17.5 / 17.6; 16.3 / 16.2 |
| LM head 128256 x 3072, M = 64 | 4.8 (memory bound) | 15.1 |

17.7 TFLOP/s is above the 17.5 the peak microbenchmark
measured: at 1.45 GHz it means at least 6,114 fp16 multiply-adds per clock, most likely 6,144 (17.8 TFLOP/s). Some
epilogue tiles are pathological at some shapes (fp16 `w2x2_eg` 8.6 where `w2x1_eg` runs 16.9), so epilogues get
their own tuning entries. `ABLAS_KERNEL` / `ABLAS_KERNEL_EP` force a kernel by name for benchmarking.

## Adreno 840 backend (ALU)

The Adreno 840 has no matrix unit. Its stock driver's fp16 cooperative matrices run on the ALUs and peak at
7.35 TFLOP/s, below the 7.99 fp16 ALU peak (`../asm/mesa/README.md`). So on the 840, AdrenoBLAS runs fp16 ALU
kernels instead (`gen_alu.py`: fp16 multiply-add and accumulate, TN layout, 8 x 8 thread tiles, shared-memory
and/or texture-path operands). `ablas_create` picks the backend by device ("840" in the name or chip
0x44050a31), not by cooperative-matrix support, so the 850 path is unchanged. On the 840 the library needs
only `VK_KHR_push_descriptor`, `shaderFloat16` and `storageBuffer16BitAccess`.

It works with both of the 840's drivers: Qualcomm's, and Mesa Turnip (`../asm/mesa`, built with
`turnip-ra-bank.patch`). Each driver has its own tuned kernels (`ablas_kernels_840.h`, driver 0 / 1),
because the best kernel differs. For Turnip the tuner also chooses the register-bank-aware register
allocation on or off per kernel. That choice travels inside the kernel: `gen_alu.mark_nobankra` tags the
SPIR-V's source-file string, and the patched Turnip compiles tagged kernels with that allocation off.
Verified: a tagged copy of `alu_gg_128x128` compiles with 128 same-bank mads, the untagged one with 22. In
the three tuned shapes the allocation was on for every winner.

Tuning (`sweep_alu.py`, Samsung RTL Galaxy Z Fold SM-F976B, cooled, every result checked against an fp32
reference, close calls re-timed three times; all runs correct). Configs: 11 with 8 × 8 thread tiles (`--set std`)
and 12 with 8 × 16 / 16 × 8 tiles (`--set big`, 128 fp16 accumulators per thread, the most the half-register
file holds):

| shape | Qualcomm driver (8 × 8) | Turnip, bank RA on, 8 × 8 | Turnip, bank RA on, 16 × 8 | Turnip, bank RA off |
|---|---|---|---|---|
| 4096³ | 3.16 (alu_gl_128x128x16) | 3.38 (alu_gl_128x128x16) | **3.57** (alu_lg_128x128x16_t16x8) | |
| 2048³ | 3.15 (alu_lg_64x128x16) | 3.32 (alu_lg_64x128x16) | **3.43** (alu_lg_128x128x16_t16x8) | 3.29 (alu_gg_128x128) |
| 1024³ | **3.14** (alu_gg_64x128) | **3.14** (alu_lg_64x128x16) | 3.03 | 2.87 |
| 512 × 2048 × 2048 | 3.01 (alu_gg_64x128) | **3.18** (alu_lg_64x128x16) | 2.90 | 2.90 |

**Bigger register tiles.** A thread tile of TM × TN reads TM values of A and TN of B per k step for TM·TN
multiply-adds, so 16 × 8 halves the B traffic (B comes through the texture path in the `lg` kernels, the
scarcer one). At 2048³ an interleaved head-to-head gives 3.436 vs 3.319 TFLOP/s (four rounds each), at 4096³
3.57 vs 3.38. Turnip compiles these kernels in 25–37 registers with no spills and 6–10 waves. With bank RA
on, `alu_lg_128x128x16_t16x8` has 3% same-bank mads. The 8 × 16 variants lose: about 29% same-bank mads, and
6 waves at 37 registers. On small shapes the 128 × 128 workgroup tile leaves too few workgroups (64 at 1024³),
and the 8 × 8 kernels stay ahead. Qualcomm's compiler cannot run them: the `lg`/`gl` big-tile kernels end in
`VK_ERROR_DEVICE_LOST` (GPU timeout), and the rest are correct but up to 1000x slow, which suggests the
accumulators are spilled. So only its 8 × 8 kernels are tuned, and its catalogue never contains a big tile.

Through the library (`ablas_test`, one shape at a time with the thermal gate, `cool_run_840.py`;
`results/library_840_*.txt`), all calls pass. `P` = pre-packed with `ablas_pack_a`/`_b`, which on the 840
write plain TN:

| call | Qualcomm driver | Turnip (bank RA, with 16 × 8 tiles) |
|---|---|---|
| TN 4096³ / PP 4096³ | 3.39 / 3.21 | **3.58 / 3.58** |
| TN 3072³ (untuned) | 3.15 | **3.64** |
| TN / NT / PP 2048³ | 3.32 / 2.98 / 3.37 | **3.46** / 3.05 / **3.46** |
| NN / TT 2048³ (8 × 8 run, transposed in the call) | 3.18 / 3.17 | 3.12 / 3.12 |
| TN 1024³ | 3.17 | 3.11 |
| TN / NT / PP 512 × 2048 × 2048 | 3.14 / 2.44 / 3.10 | 3.12 / 2.38 / 3.12 |
| TN 768 × 1536 × 1024 (untuned) | 3.07 | 3.11 |

Rows from the second run (`results/library_840_*_big.txt`, after the big tiles went in) except NN/TT and
the 512 NT/PP pair (first run). That is 39–46% of the 7.99 TFLOP/s fp16 ALU peak. The limits are operand bandwidth and register-bank
conflicts (`../asm/mesa/README.md`: a hand-written loop reaches 3.65, with its ALU part at 90%).

Notes:
- **Shapes.** M and N must be multiples of 64, K of 4; K must be a multiple of 32 when an operand is
  transposed (opA = N or opB = T). Other shapes return `ABLAS_BAD_SHAPE`. Untuned shapes take the nearest
  tuned kernel that divides them, else `alu_gg_64x64`.
- **Packed format.** It is device-specific (`ablas.h`): pre-packed weights from the 850 are not valid on the
  840 and vice versa.
- **Test threshold.** `ablas_test` passes the 840 at a sampled error below 5e-2 (2e-2 elsewhere). fp16 ALU
  accumulation rounds every step, which gives ~3e-2 at K = 2048 on 1024 sampled elements.
- **Reproduce** (RTL serial in `RTL_SERIAL`):
  ```
  cd ../asm/mesa; python3 run.py push; python3 run.py pushbank
  cd ../../ablas; python3 sweep_alu.py 2048 2048 2048
  python3 build_lib.py                                   # also writes ablas_kernels_840.h
  $NDK_CLANG -O2 -I <vulkan headers> -o build/ablas_test_840 ablas_test.c ablas.c -ldl -lm
  adb push build/ablas_test_840 /data/local/tmp/asm_mesa/
  python3 cool_run_840.py stock "T N 2048 2048 2048"; python3 cool_run_840.py turnip "T N 2048 2048 2048"
  ```

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
gen_alu.py      Adreno 840 backend: fp16 ALU kernel template (TN), mark_nobankra (per-kernel Turnip RA choice)
sweep_alu.py    Adreno 840 tuner: configs x {Qualcomm, Turnip bank RA on/off} -> results/alu840_<shape>.json
ablas_kernels_840.h  840 catalogue written by build_lib.py (build_840); copy840.comp = 840 pack for TN operands
cool_run_840.py ablas_test on the RTL 840 one shape at a time with the thermal gate
gen_q4.py       Q4_0 kernel template (dequantization into the B matrix in registers)
q4ref.py        Q4_0 quantization (ggml reference rounding) and the AdrenoBLAS Q4_0 / packed-tile layouts
q4test.py       Q4_0 kernels on the phone vs NumPy
epilogue.py     fused epilogues (packed output, SwiGLU, residual + RMS statistics), shared by gen.py and gen_q4.py
sweep_llm.py    tune both families, with epilogues, on LLM shapes -> results/llm_<fmt>_<shape>[_e<ep>].json
ablas_kernels_q4.h   Q4_0 catalogue written by build_lib.py (build_q4)
llama3b/        Llama 3.2 3B prefill benchmark on the library (fp16 and Q4_0), with its own README
llamacpp/       the ggml-vulkan patch that puts AdrenoBLAS into llama.cpp, build/bench scripts, results, README
pack_a_f32.comp, q4_pack_ggml.comp  fp32 activations -> packed fp16; ggml block_q4_0 -> AdrenoBLAS Q4_0
f32out_test.c   ablas_pack_a_f32 + ablas_q4_0_pack_ggml / ablas_pack_b + ablas_gemm_f32out vs the CPU, and timing
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

- fp16 at 4096^3 is at 95-97% of peak and Q4_0 LLM shapes at up to 99%; what's left at large sizes is the C store.
- fp32 accumulation (blocked by the conversion crash; the shared-memory epilogue staging could carry it).
- Edge tiles (shapes that aren't tile multiples), batched/strided GEMM (attention is model code in `llama3b/`).
- GEMV/decode kernels (M = 1, memory bound) for Q4_0 and fp16, and the residual epilogue's cost (it reads and
  writes the fp32 residual inside the GEMM: 14-15 vs 17 TFLOP/s for the o projection).
- Adreno 840: done as an ALU backend (section above), not cooperative matrices: its stock coopmat runs on the
  ALUs and Turnip has none. Bigger register tiles are in (16 x 8, Turnip only). Next there: interleaving the
  shared-memory and texture loads, and splitting K for small shapes so the 16 x 8 tiles get enough workgroups.
