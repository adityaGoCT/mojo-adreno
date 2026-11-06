# Qwen3-30B-A3B on a Snapdragon X2 Elite laptop, in Mojo

Qwen's mixture-of-experts model
[`Qwen/Qwen3-30B-A3B-Instruct-2507`](https://huggingface.co/Qwen/Qwen3-30B-A3B-Instruct-2507) (revision `0d7cf239`):
30.5B parameters, 3.3B active per token. Each of its 48 layers has grouped-query attention and 128 experts, of
which a router picks 8 per token. It runs in int4 on the Adreno X2-90 GPU of a Snapdragon X2 Elite laptop (X2E88100,
Windows 11 on Arm, 33.6 GB of RAM) in Qualcomm Device Cloud. The forward pass is Mojo `DeviceContext` code, as for
[SmolVLA and π0 on the same laptop](../vla/x2): the program runs on the Mac and drives the laptop's `vk_server`
through the remote driver plugin.

Presentation: **[A 30B mixture of experts on a Snapdragon laptop](../docs/presentation-qwen3moe/qwen3moe-on-the-x2-elite.pdf)**
(6 slides, PDF): fitting it into the GPU, a token without the host, prefill for an MoE, and the Hexagon NPU.
[View it online](https://claude.ai/artifact/THLm8oGyVrqYs6X2d9P2iq), or as an
[HTML slide viewer](../docs/presentation-qwen3moe/qwen3moe-on-the-x2-elite.html) (←/→, N for notes) with
[speaker notes](../docs/presentation-qwen3moe/qwen3moe-on-the-x2-elite-speaker-notes.md).

```
$ build/vla/venv/bin/python qwen3moe/run.py --prompt "Explain in two sentences why the sky is blue." --tokens 96 --check
prompt: 'Explain in two sentences why the sky is blue.', 19 tokens
prompt: 19 tokens in 829.1 ms ( 43.6 ms/token )
decode: 95 tokens in 2814.5 ms ( 29.6 ms/token, 33.75 tokens/s )
output: "The sky appears blue because molecules in Earth's atmosphere scatter shorter wavelengths of light, like blue,
more effectively than longer wavelengths like red. This scattered blue light is what we see when we look up during
the day." (43 tokens to <|im_end|>)
greedy: 95 of 95 given tokens are the reference's argmax
int4: GPU logits within 0.0001 of the reference's (range -29.1 .. 48.1); same argmax at 96 of 96 positions
```

- **Prefill: a 404-token prompt in 4.31 s**, the prompt in batches with experts grouped by token: 2.8× a token
  at a time.
- **Decode: 27–32 ms a token (31–37 tokens/s).** Each token reads 1.63 GB of active weights, so that is
  55–60 GB/s.
- **Exact on its weights.** The GPU's logits are within 1e-4 (relative 7e-6) of a PyTorch reference that runs
  transformers' own Qwen3-MoE layers on the same int4 weights, at every position checked. Every greedy token matches:
  31 of 31 and 95 of 95 on two prompts.
- **Against the bf16 model:** teacher-forced on the GPU's tokens, the original bf16 model's greedy choice agrees at
  31 of 32 positions of the first prompt. The one difference (position 23) comes after the answer has ended. The mean
  KL divergence between the two models' next-token distributions there is 0.053.
- **The weights never cross the network.** The laptop downloads the checkpoint (61 GB of bf16) and converts it to
  int4 in 4 minutes (`convert.exe`). `vk_server` then reads the 15.65 GB into the GPU from its own disk in 4–6 s.
  Through the 3 MB/s SSH tunnel that would take 90 minutes per run.

## Fitting the laptop's memory

The X2-90 has one Vulkan heap for compute: 16.82 GB, half of the laptop's RAM. A second heap of 4.29 GB is
protected memory, unusable here. About 16.0 GB of the big heap was free: a first layout of 16.7 GB (int4 with a
scale per 64 weights everywhere, an fp16 embedding on the GPU) failed to allocate its last 0.95 GB. What the GPU
holds now:

| | Format | Size |
|---|---|---|
| Experts: 48 layers × 128 × (gate, up 768 × 2048; down 2048 × 768) | int4, an fp16 scale per 128 | 14.50 + 0.45 GB |
| Attention: q, k, v (fused, 5120 × 2048), o (2048 × 4096) | int4, a scale per 64 | 0.48 GB |
| Output head (151936 × 2048) | int4, a scale per 64 | 0.17 GB |
| Routers (48 × 128 × 2048) and norms | fp32 (bf16 exactly) | 0.05 GB |
| KV cache, 512 positions | fp32 | 0.10 GB |
| **On the GPU** | | **15.75 GB** |
| Token embedding (151936 × 2048) | fp32 (bf16 exactly), in the file only | 1.24 GB |

- **The embedding stays on the laptop's disk.** A step's first request has `vk_server` copy one row of it, the
  token's, into the GPU's input (`OP_GATHER`). The token id is one the GPU wrote: the prompt's, or the previous step's
  argmax. So a whole generation is enqueued without the Mac waiting for any token.
- **Experts use a scale per 128 weights** instead of 64 (−0.45 GB). The converter picks each group's scale to
  minimize the squared error, from max |w| / d with d in 6.5 … 9, rather than llama/run.py's max |w| / 7. That more
  than pays for the larger groups. Relative errors on layer 47 and the head:

  | | Per 128, scale searched (used) | Per 128, max / 7 | Per 64, max / 7 |
  |---|---|---|---|
  | Expert 100's gate | 10.7% | 12.4% | 11.2% |
  | Expert 127's gate | 10.9% | 12.6% | 11.4% |
  | Expert 100's down | 11.0% | 12.8% | |
  | Output head (per 64) | 9.4% (per 64, searched) | | 10.6% |

## How a token runs

`model.mojo`'s `step()` enqueues 531 launches. Per layer:
1. RMSNorm;
2. q/k/v (int4, `llama/kernels`' `gemv_q4`);
3. QK norm and RoPE (θ = 10⁷), K and V into the cache;
4. attention scores and values (8 query heads share each of the 4 KV heads);
5. o projection plus the residual (`gemv_add_q4`);
6. RMSNorm, then the router (128 logits);
7. `route`: top 8 and their softmax, the experts' ids and weights left on the GPU;
8. `moe_gate_up`: each selected expert's gate and up rows and SiLU, a workgroup per row and expert;
9. `moe_down`: the 8 experts' down projections, weighted and summed into the residual.

Then the final norm, the output head and `argmax`, which writes the next token into the token list. The expert
kernels read the ids the router left, so the host never sees the routing.

## Prefill: the prompt at once, experts grouped by token

A prompt runs in batches of up to 256 tokens (`prefill()`, from 32 tokens on). The weights an MoE uses depend on the
token, so batching splits a layer in two:
- **Attention:** the same for every token. q/k/v and o read each row once for all the prompt's tokens, and causal
  attention runs a workgroup per head and token.
- **Experts:** after the router, `p_expert_lists` gives each of the 128 experts the list of (token, slot) pairs
  that chose it. Each expert then runs once over its own tokens, as a small matrix product with fixed weights (a
  grouped GEMM: on a 404-token prompt, about 25 tokens an expert). Its weights are read once per layer instead of
  once per token, and an expert no token chose costs nothing. `p_moe_sum` then adds each token's 8 weighted
  outputs.

The products run a matrix row per lane against 8 tokens at once: a lane decodes each int4 word once for the 8 tokens
(two 4-wide accumulators), and the token values are the same loads for every lane. Two other layouts were slower:
- a subgroup reduction per (row, token), as in decode: no faster than a token at a time;
- 8 rows × 8 tokens per workgroup with 64-wide accumulators: those spill to private memory, 10× slower.

| Prompt | Batched | A token at a time |
|---|---|---|
| 20 tokens | 1.17–1.33 s | 0.77–0.87 s |
| 48 tokens | 1.26 s | 1.78 s |
| 96 tokens | 1.41–1.63 s | 2.64–3.61 s |
| 128 tokens | 1.66–1.71 s | 4.02–4.25 s |
| 160 tokens | 1.86–1.99 s | 4.71–5.56 s |
| 256 tokens | 2.57–2.66 s (98 tokens/s) | 7.48–7.80 s |
| 404 tokens | **4.24–4.31 s** (94–95 tokens/s) | 11.8–13.1 s |

The prompts are the first tokens of one 404-token prompt. The 96-, 160- and 404-token ranges span two laptop
sessions running the same build. 128 and 256 tokens were timed only in the second session, twice each. From 128 tokens
on, batched is 2.3–3.1× faster. The batched logits are within 1.5e-5 of the token-at-a-time path's, with the same
tokens. Below about 32 tokens
most of the GPU stays idle, so short prompts run a token at a time (`QWEN3MOE_PREFILL=0 / 1` forces either).

## On the Hexagon NPU

The laptop's NPU is the same V81 HTP as the phones' (`../npu`). `npu/` runs one real layer (layer 0, fp16) through ONNX
Runtime's QNN execution provider (Microsoft.ML.OnnxRuntime.QNN 1.24.4 for Windows on Arm, built with Zig):
- attention, as for π0's prefix;
- the router's top 8 as a dense weight per token (`TopK`);
- **all 128 experts** for every token, weighted. An HTP graph is static and cannot gather a token's experts, so it
  does 16× the useful arithmetic.

| One layer, fp16 | NPU (HTP) | GPU, int4, this program |
|---|---|---|
| A token (decode) | 10.7–14 ms: all 128 experts' 1.2 GB at about 100 GB/s → 0.5–0.7 s a token | 27–32 ms for all 48 layers |
| 128 prompt tokens | 213–218 ms → 10.3 s for 48 layers | 1.66–1.71 s for all 48 layers |
| 256 prompt tokens | 95–97 ms (3.4 TFLOP/s) → 4.6 s for 48 layers | 2.57–2.66 s for all 48 layers |

- **Accuracy:** against transformers' fp32 layer on the same input, the NPU's output is within 1.2e-3 for the median
  token (relative to the layer's change). A few tokens reach 3%: for 2 of the 128, fp16 router logits change the top 8.
- **Fixes it needed:** QNN's `RmsNorm` refuses the QK norms over heads of 128 (error 3110), and written-out fp16
  squares underflow, so they are an L2 normalization times √128. The 128-token graph compiles to a slower plan than
  the 256-token one.
- **The hardware is fast.** It streams fp16 weights at about 100 GB/s, against 55–60 GB/s for these GPU kernels, and
  runs 3.4 TFLOP/s of fp16 matrix work. But static graphs make it compute every expert. Reading only 8 would be
  about 0.8 ms a layer (40 ms a token in fp16), in reach of the GPU's int4.
- **The whole model does not fit as fp16:** 61 GB, beyond the laptop's 33.6 GB. On the HTP it would need its
  quantized path (w4a16) and contexts of a few layers each.

So, for this MoE, the GPU decodes and prefills. The NPU could take the dense attention, or a prefill with expert
gathering, once QNN's graphs can select weights by index.

New requests in the driver protocol make this possible on a remote GPU (`driver/protocol.h`, `driver/README.md`):
- `OP_FILE`: the executor reads part of a file on its side into a buffer.
- `OP_GATHER`: the embedding row of a token the GPU chose.
- `OP_RECORD` / `OP_REPLAY` (`vla/x2/vk_server_win.c`): the server keeps a decode step's requests and runs them again
  on its own clock. That gives the GPU's time without the tunnel (`QWEN3MOE_REPLAY`).

## Speed

A decode step, at position 83, timed two ways and by how many commands `vk_server` submits at once
(`VK_SUBMIT_EVERY`; the server's default is 1):

| Commands a submission | Streamed from the Mac (63 tokens, wall clock) | Replayed on the laptop (64 steps) |
|---|---|---|
| 1 | 46.9–49.4 ms/token | **27.2 ms/token (36.7 tokens/s)** |
| 8 | **28.2–32.1 ms/token (31–35 tokens/s)** | 31.4–31.5 ms/token |
| 64 | 35.2–38.1 ms/token | 29.6–31.8 ms/token |

- Replayed, single submissions let the GPU run each launch while the server records the next.
- Streamed, launches arrive at the tunnel's pace (about 64 KB a token), and submitting each one alone costs more.
  Eight commands a submission is the best end to end.
- The prompt, a token at a time, takes 38–46 ms a token.

Where a step's time goes (`VK_SERVER_PROFILE=2`: each launch waited for alone, 39.7 ms in all):

| Launches | Time a token | Share |
|---|---|---|
| Experts' gate/up + SiLU | 9.7 ms | 24% |
| q/k/v | 5.4 ms | 14% |
| Experts' down + residual | 5.0 ms | 13% |
| o + residual | 4.9 ms | 12% |
| The two RMSNorms | 7.3 ms | 18% |
| Router, top 8 | 3.9 ms | 10% |
| Head, argmax, attention, RoPE | 3.5 ms | 9% |

The matrix-vector kernels read 41–63 GB/s. A fifth of the step is 96 single-workgroup norms: a fusion away from free.
With zero-filled weights, a step replayed in 22.5 ms. Windows probably maps zero pages to shared memory, so only
real weights' times are reported here.

## The reference

`reference.py` runs on the laptop, whose Python (3.12 for ARM64) has PyTorch 2.9.1 and transformers 4.57.1. Neither
machine holds the bf16 model at once: it is 61 GB, against the laptop's 33.6 GB of RAM and the Mac's 17. So the
reference builds transformers' `Qwen3MoeDecoderLayer` one layer at a time on the meta device and loads that layer's
weights. With the GPU's weights (the default), it dequantizes them from `qwen3moe.bin`; with `--bf16`, it reads
the checkpoint's shards. It then runs the prompt plus the generated tokens through the layer in fp32, with a causal
mask. The logits at each position give the greedy check. A pass takes 140 s (int4) or 60 s (bf16).

## Run it

```bash
qwen3moe/build_mac.sh                # build/qwen3moe/x2: vk_server.exe and convert.exe (Zig), the plugin and qwen3moe
python3 qwen3moe/export.py           # build/qwen3moe: recipe.txt and manifest.txt, from the shards' headers only
X2="ssh -p 2222 -i <QDC key> HCKTest@localhost"
# on the laptop, in C:\Users\HCKTest\qwen3moe: hf\ holds the checkpoint (curl from Hugging Face, 16 shards),
# then: copy convert.exe, vk_server.exe, recipe.txt, manifest.txt, reference.py there, and
$X2 "cd qwen3moe & convert.exe hf recipe.txt qwen3moe.bin"                       # 4 minutes
$X2 -L 7791:127.0.0.1:7788 "cd qwen3moe & set VK_SUBMIT_EVERY=8& vk_server.exe 7788"   # leave running
build/vla/venv/bin/python qwen3moe/run.py --prompt "..." --tokens 64 --check [--bf16]
```

`--check` runs `reference.py` on the laptop (with Python, PyTorch and transformers installed in
`C:\Users\HCKTest\py`). `QWEN3MOE_REPLAY=64` adds the server-clock timing.

## Follow-ups

- **Prefill on the matrix units:** the batched products are fp32 FMAs on 8 tokens; cooperative-matrix tiles of 64
  rows would read a prompt several times faster.
- **Fusions:** the RMSNorms, router and top-8 are a quarter of a step as 192 small launches.
- **The NPU with routing:** expert weights gathered by index in a QNN graph (or a graph per expert group), so it
  reads 8 experts, not 128.
- **Better int4:** GPTQ or AWQ-style rounding, or a w4a16 path, on the same storage.
- **Stopping at `<|im_end|>`:** the GPU generates the asked-for count; the host cuts the text there.

## Files

| File | |
|---|---|
| `export.py` | `qwen3moe.bin`'s layout from the shards' headers: `recipe.txt` (for `convert.c`) and `manifest.txt` (for `model.mojo`) |
| `convert.c` | the 16 bf16 shards to `qwen3moe.bin` (int4 with searched scales, fp32 norms, router and embedding); macOS and Windows on Arm |
| `kernels/moek.mojo` | RMSNorm, QK norm + RoPE, attention, router, top 8, the experts' int4 kernels, argmax |
| `model.mojo` | the weights (`M_driver_remote_file`), the token step (`M_driver_remote_gather`, 531 launches) |
| `qwen3moe.mojo` | the program: prompt, greedy decode, logits for checking, server-clock replay |
| `reference.py` | transformers' Qwen3-MoE layers one at a time, on the int4 or bf16 weights (runs on the laptop) |
| `run.py` | tokenize (chat template), run, decode the text, check against `reference.py` |
| `build_mac.sh` | the server and converter for the laptop, the plugin and the program for the Mac |
| `npu/export_layer.py` | one layer as an fp16 ONNX graph for the HTP (prefill of T tokens, all experts), and the recipe for its weights |
| `npu/npu_run.cpp`, `npu/build_win.sh` | compile an ONNX graph to an HTP context on the laptop, then time it (ONNX Runtime + QNN, Windows on Arm) |
| `npu/layer_ref.py` | the layer's input, and transformers' layer against the NPU's output |
