# Gemma 4 E2B and E4B on the Adreno 840, in Mojo

Google's on-device Gemma 4 models, [`google/gemma-4-E2B-it`](https://huggingface.co/google/gemma-4-E2B-it) (revision
`4adf1574`) and [`google/gemma-4-E4B-it`](https://huggingface.co/google/gemma-4-E4B-it) (revision `4ecc2ba6`), generate
text on the GPU of a Galaxy Z Fold (SM-F976U, Snapdragon 8 Elite Gen 5, Adreno 840, Android 17) in Samsung's Remote Test
Lab. Every GPU kernel is Mojo, compiled by the fork's adreno840 SPIR-V target. The program around them is Mojo too
(`DeviceContext`, built for Android by `android/build.py gemma4`) and runs on the phone. One program serves both
models; their sizes come from the manifest. Both checkpoints are Apache 2.0 and not gated.

```
$ build/vla/venv/bin/python gemma4/run.py --model e2b --check --bf16
prompt: 19 tokens ('Explain in two sentences why the sky is blue.')
phone: weights: 1.212 GB in 1.0 s; 35 layers, hidden 1536 , context 2048
phone: decode: 46 steps, 27.44 ms/token ( 36.44 tokens/s )
output: "The sky appears blue due to a phenomenon called Rayleigh scattering, where shorter wavelengths of sunlight
are scattered more effectively by the Earth's atmosphere. These blue wavelengths are scattered across the sky, making
the sky appear blue to our eyes.<turn|>"
int4: phone logits within 1.71e-04 of the reference's (range -30.0 .. 21.4; median position 9.92e-05)
greedy: 47 of 47 phone tokens are the int4 reference's argmax
bf16: the original model's greedy choice agrees with the phone's token at 42 of 47 positions (teacher-forced on the
phone's tokens; first difference: position 22); mean KL(bf16 || int4) 0.2988
```

| | E2B | E4B |
|---|---|---|
| Decode | **28.1 ms a token (35.6 tokens/s)** | **53.8 ms a token (18.6 tokens/s)** |
| A 960-token prompt, batched prefill | **2.36 s (406 tokens/s)**, 13× a token at a time | **4.71 s (204 tokens/s)**, 15× |
| On the GPU | 1.21 GB | 2.47 GB |

- **Exact on its weights.** At every position checked, the phone's logits are within 1.7e-4 of transformers' own
  Gemma 4 layers running the same int4 weights (`reference.py`). That holds for all 262,144 logits, over a range of
  ±30. Every greedy token matches, in all six checked runs (see [Checks](#checks)). The long prompt crosses the
  512-token sliding window and two prefill batches.
- **Against the bf16 models**, teacher-forced on the phone's tokens, the original weights' greedy choice agrees at
  42 of 47 and 49 of 64 positions for E2B, and 39 of 48 and 55 of 64 for E4B. The differences come from int4, not
  from the kernels (see [Checks](#checks)).
- **The weights never cross adb.** The phone downloads each checkpoint from Hugging Face itself: 10.2 GB in about 6
  minutes and 16.0 GB in about 15, matching Hugging Face's SHA-256 (`2db5482b…`, `cfbd3d2f…`). `gemma4_convert`
  (`convert.c`) then writes `gemma4.bin`, byte for byte the Mac's: SHA-256 `02bdea70…` (E2B, 1.213 GB) and
  `c6355f9c…` (E4B, 2.470 GB).

## What is new in Gemma 4

The text model is not Gemma 3's, nor Gemma 3n's (no AltUp, LAuReL or activation sparsity). From `config.json` and
transformers 5.5.4's `modeling_gemma4.py`:

| | E2B | E4B |
|---|---|---|
| Layers, hidden | 35 × 1536 | 42 × 2560 |
| Query heads, KV heads | 8, 1 | 8, 2 |
| Sliding layers (window 512): head dim, RoPE | 256, θ 10⁴ | 256, θ 10⁴ |
| Full layers: where, head dim, RoPE | every 5th; 512, θ 10⁶ on the first quarter ("proportional") | every 6th; the same |
| Layers that reuse earlier K/V | the last 20 | the last 18 |
| MLP (GELU-tanh) | 6144; 12288 in the 20 K/V-sharing layers | 10240 |
| Per-layer input | 256 a layer: a 262144 × 8960 embedding | 262144 × 10752 |
| Vocabulary (tied head), final soft-cap | 262144, 30 | the same |

- **Norms:** RMS norms multiply by their weight, not Gemma 3's 1 + w. Every sub-layer's output is normed before its
  residual add. Q and K get an RMS norm over each head, and V one without a weight. Attention has no scale (1.0).
- **K/V sharing:** a layer at or past `num_hidden_layers - num_kv_shared_layers` has no K or V projection. It attends
  over the cache of the last earlier layer of its type, sliding or full (E2B: layers 13 and 14; E4B: 22 and 23). That
  layer filled it earlier in the same step.
- **Per-layer inputs:** each token also looks up a row of a second embedding: 256 values per layer, times 16. They are
  added to a projection of the token's scaled embedding (RMS-normed per layer), and the sum is divided by √2.
  After its MLP, each layer gates a 256-wide projection of the residual stream with its slice
  (GELU-tanh(W_g x) ⊙ slice). It then projects that back to the hidden size, norms it, adds it, and multiplies the
  residual stream by a learned layer scalar.

## Weights

`export.py` reads only `model.safetensors`' header (by HTTP range request) and writes the layout of `gemma4.bin`:
`recipe.txt` for `convert.c`, `manifest.txt` for the program, and the two RoPE tables. Those tables come from
transformers' own `Gemma4TextRotaryEmbedding` in fp32, so the proportional RoPE matches exactly.

| | Format | E2B | E4B |
|---|---|---|---|
| q/k/v (fused), o, gate/up (fused), down, per-layer gate and projection, per-layer input projection | int4, an fp16 scale per 64 | 1.00 GB | 2.11 GB |
| Output head (the tied embedding) | int4, an fp16 scale per 64 | 0.21 GB | 0.36 GB |
| Norms, layer scalars | fp32 (bf16 exactly) | < 1 MB | < 1 MB |
| **`gemma4.bin`, all on the GPU** | | **1.21 GB** | **2.47 GB** |
| Token embedding (input side) and per-layer embedding | bf16, left in `model.safetensors` | 0.8 + 4.7 GB | 1.3 + 5.6 GB |

- **int4** is `llama/kernels`' `gemv_q4` storage: symmetric, 8 weights a uint32, low nibble first. Each scale is the
  fp16 of max |w| / d for the d in 6.5 … 9 with the least squared error, as in `qwen3moe/convert.c`. The bf16 weights
  are quantized directly.
- **The two embeddings stay in the checkpoint.** For each token, the program reads its row of each from
  `model.safetensors` on the phone: 3 KB and 18 KB for E2B. They are exact, scaled on the CPU as transformers scales
  them in fp32, and copied to the GPU. The per-layer table alone is 4.7 GB; the GPU never needs more than a row of it.
- On the Mac, `fetch.py` keeps a sparse copy of `model.safetensors`: only the byte ranges something reads (4.6 GB of
  E2B's 10.2, 9.3 GB of E4B's 16.0), plus embedding rows on demand. `convert.c` runs on that copy unchanged and writes
  the same `gemma4.bin`.

## How a token runs

`model.mojo`'s `step()` makes 3 + 12 per layer + 2 launches: 425 for E2B, 509 for E4B.
1. The per-layer inputs: `per_layer_model_projection` (int4), then `ple_prep`: per layer, scale by D^-½, RMS norm,
   add the embedding row × 16, divide by √2. Then `start`: the residual stream is the scaled embedding, and its first
   norm.
2. For each layer:
   1. q/k/v (int4; only q in a K/V-sharing layer);
   2. `qk_norm_rope`: Q and K norms and RoPE, and the scale-free V norm. K and V go into this layer's cache row.
   3. `attn_scores` (a thread per KV head and position computes the 8 or 4 query heads that share it, so each K row
      is read once) and `attn_values`, over the window's 512 positions or all of them, in the K/V-source layer's
      cache;
   4. o (int4), then `norm_add`: post-attention norm, residual add, and the pre-MLP norm;
   5. `gate_up_gelu` (gate and up rows of one int4 matrix, GELU-tanh × up), down (int4), `norm_add`;
   6. `ple_gate` (int4, GELU, × the layer's slice), the per-layer projection (int4, 256 wide), and `norm_add`: its
      norm and add, the layer scalar, and the next layer's input norm.
3. The head with the soft-cap (int4, 262144 rows), then `argmax`.

The host reads each next token (4 bytes) and its two embedding rows, then enqueues the next step. Activations and the
KV cache are fp32. The cache holds 2048 positions; only the 15 (E2B) or 24 (E4B) layers with their own K/V have one.

## Prefill

`Gemma4.prefill` runs the prompt in batches of up to 512 rows (`GEMMA4_PREFILL`, `run.py --prefill`):
- **Projections** are one matrix product each on the matrix units: llama's `p_gemm_q4`, which unpacks int4 into fp32 in
  shared memory and multiplies on KHR cooperative matrices (fp32, 64 × 64 × 8). The export's layout is already its
  layout.
- **Attention** is on the matrix units too: qwen3's three kernels, for heads of 256 and 512, grouped KV heads, the
  sliding window, and batches that start mid-prompt. `p_scores_mma` computes Q Kᵀ per 64 rows and 64 keys, with K
  read straight from the cache. Then `p_softmax`, then `p_values_mma` (P V). A block reads only the keys in its rows'
  windows. The caches start zeroed, so keys past the prompt add 0 × 0.
- **Row kernels** (norms, residual adds, RoPE, GELU products) take every row of the batch at once.

The first version computed attention with scalar dot products: a workgroup per head and row. On the 960-token prompt,
it was 1.70 of 3.88 s. On the matrix units it is 0.28 s, and the whole prompt takes 2.36 s for E2B (4.71 s for E4B).

Per kernel on the 960-token prompt, each launch submitted and waited for alone (`step_profile.py --prefill`, so a
little above a normal run's total):

| Launches | E2B | E4B |
|---|---|---|
| gate/up (int4, matrix units) | 1.01 s (2.1 TFLOP/s) | 2.12 s (2.1 TFLOP/s) |
| down (int4, matrix units) | 0.58 s (1.8 TFLOP/s) | 1.25 s (1.8 TFLOP/s) |
| q/k/v and o (int4, matrix units) | 0.31 s | 0.65 s |
| attention: Q Kᵀ, softmax, P V | 0.28 s | 0.37 s |
| per-layer inputs: gates and projections (int4, matrix units) | 0.08 s | 0.15 s |
| norms, residual adds, RoPE, GELU products, head | 0.18 s | 0.30 s |
| **total** | **2.44 s** (a normal run: 2.36 s) | **4.85 s** (4.71 s) |

The int4 projections are 80–86% of a prompt. They run at the rate `p_gemm_q4` reaches for Llama (1.7–2.1 TFLOP/s).

## Checks

`reference.py` runs transformers' own Gemma 4 text model on the Mac, a decoder layer at a time, in fp32. It uses
transformers' scaled embeddings (on just the rows used), `project_per_layer_inputs`, `Gemma4TextRotaryEmbedding`, the
causal and sliding-window masks of `masking_utils`, each `Gemma4TextDecoderLayer` with the `shared_kv_states` dict
those layers fill and read, and the final norm. The head is the tied embedding with the soft-cap, as in
`Gemma4ForCausalLM`. `reference.py --selftest` checks this driver against transformers' whole `Gemma4ForCausalLM` on
a tiny random model with E2B's structure. That model has sliding and full layers, proportional RoPE, K/V sharing, the
double-wide MLP and per-layer inputs, and its prompt is longer than its window. The two give identical logits (max
difference 0.0).

`run.py --check` has the phone write its logits after the prompt and after generated tokens. It keeps 8 rows of
1 MB each, because the bridge pulls 0.7 MB/s. It compares them with the reference's on the same int4 weights
(dequantized from `gemma4.bin`), and checks every generated token against the reference's argmax. `--bf16` runs the
checkpoint's own bf16 weights (in fp32) on the same tokens.

| Model, prompt | Prompt run | Max \|phone − reference\| (int4) | Greedy = reference (int4) | bf16 agrees | Mean KL(bf16 ‖ int4) |
|---|---|---|---|---|---|
| E2B, the sky (19 tokens) | a token at a time | 1.7e-4 (all 47 rows) | 47 of 47 | 42 of 47 | 0.30 |
| E2B, the sky | batched prefill | 1.3e-4 | 47 of 47 | | |
| E2B, the post (960 tokens) | batched prefill | 1.2e-4 | 64 of 64 | 49 of 64 | 0.62 |
| E4B, the sky | a token at a time | 1.6e-4 | 48 of 48 | 39 of 48 | 0.41 |
| E4B, the sky | batched prefill | 1.7e-4 | 48 of 48 | | |
| E4B, the post | batched prefill | 1.2e-4 | 64 of 64 | 55 of 64 | 0.34 |

The logits range over about ±30 (the soft-cap). "bf16 agrees" counts the positions where the original model's
argmax, teacher-forced on the phone's tokens, is the phone's token. The bf16 reference runs the checkpoint's bf16
weights in fp32 arithmetic. On E4B's sky prompt the first difference is the answer's first token.

The int4 weights' error is ordinary for 4 bits. Every quantized matrix sampled (E2B's head, per-layer input
projection, and the matrices of layers 0, 4, 14, 15, 20 and 34) is within 9.4–18% of its bf16 original (relative L2),
most of them about 10%. The differences come at a few positions where int4 flips a confident choice. On the sky
prompt, at position 22, bf16 says " because" (p = 0.98) and int4 says " due". At most positions both are nearly
certain of the same token. No single part dominates the error. With one group of matrices kept in bf16
(`reference.py --keep`), E2B's mean KL on the sky prompt goes from 0.30 to:

| bf16 for | Mean KL | Greedy agreement |
|---|---|---|
| nothing (the phone's int4) | 0.30 | 42 of 47 |
| the head | 0.26 | 40 of 47 |
| attention (q/k/v, o) | 0.26 | 41 of 47 |
| the MLPs | 0.23 | 41 of 47 |
| the per-layer input matrices | 0.22 | 41 of 47 |

A finer int4 grid barely helps, and 8 bits nearly close the gap. On E2B's 960-token run, every quantized matrix
quantized another way (simulated in the reference from the bf16 weights):

| Every int4 matrix as | Mean KL | Greedy agreement | Bytes a token (E2B) |
|---|---|---|---|
| int4, a scale per 64 (the phone's) | 0.62 | 49 of 64 | 1.21 GB |
| int4, a scale per 32 | 0.45 | 51 of 64 | 1.28 GB |
| int8, a scale per row | 0.008 | 63 of 64 | about 2.3 GB |

So the gap to bf16 is int4 rounding, and closing it needs more than a smaller group: GPTQ or AWQ-style rounding, or
8 bits where it matters.

## Speed

On the Galaxy Z Fold, each run after 90 s idle (battery 26.5–29.8 °C at the start), 64 tokens generated or up to
the end of turn:

| | E2B: prompt | E2B: decode | E4B: prompt | E4B: decode |
|---|---|---|---|---|
| The sky (19 tokens), a token at a time | 0.54 s | 28.1 ms/token | 1.05 s | 53.8 ms/token |
| The sky, batched prefill | 0.31 s | 28.4 ms/token | 0.58 s | 56.0 ms/token |
| The post (960 tokens), batched prefill | **2.36 s** (406 tokens/s) | 30.6 ms/token | **4.71 s** (204 tokens/s) | 58.0 ms/token |
| The post, a token at a time | 31.6 s (30 tokens/s) | 39.6 ms/token* | 69.4 s (14 tokens/s) | 90.8 ms/token* |

\* after 31 or 69 s of continuous work: the phone throttles.

- **Decode** reads all of `gemma4.bin` for every token: 1.21 GB in 28.1 ms (43 GB/s) for E2B, 2.47 GB in 53.8 ms
  (46 GB/s) for E4B. Llama 3.2 1B in int4 reads 51 GB/s on this GPU with the same `gemv_q4` arithmetic.
- **Context:** after 960 tokens a step takes 2.5 ms (E2B) or 4 ms (E4B) more. Attention then reads up to 512
  positions in the sliding layers and all 960 in the full ones, as fp32 K and V.
- **The prompt in batches** is 13–15× faster than a token at a time on 960 tokens, and 1.7–1.8× on 19.

Where a decode step goes (`step_profile.py`: each launch submitted and waited for alone, so each also pays about
0.1 ms of submission that a normal step, 64 launches a submission, does not):

| Launches | E2B | E4B |
|---|---|---|
| gate/up + GELU (int4) | 12.7 ms | 24.7 ms |
| down (int4) | 9.2 ms | 17.2 ms |
| q/k/v and o (int4) | 10.6 ms | 17.6 ms |
| head + soft-cap (int4, 262144 rows) | 4.5 ms | 7.9 ms |
| per-layer gate and projection (int4) | 7.0 ms | 8.6 ms |
| norms and residual adds (3 a layer) | 10.9 ms | 13.3 ms |
| attention scores and values, q/k norm + RoPE | 10.8 ms | 12.6 ms |
| the rest (per-layer inputs, argmax) | 1.5 ms | 1.0 ms |
| **all 425 / 509 launches, each alone** | **67.2 ms** | **102.9 ms** |
| a normal step | 28.1 ms | 53.8 ms |

The small launches each cost about the 0.1 ms floor here. Batched in a normal step, most of their cost disappears:
the step is not much more than the int4 matrix-vector products.

## Run it

```bash
build/vla/venv/bin/python gemma4/export.py --model e2b        # build/gemma4/e2b: recipe, manifest, RoPE, tokenizer
build/vla/venv/bin/python gemma4/fetch.py --model e2b         # the Mac's sparse model.safetensors (4.6 GB of 10.2)
cc -O2 -ffp-contract=off -o build/gemma4/bin/convert gemma4/convert.c
(cd build/gemma4/e2b; ../bin/convert hf recipe.txt gemma4.bin)                       # for the reference
python3 android/build.py gemma4                               # build/android/gemma4: gemma4, gemma4_convert, runtime
D=/data/local/tmp/gemma4
adb push build/android/gemma4 $D/
adb push build/gemma4/e2b/manifest.txt build/gemma4/e2b/recipe.txt build/gemma4/e2b/rope_sliding.f32 \
    build/gemma4/e2b/rope_full.f32 $D/e2b/
adb shell "cd $D/e2b; curl -sSL -o model.safetensors https://huggingface.co/google/gemma-4-E2B-it/resolve/4adf15748de9e1a0097b6274cee9c15836c41c37/model.safetensors"
adb shell "cd $D/e2b; $D/gemma4/gemma4_convert . recipe.txt gemma4.bin"
build/vla/venv/bin/python gemma4/run.py --model e2b --check --bf16                 # the sky prompt
build/vla/venv/bin/python gemma4/run.py --model e2b --prefill --check --prompt-file gemma4/prompts/long.txt
build/vla/venv/bin/python gemma4/step_profile.py --model e2b [--prefill]          # time per kernel
```

E4B is the same with `e4b` and its revision, `4ecc2ba63bcac23ba4a767fc87025b1450f84c9c`. The phone needs no Python.
`run.py` tokenizes with the chat template on the Mac. It pushes the ids as a file, because a 960-token prompt's ids
on the `adb shell` line dropped the lab's bridge. Then it runs one plain command per `adb shell`.

## Follow-ups

- **Better int4.** GPTQ or AWQ-style rounding, or a scale per 32, on the same kernels: see the table above.
- **Prefill in fp16 on the matrix units.** The int4 projections are 80–86% of the prompt and run fp32 cooperative
  matrices at 1.8–2.1 TFLOP/s; the 840's fp16 product is about twice that (fp16 accumulators only).
- **Fewer decode launches.** A quarter of a step's launches are single-workgroup norms and residual adds.
- **The Hexagon NPU for prefill**, as for π0's prefix (`../npu`).
- **Images and audio.** The checkpoints hold vision and audio towers; only the text model runs here.

## Files

| File | |
|---|---|
| `export.py` | `gemma4.bin`'s layout from `model.safetensors`' header: `recipe.txt`, `manifest.txt`, RoPE tables from transformers |
| `fetch.py` | the Mac's sparse copy of `model.safetensors`: the ranges `convert.c` and `reference.py` read, by HTTP range request |
| `convert.c` | `model.safetensors` to `gemma4.bin` (int4 with searched scales, fp32 norms); macOS and Android, the same bytes |
| `kernels/g4k.mojo` | decode kernels (int4 matrix-vector products, norms, RoPE, attention, per-layer inputs, soft-capped head, argmax) and prefill's row and attention kernels |
| `model.mojo` | the weights, the embedding rows from the checkpoint, `step()` (decode) and `prefill()` |
| `gemma4.mojo` | the program: prompt, greedy decode, logits for checking, the phone's timings |
| `reference.py` | transformers' Gemma 4 text layers one at a time, on the int4 or bf16 weights; `--selftest` against `Gemma4ForCausalLM` |
| `run.py` | tokenize (chat template), run on the phone, decode the text, check against `reference.py` |
| `step_profile.py` | time per kernel of a decode step or a prefill (`VK_SERVER_PROFILE=2`) |
| `prompts/long.txt` | the 960-token prompt: the start of this repo's Part 4 post, then "Summarize the text above in three sentences." |
