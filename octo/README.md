# Octo-Small on a Snapdragon X2 Elite laptop: GPU, GPU+NPU and NPU

[Octo](https://arxiv.org/abs/2405.12213)'s small generalist policy ([`rail-berkeley/octo-small-1.5`](https://huggingface.co/rail-berkeley/octo-small-1.5)
at `dc9aa30`) has 27M parameters plus a frozen T5-base encoder for the instruction. It computes a 4 × 7 action chunk
from a window of two frames of a 256 × 256 primary camera and a 128 × 128 wrist camera. Here it runs on the X2 Elite
laptop's Adreno X2-90 GPU as Mojo `DeviceContext` code, and on its Hexagon NPU as static ONNX graphs. Every stage is
checked against Octo's own JAX model in fp32.

| Configuration | Chunk, laptop clock (min / median) | With T5 | Actions vs JAX fp32 |
|---|---|---|---|
| GPU baseline: fp32, one launch per operation | 62 / 65 ms | 78 / 86 ms | 2.6e-6 |
| GPU optimized: denoising in one launch, fused GELU and q/k/v (fp32) | 50 / 51 ms | 66 / 71 ms | 5.2e-6 |
| GPU optimized, + fp16 weights | 44 / 48 ms | 70 / 70 ms | 3.3e-3 |
| GPU optimized, + fp16 matrix units for the trunk | 44 / 45 ms | 58 / 60 ms | 3.5e-2 |
| **GPU+NPU**: stems and trunk on the NPU; T5 and the head on the GPU | 44 / 44 ms | 55 / 58 ms | 4.8e-2 |
| **All-NPU**: stems, trunk, head (and T5) on the HTP | 38 / 47 ms | 45 / 50 ms | 4.2e-2 |

The errors are on the normalized actions, whose largest value is 2.52. In Bridge units (arm deltas scaled by stds
of 0.01–0.08) the baseline is within 3.1e-7.
- **Measurement:** chunks exclude T5, which runs once per instruction.
  - *GPU rows and GPU+NPU:* replays on the laptop's clock, 5 replays of 4 chunks each (`OCTO_REPLAY`).
  - *All-NPU:* `graph_tool chain`, 20 chunks in one process.
  - Neither includes the SSH tunnel.

### On the X Elite laptop (X1E80100, Hexagon V73)

The next QDC session assigned a Snapdragon X Elite. Its NPU is the older V73, so these rows are not comparable with
the X2 Elite's above.

| Configuration | Chunk (min / median) | With T5 | Actions vs JAX fp32 |
|---|---|---|---|
| **All-NPU**, stems and trunk as one graph (`obs_trunk`) | 92.1 / 92.3 ms (91.1 + head 1.0) | 95.6 ms (T5 3.3) | 2.1e-2 |
| All-NPU, stems and trunk as separate graphs | 106.0 / 106.2 ms | 109.6 ms | 2.1e-2 |

- **Why the error halved.** The graphs' norms are now [`npu/htp_norms.py`](../npu/htp_norms.py)'s. The HTP
  flushes fp16 subnormals, and the earlier graphs divided T5's and the stems' activations by 256, folded into their
  weights. Their small values' squares, and small weights, became subnormal and vanished. The same graphs now
  give 0.021 where the X2 run gave 0.042.
- **NPU accuracy by stage:** T5's task tokens are within 1.6e-3, the stems' tokens within 2.9e-3, and the readout within
  4.4e-3.
- **The GPU rows can't be measured here yet.** The X1-85's driver crashes compiling one of the port's kernels.

**On Octo-Small, the NPU is no faster than the GPU.** The two reasons below are the opposite of TurboVLA's case
([`../turbovla`](../turbovla)):
- **The trunk is small and narrow.** It is 12 layers of 384 over 690 tokens, about 38 GFLOP. The HTP runs it in
  35–43 ms, about 1 TFLOP/s, against 2.4 for TurboVLA's ViT-B.
- **The GPU's launch overhead was already fixed.** In the baseline, the diffusion head was the GPU's slow part:
  20 steps of about 25 launches each. GPU-optimized runs all 20 steps in a single launch (`ok.diffusion_head`).

GPU+NPU and the GPU with fp16 matrix units tie at 44–45 ms. Of the fast options, fp16 weights on the GPU are the
accurate one (3.3e-3).

## The model

Each stage of [`model.mojo`](model.mojo) matches a tensor of [`reference.py`](reference.py), Octo's own JAX code
(octo-models/octo at `241fb35`, run unchanged on the Mac's CPU):

| Stage | What it computes | Checked against JAX |
|---|---|---|
| T5 (once per instruction) | T5-base's encoder over 16 tokens, the projection and the task position embedding | 1.2e-6 |
| Stems | Two SmallStem16s, both frames each: 4 × (3 × 3 stride-2 conv as im2col + projection, GroupNorm(32), ReLU), the 1 × 1 embedding to 512 | 2e-5 |
| Tokens | 690 rows: 16 task tokens, then per frame 256 primary + 64 wrist tokens (projected, plus position embeddings), the task tokens again and a readout token | 3.2e-6 |
| Trunk | 12 pre-LN blocks of 384 (6 heads of 64, tanh GELU) under Octo's block-causal mask | blocks within 6.5e-5 |
| Head | The last frame's readout through the diffusion head: 20 DDPM steps of a 3-block MLP-ResNet, with JAX's noise injected | first step 3.4e-5, actions 2.6e-6 |

Octo's mask lets a readout token see earlier readouts, but no observation token sees any readout. One level per row
cannot express that, so [`../vla/kernels/vattn.mojo`](../vla/kernels/vattn.mojo) gained an opt-in second level
(`LV2`): key j is visible to query i when both of j's levels are at most i's. The GPU's mask matches Octo's in all
476,100 entries.

## The Hexagon NPU

[`export_npu.py`](export_npu.py) writes Octo as static ONNX graphs from the exported weights. On the Mac's CPU in fp32
they match JAX within 7e-6. On the HTP they run in fp16:

| Graph | What | HTP time |
|---|---|---|
| `t5.onnx` | ids, key mask → 16 task tokens | 2.1–3.5 ms |
| `obs.onnx` | both cameras' pixels → 2 × 256 primary and 2 × 64 wrist tokens | 3.9–5.4 ms |
| `trunk.onnx` | tokens, additive mask → the last frame's readout | 35–43 ms |
| `head.onnx` | readout, noise → actions: the 20 steps unrolled | 0.5–1.3 ms |
| `obs_trunk.onnx` | obs and trunk in one graph (GPU+NPU) | 33–35 ms inside the server |

**Two parts overflow fp16 as written**, so the graphs use equivalent forms that are exact in fp32:
- **T5's hidden state reaches 29,673**, and RMSNorm squares it. The residual stream is kept divided by 256, with
  RMSNorm's eps divided by 256².
- **The stems' conv outputs reach 446** before GroupNorm, whose variance squares them; at first the stems gave NaN.
  - GroupNorm is computed on the conv output divided by 256 (folded into the conv weights, eps divided by 256²).
  - Each mean is taken in two stages of at most 192 values.

Where the all-NPU error comes from ([`npu_check.py`](npu_check.py)):

| Stage on the NPU | Error |
|---|---|
| T5's task tokens | 1.8e-3 (largest 0.56) |
| Primary / wrist tokens (stems) | 0.016 / 0.019 (largest 1.2 / 1.9) |
| Trunk on JAX's tokens | 2.4e-3 on the readout (largest 10.9) |
| Trunk on the NPU's tokens | 0.020 on the readout |
| Head (fp32) on that readout | 0.042 on the actions |
| All-NPU | 0.042 on the actions |

The stems' fp16 drives the error. The trunk and the head add little.

A graph with q/k/v as one projection and rows padded to 704 was twice as slow on the HTP (88 ms).

## Running NPU graphs inside the server

GPU+NPU runs `obs_trunk.onnx` inside `vk_server_npu.exe`. The graph reads the task tokens, the pixels and the mask
from GPU buffers and writes the readout into one (`OCTO_NPU_OBS_TRUNK`).

**Open graphs at server start (`VK_SERVER_NPUG`).** The server crashed when a client opened a graph after an earlier
client had run a different one: an access violation inside ONNX Runtime's `memcpy`. The cause was not found. A plain
process that opens a second graph after running a first does not crash, and copying inputs through server-owned
buffers did not help. With every graph opened at startup, clients alternated between TurboVLA's and Octo's graphs
without a crash.

## Run it

```bash
# reference and weights (Mac; the JAX stack in build/octo/venv, see reference.py)
build/octo/venv/bin/python octo/reference.py --export
# the GPU program; NPU graphs and inputs (build/octo/npu)
octo/build_mac.sh
build/turbovla/venv/bin/python octo/export_npu.py
```

Copy `octo_small.safetensors` and `build/octo/npu` to `C:\Users\HCKTest\octo` on the laptop. Compile the graphs
there with `graph_tool.exe compile <graph>.onnx <graph>_ctx.onnx`, as in [`../turbovla`](../turbovla). Then:

```bash
X2="ssh -p 2222 -i <QDC key> HCKTest@localhost"
$X2 -L 7790:127.0.0.1:7788 "cd /d C:\Users\HCKTest\pi0npu\runtimes\win-arm64\native & set VK_SERVER_SEGMENTS=1& set VK_SERVER_NPUG=C:\Users\HCKTest\octo\npu\obs_trunk_ctx.onnx& vk_server_npu.exe 7788"
# GPU: every stage checked, then timed (OCTO_OPT / OCTO_F16 / OCTO_MMA16 for the optimized variants)
OCTO_OPT=1 OCTO_REPLAY=4 VK_REMOTE_PORT=7790 MODULAR_DRIVER_PLUGINS=vulkan@$PWD/build/vla/x2/libM_driver_vulkan_remote.dylib \
  OCTO_REMOTE='C:\Users\HCKTest\octo\octo_small.safetensors' \
  build/octo/x2/octo build/octo/octo_small.safetensors build/octo/ref 3
# GPU+NPU: the same, with OCTO_NPU_OBS_TRUNK='C:\Users\HCKTest\octo\npu\obs_trunk_ctx.onnx'
```

All-NPU, on the laptop in `C:\Users\HCKTest\octo\npu`. `0_task.f32` is the task tokens from an earlier chain run
that started with `t5_ctx.onnx`:

```bat
%G%\graph_tool.exe chain 20 obs_ctx.onnx in\primary.f32 in\wrist.f32 + trunk_ctx.onnx out\0_task.f32 @0:0 @0:1 in\mask.f32 + head_ctx.onnx @1:0 in\noise.f32 in\z.f32 -o out
```

## Files

- [`reference.py`](reference.py), [`requirements-reference.txt`](requirements-reference.txt): Octo's own JAX model on
  the Mac's CPU. It writes every stage's tensors; `--export` writes the weights in the ports' layouts.
- [`model.mojo`](model.mojo), [`octo.mojo`](octo.mojo), [`kernels/ok.mojo`](kernels/ok.mojo): the GPU forward pass
  (im2col, GroupNorm, T5 attention, the one-launch diffusion head), the checks and the timing.
- [`build_mac.sh`](build_mac.sh): builds the program.
- [`export_npu.py`](export_npu.py): the NPU graphs and their inputs.
- [`npu_check.py`](npu_check.py): the NPU's error by stage.
