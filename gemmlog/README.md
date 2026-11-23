# gemmlog: the kernels of "How to Optimize a GEMM on a Phone GPU: a Worklog on the Adreno 850"

Twelve fp16 GEMM kernels at M = N = K = 4096 on an Adreno 850 (Qualcomm Device Cloud SM8975, stock driver
E17.52.10.04), each checked against an fp32 reference and timed on the phone, cooled to 45 C first.

| # | kernel | GFLOP/s | of the 17.5 TFLOP/s matrix peak |
|---|---|---|---|
| 1 | naive (`k1_naive`, timed on 512 rows: one 4096^3 dispatch loses the device) | 37.5 | 0.2% |
| 2 | coalesced (`k2_coalesced`) | 198 | 1.1% |
| 3 | shared-memory tiles, 32 x 32 (`k3_shared_bs32`) | 257 | 1.5% |
| 4 | 1D register tiles (`k4_regtile_1d`) | 465 | 2.7% |
| 5 | 2D register tiles (`k5_regtile_2d`) | 750 | 4.3% |
| 6 | vectorized, fp16 math into fp32 every 16 steps (`k6_vec_mix`; `k6_vec_f32` 2,929; `k6_vec_f16` 4,272 but 2.7% error) | 3,009 | 17.2% |
| 7 | matrix unit, one 64 x 32 tile per subgroup (`gNN_w1x1_t1x1_n32_f16_k1`) | 976 | 5.6% |
| 8 | best of 40 tile configurations (`gNN_w1x2_t1x4_n32_f16_k1`) | 6,754 | 38.6% |
| 9 | K-major A (`gTN_w1x4_t1x2_n32_f16_k1`) | 9,423 | 53.8% |
| 10 | packed panels (`gPP_w1x2_t1x2_n32_f16_k1`) | 12,147 | 69.4% |
| 11 | one 64 x 64 tile per subgroup (`gPQ_w2x2_t1x1_n64_f16_k1`) | 15,209 | 86.9% |
| 12 | K contiguous inside tiles (`gRC_w2x2_t1x1_n64_f16_k1`) | 15,801 | 90.3% |

Raw results: `results_4096.json` (best of 5 runs each; `t0` = GPU temperature at start in mC).

## Files

```
alu_kernels.py   kernels 1-6 (GLSL, generated per shape: python3 alu_kernels.py M N K outdir)
run.py           builds every kernel (7-12 via AdrenoBLAS's ablas/gen.py), pushes, runs one process per kernel, cooled
results_4096.json
k4096/           generated GLSL and SPIR-V (not needed to reproduce)
```

## Reproduce

```bash
export ADB_SERVER_SOCKET='tcp:[::1]:5037' ANDROID_SERIAL=<serial>   # QDC tunnel; plain adb works for a local phone
python3 run.py alu nn tn pp pq rc k1slice f16loose
```

The harness is `../asm/peak/vk_bench.c` (built as `../asm/peak/vk_gemm_bench`); shapes and references come from
AdrenoBLAS's `ablas/sweep.py` `make_shape` (operand layouts N, T, P, Q, R, C). The runner waits for any `llama-*` or `bench`
process on the phone before each kernel, so it can share the phone with other benchmarks.
