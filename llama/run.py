"""Llama 3.2 1B on the phone's Adreno GPU with Mojo kernels: export, reference, build, push, run, compare.

  PY=../iree-adreno-genai-tuner/.venv-iree312/bin/python      # torch + transformers (Part 1)
  $PY llama/run.py --model <HF snapshot dir> --prompt "..."     # Llama-3.2-1B-Instruct
  $PY llama/run.py --model random                               # same shapes, random weights (no download)

1. export: fp16 weights for llama_vk (q/k/v and gate/up fused; the tied embedding split into 4 chunks
   of <= 128 MB, the stock driver's largest storage binding) and RoPE cos/sin tables from transformers'
   own rotary embedding (Llama 3 frequency scaling included).
2. reference: greedy decode in PyTorch, fp32 math on the same fp16-rounded weights.
3. build: llama/build_kernels.py (Mojo -> SPIR-V) and llama_vk.c (NDK); push to /data/local/tmp/llama.
4. run llama_vk on the phone, decode its token ids, compare with the reference.
"""

import argparse
import os
import pathlib
import subprocess
import sys
import time

import numpy as np
import torch
from transformers import AutoTokenizer, LlamaConfig, LlamaForCausalLM
from transformers.models.llama.modeling_llama import LlamaRotaryEmbedding

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
BUILD = ROOT / "build/llama"
DEV = "/data/local/tmp/llama"
NDK = pathlib.Path(os.environ.get("ANDROID_NDK", "/opt/homebrew/share/android-ndk"))
CC = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang"
TURNIP = "/data/local/tmp/turnip"
MAXPOS, CHUNKS = 512, 4
os.environ.setdefault("ANDROID_SERIAL", os.environ.get("ADB_WIFI", "192.168.1.7:5555"))
# meta-llama/Llama-3.2-1B-Instruct config.json (for --model random)
CONFIG_1B = dict(vocab_size=128256, hidden_size=2048, intermediate_size=8192, num_hidden_layers=16,
                 num_attention_heads=32, num_key_value_heads=8, head_dim=64, rms_norm_eps=1e-5,
                 max_position_embeddings=131072, tie_word_embeddings=True, hidden_act="silu",
                 rope_theta=500000.0, rope_scaling=dict(rope_type="llama3", factor=32.0, low_freq_factor=1.0,
                                                        high_freq_factor=4.0, original_max_position_embeddings=8192),
                 bos_token_id=128000, eos_token_id=[128001, 128008, 128009])


def sh(*cmd, check=True):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r


def load_model(src):
    if src == "random":
        torch.manual_seed(0)
        model = LlamaForCausalLM(LlamaConfig(**CONFIG_1B))
    else:
        model = LlamaForCausalLM.from_pretrained(src, dtype=torch.float32)
    for p in model.parameters():  # the phone runs fp16 weights: give the reference the same values
        p.data = p.data.half().float()
    return model.eval()


def export(model, out):
    """weights.bin (256-byte aligned tensors) + manifest.txt for llama_vk."""
    c = model.config
    assert (c.hidden_size, c.num_hidden_layers, c.num_attention_heads, c.num_key_value_heads, c.head_dim,
            c.intermediate_size, c.vocab_size) == (2048, 16, 32, 8, 64, 8192, 128256), "not a Llama 3.2 1B shape"
    sd = model.state_dict()
    f16 = lambda t: t.detach().to(torch.float16).contiguous().numpy()  # noqa: E731
    tensors = []
    emb = sd["model.embed_tokens.weight"]
    head = sd.get("lm_head.weight", emb)
    assert head.data_ptr() == emb.data_ptr() or torch.equal(head, emb), "untied lm_head: not supported"
    for i, chunk in enumerate(emb.chunk(CHUNKS)):
        tensors.append((f"embed.{i}", f16(chunk)))
    for l in range(c.num_hidden_layers):
        p = f"model.layers.{l}."
        tensors += [
            (f"l{l}.attn_norm", f16(sd[p + "input_layernorm.weight"])),
            (f"l{l}.wqkv", f16(torch.cat([sd[p + f"self_attn.{n}_proj.weight"] for n in "qkv"]))),
            (f"l{l}.wo", f16(sd[p + "self_attn.o_proj.weight"])),
            (f"l{l}.mlp_norm", f16(sd[p + "post_attention_layernorm.weight"])),
            (f"l{l}.wgu", f16(torch.cat([sd[p + "mlp.gate_proj.weight"], sd[p + "mlp.up_proj.weight"]]))),
            (f"l{l}.wdown", f16(sd[p + "mlp.down_proj.weight"])),
        ]
    tensors.append(("final_norm", f16(sd["model.norm.weight"])))
    rot = LlamaRotaryEmbedding(config=c)
    cos, sin = rot(torch.zeros(1, dtype=torch.float32), torch.arange(MAXPOS)[None])
    tensors += [("rope.cos", cos[0, :, :c.head_dim // 2].float().contiguous().numpy()),
                ("rope.sin", sin[0, :, :c.head_dim // 2].float().contiguous().numpy())]
    out.mkdir(parents=True, exist_ok=True)
    off, lines = 0, [f"llama 2048 16 32 8 64 8192 128256 {MAXPOS} {CHUNKS}"]
    with open(out / "weights.bin", "wb") as f:
        for name, a in tensors:
            assert a.nbytes <= 128 * 1024 * 1024, name
            f.write(b"\0" * (-off % 256))
            off += -off % 256
            f.write(a.tobytes())
            lines.append(f"{name} {off} {a.nbytes}")
            off += a.nbytes
    (out / "manifest.txt").write_text("\n".join(lines) + "\n")
    print(f"export: {len(tensors)} tensors, {off / 1e9:.2f} GB -> {out}")


@torch.no_grad()
def reference(model, ids, max_new, eos):
    """Greedy decode, fp32 math; returns (new token ids, logits after the prompt)."""
    out = model(torch.tensor([ids]), use_cache=True)
    first = out.logits[0, -1].float().numpy()
    past, toks, nxt = out.past_key_values, [], int(out.logits[0, -1].argmax())
    for _ in range(max_new):
        toks.append(nxt)
        if nxt in eos or len(toks) == max_new:
            break
        out = model(torch.tensor([[nxt]]), past_key_values=past, use_cache=True)
        past, nxt = out.past_key_values, int(out.logits[0, -1].argmax())
    return toks, first


def build_and_push(model_dir, backend):
    sh(sys.executable, HERE / "build_kernels.py")
    sh(CC, "-O2", "-o", BUILD / "llama_vk", HERE / "llama_vk.c", "-ldl")
    remote = f"{DEV}/{model_dir.name}"  # model / model-random: same sizes, so separate directories
    sh("adb", "shell", f"mkdir -p {remote} {DEV}/{backend}")
    for f in ("weights.bin", "manifest.txt"):  # 2.5 GB: push only when the phone's copy differs in size
        size = sh("adb", "shell", f"stat -c %s {remote}/{f} 2>/dev/null", check=False).stdout.strip()
        if size != str((model_dir / f).stat().st_size):
            print(f"push {f} ({(model_dir / f).stat().st_size / 1e9:.2f} GB) ...", flush=True)
            sh("adb", "push", model_dir / f, f"{remote}/")
    sh("adb", "push", *sorted((BUILD / backend).glob("*.spv")), f"{DEV}/{backend}/")
    sh("adb", "push", BUILD / "llama_vk", f"{DEV}/")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, help="Hugging Face snapshot dir of Llama-3.2-1B(-Instruct), or 'random'")
    ap.add_argument("--prompt", default="Explain in two sentences why the sky is blue.")
    ap.add_argument("--max-new", type=int, default=48)
    ap.add_argument("--backend", default="stock", choices=["stock", "turnip"])
    ap.add_argument("--reexport", action="store_true")
    a = ap.parse_args()
    t0 = time.time()
    model = load_model(a.model)
    tok = None if a.model == "random" else AutoTokenizer.from_pretrained(a.model)
    eos = list(CONFIG_1B["eos_token_id"])
    if tok:
        ids = tok.apply_chat_template([{"role": "user", "content": a.prompt}], add_generation_prompt=True)
        ids = list(ids["input_ids"] if isinstance(ids, dict) or hasattr(ids, "keys") else ids)
    else:
        ids = [128000] + list(np.random.default_rng(0).integers(0, 128000, 15))
    model_dir = BUILD / ("model-random" if a.model == "random" else "model")
    if a.reexport or not (model_dir / "manifest.txt").exists():
        export(model, model_dir)
    print(f"prompt: {len(ids)} tokens; model loaded and exported in {time.time() - t0:.0f} s")

    t1 = time.time()
    ref, ref_logits = reference(model, ids, a.max_new, eos)
    print(f"reference (PyTorch fp32 on the Mac CPU): {len(ref)} tokens in {time.time() - t1:.1f} s")

    build_and_push(model_dir, a.backend)
    env = f"LD_LIBRARY_PATH={TURNIP} VK_RUN_API=1.3 " if a.backend == "turnip" else ""
    cmd = (f"cd {DEV} && {env}LLAMA_EOS={','.join(map(str, eos))} LLAMA_LOGITS={DEV}/logits.bin "
           f"./llama_vk {model_dir.name} {a.backend} {a.max_new} {' '.join(map(str, ids))}")
    print(f"phone ({a.backend}):", flush=True)
    proc = subprocess.Popen(["adb", "shell", cmd], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    got, text = [], ""
    for line in proc.stdout:
        if line.startswith("tok "):
            got.append(int(line.split()[1]))
            if tok:
                new = tok.decode(got, skip_special_tokens=True)
                print(new[len(text):], end="", flush=True)
                text = new
        else:
            print(("\n" if got and text else "") + "  " + line.rstrip(), flush=True)
    proc.wait()
    sh("adb", "pull", f"{DEV}/logits.bin", BUILD / "logits_phone.bin")
    phone_logits = np.fromfile(BUILD / "logits_phone.bin", dtype=np.float32)
    match = next((i for i, (x, y) in enumerate(zip(got, ref)) if x != y), min(len(got), len(ref)))
    print(f"\nlogits after the prompt: max |phone - PyTorch| = {np.abs(phone_logits - ref_logits).max():.2e} "
          f"(logit range {ref_logits.min():.1f} .. {ref_logits.max():.1f})")
    print(f"tokens: phone {len(got)}, PyTorch {len(ref)}, identical for the first {match}")
    if tok:
        print("PyTorch:", tok.decode(ref, skip_special_tokens=True))


if __name__ == "__main__":
    main()
