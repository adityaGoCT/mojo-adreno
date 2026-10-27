# Llama 3.2 1B on the Adreno 710, with Mojo kernels

Meta's **Llama-3.2-1B-Instruct** generating text on the GPU of a moto g stylus 5G (2024), on
Qualcomm's own Vulkan driver or on Mesa Turnip. Every GPU kernel is Mojo code (MAX's `gpu` module),
compiled through this repo's Mojo → SPIR-V pipeline; a small C program schedules them with Vulkan.

```
$ PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python
$ $PY llama/run.py --model ~/.cache/huggingface/hub/models--meta-llama--Llama-3.2-1B-Instruct/snapshots/<rev>
prompt: 46 tokens; model loaded and exported in 4 s
reference (PyTorch fp32 on the Mac CPU): 48 tokens in 3.8 s
phone (stock):
  device: Adreno (TM) 710  Vulkan 1.1
  weights: 103 tensors, 2.47 GB in 3.2 s
  plan: 150 dispatches per token
  prompt: 46 tokens in 62234 ms
The sky appears blue because of a phenomenon called Rayleigh scattering, in which shorter wavelengths
of light, such as blue and violet, are scattered more than longer wavelengths, like red and orange,
by the tiny molecules of gases in the atmosphere.
  decode: 47 tokens, 1392.0 ms/token (0.72 tokens/s)

logits after the prompt: max |phone - PyTorch| = 6.89e-05 (logit range -7.1 .. 27.0)
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
| stock (Qualcomm Vulkan 1.1) | 62.2 s | 1392 ms/token (0.72 tokens/s) | 48 of 48 | 6.9e-5 |
| turnip (Mesa) | 11.2 s | 276 ms/token (3.63 tokens/s) | 48 of 48 | 6.9e-5 |

Decode reads all 2.47 GB of weights per token; at the 15.8 GB/s measured in Part 2 the floor is
156 ms/token, so Turnip runs at 57% of the bandwidth limit. One token, one dispatch per submit
(`LLAMA_DEBUG=1`, which adds about 0.4 ms of submit overhead to each):

| kernel | count | stock | turnip |
|---|---|---|---|
| `gemv` gate/up (16384 x 2048) | 16 | 46.3 ms each (1.4 GB/s) | 14.2 ms each (4.7 GB/s) |
| `gemv` lm_head chunk (32064 x 2048) | 4 | 82.9 ms each | 26.9 ms each |
| `gemv_add` o/down | 32 | 7.7 ms each | 4.9 ms each |
| `gemv` q/k/v (3072 x 2048) | 16 | 10.5 ms each | 2.9 ms each |
| everything else | 82 | 42 ms in all | 42 ms in all |

The stock driver runs the GEMVs at about a third of Turnip's speed. Two experiments ruled out the
obvious causes: reading the weights as packed 32-bit words (two halves per load) and putting four
rows in a 256-thread workgroup both left it unchanged.

## What it took

| problem | fix |
|---|---|
| Mojo's LLVM prints `f0x3FB8AA3B` and `-1.000000e+30`; LLVM 22 rejects both | `mojo2vk.py` rewrites float literals to LLVM 22's forms |
| Mojo lowers `exp` / `rsqrt` to `llvm.amdgcn.exp2` / `llvm.amdgcn.rsq` | mapped to `llvm.exp2` / `1 / llvm.sqrt` (OpenCL: `exp2`, `rsqrt`) |
| int32 narrowing (stock driver) clamped the mask `0x7FFFFFFE00` to `INT32_MAX`: wrong attention | constants wrap in bitwise / wrapping arithmetic, clamp in compares and selects |
| `if / elif / elif` in `rope_kv`: invalid structured control flow from LLVM 22 | one `if / else` over exactly 1280 threads |
| attention hung on the stock driver (device lost after 4-12 s) | every thread runs the same number of loop iterations |
| then attention was 64x off on the stock driver: shuffles after the masked loop read inactive lanes | shared-memory reductions with barriers (Vulkan does not promise reconvergence) |
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
```

The weights are not part of this repo (Llama 3.2 Community License); `run.py` writes the fp16 export
to `build/llama/` and the phone copy to `/data/local/tmp/llama/<model>`.

## Limits

Batch 1, greedy only, 512 positions, fp16 weights (2.47 GB on the phone), the prompt processed
token by token, the tokenizer on the Mac. The stock driver's GEMVs are about 3x slower than Turnip's.
