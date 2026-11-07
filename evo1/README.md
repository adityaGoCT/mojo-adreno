# Evo-1 (LIBERO) on a Snapdragon laptop: GPU and NPU

[Evo-1](https://github.com/MINT-SJTU/Evo-1)'s LIBERO checkpoint
([`MINT-SJTU/Evo1_LIBERO`](https://huggingface.co/MINT-SJTU/Evo1_LIBERO) at `3ddc6c9`, 0.77B parameters, bf16)
computes a 50 × 24 action chunk (7 dims used) from three 448 × 448 views (agent, wrist, and a masked third), an
instruction and a state. Its parts:
- InternVL3-1B's vision encoder;
- the first 14 layers of its Qwen2.5-0.5B;
- a flow-matching head that takes 32 Euler steps.

Here it runs as Mojo `DeviceContext` code for an Adreno GPU, and as static ONNX graphs on the Hexagon NPU. Every
stage is checked against the official PyTorch model in fp32.

| Configuration | Device | Chunk | Actions vs fp32 (normalized, max abs) |
|---|---|---|---|
| GPU baseline: bf16 weights, fp32 matrix units | — | not yet measured | — |
| GPU optimized: ViT, mlp1 and LLM on the fp16 matrix units (`EVO1_MMA16`) | — | not yet measured | — |
| GPU+NPU: vision and LLM on the NPU, the head on the GPU | — | not yet measured | — |
| **All-NPU**: vision (once a view), LLM and head on the HTP | X Elite (Hexagon V73) | **6.10 s** (3 × 1,843 + 239 + 334 ms) | 1.3e-2 |
| *The released bf16 model, for scale* | | | 9.7e-3 |

**Why the GPU rows are empty.** The GPU port ([`model.mojo`](model.mojo)) is written and builds, but it has not
run: the X Elite (X1E80100) QDC assigned has an Adreno X1-85, whose driver's shader compiler crashes on one of the
kernels (see [`../vla_adapter`](../vla_adapter)).

**Measurement:** the all-NPU time is `graph_tool chain`, 10 chunks in one process (6.09–6.12 s).

**The vision encoder dominates.** InternViT-300M takes 1.84 s per view on the V73, about 0.33 TFLOP/s, against
1.3 TFLOP/s for VLA-Adapter's two ViTs on the same HTP; finding out why is the first follow-up.

## The model

Each stage of [`model.mojo`](model.mojo) matches a tensor of [`reference.py`](reference.py). That script runs the
official code (MINT-SJTU/Evo-1, branch main at `2020853`: `EVO1.run_inference` → `InternVL3Embedder` and
`FlowmatchingActionHead.get_action`) on the Mac's CPU in fp32, with VLA-Adapter's LIBERO-Spatial sample observation.

| Stage | What it computes |
|---|---|
| Vision | InternViT-300M on each view: 1,025 rows (CLS and 1,024 patches) through 24 layers of 1,024 with LayerScale. InternVL's pixel shuffle then makes 32 × 32 patches into 16 × 16 tokens of 4,096, and mlp1 (LN, 4,096 → 896, GELU, 896 → 896) gives 256 tokens a view |
| LLM | Qwen2.5-0.5B's first 14 layers over the fixed 1,024-row prompt with the image slots filled, with FlashAttention-2's semantics: a masked row's attention output is zero, and valid rows see valid keys causally. The final RMSNorm gives the head's context |
| Head | The state token as context row 1,024, then 32 Euler steps. Each step runs the action encoder (50 tokens), 8 cross-attention blocks (8 heads of 112) with the time embedding before the feed-forward, norm_out, the 44,800 → 896 pooling and the MLP to 1,200: x += v / 32 |

FlashAttention-2's masking matters: plain attention on the CPU moves the actions by up to 1.66. The GPU port
expresses it as attention levels, so a masked query sees no key and outputs zero. The NPU graph multiplies masked
rows' attention output by 0.

The loader reads every weight on the laptop straight from the official DeepSpeed `mp_rank_00_model_states.pt`, at
offsets listed in `build/evo1/pt_offsets.txt`. Torch stores the tensors uncompressed, and the laptop downloads the
checkpoint itself.

## The Hexagon NPU

[`export_npu.py`](export_npu.py) writes three graphs whose parameters point into the official `.pt` (ONNX external
data):

| Graph | What | HTP time (V73) | Error |
|---|---|---|---|
| `vision.onnx` | one view: InternViT, pixel shuffle, mlp1 → 256 tokens | 1,843 ms | tokens 0.32% (rel. L2) |
| `llm.onnx` | the prompt rows with the three views' tokens placed at their slots → 1,024 context rows | 239 ms | 0.60% (chained) |
| `head.onnx` | the state token, 8 blocks' context K/V, 32 Euler steps → 50 × 24 | 334 ms | 1.7e-3 alone, from the reference's context |

The graphs use the shared fp16-safe norms ([`npu/htp_norms.py`](../npu/htp_norms.py); the HTP flushes fp16
subnormals) and centered keys. Two structural constraints:
- **One view per vision graph.** All three views in one graph compiled for 28 minutes, then failed QNN's
  finalization (error 1002). The one-view graph compiles in 6.6 minutes, and the chain runs it three times.
- **Images placed inside the LLM graph.** It takes the three views' tokens as three inputs and places them at their
  slots itself. That makes the all-NPU chain possible, and the GPU+NPU path passes three slices of its token buffer.

## Running it

```bash
build/evo1/venv/bin/python evo1/reference.py --export   # the fp32 reference tensors
build/turbovla/venv/bin/python evo1/export_npu.py       # the NPU graphs and their inputs
evo1/build_mac.sh                                       # the GPU program (build/evo1/x2)
```

On the laptop, from `C:\Users\HCKTest\evo1` (the `.pt` and the graphs side by side, inputs in `npu\in`):

```
%G% compile vision.onnx npu\vision_ctx.onnx      (likewise llm.onnx, head.onnx)
%G% chain 10 npu\vision_ctx.onnx npu\in\pixels0.f32 + npu\vision_ctx.onnx npu\in\pixels1.f32 + npu\vision_ctx.onnx
    npu\in\pixels2.f32 + npu\llm_ctx.onnx npu\in\embeds.f32 @0:0 @1:0 @2:0 npu\in\mask.f32 npu\in\rowmask.f32 +
    npu\head_ctx.onnx @3:0 npu\in\state.f32 npu\in\noise.f32 npu\in\amask.f32 -o npu\chain
```

Then `evo1/npu_check.py <dir>` reports each graph's error.

## Follow-ups

- **The vision graph's speed on the HTP.** At about 0.33 TFLOP/s it is four times slower than VLA-Adapter's ViTs.
  QNN's per-op profile should show where; the 1,025-row attention is the first suspect.
- **GPU rows.** Run the GPU port (`EVO1_MMA16`, and GPU+NPU through `EVO1_NPU_VISION` / `EVO1_NPU_LLM`) once a
  laptop's GPU compiles its kernels.
- **The masked third view.** LIBERO gives two cameras, so the third view is all zeros, and its 256 tokens are the
  same for every input. Computing them once would drop one of the three vision runs, 1.84 s of the 6.10.
- **Task success.** It has not been checked in LIBERO's simulator.

## Files

- [`reference.py`](reference.py): the official model in fp32 and every stage's tensors; `--export` writes the weights.
- [`model.mojo`](model.mojo), [`evo1.mojo`](evo1.mojo), [`kernels/ek.mojo`](kernels/ek.mojo): the GPU forward pass, the
  checks and timing.
- [`build_mac.sh`](build_mac.sh): builds the program.
- [`export_npu.py`](export_npu.py): the NPU graphs and their inputs.
- [`npu_check.py`](npu_check.py): the NPU's outputs against the reference.
