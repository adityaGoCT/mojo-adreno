# LFM2.5-2.6B on the Adreno 840 and the Hexagon NPU: GPU, GPU+NPU and NPU

Liquid AI's hybrid LFM2.5-2.6B, from [`LiquidAI/LFM2.5-2.6B-GGUF`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-GGUF)
(revision `e7caca5d`, license `lfm1.0`, not gated), generates text on a Galaxy Z Fold (SM-F976U, Snapdragon 8 Elite
Gen 5: Adreno 840 GPU, Hexagon V81 NPU) in Samsung's Remote Test Lab, in four configurations. The weights are the
repository's quantization-aware-distilled `LFM2.5-2.6B-QAD-Q4_0.gguf` (SHA-256 `a247afd6…`, 1.59 GB), which the
phone downloads from Hugging Face itself. Every GPU kernel is Mojo (adreno840 SPIR-V), driven by a Mojo
`DeviceContext` program on the phone. The NPU runs ONNX graphs through ONNX Runtime's QNN execution provider
(HTP backend), as `../npu` does.

The prompt is the 415-token passage of `prompts/long.txt` (Llama's, in LFM2's chat template). Each row then
generates 64 greedy tokens. Times are the phone's own clock, warm (after an untimed run of the prompt).

| Config, device (all on the Galaxy Z Fold SM-F976U) | Weights | Prefill, 415 tokens | Decode | vs the GGUF's int4 model (transformers) | vs fp32 (QAD source): greedy, KL |
|---|---|---|---|---|---|
| **GPU baseline**: Adreno 840, Mojo kernels, no matrix units | fp16 (the GGUF dequantized), 5.4 GB | 7.25 s (**57 tokens/s**) | **86.7 ms/token** | logits within 7.4e-5 (same fp16 weights); 64 of 64 tokens | 61 of 64, KL 0.059 |
| **GPU optimized**: Adreno 840, int4 matrix-vector kernels, prefill on fp32 cooperative matrices | the GGUF's own Q4_0 + Q6_K head, 1.59 GB | 1.30 s (**319 tokens/s**) | **31.2 ms/token** | logits within 1.1e-4; 64 of 64 | 61 of 64, KL 0.059 |
| **GPU+NPU**: prefill on the Hexagon NPU (HTP), decode on the Adreno 840 | NPU: int8 w8a16 + fp16 down projections, 3.4 GB; GPU: Q4_0 | **199 ms (2,082 tokens/s)**; + 75 ms handoff | **31.7 ms/token** | 64 of 64 (KL 2.5e-4) | 61 of 64, KL 0.060 |
| **All-NPU**: Hexagon NPU (HTP) | w8a16 + fp16 down projections, 3.4 GB | **198 ms (2,096 tokens/s)**; + 2.47 s handoff | **53.6 ms/token** | 63 of 64 (KL 3.8e-4) | 62 of 64, KL 0.068 |

- **Exact on its weights.** Both GPU configurations reproduce transformers' own LFM2 layers running the same
  weights. Every layer's residual stream matches to 4e-6 (relative), and the logits to 1e-4 at every checked
  position over a range of -19 … 37. All 64 tokens are the reference's argmax ([Checks](#checks)).
- **Against the fp32 model** the GGUF was quantized from (`qad/model.safetensors`), the devices add almost nothing
  to what Q4_0 itself costs. On the same tokens, the GGUF's int4 model in transformers agrees with fp32's greedy
  choice at 61 of 64 positions with KL 0.059 (63 of 64, 0.069 on the all-NPU run's tokens). Both GPU rows match
  that exactly. The NPU's int8 weights and 16-bit activations change the KL by +0.002 (GPU+NPU) and −0.001
  (all-NPU). Every
  configuration's first difference from fp32 is the answer's first token, where Q4_0 itself differs.
- **Prefill:** the NPU reads the prompt **6.5× faster** than the GPU's best (199 against 1,300 ms), and 36× faster
  than the baseline.
- **Decode:** memory-bound everywhere. Each token reads the weights once: 1.59 GB in 31.2 ms on the GPU (51 GB/s),
  5.4 GB of fp16 in 86.7 ms (62 GB/s), and 3.36 GB in 53.6 ms on the NPU (63 GB/s). So the GPU with 4-bit weights
  decodes 1.7× faster than the NPU, whose fast path needs 8-bit weights.
- **Handoffs:** GPU+NPU's 75 ms is releasing the NPU's contexts (66 ms) and copying 8 layers' K/V and 22 conv states
  into the GPU (8 ms). The GPU's weights then load in 1.4 s, not counted, as in `../npu`'s Qwen3 run: the two models
  are not held in memory together. All-NPU's 2.47 s is releasing the prefill contexts and loading the decode
  contexts (3.4 GB each, too much for this 11 GB phone at once).

## The model

From `qad/config.json` and transformers' `modeling_lfm2.py`:

| | |
|---|---|
| Layers | 30: 22 double-gated short-convolution blocks, and 8 grouped-query attention blocks (layers 2, 5, 9, 13, 17, 21, 24, 27) |
| Hidden, MLP | 2048; SwiGLU, 10752 |
| Attention | 32 query heads, 8 KV heads, head dim 64; RMS norms on q and k per head; RoPE (θ 10⁷, rotate-half) |
| Convolution | in_proj 2048 → 3 × 2048 (B, C, x); y = C ⊙ conv₃(B ⊙ x), depthwise, causal, 3 taps; out_proj |
| Norms | RMSNorm (x / rms · w, eps 1e-5) before each block and its MLP, and at the end (`embedding_norm`) |
| Vocabulary | 128000; the head is the tied embedding |

For decode, a convolution layer keeps the last two values of B ⊙ x as its state, a ring of 3 rows here (slot p mod 3).

## Weights

`export.py` lays out three files from the GGUF's header (`gguf_read.py`), and `convert.c` writes them. It runs on the
phone, from the GGUF the phone downloaded, and on the Mac, and both write the same bytes (SHA-256):

| Storage | File | What | Size | SHA-256 |
|---|---|---|---|---|
| `q4` | `lfm2_q4.bin` | the GGUF's own numbers: each Q4_0 matrix as int4 words (8 a uint32, two's complement, low nibble first: `llama/kernels`' storage) and its fp16 scales per 32, unchanged; the Q6_K embedding/head repacked to 4-byte-aligned super-blocks (ql, qh, scales; d apart), unchanged | 1.59 GB | `b6e14c51…` |
| `f16` | `lfm2_f16.bin` | every matrix dequantized as ggml does, rounded to fp16 | 5.39 GB | |
| `npu` | `npu_w8.bin` | every matrix and the head int8 per output channel (fp32 scale, max \|w\| / 127 of the GGUF's numbers), the MLPs' down projections fp16 | 3.36 GB | `1c415ed0…` |

Norms and conv taps stay fp32 as stored. In each layer, q|k|v and w1|w3 (gate|up) are one matrix.

## The GPU

`model.mojo`'s `step()` runs a token in 7 launches a convolution layer and 8 an attention layer, 222 in all. Token ids live on the GPU: the
embedding kernel reads `ids[p]` and the argmax writes `ids[p + 1]`.
1. `embed_q6` dequantizes the token's Q6_K row (or `embed_h` copies the fp16 row), then `add_norm` applies
   layer 0's norm.
2. Each convolution layer runs four launches:
   - `gemv_q4` for in_proj;
   - `short_conv`, which computes B ⊙ x, reads the two earlier values from the state ring, applies the 3 taps and
     C, and writes this position's B ⊙ x into its slot;
   - `gemv_q4` for out_proj;
   - `add_norm`.
3. Each attention layer runs five launches:
   - `gemv_q4` for q|k|v;
   - `qk_norm_rope`, which applies the q and k norms and RoPE, folds the 1/8 scale into q, and writes K and V into
     the cache rows;
   - `attention`, a workgroup per head with the scores in shared memory;
   - `gemv_q4` for o;
   - `add_norm`.
4. The MLP runs three launches: `gate_up_q4` (both rows, SiLU and the product), `gemv_q4` for down, and `add_norm`
   (the residual add and the next norm).
5. `head_q6` computes the tied head straight from the Q6_K super-blocks, then `argmax`.

The f16 storage swaps in `gemv_h`, `gate_up_h` and `embed_h`, the same kernels on fp16 rows.

**Prefill** (`LFM2_PREFILL`) runs the prompt in batches of up to 512 rows. Each projection is one matrix product:
- **int4:** `gemm_q4`, `llama/kernels/prefill`'s `p_gemm_q4` with Q4_0's scale per 32. It unpacks int4 into fp32
  tiles in shared memory and multiplies on KHR cooperative matrices (64 × 64 × 8).
- **fp16** (the baseline): `gemm_h`, scalar 64 × 64 tiles, 4 × 4 outputs a thread.

The row kernels take all rows at once. `short_conv` reads earlier rows of the batch directly and earlier positions
from the state, and `conv_state` keeps the last two rows. Attention is one workgroup per head and row.

The int4 prefill reaches 1.55 TFLOP/s (2.02 TFLOP for the 415 rows in 1.30 s), the rate `p_gemm_q4` reaches for
Llama and Gemma 4. Fetching the next k step into registers during the products (double buffering) gave 1.33 s.

Where a decode step goes (`LFM2_PROFILE=1`: a wait after each launch, so about 0.2 ms of waiting each; a normal step
is 31 ms):

| Launches | ms a token |
|---|---|
| gate/up + SiLU (int4) | 18.6 |
| down (int4) | 14.1 |
| residual adds + norms (60) | 13.3 |
| in_proj, out_proj (conv layers) | 7.8, 5.6 |
| short conv | 4.7 |
| head (Q6_K, 128000 rows) + argmax | 3.6 |
| q/k/v, attention + q/k norms + RoPE, o (attention layers) | 2.2, 2.2, 2.0 |
| **all, each waited for** | **74.3** |

Net of the waits, the int4 matrix-vector kernels read their weights at 46–61 GB/s, and the fp16 ones at 62 GB/s.

## The NPU

`export_npu.py` writes the graphs. Their initializers point into `npu_w8.bin` (external data next to the graphs).
`npu/graph.cpp` compiles each one for the HTP on the phone, in its own process (`compile_npu.sh`), and runs them.

| Graph | Rows | In | Out |
|---|---|---|---|
| `p0` … `p4`: prefill, 6 layers each | 416 (the prompt zero-padded; causal, so padding never reaches a real row) | x [416, 2048] (p0: the embedding rows), the last two rows' indices | x (p4: the last row only); per attention layer K, V [8, 416, 64]; per conv layer its state [2, 2048] |
| `d0` … `d4`: decode, 6 layers each | 1 | x, cos/sin of the position, a mask over 512 cache slots, the caches [8, 512, 64], the conv states | x; this position's K, V and B ⊙ x |
| `head` | 1 | x | the final norm and the tied head (int8, 4 chunks): logits [1, 128000] |

`npu_lfm2.cpp` runs them. It dequantizes the prompt's embedding rows from the GGUF's Q6_K on the CPU, and either
hands the outputs to the GPU (`hybrid.mojo`: K/V into the GPU's cache, conv states into its ring slots, the first
token from the NPU's logits) or keeps the caches on the host for its own decode loop (`lfm2_npu`).

**Why int8 weights.** fp16 weights would be 5.4 GB of HTP contexts. On this Fold, 3.8 GB of contexts plus 2.2 GB of
GPU weights rebooted it (`../npu`), so the graphs are w8a16, as `../npu` measured fast:
- each projection's weights are int8 per channel;
- its input and output pass through uint16 QuantizeLinear/DequantizeLinear pairs, calibrated per tensor on
  `npu/calib.txt` (not the test prompt), with the range widened 10%;
- norms (`npu/htp_norms.py`'s fp16-safe rms16, written out), the convolution, RoPE, attention and SwiGLU are float.

**Except the down projections.** In PyTorch, quantizing one kind of tensor at a time:
- the down projections' uint16 inputs alone moved the final hidden state by 3.3% and the logits by up to 0.43;
- their outputs alone moved it by 1.4%;
- every other kind moved it by at most 0.5%.

Layer 4's down input reaches ±17 where most values are near 0.01, so a per-tensor 16-bit grid is too coarse for
them. Widening the calibrated ranges 2× or 4× made it worse, so the step size dominates, not clipping. With the 30
down projections in fp16 and float in and out (+0.66 GB), the graphs on the Mac's CPU are within these margins:
- 0.67% (K/V) and 0.021 (logits, KL 9e-6) of PyTorch with the same weights;
- 2.5% (K/V) and 0.38 (logits, KL 2.2e-3) of the GGUF's model. That gap is re-quantizing Q4_0's numbers to int8
  per channel.

**Blocks of rows made the prefill 4.2× faster.** The first graphs carried activations as [416, c] tensors and took
835 ms. QNN's per-op profile of part 0 showed where the time went:
- the int8 products ran at about 9.5 TFLOP/s but were only 17% of the time;
- converting their uint16 outputs back to float (mostly the 416 × 21504 gate/up output) took 32%;
- element-wise ops (Mul, Abs, Div, Add) took 40%.

On a single layer's gate/up product with SiLU, viewing the activations as 13 blocks of 32 rows ([13, 32, c]) took
3.5 ms, against 18.0 ms for [416, c] and 4.1 ms with fp16 weights. So the graphs keep the residual stream in blocks,
with a 2-D view only around each projection. The prompt now takes 199 ms (`../evo1` found the same about tensor
shapes on the X Elite's HTP). Compiling the 5 prefill parts takes 4 minutes, and the decode parts and the head
1 minute, once. Loading the prefill contexts takes 3.1–3.4 s per process.

## Checks

`reference.py` runs transformers' own LFM2 one decoder layer at a time in fp32:
- the embedding lookup, `Lfm2RotaryEmbedding` and `create_causal_mask`;
- every `Lfm2DecoderLayer` (its `Lfm2ShortConv` or `Lfm2Attention`, `Lfm2MLP`, `Lfm2RMSNorm`s);
- the final norm and the tied head.

It runs either weight set:
- **`--weights gguf`:** the GGUF dequantized as ggml does, or rounded to fp16 for the f16 storage;
- **`--weights fp32`:** the QAD fp32 checkpoint, read layer by layer from Hugging Face by range request. That is
  10.8 GB a pass; the Mac had 6 GB of disk free.

`--selftest` checks the driver against transformers' whole `Lfm2ForCausalLM` on a tiny random model with conv and
attention layers. It matches to 2.4e-7, and so does transformers' incremental decode with its conv state and KV
cache.

- **Stage by stage** (`LFM2_DUMP`, the 20-token sky prompt): the phone's residual stream after the embedding and
  after each of the 30 layers. Against the reference on the GGUF's weights, it is exact after the embedding and
  within 4.0e-6 (relative) after every layer.
- **`run.py --check`** pulls 16 rows of the phone's logits and compares them with the reference on the same weights.
  It also checks every generated token against the reference's argmax, teacher-forced on the phone's tokens.
- **The NPU graphs** first ran on the Mac's CPU (`export_npu.py check`, ONNX Runtime) against PyTorch with the w8
  weights and with the GGUF's.
- **`fp32_check.py`** runs every recorded run against the fp32 model in one streamed pass (14 minutes), then
  computes greedy agreement and KL(fp32 ‖ phone) at the positions whose logits the phone wrote. It does the same
  for the GGUF's own int4 model in transformers.

The output (all four rows begin with the model's reasoning, as its chat template opens a `<think>` block):

> GPU rows and GPU+NPU: "The user wants an answer to a specific question based on the provided passage. The
> question has two parts: 1. Why is reading a prompt faster than generating text? 2. What do matrix units add?
> Constraint: Answer in exactly three sentences. Let's analyze the passage for the answers. Part 1: Why is"

> All-NPU: "The question asks two things: 1. Why is reading a prompt faster than generating text? 2. What do matrix
> units add? I need to answer in three sentences. Let me find the relevant information in the passage. For the
> first part (why reading a prompt is faster): - "Generating text one token at"

All-NPU's tokens differ from the int4 model's at its second token: teacher-forced, 63 of its 64 tokens are that
model's argmax. Against fp32 it agrees at 62 of 64, more often than the GPU rows (61).

## Run it

```bash
PY=build/vla/venv/bin/python
$PY lfm2/export.py                            # build/lfm2/{q4,f16,npu}: recipes, manifests; rope.f32
$PY lfm2/reference.py --selftest
cc -O2 -ffp-contract=off -o build/lfm2/bin/convert lfm2/convert.c
python3 android/build.py lfm2                  # build/android/lfm2: lfm2, lfm2_convert, MAX's runtime
D=/data/local/tmp/lfm2
adb push build/android/lfm2 $D/
adb push build/lfm2/rope.f32 $D/
adb push build/lfm2/q4/manifest.txt build/lfm2/q4/recipe.txt $D/q4/          # likewise f16/, npu/
adb shell "cd $D; curl -sSL -o qad_q4_0.gguf https://huggingface.co/LiquidAI/LFM2.5-2.6B-GGUF/resolve/e7caca5d835a3901a8e0d63e94009429bafafdfc/LFM2.5-2.6B-QAD-Q4_0.gguf"
adb shell "cd $D/q4; $D/lfm2/lfm2_convert $D/qad_q4_0.gguf recipe.txt lfm2_q4.bin"        # likewise f16, npu
$PY lfm2/run.py --prompt-file lfm2/prompts/long.txt --prefill --check --name q4_long_prefill            # GPU optimized
$PY lfm2/run.py --storage f16 --prompt-file lfm2/prompts/long.txt --prefill --check --name f16_long_prefill  # baseline

# NPU: graphs, then graph_tool and the two programs with QNN and ONNX Runtime in $D/qnn
PYTHONPATH=build/npu/pydeps:<a dir with ml_dtypes> $PY lfm2/export_npu.py calibrate   # build/lfm2/npu/calib.json
PYTHONPATH=... $PY lfm2/export_npu.py export && PYTHONPATH=... $PY lfm2/export_npu.py check
python3 npu/build.py graphtool lfm2npu lfm2hybrid
adb push build/npu/phone/{graph_tool,lfm2_npu,lfm2_hybrid,libonnxruntime.so,libQnn*.so,lib*Runtime*.so,libM*.so,libc++_shared.so} $D/qnn/
adb push build/lfm2/npu/*.onnx $D/npu/
lfm2/compile_npu.sh p0 p1 p2 p3 p4 head d0 d1 d2 d3 d4
$PY lfm2/run.py --config hybrid --prompt-file lfm2/prompts/long.txt --check --name hybrid_long     # GPU+NPU
$PY lfm2/run.py --config npu --prompt-file lfm2/prompts/long.txt --check --name npu_long           # all-NPU
$PY lfm2/fp32_check.py                                                      # every run against fp32 (streamed)
```

## Follow-ups

- **GPU prefill in fp16.** The int4 products are nearly all of the GPU's prompt time, on fp32 cooperative matrices
  at 1.55 TFLOP/s. The 840's fp16 product is about twice that, but it has fp16 accumulators only.
- **GPU decode.** The int4 matrix-vector kernels read at 46–61 GB/s, where fp16 reaches 62. Wider loads or several
  rows a workgroup might close that, about 5 ms a token.
- **NPU decode with 4-bit weights** would read half the bytes. On this stack, block-quantized int4 is slow or does
  not build (`../npu`), and per-channel int4 is far coarser than Q4_0.
- **One set of NPU weights** for the prefill and decode graphs (QNN weight sharing) would remove all-NPU's 2.5 s
  handoff.

## Files

| File | |
|---|---|
| `gguf_read.py` | a minimal GGUF reader: metadata and tensor table |
| `weights.py` | the GGUF's tensors dequantized as ggml does (by transformers' names), and the fp32 checkpoint by range request |
| `reference.py` | transformers' LFM2 layers one at a time on either weight set; `--selftest` against `Lfm2ForCausalLM` |
| `export.py` | the q4, f16 and npu files' layouts (`recipe.txt`, `manifest.txt`) and the RoPE table |
| `convert.c` | the GGUF to those files, on the phone or the Mac (the same bytes) |
| `kernels/lk.mojo` | the GPU kernels: int4 / fp16 / Q6_K matrix-vector products, short convolution, q/k norms + RoPE, attention, norms, prefill products |
| `model.mojo`, `lfm2.mojo` | the model (`step`, `prefill`) and the program |
| `run.py` | tokenize, run a configuration on the phone, check against the reference |
| `export_npu.py` | calibration, the NPU graphs, their CPU check |
| `npu_lfm2.cpp` | the NPU side: prefill, handoff, decode (`lfm2_npu` with `-DLFM2_NPU_MAIN`) |
| `hybrid.mojo` | NPU prefill, GPU decode |
| `compile_npu.sh` | compile the graphs on the phone |
| `fp32_check.py` | every run against the fp32 model |
| `prompts/long.txt` | the 415-token prompt |
