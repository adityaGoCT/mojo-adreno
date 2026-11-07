# VLA-Adapter (Pro) on Snapdragon laptops: GPU and NPU

[VLA-Adapter](https://arxiv.org/abs/2509.09372)'s Pro policy for LIBERO-Spatial
([`VLA-Adapter/LIBERO-Spatial-Pro`](https://huggingface.co/VLA-Adapter/LIBERO-Spatial-Pro) at `cb023c6`) has 1.47B
parameters in bf16. It computes an 8 × 7 action chunk in one pass from:
- two 224 × 224 images (agent view and wrist);
- an instruction;
- an 8-dim state.

Here it runs as Mojo `DeviceContext` code on an Adreno GPU, and as static ONNX graphs on the Hexagon NPU. Every stage
is checked against the official PyTorch model in fp32.

| Configuration | Device | Chunk, laptop clock | Actions vs fp32 (normalized, max abs) |
|---|---|---|---|
| GPU baseline: bf16 weights, fp32 matrix units | X2 Elite (Adreno X2-90) | 1.30 s | 2.3e-6 |
| GPU optimized: ViTs, projector and LLM on the fp16 matrix units (`VLA_MMA16`) | X2 Elite | 0.63 s | 1.8e-2 |
| GPU+NPU: vision and LLM on the NPU, policy on the GPU | — | not yet measured | — |
| **All-NPU**: vision, LLM and policy on the HTP | X1 Elite (Hexagon V73) | **0.855 s** (567 + 218 + 70 ms) | 2.5e-2 |
| *The released bf16 model, for scale* | | | 2.8e-2 |

The rows come from two different laptops:
- **GPU rows** were measured on the Snapdragon X2 Elite (X2E88100) reserved in Qualcomm Device Cloud on 2026-11-06.
- **All-NPU** was measured on the X Elite (X1E80100 CRD) the next QDC session assigned. On that laptop's
  Adreno X1-85, the driver's shader compiler (`qcgpuarm64xcompilercore.dll`) crashes on one of our kernels (a null
  read). That blocks the GPU rows and GPU+NPU there for now.

**Measurement:**
- *GPU rows:* replays of 2 chunks on the laptop's clock (`VLA_REPLAY`), 5 of them, without the SSH tunnel.
- *All-NPU:* `graph_tool chain`, 10 chunks in one process; the times varied by under 1%.

## The model

Each stage of [`model.mojo`](model.mojo) matches a tensor of [`reference.py`](reference.py). That script runs the
repo's own inference path (OpenHelix-Team/VLA-Adapter at `23fa0c9`, `get_vla_action` → `predict_action`) on the Mac's
CPU in fp32, with the repo's LIBERO-Spatial sample observation.

| Stage | What it computes | GPU baseline vs fp32 |
|---|---|---|
| Vision | Per image: DINOv2-L/14 with registers (blocks 0–22 of 24) and SigLIP-So400m/14 (0–25 of 27), side by side (2,176) | 1.9e-3 of 62.9; 6.6e-3 of 288 |
| Projector | 3 layers to 896: 512 vision tokens | 1.4e-4 |
| LLM | Qwen2.5-0.5B over S = L + 577 rows (here 633); each layer's task window (rows 0–511) and action-query window (64 rows) kept: 24 taps | worst tap 4.2e-3 of 1,463 |
| Policy | Proprio projector; 24 Pro blocks over 8 rows (one softmax over self, adapter and task keys, task logits gated by tanh, VLA-Adapter's interleaved RoPE); LN and the 7-dim head | actions 2.3e-6 |

The GPU loader reads weights on the laptop. The language model's weights come from `model.safetensors`, the policy's
straight from the official `action_head--checkpoint.pt` and `proprio_projector--checkpoint.pt`. Torch stores those
tensors uncompressed, so [`build/vla_adapter/pt_offsets.txt`](../build/vla_adapter) lists each one's byte offset.
The laptop downloads the checkpoint from Hugging Face itself; nothing large crosses the tunnel.

## The Hexagon NPU

[`export_npu.py`](export_npu.py) writes three graphs. Their parameters are the checkpoint's own bf16 bytes, as ONNX
external data pointing into the files on the laptop, so the graphs themselves are 0.7–8 MB. ONNX Runtime casts them to
fp16 when it loads the graph.

| Graph | What | HTP time (V73) | Error alone |
|---|---|---|---|
| `vision.onnx` | 2 × (DINOv2 + SigLIP), projector → 512 tokens | 557–562 ms | tokens rel. L2 4.3% |
| `llm.onnx` | Qwen2.5-0.5B (rows as [5, 128, 896]) → 24 taps of 576 rows | 218 ms | taps 0.14–0.89% (from the reference's vision tokens); the fp32 policy on them: actions 2.9e-3 |
| `policy.onnx` | proprio projector, 24 Pro blocks, head → 8 × 7 | 72 ms | |

**The HTP flushes fp16 subnormals to zero, and that decides how the norms are written.**
- **The flushing problem.** The first version kept the residual streams divided by 16 (ViTs) or 64 (LLM) so that
  the norms' squares could not overflow fp16. Most activations then sit near 1e-3, and their squares are below fp16's
  smallest normal (6.1e-5). The HTP drops them, the mean square comes out too small, and every norm's output comes out
  too large. Vision tokens were 59% off and the LLM's first layer 21%.
- **Why the CPU missed it.** fp16 on the Mac's CPU keeps subnormals, so it showed none of this; a one-layer probe graph
  on the HTP found it.
- **The fix.** `rms16` and `ln16` scale each row to a fixed maximum (4 or 2, by width) before squaring. The norms are
  scale-invariant, and eps is carried exactly as (k √eps / m)², so the residual streams stay unscaled (they fit fp16:
  1,463 at most).
- **Other fp16 measures:**
  - Keys are centered per head in the ViTs and the LLM (exact: each query's logits shift by a constant).
  - q carries the 1/8.
  - Scale factors multiply activations and are never folded into weights, where they would make subnormal weights.

**Two QNN quirks:**
- **`Reciprocal`.** QNN's translation of ONNX `Reciprocal` builds a wrongly sized fp16 constant ("Data length mismatch
  for static tensor"). A Python scalar divided by a tensor exports as one, so the helpers divide tensor by tensor.
- **Empty slices.** QNN rejects empty slices.

**A loader bug of ours.** `npu/graph.cpp` kept a shape view (`ConstTensorTypeAndShapeInfo`) of a temporary
`TypeInfo`, a use-after-free. On the X2 it crashed `vk_server_npu` only now and then; on the X1 it crashed every
open of a large context.

## Running it

```bash
build/vla_adapter/venv/bin/python vla_adapter/reference.py --export   # the fp32 reference tensors
build/turbovla/venv/bin/python vla_adapter/export_npu.py              # the NPU graphs and their inputs
vla_adapter/build_mac.sh                                              # the GPU program (build/vla_adapter/x2)
```

On the laptop, from `C:\Users\HCKTest\vla_adapter` (graphs next to the checkpoint files, inputs in `npu\in`), with `G`
set to the full path of `graph_tool.exe`:

```
%G% compile vision.onnx npu\vision_ctx.onnx      (likewise llm.onnx, policy.onnx)
%G% chain 10 npu\vision_ctx.onnx npu\in\pix_d.f32 npu\in\pix_s.f32 + npu\llm_ctx.onnx npu\in\prefix.f32 @0:0
    npu\in\mask.f32 npu\in\idx.i32 + npu\policy_ctx.onnx @1:0 npu\in\prop.f32 -o npu\chain
```

Then `vla_adapter/npu_check.py <dir>` on the Mac reports each graph's error.

## Follow-ups

- **The X1-85's shader compiler crash.** It blocks the GPU rows and GPU+NPU on the X Elite.
- **Vision accuracy on the HTP (4.3%).** It dominates the all-NPU error; the LLM and policy alone are within 1%.
- **The safe norms' cost.** About 170 ms of the vision graph's 557 ms are the extra per-row operations of `ln16`.
  Feeding the scaled rows to the HTP's own LayerNorm would remove most of them.
- **Task success.** The fp16 configurations' 2e-2 action errors have not been checked in LIBERO's simulator.

## Files

- [`reference.py`](reference.py): the official model in fp32 and every stage's tensors; `--export` writes the weights.
- [`model.mojo`](model.mojo), [`vla_adapter.mojo`](vla_adapter.mojo), [`kernels/vak.mojo`](kernels/vak.mojo): the GPU
  forward pass, the checks and timing (`VLA_MMA16`, `VLA_REPLAY`, GPU+NPU through `VLA_NPU_VISION` / `VLA_NPU_LLM`).
- [`build_mac.sh`](build_mac.sh): builds the program.
- [`export_npu.py`](export_npu.py): the NPU graphs, their inputs, and the fp16-safe norms (`rms16`, `ln16`) that
  Evo-1's and VLA-JEPA's exports share.
- [`npu_check.py`](npu_check.py): the NPU's outputs against the reference, graph by graph or chained.
