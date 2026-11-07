# LIBERO, closed loop: a VLA on the laptop's NPU driving a simulated arm

[LIBERO](https://github.com/Lifelong-Robot-Learning/LIBERO) is a MuJoCo tabletop benchmark in which a Franka arm picks
and places objects from language instructions. Here it runs on the Mac. TurboVLA ([`../turbovla`](../turbovla)), the
216M LIBERO policy, runs as compiled graphs on the Hexagon NPU of the Snapdragon X Elite laptop in Qualcomm Device
Cloud.

The loop, every 12 simulator steps:
1. **On the Mac:** the simulator renders the two 256 × 256 cameras, agent view and wrist.
2. **To the laptop:** the Mac sends the cameras (as PNG) and the arm's state through an SSH tunnel.
3. **On the laptop's NPU:** TurboVLA computes a 12-step action chunk.
4. **Back on the Mac:** the arm executes the chunk.

A live page shows the cameras, the instruction, the step, the chunk latencies and the success tally as the episodes
run, and keeps every episode as an MP4.

## Result: LIBERO-Spatial, all 10 tasks, 2 episodes each

**20 of 20 episodes succeeded** (2026-11-07), with every action chunk computed on the laptop's NPU in fp16. Two
runs, which differ only in how the cameras cross the tunnel, took exactly the same number of steps in every
episode:

| | Cameras as PNG (default) | Cameras as fp16 pixels (first run) |
|---|---|---|
| Steps to success (limit 220), median and range | 99.5 (74–133) | the same |
| Action chunks per episode | 9 | 9 |
| NPU time per chunk (text + vision + head graphs) | 113 ms | 114 ms |
| Round trip per chunk, Mac to laptop and back | 504 ms | 602 ms |
| Wall time per episode (simulation included) | 9.5 s | 10.3 s |
| Bytes per chunk through the tunnel | about 185 KB | 786 KB |

- **For scale:** TurboVLA's paper reports 97.6% average success over the four LIBERO suites (50 episodes a task,
  bf16 on a GPU).
- **What this run shows:** the NPU's fp16 graphs keep the policy working closed loop (their actions are within
  2.3e-2 of PyTorch fp32 on a fixed input).
- **What it does not show:** 20 episodes are not the benchmark's 500.

**The tunnel's speed drifts, so the fair comparison is back to back.** Measured just before the PNG run, a chunk
took 1.2 s with fp16 pixels and 0.44 s with PNG frames.

**Where the 0.5 s per chunk goes:**
- the tunnel's bare round trip, about 290 ms (a 32-byte request);
- the NPU, 113 ms;
- the PNG frames' transfer, the rest.

The frames are lossless PNG (two 256 × 256 RGB views, about 185 KB). The laptop decodes them and normalizes them as
DINOv3's processor does (x / 255, ImageNet's mean and std, in fp32): its pixels match the official preprocessing
within 2.4e-7. That is more exact than the fp16 pixels the first run sent. A policy running next to the simulator
would see only the NPU time.

## How it fits together

- **The laptop: [`npu/graph.cpp`](../npu/graph.cpp)'s `graph_tool serve`.** It keeps TurboVLA's three compiled graphs
  (text, vision, head) open as one chain. A client sets input slots and runs the chain over TCP:
  - the instruction's tensors are set once per episode;
  - each chunk sends the cameras (fp16) and the state;
  - all of it is pipelined into one round trip.
- **The cameras: `--transport png` (the default).** Frames go to the server as PNG (`graph_tool serve`'s SET format 2,
  decoded with [stb_image](../npu/third_party/stb_image.h)). `--transport fp16` sends the processor's pixels instead.
- **The Mac: [`libero_demo.py`](libero_demo.py)** follows TurboVLA's own LIBERO evaluation protocol: 10 settling
  steps, then the policy up to the suite's step limit, 12 actions executed per chunk. It uses the official policy
  class (`suite_policy.TurboVLAPolicy`) for:
  - DINOv3's image preprocessing;
  - the state from the observation;
  - the normalization statistics;
  - the gripper command.

  Only the forward pass moves to the NPU; `--backend cpu` runs the official PyTorch model on the Mac's CPU instead.
- **[`npu_client.py`](npu_client.py):** the serve client.
- **[`dashboard.html`](dashboard.html):** the live page, served by the demo from its output directory.

## Running it

**Once, on the Mac.** Python 3.10 with TurboVLA's LIBERO pins, LIBERO from source, and TurboVLA's package:

```bash
cd build/libero
git clone https://github.com/Lifelong-Robot-Learning/LIBERO.git      # tested at 8f1084e
uv venv --python python3.10 venv
uv pip install --python venv/bin/python torch==2.3.1 torchvision==0.18.1 transformers==4.56.0 tokenizers==0.22.2 \
    timm==1.0.25 numpy==1.26.4 Pillow==11.3.0 huggingface-hub==0.36.2 safetensors==0.7.0 bddl==1.0.1 \
    cloudpickle==2.1.0 easydict==1.9 gym==0.25.2 h5py==3.14.0 "imageio[ffmpeg]==2.37.2" matplotlib==3.9.4 \
    mujoco==2.3.7 robosuite==1.4.0 PyOpenGL==3.1.10 glfw==2.10.0 scipy==1.13.1 numba==0.60.0 llvmlite==0.43.0 \
    tqdm future termcolor opencv-python
uv pip install --python venv/bin/python --no-deps -e LIBERO -e ../turbovla/src
```

Two fixes are needed on macOS:
- **MuJoCo's OpenGL path.** MuJoCo 2.3.7's Apple binding loads `/System/Library/OpenGL.framework`, which recent macOS
  no longer has. In `venv/lib/python3.10/site-packages/mujoco/cgl/cgl.py`, change it to
  `/System/Library/Frameworks/OpenGL.framework/OpenGL`.
- **LIBERO's config.** LIBERO asks for its paths on first import, so write `build/libero/config/config.yaml` first
  (`benchmark_root`, `bddl_files`, `init_states`, `datasets`, `assets` under `LIBERO/libero/libero`).
  `libero_demo.py` points `LIBERO_CONFIG_PATH` there.

Rendering uses MuJoCo's CGL (Apple GPU) backend. TurboVLA's reference evaluation renders with OSMesa
(Mesa 21.2.6), so the images can differ slightly from the training renderer's.

**On the laptop**, from `C:\Users\HCKTest\turbovla\npu` (the compiled contexts from `turbovla/export_npu.py`), started
over the tunnel:

```bash
ssh -p 2222 -i <key> -L 7801:127.0.0.1:7801 HCKTest@localhost "cd /d C:\Users\HCKTest\turbovla\npu & <graph_tool.exe> serve 7801 text_ctx.onnx - - - - + vision_ctx.onnx - + head_ctx.onnx @1:0 @0:0 - - -"
```

**Then on the Mac:**

```bash
build/libero/venv/bin/python sim/libero_demo.py --suite libero_spatial --tasks all --episodes 2 --hold
```

Open http://localhost:8765/ for the live page. Episodes are saved in `build/sim/turbovla/videos`, with a summary in
`results.json`. `--suite` takes `libero_spatial`, `libero_object`, `libero_goal` or `libero_10`. TurboVLA's
checkpoint covers all four.

## Simulating on the laptop itself: blocked on this QDC image

Running LIBERO on the laptop too would remove the tunnel from the loop. It does not work on the X Elite laptop QDC
assigned (Windows 11 25H2, build 26200.6584):
- **No ARM64 MuJoCo.** MuJoCo publishes no Windows-on-ARM build: not on PyPI, conda-forge or its GitHub releases.
- **No AVX under emulation.** The x64 build needs AVX. This image's x64 emulator exposes none to x64 apps (an x64
  Python sees SSE4.2 but no AVX), so importing MuJoCo dies with an illegal instruction (0xC000001D). Microsoft's
  newer emulator exposes AVX and AVX2 to x64 apps by default on updated Windows 11.
- **No WSL.** It is not installed, and installing it needs admin rights and a reboot.

[`laptop_sim.py`](laptop_sim.py) and [`make_bundle.py`](make_bundle.py) are ready for a laptop where MuJoCo runs:
- **`laptop_sim.py`** runs the same evaluation protocol with no PyTorch, reaching `graph_tool serve` on localhost.
  It does in numpy what the official policy class does; `make_bundle.py` checks that against the class.
- **`make_bundle.py`** precomputes, on the Mac, each instruction's text tensors and LIBERO's initial states.

`laptop_sim.py` has not yet run end to end; the setup it needs (x64 Python 3.10 from NuGet, the same pins without
PyTorch, and LIBERO's source) installs and imports on the laptop up to MuJoCo.
