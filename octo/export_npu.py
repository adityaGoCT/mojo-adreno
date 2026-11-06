"""Octo-Small 1.5 as static ONNX graphs for the Hexagon NPU (ONNX Runtime's QNN execution provider), written to
build/octo/npu from octo_small.safetensors (octo/reference.py --export), each checked on the Mac's CPU against Octo's
own JAX tensors (build/octo/ref):

  t5.onnx     input_ids [1, 16] int32, an additive key mask [1, 16] -> the 16 task tokens [1, 16, 384]: T5-base's
              encoder, the projection and the task position embedding (once per instruction)
  obs.onnx    primary [2, 256, 256, 6], wrist [2, 128, 128, 6] (normalized, frame and goal channels, NHWC) ->
              primary tokens [2, 256, 384], wrist tokens [2, 64, 384]: both SmallStem16s, the embeddings, the
              projections and the position embeddings
  trunk.onnx  task tokens, primary and wrist tokens, an additive mask [690, 690] -> the last frame's readout [1, 384]:
              the 690 rows, 12 blocks, the final LayerNorm
  head.onnx   readout [1, 384], initial noise [1, 28], z [20, 28] (row t: time t) -> actions [1, 28] (normalized): the
              20 DDPM steps unrolled, the time conditioning a constant
  obs_trunk.onnx  obs and trunk as one graph (GPU+NPU: pixels in, readout out)

The graphs compute in fp32 (the HTP runs them in fp16). T5 is written fp16-safe: its residual stream is kept divided by
C (RMSNorm's eps divided by C^2, which leaves its output unchanged). Masks are additive floats (0 or -30000).

  build/turbovla/venv/bin/python octo/export_npu.py
"""

import json
import pathlib

import numpy as np
import torch
from safetensors.numpy import load_file
from torch import nn
from torch.nn import functional as F

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/octo"
OUT = B / "npu"
NEG = -30000.0
OT = "octo_transformer."
TB = OT + "BlockTransformer_0.Transformer_0."
T5 = OT + "task_tokenizers_language.hf_model."
RN = "heads_action.diffusion_model.reverse_network."
DM = "heads_action.diffusion_model."
NT, NPR, NWR, PER, N, D = 16, 256, 64, 337, 690, 384
CG = 256.0  # the stems' GroupNorm input scale on the HTP: the squares of conv outputs up to 446 overflow fp16
C5 = 256.0  # T5's residual scale on the HTP: its hidden state reaches 29,673, whose square overflows fp16


class Weights:
    def __init__(self, path):
        self.st = load_file(str(path))

    def __call__(self, name):
        return torch.from_numpy(self.st[name].copy())


def gelu_tanh(x):
    return 0.5 * x * (1.0 + torch.tanh(0.7978845608028654 * (x + 0.044715 * x * x * x)))


def swish(x):
    return x * torch.sigmoid(x)


def layer_norm(x, g, b, eps=1e-6):
    return F.layer_norm(x, (x.shape[-1],), g, b, eps)


class T5Enc(nn.Module):
    """T5-base's encoder over 16 tokens, the residual stream divided by C5 (fp16-safe), then Octo's projection and
    task position embedding."""

    def __init__(self, w):
        super().__init__()
        self.emb = nn.Parameter(w(T5 + "shared.embedding") / C5, requires_grad=False)
        self.bias = nn.Parameter(w("t5.position_bias"), requires_grad=False)  # [12, 16, 16]
        self.layers = []
        for l in range(12):
            p = T5 + f"encoder.block.{l}.layer."
            a = p + "0.SelfAttention."
            self.layers.append({k: w(v) for k, v in dict(
                n1=p + "0.layer_norm.weight", q=a + "q.kernel", k=a + "k.kernel", v=a + "v.kernel", o=a + "o.kernel",
                n2=p + "1.layer_norm.weight", wi=p + "1.DenseReluDense.wi.kernel",
                wo=p + "1.DenseReluDense.wo.kernel").items()})
        self.final = w(T5 + "encoder.final_layer_norm.weight")
        self.proj, self.proj_b = w(OT + "task_language_projection.kernel"), w(OT + "task_language_projection.bias")
        self.pos = w(OT + "task_language_pos_embedding")[0]

    def rms(self, x, g):
        return g * (x * torch.rsqrt((x * x).mean(-1, keepdim=True) + 1e-6 / C5 / C5))

    def forward(self, ids, key_add):  # [1, 16] int32, [1, 16] -> [1, 16, 384]
        x = self.emb[ids[0].long()]
        for p in self.layers:
            y = self.rms(x, p["n1"])
            q = (y @ p["q"].T).view(16, 12, 64).transpose(0, 1)
            k = (y @ p["k"].T).view(16, 12, 64).transpose(0, 1)
            v = (y @ p["v"].T).view(16, 12, 64).transpose(0, 1)
            s = q @ k.transpose(-1, -2) + self.bias + key_add[0][None, None, :]
            o = (torch.softmax(s, -1) @ v).transpose(0, 1).reshape(16, 768)
            x = x + o @ (p["o"].T / C5)
            y = self.rms(x, p["n2"])
            x = x + torch.relu(y @ p["wi"].T) @ (p["wo"].T / C5)
        x = self.rms(x, self.final)
        return (x @ self.proj.T + self.proj_b + self.pos)[None]


class Stem(nn.Module):
    """One camera's SmallStem16 on both frames, the embedding, the projection and the position embeddings."""

    def __init__(self, w, cam, n):
        super().__init__()
        p = OT + f"observation_tokenizers_{cam}.SmallStem16_0."
        self.convs = [(w(p + f"StdConv_{i}.kernel").permute(0, 3, 1, 2).contiguous(), w(p + f"StdConv_{i}.bias"),
                       w(p + f"GroupNorm_{i}.scale"), w(p + f"GroupNorm_{i}.bias")) for i in range(4)]
        self.emb, self.emb_b = w(p + "embedding.kernel"), w(p + "embedding.bias")
        self.proj, self.proj_b = w(OT + f"obs_{cam}_projection.kernel"), w(OT + f"obs_{cam}_projection.bias")
        self.pos = w(OT + f"obs_{cam}_pos_embedding")[0, :2]  # [2, n, 384]
        self.n = n

    def forward(self, x):  # [2, H, W, 6] -> [2, n, 384]
        x = x.permute(0, 3, 1, 2)
        for k, b, g, gb in self.convs:
            # fp16-safe GroupNorm, the same function: the convolution's output (up to 446) divided by CG (in its
            # weights; eps divided by CG^2), and each mean taken in two stages of at most 192 values
            x = F.conv2d(x, k / CG, b / CG, stride=2, padding=1)
            nb, c, h, ww = x.shape
            y = x.reshape(nb, 32, (c // 32) * h, ww)
            mean = y.mean(-1, keepdim=True).mean(-2, keepdim=True)
            d = y - mean
            var = (d * d).mean(-1, keepdim=True).mean(-2, keepdim=True)
            y = (d * torch.rsqrt(var + 1e-6 / CG / CG)).reshape(nb, c, h, ww)
            x = torch.relu(y * g[None, :, None, None] + gb[None, :, None, None])
        x = x.permute(0, 2, 3, 1).reshape(2, self.n, 384)
        x = x @ self.emb.T + self.emb_b
        return x @ self.proj.T + self.proj_b + self.pos


class Obs(nn.Module):
    def __init__(self, w):
        super().__init__()
        self.p, self.wr = Stem(w, "primary", NPR), Stem(w, "wrist", NWR)

    def forward(self, prim, wrist):
        return self.p(prim), self.wr(wrist)


class Trunk(nn.Module):
    """The 690 rows (task; per frame primary, wrist, task, readout), 12 pre-LN blocks under the additive mask, the
    final LayerNorm: the last frame's readout."""

    def __init__(self, w):
        super().__init__()
        self.readout = w(OT + "readout_action_pos_embedding")[0, :2, 0]  # [2, 384]
        self.blocks = []
        for i in range(12):
            p = TB + f"encoderblock_{i}."
            a = p + "MultiHeadDotProductAttention_0."
            self.blocks.append({k: w(v) for k, v in dict(
                g1=p + "LayerNorm_0.scale", b1=p + "LayerNorm_0.bias", q=a + "query.kernel", qb=a + "query.bias",
                k=a + "key.kernel", kb=a + "key.bias", v=a + "value.kernel", vb=a + "value.bias", o=a + "out.kernel",
                ob=a + "out.bias", g2=p + "LayerNorm_1.scale", b2=p + "LayerNorm_1.bias",
                w1=p + "MlpBlock_0.Dense_0.kernel", c1=p + "MlpBlock_0.Dense_0.bias",
                w2=p + "MlpBlock_0.Dense_1.kernel", c2=p + "MlpBlock_0.Dense_1.bias").items()})
        self.gf, self.bf = w(TB + "encoder_norm.scale"), w(TB + "encoder_norm.bias")

    def rows(self, task, prim, wrist):
        parts = [task[0]]
        for t in range(2):
            parts += [prim[t], wrist[t], task[0], self.readout[t:t + 1]]
        return torch.cat(parts, 0)  # [690, 384]

    def forward(self, task, prim, wrist, mask_add):
        x = self.rows(task, prim, wrist)
        for p in self.blocks:
            y = layer_norm(x, p["g1"], p["b1"])
            q = ((y @ p["q"].T + p["qb"]) * 0.125).view(N, 6, 64).transpose(0, 1)
            k = (y @ p["k"].T + p["kb"]).view(N, 6, 64).transpose(0, 1)
            v = (y @ p["v"].T + p["vb"]).view(N, 6, 64).transpose(0, 1)
            o = torch.softmax(q @ k.transpose(-1, -2) + mask_add, -1) @ v
            x = x + o.transpose(0, 1).reshape(N, D) @ p["o"].T + p["ob"]
            y = layer_norm(x, p["g2"], p["b2"])
            x = x + gelu_tanh(y @ p["w1"].T + p["c1"]) @ p["w2"].T + p["c2"]
        return layer_norm(x[N - 1:N], self.gf, self.bf)  # [1, 384]


class ObsTrunk(nn.Module):
    def __init__(self, w):
        super().__init__()
        self.obs, self.trunk = Obs(w), Trunk(w)

    def forward(self, task, prim, wrist, mask_add):
        p, wr = self.obs(prim, wrist)
        return self.trunk(task, p, wr, mask_add)


class Head(nn.Module):
    """The 20 DDPM steps, unrolled; the time conditioning and the step constants are constants."""

    def __init__(self, w, sched):
        super().__init__()
        wf = w(DM + "time_preprocess.kernel")[:, 0]  # [16]
        t = torch.arange(20, dtype=torch.float32)[:, None]
        f = (2 * np.pi * t).float() * wf[None]
        ff = torch.cat([torch.cos(f), torch.sin(f)], -1)
        h = swish(ff @ w(DM + "cond_encoder.Dense_0.kernel").T + w(DM + "cond_encoder.Dense_0.bias"))
        self.cond = h @ w(DM + "cond_encoder.Dense_1.kernel").T + w(DM + "cond_encoder.Dense_1.bias")  # [20, 32]
        self.w0, self.b0 = w(RN + "Dense_0.kernel"), w(RN + "Dense_0.bias")
        self.blocks = [tuple(w(RN + f"MLPResNetBlock_{b}." + n) for n in (
            "LayerNorm_0.scale", "LayerNorm_0.bias", "Dense_0.kernel", "Dense_0.bias", "Dense_1.kernel",
            "Dense_1.bias")) for b in range(3)]
        self.w1, self.b1 = w(RN + "Dense_1.kernel"), w(RN + "Dense_1.bias")
        self.sched = sched  # per time: c1, c2, sigma (fp32)

    def forward(self, emb, noise, z):  # [1, 384], [1, 28], [20, 28] -> [1, 28]
        x = noise
        for t in range(19, -1, -1):
            h = torch.cat([self.cond[t:t + 1], emb, x], -1) @ self.w0.T + self.b0
            for g, gb, wu, bu, wd, bd in self.blocks:
                h = h + (swish(layer_norm(h, g, gb) @ wu.T + bu) @ wd.T + bd)  # the bias, not h, joins the matmul
            eps = swish(h) @ self.w1.T + self.b1
            c1, c2, sg = self.sched[t]
            x = torch.clamp(c1 * (x - c2 * eps) + sg * z[t:t + 1], -5.0, 5.0)
        return x


def export(module, args, names, outs, path):
    torch.onnx.export(module, args, str(path), input_names=names, output_names=outs, opset_version=20,
                      dynamo=False, do_constant_folding=True)
    import onnx
    import onnxsim
    g, ok = onnxsim.simplify(onnx.load(str(path)))
    assert ok, path
    onnx.save(g, str(path))
    ops = sorted({n.op_type for n in g.graph.node})
    print(f"{path.name}: {len(g.graph.node)} nodes; ops {' '.join(ops)}")


def ort_run(path, feeds):
    import onnxruntime as ort
    s = ort.InferenceSession(str(path), providers=["CPUExecutionProvider"])
    return s.run(None, feeds)


def check(name, got, want):
    got, want = np.asarray(got, np.float32).ravel(), np.asarray(want, np.float32).ravel()
    print(f"  {name}: max abs error {np.abs(got - want).max():.3g} (largest reference value {np.abs(want).max():.3g})")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "in").mkdir(exist_ok=True)
    ref = B / "ref"
    rd = lambda n, dt=np.float32: np.fromfile(ref / n, dt)
    w = Weights(B / "octo_small.safetensors")

    prim = rd("image_primary.u8", np.uint8).reshape(2, 256, 256, 3).astype(np.float32) / np.float32(127.5) - 1
    wrist = rd("image_wrist.u8", np.uint8).reshape(2, 128, 128, 3).astype(np.float32) / np.float32(127.5) - 1
    prim = np.concatenate([prim, np.full_like(prim, -1.0)], -1)  # the frame, then the zero goal image
    wrist = np.concatenate([wrist, np.full_like(wrist, -1.0)], -1)
    ids = rd("input_ids.i32", np.int32).reshape(1, 16)
    key_add = np.where(rd("attention_mask.i32", np.int32).reshape(1, 16) != 0, 0.0, NEG).astype(np.float32)
    mask = rd("attn_mask.u8", np.uint8).reshape(N, N)
    mask_add = np.where(mask != 0, 0.0, NEG).astype(np.float32)
    noise = rd("diff_noise.f32").reshape(-1, 2, 28)[0, 1:2]  # the last frame's [1, 28]
    zs = rd("diff_z.f32").reshape(20, 2, 28)[:, 1]  # scan step s is time 19 - s
    z = zs[::-1].copy()  # row t: time t
    betas, alphas, ahats = rd("sched_betas.f32"), rd("sched_alphas.f32"), rd("sched_alpha_hats.f32")
    sched = []
    for t in range(20):
        c1 = np.float32(1) / np.sqrt(alphas[t])
        c2 = (np.float32(1) - alphas[t]) / np.sqrt(np.float32(1) - ahats[t])
        sched.append((float(c1), float(c2), float(np.sqrt(betas[t])) if t > 0 else 0.0))

    t5, obs, trunk, head = T5Enc(w), Obs(w), Trunk(w), Head(w, sched)
    with torch.no_grad():
        print("PyTorch modules against Octo's JAX tensors:")
        lang = t5(torch.from_numpy(ids), torch.from_numpy(key_add))
        check("task tokens (trunk input rows 0 .. 15)", lang[0], rd("trunk_input.f32").reshape(N, D)[:NT])
        p, wr = obs(torch.from_numpy(prim), torch.from_numpy(wrist))
        ti = rd("trunk_input.f32").reshape(N, D)
        check("primary tokens, frame 0", p[0], ti[NT:NT + NPR])
        check("wrist tokens, frame 1", wr[1], ti[NT + PER + NPR:NT + PER + NPR + NWR])
        r = trunk(lang, p, wr, torch.from_numpy(mask_add))
        check("readout (last frame)", r, rd("readout.f32").reshape(2, D)[1])
        a = head(r, torch.from_numpy(noise), torch.from_numpy(z))
        check("actions (normalized)", a, rd("actions_norm.f32"))

    export(t5, (torch.from_numpy(ids), torch.from_numpy(key_add)), ["ids", "key_mask"], ["task"], OUT / "t5.onnx")
    export(obs, (torch.from_numpy(prim), torch.from_numpy(wrist)), ["primary", "wrist"], ["primary_tokens",
                                                                                          "wrist_tokens"],
           OUT / "obs.onnx")
    export(trunk, (lang, p, wr, torch.from_numpy(mask_add)), ["task", "primary_tokens", "wrist_tokens", "mask"],
           ["readout"], OUT / "trunk.onnx")
    export(head, (r, torch.from_numpy(noise), torch.from_numpy(z)), ["readout", "noise", "z"], ["actions"],
           OUT / "head.onnx")
    export(ObsTrunk(w), (lang, torch.from_numpy(prim), torch.from_numpy(wrist), torch.from_numpy(mask_add)),
           ["task", "primary", "wrist", "mask"], ["readout"], OUT / "obs_trunk.onnx")
    print("ONNX Runtime (CPU, fp32) on the graphs:")
    lt = ort_run(OUT / "t5.onnx", {"ids": ids, "key_mask": key_add})[0]
    check("t5.onnx: task tokens", lt[0], ti[:NT])
    po, wo = ort_run(OUT / "obs.onnx", {"primary": prim, "wrist": wrist})
    check("obs.onnx: primary tokens, frame 1", po[1], ti[NT + PER:NT + PER + NPR])
    ro = ort_run(OUT / "trunk.onnx", {"task": lt, "primary_tokens": po, "wrist_tokens": wo, "mask": mask_add})[0]
    check("trunk.onnx: readout", ro, rd("readout.f32").reshape(2, D)[1])
    ao = ort_run(OUT / "head.onnx", {"readout": ro, "noise": noise, "z": z})[0]
    check("head.onnx: actions", ao, rd("actions_norm.f32"))
    ref_task = ti[None, :NT]  # JAX's tokens, to check the trunk on its own
    ref_prim = np.stack([ti[NT + t * PER:NT + t * PER + NPR] for t in range(2)])
    ref_wrist = np.stack([ti[NT + t * PER + NPR:NT + t * PER + NPR + NWR] for t in range(2)])
    for name, arr in (("ids", ids), ("key_mask", key_add), ("primary", prim), ("wrist", wrist), ("mask", mask_add),
                      ("noise", noise), ("z", z), ("ref_task", ref_task), ("ref_primary_tokens", ref_prim),
                      ("ref_wrist_tokens", ref_wrist)):
        arr.tofile(OUT / "in" / (name + (".i32" if arr.dtype == np.int32 else ".f32")))
    print("inputs in", OUT / "in")


if __name__ == "__main__":
    main()
