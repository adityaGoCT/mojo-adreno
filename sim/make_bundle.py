"""What sim/laptop_sim.py needs to run a LIBERO suite without PyTorch (the laptop has none): every task's BDDL file,
instruction and initial states (LIBERO stores those with torch.save), TurboVLA's text-graph inputs for each
instruction (from the official text encoder), the normalization statistics and the image normalization. Checks the
numpy preprocessing laptop_sim.py uses against the official policy class on random observations.

  build/libero/venv/bin/python sim/make_bundle.py [suites...]     # default: all four; writes build/sim/bundle
"""

import json
import os
import pathlib
import sys

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/turbovla"
SRC = B / "src"
OUT = ROOT / "build/sim/bundle"
os.environ.setdefault("LIBERO_CONFIG_PATH", str(ROOT / "build/libero/config"))
sys.path[:0] = [str(ROOT / "build/libero/LIBERO"), str(SRC), str(ROOT / "sim")]
NEG = -30000.0


def text_inputs(enc, instruction):
    """The text graph's inputs and the head's masks for one instruction (as turbovla/reference.py makes them)."""
    import torch
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
    return dict(ids=ids, pos=posid, text_mask=add, keep=keep, key_mask=key_add, self_mask=add)


def main():
    import torch
    from libero.libero import benchmark
    from turbovla.evaluation import suite_policy
    from turbovla.evaluation.policy import state_from_libero_obs
    import laptop_sim as L

    suites = sys.argv[1:] or ["libero_spatial", "libero_object", "libero_goal", "libero_10"]
    stats_path = SRC / "experiments/libero/configs/libero_all4_stats.json"
    policy = suite_policy.TurboVLAPolicy(
        ckpt_path=str(B / "hf/turbovla_libero.pth"), dinov3_path=str(B / "dinov3"), bert_path=str(B / "bert"),
        stats_path=str(stats_path), stats_key="libero_all4_no_noops", precision="fp32", device="cpu", verbose=False)
    enc = policy.model.text_encoder
    OUT.mkdir(parents=True, exist_ok=True)
    stats = dict(proprio_mean=policy.proprio_mean.tolist(), proprio_std=policy.proprio_std.tolist(),
                 action_min=policy.action_min.tolist(), action_max=policy.action_max.tolist(),
                 image_mean=[0.485, 0.456, 0.406], image_std=[0.229, 0.224, 0.225])
    (OUT / "stats.json").write_text(json.dumps(stats, indent=1))

    # laptop_sim's numpy glue against the official policy class, on random observations and chunks
    rng = np.random.default_rng(0)
    P = L.Policy(stats, chain=None)
    for _ in range(5):
        prim = rng.integers(0, 256, (256, 256, 3), dtype=np.uint8)
        wrist = rng.integers(0, 256, (256, 256, 3), dtype=np.uint8)
        q = rng.normal(size=4)
        obs = dict(robot0_eef_pos=rng.normal(size=3), robot0_eef_quat=q / np.linalg.norm(q),
                   robot0_gripper_qpos=rng.normal(size=2) * 0.04)
        samples, states = policy._build_batch([prim], [wrist], [state_from_libero_obs(obs)])
        pix, st = P.inputs(prim, wrist, obs)
        assert np.abs(pix - samples["dinov3"].numpy()).max() < 1e-5, "image preprocessing"
        assert np.abs(st - states.numpy()).max() < 1e-4, "state normalization"
        chunk = np.tanh(rng.normal(size=(12, 7))).astype(np.float32)
        want = np.stack([policy._normalized_row_to_env_action(r) for r in chunk])
        assert np.abs(P.env_actions(chunk) - want).max() < 1e-5, "action unnormalization"
    print("numpy glue matches the official policy class")

    for name in suites:
        suite = benchmark.get_benchmark_dict()[name]()
        tasks = []
        arrays = {}
        for t in range(suite.n_tasks):
            task = suite.get_task(t)
            inits = np.asarray(suite.get_task_init_states(t), np.float64)
            arrays[f"init_{t}"] = inits
            for k, v in text_inputs(enc, task.language).items():
                arrays[f"text_{t}_{k}"] = v
            tasks.append(dict(id=t, instruction=task.language, problem_folder=task.problem_folder,
                              bddl_file=task.bddl_file, n_init=int(len(inits))))
        np.savez_compressed(OUT / f"{name}.npz", **arrays)
        (OUT / f"{name}.json").write_text(json.dumps(dict(suite=name, tasks=tasks), indent=1))
        print(f"{name}: {len(tasks)} tasks, {sum(x['n_init'] for x in tasks)} initial states")


if __name__ == "__main__":
    main()
