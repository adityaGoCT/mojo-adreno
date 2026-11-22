# llama.cpp with AdrenoBLAS: Llama 3.2 3B on the Adreno 850

A patch to llama.cpp's Vulkan backend (ggml-vulkan, llama.cpp `1fdda89`) that sends the matmuls on a model's
weights to AdrenoBLAS (`../ablas.h`) through AdrenoBLASLt (`../lt/ablasLt.h`), on the Adreno 850's matrix units.
It also fuses each FFN's gate and up matmuls and their SwiGLU into one GEMM. Everything else stays ggml's:
attention, norms, RoPE, the KV cache, sampling and the LM head. Measured on Qualcomm Device Cloud QRDs (SM8975,
Adreno 850, driver dbca1a4c11 / compiler E17.52.10.04, Android 17): Q4_0 2026-11-22, F16 2026-11-21.

## Results

`llama-bench -r 3 -ngl 99`, defaults otherwise (micro-batch 512, flash attention on), each test started with the
GPU unthrottled and at or below 45 °C (`vkbench.sh`). tokens/s:

| Llama 3.2 3B | pp512 | pp1024 | pp2048 | tg32 |
|---|---|---|---|---|
| **Q4_0**, llama.cpp Vulkan + AdrenoBLAS | **1,663** | **1,470** | **1,020** | 29.9 |
| Q4_0, the same without the SwiGLU fusion (`GGML_VK_ABLAS_SWIGLU=0`) | 1,484 | 1,323 | 946 | |
| Q4_0, llama.cpp Vulkan (stock) | 418 | 405 | 361 | 29.9 |
| speedup | **4.0x** | **3.6x** | **2.8x** | 1.0x |
| **F16**, llama.cpp Vulkan + AdrenoBLAS | **1,341** | **1,248** | **902** | 10.9 |
| F16, llama.cpp Vulkan (stock) | 344 | 336 | 306 | 10.9 |
| speedup | **3.9x** | **3.7x** | **2.9x** | 1.0x |

For reference, on the same phone:

| | pp512 | pp1024 | pp2048 |
|---|---|---|---|
| llama.cpp OpenCL (Adreno kernels), Q4_0 | 456 | 418 | 366 |
| llama.cpp OpenCL, F16 | killed for memory | | |
| AdrenoBLAS's own runtime (`../llama3b/`), Q4_0 | 2,602 | 2,410 | 2,248 |
| AdrenoBLAS's own runtime, fp16 | 2,318 | 2,305 | 2,143 |

`results/llamacpp_vulkan_bench.txt`. The F16 rows are from the previous version of the patch (2026-11-21: the
same matmul path through ablas.h directly, before AdrenoBLASLt; F16 has no fusion), not yet re-measured. That
version's Q4_0 was 1,439 / 1,272 / 924, within ±4% of the fusion-off row here.

### Accuracy

The AdrenoBLAS build gives the same answers as stock llama.cpp (`results/llamacpp_vulkan_accuracy.txt`):
- **Q4_0:** perplexity 31.3109 vs 31.3116 (8 chunks of 512), KL divergence ~0, top token the same at 100% of
  positions. The prefill GEMMs are bit-identical to ggml's own (`GGML_VK_ABLAS_MODE=verify`, all 196 at M = 512):
  both use the matrix units with fp16 operands, fp16 accumulators and the same k order.
  The same with the SwiGLU fusion (2026-11-22): perplexity 31.3109, KL divergence ~0, top token the same at 100%,
  greedy text on the ~900-token prompt identical to stock.
- **F16** (previous version of the patch): perplexity 29.5491 vs 29.5496 (8 chunks of 512), KL divergence ~0, top
  token the same at 100%.
- Greedy text: identical to stock for both models, short prompt + 40 tokens and a ~900-token prompt + 32 tokens.

## What limits it

- **Long prompts: ggml's flash attention.** pp2048 costs ~0.8 s more than four pp512s in both builds, the same
  absolute cost: ggml's flash attention runs at ~1 TFLOP/s here. At pp2048 it is about a third of the AdrenoBLAS
  build's time. The micro-batch size doesn't matter (`-ub 512/1024/2048` all give 916-937 tok/s), and `-fa 0`
  segfaults in stock llama.cpp too.
- **Short prompts: everything that isn't a GEMM.** The Q4_0 prefill of 512 tokens takes 308 ms (345 ms without the
  SwiGLU fusion). AdrenoBLAS's own runtime (`../llama3b/`, or `../lt/llama_lt` through the same library) takes
  197-208 ms. The other ~100 ms go to ggml's norms, RoPE, residual adds, KV-cache writes, attention, the activation
  packs, and the barriers between them. The runtime fuses RoPE and the residual adds into the GEMM epilogues and has
  every kernel write its output directly in the packed format.
- **Decode** is unchanged: memory-bound. Q4_0 keeps ggml's mat-vec kernels (on the original weights). F16
  (repacked in place) goes through AdrenoBLAS at M = 1 padded to 64 rows and still matches stock.

## How it works

`adrenoblas-ggml-vulkan.patch` (ggml-vulkan.cpp, ggml-vulkan-types.h, CMakeLists.txt; ~410 added lines), over
AdrenoBLASLt (`../lt/`, a hipBLASLt-style layer: matmuls described by operand layouts and an epilogue):

- **Which matmuls:** `MUL_MAT` whose weight is a `blk.*.weight`, F16 or Q4_0, 2D, both dimensions multiples of 64.
  `src1` and `dst` are fp32, so the GEMM is C[M,N] = X[M,K] W[N,K]^T.
- **Weights** are repacked once, on first use, into AdrenoBLAS's layouts (`ablasLtWeightPackDevice`), in a separate
  submission that is waited for.
  - Q4_0 weights get a **repacked copy** (+1.6 GB), so matmuls with fewer than 9 rows (decode) stay on ggml's
    mat-vec kernels.
  - F16 weights are **repacked in place** (through a 64 MB staging buffer), since a copy of the 5.6 GB of `blk.*`
    weights does not fit next to the model on an 11 GB phone.
  - Weights are keyed by (VkBuffer, offset): `tensor->data` is not unique, because every ggml-vulkan device buffer
    has the same fake base address. Keying by `data` made the F16 model reuse layer 2's weights for layer 23.
- **Activations:** `ablasLtPack` converts the fp32 input to fp16 tiles in ggml's `prealloc_y`, rows padded to 64.
  q/k/v share their input, so it is packed once.
- **GEMM:** `ablasLtMatmul`, EPILOGUE_DEFAULT, fp32 rows < M straight into `dst`. Tuned per LLM shape: 14-17 TFLOP/s
  Q4_0, 11-16 fp16 (`../results/llm_*_ef.json`).
- **The SwiGLU fusion** (Q4_0, copy mode). A graph's consecutive {MUL_MAT up, MUL_MAT gate, GLU SWIGLU} nodes become
  one `ablasLtMatmul` with EPILOGUE_SWIGLU, over a gate|up weight interleaved on the CPU from the two GGUF tensors.
  - The result stays in AdrenoBLAS's tiles for the down projection. That projection is the GLU's only consumer
    (checked with `ggml_can_fuse_subgraph` and the use counts), and it reads the tiles instead of packing.
  - The GLU's own tensor is never written.
  - This saves ggml's GLU kernel, one GEMM's launch, the fp32 gate/up outputs and the down projection's pack:
    +12% at pp512.
- **Ordinary descriptor sets, not push descriptors** (`ABLASLT_DESCRIPTOR_SETS`). On this driver, once ggml's
  descriptor-set dispatches are recorded between AdrenoBLAS's push-descriptor dispatches, every push-descriptor
  dispatch in the command buffer uses the last pushed descriptors (driver bug #13, `../../driver_bugs/`). The
  descriptor sets are freed in `ggml_vk_graph_cleanup` (`ablasLtReset`). ggml puts the barriers
  (`ABLASLT_NO_AUTO_BARRIER`).
- ggml's own fusions are turned off for the matmuls AdrenoBLAS takes.

## Build and run

```
cd ~/runix/llama.cpp && git checkout 1fdda89 && git apply ~/runix/mojo-adreno/ablas/llamacpp/adrenoblas-ggml-vulkan.patch
LLAMA=~/runix/llama.cpp ./build.sh        # build-android-vulkan (stock) and build-android-vulkan-ablas
export ADB_SERVER_SOCKET=... ANDROID_SERIAL=...
adb shell mkdir -p /data/local/tmp/lcpp/vk_stock /data/local/tmp/lcpp/vk_ablas
adb push ~/runix/llama.cpp/build-android-vulkan/bin-stripped/* /data/local/tmp/lcpp/vk_stock/
adb push ~/runix/llama.cpp/build-android-vulkan-ablas/bin-stripped/* /data/local/tmp/lcpp/vk_ablas/
adb push vkbench.sh Llama-3.2-3B-Instruct-Q4_0-pure.gguf Llama-3.2-3B-Instruct-F16.gguf /data/local/tmp/lcpp/
adb shell "cd /data/local/tmp/lcpp && ./vkbench.sh vk_ablas Llama-3.2-3B-Instruct-Q4_0-pure.gguf 'pp512 pp1024 pp2048 tg32'"
adb shell "cd /data/local/tmp/lcpp && ./vk_ablas/llama-completion -m Llama-3.2-3B-Instruct-F16.gguf -c 2048 -p 'The capital of France is' -n 40 --temp 0 -ngl 99 -no-cnv"
```

The GGUFs come from `unsloth/Llama-3.2-3B-Instruct` (convert_hf_to_gguf.py --outtype f16; `llama-quantize --pure
... Q4_0`). Pass `-c 2048`: the default 131k context's KV cache does not fit.

Environment switches (AdrenoBLAS build):

| variable | |
|---|---|
| `GGML_VK_ADRENOBLAS=0` | off: the build behaves like stock |
| `GGML_VK_ABLAS_MODE` | `auto` (default: Q4_0 copy, F16 in place), `inplace`, `copy`, `verify` (copy, and every AdrenoBLAS GEMM compared with ggml's after each graph) |
| `GGML_VK_ABLAS_MIN_M` | rows from which AdrenoBLAS takes a matmul on a weight that still has its original (default 9) |
| `GGML_VK_ABLAS_FILTER` | debugging: only weights whose name contains this string |
| `GGML_VK_ABLAS_SWIGLU=0` | no gate/up/SwiGLU fusion |
| `GGML_VK_ABLAS_DEBUG=1` | print each fused gate/up/SwiGLU GEMM and its kernel |
| `ABLAS_KERNEL_EP=<name>` | force a GEMM kernel (benchmarking) |

## Next

- **AdrenoBLAS flash attention in place of ggml's** (`../llama3b/gen_attn.py`, fa3: 5.4 TFLOP/s useful vs ~1).
  This is the biggest gain at long prompts. It needs Q/K/V packing from ggml's layouts, or a kernel that reads them
  directly.
- **More graph-level fusions** with AdrenoBLASLt's epilogues, as in the own runtime:
  - o and down GEMMs + residual add (EPILOGUE_RESIDUAL);
  - RMSNorm writing the q/k/v GEMMs' tiles;
  - RoPE into the qkv GEMM (EPILOGUE_ROPE_QKV, together with the attention).
  The gate/up + SwiGLU fusion is done.
- **F16 decode** through a GEMV for the packed layout instead of 64-row padding (it ties stock now, memory-bound).
