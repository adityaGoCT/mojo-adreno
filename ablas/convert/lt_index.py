#!/usr/bin/env python3
"""An index that lets ../lt/llama_lt read a converted Llama's weights.bin, for TIMING ONLY.

  python lt_index.py OUTDIR/model.plan > llama3b_<fmt>t.idx      (on the phone: llama3b_<fmt>t.bin -> weights.bin)

llama_lt reads export.py's names and lays gate|up out for SwiGLU itself as it loads; weights.bin has them already in
that layout, so llama_lt scrambles the gate/up rows again: its logits are wrong, its kernels and their timing are
not (the same shapes, formats and value distribution). This spares pushing a second copy of the model (6.4 GB for
fp16) to time llama_lt against plan_run on one phone.
"""
import sys

NAMES = {"attn_norm": "attn_norm", "ffn_norm": "ffn_norm", "attn_qkv": "wqkv", "attn_output": "wo",
         "ffn_gate_up": "wgu", "ffn_down": "wd"}
for line in open(sys.argv[1]):
    t = line.split()
    if not t or t[0] != "weight":
        continue
    name, off, nbytes = t[1], t[6], t[7]
    if name == "token_embd":
        n = "tok"
    elif name == "rope.inv_freq":
        n = "inv_freq"
    elif name == "output_norm":
        n = "out_norm"
    else:
        l, w = name[len("blk."):].split(".")
        n = f"L{l}.{NAMES[w]}"
    print(n, off, nbytes)
