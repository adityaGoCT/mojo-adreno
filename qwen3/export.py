"""Export PrismML's Ternary-Bonsai-8B (Qwen3-8B, MLX 2-bit) for qwen3_vk, plus an MLX FP32 reference.

  python qwen3/export.py --checkpoint CKPT --output OUT [--prompt TEXT] [--tokens 16] [--capacity 128]

OUT/weights.bin + manifest.txt ("<name> <offset> <bytes>" lines after "qwen3 <capacity>"):
  emb.w/.s/.b            the embedding as MLX stores it (rows of 2-bit codes, fp16 scales and biases),
                         dequantized on the CPU one row per token
  l<i>.qkv/.o/.gu/.down  packed projections in the layout of kernels.packed_linear (bonsai/kernels):
  head0, head1           .w = codes transposed (k / 16 rows of n words), .s = fp16 scales transposed
                         (k / 128 rows of n); q/k/v and gate/up fused along n. Every group is ternary,
                         bias == -scale, so a weight is (code - 1) * scale.
  l<i>.in_norm, .post_norm, .q_norm, .k_norm, final_norm   fp32
  rope                   cap x 128 fp32: cos | sin of MLX's YaRN rope, its attention factor included
OUT/reference.f32 holds the MLX logits (FP32 activations) after the prompt and after each greedy token;
OUT/manifest.json the prompt ids and expected tokens.
"""

import argparse
import json
import pathlib

import mlx.core as mx
import numpy as np
from mlx_lm import load

D, L, H, KVH, HD, F = 4096, 36, 32, 8, 128, 12288
HEAD0 = 74 * 1024  # vocabulary rows in the first half of the head


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--checkpoint", type=pathlib.Path, required=True)
    ap.add_argument("--output", type=pathlib.Path, required=True)
    ap.add_argument("--prompt", default="What is the capital of France?")
    ap.add_argument("--tokens", type=int, default=16)
    ap.add_argument("--capacity", type=int, default=128)
    a = ap.parse_args()
    c = json.loads((a.checkpoint / "config.json").read_text())
    assert (c["hidden_size"], c["num_hidden_layers"], c["num_attention_heads"], c["num_key_value_heads"],
            c["head_dim"], c["intermediate_size"]) == (D, L, H, KVH, HD, F), "not the Qwen3-8B geometry"
    assert c["quantization"] == {"group_size": 128, "bits": 2} and not c["tie_word_embeddings"]
    V = c["vocab_size"]
    t = {k: np.asarray(v.astype(mx.float32) if v.dtype in (mx.bfloat16, mx.float16) else v)
         for k, v in mx.load(str(a.checkpoint / "model.safetensors")).items()}
    a.output.mkdir(parents=True, exist_ok=True)
    out = open(a.output / "weights.bin", "wb")
    lines = [f"qwen3 {a.capacity}"]

    def add(name, arr):
        arr = np.ascontiguousarray(arr)
        lines.append(f"{name} {out.tell()} {arr.nbytes}")
        out.write(arr.tobytes())

    def packed(name, prefixes, cols=slice(None)):  # transposed and fused along n (or a slice of n)
        ws, ss = [], []
        for p in prefixes:
            w, s, b = t[p + ".weight"][cols], t[p + ".scales"][cols], t[p + ".biases"][cols]
            if not np.array_equal(b, -s):
                raise SystemExit(f"{p}: not ternary (bias != -scale)")
            ws.append(w.T)
            ss.append(s.T)
        add(name + ".w", np.concatenate(ws, axis=1).astype(np.uint32))
        add(name + ".s", np.concatenate(ss, axis=1).astype(np.float16))

    add("emb.w", t["model.embed_tokens.weight"].astype(np.uint32))
    add("emb.s", t["model.embed_tokens.scales"].astype(np.float16))
    add("emb.b", t["model.embed_tokens.biases"].astype(np.float16))
    for i in range(L):
        p = f"model.layers.{i}."
        add(f"l{i}.in_norm", t[p + "input_layernorm.weight"].astype(np.float32))
        add(f"l{i}.post_norm", t[p + "post_attention_layernorm.weight"].astype(np.float32))
        add(f"l{i}.q_norm", t[p + "self_attn.q_norm.weight"].astype(np.float32))
        add(f"l{i}.k_norm", t[p + "self_attn.k_norm.weight"].astype(np.float32))
        packed(f"l{i}.qkv", [p + "self_attn." + n for n in ("q_proj", "k_proj", "v_proj")])
        packed(f"l{i}.o", [p + "self_attn.o_proj"])
        packed(f"l{i}.gu", [p + "mlp.gate_proj", p + "mlp.up_proj"])
        packed(f"l{i}.down", [p + "mlp.down_proj"])
        print(f"layer {i}", flush=True, end="\r")
    add("final_norm", t["model.norm.weight"].astype(np.float32))
    packed("head0", ["lm_head"], slice(0, HEAD0))  # two halves: buffers stay under 128 MB
    packed("head1", ["lm_head"], slice(HEAD0, None))
    del t

    model, tok = load(str(a.checkpoint))
    model.set_dtype(mx.float32)
    # the rope table: rotate (1 .. 1 | 0 .. 0) at every position: out = (cos | sin) times YaRN's factor
    rope = model.model.layers[0].self_attn.rope
    x = mx.concatenate([mx.ones((1, 1, a.capacity, HD // 2)), mx.zeros((1, 1, a.capacity, HD // 2))], axis=-1)
    add("rope", np.asarray(rope(x)[0, 0]).astype(np.float32))
    out.close()
    (a.output / "manifest.txt").write_text("\n".join(lines) + "\n")

    text = tok.apply_chat_template([dict(role="user", content=a.prompt)], tokenize=False,
                                   add_generation_prompt=True, enable_thinking=False)
    ids = tok.encode(text, add_special_tokens=False)
    assert len(ids) + a.tokens <= a.capacity
    from mlx_lm.models.cache import make_prompt_cache
    cache = make_prompt_cache(model)
    inputs, gen = mx.array([ids]), []
    with open(a.output / "reference.f32", "wb") as f:
        for _ in range(a.tokens):
            logits = model(inputs, cache=cache)[:, -1, :].astype(mx.float32)
            mx.eval(logits)
            lg = np.asarray(logits)[0]
            lg.astype("<f4").tofile(f)
            gen.append(int(lg.argmax()))
            inputs = mx.array([[gen[-1]]])
    (a.output / "manifest.json").write_text(json.dumps(dict(
        model="prism-ml/Ternary-Bonsai-8B-mlx-2bit", prompt=a.prompt, prompt_ids=ids, expected_ids=gen,
        expected_text=tok.decode(gen), capacity=a.capacity, generation_tokens=a.tokens, vocab=V), indent=1))
    print("\nREFERENCE", tok.decode(gen))


if __name__ == "__main__":
    main()
