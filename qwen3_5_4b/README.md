# Qwen3.5-4B on the Adreno 840

Qwen's **Qwen3.5-4B** ([`Qwen/Qwen3.5-4B`](https://huggingface.co/Qwen/Qwen3.5-4B), revision `851bf6e8`, Apache-2.0)
generates text on a Galaxy Z Fold (SM-F976U, Snapdragon 8 Elite Gen 5, Adreno 840, 11 GB) in Samsung's Remote Test
Lab. Only the text model runs here; the vision tower and `mmproj` are skipped. A Mojo `DeviceContext` program on the
phone runs it, with Mojo kernels compiled to adreno840 SPIR-V.

The weights are unsloth's Q4_0 GGUF, the file behind Pipette's Qwen3.5-4B q4_0 rows:
[`unsloth/Qwen3.5-4B-GGUF`](https://huggingface.co/unsloth/Qwen3.5-4B-GGUF) `Qwen3.5-4B-Q4_0.gguf`, revision
`e87f1764`, 2,583,221,408 bytes, SHA-256 `298fcb5f…72b8bb`. The phone downloads it from Hugging Face itself (about a
minute). `convert.c` repacks it in a few seconds into the 2.64 GB the kernels read, keeping every number as it is.

Qwen3.5-4B is a hybrid. Three of every four layers are **linear attention** (Gated DeltaNet), which carry a fixed
128 × 128 state per head instead of a K/V cache. Every fourth layer is **gated full attention**. The new kernels run
the delta rule's recurrence a row after another, with each head's state in registers.

The prompt is the passage of `../lfm2/prompts/long.txt` in Qwen3.5's chat template (thinking on, the template's
default): 410 tokens. Each row then generates 64 greedy tokens. Times are the phone's own clock, warm (after one
untimed run of the prompt), each run after the battery cooled to 30 °C.

| Galaxy Z Fold SM-F976U, Adreno 840 | Prefill | Decode | vs transformers on the GGUF's own weights | vs bf16 (the published model): greedy, KL |
|---|---|---|---|---|
| 410-token prompt + 64 tokens | 1.955-1.957 s (**209.6 tokens/s**) | **48.1 ms/token** (20.8 tokens/s; 47.4-48.4 over 3 runs) | logits within 1.0e-4 (range -14.5 … 36.2); 64 of 64 tokens | 60 of 64, KL 0.012 |
| 21-token prompt + 64 tokens | 0.43 s (padded to 64 rows) | **47.9 ms/token** (20.9 tokens/s; 46.9-48.3) | within 1.2e-4; 64 of 64 | 63 of 64, KL 0.0065 |
| Pipette protocol: 1,024 tokens → 256 | TTFT 4.18 s (245 tokens/s) | 49.8 ms (20.1 ± 0.3 tokens/s, outputs 2-100) | (same program) | |

- **Exact on its weights.** Teacher-forced on the phone's own tokens, transformers' Qwen3.5 layers running the GGUF's
  weights (dequantized as ggml does, in transformers' layout) give logits within 1.2e-4 of the phone's at every
  checked position. Every one of the 128 generated tokens is the reference's argmax.
- **Against bf16.** The GGUF in transformers agrees with the bf16 model's greedy choice at exactly the same
  positions as the phone, with the same KL: 0.0122 against the phone's 0.0122, and 0.0065 against 0.0065. The first
  difference comes at generated token 17 (long prompt) and 55 (short prompt), so the GPU adds nothing to what the
  file costs. The file costs far less than Qwen3-4B's round-to-nearest Q4_0 did (KL 0.05-0.17 there). unsloth
  quantized it with an importance matrix (its metadata names one), and five of its tensor kinds are not Q4_0.
- **Decode is memory-bound.** A token reads the 2.64 GB of weights once, plus each linear layer's 2 MB state, read
  and written back. At 47-48 ms that is 56 GB/s, the rate Qwen3-4B's 43.2 ms reached for 2.36 GB. The vocabulary
  is 248,320 tokens, so the Q6_K tied head alone is 0.52 GB (20 % of the bytes, about 9 ms a token).
- **Prefill is compute-bound** on the fp32 cooperative matrices. The projections run at about 2 TFLOP/s; the MLP's
  gate/up and down products take 1.1 s of the 1.96 s. The delta rule's recurrence takes 80 ms (24 layers × 410 rows
  in turn), the full attention 42 ms.

## Against Pipette (Liquid AI's on-device benchmark)

`../lfm2/pipette.py gpu --model qwen3.5-4b` runs Pipette's protocol (see `../lfm2/README.md`): a 1,024-token prompt
(the same passages as for LFM2 and Qwen3-4B, in Qwen3.5's tokenizer, no BOS), greedy, 5 repetitions after a readiness
wait (battery ≤ 31 °C, 20 s idle), decode over outputs 2-100 and E2E to the 256th output token, and peak memory from
a 1,024 → 1 run. Pipette's rows are for exactly this GGUF file (q4_0) run by llama.cpp b11988.

| Device, engine | Quant | Decode (1024→100) | Prefill (1024) | TTFT (1024) | E2E (1024→256) | Peak RAM |
|---|---|---|---|---|---|---|
| Galaxy S26 Ultra, llama.cpp CPU (Pipette) | q4_0 | (none) | 76 tok/s | 13,555 ms | 26,463 ms | 3.16 GB |
| Galaxy S26 Ultra, llama.cpp CPU (Pipette) | q4_k_m | 14.5 tok/s | 57 tok/s | 17,861 ms | 33,110 ms | 3.31 GB |
| iPhone 17 Pro, llama.cpp GPU (Pipette) | q4_0 | 22.3 tok/s | 515 tok/s | 1,990 ms | 13,414 ms | 3.17 GB |
| **Galaxy Z Fold SM-F976U, Mojo, Adreno 840 GPU (ours)** | q4_0 | **20.1 ± 0.3 tok/s** | **245 ± 0 tok/s** | **4,182 ± 3 ms** | **18,650 ± 183 ms** | 2.54 GB host + 2.80 GB GPU |

- Against the S26 Ultra's llama.cpp on its CPU (the same SM8850 chip), the Fold's GPU reads the prompt 3.2× as fast
  (TTFT 4.2 s against 13.6 s) and finishes 1.4× sooner (18.7 s against 26.5 s).
- The iPhone 17 Pro's GPU is ahead: 2.1× our prefill, and 22.3 against 20.1 tokens/s. Its E2E is 13.4 s against
  18.7 s. Our E2E counts the 2.0 s it takes to load the 2.64 GB of weights into the GPU, as Pipette's protocol does.
- Peak memory: the process's VmHWM is 2.54 GiB, almost all file-backed (RssFile 2.49 GiB: the weight file as read).
  The GPU's page allocations rise 2.80 GiB above idle: the weights, the K/V cache of 8 layers (1,344 positions, 12 MB
  a layer), the 24 linear layers' states (2 MB each) and the prefill's buffers.

## The model

From `config.json` (its `text_config`) and transformers' `modeling_qwen3_5.py` (5.5.4; read, not recalled):

| | |
|---|---|
| Layers | 32: `linear_attention` × 3, then `full_attention`, eight times; each RMSNorm → token mixer → residual, RMSNorm → SwiGLU MLP → residual |
| Norms | zero-centred RMSNorm, x / rms(x) × (1 + w), eps 1e-6 (input, post-attention, q/k head norms, final) |
| Hidden, MLP | 2560; SwiGLU, 9216 |
| Linear attention (Gated DeltaNet) | `in_proj_qkv` → q (16 key heads × 128) \| k (16 × 128) \| v (32 value heads × 128); a depthwise causal conv of 4 taps over those 8,192 channels, then SiLU; q and k L2-normed per head (q also × 1/√128); `in_proj_a`, `in_proj_b` (32 each): decay = exp(-exp(A_log) · softplus(a + dt_bias)), β = sigmoid(b); a value head reads key head h / 2 |
| The delta rule | per value head, a 128 × 128 state S: S ← decay · S; S ← S + k (β (v − Sᵀk))ᵀ; out = Sᵀq; then RMSNorm over the head's 128 with a plain weight (not 1 + w), × SiLU(z) (`in_proj_z`, 4096), and `out_proj` (4096 → 2560) |
| Full attention | 16 query and 4 KV heads of 256; `q_proj` gives each head's q and an output gate (512 a head); q/k head norms; RoPE on the first 64 of 256 dimensions (rotate-half, θ = 10,000,000); scale 1/16; output × sigmoid(gate), then `o_proj` |
| RoPE | multimodal RoPE (`mrope_section` [11, 11, 10], interleaved). For text all three position ids are the token's position, so it is ordinary RoPE |
| Vocabulary, head | 248,320; tied embedding |

Two things are left out. The checkpoint's multi-token-prediction layer (`mtp.*`) is not in the GGUF, and the vision
tower is not used.

## Weights

The "Q4_0" GGUF is not all Q4_0. Listing its 426 tensors' GGML types first showed this:

| Tensors | GGML type | Stored for the GPU as |
|---|---|---|
| attn_qkv, attn_gate (linear layers); attn_q, attn_k, attn_v, attn_output (full layers); ffn_gate, ffn_up; ffn_down of layers 4-31 | Q4_0 (172 matrices) | `lk`'s int4 words + fp16 scales, fused per layer: q\|k\|v\|z (12,288 rows), q\|k\|v\|gate (10,240), gate\|up (18,432) |
| ffn_down of layers 0-3 | Q4_1 | the affine storage (below), no high bits |
| ssm_out (`out_proj`, 24 layers) | Q5_K | the affine storage with a word of high bits a block |
| ssm_alpha, ssm_beta (`in_proj_a`, `in_proj_b`) | Q8_0 | fp32 (q · d is exact in fp32), one 64 × 2560 matrix a layer |
| token_embd (= the tied head) | Q6_K | `lk`'s 208-byte super-blocks + fp16 d's (`embed_q6`, `head_q6`) |
| norms, ssm_conv1d (8192 × 4), ssm_dt.bias, ssm_a, ssm_norm | F32 | fp32 |

The **affine storage** (`convert.c`, `kernels/q35k.mojo`) holds Q4_1 and Q5_K without changing a weight. Per block of
32 it keeps the four low bits as `lk`'s int4 words (low nibble − 8), a word of fifth bits for Q5_K, and fp32 `d` and
`c`, with w = d · (lo − 8 + 16 · hi) + c. For Q4_1, c = 8d + m. For Q5_K, d = d · scale_j and c = 8 · d − dmin · min_j,
computed as ggml computes its d1 and m1. `convert.c` was checked on the Mac against ggml's dequantization of real
tensors from the file: Q5_K and Q4_1 decoded through the affine formula, Q8_0 and Q4_0 all equal ggml's values.

By bytes: gate|up 849 MB, the Q6_K embedding / head 522 MB, q|k|v|z 425 MB, down 442 MB, out_proj 220 MB, the full
layers' projections 165 MB, a|b 16 MB.

llama.cpp's converter changed the layout, and `weights.GGUFWeights` undoes it for the reference. Each change below was
checked tensor by tensor against the bf16 checkpoint (`python qwen3_5_4b/weights.py`):
- **The value heads are tiled, not grouped.** GGUF head i is transformers' head 2 (i mod 16) + ⌊i / 16⌋, so it reads
  key head i mod 16 (ggml broadcasts by tiling). This applies to `in_proj_qkv`'s v rows, `in_proj_z`, `in_proj_a`/`_b`,
  `A_log`, `dt_bias`, the conv's v channels and `out_proj`'s columns. The phone keeps the GGUF's order throughout.
- **The zero-centred norms are stored as 1 + w** (exactly: the bf16 values plus 1 in fp32). The kernels use them
  as they are. The gated norm's weight is stored as it is.
- **`ssm_a` = −exp(A_log)** (exactly).
- `attn_q` keeps each head's q and gate rows together, as transformers does. `export.py` splits them, so the q heads
  and the gates each come out contiguous.

## The GPU

`model.mojo` (the forward pass) and `qwen3_5_4b.mojo` (the program) follow `../qwen3_4b`. Token ids live on the GPU,
and the argmax writes the next one, so a decode step never waits for the host. The program prints the same
`tok <id> <ms>`, `prompt:`, `decode:` and `mem:` lines that `../lfm2/pipette.py` parses.

| Step | Decode (one token) | Prefill (batches of up to 512 rows) | Kernels from |
|---|---|---|---|
| embedding, norms, residual adds | `embed_q6`, `add_norm` | the same, a row a workgroup | `lk`, `q4bk` (eps 1e-6) |
| Q4_0 projections | `gemv_q4` / `gate_up_q4` | `gemm_q4` (128 × 128 tiles on fp32 64 × 64 × 8 cooperative matrices) + `gemm64` for a last 64 rows | `lk`, `q35k` |
| Q4_1 / Q5_K projections | `gemv_aff` | `gemm_aff` (`gemm_q4` with the affine unpacking) + `gemm64` | `q35k` |
| a\|b | `gemv_f32` | the same, a workgroup a row and output | `q35k` |
| conv + SiLU, q/k L2 norms, decay and β | `conv_qk` (updates the 3-position ring) | `conv_qk`, then `conv_state` | `q35k` |
| the delta rule | `delta_rule` | `delta_rule`: every row in turn, the state in registers | `q35k` |
| gated norm | `gated_norm` | `gated_norm` | `q35k` |
| q/k norms, RoPE (64 of 256), K/V rows | `qk_norm_rope` | `qk_norm_rope` (q pre-scaled by 1/16) | `q35k` |
| attention × sigmoid(gate) | `attn_part` + `attn_combine` (chunks of 32 positions, the gate folded in) | `p_scores_mma`, `p_softmax`, `p_values_mma`, `gate_mul` | `q35k`, `g4k` |
| head, argmax | `head_q6` (Q6_K), `argmax` | the last row only | `lk` |

**The delta rule** (`q35k.delta_rule`) gives a 16-lane group one column of a head's state. Each lane holds 8 of the
128 key dimensions, so one 16-lane shuffle sum gives Sᵀk and another Sᵀq. Every column is independent: the update of
column v needs only v's own Sᵀk. During a prefill, a workgroup walks the batch's rows in turn, with the state in
registers, and writes it back once. Two changes took the 24 layers' recurrence over 410 rows from 248 ms to 80 ms:
- Loading the next row's q, k, v, decay and β before this row's arithmetic.
- Giving each group two columns, so two independent chains share the q and k loads (`QWEN35_DNC`; four were no
  faster).

**Prefill padding.** `gemm_q4`'s tiles are 128 rows, so a 410-token prompt paid for 512. `q35k.gemm64` computes a
batch's last 64 rows with a 64 × 128 tile (two subgroups), so the 410 rows cost 448. That took the prefill from
2.22 s to 1.96 s. Loading the affine storage's per-block constants once per 32 weights, not once per 16, took its
products from 252 to 208 ms. They are still 1.6× `gemm_q4` on the same shapes.

Prefill profile (410 tokens, `QWEN35_PROFILE=prefill`; each launch waited for): gate/up 714 ms, down 420, q|k|v|z 348,
out_proj 227, full attention's q|k|v|gate 100, delta rule 86, residual adds and norms 52, o_proj 51, full attention
42, a|b 27, conv 21, gated norm 17, head 9.

**Prefill on fp16 cooperative matrices** (`QWEN35_GEMM=q`). This applies Qwen3-4B's `QWEN3_GEMM=q`
([`../qwen3_4b/README.md`](../qwen3_4b/README.md)) to the batch's whole 128s of rows, for batches of 256 or more:
- X is packed into fp16 tiles (`lkh.pack_x`).
- The Q4_0 projections run on `lkh.gemm_hq`, which unpacks the int4 rows into shared memory inside the product.
- The affine storage is first unpacked into fp16 tiles (`q35k.deq_aff`) and multiplied by `lkh.gemm_h`.
- K is split into chunks of 2,048, added in fp32 by `lkh.sum_parts`.
- A last 64 rows stay on `gemm64`.

It needs the fork's SPIR-V backend from `2cb90a66ac`. On a Galaxy Z Fold the 410-token prompt takes 1,274 ms instead of
1,954-1,994 (322 tokens/s instead of 207; alternating runs, each after the GPU cooled to 45 °C), and decode is
unchanged. Against the GGUF's weights, 64 of 64 tokens match, with KL 3.6e-5 and logits within 0.11. Against bf16, 60
of 64 tokens agree, as for the int4 reference itself (KL 0.0113 against its 0.0122).

## Checks

- `reference.py` drives transformers' own `Qwen3_5DecoderLayer` (Gated DeltaNet with transformers' chunked delta rule,
  gated attention, MLP), `Qwen3_5TextRotaryEmbedding`, `create_causal_mask` and `Qwen3_5RMSNorm`. It runs a layer at a
  time in fp32, with the tied head. `--selftest` matches the whole `Qwen3_5ForCausalLM` exactly (difference 0) on a
  tiny random model with Qwen3.5's structure: 3 linear layers and a full one, GQA, partial RoPE, a tied head.
- Both weight sets are streamed from Hugging Face by HTTP range request, and the Mac keeps neither:
  - **q4** is the GGUF, dequantized as ggml does and mapped back to transformers' layout. It is the phone's own
    numbers, so this is the exact check.
  - **bf16** is the published checkpoint, the model itself.
- `stages.py` compares the phone's residual stream after every layer (`QWEN35_DUMP`) with the reference's. For the
  21-token prompt every layer matched: within 2e-6 to 2e-4, on values up to 118.
- `run.py --rows 16 --name N`: the phone writes 16 logit rows (every 4th position, 1 MB each). `check.py` then
  compares every recorded run, teacher-forced on the phone's tokens, in one pass over both files, and keeps the
  reference logits (`build/qwen3_5_4b/runs/ref/`). One pass read 11.0 GB, in 25 minutes.

```
sky_final: 64 tokens after a 21-token prompt
  vs q4 (the GGUF's weights): logits within 1.24e-04 at 16 rows (range -14.0 .. 35.2), KL 1.20e-11; argmax = phone token at 64 of 64
  vs bf16: argmax = phone token at 63 of 64 (first difference at 55); max |logit diff| 4.82, KL 0.0065 | the q4 reference itself: 63 of 64, KL 0.0065
long_final: 64 tokens after a 410-token prompt
  vs q4 (the GGUF's weights): logits within 1.03e-04 at 16 rows (range -14.5 .. 36.2), KL 1.80e-12; argmax = phone token at 64 of 64
  vs bf16: argmax = phone token at 60 of 64 (first difference at 17); max |logit diff| 4.61, KL 0.0122 | the q4 reference itself: 60 of 64, KL 0.0122
```

The phone's outputs (thinking on):

```
'Thinking Process:\n\n1.  **Analyze the Request:**\n    *   Topic: Why the sky is blue.\n    *   Constraint: Exactly
two sentences.\n\n2.  **Identify Key Scientific Concepts:**\n    *   Sunlight is white (composed of all colors).\n    *  '
'Thinking Process:\n\n1.  **Analyze the Request:**\n    *   Input: A passage about mobile graphics processors, memory
bandwidth, and language models.\n    *   Task: Answer a specific question based on the passage.\n    *   Question:
"according to the passage, why is reading a'
```

## Run it

```bash
python3 android/build.py qwen3_5_4b                   # build/android/qwen3_5_4b: the program and qwen3_5_4b_convert
build/vla/venv/bin/python qwen3_5_4b/export.py        # build/qwen3_5_4b/q4/{recipe,manifest}.txt, rope.f32
qwen3_5_4b/stage_phone.sh                             # the phone downloads the GGUF, converts (/data/local/tmp/q35)
build/vla/venv/bin/python qwen3_5_4b/run.py --prompt-file lfm2/prompts/long.txt --tokens 64   # text + timings
build/vla/venv/bin/python qwen3_5_4b/run.py --tokens 64 --rows 16 --name sky --no-eos          # record for check.py
build/vla/venv/bin/python qwen3_5_4b/check.py sky     # vs transformers, bf16 and the GGUF's weights
build/vla/venv/bin/python qwen3_5_4b/reference.py --selftest
build/vla/venv/bin/python lfm2/pipette.py gpu --model qwen3.5-4b --input 1024                  # Pipette's protocol
build/vla/venv/bin/python lfm2/pipette.py --table --model qwen3.5-4b
```

`run.py` waits for the battery to read ≤ 30 °C first (`--cool`). On the phone, by hand (one plain command per `adb
shell` on a lab phone):

```bash
D=/data/local/tmp/q35
adb shell "cd $D; LD_LIBRARY_PATH=$D/qwen3_5_4b MODULAR_DRIVER_PLUGINS=vulkan@$D/qwen3_5_4b/libM_driver_vulkan.so QWEN35_PREFILL=1 QWEN35_WARM=1 ./qwen3_5_4b/qwen3_5_4b $D/q4 $D/q4/qwen3_5_4b_q4.bin 64 @$D/runs/ids.txt"
```

The program's switches (`qwen3_5_4b.mojo`):
- `QWEN35_PREFILL=1`: batched prefill.
- `QWEN35_CTX`: K/V positions (default 2048, at most 8192).
- `QWEN35_LOGITS` and `QWEN35_LOGITS_EVERY`: write logit rows.
- `QWEN35_EOS`: stop tokens (248046 `<|im_end|>`, 248044 `<|endoftext|>`).
- `QWEN35_DUMP`: per-layer residual streams.
- `QWEN35_WARM`: untimed warm-up runs.
- `QWEN35_PROFILE=1|prefill`: time each kind of launch.
- `QWEN35_DNC=1|2|4`: the prefill delta rule's columns a group.
- `QWEN35_GEMM=q`: prefill projections on fp16 cooperative matrices (batches of 256 rows or more).

## Lessons

- **List a GGUF's tensor types before writing kernels.** The "Q4_0" file carries five quantization types: its
  recipe keeps the first four down projections and every linear-attention output projection at higher precision,
  and the small a / b projections at 8 bits. One storage (affine, with optional high bits) covers Q4_1 and Q5_K without changing a weight.
- **Check a GGUF's layout against the checkpoint, tensor by tensor.** llama.cpp tiled the value heads, added 1 to the
  zero-centred norms and stored −exp(A_log). Each change is exact, so comparing the F32 tensors with the bf16 ones
  found every one (`weights.py`). A reference fed the GGUF in transformers' layout then checks the phone exactly.
- **A recurrence can stay sequential in prefill.** The chunked delta rule is what GPUs use for training, but for one
  prompt on the phone, rows in turn with the state in registers cost 80 ms for 410 rows × 24 layers. That is 4 % of
  the prefill, and it is the decode kernel's arithmetic. What made it fast was latency hiding (prefetch the next row,
  two independent columns a group), not more parallelism.
- **Pad to 64, not 128.** A 64-row tile for a batch's last rows cut the prefill by 12 % (Qwen3-4B's follow-up).
- **Lab bridge.** The first run's bridge dropped, and the phone came back wiped from a new session. Afterwards
  `adb devices` said "device" while every `adb shell` hung, which `adb disconnect` + `adb connect` fixed. Pipette's
  own-process guard in `../lfm2/pipette.py` needed this model's directory (`/q35/`), or it discarded its own runs as
  "another model process".

## Follow-ups

- **NPU prefill + GPU decode**, as `../lfm2` does: the 8 attention layers and the MLPs are static-shape graphs. The
  delta rule is a scan, which needs an HTP-friendly chunked form.
- **The head**: at 248,320 × 2560, the Q6_K head is a fifth of a decode token's bytes. Q4_0 would save ~3 ms a token,
  at a cost in quality not measured here.
- **Multi-token prediction**: the checkpoint has an MTP layer (`mtp.*`, not in the GGUF). It could draft tokens for
  speculative decoding, as DSpark does for LFM2.
- **The affine products** are still 1.6× `gemm_q4`'s time; a block layout with d, c and the high bits together would
  need one load where it takes three.

## Files

| File | |
|---|---|
| `model.mojo` | the forward pass: decode `step`, batched `prefill`, weights from the manifest |
| `qwen3_5_4b.mojo` | the program: greedy generation, timings, logits, memory |
| `kernels/q35k.mojo` | the affine storage's products, the linear attention (conv, delta rule, gated norm), the gated full attention, the 64-row tail tile |
| `convert.c` | `qwen3_5_4b_convert`: the GGUF → the weight file on the phone (Q4_0 / Q6_K repacked, Q4_1 / Q5_K to the affine storage, Q8_0 to fp32) |
| `export.py` | `recipe.txt` and `manifest.txt` from the GGUF's tensor table; the RoPE table |
| `weights.py` | the checkpoint and the GGUF streamed by HTTP range; ggml's dequantizers; llama.cpp's layout undone |
| `reference.py` | transformers' Qwen3.5 a layer at a time, bf16 and GGUF views; `--selftest` |
| `run.py`, `check.py` | run on the phone (and record); compare recorded runs with the reference |
| `stages.py` | the phone's residual stream a layer at a time against the reference |
| `stage_phone.sh` | stage a wiped phone: download, convert, push |
