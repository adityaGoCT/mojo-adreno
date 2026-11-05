# vla/: what SmolVLA and π0 share

The two robot policies, [SmolVLA](../smolvla) and [π0](../pi0), have the same shape: a SigLIP vision encoder, a
language model run once over the prefix (images, task, and for SmolVLA the state), and an action expert that
denoises a 50-step action chunk in 10 Euler steps against the prefix's K/V cache. They share every GPU kernel and
the host code that launches them.

| File | What |
|---|---|
| `kernels/vgemm.mojo` | `gemm`: Y = act(X) Wᵀ (+ bias) (+ Y) on the 840's fp32 cooperative matrices, W in bf16 / fp16 / fp32, staged and widened in shared memory; any n and k (a multiple of 4). `gemm_sk` + `reduce_sk`: split-k for short X (64–256 rows), X straight from memory, W double-buffered. `gemm16` + `finish16`: the fp16 matrix units. |
| `kernels/vattn.mojo` | `attention`: flash-style attention, online softmax, Q Kᵀ and P V on cooperative matrices, one accumulator alive at a time; heads of 64, 72 (64 + 16 columns) or 256 (four chunks); masks as levels. |
| `kernels/vrow.mojo` | LayerNorm, RMSNorm (Llama's and Gemma's `1 + w`), patches, position embedding, SmolVLM's pixel shuffle, embedding rows, RoPE into the K/V cache (heads of 64 or 256), the time embedding's columns, the Euler step. |
| `host.mojo` | `Weights`: a checkpoint's tensors as device buffers (bf16 as stored, fp32 widened from bf16, or fp32 narrowed to bf16 when exact); `lin`: the projection launches; `attend`: the attention launches. |
| `safetensors.mojo` | the checkpoint's header, parsed on the phone: the program reads `model.safetensors` as Hugging Face serves it. |
| `check.mojo` | reading the PyTorch reference's tensors and comparing device buffers with them. |
| `test/` | `test_gemm.mojo`: the projection kernels against the CPU (`python3 vla/test/build_test.py`). |
| `x2/` | the same programs on a Snapdragon X2 Elite laptop's Adreno X2-90 (Windows on Arm), through the remote driver plugin and a Vulkan server ported to Windows: [x2/README.md](x2/README.md) |

The 840's driver shaped these kernels (see also [`../tuner`](../tuner) and the repo's notes):
- **One accumulator.** A subgroup may hold only one 64 × 64 fp32 accumulator. So attention never keeps S and O
  as matrices together: O lives in registers, one column a thread, and each block's P V passes through shared
  memory.
- **No accumulator from memory.** A multiply-add whose accumulator starts as a loaded matrix fails at pipeline
  creation. Biases go in as one more k step (X's column of ones times W's column of the bias), and residuals as
  identity × Y.
- **fp16 tiles.** fp16 shared-memory addressing is wrong, so `gemm16` reads fp16 tiles straight from memory.
  Converting an fp16 accumulator to fp32 crashes the driver's compiler, so `finish16` does it in a second kernel.
- **Prefetch.** Prefetching the next W slice into a register vector across `gemm_sk`'s loop made the kernel
  silently store nothing; it stages each slice when it is used instead.
- **Watchdog.** π0's prefix synchronizes after each layer: the plugin's 64-launch submissions of 832-row Gemma
  layers outlast the GPU watchdog.
