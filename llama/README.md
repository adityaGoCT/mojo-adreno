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
```

`--backend native` compiles the kernels with a source-built Mojo that has the `adreno710` Vulkan
target ([Native SPIR-V target](../README.md#native-spir-v-target)): 283.6 ms/token, 48 of 48 tokens.

The weights are not part of this repo (Llama 3.2 Community License); `run.py` writes the fp16 export
to `build/llama/` and the phone copy to `/data/local/tmp/llama/<model>`.

## Limits

Batch 1, greedy only, 512 positions, fp16 weights (2.47 GB on the phone), the prompt processed
token by token (batched with `--prefill`, Adreno 8xx only), the tokenizer on the Mac.
