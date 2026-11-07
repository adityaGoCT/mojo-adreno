# LFM2-MoE on Adreno: LFM2.5-8B-A1B on the phone, LFM2.5-24B-A2B on the laptop

LiquidAI's mixture-of-experts LFM2.5 models, 4-bit, in Mojo on the GPU:

| | LFM2.5-8B-A1B | LFM2.5-24B-A2B |
|---|---|---|
| Checkpoint | `LiquidAI/LFM2.5-8B-A1B-GGUF` @49c14831, `Q4_0` | `LiquidAI/LFM2.5-24B-A2B-GGUF` @7be3a8c7, `QAD-Q4_0` |
| Layers | 24: 18 short conv, 6 attention (2, 6, 10, 14, 18, 21) | 40: 30 short conv, 10 attention (2, 6, ..., 38) |
| MLP | layers 0-1 dense (7168), then 32 experts of 1792, top 4 | layers 0-1 dense (11776), then 64 experts of 1536, top 4 |
| Router | sigmoid; the expert bias only chooses; weights normalized | same |
| File | 4.50 GiB: experts 4.06, the rest 0.44 | 12.64 GiB: experts 12.02, the rest 0.61 |
| Weights read a token | about 1.0 GB | about 1.47 GB (as many as the dense LFM2.5-2.6B) |
| Device | Galaxy Z Fold (Adreno 840, 11 GB visible) | QDC Snapdragon X Elite CRD (Adreno X1-85, 68 GB) |

The 24B's 4-bit file is larger than the phone's whole memory, so it runs on the laptop. Pipette (Liquid's on-device
leaderboard) has no 4-bit 24B entry on the Galaxy S26 Ultra either: llama.cpp on that phone runs the 24B-class models
only at 1-2 bits.

## How it works

- **Weights**: the GGUF's own numbers. `export.py` reads the GGUF's header and writes a recipe; the device downloads
  the GGUF from Hugging Face itself and `lfm2/convert.c` repacks it (Q4_0 to int4 words with their fp16 scales, the
  Q6_K tied head to aligned super-blocks). Each expert's gate and up rows sit together (`egu`, rows `e * 2 FE`), its
  down rows at `e * D` (`edown`).
- **Decode** (`model.mojo` `step`): the router (fp32 weights, as stored) and its top 4 run on the GPU and leave the
  expert ids there; the expert kernels read only those 4 experts' rows (`mk.moe_gate_up`, `mk.moe_down`). No host
  round trip in a token.
- **Prefill** (`prefill_batch`): the batch's (token, choice) pairs are grouped by expert on the GPU (`p_group`), each
  expert's rows copied together and padded to 64 (`p_gather`), and every expert's product runs in one launch
  (`p_gemm_q4g`: a work tile = an expert and 64 of its rows), then each token's 4 outputs are summed with the router's
  weights (`p_combine`). On the 840 the products use the cooperative matrices (fp32, 64 x 64 x 8); the X1-85 has none,
  so there `LFM2MOE_SCALAR=1` uses tiled scalar int4 products (`gemm_q4s`, `p_gemm_q4gs`).
- The rest is the dense LFM2's: short conv, attention, norms and the Q6_K head from `lfm2/kernels/lk.mojo`, the
  matrix-unit prefill attention from `gemma4/kernels`.
- **The laptop**: Mojo has no Windows runtime, so `lfm2moe` runs on the Mac and drives the laptop's GPU through the
  remote driver plugin (`vla/x2`); the weight file never crosses the tunnel (`M_driver_remote_file`: the laptop's
  server reads it from its own disk).

## LFM2.5-8B-A1B on the phone (Galaxy Z Fold SM-F976U, Adreno 840)

Correctness: the "sky" prompt (19 tokens) against `reference.py` on the same GGUF weights: every layer's residual
stream within 1.7e-6 (max |diff| / max), the logits after the prompt within 3.8e-5 (max |logit| 46.2), KL 5e-16, the
same argmax; the text is the model's (it thinks first: `<think> The user asks: ...`).

| LFM2.5-8B-A1B Q4_0 | prefill | decode |
|---|---|---|
| **lfm2moe (Mojo, Adreno 840)**, 414-token prompt, 48 tokens | **323 tok/s** (1.28 s) | **52.9 tok/s** (18.9 ms) |
| Pipette, Galaxy S26 Ultra, llama.cpp b11988 CPU q4_0 (1024 -> 100) | 96 tok/s | 49.1 tok/s |

(Phone clock, one warm-up; not yet the Pipette protocol's exact-token sweep.) On the 840 a row a workgroup decodes
faster than 4 (18.9 vs 20.2 ms), the opposite of the X1-85. The 8B's 4.84 GB on the GPU is most of the phone's
memory: the phone reports about 5.0 GB available with nothing running, so the prefill attention's score buffer grows
with the prompt instead of being sized for 4096 positions (277 MB).

## LFM2.5-8B-A1B against Pipette (Liquid AI's on-device benchmark)

[Pipette](https://pipette.liquid.ai) publishes LFM2.5-8B-A1B (8,468M parameters, 1,500M active) on a Galaxy S26
Ultra (Snapdragon 8 Elite Gen 5, SM8850) with llama.cpp b11988 on the CPU, and on an iPhone 17 Pro with llama.cpp on
its GPU. `../lfm2/pipette.py --model 8b` measures `lfm2moe` on the Adreno 840 by Pipette's protocol, from Pipette's
own weights file, `LFM2.5-8B-A1B-Q4_0.gguf` (SHA-256 `48ed1465…`), staged in `/data/local/tmp/lfm2/plain8b`.

The phone is an SM8850 QRD: Qualcomm Device Cloud's "Canoe" reference phone, with the S26 Ultra's chip, 24 GB and
Android 16 userdebug. It has no internet, so the Mac streamed the GGUF from Hugging Face straight to it
(`curl … | adb exec-in "cat > …"`), and the phone wrote the weight file. Its "sky" tokens match the Fold's run above
at all 30 positions; that run matched transformers' reference layer by layer.

The protocol is the one in `../lfm2/README.md`'s Pipette section:
- prompts of an exact token count, 256 to 4,096 (the same token lists as the 2.6B's: the two models share a tokenizer);
- TTFT as the prefill time, decode over outputs 1 … 100 of an N → 256 run, and E2E to the 256th output;
- 5 repetitions a point, mean ± sample standard deviation, warm-up excluded;
- before each, 20 s idle, no other model process, and the GPU's thermal zone (`gpuss-0`) at or below 45 °C. The QRD's
  battery reads a fixed 39 °C, so it can't serve as the readiness check; the temperature saved with each run is
  that zone's.

Peak RAM is one N → 1 run: the process's resident high-water mark plus swap (Pipette's measure on Android). The GPU's
page allocations above idle are shown apart, since they sit outside it.

At 1,024 input tokens:

| Device, engine | Quant | Decode (1024→100) | Prefill (1024) | TTFT (1024) | E2E (1024→256) | Peak RAM |
|---|---|---|---|---|---|---|
| Galaxy S26 Ultra, llama.cpp CPU (Pipette) | q4_0 | 49 tok/s | 96 tok/s | 10,664 ms | 15,178 ms | 4.90 GB |
| Galaxy S26 Ultra, llama.cpp CPU (Pipette) | q4_k_m | 39 tok/s | 77 tok/s | 13,284 ms | 19,089 ms | 5.19 GB |
| Galaxy S26 Ultra, llama.cpp CPU (Pipette) | q5_k_m | 29 tok/s | 50 tok/s | 20,520 ms | 27,228 ms | 6.00 GB |
| iPhone 17 Pro, llama.cpp GPU (Pipette) | q4_0 | 56 tok/s | 1320 tok/s | 776 ms | 5,521 ms | 4.88 GB |
| SM8850 QRD (Qualcomm Device Cloud), lfm2moe: Mojo, Adreno 840 GPU (int4) (ours) | q4_0 | 52.5 ± 0.2 tok/s | 302 ± 1 tok/s | 3,388 ± 7 ms | 8,260 ± 16 ms | 4.67 GB host + 5.05 GB GPU |

The sweep (Pipette's line is its leaderboard's data for the S26 Ultra's CPU, q4_0):

| Input tokens | Phone | llama.cpp CPU (Pipette, S26 Ultra): TTFT, decode, E2E (→256) | GPU (int4): TTFT, decode, E2E (→256) |
|---|---|---|---|
| 256 | SM8850 QRD (Qualcomm Device Cloud) | 2,300 ms, 52.8 tok/s, 7,401 ms | 1,300 ms, 53.3 tok/s, 6,084 ms |
| 512 | SM8850 QRD (Qualcomm Device Cloud) | 4,701 ms, 51.6 tok/s, 9,814 ms | 1,680 ms, 53.2 tok/s, 6,487 ms |
| 1,024 | SM8850 QRD (Qualcomm Device Cloud) | 10,664 ms, 49.1 tok/s, 15,178 ms | 3,388 ms, 52.5 tok/s, 8,260 ms |
| 2,048 | SM8850 QRD (Qualcomm Device Cloud) | 23,181 ms, 37.2 tok/s, 28,422 ms | 7,972 ms, 51.3 tok/s, 12,954 ms |
| 4,096 | SM8850 QRD (Qualcomm Device Cloud) | 53,275 ms, 32.6 tok/s, 58,487 ms | 20,192 ms, 48.0 tok/s, 25,525 ms |

What the numbers say:
- **Time to first token.** From 512 tokens on, the GPU reads the prompt 2.6–3.1× faster than llama.cpp on the S26
  Ultra's CPU:
  - 1.68 against 4.70 s at 512 tokens;
  - 3.39 against 10.66 s at 1,024;
  - 7.97 against 23.18 s at 2,048;
  - 20.2 against 53.3 s at 4,096.

  At 256 tokens the margin is 1.77× (1.30 against 2.30 s), because the prefill's fixed costs weigh most there:
  256 tokens take 1.30 s, 512 only 1.68 s. With 4 of 32 experts a token, 256 tokens give each expert about 32
  rows, half of a 64-row work tile. The rate falls from 305 to 203 tokens/s between 512 and 4,096 tokens, because
  attention (6 of the 24 layers) grows with the square of the prompt.
- **Decode** stays between 48 and 53 tokens/s at every length (53.3 at 256, 48.0 at 4,096), while llama.cpp's CPU
  falls from 52.8 to 32.6:
  - equal at 256 and 512 tokens;
  - 1.07× at 1,024;
  - 1.38× at 2,048;
  - 1.47× at 4,096.

  Each token reads about 1.0 GB: the shared layers and 4 of the 32 experts in each mixture-of-experts layer.
- **End to end** (to the 256th output token): 1.22× faster at 256 tokens, 1.51× at 512, 1.84× at 1,024, 2.19× at
  2,048 and 2.29× at 4,096.
- **Against Pipette's iPhone 17 Pro** (llama.cpp on its GPU, 1,024 tokens: TTFT 776 ms, decode 55.5 tokens/s, E2E
  5.52 s), the iPhone leads on all three. Its prefill is 4.4× ours (1,320 against 302 tokens/s), and that is where our
  work is. The expert products run on the 840's fp32 cooperative matrices, and the 2.6B's NPU prefill (`../lfm2`)
  shows what an NPU prefill could add.
- **Peak RAM.** By Pipette's measure (VmHWM + swap) we hold 4.67 GB, under llama.cpp's 4.90 GB, but 4.53 GB of that
  is the mapped weights file. The GPU's own pages are another 4.9–5.4 GB: the weights, the 6 attention layers' cache
  for 4,608 positions, and the prefill's buffers. Reading the file in pieces would leave about 0.15 GB resident.
- **The phone.** These numbers come from Qualcomm's reference phone (24 GB), not a retail one. On the 2.6B, another
  of these phones had a GPU prefill 9–10% slower than a retail Galaxy Z Fold's, and a decode 3–10% faster.

## LFM2.5-24B-A2B on the laptop (QDC Snapdragon X Elite X1E80100, Adreno X1-85)

Correctness: the "sky" prompt (20 tokens) against `reference.py` on the same GGUF weights: every layer's residual
stream within 1.6e-6 (max |diff| / max), the logits after the prompt within 6.1e-5 (max |logit| 22.5), KL 2e-11, the
same argmax; the generated text is the model's ("We need to answer: ... Rayleigh scattering ...").

The X1-85 has no `VK_KHR_cooperative_matrix` (probe: `coopmat/vk_coopmat_probe.c`), so prefill runs the scalar
kernels (`LFM2MOE_SCALAR=1`). Times on the laptop's clock: decode by `LFM2MOE_REPLAY` (the server reruns a recorded
step), the prompt as the server's segment (`VK_SERVER_SEGMENTS=1`), warm. Same GGUF for llama.cpp (b11988, the
Windows-on-Arm releases, `llama-bench -p 512 -n 64 -r 2`):

| LFM2.5-24B-A2B QAD-Q4_0, X1E80100 | prefill | decode |
|---|---|---|
| **lfm2moe (Mojo, Adreno X1-85)**: 415-token prompt | **71 tok/s** (5.82 s) | **35-38 tok/s** (26.6-28.3 ms) |
| llama.cpp OpenCL (Adreno), pp512 / tg64 | 109 tok/s | 34.3 tok/s |
| llama.cpp CPU (12 Oryon cores), pp512 / tg64 | 186 tok/s | 53.4 tok/s |
| llama.cpp Vulkan | did not finish pp512 in 10 minutes | |

Settings: `LFM2MOE_SCALAR=1 LFM2MOE_TM=16 LFM2MOE_WAVE=1 LFM2MOE_ROWS=4 LFM2MOE_HEAD_ROWS=4 LFM2MOE_DOWN=flat`.

What moved the X1-85 (ablations on the server's clock, `LFM2MOE_SKIP` / `LFM2MOE_PSKIP`):
- Decode 50.9 -> 32.0 ms with 4 weight rows a workgroup (`gemv_q4r`): a row a workgroup reads 128 bytes of x from
  cache for each 18-byte int4 block. A 4-row Q6_K head 31.6 -> 30.1 ms; the experts' down product with the lanes over
  all 4 experts' blocks (192 = 3 x 64 for 1536 columns) -> 28.3 ms. 8 rows a workgroup is slower (37.7 ms).
- Decode is now launch-bound: 370 dependent launches a token; the 80 one-workgroup norms cost 6.1 ms (76 us each).
  Batching submits (`VK_SUBMIT_EVERY` 8-128) gains at most 2 ms: the cost is the barrier between dependent launches.
- Prefill 11.4 -> 5.8 s: 64 experts and 415 tokens leave about 26 rows an expert, so 64-row work tiles computed 2.5x
  the real rows (16-row tiles 1.3x); one-subgroup workgroups (16 x 64 tile, 64 threads, 4 x 4 a thread, k-major
  shared memory) beat 256-thread tiles. The scalar fp32 tiles run at about 0.4 TFLOP/s: the experts' products are
  3.7 s and the conv projections 1.3 s of the 5.8.
- 128-lane subgroups (`VK_SUBGROUP_SIZE=128` or the driver's choice) break the 64-lane reductions and gain nothing.

## Reference

`reference.py` runs transformers' own `Lfm2MoeDecoderLayer`s a layer at a time in fp32 on the Mac, on the GGUF's
weights dequantized exactly as ggml does (`weights.py GGUFWeights`, read from Hugging Face by range request, a layer
at a time) or on the bf16 checkpoint (`BF16Weights`). `--selftest` checks the driver against the whole
`Lfm2MoeForCausalLM` on a tiny random model (max |diff| 6e-7, incremental decode too). `--trace` records every MoE
layer's router choices.

GGUF against bf16, tensor by tensor (8B): Q4_0 matrices 8.6-9.1% relative error, the Q6_K embedding 1.7%, the
router, expert bias, norms and conv taps exact.

## Run

```bash
PY=build/vla/venv/bin/python
LFM2MOE=8b  $PY lfm2moe/export.py               # build/lfm2moe/8b/q4/{recipe,manifest}.txt, rope.f32
LFM2MOE=24b $PY lfm2moe/export.py
LFM2MOE=8b  $PY lfm2moe/reference.py --jobs build/lfm2moe/8b/ref/jobs.json
python3 lfm2moe/build_android.py                 # build/android/lfm2moe (the phone)
lfm2moe/build_mac.sh                             # build/lfm2moe/x2 (the Mac program, plugin, vk_server.exe, convert.exe)
LFM2MOE=8b  $PY lfm2moe/run.py --target phone  --prompt sky --check
LFM2MOE=24b $PY lfm2moe/run.py --target laptop --prompt sky --check --env LFM2MOE_SCALAR=1
# Pipette's protocol on a phone: Pipette's own Q4_0 GGUF, the programs and the q4 recipe in /data/local/tmp/lfm2/plain8b
# (bin/: build/android/lfm2moe and lfm2_convert; rope.f32; q4/; lfm2moe_q4.bin written there by lfm2_convert)
for n in 256 512 1024 2048 4096; do $PY lfm2/pipette.py gpu --model 8b --input $n; done   # build/lfm2moe/pipette/
$PY lfm2/pipette.py --table --model 8b
```
