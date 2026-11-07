"""VLA-Adapter (Pro, LIBERO-Spatial) as static ONNX graphs for the Hexagon NPU (ONNX Runtime's QNN execution
provider), written to build/vla_adapter/npu from the checkpoint's bf16 tensors (model.safetensors and
head_bf16.safetensors), the modules written out (no shape logic), each checked in fp32 on the Mac's CPU against the
official model's tensors (build/vla_adapter/ref):

  vision.onnx  DINOv2-normalized and SigLIP-normalized pixels [2, 3, 224, 224] each -> the 512 projected vision tokens
               [512, 896]: DINOv2-L (blocks 0 .. 22), SigLIP-So400m (0 .. 25), the projector
  llm.onnx     the prefix's embeddings [640, 896] (vision rows ignored), the vision tokens [512, 896], an additive
               mask [640, 640], the window rows [576] int32 -> the 24 taps [24, 576, 896]: Qwen2.5-0.5B
  policy.onnx  the taps, the normalized state [1, 8] -> the normalized actions [8, 7]: the proprio projector and the 24
               Pro blocks

The graphs are exported with fp16 weights and fp32 inputs and outputs (cast inside): the HTP computes in fp16 either
way, and in fp32 the vision graph would pass protobuf's 2 GB.

  build/turbovla/venv/bin/python vla_adapter/export_npu.py
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
B = ROOT / "build/vla_adapter"
OUT = B / "npu"
NEG = -30000.0
VB, SB, LM, AH, PP = ("vision_backbone.featurizer.", "vision_backbone.fused_featurizer.", "language_model.model.",
                      "action_head.model.", "proprio_projector.")
SP, VROWS, TAP, D = 640, 512, 576, 896


sys.path.insert(0, str(ROOT / "npu"))
from htp_norms import ln16, rms16  # noqa: E402  (fp16-safe norms)


class W(nn.Module):
    """The checkpoint's tensors as the graph's parameters, bf16 as stored, returned in self.dtype (fp32 for the
    checks, fp16 for export): the cast, and any scaling a module applies, are graph nodes on the raw tensor, so
    externalize() can point each parameter at its bytes in the checkpoint files (ONNX Runtime folds the casts when it
    loads the graph)."""

    def __init__(self):
        super().__init__()
        t = load_file(str(B / "hf/model.safetensors"))
        t.update(load_file(str(B / "head_bf16.safetensors")))
        self.p = nn.ParameterDict({k.replace(".", "__"): nn.Parameter(v, requires_grad=False) for k, v in t.items()})
        self.dtype = torch.float32

    def forward(self, name):
        return self.p[name.replace(".", "__")].to(self.dtype)


FILES = [("model.safetensors", B / "hf/model.safetensors"), ("head_bf16.safetensors", B / "head_bf16.safetensors")]


def externalize(path):
    """Every bf16 parameter of the graph at `path` pointed at its bytes in the checkpoint files (FILES: the name the
    laptop knows, in the graph's directory, and the local copy), so the graph carries no weights."""
    import onnx
    import struct
    where = {}
    for loc, local in FILES:
        with open(local, "rb") as f:
            n = struct.unpack("<Q", f.read(8))[0]
            head = json.loads(f.read(n))
        for k, v in head.items():
            if k != "__metadata__":
                where[k.replace(".", "__")] = (loc, 8 + n + v["data_offsets"][0], v["data_offsets"][1] - v["data_offsets"][0])
    # the head's tensors from the official .pt files instead (pt_offsets.txt: name, file, offset), which the laptop
    # downloads itself
    for line in (B / "pt_offsets.txt").read_text().splitlines():
        name, loc, off = line.split(" ")
        key = name.replace(".", "__")
        where[key] = (loc, int(off), where[key][2])
    m = onnx.load(str(path))
    moved = kept = 0
    for init in m.graph.initializer:
        key = init.name.split("p.", 1)[-1]
        if init.data_type == onnx.TensorProto.BFLOAT16 and key in where:
            loc, off, length = where[key]
            assert len(init.raw_data) == length, init.name
            init.ClearField("raw_data")
            init.data_location = onnx.TensorProto.EXTERNAL
            del init.external_data[:]
            for k, v in (("location", loc), ("offset", str(off)), ("length", str(length))):
                e = init.external_data.add()
                e.key, e.value = k, v
            moved += 1
        else:
            kept += 1
    onnx.save(m, str(path))
    print(f"{path.name}: {moved} parameters point into the checkpoint files, {kept} constants kept; "
          f"{path.stat().st_size / 1e6:.1f} MB")


def lin(x, w, name, bias=True):
    return F.linear(x, w(name + ".weight"), w(name + ".bias") if bias else None)


class ViT(nn.Module):
    """A timm ViT's first `blocks` blocks (DINOv2 with CLS, registers and LayerScale; or SigLIP), patch tokens out.
    fp16-safe: the LayerNorms are ln16 (DINOv2's registers reach 528 and SigLIP carries 288, whose squares overflow
    fp16; a residual stream divided by 16 instead made small activations' squares subnormal, which the HTP flushes).
    C (the residual's scale) stays 1."""

    C = 1.0

    def __init__(self, w, pre, blocks, heads, dino):
        super().__init__()
        self.w, self.pre, self.blocks, self.heads, self.dino = w, pre, blocks, heads, dino

    def out(self, x, name, ls):
        """A projection onto the residual, its output times LayerScale (DINOv2) and 1 / C. Scaled after the product,
        not folded into the weights: folded, 97% of DINOv2's would be fp16 subnormals, which the HTP flushes to 0."""
        y = lin(x, self.w, name)
        return y * (self.w(ls) / self.C) if self.dino else y * (1.0 / self.C)

    def forward(self, pix):  # [2, 3, 224, 224] -> [2, 256, C]
        w, p = self.w, self.pre
        C = self.C
        x = F.conv2d(pix, w(p + "patch_embed.proj.weight"), w(p + "patch_embed.proj.bias"), stride=14) * (1.0 / C)
        x = x.flatten(2).transpose(1, 2) + w(p + "pos_embed") * (1.0 / C)
        if self.dino:
            x = torch.cat([w(p + "cls_token").expand(2, -1, -1) / C, w(p + "reg_token").expand(2, -1, -1) / C, x], 1)
        n, c = x.shape[1], x.shape[2]
        hd = c // self.heads
        for i in range(self.blocks):
            b = p + f"blocks.{i}."
            y = ln16(x, w(b + "norm1.weight"), w(b + "norm1.bias"))
            qkv = lin(y, w, b + "attn.qkv").view(2, n, 3, self.heads, hd).permute(2, 0, 3, 1, 4)
            k = qkv[1] - qkv[1].mean(-2, keepdim=True)  # centered: each query's logits shift by a constant
            o = torch.softmax((qkv[0] * hd ** -0.5) @ k.transpose(-1, -2), -1) @ qkv[2]
            x = x + self.out(o.transpose(1, 2).reshape(2, n, c), b + "attn.proj", b + "ls1.scale_factor")
            y = ln16(x, w(b + "norm2.weight"), w(b + "norm2.bias"))
            x = x + self.out(F.gelu(lin(y, w, b + "mlp.fc1")), b + "mlp.fc2", b + "ls2.scale_factor")
        x = x * C
        return x[:, 5:] if self.dino else x


class Vision(nn.Module):
    def __init__(self, w):
        super().__init__()
        self.w = w
        self.dino = ViT(w, VB, 23, 16, True)
        self.sig = ViT(w, SB, 26, 16, False)

    def forward(self, pix_d, pix_s):  # -> [512, 896]
        f = torch.cat([self.dino(pix_d), self.sig(pix_s)], -1).reshape(VROWS, 2176)
        w = self.w
        return lin(F.gelu(lin(F.gelu(lin(f, w, "projector.fc1")), w, "projector.fc2")), w, "projector.fc3")


def rms(x, g, eps=1e-6):
    return g * (x * torch.rsqrt((x * x).mean(-1, keepdim=True) + eps))


class LLM(nn.Module):
    """Qwen2.5-0.5B over the 640 rows: [prefix row 0, the vision rows, prefix rows 513 ..]; the windows of every
    layer's output (the last after the final RMSNorm). fp16-safe: the RMSNorms are rms16 (the residual stream reaches
    1,463 at row 0; dividing it by 64 instead made small activations' squares subnormal, which the HTP flushes). Each
    head's keys are centered and q carries the 1/8: the logits reach 2,277 otherwise (62 centered), too coarse in
    fp16. C (the residual's scale) stays 1."""

    C = 1.0

    def __init__(self, w):
        super().__init__()
        self.w = w
        inv = 1.0 / (1e6 ** (torch.arange(0, 64, 2).float() / 64))
        f = torch.arange(SP).float()[:, None] * inv[None]
        emb = torch.cat([f, f], -1)
        self.cos, self.sin = emb.cos(), emb.sin()  # [640, 64]

    def rope(self, x):  # [h, 640, 64]
        half = torch.cat([-x[..., 32:], x[..., :32]], -1)
        return x * self.cos + half * self.sin

    def forward(self, prefix, vis, mask_add, idx):
        w, C = self.w, self.C
        # row-wise work on the rows as [5, 128, D]: the HTP runs it faster than on one long [SP, D]
        x = (torch.cat([prefix[:1], vis, prefix[1 + VROWS:]], 0) / C).reshape(5, SP // 5, D)
        taps = []
        for l in range(24):
            p = LM + f"layers.{l}."
            y = rms16(x, w(p + "input_layernorm.weight"))
            q = lin(y, w, p + "self_attn.q_proj").view(SP, 14, 64).transpose(0, 1)
            k = lin(y, w, p + "self_attn.k_proj").view(SP, 2, 64).transpose(0, 1)
            v = lin(y, w, p + "self_attn.v_proj").view(SP, 2, 64).transpose(0, 1)
            q, k = self.rope(q), self.rope(k)
            k = k - k.mean(1, keepdim=True)  # each head's mean key: shifts a query's logits by a constant (from 2,277 to 62)
            k, v = k.repeat_interleave(7, 0), v.repeat_interleave(7, 0)
            o = torch.softmax((q * 0.125) @ k.transpose(-1, -2) + mask_add, -1) @ v
            x = x + F.linear(o.transpose(0, 1).reshape(5, SP // 5, D), w(p + "self_attn.o_proj.weight")) * (1.0 / C)
            y = rms16(x, w(p + "post_attention_layernorm.weight"))
            g = F.linear(y, w(p + "mlp.gate_proj.weight"))
            u = F.linear(y, w(p + "mlp.up_proj.weight"))
            x = x + F.linear(F.silu(g) * u, w(p + "mlp.down_proj.weight")) * (1.0 / C)
            rows = x.reshape(SP, D)
            out = rms16(rows, w(LM + "norm.weight")) if l == 23 else rows[idx] * C
            taps.append(out[idx] if l == 23 else out)
        return torch.stack(taps)  # [24, 576, 896]


class Policy(nn.Module):
    """The proprio projector and the Pro policy over 8 rows (VLA-Adapter's RoPE, the joint softmax)."""

    def __init__(self, w):
        super().__init__()
        self.w = w
        inv = 1.0 / (1e4 ** (torch.arange(0, 112, 2).float() / 112))
        f = torch.arange(VROWS).float()[:, None] * inv[None]
        emb = torch.cat([f, f], -1)
        self.cos, self.sin = emb.cos(), emb.sin()  # [512, 112]
        z = F.layer_norm(torch.zeros(1, 6272), (6272,), w(AH + "layer_norm1.weight"), w(AH + "layer_norm1.bias"))
        self.x0 = torch.relu(lin(z, w, AH + "fc1")).expand(8, -1).clone()

    def rope(self, x):  # [8 heads, n, 112]
        n = x.shape[1]
        rot = torch.stack([-x[..., 1::2], x[..., ::2]], -1).reshape(x.shape)
        return x * self.cos[:n] + rot * self.sin[:n]

    def forward(self, taps, prop):
        w = self.w
        p = lin(F.gelu(lin(prop, w, PP + "fc1")), w, PP + "fc2")  # [1, 896]
        x = self.x0
        heads = lambda t: t.view(t.shape[0], 8, 112).transpose(0, 1)
        for i in range(24):
            b = AH + f"mlp_resnet_blocks.{i}."
            ha = torch.cat([taps[i, VROWS:], p], 0)
            ht = taps[i, :VROWS]
            q, ks, vs = heads(lin(x, w, b + "q_proj")), heads(lin(x, w, b + "k_self")), heads(lin(x, w, b + "v_self"))
            ka, va = heads(lin(ha, w, b + "k_adapter")), heads(lin(ha, w, b + "v_adapter"))
            kt, vt = heads(lin(ht, w, b + "k_task")), heads(lin(ht, w, b + "v_task"))
            q, ks, ka, kt = self.rope(q), self.rope(ks), self.rope(ka), self.rope(kt)
            g = torch.tanh(w(b + "gating_factor"))
            s = torch.cat([q @ ks.transpose(-1, -2), q @ ka.transpose(-1, -2), (q @ kt.transpose(-1, -2)) * g], -1)
            o = torch.softmax(s / math.sqrt(112), -1) @ torch.cat([vs, va, vt], 1)
            o = lin(o.transpose(0, 1).reshape(8, D), w, b + "o_proj")
            y = ln16(o + x, w(b + "ffn.0.weight"), w(b + "ffn.0.bias"), 1e-5)
            x = torch.relu(lin(y, w, b + "ffn.1"))
        y = ln16(x, w(AH + "layer_norm2.weight"), w(AH + "layer_norm2.bias"), 1e-5)
        return lin(y, w, AH + "fc2")  # [8, 7]


class Half(nn.Module):
    """A module run in fp16 with fp32 inputs and outputs (integer inputs passed through)."""

    def __init__(self, m):
        super().__init__()
        self.m = m

    def forward(self, *xs):
        ys = self.m(*(x.half() if x.is_floating_point() else x for x in xs))
        return tuple(y.float() for y in ys) if isinstance(ys, tuple) else ys.float()


def precision(m, dtype):
    """The module's weights and constant tables in dtype (fp16 for export, fp32 for the checks)."""
    m.w.dtype = dtype
    for name in ("cos", "sin", "x0"):
        if hasattr(m, name):
            setattr(m, name, getattr(m, name).to(dtype))
    return m


def export(module, args, names, outs, path):
    """The graph with its parameters as raw bf16 initializers (no constant folding, no onnxsim: either would bake
    fp16 copies in), then externalize()d."""
    import onnx
    torch.onnx.export(module, args, str(path), input_names=names, output_names=outs, opset_version=20,
                      dynamo=False, do_constant_folding=False)
    externalize(path)
    g = onnx.load(str(path), load_external_data=False)
    print(f"{path.name}: {len(g.graph.node)} nodes; ops {' '.join(sorted({n.op_type for n in g.graph.node}))}")


def check(name, got, want):
    got, want = np.asarray(got, np.float32).ravel(), np.asarray(want, np.float32).ravel()
    print(f"  {name}: max abs error {np.abs(got - want).max():.3g} (largest reference value {np.abs(want).max():.3g})")


def main():
    import onnxruntime  # noqa: F401  (fail early if missing)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "in").mkdir(exist_ok=True)
    ref = B / "ref"
    meta = json.loads((ref / "meta.json").read_text())
    rd = lambda n, dt=np.float32: np.fromfile(ref / n, dt)
    L, S = meta["L"], meta["S"]
    w = W()
    pv = rd("pixel_values.f32").reshape(12, 224, 224)
    pix_d = np.stack([pv[0:3], pv[6:9]])
    pix_s = np.stack([pv[3:6], pv[9:12]])
    emb = rd("llm_inputs_embeds.f32").reshape(S, D)
    prefix = np.zeros((SP, D), np.float32)
    prefix[:S] = emb  # the vision rows (1 .. 512) are taken from the vision input
    prefix[S:] = w(LM + "embed_tokens.weight")[0].float().numpy()  # padding: token 0's row, as on the GPU
    mask = np.full((SP, SP), NEG, np.float32)
    for i in range(SP):
        mask[i, :min(i, S - 1) + 1] = 0.0 if i < S else NEG
    mask[S:, 0] = 0.0  # padding rows see row 0: finite, unused
    idx = np.concatenate([np.arange(VROWS), np.arange(L + VROWS - 1, L + VROWS + 63)]).astype(np.int32)
    prop = rd("proprio_norm.f32").reshape(1, 8)
    vis_ref = rd("projector.f32").reshape(VROWS, D)
    taps_ref = np.stack([rd(f"llm_hidden_{j:02d}.f32").reshape(S, D)[idx] for j in range(1, 25)])
    act_ref = rd("policy_actions_norm.f32").reshape(8, 7)

    vision, llm, policy = Vision(w), LLM(w), Policy(w)
    t = torch.from_numpy
    with torch.no_grad():
        print("fp32 PyTorch modules against the official model's tensors:")
        vis = vision(t(pix_d), t(pix_s))
        check("vision tokens (projector)", vis, vis_ref)
        taps = llm(t(prefix), t(vis_ref), t(mask), t(idx))
        check("LLM taps (24 x 576 x 896), from the reference's vision tokens", taps, taps_ref)
        act = policy(t(taps_ref), t(prop))
        check("actions (normalized), from the reference's taps", act, act_ref)
    with torch.no_grad():
        export(Half(precision(vision, torch.float16)), (t(pix_d), t(pix_s)), ["pix_d", "pix_s"], ["vision"],
               OUT / "vision.onnx")
        export(Half(precision(llm, torch.float16)), (t(prefix), t(vis_ref), t(mask), t(idx)),
               ["prefix", "vision", "mask", "idx"], ["taps"], OUT / "llm.onnx")
        export(Half(precision(policy, torch.float16)), (t(taps_ref), t(prop)), ["taps", "prop"], ["actions"],
               OUT / "policy.onnx")
    for name, arr in (("pix_d", pix_d), ("pix_s", pix_s), ("prefix", prefix), ("mask", mask), ("idx", idx),
                      ("prop", prop), ("ref_vision", vis_ref), ("ref_taps", taps_ref)):
        arr.tofile(OUT / "in" / (name + (".i32" if arr.dtype == np.int32 else ".f32")))
    print("inputs in", OUT / "in")


if __name__ == "__main__":
    main()
