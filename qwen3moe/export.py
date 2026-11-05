"""Qwen3-30B-A3B's weights for the GPU: the layout of qwen3moe.bin, as recipe.txt for convert.c and manifest.txt for
model.mojo. Only the 16 shards' safetensors headers are read (from Hugging Face, by HTTP range request), so the Mac
needs neither the 61 GB checkpoint nor the 16.7 GB result; convert.c writes qwen3moe.bin where the shards are (the
laptop, which downloads them itself).

  python3 qwen3moe/export.py [--out build/qwen3moe]

qwen3moe.bin, every tensor aligned to 4096 bytes:
  embed                  fp32 [151936, 2048]      the token embedding (exact; never on the GPU: the executor copies a
                                                  token's row from the file, OP_GATHER)
  final_norm             fp32 [2048]
  head.q / head.s        int4 [151936, 2048]      the output head (untied)
  l<i>.in_norm, l<i>.post_norm   fp32 [2048]; l<i>.q_norm, l<i>.k_norm   fp32 [128]
  l<i>.qkv.q / .s        int4 [5120, 2048]        q (32 heads), k (4), v (4) projections, fused
  l<i>.o.q / .s          int4 [2048, 4096]
  l<i>.router            fp32 [128, 2048]         the router (bf16 widened exactly)
  l<i>.gu.q / .s         int4 [128 * 1536, 2048]  expert e: gate rows e*1536 .. +767, up rows e*1536+768 .. +1535
  l<i>.down.q / .s       int4 [128 * 2048, 768]   expert e: rows e*2048 .. +2047

int4 is llama/run.py's storage (llama/kernels' gemv_q4): symmetric, an fp16 scale per group of a row, 8 weights a
uint32 as 4-bit two's complement, low nibble first. Groups are 64 weights, but 128 for the experts: the GPU of the X2
Elite laptop has one 16.8 GB heap (half its RAM), about 16.0 GB of it free, and with scales per 64 the model is 16.7
GB. Each group's scale is the one of max |w| / d, d in 6.5 .. 9, whose fp16 rounding gives the least squared error
(convert.c). The bf16 weights are quantized directly (not rounded to fp16 first). The GPU then holds 15.7 GB.
"""

import argparse
import json
import pathlib
import struct
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
REPO = "Qwen/Qwen3-30B-A3B-Instruct-2507"
REV = "0d7cf23991f47feeb3a57ecb4c9cee8ea4a17bfe"
D, L, H, KVH, HD, E, TOPK, F, V = 2048, 48, 32, 4, 128, 128, 8, 768, 151936
QKV = (H + 2 * KVH) * HD  # 5120
G4 = 64
GE = 128  # the experts' int4 group
ALIGN = 4096
P = "model.layers."


def url(name):
    return f"https://huggingface.co/{REPO}/resolve/{REV}/{name}"


def header(name, cache):
    """A shard's safetensors header (tensor -> dtype, shape, absolute offset), cached."""
    path = cache / (name + ".json")
    if not path.exists():
        req = urllib.request.Request(url(name), headers={"Range": "bytes=0-7"})
        n = struct.unpack("<Q", urllib.request.urlopen(req).read())[0]
        req = urllib.request.Request(url(name), headers={"Range": f"bytes=8-{8 + n - 1}"})
        h = json.loads(urllib.request.urlopen(req).read())
        h["__base__"] = 8 + n
        path.write_text(json.dumps(h))
    return json.loads(path.read_text())


class Layout:
    def __init__(self, index, cache):
        self.where = index["weight_map"]  # tensor -> shard
        self.cache = cache
        self.recipe, self.manifest, self.pos, self.shard = [], [], 0, None

    def src(self, tensor):
        """The tensor's shard (switching the recipe's input), dtype, shape and absolute offset."""
        shard = self.where[tensor]
        h = header(shard, self.cache)
        if shard != self.shard:
            self.recipe.append(f"src {shard}")
            self.shard = shard
        e = h[tensor]
        assert e["dtype"] == "BF16", (tensor, e["dtype"])
        return e["shape"], h["__base__"] + e["data_offsets"][0]

    def alloc(self, name, dtype, shape, nbytes):
        off = self.pos
        self.manifest.append(f"{name} {off} {nbytes} {dtype} {'x'.join(map(str, shape))}")
        self.pos = (self.pos + nbytes + ALIGN - 1) // ALIGN * ALIGN
        return off

    def plain(self, name, tensor, dtype):
        """A bf16 tensor widened to fp32 or converted to fp16."""
        shape, off = self.src(tensor)
        n = 1
        for s in shape:
            n *= s
        size = 4 if dtype == "f32" else 2
        out = self.alloc(name, dtype, shape, n * size)
        self.recipe.append(f"{dtype} {out} {off} {n}")

    def int4(self, name, tensors, rows_each, cols, group=G4):
        """bf16 matrices [rows, cols], stacked by rows, as one int4 matrix (name.q, name.s: a scale per `group`)."""
        rows = sum(rows_each)
        oq = self.alloc(name + ".q", "u32", [rows, cols // 8], rows * cols // 2)
        os_ = self.alloc(name + ".s", "f16", [rows, cols // group], rows * cols // group * 2)
        r0 = 0
        for t, r in zip(tensors, rows_each):
            shape, off = self.src(t)
            assert shape == [r, cols], (t, shape, r, cols)
            self.recipe.append(f"q4 {oq + r0 * cols // 2} {os_ + r0 * cols // group * 2} {off} {r} {cols} {group}")
            r0 += r


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=pathlib.Path, default=ROOT / "build/qwen3moe")
    a = ap.parse_args()
    cache = a.out / "headers"
    cache.mkdir(parents=True, exist_ok=True)
    idx = a.out / "model.safetensors.index.json"
    if not idx.exists():
        idx.write_bytes(urllib.request.urlopen(url("model.safetensors.index.json")).read())
    lay = Layout(json.loads(idx.read_text()), cache)
    lay.plain("embed", "model.embed_tokens.weight", "f32")
    lay.plain("final_norm", "model.norm.weight", "f32")
    lay.int4("head", ["lm_head.weight"], [V], D)
    for l in range(L):
        p = f"{P}{l}."
        for name, t in (("in_norm", "input_layernorm"), ("post_norm", "post_attention_layernorm"),
                        ("q_norm", "self_attn.q_norm"), ("k_norm", "self_attn.k_norm")):
            lay.plain(f"l{l}.{name}", p + t + ".weight", "f32")
        lay.int4(f"l{l}.qkv", [p + f"self_attn.{w}_proj.weight" for w in "qkv"], [H * HD, KVH * HD, KVH * HD], D)
        lay.int4(f"l{l}.o", [p + "self_attn.o_proj.weight"], [D], H * HD)
        lay.plain(f"l{l}.router", p + "mlp.gate.weight", "f32")
        gu, rows = [], []
        for e in range(E):
            gu += [p + f"mlp.experts.{e}.gate_proj.weight", p + f"mlp.experts.{e}.up_proj.weight"]
            rows += [F, F]
        lay.int4(f"l{l}.gu", gu, rows, D, GE)
        lay.int4(f"l{l}.down", [p + f"mlp.experts.{e}.down_proj.weight" for e in range(E)], [D] * E, F, GE)
    (a.out / "recipe.txt").write_text(f"size {lay.pos}\n" + "\n".join(lay.recipe) + "\n")
    (a.out / "manifest.txt").write_text(f"qwen3moe {REPO}@{REV[:8]} {D} {L} {H} {KVH} {HD} {E} {TOPK} {F} {V}\n"
                                        + "\n".join(lay.manifest) + "\n")
    print(f"qwen3moe.bin: {lay.pos / 1e9:.2f} GB, {len(lay.manifest)} tensors, {len(lay.recipe)} recipe lines")


if __name__ == "__main__":
    main()
