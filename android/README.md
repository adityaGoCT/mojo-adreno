# Mojo host code on the phone

With these programs the C runners are optional. Mojo code that uses MAX's `DeviceContext` is
compiled for Android ARM64, with its kernels as adreno840 SPIR-V inside. It runs on the phone and
launches on the Adreno through the Vulkan driver plugin ([`../driver`](../driver)):

```
Mojo host code (DeviceContext)  ->  MAX's HAL DeviceContext (Mojo)  ->  libM_driver_vulkan.so  ->  Vulkan
```

MAX's HAL `DeviceContext` is plain Mojo. It opens the plugin named in `MODULAR_DRIVER_PLUGINS`
itself, so the program needs only MAX's Mojo runtime, `libKGENCompilerRTShared.so`, cross-built for
Android.

## Build

```bash
python3 android/build.py runtime     # MAX's runtime for Android, and the plugin: build/android/runtime
python3 android/build.py vecadd      # build/android/vecadd/
python3 android/build.py llama       # build/android/llama/: llama/llama.mojo
python3 android/build.py qwen3       # build/android/qwen3/: qwen3/qwen3.mojo and qwen3_convert
python3 android/build.py bonsai      # build/android/bonsai/
```

Each step does the following:
- **runtime:** builds `//Mojo:CompilerRT` of the modular fork (`MOJO_SRC`, branch
  `adreno-spirv-target`) with Bazel's `--config=android-arm64` and the NDK (`ANDROID_NDK`). It adds
  NDK libc++ and `driver/libM_driver_vulkan.so`.
- **packages:** precompiles the fork's `std` and MAX's package with the HAL `DeviceContext` from
  source, together in about 20 s, whenever a source is newer. The HAL package is `max/mojo/max`,
  staged as `//max/mojo/max/_driver/max_license:max_srcs_hal` stages it. The host compiler in
  `bazel-bin` does this, not Bazel: the Android build's change to `Support/Log.h` would make Bazel
  rebuild that compiler.
- **programs:** compiles each program with `mojo build --emit object --target-triple
  aarch64-unknown-linux-android33 --target-accelerator adreno840` and links it with the NDK. The
  triple needs all four parts: Mojo's stdlib reads the OS, `linux`, from the third.

Each program's directory holds what it needs on the phone: the executable, the runtime libraries
(stripped of debug info) and the plugin, found through rpath `$ORIGIN`.

**Bonsai** is the Android port's own model, from mav3ri3k/modular's `max/examples/android-llm`
(`BONSAI_PORT`, 03de9211):
- `model.mojo`, its forward pass in `DeviceContext` launches;
- `kernels.mojo`;
- the C++ runner (`runner.cpp`, `engine.cpp`) for weights and sampling.

`model_runtime.mojo` and `engine.cpp` change only `"opencl"` to `"vulkan"`. Everything else is
the port's, unchanged.

## Run

```bash
D=/data/local/tmp/mojo/android
adb push build/android/vecadd $D/
adb shell "cd $D/vecadd; MODULAR_DRIVER_PLUGINS=vulkan@$D/vecadd/libM_driver_vulkan.so ./vecadd"
```

Bonsai's runner names the plugin itself, so it sets `MODULAR_DRIVER_PLUGINS`. It needs only the
prompt and the reference logits from `prepare.py`, which are 16 MB. The phone downloads the 1.2 GB
checkpoint from Hugging Face itself, in under a minute, instead of receiving `weights.bin` over a
remote device's adb bridge, which can take an hour. Then `bonsai_convert` (`bonsai/convert.cpp`)
writes `weights.bin` from it in seconds. It is `prepare.py`'s export in C++: all 604 weight tensors
are byte for byte the same, and the RoPE table is within 1 ulp.

```bash
D=/data/local/tmp/mojo/android/bonsai
adb push build/android/bonsai /data/local/tmp/mojo/android/
adb push $MODEL/prompt.txt $MODEL/reference.f32 $D/model/      # prepare.py's output
adb shell "cd $D; curl -sSL -o model.safetensors https://huggingface.co/prism-ml/Ternary-Bonsai-2-2B-mlx-2bit/resolve/1c6cbae21f8c38830ce337972b46fdae7b18eaaa/model.safetensors"
adb shell "cd $D; ./bonsai_convert model.safetensors model/weights.bin 128"
adb shell "cd $D; ./runner $D/libM_driver_vulkan.so model/weights.bin model/prompt.txt model/reference.f32 16"
adb shell "cd $D; ./runner $D/libM_driver_vulkan.so model/weights.bin model/prompt.txt benchmark 100"
```

## Results: Galaxy S26 Ultra (Adreno 840, stock driver)

`vecadd.mojo` is an ordinary `DeviceContext` program (`DeviceContext(api="vulkan")`,
`enqueue_create_buffer`, `map_to_host`, `enqueue_function`, `synchronize`):

```
device: Adreno (TM) 840 (local, Vulkan) | arch: adreno840
vecadd of 1048576 floats: c[5] = 15.0 | mismatches: 0
721 launches: enqueued in 8.10 ms, done in 132.11 ms
721 launches of 256 elements: enqueued in 4.68 ms, done in 4.69 ms
```

- **Large launches:** 721 adds of a million floats run at the memory's speed, 12 MB in 0.18 ms each
  (66 GB/s).
- **Small launches:** 6.5 µs each, through Mojo's `DeviceContext`, MAX's HAL layer and the plugin.
  The plugin alone takes 5.6 µs.

### Every model, written as Mojo host code

Each C runner's forward pass also exists in Mojo, as `DeviceContext` launches of the same kernels:
- `llama/model.mojo` for Llama;
- `qwen3/model.mojo` for Qwen3;
- the port's own `model.mojo` for Bonsai.

`llama/llama.mojo` and `qwen3/qwen3.mojo` are the programs that load the weights, decode and
check. They take the runners' arguments and print their lines, so `llama/run.py --runner mojo`
checks against PyTorch and `qwen3/qwen3.mojo` checks against MLX (`QWEN3_REF`) as before.

On the Galaxy S26 Ultra, with every model's weights downloaded and converted on the phone:

| Model | Mojo `DeviceContext` | C runner | Check |
|---|---|---|---|
| Llama 3.2 1B, fp16 | 24.7 tok/s, 40.6 ms | 23 tok/s, 43 ms | 48 of 48 tokens as PyTorch; logits within 7.3e-5 |
| Llama 3.2 1B, 4-bit | 78.1 tok/s, 12.8 ms | 75 tok/s, 13 ms | 48 of 48 tokens as PyTorch (same int4 weights); 6.7e-5 |
| Bonsai 2 2B, ternary | 74–76 tok/s | 80 tok/s | 16 of 16 tokens as MLX; max abs 0.021 |
| Qwen3-8B, ternary | 25.1 tok/s, 39.8 ms | 25 tok/s, 40 ms | 16 of 16 tokens as MLX; max abs 0.0082 |

Decode moves weights from memory, so launching each kernel as it comes costs nothing measurable for
Llama and Qwen3. The runners record a token's dispatches once and resubmit them, so the batching
plugin issues the same work. Only Bonsai, with 721 small launches a token, gives up 5–8%.

The weights never cross adb: the phone downloads each public checkpoint from Hugging Face and
converts it. Each conversion is byte for byte the Mac's export, checked by SHA-256:
- **Llama:** `unsloth/Llama-3.2-1B-Instruct` (a mirror of Meta's, same SHA-256), converted by
  `llama/st2bin.c` with a recipe from `llama/st2bin_recipe.py`, plus `--q4` for 4-bit.
- **Qwen3:** `prism-ml/Ternary-Bonsai-8B-mlx-2bit`, converted by `qwen3/convert.cpp`
  (`export.py`'s export in C++). Its 64 KB RoPE table (MLX's YaRN) comes from the Mac.
- **Bonsai:** converted by `bonsai/convert.cpp`.

```bash
# Llama: the phone fetches and converts the checkpoint, then run.py checks the Mojo program
adb shell "cd /data/local/tmp/llama; curl -sSL -o model.safetensors https://huggingface.co/unsloth/Llama-3.2-1B-Instruct/resolve/main/model.safetensors"
adb shell "cd /data/local/tmp/llama; conv/st2bin model.safetensors conv/recipe.txt conv model/weights.bin"
$PY llama/run.py --model <Llama-3.2-1B-Instruct snapshot> --runner mojo [--quant q4]

# Qwen3: qwen3_convert writes weights.bin and manifest.txt from the checkpoint and export.py's rope.f32
adb shell "cd /data/local/tmp/q8; curl -sSL -o model.safetensors https://huggingface.co/prism-ml/Ternary-Bonsai-8B-mlx-2bit/resolve/main/model.safetensors"
adb shell "cd /data/local/tmp/q8; ./qwen3_convert model.safetensors rope.f32 model"
adb shell "cd /data/local/tmp/q8; QWEN3_REF=reference.f32 MODULAR_DRIVER_PLUGINS=vulkan@/data/local/tmp/q8/mojo/libM_driver_vulkan.so mojo/qwen3 model 16 \$(cat prompt.txt)"
```

Mojo's stdlib took an Android target for glibc Linux and called three glibc-only names:
`__errno_location`, `__xstat` and `__lxstat`. In the fork, `CompilationTarget.is_android()` reads
the target triple's environment, and on Android the stdlib calls Bionic's `__errno`, `stat` and
`lstat` instead. On the phone, `os.path.isdir`, `os.path.islink` and a failed `open`'s errno message
all work.

### Bonsai 2 2B through the port's `model.mojo`

The Android port's forward pass, written as `DeviceContext` launches, runs on our Vulkan backend.
Its kernels are compiled to adreno840 SPIR-V and embedded in the program. Every generated token
matches the MLX reference:

```
GPU: Adreno (TM) 840 (local, Vulkan)
Decode: 15 forwards ... (includes token selection readback, full-logit readback and validation)
Logits: max_abs_error=0.020813 relative_l2=0.000640047
PASS: all generated tokens and logits match reference
```

Decode, 99 tokens after the 19-token prompt, over four runs:

| Path | Decode |
|---|---|
| The port's `model.mojo` on our Vulkan plugin (this page) | 74–76 tok/s |
| The same `model.mojo` on the port's OpenCL plugin, as the port reports | 75–77 tok/s |
| `bonsai/bonsai_vk.c`: the same kernels, every dispatch of a token recorded once | 80 tok/s |

`model.mojo` launches each kernel as it goes; `bonsai_vk.c` records a token's 721 dispatches once
and resubmits them. That difference costs 5–8%, and the Mojo version needs no runner of its own.
