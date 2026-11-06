# Prefill on the Hexagon NPU, decode on the Adreno

An experiment on the Galaxy S26 Ultra (Snapdragon 8 Elite Gen 5, SM8850). The prompt of Llama 3.2 1B Instruct is
prefilled on the Hexagon NPU's HTP. Its KV cache and first-token logits are handed to the Adreno 840, which
decodes with our Mojo `DeviceContext` program (`llama/model.mojo`). This is compared against prefill and decode both
on the GPU, and both on the NPU.

## Results

Galaxy S26 Ultra SM-S948U (Android 16, S948USQS4AZG3) in Samsung's Remote Test Lab. The prompt is the 431-token
passage of `llama/prompts/long.txt` in Llama-3's chat template, followed by 80 greedy tokens. Each run uses a warm
Vulkan pipeline cache and starts with SKIN below 40 °C. Decode is the 79 tokens after the first.

| Llama 3.2 1B | Prompt: prefill + handoff left after it | Prefill rate | Decode after the prompt | Tokens vs PyTorch |
|---|---|---|---|---|
| All-NPU, fp16 (`npu_decode`) | 169 ms + 0.4 ms = 169 ms | 2,550 tokens/s | 38.8 ms, 25.7 tokens/s | 80 of 80 |
| **NPU prefill (fp16) + GPU decode, fp16** | **169 ms + 1.4 ms = 170 ms** | **2,550 tokens/s** | 40.0 ms, 25.0 tokens/s | 80 of 80 |
| All-GPU, fp16 (`llama.mojo`, `LLAMA_PREFILL`) | 685 ms | 629 tokens/s | 39.8 ms, 25.2 tokens/s | 80 of 80 |
| **NPU prefill (fp16) + GPU decode, 4-bit** | **169 ms + 0.8 ms = 170 ms** | **2,550 tokens/s** | 13.2 ms, 76.0 tokens/s | 38 of 80 (a near-tie, below); 80 of 80 from the NPU's K/V |
| All-GPU, 4-bit | 641 ms | 672 tokens/s | 13.2 ms, 75.7 tokens/s | 80 of 80 (int4 throughout) |

There is no 4-bit all-NPU row: the NPU's graphs are fp16, and 4-bit weights on the HTP need quantized
activations (w4a16).

- **Prefill:** the HTP prefills the prompt **4.1× faster** than the Adreno in fp16 (168 ms against 685 ms) and
  **3.8× faster** than the Adreno's 4-bit prefill (641 ms). The NPU graph is the same fp16 one in both rows. The
  Adreno's time uses `p_attention_scalar`, because this phone's driver cannot create the fused attention kernel's
  pipeline. The graphs run 448 rows (the prompt padded to a multiple of 32); `Llama.prefill` runs 512.
- **Decode on the GPU:** the same with either prefill, since both decode with the same Mojo program.
- **Decode on the NPU:** 38.8–39.0 ms a token in fp16 (two runs), against 39.8–40.0 ms on the GPU. Each token reads the 2.47 GB of
  fp16 weights, so both run near the same memory speed: about 63 GB/s, where `android/README.md`'s `vecadd`
  measured 66 GB/s. With 4-bit weights the GPU decodes 3× faster (13.2 ms), which the NPU could match only with
  quantized graphs.
- **All-NPU handoff:** 0.4 ms, only the first token's logits. The prefill writes the prompt's K/V directly into
  the decode graphs' fp16 cache, bound as its outputs (below). Copying them through `npu_kv`'s fp32 and back took
  6.8 ms. The process then releases the prefill contexts and loads the decode ones (2.1–2.4 s), since both sets
  together are 5 GB.
- **Time to the first token:** 170 ms against 641–685 ms.
- **Quantized weights** ([below](#quantized-weights-on-the-htp)): with int8 weights per output channel and uint16
  activations (w8a16), the HTP prefills the same prompt in **116 ms**.
- **Handoff:** 8–15 ms when it follows the whole prefill. It is overlapped with the NPU instead: each part's 4
  layers are converted and copied to the GPU while the NPU runs the next parts. That leaves 0.8–2.0 ms after the
  last part (its 4 layers and the logits), and the NPU's own time does not change. In the same process,
  one-after-the-other against overlapped measured:
  - fp16: 168.1 + 10.9 = 179.1 ms against 169.1 + 2.0 = 171.1 ms;
  - again: 175.0 + 13.4 = 188.4 ms against 168.8 + 1.4 = 170.1 ms;
  - 4-bit: 169.7 + 10.1 = 179.8 ms against 168.9 + 0.8 = 169.8 ms.
- **4-bit decode:** the NPU still prefills with the fp16 weights, so the right reference is mixed: PyTorch's fp16
  prompt pass, then int4 decode from its cache. The phone matches it for 38 tokens. At token 38 the reference's
  top two logits are 0.0043 apart, the smallest margin of the 80 steps, and the fp16 prefill's K/V error (about
  1e-3 relative) is enough to flip it. PyTorch's int4 decode from the NPU's own K/V gives exactly the phone's 80
  tokens, so the handoff and the GPU decode are exact, and the difference comes from the prefill's precision
  alone. With fp16 decode weights, all 80 tokens match.

One-time and per-process costs of the NPU path:

| Step | Time |
|---|---|
| Compile the 4 graphs for the HTP (`libQnnHtpPrepare.so` on the phone, finalization mode 3), once | 201 s (28 + 46 + 45 + 82 s; part 3 holds the lm_head) |
| Load the 4 compiled contexts (2.5 GB of context binaries), at each process start | 1.9–2.4 s |
| First prefill in a process | 175–195 ms |
| Later prefills | 167–172 ms |
| Compile the 4 decode graphs (all-NPU), once | 78 s (12.6 + 12.4 + 12.5 + 40.7 s) |
| Load the 4 decode contexts (2.5 GB), at each process start | 2.1–2.4 s |

The GPU's own weight load is the same in both paths: 1.5 s in fp16, 0.5–0.8 s in 4-bit.

### Accuracy of fp16 on the HTP

`npu_tool` dumps the NPU's KV cache and logits. Compared with PyTorch (fp32 math on the same fp16 weights) over the
431 prompt positions:

| | NPU (HTP, fp16) | ONNX Runtime CPU, the same fp16 graph (Mac) |
|---|---|---|
| K, worst layer | max abs error 0.035 (values up to 21), relative error 1.0e-3 | 0.099 |
| V, worst layer | max abs error 0.011 (values up to 6), relative error 2.2e-3 | 0.057 |
| First-token logits | max abs error 0.027 (range −9.2 … 27.5); same top 5 | 0.112 |
| Generated tokens | 80 of 80 identical | |

The relative errors are Frobenius norms. The HTP's fp16 is more accurate than ONNX Runtime's fp16 CPU kernels on the
same graph, consistent with wider accumulators in its matrix unit. With fp16 decode weights the fp16 prefill
costs no token on this prompt. With int4 decode weights it flips the near-tie at token 38 (above).

## Quantized weights on the HTP

### What ONNX Runtime 1.29's QNN execution provider maps

- **Block-quantized int4 means LPBQ.** The only block-quantized weights the execution provider gives QNN are
  low-power block quantization (`QNN_QUANTIZATION_ENCODING_BLOCKWISE_EXPANSION`), through two node-group
  fusions, `LowPowerBlockQuantizedGemmFusion` and `LowPowerBlockQuantizedMatMulFusion`. A weight is
  `q · c · u`: q int4, c an fp32 scale per output channel, u a 4-bit integer per block (1–15 here; QNN reads
  it as a plain multiplier). In ONNX that is two DequantizeLinear nodes:
  1. `DQ(u uint8, c, axis)` gives the block scales;
  2. a second `DQ(q INT4, those scales, zero point INT4, block_size)` feeds the Gemm or MatMul, with a
     uint16 `DQ` on its input and a `Q` on its output.
- **Plain block DQ is not mapped.** A DequantizeLinear with fp16 block scales (the format of
  `llama/run.py --quant q4`) gets no mapping. QNN's own block encoding (`QNN_QUANTIZATION_ENCODING_BLOCK`)
  has a constructor in the execution provider but no caller, and the per-channel path would misread the
  scales. So the GPU's int4 export cannot be pointed at directly. `quant.py` quantizes the fp16 weights
  again, to scales of LPBQ's form. Each block picks the u near `ceil(s / c)` that minimizes its squared
  error, where s is the block's own `max |w| / 7` and c is the row's largest s over 15. That costs nothing
  measurable: with weights alone, the K/V error against the fp16 model is 0.431 (Frobenius, worst layer),
  against 0.437 for the GPU's q4 with fp16 scales.
- **Q/DQ scales must be fp32.** So the quantized graphs compute in fp32, which the HTP runs in fp16
  (`enable_htp_fp16_precision`, on by default). Only the projections are quantized: each Gemm sits between
  a uint16 QuantizeLinear/DequantizeLinear pair calibrated per tensor. RMSNorm, RoPE, attention, SwiGLU and
  the residual stream stay float, and the graphs' inputs and outputs stay fp16, so `npu_prefill.cpp` reads
  either kind.

### What QNN 2.42's HTP backend builds

Single-projection graphs on the S26 Ultra, 448 rows × 2048 inputs → 16384 outputs (Llama's gate/up), warm,
including about 0.4 ms of fixed per-run cost (`npu_tool bench`):

| Weights | Compiles | Time |
|---|---|---|
| fp16 (the fp16 graphs' FullyConnected) | yes | 4.25 ms |
| int8, per output channel (w8a16 FullyConnected) | yes | 3.94 ms |
| int4, per output channel (w4a16 FullyConnected) | yes | 3.75 ms |
| int4 LPBQ, blocks of 64, MatMul form | yes | 23.4 ms (5.5× fp16) |
| int4 LPBQ, blocks of 64, Gemm form (FullyConnected) | segmentation fault | |

The Gemm form of LPBQ builds only when the weight is exactly 2048 × 2048 (blocks of 32, 64 or 128), and
then takes 1.6 ms, about 3× the time per weight of per-channel int4. Every other shape tried (2048 × 1024,
1024 × 2048, 4096 × 2048, 8192 × 2048, 2048 × 4096, 2048 × 8192) crashes QNN while it adds the weight
tensor or, with inputs split into 2048-wide chunks, in finalization (`tcm_migration.cc: no properties
registered for q::GenPad`).

So on this stack, block-quantized int4 is either slow (MatMul) or unbuildable (FullyConnected).
Per-channel int8 and int4 are faster than fp16.

### Llama 3.2 1B with quantized weights

The same 431-token prompt, the same phone, warm, SKIN below 40 °C. Each graph has 4 parts of 448 rows, like the
fp16 one. The GPU decodes with fp16 weights in every row: 40 ms a token, 25 tokens/s.

| Llama 3.2 1B | NPU prefill (warm) | Prompt: prefill + handoff | Contexts | Compile, once | K/V error vs PyTorch, fp16 model | the same, vs PyTorch with the graph's own weights | First-token logits vs the fp16 model | Tokens vs PyTorch (fp16) |
|---|---|---|---|---|---|---|---|---|
| fp16 (above) | 168 ms | 177 ms | 2.5 GB | 229 s | 2.2e-3 | | 0.027 | 80 of 80 |
| **w8a16: int8 per channel** | **116 ms** | **130 ms** | 1.29 GB | 80 s | 3.1e-2 | 1.3e-2 | 0.57 | 29 of 80 |
| **w4a16: int4 per channel** | **111 ms** | **126 ms** | 0.68 GB | 161 s | 0.60 | 3.8e-2 | 7.3 | 14 of 79 |
| w4a16: int4 LPBQ, blocks of 64 (MatMul) | 495 ms | 509 ms | 0.72 GB | 291 s | 0.35 | 1.5e-2 | 5.5 | 16 of 71; all 71 vs the int4 model |

- **Speed:** per-channel weights prefill **1.45× (int8) and 1.5× (int4) faster** than fp16 on the HTP. Against
  the Adreno's 685 ms that is 5.9× and 6.2×.
- **Accuracy:**
  - **w8a16 is the usable variant.** Its K/V are within 3.1e-2 of the fp16 model, and the text stays coherent
    after the 29th token, where it diverges into a paraphrase: "…involves matrix multiplication, which is
    dominated by memory traffic" for "…is limited by memory bandwidth".
  - **Int4 per channel is too coarse** for Llama: 0.60 against the fp16 model.
  - **Block-64 int4 is as accurate as the GPU's q4,** but at 495 ms it is 3× slower than fp16 (below). Its
    error is the weights' own: PyTorch's prompt pass with the same int4 weights, followed by fp16 decode,
    gives all 71 of the phone's tokens.
  - **Activations:** the uint16 activations add 1.3e-2 to 3.8e-2 (the second K/V column).
  - **Handoff:** in every row, PyTorch decoding from the NPU's own K/V gives exactly the phone's tokens, so
    handoff and decode are exact. The token differences come from the prefill alone.
- **Layer 1's down projection stays fp16** in all three quantized graphs (`--keep`). Its input carries the
  massive activation (−1093 against ±3 elsewhere), and a per-tensor uint16 scale over that range is 0.018.
  Quantizing it raises the activations' K/V error from 1.4e-2 to 0.18.
- **Calibration:** min/max per tensor, widened by 10%. The prompts are `calib.txt`: five prompts plus their
  concatenation, cut at 448 tokens. The test prompt is not among them.
- **Handoff time:** 13–15 ms, against 9 ms for fp16. The K/V are the same fp16 tensors; the difference is run
  to run.
- **Weights on the phone:** the per-channel weights are written there from its own fp16 `weights.bin`
  (`pc_convert.cpp`, following `export.py`'s `recipe.txt`), byte for byte the Mac's (SHA-256), in seconds.
  Pushing them over the lab's adb bridge runs at 1.3–3 MB/s.

### Ternary Qwen3-8B

Prism ML's ternary Qwen3-8B (`prism-ml/Ternary-Bonsai-8B-mlx-2bit`, the checkpoint `qwen3/` runs on the GPU).

**Its weights cannot go on the HTP exactly at speed.** Every projection and the head are ternary: t ∈ {−1, 0, +1}
times an fp16 scale per 128. That is exact as int4 with per-128 block scales, but:
- block scales mean LPBQ (above), whose fast FullyConnected form QNN 2.42 does not build at Qwen3's shapes;
- its MatMul form, at the rate the microbenchmark above measured (5.5× per-channel int4), would take about
  4.8 s for this prefill, slower than the GPU's 3.95 s;
- int8 per channel would be near-exact (k up to 127) but 7.6 GB, which does not fit next to the GPU's 2.2 GB.

**So the graphs use int4 per output channel** (`export_qwen3.py --form pc4`, 3.79 GB), and the per-group
scales are approximated. A weight is `t · k · c`:
- k ∈ 1…7 per group of 128 (so the int4 value is ±k or 0);
- c is fp32 per row, fitted with k by a few Lloyd steps to minimize the row's squared scale error.

**What that costs.** Within a row the group scales spread about 1.3–1.4× (max/min). So a group's scale is
typically off by up to 8%, and in rare rows with one tiny group by far more: the worst group in the model is
192% off, because k cannot go below 1. In PyTorch (`qwen3_check.py`), these weights alone move the K/V of the
408-token prompt by 0.086 (relative, worst layer) from the exact ternary model. The logits move by up to 0.93
(range −11 … 27), with the same argmax and top 5.

**The graph.** 36 layers in 6 parts of 6 layers, about 630 MB each, the last with the head (4 chunks).
- 416 rows, for the 408-token prompt.
- q/k RMSNorm per head, written out (ReduceMean, Sqrt, Div on values pre-scaled by 1/8), then RoPE from MLX's
  YaRN table (`build/qwen3/rope1024.f32`, its attention factor included). The q/k norm cannot be an ONNX
  `RMSNormalization` here. ONNX Runtime 1.29 gives every QNN `RmsNorm` one shared dummy beta tensor
  (`_beta_dummy`), sized by the first norm it meets (4096). So a 128-wide `RmsNorm` in the same graph fails QNN's
  validation ("Beta shape does not match … 4096 != 128", error 3110).
- uint16 activations around every projection, calibrated on `calib.txt` in Qwen3's chat template.
- The residual stream reaches 7,800, within fp16. No projection is kept in fp16.

The widest activation ranges are in the last layers: layer 35's down-projection input reaches ±1,100 and its
o-projection output 4,050. On the Mac's CPU (ONNX Runtime, `qwen3_check.py cpu`) the graphs give:

| Qwen3-8B, 408-token prompt | K/V error, worst layer | Logits max error | Argmax, top 5 |
|---|---|---|---|
| PyTorch with the int4 weights, vs the exact ternary model | 8.6e-2 | 0.93 | same |
| the graphs on the Mac's CPU, vs the exact ternary model | 8.7e-2 | 1.35 | same |
| the graphs on the Mac's CPU, vs PyTorch with the same int4 weights (the activations' share) | 3.0e-2 | 1.96 | same |

The activations' share grows from about 3e-3 in the first 18 layers to 3e-2 in the last ones, as the ranges
widen.
Keeping the widest projections in fp16 would cut it, as layer 1's down projection does for Llama.

**On the phone.** The S26 dropped off the lab's adb bridge twice during these runs, and the lab then gave a
Galaxy Z Fold SM-F976U (the same SM8850, Android 17, 11 GB). So the Qwen3 numbers are all from the Fold. Its
graphs compile in about 10 minutes, a part a process. The last part was split once more, layers 30–32 apart from
33–35 with the head (`--bounds`): compiling those six layers and the head in one process ran out of memory (QNN
error 1002, then an abort).

| Ternary Qwen3-8B, 408-token prompt, Galaxy Z Fold | Time | K/V error, worst layer (vs exact ternary; vs the same int4 weights) | Logits vs the exact model |
|---|---|---|---|
| NPU prefill, w4a16 per channel, 7 contexts (3.79 GB) | **1.53–1.65 s** (5 runs; 267–247 tokens/s) | 9.7e-2; 6.0e-2 | max error 1.35 (range −11 … 27); same argmax and top 5 |
| loading the 7 contexts, once a process | 5.0 s | | |

Then prefill on the NPU, decode on the GPU (`hybrid_qwen3`), against `Qwen3.prefill` on the GPU, the same Fold,
SKIN below 40 °C, 80 greedy tokens:

| Ternary Qwen3-8B, 408 tokens, Galaxy Z Fold | Prompt | Decode after it | Tokens |
|---|---|---|---|
| **NPU prefill (w4a16) + GPU decode** | **1.64 s** = 1.37 s prefill (best of 2 warm; 1.42 s cold) + 0.23 s handoff | 48.0 ms, 20.8 tokens/s | 80, identical to the all-GPU run's 80 |
| All-GPU (`qwen3.mojo`, `QWEN3_PREFILL`, `tuner/`'s table) | 3.60 s (warm; the first run took 40.9 s, building the fused attention pipeline once) | 45.4 ms, 22.0 tokens/s | 80 |

- **Speed:** the HTP prefills the prompt **2.6× faster** than the Adreno (1.37 s against 3.60 s). With the
  handoff the time to the first token is **2.2× shorter**.
- **Tokens:** despite the approximate group scales, all 80 tokens are the GPU's exact-ternary tokens.
- **One model at a time:** the NPU's 7 contexts (3.8 GB) and the GPU's weights (2.2 GB) together rebooted the
  Fold, which had 5.5 GB free. So `hybrid_qwen3` converts the NPU's K/V and logits into host memory (11 ms),
  releases the contexts, then loads the GPU model (2.6 s, not counted in the prompt time) and copies the K/V into
  its cache (219 ms for 36 layers of fp32).
- **Decode** is 6% slower than in the all-GPU run (48.0 against 45.4 ms a token), with the same Mojo program. The
  two runs differ only in what ran before them, so this is probably the phone's state after the NPU run rather
  than the cache contents.

**The pieces:**
- **Phone setup.** The phone downloads the checkpoint itself (2.3 GB, SHA-256 `f43270cb…` checked) and writes
  both weight files:
  - `qwen3_lpbq.cpp` writes the NPU graphs' `weights.bin` in 20 s, byte for byte the Mac's export (same
    SHA-256);
  - `qwen3_convert` writes the GPU's, with a context of 1024.
- **Prefill.** `npu_prefill.cpp` reads `qwen3-prefill` from `npu.txt` for Qwen3's shape and dequantizes the
  2-bit embedding rows on the CPU.
- **Handoff.** `hybrid_qwen3.mojo` copies each layer's K/V into `qwen3/model.mojo`'s position-major cache
  (`npu_kv_rows`), takes the first token from the NPU's logits, and continues with `Qwen3.forward`.
- **Validation.** The PyTorch reference (a layer at a time from the checkpoint) matches MLX's logits for
  `qwen3/`'s 19-token prompt to 4 decimals.

## How the NPU is reached from `adb shell`

A retail S26 has no Qualcomm SDK on it. Its compute DSP has an unsigned protection domain
(`/vendor/dsp/cdsp/fastrpc_shell_unsigned_3`), and the HTP skel loads from `/data/local/tmp`. Everything needed is
public on Maven Central:

| Artifact | Size | What it gives |
|---|---|---|
| `com.microsoft.onnxruntime:onnxruntime-android-qnn:1.29.0` | 9.4 MB | `libonnxruntime.so` with the QNN execution provider, and its C/C++ headers |
| `com.qualcomm.qti:qnn-runtime:2.42.0` (the version ORT 1.29 depends on) | 63 MB | `libQnnHtp.so`, `libQnnHtpPrepare.so` (the HTP graph compiler), `libQnnHtpV81Stub.so` and `libQnnHtpV81Skel.so` (Hexagon V81) |

No Qualcomm account is needed. The ONNX graph is compiled for the HTP on the phone by `libQnnHtpPrepare.so`, and
the compiled context binary is saved, so later runs only load it.

Compiling takes its own process for each part (`npu_tool compile <dir> <i>`), for two reasons:
- **Memory.** Compiling holds several copies of a part's weights: ONNX Runtime's initializers, QNN's tensors, the
  prepared graph and the context. With four parts compiled in one process, the phone's available memory fell from
  8 GB to 0.4 GB while part 3 compiled, and `dumpsys meminfo` timed out.
- **An unexplained ONNX Runtime error.** On the first lab phone, compiling the parts inside the prefill program
  failed with "Input/Output name not found", and so did loading the context it had saved. QNN's own graph had the
  right inputs and outputs (its JSON dump), and the context binary holds the right tensor names. Compiling a part
  in a process of its own, then loading the saved contexts in another, works. So `npu_open` loads only compiled
  contexts.

Two details of running from a shell:
- `LD_LIBRARY_PATH` must list `/system/lib64` before `/vendor/lib64`. Otherwise the system's `libbinder_ndk.so`
  binds the vendor `libbinder.so`, the stub fails to load (`cannot locate symbol
  _ZN7android7IBinder16setMinRpcThreadsEt`), and QNN reports `QNN_DEVICE_ERROR_INVALID_CONFIG`.
- `ADSP_LIBRARY_PATH` names the directory holding the skel. `npu_prefill.cpp` sets it from the executable's
  directory.

## The prefill graph

`export.py` writes Llama's prefill as ONNX graphs with no weights in them. Each initializer points into the
`weights.bin` that `llama/run.py` exports and `llama/st2bin.c` writes on the phone, at its `manifest.txt` offset.
The phone needs only the graphs (1.7 MB each, mostly the causal mask), placed in its `llama/model` directory next
to the `weights.bin` they read. ONNX Runtime refuses external data outside the graph's directory or reached
through a symlink, and one lab phone refused a hard link.

- **Parts:** 4, each with 4 layers. A part runs `rows = 448` prompt positions at once. A shorter prompt is
  zero-padded at the end, and the causal mask keeps the padding out of the real rows.
  - Inputs: `x [448, 2048]`, the embedding rows, gathered on the CPU from `weights.bin`.
  - Outputs: `k<l>`, `v<l>` (fp16, RoPE applied), and `x_out` for the next part. The last part instead outputs
    `logits [1, 128256]` of row `last`, an input.
  - K/V layout: `[8, 512, 64]`, the KV cache's own layout. The 448 rows are zero-padded by a `Pad` on each
    output (`--kv-slots 512`), so a decode cache can be bound as the output buffer itself.
- **Precision:** all fp16, the HTP's float type.
- **RMSNorm:** ONNX's `RMSNormalization`, which the QNN EP maps to QNN's `RmsNorm`. The residual stream
  reaches 410 on this prompt, the massive-activation dimensions after layer 1, and 410² overflows fp16. So
  RMSNorm cannot be written as fp16 `x * x` ops.
- **Projections:** `Gemm` with `transB=1` on `weights.bin`'s row-major `[out, in]` matrices. The fused `wqkv`
  and `wgu` are `Split` after the `Gemm`.
- **Attention:** grouped-query. The 32 query heads are reshaped to `[8, 4·rows, 64]` against the 8 KV heads, with
  an additive causal mask and `Softmax`.
- **lm_head:** the tied embedding's 4 chunks (`embed.0..3`), as on the GPU.

`export.py --fp32` writes the same graphs computing in fp32. On the Mac's CPU (ONNX Runtime 1.31), they match
PyTorch's KV cache within 6.6e-5 and its logits within 9.2e-5.

## The handoff

`npu_prefill.cpp` runs the parts through ONNX Runtime's C++ API with IO binding to fixed host buffers. They run
on a worker thread: `npu_prefill_start` starts them, `npu_part_wait(i)` returns when part i's K/V are written, and
`npu_prefill_finish` waits for the last part. As each part finishes, while the NPU runs the next ones,
`hybrid.mojo`:
1. converts each layer's fp16 K and V to fp32 `[kv head][512][64]`, the layout `p_rope_kv` writes;
2. copies them into the `Llama` model's `kc`/`vc` device buffers with `enqueue_copy`;
3. after the last part, takes the first token from the NPU's logits;
4. continues with `Llama.forward(token, position)` from position `n`.

The existing paths (`Llama.forward`, `Llama.prefill`, `llama.mojo`) are unchanged.

All on the NPU (`npu_decode.cpp`), there is nothing to convert. The decode graphs read an fp16 cache
`[8][512][64]` per layer, the same layout as the prefill's padded outputs. So `npu_bind_kv` binds each layer's
K/V output to that cache before the prefill runs: ONNX Runtime's `IoBinding` replaces an output's buffer when it is
bound again. The prefill then writes the prompt's K/V into the decode cache, and the handoff is just the first
token's logits.

## Follow-ups

- **Any prompt length:** the graphs are compiled for 448 rows. A chunked graph that takes a KV-cache input (128
  rows at a time, say) would serve any prompt without recompiling, as Qualcomm's own LLM pipelines do.
- **Block-quantized int4 at speed:** LPBQ through a QNN FullyConnected is the fast form Qualcomm's own LLM
  pipelines use, but QNN 2.42 builds it only for 2048 × 2048 weights. A newer QNN runtime (the HTP backend
  libraries are separate from ONNX Runtime), or QNN's own converter instead of ONNX Runtime, may lift that.
- **Fully quantized graphs:** the float parts (RMSNorm, attention, SwiGLU) run in fp16 between Quantize and
  Dequantize ops. A graph quantized throughout (uint16 everywhere, as Qualcomm's are) would drop those
  conversions. In the LPBQ graph's profile they took 40% of the HTP's cycles.
- **The fp16 graph's SwiGLU:** in the HTP's profile of the fp16 graph, the two Muls of SwiGLU (`gate * sigmoid(gate)
  * up` on [448, 8192]) took 25 M cycles a layer, three times the layer's four projections (8 M). An HTP-friendly
  form of that product would speed up every variant.

## Files

| File | |
|---|---|
| `export.py` | the prefill graphs (`--fp32` for checking on the Mac, `--parts`, `--rows`, `--kv-slots`; `--quant w4a16 --form pc8/pc4/matmul/fc` for quantized weights) |
| `npu_prefill.cpp` | ONNX Runtime + QNN HTP (C interface), Llama's or Qwen3's graphs (from `npu.txt`): compile a part (`npu_compile`), load the compiled parts, prefill, K/V and logits out; `-DNPU_TOOL` builds `npu_tool` (also `bench`: time any compiled graph; `NPU_PROFILE`: QNN's per-op profile) |
| `hybrid.mojo` | NPU prefill, handoff (timed one after the other and overlapped with the NPU's parts), GPU decode: the new entry point |
| `export_decode.py` | the decode graphs (one token against an fp16 KV cache of 512 positions; `--fp32` for the Mac) |
| `npu_decode.cpp` | all-NPU: `npu_prefill.cpp`'s prefill, then greedy decode through the decode graphs; `compile <dir> <i>` compiles one decode part |
| `build.py` | `tool`, `hybrid`, `decode`, `pi0tool`, `pi0`, `hybrid_qwen3` and `convert` (`pc_convert`, `qwen3_lpbq`) for the phone, with the ORT and QNN libraries staged next to them |
| `run.py` | reference in PyTorch, push, NPU K/V check (`--kv`), hybrid run, all-GPU baseline (`--baseline`), all-NPU run (`--all-npu`); `--graphs` picks a quantized variant |
| `export_pi0.py` | π0's Gemma 2B prefix as fp16 graphs in 6 parts, and the recipe for their `gemma.bin` ([`../pi0`](../pi0/README.md#the-prefix-on-the-hexagon-npu)) |
| `pi0_f16.c` | `gemma.bin` from π0's fp32 checkpoint (fp16), on the phone |
| `pi0_prefix.cpp`, `pi0_prefix.h` | π0's prefix through ONNX Runtime + QNN HTP (C interface for `pi0/pi0npu.mojo` on the phone, and for `vla/x2`'s `vk_server_npu.exe` on the X2 Elite laptop); `-DNPU_TOOL` builds `pi0npu_tool` (compile a part, time, dump K/V) |
| `pi0_check.py` | π0's prefix graphs on the Mac's CPU, or the phone's K/V dump, against PyTorch's cache |
| `quant.py` | quantized weights: LPBQ (block int4) and per-channel int8 / int4, their `weights.bin` writer and reader, activation ranges |
| `calib.txt` | the calibration prompts (not the test prompt) |
| `pc_convert.cpp` | the per-channel graphs' `weights.bin` on the phone, from its fp16 one (`export.py`'s `recipe.txt`) |
| `cpu_check.py` | the Llama graphs on the Mac's CPU (ONNX Runtime) against PyTorch |
| `export_qwen3.py` | ternary Qwen3-8B's w4a16 prefill graphs, its PyTorch reference (a layer at a time) and calibration |
| `qwen3_lpbq.cpp` | Qwen3's int4 `weights.bin` on the phone, from the checkpoint it downloads (byte for byte `export_qwen3.py`'s) |
| `qwen3_check.py` | the Qwen3 reference against MLX's logits; the NPU's K/V and logits against it |
| `hybrid_qwen3.mojo` | Qwen3: NPU prefill, handoff into `qwen3/model.mojo`'s cache, GPU decode |
| `run_qwen3.py` | Qwen3 on the phone: setup, compile, K/V check, hybrid run, all-GPU baseline |

## Run

```bash
PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python
SNAP=<Llama-3.2-1B-Instruct snapshot>
PYTHONPATH=build/npu/pydeps $PY npu/export.py                 # build/npu/graphs
python3 npu/build.py tool hybrid                               # build/npu/phone
# --setup on a wiped phone: it downloads the checkpoint from Hugging Face and converts it (st2bin, SHA-256 checked).
# Missing contexts are compiled first, one part per process (npu_tool compile).
PYTHONPATH=build/npu/pydeps $PY npu/run.py --model $SNAP --setup --push-graphs --kv --baseline
PYTHONPATH=build/npu/pydeps $PY npu/run.py --model $SNAP --quant q4 --kv --baseline
# all on the NPU: the decode graphs, compiled once a part a process, then prefill and decode on the HTP
PYTHONPATH=build/npu/pydeps $PY npu/export_decode.py          # build/npu/decode
python3 npu/build.py decode                                    # build/npu/phone/npu_decode
PYTHONPATH=build/npu/pydeps $PY npu/run.py --model $SNAP --all-npu --no-hybrid
```

The quantized variants (`llama/run.py` defaults `ANDROID_SERIAL` to a Wi-Fi phone: set it to the lab phone's
serial). `NPU_DEV` is the phone directory for the programs and libraries, `/data/local/tmp/npu` by default:

```bash
python3 npu/build.py tool hybrid hybrid_qwen3 convert       # convert: pc_convert, qwen3_lpbq for the phone
for f in pc8 pc4 matmul; do      # w8a16, w4a16 per channel, w4a16 LPBQ (its weights are pushed, 0.66 GB)
  PYTHONPATH=build/npu/pydeps $PY npu/export.py --quant w4a16 --form $f --out build/npu/graphs-$f --hf $SNAP
  PYTHONPATH=build/npu/pydeps $PY npu/cpu_check.py --graphs build/npu/graphs-$f --hf $SNAP        # Mac CPU
  ANDROID_SERIAL=localhost:<port> PYTHONPATH=build/npu/pydeps $PY npu/run.py --model $SNAP --graphs build/npu/graphs-$f --kv
done
```

Ternary Qwen3-8B (the Mac needs the checkpoint for calibration; the phone downloads its own):

```bash
PYTHONPATH=build/npu/pydeps $PY npu/qwen3_check.py --checkpoint <ckpt dir> mlx         # the reference vs MLX
PYTHONPATH=build/npu/pydeps $PY npu/export_qwen3.py --checkpoint <ckpt dir> --form pc4 --out build/npu/qwen3-pc4
PYTHONPATH=build/npu/pydeps $PY npu/qwen3_check.py --checkpoint <ckpt dir> reference --graphs build/npu/qwen3-pc4
python3 android/build.py qwen3
ANDROID_SERIAL=localhost:<port> PYTHONPATH=build/npu/pydeps $PY npu/run_qwen3.py --setup --kv --baseline
```

On the phone, by hand (`D=/data/local/tmp/npu`, `M=/data/local/tmp/llama/model`):

```bash
adb shell "cd $D; LD_LIBRARY_PATH=$D:/system/lib64:/vendor/lib64 ./npu_tool compile $M 0"     # once per part, 0..3
adb shell "cd $D; LD_LIBRARY_PATH=$D:/system/lib64:/vendor/lib64 MODULAR_DRIVER_PLUGINS=vulkan@$D/libM_driver_vulkan.so ./hybrid $M $M 80 <token ids>"
```

`onnx` and `onnxruntime` (Mac) are installed with `uv pip install --target build/npu/pydeps`. The two AARs are
unpacked under `build/npu/dl/{ort,qnn}/x`.
