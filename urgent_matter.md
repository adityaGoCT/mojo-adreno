# Urgent: Adreno Vulkan driver bugs that cap GEMM, and what fixing them is worth

*2026-11-21 · AdrenoBLAS (`ablas/`) and the assembly probes (`asm/`) · numbers from this repo's measurements*

## Summary

Seven bugs in the Adreno 850's stock Vulkan driver block or slow fp16 GEMM, the core of LLM prefill. AdrenoBLAS works around all of them and reaches **16.6 TFLOP/s at 4096³ (95% of the 17.5 peak) and 17.0 at 4096 x 4096 x 8192 (97%)**, with one 64 x 64 tile per subgroup and tiles that store K contiguously.

**Update (later): #1 is narrower too.** With a single 64 x 64 accumulator per subgroup, K unrolled by 2 or 4 runs correctly; the hang needs 64 x 32 tiles. Unrolling is slower there anyway (15.5 and 14.3 vs 16.6 TFLOP/s), so fixing #1 is no longer worth much for GEMM. What's left at 4096³ is the store of C, which every workgroup issues at the same moment; persistent workgroups, the usual fix, ran 3x slower on this driver (same inner loop in the disassembly).

**Update (same day): #4 is narrower than first reported, and its workaround is measured.** One 64 x 64 tile per subgroup does not hang; two or more do. With one 64-wide tile per subgroup and 64-wide B panels, fp16 GEMM went from 10.8 to **13.8 TFLOP/s at 2048³ (+28%)** and from 12.5 to **14.1 at 4096³ (+13%)**. That is the low end of the +20-35% estimated below, now measured.

- **Remaining performance cost:** small. #4 (two 64-wide tiles per subgroup hang) blocks more reuse per load; #1 no longer blocks the best kernel. The last 3-5% at 4096³ is the C store burst, not a driver bug we can name.
- **Urgent for every Vulkan app on this driver, not just ours.**
  - #7: specialization constants make kernels up to **2x slower** and can **hang the GPU**.
  - #5: cooperative loads from `uint`/`uvec4` shared memory return **wrong data with no error**.
  - #1: any compiler that unrolls a matrix-multiply K loop **hangs the GPU**.
- **Accuracy and new formats.** #3 blocks fp32 accumulation with fp16 output; today's error is 3e-3 to 1e-2 of the largest output, growing with K. #2 blocks combining accumulators in registers and arithmetic on int8 matrices, which is the first step to measuring int8 throughput.

**Driver identification** (QDC "Art" reference phone, SM8975, Android 17 userdebug CQ2A.260820.002):
- GPU: Adreno (TM) 850, chip id 0x44051431, Vulkan 1.4.351.
- Driver build: `dbca1a4c11, Ie9dcd0093d, 1787853470`, dated 08/27/26.
- Compiler: **E17.52.10.04**.

## The seven bugs at a glance

| # | bug | kind | what it costs today | estimated gain if fixed | confidence |
| --- | --- | --- | --- | --- | --- |
| 4 | fp16 cooperative matrices with N = 64 tiles: hang with two or more 64-wide accumulators per subgroup (or B held in registers across steps) | **GPU hang** | worked around: one 64 x 64 tile per subgroup (+28% at 2048³, +13% at 4096³, measured) | larger tiles per subgroup: unknown | measured |
| 1 | two dependent `coopMatMulAdd` into one accumulator in one loop body, with 64 x 32 tiles | **GPU hang** | none for the best kernel (a single 64 x 64 accumulator unrolls fine, but slower); shared-memory staging limited to K steps of 16 | ~0% for the best kernel; staged kernels unblocked | measured |
| 7 | M, N, K as specialization constants | 2x slowdown, **GPU hang** | none for AdrenoBLAS (rewritten in the runtime); **up to 2x for other apps** | 0% for us; up to 2x elsewhere | measured |
| 5 | `coopMatLoad` from a `uint`/`uvec4` shared array | **silent wrong results** | none (we use `f16vec4` arrays) | correctness for other apps | measured |
| 3 | converting an fp32 accumulator to fp16 (`coopmat<float16_t>(c)`) | compiler segfault | no fp32 accumulation with fp16 output | accuracy (costs ~9% speed) | measured crash, cause inferred |
| 2 | adding two cooperative matrices (`c0 + c1`, `ma + ma`) | compiler segfault | element-wise loops instead; no int8 matrix arithmetic | small speed gain; unblocks int8 work | measured |
| 6 | 4+ accumulator tiles combined element-wise | `vkCreateComputePipelines` -> `VK_ERROR_UNKNOWN` | blocks the workaround for #1 at larger tiles | small; moot if #1 is fixed | measured |

## Details

### 4. 64-wide fp16 tiles hang the GPU (narrower than first reported; worked around)

```glsl
coopmat<float16_t, gl_ScopeSubgroup, 64, 16, gl_MatrixUseA> ma;
coopmat<float16_t, gl_ScopeSubgroup, 16, 64, gl_MatrixUseB> mb;   // N = 64 (advertised by the driver)
coopmat<float16_t, gl_ScopeSubgroup, 64, 64, gl_MatrixUseAccumulator> c0;
for (uint i = 0; i < 64; ++i) {
  coopMatLoad(ma, a, ((base + i) & 31u) * 1024u, 16, gl_CooperativeMatrixLayoutRowMajor);  // new A each step
  c0 = coopMatMulAdd(ma, mb, c0);
}
```

- **Observed:** `VK_ERROR_DEVICE_LOST` for fp16 into fp16 and fp16 into fp32 at N = 64 in this probe, where B stays in registers across iterations. The same loop at N = 32 runs at 17.5 TFLOP/s, and fp32 at N = 64 runs fine. Repro: `asm/peak/gen_coopmat_load.py`, kernels `cml_f16f16_n64k16_*` and `cml_f16f32_n64k16_*`.
- **In GEMM (2048³ TN, `ablas/sweep.py --nt 64`):** all 8 configs with **one** 64 x 64 accumulator per subgroup (`t1x1`, A and B loaded every step) pass. All 16 with **two** (`t1x2`, `t2x1`) lose the device.
- **Workaround:** one 64 x 64 tile per subgroup, with B stored as 64-wide panels (16 x 64 tiles, 2 KB each). That gives one A and one B load per 64 x 64 multiply and 128-byte B rows. Measured:

| kernel | 2048³ | 4096³ |
| --- | --- | --- |
| before: 64 x 32 tiles, best layout | 11.38 | 12.49 |
| 64 x 64 tile per subgroup, TN layout | 11.40 | |
| **64 x 64 tile per subgroup, panels (B 64 wide)** | **13.82** | **14.12** |

- **Still blocked:** two or more 64-wide accumulators per subgroup (64 x 128 of C or more per subgroup), the usual next step for more reuse per load.

### 1. Two dependent multiply-adds into one accumulator per iteration hang the GPU

```glsl
for (uint k = 0u; k < K; k += 32u) {            // K unrolled by 2
  ... c00 = coopMatMulAdd(a0_0, b0_0, c00);
  ... c00 = coopMatMulAdd(a0_1, b0_1, c00);      // second multiply into the same accumulator: GPU hang
}
```

- **Observed:** device lost for every K-unrolled kernel with 64 x 32 tiles (`ku=2` in `ablas/gen.py`) and for every shared-memory kernel with K chunks of 32. Splitting the chain across two accumulators (`--dual` in `ablas/sweep.py`) never hangs. With one 64 x 64 accumulator per subgroup (K-contiguous tiles, 4096³), `--ku 2 4` runs correctly at 15.5 and 14.3 TFLOP/s, below the 16.6 of the unrolled-by-1 loop.
- **Workaround:** one multiply per accumulator per iteration. The dual-accumulator version is correct but slower (6.2 vs 8.8 TFLOP/s) and hits #6 at larger tiles.
- **Why it matters:** compilers routinely unroll K loops, so this is a hang risk for any framework's cooperative-matrix shaders. The direct gain is uncertain: software prefetch, which also puts more loads in flight, was slower (8.7 vs 10.8). The clear gain is for shared-memory staging, which today pays a barrier every 16 elements of K (7.8 TFLOP/s).

### 7. Specialization constants: 2x slower code, and a hang

Same kernels, with M, N, K supplied three ways (`ablas/gen.py` `spec=True`; `ablas/specialize.py`):

| kernel | specialization constants | same SPIR-V, constants rewritten to `OpConstant` | literals |
| --- | --- | --- | --- |
| NN 2048³ | 4,203 µs | 2,112 µs | 2,123 µs |
| TT 2048³ | 2,536 µs | 2,265 µs | 2,272 µs |
| TN 2048³ | 1,713 µs | 1,618 µs | 1,777 µs |
| TN 1024³ | **device lost** | 179 µs | 175 µs |

- **Workaround:** AdrenoBLAS rewrites `OpSpecConstant` into `OpConstant` before pipeline creation (`specialize()` in `ablas/ablas.c`).
- **Why it matters:** specialization constants are the standard Vulkan way to size kernels per shape. Every app that uses them on this driver pays up to 2x on affected kernels and risks a hang.

### 5. Cooperative loads from `uint`/`uvec4` shared memory return wrong data

| path (`ablas/diag/`) | result |
| --- | --- |
| global -> shared (`uvec4`) -> global, plain loads and stores | exact |
| `coopMatLoad` from global | exact |
| global -> shared (`uvec4` or `uint`) -> `coopMatLoad` | **wrong (relative error ~2), no error reported** |
| same through a `float16_t` or `f16vec4` shared array | exact |

- **Workaround:** `f16vec4` shared arrays, filled from 128-bit global loads by bitcast.
- **Why it matters:** declaring shared tiles as `uint`/`uvec4` for 128-bit copies is a common pattern. Results are silently wrong.

### 3. fp32 accumulator to fp16 conversion crashes the compiler

`coopMatStore(coopmat<float16_t, gl_ScopeSubgroup, 64, 32, gl_MatrixUseAccumulator>(c00), ...)` with `c00` an fp32 accumulator crashes the compiler (segfault inside `vkCreateComputePipelines`). The same fp16 x fp16 -> fp32 multiply stored as fp32 runs at 15.9 TFLOP/s, so the conversion is the likely trigger.

- **Workaround:** fp16 accumulation. The 850's matrix unit accumulates wider internally, so errors are 3x below a fp16-every-step model.
- **Gain if fixed:** accuracy for long K: today 3e-3 relative error at K = 2048 and up to 1e-2 at K = 8192. The price is speed: the fp32-accumulate peak is 15.9 vs 17.5.

### 2. Adding two cooperative matrices crashes the compiler

`c0 = c0 + c1` on fp16 accumulators, and `ma = ma + ma` on int8 A matrices, segfault the compiler (`asm/peak/gen_coopmat_peak.py`). A plain int8 multiply loop compiles. Scaling a matrix by a scalar works.

- **Workaround:** element-wise `for (e < c.length()) c0[e] += c1[e]`.
- **Gain if fixed:** small for fp16 GEMM. It unblocks split-K-style register reductions and int8 matrix arithmetic. **int8 throughput has not been measured honestly yet.** If the unit runs int8 at twice the fp16 rate, as comparable hardware does, W8A8 prefill could approach 2x. That figure is unverified.

### 6. Pipeline creation fails with 4+ accumulator tiles combined element-wise

Dual-accumulator kernels with `t1x2` tiles (four 64 x 32 accumulators plus the element-wise combine) return `VK_ERROR_UNKNOWN` (-13) from `vkCreateComputePipelines`. This matters only because it blocks the workaround for #1 at useful tile sizes.

## Adreno 840 (Snapdragon 8 Elite Gen 5), for completeness

Measured with Samsung phones' stock driver and with Mesa Turnip (`asm/mesa/` this week; the shared-memory and pipeline rows are from `BLOG-COOPMAT.md`):

| issue | cost | estimated gain if fixed |
| --- | --- | --- |
| stock compiler: fp16 multiply-add loops reach 89% of peak (Turnip 99%) | fp16 ALU-bound kernels | +11% on such kernels (measured) |
| Turnip's register allocator ignores a bank rule: a `mad` with all three sources in the same component issues at 1/3 rate (5-21% of its GEMM `mad`s) | fp16 GEMM 3.33 vs 3.65 hand-written | **+10%**. Mesa is open source, so we can fix this ourselves and upstream it |
| fp16 shared memory: single elements behave as 4 bytes apart; matrix offsets start at byte 4e | workarounds (halved offsets) | none in speed; removes fragile workarounds |
| exactly 32 KB of shared memory gives wrong results | K step limited to 16 in `p_gemm` | unmeasured (longer contiguous runs) |
| matmul with an accumulator loaded from memory: `VK_ERROR_UNKNOWN` | separate add kernel | one dispatch per fused update |
| Android 17 driver build rejects `OpCompositeConstruct` of a cooperative matrix | our Mojo SPIR-V target rewrites it to `OpConstantComposite` | none |

## What to ask for, in order

1. **The rest of #4** (two 64-wide accumulators per subgroup hang the GPU) and **#1** for 64 x 32 tiles: GPU hangs, a robustness problem for every framework; for AdrenoBLAS's best kernel they no longer cost speed.
2. **#7 and #5** (2x slowdown and hang; silent wrong data): ecosystem-wide correctness and performance.
3. **#3 and #2** (compiler crashes): fp32 accumulation for accuracy, int8 matrix work.
4. **#6** after #1.
5. **Ours to do:** the Turnip register-allocator fix for the 840 (+10%), and an honest int8 throughput probe on the 850.

## How the estimates were made

- **Peak.** 17.5 TFLOP/s is the measured fp16 cooperative-matrix throughput with a fresh A tile loaded every iteration. Probes with loop-invariant operands report up to 66 TFLOP/s because the driver hoists the product, so they are not used. The GPU ran at its 1.45 GHz top clock for 34 of 40 samples during these runs.
- **#4.** The original +20-35% was an inference from load ratios. The workaround then measured +28% at 2048³ (10.8 to 13.8) and +13% at 4096³ (12.5 to 14.1), so the estimate held at its low end.
- **#1.** A wide range: the one comparable experiment (software prefetch) was negative, and staging gains depend on barrier cost.
- **Measured vs estimated.** Every number in the tables is measured, except the "estimated gain" column for #1 and #2 and the int8 note. Raw results: `ablas/results/*.json`, `ablas/README.md`, `asm/README.md`, `asm/mesa/README.md`.
