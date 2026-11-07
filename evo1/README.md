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
| GPU baseline: bf16 weights, fp32 matrix units | Galaxy Z Fold (Adreno 840) | 7.6–9.3 s | 3.1e-6 |
| GPU, ViT, mlp1 and LLM on the fp16 matrix units (`EVO1_MMA16`) | Galaxy Z Fold (Adreno 840) | 7.6–8.7 s | 9.7e-3 |
| GPU+NPU: vision and LLM on the NPU, the head on the GPU | — | not yet measured | — |
| **All-NPU**: vision (once a view), LLM and head on the HTP | X Elite (Hexagon V73) | **1.74 s** (3 × 419 + 143 + 330 ms) | 1.1e-2 |
| *The released bf16 model, for scale* | | | 9.7e-3 |

**Where the rows were measured.**
- **GPU rows:** a Galaxy Z Fold (SM-F976U, Adreno 840) in Samsung's Remote Test Lab, as replays of whole chunks on the
  phone's clock (`EVO1_REPLAY`). The phone heats from run to run, so the ranges cover two sessions' runs.
- **Why the laptop's GPU isn't used:** the X Elite laptop's Adreno X1-85 driver crashes compiling one of the kernels
  (see [`../vla_adapter`](../vla_adapter)).
- **The GPU's time goes to the head.** The 32 Euler steps take 5.3–5.6 s, about 3,900 small launches at 1.4 ms
  each. Vision takes 1.9–2.3 s and the LLM 0.36 s. The fp16 matrix units speed up only the latter two, so they gain
  little. Making the head's launches cheaper (fewer, larger, or batched into submissions) is the open GPU
  optimization.

**Measurement:** the all-NPU time is `graph_tool chain`, 10 chunks in one process (1.73–1.75 s).

**The tensors' shape made the NPU 3.5× faster.** InternViT's 1,025 rows (CLS and 32 × 32 patches) first took 1.84 s
per view on the V73, about 0.33 TFLOP/s against 1.3 for VLA-Adapter's ViTs on the same HTP.
- **The cause.** QNN's per-op profile (`NPU_PROFILE=detailed`, [`../npu/graph.cpp`](../npu/graph.cpp)) put 45% of
  the cycles in the 24 GELUs, at 16.7 cycles per element against 2.5 for VLA-Adapter's 261-row ViTs. A GELU over
  1,025 rows would not even compile on its own, while 1,024 rows did.
- **Padding the rows.** The graph pads them to 1,056 (a multiple of 32), masks the padding as keys, and drops it at
  the end. That is exact: 822 ms per view.
- **Row blocks.** The row-wise work (norms, projections, GELU) runs on the rows as [4, 264, 1,024] rather than one
  [1,056, 1,024]; only attention sees all rows at once. That gives 419 ms per view. The LLM's 1,024 rows as
  [8, 128, 896] went from 248 to 143 ms.
- **The result.** The chunk takes 1.74 s instead of 6.10 s. The tokens drift a little more (1.2% against 0.3%), but
  the actions do not (1.1e-2 against 1.3e-2).

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
| `vision.onnx` | one view: InternViT (rows padded to 1,056, in 4 blocks), pixel shuffle, mlp1 → 256 tokens | 419 ms | tokens 1.2% (rel. L2) |
| `llm.onnx` | the prompt rows with the three views' tokens placed at their slots → 1,024 context rows (8 blocks) | 143 ms | 0.93% (chained) |
| `head.onnx` | the state token, 8 blocks' context K/V, 32 Euler steps → 50 × 24 | 330 ms | 1.7e-3 alone, from the reference's context |

The graphs use the shared fp16-safe norms ([`npu/htp_norms.py`](../npu/htp_norms.py); the HTP flushes fp16
subnormals) and centered keys. Two structural constraints:
- **One view per vision graph.** All three views in one graph compiled for 28 minutes, then failed QNN's
  finalization (error 1002). The one-view graph compiles in 4 minutes, and the chain runs it three times.
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

- **The GPU's head.** About 3,900 launches a chunk at 1.4 ms each on the Adreno 840. Fusing a block's launches,
  or batching them into fewer submissions (`VK_SUBMIT_EVERY`, only for these small launches), is the GPU-optimized
  step still to do.
- **GPU+NPU.** Run it (`EVO1_NPU_VISION` / `EVO1_NPU_LLM`) on a device with both a working GPU and the NPU.
- **The masked third view.** LIBERO gives two cameras, so the third view is all zeros, and its 256 tokens are the
  same for every input. Computing them once would drop one of the three vision runs, 0.42 s of the 1.74.
- **Task success.** It has not been checked in LIBERO's simulator.

## Files

- [`reference.py`](reference.py): the official model in fp32 and every stage's tensors; `--export` writes the weights.
- [`model.mojo`](model.mojo), [`evo1.mojo`](evo1.mojo), [`kernels/ek.mojo`](kernels/ek.mojo): the GPU forward pass, the
  checks and timing.
- [`build_mac.sh`](build_mac.sh): builds the program.
- [`export_npu.py`](export_npu.py): the NPU graphs and their inputs.
- [`npu_check.py`](npu_check.py): the NPU's outputs against the reference.
