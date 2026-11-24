# Llama 3.2 1B on the Adreno 710, with Mojo kernels

Meta's **Llama-3.2-1B-Instruct** generating text on the GPU of a moto g stylus 5G (2024), on
Qualcomm's own Vulkan driver or on Mesa Turnip. Every GPU kernel is Mojo code (MAX's `gpu` module),
compiled through this repo's Mojo → SPIR-V pipeline; a small C program schedules them with Vulkan.

```
$ PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python
$ $PY llama/run.py --model ~/.cache/huggingface/hub/models--meta-llama--Llama-3.2-1B-Instruct/snapshots/<rev>
prompt: 46 tokens; model loaded and exported in 5 s
reference (PyTorch fp32 on the Mac CPU): 48 tokens in 4.0 s
phone (stock):
  device: Adreno (TM) 710  Vulkan 1.1
  weights: 103 tensors, 2.47 GB in 2.5 s
  plan: 150 dispatches per token
  prompt: 46 tokens in 11457 ms
The sky appears blue because of a phenomenon called Rayleigh scattering, in which shorter wavelengths
of light, such as blue and violet, are scattered more than longer wavelengths, like red and orange,
by the tiny molecules of gases in the atmosphere.
  decode: 47 tokens, 285.3 ms/token (3.50 tokens/s)

logits after the prompt: max |phone - PyTorch| = 6.20e-05 (logit range -7.1 .. 27.0)
tokens: phone 48, PyTorch 48, identical for the first 48
```

## How it fits together

MAX's graph compiler and runtime target NVIDIA, AMD, Apple and CPUs; there is no Android build and
no SPIR-V output, so MAX cannot run a model on this phone by itself. The demo keeps Mojo and MAX for
what reaches the device, the kernels, and replaces the rest:

```
Mac                                                         phone (adb)
llama/kernels/*.mojo  --mojo build --target-accelerator gfx90a-->  kernel LLVM IR
   (MAX gpu module)   --mojo2vk.py (opt, retarget, llc)--------->  SPIR-V  ---------->  llama_vk (Vulkan)
HF safetensors (bf16) --run.py export: fp16, fused, chunked-------->  weights.bin ------>    150 dispatches
chat prompt           --tokenizer------------------------------->  token ids -------->    per token, argmax
PyTorch (fp32 math on the same fp16 weights): reference tokens and logits   <-- token ids, logits
```

| kernel (`kernels/`) | work | launch |
|---|---|---|
| `embed` | x = one row of an fp16 embedding chunk | 8 x 256 |
| `rmsnorm` | x / sqrt(mean(x²) + eps) · w, shared-memory reduction | 1 x 256 |
| `gemv`, `gemv_add` | y = W x (`_add`: y += W x, the residual), fp16 W, one 64-lane warp per row | rows x 64 |
| `rope_kv` | RoPE on q in place; RoPE on k, then k and v into this layer's KV cache | 5 x 256 |
| `attention` | grouped-query decode attention (32 heads over 8 KV heads), scores in shared memory | 32 x 64 |
| `silu_mul` | silu(gate) · up | 32 x 256 |

Per token: `embed`, then per layer `rmsnorm`, `gemv` (fused q/k/v, 3072 rows), `rope_kv`, `attention`,
`gemv_add` (o_proj), `rmsnorm`, `gemv` (fused gate/up, 16384 rows), `silu_mul`, `gemv_add`
(down_proj); then the final `rmsnorm` and the tied lm_head as 4 `gemv`s over the embedding chunks.
Weights are fp16 (2.47 GB), activations and the KV cache fp32. The embedding is split into 4 chunks
of 125 MB because the stock driver binds at most 128 MB per storage buffer. The prompt runs through
the same decode path, one token at a time; greedy argmax runs on the phone's CPU.

`run.py` exports the weights (q/k/v and gate/up concatenated; RoPE cos/sin tables from transformers'
own rotary class, so the Llama 3 frequency scaling matches), runs the PyTorch reference with the same
fp16-rounded weights, builds the kernels (`build_kernels.py`) and the runtime (`llama_vk.c`, NDK),
pushes them, runs, streams the decoded text and compares tokens and logits. `--model random` builds
a randomly initialised model of the same shape, which tests the whole path without the download.

## Results

Prompt "Explain in two sentences why the sky is blue." (46 tokens with the Llama 3 chat template),
48 new tokens, greedy:

| backend | prompt (46 tokens) | decode | tokens identical to PyTorch | max logit difference |
|---|---|---|---|---|
| stock (Qualcomm Vulkan 1.1) | 11.5 s | 283-285 ms/token (3.5 tokens/s) | 48 of 48 | 6.2e-5 |
| turnip (Mesa) | 11.4 s | 282 ms/token (3.55 tokens/s) | 48 of 48 | 6.2e-5 |

Decode reads all 2.47 GB of weights per token; at the 15.8 GB/s measured in Part 2 the floor is
156 ms/token, so both drivers run at 55% of the bandwidth limit. One token, one dispatch per submit
(`LLAMA_DEBUG=1`, which adds about 0.4 ms of submit overhead to each):

| kernel | count | stock, warp sum as shuffles | stock now | turnip now |
|---|---|---|---|---|
| `gemv` gate/up (16384 x 2048) | 16 | 46.5 ms each | 14.7 ms each | 14.5 ms each |
| `gemv` lm_head chunk (32064 x 2048) | 4 | 83.7 ms each | 27.0 ms each | 27.1 ms each |
| `gemv_add` o/down | 32 | 7.6 ms each | 4.9 ms each | 4.9 ms each |
| `gemv` q/k/v (3072 x 2048) | 16 | 10.1 ms each | 3.0 ms each | 3.0 ms each |

### Adreno 840 (Galaxy S26 Ultra) and batched prefill on cooperative matrices

The same run on a Galaxy S26 Ultra (Snapdragon 8 Elite Gen 5, Adreno 840, Qualcomm's Vulkan 1.4
driver) in Samsung's Remote Test Lab, stock kernels: the 46-token prompt in 1.83 s, decode at
41.1 ms/token (24.4 tokens/s), 48 of 48 tokens identical to PyTorch, logits within 6.1e-5. The
weights cross the lab's bridge at 2.3 MB/s, 18 minutes for 2.47 GB; it drops a shell command with
`&&`, so `run.py` sends plain ones.

With `--prefill`, the prompt runs through the layers once, all tokens together, instead of one
token at a time: `kernels/prefill/` are batched versions of the decode kernels, compiled with
Mojo's own SPIR-V target for `adreno840`, and `p_gemm` computes each projection as one matrix
product on KHR cooperative matrices (fp32 x fp32 -> fp32, 64 x 64 x 8; the fp16 weights are
converted while they are staged in shared memory, so the math stays fp32). A long prompt
(`prompts/long.txt`, 431 tokens, padded to 512 rows):

| prompt, 431 tokens | time | tokens identical to PyTorch | max logit difference |
|---|---|---|---|
| one token at a time | 17.7 s | 48 of 48 | 5.3e-5 |
| batched prefill (`--prefill`) | **0.63 s** (28x) | 48 of 48 | 6.0e-5 |

Measured on the Android 17 S26 Ultra (the first version of `p_gemm`, below, took 1.29 s against
17.3 s on the Android 16 one). Decode afterwards is unchanged (43 ms/token). Per kernel
(`LLAMA_PROFILE=1`, each dispatch on its own submit): `p_gemm` 556-586 ms for the 64 projections,
about 1.7-1.8 TFLOP/s averaged over its four shapes (1221 ms, 0.8 TFLOP/s, with the first version);
attention 46 ms, fused (100 ms before, below); the rest 50 ms. On the 840's driver a matmul whose accumulator starts as a matrix loaded
from memory fails to compile (VK_ERROR_UNKNOWN), so the residual is a separate `p_add`.

`p_gemm` now stages W with consecutive threads on consecutive addresses (each thread used to read
its own row of W) and reads B = W^T column-major from shared memory. Alone on the phone, 512 rows,
against NumPy:

| projection | before | now |
|---|---|---|
| gate/up, 16384 x 2048 | 1.77 TFLOP/s | 2.09 TFLOP/s |
| down, 2048 x 8192 | 1.10 TFLOP/s | 1.91 TFLOP/s |

A K step of 32 would read longer runs of W, but fills the 840's 32 KB of shared memory exactly,
which gave wrong results; the K step is 16.

`p_attention` is fused: one subgroup takes 64 prompt tokens of one head, and for each block of 64
keys up to the diagonal computes S = Q K^T on cooperative matrices (8 fp32 products, K read
column-major from the KV cache) into shared memory, where each thread owns a query row. A first
pass finds each row's softmax max and sum; a second recomputes S, turns it into probabilities and
accumulates O += P V on the matrix units, so O never needs the per-row rescaling an opaque matrix
cannot do. At 512 rows: 2.72 ms a layer against 5.81 for one workgroup per token (max error 1.0e-6
against NumPy); end to end the prompt went from 0.68 s to 0.63 s.

The lab's bridge can be slow (it dropped to 0.16 MB/s, four hours for the weights), and the lab
wipes the phone between sessions. The phone can fetch the weights itself instead:
`st2bin_recipe.py` writes, from the local `model.safetensors`, which bf16 byte ranges become which
fp16 tensors of `weights.bin`; the phone downloads the same file with `curl` (a public mirror with
the same SHA-256) and `st2bin.c` converts it in seconds. The result is byte-identical to the Mac's
export (SHA-256), so `run.py` skips the push.

### 4-bit weights

`--quant q4` quantizes every projection and the lm_head to int4: symmetric, one fp16 scale per 64
weights of a row, 8 weights per 32-bit word (`run.py`'s `quantize4`). The embedding lookup stays
fp16, so the lm_head gets its own quantized copy. The model is 1.18 GB, of which about 0.65 GB is read
per token instead of 2.47 GB. `gemv_q4` and `gemv_add_q4` unpack 8 weights per word for decode;
`p_gemm_q4` unpacks them into fp32 while it stages W for prefill, so the matrix units still multiply
in fp32. The PyTorch reference uses the same dequantized weights. On the S26 Ultra (Android 16
driver), the 431-token prompt, the same session:

| | fp16 | int4 |
|---|---|---|
| decode | 43.4 ms/token (23 tokens/s) | **13.4-14.9 ms/token (67-75 tokens/s)** |
| prompt, one token at a time | 17.8 s | 5.5 s |
| prompt, batched (`--prefill`) | 0.63 s (Android 17 driver) | 0.62 s |
| tokens identical to PyTorch on the same weights | 48 of 48 | 48 of 48 (logits within 1.1e-4) |

Decode is 2.9-3.2x faster for 3.8x fewer bytes: unpacking costs some compute, and attention, the
norms and the dispatches do not shrink. Prefill barely changes: it is limited by arithmetic, not by
the weights' bytes (`p_gemm_q4` alone runs at 1.7-2.1 TFLOP/s, like `p_gemm`). The int4 answer
differs from the fp16 model's from the first token ("The passage states that..." against "According
to the passage, ...") and still answers the question. `st2bin_recipe.py --q4` builds the int4
weights on the phone from the downloaded `model.safetensors`, byte-identical to the export.

On the 840's Android 16 driver build the fused `p_attention` fails to link ("Failed to link
shaders"; one cut-down variant ran out of registers), so `llama_vk` falls back to
`p_attention_scalar`, one workgroup per token (99 ms instead of 46 for the 16 layers).

### In Mojo, through DeviceContext

[`model.mojo`](model.mojo) is `llama_vk.c`'s decode as MAX `DeviceContext` launches of the same
kernels, and [`llama.mojo`](llama.mojo) the program around it. It takes `llama_vk`'s arguments and
prints its lines, so `run.py --runner mojo` checks it against PyTorch. Built for Android
(`android/build.py llama`), it runs through the Vulkan driver plugin (`driver/`). On the S26 Ultra,
both runs below match PyTorch for all 48 tokens:
- fp16: 24.7 tok/s (40.6 ms a token), logits within 7.3e-5;
- `--quant q4`: 78.1 tok/s (12.8 ms), logits within 6.7e-5.

That is as fast as `llama_vk`, which records a token's dispatches once: decode is bound by the
weights' bytes.

`Llama.prefill` runs the whole prompt at once with the kernels of `kernels/prefill`, launched per
layer as `llama_vk.c`'s prefill plan records them. The matmuls run on cooperative matrices, and the
embedding rows come from the decode `embed` kernel. `llama.mojo` uses it when `LLAMA_PREFILL` is
set, as `run.py --runner mojo --prefill` does. On a Galaxy Z Fold (SM-F976U, Adreno 840, Android
17), the 431-token prompt of `prompts/long.txt`:

| | Prompt | Then decode | Against PyTorch |
|---|---|---|---|
| fp16, `llama.mojo` | 0.65 s | 40.2 ms a token | 48 of 48 tokens; logits within 4.8e-5 |
| 4-bit, `llama.mojo` | 0.59 s | 13.7 ms a token | 48 of 48 tokens; logits within 8.3e-5 |
| fp16, `llama_vk` | 0.62 s | 40.0 ms a token | |

The first run on a phone also compiles the pipelines. On this driver build, the fused attention
`p_attention` takes 39 s and `p_gemm` 3 s, for `llama_vk` too, which compiles them before it times
anything. The driver plugin keeps a pipeline cache file, so later runs load them in under a
millisecond.

#### Prefill on fp16 cooperative matrices (`LLAMA_GEMM=q`)

`p_gemm` and `p_gemm_q4` multiply on fp32 cooperative matrices (64 × 64 × 8). The 840 has no matrix
unit, and its fp16 product (64 × 64 × 16) runs at twice their ceiling. With `LLAMA_GEMM=q`
(`run.py --env LLAMA_GEMM=q`), `Llama.prefill` uses `lfm2/kernels/lkh.mojo` instead, as Qwen3-4B's
`QWEN3_GEMM=q` does. For each projection:
1. `pack_x` packs X into fp16 tiles in the layout the 840 reads fastest.
2. `gemm_hq` unpacks W's rows (int4 with a scale per 64, or fp16) into fp16 shared memory inside the
   product. W keeps its one copy, shared with decode.
3. K is split into chunks of 1024, each written as an fp16 partial product. `sum_parts` adds the
   chunks in fp32.

On the Fold, the 431-token prompt, three rounds, each run after the GPU cooled to 45 °C:

| Weights | Prompt, fp32 products | Prompt, `LLAMA_GEMM=q` | Against PyTorch on the same weights |
|---|---|---|---|
| 4-bit | 590–594 ms | **331–334 ms (1.78×)** | 48 of 48 tokens; logits within 0.18 |
| fp16 | 637–642 ms | **375–402 ms (1.66×)** | 48 of 48 tokens; logits within 0.31 |

Against the same run without the switch (whose logits are within 7.5e-5 of PyTorch's), the KL at the
prompt's last position is 4.5e-4 (4-bit) and 2.5e-5 (fp16). Decode is unchanged.

The 840 rounds every partial sum of an fp16 product to fp16, so the chunks are short. With chunks of
2048, the 4-bit logits moved by up to 0.39 and the KL was 5.7e-3. That was enough to flip the first
token, a near tie: "According" scores 27.42 and "The" 27.26 (probabilities 0.53 and 0.45). Chunks
of 1024 cost 15 ms more and give 48 of 48 tokens.

Each product alone (`bench_hq`, `android/build.py llamahq`; 512 rows, chunks of 1024, with `pack_x`):

| Projection | `p_gemm_q4` | `gemm_hq`, int4 | `p_gemm` | `gemm_hq`, fp16 |
|---|---|---|---|---|
| q/k/v, 3072 × 2048 | 2.09 TFLOP/s | 4.32 | 1.84 | 4.35 |
| o, 2048 × 2048 | 1.85 | 3.84 | 1.66 | 3.59 |
| gate/up, 16384 × 2048 | 2.12 | 4.98 | 2.02 | 4.34 |
| down, 2048 × 8192 | 1.73 | 2.94 | 1.52 | 2.58 |

### Llama 3.2 3B (`llama3.mojo`)

`model.mojo` and the kernels it shares with `llama_vk.c` have Llama 3.2 1B's shapes compiled in. `model3.mojo` is the
same forward pass with every size read from the manifest, so it runs any Llama 3.x. Here that is
[`unsloth/Llama-3.2-3B-Instruct`](https://huggingface.co/unsloth/Llama-3.2-3B-Instruct) (revision `006f5dcd`, the same
weights as Meta's): 28 layers, hidden 3072, 24 query heads and 8 KV heads of 128, MLP 8192.
- **Kernels:** the 1B's int4 matrix-vector and prefill products take their sizes as arguments already.
  `kernels/lg.mojo` adds the rest with sizes as arguments: embedding, RMS norm, RoPE, and decode attention scores for
  any number of query heads per KV head (3 here).
- **Attention:** for the prompt, gemma4's kernels run it on the matrix units, as for Qwen3-4B. A token's attention
  values are gemma4's too. Both read a position-major KV cache, and RoPE scales q by 1/√128 as it rotates it.
- **`run3.py`** exports int4 a tensor at a time (2.50 GB), runs the program on the phone and checks it.
  `reference3.py` is transformers' own `LlamaDecoderLayer`, a layer at a time in fp32, on the same int4 weights,
  teacher-forced on the phone's tokens. The whole fp32 model would not fit next to everything else in the Mac's 17 GB.
- **Weights:** the lab's bridge pushed at about 1 MB/s, so the phone downloaded the checkpoint's two shards itself
  (6.4 GB at about 9 MB/s) and joined them. `st2bin` converted them with `run3.py --recipe`'s recipe, byte for byte
  the Mac's export (SHA-256 `eb1ada05…`).

On the Fold, three rounds each (two for the short prompt), each run after the GPU cooled to 45 °C:

| Llama 3.2 3B, int4 | Prompt, fp32 products | Prompt, `LLAMA_GEMM=q` | Decode |
|---|---|---|---|
| 431 tokens (`prompts/long.txt`) | 1,604–1,615 ms (267–269 tokens/s) | **868–882 ms (489–497 tokens/s, 1.84×)** | 33.6–34.2 ms a token (29.5 tokens/s) |
| 46 tokens (the sky) | 408 ms (113 tokens/s) | **200–205 ms (224–230 tokens/s, 2.0×)** | 29.9–30.1 ms a token |

| Check against `reference3.py` | Max \|phone − reference\| after the prompt | KL | Greedy = reference |
|---|---|---|---|
| 431 tokens, fp32 products | 5.3e-5 (logits −9.2 … 27.0) | 2.3e-11 | 48 of 48 |
| 431 tokens, `LLAMA_GEMM=q` | 0.19 | 1.1e-4 | 48 of 48 (the same tokens) |
| 46 tokens, fp32 products | 5.2e-5 | 8.9e-12 | 48 of 48 |
| 46 tokens, `LLAMA_GEMM=q` | 0.14 | 9.3e-5 | 48 of 48 |

The answer starts "According to the passage, reading a prompt is faster than generating text because…" on the long
prompt, and "The sky appears blue because of a phenomenon called Rayleigh scattering…" on the short one. The products
use chunks of 1024, as the 1B's do. A decode step reads the int4 weights, 1.71 GB of the 2.50 (the fp16 embedding
gives only a row), in 34 ms: about 50 GB/s, as for the 1B. The switch does not change decode.

#### Faster: the glue fused, attention reworked

Profiling the switch's prompt (`LLAMA_PROFILE=1`) showed the products already at 4–5.5 TFLOP/s and 40% of the time
around them: packing X into fp16 tiles, adding the K chunks' partial products, SiLU, the residual adds and
attention. `model3.mojo`'s `layer_q` now fuses that glue:
- **The norms write the next product's fp16 tiles directly.** `lg.norm_scale` computes each row's scale, and
  `lg.norm_pack_t` writes the normed rows as whole tiles. So q/k/v and gate/up have no `pack_x`.
- **gate/up's partials go straight to the down product's input.** `lkh.swiglu_pack_t` adds them, applies
  silu(gate) × up and writes the packed tiles. A workgroup stages a 64 × 64 block in shared memory and writes whole
  2 KB tiles; a thread writing its own 8 values scattered 32-byte pieces 2 KB apart.
- **o's and down's partials are added straight into the residual stream** (`lkh.sum_parts_add`).
- **Attention** (`lg.p_scores_packed`, `lg.p_softmax`, `lg.p_values`): one 64 × 64 score tile per workgroup, 8× the
  workgroups. The scores are laid out [head][row][key], so P V's operand rows are 2 KB apart, not 48 KB. RoPE also
  writes q as contiguous 64 × 8 tiles (`lg.rope_pack`). Writing k transposed as well cost more in scattered stores
  than it saved.
- **down** (k = 8192) runs 128-deep K steps, 6% faster for it (`llama/bench_hq.mojo` shapes 8–11).

`LLAMA_FUSE=0` runs the switch as committed before this, and `LLAMA_SYNTH=1` runs with synthetic weights filled on
the GPU (only the manifest on the phone). The synthetic weights time within 1% of the real ones. On a Galaxy Z Fold
with the real weights, three rounds each, each run after the GPU cooled to 45 °C:

| Llama 3.2 3B, int4, prompt | 431 tokens | 46 tokens (synthetic weights) |
|---|---|---|
| fp32 products | 1,610–1,617 ms (267 tokens/s) | 411–416 ms |
| `LLAMA_GEMM=q`, each projection alone (`LLAMA_FUSE=0`) | 870–877 ms (493 tokens/s) | 207–209 ms |
| **`LLAMA_GEMM=q`** | **748–756 ms (570–576 tokens/s, 2.15×)** | **184–195 ms** |
| `LLAMA_GEMM=q LLAMA_CH=2048` | 672–676 ms (638–641 tokens/s, 2.4×) | 178–181 ms |

Against `reference3.py`, `LLAMA_GEMM=q` gives 48 of 48 tokens on both prompts: logits within 0.13, KL 1.7e-4
(431 tokens) and 5.1e-5 (46). `LLAMA_CH=2048` puts the products' K in chunks of 2048, half as many fp16 partial
planes. It is 11% faster but less accurate: KL 4.2e-4 and 6.4e-4, and 47 of 48 tokens on the long prompt. At
position 43 it picks " This" where the reference picks " Matrix" (logits 24.00 vs 24.19). So 1024 stays the default.

Where the 750 ms go (`LLAMA_PROFILE=1`, which waits after each kind of launch): the four products about 580 (gate/up
260, down 170, q/k/v 90, o 60; up to 5.6 TFLOP/s); attention, the norms, RoPE and the fused glue the other 170.

**Against AdrenoBLAS.** AdrenoBLAS's Llama 3.2 3B prefill (2,602 tokens/s at 512 tokens, Q4_0) runs on the Adreno 850,
whose matrix units reach 17.5 TFLOP/s. The 840 has none: its fp16 cooperative matrices run on the ALUs, at most about
7.3 TFLOP/s, 7.0 in the best GEMM so far (the GEMM worklog's Adreno 840 companion,
[adreno-gemm-worklog](https://github.com/adityaGoCT/adreno-gemm-worklog)). On the 840, AdrenoBLAS's own GEMMs (an fp16 ALU backend)
reach 3.1–3.6 TFLOP/s, below these products' 4–5.6. The remaining gap here is to the 840's own ceiling.

### A/B against GLSL: what the route through LLVM IR cost

The stock driver first ran this model at 1,392 ms/token, 4.9x slower than now. To see whether the
Mojo -> LLVM -> SPIR-V route or the driver was to blame, the same GEMV was written in GLSL
([`ab/`](ab/): same bindings, same 64 threads per row, same loads) and compiled with the NDK's
`glslc`. Gate/up GEMV on the stock driver, ms per dispatch:

| variant | ms | result |
|---|---|---|
| Mojo route, warp sum as 6 generic subgroup shuffles (`llvm.spv.wave.readlane`) | 46.5 | correct |
| GLSL, 6 generic `subgroupShuffle` (`ab/gemv_shuf.comp`) | 45.6 | correct |
| GLSL, 6 `subgroupShuffleXor` (`ab/gemv_xor.comp`) | 14.6 | **wrong** |
| GLSL, `subgroupAdd` (`ab/gemv.comp`) | 13.7 | correct |
| Mojo route, warp sum as one `OpGroupNonUniformFAdd` (now) | 14.7 | correct |

Qualcomm's compiler runs generic subgroup shuffles slowly, and LLVM 22's SPIR-V backend has no other
kind (`llvm.spv.wave.readlane`). The xor form is fast but wrong there: the driver does not reconverge
a subgroup after the loop, and offers neither `VK_KHR_shader_subgroup_uniform_control_flow` nor
`VK_KHR_shader_maximal_reconvergence`. A native reduction is fast and right, so `mojo2vk.py` now
recognizes Mojo's warp sum (on gfx90a: 4 DPP moves and 2 `ds.bpermute` hops, each followed by an add)
and emits one `llvm.spv.wave.reduce.sum` for workgroups of at most 64 threads. On Turnip both routes
were already equal (14.1 ms Mojo, 14.5 ms GLSL). The SPIR-V shrank from 279 to 199 instructions
(GLSL: 114).

To repeat the A/B: compile `ab/*.comp` with `glslc -O --target-env=vulkan1.1`, copy the stock kernel
directory on the phone, replace `gemv.spv` (and `gemv_add.spv`), and run `llama_vk` on it with
`LLAMA_DEBUG=1`.

## What it took

| problem | fix |
|---|---|
| Mojo's LLVM prints `f0x3FB8AA3B` and `-1.000000e+30`; LLVM 22 rejects both | `mojo2vk.py` rewrites float literals to LLVM 22's forms |
| Mojo lowers `exp` / `rsqrt` to `llvm.amdgcn.exp2` / `llvm.amdgcn.rsq` | mapped to `llvm.exp2` / `1 / llvm.sqrt` (OpenCL: `exp2`, `rsqrt`) |
| int32 narrowing (stock driver) clamped the mask `0x7FFFFFFE00` to `INT32_MAX`: wrong attention | constants wrap in bitwise / wrapping arithmetic, clamp in compares and selects |
| `if / elif / elif` in `rope_kv`: invalid structured control flow from LLVM 22 | one `if / else` over exactly 1280 threads |
| attention hung on the stock driver (device lost after 4-12 s) | every thread runs the same number of loop iterations |
| then attention was 64x off on the stock driver: shuffles after the masked loop read inactive lanes | shared-memory reductions with barriers (Vulkan does not promise reconvergence) |
| stock-driver GEMVs 3.4x slower than the same GLSL: generic subgroup shuffles are slow there, the xor form is wrong | Mojo's warp sum becomes one native subgroup reduction |
| `out` is a Mojo keyword | parameters renamed |

## Reproduce

```bash
PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python               # torch 2.14.1, transformers 5.19.0
hf auth login                                                          # an account that accepted the license
hf download meta-llama/Llama-3.2-1B-Instruct model.safetensors config.json generation_config.json \
    tokenizer.json tokenizer_config.json special_tokens_map.json
$PY llama/run.py --model random --max-new 8                            # same shapes, random weights
$PY llama/run.py --model <snapshot dir> --prompt "..." --max-new 48    # stock driver
$PY llama/run.py --model <snapshot dir> --backend turnip               # Mesa Turnip
$PY llama/run.py --model <snapshot dir> --backend native               # Turnip, Mojo's own SPIR-V target
$PY llama/run.py --model <snapshot dir> --prefill --prompt-file llama/prompts/long.txt  # Adreno 8xx
$PY llama/run.py --model <snapshot dir> --runner mojo --prefill --quant q4 --prompt-file llama/prompts/long.txt \
    --env LLAMA_GEMM=q                                                 # prefill on fp16 cooperative matrices
$PY llama/run3.py --model <Llama-3.2-3B-Instruct snapshot> --export-only   # build/llama/llama3b-q4 (2.50 GB)
$PY llama/run3.py --model <snapshot> --prompt-file llama/prompts/long.txt --check [--env LLAMA_GEMM=q]
```

`--backend native` compiles the kernels with a source-built Mojo that has the `adreno710` Vulkan
target ([Native SPIR-V target](../README.md#native-spir-v-target)): 283.6 ms/token, 48 of 48 tokens.

The weights are not part of this repo (Llama 3.2 Community License); `run.py` writes the fp16 export
to `build/llama/` and the phone copy to `/data/local/tmp/llama/<model>`.

## Limits

Batch 1, greedy only, 512 positions, fp16 weights (2.47 GB on the phone), the prompt processed
token by token (batched with `--prefill`, Adreno 8xx only), the tokenizer on the Mac.
