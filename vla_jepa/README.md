# VLA-JEPA (LIBERO) on a Snapdragon laptop: GPU and NPU

[VLA-JEPA](https://github.com/ginwind/VLA-JEPA)'s LIBERO checkpoint
([`ginwind/VLA-JEPA`](https://huggingface.co/ginwind/VLA-JEPA), `LIBERO/checkpoints/VLA-JEPA-LIBERO.pt` at `db32b4a`)
pairs Qwen3-VL-2B with a GR00T-style flow-matching DiT. At inference it uses 2.3B of its 3.1B parameters (bf16): the
V-JEPA 2 encoder and predictor serve training only. It computes a 7 × 7 action chunk in 4 Euler steps from:
- two 256 × 256 views;
- an instruction;
- an 8-dim state.

Here it runs as Mojo `DeviceContext` code for an Adreno GPU, and as static ONNX graphs on the Hexagon NPU. Every
stage is checked against the official PyTorch model in fp32.

| Configuration | Device | Chunk | Actions vs fp32 (normalized, max abs) |
|---|---|---|---|
| GPU baseline: bf16 weights, fp32 matrix units | Galaxy Z Fold (Adreno 840) | 947–966 ms (phone clock) | 9.2e-7 |
| GPU optimized: ViT, mergers and LLM on the fp16 matrix units (`VJ_MMA16`) | Galaxy Z Fold | not yet | — |
| GPU+NPU: vision and LLM on the NPU, the DiT on the GPU | — | not yet measured | — |
| **All-NPU**: vision, LLM and DiT on the HTP | X Elite (Hexagon V73) | **0.786 s** (325 + 374 + 87 ms) | 1.7e-3 |
| *The released bf16 model, for scale* | | | 3.4e-3 |

**The GPU rows are from a phone.** The X Elite laptop's Adreno X1-85 driver crashes compiling one of our kernels
(see [`../vla_adapter`](../vla_adapter)), so the GPU port ([`model.mojo`](model.mojo)) ran on a Galaxy Z Fold
(SM-F976U, Adreno 840) in Samsung Remote Test Lab.
- **Baseline:** its first run matched the official model at every stage (actions within 9.2e-7, normalized).
  A chunk took 947–966 ms over two sessions of 5 replays on the phone's clock (`VJ_REPLAY=1`, after a 90 s
  cool-down, `REPLAY_SLEEP=90`).
- **`VJ_MMA16` is not yet measured.** Its first attempt kept both the bf16 matrices and their fp16 copies, plus the
  fused LLM matrices' parts: about 10 GB on an 11 GB phone. The phone dropped off adb while it loaded. The originals
  are now freed as they are copied (about 4.6 GB), built but not yet run.

**Measurement:** the all-NPU time is `graph_tool chain`, 10 chunks in one process (781–787 ms).

## The model

Each stage of [`model.mojo`](model.mojo) matches a tensor of [`reference.py`](reference.py). That script runs the
repo's own path (ginwind/VLA-JEPA at `ec90777`, the LIBERO client's request through the policy server's msgpack round
trip into `VLA_JEPA.predict_action`) on the Mac's CPU in fp32, with:
- the sdpa attention in place of FlashAttention-2;
- the training-only V-JEPA modules on the meta device;
- VLA-Adapter's LIBERO-Spatial sample observation;
- seeded noise.

| Stage | What it computes |
|---|---|
| ViT | Qwen3-VL's ViT on both views: 256 patches of 1,536 each, in the processor's 2 × 2 merge order. The patch projection plus the learned 48 × 48 position grid interpolated to 16 × 16, then 24 blocks of 1,024 with 2-D RoPE and tanh GELU |
| Mergers | DeepStack taps after blocks 5, 11 and 17, and the final merger: 2 × 2 patches → 2,048. That gives 64 tokens a view and three DeepStack sets |
| LLM | Qwen3 over the 234-row prompt (padded to 256): 28 layers of 2,048, 16 heads of 128 with 8 KV heads, q/k RMSNorm, interleaved 3-D RoPE with θ 5e6. The DeepStack sets are added at the image rows after layers 0–2. The head reads the 32 embodied-action rows of layer 27, before the final norm |
| DiT | 4 Euler steps of 16 blocks of 768 (12 heads): even blocks cross-attend to the 32 context rows, odd blocks self-attend, AdaLN from the timestep. Rows are [state, 32 future tokens, 7 action tokens], and the decoder's last 7 rows are the velocity |

The loader reads every weight on the laptop straight from the official 6.2 GB `.pt`, at offsets listed in
`build/vla_jepa/pt_offsets.txt`. The laptop downloads that file from Hugging Face itself, in four ranged parts joined
with `copy /b`. One connection got about 3 MB/s there, and several together about 11.

## The Hexagon NPU

[`export_npu.py`](export_npu.py) writes three graphs whose parameters point into the official `.pt` (ONNX external
data):

| Graph | What | HTP time (V73) | Error |
|---|---|---|---|
| `vision.onnx` | ViT (the two views as [2, 256, 1,024]), DeepStack mergers, merger → 128 tokens and 3 × 128 DeepStack rows | 325 ms | tokens 0.30%, DeepStack 0.19–0.27% (rel. L2) |
| `llm.onnx` | Qwen3 over rows 4–255 → the 32 embodied rows | 374 ms | 0.96% (chained after the NPU's vision) |
| `head.onnx` | the 4-step DiT → 7 × 7 actions | 85 ms | 9.1e-4 alone, from the reference's context |

**The vision graph's speed came from its tensors' shape.** It first took 848 ms. QNN's per-op profile
(`NPU_PROFILE=detailed` in `graph_tool`) put 54% of the cycles in the 24 tanh GELUs, at about 16 cycles an element.
Two changes, both the same function, brought it to 325 ms:
- **The GELU written out** (`0.5 x (1 + tanh(...))` instead of ONNX `Gelu` with `approximate="tanh"`): 714 ms.
- **The two views' rows as [2, 256, 1,024]** instead of one [512, 1,024]: 325 ms. The HTP runs row-wise work several
  times faster on such blocks (Evo-1 gained the same way).

The same blocking made the LLM 11% faster but doubled its error (embodied rows 2.6%, actions 4.7e-3), so the LLM
keeps one block.

fp16 measures, besides the shared fp16-safe norms (`rms16`, `ln16`; see [`../vla_adapter`](../vla_adapter)):
- **Rows 0–3 as constants.** Their residual reaches 37,897, beyond fp16. They are the same for every input (the chat
  template's first tokens), so their keys and values in every layer are computed once in fp32 and enter the graph
  as constants. The graph starts at row 4, whose residual stays within 2,003.
- **Centered keys.** The DiT's cross-attention logits reach 3,319, so its keys are centered per head, and so are the
  ViT's.
- **No empty slices.** The first image starts at row 4, so the graph omits the empty piece before it; QNN rejects
  empty slices.

## Running it

```bash
build/vla_jepa/venv/bin/python vla_jepa/reference.py --export   # the fp32 reference tensors, pt_offsets.txt
build/turbovla/venv/bin/python vla_jepa/export_npu.py           # the NPU graphs and their inputs
vla_jepa/build_mac.sh                                           # the GPU program (build/vla_jepa/x2)
```

On the laptop, from `C:\Users\HCKTest\vla_jepa` (the `.pt` and the graphs side by side, inputs in `npu\in`):

```
%G% compile vision.onnx npu\vision_ctx.onnx      (likewise llm.onnx, head.onnx)
%G% chain 10 npu\vision_ctx.onnx npu\in\pixels.f32 + npu\llm_ctx.onnx npu\in\embeds.f32 @0:0 @0:1 npu\in\cos.f32
    npu\in\sin.f32 npu\in\mask.f32 + npu\head_ctx.onnx @1:0 npu\in\state.f32 npu\in\noise.f32 -o npu\chain
```

Then `vla_jepa/npu_check.py <dir>` reports each graph's error.

## Follow-ups

- **GPU rows.** Run the GPU port (`VJ_MMA16`, GPU+NPU through `VJ_NPU_VISION` / `VJ_NPU_LLM`) once a laptop's
  GPU can compile its kernels.
- **Task success.** It has not been checked in LIBERO's simulator.

## Files

- [`reference.py`](reference.py): the official model in fp32 and every stage's tensors; `--export` writes the weights
  and their offsets in the `.pt`.
- [`model.mojo`](model.mojo), [`vla_jepa.mojo`](vla_jepa.mojo), [`kernels/jk.mojo`](kernels/jk.mojo): the GPU
  forward pass, the checks and timing.
- [`build_mac.sh`](build_mac.sh): builds the program.
- [`export_npu.py`](export_npu.py): the NPU graphs and their inputs.
- [`npu_check.py`](npu_check.py): the NPU's outputs against the reference.
