# AdrenoBLASLt: a hipBLASLt-style layer for LLMs on the Adreno 850

AdrenoBLAS (`../ablas.h`) plays rocBLAS's part: the kernels, pack routines, tuning tables and a few fused epilogues,
called by name with packed operands. AdrenoBLASLt (`ablasLt.h`) plays hipBLASLt's part. A matmul is described by
the layout of each operand and an epilogue; the library picks the AdrenoBLAS calls, workspace, packing and barriers.
It keeps only what LLM inference needs, plus the two non-GEMM operations every transformer layer has.

| | what it does | built from |
|---|---|---|
| `ablasLtMatmul`, `EPILOGUE_DEFAULT` | D = A W^T; A fp32 rows (any M, packed inside), fp16 rows or tiles; D fp32 rows, fp16 rows, or tiles for the next GEMM | `ablas_pack_a_f32`, `ablas_gemm_f32out`, `ablas_hgemm*_ex` |
| `EPILOGUE_RESIDUAL` | residual stream (fp32) += A W^T, plus per-row sums of squares for the next RMSNorm | `ABLAS_EPI_RESIDUAL_RMS` |
| `EPILOGUE_SWIGLU` | silu(gate) * up into the down projection's tiles | `ABLAS_EPI_SWIGLU` |
| `EPILOGUE_ROPE_QKV` | q;k;v projection, RoPE, then attention-ready Q/K tiles and V^T | GEMM + `kernels/rope_qk`, `kernels/vtrans` |
| `ablasLtRmsNorm` | RMSNorm of the fp32 residual into tiles, from the epilogue's sums or computed | `kernels/rowss`, `kernels/normtiles` |
| `ablasLtAttention` | causal flash attention, grouped KV heads, head dim 128 | `fa3` from `../llama3b/gen_attn.py`, group ratio as a parameter |
| `ablasLtWeightPack` / `Row` | weights from fp32/fp16 rows, ggml Q4_0 blocks or packed files, laid out for their epilogue (gate/up interleave); row decode for embeddings | host code |
| `EPILOGUE_GEGLU`, `BIAS_GELU`, `RESIDUAL_BIAS` | gelu_tanh(gate) * up; gelu_tanh(A W^T + b) into tiles; x += A W^T + b | `ABLAS_EPI_GEGLU`, `_BIAS_GELU`, `_RESIDUAL_BIAS` |
| `ROPE_QKV`, general form | heads of 256 or 128, heads of 72 zero-padded to 128, q/k/v bias, no RoPE, K/V into a longer cache at a row offset | GEMM (packed tiles out) + `kernels/qksplit`, `kernels/vsplit` |
| `ablasLtAttentionMasked` | non-causal attention with a key mask, a block-causal suffix (π0's action expert), independent batches (a ViT's images), heads of 128 or 256, key splits for few query rows | `famask*` from `gen_kernels.py`, `kernels/facombine` |
| `ablasLtLayerNorm` | LayerNorm (weight and bias) of the fp32 residual into tiles, D any multiple of 64 | `kernels/lnstats`, `kernels/lntiles` |

The last four rows came with π0 ([`../pi0`](../pi0)). Two more things changed under every caller:
- **Row split.** A GEMM with M not a multiple of 256 (and N at most 4096) runs as two row ranges, so the 256-row
  tiles fit the first. π0's 832-row prefix: its down projection 6.7 -> 4.0 ms a layer.
- **Heads of 256 use one accumulator per subgroup.** Two long-lived 64 x 64 accumulators per subgroup hang the 850
  (driver bug #4), so P V runs once per 128 output dims.

`kernels/facombine_coalesced.comp` is a coalesced version of the key-split merge. It is **not tested on a device**
and not in the kernel table: see [`../pi0/README.md`](../pi0/README.md#next).

Every call records into the caller's command buffer and, unless `ABLASLT_NO_AUTO_BARRIER` is set, ends with a
barrier. `ABLASLT_DESCRIPTOR_SETS` switches AdrenoBLAS and this layer to ordinary descriptor sets, for hosts that
record their own descriptor-set dispatches in between (driver bug #13).

## The runner

`llama_lt.c` is Llama 3.2 3B written against this API only. Its forward pass is 7 calls per layer plus the final
norm and LM head:

```c
for (int l = 0; l < NL; ++l) {
  ablasLtRmsNorm(lt, c, M, D, x, l ? ssp : none, attn_norm[l], 1e-5f, h, ws);
  ablasLtMatmul(lt, c, &rope, h, &hl, wqkv[l], &wqkv_l, none, NULL, ws);   // -> q, k, vt
  ablasLtAttention(lt, c, M, NH, NKV, 1 / sqrtf(HD), q, k, vt, attn);
  ablasLtMatmul(lt, c, &residual, attn, &hl, wo[l], &wo_l, x, &xl, none);   // x += ...; ssp
  ablasLtRmsNorm(lt, c, M, D, x, ssp, ffn_norm[l], 1e-5f, h, none);
  ablasLtMatmul(lt, c, &swiglu, h, &hl, wgu[l], &wgu_l, act, &al, none);
  ablasLtMatmul(lt, c, &residual, act, &al, wd[l], &wd_l, x, &xl, none);
}
```

The runner is 196 lines, where `../llama3b/llama3b.c` is 406. All its layout code is gone: gate/up interleave,
embedding decode from the packed format, kernel files, tile-size files. It prefills any prompt length (rows padded
to 64), and `-g G` predicts G more tokens greedily by prefilling again. There is no KV cache yet (see Next).

## Results (Adreno 850, Qualcomm Device Cloud SM8975 QRD, 2026-11-22)

- **`lt_test`: all pass, at the first run on the device.** Host checks: packing, quantization and the gate/up
  layout, byte-identical to `llama3b.c`'s `interleave_gu`. GPU checks, max relative error against double-precision
  math on the same fp16 inputs:

  | check | error |
  |---|---|
  | fp16 matmul, M = 100, fp32 rows in and out | 1.9e-3 |
  | Q4_0 matmul, fp32 rows in and out | 2.2e-3 |
  | RESIDUAL | 1.0e-3 |
  | SWIGLU | 1.5e-3 |
  | ROPE_QKV | 1.7e-3 |
  | attention (grouped, 3 query heads per KV head) | 3.2e-4 |
  | RMSNorm, both forms | 4.8e-4 |

- **`llama_lt` against `ref.py`'s fp32 reference (512 tokens): the same accuracy as `llama3b`.**

  | | last-token logits cosine | top-1 | top-5 overlap | KL(ref ‖ device) | hidden-state cosine: mean / worst row |
  |---|---|---|---|---|---|
  | Q4_0 | 0.99997 | same | 5/5 | 5e-4 | 0.99992 / 0.9929 |
  | fp16 | 0.99997 | same | 4/5 | 5e-4 | 0.99993 / 0.9948 |

  The worst row is the chaotic row 327 of `../llama3b/README.md`.
  - A 500-token prompt (padded to 512 rows) gives rows 0-499 bit-identical to the 512-token run.
  - Greedy text continues the blog post coherently ("## Introduction\n\nIn this part of the blog series, we will
    explore how to accelerate the").
- **Speed: within 3-5% of the hand-written runner.** Same phone, alternating, each run started at <= 45 °C
  (`bench.sh`):

  | prefill | llama_lt | llama3b (hand-written) | |
  |---|---|---|---|
  | Q4_0, 512 tokens | 207.7 ms (2,465 tok/s) | 198.0 ms (2,586 tok/s) | +4.9% |
  | Q4_0, 1024 | 422.1 ms (2,426 tok/s) | 405.7 ms (2,524 tok/s) | +4.0% |
  | Q4_0, 2048 | 921.7 ms (2,222 tok/s) | 893.1 ms (2,293 tok/s) | +3.2% |
  | fp16, 512 | 219.2 ms (2,335 tok/s) | 213.8 ms (2,395 tok/s) | +2.5% |
  | fp16, 1024 | 452.2 ms (2,265 tok/s) | 434.5 ms (2,357 tok/s) | +4.1% |
  | fp16, 2048 | 987.4 ms (2,074 tok/s) | 957.6 ms (2,139 tok/s) | +3.1% |

  The difference is the unfused RoPE: the qkv GEMM writes fp16 rows that a second kernel turns into Q/K tiles and
  V^T. `llama3b` does this in the GEMM's epilogue.

## Running it

```bash
./build.sh
adb push build/lt_test build/llama_lt /data/local/tmp/l3b/
adb shell "cd /data/local/tmp/l3b && ./lt_test"
adb shell "cd /data/local/tmp/l3b && ./llama_lt -w w/llama3b_q4 -t tokens.bin -n 512 -o out"
adb pull /data/local/tmp/l3b/out/logits.bin /data/local/tmp/l3b/out/hidden.bin ../llama3b/out/
python ../llama3b/ref.py cmp q4 512 ../llama3b/out
adb push bench.sh /data/local/tmp/l3b/lt_bench.sh   # with ../llama3b/llama3b and its kernels/ there too
adb shell "cd /data/local/tmp/l3b && sh lt_bench.sh 'lt q4 512' 'old q4 512'"
```

The weights and `tokens.bin` are `../llama3b`'s (its README: `export.py`, `ref.py tokens`).

## Next

- **Decode:**
  - a KV cache in the tile layouts (appending row p touches only panel p / 64);
  - decode attention over the cache;
  - a GEMV for M = 1 (today M is padded to 64).
- **Fused `ROPE_QKV`:** `../llama3b/gen_fused.py`'s kernel, generated per shape, behind the same descriptor.
- **A prologue** converting fp32 A while loading, to drop the separate pack pass for fp32 hosts such as llama.cpp.
- **A heuristic query** returning the ranked kernels, and grouped GEMM for MoE.
