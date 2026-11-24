"""Llama 3.x of any size (Llama 3.2 3B here) on the phone's Adreno 840 in Mojo: export, run, check.

llama/run.py and llama.mojo are Llama 3.2 1B's (its shapes are compiled into llama/kernels, which llama_vk.c shares).
This driver exports any Llama 3.x checkpoint the same way, int4 (run.py's quantize4: an fp16 scale per 64), and runs
llama3.mojo (llama/model3.mojo: every size from the manifest), then checks the phone against reference3.py.

  PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python
  $PY llama/run3.py --model <HF snapshot of Llama-3.2-3B-Instruct> --prompt-file llama/prompts/long.txt [--check]
      [--env LLAMA_GEMM=q] [--max-new 48]

1. export (once): build/llama/<name>-q4/{weights.bin, manifest.txt}, read a tensor at a time from the safetensors
   (the Mac need not hold the model): the embedding in fp16 chunks of <= 128 MB, q/k/v and gate/up fused, every
   projection and the (tied) head int4, norms fp16, RoPE cos/sin tables from transformers' LlamaRotaryEmbedding.
   --recipe writes st2bin's recipe for the same file instead of pushing it: the phone downloads the checkpoint's
   shards, joins them (cat) and converts them with llama/st2bin.c, byte for byte the export.
2. push the weights (when the phone's copy differs in size), build llama3 (android/build.py llama3), push it.
3. run on the phone: "prompt: ... ms", "tok <id> <ms>", "decode: ..."; the logits after the prompt (LLAMA_LOGITS).
4. --check: reference3.py on the Mac, a decoder layer at a time in fp32 on the same int4 weights, teacher-forced on
   the phone's tokens: the logits after the prompt and every generated token against the reference's argmax.
"""

import argparse
import json
import os
import pathlib
import subprocess
import sys

import numpy as np
import torch
from safetensors import safe_open
from transformers import AutoTokenizer, LlamaConfig
from transformers.models.llama.modeling_llama import LlamaRotaryEmbedding

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
BUILD = ROOT / "build/llama"
DEV = "/data/local/tmp/llama"
MAXPOS = 512
sys.path.insert(0, str(HERE))
from run import quantize4  # noqa: E402


def sh(*cmd, check=True):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r


class Checkpoint:
    """A Hugging Face snapshot's safetensors, a tensor at a time."""

    def __init__(self, snap):
        self.snap = pathlib.Path(snap)
        index = self.snap / "model.safetensors.index.json"
        if index.exists():
            self.where = json.loads(index.read_text())["weight_map"]
        else:
            with safe_open(self.snap / "model.safetensors", framework="pt") as f:
                self.where = {k: "model.safetensors" for k in f.keys()}
        self.files = {}

    def __getitem__(self, name):
        fn = self.where[name]
        if fn not in self.files:
            self.files[fn] = safe_open(self.snap / fn, framework="pt")
        return self.files[fn].get_tensor(name)


def config(snap):
    return LlamaConfig(**json.loads((pathlib.Path(snap) / "config.json").read_text()))


def export_q4(snap, out):
    """weights.bin + manifest.txt for llama3.mojo, int4 projections and head (<name>.q packed words, <name>.s fp16
    scales), the rest fp16 and the RoPE tables fp32. The header gives every size: "llama D L H KVH HD F V MAXPOS
    CHUNKS"."""
    c = config(snap)
    ck = Checkpoint(snap)
    hd = getattr(c, "head_dim", None) or c.hidden_size // c.num_attention_heads
    f16 = lambda t: t.to(torch.float16).contiguous()  # noqa: E731
    emb = f16(ck["model.embed_tokens.weight"])
    assert "lm_head.weight" not in ck.where or torch.equal(f16(ck["lm_head.weight"]), emb), "untied head"
    chunks = 1
    while emb.shape[0] % chunks or emb[: emb.shape[0] // chunks].numel() * 2 > 128 << 20:
        chunks += 1
    out.mkdir(parents=True, exist_ok=True)
    off, lines = 0, [f"llama {c.hidden_size} {c.num_hidden_layers} {c.num_attention_heads} "
                     f"{c.num_key_value_heads} {hd} {c.intermediate_size} {c.vocab_size} {MAXPOS} {chunks}"]
    with open(out / "weights.bin", "wb") as f:
        def put(name, a):
            nonlocal off
            a = np.ascontiguousarray(a)
            f.write(b"\0" * (-off % 256))
            off += -off % 256
            f.write(a.tobytes())
            lines.append(f"{name} {off} {a.nbytes}")
            off += a.nbytes

        def q4(name, w16):
            packed, scales, _ = quantize4(w16)
            put(name + ".q", packed)
            put(name + ".s", scales)

        for i, chunk in enumerate(emb.chunk(chunks)):
            put(f"embed.{i}", chunk.numpy())
        for l in range(c.num_hidden_layers):
            p = f"model.layers.{l}."
            put(f"l{l}.attn_norm", f16(ck[p + "input_layernorm.weight"]).numpy())
            q4(f"l{l}.wqkv", torch.cat([f16(ck[p + f"self_attn.{n}_proj.weight"]) for n in "qkv"]))
            q4(f"l{l}.wo", f16(ck[p + "self_attn.o_proj.weight"]))
            put(f"l{l}.mlp_norm", f16(ck[p + "post_attention_layernorm.weight"]).numpy())
            q4(f"l{l}.wgu", torch.cat([f16(ck[p + "mlp.gate_proj.weight"]), f16(ck[p + "mlp.up_proj.weight"])]))
            q4(f"l{l}.wdown", f16(ck[p + "mlp.down_proj.weight"]))
            print(f"export: layer {l}", end="\r", flush=True)
        put("final_norm", f16(ck["model.norm.weight"]).numpy())
        for i, chunk in enumerate(emb.chunk(chunks)):
            q4(f"lm.{i}", chunk)
        rot = LlamaRotaryEmbedding(config=c)
        cos, sin = rot(torch.zeros(1, dtype=torch.float32), torch.arange(MAXPOS)[None])
        put("rope.cos", cos[0, :, : hd // 2].float().contiguous().numpy())
        put("rope.sin", sin[0, :, : hd // 2].float().contiguous().numpy())
    (out / "manifest.txt").write_text("\n".join(lines) + "\n")
    print(f"export: {len(lines) - 1} tensors, {off / 1e9:.2f} GB -> {out}")


def recipe(snap, model_dir, out):
    """st2bin's recipe for model_dir's weights.bin from the checkpoint's safetensors shards joined in order (the phone
    downloads them and cats them into one file): the same tensors as export_q4, converted or quantized by st2bin.c;
    the RoPE tables as files. Returns the shards' file names."""
    snap = pathlib.Path(snap)
    c = config(snap)
    ck = Checkpoint(snap)
    shards = sorted(set(ck.where.values()))
    base, heads = 0, {}
    for fn in shards:  # each shard's header, and where its data starts in the joined file
        with open(snap / fn, "rb") as f:
            n = int.from_bytes(f.read(8), "little")
            heads[fn] = (base + 8 + n, json.loads(f.read(n)))
        base += (snap / fn).stat().st_size

    def source(name):  # (byte offset in the joined file, bf16 values)
        start0, h = heads[ck.where[name]]
        t = h[name]
        assert t["dtype"] == "BF16", (name, t["dtype"])
        a, b = t["data_offsets"]
        return start0 + a, (b - a) // 2

    lines0 = (model_dir / "manifest.txt").read_text().splitlines()
    D, L, H, KVH, HD, F, V, _, chunks = [int(x) for x in lines0[0].split()[1:]]
    place = {l.split()[0]: (int(l.split()[1]), int(l.split()[2])) for l in lines0[1:] if l.strip()}
    lines = []

    def conv(name, parts):
        off, nbytes = place[name]
        assert sum(n for _, n in parts) * 2 == nbytes, name
        for at, n in parts:
            lines.append(f"conv {off} {at} {n}")
            off += n * 2

    def q4(name, parts, cols):
        oq, nq = place[name + ".q"]
        os_, ns = place[name + ".s"]
        assert sum(n for _, n in parts) // 2 == nq and sum(n for _, n in parts) // 32 == ns, name
        for at, n in parts:
            rows = n // cols
            lines.append(f"q4 {oq} {os_} {at} {rows} {cols}")
            oq += rows * cols // 2
            os_ += rows * cols // 64 * 2

    emb, count = source("model.embed_tokens.weight")
    per = count // chunks
    for i in range(chunks):
        conv(f"embed.{i}", [(emb + i * per * 2, per)])
    for l in range(L):
        p = f"model.layers.{l}."
        conv(f"l{l}.attn_norm", [source(p + "input_layernorm.weight")])
        q4(f"l{l}.wqkv", [source(p + f"self_attn.{n}_proj.weight") for n in "qkv"], D)
        q4(f"l{l}.wo", [source(p + "self_attn.o_proj.weight")], H * HD)
        conv(f"l{l}.mlp_norm", [source(p + "post_attention_layernorm.weight")])
        q4(f"l{l}.wgu", [source(p + "mlp.gate_proj.weight"), source(p + "mlp.up_proj.weight")], D)
        q4(f"l{l}.wdown", [source(p + "mlp.down_proj.weight")], F)
    conv("final_norm", [source("model.norm.weight")])
    for i in range(chunks):
        q4(f"lm.{i}", [(emb + i * per * 2, per)], D)
    out.mkdir(parents=True, exist_ok=True)
    blob = np.memmap(model_dir / "weights.bin", np.uint8, "r")
    for name in ("rope.cos", "rope.sin"):
        off, nbytes = place[name]
        (out / name).write_bytes(blob[off:off + nbytes].tobytes())
        lines.append(f"file {off} {name}")
    size = (model_dir / "weights.bin").stat().st_size
    (out / "recipe.txt").write_text(f"size {size}\n" + "\n".join(lines) + "\n")
    print(f"recipe: {len(lines)} lines, {size} bytes -> {out}")
    return shards


def push_weights(model_dir):
    remote = f"{DEV}/{model_dir.name}"
    sh("adb", "shell", f"mkdir -p {remote}")
    for f in ("weights.bin", "manifest.txt"):
        size = sh("adb", "shell", f"stat -c %s {remote}/{f} 2>/dev/null", check=False).stdout.strip()
        if size != str((model_dir / f).stat().st_size):
            print(f"push {f} ({(model_dir / f).stat().st_size / 1e9:.2f} GB) ...", flush=True)
            sh("adb", "push", model_dir / f, f"{remote}/")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, help="Hugging Face snapshot dir of a Llama 3.x checkpoint")
    ap.add_argument("--name", default="llama3b", help="build/llama/<name>-q4 and the phone's copy")
    ap.add_argument("--prompt", default="Explain in two sentences why the sky is blue.")
    ap.add_argument("--prompt-file")
    ap.add_argument("--max-new", type=int, default=48)
    ap.add_argument("--env", nargs="*", default=[], help="extra LLAMA_* settings for the phone (e.g. LLAMA_GEMM=q)")
    ap.add_argument("--export-only", action="store_true")
    ap.add_argument("--recipe", action="store_true",
                    help="also write build/llama/<name>-conv: st2bin's recipe and RoPE tables, for the phone to build "
                         "weights.bin from the checkpoint's shards itself (when adb is slow)")
    ap.add_argument("--no-build", action="store_true", help="run the llama3 already on the phone")
    ap.add_argument("--check", action="store_true", help="reference3.py: logits and teacher-forced tokens")
    a = ap.parse_args()
    model_dir = BUILD / f"{a.name}-q4"
    if not (model_dir / "manifest.txt").exists():
        export_q4(a.model, model_dir)
    if a.recipe:
        shards = recipe(a.model, model_dir, BUILD / f"{a.name}-conv")
        print("the phone: cat " + " ".join(shards) + " > joined.safetensors; "
              "st2bin joined.safetensors recipe.txt <conv dir> weights.bin")
    if a.export_only or a.recipe:
        return
    if a.prompt_file:
        a.prompt = pathlib.Path(a.prompt_file).read_text().strip()
    tok = AutoTokenizer.from_pretrained(a.model)
    ids = tok.apply_chat_template([{"role": "user", "content": a.prompt}], add_generation_prompt=True)
    ids = list(ids["input_ids"] if hasattr(ids, "keys") else ids)
    eos = [128001, 128008, 128009]
    push_weights(model_dir)
    if not a.no_build:
        sh(sys.executable, ROOT / "android/build.py", "llama3")
        sh("adb", "shell", f"mkdir -p {DEV}/mojo3")
        sh("adb", "push", *sorted(p for p in (ROOT / "build/android/llama3").iterdir() if p.suffix != ".o"),
           f"{DEV}/mojo3/")
    (BUILD / "ids3.txt").write_text(" ".join(map(str, ids)) + "\n")
    sh("adb", "push", BUILD / "ids3.txt", f"{DEV}/ids3.txt")
    env = " ".join(a.env)
    cmd = (f"cd {DEV}; LD_LIBRARY_PATH={DEV}/mojo3 MODULAR_DRIVER_PLUGINS=vulkan@{DEV}/mojo3/libM_driver_vulkan.so "
           f"LLAMA_PREFILL=1 LLAMA_EOS={','.join(map(str, eos))} LLAMA_LOGITS={DEV}/logits3.bin {env} "
           f"mojo3/llama3 {model_dir.name} {a.max_new} @{DEV}/ids3.txt > {DEV}/run3.log 2>&1; echo exit $? >> {DEV}/run3.log")
    print(f"prompt: {len(ids)} tokens")
    sh("adb", "shell", cmd)
    log = sh("adb", "shell", f"cat {DEV}/run3.log").stdout
    got = [int(l.split()[1]) for l in log.splitlines() if l.startswith("tok ")]
    for l in log.splitlines():
        if not l.startswith("tok "):
            print("phone:", l)
    print("output:", repr(tok.decode(got)))
    if "exit 0" not in log:
        sys.exit("the phone's run failed")
    (BUILD / f"{a.name}_run.json").write_text(json.dumps({"prompt": ids, "generated": got}))
    if not a.check:
        return
    sh("adb", "pull", f"{DEV}/logits3.bin", BUILD / "logits3_phone.bin")
    phone = np.fromfile(BUILD / "logits3_phone.bin", np.float32)
    seq = ids + got[:-1]
    out = BUILD / f"{a.name}_ref.npy"
    r = subprocess.run([sys.executable, HERE / "reference3.py", "--model", a.model, "--weights", model_dir,
                        "--ids", ",".join(map(str, seq)), "--first", str(len(ids) - 1), "--out", out])
    if r.returncode:
        sys.exit("reference3.py failed")
    ref = np.load(out)  # [len(got), V]: the logits at positions len(ids) - 1 ..
    d = np.abs(phone - ref[0])
    la = ref[0].astype(np.float64) - ref[0].max()
    la -= np.log(np.exp(la).sum())
    lb = phone.astype(np.float64) - phone.max()
    lb -= np.log(np.exp(lb).sum())
    kl = float((np.exp(la) * (la - lb)).sum())
    print(f"logits after the prompt: max |phone - reference| = {d.max():.2e} (range {ref[0].min():.1f} .. "
          f"{ref[0].max():.1f}), argmax {phone.argmax()} vs {ref[0].argmax()}, KL {kl:.2e}")
    same = sum(int(ref[i].argmax()) == got[i] for i in range(len(got)))
    first = next((i for i in range(len(got)) if int(ref[i].argmax()) != got[i]), None)
    print(f"greedy: {same} of {len(got)} phone tokens are the reference's argmax (teacher-forced)"
          + (f"; first difference at {first}" if first is not None else ""))


if __name__ == "__main__":
    main()
