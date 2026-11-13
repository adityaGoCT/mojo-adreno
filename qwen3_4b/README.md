# Qwen3-4B on the Adreno 840

Qwen's dense **Qwen3-4B** ([`Qwen/Qwen3-4B`](https://huggingface.co/Qwen/Qwen3-4B), revision `1cfa9a72`, Apache-2.0,
not gated: the original hybrid-thinking release) generates text on a Galaxy Z Fold (SM-F976U, Snapdragon 8 Elite Gen
5, Adreno 840, 11 GB) in Samsung's Remote Test Lab. A Mojo `DeviceContext` program on the phone runs it, with Mojo
kernels compiled to adreno840 SPIR-V. The phone downloads the bf16 checkpoint from Hugging Face itself (3 shards,
8.04 GB, about 5 minutes) and quantizes it in 13 s with `convert.c`. Every projection becomes ggml's Q4_0, and the
tied embedding / head becomes one Q6_K copy, as llama.cpp stores a tied embedding in its Q4_0 files. That gives
2.36 GB, which the existing int4 kernels of `../lfm2` run as is.

The prompt is the passage of `../lfm2/prompts/long.txt` in Qwen3's chat template (thinking on, the default): 404
tokens. Each row then generates 64 greedy tokens. Times are the phone's own clock, warm (after one untimed run of the
prompt), each run after the battery cooled to 30 °C.

| Galaxy Z Fold SM-F976U, Adreno 840 | Prefill | Decode | vs transformers on the same int4 weights | vs bf16 (the published model): greedy, KL |
|---|---|---|---|---|
| 404-token prompt + 64 tokens | 2.26-2.27 s (**178 tokens/s**) | **43.2 ms/token** (23.1 tokens/s; 42.8-43.6 over 3 runs) | logits within 1.6e-4 (range -23 … 46); 64 of 64 tokens | 62 of 64, KL 0.054 |
| 19-token prompt + 64 tokens | 0.51 s (padded to 128 rows) | **41.0 ms/token** (24.4 tokens/s; 40.9-41.2) | within 1.2e-4; 64 of 64 | 60 of 64, KL 0.172 |
| Pipette protocol: 1,024 tokens → 256 | TTFT 4.74 s (216 tokens/s) | 47.8 ms (20.9 ± 0.3 tokens/s, outputs 2-100) | (same program) | |

- **Exact on its weights.** Teacher-forced on the phone's own tokens, transformers' Qwen3 layers running the same
  Q4_0 / Q6_K weights (dequantized as ggml does) give logits within 1.6e-4 of the phone's at every checked position.
  Every one of the 128 generated tokens is the reference's argmax.
- **Against bf16, the GPU adds nothing to what Q4_0 costs.** The int4 model in transformers agrees with the bf16
  model's greedy choice at exactly the same positions as the phone, with the same KL (0.0538 against the phone's
  0.0538; 0.1721 against 0.1721). The first difference is at generated token 42 (long prompt) and 26 (short prompt).
  Q4_0 rounds to nearest with no calibration, and Qwen3-4B was not trained for it (unlike LFM2's quantization-aware
  file), so what it costs depends on the text: KL 0.054 on the long prompt, 0.17 on the short one. An 8-bit storage
  is the way to close it ([Follow-ups](#follow-ups)).
- **Decode is memory-bound.** A token reads the 2.36 GB of weights once: 41.0 ms is 58 GB/s, the same rate as LFM2's
  27.5 ms for 1.59 GB. Kernel shape barely matters there. Two or four weight rows a workgroup (lanes split between
  the rows, or every lane on every row sharing each block of x) gave 44.6-47.4 ms against lk's one row's 44.8, so
  the program keeps lk's kernels.
- **The K/V cache is fp32: 288 KB a position** (36 layers × 8 heads × 128 × K and V). At 1,100 positions that is
  317 MB a token on top of the weights. qwen3k's attention kernels took 11-22 ms a token for it (varying from run
  to run). A chunked decode attention (below) reads it at the weights' rate: 5-6 ms. That took the 1,024-token
  Pipette decode from 16.7 to 20.9 tokens/s.
- **Prefill is compute-bound** on the fp32 cooperative matrices: the projections run at ~2.0 TFLOP/s (the 840's fp32
  64 × 64 × 8 product measured 2.48). A 404-token prompt pays for 512 rows (gemm_q4's 128-row tiles).

## Against Pipette (Liquid AI's on-device benchmark)

`../lfm2/pipette.py gpu --model qwen3-4b` runs Pipette's protocol (see `../lfm2/README.md`): a 1,024-token prompt
(the same passages as for LFM2, in Qwen3's tokenizer, no BOS), greedy, 5 repetitions after a readiness wait, decode
over outputs 2-100 and E2E to the 256th output token, and peak memory from a 1,024 → 1 run.

Pipette has no Qwen3-4B. For scale only, here are its rows for the nearest model it has, Qwen3.5-4B
(`unsloth/Qwen3.5-4B-GGUF`, llama.cpp b11988). Qwen3.5-4B is a newer model with a different architecture, so this is
not a like-for-like comparison.

| Device, engine | Quant | Decode (1024→100) | Prefill (1024) | TTFT (1024) | E2E (1024→256) | Peak RAM |
|---|---|---|---|---|---|---|
| Galaxy S26 Ultra, llama.cpp CPU, Qwen3.5-4B (Pipette) | q4_0 | (none) | 76 tok/s | 13,555 ms | 26,463 ms | 3.16 GB |
| Galaxy S26 Ultra, llama.cpp CPU, Qwen3.5-4B (Pipette) | q4_k_m | 14.5 tok/s | 57 tok/s | 17,861 ms | 33,110 ms | 3.31 GB |
| iPhone 17 Pro, llama.cpp GPU, Qwen3.5-4B (Pipette) | q4_0 | 22.3 tok/s | 515 tok/s | 1,990 ms | 13,414 ms | 3.17 GB |
| **Galaxy Z Fold SM-F976U, Mojo, Adreno 840 GPU, Qwen3-4B (ours)** | q4_0 + q6_K head | **20.9 ± 0.3 tok/s** | **216 ± 0 tok/s** | **4,744 ± 3 ms** | **18,914 ± 381 ms** | 2.29 GB host + 2.76 GB GPU |

Peak memory: the process's VmHWM is 2.29 GiB, almost all file-backed (RssFile 2.23 GiB). The GPU's page allocations
rise 2.76 GiB above idle: the 2.36 GB of weights, the K/V cache (0.35 GB for 1,088 positions) and the prefill's
buffers.

## The model

From `config.json` and transformers' `modeling_qwen3.py` (read from Hugging Face, not from memory):

| | |
|---|---|
| Layers | 36, each: RMSNorm → attention → residual, RMSNorm → SwiGLU MLP → residual (eps 1e-6) |
| Hidden, MLP | 2560; SwiGLU, 9728 |
| Attention | 32 query and 8 KV heads of 128 (q is 4096 wide, not the hidden size); RMSNorm on each q and k head before RoPE; no biases; scale 1/√128 |
| RoPE | default (rotate-half), θ = 1,000,000, no scaling; no sliding window |
| Vocabulary, head | 151,936; tied embedding (`tie_word_embeddings`), no `lm_head.weight` in the checkpoint |
| Parameters | 4.02 B: 3.63 B in the projections, 0.39 B in the embedding |

Qwen3-4B has exactly the attention shapes of Qwen3-8B (32 / 8 heads of 128). So `../qwen3/kernels/qwen3k.mojo`'s
q/k norm + RoPE + K/V-cache kernel, written for Ternary-Bonsai-8B, runs it unchanged. Only the hidden size differs
(2560 against 4096). Unlike `../qwen3`'s Bonsai, plain Qwen3-4B has no YaRN: the RoPE table is transformers' own
`Qwen3RotaryEmbedding` (`export.py`, 8,192 positions).

## Weights

`Qwen/Qwen3-4B-GGUF` has Q4_K_M, Q5_0, Q5_K_M, Q6_K and Q8_0, but no Q4_0, and `../lfm2`'s kernels run Q4_0 and
Q6_K. So `convert.c` quantizes the bf16 checkpoint itself, on the phone, with ggml's reference quantizers:

| Tensor | Storage | Bytes |
|---|---|---|
| q\|k\|v (6144 × 2560), o (2560 × 4096), gate\|up (19456 × 2560), down (2560 × 9728), × 36 | Q4_0 (`quantize_row_q4_0_ref`: per 32 weights d = the value of largest magnitude / -8, q = min(15, ⌊w/d + 8.5⌋), d fp16) as `lk`'s int4 words + fp16 scales | 2.044 GB |
| embedding = head (151936 × 2560) | Q6_K (`quantize_row_q6_K_ref` with `make_qx_quants`), repacked to `lk`'s 208-byte super-blocks + fp16 d's | 0.319 GB |
| norms (input, post-attention, q/k head norms, final) | fp32 | 0.8 MB |

One Q6_K copy serves both the embedding lookup (`lk.embed_q6`) and the head (`lk.head_q6`). The head reads it
(0.32 GB) once per decode token, about 5.5 ms. An int4 head would save about 1.7 ms; its cost in quality is not
measured here.

`convert.c` (`qwen3_4b_convert` on the phone) reads `export.py`'s `recipe.txt`, a line per tensor with its shard and
byte offset, from the safetensors headers. It converts a block of 1,024 rows at a time on 6 threads, so it never
holds a whole matrix, and writes `qwen3_4b_q4.bin` (SHA-256 `99825a20…`). The Mac's reference loads the same
`convert.c` as a library (`weights.quant_blocks`). Both builds use `-ffp-contract=off`, so the Mac quantizes to the
same bytes as the phone. The logits check confirms it: 1.6e-4 over a range of 69.

## The GPU

`model.mojo` (the forward pass) and `qwen3_4b.mojo` (the program) follow `../lfm2/model.mojo` and `lfm2.mojo`.
Token ids live on the GPU, and the argmax writes the next one, so a decode step never waits for the host. The program
prints the same `tok <id> <ms>`, `prompt:`, `decode:` and `mem:` lines, which `../lfm2/pipette.py` parses.

| Step | Decode (one token) | Prefill (batches of up to 512 rows) | Kernels from |
|---|---|---|---|
| embedding, first norm | `embed_q6`, `add_norm` | the same, a row a workgroup | `lk`, `q4bk` (eps 1e-6) |
| q\|k\|v, o, gate\|up + SiLU, down | `gemv_q4` / `gate_up_q4` (a row a workgroup, a 32-weight block a lane a step) | `gemm_q4` (int4 unpacked into shared memory, fp32 64 × 64 × 8 cooperative matrices, 128 × 128 tiles), `silu_mul` | `lk` |
| q/k head norms, RoPE, K/V cache rows | `qk_norm_rope` | `p_qk_norm_rope` (the same body from position p0, q pre-scaled by 1/√128) | `qwen3k`, `q4bk` |
| attention | `attn_part` + `attn_combine` (chunks of 32 positions) | `p_scores_mma`, `p_softmax`, `p_values_mma` (Q Kᵀ and P V on the matrix units, any p0) | `q4bk`, `g4k` (`../gemma4`'s generalization of `qwen3p`'s) |
| residual add + norm | `add_norm` | `add_norm` | `q4bk` |
| head, argmax | `head_q6` (Q6_K), `argmax` | the last row only | `lk` |

**Decode attention in chunks** (`kernels/q4bk.mojo`). In qwen3k's `attn_values`, each query head's half gets one
workgroup, which walks every cached position in turn: 64 workgroups, and a chain as long as the context. Its
`attn_scores` has each lane read its own 512-byte K row, 64 rows per load instruction. Instead, `attn_part` gives a
workgroup 32 positions of one KV head and its 4 query heads, so each K and V row is read once:
- Scores: 16 lanes read a K row together (two coalesced 256-byte loads, then a shuffle sum), four positions at a time.
- The chunk's softmax numerators are taken against the chunk's own maximum, then multiplied into V.
- `attn_combine` rescales the chunks to the common maximum.

At 1,100 positions this takes the attention from 11-22 ms (qwen3k's) to 5-6 ms a token, which is the cache's
bandwidth. `QWEN3_ATTN=qwen3k` selects the old pair. A first version with 64 positions a chunk and a K row a lane
still took 16-22 ms.

Prefill profile (404 tokens, `QWEN3_PROFILE=prefill`; each launch waited for): gate/up 871 ms, down 506, attention
351, q/k/v 278, o 239, norms 56, SiLU 48, q/k norm + RoPE 28, head 6.

## Checks

- `reference.py`: transformers' own `Qwen3DecoderLayer`, `Qwen3RotaryEmbedding`, `create_causal_mask` and
  `Qwen3RMSNorm`, a layer at a time in fp32, with the tied head. `--selftest` matches the whole `Qwen3ForCausalLM`
  exactly (difference 0) on a tiny random model with Qwen3's structure. The checkpoint is streamed from Hugging Face
  by HTTP range request (`weights.Bf16Weights`, 8 GB a pass, about 13 minutes), and the Mac keeps none of it. Each
  layer runs twice from one read: on the bf16 weights, and on the same weights quantized as the phone holds them.
- `run.py --rows 16 --name N`: the phone writes 16 logit rows (every 4th position, 0.6 MB each). `check.py` then
  compares every recorded run, teacher-forced on the phone's tokens, in one streamed pass, and keeps the reference
  logits (`build/qwen3_4b/runs/ref/`).

```
sky: 64 tokens after a 19-token prompt
  vs q4 (same int4 weights): logits within 1.22e-04 at 16 rows (range -23.4 .. 45.0), KL 5.22e-11; argmax = phone token at 64 of 64
  vs bf16: argmax = phone token at 60 of 64 (first difference at 26); max |logit diff| 5.05, KL 0.1721 | the q4 reference itself: 60 of 64, KL 0.1721
long: 64 tokens after a 404-token prompt
  vs q4 (same int4 weights): logits within 1.60e-04 at 16 rows (range -22.6 .. 45.7), KL 5.10e-11; argmax = phone token at 64 of 64
  vs bf16: argmax = phone token at 62 of 64 (first difference at 42); max |logit diff| 6.51, KL 0.0538 | the q4 reference itself: 62 of 64, KL 0.0538
```

The phone's outputs (thinking on):

```
'<think>\nOkay, the user wants a two-sentence explanation of why the sky is blue. Let me start by recalling the
basic science behind this. The sky appears blue because of Rayleigh scattering. When sunlight enters the Earth's
atmosphere, the shorter wavelengths of light, like blue, are scattered more by the air molecules'
'<think>\nOkay, let's tackle this question. The user is asking why reading a prompt is faster than generating text,
and what matrix units add. \n\nFirst, I need to recall the passage. The passage mentions that generating text one
token at a time is limited by memory bandwidth because each token requires every weight of the'
```

## Run it

```bash
python3 android/build.py qwen3_4b                     # build/android/qwen3_4b: the program and qwen3_4b_convert
build/vla/venv/bin/python qwen3_4b/export.py          # build/qwen3_4b/q4/{recipe,manifest}.txt, rope.f32
qwen3_4b/stage_phone.sh                               # the phone downloads the shards, converts (/data/local/tmp/q4b)
build/vla/venv/bin/python qwen3_4b/run.py --prompt-file lfm2/prompts/long.txt --tokens 64     # text + timings
build/vla/venv/bin/python qwen3_4b/run.py --tokens 64 --rows 16 --name sky --no-eos            # record for check.py
build/vla/venv/bin/python qwen3_4b/check.py sky       # vs transformers, bf16 and the same int4 weights
build/vla/venv/bin/python lfm2/pipette.py gpu --model qwen3-4b --input 1024                    # Pipette's protocol
build/vla/venv/bin/python lfm2/pipette.py --table --model qwen3-4b
```

On the phone, by hand (one plain command per `adb shell` on a lab phone):

```bash
D=/data/local/tmp/q4b
adb shell "cd $D; LD_LIBRARY_PATH=$D/qwen3_4b MODULAR_DRIVER_PLUGINS=vulkan@$D/qwen3_4b/libM_driver_vulkan.so QWEN3_PREFILL=1 QWEN3_WARM=1 ./qwen3_4b/qwen3_4b $D/q4 $D/q4/qwen3_4b_q4.bin 64 @$D/runs/ids.txt"
```

The program's switches (`qwen3_4b.mojo`):
- `QWEN3_PREFILL=1`: batched prefill.
- `QWEN3_CTX`: K/V positions (default 2048, at most 8192).
- `QWEN3_LOGITS` and `QWEN3_LOGITS_EVERY`: write logit rows.
- `QWEN3_EOS`: stop tokens.
- `QWEN3_DUMP`: per-layer residual streams.
- `QWEN3_WARM`: untimed warm-up runs.
- `QWEN3_PROFILE=1|prefill`: time each kind of launch.
- `QWEN3_ATTN=qwen3k`: the old decode attention.
- `QWEN3_SKIP=qkv,attn,o,gu,down,norm,head`: leave kinds of launch out, for timing ablations.

## Lessons

- **Gate timings on the battery, and suspect latency-bound kernels.** Back-to-back runs on the Fold drift from 44.7
  to 51 ms a token, so every timed run here waited for the battery to read ≤ 30.0 °C (`dumpsys battery`; the GPU's
  thermal zone at ≤ 38 °C was not enough). Even so, at 1,024 positions qwen3k's attention gave 53.6-65 ms a token
  from run to run, and the first chunked version 58-65. Decode with the attention left out stayed at 42.2-43.7 ms,
  and the final bandwidth-bound attention at 47.5-49.6.
- **Ablate, don't profile, for decode.** `QWEN3_PROFILE=1` waits after every launch: 115 ms a token against 45
  without. Leaving a kind of launch out (`QWEN3_SKIP`) saved about 16 ms for gate/up, 11 for down, 4 for q/k/v and
  3.8 for attention at 440 positions (single runs, before the battery gate; the savings don't add up exactly).
- **Mojo's SPIR-V target asserted on `shuffle_xor` of a `SIMD[float32, 4]`** (a crash in the compiler,
  `SmallVector.h` index). Four scalar shuffles compile.
- **A sibling module's `sys.path` edit leaks.** `lfm2/weights.py` puts `lfm2/` first on `sys.path`, so after loading
  it, `import run` found `lfm2/run.py`. `weights.py` restores the path after loading it.
- **An `adb shell` with a `for` loop survived** on this RTL bridge once (it has dropped the bridge before). Don't rely
  on it.

## Follow-ups

- **NPU prefill + GPU decode**, as `../npu/hybrid_qwen3.mojo` does for ternary Qwen3-8B and `../lfm2` for LFM2. This
  needs w8a16 graphs from `../npu/export_qwen3.py` generalized to Qwen3-4B's sizes. They would hold about 4 GB of
  int8 contexts, so, as there, the NPU and the GPU's 2.36 GB would not be held at once on the 11 GB Fold. LFM2's NPU
  prefill ran 6.5× its GPU's.
- **An 8-bit storage** (int8 rows with a scale per 64, as `../gemma4`'s `--storage int8`) for the bf16 agreement.
  Q4_0 alone costs KL 0.05-0.17 here. At 4.1 GB with the Q6_K head, decode would be about 70 ms.
- **fp16 K/V cache**: half the attention's bytes at long contexts (5-6 ms → ~3 at 1,100 positions).
- **Prefill padding**: a 64-row tile for the batch's last rows would take a 404-token prompt from 512 rows of work
  to 448.

## Files

| File | |
|---|---|
| `model.mojo` | the forward pass: decode `step`, batched `prefill`, weights from the manifest |
| `qwen3_4b.mojo` | the program: greedy generation, timings, logits, memory |
| `kernels/q4bk.mojo` | add + RMS norm (eps 1e-6), prefill rows' q/k norm + RoPE from p0, decode attention in chunks |
| `convert.c` | `qwen3_4b_convert`: bf16 shards → Q4_0 / Q6_K weight file on the phone; also the reference's quantizer |
| `export.py` | `recipe.txt` and `manifest.txt` from the safetensors headers; the RoPE table |
| `weights.py` | the checkpoint streamed by HTTP range; the phone's quantization of any tensor |
| `reference.py` | transformers' Qwen3 a layer at a time, bf16 and int4 in one pass; `--selftest` |
| `run.py`, `check.py` | run on the phone (and record); compare recorded runs with the reference |
| `stage_phone.sh` | stage a wiped phone: download, convert, push |
