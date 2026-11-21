# Llama 3.2 3B prefill on the Adreno 850 with AdrenoBLAS (fp16 and Q4_0)

A prefill benchmark for `unsloth/Llama-3.2-3B-Instruct` in which every GEMM runs through AdrenoBLAS
(`../ablas.h`) on the Adreno 850's matrix units, with fp16 or Q4_0 weights, checked against an fp32 reference
built from transformers' own layers. Measured 2026-11-21 on a Qualcomm Device Cloud QRD (SM8975, Android 17,
stock Vulkan driver E17.52.10.04, 1.45 GHz).

## Results

Prefill of M tokens (this repo's blog posts, tokenized; BOS first), GPU time for the whole forward pass including
the LM head on the last token (the embedding gather runs on the CPU; wall clock adds ~1 ms). Best of 3 prefills
after a warm-up, each configuration started below 45 °C with no thermal cap (`bench.sh`); run-to-run spread ~3%.
FLOPs counted: linear layers + LM head + causal attention (useful FLOPs only).

| weights | M | prefill | tokens/s | TFLOP/s overall |
|---|---|---|---|---|
| Q4_0 | 512 | 196.8 ms | **2,602** | 15.2 |
| Q4_0 | 1024 | 425.0 ms | **2,410** | 14.1 |
| Q4_0 | 2048 | 910.9 ms | **2,248** | 13.5 |
| fp16 | 512 | 220.9 ms | **2,318** | 13.5 |
| fp16 | 1024 | 444.3 ms | **2,305** | 13.5 |
| fp16 | 2048 | 955.7 ms | **2,143** | 12.9 |

`results/llama3b_bench.txt`. The fp16 matrix peak is 17.5 TFLOP/s measured (17.8 theoretical at 6,144 fp16
multiply-adds per clock); at M = 512 the whole Q4_0 prefill runs at 87% of the measured peak.

### Against llama.cpp on the same phone

llama.cpp `1fdda89` (2026-11-21), OpenCL backend with its Adreno kernels (the 850 is in its A8X list),
`llama-bench -ngl 99 -n 0 -ub 512 -fa 0` (its best setting here: flash attention and micro-batch 2048 were slower),
same thermal gate (`lcpp_bench.sh`), tokens/s:

| | pp512 | pp1024 | pp2048 |
|---|---|---|---|
| llama.cpp OpenCL, Q4_0 (`--pure`, every weight Q4_0, same quantization as here) | 456 | 418 | 366 |
| llama.cpp OpenCL, Q4_0 (default: embedding/output in Q6_K) | 443 | 416 | 366 |
| **AdrenoBLAS, Q4_0** | **2,602 (5.7x)** | **2,410 (5.8x)** | **2,248 (6.1x)** |
| **AdrenoBLAS, fp16** | **2,318** | **2,305** | **2,143** |
| llama.cpp OpenCL, F16 | killed for memory (every load mode) | | |

`results/llamacpp_opencl_bench.txt`. llama.cpp's OpenCL kernels run on the ALUs; AdrenoBLAS uses the matrix units.
llama.cpp's F16 model doesn't run on this 11 GB phone: the process is killed for memory with every load mode (`-lm auto`,
`none`, `dio`). AdrenoBLAS's fp16 run reads the 6.4 GB of weights once into GPU-visible buffers (the memory is
unified) and fits.

### Accuracy

Against the fp32 reference with the same weights (`ref.py cmp`):

| | last-token logits cosine | top-1 | top-5 overlap | KL(ref ‖ device) | hidden-state cosine (mean over rows) |
|---|---|---|---|---|---|
| Q4_0, M = 512 | 0.99993 | same | 5/5 | 5e-4 | 0.99992 |
| Q4_0, M = 2048 | 0.99998 | same | 5/5 | 5e-4 | 0.99993 |
| fp16, M = 512 | 0.99994 | same | 5/5 | 4e-4 | 0.99994 |
| fp16, M = 2048 | 0.99998 | same | 4/5 | 8e-4 | 0.99993 |

The worst single row is 0.994 to 0.998. One row (token 327, "LO" in "TFLOP") is chaotic: a 1e-6 change of
RMSNorm's eps moves it between 0.993 and 0.9998 in every pipeline variant, and it is also the most noise-sensitive
row of the fp32 reference itself.

### Where the time went

Q4_0, M = 512:

| step | prefill | tok/s |
|---|---|---|
| first correct version: GEMMs in AdrenoBLAS, simple elementwise kernels, unfused attention | 311 ms | 1,647 |
| elementwise kernels remapped (lane = row, one 2 KB tile per subgroup) | 245 ms | 2,087 |
| flash attention (two-pass, scores staged through shared memory) | 236 ms | 2,166 |
| SwiGLU fused into the gate/up GEMM (`ABLAS_EPI_SWIGLU`) | 214 ms | 2,388 |
| RoPE fused into the qkv GEMM; residual add + RMS statistics fused into the o/down GEMMs | 200 ms | 2,560 |
| flash attention with the score work split between subgroups (fa3) | 198 ms | 2,588 |
| LLM-shape tuning (`../sweep_llm.py`), cooled | 197 ms | 2,602 |

At M = 2048 the same steps took Q4_0 from 1,367 ms to 911 ms and fp16 from 1,422 ms to 956 ms; the unfused
attention's softmax alone was 343 ms there (25%).

Per operation, Q4_0, M = 2048 (`llama3b -p`; two profiled runs of 894 and 903 ms, shares relative to each):

| op | ms | share | TFLOP/s | kernel |
|---|---|---|---|---|
| RMSNorm (tile writer) | 38.5 | 4.3% | | normtile2 |
| qkv + RoPE | 117.7 | 12.8% | 15.3 | qkv_rope_q4_2048 (q4_w2x4) |
| flash attention | 134.5 | 14.6% | 5.4 (useful; 1.5x that executed) | fa3 |
| o + residual | 77.4 | 8.6% | 14.0 | q4_w1x4_k32_ea |
| gate/up + SwiGLU | 348.6 | 37.9% | 16.6 | q4_w1x2_k32_eg |
| down + residual | 189.7 | 21.0% | 15.2 | q4_w4x2_k32_ea |
| LM head (M = 64) | 3.4 | 0.4% | 14.9 | q4_w1x1_k32 |

GEMMs are 80% of the time, at 14-17 TFLOP/s inside the model (17.1-17.7 in isolation; the model runs hot for
~1 s per prefill). Attention is the biggest remaining item at long prompts.

## How it works

- **One command buffer** per prefill, a barrier between operations, no CPU work in between.
- **GEMMs in AdrenoBLAS**, weights pre-packed by `export.py`: fp16 in the packed tile format (`ABLAS_OP_P`), Q4_0
  in AdrenoBLAS's Q4_0 layout (ggml rounding). Activations are written directly in the packed A format by the
  kernel that produces them, so no GEMM packs anything at run time.
- **Q4_0 dequantizes in registers.** On the 850 a 16 x 64 B matrix holds output column n in lane n and k in element
  k (`probe/map.comp`), so each lane expands its own column's 4-bit weights into the B operand. The Q4_0 GEMMs
  are faster than the fp16 ones (3.6x fewer weight bytes per multiply-add).
- **Fused epilogues** (`../epilogue.py`): the accumulator goes to shared memory and lane l handles row l.
  - qkv: RoPE, then Q and K as packed tiles per head and V transposed as the PV operand (`gen_fused.py`; the Q
    and K weight rows of each head are permuted to [0, 64, 1, 65, ...] at load time so rotate_half pairs are
    adjacent; Q K^T is unchanged by the common permutation).
  - gate/up: silu(gate) * up, packed for the down GEMM (gate and up rows interleaved 32 at a time at load time).
  - o and down: added into the fp32 residual stream with per-row sums of squares for the next RMSNorm.
- **Flash attention** (`gen_attn.py`, fa3): one workgroup per (head, 64-row query block), causal blocks only.
  - Two passes over the key blocks: row max and sum, then P V with P already normalized. No rescaling of the
    accumulator: on this driver, touching accumulator elements costs ~20 clocks each.
  - Scores go through shared memory, so each lane reads its own row.
  - The two subgroups split the key blocks and share their P tiles.

## Findings

- **The matrix unit's register layout is regular**: B lane = column, A lane = row, accumulator lane = row with
  element = column. Per-lane dequantization and lane-local softmax follow from it.
- **But element access is slow** (~20 clocks per accumulator element; a matrix-times-scalar is slower still), so
  epilogues and the softmax stage through shared memory instead.
- **Four more driver bugs** (#8-#11 in `../../urgent_matter.md`, repros in `probe/`):
  - element writes into an uninitialized cooperative matrix crash the compiler;
  - a constant-index write to element 4 of a B matrix is silently dropped;
  - constant-index reads of accumulator elements into a vector constructor crash it;
  - multiplies under per-subgroup branches crash its layout analysis.
- **Some 4-subgroup epilogue tiles run at half speed at some shapes**, so epilogue kernels are tuned separately.
- **The residual epilogue barely pays.** Reading and writing the fp32 residual inside the o/down GEMMs costs ~25 ms
  at M = 2048 and saves ~45 ms of RMSNorm: 894 vs 908 ms, and 198 vs 201 ms at M = 512.

## Files

```
export.py        HF safetensors -> weights/llama3b_{f16,q4}.bin + .idx (AdrenoBLAS B formats)
ref.py           fp32 reference (transformers LlamaDecoderLayer, one layer in memory at a time), token file, compare
llama3b.c        the benchmark (-p per-op profile, -o dumps for ref.py, -L n residual after n layers)
vkutil.h vkrun.c Vulkan helpers; a generic on-device kernel runner (bI=file | @bytes zeroed | ~bytes random)
kernels/         elementwise kernels (normtile2, addsq; rope2, silu2, normtile and the unfused attention kernels
                 kept for the ablation switches below)
gen_attn.py      attention kernels: unfused QK^T / softmax / PV, flash attention fa, fa2, fa3
gen_fused.py     the qkv GEMM + RoPE kernel (from ../gen.py / ../gen_q4.py with a custom epilogue)
build.sh         catalogue, kernels and Android binaries
bench.sh         cooled runs on the phone; lcpp_bench.sh the same for llama.cpp's llama-bench
probe/           cooperative-matrix element map, Q4 debug, driver-bug repros (probe/README.md)
```

Ablation switches (environment): `L3B_NOFA` (unfused attention), `L3B_FA=fa|fa2|fa3`, `L3B_NOFUSEQKV`,
`L3B_NOFUSERES`; `ABLAS_KERNEL` / `ABLAS_KERNEL_EP` force a GEMM kernel.

## Reproduce

```
python export.py q4 && python export.py f16          # ~10 min, 1.8 + 6.4 GB in weights/
python ref.py tokens && python ref.py q4 512          # fp32 reference (transformers 5.19)
./build.sh
export ADB_SERVER_SOCKET='tcp:[::1]:5037' ANDROID_SERIAL=<serial>
adb shell mkdir -p /data/local/tmp/l3b/kernels /data/local/tmp/l3b/w
adb push llama3b vkrun bench.sh ref/tokens.bin /data/local/tmp/l3b/ && adb push kernels/*.spv kernels/qkv_rope_tiles.txt /data/local/tmp/l3b/kernels/
adb push weights/llama3b_q4.* weights/llama3b_f16.* /data/local/tmp/l3b/w/   # ~25 min at 6-8 MB/s
adb shell "cd /data/local/tmp/l3b && ./llama3b -w w/llama3b_q4 -m 512 -p -o out"   # profile + dumps
adb pull /data/local/tmp/l3b/out/logits.bin /data/local/tmp/l3b/out/hidden.bin out/ && python ref.py cmp q4 512 out
adb shell "cd /data/local/tmp/l3b && ./bench.sh 'q4 512' 'q4 2048' 'f16 512' 'f16 2048'"
```

## Next

- **Attention at long prompts**:
  - a single-pass flash attention needs a cheap rescale of the output accumulator; on this driver that has to go
    through shared memory;
  - sharing K/V tiles across the 3 query heads of each KV group.
- **Decode** (M = 1): memory-bound GEMV kernels for Q4_0 and fp16, and a KV cache.
- **fp32 accumulation**: the shared-memory epilogue staging could carry it past driver bug #3.
