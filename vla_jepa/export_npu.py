"""VLA-JEPA (LIBERO) as static ONNX graphs for the Hexagon NPU (ONNX Runtime's QNN execution provider), written to
build/vla_jepa/npu, each checked in fp32 on the Mac's CPU against the official model's tensors (build/vla_jepa/ref).
Their parameters point at the bytes of the official checkpoint (VLA-JEPA-LIBERO.pt, which the laptop downloads itself;
build/vla_jepa/pt_offsets.txt), as VLA-Adapter's and Evo-1's do:

  vision.onnx  the processor's patches [512, 1536] -> the views' tokens [128, 2048] and the three DeepStack sets
               [3, 128, 2048]: Qwen3-VL's ViT and mergers
  llm.onnx     the prompt's embeddings rows 4 .. 255 [252, 2048] (image rows ignored), the vision tokens, the DeepStack
               sets, the RoPE tables [252, 64] x 2, an additive mask [252, 256] -> the 32 embodied rows [32, 2048]:
               Qwen3's 28 layers. Rows 0 .. 3 (<|im_start|>user\\n<|vision_start|>) come before any input and attention
               is causal, so their keys and values in every layer are constants of the weights (computed here in fp32):
               the graph never computes token 0, whose residual reaches 37,897
  head.onnx    the embodied rows [32, 2048], the state [1, 8], the noise [7, 7] -> x after 4 Euler steps [7, 7]: the DiT

fp16-safe forms, the same functions in fp32: residual streams kept scaled on the activation side (ViT 1/16: channels
reach 1,046; LLM 1/64; DiT 1/16: 1,190), norms' eps scaled; the DiT's cross-attention keys centered per head (logits
reach 3,319).

  build/turbovla/venv/bin/python vla_jepa/export_npu.py
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
B = ROOT / "build/vla_jepa"
OUT = B / "npu"
NEG = -30000.0
VQ, LQ, AM, DM = ("qwen_vl_interface.model.model.visual.", "qwen_vl_interface.model.model.language_model.",
                  "action_model.", "action_model.model.")
D, SP, PRE = 2048, 256, 4
PT = "VLA-JEPA-LIBERO.pt"
sys.path.insert(0, str(ROOT / "vla_adapter"))
from export_npu import check, precision, Half  # noqa: E402


class W(nn.Module):
    def __init__(self):
        super().__init__()
        t = load_file(str(B / "vla_jepa.safetensors"))
        self.p = nn.ParameterDict({k.replace(".", "__"): nn.Parameter(v, requires_grad=False) for k, v in t.items()})
        self.dtype = torch.float32

    def forward(self, name):
        return self.p[name.replace(".", "__")].to(self.dtype)


def lin(x, w, name, bias=True):
    return F.linear(x, w(name + ".weight"), w(name + ".bias") if bias else None)


def rot(x):
    h = x.shape[-1] // 2
    return torch.cat([-x[..., h:], x[..., :h]], -1)


class Vision(nn.Module):
    """Qwen3-VL's ViT on both views (residual kept / C), the DeepStack mergers and the final merger."""

    C = 16.0

    def __init__(self, w, posemb, vcos, vsin):
        super().__init__()
        self.w, self.posemb, self.cos, self.sin = w, posemb, vcos, vsin  # [256, 1024], [256, 64] x 2

    def merge(self, x, p, post):
        w = self.w
        if post:
            x = F.layer_norm(x.reshape(128, 4096), (4096,), w(p + "norm.weight"), w(p + "norm.bias"), 1e-6)
        else:
            x = F.layer_norm(x, (1024,), w(p + "norm.weight"), w(p + "norm.bias"), 1e-6).reshape(128, 4096)
        return lin(F.gelu(lin(x, w, p + "linear_fc1")), w, p + "linear_fc2")

    def forward(self, pix):
        w, C = self.w, self.C
        eps = 1e-6 / C / C
        x = F.linear(pix, w(VQ + "patch_embed.proj.weight").reshape(1024, 1536), w(VQ + "patch_embed.proj.bias"))
        x = (x + torch.cat([self.posemb, self.posemb], 0)) * (1.0 / C)
        cos, sin = torch.cat([self.cos, self.cos], 0), torch.cat([self.sin, self.sin], 0)  # [512, 64]
        ds = []
        for i in range(24):
            p = VQ + f"blocks.{i}."
            y = F.layer_norm(x, (1024,), w(p + "norm1.weight"), w(p + "norm1.bias"), eps)
            qkv = lin(y, w, p + "attn.qkv").view(512, 3, 16, 64).permute(1, 2, 0, 3)  # [3, 16, 512, 64]
            q = qkv[0] * cos + rot(qkv[0]) * sin
            k = qkv[1] * cos + rot(qkv[1]) * sin
            q, k, v = q.view(16, 2, 256, 64), k.view(16, 2, 256, 64), qkv[2].view(16, 2, 256, 64)
            o = torch.softmax((q * 0.125) @ k.transpose(-1, -2), -1) @ v  # per view
            o = o.reshape(16, 512, 64).transpose(0, 1).reshape(512, 1024)
            x = x + lin(o, w, p + "attn.proj") * (1.0 / C)
            y = F.layer_norm(x, (1024,), w(p + "norm2.weight"), w(p + "norm2.bias"), eps)
            x = x + lin(F.gelu(lin(y, w, p + "mlp.linear_fc1"), approximate="tanh"), w, p + "mlp.linear_fc2") * (1.0 / C)
            if i in (5, 11, 17):
                ds.append(self.merge(x * C, VQ + f"deepstack_merger_list.{(i - 5) // 6}.", True))
        return self.merge(x * C, VQ + "merger.", False), torch.stack(ds)


def rms(x, g, eps):
    return g * (x * torch.rsqrt((x * x).mean(-1, keepdim=True) + eps))


class LLM(nn.Module):
    """Qwen3's 28 layers over rows 4 .. 255, rows 0 .. 3's keys and values given (constants), residual kept / C."""

    C = 64.0

    def __init__(self, w, img0, pre_k, pre_v):
        super().__init__()
        self.w, self.img0 = w, img0  # each view's first image row
        self.pre_k, self.pre_v = pre_k, pre_v  # [28, 8, 4, 128]

    def forward(self, emb, vis, ds, cos, sin, mask_add):
        w, C = self.w, self.C
        n = SP - PRE
        eps = 1e-6 / C / C
        parts = []
        at = PRE
        for v in range(2):  # the image rows from the vision graph
            parts += [emb[at - PRE:self.img0[v] - PRE], vis[v * 64:(v + 1) * 64]]
            at = self.img0[v] + 64
        parts.append(emb[at - PRE:])
        x = torch.cat(parts, 0) * (1.0 / C)
        for l in range(28):
            p = LQ + f"layers.{l}."
            y = rms(x, w(p + "input_layernorm.weight"), eps)
            q = F.linear(y, w(p + "self_attn.q_proj.weight")).view(n, 16, 128).transpose(0, 1)
            k = F.linear(y, w(p + "self_attn.k_proj.weight")).view(n, 8, 128).transpose(0, 1)
            v = F.linear(y, w(p + "self_attn.v_proj.weight")).view(n, 8, 128).transpose(0, 1)
            q = rms(q, w(p + "self_attn.q_norm.weight"), 1e-6)
            k = rms(k, w(p + "self_attn.k_norm.weight"), 1e-6)
            q, k = q * cos + rot(q) * sin, k * cos + rot(k) * sin
            k = torch.cat([self.pre_k[l], k], 1).repeat_interleave(2, 0)  # [16, 256, 128]
            v = torch.cat([self.pre_v[l], v], 1).repeat_interleave(2, 0)
            o = torch.softmax((q * (128 ** -0.5)) @ k.transpose(-1, -2) + mask_add, -1) @ v
            x = x + F.linear(o.transpose(0, 1).reshape(n, D), w(p + "self_attn.o_proj.weight")) * (1.0 / C)
            y = rms(x, w(p + "post_attention_layernorm.weight"), eps)
            g = F.linear(y, w(p + "mlp.gate_proj.weight"))
            u = F.linear(y, w(p + "mlp.up_proj.weight"))
            x = x + F.linear(F.silu(g) * u, w(p + "mlp.down_proj.weight")) * (1.0 / C)
            if l < 3:
                rows = []
                at = 0
                for vw in range(2):
                    s0 = self.img0[vw] - PRE
                    rows += [x[at:s0], x[s0:s0 + 64] + ds[l, vw * 64:(vw + 1) * 64] * (1.0 / C)]
                    at = s0 + 64
                rows.append(x[at:])
                x = torch.cat(rows, 0)
        return x * C  # the caller takes the embodied rows


class Head(nn.Module):
    """VLA-JEPA's flow-matching DiT, 4 Euler steps unrolled; the per-step timestep tables are constants."""

    C = 16.0

    def __init__(self, w):
        super().__init__()
        self.w = w
        t = torch.tensor([0.0, 250.0, 500.0, 750.0])
        e = torch.exp(-math.log(10000) * torch.arange(128, dtype=torch.float32) / 127)
        f = t[:, None] * e[None]
        tp = torch.cat([torch.cos(f), torch.sin(f)], -1)
        te = DM + "timestep_encoder.timestep_embedder."
        temb = lin(F.silu(lin(tp, w, te + "linear_1")), w, te + "linear_2")
        st = F.silu(temb)
        self.mods = torch.stack([lin(st, w, DM + f"transformer_blocks.{b}.norm1.linear") for b in range(16)], 1)
        self.outmod = lin(st, w, DM + "proj_out_1")  # [4, 1536]
        e2 = torch.exp(-torch.arange(384, dtype=torch.float32) * (math.log(10000.0) / 384))
        f2 = t[:, None] * e2[None]
        self.tau = torch.cat([torch.sin(f2), torch.cos(f2)], -1)  # [4, 768]

    def ln(self, x, eps):
        return F.layer_norm(x, (768,), None, None, eps)

    def forward(self, vl, state, noise):
        w, C = self.w, self.C
        s = lin(F.relu(lin(state, w, AM + "state_encoder.layer1")), w, AM + "state_encoder.layer2")  # [1, 768]
        ck, cv = [], []
        for b in range(0, 16, 2):
            p = DM + f"transformer_blocks.{b}.attn1."
            k = lin(vl, w, p + "to_k").view(32, 12, 64).transpose(0, 1)
            ck.append(k - k.mean(1, keepdim=True))  # logits reach 3,319; a constant shift per query row
            cv.append(lin(vl, w, p + "to_v").view(32, 12, 64).transpose(0, 1))
        x = noise
        for st in range(4):
            a = lin(x, w, AM + "action_encoder.layer1")
            a = torch.cat([a, self.tau[st].expand(7, -1)], -1)
            a = lin(F.silu(lin(a, w, AM + "action_encoder.layer2")), w, AM + "action_encoder.layer3")
            a = a + w(AM + "position_embedding.weight")[:7]
            h = torch.cat([s, w(AM + "future_tokens.weight"), a], 0) * (1.0 / C)  # [40, 768]
            for b in range(16):
                p = DM + f"transformer_blocks.{b}."
                m = self.mods[st, b]
                y = self.ln(h, 1e-5 / C / C) * (1 + m[:768]) + m[768:]
                q = lin(y, w, p + "attn1.to_q").view(40, 12, 64).transpose(0, 1)
                if b % 2 == 0:
                    k, v = ck[b // 2], cv[b // 2]
                else:
                    k = lin(y, w, p + "attn1.to_k").view(40, 12, 64).transpose(0, 1)
                    v = lin(y, w, p + "attn1.to_v").view(40, 12, 64).transpose(0, 1)
                    k = k - k.mean(1, keepdim=True)
                o = torch.softmax((q * 0.125) @ k.transpose(-1, -2), -1) @ v
                h = h + lin(o.transpose(0, 1).reshape(40, 768), w, p + "attn1.to_out.0") * (1.0 / C)
                y = self.ln(h, 1e-5 / C / C)
                h = h + lin(F.gelu(lin(y, w, p + "ff.net.0.proj"), approximate="tanh"), w, p + "ff.net.2") * (1.0 / C)
            m = self.outmod[st]
            y = self.ln(h, 1e-6 / C / C) * (1 + m[768:]) + m[:768]
            o = lin(y, w, DM + "proj_out_2")
            vel = lin(F.relu(lin(o, w, AM + "action_decoder.layer1")), w, AM + "action_decoder.layer2")[-7:]
            x = x + vel * 0.25
        return x


def externalize(path):
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


def prefix_kv(w, emb, cos, sin):
    """Rows 0 .. 3's keys (normed, rotated) and values in every layer, in fp32 (their residual reaches 37,897)."""
    x = emb[:PRE]
    ks, vs = [], []
    mask = torch.full((PRE, PRE), float("-inf")).triu(1)
    for l in range(28):
        p = LQ + f"layers.{l}."
        y = rms(x, w(p + "input_layernorm.weight"), 1e-6)
        q = F.linear(y, w(p + "self_attn.q_proj.weight")).view(PRE, 16, 128).transpose(0, 1)
        k = F.linear(y, w(p + "self_attn.k_proj.weight")).view(PRE, 8, 128).transpose(0, 1)
        v = F.linear(y, w(p + "self_attn.v_proj.weight")).view(PRE, 8, 128).transpose(0, 1)
        q = rms(q, w(p + "self_attn.q_norm.weight"), 1e-6)
        k = rms(k, w(p + "self_attn.k_norm.weight"), 1e-6)
        q, k = q * cos[:PRE] + rot(q) * sin[:PRE], k * cos[:PRE] + rot(k) * sin[:PRE]
        ks.append(k)
        vs.append(v)
        kk, vv = k.repeat_interleave(2, 0), v.repeat_interleave(2, 0)
        o = torch.softmax((q * 128 ** -0.5) @ kk.transpose(-1, -2) + mask, -1) @ vv
        x = x + F.linear(o.transpose(0, 1).reshape(PRE, D), w(p + "self_attn.o_proj.weight"))
        y = rms(x, w(p + "post_attention_layernorm.weight"), 1e-6)
        x = x + F.linear(F.silu(F.linear(y, w(p + "mlp.gate_proj.weight"))) * F.linear(y, w(p + "mlp.up_proj.weight")),
                         w(p + "mlp.down_proj.weight"))
    return torch.stack(ks), torch.stack(vs)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "in").mkdir(exist_ok=True)
    ref = B / "ref"
    rd = lambda n, dt=np.float32: np.fromfile(ref / n, dt)
    t = torch.from_numpy
    w = W()
    ids = rd("input_ids.i32", np.int32)
    S = len(ids)
    img0 = [int(v) for v in rd("image_token_positions.i32", np.int32).reshape(2, 64)[:, 0]]
    emb0 = int(rd("embodied_token_positions.i32", np.int32)[0])
    lcos = np.zeros((SP, 128), np.float32)
    lsin = np.zeros((SP, 128), np.float32)
    lcos[:S] = rd("llm_rope_cos.f32").reshape(S, 128)
    lsin[:S] = rd("llm_rope_sin.f32").reshape(S, 128)
    emb = np.zeros((SP, D), np.float32)
    emb[:S] = rd("llm_input_embeds.f32").reshape(S, D)
    n = SP - PRE
    mask = np.full((n, SP), NEG, np.float32)
    for i in range(n):
        if PRE + i < S:
            mask[i, :PRE + i + 1] = 0.0
        else:
            mask[i, 0] = 0.0
    pix = rd("pixel_values.f32").reshape(512, 1536)
    posemb = t(rd("vit_pos_embed.f32").reshape(256, 1024))  # a function of the weights and the grid (the GPU port
    vcos = t(rd("vit_rope_cos.f32").reshape(256, 64))  # computes them itself); constants of the graph
    vsin = t(rd("vit_rope_sin.f32").reshape(256, 64))
    with torch.no_grad():
        pre_k, pre_v = prefix_kv(w, t(emb), t(lcos), t(lsin))
    vision = Vision(w, posemb, vcos, vsin)
    llm = LLM(w, img0, pre_k, pre_v)
    head = Head(w)
    vis_ref = rd("vit_merger.f32").reshape(128, D)
    ds_ref = np.stack([rd(f"vit_deepstack{k}.f32").reshape(128, D) for k in range(3)])
    vl_ref = rd("embodied_hidden.f32").reshape(32, D)
    with torch.no_grad():
        print("fp32 PyTorch modules against the official model's tensors:")
        vis, ds = vision(t(pix))
        check("vision tokens (merger)", vis, vis_ref)
        check("DeepStack sets", ds, ds_ref)
        out = llm(t(emb[PRE:]), t(vis_ref), t(ds_ref), t(lcos[PRE:, :128]), t(lsin[PRE:, :128]), t(mask))
        check("embodied rows (layer 27, before the final norm)", out[emb0 - PRE:emb0 - PRE + 32], vl_ref)
        x = head(t(vl_ref), t(rd("state_raw.f32").reshape(1, 8)), t(rd("noise.f32").reshape(7, 7)))
        check("actions (normalized)", x, rd("actions_norm.f32"))

    class LLMOut(nn.Module):  # the graph returns only the embodied rows
        def __init__(self, m):
            super().__init__()
            self.m = m

        def forward(self, *a):
            return self.m(*a)[emb0 - PRE:emb0 - PRE + 32]

    with torch.no_grad():
        for name in ("posemb", "cos", "sin"):
            setattr(vision, name, getattr(vision, name).half())
        llm.pre_k, llm.pre_v = llm.pre_k.half(), llm.pre_v.half()
        head.mods, head.outmod, head.tau = head.mods.half(), head.outmod.half(), head.tau.half()
        w.dtype = torch.float16
        export(Half(vision), (t(pix),), ["pixels"], ["tokens", "deepstack"], OUT / "vision.onnx")
        export(Half(LLMOut(llm)), (t(emb[PRE:]), t(vis_ref), t(ds_ref), t(lcos[PRE:]), t(lsin[PRE:]), t(mask)),
               ["embeds", "vision", "deepstack", "cos", "sin", "mask"], ["embodied"], OUT / "llm.onnx")
        export(Half(head), (t(vl_ref), t(rd("state_raw.f32").reshape(1, 8)), t(rd("noise.f32").reshape(7, 7))),
               ["vl", "state", "noise"], ["x"], OUT / "head.onnx")
    for name, arr in (("pixels", pix), ("embeds", emb[PRE:].copy()), ("cos", lcos[PRE:].copy()),
                      ("sin", lsin[PRE:].copy()), ("mask", mask), ("state", rd("state_raw.f32").reshape(1, 8)),
                      ("noise", rd("noise.f32").reshape(7, 7)), ("ref_vl", vl_ref)):
        arr.tofile(OUT / "in" / (name + ".f32"))
    print("inputs in", OUT / "in")


if __name__ == "__main__":
    main()
