"""π0 (lerobot/pi0_base, lerobot's port of openpi's PyTorch π0) in PyTorch on the Mac: the reference the phone's Mojo
forward pass is checked against.

The checkpoint is fp32 (14 GB), but every matrix of SigLIP, Gemma and the expert, and the embedding, holds values
that bf16 represents exactly (their low 16 bits are zero); only the action and state projections are real fp32.
So the model is built by lerobot (PI0Policy, on the meta device) and given those tensors in bf16, the rest in
fp32, and every nn.Linear / nn.Embedding / nn.Conv2d / nn.LayerNorm widens its weight to fp32 when it runs
(widen_weights; keep_fp32_activations turns off lerobot's switch to bf16 activations for bf16-stored weights):
the same fp32 arithmetic as the fp32 checkpoint, in 6.5 GB instead of 14 (the Mac has 17). The two output heads (lm_head) are
not used by π0 and stay unloaded.

One fixed example (three procedurally drawn 224 x 224 camera images, a 32-dim state, noise from a fixed seed) and
fixed token ids for the instruction: PaliGemma's tokenizer (google/paligemma-3b-pt-224) is gated, so the ids are
BOS, 13 arbitrary ids and "\\n" (108), right-padded to 48. Saved as raw little-endian fp32/int32 files:

  inputs   pixels.f32   [3, 3, 224, 224]   the images in [-1, 1]
           tokens.i32 / lang_mask.i32 [48]
           state.f32    [32]
           noise.f32    [50, 32]
           rope.f32     [2, 1024, 128]     Gemma's RoPE cos and sin (first half) for positions 0..1023
  stages   vision.f32   [3, 256, 1152]     SigLIP So400m's output (after post_layernorm)
           image.f32    [3, 256, 2048]     the projector's output: the prefix's image rows
           prefix.f32   [816, 2048]        the prefix embeddings (images, then the 48 language rows)
           k<l>.f32, v<l>.f32 [816, 256]   Gemma 2B's K (after RoPE) and V cache of layer l
           v_t<s>.f32, x_t<s>.f32 [50, 32] each Euler step's velocity and x after it; x_t9 = the action chunk
           actions.f32  [50, 32]           predict_action_chunk's actions before unpadding
  meta.json

  build/vla/venv/bin/python pi0/reference.py [--out build/vla/pi0/ref]
"""

import argparse
import json
import pathlib

import numpy as np
import torch
import torch.nn.functional as F

ROOT = pathlib.Path(__file__).resolve().parents[1]
HF = ROOT / "build/vla/hf"
SEED = 0
TOKENS = [2, 4985, 908, 573, 3118, 28660, 578, 2040, 665, 575, 573, 3868, 14581, 235265, 108]
SKIP = {"paligemma_with_expert.gemma_expert.lm_head.weight"}  # unused by π0


def draw_images(n=3, size=224, seed=SEED):
    """n RGB images in [0, 1]: a smooth background, colored boxes and discs, mild noise; deterministic."""
    g = np.random.default_rng(seed + 1)
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
    a = t.detach().float().cpu().contiguous().numpy() if not name.endswith(".i32") else t.cpu().numpy()
    a.astype(np.int32 if name.endswith(".i32") else np.float32).tofile(out / name)
    return list(a.shape)


def widen_weights():
    """nn.Linear, nn.Embedding, nn.Conv2d and nn.LayerNorm compute with their weights in fp32 whatever they are
    stored in (Gemma's RMSNorm widens its weight itself)."""
    def linear(self, x):
        return F.linear(x, self.weight.float(), None if self.bias is None else self.bias.float())

    def embedding(self, x):
        return F.embedding(x, self.weight, self.padding_idx).float()

    def conv(self, x):
        return self._conv_forward(x, self.weight.float(), None if self.bias is None else self.bias.float())

    def scaled_embedding(self, x):  # the scale in fp32, as with the fp32 checkpoint (not rounded to bf16)
        return embedding(self, x) * self.embed_scale.float()

    from transformers.models.gemma.modeling_gemma import GemmaTextScaledWordEmbedding

    def layer_norm(self, x):
        return F.layer_norm(x, self.normalized_shape, self.weight.float(), self.bias.float(), self.eps)

    torch.nn.LayerNorm.forward = layer_norm
    torch.nn.Linear.forward = linear
    torch.nn.Embedding.forward = embedding
    torch.nn.Conv2d.forward = conv
    GemmaTextScaledWordEmbedding.forward = scaled_embedding


def keep_fp32_activations():
    """lerobot casts activations to bf16 when a layer's weight is stored in bf16 (PiGemmaModel.forward,
    compute_layer_complete); here bf16 is storage only, so those two checks are turned off: the source of each
    function with that one condition replaced by False."""
    import inspect
    import textwrap

    from lerobot.policies import pi_gemma
    from lerobot.policies.pi0 import modeling_pi0

    def patch(module, func, old):
        src = textwrap.dedent(inspect.getsource(func))
        assert src.count(old) == 1, old
        ns = {}
        exec(compile(src.replace(old, "if False:"), inspect.getsourcefile(module), "exec"), module.__dict__, ns)
        return ns[func.__name__]

    pi_gemma.PiGemmaModel.forward = patch(
        pi_gemma, pi_gemma.PiGemmaModel.forward,
        "if len(self.layers) > 0 and self.layers[0].self_attn.q_proj.weight.dtype == torch.bfloat16:")
    modeling_pi0.compute_layer_complete = patch(modeling_pi0, modeling_pi0.compute_layer_complete,
                                                "if layer.mlp.up_proj.weight.dtype == torch.bfloat16:")


def load_policy():
    from lerobot.configs.policies import PreTrainedConfig
    from lerobot.policies.pi0.modeling_pi0 import PI0Policy
    from safetensors import safe_open

    cfg = PreTrainedConfig.from_pretrained(HF / "pi0_base")
    cfg.device = "meta"
    cfg.dtype = "float32"
    with torch.device("meta"):
        policy = PI0Policy(cfg)
    names = {"bf16": 0, "fp32": 0}
    state = {}
    with safe_open(HF / "pi0_base/model.safetensors", "pt") as f:
        for key in f.keys():
            if key in SKIP:
                continue
            t = f.get_tensor(key)
            if (t.view(torch.int32) & 0xFFFF).any():
                names["fp32"] += 1
            else:
                t = t.to(torch.bfloat16)  # exact
                names["bf16"] += 1
            new = "action_" + key if key.startswith(("time_mlp_in.", "time_mlp_out.")) else key
            if key == "paligemma_with_expert.paligemma.lm_head.weight":  # tied: the language embedding
                state["model.paligemma_with_expert.paligemma.model.language_model.embed_tokens.weight"] = t
                continue
            state["model." + new] = t
    missing, unexpected = policy.load_state_dict(state, strict=False, assign=True)
    missing = [m for m in missing if "lm_head" not in m]
    assert not missing and not unexpected, (missing[:5], unexpected[:5])
    # Non-persistent buffers are not in the checkpoint and are still on meta: SigLIP's position ids, and the RoPE
    # modules' frequencies, which are rebuilt on the CPU from their configs.
    for name, mod in list(policy.named_modules()):
        if "Rotary" in type(mod).__name__ and any(b.is_meta for b in mod.buffers(recurse=False)):
            parent, _, attr = name.rpartition(".")
            setattr(policy.get_submodule(parent), attr, type(mod)(config=mod.config, device="cpu"))
        elif hasattr(mod, "scalar_embed_scale"):  # Gemma's embedding: x sqrt(2048), kept in fp32
            mod.register_buffer("embed_scale", torch.tensor(mod.scalar_embed_scale, dtype=torch.float32),
                                persistent=False)
        elif hasattr(mod, "position_ids") and getattr(mod, "position_ids").is_meta:
            n = mod.position_ids.shape[-1]
            mod.register_buffer("position_ids", torch.arange(n).expand((1, -1)), persistent=False)
    for name, param in list(policy.named_parameters()):  # the unused heads: empty, on the CPU
        if param.is_meta:
            assert "lm_head" in name, name
            parent, _, attr = name.rpartition(".")
            setattr(policy.get_submodule(parent), attr, torch.nn.Parameter(torch.empty(0), requires_grad=False))
    for name, buf in list(policy.named_buffers()):
        if buf.is_meta:
            raise RuntimeError("buffer left on meta: " + name)
    policy.config.device = "cpu"
    policy.eval()
    return policy, names


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ROOT / "build/vla/pi0/ref"))
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    torch.set_grad_enabled(False)
    widen_weights()
    keep_fp32_activations()

    from lerobot.policies.common.vla_utils import make_att_2d_masks, prepare_attention_masks_4d
    from lerobot.utils.constants import OBS_LANGUAGE_ATTENTION_MASK, OBS_LANGUAGE_TOKENS, OBS_STATE

    policy, kinds = load_policy()
    cfg = policy.config
    images = draw_images()
    keys = ["observation.images.base_0_rgb", "observation.images.left_wrist_0_rgb",
            "observation.images.right_wrist_0_rgb"]
    batch = {k: images[i:i + 1] for i, k in enumerate(keys)}
    g = torch.Generator().manual_seed(SEED + 2)
    batch[OBS_STATE] = torch.randn(1, 32, generator=g).clamp(-2, 2)
    tokens = torch.zeros(1, cfg.tokenizer_max_length, dtype=torch.long)
    tokens[0, :len(TOKENS)] = torch.tensor(TOKENS)
    mask = torch.zeros(1, cfg.tokenizer_max_length, dtype=torch.bool)
    mask[0, :len(TOKENS)] = True
    batch[OBS_LANGUAGE_TOKENS] = tokens
    batch[OBS_LANGUAGE_ATTENTION_MASK] = mask
    torch.manual_seed(SEED)
    noise = torch.randn(1, cfg.chunk_size, cfg.max_action_dim, dtype=torch.float32)

    official = policy.predict_action_chunk(dict(batch), noise=noise.clone())  # [1, 50, 32]

    model = policy.model
    pwe = model.paligemma_with_expert
    imgs, img_masks = policy._preprocess_images(dict(batch))
    state = policy.prepare_state(dict(batch))
    vt = pwe.paligemma.model.vision_tower
    vision = [vt(im).last_hidden_state for im in imgs]
    image = [pwe.embed_image(im) for im in imgs]
    for v, im in zip(vision, image):
        assert torch.equal(pwe.paligemma.model.multi_modal_projector(v), im)
    prefix_embs, prefix_pad, prefix_att = model.embed_prefix(imgs, img_masks, tokens, mask)
    prefix_2d = make_att_2d_masks(prefix_pad, prefix_att)
    prefix_pos = torch.cumsum(prefix_pad, dim=1) - 1
    pwe.paligemma.model.language_model.config._attn_implementation = "eager"
    _, cache = pwe.forward(attention_mask=prepare_attention_masks_4d(prefix_2d), position_ids=prefix_pos,
                           past_key_values=None, inputs_embeds=[prefix_embs, None], use_cache=True)
    kv = [(cache.layers[l].keys[0, 0], cache.layers[l].values[0, 0]) for l in range(len(cache.layers))]
    x_t = noise.clone()
    steps = cfg.num_inference_steps
    dt = -1.0 / steps
    vts, xts = [], []
    for s in range(steps):
        t = torch.tensor(1.0 + s * dt, dtype=torch.float32).expand(1)
        v_t = model.denoise_step(state=state, prefix_pad_masks=prefix_pad, past_key_values=cache, x_t=x_t, timestep=t)
        x_t = x_t + dt * v_t
        vts.append(v_t[0])
        xts.append(x_t[0])
    assert torch.equal(x_t, official), (x_t - official).abs().max()

    rot = pwe.paligemma.model.language_model.rotary_emb
    cos, sin = rot(torch.zeros(1, 1024, 256), torch.arange(1024)[None])
    meta = {"checkpoint": "lerobot/pi0_base@6e245399", "tokens": TOKENS, "seed": SEED, "tensors": kinds,
            "lerobot": __import__("lerobot").__version__, "torch": torch.__version__,
            "transformers": __import__("transformers").__version__, "prefix_len": int(prefix_embs.shape[1]),
            "prefix_valid": int(prefix_pad.sum()), "steps": steps, "chunk": cfg.chunk_size, "files": {}}
    files = meta["files"]
    files["pixels.f32"] = save(out, "pixels.f32", torch.cat(imgs, 0))
    files["tokens.i32"] = save(out, "tokens.i32", tokens[0].int())
    files["lang_mask.i32"] = save(out, "lang_mask.i32", mask[0].int())
    files["state.f32"] = save(out, "state.f32", state[0])
    files["noise.f32"] = save(out, "noise.f32", noise[0])
    files["rope.f32"] = save(out, "rope.f32", torch.stack([cos[0, :, :128], sin[0, :, :128]]))
    files["vision.f32"] = save(out, "vision.f32", torch.cat(vision, 0))
    files["image.f32"] = save(out, "image.f32", torch.cat(image, 0))
    files["prefix.f32"] = save(out, "prefix.f32", prefix_embs[0])
    for l, (k, v) in enumerate(kv):
        files[f"k{l}.f32"] = save(out, f"k{l}.f32", k)
        files[f"v{l}.f32"] = save(out, f"v{l}.f32", v)
    for s in range(steps):
        files[f"v_t{s}.f32"] = save(out, f"v_t{s}.f32", vts[s])
        files[f"x_t{s}.f32"] = save(out, f"x_t{s}.f32", xts[s])
    files["actions.f32"] = save(out, "actions.f32", x_t[0])
    (out / "meta.json").write_text(json.dumps(meta, indent=1))
    print("tensors:", kinds, "| prefix:", meta["prefix_len"], "rows,", meta["prefix_valid"], "valid")
    print("actions[0, :6]:", [round(v, 5) for v in x_t[0, 0, :6].tolist()])
    print("saved to", out)


if __name__ == "__main__":
    main()
