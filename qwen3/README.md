# Ternary Qwen3-8B on the Adreno 840

PrismML's **Ternary-Bonsai-8B** (`prism-ml/Ternary-Bonsai-8B-mlx-2bit`, revision `9260b242`): Qwen3-8B
with every projection and the output head ternary (-1, 0, +1 times a scale per 128 weights), stored
as MLX 2-bit groups. 36 layers, hidden 4096, 32 query and 8 KV heads of 128, MLP 12288, vocabulary
151,669, YaRN RoPE. On the GPU it is 2.19 GB.

On Qualcomm's SM8850 reference phone (Adreno 840, driver 512.842.25, Qualcomm Device Cloud):

```
$ python qwen3/run.py --model OUT --hf CKPT
prompt: 'What is the capital of France?', 19 tokens; checking 16 steps
weights: 441 tensors, 2.19 GB in 0.7 s, context 128
plan: 615 dispatches per token
check  0: token    785 reference    785  max abs 0.006471  rel L2 0.00078932 OK
  ...
check 15: token  59108 reference  59108  max abs 0.008191  rel L2 0.00055052 OK
decode: 15 tokens, 40.5 ms/token (24.72 tokens/s)
validation: 16 steps, max abs logit error 0.008191, all greedy ids match
output: 'The capital of France is Paris.<|im_end|>\n\nParis is a city in the Î'

$ python qwen3/run.py --model OUT --hf CKPT --prompt 'Explain in two sentences why the sky is blue.' --tokens 96
decode: 56 tokens, 40.0 ms/token (24.99 tokens/s)
output: "The sky appears blue because sunlight, which contains all colors of the spectrum, is scattered more
efficiently by the atmosphere's molecules and small particles. This scattering, known as Rayleigh
scattering, is stronger for shorter wavelengths like blue and violet, making those colors more
prominent in the sky.<|im_end|>"
```

**25 tokens/s** for an 8B model: every token reads the 2.19 GB of weights, about 54 GB/s. All 16 checked
steps give MLX's greedy token, every one of the 151,669 logits within 0.0082. The prompt runs one
token at a time (about 38 ms a token); batched prefill would reuse `bonsai/kernels/prefill.mojo`'s
`p_gemm_t2`, whose weight layout this export already matches.

The projections run on the ternary kernels of the Bonsai 2 port (`bonsai/kernels/kernels.mojo`, from
mav3ri3k/modular, unchanged): `packed_linear` and `packed_reduce` for every layer projection (q/k/v
and gate/up fused), `packed_head` for the output head in two halves (each under 128 MB, the Adreno 710 driver's
buffer limit; this driver allows 2 GB). Qwen3 has no
Hadamard rotations, so its projection inputs are only packed into fp16 pairs. The rest is
[`kernels/qwen3k.mojo`](kernels/qwen3k.mojo): RMS norm (packing its output), q/k head norm with RoPE
and the KV-cache writes in one kernel, attention scores and values, SwiGLU (packing), residual add.
[`qwen3_vk.c`](qwen3_vk.c) records 615 dispatches per token once; the embedding row is dequantized on
the CPU each token.

[`export.py`](export.py) writes the weights in that layout, checks that every group is ternary (bias
== -scale), takes the RoPE table from MLX's own YaRN rope (cos | sin, its attention factor included),
and records MLX's FP32-activation logits as the reference.

```bash
python qwen3/export.py --checkpoint CKPT --output OUT --tokens 16 --capacity 128   # MLX venv
python3 qwen3/build_kernels.py
# push OUT/weights.bin, manifest.txt, reference.f32 to /data/local/tmp/q8, then
python qwen3/run.py --model OUT --hf CKPT                     # validate
python qwen3/run.py --model OUT --hf CKPT --prompt 'Explain in two sentences why the sky is blue.'
```

## In Mojo, through DeviceContext

[`model.mojo`](model.mojo) is `qwen3_vk.c`'s forward pass as MAX `DeviceContext` launches of the same
kernels, and [`qwen3.mojo`](qwen3.mojo) the program around it. It takes `qwen3_vk`'s arguments and
checks against the same reference (`QWEN3_REF`). Built for Android (`android/build.py qwen3`), it runs
through the Vulkan driver plugin (`driver/`). On a Galaxy S26 Ultra (stock driver):

```
weights: 441 tensors, 2.186006464 GB, context 128
check 0 : token 785 reference 785  max abs 0.006471  rel L2 0.00078932 OK
  ...
check 15 : token 59108 reference 59108  max abs 0.008191  rel L2 0.00055052 OK
decode: 15 tokens, 39.8 ms/token (25.1 tokens/s)
validation: 16 steps, max abs logit error 0.008191 , all greedy ids match
```

It is as fast as `qwen3_vk` and its logits are the same to 0.0082. `run.py --runner mojo --weights
model` runs it.

The weights came from Hugging Face to the phone directly. [`convert.cpp`](convert.cpp) is
`export.py`'s export in C++ and writes `weights.bin` and `manifest.txt` from the downloaded
checkpoint (SHA-256 `f43270cb…`) in seconds, byte for byte `export.py`'s. The exception is the 64 KB
RoPE table, which MLX computes and the Mac supplies (`rope.f32`, cut out of an export):

```bash
adb shell "cd /data/local/tmp/q8; curl -sSL -o model.safetensors https://huggingface.co/prism-ml/Ternary-Bonsai-8B-mlx-2bit/resolve/main/model.safetensors"
adb shell "cd /data/local/tmp/q8; ./qwen3_convert model.safetensors rope.f32 model"
```
