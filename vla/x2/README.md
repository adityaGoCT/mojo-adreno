# The same programs on a Snapdragon X2 Elite laptop

The SmolVLA and π0 programs also drive the **Adreno X2-90** of a Snapdragon X2 Elite laptop (X2E88100, Windows 11
on Arm, Qualcomm's Vulkan 1.4 driver 0.872.0, 33.6 GB RAM) in Qualcomm Device Cloud. Mojo's runtime has no Windows
build, so the program runs on the Mac. MAX's `DeviceContext` there talks to the repo's remote driver plugin
(`driver/plugin.cpp` + `remote/transport.cpp`). The plugin streams allocations, copies and launches over TCP to a
Vulkan server on the laptop, which runs the same `driver/executor.c` as on the phone:

```
Mac: smolvla / pi0 (Mojo, macOS)  ->  libM_driver_vulkan_remote.dylib  --TCP via ssh -L-->  laptop: vk_server.exe
     kernels: adreno840 SPIR-V                                                            driver/executor.c + Vulkan
```

The kernels are the same adreno840 SPIR-V modules. The X2-90's driver offers the same cooperative matrices (64-lane
subgroups, `VK_KHR_cooperative_matrix`) and 32 KB of shared memory. Every check gives the phone's numbers, bit for
bit: SmolVLA's actions within 1.37e-6 of PyTorch.

| File | What |
|---|---|
| `vk_server_win.c` | `remote/vk_server.c` with Winsock. `VK_SERVER_SEGMENTS=1` times each stretch between synchronizes on the laptop's clock, without the network round trip. Built with `-DVK_SERVER_NPU` (`vk_server_npu.exe`), it also runs π0's Gemma prefix on the laptop's Hexagon NPU (`npu/pi0_prefix.cpp`) and writes its K/V into the GPU's buffers ([`../../pi0`](../../pi0/README.md#the-chunk-with-the-npu-prefix)). |
| `executor_win.c`, `shim/dlfcn.h` | `driver/executor.c` unchanged: `dlopen` loads `vulkan-1.dll`, and `rename` replaces the pipeline cache file. It adds the mapped memory of a buffer for the server's own requests. |
| `build_mac.sh` | the servers, cross-compiled by Zig 0.15.1 (`zig cc -target aarch64-windows-gnu`; `vk_server_npu.exe` against ONNX Runtime's QNN NuGet package), the remote plugin, and the programs for the Mac (`mojo build --emit object --target-accelerator adreno840`, linked against the fork's host runtime; `pi0npu` with `-D PI0NPU_REMOTE`) |

## Run it

```bash
vla/x2/build_mac.sh                                   # build/vla/x2/: vk_server.exe, vk_server_npu.exe, the plugin, smolvla, pi0
X2="ssh -p 2222 -i <QDC key> HCKTest@localhost"       # through the QDC tunnel to the laptop's port 22
scp -P 2222 -i <QDC key> build/vla/x2/vk_server.exe HCKTest@localhost:vla/
$X2 -L 7790:127.0.0.1:7788 "cd vla & set VK_SERVER_SEGMENTS=1& vk_server.exe 7788"   # leave running
VK_REMOTE_PORT=7790 MODULAR_DRIVER_PLUGINS=vulkan@$PWD/build/vla/x2/libM_driver_vulkan_remote.dylib \
    build/vla/x2/smolvla build/vla/hf/smolvla_base/model.safetensors build/vla/smolvla/ref 4
```

## Timing through a tunnel

QDC reaches the laptop only through SSH, which costs a lot:
- **Uploads.** The weights cross at about 3 MB/s: SmolVLA's 0.81 GB take 4.5 minutes.
- **Round trips.** Every synchronize waits about 0.3 s, so the times the program prints include that.

The laptop's numbers come from the server's clock instead (`VK_SERVER_SEGMENTS`). Each segment runs from the first
request after a synchronize to that synchronize's answer. The launches still stream in at the tunnel's rate, so a
segment of many small launches (the denoising steps) is an upper bound.

SmolVLA (bf16 weights, fp32 matrix units), four runs:

| Stage | X2-90 | Adreno 840 (Galaxy Z Fold) |
|---|---|---|
| Vision | 338–358 ms | 518–523 ms |
| Prefix | 38–42 ms (one run 68) | 62 ms |
| 10 steps | 161–188 ms (16–19 ms/step) | 189–191 ms |
| **Action chunk** | **531–550 ms** | **776–778 ms** |

On a laptop that holds its clocks, the chunk takes 70% of the phone's time.

π0, three runs: same checks as the phone, bit for bit (actions within 7.2e-6). Its 5.4 GB of weights took
20 minutes through the tunnel.

| Stage | X2-90 | Adreno 840 (Galaxy Z Fold) |
|---|---|---|
| Vision (SigLIP So400m) | 378–389 ms | 554–558 ms |
| Prefix (Gemma 2B, 18 layers) | 2.13–2.15 s (about 120 ms a layer) | 2.73–2.75 s |
| 10 steps | 0.70–0.74 s (70–74 ms/step) | 0.76–0.79 s |
| **Action chunk** | **3.1–3.9 s** | **4.05–4.06 s** |

The split kernels (`pi0/README.md`) on the laptop, old and new alternating in one process: the expert's split
keys save about 10% a step (77–79 → 69 ms), while splitting Gemma's projections over k made the prefix 1–12%
slower here too (the version without that is what `pi0` now does).

The laptop's π0 chunk includes 0.1–0.2 s for the 48 language rows (393 KB, gathered on the Mac) to cross the
tunnel, and π0 synchronizes after each prefix layer. Its stages add up to 3.2–3.3 s. The expert's steps gain
least: 2,840 small launches a chunk, streamed at the tunnel's rate.

With Gemma 2B's prefix on the laptop's Hexagon NPU, inside the server (`vk_server_npu.exe`, `pi0npu`), the chunk takes
**1.82–1.85 s** on the laptop's clock: vision 378–383 ms, the prefix 0.81 s, 10 steps 674–701 ms. The NPU's K/V go
into the GPU's buffers on the laptop and never cross the tunnel. Details in
[`../../pi0`](../../pi0/README.md#the-chunk-with-the-npu-prefix).
