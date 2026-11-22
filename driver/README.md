# The Vulkan driver plugin

`libM_driver_vulkan.so` is a MAX driver plugin for a phone's GPU. It implements modular's
`SDK/include/HAL` (the `M_driver_*` C interface that MAX's runtime and `DeviceContext` sit on)
with Vulkan, on the phone, for kernels from Mojo's Vulkan SPIR-V target (`adreno710`,
`adreno840`).

MAX loads it like its CUDA, HIP and Metal plugins:

```bash
MODULAR_DRIVER_PLUGINS="vulkan@/data/local/tmp/mojo/driver/libM_driver_vulkan.so"
```

`DeviceContext` code, such as the Android port's `model.mojo`, can then allocate, copy and launch
on the Adreno with no runner of its own. That still needs MAX's runtime built for Android (see the
end of this page).

## How it works

| File | What it does |
|---|---|
| `plugin.cpp` | The `M_driver_*` interface: device addresses for allocations, launch descriptions, arguments to bindings |
| `executor.c` | Vulkan: the device, buffers, pipelines, descriptor sets, command buffers |
| `local.cpp` | Runs the executor in the plugin's own process (this plugin) |
| `protocol.h` | The requests from the plugin to the executor |
| `json.h` | Reads launch descriptions |
| `test_plugin.cpp` | The on-phone test |

`../remote/` builds the same `plugin.cpp` for the Mac with a TCP transport (`remote/transport.cpp`).
There, `remote/vk_server.c` runs the same `executor.c` on the phone.

**Requests beyond MAX's.** `protocol.h` also has requests that `M_driver_*` has no call for. Programs reach them
through functions the plugin exports (`dlopen`/`dlsym` of the plugin; Mojo: `OwnedDLHandle(path).call[...]`):
- `M_driver_remote_file` (`OP_FILE`): the executor reads a range of a file on its own side into a buffer. With the
  remote plugin, weights already on the device running `vk_server` need not cross the transport.
- `M_driver_remote_gather` (`OP_GATHER`): when the GPU's work so far is done, the executor copies row t of a table in a
  file into a buffer, t being an int32 the GPU left in memory. This is an embedding row for a token the GPU chose,
  without asking the host.
- `M_driver_remote_record` / `M_driver_remote_replay` (`OP_RECORD`, `OP_REPLAY`, `vla/x2/vk_server_win.c` only): the
  server keeps a copy of the requests that follow, then runs them n more times and answers with its own clock's time.
  That times GPU work without the transport.
- `M_driver_remote_npu_open` / `_rope` / `_prefix` / `_time` (`OP_NPU_*`, `vla/x2`'s `vk_server_npu.exe` only):
  π0's Gemma prefix on the NPU of the device running the server (`npu/pi0_prefix.cpp`). The prefix request names the
  buffers of the embeddings and of every layer's K and V. Once the GPU is done, the server reads the embeddings from
  the first, and as each graph finishes it writes K and V into the others, so they never cross the transport.

[`../qwen3moe`](../qwen3moe) uses the first four on the X2 Elite laptop; [`../pi0`](../pi0) uses the NPU's.

**Launch arguments.** Each module carries a launch description, `OpModuleProcessed
"mojo.vulkan.abi {json}"`. It says which argument and byte offset each storage buffer's pointer
comes from, and the same for each params slot. A launch passes CUDA-style arguments: a pointer to
each argument's bytes, laid out by MAX's host code. Tensors arrive whole, with their pointers
inside. The plugin reads each pointer out of those bytes, finds the allocation it points into, and
binds that buffer at that offset. It copies each scalar into a 64-bit params slot. A kernel without
a fixed workgroup size gets the block size as specialization constants 0-2, with one pipeline per
block size.

**Batching.** Launches, copies and fills are recorded into command buffers of 64 commands
(`VK_SUBMIT_EVERY`), each command after a barrier on the ones before it. Nothing waits for the GPU
until the host reads or writes memory, or synchronizes. A launch of 2¹⁸ threads or more is submitted
at once. 64 of a long prefill's launches in one submission outlast the driver's GPU watchdog, and the
device is lost (`VK_ERROR_DEVICE_LOST`). Decode's launches, under 100K threads, stay batched. On an Adreno 840 (Galaxy S26 Ultra, stock
driver), 721 launches in a row, as in one Bonsai token, take:

| Commands a submission | Each launch | 721 launches |
|---|---|---|
| 1 | 105 µs | 76 ms |
| 16 | 11 µs | 8.0 ms |
| 64 (default) | 5.6 µs | 4.1 ms |

`bonsai_vk.c` records a token's 721 dispatches once and resubmits them, at 12.4 ms a token. Through
the plugin, each launch is encoded as it comes, and that work overlaps the GPU's.

**Recorded command buffers (replay).** MAX's `DeviceGraph` (CUDA graphs) is CUDA and HIP only, and `M_driver_*` has
no call for it, so the plugin exports its own. Programs use them as they use `M_driver_remote_file`:

```mojo
var lib = OwnedDLHandle("libM_driver_vulkan.so")
ctx.synchronize()                                        # the graph starts with the next launch
_ = lib.call["M_driver_vulkan_graph_begin", Int32]()
model.decode_step(ctx)                                   # launches, device copies, fills: recorded and run
var g = lib.call["M_driver_vulkan_graph_end", Int32]()   # graph id > 0, or -1
for _ in range(steps):
    ctx.enqueue_copy(pos_buf, pos_host)                  # what changes goes through device memory
    _ = lib.call["M_driver_vulkan_graph_launch", Int32](g, Int32(1))   # no launch encoded
    ...
_ = lib.call["M_driver_vulkan_graph_free", Int32](g)
```

- Between `_begin` and `_end`, the executor puts the launches, device copies and fills into command buffers that it
  keeps, with descriptor sets and params of their own, and runs them as usual. `_launch(id, count)` submits those
  command buffers again `count` times, in order with the work around it, in one `vkQueueSubmit`. Nothing is encoded:
  no descriptor set, no params copy, no command.
- The command buffers are cut like the batch's: `VK_SUBMIT_EVERY` commands, or `VK_GRAPH_EVERY` for graphs only,
  with a big launch alone. Each is its own batch of the submission, so a replay outlasts the watchdog only where
  the first run would have.
- Refused while recording: copies from or to the host, file reads, frees and kernel loads.
- Baked in: each launch's scalar arguments. Whatever changes between replays (a position, a token) has to live in
  device memory, written between them.
- Freeing a buffer the graph uses, or loading one of its kernels again, makes its `_launch` fail.
- `test_plugin` checks it: 721 residual launches recorded, replayed one at a time and 20 at once, results exact; then
  the launch refused after a free.

Measured with `test_plugin` on a Qualcomm Device Cloud QRD (SM8850, Adreno 840, stock driver), 2026-11-22: 721
dependent launches of Bonsai's residual kernel (one token's worth), ms for all 721, best / median of 3 runs:

| commands a command buffer | enqueued one by one (batched) | one replay | 20 replays in one call, each |
|---|---|---|---|
| 64 (default) | 2.67 / 3.30 | **1.26 / 1.31** | 1.37 / 1.48 |
| 721 (`VK_GRAPH_EVERY=721`) | | 1.30 / 1.32 | **1.10 / 1.11** |
| 1 (`VK_SUBMIT_EVERY=1`) | 135.5 / 135.6 | 118.9 / 120.3 | 119.4 / 120.4 |
| 1, graphs 64 (`VK_SUBMIT_EVERY=1 VK_GRAPH_EVERY=64`) | 136.7 / 136.9 | 2.15 / 2.19 | 2.00 / 2.03 |

- A replay takes 2.1-2.5x less time than enqueueing the same launches. What is left, ~1.5-1.8 µs a launch, is
  the GPU's: a barrier and a tiny dispatch per launch. Only fusing kernels removes that.
- Each submitted batch costs ~165 µs on this driver, even as one of many batches in a single `vkQueueSubmit`. So
  replays need large command buffers: replaying one-command buffers saves little (120 vs 136 ms).
- `vkQueueSubmit` with many batches returns only once most of them have run (20 replays: submitted in ~30 ms of
  ~30 ms). The driver's queue fills up, so a long replay doesn't free the host thread early.

**Host testing.** On a Mac, `executor.c` asks the Vulkan loader for portability drivers, so the plugin and
`test_plugin` also build for macOS and run on MoltenVK. That checks behaviour, not Adreno timing:

```bash
clang -O2 -c -o build/driver-mac/executor.o driver/executor.c -I/opt/homebrew/include
clang++ -std=c++17 -O2 -shared -I../modular/SDK/include -o build/driver-mac/libM_driver_vulkan.dylib \
    driver/plugin.cpp driver/local.cpp build/driver-mac/executor.o
clang++ -std=c++17 -O2 -I../modular/SDK/include -o build/driver-mac/test_plugin driver/test_plugin.cpp
DYLD_LIBRARY_PATH=/opt/homebrew/lib build/driver-mac/test_plugin build/driver-mac/libM_driver_vulkan.dylib <kernels>
```

**The device.** Pipelines require 64-lane subgroups where the driver allows it (`VK_SUBGROUP_SIZE`;
0 leaves it to the driver). A Mojo warp is 64 lanes, and cooperative matrices on the Adreno 840 need
64. Full subgroups are required where a block's rows fill them. The device enables what it has of
what LLVM's SPIR-V may declare:
- 8-, 16- and 64-bit integers, and fp16;
- 8- and 16-bit storage, and 64-bit atomics;
- the Vulkan memory model;
- KHR cooperative matrices.

The arch MAX compiles for comes from the driver's device name, for example `Adreno (TM) 840` →
`adreno840`, unless `VK_DRIVER_ARCH` is set.

**The pipeline cache.** A pipeline is created at its kernel's first launch, through a
`VkPipelineCache` kept in a file. The file is `$TMPDIR/mojo-vulkan-pipelines.bin` by default;
`VK_PIPELINE_CACHE` names another, and an empty value turns the cache off. The driver then
compiles each pipeline once per device. On a Galaxy Z Fold (Android 17), Llama's fused prefill
attention takes 39 s to compile, and 0.2 ms from the cache.

**Limits.** A pointer argument must point a multiple of `minStorageBufferOffsetAlignment` (64 on
Adreno) into its allocation, since it becomes a binding offset. A kernel takes at most 64 storage
buffers. Memory is host-visible and coherent, with one queue.

## Build and test

```bash
driver/build.sh                       # NDK: build/driver/libM_driver_vulkan.so, build/driver/test_plugin
```

The test loads the plugin as MAX does: `dlopen`, then every symbol in `M_driver_hal_symbols.inc`.
It runs, and checks on the CPU:
- MAX's naive matmul (256x256x256, and a 1x2048x2048 GEMV) and the four compiled variants of its
  elementwise add, from `max_kernels/test_max_kernels.py --compile`;
- the fp32 cooperative-matrix matmuls of `coopmat/` (adreno840), plain and staged in shared memory;
- a fill and a copy on the device;
- Bonsai's `residual` 721 times, to time a launch.

```bash
mkdir -p build/driver/kernels/coopmat
cp -R build/max_kernels/spv/{matmul_f32_256x256,matmul__gemv__1x2048x2048,add} build/driver/kernels/
cp build/bonsai/residual.spv build/driver/kernels/
cp build/coopmat/*matmul_coopmat_{f32,smem_f32}_*.spv build/driver/kernels/coopmat/
adb shell mkdir -p /data/local/tmp/mojo/driver
adb push build/driver/libM_driver_vulkan.so build/driver/test_plugin build/driver/kernels /data/local/tmp/mojo/driver/
adb shell "cd /data/local/tmp/mojo/driver; ./test_plugin ./libM_driver_vulkan.so kernels"
```

On a Galaxy S26 Ultra (Adreno 840, Vulkan 1.4, stock driver), every check passes:

```
plugin api "vulkan", 1 device: Adreno (TM) 840 (local, Vulkan), arch adreno840, 1024 threads and 32768 bytes shared memory a block

fill, then copy on the device                    PASS  max error 0.00e+00     0.00 ms
matmul_f32_256x256                               PASS  max error 1.40e-05    16.92 ms
matmul__gemv__1x2048x2048                        PASS  max error 1.06e-04    10.02 ms
add 0-mogg.foreach_r1_w4_b256.gs.True_c2757a     PASS  max error 0.00e+00    10.49 ms
add 1-mogg.foreach_r1_w4_b256.gs.False_879d5     PASS  max error 0.00e+00     7.75 ms
add 2-mogg.foreach_r1_w4_b256.gs.True_2f1a70     PASS  max error 0.00e+00     8.85 ms
add 3-mogg.foreach_r1_w4_b256.gs.False_b6d80     PASS  max error 0.00e+00     6.48 ms
cooperative matrices: matmul_coopmat_f32         PASS  max error 1.32e-05   410.82 ms
cooperative matrices: matmul_coopmat_smem_f32    PASS  max error 1.58e-05   695.67 ms
residual x721                                    PASS  max error 0.00e+00     5.22 ms
  721 launches: enqueued in 5.04 ms (7.0 us each), done in 5.22 ms (7.2 us each)
residual x721                                    PASS  max error 0.00e+00     4.07 ms
  721 launches: enqueued in 3.90 ms (5.4 us each), done in 4.07 ms (5.6 us each)
```

The times include each kernel's first pipeline, which the driver compiles on first use.

Environment variables:
- `VK_SUBMIT_EVERY`: commands a submission.
- `VK_SUBGROUP_SIZE`: the required subgroup size.
- `VK_DRIVER_ARCH`: the arch MAX compiles for.
- `VK_DRIVER_PROFILE=1`: the plugin's requests, at exit.
- `VK_DRIVER_DEBUG=1`: every request and launch.
- `VK_SERVER_PROFILE=1`: the executor's batches and each pipeline's creation; `=2` times each launch on its own.
- `VK_PIPELINE_CACHE`: the pipeline cache file; empty: no cache.

## Next: Mojo host code on the phone

The plugin is the device side of `DeviceContext`. For a `model.mojo` to run on the phone, its host
code and MAX's runtime must also be built for Android. The Android port (mav3ri3k/modular,
`max/examples/android-llm/build.py`) does this with the OpenCL plugin in this plugin's place, in
three steps:

1. `mojo build --target-triple aarch64-linux-android33 --emit object`, with the kernels embedded;
2. `//Mojo:CompilerRT` built with Bazel's `--config=android-arm64` and an NDK toolchain;
3. a small C++ main for weights and sampling.

The `adreno-spirv-target` fork has the SPIR-V target but not that Android configuration.
