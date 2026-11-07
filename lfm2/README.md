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
| **GPU optimized**: Adreno 840, int4 matrix-vector kernels, prefill on fp32 cooperative matrices | the GGUF's own Q4_0 + Q6_K head, 1.59 GB | 1.30 s (**319 tokens/s**) | **27.5 ms/token** | logits within 1.1e-4; 64 of 64 | 61 of 64, KL 0.059 |
| **GPU+NPU**: prefill on the Hexagon NPU (HTP), decode on the Adreno 840 | NPU: int8 w8a16 + fp16 down projections, 3.4 GB; GPU: Q4_0 | **199 ms (2,084 tokens/s)**; + 81 ms handoff | **27.5 ms/token** | 64 of 64 (KL 2.5e-4) | 61 of 64, KL 0.060 |
| **All-NPU**: Hexagon NPU (HTP) | w8a16 + fp16 down projections, 3.4 GB | **198 ms (2,096 tokens/s)**; + 2.47 s handoff | **53.6 ms/token** | 63 of 64 (KL 3.8e-4) | 62 of 64, KL 0.068 |

With Liquid AI's DSpark drafter (speculative decoding, [below](#speculative-decoding-with-dspark)), the GPU decodes the
same 64 tokens at **19.9 ms a token (50.2 tokens/s), 1.38× faster** than its plain 27.5.

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
- **Decode:** memory-bound everywhere. Each token reads the weights once: 1.59 GB in 27.5 ms on the GPU (58 GB/s),
  5.4 GB of fp16 in 86.7 ms (62 GB/s), and 3.36 GB in 53.6 ms on the NPU (63 GB/s). So the GPU with 4-bit weights
  decodes 2.0× faster than the NPU, whose fast path needs 8-bit weights.
- **Handoffs:** GPU+NPU's 81 ms is releasing the NPU's contexts (75 ms) and copying 8 layers' K/V and 22 conv states
  into the GPU (7 ms). The GPU's weights then load in 1.2 s, not counted, as in `../npu`'s Qwen3 run: the two models
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
Llama and Gemma 4. Its products are 1.25 of the 1.39 s that `LFM2_PROFILE=prefill` measures (gate/up 0.64 s, down
0.36 s), attention 0.07 s. Two tries did not help:
- fetching the next k step into registers during the products (double buffering): 1.33 s;
- skipping the 64-row tiles past the prompt (415 rows pad to 512 in 128-row blocks): 1.40 s, as a branch around the
  products slows every tile more than the skipped rows save.

Where a decode step went (`LFM2_PROFILE=1`: a wait after each launch, so about 0.2 ms of waiting each), with the first
int4 kernels, which read a word (8 weights) a lane a step; a normal step was 31.2 ms:

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

Net of the waits, those int4 matrix-vector kernels read their weights at 46–61 GB/s, where the fp16 ones reach
62 GB/s. Reading a block of 32 weights (16 bytes and its scale) a lane a step instead (`dot_q4b`, now the default;
`LFM2_GEMV=word` for the first ones) brought a step from 31.2–32.7 to 27.4–28.9 ms (58 GB/s), with the same results.

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

## Speculative decoding with DSpark

[`LiquidAI/LFM2.5-2.6B-DSpark`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-DSpark) (revision `458cedab`, license
`lfm1.0`, not gated) is Liquid AI's drafter for this model: 327.7M parameters in bf16, 655 MB, which the phone downloads
itself (SHA-256 `a464fec8…`) and reads in place. With it the GPU decodes the same tokens 1.38× faster. Three runs of
each, interleaved, each after the phone had been idle 20 s, and no other process on it during the run:

| | Plain greedy decode (GPU optimized) | With the DSpark drafter |
|---|---|---|
| Decode, 64 tokens after the 415-token prompt | 27.52, 27.77, 27.53 ms/token (36.3 tokens/s) | **19.92, 19.90, 19.91 ms/token (50.2 tokens/s)** |
| Target passes | 63 | 14 (4.5 tokens a pass) |
| Prompt | 1.30 s | 1.39 s (+85 ms: the drafter's context of the 415 rows) |
| GPU memory | 1.59 GB | + 0.68 GB drafter, + 0.33 GB an int8 copy of the head |
| Tokens | 64 | the same 64, in all six runs |

**How it works**, from SGLang's implementation (sgl-project/sglang#31041: `models/dspark.py`, `models/dflash.py`,
`speculative/dspark_components`); `dspark_ref.py` is the same in PyTorch:
- **Context.** The drafter reads the target's residual stream after layers 2, 9, 17, 21 and 27 (5 × 2048 values a
  position), projects it (`fc`, 10240 → 2048, then an RMSNorm) and keeps, in each of its 5 attention layers, the K
  (k_norm, then RoPE on interleaved pairs, θ 10⁷) and V of every committed position.
- **A draft.** The anchor (the target's newest token, not yet through the target) and 8 mask tokens (id 125017), at
  positions p … p + 8, go through the drafter's layers, attending to its context and to the whole block (not causal).
  Row j's final hidden state through the target's tied head gives base logits for position p + j + 1. The Markov
  head adds W₂ W₁[previous token] (rank 256) for the anchor, then each draft in turn, and greedy picks d_j.
- **The check.** The target runs the anchor and the drafts as one batch (`model.verify`). A draft is accepted while
  it equals the target's argmax at its position, and the target's argmax after the last accepted one is the next
  anchor. So the output is exactly greedy decode's. The conv layers' states are rewound to the last accepted position
  from the B ⊙ x values the pass kept (`dsk.conv_commit`); K/V rows past it are overwritten later. The accepted rows'
  taps go into the drafter's context.
- **7 drafts a step** (`LFM2_DSPARK_DRAFTS`, up to 9). The block is always 9 rows, as the drafter was trained, but only 7
  go through the head, the Markov steps and the check. That makes the check 8 rows, which fits the cheaper 2-slot
  products below. On this prompt it still takes 14 passes.

**Checks.** `dspark_ref.py --simulate` drafts at every anchor along a recorded greedy run (one target pass gives every
position's taps): 0, 1, 1, 6, 4, 5, 8, 5, 2, 3, 3, 6, 5 drafts accepted (4.57 tokens a pass). The phone's drafter, with
9 drafts a step, accepted exactly those counts at each of those 13 steps, and its output was greedy decode's 64
tokens.

**Products for a few rows.** A check multiplies every weight by 8 rows instead of 1. Each design was timed alone on
gate/up's shape (21504 × 2048, int4 Q4_0, random weights, 8 rows; `bench_rows.mojo`):

| Design | ms | |
|---|---|---|
| decode's matrix-vector kernel, 1 row | 0.38 | 66 GB/s: the memory's rate |
| cooperative matrices, weights as M (64) and rows as N (16) | 2.35 | each lane unpacks its weights into shared memory for an N of only 16: staging alone took 2.0 ms |
| a lane a weight row, x by broadcast loads | 2.55 | row-strided weight loads: 1.95 ms even for 1 row |
| 64 lanes across k, 2 weight rows a workgroup | 1.42 | x re-read from cache for every 2 rows |
| **8 weight rows a workgroup; 4 groups of 16 lanes split x's rows; FMA chains** (`dsk.rows_q4`) | **0.69** (2 x slots, ≤ 8 rows), 0.83 (3 slots, ≤ 12) | each x element loaded once a workgroup, each weight unpacked once a group |

Holding more in registers (16 weight rows, or 2 groups with 5 x rows each) was slower. The head's few-row product reads
an int8 copy of the Q6_K head (`dsk.q6_to_q8`: q − 32 and the fp32 scale d·sc per 16, the same weights), as Q6_K's
unpacking cost more than its bytes: 7.7 ms a call against 10.5.

Where a step goes (`LFM2_PROFILE=verify`: a wait after each launch, about 0.2 ms each, so the parts add up to more than
a normal step's 89.6 ms):

| Draft | ms | Check (8 rows) | ms |
|---|---|---|---|
| the 5 layers' products (bf16) | 13.1 | int4 products (gate/up 27.5, down 19.9, in_proj 10.2, out_proj 7.2, q/k/v 2.8, o 2.7) | 70.2 |
| q/k norms, RoPE, attention | 5.7 | residual adds + norms | 16.5 |
| head (7 rows) | 7.7 | head (8 rows) | 7.7 |
| 7 Markov steps (each reads W₂, 65 MB) | 10.0 | short convolutions, attention | 10.8 |
| **all** | **38.7** | **all** | **106.1** |

```bash
build/vla/venv/bin/python lfm2/dspark_ref.py --export         # build/lfm2/dspark/manifest.txt, from model.safetensors there
lfm2/stage_phone.sh gpu dspark                                 # the phone downloads the GGUF and the drafter
D=/data/local/tmp/lfm2
adb shell "cd $D; LD_LIBRARY_PATH=$D/lfm2 MODULAR_DRIVER_PLUGINS=vulkan@$D/lfm2/libM_driver_vulkan.so LFM2_PREFILL=1 LFM2_WARM=1 LFM2_DSPARK=$D/dspark ./lfm2/lfm2 $D/q4 $D/q4/lfm2_q4.bin 64 @$D/runs/ids_long.txt"
build/vla/venv/bin/python lfm2/dspark_ref.py --simulate build/lfm2/runs/q4_long_prefill.json   # acceptance, on the Mac
python3 android/build.py lfm2bench                             # bench_rows: the few-row products above
```

## Against Pipette (Liquid AI's on-device benchmark)

[Pipette](https://pipette.liquid.ai) publishes LFM2.5-2.6B on a Galaxy S26 Ultra (Snapdragon 8 Elite Gen 5, SM8850,
12 GB) with llama.cpp b11988 on the CPU (4 threads, flash attention off). `pipette.py` measures our configurations by
its protocol, from Pipette's own weights file, `LFM2.5-2.6B-Q4_0.gguf` (SHA-256 `e1a61bf9…`, not the QAD file above),
staged in `$D/plain`, on two phones with the same chip:

- **The Galaxy Z Fold SM-F976U** (Samsung Remote Test Lab, build `CP2A.260605.016.F976USQU1AZGI`), a retail phone
  like Pipette's: every point up to 2,048 input tokens. The lab dropped it as the 4,096-token point began.
- **An SM8850 QRD** (Qualcomm Device Cloud's "Canoe" reference phone, Android 16 userdebug, 24 GB): the 4,096-token
  points, DSpark, and the other lengths down to 512 tokens (all-NPU down to 1,024) before its session ended.
  It has no internet, so the Mac pushed it the GGUF and the drafter (the same SHA-256s).

The protocol:
- **Prompts** are synthesized to an exact token count: the start-of-text token, then the repo's long passages
  (`gemma4/prompts/long.txt`, `llama/prompts/long.txt`, then `BLOG.md` and `BLOG-COOPMAT.md`), cut. Each shorter
  prompt is a prefix of the longer; greedy decoding.
- **TTFT** is the prefill time, as on Pipette's dashboard; **prefill** is the prompt's tokens over it.
- **Decode** is outputs 1 … 100 of an N → 256 run (for DSpark, a separate N → 100 run), over their time.
- **E2E** runs from the start of the prefill to the 256th output token, with every handoff: for GPU + NPU, releasing
  the NPU and loading the GPU's weights (1.3–1.8 s, which the tables above leave out); for all-NPU, the context swap.
- **5 repetitions** per point, mean ± sample standard deviation, warm-up and model loading excluded. Before each: no
  other model process on the phone and 20 s idle. On the Fold the battery is at or below 31 °C. The QRD's battery
  reads a fixed 39.0 °C (a bench supply), so it waits for its GPU's thermal zone (`gpuss-0`) to reach 45 °C (28 °C
  idle, about 60 °C after a run). Without that wait the QRD's GPU decode at 4,096 tokens swung from 21.5 to 32.6
  tokens/s between repetitions; with it, 33.0 ± 0.1. A repetition that overlapped another model process was
  discarded and repeated.
- **Peak RAM** is one N → 1 run: the process's resident high-water mark plus swap (what Pipette counts on Android),
  and, apart, the GPU's page allocations above idle (kgsl `page_alloc`; GPU buffers are outside VmHWM). The programs
  print it before exiting, with every buffer still held. On the Fold, GPU + NPU's figures were only sampled once a
  second from the Mac, which missed the GPU's weights at the end of the run, so the table gives the QRD's.

The NPU graphs are a set of their own for these lengths (`export_npu.py export-sweep`, beside the QAD set's 416 rows
and 512 slots):
- up to 1,024 tokens, one-pass prefill graphs of the prompt's own length (`r256_p*`, `r512_p*`, `p*`) and decode
  graphs with 1,280 cache slots (`d*`);
- beyond, 512-row prefill chunks, each after up to 3,584 earlier positions (`c_p*`), and decode graphs with 4,352
  slots (`dl_d*`: 4,096 prompt tokens and 256 outputs).

At 1,024 input tokens:

| Device, engine | Quant | Decode (1024→100) | Prefill (1024) | TTFT (1024) | E2E (1024→256) | Peak RAM |
|---|---|---|---|---|---|---|
| Galaxy S26 Ultra, llama.cpp CPU (Pipette) | q4_0 | 34 tok/s | 150 tok/s | 6,844 ms | 13,995 ms | 1.87 GB |
| Galaxy S26 Ultra, llama.cpp CPU (Pipette) | q4_k_m | 31 tok/s | 104 tok/s | 9,864 ms | 17,593 ms | 1.95 GB |
| Galaxy S26 Ultra, llama.cpp CPU (Pipette) | q5_k_m | 22 tok/s | 79 tok/s | 12,998 ms | 24,120 ms | 2.20 GB |
| iPhone 17 Pro, llama.cpp GPU (Pipette) | q4_0 | 39 tok/s | 967 tok/s | 1,059 ms | 7,687 ms | 1.86 GB |
| Galaxy Z Fold SM-F976U, Mojo, Adreno 840 GPU (int4) (ours) | q4_0 | 34.7 ± 0.8 tok/s | 368 ± 6 tok/s | 2,787 ± 47 ms | 10,560 ± 324 ms | 1.55 GB host + 2.14 GB GPU |
| SM8850 QRD (Qualcomm Device Cloud), Mojo, Adreno 840 GPU (int4) (ours) | q4_0 | 36.7 ± 0.1 tok/s | 336 ± 0 tok/s | 3,047 ± 2 ms | 10,034 ± 6 ms | 1.55 GB host + 2.14 GB GPU |
| Galaxy Z Fold SM-F976U, Mojo GPU + Hexagon NPU prefill (w8a16) (ours) | q4_0 | 35.4 ± 0.3 tok/s | 1545 ± 60 tok/s | 664 ± 27 ms | 9,939 ± 475 ms | not caught (see the QRD) |
| SM8850 QRD (Qualcomm Device Cloud), Mojo GPU + Hexagon NPU prefill (w8a16) (ours) | q4_0 | 37.0 ± 0.6 tok/s | 1654 ± 15 tok/s | 619 ± 6 ms | 8,382 ± 157 ms | 1.68 GB host + 1.88 GB GPU |
| Galaxy Z Fold SM-F976U, Hexagon NPU (w8a16) (ours) | q4_0 | 18.2 ± 0.1 tok/s | 1587 ± 85 tok/s | 647 ± 36 ms | 17,423 ± 445 ms | 0.69 GB host + 0.00 GB GPU |
| SM8850 QRD (Qualcomm Device Cloud), Hexagon NPU (w8a16) (ours) | q4_0 | 19.6 ± 0.0 tok/s | 1655 ± 5 tok/s | 619 ± 2 ms | 15,030 ± 646 ms | 0.69 GB host + 0.00 GB GPU |
| SM8850 QRD (Qualcomm Device Cloud), Mojo GPU (int4) + DSpark speculative decoding (ours) | q4_0 | 24.0 ± 0.1 tok/s | 318 ± 1 tok/s | 3,218 ± 10 ms | 10,109 ± 20 ms | 2.29 GB host + 3.24 GB GPU |

The sweep (Pipette's line is its leaderboard's data for the S26 Ultra's CPU, q4_0):

| Input tokens | Phone | llama.cpp CPU (Pipette, S26 Ultra): TTFT, decode, E2E (→256) | GPU (int4): TTFT, decode, E2E (→256) | GPU + NPU prefill: TTFT, decode, E2E (→256) | NPU: TTFT, decode, E2E (→256) |
|---|---|---|---|---|---|
| 256 | Galaxy Z Fold SM-F976U | 1,388 ms, 36.6 tok/s, 8,579 ms | 703 ms, 36.4 tok/s, 7,961 ms | 109 ms, 35.7 tok/s, 9,177 ms | 111 ms, 17.7 tok/s, 17,568 ms |
| 512 | Galaxy Z Fold SM-F976U | 2,937 ms, 35.0 tok/s, 10,290 ms | 1,334 ms, 36.1 tok/s, 8,913 ms | 226 ms, 35.9 tok/s, 9,556 ms | 208 ms, 18.3 tok/s, 16,942 ms |
| 512 | SM8850 QRD (Qualcomm Device Cloud) | 2,937 ms, 35.0 tok/s, 10,290 ms | 1,451 ms, 37.2 tok/s, 8,329 ms | 211 ms, 37.1 tok/s, 7,934 ms |  |
| 1,024 | Galaxy Z Fold SM-F976U | 6,844 ms, 34.0 tok/s, 13,995 ms | 2,787 ms, 34.7 tok/s, 10,560 ms | 664 ms, 35.4 tok/s, 9,939 ms | 647 ms, 18.2 tok/s, 17,423 ms |
| 1,024 | SM8850 QRD (Qualcomm Device Cloud) | 6,844 ms, 34.0 tok/s, 13,995 ms | 3,047 ms, 36.7 tok/s, 10,034 ms | 619 ms, 37.0 tok/s, 8,382 ms | 619 ms, 19.6 tok/s, 15,030 ms |
| 2,048 | Galaxy Z Fold SM-F976U | 15,025 ms, 26.7 tok/s, 22,124 ms | 5,991 ms, 33.2 tok/s, 14,605 ms | 3,325 ms, 33.5 tok/s, 13,636 ms | 3,368 ms, 15.1 tok/s, 24,175 ms |
| 2,048 | SM8850 QRD (Qualcomm Device Cloud) | 15,025 ms, 26.7 tok/s, 22,124 ms | 6,588 ms, 35.4 tok/s, 13,817 ms | 3,237 ms, 35.3 tok/s, 11,409 ms | 3,226 ms, 16.6 tok/s, 20,129 ms |
| 4,096 | SM8850 QRD (Qualcomm Device Cloud) | 36,442 ms, 22.7 tok/s, 44,139 ms | 14,850 ms, 33.0 tok/s, 22,593 ms | 6,534 ms, 32.9 tok/s, 15,263 ms | 6,466 ms, 16.6 tok/s, 23,225 ms |

What the numbers say:
- **Time to first token.** The GPU reads the prompt 2.0–2.5× faster than llama.cpp on the S26 Ultra's CPU at every
  length: 703 against 1,388 ms at 256 tokens, 14.9 against 36.4 s at 4,096. The NPU reads it 10–14× faster up to
  1,024 tokens (109 ms at 256, 0.62–0.66 s at 1,024), where one graph takes the whole prompt. Beyond that, each
  512-row chunk attends over all 3,584 past slots, filled or not: 2,048 tokens take 3.3 s (4.5×) and 4,096 take
  6.5 s (5.6×).
- **Decode** is bound by memory bandwidth on the CPU and the GPU alike. Up to 1,024 tokens the GPU matches
  llama.cpp's CPU (34.7 against 34.0 tokens/s), but it slows less as the context grows: 33.2 against 26.7 at 2,048,
  and 33.0 against 22.7 at 4,096.
  LFM2 has attention in 8 of its 30 layers, so the cache adds little to what each token reads: at 4,096 tokens,
  134 MB beside the weights' 1.59 GB. All-NPU decodes at half the GPU's rate (17.7–19.6 tokens/s, and 15.1–16.6 with
  the 4,352-slot graphs), because its int8 weights are 3.36 GB a token.
- **End to end** (to the 256th output token), GPU + NPU is best from 1,024 tokens on:
  - 9.9 s against 14.0 s (1.41×) on the Fold, and 8.4 s on the QRD;
  - 13.6 against 22.1 s at 2,048 (1.62×), and 11.4 s on the QRD;
  - 15.3 against 44.1 s at 4,096 (2.9×).

  At 256 and 512 tokens the GPU alone is best (7.96 and 8.91 s: 1.08× and 1.15×). GPU + NPU's E2E includes loading
  the GPU's weights after the NPU's prefill, 1.3–1.8 s on the Fold, more than its faster prefill saves on a short
  prompt. The same load takes 0.8–1.0 s on the QRD, likely because its 24 GB keep the weights file cached, so there
  GPU + NPU is already best at 512 tokens (7.93 against 8.33 s). All-NPU's
  E2E is longer than llama.cpp's up to 2,048 tokens (half the decode rate, plus a 1.1–2.7 s context swap) and 1.9×
  shorter at 4,096.
- **Against Pipette's iPhone 17 Pro** (llama.cpp on its GPU, 1,024 tokens: TTFT 1,059 ms, decode 39 tokens/s, E2E
  7,687 ms), GPU + NPU's first token comes sooner (619–664 ms). Its E2E is longer (8.4–9.9 s), because of the weight
  load in the handoff and a slower decode.
- **DSpark** (QRD, 1,024 tokens) decodes outputs 1–100 at 24.0 tokens/s, against 36.7 without it. On this prompt
  (a passage to continue, not a chat question) the drafter averages 2.6 tokens per target pass (4.5 on the chat
  prompt above), too few to pay for its steps. Its later outputs go better: E2E is 10.1 s, the same as plain
  decoding's 10.0 s. Its TTFT includes the drafter's context of the prompt (+171 ms).
- **The two phones:** the QRD's GPU prefill is 9–10% slower than the Fold's at every length both ran (3,047 against
  2,787 ms at 1,024 tokens), and its decode 3–10% faster in every configuration. The chip is the same; the driver
  and firmware builds are not.
- **Peak RAM.** By Pipette's measure (VmHWM + swap), the GPU configuration holds 1.55 GB, under llama.cpp's
  1.87 GB. But 1.50 GB of that is the mapped weights file. The GPU's own pages are outside it: 2.14 GB for the
  weights, an 8,192-position cache and the prefill's buffers. All-NPU's 0.69–0.89 GB leaves out its HTP contexts in
  the same way.
- **LFM2.5-8B-A1B**, Liquid AI's mixture of experts (1.5B of its 8.5B parameters active), is measured the same way in
  [`../lfm2moe/README.md`](../lfm2moe/README.md#lfm25-8b-a1b-against-pipette-liquid-ais-on-device-benchmark): on the
  GPU, 3.39 s to the first token and 8.26 s end to end at 1,024 tokens, against llama.cpp's 10.66 and 15.18 s.

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

# Against Pipette (pipette.py): Pipette's own Q4_0 file, staged apart in $D/plain; the NPU's graph set for 256-4,096
B=build/lfm2/plain; X="LFM2_GGUF=$B/LFM2.5-2.6B-Q4_0.gguf LFM2_NPU_DIR=$B/npu LFM2_R=1024 LFM2_C=1280"
env LFM2_GGUF=$B/LFM2.5-2.6B-Q4_0.gguf LFM2_OUT=$B LFM2_CAP=8192 $PY lfm2/export.py   # $B/{q4,npu}, rope.f32
env $X PYTHONPATH=... $PY lfm2/export_npu.py calibrate && env $X PYTHONPATH=... $PY lfm2/export_npu.py export
env $X PYTHONPATH=... $PY lfm2/export_npu.py export-sweep                     # r256_p*, r512_p*, c_p*, dl_d*
adb shell "mkdir -p $D/plain/q4 $D/plain/npu; cd $D/plain; curl -sSL -o q4_0.gguf https://huggingface.co/LiquidAI/LFM2.5-2.6B-GGUF/resolve/e7caca5d835a3901a8e0d63e94009429bafafdfc/LFM2.5-2.6B-Q4_0.gguf"
adb push $B/rope.f32 $D/plain/ && adb push $B/q4/manifest.txt $B/q4/recipe.txt $D/plain/q4/
adb push $B/npu/manifest.txt $B/npu/recipe.txt $B/npu/*.onnx $D/plain/npu/
adb shell "cd $D/plain/q4; $D/lfm2/lfm2_convert $D/plain/q4_0.gguf recipe.txt lfm2_q4.bin"   # likewise npu_w8.bin in npu/
NPU_DIR=$D/plain/npu lfm2/compile_npu.sh p0 p1 p2 p3 p4 head d0 d1 d2 d3 d4   # and the r256_p*, r512_p*, c_p*, dl_d* graphs
for n in 256 512 1024 2048 4096; do $PY lfm2/pipette.py gpu hybrid npu --input $n; done   # build/lfm2/pipette/<config>_<n>.json
$PY lfm2/pipette.py spec --input 1024
PIPETTE_OUT=build/lfm2/pipette/qrd PIPETTE_ZONE=gpuss-0 PIPETTE_TEMP_MAX=45 $PY lfm2/pipette.py ...   # another phone
$PY lfm2/pipette.py --table                                                  # the tables above
```

## Follow-ups

- **GPU prefill in fp16.** The int4 products are nearly all of the GPU's prompt time, on fp32 cooperative matrices
  at 1.55 TFLOP/s. The 840's fp16 product is about twice that, but it has fp16 accumulators only.
- **GPU decode.** The int4 matrix-vector kernels read at 58 GB/s, where fp16 reaches 62. Fewer launches (60 of the
  222 are single-workgroup norms and residual adds) might close part of that.
- **NPU decode with 4-bit weights** would read half the bytes. On this stack, block-quantized int4 is slow or does
  not build (`../npu`), and per-channel int4 is far coarser than Q4_0.
- **One set of NPU weights** for the prefill and decode graphs (QNN weight sharing) would remove all-NPU's 2.5 s
  handoff.
- **A cheaper DSpark step.**
  - The 7 Markov steps read the 65 MB W₂ in bf16 each time, and the drafter's layers are bf16 too. int8 copies would
    halve both, but the drafts would then differ slightly from the reference.
  - The confidence head (unused here) could pick each step's number of drafts.
  - The down projection's few-row product runs only 256 workgroups. Splitting k would raise that.
- **NPU prefill chunks over the filled past only.** Each 512-row chunk attends over all 3,584 past slots, filled or
  not: at 2,048 tokens a chunk takes about 830 ms, against 226 ms for the one-pass 512-row graph. Chunk graphs for a
  few past lengths (512, 1,536, 2,560, 3,584) would recover most of that.
- **The weights file outside the resident peak.** The GPU program maps the whole 1.59 GB file to upload it, and
  that is 1.50 GB of the 1.55 GB that Pipette's measure counts. Reading it in pieces would leave about 0.1 GB.
- **GPU + NPU on short prompts.** At 256 and 512 tokens, loading the GPU's weights after the NPU's prefill (1.3–1.8 s
  on the Fold) costs more than the faster prefill saves. Loading them during the prefill needs both in memory at
  once, which the 416-row contexts did not allow on the Fold.

## Files

| File | |
|---|---|
| `gguf_read.py` | a minimal GGUF reader: metadata and tensor table |
| `weights.py` | the GGUF's tensors dequantized as ggml does (by transformers' names), and the fp32 checkpoint by range request |
| `reference.py` | transformers' LFM2 layers one at a time on either weight set; `--selftest` against `Lfm2ForCausalLM` |
| `export.py` | the q4, f16 and npu files' layouts (`recipe.txt`, `manifest.txt`) and the RoPE table |
| `convert.c` | the GGUF to those files, on the phone or the Mac (the same bytes) |
| `kernels/lk.mojo` | the GPU kernels: int4 / fp16 / Q6_K matrix-vector products, short convolution, q/k norms + RoPE, attention, norms, prefill products |
| `model.mojo`, `lfm2.mojo` | the model (`step`, `prefill`, `verify`) and the program (`LFM2_DSPARK`: speculative decoding) |
| `run.py` | tokenize, run a configuration on the phone, check against the reference |
| `export_npu.py` | calibration, the NPU graphs, their CPU check |
| `npu_lfm2.cpp` | the NPU side: prefill, handoff, decode (`lfm2_npu` with `-DLFM2_NPU_MAIN`) |
| `hybrid.mojo` | NPU prefill, GPU decode |
| `compile_npu.sh` | compile the graphs on the phone |
| `fp32_check.py` | every run against the fp32 model |
| `dspark_ref.py` | the DSpark drafter in PyTorch (from SGLang's implementation); `--simulate` acceptance along a recorded run, `--export` its manifest |
| `dspark.mojo` | the drafter on the GPU: context cache from the target's taps, the block, the head and the Markov steps |
| `kernels/dsk.mojo` | speculative decoding's kernels: few-row int4 / bf16 / head products, the drafter's attention, Markov steps, conv-state rewind |
| `bench_rows.mojo` | the few-row products against the designs they replaced |
| `stage_phone.sh` | re-stage a wiped lab phone: the phone downloads the GGUF (and the drafter) and converts |
| `pipette.py` | Pipette's protocol on the phone: exact-token prompts, TTFT, decode, E2E, peak RAM; 5 repetitions with readiness waits; `--table` |
| `prompts/long.txt` | the 415-token prompt |
