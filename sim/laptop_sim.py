"""LIBERO on the laptop itself: the simulator and the policy side by side, no tunnel in the loop. MuJoCo/robosuite
render the two cameras, TurboVLA's chain on the laptop's NPU (graph_tool serve, on localhost) computes each 12-step
action chunk, and every episode is recorded as an MP4; the Mac only copies the recordings back.

No PyTorch here: the inputs the official policy class would make (DINOv3's normalization, the normalized state, the
text graph's tensors) and its action postprocessing are done in numpy; sim/make_bundle.py precomputes the text
tensors and LIBERO's initial states on the Mac and checks this numpy glue against the official class. The episode
protocol is TurboVLA's evaluation (10 settling steps, then the policy up to the suite's step limit, 12 actions a
chunk).

  python laptop_sim.py --bundle bundle --suite libero_spatial --tasks all --episodes 2 --out runs\\spatial
"""

import argparse
import json
import math
import os
import pathlib
import sys
import time
from collections import deque

import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
MAX_STEPS = {"libero_spatial": 220, "libero_object": 280, "libero_goal": 300, "libero_10": 520}
SLOTS = dict(ids=0, pos=1, text_mask=2, keep=3, pixels=4, key_mask=5, self_mask=6, state=7)  # graph_tool serve's
DUMMY = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -1.0]


def quat2axisangle(quat):
    quat = np.asarray(quat, np.float32).copy()
    quat[3] = np.clip(quat[3], -1.0, 1.0)
    den = math.sqrt(max(0.0, 1.0 - float(quat[3]) * float(quat[3])))
    if math.isclose(den, 0.0):
        return np.zeros(3, np.float32)
    return (quat[:3] * 2.0 * math.acos(float(quat[3])) / den).astype(np.float32)


class Policy:
    """TurboVLA's evaluation policy (turbovla/evaluation/suite_policy.py) with the forward pass on the NPU chain."""

    def __init__(self, stats, chain):
        f = lambda k: np.asarray(stats[k], np.float32)
        self.pmean, self.pstd = f("proprio_mean"), f("proprio_std")
        self.amin, self.amax = f("action_min"), f("action_max")
        self.imean, self.istd = f("image_mean").reshape(3, 1, 1), f("image_std").reshape(3, 1, 1)
        self.chain = chain
        self.text = None
        self.last = dict(npu_ms=0.0, round_trip_ms=0.0)

    def inputs(self, primary, wrist, obs):
        """pixels [1, 2, 3, 256, 256] (x / 255 normalized with ImageNet's mean and std), the state [1, 8]."""
        views = [(np.asarray(v, np.float32) * np.float32(1 / 255)).transpose(2, 0, 1) for v in (primary, wrist)]
        pix = np.stack([(v - self.imean) / self.istd for v in views])[None].astype(np.float32)
        state = np.concatenate([np.asarray(obs["robot0_eef_pos"], np.float32).reshape(-1),
                                quat2axisangle(obs["robot0_eef_quat"]),
                                np.asarray(obs["robot0_gripper_qpos"], np.float32).reshape(-1)])
        return pix, ((state - self.pmean) / (self.pstd + 1e-6))[None].astype(np.float32)

    def env_actions(self, chunk):
        """Normalized [n, 7] -> environment actions: the arm from the [-1, 1] range back to the data's, the gripper as
        +1 / -1 (sign; 0 counts as +1)."""
        rows = []
        for a in np.nan_to_num(np.asarray(chunk, np.float32), nan=0.0, posinf=1.0, neginf=-1.0):
            arm = 0.5 * (a[:6] + 1.0) * (self.amax[:6] - self.amin[:6]) + self.amin[:6]
            rows.append(np.concatenate([arm, [-1.0 if a[6] < 0 else 1.0]]).astype(np.float32))
        return np.stack(rows)

    def set_text(self, text):
        for k, v in text.items():
            self.chain.set(SLOTS[k], v)

    def act(self, primary, wrist, obs):
        pix, st = self.inputs(primary, wrist, obs)
        out, ms, rt = self.chain.run([(SLOTS["pixels"], pix, True), (SLOTS["state"], st, False)])
        self.last = dict(npu_ms=ms, round_trip_ms=rt)
        return self.env_actions(out.reshape(12, 7))


def libero_config(libero_dir):
    """LIBERO asks for its paths on first import unless a config exists: write one next to this script."""
    cfg = HERE / "libero_config"
    cfg.mkdir(exist_ok=True)
    root = (libero_dir / "libero/libero").resolve()
    lines = [f"benchmark_root: {root}", f"bddl_files: {root / 'bddl_files'}", f"init_states: {root / 'init_files'}",
             f"datasets: {HERE / 'datasets'}", f"assets: {root / 'assets'}"]
    (cfg / "config.yaml").write_text("\n".join(lines) + "\n")
    os.environ["LIBERO_CONFIG_PATH"] = str(cfg)
    sys.path.insert(0, str(libero_dir))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bundle", type=pathlib.Path, default=HERE / "bundle")
    ap.add_argument("--libero", type=pathlib.Path, default=HERE / "LIBERO-8f1084e")
    ap.add_argument("--suite", default="libero_spatial", choices=list(MAX_STEPS))
    ap.add_argument("--tasks", default="all")
    ap.add_argument("--episodes", type=int, default=1)
    ap.add_argument("--port", type=int, default=7801)
    ap.add_argument("--out", type=pathlib.Path, default=HERE / "runs")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--open-loop", type=int, default=12)
    a = ap.parse_args()

    libero_config(a.libero)
    from libero.libero import get_libero_path
    from libero.libero.envs import OffScreenRenderEnv
    import imageio
    from npu_client import NPUChain

    np.random.seed(a.seed)
    meta = json.loads((a.bundle / f"{a.suite}.json").read_text())
    arrays = np.load(a.bundle / f"{a.suite}.npz")
    stats = json.loads((a.bundle / "stats.json").read_text())
    policy = Policy(stats, NPUChain(a.port))
    tasks = meta["tasks"] if a.tasks == "all" else [meta["tasks"][int(t)] for t in a.tasks.split(",")]
    max_steps = MAX_STEPS[a.suite]
    (a.out / "videos").mkdir(parents=True, exist_ok=True)
    results = []
    t_run = time.time()
    for task in tasks:
        t = task["id"]
        bddl = os.path.join(get_libero_path("bddl_files"), task["problem_folder"], task["bddl_file"])
        env = OffScreenRenderEnv(bddl_file_name=bddl, camera_heights=256, camera_widths=256)
        env.seed(a.seed)
        policy.set_text({k: arrays[f"text_{t}_{k}"] for k in ("ids", "pos", "text_mask", "keep", "key_mask",
                                                              "self_mask")})
        inits = arrays[f"init_{t}"]
        for ep in range(a.episodes):
            env.reset()
            obs = env.set_init_state(inits[ep % len(inits)])
            queue, frames, chunks, success = deque(), [], [], False
            t0 = time.time()
            sim_s = 0.0
            for step in range(max_steps + 10):
                primary = np.ascontiguousarray(obs["agentview_image"][::-1, ::-1])
                wrist = np.ascontiguousarray(obs["robot0_eye_in_hand_image"][::-1, ::-1])
                if step < 10:
                    s0 = time.time()
                    obs, _, _, _ = env.step(DUMMY)
                    sim_s += time.time() - s0
                    continue
                frames.append(np.concatenate([primary, wrist], 1))
                if not queue:
                    queue.extend(policy.act(primary, wrist, obs)[:a.open_loop])
                    chunks.append(policy.last)
                s0 = time.time()
                obs, _, done, _ = env.step(queue.popleft().tolist())
                sim_s += time.time() - s0
                if done:
                    success = True
                    break
            name = f"{a.suite}_task{t:02d}_ep{ep:02d}_{'success' if success else 'failure'}.mp4"
            imageio.mimwrite(a.out / "videos" / name, frames, fps=20)
            npu = [c["npu_ms"] for c in chunks]
            rt = [c["round_trip_ms"] for c in chunks]
            res = dict(task_id=t, instruction=task["instruction"], episode=ep, success=success, steps=len(frames),
                       chunks=len(chunks), wall_s=round(time.time() - t0, 1), sim_s=round(sim_s, 1),
                       npu_ms=round(float(np.median(npu)), 1), policy_ms=round(float(np.median(rt)), 1),
                       video=f"videos/{name}")
            results.append(res)
            print(json.dumps(res), flush=True)
            (a.out / "results.json").write_text(json.dumps(results, indent=1))
        env.close()
    n = sum(r["success"] for r in results)
    print(f"success {n}/{len(results)} in {time.time() - t_run:.0f} s", flush=True)


if __name__ == "__main__":
    main()
