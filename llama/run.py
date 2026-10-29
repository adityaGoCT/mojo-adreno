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


G4 = 64  # int4 weights: one fp16 scale per 64 consecutive weights of a row


def quantize4(w16):
    """Symmetric int4 per group of G4 along each row of an fp16 matrix: (packed uint32 rows, 8 weights a
    word, low nibble first; fp16 scales; the dequantized float32 matrix). fp32 math, as st2bin.c does it."""
    rows, cols = w16.shape
    w = w16.float().numpy().reshape(rows, cols // G4, G4)
    s16 = (np.abs(w).max(-1) / np.float32(7)).astype(np.float16)
    sf = s16.astype(np.float32)[..., None]
    with np.errstate(divide="ignore", invalid="ignore"):
        q = np.where(sf > 0, np.rint(w / sf), np.float32(0))
    q = np.clip(q, -8, 7).astype(np.int32)
    nibbles = (q.reshape(rows, cols // 8, 8) & 0xF).astype(np.uint32)
    packed = np.zeros((rows, cols // 8), np.uint32)
    for j in range(8):
        packed |= nibbles[..., j] << np.uint32(4 * j)
    return packed, s16, (q.astype(np.float32) * sf).reshape(rows, cols)


Q4_WEIGHTS = ("self_attn.q_proj", "self_attn.k_proj", "self_attn.v_proj", "self_attn.o_proj",
              "mlp.gate_proj", "mlp.up_proj", "mlp.down_proj")


@torch.no_grad()
def quantize_model4(model):
    """Gives the reference model the int4 weights the phone uses: every projection and the lm_head
    dequantized (the embedding lookup stays fp16, so the lm_head is untied from it)."""
    for layer in model.model.layers:
        for name in Q4_WEIGHTS:
            lin = layer.get_submodule(name)
            lin.weight.data = torch.from_numpy(quantize4(lin.weight.data.half())[2])
    emb = model.model.embed_tokens.weight.data
    model.lm_head.weight = torch.nn.Parameter(torch.from_numpy(quantize4(emb.half())[2]), requires_grad=False)


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


def export_q4(model, fp16_dir, out):
    """weights.bin + manifest.txt with int4 projections and lm_head (<name>.q packed words, <name>.s fp16
    scales); the embedding chunks, norms and RoPE tables as in the fp16 export (from fp16_dir)."""
    c = model.config
    sd = model.state_dict()
    f16 = lambda t: t.detach().to(torch.float16).contiguous()  # noqa: E731
    fp16 = {l.split()[0]: (int(l.split()[1]), int(l.split()[2]))
            for l in (fp16_dir / "manifest.txt").read_text().splitlines()[1:] if l.strip()}
    blob = (fp16_dir / "weights.bin").read_bytes()
    copy = lambda name: np.frombuffer(blob, np.uint8, fp16[name][1], fp16[name][0])  # noqa: E731
    tensors = []

    def q4(name, w16):
        packed, scales, _ = quantize4(w16)
        tensors.extend([(name + ".q", packed), (name + ".s", scales)])

    for i in range(CHUNKS):
        tensors.append((f"embed.{i}", copy(f"embed.{i}")))
    for l in range(c.num_hidden_layers):
        p = f"model.layers.{l}."
        tensors.append((f"l{l}.attn_norm", copy(f"l{l}.attn_norm")))
        q4(f"l{l}.wqkv", torch.cat([f16(sd[p + f"self_attn.{n}_proj.weight"]) for n in "qkv"]))
        q4(f"l{l}.wo", f16(sd[p + "self_attn.o_proj.weight"]))
        tensors.append((f"l{l}.mlp_norm", copy(f"l{l}.mlp_norm")))
        q4(f"l{l}.wgu", torch.cat([f16(sd[p + "mlp.gate_proj.weight"]), f16(sd[p + "mlp.up_proj.weight"])]))
        q4(f"l{l}.wdown", f16(sd[p + "mlp.down_proj.weight"]))
    tensors.append(("final_norm", copy("final_norm")))
    for i, chunk in enumerate(f16(sd["model.embed_tokens.weight"]).chunk(CHUNKS)):
        q4(f"lm.{i}", chunk)
    tensors += [("rope.cos", copy("rope.cos")), ("rope.sin", copy("rope.sin"))]
    out.mkdir(parents=True, exist_ok=True)
    off, lines = 0, [f"llama 2048 16 32 8 64 8192 128256 {MAXPOS} {CHUNKS}"]
    with open(out / "weights.bin", "wb") as f:
        for name, a in tensors:
            a = np.ascontiguousarray(a)
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


def build_and_push(model_dir, backend, prefill=False):
    sh(sys.executable, HERE / "build_kernels.py", "--flavor", backend, *(["prefill840"] if prefill else []))
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
    if prefill:
        sh("adb", "shell", f"mkdir -p {DEV}/prefill840")
        sh("adb", "push", *sorted((BUILD / "prefill840").glob("*.spv")), f"{DEV}/prefill840/")
        qspv = sorted((BUILD / "prefill840/qcom").glob("*.spv"))  # VK_QCOM variants (qcom/*.comp)
        if qspv:
            sh("adb", "shell", f"mkdir -p {DEV}/prefill840/qcom")
            sh("adb", "push", *qspv, f"{DEV}/prefill840/qcom/")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, help="Hugging Face snapshot dir of Llama-3.2-1B(-Instruct), or 'random'")
    ap.add_argument("--prompt", default="Explain in two sentences why the sky is blue.")
    ap.add_argument("--prompt-file", help="read the prompt from this file instead")
    ap.add_argument("--prefill", action="store_true",
                    help="batched prefill on KHR cooperative matrices (prefill840 kernels; an Adreno 8xx)")
    ap.add_argument("--max-new", type=int, default=48)
    ap.add_argument("--backend", default="stock", choices=["stock", "turnip", "native"],
                    help="native: kernels from a source-built Mojo's Vulkan SPIR-V target, on Mesa Turnip")
    ap.add_argument("--reexport", action="store_true")
    ap.add_argument("--quant", choices=["fp16", "q4"], default="fp16",
                    help="q4: int4 projections and lm_head (groups of 64, fp16 scales); embedding fp16")
    a = ap.parse_args()
    if a.prompt_file:
        a.prompt = pathlib.Path(a.prompt_file).read_text().strip()
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
    fp16_ref = None
    if a.quant == "q4":
        fp16_dir, model_dir = model_dir, BUILD / (model_dir.name + "-q4")
        if a.reexport or not (model_dir / "manifest.txt").exists():
            export_q4(model, fp16_dir, model_dir)
        fp16_ref = None if a.model == "random" else reference(model, ids, a.max_new, eos)[0]
        quantize_model4(model)
    print(f"prompt: {len(ids)} tokens; model loaded and exported in {time.time() - t0:.0f} s")

    t1 = time.time()
    ref, ref_logits = reference(model, ids, a.max_new, eos)
    print(f"reference (PyTorch fp32 on the Mac CPU): {len(ref)} tokens in {time.time() - t1:.1f} s")

    build_and_push(model_dir, a.backend, a.prefill)
    env = f"LD_LIBRARY_PATH={TURNIP} VK_RUN_API=1.3 " if a.backend in ("turnip", "native") else ""
    if a.prefill:
        env += f"LLAMA_PREFILL={DEV}/prefill840 " + ("LLAMA_PROFILE=1 " if os.environ.get("LLAMA_PROFILE") else "")
    cmd = (f"cd {DEV}; {env}LLAMA_EOS={','.join(map(str, eos))} LLAMA_LOGITS={DEV}/logits.bin "
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
    if a.quant == "q4" and fp16_ref:
        same = next((i for i, (x, y) in enumerate(zip(got, fp16_ref)) if x != y), min(len(got), len(fp16_ref)))
        print(f"against the fp16 model: identical for the first {same} of {len(fp16_ref)} tokens")
        print("fp16 PyTorch:", tok.decode(fp16_ref, skip_special_tokens=True))


if __name__ == "__main__":
    main()
