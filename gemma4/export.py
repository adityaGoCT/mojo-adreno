"""Gemma 4 E2B / E4B (text) for the GPU: the layout of gemma4.bin, as recipe.txt for convert.c and manifest.txt for
model.mojo, plus the RoPE tables. Only model.safetensors' header is read (by HTTP range request); the phone downloads
the checkpoint itself and convert.c writes gemma4.bin from it there. fetch.py gives the Mac the same file's needed
byte ranges (a sparse copy), so convert.c writes the same gemma4.bin here for the reference.

  build/vla/venv/bin/python gemma4/export.py --model e2b      # or e4b; writes build/gemma4/<model>/

gemma4.bin, every tensor aligned to 4096 bytes (int4 as llama/kernels' gemv_q4 reads it: symmetric, an fp16 scale per
64 weights of a row, 8 weights a uint32 as 4-bit two's complement, low nibble first; each scale is the one of
max |w| / d, d in 6.5 .. 9, with the least squared error, as qwen3moe/convert.c picks it):
  head.q / .s             int4 [V, D]              the output head: the tied token embedding, quantized
  final_norm              fp32 [D]
  ple_proj.q / .s         int4 [L * 256, D]        per_layer_model_projection
  ple_norm                fp32 [256]               per_layer_projection_norm
  l<i>.in_norm, .post_attn_norm, .pre_ff_norm, .post_ff_norm, .ple_norm   fp32 [D]
  l<i>.q_norm, .k_norm    fp32 [head dim]          (k_norm only in layers with their own K and V)
  l<i>.qkv.q / .s         int4 [(H + 2 KVH) hd, D] q, k, v fused; only q in a layer that reuses another's K and V
  l<i>.o.q / .s           int4 [D, H hd]
  l<i>.gu.q / .s          int4 [2 F_i, D]          gate rows 0 .. F_i - 1, up rows F_i .. 2 F_i - 1
  l<i>.down.q / .s        int4 [D, F_i]
  l<i>.pg.q / .s          int4 [256, D]            per_layer_input_gate
  l<i>.pp.q / .s          int4 [D, 256]            per_layer_projection
  l<i>.scalar             fp32 [1]                 layer_scalar

The token embedding (input side) and the per-layer embedding stay in model.safetensors as bf16: the program reads a
token's rows from there (the manifest's `table` lines give their absolute offsets), so they are exact. The per-layer
embedding alone is 4.7 GB (E2B) or 5.6 GB (E4B), more than the GPU needs to hold for one row a token.
"""

import argparse
import json
import pathlib
import struct
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
MODELS = {  # the instruction-tuned checkpoints, pinned
    "e2b": ("google/gemma-4-E2B-it", "4adf15748de9e1a0097b6274cee9c15836c41c37"),
    "e4b": ("google/gemma-4-E4B-it", "4ecc2ba63bcac23ba4a767fc87025b1450f84c9c"),
}
FILES = ["config.json", "generation_config.json", "tokenizer.json", "tokenizer_config.json", "chat_template.jinja"]
P = "model.language_model."
G4 = 64
ALIGN = 4096
CAP = 2048  # positions of the RoPE tables (and the program's KV caches)


def url(repo, rev, name):
    return f"https://huggingface.co/{repo}/resolve/{rev}/{name}"


def header(repo, rev, path):
    """model.safetensors' header (tensor -> dtype, shape, absolute offset), cached."""
    if not path.exists():
        u = url(repo, rev, "model.safetensors")
        def get(r):
            return urllib.request.urlopen(urllib.request.Request(u, headers={"Range": f"bytes={r}"})).read()
        n = struct.unpack("<Q", get("0-7"))[0]
        h = json.loads(get(f"8-{8 + n - 1}"))
        h["__base__"] = 8 + n
        path.write_text(json.dumps(h))
    return json.loads(path.read_text())


class Layout:
    def __init__(self, h):
        self.h = h
        self.recipe, self.manifest, self.pos = ["src model.safetensors"], [], 0

    def src(self, tensor):
        e = self.h[tensor]
        assert e["dtype"] == "BF16", (tensor, e["dtype"])
        return e["shape"], self.h["__base__"] + e["data_offsets"][0]

    def alloc(self, name, dtype, shape, nbytes):
        off = self.pos
        self.manifest.append(f"{name} {off} {nbytes} {dtype} {'x'.join(map(str, shape))}")
        self.pos = (self.pos + nbytes + ALIGN - 1) // ALIGN * ALIGN
        return off

    def f32(self, name, tensor):
        shape, off = self.src(tensor)
        n = 1
        for s in shape:
            n *= s
        out = self.alloc(name, "f32", shape, n * 4)
        self.recipe.append(f"f32 {out} {off} {n}")

    def int4(self, name, tensors, rows_each, cols):
        """bf16 matrices [rows, cols], stacked by rows, as one int4 matrix (name.q, name.s)."""
        rows = sum(rows_each)
        assert cols % G4 == 0, (name, cols)
        oq = self.alloc(name + ".q", "u32", [rows, cols // 8], rows * cols // 2)
        os_ = self.alloc(name + ".s", "f16", [rows, cols // G4], rows * cols // G4 * 2)
        r0 = 0
        for t, r in zip(tensors, rows_each):
            shape, off = self.src(t)
            assert shape == [r, cols], (t, shape, r, cols)
            self.recipe.append(f"q4 {oq + r0 * cols // 2} {os_ + r0 * cols // G4 * 2} {off} {r} {cols} {G4}")
            r0 += r

    def table(self, name, tensor):
        """A bf16 table left in model.safetensors: its absolute offset and shape, for the program's row reads."""
        shape, off = self.src(tensor)
        self.manifest.append(f"table {name} {off} {shape[0]} {shape[1]}")


def layer_plan(tc):
    """Per layer: (sliding?, MLP width, layer whose K/V it uses (itself unless shared), head dim)."""
    L = tc["num_hidden_layers"]
    types = tc["layer_types"]
    first_shared = L - tc["num_kv_shared_layers"]
    plan = []
    for i in range(L):
        sliding = types[i] == "sliding_attention"
        shared = i >= first_shared > 0
        f = tc["intermediate_size"] * (2 if tc["use_double_wide_mlp"] and shared else 1)
        if shared:
            prev = types[:first_shared]
            src = len(prev) - 1 - prev[::-1].index(types[i])
        else:
            src = i
        hd = tc["head_dim"] if sliding else tc["global_head_dim"]
        plan.append((sliding, f, src, hd))
    return plan


def rope_tables(cfg_path, out):
    """cos | sin of the first half of each head (the second half repeats it), positions 0 .. CAP - 1, from
    transformers' own Gemma4TextRotaryEmbedding in fp32: sliding layers (theta 1e4 over 256) and full ones
    (proportional RoPE: theta 1e6 on the first quarter of 512, cos 1 / sin 0 for the rest)."""
    import torch
    from transformers import AutoConfig
    from transformers.models.gemma4.modeling_gemma4 import Gemma4TextRotaryEmbedding

    tc = AutoConfig.from_pretrained(cfg_path).get_text_config()
    rot = Gemma4TextRotaryEmbedding(tc)
    pos = torch.arange(CAP)[None]
    x = torch.zeros(1, dtype=torch.float32)
    for kind, name in (("sliding_attention", "rope_sliding.f32"), ("full_attention", "rope_full.f32")):
        cos, sin = rot(x, pos, kind)
        half = cos.shape[-1] // 2
        assert torch.equal(cos[..., :half], cos[..., half:]) and torch.equal(sin[..., :half], sin[..., half:])
        t = torch.cat([cos[0, :, :half], sin[0, :, :half]], dim=-1).contiguous()
        (out / name).write_bytes(t.numpy().astype("<f4").tobytes())
        print(f"{name}: {CAP} x {t.shape[1]}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", choices=MODELS, default="e2b")
    ap.add_argument("--out", type=pathlib.Path)
    a = ap.parse_args()
    repo, rev = MODELS[a.model]
    out = a.out or ROOT / "build/gemma4" / a.model
    out.mkdir(parents=True, exist_ok=True)
    for f in FILES:
        if not (out / f).exists():
            (out / f).write_bytes(urllib.request.urlopen(url(repo, rev, f)).read())
    tc = json.loads((out / "config.json").read_text())["text_config"]
    h = header(repo, rev, out / "header.json")
    D, L, H, KVH = tc["hidden_size"], tc["num_hidden_layers"], tc["num_attention_heads"], tc["num_key_value_heads"]
    V, PL = tc["vocab_size"], tc["hidden_size_per_layer_input"]
    assert not tc["attention_k_eq_v"] and not tc["enable_moe_block"] and not tc["attention_bias"]
    assert tc["hidden_activation"] == "gelu_pytorch_tanh" and tc["tie_word_embeddings"]
    plan = layer_plan(tc)

    lay = Layout(h)
    lay.table("embed", P + "embed_tokens.weight")
    lay.table("ple", P + "embed_tokens_per_layer.weight")
    lay.int4("head", [P + "embed_tokens.weight"], [V], D)
    lay.f32("final_norm", P + "norm.weight")
    lay.int4("ple_proj", [P + "per_layer_model_projection.weight"], [L * PL], D)
    lay.f32("ple_norm", P + "per_layer_projection_norm.weight")
    for i, (sliding, f, src, hd) in enumerate(plan):
        p = f"{P}layers.{i}."
        for name, t in (("in_norm", "input_layernorm"), ("post_attn_norm", "post_attention_layernorm"),
                        ("pre_ff_norm", "pre_feedforward_layernorm"), ("post_ff_norm", "post_feedforward_layernorm"),
                        ("ple_norm", "post_per_layer_input_norm"), ("q_norm", "self_attn.q_norm")):
            lay.f32(f"l{i}.{name}", p + t + ".weight")
        if src == i:
            lay.f32(f"l{i}.k_norm", p + "self_attn.k_norm.weight")
            lay.int4(f"l{i}.qkv", [p + f"self_attn.{w}_proj.weight" for w in "qkv"], [H * hd, KVH * hd, KVH * hd], D)
        else:
            lay.int4(f"l{i}.qkv", [p + "self_attn.q_proj.weight"], [H * hd], D)
        lay.int4(f"l{i}.o", [p + "self_attn.o_proj.weight"], [D], H * hd)
        lay.int4(f"l{i}.gu", [p + "mlp.gate_proj.weight", p + "mlp.up_proj.weight"], [f, f], D)
        lay.int4(f"l{i}.down", [p + "mlp.down_proj.weight"], [D], f)
        lay.int4(f"l{i}.pg", [p + "per_layer_input_gate.weight"], [PL], D)
        lay.int4(f"l{i}.pp", [p + "per_layer_projection.weight"], [D], PL)
        lay.f32(f"l{i}.scalar", p + "layer_scalar")

    head = (f"gemma4 {repo}@{rev[:8]} D {D} L {L} H {H} KVH {KVH} HD {tc['head_dim']} GHD {tc['global_head_dim']} "
            f"V {V} PL {PL} WINDOW {tc['sliding_window']} CAP {CAP} SOFTCAP {tc['final_logit_softcapping']}")
    layers = [f"layer {i} {'sliding' if s else 'full'} {f} {src} {hd}" for i, (s, f, src, hd) in enumerate(plan)]
    (out / "recipe.txt").write_text(f"size {lay.pos}\n" + "\n".join(lay.recipe) + "\n")
    (out / "manifest.txt").write_text(head + "\n" + "\n".join(layers + lay.manifest) + "\n")
    rope_tables(out, out)
    gpu = sum(int(m.split()[2]) for m in lay.manifest if not m.startswith("table"))
    print(f"{a.model}: gemma4.bin {lay.pos / 1e9:.3f} GB ({gpu / 1e9:.3f} GB of tensors), "
          f"{len(lay.manifest)} manifest lines, {len(lay.recipe)} recipe lines")


if __name__ == "__main__":
    main()
