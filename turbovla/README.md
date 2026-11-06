# TurboVLA on a Snapdragon X2 Elite laptop: GPU, GPU+NPU and NPU

[TurboVLA](https://arxiv.org/abs/2607.27205)'s LIBERO policy ([`H-EmbodVis/TurboVLA`](https://huggingface.co/H-EmbodVis/TurboVLA)
at `9cdb576`, 216M parameters, fp32) computes a 12 × 7 action chunk in one forward pass. Its inputs are two
256 × 256 camera views, an instruction and an 8-dim state. Here it runs on the X2 Elite laptop's Adreno X2-90 GPU
as Mojo `DeviceContext` code, and on its Hexagon NPU as static ONNX graphs. Every configuration is checked against
the official PyTorch model in fp32.

| Configuration | Chunk, laptop clock (min / median) | With BERT | Actions vs PyTorch fp32 |
|---|---|---|---|
| GPU baseline: fp32 weights, fp32 matrix units | 111 / 136 ms | 147 / 148 ms | 1.2e-6 |
| GPU optimized: fused q/k/v, folded LayerScale, fused GELU (fp32) | 102 / 107 ms | 109 / 117 ms | 2.1e-6 |
| GPU optimized, + fp16 weights | 96 / 97 ms | 102 / 108 ms | 3.0e-4 |
| GPU optimized, + fp16 matrix units for DINOv3 | 59 / 66 ms | 74 / 78 ms | 1.1e-2 |
| **GPU+NPU**: DINOv3 on the NPU, the rest on the GPU (fp16 weights) | 63 / 65 ms | 74 / 78 ms | 1.9e-2 |
| **All-NPU**: three graphs on the HTP (fp16) | **37 / 39 ms** | 43 / 46 ms | 2.2e-2 |

Actions are tanh outputs, so their largest value is 1. A chunk excludes BERT, which runs once per instruction.

- The GPU rows and GPU+NPU are replays on the laptop's clock: 5 replays of 4 chunks, each the average of its 4. The laptop's
  Vulkan server keeps one chunk's requests and runs them again itself (`TURBOVLA_REPLAY`, `OP_RECORD` / `OP_REPLAY`).
- All-NPU is `graph_tool chain`: 20 chunks in one process on the laptop, each timed end to end.
- Neither measurement includes the SSH tunnel from the Mac.

**At the median, the NPU runs the whole chunk 1.7× faster than the fastest GPU-only configuration, and 2.5× faster
than the accurate fp16-weight one.** Two things explain it:

- **DINOv3 is faster on the NPU.** It is the ViT-B/16 vision encoder, about 90% of a chunk's FLOPs, and takes 37 ms
  on the HTP.
- **The rest of the chunk is cheap on the NPU.** On the GPU it is 236 small launches, about 20 ms (the GPU+NPU row
  minus its NPU time). The HTP runs the same fusion, decoder and MLP as one graph in 1.7 ms.

So putting only the compute-bound part on the NPU (GPU+NPU) gains little over the GPU with fp16 matrix units. The
gain comes from moving everything.

## The model

Each stage of [`model.mojo`](model.mojo) matches a tensor of [`reference.py`](reference.py) (the official model):

- **Vision:** DINOv3 ViT-B/16 on both views: 12 layers of 768, 2-D RoPE on the patches, LayerScale, 4 registers.
  Then the projection to 256 and the view embedding give 512 vision tokens.
- **Text:** BERT-base over the instruction's 21 tokens with TurboVLA's sub-sentence mask, then the projection to 256.
- **Fusion:** 6 bidirectional vision ↔ text attention layers, each followed by a text self-attention layer.
- **Action:** two state tokens, then the ACT decoder (3 layers of 256, 12 queries), an MLP and tanh.

The example input is fixed:
- two procedurally drawn views, normalized as the policy does;
- the LIBERO instruction "put the bowl on the plate";
- a seeded state.

DINOv3's config comes from a gated repo, so `reference.py` rebuilds it; the checkpoint's tensors fix every shape.

## GPU: baseline and optimized

[`model.mojo`](model.mojo) uses the kernels of [`../vla/kernels`](../vla) and its own [`kernels/tk.mojo`](kernels/tk.mojo)
(exact GELU, RoPE on patch tokens, residual forms, small masked attention). The weights are read on the laptop from
its own copy of the checkpoint (`M_driver_remote_file`). Runtime switches select the variants, so one binary times
all of them:

| Switch | What it changes |
|---|---|
| `TURBOVLA_OPT=1` | q/k/v as one projection; DINOv3's LayerScale folded into the o and down projections; the exact GELU applied as the down projection stages its input |
| `TURBOVLA_F16=1` | every projection's weight rounded to fp16 (fp32 matrix units, fp32 sums) |
| `TURBOVLA_MMA16=1` | DINOv3's projections on the fp16 matrix units (fp16 sums) |

Accuracy by stage, largest error against PyTorch:

| Stage (largest value) | fp32 | fp16 weights | fp16 matrix units |
|---|---|---|---|
| DINOv3 (5.08) | 1.5e-5 | 1.8e-3 | 8.8e-2 |
| vision tokens (3.81) | 1.6e-5 | 2.4e-3 | 7.6e-2 |
| BERT (9.08) | 7.0e-5 | 1.1e-2 | 1.1e-2 |
| memory, after fusion (4.37) | 2.1e-5 | 2.6e-3 | 7.3e-2 |
| actions (1.0) | 1.2e-6 | 3.0e-4 | 1.1e-2 |

## The Hexagon NPU

[`export_npu.py`](export_npu.py) writes TurboVLA as three static ONNX graphs. ONNX Runtime's QNN execution provider
(1.24.4 on Windows) runs them on the HTP in fp16 (`enable_htp_fp16_precision`), every node on the HTP:

| Graph | What | HTP time | Compile once |
|---|---|---|---|
| `vision.onnx` | pixels [2, 3, 256, 256] → 512 vision tokens: DINOv3, projection, view embedding | 35–41 ms | 25 s |
| `text.onnx` | ids, positions, additive mask, keep → 21 text tokens: BERT and projection | 2.3 ms | 4 s |
| `head.onnx` | vision and text tokens, masks, state → actions: fusion, state tokens, decoder, MLP, tanh | 1.7 ms | 2 s |

The graphs are written out by hand, with no shape logic and additive masks. The HF DINOv3's traced `If` nodes and
PyTorch's fused multi-head attention do not export. On the Mac's CPU in fp32 they match PyTorch: vision 1.4e-5,
text 4.9e-4, actions 1.9e-6.

**DINOv3 overflows fp16 as written.** Its register tokens carry activations up to 17,000, and layer 0's attention
scores reach 86,689. The vision graph therefore uses an equivalent form that is exact in fp32:
- The residual stream is kept divided by 256, with the LayerNorm's eps divided by 256².
- The queries are scaled before the product.
- The keys are centered per head, which leaves the softmax unchanged.

Before this rewrite, the NPU's vision tokens were off by up to 1.1. Now they are within 0.095 (relative L2 1.9%).

**BERT on the HTP drifts in rows that attend only to themselves**: [CLS] and the padding rows the instruction keeps.
Those rows reach 0.28 at the last layer, and 1.6 after the projection (text tokens up to 12.7). In fp16 on the Mac's
GPU the same rows are the least accurate too (0.046), so they are fp16-sensitive and the HTP's arithmetic is
coarser. The other rows stay within 0.06. Per-layer outputs from
the HTP show it begins at layer 5. LayerNorm inputs up to 856 are not the cause: the row that carries them is the
most accurate.

Where the all-NPU error comes from ([`npu_check.py`](npu_check.py) runs the head graph in fp32 on the NPU's tokens):

| Head (fp32) on | Actions within |
|---|---|
| PyTorch's vision and text tokens | 6.3e-7 |
| the NPU's vision tokens | 1.9e-2 |
| the NPU's text tokens | 1.8e-3 |
| both | 2.0e-2 |
| all-NPU (head on the HTP too) | 2.2e-2 |

The vision graph's fp16 accounts for nearly all of the error. BERT's drift barely reaches the actions.

## GPU+NPU

`TURBOVLA_NPU_VISION=<compiled vision graph on the laptop>` runs DINOv3 on the NPU inside the laptop's Vulkan
server, `vk_server_npu.exe`. The server reads the pixels from the GPU's buffer and writes the vision tokens into it,
so nothing crosses the tunnel. The fusion and action stages then run on the GPU. Generic requests carry this
(`OP_NPUG_OPEN` / `OP_NPUG_RUN` / `OP_NPUG_TIME` in [`../driver/protocol.h`](../driver/protocol.h)), so any static
graph compiled by [`../npu/graph.cpp`](../npu/graph.cpp) can run between a program's launches. Inside the server the
vision graph took 37–47 ms over three sessions, against 35–41 ms alone in `graph_tool`.

## Run it

```bash
# reference and weights (Mac; transformers 4.56 in build/turbovla/venv)
build/turbovla/venv/bin/python turbovla/reference.py --export
# the GPU program, the laptop's servers and the graph tool
turbovla/build_mac.sh
vla/x2/build_mac.sh
npu/build_win.sh
# NPU graphs and their inputs (build/turbovla/npu)
build/turbovla/venv/bin/python turbovla/export_npu.py
```

The laptop needs ONNX Runtime QNN's DLLs: `curl` the `Microsoft.ML.OnnxRuntime.QNN/1.24.4` NuGet package, then run
`tar -xf ortqnn.zip runtimes/win-arm64/native`. Copy `vk_server.exe`, `vk_server_npu.exe` and `graph_tool.exe` into
that folder. Copy `turbovla.safetensors` and `build/turbovla/npu` to `C:\Users\HCKTest\turbovla`. Then:

```bash
X2="ssh -p 2222 -i <QDC key> HCKTest@localhost"
# the server, from the DLLs' folder, with the port forward (leave running)
$X2 -L 7790:127.0.0.1:7788 "cd /d C:\Users\HCKTest\pi0npu\runtimes\win-arm64\native & set VK_SERVER_SEGMENTS=1& vk_server_npu.exe 7788"
# GPU: every stage checked, then timed (TURBOVLA_OPT / _F16 / _MMA16 for the optimized variants)
TURBOVLA_REPLAY=4 VK_REMOTE_PORT=7790 MODULAR_DRIVER_PLUGINS=vulkan@$PWD/build/vla/x2/libM_driver_vulkan_remote.dylib \
  TURBOVLA_REMOTE='C:\Users\HCKTest\turbovla\turbovla.safetensors' \
  build/turbovla/x2/turbovla build/turbovla/turbovla.safetensors build/turbovla/ref 4
# GPU+NPU: the same, with TURBOVLA_NPU_VISION='C:\Users\HCKTest\turbovla\npu\vision_ctx.onnx'
```

On the laptop, in `C:\Users\HCKTest\turbovla\npu` (`G` is the DLLs' folder):

```bat
%G%\graph_tool.exe compile vision.onnx vision_ctx.onnx
%G%\graph_tool.exe run vision_ctx.onnx 10 in\pixels.f32 -o out
%G%\graph_tool.exe chain 20 vision_ctx.onnx in\pixels.f32 + head_ctx.onnx @0:0 out\text.f32 in\key_mask.f32 in\mask.f32 in\state.f32
```

Compile `text.onnx` and `head.onnx` the same way. Back on the Mac, pass the NPU's outputs to
`turbovla/npu_check.py` to see the error by graph.

## Follow-ups

- **GPU launches.** The GPU's fusion and action stages are 236 launches for little arithmetic. Fusing them would
  help both GPU-only and GPU+NPU.
- **Pipelining GPU+NPU.** Running the NPU's vision for the next frame while the GPU finishes this one would bring
  GPU+NPU throughput to about one chunk per 40 ms. Latency would stay the same.
- **Task success.** The fp16 configurations' 1e-2 action errors have not been checked against task success in
  LIBERO's simulator.

## Files

- [`reference.py`](reference.py): the official model in fp32, every stage's tensors; `--export` writes the weights.
- [`model.mojo`](model.mojo), [`turbovla.mojo`](turbovla.mojo), [`kernels/tk.mojo`](kernels/tk.mojo): the GPU
  forward pass, the checks and timing.
- [`build_mac.sh`](build_mac.sh): builds the program.
- [`profile_chunk.py`](profile_chunk.py): a chunk's operations, each waited for alone, summed by stage.
- [`export_npu.py`](export_npu.py): the three NPU graphs and their inputs.
- [`npu_check.py`](npu_check.py): the all-NPU error by graph.
- [`../npu/graph.cpp`](../npu/graph.cpp): any static graph on the HTP, and `graph_tool`.
