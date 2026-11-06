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
check vision (SigLIP So400m, 3 x 256 x 1152) : max abs error 0.00049 (largest reference value 35.6)
check image tokens (projector) : max abs error 0.00012 (largest reference value 21.0)
check prefix embeddings (valid rows) : max abs error 0.00012 (largest reference value 492.1)
check prefix K cache, worst of 18 layers (layer 16) : max abs error 0.00078 (largest reference value 17.8)
check prefix V cache, worst of 18 layers : max abs error 0.0018 (largest reference value 19.8)
check step 0 v_t : max abs error 1.1e-05 (largest reference value 4.04)
...
check step 9 v_t : max abs error 1.5e-05 (largest reference value 4.14)
check actions (50 x 32) : max abs error 1.1e-05 (largest reference value 1.15)
run 0 : vision 529.9 ms, projector+embed 2.6 ms, prefix 2560.7 ms, 10 steps 778.8 ms ( 77.9 ms/step ); chunk 3603.7 ms
```

With Gemma 2B's prefix on the phone's Hexagon NPU instead, a chunk takes **2.05–2.16 s instead of 3.6 s**, with the
actions within 3.2e-3 of PyTorch's ([below](#the-prefix-on-the-hexagon-npu)).

**The action chunk matches PyTorch fp32 within 1.1e-5.** The stated tolerance is 2e-5 absolute on the actions.
Before the split kernels below it was 7.2e-6: splitting sums over k and over keys reorders fp32 additions.
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

The Galaxy Z Fold, pipelines cached. Each run is its own process after 100 s idle. Each stage is synchronized,
then the whole chunk runs with one synchronize. "Before" is the same program with the three changes below
turned off (`PI0_KSPLIT=0 PI0_SPLIT_BELOW=0 PI0_ACT_FIRST=0`), timed right before it (GPU at 31 and 36 °C).

| Stage | Work | Before | Now |
|---|---|---|---|
| Vision | SigLIP So400m, 27 layers of 1152 (heads of 72), 3 images × 256 patches (768 rows) | 571 ms | **530 ms** |
| Projector + embeddings | 1152 → 2048 for 768 image rows; 48 language rows × √2048 | 3 ms | 3 ms |
| Prefix | Gemma 2B, 18 layers over 816 rows (896 padded): 3.2 TFLOP | 2.75 s | **2.56 s** |
| Denoising | 10 Euler steps of the expert (Gemma 300M, 18 layers, 51 rows against the 816-row cache) | 800 ms (80.0 ms/step) | **779 ms** (77.9 ms/step) |
| **Action chunk** | | **4.07 s** | **3.60 s** |

This is one pair of runs: after it, the phone went to other work and heated. The new stages add up to 3.87 s
(4.13 s before); the chunk timed with one synchronize came out at 3.60 s (4.07 s before).
Earlier runs of the "before" kernels, three runs after 90 s idle, gave a 4.05–4.06 s chunk (prefix 2.73–2.75 s).
Back-to-back runs without a rest warm the phone and drift up 10% or more.

Loading takes 8 s: 10.8 GB read from the checkpoint, of which 5.4 GB go to the GPU.

What the three changes do:
- **Gemma's `down` projection activates its input once** (`host.Scratch.act_first`). Its k is 16384, and it
  read both halves of the GeGLU input (gate and up, 117 MB) for each of its 16 column blocks, recomputing
  `gelu(gate) · up` each time: 1.9 GB a layer. Now `vgemm.act_rows` writes the activation once (59 MB), and the
  matmul stages it plainly. The prefix: 2.75 → 2.56 s.
- **Split-k for projections of very few blocks** (`vgemm.gemm[SPLIT]` + `reduce_sk`). SigLIP's fc2 (k = 4304)
  has only 54 blocks of 128 × 128; in 4 k ranges it fills the GPU. Vision: 571 → 530 ms. Gemma's projections
  (112 blocks and more) got slower when split (prefix +130 ms), so they stay whole (`SPLIT_BELOW = 64`).
- **The expert's attention splits its keys** (`vattn.attention[SPLIT]` + `attention_combine`). Its 51 query rows
  against 960 keys gave only 32 workgroups (8 heads × 4 column chunks of the heads of 256); with the keys split
  5 ways, 160, merged by their row maxima and sums. That saves about 2 ms a step. The per-launch profile had
  overstated the attention's share: synchronizing after each launch adds about 0.25 ms to every one.

Still true from the per-launch profile (`PI0_PROFILE=1`):
- **The prefix is the projections.** Gemma's gate and up run at about 1.6 TFLOP/s.
- **The prefix rows are padded to 896.** With the 832 rows that 64 suffices for, the projections take
  64 × 128 blocks, and the prefix took 6.5 s.
- **The prefix synchronizes after each layer.** The driver plugin submits 64 launches at a time
  (`VK_SUBMIT_EVERY`), and 64 of these outlast the GPU's watchdog: the device is lost.

## The prefix on the Hexagon NPU

`pi0npu.mojo` runs the same chunk with Gemma 2B's prefix on the phone's Hexagon NPU (HTP). SigLIP, the projector and
the expert's 10 steps stay on the Adreno, as above. The prefix is fp16 ONNX graphs ([`../npu/export_pi0.py`](../npu))
that ONNX Runtime's QNN execution provider runs on the HTP ([`../npu/pi0_prefix.cpp`](../npu/pi0_prefix.cpp)), the
route `npu/` takes for Llama's prefill. The program:
1. reads the 816 prefix embeddings back from the GPU and converts them to fp16;
2. runs the six graphs one after another on the NPU;
3. as each graph finishes, converts its three layers' K and V to fp32 and copies them into the expert's cache
   (`kc`/`vc`, rows 0–815), while the NPU runs the next graph.

The GPU holds no Gemma 2B weights (`Pi0(gemma=False)`): 1.4 GB instead of 5.4 GB.

Both programs use the GPU kernels above (split keys, split-k, Gemma's activation first). Same Galaxy Z Fold, same
example, pipelines cached, nothing else running on the phone: the GPU's program first, then `pi0npu`, each started
with SKIN at 30 °C:

| Stage | NPU prefix (`pi0npu`, 4 runs) | All on the GPU (`pi0`, same session, 3 runs) | All on the GPU (above) |
|---|---|---|---|
| Vision | 494–496 ms | 494–514 ms | 530 ms |
| Projector + embeddings | 2–3 ms | 3 ms | 3 ms |
| **Prefix** | **0.80 s** (NPU 0.79 s) | 2.34–2.35 s | 2.56 s |
| 10 steps | 745–748 ms | 749–784 ms | 779 ms |
| **Action chunk** | **2.05–2.16 s** | 3.59–3.61 s | 3.60 s |

- **The prefix runs 2.9× faster on the NPU:** 0.80 s against 2.34–2.35 s on the GPU. Its 3.2 TFLOP (832 rows) take
  0.79 s in most runs (4.0 TFLOP/s) and 0.92 s in some (3.5 TFLOP/s), within one process: here one of the four
  chunks (2.16 s). A separate run of 5 prefixes (`pi0npu_tool`) took 920–929 ms each.
- **The chunk is 1.7× faster:** 2.05–2.16 s against 3.59–3.61 s. Vision (0.49 s) and the 10 steps (0.75 s) are now
  most of it.
- **Overhead:** reading back the embeddings, converting them, and the handoff left after the last graph add 4–12 ms
  to the NPU's time. The first 15 layers' K/V reach the GPU while the NPU is still running.
- The NPU's graphs load in 3.3–6 s per process (3.78 GB of compiled contexts). The GPU's weights load in 2–3 s
  instead of 8–9 s.
- Two sessions once timed π0 on the phone at the same time: GPU chunks then drifted to 3.9–4.2 s. The numbers here
  come from runs with the phone to themselves.
- Before the GPU kernels above, the same comparison gave a 2.12–2.26 s chunk with the NPU (prefix 0.80–0.94 s)
  against 4.05 s all on the GPU (prefix 2.73–2.75 s).
- Compiling the graphs for the HTP takes 18.5 minutes once, on the phone (139–220 s a graph, one graph a process).

### Accuracy in fp16

| | NPU (HTP, fp16) | GPU (fp32, above) |
|---|---|---|
| Prefix K, worst layer | max abs error 0.078 (layer 17; values up to 13.1), relative 4.9e-3 | 0.00078 |
| Prefix V, worst layer | max abs error 0.17 (layer 17; values up to 19.8), relative 6.2e-3 | 0.0018 |
| `v_t` of the 10 steps | 2.5e-3 … 4.6e-3 (values up to 4.1) | 1.1e-5 … 1.5e-5 |
| **Actions (50 × 32)** | **max abs error 3.2e-3** (values up to 1.15; mean 1.6e-4) | 1.1e-5 |

All of that error comes from the prefix's fp16 arithmetic:
- **The handoff and the GPU expert are exact.** `pi0/reference.py --kv` runs PyTorch's 10 steps from the very K/V the
  phone handed to its expert (`PI0_KV`). Its actions are within 1.4e-6 of the phone's (2.4e-6 with the expert's
  kernels before the split keys).
- **The fp16 weights cost almost nothing.** The same graphs computing in fp32 on the Mac's CPU, with the
  fp16-rounded weights (`export_pi0.py --fp32`), give K/V within 4e-4 and actions within 8.9e-6.
- **The HTP is more accurate than ONNX Runtime's fp16 on the Mac's CPU.** The same fp16 graphs there give K/V within
  0.145 / 0.32 (relative 8.5e-3 / 1.1e-2) and actions within 4.7e-3.

The relative errors grow with depth, from 4e-4 in layer 0 to 5–6e-3 in layers 16–17.

### The graphs

`npu/export_pi0.py` writes the 18 layers as six graphs of three layers each:
- **Rows:** each graph runs 832 rows, the 816 prefix rows zero-padded.
- **Inputs:** `x [832, 2048]`, `cos`/`sin [832, 1, 256]` at each row's position (cumsum of the pad mask, minus 1),
  and an additive key mask `[1, 832]` (0 or −30000) for the bidirectional attention.
- **Outputs:** each layer's `k`/`v [832, 256]`, K after RoPE, and the residual stream for the next graph. The last
  layer computes only its K and V.
- **Weights:** they are not in the graphs. They live in `gemma.bin`, an fp16 copy of the 18 layers (3.75 GB). The
  phone writes it from its own checkpoint in 9 s (`npu/pi0_f16.c`, following `recipe.txt`), and its SHA-256 matches
  the Mac's. Gemma's matrices are bf16-exact, and in fp16 only 0.2% of them (those below 2^-14) lose bits.
- **fp16 range:** on this example the residual stream peaks at 3,360 entering layer 17, `gelu(gate) · up` at 2,200,
  and the attention scores at 35. RMSNorm is ONNX's `RMSNormalization` (QNN's `RmsNorm`, which squares in fp32).
- **GeGLU:** `gelu_tanh(x)` is written as `x · sigmoid(u · (1.5957691 + 0.0713548 u²))` with `u = clip(x, −10, 10)`.
  That is the same function, but `u³` cannot overflow fp16 when the gate reaches 43.
- **Attention:** multi-query attention is `[8 · 832, 256] × [256, 832]`, then `Softmax`, then `× V`.

Every node runs on the HTP: CPU fallback is disabled.

## Also on a Snapdragon X2 Elite laptop

The same program drives the Adreno X2-90 of a Snapdragon X2 Elite laptop (Windows on Arm, 33.6 GB) from the Mac,
through the remote driver plugin ([`../vla/x2`](../vla/x2)), with the phone's checks bit for bit. On the laptop's
clock: vision 378–389 ms, prefix 2.13–2.15 s, 70–74 ms a step; 3.1–3.9 s a chunk, including 0.1–0.2 s of
tunnel transfer.

The laptop's Hexagon NPU is the same V81 HTP as the phone's. [`../npu/build_win.sh`](../npu/build_win.sh) builds
`pi0npu_tool` and `pi0_f16` for Windows on ARM (Zig) against ONNX Runtime's QNN NuGet package (1.24.4). There:
- `gemma.bin` came from the checkpoint's 7.9 GB Gemma byte range (an HTTP range request, 8.6 minutes), SHA-256
  identical to the phone's;
- the six graphs compiled for the HTP in 9.6 minutes (78–102 s a graph, one graph a process; 18.5 minutes on the
  phone). Their 3.78 GB of contexts load in 1.9–2.1 s.
- **The prefix takes 0.80–0.84 s on the NPU** (`pi0npu_tool`, two processes of 10 runs), against 2.13–2.15 s on the
  laptop's GPU: 2.6× faster. The phone's NPU takes 0.79–0.92 s.
- Its K/V is within 0.085 (K) and 0.16 (V) of PyTorch's, relative 4.8e-3 and 6.0e-3 (layer 17). PyTorch's 10 steps
  from it (`reference.py --kv`) give actions within 1.95e-3 of the fp32 model's (mean 1.7e-4), against 3.2e-3 from
  the phone's. The two HTPs' K/V are not bit-identical (27% of the values match, the rest within 0.07 and 0.2):
  ONNX Runtime 1.24.4's QNN libraries here, QNN 2.42 on the phone.

The laptop's chunk with the NPU prefix is not measured: the Mac drives the laptop's GPU through the tunnel, so
handing it the K/V would need the NPU inside `vk_server` (writing into its mapped buffers).

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

The phone downloads the 14 GB checkpoint itself (8 minutes in the lab).

With the prefix on the NPU (`N=/data/local/tmp/vla/pi0npu`; ONNX Runtime 1.29 and QNN 2.42 from Maven Central, as in
[`../npu`](../npu)):

```bash
PYTHONPATH=build/npu/pydeps python3 npu/export_pi0.py         # build/npu/pi0: 6 graphs, recipe.txt
python3 npu/build.py pi0tool pi0                               # build/npu/pi0phone: pi0npu_tool, pi0_f16, pi0npu
adb push build/npu/pi0phone/. $N/bin/
adb push build/npu/pi0/npu.txt build/npu/pi0/recipe.txt build/npu/pi0/part*.onnx $N/model/
adb shell "cd $N; bin/pi0_f16 $D/model.safetensors model/recipe.txt model/gemma.bin"     # 9 s
L="LD_LIBRARY_PATH=$N/bin:/system/lib64:/vendor/lib64"
adb shell "cd $N/bin; $L ./pi0npu_tool compile $N/model 0 > $N/compile0.log 2>&1"   # once per graph, 0..5
adb shell "cd $N/bin; $L ./pi0npu_tool $N/model $D/ref 5 $N/dump"                     # NPU alone: time, K/V dump
adb shell "cd $N/bin; $L VK_PIPELINE_CACHE=$N/pipelines.bin MODULAR_DRIVER_PLUGINS=vulkan@$N/bin/libM_driver_vulkan.so PI0_KV=$N/kv.f32 PI0_OUT=$N/actions.f32 ./pi0npu $D/model.safetensors $D/ref $N/model 4"
build/vla/venv/bin/python pi0/reference.py --kv kv.f32 --actions actions.f32   # PyTorch's steps from the phone's K/V
```

Send each compile in its own `adb shell` line. On the lab's bridge, a `for` loop, `nohup`, `setsid` or `sh script.sh`
dropped the connection before the command ran. `npu/pi0_check.py` checks the graphs on the Mac's CPU
(`--graphs`) or the phone's K/V dump (`--dump`) against PyTorch. Its SHA-256 `8229fd9a…` matches the
Mac's copy and Hugging Face's.

**The reference** builds lerobot's `PI0Policy` on the meta device. It hands it the bf16-exact tensors in bf16 and
the rest in fp32, and widens every weight to fp32 inside `nn.Linear`, `nn.Embedding`, `nn.Conv2d` and
`nn.LayerNorm` (`widen_weights`). So the arithmetic is the fp32 checkpoint's, in 6.8 GB of the Mac's 17 instead
of 14. Two of lerobot's checks switch activations to bf16 when a weight is stored in bf16; `keep_fp32_activations`
turns exactly those two off. `predict_action_chunk` and the stage-by-stage replay agree exactly.

**The prompt is fixed token ids.** PaliGemma's tokenizer (`google/paligemma-3b-pt-224`) is gated, so the
instruction is BOS, 13 arbitrary ids and "\n" (108), padded to 48. The images are three procedurally drawn
224 × 224 scenes, the state a seeded normal vector, and the noise `torch.manual_seed(0)`.
