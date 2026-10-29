# Bonsai 2 2B on the Adreno 840, with the Android port's Mojo kernels on Vulkan

PrismML's **Ternary Bonsai 2 2B** (text part of `prism-ml/Ternary-Bonsai-2-2B-mlx-2bit`) generating on
the GPU of a Galaxy S26 Ultra (SM-S948U, Snapdragon SM8850, Adreno 840, Android 16, Samsung Remote Test
Lab). The GPU kernels are the Mojo kernels of
[mav3ri3k/modular](https://github.com/mav3ri3k/modular)'s Android port
(`max/examples/android-llm/bonsai/kernels.mojo`, branch `android-publication`, 03de9211). There they
run through that fork's new OpenCL target; here **the same file, unchanged**, goes through this repo's
Mojo → Vulkan SPIR-V target (`--target-accelerator adreno840`), and a small C program schedules the
kernels with Vulkan.

```
$ python bonsai/run.py --model $M --hf $H --push          # validate against the exporter's FP32 logits
prompt: 'What is the capital of France?', 19 tokens; checking 16 steps
device: Adreno (TM) 840  Vulkan 1.4
weights: 605 tensors, 484.4 MiB on the GPU in 0.6 s, context 128
plan: 721 dispatches per token, scratch and caches 23.5 MiB
prompt: 19 tokens in 253 ms
check  0: token    760 reference    760  max abs 0.010038  rel L2 0.00080912 OK
  ...
check 15: token   9338 reference   9338  max abs 0.010849  rel L2 0.00050826 OK
decode: 15 tokens, 12.4 ms/token (80.91 tokens/s)
validation: 16 steps, max abs logit error 0.018940, all greedy ids match
output: 'The capital of France is **Paris**.<|im_end|>\n</think>\n\nThe capital of France'

$ python bonsai/run.py --model $M --hf $H --prompt 'Explain in two sentences why the sky is blue.' --tokens 96
prompt: 23 tokens in 285 ms
decode: 58 tokens, 12.4 ms/token (80.34 tokens/s)
output: "Sunlight contains all colors of the rainbow, but when it travels through the Earth's atmosphere,
shorter wavelengths (like blue) are scattered more strongly by gas molecules than longer wavelengths
(like red). This process is known as Rayleigh scattering, which makes the sky appear blue to our eyes.<|im_end|>"
```

Validation compares all 248,320 logits at each of 16 steps (after the prompt, then after each
token, continuing past `<|im_end|>`) with prepare.py's MLX FP32 reference: every greedy id matches,
max absolute error 0.019, relative L2 at most 1.1e-3. That is the error level of the kernels' FP16
multiply-adds; the port reports the same range for its own OpenCL runs (max absolute 0.011–0.022,
relative L2 4–8e-4, `PERFORMANCE.md`).

## How it fits together

```
Mac                                                                     phone (adb)
kernels/kernels.mojo (the port's, unchanged)
  + a generated main() per kernel --mojo build, adreno840 SPIR-V---> 21 .spv  ------>  bonsai_vk (Vulkan)
checkpoint (MLX 2-bit) --the port's prepare.py (MLX)---------------> weights.bin ---->   721 dispatches per token,
                                                                     reference.f32 -->   one command buffer
chat prompt --tokenizer (transformers)------------------------------> token ids  ---->  <-- token ids, logits
```

- [`build_kernels.py`](build_kernels.py) writes, for each of the 21 kernels the forward pass uses, a
  `main()` that only enqueues it, and compiles it with the source-built Mojo of `../modular` (branch
  `adreno-spirv-target`). The Vulkan ABI makes each pointer argument the next storage buffer and each
  scalar argument a 64-bit slot of a params buffer bound last. All 21 pass `spirv-val` as they are:
  SIMD8 fp16 math, `bitcast` of fp16 pairs, `shuffle_xor` (`OpGroupNonUniformShuffleXor`), `exp`,
  `log`, `rsqrt`, `isfinite`. Nothing in the kernel file changed.
- [`bonsai_vk.c`](bonsai_vk.c) is the port's `model.mojo` `forward()` and `engine.cpp` loader in C:
  the same buffers (`model_spec.h`), dispatches and grids. The packed weights stay 2-bit; each group's
  scale/bias pair (always `bias == -scale`) becomes one fp16 scale at load time, as in the port. All
  721 dispatches are recorded once. Per token only the token id and the position change, in the params
  buffer. Attention scores launch for the whole context, and the kernel skips positions past the
  current one. Greedy selection finishes on the CPU from the head's 485 per-subgroup candidates.
  Pipelines require 64-lane subgroups, since the kernels shuffle across 64 lanes.
- [`run.py`](run.py) builds the runner (NDK), pushes it with the kernels (and with `--push`, the
  weights gzip'ed and the reference), tokenizes with the checkpoint's chat template (thinking off),
  runs and decodes.

Per DeltaNet layer (18): RMSNorm, Hadamard transform, packed q/k/v and z projections, the two gate
projections, causal conv, q/k L2 norm, decay/update gates, the recurrent state update, gated norm,
out projection; per attention layer (6): q (with output gate), k, v, q/k norm, partial RoPE, KV cache,
scores, softmax·V; then the SwiGLU MLP and residuals; then the final norm and the tied packed head.

## Run it

```bash
python3 -m venv /tmp/bonsai-venv
/tmp/bonsai-venv/bin/pip install -r ../modular-android/max/examples/android-llm/bonsai/requirements.txt
/tmp/bonsai-venv/bin/hf download prism-ml/Ternary-Bonsai-2-2B-mlx-2bit --revision 1c6cbae21f8c38830ce337972b46fdae7b18eaaa --local-dir /tmp/bonsai-hf
/tmp/bonsai-venv/bin/python ../modular-android/max/examples/android-llm/bonsai/prepare.py --checkpoint /tmp/bonsai-hf --output /tmp/bonsai-model --tokens 16 --capacity 128
python3 bonsai/build_kernels.py
/tmp/bonsai-venv/bin/python bonsai/run.py --model /tmp/bonsai-model --hf /tmp/bonsai-hf --push
/tmp/bonsai-venv/bin/python bonsai/run.py --model /tmp/bonsai-model --hf /tmp/bonsai-hf --prefill   # Adreno 8xx
```

For the long prompt, export with `--prompt "$(cat llama/prompts/long.txt)" --capacity 512`; `run.py`
pushes each model's reference on every validation run, so one weights file with enough context serves
both prompts.

`../modular-android` is a checkout of mav3ri3k/modular (`android-publication`), used only for
`prepare.py` (MLX, Mac). Its compiler is not needed. The weights file is 568 MiB, 420 MiB gzip'ed,
about 3 minutes over the remote lab's bridge.

## Batched prefill on cooperative matrices

`--prefill` reads the whole prompt at once instead of one decode step per token (from position 0;
`BONSAI_PREFILL=<dir>` in `bonsai_vk`, kernels in [`kernels/prefill.mojo`](kernels/prefill.mojo)). On
Qualcomm's SM8850 reference phone (Adreno 840, driver 512.842.25, Qualcomm Device Cloud), with the
exporter's reference for a 412-token prompt (`llama/prompts/long.txt`, context 512):

```
$ python bonsai/run.py --model $M512 --hf $H --prefill
prefill: 572 dispatches for 512 rows (412 prompt tokens), buffers 139.1 MiB
prompt: 412 tokens in 862 ms                      # token by token on the same phone: 5168 ms
check  0: token  30852 reference  30852  max abs 0.005578  rel L2 0.00044800 OK
  ...
validation: 16 steps, max abs logit error 0.009702, all greedy ids match
output: 'Reading a prompt is faster because processing all tokens together allows weights to be reused for'
```

**About 6× faster** (5.17 s → 0.86-0.89 s), every greedy id matching the FP32 reference over 16 steps,
and closer to it than decode (max abs 0.0097 against 0.0126 for the token-by-token run of the same
prompt): the prefill computes in fp32 throughout. The France prompt passes too (19 tokens in 239 ms;
short prompts gain nothing, as they are padded to 128 rows).

- **Most kernels are the port's decode kernels, unchanged.** A wrapper per kernel takes the prompt
  row from the grid's second dimension, offsets that row's pointers and calls the decode kernel, whose
  `global_idx.x` then indexes inside the row exactly as in decode; positions are row numbers. Norms,
  Hadamard transforms, gates, q/k norms, RoPE, the KV cache, attention values, SwiGLU and residuals
  all run this way, one dispatch for all rows. The wrappers inline the decode kernels (no SPIR-V
  function calls).
- **`p_gemm_t2`: every packed projection as one matrix product over all rows**, fp32 x fp32 -> fp32
  cooperative matrices (64 x 64 x 8), 128 x 128 blocks of 2 x 2 subgroups. Per K step of 16, one 32-bit
  word holds a column's sixteen 2-bit codes, so two threads unpack each column of W's slice, (code - 1)
  x its fp16 group scale, into fp32 in shared memory, consecutive threads on consecutive words.
- **`p_scores_mma`: attention scores as Q K^T per head on the matrix units**, K read column-major
  straight from the KV cache, after `p_scale` multiplies q by 1/16 (exact): 145 ms -> 7 ms.
- **`p_delta_scan`: the DeltaNet recurrence over all rows in one dispatch.** It is sequential in
  the tokens, so it stays a scan: the same lanes as `delta_update` own the same sixteen state rows of a
  column, kept in registers from the first token to the last (26 ms for 18 layers). `p_conv` runs the
  causal conv over all rows and leaves the last three in the history.
- The vocabulary head runs once, on the last row (the decode plan's last four dispatches), and decode
  continues from the conv histories, DeltaNet states and KV caches the prefill left.

Where the 0.86 s goes (`--profile`, one submit per dispatch): projections 795 ms (about 1.8 TFLOP/s on
1.4 TFLOP of products for 512 rows), Hadamard transforms 49 ms, DeltaNet scan 26 ms, attention values
15 ms, scores 9 ms, the rest under 25 ms each. Faster products would need fp16 (fp16 accumulation only
on this driver) or int8 (ternary weights are exact in int8, the activations would not be).

## Compared with the port's OpenCL path

The port's `PERFORMANCE.md` reports about 75 tokens/s median decode on a Galaxy S26 (SM-S942U1, same
Adreno 840) through its OpenCL target, with about 11.9 ms of GPU work per token. Here, the same kernels
through Vulkan run at 80 tokens/s (12.4 ms per token, submit to result) on an S26 Ultra. These were
short runs on a different phone, without thermal control, so they are not a controlled comparison.
What it does show: the kernels lose nothing by going through SPIR-V and Vulkan instead of OpenCL C.

## Limits

- The context is prepare.py's capacity (128 or 512 here, up to 8192). Without `--prefill` the prompt
  runs one token at a time through the decode path, about 12.5 ms per prompt token. The prefill starts
  from position 0 (an empty state), and its scores kernel needs the padded prompt within the context
  (otherwise the per-row scores kernel runs).
- Text only, batch 1, greedy.
- `BONSAI_PROFILE=1` times each dispatch on its own submit. That includes about 0.15 ms of submit
  overhead per dispatch, so it shows where dispatch counts are, not GPU time. Packed projections and
  their reductions are 300 of the 721 dispatches.
- Tested on Android 16 drivers only: 512.842.19 (Galaxy S26 Ultra, decode) and 512.842.25 (the SM8850
  reference phone, decode and prefill; decode there runs at 11.8-15 ms per token).

`kernels/kernels.mojo` is © Modular Inc. and the port's authors, Apache-2.0 with LLVM Exceptions (its
header is kept).
