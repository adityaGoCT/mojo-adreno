"""Evo-1 (LIBERO) as static ONNX graphs for the Hexagon NPU (ONNX Runtime's QNN execution provider), written to
build/evo1/npu, each checked in fp32 on the Mac's CPU against the official model's tensors (build/evo1/ref). Their
parameters point at the bytes of the official DeepSpeed checkpoint (mp_rank_00_model_states.pt, which the laptop
downloads itself; build/evo1/pt_offsets.txt), as VLA-Adapter's do:

  vision.onnx  pixel_values [3, 3, 448, 448] -> the views' tokens [768, 896]: InternViT-300M, the pixel shuffle, mlp1
  llm.onnx     the prompt's embeddings [1024, 896] (image slots filled), an additive mask [1024, 1024], the row mask
               [1024, 1] -> the head's context rows [1024, 896]: 14 Qwen2.5 layers with FlashAttention-2's masking
               (masked rows' attention output zeroed), the final RMSNorm
  head.onnx    the context [1024, 896], the normalized state [1, 24], the noise [50, 24], the action mask [1, 24] ->
               x after 32 Euler steps [50, 24]: the state token, every block's context K/V once, the steps unrolled

fp16-safe forms, the same functions in fp32: the ViT's and the LLM's residual streams kept scaled (1/16, 1/64; the
norms' eps scaled), applied to activations (folded into weights they would underflow: the HTP flushes subnormals);
each attention's keys centered per head (the LLM's logits reach 1,775, the ViT's 701).

  build/turbovla/venv/bin/python evo1/export_npu.py
"""

import json
import math
import pathlib
import sys

import numpy as np
import torch
from safetensors.torch import load_file
from torch import nn
from torch.nn import functional as F

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/evo1"
OUT = B / "npu"
NEG = -30000.0
VM, ML, LM, AH = ("embedder.model.vision_model.", "embedder.model.mlp1.", "embedder.model.language_model.model.",
                  "action_head.")
S, D, VD = 1024, 896, 1024
PT = "mp_rank_00_model_states.pt"
sys.path.insert(0, str(ROOT / "vla_adapter"))
sys.path.insert(0, str(ROOT / "npu"))
from export_npu import check, precision, Half  # noqa: E402
from htp_norms import ln16, rms16  # noqa: E402


class W(nn.Module):
    """The checkpoint's tensors as the graph's parameters, bf16 as stored, returned in self.dtype."""

    def __init__(self):
        super().__init__()
        t = load_file(str(B / "evo1.safetensors"))
        self.p = nn.ParameterDict({k.replace(".", "__"): nn.Parameter(v, requires_grad=False) for k, v in t.items()})
        self.dtype = torch.float32

    def forward(self, name):
        return self.p[name.replace(".", "__")].to(self.dtype)


def lin(x, w, name, bias=True):
    return F.linear(x, w(name + ".weight"), w(name + ".bias") if bias else None)


class Vision(nn.Module):
    """InternViT-300M on one view (keys centered), the pixel shuffle, mlp1: run once a view (all three views in one
    graph failed QNN's finalization, error 1002). fp16-safe norms: ln16 (the HTP flushes subnormals; a residual
    divided by 16 made small activations' squares vanish)."""

    C = 1.0

    def __init__(self, w):
        super().__init__()
        self.w = w

    def forward(self, pix):  # [n, 3, 448, 448] -> [n 256, 896] (the graph: n = 1)
        w, C = self.w, self.C
        nv = int(pix.shape[0])
        pe = VM + "embeddings."
        x = F.conv2d(pix, w(pe + "patch_embedding.weight"), w(pe + "patch_embedding.bias"), stride=14)
        x = torch.cat([w(pe + "class_embedding").expand(nv, -1, -1), x.flatten(2).transpose(1, 2)], 1)
        x = (x + w(pe + "position_embedding")) * (1.0 / C)
        for i in range(24):
            p = VM + f"encoder.layers.{i}."
            y = ln16(x, w(p + "norm1.weight"), w(p + "norm1.bias"))
            qkv = lin(y, w, p + "attn.qkv").view(nv, 1025, 3, 16, 64).permute(2, 0, 3, 1, 4)
            k = qkv[1] - qkv[1].mean(2, keepdim=True)
            o = torch.softmax((qkv[0] * 0.125) @ k.transpose(-1, -2), -1) @ qkv[2]
            x = x + lin(o.transpose(1, 2).reshape(nv, 1025, VD), w, p + "attn.proj") * (w(p + "ls1") / C)
            y = ln16(x, w(p + "norm2.weight"), w(p + "norm2.bias"))
            x = x + lin(F.gelu(lin(y, w, p + "mlp.fc1")), w, p + "mlp.fc2") * (w(p + "ls2") / C)
        x = (x * C)[:, 1:].reshape(nv, 32, 32, VD)
        # InternVL's pixel_shuffle (v2, 0.5): [n, 32, 32, c] -> [n, 16, 16, 4c]
        x = x.reshape(nv, 32, 16, 2 * VD).permute(0, 2, 1, 3).reshape(nv, 16, 16, 4 * VD).permute(0, 2, 1, 3)
        x = x.reshape(nv * 256, 4 * VD)
        x = ln16(x, w(ML + "0.weight"), w(ML + "0.bias"), 1e-5)
        return lin(F.gelu(lin(x, w, ML + "1")), w, ML + "3")


def rms(x, g, eps):
    return g * (x * torch.rsqrt((x * x).mean(-1, keepdim=True) + eps))


class LLM(nn.Module):
    """Qwen2.5-0.5B's first 14 layers over the 1024 rows, FlashAttention-2's masking (masked rows' attention output
    zeroed), keys centered; the final RMSNorm. fp16-safe norms: rms16 (a residual divided by 64 made small
    activations' squares subnormal, which the HTP flushes)."""

    C = 1.0

    def __init__(self, w, slots0):
        super().__init__()
        self.w = w
        self.slots0 = slots0  # each view's first image row (256 rows a view)
        inv = 1.0 / (1e6 ** (torch.arange(0, 64, 2).float() / 64))
        f = torch.arange(S).float()[:, None] * inv[None]
        emb = torch.cat([f, f], -1)
        self.cos, self.sin = emb.cos(), emb.sin()

    def rope(self, x):
        return x * self.cos + torch.cat([-x[..., 32:], x[..., :32]], -1) * self.sin

    def forward(self, emb, v0, v1, v2, mask_add, rowmask):
        """emb: the prompt's embedded rows (image rows ignored), v0 .. v2: each view's 256 tokens (the vision
        graph's output, once a view)."""
        w, C = self.w, self.C
        parts, at = [], 0
        for v, vis in enumerate((v0, v1, v2)):
            parts += [emb[at:self.slots0[v]], vis]
            at = self.slots0[v] + 256
        x = torch.cat(parts + [emb[at:]], 0) * (1.0 / C)
        for l in range(14):
            p = LM + f"layers.{l}."
            y = rms16(x, w(p + "input_layernorm.weight"))
            q = lin(y, w, p + "self_attn.q_proj").view(S, 14, 64).transpose(0, 1)
            k = lin(y, w, p + "self_attn.k_proj").view(S, 2, 64).transpose(0, 1)
            v = lin(y, w, p + "self_attn.v_proj").view(S, 2, 64).transpose(0, 1)
            q, k = self.rope(q), self.rope(k)
            k = k - k.mean(1, keepdim=True)
            k, v = k.repeat_interleave(7, 0), v.repeat_interleave(7, 0)
            o = torch.softmax((q * 0.125) @ k.transpose(-1, -2) + mask_add, -1) @ v
            o = o.transpose(0, 1).reshape(S, D) * rowmask
            x = x + F.linear(o, w(p + "self_attn.o_proj.weight")) * (1.0 / C)
            y = rms16(x, w(p + "post_attention_layernorm.weight"))
            g = F.linear(y, w(p + "mlp.gate_proj.weight"))
            u = F.linear(y, w(p + "mlp.up_proj.weight"))
            x = x + F.linear(F.silu(g) * u, w(p + "mlp.down_proj.weight")) * (1.0 / C)
        return rms16(x, w(LM + "norm.weight"))


class Head(nn.Module):
    """The state token, the blocks' context K/V once, 32 Euler steps unrolled (Evo-1's FlowmatchingActionHead)."""

    def __init__(self, w, tindex):
        super().__init__()
        self.w = w
        self.tindex = tindex

    def forward(self, ctx, state, noise, amask):
        w = self.w
        s = F.relu(lin(state, w, AH + "state_encoder.fc1.linear"))
        ctx = torch.cat([ctx, lin(s, w, AH + "state_encoder.fc2.linear")], 0)  # [1025, 896]
        kv = []
        for b in range(8):
            ip = w(AH + f"transformer_blocks.{b}.attn.in_proj_weight")
            ib = w(AH + f"transformer_blocks.{b}.attn.in_proj_bias")
            k = F.linear(ctx, ip[D:2 * D], ib[D:2 * D]).view(1025, 8, 112).transpose(0, 1)
            v = F.linear(ctx, ip[2 * D:], ib[2 * D:]).view(1025, 8, 112).transpose(0, 1)
            kv.append((k, v))
        x = noise
        ae = AH + "action_encoder."
        for i in range(32):
            a = x * amask
            t = F.relu(lin(a, w, ae + "W1.linear")) + w(ae + "pos_encoding.pe")[0]
            t = lin(F.relu(lin(t, w, ae + "W2.linear")), w, ae + "W3.linear")
            temb = w(AH + "time_pos_enc.pe")[0, self.tindex[i]]
            for b in range(8):
                p = AH + f"transformer_blocks.{b}."
                y = ln16(t, w(p + "norm1.weight"), w(p + "norm1.bias"), 1e-5)
                ip = w(p + "attn.in_proj_weight")
                ib = w(p + "attn.in_proj_bias")
                q = F.linear(y, ip[:D], ib[:D]).view(50, 8, 112).transpose(0, 1)
                o = torch.softmax(q @ kv[b][0].transpose(-1, -2) / math.sqrt(112), -1) @ kv[b][1]
                t = t + lin(o.transpose(0, 1).reshape(50, D), w, p + "attn.out_proj")
                y = ln16(t, w(p + "norm2.weight"), w(p + "norm2.bias"), 1e-5) + temb
                t = t + lin(F.gelu(lin(y, w, p + "ff.0")), w, p + "ff.2")
            y = ln16(t, w(AH + "norm_out.weight"), w(AH + "norm_out.bias"), 1e-5)
            pooled = lin(y.reshape(1, 50 * D), w, AH + "seq_pool_proj")
            v = lin(F.relu(lin(pooled, w, AH + "mlp_head.fc1.linear")), w, AH + "mlp_head.fc2.linear")
            x = x + v.reshape(50, 24) * (1.0 / 32)
        return x


def externalize(path):
    """Every bf16 parameter of the graph pointed at its bytes in the official .pt (pt_offsets.txt)."""
    import onnx
    where = {}
    for line in (B / "pt_offsets.txt").read_text().splitlines():
        name, off = line.split(" ")
        where[name.replace(".", "__")] = int(off)
    m = onnx.load(str(path))
    moved = kept = 0
    for init in m.graph.initializer:
        key = init.name.split("p.", 1)[-1]
        if init.data_type == onnx.TensorProto.BFLOAT16 and key in where:
            n = len(init.raw_data)
            init.ClearField("raw_data")
            init.data_location = onnx.TensorProto.EXTERNAL
            del init.external_data[:]
            for k, v in (("location", PT), ("offset", str(where[key])), ("length", str(n))):
                e = init.external_data.add()
                e.key, e.value = k, v
            moved += 1
        else:
            kept += 1
    onnx.save(m, str(path))
    print(f"{path.name}: {moved} parameters point into {PT}, {kept} constants kept; {path.stat().st_size / 1e6:.1f} MB")


def export(module, args, names, outs, path):
    import onnx
    torch.onnx.export(module, args, str(path), input_names=names, output_names=outs, opset_version=20,
                      dynamo=False, do_constant_folding=False)
    externalize(path)
    g = onnx.load(str(path), load_external_data=False)
    print(f"{path.name}: {len(g.graph.node)} nodes; ops {' '.join(sorted({n.op_type for n in g.graph.node}))}")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "in").mkdir(exist_ok=True)
    ref = B / "ref"
    rd = lambda n, dt=np.float32: np.fromfile(ref / n, dt)
    w = W()
    pix = rd("pixel_values.f32").reshape(3, 3, 448, 448)
    emb = rd("llm_input_embeds.f32").reshape(S, D)
    am = rd("attention_mask.i32", np.int32)
    valid = am != 0
    mask = np.full((S, S), NEG, np.float32)
    for i in range(S):
        if valid[i]:
            mask[i, :i + 1] = np.where(valid[:i + 1], 0.0, NEG)
        else:
            mask[i, 0] = 0.0  # its output is zeroed anyway; keep the softmax finite
    rowmask = valid.astype(np.float32).reshape(S, 1)
    ctx_ref = rd("context.f32").reshape(1025, D)
    state = rd("state_norm.f32").reshape(1, 24)
    noise = rd("noise.f32").reshape(50, 24)
    amask = rd("action_mask.i32", np.int32).astype(np.float32).reshape(1, 24)
    tindex = [int(v) for v in rd("time_index.i32", np.int32)]
    slots0 = [int(v) for v in rd("image_slots.i32", np.int32).reshape(3, 256)[:, 0]]
    vis_ref = rd("mlp1_out.f32").reshape(768, D)
    vision, llm, head = Vision(w), LLM(w, slots0), Head(w, tindex)
    t = torch.from_numpy
    with torch.no_grad():
        print("fp32 PyTorch modules against the official model's tensors:")
        check("views' tokens (mlp1)", vision(t(pix)), rd("mlp1_out.f32"))
        check("LLM final norm (the context rows)", llm(t(emb), *(t(vis_ref[v * 256:(v + 1) * 256]) for v in range(3)),
                                                       t(mask), t(rowmask)), ctx_ref[:S])
        x = head(t(ctx_ref[:S]), t(state), t(noise), t(amask)).numpy()
        check("actions (normalized, the 7 used dims)", x[:, :7], rd("actions_norm.f32").reshape(50, 24)[:, :7])
    with torch.no_grad():
        export(Half(precision(vision, torch.float16)), (t(pix[:1]),), ["pixels"], ["tokens"], OUT / "vision.onnx")
        export(Half(precision(llm, torch.float16)),
               (t(emb), *(t(vis_ref[v * 256:(v + 1) * 256]) for v in range(3)), t(mask), t(rowmask)),
               ["embeds", "vision0", "vision1", "vision2", "mask", "rowmask"], ["context"], OUT / "llm.onnx")
        export(Half(precision(head, torch.float16)), (t(ctx_ref[:S]), t(state), t(noise), t(amask)),
               ["context", "state", "noise", "amask"], ["x"], OUT / "head.onnx")
    for name, arr in (("pixels", pix), ("embeds", emb), ("mask", mask), ("rowmask", rowmask), ("state", state),
                      ("noise", noise), ("amask", amask), ("ref_context", ctx_ref[:S].copy()),
                      ("ref_vision", vis_ref), ("pixels0", pix[0:1].copy()), ("pixels1", pix[1:2].copy()),
                      ("pixels2", pix[2:3].copy())) + tuple((f"ref_vision{v}", vis_ref[v * 256:(v + 1) * 256].copy())
                                                            for v in range(3)):
        arr.tofile(OUT / "in" / (name + ".f32"))
    print("inputs in", OUT / "in")


if __name__ == "__main__":
    main()
