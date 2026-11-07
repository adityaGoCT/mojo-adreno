# LIBERO, closed loop: a VLA on the laptop's NPU driving a simulated arm

[LIBERO](https://github.com/Lifelong-Robot-Learning/LIBERO) is a MuJoCo tabletop benchmark in which a Franka arm picks
and places objects from language instructions. Here it runs on the Mac. TurboVLA ([`../turbovla`](../turbovla)), the
216M LIBERO policy, runs as compiled graphs on the Hexagon NPU of the Snapdragon X Elite laptop in Qualcomm Device
Cloud.

The loop, every 12 simulator steps:
1. **On the Mac:** the simulator renders the two 256 × 256 cameras, agent view and wrist.
2. **To the laptop:** the Mac sends the cameras and the arm's state through an SSH tunnel.
3. **On the laptop's NPU:** TurboVLA computes a 12-step action chunk.
4. **Back on the Mac:** the arm executes the chunk.

A live page shows the cameras, the instruction, the step, the chunk latencies and the success tally as the episodes
run, and keeps every episode as an MP4.

## Result: LIBERO-Spatial, all 10 tasks, 2 episodes each

**20 of 20 episodes succeeded** (2026-11-07), with every action chunk computed on the laptop's NPU in fp16:

| | median | range |
|---|---|---|
| Steps to success (limit 220) | 99.5 | 74–133 |
| Action chunks per episode | 9 | |
| NPU time per chunk (text + vision + head graphs) | 114 ms | |
| Round trip per chunk, Mac to laptop and back | 602 ms | |
| Wall time per episode (simulation included) | 10.3 s | 7.1–13.3 s |

- **For scale:** TurboVLA's paper reports 97.6% average success over the four LIBERO suites (50 episodes a task,
  bf16 on a GPU).
- **What this run shows:** the NPU's fp16 graphs keep the policy working closed loop (their actions are within
  2.3e-2 of PyTorch fp32 on a fixed input).
- **What it does not show:** 20 episodes are not the benchmark's 500.

The tunnel dominates the round trip: 114 ms of it is NPU work, and the remaining 490 ms or so is the SSH tunnel,
carrying the two cameras (0.8 MB as fp16) plus its own latency. A policy running next to the simulator would see
only the NPU time.

## How it fits together

- **The laptop: [`npu/graph.cpp`](../npu/graph.cpp)'s `graph_tool serve`.** It keeps TurboVLA's three compiled graphs
  (text, vision, head) open as one chain. A client sets input slots and runs the chain over TCP:
  - the instruction's tensors are set once per episode;
  - each chunk sends the cameras (fp16) and the state;
  - all of it is pipelined into one round trip.
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
