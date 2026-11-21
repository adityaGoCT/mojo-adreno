"""Export Llama 3.2 3B (HF safetensors, bf16) for the AdrenoBLAS prefill benchmark.
  python export.py f16|q4 [outdir]   -> outdir/llama3b_<fmt>.bin + .idx ("name offset bytes" per line)
Linear weights as AdrenoBLAS B operands: f16 = K-minor 64 x 16 tiles (ablas_pack_b of a [N,K] weight);
q4 = ggml Q4_0 (blocks of 32 along K, reference rounding) in gen_q4.py's 'Q4' layout. Per layer:
  wqkv [5120, 3072] = q_proj ; k_proj ; v_proj     wo [3072, 3072]
  wgu [16384, 3072] = gate_proj ; up_proj          wd [3072, 8192]
plus attn_norm / ffn_norm (fp32), out_norm, tok (the tied embedding / LM head, same format as the linears),
inv_freq (fp32 [64], llama3 rope scaling applied, from transformers' rotary embedding).
"""
import json, pathlib, sys, glob
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
import numpy as np
import torch
from safetensors import safe_open
from q4ref import quant_q4_0, pack_q4, pack_tiles

SNAP = glob.glob(str(pathlib.Path.home() / ".cache/huggingface/hub/models--unsloth--Llama-3.2-3B-Instruct/snapshots/*"))[0]

def tensors():
    out = {}
    for f in sorted(glob.glob(SNAP + "/*.safetensors")):
        with safe_open(f, framework="pt") as s:
            for k in s.keys():
                out[k] = (f, k)
    return out

def main():
    fmt = sys.argv[1]
    outdir = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else pathlib.Path(__file__).parent / "weights")
    outdir.mkdir(parents=True, exist_ok=True)
    cfg = json.load(open(SNAP + "/config.json"))
    idx = tensors()
    def get(name):
        f, k = idx[name]
        with safe_open(f, framework="pt") as s:
            return s.get_tensor(k).float()
    from transformers import LlamaConfig
    from transformers.models.llama.modeling_llama import LlamaRotaryEmbedding
    inv_freq = LlamaRotaryEmbedding(LlamaConfig(**cfg)).inv_freq.float().numpy()
    binf = open(outdir / f"llama3b_{fmt}.bin", "wb")
    lines = []
    def put(name, data):
        off = binf.tell()
        binf.write(data)
        pad = (-binf.tell()) % 256
        binf.write(b"\0" * pad)
        lines.append(f"{name} {off} {len(data)}")
    def mat(name, w):  # w torch [N, K] fp32
        if fmt == "f16":
            put(name, pack_tiles(w.half().numpy()).astype("<f2").tobytes())
        else:
            q, d = quant_q4_0(w.numpy())
            put(name, pack_q4(q, d))
    put("inv_freq", inv_freq.astype("<f4").tobytes())
    put("out_norm", get("model.norm.weight").numpy().astype("<f4").tobytes())
    mat("tok", get("model.embed_tokens.weight"))
    for i in range(cfg["num_hidden_layers"]):
        p = f"model.layers.{i}."
        put(f"L{i}.attn_norm", get(p + "input_layernorm.weight").numpy().astype("<f4").tobytes())
        put(f"L{i}.ffn_norm", get(p + "post_attention_layernorm.weight").numpy().astype("<f4").tobytes())
        mat(f"L{i}.wqkv", torch.cat([get(p + "self_attn.q_proj.weight"), get(p + "self_attn.k_proj.weight"),
                                    get(p + "self_attn.v_proj.weight")]))
        mat(f"L{i}.wo", get(p + "self_attn.o_proj.weight"))
        mat(f"L{i}.wgu", torch.cat([get(p + "mlp.gate_proj.weight"), get(p + "mlp.up_proj.weight")]))
        mat(f"L{i}.wd", get(p + "mlp.down_proj.weight"))
        print(fmt, "layer", i, flush=True)
    binf.close()
    (outdir / f"llama3b_{fmt}.idx").write_text("\n".join(lines) + "\n")
    print("done", outdir / f"llama3b_{fmt}.bin", sum(int(l.split()[2]) for l in lines) / 1e9, "GB")

main()
