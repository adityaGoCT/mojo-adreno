# SmolVLA on the Adreno 840, in Mojo

LeRobot's **SmolVLA** ([`lerobot/smolvla_base`](https://huggingface.co/lerobot/smolvla_base), 450M parameters)
computes a robot's action chunk on a phone's GPU. It takes three camera images, a task and the robot's state, and
returns 50 × 32 actions after 10 flow-matching steps. The whole forward pass is Mojo code: `DeviceContext` launches
of the kernels in [`../vla/kernels`](../vla), on a Galaxy Z Fold (SM-F976U, Snapdragon 8 Elite Gen 5,
Adreno 840, stock driver) through the Vulkan driver plugin. Every stage is checked against lerobot's own PyTorch
model:

```
weights: 0.81 GB from the checkpoint; bf16 and fp32 weights as stored, fp32 matrix units ; loaded in 1.2 s
prefix: 241 rows, 207 valid; chunk 50 x 32 , 10 steps
check vision (SigLIP, 3 x 1024 x 768) : max abs error 0.000256 (largest reference value 19.8)
check connector (image tokens x sqrt(960)) : max abs error 0.0093 (largest reference value 2715.4)
check prefix embeddings (valid rows) : max abs error 0.0093 (largest reference value 2715.4)
check prefix K cache, worst of 16 layers (layer 2) : max abs error 3.8e-05 (largest reference value 14.5)
check prefix V cache, worst of 16 layers : max abs error 2.4e-05 (largest reference value 4.1)
check step 0 v_t : max abs error 3.3e-06 (largest reference value 3.99)
...
check step 9 v_t : max abs error 6.2e-06 (largest reference value 4.23)
check actions (50 x 32) : max abs error 1.37e-06 (largest reference value 1.25)
run 0 : vision 518.0 ms, connector+embed 7.2 ms, prefix 62.9 ms, 10 steps 191.3 ms ( 19.1 ms/step ); chunk 778.3 ms
run 1 : vision 521.8 ms, connector+embed 8.0 ms, prefix 61.9 ms, 10 steps 190.5 ms ( 19.1 ms/step ); chunk 776.2 ms
run 2 : vision 523.2 ms, connector+embed 8.2 ms, prefix 61.6 ms, 10 steps 188.6 ms ( 18.9 ms/step ); chunk 775.8 ms
```

**The action chunk matches PyTorch fp32 within 1.4e-6, and every stage within 1e-5 of its largest value.** The
stated tolerance is 1e-5 absolute on the actions. For scale, lerobot's own run of the same policy as it loads it
(the VLM in bf16) differs from fp32 by 5.4e-3.

## Latency on the Adreno 840

The Galaxy Z Fold, three runs after 90 s idle (GPU at 32 °C), pipelines cached. Each stage is synchronized, then
the whole chunk runs with one synchronize at the end. Back-to-back runs without a rest warm the phone and drift up
5–12%.

| Stage | Work | Time |
|---|---|---|
| Vision | SigLIP, 12 layers of 768, 3 images × 1024 patches (3072 rows) | 518–523 ms |
| Connector + embeddings | pixel shuffle, projection to 960 (× √960), 48 language rows, the state | 7–8 ms |
| Prefix | 16 SmolLM2 layers over 241 rows (256 padded), every layer's K/V cache; the 8 cross-attention layers' K/V | 62 ms |
| Denoising | 10 Euler steps of the action expert (16 layers of 720, 64 rows) | 189–191 ms (19 ms/step) |
| **Action chunk** | | **776–778 ms** |

Where the time goes, from a run synchronized after every launch (`SMOLVLA_PROFILE=1`, which adds 0.2–0.3 ms a
launch): SigLIP's attention is the largest piece, about 18 ms a layer. The projections run at 1.2–1.8 TFLOP/s
out of the 840's 2.5 fp32.

## Precision: what fp16 costs

The default keeps the checkpoint's bf16 weights in bf16 and widens them exactly as the matmuls stage them. Its
few fp32 tensors (the action and state projections, the expert's cross-attention K/V projections) stay fp32. The
matrix units then multiply and sum in fp32. `SMOLVLA_PREC` selects two fp16 variants:

| | `bf16` (default) | `fp16w` | `fp16` |
|---|---|---|---|
| weights | bf16 / fp32 as stored | all rounded to fp16 | all rounded to fp16 |
| matrix units | fp32 × fp32 → fp32 | fp32 × fp32 → fp32 | fp16 × fp16 → **fp16 sums** |
| vision (max 19.8) | 2.6e-4 | 3.7e-4 | **2.6** |
| connector (max 2715) | 9.3e-3 | 9.0e-3 | 96 |
| prefix K cache (max 16) | 3.8e-5 | 1.2e-3 | 0.43 |
| prefix V cache (max 5) | 2.4e-5 | 1.3e-3 | 0.17 |
| velocity v_t, last step (max 4.2) | 6.2e-6 | 9.2e-4 | 0.058 |
| **actions (max 1.25)** | **1.4e-6** | **3.7e-4** | **0.014** |
| action chunk | 776–778 ms | 773–775 ms | **657–658 ms** (vision 478, prefix 39, 13.4 ms/step) |

- **fp16 weights alone (`fp16w`)** cost nothing in time, since the matmuls stage and widen either way. Rounding
  the weights moves the actions by 3.7e-4.
- **fp16 on the matrix units (`fp16`)** is 15% faster per chunk. The expert's steps gain most (13.5 vs 19 ms):
  its fp16 tiles load straight from memory, without the shared-memory staging that bf16 needs. But the 840 sums
  fp16 tiles only in fp16 (there is no fp16 × fp16 → fp32), and every product and partial sum is rounded to fp16.
  Over SigLIP's k = 3072 and the connector's k = 12288 that is visible inside the network: 13% of the vision
  output's range, 3.5% of the connector's. The actions still come out within 0.014, 2.5× lerobot's own bf16
  deviation (5.4e-3). That is plausibly harmless for a policy, but it is not the reference model.
- The 840 cannot do better here: converting an fp16 accumulator to fp32 inside a kernel crashes the driver's
  shader compiler, so `vgemm.gemm16` stores fp16 and a second kernel adds bias and residual in fp32.

## Also on a Snapdragon X2 Elite laptop

The same program drives the Adreno X2-90 of a Snapdragon X2 Elite laptop (Windows on Arm) from the Mac, through the
remote driver plugin and a Vulkan server ported to Windows ([`../vla/x2`](../vla/x2)). It runs the same kernels,
and the checks match the phone's bit for bit. Timed on the laptop's clock, a chunk takes 531–550 ms there: vision
338–358 ms, prefix about 40 ms, 16–19 ms a step.

## How it is computed

`model.mojo` follows lerobot 0.6.1's `VLAFlowMatching.sample_actions` stage by stage:

1. **SigLIP** (`vision`): patches as a matmul (`vrow.patchify` + `vgemm.gemm`, bias), position embedding,
   12 pre-norm layers. Q/K/V is one fused projection, followed by attention per image (`vattn.attention`: flash
   style, online softmax, both products on cooperative matrices). The output projection adds its residual inside
   the matmul. fc1, then fc2 with GELU applied as X is staged, plus the residual. Then the post-layernorm. The
   three cameras run as one 3072-row batch.
2. **Connector and embeddings** (`embed`): SmolVLM's pixel shuffle (`vrow.pixel_shuffle`, 1024 × 768 → 64 ×
   12288 per image), the projection to 960 times √960, the 48 language tokens' embeddings times √960, and the
   state's projection: 241 prefix rows.
3. **Prefix** (`prefix`): SmolLM2's first 16 layers (RMSNorm, fused Q/K/V, RoPE into the cache with lerobot's
   `apply_rope` table, grouped-query attention, SwiGLU with `silu(gate) * up` applied as `down` stages X). Only
   the K/V caches are kept. Then, for the expert's 8 cross-attention layers, its `k_proj` / `v_proj` of the
   cached K/V, once per chunk.
4. **Denoising** (`step`, 10×): the action/time MLP (the time embedding is computed on the CPU as lerobot does,
   in float64), then the expert's 16 layers. Even layers self-attend to the prefix's cache plus the actions'
   own K/V, written into rows 256–319 of the same cache. Odd layers cross-attend to the projected prefix K/V.
   Then the final norm, `action_out_proj`, and the Euler update `x_t += -0.1 v_t`.

Attention masks are *levels*, compared per key and query. Images and language are 0, the state 1, action i is
2 + i (SmolVLA's actions are causal), and padding is +∞. That reproduces `make_att_2d_masks` for the prefix and
both kinds of expert layers with one kernel. Padded rows (the prefix's 15, the chunk's 14) are zero and stay
finite. Query rows with no visible key get zero output; PyTorch gives them a uniform average. They never feed a
valid row, so the checks skip them.

Weights come straight from the downloaded `model.safetensors`. `vla/safetensors.mojo` parses its header on the
phone, and `vla/host.mojo` uploads each tensor: matrices as stored (bf16 bits or fp32), and norms, biases and
position embeddings widened to fp32. The 840 binds at most 128 MB per buffer, and the largest tensor is the 95 MB
embedding.

## Run it

```bash
python3 android/build.py runtime vla                       # once: MAX's runtime; then build/android/smolvla/
build/vla/venv/bin/python smolvla/reference.py             # PyTorch reference -> build/vla/smolvla/ref (29 MB)
D=/data/local/tmp/vla/smolvla
adb push build/android/smolvla/. $D/bin/
adb push build/vla/smolvla/ref/. $D/ref/
adb shell "cd $D; curl -sSL -o model.safetensors https://huggingface.co/lerobot/smolvla_base/resolve/5e8d12a6e2975b0e5e5fce7c8caf47c371d257b6/model.safetensors"
adb shell "cd $D; VK_PIPELINE_CACHE=$D/pipelines.bin MODULAR_DRIVER_PLUGINS=vulkan@$D/bin/libM_driver_vulkan.so bin/smolvla model.safetensors ref 3 > run.log 2>&1"
adb shell cat $D/run.log
```

`SMOLVLA_PREC=fp16w|fp16` picks the precision, `SMOLVLA_PROFILE=1` adds a per-launch profile and
`SMOLVLA_OUT=<file>` writes the action chunk. The first run creates about 40 pipelines (a few minutes without the
cache file, seconds with it).

The reference needs lerobot 0.6.1, which pins transformers < 5.6, so it gets its own venv:
`uv venv build/vla/venv; uv pip install "lerobot[smolvla]==0.6.1"` (torch 2.11, transformers 5.5.4). It
loads the policy with `load_vlm_weights=False`, since `smolvla_base`'s checkpoint holds the VLM's weights too.
SmolVLM2's config and tokenizer come from `HuggingFaceTB/SmolVLM2-500M-Video-Instruct`, without its weights. The
example is three procedurally drawn 256 × 256 images (resized to 512 × 512 by the policy), the task "Pick up the
red cube and place it in the blue bowl.", a fixed normalized state, and noise from `torch.manual_seed(0)`. The
reference is lerobot's model in fp32 (the bf16 weights widened). `predict_action_chunk` and the stage-by-stage
replay agree exactly.
