# π0 on the Adreno 840, in Mojo

Physical Intelligence's **π0** as LeRobot ports openpi's PyTorch model
([`lerobot/pi0_base`](https://huggingface.co/lerobot/pi0_base), 3.3B parameters without the unused output heads).
It computes a 50 × 32 action chunk from three camera images, a task and a 32-dim state, on a phone's GPU. The
forward pass is Mojo code: `DeviceContext` launches of the same kernels as [SmolVLA](../smolvla)
([`../vla/kernels`](../vla)), on a Galaxy Z Fold (SM-F976U, Adreno 840, stock driver). Every stage is checked
against lerobot's own PyTorch model:

```
weights: 10.85 GB read from the checkpoint; 289 tensors stored as bf16 (exactly), 6 kept in fp32; loaded in 8.0 s
prefix: 816 rows, 783 valid; chunk 50 x 32 , 10 steps
check vision (SigLIP So400m, 3 x 256 x 1152) : max abs error 0.00033 (largest reference value 35.6)
check image tokens (projector) : max abs error 0.00015 (largest reference value 21.0)
check prefix embeddings (valid rows) : max abs error 0.00015 (largest reference value 492.1)
check prefix K cache, worst of 18 layers (layer 16) : max abs error 0.00079 (largest reference value 17.8)
check prefix V cache, worst of 18 layers : max abs error 0.0018 (largest reference value 19.8)
check step 0 v_t : max abs error 7.6e-06 (largest reference value 4.04)
...
check step 9 v_t : max abs error 1.0e-05 (largest reference value 4.14)
check actions (50 x 32) : max abs error 7.2e-06 (largest reference value 1.15)
run 0 : vision 558.2 ms, projector+embed 3.3 ms, prefix 2752.0 ms, 10 steps 785.4 ms ( 78.5 ms/step ); chunk 4053.2 ms
run 1 : vision 554.1 ms, projector+embed 2.5 ms, prefix 2730.9 ms, 10 steps 768.0 ms ( 76.8 ms/step ); chunk 4058.1 ms
run 2 : vision 553.6 ms, projector+embed 2.3 ms, prefix 2748.7 ms, 10 steps 761.4 ms ( 76.1 ms/step ); chunk 4055.1 ms
```

**The action chunk matches PyTorch fp32 within 7.2e-6.** The stated tolerance is 1e-5 absolute on the actions.
Inside the network, every stage is within 1e-4 of its largest value. The prefix's K/V differ most (up to 1.8e-3
on values of 20): they come out of 18 Gemma layers whose MLP sums run over k = 16384.

## It fits

The checkpoint is 14.0 GB of fp32. But every matrix of SigLIP, Gemma and the expert, and the embedding, holds
values that bf16 represents exactly: their low 16 bits are zero. So the phone stores those in bf16, losslessly,
and widens them as the matmuls stage them (`host.AUTO`). Only the 6 action/state projection tensors are real
fp32 and stay so. Norms, biases and position embeddings are widened to fp32. The device holds 5.4 GB: Gemma 2B's
18 layers 4.0 GB, SigLIP So400m 0.8 GB, the expert 0.6 GB. The 257K × 2048 embedding (2.1 GB in fp32) stays in
the file: the 48 language rows are read on the CPU per call. On this 11 GB phone that left room; no matrix exceeds
the driver's 128 MB binding (Gemma's gate and up are kept separate: 64 MB each).

## Latency on the Adreno 840

The Galaxy Z Fold, three runs after 90 s idle (GPU at 28 °C), pipelines cached. Each stage is synchronized, then
the whole chunk runs with one synchronize.

| Stage | Work | Time |
|---|---|---|
| Vision | SigLIP So400m, 27 layers of 1152 (heads of 72), 3 images × 256 patches (768 rows) | 554–558 ms |
| Projector + embeddings | 1152 → 2048 for 768 image rows; 48 language rows × √2048 | 2–3 ms |
| Prefix | Gemma 2B, 18 layers over 816 rows (896 padded): 3.2 TFLOP | 2.73–2.75 s |
| Denoising | 10 Euler steps of the expert (Gemma 300M, 18 layers, 51 rows against the 816-row cache) | 761–785 ms (76–79 ms/step) |
| **Action chunk** | | **4.05–4.06 s** |

Loading takes 8 s: 10.8 GB read from the checkpoint, of which 5.4 GB go to the GPU.

From a run synchronized after every launch (`PI0_PROFILE=1`):
- **The prefix is the projections.** Gemma's gate/up (1.28 s) and down (1.19 s) run at 1.6 and 0.9 TFLOP/s.
  `down` has k = 16384 and only 112 workgroups of 128 × 128.
- **The prefix rows are padded to 896.** With the 832 rows that 64 suffices for, the projections take
  64 × 128 blocks, and the prefix took 6.5 s.
- **The expert's attention dominates a step** (2.8 ms a layer). Heads of 256 are computed as four 64-column
  chunks, each recomputing Q Kᵀ, since the 840's driver allows one fp32 accumulator a subgroup. With 51 query
  rows that is only 32 workgroups.
- **The prefix synchronizes after each layer.** The driver plugin submits 64 launches at a time
  (`VK_SUBMIT_EVERY`), and 64 of these outlast the GPU's watchdog: the device is lost.

## How it is computed

`model.mojo` follows lerobot 0.6.1's `PI0Pytorch.sample_actions`:

1. **SigLIP So400m** (`vision`): 14 × 14 patches (k = 588: the matmul stages zeros past k), position embedding,
   27 pre-norm layers like SmolVLA's. Its heads of 72 run as two attention launches, columns 0–63 and 64–79
   (the last 8 unused).
2. **Projector and language** (`embed`): `multi_modal_projector` (1152 → 2048, bias) gives the 768 image rows,
   unscaled. Gemma's embedding rows for the 48 token ids follow, times √2048 in fp32, as
   `GemmaTextScaledWordEmbedding` does.
3. **Prefix** (`prefix`): Gemma 2B's 18 layers, each:
   - RMSNorm `x · rsqrt(mean x² + 1e-6) · (1 + w)`;
   - fused Q/K/V (8 query heads and 1 K/V head, of 256);
   - RoPE from transformers' table into the cache;
   - attention over the 783 valid rows (bidirectional);
   - `o_proj` plus residual;
   - GeGLU: `gelu_tanh(gate) · up`, applied as `down` stages X, plus residual.

   The last layer stops after its K/V.
4. **Denoising** (`step`, 10×): the suffix is 50 action tokens (`action_in_proj` with the time embedding, then
   the MLP) and the state token (`state_proj`). It runs through the expert's 18 layers, attending to the prefix's
   cache plus its own K/V, which are written into rows 896–959. Then the final norm, `action_out_proj` on the
   action rows, and `x_t += -0.1 v_t`. The masks are levels: prefix 0, state 1, actions 2 (they see each other
   and the state; the state does not see them).

## Run it

```bash
python3 android/build.py runtime vla                     # build/android/pi0/
build/vla/venv/bin/python pi0/reference.py               # PyTorch reference -> build/vla/pi0/ref (47 MB), 35 s
D=/data/local/tmp/vla/pi0
adb push build/android/pi0/. $D/bin/
adb push build/vla/pi0/ref/. $D/ref/
adb shell "cd $D; curl -sSL -o model.safetensors https://huggingface.co/lerobot/pi0_base/resolve/6e245399ad403ccf02b8112b73cfdc2633068f38/model.safetensors"
adb shell "cd $D; VK_PIPELINE_CACHE=$D/pipelines.bin MODULAR_DRIVER_PLUGINS=vulkan@$D/bin/libM_driver_vulkan.so bin/pi0 model.safetensors ref 2 > run.log 2>&1"
adb shell cat $D/run.log
```

The phone downloads the 14 GB checkpoint itself (8 minutes in the lab). Its SHA-256 `8229fd9a…` matches the
Mac's copy and Hugging Face's.

**The reference** builds lerobot's `PI0Policy` on the meta device. It hands it the bf16-exact tensors in bf16 and
the rest in fp32, and widens every weight to fp32 inside `nn.Linear`, `nn.Embedding`, `nn.Conv2d` and
`nn.LayerNorm` (`widen_weights`). So the arithmetic is the fp32 checkpoint's, in 6.8 GB of the Mac's 17 instead
of 14. Two of lerobot's checks switch activations to bf16 when a weight is stored in bf16; `keep_fp32_activations`
turns exactly those two off. `predict_action_chunk` and the stage-by-stage replay agree exactly.

**The prompt is fixed token ids.** PaliGemma's tokenizer (`google/paligemma-3b-pt-224`) is gated, so the
instruction is BOS, 13 arbitrary ids and "\n" (108), padded to 48. The images are three procedurally drawn
224 × 224 scenes, the state a seeded normal vector, and the noise `torch.manual_seed(0)`.
