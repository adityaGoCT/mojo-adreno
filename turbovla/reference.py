"""TurboVLA (H-EmbodVis/TurboVLA, LIBERO checkpoint) in fp32 on the Mac's CPU: the reference the device ports are checked
against. It builds the official model (build/turbovla/src, the GitHub repo at a pinned revision) with transformers 4.56,
loads the checkpoint, runs one action chunk on fixed inputs, and writes every stage's tensors to build/turbovla/ref:

  build/turbovla/venv/bin/python turbovla/reference.py            # writes build/turbovla/ref
  build/turbovla/venv/bin/python turbovla/reference.py --export   # also build/turbovla/turbovla.safetensors (fp32)

Inputs (no simulator): two procedurally drawn 256 x 256 RGB views (agentview, wrist), already in the model's orientation,
normalized with ImageNet's mean and std as the policy does; the LIBERO instruction "put the bowl on the plate" (BERT
padding group 11, zero-extended to the model's 21 text tokens); a seeded 8-dim state, already z-scored.

DINOv3's config and preprocessor come from the gated facebook/dinov3-vitb16-pretrain-lvd1689m. Its ViT-B/16 config is
rebuilt here (the shapes match the checkpoint's tensors; transformers' DINOv3ViTConfig defaults are ViT-B's), and the
model is created with random weights, which load_state_dict then replaces with the checkpoint's fine-tuned ones. BERT is
bert-base-uncased's config and tokenizer, its weights likewise replaced by the checkpoint's.
"""

import argparse
import json
import pathlib
import sys
import urllib.request

import numpy as np
import torch

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/turbovla"
sys.path.insert(0, str(B / "src"))
REV_HF = "9cdb576ed9c56039b9c1149142ed654e876bad76"
BERT_REV = "86b5e0934494bd15c9632b12f734a8a67f723594"
INSTRUCTION = "put the bowl on the plate"
MEAN = [0.485, 0.456, 0.406]
STD = [0.229, 0.224, 0.225]


def local_dirs():
    """build/turbovla/{dinov3,bert}: configs, tokenizer and placeholder weights for from_pretrained."""
    from transformers import BertConfig, BertModel, DINOv3ViTConfig, DINOv3ViTModel

    d = B / "dinov3"
    if not (d / "model.safetensors").exists():
        cfg = DINOv3ViTConfig(patch_size=16, hidden_size=768, intermediate_size=3072, num_hidden_layers=12,
                              num_attention_heads=12, hidden_act="gelu", layer_norm_eps=1e-5, rope_theta=100.0,
                              image_size=224, query_bias=True, key_bias=False, value_bias=True, proj_bias=True,
                              mlp_bias=True, layerscale_value=1.0, use_gated_mlp=False, num_register_tokens=4,
                              pos_embed_rescale=2.0)
        DINOv3ViTModel(cfg).save_pretrained(d)
        (d / "preprocessor_config.json").write_text(json.dumps({"image_mean": MEAN, "image_std": STD}))
    t = B / "bert"
    if not (t / "model.safetensors").exists():
        t.mkdir(parents=True, exist_ok=True)
        for f in ("config.json", "tokenizer.json", "tokenizer_config.json", "vocab.txt"):
            url = f"https://huggingface.co/google-bert/bert-base-uncased/resolve/{BERT_REV}/{f}"
            (t / f).write_bytes(urllib.request.urlopen(url).read())
        BertModel(BertConfig.from_pretrained(t), add_pooling_layer=True).save_pretrained(t)
    return d, t


def scene(seed, size=256):
    """A procedurally drawn RGB view (uint8 HWC): a gradient floor and a few colored boxes and discs."""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:size, 0:size].astype(np.float32) / size
    img = np.stack([0.35 + 0.3 * y, 0.3 + 0.2 * x, 0.25 + 0.25 * (1 - y)], -1)
    for _ in range(6):
        c = rng.uniform(0.05, 0.95, 3)
        cx, cy, r = rng.uniform(0.1, 0.9), rng.uniform(0.2, 0.9), rng.uniform(0.04, 0.15)
        if rng.random() < 0.5:
            m = (np.abs(x - cx) < r) & (np.abs(y - cy) < r * 0.7)
        else:
            m = (x - cx) ** 2 + (y - cy) ** 2 < r * r
        img[m] = c
    img += rng.normal(0, 0.02, img.shape)
    return (np.clip(img, 0, 1) * 255).round().astype(np.uint8)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=pathlib.Path, default=B / "ref")
    ap.add_argument("--export", action="store_true", help="also write the checkpoint as safetensors (fp32)")
    a = ap.parse_args()
    torch.manual_seed(0)
    dinov3_dir, bert_dir = local_dirs()

    from turbovla.models.configuration import TurboVLAConfig
    from turbovla.models.turbovla import TurboVLA

    ck = torch.load(B / "hf/turbovla_libero.pth", map_location="cpu", weights_only=True)
    cfg = dict(ck["model_config"])
    cfg["text"] = dict(cfg["text"], model_name_or_path=str(bert_dir), local_files_only=True)
    cfg["vision"] = dict(cfg["vision"], model_name_or_path=str(dinov3_dir), local_files_only=True,
                         compute_precision="fp32")
    model = TurboVLA(TurboVLAConfig.from_mapping(cfg))
    missing = model.load_state_dict(ck["model_state_dict"], strict=True)
    model = model.float().eval()
    print("loaded", sum(p.numel() for p in model.parameters()), "parameters;", missing)

    views = np.stack([scene(1), scene(2)])  # agentview, wrist
    pix = torch.from_numpy(views).permute(0, 3, 1, 2).float() / 255
    pix = (pix - torch.tensor(MEAN).view(1, 3, 1, 1)) / torch.tensor(STD).view(1, 3, 1, 1)
    pix = pix.unsqueeze(0)  # [1, 2, 3, 256, 256]
    state = torch.from_numpy(np.random.default_rng(3).normal(0, 1, (1, 8)).astype(np.float32))

    out = a.out
    out.mkdir(parents=True, exist_ok=True)
    saved = {}

    def save(name, t):
        arr = t.detach().float().contiguous().numpy()
        arr.tofile(out / f"{name}.f32")
        saved[name] = list(arr.shape)

    # the text side, as TurboVLATextEncoder computes it, plus its inputs for the device (ids, masks, positions)
    enc = model.text_encoder
    group = int(cfg["text"]["padding_length_by_instruction"].get(INSTRUCTION, cfg["text"]["padding_length"]))
    tok, self_mask, pos = enc._tokenize_group([INSTRUCTION], torch.device("cpu"), group)
    T = int(cfg["text"]["padding_length"])
    ids = np.zeros(T, np.int32)
    ids[:group] = tok["input_ids"][0].numpy()
    posid = np.zeros(T, np.int32)
    posid[:group] = pos[0].numpy()
    bert_mask = np.eye(T, dtype=np.int32)  # BERT's 3-D mask (1 = may attend), zero-extended like encode_bert_hidden
    bert_mask[:group, :group] = self_mask[0].numpy()
    keypad = np.ones(T, np.int32)  # 1 = a padding key (masked for the vision queries)
    keypad[:group] = 1 - tok["attention_mask"][0].numpy()
    for name, arr in (("text_ids", ids), ("text_pos", posid), ("text_mask", bert_mask), ("text_keypad", keypad)):
        arr.astype(np.int32).tofile(out / f"{name}.i32")
        saved[name] = list(arr.shape)

    with torch.no_grad():
        text_tokens, text_kpm, text_sam = enc([INSTRUCTION], torch.device("cpu"))
        assert np.array_equal(text_kpm[0].numpy().astype(np.int32), keypad)
        assert np.array_equal(text_sam[0].numpy().astype(np.int32), bert_mask)
        hidden, _, _ = enc.encode_bert_hidden([INSTRUCTION], torch.device("cpu"))
        save("bert_hidden", hidden[0])
        save("text_tokens", text_tokens[0])

        save("pixels", pix[0])
        dino = model.vision_encoder(pix)  # [1, 2, 256, 768], CLS and registers dropped
        save("dinov3", dino[0])
        vis = model.encode_vision(pix)  # [1, 512, 256]
        save("vision_tokens", vis[0])

        inter = model.vision_language_interaction
        v, l = vis, text_tokens
        for i, (fusion, text_layer) in enumerate(zip(inter.fusion_layers, inter.text_layers)):
            v, l = fusion(v=v, l=l, attention_mask_v=None, attention_mask_l=text_kpm)
            save(f"fusion{i}_v", v[0])
            save(f"fusion{i}_l", l[0])
            l = text_layer(src=l.transpose(0, 1), src_mask=~text_sam, src_key_padding_mask=text_kpm,
                           pos=None).transpose(0, 1)
            save(f"text{i}", l[0])
        condition = torch.cat([v, l], 1)
        cond_ref = model.encode_condition([INSTRUCTION], pix)
        print("condition: stage-by-stage vs encode_condition max |diff|", float((condition - cond_ref).abs().max()))
        save("condition", condition[0])

        head = model.action_head
        save("state", state[0])
        st = head.state_projection(state)
        save("state_tokens", st[0])
        memory = torch.cat([condition, st], 1)
        save("memory", memory[0])
        dec = head.decoder
        x = dec.action_queries.weight.unsqueeze(0)
        for i, layer in enumerate(dec.decoder.layers):
            x = layer(x, memory)
            save(f"decoder{i}", x[0])
        actions = torch.tanh(dec.action_projection(x))
        save("actions", actions[0])
        whole = model([INSTRUCTION], pix, state)
        print("actions: stage-by-stage vs model() max |diff|", float((actions - whole).abs().max()))

    (out / "meta.json").write_text(json.dumps({"instruction": INSTRUCTION, "text_group": group, "tensors": saved},
                                              indent=1))
    print("actions (12 x 7, normalized):\n", np.round(actions[0].numpy(), 4))
    print("wrote", len(saved), "tensors to", out)

    if a.export:
        from safetensors.torch import save_file
        sd = {k: v.float().contiguous() for k, v in model.state_dict().items()}
        save_file(sd, str(B / "turbovla.safetensors"))
        print("wrote", B / "turbovla.safetensors", len(sd), "tensors")


if __name__ == "__main__":
    main()
