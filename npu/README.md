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

### Ternary Qwen3-8B: considered, not attempted

The HTP path above relies on fp16 weights, which Qwen3-8B cannot use. Its 8.2 B parameters are 16 GB in fp16,
beyond the phone's 11 GB of RAM, let alone the HTP's 32-bit address space per process. An int8 copy would still be
8 GB. The ternary weights (−1, 0, +1 times a scale per 128) are exactly representable as int4 with per-128 block
scales, about 4.1 GB. But the HTP runs int4 weights only against quantized activations (w4a16). That means:
- a QDQ graph with block-quantized int4 weights and uint16 activations calibrated per tensor;
- care with Qwen3's large activations;
- splitting into contexts of about 1 GB, as Qualcomm does for 8B models.

That is a quantization project of its own, so it is a follow-up rather than part of this experiment.

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
- **Quantized weights on the HTP:** w8a16 or w4a16 QDQ graphs would cut the HTP's weight traffic. They need
  calibrated activation ranges, and they would cost accuracy that this fp16 graph does not.
- **Ternary Qwen3-8B,** through the same quantized path (above).

## Files

| File | |
|---|---|
| `export.py` | the prefill graphs (`--fp32` for checking on the Mac, `--parts`, `--rows`) |
| `npu_prefill.cpp` | ONNX Runtime + QNN HTP (C interface): compile a part (`npu_compile`), load the compiled parts, prefill, K/V and logits out; `-DNPU_TOOL` builds `npu_tool` |
| `hybrid.mojo` | NPU prefill, handoff (timed one after the other and overlapped with the NPU's parts), GPU decode: the new entry point |
| `export_decode.py` | the decode graphs (one token against an fp16 KV cache of 512 positions; `--fp32` for the Mac) |
| `npu_decode.cpp` | all-NPU: `npu_prefill.cpp`'s prefill, then greedy decode through the decode graphs; `compile <dir> <i>` compiles one decode part |
| `build.py` | `tool`, `hybrid`, `decode`, `pi0tool` and `pi0` for the phone, with the ORT and QNN libraries staged next to them |
| `run.py` | reference in PyTorch, push, NPU K/V check (`--kv`), hybrid run, all-GPU baseline (`--baseline`), all-NPU run (`--all-npu`) |
| `export_pi0.py` | π0's Gemma 2B prefix as fp16 graphs in 6 parts, and the recipe for their `gemma.bin` ([`../pi0`](../pi0/README.md#the-prefix-on-the-hexagon-npu)) |
| `pi0_f16.c` | `gemma.bin` from π0's fp32 checkpoint (fp16), on the phone |
| `pi0_prefix.cpp`, `pi0_prefix.h` | π0's prefix through ONNX Runtime + QNN HTP (C interface for `pi0/pi0npu.mojo` on the phone, and for `vla/x2`'s `vk_server_npu.exe` on the X2 Elite laptop); `-DNPU_TOOL` builds `pi0npu_tool` (compile a part, time, dump K/V) |
| `pi0_check.py` | π0's prefix graphs on the Mac's CPU, or the phone's K/V dump, against PyTorch's cache |

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

On the phone, by hand (`D=/data/local/tmp/npu`, `M=/data/local/tmp/llama/model`):

```bash
adb shell "cd $D; LD_LIBRARY_PATH=$D:/system/lib64:/vendor/lib64 ./npu_tool compile $M 0"     # once per part, 0..3
adb shell "cd $D; LD_LIBRARY_PATH=$D:/system/lib64:/vendor/lib64 MODULAR_DRIVER_PLUGINS=vulkan@$D/libM_driver_vulkan.so ./hybrid $M $M 80 <token ids>"
```

`onnx` and `onnxruntime` (Mac) are installed with `uv pip install --target build/npu/pydeps`. The two AARs are
unpacked under `build/npu/dl/{ort,qnn}/x`.
