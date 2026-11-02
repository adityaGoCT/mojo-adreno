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
python3 android/build.py bonsai      # build/android/bonsai/
```

Each step does the following:
- **runtime:** builds `//Mojo:CompilerRT` of the modular fork (`MOJO_SRC`, branch
  `adreno-spirv-target`) with Bazel's `--config=android-arm64` and the NDK (`ANDROID_NDK`). It adds
  NDK libc++ and `driver/libM_driver_vulkan.so`.
- **packages:** builds MAX's package with the HAL `DeviceContext` from `max/mojo/max`, staged as
  `//max/mojo/max/_driver/max_license:max_srcs_hal` stages it. The host compiler in `bazel-bin`
  precompiles it, not Bazel: the Android build's change to `Support/Log.h` would make Bazel
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
