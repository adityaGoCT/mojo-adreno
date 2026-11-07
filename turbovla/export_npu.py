"""TurboVLA as static ONNX graphs for the Hexagon NPU (ONNX Runtime's QNN execution provider), written to
build/turbovla/npu, each checked on the Mac's CPU against turbovla/reference.py's tensors:

  vision.onnx  pixels [1, 2, 3, 256, 256] -> vision tokens [1, 512, 256]: DINOv3 ViT-B/16 on both views, the
               projection and the view embedding (about 90% of a chunk's FLOPs)
  text.onnx    ids, positions [1, 21] int32, an additive mask [1, 21, 21], keep [1, 21, 1] -> text tokens [1, 21, 256]:
               BERT and the projection, once per instruction
  head.onnx    vision tokens, text tokens, the vision -> text key mask [1, 1, 21], the text self-attention mask
               [1, 21, 21] (additive), state [1, 8] -> actions [1, 12, 7]: 6 fusion and text layers, the state's
               tokens, the ACT decoder, the MLP and tanh

The graphs compute in fp32 (the HTP runs them in fp16). Masks are additive floats (0 or -30000, which fp16 holds) in
place of TurboVLA's boolean ones; the head's fusion attention is written out with them, the same arithmetic.
Inputs for the laptop's run go to build/turbovla/npu/in (raw fp32 / int32 files, in each graph's input order).

  build/turbovla/venv/bin/python turbovla/export_npu.py
"""

import json
import pathlib
import sys

import numpy as np
import torch
from torch import nn

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "turbovla"))
import reference as R  # noqa: E402
sys.path.insert(0, str(ROOT / "npu"))
from htp_norms import swap_layernorms  # noqa: E402

OUT = R.B / "npu"
NEG = -30000.0


def build():
    from turbovla.models.configuration import TurboVLAConfig
    from turbovla.models.turbovla import TurboVLA
    d, t = R.local_dirs()
    ck = torch.load(R.B / "hf/turbovla_libero.pth", map_location="cpu", weights_only=True)
    cfg = dict(ck["model_config"])
    cfg["text"] = dict(cfg["text"], model_name_or_path=str(t))
    cfg["vision"] = dict(cfg["vision"], model_name_or_path=str(d), compute_precision="fp32")
    m = TurboVLA(TurboVLAConfig.from_mapping(cfg))
    m.load_state_dict(ck["model_state_dict"], strict=True)
    m = m.float().eval()
    m.vision_encoder.backbone.config._attn_implementation = "eager"
    m.text_encoder.bert.config._attn_implementation = "eager"
    swap_layernorms(m)  # every LayerNorm fp16-safe on the HTP (npu/htp_norms.py); the same function
    return m


class Vision(nn.Module):
    """DINOv3 ViT-B/16 on both views (written out: RoPE tables as constants, so the graph is static), the vision
    projection and the view embedding."""

    def __init__(self, m):
        super().__init__()
        self.m = m
        bb = m.vision_encoder.backbone
        cos, sin = bb.rope_embeddings(torch.zeros(1, 3, 256, 256))
        self.register_buffer("cos", cos.clone())  # [256, 64]
        self.register_buffer("sin", sin.clone())

    def dino(self, pix):  # [V, 3, 256, 256] -> patch tokens [V, 256, 768], after the final LayerNorm
        """Written for fp16 (the HTP), the same function: DINOv3's registers carry activations up to 17,000, inside
        fp16 but not their squares: the LayerNorms are htp_norms' (each row scaled first; a residual stream divided by
        256 instead made small activations' squares subnormal, which the HTP flushes). Layer 0's attention scores
        reach 86,689 across whole rows, so the keys are centered per head (each query row's scores shift by a
        constant, which the softmax ignores) and q carries the 1/8."""
        bb = self.m.vision_encoder.backbone
        e = bb.embeddings
        c = 1.0
        ln = lambda mod, x: mod(x)  # LN16 (build() swapped them in)
        x = e.patch_embeddings(pix).flatten(2).transpose(1, 2)
        nv = pix.shape[0]
        x = torch.cat([e.cls_token.expand(nv, -1, -1), e.register_tokens.expand(nv, -1, -1), x], 1) / c
        h, hd = 12, 64
        for layer in bb.layer:
            a = layer.attention
            y = ln(layer.norm1, x)
            q = (a.q_proj(y) * (hd ** -0.5)).view(nv, -1, h, hd).transpose(1, 2)
            k = a.k_proj(y).view(nv, -1, h, hd).transpose(1, 2)
            v = a.v_proj(y).view(nv, -1, h, hd).transpose(1, 2)
            q = torch.cat([q[:, :, :5], q[:, :, 5:] * self.cos + rot(q[:, :, 5:]) * self.sin], 2)
            k = torch.cat([k[:, :, :5], k[:, :, 5:] * self.cos + rot(k[:, :, 5:]) * self.sin], 2)
            k = k - k.mean(2, keepdim=True)
            o = torch.softmax(q @ k.transpose(-1, -2), dim=-1) @ v
            x = x + layer.layer_scale1(a.o_proj(o.transpose(1, 2).reshape(nv, -1, h * hd))) / c
            x = x + layer.layer_scale2(layer.mlp(ln(layer.norm2, x))) / c
        return ln(bb.norm, x)[:, 5:]

    def forward(self, pixels):  # [1, 2, 3, 256, 256] -> [1, 512, 256]
        m = self.m
        tokens = self.dino(pixels[0]).unsqueeze(0)  # [1, 2, 256, 768]
        tokens = m.vision_projection(tokens)
        return (tokens + m.view_embedding[:, :, None, :]).flatten(1, 2)


def rot(x):
    half = x.shape[-1] // 2
    return torch.cat([-x[..., half:], x[..., :half]], -1)


class Text(nn.Module):
    """BERT with an additive 3-D mask, the rows past the instruction's group zeroed (keep), then the projection."""

    def __init__(self, m):
        super().__init__()
        self.bert = m.text_encoder.bert
        self.proj = m.text_encoder.text_projection

    def forward(self, ids, pos, add_mask, keep):
        emb = self.bert.embeddings(input_ids=ids.long(), position_ids=pos.long(),
                                   token_type_ids=torch.zeros_like(ids).long())
        h = emb
        ext = add_mask[:, None, :, :]
        for layer in self.bert.encoder.layer:
            out = layer(h, attention_mask=ext)
            h = out[0] if isinstance(out, tuple) else out
        return self.proj(h * keep)


def bi_attention(attn, v, l, key_add):
    """BiMultiHeadAttention.forward (manual backend) with an additive mask on the text keys for the vision queries."""
    b, tv, _ = v.shape
    tl = l.shape[1]
    h, hd = attn.num_heads, attn.head_dim
    q = (attn.v_proj(v) * attn.scale).view(b, tv, h, hd).transpose(1, 2)
    k = attn.l_proj(l).view(b, tl, h, hd).transpose(1, 2)
    vv = attn.values_v_proj(v).view(b, tv, h, hd).transpose(1, 2)
    vl = attn.values_l_proj(l).view(b, tl, h, hd).transpose(1, 2)
    w = q @ k.transpose(-1, -2)  # [b, h, tv, tl]
    out_v = torch.softmax(w + key_add[:, None, :, :], dim=-1) @ vl
    out_l = torch.softmax(w.transpose(-1, -2), dim=-1) @ vv
    out_v = out_v.transpose(1, 2).reshape(b, tv, h * hd)
    out_l = out_l.transpose(1, 2).reshape(b, tl, h * hd)
    return attn.out_v_proj(out_v), attn.out_l_proj(out_l)


def text_layer(layer, x, self_add):
    """TransformerEncoderLayer (post-norm, relu) with an additive attention mask, written out."""
    sa = layer.self_attn
    b, t, d = x.shape
    h = sa.num_heads
    hd = d // h
    qkv = x @ sa.in_proj_weight.t() + sa.in_proj_bias
    q, k, v = qkv.split(d, dim=-1)
    q = q.view(b, t, h, hd).transpose(1, 2) / (hd ** 0.5)
    k = k.view(b, t, h, hd).transpose(1, 2)
    v = v.view(b, t, h, hd).transpose(1, 2)
    a = torch.softmax(q @ k.transpose(-1, -2) + self_add[:, None, :, :], dim=-1) @ v
    a = sa.out_proj(a.transpose(1, 2).reshape(b, t, d))
    x = layer.norm1(x + a)
    return layer.norm2(x + layer.linear2(torch.relu(layer.linear1(x))))


def mha(sa, xq, xkv, add=None):
    """nn.MultiheadAttention (batch first, packed in_proj) written out, an optional additive mask."""
    b, tq, d = xq.shape
    tk = xkv.shape[1]
    h = sa.num_heads
    hd = d // h
    w, bias = sa.in_proj_weight, sa.in_proj_bias
    q = (xq @ w[:d].t() + bias[:d]).view(b, tq, h, hd).transpose(1, 2) / (hd ** 0.5)
    k = (xkv @ w[d:2 * d].t() + bias[d:2 * d]).view(b, tk, h, hd).transpose(1, 2)
    v = (xkv @ w[2 * d:].t() + bias[2 * d:]).view(b, tk, h, hd).transpose(1, 2)
    s = q @ k.transpose(-1, -2)
    if add is not None:
        s = s + add[:, None, :, :]
    a = torch.softmax(s, dim=-1) @ v
    return sa.out_proj(a.transpose(1, 2).reshape(b, tq, d))


def decoder_layer(layer, x, memory):
    """nn.TransformerDecoderLayer, norm_first, relu, written out (eval mode would use a fused kernel ONNX lacks)."""
    y = layer.norm1(x)
    x = x + mha(layer.self_attn, y, y)
    x = x + mha(layer.multihead_attn, layer.norm2(x), memory)
    return x + layer.linear2(torch.relu(layer.linear1(layer.norm3(x))))


class Head(nn.Module):
    def __init__(self, m):
        super().__init__()
        self.inter = m.vision_language_interaction
        self.head = m.action_head

    def forward(self, vis, text, key_add, self_add, state):
        v, l = vis, text
        for fusion, tl in zip(self.inter.fusion_layers, self.inter.text_layers):
            vn, ln = fusion.layer_norm_v(v), fusion.layer_norm_l(l)
            dv, dl = bi_attention(fusion.attn, vn, ln, key_add)
            v, l = vn + fusion.gamma_v * dv, ln + fusion.gamma_l * dl  # residual_style "normalized"
            l = text_layer(tl, l, self_add)
        memory = torch.cat([v, l, self.head.state_projection(state)], 1)
        dec = self.head.decoder
        x = dec.action_queries.weight.unsqueeze(0)
        for layer in dec.decoder.layers:
            x = decoder_layer(layer, x, memory)
        return torch.tanh(dec.action_projection(x))


def check(name, got, want):
    err = float(np.abs(got - want).max())
    print(f"  {name}: max abs error {err:.2e} (largest {float(np.abs(want).max()):.3g})")
    return err


def export(module, args, names, outs, path):
    torch.onnx.export(module, args, str(path), input_names=names, output_names=outs, opset_version=20,
                      dynamo=False, do_constant_folding=True)
    import onnx
    import onnxsim
    g, ok = onnxsim.simplify(onnx.load(str(path)))  # fold the shape logic and constants: a static graph for QNN
    assert ok, path
    onnx.save(g, str(path))
    ops = sorted({n.op_type for n in g.graph.node})
    print(f"{path.name}: {len(g.graph.node)} nodes; ops {' '.join(ops)}")


def ort_run(path, feeds):
    import onnxruntime as ort
    s = ort.InferenceSession(str(path), providers=["CPUExecutionProvider"])
    return s.run(None, feeds)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "in").mkdir(exist_ok=True)
    ref = R.B / "ref"
    meta = json.loads((ref / "meta.json").read_text())
    rd = lambda n, dt=np.float32: np.fromfile(ref / n, dt).reshape(meta["tensors"][n.rsplit(".", 1)[0]])
    m = build()

    pix = rd("pixels.f32")[None]  # [1, 2, 3, 256, 256]
    ids, pos = rd("text_ids.i32", np.int32)[None], rd("text_pos.i32", np.int32)[None]
    mask, keypad = rd("text_mask.i32", np.int32), rd("text_keypad.i32", np.int32)
    group = meta["text_group"]
    add_mask = np.where(mask[None] != 0, 0.0, NEG).astype(np.float32)  # [1, 21, 21]
    keep = np.zeros((1, 21, 1), np.float32)
    keep[0, :group] = 1
    key_add = np.where(keypad[None, None] != 0, NEG, 0.0).astype(np.float32)  # [1, 1, 21]
    state = rd("state.f32")[None]

    with torch.no_grad():
        print("PyTorch modules against reference.py:")
        vis = Vision(m)(torch.from_numpy(pix))
        check("vision tokens", vis[0].numpy(), rd("vision_tokens.f32"))
        text = Text(m)(*(torch.from_numpy(a) for a in (ids, pos, add_mask, keep)))
        check("text tokens", text[0].numpy(), rd("text_tokens.f32"))
        act = Head(m)(vis, text, torch.from_numpy(key_add), torch.from_numpy(add_mask), torch.from_numpy(state))
        check("actions", act[0].numpy(), rd("actions.f32"))

        export(Vision(m), (torch.from_numpy(pix),), ["pixels"], ["vision"], OUT / "vision.onnx")
        export(Text(m), tuple(torch.from_numpy(a) for a in (ids, pos, add_mask, keep)),
               ["ids", "pos", "mask", "keep"], ["text"], OUT / "text.onnx")
        export(Head(m), (vis, text, torch.from_numpy(key_add), torch.from_numpy(add_mask), torch.from_numpy(state)),
               ["vision", "text", "key_mask", "self_mask", "state"], ["actions"], OUT / "head.onnx")

    print("ONNX Runtime on the Mac's CPU against reference.py:")
    v = ort_run(OUT / "vision.onnx", {"pixels": pix})[0]
    check("vision.onnx", v[0], rd("vision_tokens.f32"))
    t = ort_run(OUT / "text.onnx", {"ids": ids, "pos": pos, "mask": add_mask, "keep": keep})[0]
    check("text.onnx", t[0], rd("text_tokens.f32"))
    a = ort_run(OUT / "head.onnx", {"vision": v, "text": t, "key_mask": key_add, "self_mask": add_mask,
                                    "state": state})[0]
    check("head.onnx", a[0], rd("actions.f32"))

    for name, arr in (("pixels", pix), ("ids", ids), ("pos", pos), ("mask", add_mask), ("keep", keep),
                      ("key_mask", key_add), ("state", state)):
        arr.tofile(OUT / "in" / (name + (".i32" if arr.dtype == np.int32 else ".f32")))
    print("inputs in", OUT / "in")


if __name__ == "__main__":
    main()
