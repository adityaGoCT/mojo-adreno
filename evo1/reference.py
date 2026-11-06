"""Evo-1 (MINT-SJTU/Evo1_LIBERO) in fp32 on the Mac's CPU: the reference the GPU/NPU ports are checked against.
It runs the OFFICIAL model code (MINT-SJTU/Evo-1 on main at a pinned commit, cloned to build/evo1/src): the main
branch server's infer_from_json_dict -> EVO1.run_inference -> InternVL3Embedder (InternViT-300M + mlp1 + the first 14
layers of Qwen2.5-0.5B) and FlowmatchingActionHead.get_action, on one LIBERO observation, and writes every stage's
tensors to build/evo1/ref as raw little-endian .f32 / .i32 / .u8 files plus meta.json:

  build/evo1/venv/bin/python evo1/reference.py            # writes build/evo1/ref (fp32, plus eager and bf16 repeats)
  build/evo1/venv/bin/python evo1/reference.py --export   # also build/evo1/evo1.safetensors + export_names.txt
  build/evo1/venv/bin/python evo1/reference.py --no-bf16  # skips the bf16 repeat

About 1.5 minutes on an M4 (fp32 chunk 7 s with every tap on, the eager rerun 4 s, the bf16 repeat 66 s: CPU bf16
matmuls are slow); peak footprint 5.7 GB (7.3 GB RSS counting the mmap'd checkpoint).

Setup (once): the venv is Python 3.10 with evo1/requirements-reference.txt (CPU torch 2.5.1, transformers 4.39.0,
no flash-attn, no deepspeed). The script itself clones the code and downloads what it needs at the pinned revisions
if it is missing: MINT-SJTU/Evo1_LIBERO (config.json, norm_stats.json, the DeepSpeed mp_rank_00_model_states.pt,
sha256-checked) into build/evo1/hf/Evo1_LIBERO, and from OpenGVLab/InternVL3-1B only the config, the remote code and the
tokenizer into build/evo1/hf/InternVL3-1B. InternVL3-1B's 1.9 GB model.safetensors is NOT downloaded: the code only
builds the architecture from it (AutoModel.from_pretrained) and then load_state_dict(strict=True) replaces every
parameter and buffer with the Evo-1 checkpoint's. A 0-tensor model.safetensors placeholder stands in for it;
from_pretrained(low_cpu_mem_usage=True) then allocates the parameters uninitialized, and the strict load fills all of
them (checked below: every state_dict entry equals the checkpoint's). The non-persistent buffers (Qwen2 RoPE inv_freq
and cos/sin caches) are computed from the config either way. HF_MODULES_CACHE points into build/evo1/hf/modules.

Code branch and sampler: main @ 2020853, the branch the LIBERO checkpoint was trained with. Its config.json holds every
key of main's train.py argparse and none of the 15 evo1-flash adds (cache_dir, vision_masked, video_backend,
finetune_vision_model, ...; the two extras are action_dim, which EVO1 writes into the config, and use_vggt, in neither
branch), and its DeepSpeed metadata says ds_version 0.17.1, step 80000, bf16 ZeRO-2. So the sampler is main's:
num_inference_timesteps = 32 (main scripts/Evo1_server.py L69; the checkpoint config has no such key), Euler
x <- x + (1/32) v with t = i/32, and time-embedding row int(t * 1000) = 0, 31, 62, ..., 968 of the checkpoint's own
(bf16-rounded) time_pos_enc.pe buffer. The initial noise is uniform: torch.rand(1, 1200) * 2 - 1 after
torch.manual_seed(0); it is the only RNG draw on the path (checked), recorded so a port can inject it. As in the code,
the noise and x keep their values in the 17 padded action dims (only the action encoder's input is multiplied by the
action mask), so x[..., 7:] is not zero; only [..., :7] is meaningful.

Inputs (no simulator): the LIBERO-spatial sample observation VLA-Adapter ships
(OpenHelix-Team/VLA-Adapter @ 23fa0c9 experiments/robot/libero/sample_libero_spatial_observation.pkl, copied from
build/vla_adapter/src if it is there, else fetched from the raw URL; sha256-checked; read with an unpickler that only
admits numpy's array rebuild). full_image and wrist_image are 224x224x3 uint8 RGB as robosuite renders them, already
rotated 180 degrees exactly like Evo-1's LIBERO client does ([::-1, ::-1]); state is the same 8-D eef_pos + axis-angle
+ gripper_qpos the client builds; the prompt is the task string. The request is the dict
LIBERO_evaluation/libero_client_4tasks.py:obs_to_json_dict builds: images [agentview, wrist, zeros(448,448,3)],
image_mask [1,1,0], action_mask [1]*7 + [0]*17, sent through a JSON round trip. It then goes through the server's own
code unmodified: decode_image_from_list = cv2.resize(.., (448, 448)) (INTER_LINEAR, here a 224 -> 448 upsample; the
real client renders at 448 so it is a no-op there), then cv2.cvtColor(BGR2RGB), ToTensor. The client sends RGB, so
this swap REVERSES the channels: the ViT's channel 0 (normalized with mean 0.485 / std 0.229) carries the scene's
blue, channel 2 its red (checked bit-exactly: images_448[k] == cv2.resize(view_k)[..., ::-1]). That is what the LIBERO
evaluation fed the model (training decoded video frames as RGB: the notes' open question 2). The embedder then goes
tensor -> to_pil_image -> (resize and tile: identities at 448 with max_num=1) -> ToTensor -> ImageNet Normalize; the
u8 -> /255 -> *255 -> u8 round trip is exact for all 256 values. The state goes JSON -> fp32 -> zero-pad to 24 ->
clamp(2(x-min)/(max-min+1e-8)-1, -1, 1) with norm_stats.json's libero_robot stats zero-padded to 24, so the 16 padded
state dims normalize to -1, not 0.

Runtime patches (nothing in build/evo1/src or the InternVL remote code is edited):
  1. device: config["device"] = "cpu" (EVO1 and the embedder take it from the config), and a TorchFunctionMode that
     rewrites device="cuda" / .to("cuda") to cpu in the server's decode_image_from_list and infer_from_json_dict,
     which hard-code it. The server's torch.amp.autocast("cuda", bfloat16) disables itself on a CUDA-less torch (it
     warns), so the fp32 run has no autocast at all.
  2. dtype: inside model/internvl3/internvl3_embedder.py only, the name `torch` is a proxy whose .bfloat16 is
     torch.float32. That flips its two bf16 sites, from_pretrained(torch_dtype=...) and the pixel_values cast, to fp32
     (so the RoPE cos/sin caches are built in fp32, not bf16-rounded). The action head is fp32 already (created in the
     default dtype, filled with the checkpoint's bf16 values).
  3. FlashAttention-2 semantics: without flash_attn the InternVL code picks attn_implementation 'eager' for Qwen2.
     transformers 4.39's FA2 path unpads the masked tokens and pad_input writes ZEROS as their attention output; eager
     lets those query rows attend to earlier valid tokens. The emulation is a forward pre-hook on every Qwen2 layer's
     o_proj (bias-free) that multiplies its input rows by the 2-D attention mask the embedder passes the LLM, i.e.
     o_proj(0) = 0 at masked rows exactly as after pad_input. Nothing else differs: in both paths valid tokens see only
     valid keys with a causal mask (FA2 varlen over the packed valid tokens = eager's causal + key mask), and the RoPE
     positions are 0..1023 for every token (Qwen2Model's default arange; FA2 never compacts them). The ViT has no mask,
     so its eager attention is FA's math. The script also reruns the whole chunk with plain eager to measure the
     difference (eager_* files and checks).
  4. Loading: torch.load(..., weights_only=True) with builtins.set allowlisted (the DeepSpeed pickle holds only
     tensors, OrderedDict, torch.Size and an empty set), instead of the server's weights_only=False default; same
     tensors. The server's load_model_and_normalizer is reproduced line for line (config overrides finetune_* = False
     and num_inference_timesteps = 32, EVO1(config).eval(), strict load), with vlm_name pointed at the local snapshot.
Nothing else needs CUDA. Recording uses forward hooks and wrappers that only copy tensors; the eager rerun checks that
the FA2-emulated run's valid rows are bit-identical to eager's, i.e. the hooks did not perturb anything else.

The bf16 repeat ("as released"): a second model built without patch 2 (bf16 VLM weights, bf16 pixel_values,
bf16-built RoPE caches; head params fp32 holding bf16 values), with the FA2 emulation, run under
torch.autocast("cpu", bfloat16) as the stand-in for the server's CUDA autocast, same seed and noise. CPU and CUDA
autocast keep different ops in fp32 and the real FA2 kernel accumulates differently, so this measures the size of the
bf16 effect, not the CUDA output bit for bit.

--export writes build/evo1/evo1.safetensors: ckpt["module"] (the DeepSpeed wrapper dict stripped; the keys are the EVO1
module's own state_dict names, embedder.model.{vision_model,mlp1,language_model.model}.* and action_head.*), as stored
(all bf16 in this checkpoint, including the two sinusoid buffers), PyTorch (out, in) layouts. A tensor is exported
when the official path passes it to a torch op (tracked by the TorchFunctionMode in the plain eager run; module hooks
would miss nn.MultiheadAttention's out_proj, which F.multi_head_attention_forward reads directly); the rest would be
listed as skipped. None are: all 632 are read (lm_head is Identity and not in the checkpoint, the 10 dropped LLM
layers were never saved).
"""

import argparse
import collections
import contextlib
import gc
import hashlib
import io
import json
import os
import pathlib
import pickle
import shutil
import subprocess
import sys
import time
import types
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/evo1"
SRC = B / "src"
HF = B / "hf"
CKPT = HF / "Evo1_LIBERO"
VLM = HF / "InternVL3-1B"
REV_GH = "202085382605e47822455c6f12bc88da1b531832"  # MINT-SJTU/Evo-1 main
REV_HF = "3ddc6c9cafc57d5e678d0c7c2129060066feaaf3"  # MINT-SJTU/Evo1_LIBERO
REV_VLM = "4415a3b810e636d11dfa86b0e9ba40bb00535aa8"  # OpenGVLab/InternVL3-1B
REV_VA = "23fa0c9c159e2aa04341cdd3e924f44061311060"  # OpenHelix-Team/VLA-Adapter
CKPT_SHA256 = "1bc3abd53046648ef72970f338753fadf5acf3f444117a7e3b36e1ff93f71ef0"
SAMPLE_SHA256 = "326db6c78dd0a9d91c11f05af03b93fa3095338ee3cb5a5eb15adf3d87eb0109"
SAMPLE_PATH = "experiments/robot/libero/sample_libero_spatial_observation.pkl"
SAMPLE = B / "inputs/sample_libero_spatial_observation.pkl"
VLM_FILES = ["config.json", "configuration_intern_vit.py", "configuration_internvl_chat.py", "conversation.py",
             "modeling_intern_vit.py", "modeling_internvl_chat.py", "generation_config.json", "preprocessor_config.json",
             "added_tokens.json", "special_tokens_map.json", "tokenizer_config.json", "vocab.json", "merges.txt",
             "tokenizer.json"]
SEED = 0
STEPS = 32  # main scripts/Evo1_server.py L69
IMG_CONTEXT = 151667

os.environ.setdefault("HF_MODULES_CACHE", str(HF / "modules"))
os.environ.setdefault("HF_HUB_CACHE", str(HF / "hub"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")  # every path below is local; nothing is resolved by hub id
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
sys.path.insert(0, str(SRC / "Evo_1"))

import numpy as np  # noqa: E402
import torch  # noqa: E402
from torch.overrides import TorchFunctionMode  # noqa: E402


# ---------------------------------------------------------------------------------------------------------- fetch
def _sha256(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 24), b""):
            h.update(chunk)
    return h.hexdigest()


def _get(url, dst, sha=None):
    if dst.exists():
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    tmp = dst.with_name(dst.name + ".part")
    print("downloading", url)
    urllib.request.urlretrieve(url, tmp)
    if sha is not None:
        assert _sha256(tmp) == sha, f"sha256 mismatch for {url}"
    tmp.rename(dst)


def fetch():
    """Clone Evo-1 at REV_GH, download the checkpoint and InternVL3-1B's config/code/tokenizer, write the weight
    placeholder, and get the sample observation, if any of it is missing."""
    if not (SRC / "Evo_1/scripts/Evo1.py").exists():
        subprocess.run(["git", "clone", "-q", "https://github.com/MINT-SJTU/Evo-1.git", str(SRC)], check=True)
        subprocess.run(["git", "-C", str(SRC), "checkout", "-q", REV_GH], check=True)
    head = subprocess.run(["git", "-C", str(SRC), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    assert head == REV_GH, f"build/evo1/src is at {head}, expected {REV_GH}"
    for f in ("config.json", "norm_stats.json", "checkpoint.json", "mp_rank_00_model_states.pt"):
        _get(f"https://huggingface.co/MINT-SJTU/Evo1_LIBERO/resolve/{REV_HF}/{f}", CKPT / f,
             CKPT_SHA256 if f.endswith(".pt") else None)
    for f in VLM_FILES:
        _get(f"https://huggingface.co/OpenGVLab/InternVL3-1B/resolve/{REV_VLM}/{f}", VLM / f)
    if not (VLM / "model.safetensors").exists():
        from safetensors.torch import save_file
        save_file({}, str(VLM / "model.safetensors"),
                  metadata={"format": "pt", "note": "0-tensor placeholder written by evo1/reference.py; every weight "
                                                    "comes from the Evo1_LIBERO checkpoint's strict load_state_dict"})
    if not SAMPLE.exists():
        SAMPLE.parent.mkdir(parents=True, exist_ok=True)
        local = ROOT / "build/vla_adapter/src" / SAMPLE_PATH
        if local.exists() and _sha256(local) == SAMPLE_SHA256:
            shutil.copyfile(local, SAMPLE)
        else:
            _get(f"https://raw.githubusercontent.com/OpenHelix-Team/VLA-Adapter/{REV_VA}/{SAMPLE_PATH}", SAMPLE)
    assert _sha256(SAMPLE) == SAMPLE_SHA256, "sample observation sha256 mismatch"


def load_sample():
    """The VLA-Adapter sample observation, unpickled with only numpy's array rebuild allowed."""
    allowed = {("numpy.core.numeric", "_frombuffer"), ("numpy", "dtype"), ("numpy.core.multiarray", "_reconstruct"),
               ("numpy", "ndarray")}

    class Restricted(pickle.Unpickler):
        def find_class(self, module, name):
            if (module, name) in allowed:
                return super().find_class(module, name)
            raise pickle.UnpicklingError(f"blocked global {module}.{name}")

    with open(SAMPLE, "rb") as f:
        return Restricted(f).load()


# ---------------------------------------------------------------------------------------------------------- patches
def _is_cuda(a):
    return (isinstance(a, str) and a.split(":")[0] == "cuda") or (isinstance(a, torch.device) and a.type == "cuda")


class CpuForCuda(TorchFunctionMode):
    """Patch 1: device='cuda' / .to('cuda') in any torch call becomes cpu. Also records every random draw and (track)
    the id of every tensor passed to a torch op, to tell which weights the inference path reads."""

    def __init__(self, track=False):
        super().__init__()
        self.rewrites = 0
        self.draws = []
        self.seen = set() if track else None

    def _note(self, x):
        if isinstance(x, torch.Tensor):
            self.seen.add(id(x))
        elif isinstance(x, (list, tuple)):
            for y in x:
                self._note(y)

    def __torch_function__(self, func, types_, args=(), kwargs=None):
        kwargs = dict(kwargs or {})
        if _is_cuda(kwargs.get("device")):
            kwargs["device"] = "cpu"
            self.rewrites += 1
        if getattr(func, "__name__", "") == "to" and any(_is_cuda(a) for a in args):
            args = tuple("cpu" if _is_cuda(a) else a for a in args)
            self.rewrites += 1
        if self.seen is not None:
            self._note(args)
            self._note(list(kwargs.values()))
        out = func(*args, **kwargs)
        name = getattr(func, "__name__", "")
        if name.startswith("rand") or name in ("normal", "normal_", "bernoulli", "multinomial", "uniform_"):
            self.draws.append((name, out.detach().clone() if isinstance(out, torch.Tensor) else None))
        return out


class _Bf16AsFp32(types.ModuleType):
    """Patch 2: stands in for `torch` inside internvl3_embedder.py only; there, torch.bfloat16 is torch.float32."""

    def __getattr__(self, name):
        return torch.float32 if name == "bfloat16" else getattr(torch, name)


def fa2_emulation(lm):
    """Patch 3: FA2's pad_input zeros at masked query rows = zero the masked rows of every o_proj's input."""
    state = {}

    def grab_mask(module, args, kwargs):
        state["mask"] = kwargs["attention_mask"]

    def zero_masked_rows(module, args):
        x = args[0]
        return (x * state["mask"][..., None].to(x.dtype),)

    hooks = [lm.register_forward_pre_hook(grab_mask, with_kwargs=True)]
    for layer in lm.model.layers:
        assert layer.self_attn.o_proj.bias is None
        hooks.append(layer.self_attn.o_proj.register_forward_pre_hook(zero_masked_rows))
    return hooks


# ---------------------------------------------------------------------------------------------------------- model
def load_checkpoint():
    torch.serialization.add_safe_globals([set])
    ck = torch.load(CKPT / "mp_rank_00_model_states.pt", map_location="cpu", weights_only=True, mmap=True)
    meta = {k: ck[k] for k in ("ds_version", "step", "global_steps", "dp_world_size")}
    return ck["module"], meta, ck.get("buffer_names")


def build_model(sd, fp32):
    """main scripts/Evo1_server.py load_model_and_normalizer, with device cpu, the local InternVL3-1B snapshot, and
    (fp32=True) patch 2."""
    import model.internvl3.internvl3_embedder as emb_mod
    from scripts.Evo1 import EVO1

    import transformers

    emb_mod.torch = _Bf16AsFp32("torch") if fp32 else torch
    # from_pretrained would list every weight as "newly initialized" (the placeholder holds none); expected, silenced
    transformers.logging.set_verbosity_error()
    config = json.loads((CKPT / "config.json").read_text())
    config["finetune_vlm"] = False
    config["finetune_action_head"] = False
    config["num_inference_timesteps"] = STEPS
    config["device"] = "cpu"  # patch 1 (the checkpoint's config.json says "cuda")
    config["vlm_name"] = str(VLM)  # OpenGVLab/InternVL3-1B @ REV_VLM, config/code/tokenizer + weight placeholder
    model = EVO1(config).eval()
    result = model.load_state_dict(sd, strict=True)
    model = model.to("cpu")
    return model, result


# ---------------------------------------------------------------------------------------------------------- run
def infer(model, normalizer, data, fa2=True, bf16=False, track=False):
    """One chunk through the server's infer_from_json_dict. Returns the server's output (denormalized actions, 50 x 24)
    and the normalized actions it denormalized, plus the device mode (random draws)."""
    from scripts.Evo1_server import infer_from_json_dict

    hooks = fa2_emulation(model.embedder.model.language_model) if fa2 else []
    rec = {}
    orig = normalizer.denormalize_action

    def denorm(a):
        rec["actions_norm"] = a.detach().float().clone()
        return orig(a)

    normalizer.denormalize_action = denorm
    mode = CpuForCuda(track)
    torch.manual_seed(SEED)
    amp = torch.autocast("cpu", dtype=torch.bfloat16) if bf16 else contextlib.nullcontext()
    log = io.StringIO()
    t0 = time.time()
    try:
        with mode, amp, contextlib.redirect_stdout(log):
            out = infer_from_json_dict(data, model, normalizer)
    finally:
        normalizer.denormalize_action = orig
        for h in hooks:
            h.remove()
    print(f"  infer_from_json_dict ({'FA2-emulated' if fa2 else 'plain eager'}, {'bf16' if bf16 else 'fp32'}) "
          f"{time.time() - t0:.1f} s; {mode.rewrites} cuda->cpu rewrites; draws {[d[0] for d in mode.draws]}")
    return np.asarray(out, np.float32), rec["actions_norm"], mode


class Taps:
    """Forward hooks that copy what the official modules see and produce, plus the numerics survey."""

    def __init__(self, model):
        self.s = collections.defaultdict(list)
        self.maxabs = {}
        self.ctx_diff = 0.0
        self.qk = {}
        self.head_logit = collections.defaultdict(float)
        self.vit_logit = {}
        self.h = []
        emb = model.embedder.model
        lm = emb.language_model
        head = model.action_head
        keep = self.keep
        H = self.h
        H.append(emb.vision_model.register_forward_pre_hook(
            lambda m, a, k: keep("pixel_values", k["pixel_values"]), with_kwargs=True))
        H.append(emb.vision_model.embeddings.register_forward_hook(lambda m, a, o: keep("vit_embeddings", o)))
        H.append(emb.vision_model.register_forward_hook(lambda m, a, o: keep("vit_out", o.last_hidden_state)))
        H.append(emb.mlp1.register_forward_hook(lambda m, a, o: keep("mlp1_out", o)))
        H.append(lm.get_input_embeddings().register_forward_pre_hook(lambda m, a: keep("input_ids", a[0])))
        def lm_pre(module, args, kwargs):  # must return None (a with_kwargs pre-hook's return replaces args/kwargs)
            keep("llm_input_embeds", kwargs["inputs_embeds"])
            keep("attention_mask", kwargs["attention_mask"])

        H.append(lm.register_forward_pre_hook(lm_pre, with_kwargs=True))
        for i, layer in enumerate(lm.model.layers):
            H.append(layer.register_forward_hook(lambda m, a, o, i=i: keep(f"llm_layer{i:02d}", o[0])))
            H.append(layer.self_attn.register_forward_pre_hook(
                lambda m, a, k, i=i: self.qk.setdefault(i, {}).update(pos=k["position_ids"].clone()), with_kwargs=True))
            H.append(layer.self_attn.q_proj.register_forward_hook(
                lambda m, a, o, i=i: self.qk.setdefault(i, {}).update(q=o.detach().float().clone())))
            H.append(layer.self_attn.k_proj.register_forward_hook(
                lambda m, a, o, i=i: self.qk.setdefault(i, {}).update(k=o.detach().float().clone())))
        H.append(lm.model.norm.register_forward_hook(lambda m, a, o: keep("llm_final_norm", o)))
        H.append(head.state_encoder.register_forward_pre_hook(lambda m, a: keep("state_norm", a[0])))
        H.append(head.state_encoder.register_forward_hook(lambda m, a, o: keep("state_token", o)))
        H.append(head.action_encoder.register_forward_pre_hook(lambda m, a: keep("head_in", a[0])))
        H.append(head.action_encoder.register_forward_hook(lambda m, a, o: keep("action_tokens", o)))
        H.append(head.transformer_blocks[0].register_forward_pre_hook(self.block0_pre))
        for i, blk in enumerate(head.transformer_blocks):
            H.append(blk.register_forward_hook(lambda m, a, o, i=i: keep(f"block{i}", o)))
            H.append(blk.attn.register_forward_pre_hook(lambda m, a, i=i: self.head_logits(i, m, a)))
        H.append(head.norm_out.register_forward_hook(lambda m, a, o: keep("norm_out", o)))
        H.append(head.seq_pool_proj.register_forward_hook(lambda m, a, o: keep("pooled", o)))
        H.append(head.mlp_head.register_forward_hook(lambda m, a, o: keep("velocity", o)))
        for i, layer in enumerate(emb.vision_model.encoder.layers):
            H.append(layer.attn.qkv.register_forward_hook(lambda m, a, o, i=i: self.vit_logits(i, o)))
        for name, mod in model.named_modules():
            if name:
                H.append(mod.register_forward_hook(lambda m, a, o, name=name: self.survey(name, m, a, o)))

    def keep(self, name, x):
        self.s[name].append(x.detach().float().clone())

    def block0_pre(self, module, args):
        ctx = args[1].detach().float()
        if "context" not in self.s:
            self.keep("context", ctx)
        else:
            self.ctx_diff = max(self.ctx_diff, float((ctx - self.s["context"][0]).abs().max()))
        self.keep("time_emb", args[2])

    def head_logits(self, i, mha, args):
        """nn.MultiheadAttention logits (q/sqrt(112)) k^T, 8 heads, 50 queries x 1025 keys; max over steps."""
        q_in, k_in = args[0].detach().float(), args[1].detach().float()
        d = mha.embed_dim
        w, b = mha.in_proj_weight.float(), mha.in_proj_bias.float()
        h = mha.num_heads
        q = (q_in @ w[:d].T + b[:d]).view(q_in.shape[1], h, d // h).transpose(0, 1) / (d // h) ** 0.5
        k = (k_in @ w[d:2 * d].T + b[d:2 * d]).view(k_in.shape[1], h, d // h).transpose(0, 1)
        self.head_logit[i] = max(self.head_logit[i], float((q @ k.transpose(1, 2)).abs().max()))

    def vit_logits(self, i, qkv):
        """InternViT logits (q/8) k^T, 16 heads, 1025 x 1025 per view; the max |.| and where (view, head, q, k)."""
        n, s, _ = qkv.shape
        qkv = qkv.detach().float().view(n, s, 3, 16, 64)
        for j in range(n):
            q, k = qkv[j, :, 0].transpose(0, 1) * 64 ** -0.5, qkv[j, :, 1].transpose(0, 1)
            lg = (q @ k.transpose(1, 2)).abs()
            m = float(lg.max())
            if m > self.vit_logit.get(i, (0.0,))[0]:
                hh, qq, kk = np.unravel_index(int(lg.argmax()), lg.shape)
                self.vit_logit[i] = (m, j, int(hh), int(qq), int(kk))

    def survey(self, name, module, args, out):
        if isinstance(out, torch.Tensor):
            t = out
        elif isinstance(out, (tuple, list)) and out and isinstance(out[0], torch.Tensor):
            t = out[0]
        elif hasattr(out, "last_hidden_state"):
            t = out.last_hidden_state
        else:
            t = None
        if t is not None and t.is_floating_point():
            self.maxabs[name] = max(self.maxabs.get(name, 0.0), float(t.detach().abs().max()))
        if isinstance(module, torch.nn.Linear) and args and isinstance(args[0], torch.Tensor):
            key = name + " (input)"
            self.maxabs[key] = max(self.maxabs.get(key, 0.0), float(args[0].detach().abs().max()))

    def remove(self):
        for h in self.h:
            h.remove()


def llm_logits(taps, lm, mask):
    """Qwen2 logits q k^T / 8 after RoPE (official rotary_emb + apply_rotary_pos_emb), GQA 14/2, over the entries FA2
    computes: valid query, valid key, key <= query. Also the max over eager's extra rows (masked query rows)."""
    from transformers.models.qwen2.modeling_qwen2 import apply_rotary_pos_emb

    valid = torch.from_numpy(mask.astype(bool))
    causal = torch.ones(1024, 1024, dtype=torch.bool).tril()
    fa2_ok = causal & valid[None, :] & valid[:, None]
    eager_ok = causal & valid[None, :]
    out = {}
    for i, layer in enumerate(lm.model.layers):
        d = taps.qk[i]
        q = d["q"].view(1, 1024, 14, 64).transpose(1, 2)
        k = d["k"].view(1, 1024, 2, 64).transpose(1, 2)
        cos, sin = layer.self_attn.rotary_emb(k, seq_len=1024)
        q, k = apply_rotary_pos_emb(q, k, cos.float(), sin.float(), d["pos"])
        k = k.repeat_interleave(7, dim=1)
        lg = ((q @ k.transpose(2, 3))[0] / 8.0).abs()
        hh, qq, kk = np.unravel_index(int(torch.where(fa2_ok, lg, -1.0).argmax()), lg.shape)
        out[i] = {"fa2": float(lg[:, fa2_ok].max()), "fa2_at_(head,q,k)": [int(hh), int(qq), int(kk)],
                  "eager_masked_rows": float(lg[:, eager_ok & ~fa2_ok].max())}
    return out


# ---------------------------------------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=pathlib.Path, default=B / "ref")
    ap.add_argument("--export", action="store_true", help="also write build/evo1/evo1.safetensors + export_names.txt")
    ap.add_argument("--no-bf16", action="store_true", help="skip the bf16 repeat")
    a = ap.parse_args()
    fetch()

    import cv2
    import model.internvl3.internvl3_embedder as emb_mod
    from scripts.Evo1_server import Normalizer

    obs = load_sample()
    full, wrist = obs["full_image"], obs["wrist_image"]
    state8 = np.asarray(obs["state"], np.float64)
    prompt = str(obs["task_description"])
    # libero_client_4tasks.py obs_to_json_dict, with the sample's (already 180-degree-rotated) views
    data = {"image": [full.astype(np.uint8).tolist(), wrist.astype(np.uint8).tolist(),
                      np.zeros((448, 448, 3), np.uint8).tolist()],
            "state": state8.tolist(), "prompt": prompt, "image_mask": [1, 1, 0], "action_mask": [1] * 7 + [0] * 17}
    data = json.loads(json.dumps(data))
    stats = json.loads((CKPT / "norm_stats.json").read_text())
    normalizer = Normalizer(stats)

    t0 = time.time()
    sd, ds_meta, buffer_names = load_checkpoint()
    model, load_result = build_model(sd, fp32=True)
    print(f"built EVO1 (fp32) in {time.time() - t0:.1f} s; strict load: {load_result}")
    msd = model.state_dict()
    assert set(msd) == set(sd)
    load_exact = all(torch.equal(msd[k], sd[k].to(msd[k].dtype)) for k in sd)
    n_params = sum(v.numel() for v in sd.values())
    dtypes = {k: str(v.dtype) for k, v in msd.items()}
    rope = model.embedder.model.language_model.model.layers[0].self_attn.rotary_emb
    assert rope.cos_cached.dtype == torch.float32
    print(f"checkpoint: {len(sd)} tensors, {n_params} elements, all equal after load: {load_exact}; "
          f"param dtypes {collections.Counter(dtypes.values())}")

    # ------------------------------------------------------------ reference run (fp32, FA2-emulated), every tap on
    pil_u8 = []
    orig_to_pil = emb_mod.to_pil_image

    def to_pil_rec(pic, mode=None):
        img = orig_to_pil(pic, mode)
        pil_u8.append(np.asarray(img).copy())
        return img

    taps = Taps(model)
    emb_mod.to_pil_image = to_pil_rec
    try:
        out_fa2, actn_fa2, mode = infer(model, normalizer, data, fa2=True)
    finally:
        emb_mod.to_pil_image = orig_to_pil
        taps.remove()
    S = {k: v for k, v in taps.s.items()}

    # ------------------------------------------------------------ plain eager rerun (no FA2 emulation)
    eager_final = []
    lm = model.embedder.model.language_model
    h = lm.model.norm.register_forward_hook(lambda m, a, o: eager_final.append(o.detach().float().clone()))
    out_eager, actn_eager, mode_e = infer(model, normalizer, data, fa2=False, track=True)
    idmap = {id(t): n for n, t in list(model.named_parameters()) + list(model.named_buffers())}
    read = {idmap[i] for i in mode_e.seen if i in idmap}  # weights the official path passed to a torch op
    h.remove()

    # ------------------------------------------------------------ derived records and checks
    assert len(mode.draws) == 1 and mode.draws[0][0] == "rand", mode.draws
    u = mode.draws[0][1]  # torch.rand(1, 1200)
    noise = u * 2 - 1  # get_action: (torch.rand(B, action_dim_total) * 2 - 1)
    torch.manual_seed(SEED)
    seed_ok = torch.equal(torch.rand(1, 1200), u)
    amask = torch.tensor([1] * 7 + [0] * 17, dtype=torch.float32).view(1, 1, 24).repeat(1, 50, 1)
    dt = 1.0 / STEPS
    x = noise.clone()
    xs, step_in_ok = [], True
    vel = S["velocity"]
    assert len(vel) == STEPS and len(S["head_in"]) == STEPS
    for i in range(STEPS):
        step_in_ok &= torch.equal(S["head_in"][i], (x.view(1, 50, 24) * amask))
        x = x + dt * vel[i]  # get_action: action = action + dt * pred
        xs.append(x.clone())
    final_ok = torch.equal(xs[-1].view(50, 24), actn_fa2)
    unnorm = normalizer.denormalize_action(actn_fa2).numpy()
    tidx = [int((i / STEPS) * 1000) for i in range(STEPS)]
    pe = model.action_head.time_pos_enc.pe[0]
    temb_ok = all(torch.equal(S["time_emb"][i][0], pe[tidx[i]]) for i in range(STEPS))

    ids = S["input_ids"][0][0].long().numpy()
    attn = S["attention_mask"][0][0].long().numpy()
    tok_mask = (ids != 151643).astype(np.int32)  # the tokenizer's mask (right padding with <|endoftext|>)
    slots = np.nonzero(ids == IMG_CONTEXT)[0]
    assert slots.size == 768
    slots = slots.reshape(3, 256)
    n_real = int(tok_mask.sum())
    assert tok_mask[:n_real].all() and not tok_mask[n_real:].any()
    exp_attn = tok_mask.copy()
    exp_attn[slots[2]] = 0
    assert np.array_equal(attn, exp_attn)
    valid = attn.astype(bool)

    # channels: the server's cv2.resize + BGR2RGB of the RGB views
    imgs448 = np.stack(pil_u8)  # [3, 448, 448, 3], the u8 the embedder normalizes
    swap_ok = all(np.array_equal(imgs448[k], cv2.resize(v, (448, 448))[..., ::-1]) for k, v in enumerate((full, wrist)))
    mean = np.array([0.485, 0.456, 0.406], np.float32).reshape(3, 1, 1)
    std = np.array([0.229, 0.224, 0.225], np.float32).reshape(3, 1, 1)
    pix_np = (imgs448.transpose(0, 3, 1, 2).astype(np.float32) / np.float32(255) - mean) / std
    pix = S["pixel_values"][0].numpy()
    pix_d = float(np.abs(pix_np - pix).max())

    fin = S["llm_final_norm"][0][0]
    fin_e = eager_final[0][0]
    vit_out, mlp1_out = S["vit_out"][0], S["mlp1_out"][0]
    llm_in = S["llm_input_embeds"][0][0]
    scatter_ok = torch.equal(llm_in[torch.from_numpy(slots.reshape(-1))], mlp1_out.reshape(-1, 896))
    embed_w = model.embedder.model.language_model.get_input_embeddings().weight
    text_pos = torch.from_numpy(np.setdiff1d(np.arange(1024), slots.reshape(-1)))
    embed_ok = torch.equal(llm_in[text_pos], embed_w[torch.from_numpy(ids)[text_pos]].float())
    ctx = S["context"][0][0]
    ctx_ok = torch.equal(ctx[:1024], fin) and torch.equal(ctx[1024], S["state_token"][0][0])

    checks = {
        "checkpoint_all_tensors_equal_after_strict_load": load_exact,
        "only_rng_draw_is_get_action_torch_rand": True,
        "noise_reproduced_by_manual_seed0_rand_1x1200": seed_ok,
        "head_input_each_step_equals_x_times_action_mask_bitwise": bool(step_in_ok),
        "x_after_last_step_equals_denormalize_input_bitwise": bool(final_ok),
        "time_emb_rows_equal_pe[int(i/32*1000)]_bitwise": temb_ok,
        "server_output_vs_denormalize(actions_norm)_maxabs": float(np.abs(out_fa2 - unnorm).max()),
        "images_448_equal_cv2_resize_then_channel_reverse": swap_ok,
        "pixel_values_vs_numpy_(u8/255-mean)/std_maxabs": pix_d,
        "image_slot_scatter_equals_mlp1_out_bitwise": bool(scatter_ok),
        "text_rows_equal_embed_tokens[input_ids]_bitwise": bool(embed_ok),
        "context_equals_[llm_final_norm, state_token]_bitwise": bool(ctx_ok),
        "context_identical_across_steps_maxabs": taps.ctx_diff,
        "fa2_vs_eager_llm_final_valid_rows_maxabs": float((fin[valid] - fin_e[valid]).abs().max()),
        "fa2_vs_eager_llm_final_masked_rows_maxabs": float((fin[~valid] - fin_e[~valid]).abs().max()),
        "fa2_vs_eager_actions_norm_7dims_maxabs": float((actn_fa2[:, :7] - actn_eager[:, :7]).abs().max()),
        "fa2_vs_eager_actions_unnorm_7dims_maxabs": float(np.abs(out_fa2[:, :7] - out_eager[:, :7]).max()),
        "fa2_vs_eager_actions_unnorm_per_dim_maxabs": np.abs(out_fa2[:, :7] - out_eager[:, :7]).max(0).tolist(),
        "fa2_vs_eager_actions_unnorm_first14_per_dim_maxabs":
            np.abs(out_fa2[:14, :7] - out_eager[:14, :7]).max(0).tolist(),
        "actions_unnorm_first14_per_dim_range_fa2": np.ptp(out_fa2[:14, :7], 0).tolist(),
    }
    for k, v in checks.items():
        print(f"  check {k}: {v}")

    # ------------------------------------------------------------ write ref
    out = a.out
    out.mkdir(parents=True, exist_ok=True)
    tensors = {}

    def save(name, arr, meaning, dtype="f32"):
        if isinstance(arr, torch.Tensor):
            arr = arr.detach().cpu().numpy()
        np_dtype = {"f32": "<f4", "i32": "<i4", "u8": "u1"}[dtype]
        arr = np.ascontiguousarray(np.asarray(arr).astype(np_dtype))
        arr.tofile(out / f"{name}.{dtype}")
        tensors[name] = {"file": f"{name}.{dtype}", "shape": list(arr.shape), "dtype": dtype, "meaning": meaning,
                         "max_abs": float(np.abs(arr.astype(np.float64)).max()) if arr.size else 0.0}

    save("image_agentview_224", full, "sample full_image as sent (224x224x3 RGB HWC, already rotated 180 deg)", "u8")
    save("image_wrist_224", wrist, "sample wrist_image as sent (224x224x3 RGB HWC, already rotated 180 deg)", "u8")
    save("images_448", imgs448, "the 3 views as the embedder normalizes them (HWC u8): cv2.resize to 448 (INTER_LINEAR)"
         " then cv2 BGR2RGB, i.e. CHANNEL-REVERSED w.r.t. the RGB sample (ch0 = scene blue); view 3 = zeros", "u8")
    save("pixel_values", pix, "ViT input [view, C, 448, 448] = (images_448/255 - ImageNet mean)/std, channel order of "
         "images_448; view 3 is the constant dummy", "f32")
    save("input_ids", ids, "Qwen2 slow tokenizer ids, prompt 'Image-1: <img>'+256*<IMG_CONTEXT>+'</img>\\n' x3 + task, "
         "right-padded to 1024 with <|endoftext|> 151643", "i32")
    save("attention_mask", attn, "LLM attention mask (1 = valid): tokenizer mask with view 3's 256 slots zeroed "
         "(image_mask [1,1,0]); FA2: masked rows get zero attention output and are never attended to", "i32")
    save("attention_mask_tokenizer", tok_mask, "the tokenizer's own mask (1 for the real tokens)", "i32")
    save("image_slots", slots, "positions of the <IMG_CONTEXT> slots per view [3, 256]; mlp1_out[v] goes to "
         "input_embeds[image_slots[v]]", "i32")
    save("position_ids", np.arange(1024), "RoPE positions: 0..1023 for every token, masked ones included", "i32")
    save("vit_embeddings", S["vit_embeddings"][0], "InternViT embeddings output [view, 1025, 1024]: [CLS, 1024 patches]"
         " + position embedding (the bicubic resize of the 32x32 grid is the identity at 448)")
    save("vit_out", vit_out, "InternViT last_hidden_state [view, 1025, 1024] (CLS first), the input of extract_feature's"
         " CLS drop + pixel shuffle + mlp1 (no final norm)")
    save("mlp1_out", mlp1_out, "extract_feature output [view, 256, 896]: drop CLS, 32x32x1024 -> pixel_shuffle(0.5, "
         "v2) -> 16x16x4096 -> mlp1 (LayerNorm 1e-5, Linear, GELU, Linear)")
    save("llm_input_embeds", llm_in, "inputs_embeds [1024, 896]: embed_tokens[input_ids], image slots replaced by "
         "mlp1_out (view 3's too, masked)")
    for i in range(14):
        save(f"llm_layer{i:02d}", S[f"llm_layer{i:02d}"][0][0], f"Qwen2 decoder layer {i} output [1024, 896], "
             "FA2-emulated (residual stream before the final norm)")
    save("llm_final_norm", fin, "model.norm(layer 13 output) [1024, 896] = fused_hidden = head context rows 0..1023")
    save("state_raw", np.asarray(state8, np.float32), "sample state (8,): eef_pos 3, axis-angle 3, gripper_qpos 2; the "
         "server casts it to fp32")
    save("state_norm", S["state_norm"][0][0], "normalized state (24,): clamp(2(x-min)/(max-min+1e-8)-1,-1,1) of the "
         "zero-padded state; padded dims = -1")
    save("state_token", S["state_token"][0][0], "state_encoder output (896,): Linear 24->1024, ReLU, Linear 1024->896")
    save("context", ctx, "action-head context [1025, 896] = [llm_final_norm; state_token], keys/values of every "
         "cross-attention, no key mask (pad and masked rows included)")
    save("noise", noise.view(50, 24), "initial x: torch.rand(1,1200)*2-1 after torch.manual_seed(0) (uniform [-1,1)), "
         "NOT masked: the padded dims keep their noise in x")
    save("action_mask", amask[0, 0].numpy(), "action mask (24,): 7 real dims; the head's input each step is x*mask",
         "i32")
    save("time_index", np.array(tidx), f"per-step time_pos_enc row int(i/{STEPS}*1000) (main), t = i/{STEPS}", "i32")
    save("time_emb", torch.stack([t[0] for t in S["time_emb"]]), f"per-step time embedding ({STEPS} x 896): "
         "time_pos_enc.pe[time_index], the checkpoint's bf16-rounded sinusoid table; added after norm2 in every block")
    save("velocity", torch.stack([v.view(50, 24) for v in vel]), f"per-step mlp_head output ({STEPS} x 50 x 24)")
    save("x", torch.stack([v.view(50, 24) for v in xs]), f"per-step x after x += (1/{STEPS}) v ({STEPS} x 50 x 24)")
    save("head0_action_tokens", S["action_tokens"][0][0], "step 0: action_encoder(noise*mask) [50, 896]")
    for i in range(8):
        save(f"head0_block{i}", S[f"block{i}"][0][0], f"step 0: transformer block {i} output [50, 896]")
    save("head0_norm_out", S["norm_out"][0][0], "step 0: norm_out output [50, 896]")
    save("head0_pooled", S["pooled"][0][0], "step 0: seq_pool_proj(flatten(norm_out)) (896,)")
    save("actions_norm", actn_fa2, "final normalized actions [50, 24] = x after the last step (only [:, :7] "
         "meaningful)")
    save("actions", out_fa2[:, :7], "unnormalized actions [50, 7] = server output cropped to 7: (a+1)/2*(max-min+1e-8)"
         "+min; the LIBERO client then executes the first 14, gripper -> -1 if a[6] > 0.5 else 1")
    save("state_min", normalizer.state_min, "state min as used (8 from norm_stats.json libero_robot, zero-padded to 24)")
    save("state_max", normalizer.state_max, "state max as used (zero-padded to 24)")
    save("action_min", normalizer.action_min, "action min as used (7, zero-padded to 24)")
    save("action_max", normalizer.action_max, "action max as used (7, zero-padded to 24)")
    save("eager_actions_norm", actn_eager, "plain eager attention (no FA2 emulation): normalized actions [50, 24]")
    save("eager_actions", out_eager[:, :7], "plain eager attention: unnormalized actions [50, 7]")

    # ------------------------------------------------------------ numerics survey
    def part(name):
        if name.startswith("embedder.model.vision_model"):
            return "vit"
        if name.startswith("embedder.model.mlp1"):
            return "mlp1"
        if name.startswith("embedder.model.language_model"):
            return "llm"
        return "head"

    by_part = collections.defaultdict(dict)
    for k, v in taps.maxabs.items():
        by_part[part(k)][k] = v
    top = {p: dict(sorted(d.items(), key=lambda kv: -kv[1])[:8]) for p, d in by_part.items()}
    over = {k: v for k, v in taps.maxabs.items() if v > 30000}
    llm_rows = {}
    for i in range(14):
        y = S[f"llm_layer{i:02d}"][0][0]
        llm_rows[f"layer{i:02d}"] = {"valid": float(y[valid].abs().max()), "masked": float(y[~valid].abs().max())}
    tops = {}
    for i in (0, 13):
        y = S[f"llm_layer{i:02d}"][0][0].abs()
        flat = y.flatten().topk(4)
        tops[f"layer{i:02d}"] = [(int(j // 896), int(j % 896), float(v)) for v, j in zip(flat.values, flat.indices)]
    logits = {"vit": {f"layer{i:02d}": {"max": v[0], "at_(view,head,q,k)": list(v[1:])}
                      for i, v in sorted(taps.vit_logit.items())},
              "llm": {f"layer{i:02d}": v for i, v in llm_logits(taps, lm, attn).items()},
              "head": {f"block{i}": v for i, v in sorted(taps.head_logit.items())}}
    numerics = {"over_30000": over, "top_per_part": top, "llm_residual_maxabs_valid_vs_masked_rows": llm_rows,
                "llm_residual_top4_(row,col,|x|)": tops, "attention_logit_maxabs": logits,
                "all_module_outputs_maxabs": taps.maxabs}
    del taps, S
    gc.collect()

    # ------------------------------------------------------------ bf16 repeat (as released)
    bf16 = None
    if not a.no_bf16:
        del model, msd, lm, rope, embed_w, pe
        gc.collect()
        t0 = time.time()
        model16, _ = build_model(sd, fp32=False)
        emb_mod.torch = torch
        lm16 = model16.embedder.model.language_model
        rope16 = lm16.model.layers[0].self_attn.rotary_emb.cos_cached.dtype
        print(f"built EVO1 (bf16 VLM) in {time.time() - t0:.1f} s; RoPE cache {rope16}")
        fin16 = []
        h = lm16.model.norm.register_forward_hook(lambda m, a, o: fin16.append(o.detach().float().clone()))
        out16, actn16, _ = infer(model16, normalizer, data, fa2=True, bf16=True)
        h.remove()
        f16 = fin16[0][0]
        bf16 = {
            "actions_norm_7dims_maxabs": float((actn16[:, :7] - actn_fa2[:, :7]).abs().max()),
            "actions_unnorm_7dims_maxabs": float(np.abs(out16[:, :7] - out_fa2[:, :7]).max()),
            "actions_unnorm_7dims_per_dim_maxabs": np.abs(out16[:, :7] - out_fa2[:, :7]).max(0).tolist(),
            "llm_final_valid_rows_maxabs": float((f16[valid] - fin[valid]).abs().max()),
            "llm_final_valid_rows_rel_rms": float((f16[valid] - fin[valid]).norm() / fin[valid].norm()),
            "rope_cache_dtype": str(rope16),
        }
        save("bf16_actions_norm", actn16, "bf16 repeat (bf16 VLM, CPU autocast bf16, FA2-emulated): normalized [50, 24]")
        save("bf16_actions", out16[:, :7], "bf16 repeat: unnormalized actions [50, 7]")
        print("  bf16 vs fp32:", json.dumps(bf16))
        del model16
        gc.collect()

    meta = {
        "model": "MINT-SJTU/Evo1_LIBERO", "hf_revision": REV_HF, "checkpoint_sha256": CKPT_SHA256,
        "deepspeed": ds_meta, "checkpoint_buffers": buffer_names,
        "code": "MINT-SJTU/Evo-1 (branch main)", "code_revision": REV_GH,
        "vlm": f"OpenGVLab/InternVL3-1B @ {REV_VLM} (config, remote code, tokenizer; weights from the checkpoint)",
        "sample": f"OpenHelix-Team/VLA-Adapter @ {REV_VA} {SAMPLE_PATH} (sha256 {SAMPLE_SHA256})",
        "prompt": prompt, "n_real_tokens": n_real, "steps": STEPS,
        "time_index_convention": "int((i / 32) * 1000), main FlowmatchingActionHead.get_action",
        "seed": SEED, "image_mask": [1, 1, 0],
        "versions": {"torch": torch.__version__, "transformers": __import__("transformers").__version__,
                     "python": sys.version.split()[0]},
        "notes": [
            "Files are raw little-endian, C order, no header; the batch dim (1) is dropped.",
            "fp32 throughout; weights are the checkpoint's bf16 values upcast exactly.",
            "Attention semantics = FlashAttention-2's (transformers 4.39 Qwen2FlashAttention2 with a 2-D mask): masked "
            "query rows get a zero attention output (they evolve through the residual + MLP only), valid rows see "
            "valid keys causally, RoPE positions 0..1023. eager_* = plain eager (masked rows attend to earlier valid "
            "keys).",
            "ViT: pre-LN (eps 1e-6), qkv bias, scale 1/8, exact GELU, layer scale ls1/ls2, no final norm. mlp1 "
            "LayerNorm eps 1e-5. LLM: RMSNorm eps 1e-6, RoPE theta 1e6 (rope_scaling ignored in 4.39), GQA 14/2, "
            "SwiGLU. Head: LayerNorm eps 1e-5, nn.MultiheadAttention 8 heads x 112 (scale 1/sqrt(112)), FFN GELU "
            "(exact), x2 = norm2(x) + time_emb.",
            f"Sampler: x0 = noise; for i in 0..{STEPS - 1}: v = head(x*mask, context, time_emb[i]); x += v/{STEPS}.",
        ],
        "checks": checks,
        "bf16_vs_fp32": bf16,
        "numerics": numerics,
        "tensors": tensors,
    }
    (out / "meta.json").write_text(json.dumps(meta, indent=1))

    # ------------------------------------------------------------ export
    if a.export:
        export(sd, read, dtypes)

    np.set_printoptions(precision=5, suppress=True, linewidth=140)
    print("\nprompt:", prompt, f"({n_real} real tokens)")
    print("normalized actions [:14, :7]:\n", actn_fa2[:14, :7].numpy())
    print("unnormalized actions [:14] (libero_robot):\n", out_fa2[:14, :7])
    print("\nlargest attention logits:", json.dumps(
        {p: max(v if isinstance(v, float) else v.get("fa2", v.get("max")) for v in d.values()) for p, d in logits.items()}))
    print("over 30000:", over)
    print("top per part:", json.dumps({p: dict(list(d.items())[:3]) for p, d in top.items()}, indent=1))
    print("wrote", len(tensors), "tensors to", out)


def export(sd, read, dtypes):
    """build/evo1/evo1.safetensors: the checkpoint's tensors as stored, EVO1 state_dict names."""
    from safetensors.torch import save_file

    used, skipped = {}, []
    for k, v in sd.items():
        if k in read:
            used[k] = v.contiguous().clone()
        else:
            skipped.append(k)
    lines = [f"# {len(used)} tensors from MINT-SJTU/Evo1_LIBERO@{REV_HF} mp_rank_00_model_states.pt ['module'], "
             "dtype as stored, PyTorch (out, in) layouts; names = EVO1 state_dict keys (main @ 2020853)",
             f"# skipped (never passed to a torch op by the official inference path, plain eager run): {len(skipped)}",
             "# not in the checkpoint, derived from the config at load: Qwen2 rotary_emb inv_freq / cos_cached / "
             "sin_cached (theta 1e6, head_dim 64); lm_head is Identity",
             "# name\tshape\tdtype (fp32 reference model dtype in brackets)"]
    for k, v in used.items():
        lines.append(f"{k}\t{list(v.shape)}\t{str(v.dtype).removeprefix('torch.')}\t[{dtypes[k].removeprefix('torch.')}]")
    if skipped:
        lines.append("# skipped:")
        lines += [f"# {k}\t{list(sd[k].shape)}" for k in skipped]
    save_file(used, str(B / "evo1.safetensors"),
              metadata={"source": f"MINT-SJTU/Evo1_LIBERO@{REV_HF}", "code": f"MINT-SJTU/Evo-1@{REV_GH}"})
    (B / "export_names.txt").write_text("\n".join(lines) + "\n")
    print(f"wrote {B / 'evo1.safetensors'} ({len(used)} tensors, {len(skipped)} skipped)")


if __name__ == "__main__":
    main()
