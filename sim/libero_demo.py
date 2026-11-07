"""TurboVLA in LIBERO's simulator, closed loop: MuJoCo/robosuite on the Mac renders the two cameras, the laptop's
Hexagon NPU computes each 12-step action chunk (graph_tool serve, through an SSH tunnel), and the Mac steps the arm.
A live page (sim/dashboard.html, served from the output directory) shows the cameras, the task, the step and the
success tally as episodes run; every episode is also saved as an MP4.

The episode protocol is TurboVLA's own evaluation (third_party/vla_adapter rollout: 10 waiting steps, then the policy
until the task's step limit, 12 actions executed per chunk), and the inputs go through the official policy class
(suite_policy.TurboVLAPolicy: DINOv3's preprocessing, the state from the observation, the normalization statistics,
the gripper command). Only the forward pass moves to the NPU: --backend cpu runs the official PyTorch model on the
Mac's CPU instead, for comparison.

  build/libero/venv/bin/python sim/libero_demo.py --suite libero_spatial --tasks 0,1,2 --episodes 2

The laptop side (C:\\Users\\HCKTest\\turbovla\\npu), with the tunnel `ssh -L 7801:127.0.0.1:7801`:
  graph_tool serve 7801 text_ctx.onnx - - - - + vision_ctx.onnx - + head_ctx.onnx @1:0 @0:0 - - -
"""

import argparse
import functools
import http.server
import json
import os
import pathlib
import sys
import threading
import time
from collections import deque

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/turbovla"
SRC = B / "src"
os.environ.setdefault("LIBERO_CONFIG_PATH", str(ROOT / "build/libero/config"))
sys.path[:0] = [str(ROOT / "build/libero/LIBERO"), str(SRC), str(SRC / "third_party/vla_adapter"), str(ROOT / "sim")]

MAX_STEPS = {"libero_spatial": 220, "libero_object": 280, "libero_goal": 300, "libero_10": 520}
NEG = -30000.0  # the graphs' masked logit (fp16 holds it)
SLOTS = dict(ids=0, pos=1, text_mask=2, keep=3, pixels=4, key_mask=5, self_mask=6, state=7)  # graph_tool serve's


class Live:
    """The dashboard's files in out/: live.jpg (the cameras now), status.json (everything else), videos/."""

    def __init__(self, out, args):
        self.out = out
        (out / "videos").mkdir(parents=True, exist_ok=True)
        page = (ROOT / "sim/dashboard.html").read_text()
        (out / "index.html").write_text(page)
        self.status = dict(model="TurboVLA (H-EmbodVis/TurboVLA, LIBERO, 216M)",
                           backend="laptop NPU (Snapdragon X Elite, Hexagon V73)" if args.backend == "npu"
                           else "Mac CPU (PyTorch fp32)",
                           suite=args.suite, episodes=[], state="starting")
        self.frame_t = 0.0

    def frame(self, primary, wrist, force=False):
        now = time.time()
        if not force and now - self.frame_t < 0.05:
            return
        self.frame_t = now
        from PIL import Image
        img = Image.fromarray(np.concatenate([primary, wrist], 1)).resize((1024, 512), Image.BILINEAR)
        img.save(self.out / "live.tmp.jpg", quality=85)
        os.replace(self.out / "live.tmp.jpg", self.out / "live.jpg")

    def update(self, **kw):
        self.status.update(kw)
        self.status["time"] = time.time()
        (self.out / "status.tmp.json").write_text(json.dumps(self.status))
        os.replace(self.out / "status.tmp.json", self.out / "status.json")


def serve_dir(out, port):
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(out))
    handler.log_message = lambda *a, **k: None
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", port), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv


def make_policy(backend, port):
    import torch
    from turbovla.evaluation import suite_policy
    from turbovla.evaluation.policy import sanitize_pred_chunk, state_from_libero_obs

    base = suite_policy.TurboVLAPolicy

    class NPUPolicy(base):
        """The official policy's preprocessing and postprocessing; the forward pass on the laptop's NPU."""

        def __init__(self, *a, **k):
            super().__init__(*a, **k)
            from npu_client import NPUChain
            self.chain = NPUChain(port)
            self.instruction = None
            self.last = dict(npu_ms=0.0, round_trip_ms=0.0)

        def set_instruction(self, instruction):
            """The text graph's inputs and the head's masks, as the text encoder makes them (turbovla/reference.py)."""
            enc = self.model.text_encoder
            T = int(enc.config.padding_length)
            group = int(enc.config.padding_length_by_instruction.get(instruction, T))
            tok, self_mask, pos = enc._tokenize_group([instruction], torch.device("cpu"), group)
            ids = np.zeros((1, T), np.int32)
            ids[0, :group] = tok["input_ids"][0].numpy()
            posid = np.zeros((1, T), np.int32)
            posid[0, :group] = pos[0].numpy()
            bert = np.eye(T, dtype=np.int32)
            bert[:group, :group] = self_mask[0].numpy()
            keypad = np.ones(T, np.int32)
            keypad[:group] = 1 - tok["attention_mask"][0].numpy()
            add = np.where(bert[None] != 0, 0.0, NEG).astype(np.float32)
            keep = np.zeros((1, T, 1), np.float32)
            keep[0, :group] = 1
            key_add = np.where(keypad[None, None] != 0, NEG, 0.0).astype(np.float32)
            for name, arr in (("ids", ids), ("pos", posid), ("text_mask", add), ("keep", keep), ("key_mask", key_add),
                              ("self_mask", add)):
                self.chain.set(SLOTS[name], arr)
            self.instruction = instruction

        def predict_normalized_action_chunk(self, primary_image, wrist_image, instruction, state_or_obs):
            if instruction != self.instruction:
                self.set_instruction(instruction)
            state = state_from_libero_obs(state_or_obs) if isinstance(state_or_obs, dict) else state_or_obs
            samples, states = self._build_batch([primary_image], [wrist_image], [state])
            pix = samples["dinov3"].float().cpu().numpy()  # [1, 2, 3, 256, 256]
            st = states.float().cpu().numpy()  # [1, 8]
            out, ms, rt = self.chain.run([(SLOTS["pixels"], pix, True), (SLOTS["state"], st, False)])
            self.last = dict(npu_ms=ms, round_trip_ms=rt)
            return sanitize_pred_chunk(out.reshape(12, 7))

    class CPUPolicy(base):
        def predict_normalized_action_chunk(self, *a, **k):
            t0 = time.perf_counter()
            r = super().predict_normalized_action_chunk(*a, **k)
            self.last = dict(npu_ms=0.0, round_trip_ms=(time.perf_counter() - t0) * 1e3)
            return r

    cls = NPUPolicy if backend == "npu" else CPUPolicy
    return cls(ckpt_path=str(B / "hf/turbovla_libero.pth"), dinov3_path=str(B / "dinov3"), bert_path=str(B / "bert"),
               stats_path=str(SRC / "experiments/libero/configs/libero_all4_stats.json"),
               stats_key="libero_all4_no_noops", precision="fp32", device="cpu", verbose=False)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--suite", default="libero_spatial", choices=list(MAX_STEPS))
    ap.add_argument("--tasks", default="0", help="comma-separated task ids, or all")
    ap.add_argument("--episodes", type=int, default=1, help="episodes per task (init states 0, 1, ...)")
    ap.add_argument("--backend", default="npu", choices=["npu", "cpu"])
    ap.add_argument("--port", type=int, default=7801, help="graph_tool serve's port (tunnelled)")
    ap.add_argument("--http", type=int, default=8765, help="the dashboard's port on the Mac")
    ap.add_argument("--out", type=pathlib.Path, default=ROOT / "build/sim/turbovla")
    ap.add_argument("--open-loop", type=int, default=12, help="actions executed per chunk")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--hold", action="store_true", help="keep serving the dashboard after the last episode")
    a = ap.parse_args()

    a.out.mkdir(parents=True, exist_ok=True)
    live = Live(a.out, a)
    serve_dir(a.out, a.http)
    print(f"dashboard: http://localhost:{a.http}/", flush=True)
    live.update(state="loading the policy")

    from libero.libero import benchmark, get_libero_path
    from libero.libero.envs import OffScreenRenderEnv
    from turbovla.evaluation.policy import get_libero_dummy_action, rotate_libero_image, set_seed_everywhere
    import imageio

    set_seed_everywhere(a.seed)
    policy = make_policy(a.backend, a.port)
    suite = benchmark.get_benchmark_dict()[a.suite]()
    tasks = range(suite.n_tasks) if a.tasks == "all" else [int(t) for t in a.tasks.split(",")]
    max_steps = MAX_STEPS[a.suite]
    dummy = np.asarray(get_libero_dummy_action(), np.float32)
    results = []
    for task_id in tasks:
        task = suite.get_task(task_id)
        bddl = os.path.join(get_libero_path("bddl_files"), task.problem_folder, task.bddl_file)
        live.update(state="building the scene", task_id=task_id, instruction=task.language)
        env = OffScreenRenderEnv(bddl_file_name=bddl, camera_heights=256, camera_widths=256)
        env.seed(a.seed)
        inits = suite.get_task_init_states(task_id)
        for ep in range(a.episodes):
            env.reset()
            obs = env.set_init_state(inits[ep % len(inits)])
            queue, frames, success, chunks = deque(), [], False, []
            t_start = time.time()
            for t in range(max_steps + 10):
                primary = rotate_libero_image(obs["agentview_image"])
                wrist = rotate_libero_image(obs["robot0_eye_in_hand_image"])
                live.frame(primary, wrist)
                if t < 10:  # the objects settle (the evaluation's num_steps_wait)
                    obs, _, _, _ = env.step(dummy.tolist())
                    continue
                frames.append(np.concatenate([primary, wrist], 1))
                if not queue:
                    acts = policy.predict_env_action_chunk(primary, wrist, task.language, obs,
                                                           execute_steps=a.open_loop)
                    queue.extend(np.asarray(r, np.float32) for r in acts)
                    chunks.append(policy.last)
                    live.update(state="running", episode=ep, step=t - 10, max_steps=max_steps, chunk=len(chunks),
                                npu_ms=round(policy.last["npu_ms"], 1),
                                round_trip_ms=round(policy.last["round_trip_ms"], 1))
                obs, _, done, _ = env.step(queue.popleft().tolist())
                if done:
                    success = True
                    break
            live.frame(primary, wrist, force=True)
            name = f"{a.suite}_task{task_id:02d}_ep{ep:02d}_{'success' if success else 'failure'}.mp4"
            imageio.mimwrite(a.out / "videos" / name, frames, fps=20)
            rts = [c["round_trip_ms"] for c in chunks]
            npus = [c["npu_ms"] for c in chunks]
            res = dict(task_id=task_id, instruction=task.language, episode=ep, success=success, steps=len(frames),
                       chunks=len(chunks), wall_s=round(time.time() - t_start, 1),
                       npu_ms=round(float(np.median(npus)), 1) if npus else 0,
                       round_trip_ms=round(float(np.median(rts)), 1) if rts else 0, video=f"videos/{name}")
            results.append(res)
            live.status["episodes"] = results
            live.update(state="episode done")
            print(json.dumps(res), flush=True)
        env.close()
    n_ok = sum(r["success"] for r in results)
    live.update(state=f"finished: {n_ok}/{len(results)} succeeded")
    print(f"success {n_ok}/{len(results)}", flush=True)
    (a.out / "results.json").write_text(json.dumps(results, indent=1))
    if a.hold:
        print("holding the dashboard (Ctrl-C to stop)", flush=True)
        while True:
            time.sleep(3600)


if __name__ == "__main__":
    main()
