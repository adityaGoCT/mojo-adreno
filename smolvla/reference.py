"""SmolVLA (lerobot/smolvla_base) in PyTorch on the Mac: the reference the phone's Mojo forward pass is checked against.

Runs lerobot 0.6.1's own SmolVLAPolicy in fp32 on the CPU on one fixed example (three procedurally drawn camera
images, a task, a robot state, noise from a fixed seed) and saves, as raw little-endian fp32/int32 files:

  inputs   pixels.f32   [3 cameras, 3, 512, 512]  the images after the policy's resize_with_pad and [-1, 1] scaling
           tokens.i32   [48]                      the task's token ids (right-padded to 48), lang_mask.i32 [48]
           rope.f32     [2, 512, 32]              cos, then sin, of apply_rope's angles for positions 0..511, as
                                                  apply_rope computes them (fp32)
           state.f32    [32]                      the state, zero-padded to max_state_dim
           noise.f32    [50, 32]                  x_1 of the flow, torch.manual_seed(SEED)
  stages   vision.f32   [3, 1024, 768]            SigLIP's last hidden state (after post_layernorm), per camera
           connector.f32 [3, 64, 960]             pixel shuffle + modality projection, per camera
           prefix.f32   [241, 960]                the prefix embeddings: image tokens * sqrt(960), language * sqrt(960), state
           k<l>.f32, v<l>.f32 [241, 320]          the prefix K/V cache of language layer l (K after RoPE)
           v_t<s>.f32   [50, 32]                  the velocity of Euler step s (s = 0..9)
           x_t<s>.f32   [50, 32]                  x after step s; x_t9 is the action chunk
           actions.f32  [50, 32]                  predict_action_chunk's actions before unpadding (== x_t9)
           actions_mixed.f32 [50, 6]              predict_action_chunk with the policy as lerobot loads it (bf16 VLM)
  meta.json  shapes, the task, the prefix layout

  build/vla/venv/bin/python smolvla/reference.py [--out build/vla/smolvla/ref]

The checkpoint is build/vla/hf/smolvla_base (lerobot/smolvla_base at 5e8d12a6), SmolVLM2's config and tokenizer
build/vla/hf/smolvlm2; the VLM's own weights are not needed (load_vlm_weights=False): smolvla_base holds them.
"""

import argparse
import json
import math
import pathlib

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
HF = ROOT / "build/vla/hf"
SEED = 0
TASK = "Pick up the red cube and place it in the blue bowl."
STATE = [0.31, -1.12, 0.84, 0.05, -0.47, 1.36]  # already normalized (the checkpoint ships no state statistics)


def draw_images(n=3, size=256, seed=SEED):
    """n RGB images in [0, 1]: a smooth background, colored boxes and discs, mild noise; deterministic."""
    g = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32) / size
    out = []
    for _ in range(n):
        img = np.empty((3, size, size), np.float32)
        a, b, c = g.uniform(0.2, 0.8, 3)
        img[0] = a + 0.2 * xx - 0.1 * yy
        img[1] = b - 0.15 * xx + 0.2 * yy
        img[2] = c + 0.1 * np.sin(6.28 * (xx + yy))
        for _ in range(4):
            color = g.uniform(0, 1, 3).astype(np.float32)
            x0, y0 = g.uniform(0.05, 0.75, 2)
            w, h = g.uniform(0.08, 0.3, 2)
            if g.uniform() < 0.5:
                m = (xx >= x0) & (xx < x0 + w) & (yy >= y0) & (yy < y0 + h)
            else:
                m = (xx - x0 - w / 2) ** 2 + (yy - y0 - h / 2) ** 2 < (min(w, h) / 2) ** 2
            img[:, m] = color[:, None]
        img += g.normal(0, 0.02, img.shape).astype(np.float32)
        out.append(np.clip(img, 0, 1))
    return torch.from_numpy(np.stack(out))


def save(out, name, t):
    a = t.detach().cpu().contiguous().numpy()
    a = a.astype(np.int32 if name.endswith(".i32") else np.float32)
    a.tofile(out / name)
    return list(a.shape)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "build/vla/smolvla/ref"))
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    from lerobot.configs.policies import PreTrainedConfig
    from lerobot.policies.smolvla.modeling_smolvla import SmolVLAPolicy
    from lerobot.utils.constants import OBS_LANGUAGE_ATTENTION_MASK, OBS_LANGUAGE_TOKENS, OBS_STATE
    from lerobot.policies.common.vla_utils import make_att_2d_masks
    from transformers import AutoTokenizer

    torch.set_grad_enabled(False)
    cfg = PreTrainedConfig.from_pretrained(HF / "smolvla_base")
    cfg.vlm_model_name = str(HF / "smolvlm2")
    cfg.load_vlm_weights = False  # the VLM's weights are in smolvla_base's model.safetensors
    cfg.device = "cpu"
    policy = SmolVLAPolicy.from_pretrained(HF / "smolvla_base", config=cfg, strict=True)
    policy.eval()
    # As loaded, lerobot keeps the VLM and the expert's layers in bf16 (their config's dtype) and the
    # projections in fp32. The reference is all fp32 (the bf16 weights widened, exactly); the policy as
    # loaded runs once too, for comparison.
    mixed = sorted({str(p.dtype) for p in policy.parameters()})

    # The example: the batch the policy's preprocessor would produce (the task with its newline, tokenized
    # right-padded to 48; the state as given, already normalized).
    tok = AutoTokenizer.from_pretrained(HF / "smolvlm2")
    enc = tok(TASK + "\n", padding="max_length", max_length=cfg.tokenizer_max_length, truncation=True,
              padding_side="right", return_tensors="pt")
    images = draw_images()
    batch = {f"observation.images.camera{i + 1}": images[i:i + 1] for i in range(3)}
    batch[OBS_STATE] = torch.tensor([STATE], dtype=torch.float32)
    batch[OBS_LANGUAGE_TOKENS] = enc["input_ids"]
    batch[OBS_LANGUAGE_ATTENTION_MASK] = enc["attention_mask"].bool()
    torch.manual_seed(SEED)
    noise = torch.randn(1, cfg.chunk_size, cfg.max_action_dim, dtype=torch.float32)

    # The official path: predict_action_chunk with this noise, as loaded (bf16 VLM) and in fp32.
    policy.reset()
    official_mixed = policy.predict_action_chunk(dict(batch), noise=noise.clone())  # [1, 50, 6]
    policy.to(torch.float32)
    assert {p.dtype for p in policy.parameters()} == {torch.float32}
    policy.reset()
    official = policy.predict_action_chunk(dict(batch), noise=noise.clone())

    # The same, stage by stage, through the model's own methods (sample_actions, unrolled).
    model = policy.model
    vwe = model.vlm_with_expert
    imgs, img_masks = policy.prepare_images(dict(batch))
    state = policy.prepare_state(dict(batch))
    lang_tokens, lang_masks = batch[OBS_LANGUAGE_TOKENS], batch[OBS_LANGUAGE_ATTENTION_MASK]
    vision = [vwe.get_vlm_model().vision_model(pixel_values=im).last_hidden_state for im in imgs]
    conn = [vwe.get_vlm_model().connector(v) for v in vision]
    for im, c in zip(imgs, conn):
        assert torch.equal(vwe.embed_image(im), c)
    prefix_embs, prefix_pad, prefix_att = model.embed_prefix(imgs, img_masks, lang_tokens, lang_masks, state=state)
    prefix_2d = make_att_2d_masks(prefix_pad, prefix_att)
    prefix_pos = torch.cumsum(prefix_pad, dim=1) - 1
    _, cache = vwe.forward(attention_mask=prefix_2d, position_ids=prefix_pos, past_key_values=None,
                           inputs_embeds=[prefix_embs, None], use_cache=True)
    kv = [(cache.layers[l].keys.transpose(1, 2).reshape(1, -1, 320)[0],
           cache.layers[l].values.transpose(1, 2).reshape(1, -1, 320)[0]) for l in range(vwe.num_vlm_layers)]
    x_t = noise.clone()
    steps = cfg.num_steps
    dt = -1.0 / steps
    vts, xts = [], []
    for s in range(steps):
        t = torch.tensor(1.0 + s * dt, dtype=torch.float32).expand(1)
        v_t = model.denoise_step(x_t=x_t, prefix_pad_masks=prefix_pad, past_key_values=cache, timestep=t)
        x_t = x_t + dt * v_t
        vts.append(v_t[0])
        xts.append(x_t[0])
    assert torch.equal(x_t[:, :, :official.shape[-1]], official), (x_t[:, :, :6] - official).abs().max()

    files_mixed = save(out, "actions_mixed.f32", official_mixed[0])
    meta = {"task": TASK, "loaded_dtypes": mixed,
            "mixed_vs_fp32_max_abs": float((official_mixed - official).abs().max()), "seed": SEED, "state": STATE, "checkpoint": "lerobot/smolvla_base@5e8d12a6",
            "lerobot": __import__("lerobot").__version__, "torch": torch.__version__,
            "transformers": __import__("transformers").__version__,
            "n_lang": int(lang_masks.sum()), "prefix_len": int(prefix_embs.shape[1]),
            "prefix_valid": int(prefix_pad.sum()), "steps": steps, "chunk": cfg.chunk_size, "files": {}}
    files = meta["files"]
    files["pixels.f32"] = save(out, "pixels.f32", torch.cat(imgs, 0))
    files["tokens.i32"] = save(out, "tokens.i32", lang_tokens[0])
    files["lang_mask.i32"] = save(out, "lang_mask.i32", lang_masks[0])
    files["state.f32"] = save(out, "state.f32", state[0])
    # apply_rope's tables (smolvlm_with_expert.apply_rope: max_wavelength 10000, fp32), positions 0..511
    freq = (2.0 / 64) * torch.arange(32, dtype=torch.float32)
    radians = torch.arange(512, dtype=torch.float32)[:, None] / (10_000 ** freq)[None, :]
    files["rope.f32"] = save(out, "rope.f32", torch.stack([torch.cos(radians), torch.sin(radians)]))
    files["noise.f32"] = save(out, "noise.f32", noise[0])
    files["vision.f32"] = save(out, "vision.f32", torch.cat(vision, 0))
    files["connector.f32"] = save(out, "connector.f32", torch.cat(conn, 0))
    files["prefix.f32"] = save(out, "prefix.f32", prefix_embs[0])
    for l, (k, v) in enumerate(kv):
        files[f"k{l}.f32"] = save(out, f"k{l}.f32", k)
        files[f"v{l}.f32"] = save(out, f"v{l}.f32", v)
    for s in range(steps):
        files[f"v_t{s}.f32"] = save(out, f"v_t{s}.f32", vts[s])
        files[f"x_t{s}.f32"] = save(out, f"x_t{s}.f32", xts[s])
    files["actions.f32"] = save(out, "actions.f32", x_t[0])
    files["actions_mixed.f32"] = files_mixed
    (out / "meta.json").write_text(json.dumps(meta, indent=1))
    print("tokens:", lang_tokens[0, :meta["n_lang"]].tolist())
    print("prefix:", meta["prefix_len"], "rows,", meta["prefix_valid"], "valid")
    print("actions[0, :6]:", [round(v, 5) for v in x_t[0, 0, :6].tolist()])
    print("as loaded (dtypes", mixed, ") vs fp32: max abs", meta["mixed_vs_fp32_max_abs"])
    print("saved to", out)


if __name__ == "__main__":
    main()
