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
| `vk_server_win.c` | `remote/vk_server.c` with Winsock. `VK_SERVER_SEGMENTS=1` times each stretch between synchronizes on the laptop's clock, without the network round trip. |
| `executor_win.c`, `shim/dlfcn.h` | `driver/executor.c` unchanged: `dlopen` loads `vulkan-1.dll`, and `rename` replaces the pipeline cache file. |
| `build_mac.sh` | the server, cross-compiled by Zig 0.15.1 (`zig cc -target aarch64-windows-gnu`), the remote plugin, and the programs for the Mac (`mojo build --emit object --target-accelerator adreno840`, linked against the fork's host runtime) |

## Run it

```bash
vla/x2/build_mac.sh                                   # build/vla/x2/: vk_server.exe, the plugin, smolvla, pi0
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
