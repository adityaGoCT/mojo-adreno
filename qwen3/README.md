# Ternary Qwen3-8B on the Adreno 840

PrismML's **Ternary-Bonsai-8B** (`prism-ml/Ternary-Bonsai-8B-mlx-2bit`, revision `9260b242`): Qwen3-8B
with every projection and the output head ternary (-1, 0, +1 times a scale per 128 weights), stored
as MLX 2-bit groups. 36 layers, hidden 4096, 32 query and 8 KV heads of 128, MLP 12288, vocabulary
151,669, YaRN RoPE. On the GPU it is 2.19 GB.

On Qualcomm's SM8850 reference phone (Adreno 840, driver 512.842.25, Qualcomm Device Cloud):

```
$ python qwen3/run.py --model OUT --hf CKPT
prompt: 'What is the capital of France?', 19 tokens; checking 16 steps
weights: 441 tensors, 2.19 GB in 0.7 s, context 128
plan: 615 dispatches per token
check  0: token    785 reference    785  max abs 0.006471  rel L2 0.00078932 OK
  ...
check 15: token  59108 reference  59108  max abs 0.008191  rel L2 0.00055052 OK
decode: 15 tokens, 40.5 ms/token (24.72 tokens/s)
validation: 16 steps, max abs logit error 0.008191, all greedy ids match
output: 'The capital of France is Paris.<|im_end|>\n\nParis is a city in the Î'

$ python qwen3/run.py --model OUT --hf CKPT --prompt 'Explain in two sentences why the sky is blue.' --tokens 96
decode: 56 tokens, 40.0 ms/token (24.99 tokens/s)
output: "The sky appears blue because sunlight, which contains all colors of the spectrum, is scattered more
efficiently by the atmosphere's molecules and small particles. This scattering, known as Rayleigh
scattering, is stronger for shorter wavelengths like blue and violet, making those colors more
prominent in the sky.<|im_end|>"
```

**25 tokens/s** for an 8B model: every token reads the 2.19 GB of weights, about 54 GB/s. All 16 checked
steps give MLX's greedy token, every one of the 151,669 logits within 0.0082. The prompt runs one
token at a time (about 38 ms a token); batched prefill would reuse `bonsai/kernels/prefill.mojo`'s
`p_gemm_t2`, whose weight layout this export already matches.

The projections run on the ternary kernels of the Bonsai 2 port (`bonsai/kernels/kernels.mojo`, from
mav3ri3k/modular, unchanged): `packed_linear` and `packed_reduce` for every layer projection (q/k/v
and gate/up fused), `packed_head` for the output head in two halves (each under 128 MB, the Adreno 710 driver's
buffer limit; this driver allows 2 GB). Qwen3 has no
Hadamard rotations, so its projection inputs are only packed into fp16 pairs. The rest is
[`kernels/qwen3k.mojo`](kernels/qwen3k.mojo): RMS norm (packing its output), q/k head norm with RoPE
and the KV-cache writes in one kernel, attention scores and values, SwiGLU (packing), residual add.
[`qwen3_vk.c`](qwen3_vk.c) records 615 dispatches per token once; the embedding row is dequantized on
the CPU each token.

[`export.py`](export.py) writes the weights in that layout, checks that every group is ternary (bias
== -scale), takes the RoPE table from MLX's own YaRN rope (cos | sin, its attention factor included),
and records MLX's FP32-activation logits as the reference.

```bash
python qwen3/export.py --checkpoint CKPT --output OUT --tokens 16 --capacity 128   # MLX venv
python3 qwen3/build_kernels.py
# push OUT/weights.bin, manifest.txt, reference.f32 to /data/local/tmp/q8, then
python qwen3/run.py --model OUT --hf CKPT                     # validate
python qwen3/run.py --model OUT --hf CKPT --prompt 'Explain in two sentences why the sky is blue.'
```

## In Mojo, through DeviceContext

[`model.mojo`](model.mojo) is `qwen3_vk.c`'s forward pass as MAX `DeviceContext` launches of the same
kernels, and [`qwen3.mojo`](qwen3.mojo) the program around it. It takes `qwen3_vk`'s arguments and
checks against the same reference (`QWEN3_REF`). Built for Android (`android/build.py qwen3`), it runs
through the Vulkan driver plugin (`driver/`). On a Galaxy S26 Ultra (stock driver):

```
weights: 441 tensors, 2.186006464 GB, context 128
check 0 : token 785 reference 785  max abs 0.006471  rel L2 0.00078932 OK
  ...
check 15 : token 59108 reference 59108  max abs 0.008191  rel L2 0.00055052 OK
decode: 15 tokens, 39.8 ms/token (25.1 tokens/s)
validation: 16 steps, max abs logit error 0.008191 , all greedy ids match
```

It is as fast as `qwen3_vk` and its logits are the same to 0.0082. `run.py --runner mojo --weights
model` runs it.

### Batched prefill

`Qwen3.prefill` (`QWEN3_PREFILL`, `run.py --runner mojo --prefill`) runs the whole prompt at once.
- **Projections:** Bonsai's `p_gemm_t2` (`bonsai/kernels/prefill.mojo`), which multiplies fp32 rows
  by the packed ternary weights on cooperative matrices. `export.py` already writes Qwen3's weights
  in its layout, so it serves q/k/v, o, gate/up and down unchanged.
- **The rest:** [`kernels/qwen3p.mojo`](kernels/qwen3p.mojo), whose kernels run every prompt row
  at once, row r at position r:
  - RMS norm, SwiGLU and the residual add in fp32;
  - q/k norm with RoPE into the KV cache, sharing the body of `qwen3k`'s decode kernel;
  - attention on the matrix units: `p_scores_mma` (Q Kᵀ for 64 rows and 64 cached positions a step,
    K read straight from the cache), `p_softmax` (in place), and `p_values_mma` (P V).
- **Embedding and head:** the embedding rows are dequantized on the CPU, as for decode, and the last
  row's logits come from the decode head.

On the S26 Ultra (stock driver, Android 16), all 16 greedy tokens match MLX. The logits after the
prompt are within 0.0041, closer than one token at a time (0.0065), because the projections take
fp32 inputs instead of fp16 pairs.

| Prompt | Batched prefill | One token at a time |
|---|---|---|
| 19 tokens (the reference prompt) | 0.98 s | 0.94 s |
| 95 tokens | 1.00 s | 3.74 s (3.7×) |

The matrix kernel works on 128-row tiles, so any prompt of up to 128 tokens (the export's context)
costs about 1 s, 1.8 TFLOP at about 1.8 TFLOP/s. A 64-row tile would halve that for short prompts.

#### A 1000-token prompt

`model1024` is the same weights with a context of 1024. `qwen3_convert` takes the context from the
RoPE table, and `rope1024.f32` extends MLX's 128-row table to 1024 positions. Its frequencies and
YaRN factor are recovered from the 128 rows, which they rebuild to within 4.4e-6. The prompt is the
first 1000 tokens of this repository's Part 4 post, ending in "Summarize the text above in three
sentences." Qwen3 answers "The text describes how Mojo was adapted to run on an Adreno GPU by adding
a Vulkan SPIR-V target, …".

On the S26 Ultra, 1000 prompt tokens, then 24 generated:

| | Prompt (1000 tokens) | Decode, at positions 1000-1023 |
|---|---|---|
| Batched prefill (`QWEN3_PREFILL`) | **8.4 s, 119 tokens/s** | **57.5 ms, 17.4 tokens/s** |
| One token at a time | 53.3 s, 18.8 tokens/s (6.3× slower) | 70 ms (probably throttled after 53 s of work) |
| `qwen3_vk`, one token at a time | 57.7 s | 79 ms (the same) |

All three give the same 24 tokens. With the 19-token prompt and the same context, decode takes 43 ms
a token. At position 1000, attention reads 8 MB of fp32 KV cache a layer, and that adds about 14 ms.

The first long prompt took 20.8 s. Three changes brought it to 8.4 s:
- **The watchdog.** 64 large launches in one submission outlast the driver's GPU watchdog and lose
  the device (`VK_ERROR_DEVICE_LOST`). The plugin now submits each launch of 2¹⁸ threads or more at
  once. Decode's launches stay batched.
- **Scores on the matrix units.** The row kernel computed one score a thread with scalar loads and
  took 12.2 s of the 20.8. `p_scores_mma` takes 0.44 s.
- **P V on the matrix units.** `p_softmax` plus `p_values_mma` take 0.94 s, against 1.45 s for the
  row kernel.

Per kernel over 36 layers, each launch timed alone (`VK_SERVER_PROFILE=2`):

| Kernel | Time |
|---|---|
| gate/up projection | 3.57 s |
| down projection | 1.82 s |
| q/k/v projection | 0.88 s |
| P V (`p_values_mma`) | 0.75 s |
| o projection | 0.62 s |
| scores (`p_scores_mma`) | 0.44 s |
| softmax | 0.19 s |
| the rest (norms, RoPE, SwiGLU, adds) | 0.29 s |

The ternary projections are 6.9 s of it, at about 2 TFLOP/s.

Decode's attention kernels changed too, and `qwen3_vk` uses the same ones, with the same launches:
- `attn_scores` computes a KV head's four query heads in one thread, so each cached K row is read
  once, with four-float loads.
- `attn_values` computes each probability once, into shared memory, instead of in all 128 threads
  of the head.

Together they take decode at position 1000 from 72 ms to 57.5 ms a token. `qwen3_vk` still matches
MLX on all 16 steps.

A kernel that calls another kernel does not compile for the Vulkan target: the kernel ABI pass
rewrites both into entry points. So `qk_norm_rope` keeps its body in an inline helper, and the
decode kernel and the prefill row kernel both call it.

The weights came from Hugging Face to the phone directly. [`convert.cpp`](convert.cpp) is
`export.py`'s export in C++ and writes `weights.bin` and `manifest.txt` from the downloaded
checkpoint (SHA-256 `f43270cb…`) in seconds, byte for byte `export.py`'s. The exception is the 64 KB
RoPE table, which MLX computes and the Mac supplies (`rope.f32`, cut out of an export):

```bash
adb shell "cd /data/local/tmp/q8; curl -sSL -o model.safetensors https://huggingface.co/prism-ml/Ternary-Bonsai-8B-mlx-2bit/resolve/main/model.safetensors"
adb shell "cd /data/local/tmp/q8; ./qwen3_convert model.safetensors rope.f32 model"
```
