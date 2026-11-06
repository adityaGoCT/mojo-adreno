"""Octo-Small 1.5 (rail-berkeley/octo-small-1.5) in fp32 on the Mac's CPU: the reference the GPU/NPU ports are checked
against. It runs the OFFICIAL JAX/Flax model code (octo-models/octo at a pinned commit, cloned to build/octo/src), loads
the checkpoint with OctoModel.load_pretrained, samples one action chunk with sample_actions(rng=PRNGKey(0)), and writes
every stage's tensors to build/octo/ref as raw little-endian .f32 / .i32 / .u8 files plus meta.json:

  build/octo/venv/bin/python octo/reference.py            # writes build/octo/ref
  build/octo/venv/bin/python octo/reference.py --export   # also build/octo/octo_small.safetensors + export_names.txt

Setup (once): the venv is Python 3.10 with octo/requirements-reference.txt, the inference-path subset of the repo's
requirements.txt (jax/jaxlib 0.4.20, flax 0.7.5, tensorflow 2.15, tfp 0.23, distrax 0.1.5, dlimp at its git pin,
tensorflow_datasets 4.9.2, orbax-checkpoint 0.4.4, transformers 4.43 with Flax), resolved with --exclude-newer
2024-07-31 (the pinned commit's date). Two pins beyond upstream: scipy < 1.13 (jax 0.4.20 wraps scipy.linalg.tril,
which 1.13 removed) and orbax-checkpoint 0.4.4 (unpinned upstream; newer ones expect newer jax). Nothing is stubbed:
every import on the inference path (tensorflow for tf.io.gfile, dlimp + tfds via octo.data.utils, distrax) installs
on macOS arm64. tensorflow_text / tensorflow_hub / tensorflow_graphics, gym, wandb, etc. are left out: only the
MUSE text encoder, the data pipeline and the eval wrappers import them. The script itself clones the repo and downloads
the checkpoint at the pinned revisions if they are missing (build/octo/src, build/octo/hf/octo-small-1.5); t5-base's
config and tokenizer, which Octo's code fetches by name, land in build/octo/hf/hub (HF_HUB_CACHE).

Inputs (no simulator): two procedurally drawn scenes, one per camera (seed 1: image_primary 256x256, seed 2:
image_wrist 128x128), each in 2 frames whose objects move slightly between frames; window 2 with both frames valid
(timestep_pad_mask [True, True]) and both cameras present (pad_mask_dict True), shaped like the checkpoint's
example_batch. The task is model.create_tasks(texts=["put the eggplant in the basket"]), so the goal images are the
zeros create_tasks fills in (pixel value -1.0 after Octo's normalization, stacked as channels 3..5 of each stem
input). This is the full 690-token layout: task_language 16 + 2 x (obs_primary 256, obs_wrist 64, obs_task_language 16,
readout_action 1).

The intermediates come from the official modules: flax capture_intermediates (each submodule's output, plus
BlockTransformer.assemble_input_tokens / generate_attention_mask and T5's compute_bias), run eagerly on the same
params. The diffusion loop's noise is drawn with the same PRNG split chain predict_action uses, and the head is
re-run step by step on the official modules with that noise injected; the result is checked against sample_actions.
"""

import argparse
import functools
import hashlib
import json
import os
import pathlib
import subprocess
import sys
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/octo"
SRC = B / "src"
CKPT = B / "hf/octo-small-1.5"
REV_GH = "241fb3514b7c40957a86d869fecb7c7fc353f540"
REV_HF = "dc9aa3019f764726c770814b27e4ab0fc6e32a58"
CKPT_SHA256 = "644b2d8102f6d2a3145243223a7f0cc77165486ff9da087af590d8f814152c50"
INSTRUCTION = "put the eggplant in the basket"
DATASET = "bridge_dataset"

os.environ.setdefault("HF_HUB_CACHE", str(B / "hf/hub"))
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
os.environ.setdefault("JAX_PLATFORMS", "cpu")
os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
sys.path.insert(0, str(SRC))


def fetch():
    """Clone octo at REV_GH and download the checkpoint at REV_HF if they are not there yet."""
    if not (SRC / "octo/model/octo_model.py").exists():
        subprocess.run(["git", "clone", "-q", "https://github.com/octo-models/octo.git", str(SRC)], check=True)
        subprocess.run(["git", "-C", str(SRC), "checkout", "-q", REV_GH], check=True)
    head = subprocess.run(["git", "-C", str(SRC), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    assert head == REV_GH, f"build/octo/src is at {head}, expected {REV_GH}"
    files = ["config.json", "dataset_statistics.json", "example_batch.msgpack", "README.md", "300000/default/checkpoint"]
    for f in files:
        p = CKPT / f
        if not p.exists():
            p.parent.mkdir(parents=True, exist_ok=True)
            url = f"https://huggingface.co/rail-berkeley/octo-small-1.5/resolve/{REV_HF}/{f}"
            print("downloading", url)
            urllib.request.urlretrieve(url, p)
            if f.endswith("checkpoint"):
                h = hashlib.sha256()
                with open(p, "rb") as fh:
                    for chunk in iter(lambda: fh.read(1 << 24), b""):
                        h.update(chunk)
                assert h.hexdigest() == CKPT_SHA256, "checkpoint sha256 mismatch"


def scene(seed, size, frame):
    """A procedurally drawn RGB view (uint8 HWC): a gradient tabletop and six colored boxes and discs. Frame k moves
    each object by k times its own small velocity, so the two window frames differ like consecutive camera frames."""
    import numpy as np

    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:size, 0:size].astype(np.float32) / size
    img = np.stack([0.35 + 0.3 * y, 0.3 + 0.2 * x, 0.25 + 0.25 * (1 - y)], -1)
    for _ in range(6):
        c = rng.uniform(0.05, 0.95, 3)
        cx, cy, r = rng.uniform(0.1, 0.9), rng.uniform(0.2, 0.9), rng.uniform(0.04, 0.15)
        vx, vy = rng.uniform(-0.03, 0.03, 2)
        box = rng.random() < 0.5
        cx, cy = cx + frame * vx, cy + frame * vy
        m = ((np.abs(x - cx) < r) & (np.abs(y - cy) < r * 0.7)) if box else ((x - cx) ** 2 + (y - cy) ** 2 < r * r)
        img[m] = c
    img += np.random.default_rng(1000 * seed + frame).normal(0, 0.02, img.shape)
    return (np.clip(img, 0, 1) * 255).round().astype(np.uint8)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=pathlib.Path, default=B / "ref")
    ap.add_argument("--export", action="store_true", help="also write build/octo/octo_small.safetensors (fp32)")
    a = ap.parse_args()
    fetch()

    import flax
    import jax
    import jax.numpy as jnp
    import numpy as np

    from octo.model.components.block_transformer import BlockTransformer
    from octo.model.components.vit_encoders import weight_standardize
    from octo.model.octo_model import OctoModel

    t0 = time.time()
    model = OctoModel.load_pretrained(str(CKPT))
    n_params = sum(x.size for x in jax.tree_util.tree_leaves(model.params))
    print(f"loaded {n_params} parameters in {time.time() - t0:.1f} s")
    params = model.params

    # ---------------------------------------------------------------- inputs
    prim = np.stack([scene(1, 256, f) for f in range(2)])  # (2, 256, 256, 3)
    wrist = np.stack([scene(2, 128, f) for f in range(2)])  # (2, 128, 128, 3)
    tpm = np.ones((1, 2), bool)
    obs = {
        "image_primary": prim[None],
        "image_wrist": wrist[None],
        "timestep_pad_mask": tpm,
        "pad_mask_dict": {"image_primary": np.ones((1, 2), bool), "image_wrist": np.ones((1, 2), bool),
                          "timestep": np.ones((1, 2), bool)},
        "timestep": np.array([[0, 1]], np.int32),  # not read by the model, present in example_batch
        "task_completed": np.zeros((1, 2, 4), bool),  # likewise
    }
    tasks = model.create_tasks(texts=[INSTRUCTION])
    ids = np.asarray(tasks["language_instruction"]["input_ids"][0], np.int32)
    amask = np.asarray(tasks["language_instruction"]["attention_mask"][0], np.int32)
    stats = model.dataset_statistics[DATASET]["action"]

    out = a.out
    out.mkdir(parents=True, exist_ok=True)
    tensors = {}

    def save(name, arr, meaning, dtype="f32"):
        np_dtype = {"f32": "<f4", "i32": "<i4", "u8": "u1"}[dtype]
        arr = np.ascontiguousarray(np.asarray(arr).astype(np_dtype))
        arr.tofile(out / f"{name}.{dtype}")
        tensors[name] = {"file": f"{name}.{dtype}", "shape": list(arr.shape), "dtype": dtype, "meaning": meaning,
                         "max_abs": float(np.abs(arr.astype(np.float64)).max()) if arr.size else 0.0}
        return arr

    save("image_primary", prim, "obs image_primary, frames t0,t1 (NHWC uint8 RGB)", "u8")
    save("image_wrist", wrist, "obs image_wrist, frames t0,t1 (NHWC uint8 RGB)", "u8")
    save("timestep_pad_mask", tpm[0], "obs timestep_pad_mask (1 = valid frame)", "u8")
    save("input_ids", ids, "T5 tokenizer input_ids (t5-base, max_length 16, EOS=1, pad=0)", "i32")
    save("attention_mask", amask, "T5 tokenizer attention_mask (1 = real token); used inside T5 only", "i32")

    # ---------------------------------------------------------------- official sample_actions
    rng = jax.random.PRNGKey(0)
    t0 = time.time()
    act_unnorm = np.asarray(model.sample_actions(obs, tasks, unnormalization_statistics=stats, rng=rng))
    print(f"sample_actions (jit compile + run) {time.time() - t0:.1f} s")
    act_norm_official = np.asarray(model.sample_actions(obs, tasks, rng=rng))  # same RNG, no unnormalization

    # ---------------------------------------------------------------- trunk intermediates (official modules)
    def want(mdl, method):
        if method in ("compute_bias", "assemble_input_tokens", "generate_attention_mask"):
            return True
        return method == "__call__" and not isinstance(mdl, BlockTransformer)

    t0 = time.time()
    outs, state = model.module.apply({"params": params}, obs, tasks, obs["timestep_pad_mask"], train=False,
                                     method="octo_transformer", capture_intermediates=want,
                                     mutable=["intermediates"])
    print(f"captured intermediates (eager) in {time.time() - t0:.1f} s")
    inter = flax.traverse_util.flatten_dict(state["intermediates"], sep="/")
    inter = {k: v[0] for k, v in inter.items()}  # each sow is a 1-tuple

    def get(path):
        return inter["octo_transformer/" + path]

    # T5 encoder (inside Octo's forward pass)
    t5 = "task_tokenizers_language/hf_model/encoder/"
    t5_hidden = save("t5_hidden", np.asarray(get("task_tokenizers_language/__call__").tokens[0]),
                     "T5 encoder last_hidden_state (16 x 768), = final_layer_norm output")
    pos_bias = save("t5_position_bias", np.asarray(get(t5 + "block/0/layer/0/SelfAttention/compute_bias")[0]),
                    "T5 relative position bias (12 heads x 16 q x 16 k) from compute_bias, attention mask NOT "
                    "included (T5 adds finfo(f32).min on keys with attention_mask 0)")
    save("t5_embed", np.asarray(get("task_tokenizers_language/hf_model/shared/__call__")[0]),
         "T5 token embeddings (16 x 768), shared[input_ids]")
    for i in range(12):
        save(f"t5_block{i}", np.asarray(get(t5 + f"block/{i}/__call__")[0][0]),
             f"T5 hidden state after encoder block {i} (16 x 768), before final_layer_norm")

    # SmallStem16 of image_primary, frame 0 (batch*time index 0)
    stem = "observation_tokenizers_primary/SmallStem16_0/"
    for k in range(4):
        conv = np.asarray(get(stem + f"StdConv_{k}/__call__")[0])
        gn = np.asarray(get(stem + f"GroupNorm_{k}/__call__")[0])
        save(f"stem{k}_conv", conv, f"primary frame 0, stem stage {k}: StdConv output (NHWC), before GroupNorm")
        save(f"stem{k}", np.maximum(gn, 0), f"primary frame 0, stem stage {k}: conv -> GroupNorm -> ReLU (NHWC)")

    tok_p = get("observation_tokenizers_primary/__call__").tokens[0]
    tok_w = get("observation_tokenizers_wrist/__call__").tokens[0]
    save("tokens_primary", tok_p, "image_primary tokenizer output (2 frames x 256 x 512), before obs_primary_projection")
    save("tokens_wrist", tok_w, "image_wrist tokenizer output (2 frames x 64 x 512), before obs_wrist_projection")

    trunk_in = np.asarray(get("BlockTransformer_0/assemble_input_tokens")[0])
    mask = np.asarray(get("BlockTransformer_0/attention_mask")[0, 0])
    assert np.array_equal(mask, np.asarray(get("BlockTransformer_0/generate_attention_mask")[0, 0]))
    save("trunk_input", trunk_in, "token sequence entering the trunk (690 x 384), Octo's order, pos-embs added")
    save("attn_mask", mask, "trunk attention mask (690 q x 690 k), 1 = may attend; rule mask AND key pad mask", "u8")
    tr = "BlockTransformer_0/Transformer_0/"
    for i in range(12):
        save(f"block{i}", np.asarray(get(tr + f"encoderblock_{i}/__call__")[0]), f"trunk block {i} output (690 x 384)")
    final = save("final_norm", np.asarray(get(tr + "encoder_norm/__call__")[0]), "trunk final LayerNorm output")
    readout = save("readout", np.asarray(outs["readout_action"].tokens[0, :, 0]),
                   "readout_action tokens (2 window positions x 384) = final_norm rows 352 and 689")

    # token layout, read off the groups the official forward built
    order = ["obs_primary", "obs_wrist", "obs_task_language", "readout_action"]
    for g in order:
        assert g in outs, g
    layout = [{"group": "task_language", "timestep": -1, "start": 0, "n": 16}]
    pos = 16
    for t in range(2):
        for g in order:
            n = outs[g].tokens.shape[2]
            layout.append({"group": g, "timestep": t, "start": pos, "n": n})
            pos += n
    assert pos == trunk_in.shape[0] == 690
    for e in layout:  # the split outputs are slices of the final LN output: confirms the order
        ref = outs[e["group"]].tokens[0] if e["timestep"] < 0 else outs[e["group"]].tokens[0, e["timestep"]]
        assert np.array_equal(np.asarray(ref), final[e["start"]:e["start"] + e["n"]]), e

    # cross-check: eager capture vs the jitted run_transformer that sample_actions uses
    tout = model.run_transformer(obs, tasks, obs["timestep_pad_mask"])
    d_readout = float(np.abs(np.asarray(tout["readout_action"].tokens[0, :, 0]) - readout).max())

    # ---------------------------------------------------------------- diffusion head
    head = model.module.bind({"params": params}).heads["action"]
    module, variables = head.unbind()
    betas, alphas, alpha_hats = (np.asarray(x, np.float32) for x in (head.betas, head.alphas, head.alpha_hats))
    steps, adim, hor, max_action = head.diffusion_steps, head.action_dim, head.action_horizon, head.max_action
    shape = (1, 2, adim * hor)

    @jax.jit
    def draw(rng):  # predict_action's PRNG chain: one split for the initial noise, then one split per scan step
        rng, key = jax.random.split(rng)
        noise = jax.random.normal(key, shape)

        def f(rng, _):
            rng, key = jax.random.split(rng)
            return rng, jax.random.normal(key, shape)

        _, zs = jax.lax.scan(f, rng, jnp.arange(steps - 1, -1, -1))
        return noise, zs

    noise, zs = (np.asarray(x) for x in draw(rng))
    # the same chain op by op, outside jit
    r = rng
    r, k = jax.random.split(r)
    eager = [np.asarray(jax.random.normal(k, shape))]
    for _ in range(steps):
        r, k = jax.random.split(r)
        eager.append(np.asarray(jax.random.normal(k, shape)))
    rng_bitwise = bool(np.array_equal(eager[0], noise) and np.array_equal(np.stack(eager[1:]), zs))

    flat_mask = np.ones(shape, bool)
    flat_mask[..., :] = np.tile(np.arange(adim) < len(stats["mean"]), hor)  # embodiment_action_dim = 7: all True

    def update(x, eps, t, z):  # predict_action's scan_fn body, verbatim
        alpha_1 = 1 / jnp.sqrt(head.alphas[t])
        alpha_2 = (1 - head.alphas[t]) / (jnp.sqrt(1 - head.alpha_hats[t]))
        x = alpha_1 * (x - alpha_2 * eps)
        pre = x + (t > 0) * (jnp.sqrt(head.betas[t]) * z)
        x = jnp.clip(pre, -max_action, max_action)
        x = jnp.where(flat_mask, x, jnp.sqrt(1 - head.alpha_hats[t]) * z)
        return x, pre

    @jax.jit
    def rerun(tout, noise, zs):  # the official scan with the recorded noise injected
        def scan_fn(x, inp):
            t, z = inp
            eps = module.apply(variables, tout, jnp.broadcast_to(t, (*x.shape[:-1], 1)), x, train=False)
            x, _ = update(x, eps, t, z)
            return x, x

        return jax.lax.scan(scan_fn, noise, (jnp.arange(steps - 1, -1, -1), zs))

    x_scan, _ = rerun(tout, noise, zs)
    act_scan = np.asarray(x_scan).reshape(1, 2, hor, adim)[0, -1]
    # the official predict_action on the very same transformer outputs, drawing its own noise: isolates the noise
    # reproduction from the (1e-6-level) differences between XLA's compilations of the transformer
    act_pa = np.asarray(jax.jit(lambda tout, rng: head.predict_action(
        tout, rng=rng, train=False, embodiment_action_dim=len(stats["mean"])))(tout, rng))[0]

    @jax.jit
    def head_step(tout, t, x):
        return module.apply(variables, tout, jnp.broadcast_to(t, (*x.shape[:-1], 1)), x, train=False,
                            capture_intermediates=True, mutable=["intermediates"])

    x = jnp.asarray(noise)
    rec = {"t": [], "fourier": [], "cond": [], "eps": [], "x": [], "pre": []}
    for i, t in enumerate(range(steps - 1, -1, -1)):
        t = jnp.int32(t)
        eps, st = head_step(tout, t, x)
        dm = st["intermediates"]["diffusion_model"]
        four = np.asarray(dm["time_preprocess"]["__call__"][0][0])
        cond = np.asarray(dm["cond_encoder"]["__call__"][0][0])
        assert np.array_equal(four[0], four[1]) and np.array_equal(cond[0], cond[1])
        x, pre = update(x, eps, t, zs[i])
        for key, v in (("t", int(t)), ("fourier", four[0]), ("cond", cond[0]), ("eps", np.asarray(eps[0])),
                       ("x", np.asarray(x[0])), ("pre", np.asarray(pre[0]))):
            rec[key].append(v)
    act_steps = np.asarray(x).reshape(1, 2, hor, adim)[0, -1]

    save("diff_noise", noise[0], "initial noise x_T (2 window positions x 28), from PRNGKey(0)'s first split")
    save("diff_z", zs[:, 0], "per-step z (20 steps x 2 x 28), step i uses t = 19 - i; z at t=0 is drawn but unused")
    save("diff_t", np.array(rec["t"]), "per-step diffusion time t (20,), 19..0, fed to the head as an integer",
         "i32")
    save("diff_fourier", np.stack(rec["fourier"]), "per-step time_preprocess output [cos(2 pi t W^T), sin(...)] "
                                                   "(20 x 32)")
    save("diff_cond", np.stack(rec["cond"]), "per-step cond_encoder output (20 x 32), the head's time conditioning")
    save("diff_eps", np.stack(rec["eps"]), "per-step predicted eps (20 x 2 x 28)")
    save("diff_x", np.stack(rec["x"]), "per-step x after the update, noise and clip to [-5, 5] (20 x 2 x 28)")
    save("sched_betas", betas, "head.betas (20,), cosine schedule as the head holds it; indexed by t")
    save("sched_alphas", alphas, "head.alphas = 1 - betas (20,)")
    save("sched_alpha_hats", alpha_hats, "head.alpha_hats = cumprod(alphas) (20,)")
    save("actions_norm", act_steps, "normalized actions (4 x 7), last window position = sample_actions output")
    save("stats_mean", stats["mean"], f"dataset_statistics['{DATASET}']['action']['mean'] (7,)")
    save("stats_std", stats["std"], f"dataset_statistics['{DATASET}']['action']['std'] (7,)")
    save("stats_mask", stats["mask"], f"dataset_statistics['{DATASET}']['action']['mask'] (7,), 1 = unnormalize",
         "u8")
    save("actions", act_unnorm[0], f"unnormalized actions (4 x 7): where(mask, a * std + mean, a), {DATASET}")
    unnorm_check = np.where(stats["mask"], act_steps * stats["std"] + stats["mean"], act_steps)

    checks = {
        "rng_jit_vs_eager_bitwise": rng_bitwise,
        "actions_norm_steps_vs_sample_actions_maxabs": float(np.abs(act_steps - act_norm_official[0]).max()),
        "actions_norm_scan_vs_sample_actions_maxabs": float(np.abs(act_scan - act_norm_official[0]).max()),
        "actions_norm_injected_noise_vs_predict_action_same_transformer_outputs_maxabs":
            float(np.abs(act_scan - act_pa).max()),
        "actions_unnorm_vs_sample_actions_maxabs": float(np.abs(unnorm_check - act_unnorm[0]).max()),
        "readout_eager_capture_vs_jit_run_transformer_maxabs": d_readout,
    }

    # ---------------------------------------------------------------- numerics survey (for the port, not dumped)
    def maxabs(v):
        return float(np.abs(np.asarray(v, np.float64)).max())

    act_max = {}
    for k, v in inter.items():
        if isinstance(v, (jax.Array, np.ndarray)) and np.issubdtype(np.asarray(v).dtype, np.floating):
            act_max[k.removeprefix("octo_transformer/")] = maxabs(v)
        elif isinstance(v, tuple) and isinstance(v[0], (jax.Array, np.ndarray)):
            act_max[k.removeprefix("octo_transformer/")] = maxabs(v[0])
    top = sorted(act_max.items(), key=lambda kv: -kv[1])[:12]
    logits = {}
    allowed = mask.astype(bool)
    for i in range(12):
        q = np.asarray(get(tr + f"encoderblock_{i}/MultiHeadDotProductAttention_0/query/__call__")[0]) / 8.0
        k_ = np.asarray(get(tr + f"encoderblock_{i}/MultiHeadDotProductAttention_0/key/__call__")[0])
        lg = np.einsum("qhd,khd->hqk", q, k_)
        logits[f"trunk{i}"] = float(np.abs(lg[:, allowed]).max())
    keyok = amask.astype(bool)
    for i in range(12):
        q = np.asarray(get(t5 + f"block/{i}/layer/0/SelfAttention/q/__call__")[0]).reshape(16, 12, 64)
        k_ = np.asarray(get(t5 + f"block/{i}/layer/0/SelfAttention/k/__call__")[0]).reshape(16, 12, 64)
        lg = np.einsum("qhd,khd->hqk", q, k_) + pos_bias  # T5: no 1/sqrt(d) scaling
        logits[f"t5_{i}"] = float(np.abs(lg[:, :, keyok]).max())
    gn = {}
    for cam in ("primary", "wrist"):
        for k in range(4):
            xin = np.asarray(get(f"observation_tokenizers_{cam}/SmallStem16_0/StdConv_{k}/__call__"), np.float64)
            n, h, w, c = xin.shape
            g = xin.reshape(n, h * w, 32, c // 32)
            mu = g.mean((1, 3))
            var = g.var((1, 3))
            ex2 = (g ** 2).mean((1, 3))
            gn[f"{cam}{k}"] = {"group_size": c // 32, "min_var": float(var.min()), "max_var": float(var.max()),
                               "max_E[x^2]": float(ex2.max()), "max_mean^2/var": float((mu ** 2 / var).max()),
                               "max_abs_in": float(np.abs(xin).max())}
    numerics = {"largest_intermediates": dict(top), "attention_logit_maxabs_allowed": logits, "groupnorm": gn,
                "diffusion_preclip_maxabs_per_step": [maxabs(p) for p in rec["pre"]],
                "over_30000": {k: v for k, v in act_max.items() if v > 30000},
                "all_intermediates_maxabs": act_max}

    t5_rev = sorted((B / "hf/hub/models--t5-base/snapshots").iterdir())[0].name if (
        B / "hf/hub/models--t5-base/snapshots").exists() else None
    meta = {
        "model": "rail-berkeley/octo-small-1.5", "hf_revision": REV_HF, "code": "octo-models/octo", "code_revision": REV_GH,
        "t5_config_tokenizer": f"t5-base @ {t5_rev}",
        "instruction": INSTRUCTION, "dataset_statistics": DATASET, "rng": "jax.random.PRNGKey(0)",
        "inputs": "obs: image_primary (1,2,256,256,3) + image_wrist (1,2,128,128,3) uint8, timestep_pad_mask "
                  "[[1,1]], pad_mask_dict image_primary/image_wrist/timestep all True; task: create_tasks(texts=[...]) "
                  "-> goal images zeros (uint8, -1.0 after /127.5-1), language pad flag True. Stem input = "
                  "concat([obs RGB, goal RGB], -1) -> 6 channels.",
        "layout": layout,
        "notes": [
            "Files are raw little-endian, C order, no header; shapes below drop the batch dim.",
            "Frame index f in images/tokens = window position t (0, 1); stem dumps are primary frame 0 only.",
            "Trunk LayerNorm/GroupNorm (flax 0.7.5): var = max(0, E[x^2] - E[x]^2) in fp32, y = (x-mu)*rsqrt(var+1e-6)"
            "*scale+bias. GroupNorm: 32 groups (group sizes 1/3/6/12), stats over H, W and the group's channels.",
            "Attention: q/sqrt(64), masked logits = finfo(float32).min, fp32 softmax. MLP GELU = tanh approximation.",
            "Diffusion step (t = 19..0): x = (x - (1-alpha_t)/sqrt(1-alpha_hat_t) * eps) / sqrt(alpha_t); "
            "if t>0: x += sqrt(beta_t) z; x = clip(x, -5, 5). Both window positions are denoised; actions = last.",
        ],
        "checks": checks,
        "numerics": numerics,
        "tensors": tensors,
    }
    (out / "meta.json").write_text(json.dumps(meta, indent=1))

    # ---------------------------------------------------------------- export
    if a.export:
        export(params, pos_bias, weight_standardize, inter, get, tr, prim)

    # ---------------------------------------------------------------- summary
    np.set_printoptions(precision=5, suppress=True, linewidth=120)
    print("\nnormalized actions (4 x 7, last window position):\n", act_steps)
    print(f"unnormalized actions ({DATASET}):\n", act_unnorm[0])
    print("\nchecks:", json.dumps(checks, indent=1))
    print("\nmax |x| of each recorded tensor:")
    for name, t in tensors.items():
        print(f"  {name:20s} {t['dtype']:3s} {str(t['shape']):18s} {t['max_abs']:.6g}")
    print("\nlargest intermediates:", json.dumps(dict(top[:6]), indent=1))
    print("attention logit max |.| (allowed entries):", json.dumps({k: round(v, 2) for k, v in logits.items()}))
    print("over 30000:", numerics["over_30000"])
    print("wrote", len(tensors), "tensors to", out)


def export(params, pos_bias, weight_standardize, inter, get, tr, prim):
    """build/octo/octo_small.safetensors: fp32, flax param path joined by '.', in the layouts a port wants."""
    import jax
    import jax.numpy as jnp
    import numpy as np
    from flax.traverse_util import flatten_dict
    from safetensors.numpy import save_file

    std = jax.jit(functools.partial(weight_standardize, axis=[0, 1, 2], eps=1e-5))
    sd, lines = {}, []
    for path, w in flatten_dict(params).items():
        name = ".".join(path)
        w = np.asarray(w, np.float32)
        parent, leaf = path[-2], path[-1]
        if leaf == "kernel" and w.ndim == 4:
            if parent.startswith("StdConv"):
                w = np.asarray(std(jnp.asarray(w)))
                how = "StdConv: standardized (w-mean)/(std+1e-5) over H,W,I (Octo's weight_standardize, fp32); " \
                      "HWIO -> OHWI"
            else:
                how = "conv HWIO -> OHWI"
            w = w.transpose(3, 0, 1, 2)
            if w.shape[1:3] == (1, 1):
                w = w.reshape(w.shape[0], w.shape[3])
                how = "1x1 conv HWIO (1,1,I,O) -> (O,I)"
        elif leaf == "kernel" and w.ndim == 3 and parent in ("query", "key", "value"):
            w = w.reshape(w.shape[0], -1).T
            how = "attention q/k/v (in, heads, 64) -> (in, heads*64) -> (out, in)"
        elif leaf == "kernel" and w.ndim == 3 and parent == "out":
            w = w.reshape(-1, w.shape[-1]).T
            how = "attention out (heads, 64, out) -> (heads*64, out) -> (out, in)"
        elif leaf == "bias" and w.ndim == 2:
            w = w.reshape(-1)
            how = "attention bias (heads, 64) -> (heads*64,)"
        elif leaf == "kernel" and w.ndim == 2 and parent != "time_preprocess":
            w = w.T
            how = "Dense (in, out) -> (out, in)"
        else:
            how = "as stored"
        sd[name] = np.ascontiguousarray(w, np.float32)
        lines.append(f"{name}\t{list(sd[name].shape)}\t{how}")
    sd["t5.position_bias"] = np.ascontiguousarray(pos_bias, np.float32)
    lines.append(f"t5.position_bias\t{list(pos_bias.shape)}\tderived: T5 compute_bias for 16 tokens "
                 "(heads, q, k), mask not included")

    # self-checks of the layouts against the captured activations
    ot = "octo_transformer."
    stem = ot + "observation_tokenizers_primary.SmallStem16_0."
    x0 = jnp.asarray(np.concatenate([prim[:1].astype(np.float32) / 127.5 - 1.0,
                                     np.full((1, 256, 256, 3), -1.0, np.float32)], -1))
    k0 = jnp.asarray(sd[stem + "StdConv_0.kernel"].transpose(1, 2, 3, 0))
    c0 = jax.lax.conv_general_dilated(x0, k0, (2, 2), ((1, 1), (1, 1)), dimension_numbers=("NHWC", "HWIO", "NHWC"))
    c0 = np.asarray(c0) + sd[stem + "StdConv_0.bias"]
    d_conv = float(np.abs(c0[0] - np.asarray(get("observation_tokenizers_primary/SmallStem16_0/StdConv_0/__call__")[0])).max())
    blk = ot + "BlockTransformer_0.Transformer_0.encoderblock_0."
    ln0 = np.asarray(get(tr + "encoderblock_0/LayerNorm_0/__call__")[0])
    q = ln0 @ sd[blk + "MultiHeadDotProductAttention_0.query.kernel"].T + sd[blk + "MultiHeadDotProductAttention_0.query.bias"]
    d_q = float(np.abs(q - np.asarray(get(tr + "encoderblock_0/MultiHeadDotProductAttention_0/query/__call__")[0]).reshape(690, 384)).max())
    tp = np.asarray(get("observation_tokenizers_primary/__call__").tokens[0, 0])
    pp = tp @ sd[ot + "obs_primary_projection.kernel"].T + sd[ot + "obs_primary_projection.bias"]
    d_p = float(np.abs(pp - np.asarray(get("obs_primary_projection/__call__")[0, 0])).max())
    lines.insert(0, f"# {len(sd)} tensors, fp32. Layout self-checks vs captured activations (max |diff|): "
                    f"StdConv_0 {d_conv:.2e}, block0 query {d_q:.2e}, obs_primary_projection {d_p:.2e}")
    lines.insert(1, "# name\tshape\tconversion from the flax checkpoint")
    save_file(sd, str(B / "octo_small.safetensors"), metadata={"source": f"rail-berkeley/octo-small-1.5@{REV_HF}"})
    (B / "export_names.txt").write_text("\n".join(lines) + "\n")
    print(f"wrote {B / 'octo_small.safetensors'} ({len(sd)} tensors); layout checks: conv {d_conv:.2e}, "
          f"query {d_q:.2e}, projection {d_p:.2e}")


if __name__ == "__main__":
    main()
