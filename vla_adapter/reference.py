"""VLA-Adapter Pro (VLA-Adapter/LIBERO-Spatial-Pro) in fp32 on the Mac's CPU: the reference the GPU/NPU ports are
checked against. It runs the OFFICIAL inference path from the repo's own code (OpenHelix-Team/VLA-Adapter at a pinned commit,
cloned to build/vla_adapter/src), the way experiments/robot/libero/run_libero_eval.py drives it:

  robot_utils.get_model -> openvla_utils.get_vla (AutoModelForVision2Seq -> prismatic.extern.hf.modeling_prismatic.
  OpenVLAForActionPrediction), get_proprio_projector, get_action_head (L1RegressionActionHead, Pro blocks),
  get_processor; then robot_utils.get_action -> openvla_utils.get_vla_action -> OpenVLAForActionPrediction.
  predict_action -> _regression_or_discrete_prediction -> L1RegressionActionHead.predict_action -> unnormalize.

It runs one action chunk twice: first in bf16 exactly as released (only the CPU load fix below), then in fp32, and
writes the fp32 run's tensors to build/vla_adapter/ref as raw little-endian .f32 / .i32 / .u8 files plus meta.json:

  build/vla_adapter/venv/bin/python vla_adapter/reference.py              # writes build/vla_adapter/ref
  build/vla_adapter/venv/bin/python vla_adapter/reference.py --export     # + vla_adapter.safetensors, export_names.txt
  build/vla_adapter/venv/bin/python vla_adapter/reference.py --skip-bf16  # fp32 only (no bf16-vs-fp32 numbers)

Setup (once): the venv is Python 3.10 with vla_adapter/requirements-reference.txt (the repo's pins where they exist:
torch 2.2.0 / torchvision 0.17.0 CPU wheels, transformers 4.40.1, tokenizers 0.19.1, timm 0.9.10, tensorflow 2.15.0;
the rest pinned to the authors' our_envs.txt), plus `uv pip install --no-deps tensorflow_graphics==2021.12.3`.
Nothing is stubbed: importing openvla_utils pulls in prismatic/__init__ (draccus, rich), the RLDS data code (dlimp,
tensorflow_datasets, tensorflow_graphics via oxe/utils/droid_utils.py), prismatic.training (jsonlines, wandb) and
robot_utils (msgpack); none of them runs at inference. The script clones the repo and downloads the checkpoint at
the pinned revisions if they are missing (build/vla_adapter/src, build/vla_adapter/hf), then sets HF_HUB_OFFLINE.

Input: the repo's own sample, experiments/robot/libero/sample_libero_spatial_observation.pkl: full_image and
wrist_image (224x224x3 uint8, already 180-degree rotated and resized like run_libero_eval.prepare_observation does),
state (8 float64: eef pos 3, axis-angle 3, gripper qpos 2) and its task_description, "pick up the black bowl between
the plate and the ramekin and place it on the plate". The observation dict handed to get_action has the keys
prepare_observation builds (full_image, wrist_image, state). The config mirrors run_libero_eval.GenerateConfig's
defaults (center_crop=True, num_images_in_input=2, use_proprio, use_l1_regression, use_minivlm, use_pro_version,
seed 7) with pretrained_checkpoint = build/vla_adapter/hf; that module imports the LIBERO simulator, so its
GenerateConfig, check_unnorm_key and process_action (3-5 lines each) are mirrored here, not imported.
unnorm_key resolves to libero_spatial_no_noops.

Patches (all applied in memory by this script; no file in build/vla_adapter/src is modified). Each source patch
replaces exact text in the function's source (asserting how often it occurs), re-executes the function in its own
module's globals and rebinds it (also where another module imported it by name):
  P0  platform constants: prismatic/vla/constants.py picks LIBERO / ALOHA / BRIDGE / CALVIN by grepping sys.argv. It
      is loaded here before anything imports it, and NUM_ACTIONS_CHUNK=8, ACTION_DIM=7, PROPRIO_DIM=8,
      ACTION_PROPRIO_NORMALIZATION_TYPE=bounds_q99 are set from its LIBERO_CONSTANTS explicitly (checked afterwards
      in every module that copied them).
  P1  openvla_utils.load_component_state_dict: torch.load(..., map_location="cpu"). The .pt storages are tagged
      cuda:0. (The other two torch.load calls, load_component_state_dict_v1 and the FiLM loader, are not on this path.)
  fp32 run only, each a hard-coded torch.bfloat16 -> torch.float32:
  P2  openvla_utils.get_vla: from_pretrained(torch_dtype=...). (The bf16 weights are upcast exactly.)
  P3  openvla_utils.get_proprio_projector: .to(dtype).
  P4  openvla_utils.get_action_head: .to(dtype).
  P5  openvla_utils.get_vla_action: processor(...).to(DEVICE, dtype=...) for the primary and the wrist image.
  P6  modeling_prismatic.OpenVLAForActionPrediction._regression_or_discrete_prediction: the ActionQuery window is cast
      .to(torch.bfloat16) before it is concatenated with the (fp32) task window.
  P7  action_heads.L1RegressionActionHead.predict_action: proprio .to(dtype).
The bf16 run uses P0 and P1 only, so it is the released inference code as is, on CPU.

Side effects of the official loader, kept as they are: get_vla() is called with the working directory at
build/vla_adapter/src, as the eval script runs; update_auto_map rewrites build/vla_adapter/hf/config.json's auto_map
(with a timestamped backup) and check_model_logic_mismatch copies the repo's modeling_prismatic.py /
configuration_prismatic.py over the checkpoint's stale copies (backing those up once). Neither changes what runs:
trust_remote_code=False and the classes are registered from the repo's prismatic package. Backups that are
byte-identical to the current config.json (one per get_vla call) are removed at the end.

Runtime on this Mac (10 cores, 16 GB): about 3 min in all, 8.7 GB peak RSS with --export. The bf16 run's get_action
takes about 140 s (torch 2.2 has no fast CPU bf16 GEMM here), the fp32 one about 4 s with the diagnostic hooks. The fp32
outputs are bit-identical from run to run.

Recording: forward hooks on the official modules (no module is wrapped or replaced), plus a pass-through wrapper on
openvla_utils.prepare_images_for_vla during the call that keeps the center-cropped images. The diagnostics (max |x| of
every module's input and output, attention logits of every ViT block, LLM layer and policy block, the policy's softmax
mass per key segment) recompute q.k from the modules' own weights inside the hooks; they do not feed back into the run.
"""

import argparse
import gc
import importlib.util
import inspect
import json
import math
import os
import pathlib
import pickle
import platform
import subprocess
import sys
import textwrap
import time
import types

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/vla_adapter"
SRC = B / "src"
HF = B / "hf"
GH_REPO = "OpenHelix-Team/VLA-Adapter"
REV_GH = "23fa0c9c159e2aa04341cdd3e924f44061311060"
HF_REPO = "VLA-Adapter/LIBERO-Spatial-Pro"
REV_HF = "cb023c6771fc62ea729d218f09ac0583c14f59d4"
SAMPLE = SRC / "experiments/robot/libero/sample_libero_spatial_observation.pkl"

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")

PATCHES = []


def ensure_sources():
    """Clone the repo / download the checkpoint at the pinned revisions if missing; check both revisions."""
    if not (SRC / ".git").exists():
        for cmd in (["git", "init", "-q", str(SRC)],
                    ["git", "-C", str(SRC), "remote", "add", "origin", f"https://github.com/{GH_REPO}"],
                    ["git", "-C", str(SRC), "fetch", "-q", "--depth", "1", "origin", REV_GH],
                    ["git", "-C", str(SRC), "checkout", "-q", "FETCH_HEAD"]):
            subprocess.run(cmd, check=True)
    head = subprocess.run(["git", "-C", str(SRC), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    assert head == REV_GH, f"build/vla_adapter/src is at {head}, expected {REV_GH}"
    dirty = subprocess.run(["git", "-C", str(SRC), "status", "--porcelain", "--untracked-files=no"],
                           capture_output=True, text=True).stdout.strip()
    assert not dirty, f"build/vla_adapter/src has local modifications:\n{dirty}"
    if not (HF / "model.safetensors").exists():
        from huggingface_hub import snapshot_download
        snapshot_download(HF_REPO, revision=REV_HF, local_dir=HF)
    for f in ("model.safetensors", "action_head--checkpoint.pt", "proprio_projector--checkpoint.pt"):
        rev = (HF / ".cache/huggingface/download" / f"{f}.metadata").read_text().split()[0]
        assert rev == REV_HF, f"{f} was downloaded at {rev}, expected {REV_HF}"
    os.environ["HF_HUB_OFFLINE"] = "1"
    os.environ["TRANSFORMERS_OFFLINE"] = "1"


def libero_constants():
    """P0: load prismatic/vla/constants.py before anything imports it and set the LIBERO constants explicitly."""
    name = "prismatic.vla.constants"
    spec = importlib.util.spec_from_file_location(name, SRC / "prismatic/vla/constants.py")
    c = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(c)
    c.ROBOT_PLATFORM = "LIBERO"
    c.constants = c.LIBERO_CONSTANTS
    for k, v in c.LIBERO_CONSTANTS.items():
        setattr(c, k, v)
    sys.modules[name] = c
    print("P0: platform constants set to LIBERO:", {k: str(v) for k, v in c.LIBERO_CONSTANTS.items()})
    PATCHES.append({"id": "P0", "where": "prismatic.vla.constants",
                    "what": "preloaded; ROBOT_PLATFORM='LIBERO' and LIBERO_CONSTANTS assigned explicitly",
                    "why": "constants.py picks the platform by grepping sys.argv"})
    return c


def patch_source(pid, owner, name, edits, why):
    """Replace exact text in a function's source, re-exec it in its module's globals and rebind it."""
    old = owner.__dict__[name]
    src = textwrap.dedent(inspect.getsource(old))
    for a, b, n in edits:
        found = src.count(a)
        if found != n:
            raise RuntimeError(f"{pid}: expected {n} x {a!r} in {old.__qualname__}, found {found}")
        src = src.replace(a, b)
    src = "\n" * (old.__code__.co_firstlineno - 1) + src  # keep the file's line numbers in tracebacks
    module = sys.modules[old.__module__]
    ns = {}
    exec(compile(src, inspect.getsourcefile(old), "exec"), module.__dict__, ns)
    new = ns[name]
    new.__qualname__ = old.__qualname__
    setattr(owner, name, new)
    if isinstance(owner, types.ModuleType):  # rebind where other modules imported it by name
        for m in list(sys.modules.values()):
            if getattr(m, "__name__", "").startswith(("experiments", "prismatic")) and m.__dict__.get(name) is old:
                setattr(m, name, new)
    PATCHES.append({"id": pid, "where": f"{old.__module__}.{old.__qualname__}",
                    "edits": [{"old": a, "new": b, "count": n} for a, b, n in edits], "why": why})
    print(f"{pid}: patched {old.__module__}.{old.__qualname__}")


def make_cfg():
    """run_libero_eval.GenerateConfig's defaults (that module imports the LIBERO simulator, so it is mirrored)."""
    return types.SimpleNamespace(
        model_family="openvla", pretrained_checkpoint=str(HF), use_l1_regression=True, use_minivlm=True,
        num_diffusion_steps=50, use_film=False, num_images_in_input=2, use_proprio=True, center_crop=True,
        num_open_loop_steps=8, unnorm_key="", load_in_8bit=False, load_in_4bit=False,
        task_suite_name="libero_spatial", num_steps_wait=10, num_trials_per_task=50, initial_states_path="DEFAULT",
        env_img_res=256, run_id_note=None, local_log_dir="./experiments/logs", use_wandb=False, seed=7,
        save_version="vla-adapter", use_pro_version=True, phase="Inference")


def first_tensor(x):
    import torch
    if torch.is_tensor(x):
        return x
    if isinstance(x, (tuple, list)) and x and torch.is_tensor(x[0]):
        return x[0]
    return None


class Recorder:
    """Forward hooks on the official modules: captured tensors (as fp32 numpy) and, if full, the diagnostics."""

    def __init__(self, vla, head, proj, full):
        import torch
        self.cap, self.stats, self.called, self.dtypes, self.logits, self.mass = {}, {}, set(), set(), {}, {}
        self.full, self.diag, self.handles = full, False, []
        np_ = lambda t: t.detach().float().cpu().numpy().copy()  # noqa: E731
        add = lambda k, t: self.cap.setdefault(k, []).append(np_(t))  # noqa: E731
        H = self.handles
        vb, lm = vla.vision_backbone, vla.language_model

        H.append(vb.register_forward_pre_hook(lambda m, a: add("pixel_values", a[0])))
        H.append(vb.featurizer.register_forward_hook(lambda m, a, o: add("dinov2", o)))
        H.append(vb.fused_featurizer.register_forward_hook(lambda m, a, o: add("siglip", o)))
        H.append(vb.register_forward_hook(lambda m, a, o: add("vision_patches", o)))
        H.append(vla.projector.register_forward_hook(lambda m, a, o: add("projector", o)))
        H.append(lm.get_input_embeddings().register_forward_pre_hook(
            lambda m, a: self.cap.setdefault("llm_input_ids", []).append(a[0].cpu().numpy().copy())))
        H.append(lm.register_forward_pre_hook(lambda m, a, kw: add("llm_inputs_embeds", kw["inputs_embeds"]),
                                              with_kwargs=True))
        H.append(lm.register_forward_hook(
            lambda m, a, o: self.cap.setdefault("llm_hidden", []).append([np_(h) for h in o.hidden_states])))
        H.append(lm.model.layers[-1].register_forward_hook(lambda m, a, o: add("llm_last_layer_prenorm", o[0])))
        H.append(proj.register_forward_pre_hook(lambda m, a: add("proprio_projector_in", a[0])))
        H.append(proj.register_forward_hook(lambda m, a, o: add("proprio_p", o)))

        def mlp_pre(m, a, kw):
            add("policy_x0", a[0])
            add("policy_h_a", kw["h_a"])
            add("policy_h_t", kw["h_t"])
            add("policy_p", kw["p"])
        H.append(head.model.register_forward_pre_hook(mlp_pre, with_kwargs=True))
        H.append(head.model.register_forward_hook(lambda m, a, o: add("policy_actions_norm", o)))
        for i, blk in enumerate(head.model.mlp_resnet_blocks):
            H.append(blk.register_forward_pre_hook(lambda m, a, kw, i=i: add(f"policy_in_{i:02d}", a[0]),
                                                   with_kwargs=True))
            H.append(blk.register_forward_hook(lambda m, a, o, i=i: add(f"policy_block_{i:02d}", o)))
        if not full:
            return

        # every module's max |input| and max |output| (and which modules ran)
        named = [(n or "vla", m) for n, m in vla.named_modules()]
        named += [("action_head" + (f".{n}" if n else ""), m) for n, m in head.named_modules()]
        named += [("proprio_projector" + (f".{n}" if n else ""), m) for n, m in proj.named_modules()]

        def stat_hook(name):
            def h(m, a, o):
                if self.diag:
                    return
                self.called.add(name)
                for kind, t in (("in", first_tensor(a)), ("out", first_tensor(o))):
                    if t is not None and t.is_floating_point() and t.numel():
                        self.dtypes.add(str(t.dtype))
                        s = self.stats.setdefault(name, {})
                        s[kind] = max(s.get(kind, 0.0), float(t.detach().abs().max()))
            return h
        for n, m in named:
            H.append(m.register_forward_hook(stat_hook(n)))

        # attention logits (recomputed from the modules' own weights; diagnostics only)
        def vit_pre(key):
            def h(attn, a):
                self.diag = True
                x = a[0]
                B_, N, _ = x.shape
                qkv = attn.qkv(x).reshape(B_, N, 3, attn.num_heads, attn.head_dim).permute(2, 0, 3, 1, 4)
                q, k = attn.q_norm(qkv[0]), attn.k_norm(qkv[1])
                s = (q * attn.scale) @ k.transpose(-2, -1)
                self._logit(key, s)
                self.diag = False
            return h
        for tag, vit in (("dinov2", vb.featurizer), ("siglip", vb.fused_featurizer)):
            for i, blk in enumerate(vit.blocks):
                H.append(blk.attn.register_forward_pre_hook(vit_pre(f"{tag}.block{i:02d}")))

        from transformers.models.qwen2.modeling_qwen2 import apply_rotary_pos_emb, repeat_kv

        def llm_pre(key):
            def h(m, a, kw):
                self.diag = True
                x, pos = kw["hidden_states"], kw["position_ids"]
                B_, S, _ = x.shape
                q = m.q_proj(x).view(B_, S, m.num_heads, m.head_dim).transpose(1, 2)
                k = m.k_proj(x).view(B_, S, m.num_key_value_heads, m.head_dim).transpose(1, 2)
                cos, sin = m.rotary_emb(k, seq_len=S)
                q, k = apply_rotary_pos_emb(q, k, cos, sin, pos)
                s = q @ repeat_kv(k, m.num_key_value_groups).transpose(2, 3) / math.sqrt(m.head_dim)
                self._logit(key, s, torch.ones(S, S, dtype=torch.bool).tril())  # causal entries only
                self.diag = False
            return h
        for i, layer in enumerate(lm.model.layers):
            H.append(layer.self_attn.register_forward_pre_hook(llm_pre(f"llm.layer{i:02d}"), with_kwargs=True))

        import prismatic.models.action_heads as AH

        def policy_pre(i):
            def h(blk, a, kw):
                self.diag = True
                x, h_a, h_t, p = a[0], kw["h_a"], kw["h_t"], kw["p"]
                B_, T, _ = x.shape
                ha = torch.cat((h_a, p), dim=1)
                heads = lambda t: t.view(B_, t.shape[1], blk.num_heads, blk.head_dim).transpose(1, 2)  # noqa: E731
                rope = lambda n: blk.rope(seq_len=n, device=x.device, dtype=x.dtype)  # noqa: E731
                q, ks = AH.apply_rope(heads(blk.q_proj(x)), heads(blk.k_self(x)), *rope(T))
                ka, kt = heads(blk.k_adapter(ha)), heads(blk.k_task(h_t))
                _, ka = AH.apply_rope(ka, ka, *rope(ka.shape[2]))
                _, kt = AH.apply_rope(kt, kt, *rope(kt.shape[2]))
                r = 1.0 / math.sqrt(blk.head_dim)
                g = torch.tanh(blk.gating_factor)
                segs = {"self": q @ ks.transpose(-2, -1) * r, "adapter": q @ ka.transpose(-2, -1) * r,
                        "task_ungated": q @ kt.transpose(-2, -1) * r}
                segs["task"] = q @ kt.transpose(-2, -1) * g * r  # the code scales q.k by tanh(g), then / sqrt(d)
                for sname in ("self", "adapter", "task", "task_ungated"):
                    self._logit(f"policy.block{i:02d}.{sname}", segs[sname])
                w = torch.softmax(torch.cat([segs["self"], segs["adapter"], segs["task"]], -1), -1)
                n1, n2 = T, T + ha.shape[1]
                self.mass[f"block{i:02d}"] = {"self": float(w[..., :n1].sum(-1).mean()),
                                              "adapter": float(w[..., n1:n2].sum(-1).mean()),
                                              "task": float(w[..., n2:].sum(-1).mean())}
                self.diag = False
            return h
        for i, blk in enumerate(head.model.mlp_resnet_blocks):
            H.append(blk.register_forward_pre_hook(policy_pre(i), with_kwargs=True))

    def _logit(self, key, s, allowed=None):
        """max / min / argmax |.| as [head, query, key] / count over 100 of logits s [1, heads, q, k]."""
        import numpy as np
        import torch
        if allowed is not None:
            hi, lo = s.masked_fill(~allowed, -math.inf), s.masked_fill(~allowed, math.inf)
            s = s.masked_fill(~allowed, 0)
        else:
            hi = lo = s
        a = s[0].abs()
        at = [int(i) for i in np.unravel_index(int(a.argmax()), a.shape)]
        self.logits[key] = {"max": float(hi.max()), "min": float(lo.min()), "argmax_abs_head_q_k": at,
                            "n_abs_over_100": int((a > 100).sum()),
                            "n": int(allowed.sum()) * a.shape[0] if allowed is not None else a.numel()}

    def remove(self):
        for h in self.handles:
            h.remove()
        self.handles = []


def run_chunk(OU, RU, cfg, obs, task, full):
    """run_libero_eval.initialize_model + one get_action call; returns the model parts, the actions and the record."""
    import numpy as np
    import torch
    t0 = time.time()
    model = RU.get_model(cfg)
    model.set_version(cfg.save_version)
    proprio_projector = OU.get_proprio_projector(cfg, model.llm_dim, proprio_dim=8)
    action_head = OU.get_action_head(cfg, model.llm_dim)
    processor = OU.get_processor(cfg)
    unnorm_key = cfg.task_suite_name  # run_libero_eval.check_unnorm_key
    if unnorm_key not in model.norm_stats and f"{unnorm_key}_no_noops" in model.norm_stats:
        unnorm_key = f"{unnorm_key}_no_noops"
    assert unnorm_key in model.norm_stats, unnorm_key
    cfg.unnorm_key = unnorm_key
    t_load = time.time() - t0

    rec = Recorder(model, action_head, proprio_projector, full)
    imgs = []
    orig_prepare = OU.prepare_images_for_vla

    def prepare_and_keep(images, c):  # records what prepare_images_for_vla returns (the center-cropped PIL images)
        out = orig_prepare(images, c)
        imgs.extend(np.asarray(im) for im in out)
        return out
    OU.prepare_images_for_vla = prepare_and_keep
    observation = {"full_image": obs["full_image"].copy(), "wrist_image": obs["wrist_image"].copy(),
                   "state": obs["state"].copy()}
    t0 = time.time()
    try:
        actions = RU.get_action(cfg, model, observation, task, processor=processor, action_head=action_head,
                                proprio_projector=proprio_projector, noisy_action_projector=None,
                                use_film=cfg.use_film, use_minivlm=cfg.use_minivlm)
    finally:
        OU.prepare_images_for_vla = orig_prepare
    t_run = time.time() - t0
    rec.remove()
    actions = np.stack(actions)
    env_actions = np.stack([process_action(RU, a, cfg.model_family) for a in actions])
    print(f"chunk ({'fp32' if full else 'bf16'}): load {t_load:.1f} s, get_action {t_run:.1f} s")
    return dict(model=model, head=action_head, proj=proprio_projector, processor=processor, rec=rec,
                actions=actions, env_actions=env_actions, images=np.stack(imgs),
                proprio_norm=np.asarray(observation["state"]), t_load=t_load, t_run=t_run)


def process_action(RU, action, model_family):
    """run_libero_eval.process_action."""
    action = RU.normalize_gripper_action(action, binarize=True)
    if model_family == "openvla":
        action = RU.invert_gripper_action(action)
    return action


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=pathlib.Path, default=B / "ref")
    ap.add_argument("--export", action="store_true", help="also write build/vla_adapter/vla_adapter.safetensors")
    ap.add_argument("--skip-bf16", action="store_true", help="skip the bf16 (as released) run")
    a = ap.parse_args()
    out = a.out.resolve()

    ensure_sources()
    sys.path.insert(0, str(SRC))
    C = libero_constants()

    import numpy as np
    import torch
    import experiments.robot.openvla_utils as OU
    import experiments.robot.robot_utils as RU
    import prismatic.extern.hf.modeling_prismatic as MP
    import prismatic.models.action_heads as AH
    import prismatic.training.train_utils as TU

    for mod in (MP, AH, OU, TU):
        for k, v in C.LIBERO_CONSTANTS.items():
            if k in mod.__dict__:
                assert mod.__dict__[k] == v, f"{mod.__name__}.{k} = {mod.__dict__[k]}, expected {v}"
    patch_source("P1", OU, "load_component_state_dict",
                 [("torch.load(checkpoint_path, weights_only=True)",
                   'torch.load(checkpoint_path, weights_only=True, map_location="cpu")', 1)],
                 "the .pt storages are tagged cuda:0")

    with open(SAMPLE, "rb") as f:
        obs = pickle.load(f)
    task = obs["task_description"]
    cfg = make_cfg()
    os.chdir(SRC)  # the eval runs from the repo root; check_model_logic_mismatch walks ./prismatic/
    RU.set_seed_everywhere(cfg.seed)

    bf = None
    if not a.skip_bf16:
        r = run_chunk(OU, RU, cfg, obs, task, full=False)
        bf = {k: r[k] for k in ("actions", "env_actions", "t_run")}
        bf["actions_norm"] = r["rec"].cap["policy_actions_norm"][0][0]
        bf["hidden"] = r["rec"].cap["llm_hidden"][0]
        bf["projector"] = r["rec"].cap["projector"][0][0]
        bf["policy_blocks"] = [r["rec"].cap[f"policy_block_{i:02d}"][0][0] for i in range(24)]
        bf["dtype"] = str(next(r["model"].parameters()).dtype)
        del r
        gc.collect()

    fp32 = "torch.float32"
    patch_source("P2", OU, "get_vla", [("torch_dtype=torch.bfloat16,", f"torch_dtype={fp32},", 1)], "fp32 reference")
    patch_source("P3", OU, "get_proprio_projector", [(".to(torch.bfloat16)", f".to({fp32})", 1)], "fp32 reference")
    patch_source("P4", OU, "get_action_head", [(".to(torch.bfloat16)", f".to({fp32})", 1)], "fp32 reference")
    patch_source("P5", OU, "get_vla_action", [("dtype=torch.bfloat16", f"dtype={fp32}", 2)], "fp32 reference")
    patch_source("P6", MP.OpenVLAForActionPrediction, "_regression_or_discrete_prediction",
                 [(".to(torch.bfloat16)", f".to({fp32})", 1)], "fp32 reference (ActionQuery window cast)")
    patch_source("P7", AH.L1RegressionActionHead, "predict_action", [(".to(torch.bfloat16)", f".to({fp32})", 1)],
                 "fp32 reference")

    r = run_chunk(OU, RU, cfg, obs, task, full=True)
    vla, head, proj, rec, cap = r["model"], r["head"], r["proj"], r["rec"], r["rec"].cap
    assert {str(p.dtype) for m in (vla, head, proj) for p in m.parameters()} == {fp32}
    assert rec.dtypes == {fp32}, rec.dtypes

    # ------------------------------------------------------------------------------------------------ layout
    ids_full = cap["llm_input_ids"][0][0]
    L = len(ids_full) - 65  # prompt + 64 ActionQuery placeholders (id 1) + stop (id 2)
    hidden = [h[0] for h in cap["llm_hidden"][0]]
    S = hidden[0].shape[0]
    assert S == L + 577 and len(hidden) == 25
    prompt = ("<|im_start|>system\nYou are Qwen, created by Alibaba Cloud. You are a helpful assistant.<|im_end|>\n"
              f"<|im_start|>user\nWhat action should the robot take to {task.lower()}?<|im_end|>\n"
              "<|im_start|>assistant\n")
    ids_prompt = r["processor"].tokenizer(prompt, return_tensors="np")["input_ids"][0]
    assert np.array_equal(ids_prompt, ids_full[:L]) and (ids_full[L:L + 64] == 1).all() and ids_full[-1] == 2
    aq0, aq1 = L + 511, L + 575
    h_t, h_a = cap["policy_h_t"][0][0], cap["policy_h_a"][0][0]  # [25, 512, 896], [25, 64, 896]
    for j in range(25):
        assert np.array_equal(h_t[j], hidden[j][:512]) and np.array_equal(h_a[j], hidden[j][aq0:aq1])
    with torch.no_grad():
        hs_last_norm = vla.language_model.model.norm(torch.from_numpy(cap["llm_last_layer_prenorm"][0])).numpy()
    checks = {"hidden24_is_final_norm_of_layer23_output_maxdiff": float(np.abs(hs_last_norm[0] - hidden[24]).max()),
              "llm_input_vision_rows_equal_projector": bool(np.array_equal(cap["llm_inputs_embeds"][0][0][1:513],
                                                                           cap["projector"][0][0])),
              "llm_input_aq_rows_equal_action_queries": bool(np.array_equal(
                  cap["llm_inputs_embeds"][0][0][L + 512:L + 576], vla.action_queries.weight.detach().numpy())),
              "windows_equal_hidden_state_slices": True}

    # ------------------------------------------------------------------------------------------------ save
    out.mkdir(parents=True, exist_ok=True)
    for old in [*out.glob("*.f32"), *out.glob("*.i32"), *out.glob("*.u8")]:  # no stale files from an earlier run
        old.unlink()
    tensors = {}

    def save(name, arr, meaning, dtype="f32"):
        np_dtype = {"f32": "<f4", "i32": "<i4", "u8": "u1"}[dtype]
        arr = np.ascontiguousarray(np.asarray(arr).astype(np_dtype))
        arr.tofile(out / f"{name}.{dtype}")
        tensors[name] = {"file": f"{name}.{dtype}", "shape": list(arr.shape), "dtype": dtype, "meaning": meaning,
                         "max_abs": float(np.abs(arr.astype(np.float64)).max()) if arr.size else 0.0}
        return arr

    stats = vla.norm_stats[cfg.unnorm_key]
    save("obs_full_image", obs["full_image"], "sample full_image (agentview), HWC uint8 RGB, as given", "u8")
    save("obs_wrist_image", obs["wrist_image"], "sample wrist_image, HWC uint8 RGB, as given", "u8")
    save("images", r["images"], "after prepare_images_for_vla: [primary, wrist] center-cropped (crop_scale 0.9, "
                                "tf.image.crop_and_resize bilinear back to 224), HWC uint8 RGB", "u8")
    save("state", obs["state"], "sample state (8, float64 in the pkl): eef pos 3, axis-angle 3, gripper qpos 2")
    save("pixel_values", cap["pixel_values"][0][0], "processor output, [primary: DINOv2 RGB (ImageNet mean/std, "
         "bf16-rounded), SigLIP RGB (mean 0.5 std 0.5); wrist: same] = 12 x 224 x 224, CHW")
    save("input_ids", ids_full[:L], f"Qwen2 tokenizer ids of the chat prompt (L = {L}; no BOS)", "i32")
    save("llm_input_ids", ids_full, "input_ids + 64 ActionQuery placeholders (id 1) + stop (id 2), before the "
                                    "512 vision tokens are inserted after position 0", "i32")
    for k in (0, 1):
        img = ("primary", "wrist")[k]
        save(f"dinov2_{k}", cap["dinov2"][k][0], f"{img} image: DINOv2 block index 22 output (no final norm), "
                                                  "cls + 4 registers dropped (get_intermediate_layers n={22})")
        save(f"siglip_{k}", cap["siglip"][k][0], f"{img} image: SigLIP block index 25 output (no final norm)")
    save("vision_patches", cap["vision_patches"][0][0], "projector input: per image cat[DINOv2, SigLIP] channels, "
                                                        "images [primary 256, wrist 256]")
    save("projector", cap["projector"][0][0], "projector output fc1 -> GELU -> fc2 -> GELU -> fc3 (512 vision tokens)")
    save("llm_inputs_embeds", cap["llm_inputs_embeds"][0][0],
         f"LLM inputs_embeds [S={S}]: pos 0 = embed(<|im_start|>), 1..512 = projector, 513..{L + 511} = prompt "
         f"tokens 1..L-1, {L + 512}..{L + 575} = action_queries.weight, {L + 576} = embed(stop id 2)")
    for j in range(25):
        save(f"llm_hidden_{j:02d}", hidden[j],
             "hidden_states[0] = inputs_embeds" if j == 0 else
             "hidden_states[24] = layer 23 output AFTER the final RMSNorm" if j == 24 else
             f"hidden_states[{j}] = decoder layer {j - 1} output (raw residual stream)")
    save("llm_last_layer_prenorm", cap["llm_last_layer_prenorm"][0][0],
         "decoder layer 23 output before the final RMSNorm (hidden_states[24] = norm of this)")
    save("policy_h_task", h_t[1:], "h_t read by block i = hidden_states[i+1][0:512] (<|im_start|> + vision 0..510)")
    save("policy_h_adapter", h_a[1:], f"h_a read by block i = hidden_states[i+1][{aq0}:{aq1}] (last prompt token "
                                      "+ ActionQuery 0..62)")
    save("proprio_norm", r["proprio_norm"], "normalize_proprio(state): clip(2(x-q01)/(q99-q01+1e-8)-1, -1, 1)")
    save("proprio_p", cap["proprio_p"][0][0], "proprio projector output p (fc1 -> GELU -> fc2), the extra adapter key")
    save("policy_x_in", cap["policy_in_00"][0][0], "policy block 0 input x = ReLU(fc1(LN1(zeros[8, 6272]))): the "
                                                   "same row 8 times")
    for i in range(24):
        save(f"policy_block_{i:02d}", cap[f"policy_block_{i:02d}"][0][0], f"policy block {i} output x")
    save("policy_actions_norm", cap["policy_actions_norm"][0][0], "fc2(LN2(x)): normalized actions [-1, 1] scale")
    blk0 = head.model.mlp_resnet_blocks[0]
    cos, sin = blk0.rope(seq_len=512, device=torch.device("cpu"), dtype=torch.float32)
    for blk in head.model.mlp_resnet_blocks:
        c8, s8 = blk.rope(seq_len=8, device=torch.device("cpu"), dtype=torch.float32)
        assert torch.equal(c8, cos[:8]) and torch.equal(s8, sin[:8])
    save("rope_cos", cos, "Pro policy RoPE cos for positions 0..511, head dim 112: cat([freqs, freqs]), "
                          "inv_freq = 1e4^(-arange(0,112,2)/112); q/k_self use rows 0..7, k_adapter 0..64, k_task 0..511")
    save("rope_sin", sin, "Pro policy RoPE sin (as rope_cos). rotate_half pairs INTERLEAVED elements: "
                          "stack(-x[1::2], x[::2]) -> [-x1, x0, -x3, x2, ...]")
    gates = torch.stack([torch.tanh(b.gating_factor.detach())[0] for b in head.model.mlp_resnet_blocks])
    save("policy_gate_tanh", gates, "tanh(gating_factor) per block: multiplies q.k of the task window before /sqrt(112)")
    save("actions", r["actions"], "unnormalized actions (predict_action's output; what get_action returns)")
    save("env_actions", r["env_actions"], "process_action(actions): gripper [0,1] -> [-1,1], sign(), x -1")
    save("action_q01", stats["action"]["q01"], f"{cfg.unnorm_key} action q01")
    save("action_q99", stats["action"]["q99"], f"{cfg.unnorm_key} action q99")
    save("action_mask", stats["action"]["mask"], "1 = unnormalize, 0 = pass through (gripper)", "u8")
    save("proprio_q01", stats["proprio"]["q01"], f"{cfg.unnorm_key} proprio q01")
    save("proprio_q99", stats["proprio"]["q99"], f"{cfg.unnorm_key} proprio q99")
    save("proprio_mask", stats["proprio"].get("mask", np.ones(8, bool)),
         "no mask in the stats: normalize_proprio defaults to all ones", "u8")
    if bf is not None:
        save("actions_bf16", bf["actions"], "unnormalized actions of the official bf16 run (as released), on CPU")
        save("actions_norm_bf16", bf["actions_norm"], "normalized actions of the official bf16 run")

    # ------------------------------------------------------------------------------------------------ numerics
    an = cap["policy_actions_norm"][0][0]
    numerics = {"action_rows": {
        "policy_x_in_max_row_diff": float(np.abs(cap["policy_in_00"][0][0] - cap["policy_in_00"][0][0][:1]).max()),
        "block0_out_max_row_diff": float(np.abs(cap["policy_block_00"][0][0] - cap["policy_block_00"][0][0][:1]).max()),
        "actions_norm_max_row_diff": float(np.abs(an - an[:1]).max()),
        "actions_norm_row_minus_row0": (an - an[:1]).tolist()}}
    comp = {"dinov2": "vision_backbone.featurizer", "siglip": "vision_backbone.fused_featurizer",
            "projector": "projector", "llm": "language_model", "policy": "action_head",
            "proprio_projector": "proprio_projector"}
    per = {}
    for cname, prefix in comp.items():
        best = max(((v, n, k) for n, s in rec.stats.items() if n.startswith(prefix) for k, v in s.items()),
                   default=(0.0, None, None))
        per[cname] = {"max_abs": best[0], "where": f"{best[1]} ({best[2]}put)"}
    numerics["max_abs_by_component"] = per
    numerics["over_30000"] = {f"{n} ({k}put)": v for n, s in rec.stats.items() for k, v in s.items() if v > 30000}
    numerics["top_modules_by_component"] = {
        cname: sorted(([f"{n} ({k}put)", v] for n, s in rec.stats.items() if n.startswith(prefix)
                       for k, v in s.items()), key=lambda t: -t[1])[:12] for cname, prefix in comp.items()}
    numerics["all_modules_max_abs"] = rec.stats
    numerics["over_10000"] = {f"{n} ({k}put)": v for n, s in rec.stats.items() for k, v in s.items() if v > 10000}
    llm_taps = []
    for j in range(25):
        h = np.abs(hidden[j])
        p, c = np.unravel_index(int(h.argmax()), h.shape)
        llm_taps.append({"j": j, "max_abs": float(h.max()), "pos": int(p), "ch": int(c),
                         "max_abs_excl_pos0": float(h[1:].max()), "task_window": float(h[:512].max()),
                         "aq_window": float(h[aq0:aq1].max())})
    numerics["llm_hidden_states"] = llm_taps
    for tag, vit in (("dinov2", "featurizer"), ("siglip", "fused_featurizer")):
        n_blocks = len(getattr(vla.vision_backbone, vit).blocks)
        numerics[f"{tag}_block_out_max_abs"] = [rec.stats[f"vision_backbone.{vit}.blocks.{i}"]["out"]
                                                for i in range(n_blocks)]
    lg = rec.logits

    numerics["attention_logits"] = {
        "dinov2": worst(lg, "dinov2."), "siglip": worst(lg, "siglip."), "llm": worst(lg, "llm."),
        **{f"policy_{seg}": worst(lg, "policy.", seg) for seg in ("self", "adapter", "task", "task_ungated")},
        "note": "argmax_abs_head_q_k: LLM q/k are sequence positions (S); policy q = action row 0..7, k = row of "
                "that key segment (self 0..7, adapter 0..64 with p = 64, task 0..511); ViT k/q = token index",
        "all": lg}
    numerics["policy_softmax_mass"] = rec.mass
    numerics["fp32_dtypes_seen"] = sorted(rec.dtypes)
    if bf is not None:
        def rel(x, y):
            return float(np.linalg.norm(x - y) / max(np.linalg.norm(y), 1e-30))
        numerics["bf16_vs_fp32"] = {
            "bf16_run_param_dtype": bf["dtype"],
            "actions_max_abs_diff": float(np.abs(bf["actions"] - r["actions"]).max()),
            "actions_max_abs_diff_per_dim": np.abs(bf["actions"] - r["actions"]).max(0).tolist(),
            "actions_norm_max_abs_diff": float(np.abs(bf["actions_norm"] - an).max()),
            "actions_norm_rel_l2": rel(bf["actions_norm"], an),
            "env_actions_gripper_equal": bool(np.array_equal(bf["env_actions"][:, -1], r["env_actions"][:, -1])),
            "projector_rel_l2": rel(bf["projector"], cap["projector"][0][0]),
            "llm_hidden_rel_l2": [rel(bf["hidden"][j][0], hidden[j]) for j in range(25)],
            "policy_block_rel_l2": [rel(bf["policy_blocks"][i], cap[f"policy_block_{i:02d}"][0][0]) for i in range(24)],
            "time_get_action_s": bf["t_run"]}
    numerics["time_get_action_fp32_with_hooks_s"] = r["t_run"]

    proc = r["processor"].image_processor
    meta = {
        "model": HF_REPO, "hf_revision": REV_HF, "code": GH_REPO, "code_revision": REV_GH,
        "task": task, "prompt": prompt, "L": L, "S": S, "unnorm_key": cfg.unnorm_key,
        "windows": {"task": [0, 512], "action_queries": [aq0, aq1],
                    "note": "block i (0..23) reads hidden_states[i+1] at both windows; hidden_states[0] is unused"},
        "layout": {"im_start": 0, "vision_primary": [1, 257], "vision_wrist": [257, 513],
                   "prompt_tokens_1_to_L-1": [513, L + 512], "action_queries": [L + 512, L + 576], "stop": L + 576},
        "inputs": f"{SAMPLE.relative_to(B)}: full_image + wrist_image (224x224x3 uint8), state (8 float64), "
                  "task_description; center_crop=True, num_images_in_input=2",
        "state_float64": obs["state"].tolist(),
        "action_stats": {k: stats["action"][k] for k in ("q01", "q99", "mask")},
        "proprio_stats": {k: stats["proprio"][k] for k in ("q01", "q99")},
        "dinov2_siglip_normalize": proc.tvf_normalize_params,
        "attn_implementation": vla.language_model.config._attn_implementation,
        "llm_attention_class": type(vla.language_model.model.layers[0].self_attn).__name__,
        "versions": {"python": platform.python_version(), "torch": torch.__version__,
                     **{m: __import__(m).__version__ for m in ("transformers", "tokenizers", "timm", "tensorflow",
                                                               "numpy")}},
        "threads": torch.get_num_threads(),
        "patches": PATCHES,
        "notes": [
            "Files are raw little-endian, C order, no header; shapes drop the batch dim (batch is 1).",
            "Everything is the fp32 run (weights stored bf16, upcast exactly); *_bf16 files are the as-released run.",
            "LLM: Qwen2 (transformers 4.40.1), causal, RoPE theta 1e6 NeoX half-split, RMSNorm eps 1e-6, no KV cache, "
            "positions 0..S-1. lm_head logits are computed by the official code and unused.",
            "DINOv2 / SigLIP run all 24 / 27 blocks (timm 0.9.10 _intermediate_layers) and keep block 22 / 25.",
            "Policy block (Pro): s = cat[q.k_self, q.k_adapter, tanh(g) q.k_task] / sqrt(112), one softmax over "
            "8 + 65 + 512 keys; x = ReLU(Linear(LN(o_proj(s.V) + x))).",
        ],
        "checks": checks,
        "numerics": numerics,
        "tensors": tensors,
    }
    (out / "meta.json").write_text(json.dumps(meta, indent=1))

    if a.export:
        export(vla, head, proj, rec)

    # tidy the loader's redundant config.json backups (byte-identical copies of the current config.json)
    cur = (HF / "config.json").read_bytes()
    for bk in HF.glob("config.json.back.*"):  # (copy2 keeps the source's mtime, so compare contents only)
        if bk.read_bytes() == cur:
            bk.unlink()

    np.set_printoptions(precision=5, suppress=True, linewidth=140)
    print(f"\nL = {L}, S = {S}; windows task [0, 512), ActionQuery [{aq0}, {aq1})")
    print("normalized actions (fp32):\n", an)
    print(f"unnormalized actions (fp32, {cfg.unnorm_key}):\n", r["actions"])
    if bf is not None:
        print("unnormalized actions (bf16, as released):\n", bf["actions"])
        d = numerics["bf16_vs_fp32"]
        print(f"bf16 vs fp32: actions max |diff| {d['actions_max_abs_diff']:.4g}, "
              f"normalized {d['actions_norm_max_abs_diff']:.4g}"
              f" (rel L2 {d['actions_norm_rel_l2']:.3g}); gripper signs equal: {d['env_actions_gripper_equal']}")
    print("checks:", json.dumps(checks))
    print("max |x| by component:", json.dumps(per, indent=1))
    print("over 30000:", numerics["over_30000"])
    print("LLM hidden max |h| per j (pos, ch):", [(t["j"], round(t["max_abs"], 1), t["pos"], t["ch"]) for t in llm_taps])
    print("attention logits:", json.dumps({k: v for k, v in numerics["attention_logits"].items() if k != "all"}))
    print("tanh(gate):", gates.numpy())
    print("action rows:", {k: v for k, v in numerics["action_rows"].items() if k != "actions_norm_row_minus_row0"})
    print("wrote", len(tensors), "tensors to", out)


def worst(lg, prefix, seg=None):
    """The attention-logit record with the largest |logit| among keys starting with prefix (and ending in seg)."""
    items = [(max(abs(v["max"]), abs(v["min"])), k) for k, v in lg.items()
             if k.startswith(prefix) and (seg is None or k.split(".")[-1] == seg)]
    m, k = max(items)
    return {"max_abs": m, "where": k, **lg[k]}


def skip_reason(name):
    """Why a checkpoint tensor is left out of the export (None = the inference path uses it)."""
    vb = "vision_backbone."
    if ".film_gen." in name:
        return "Pro block film_gen: constructed, never called (its use is commented out in forward)"
    if name.startswith(vb + "fused_featurizer.attn_pool."):
        return "SigLIP MAP head: never called (features come from get_intermediate_layers)"
    if name.startswith((vb + "featurizer.norm.", vb + "fused_featurizer.norm.")):
        return "ViT final norm: never called (get_intermediate_layers norm=False)"
    if name.startswith(vb + "featurizer.blocks.23."):
        return "DINOv2 last block: computed by timm and discarded (the tap is block 22)"
    if name.startswith(vb + "fused_featurizer.blocks.26."):
        return "SigLIP last block: computed by timm and discarded (the tap is block 25)"
    return None


def export(vla, head, proj, rec):
    """build/vla_adapter/vla_adapter.safetensors: every tensor the inference path uses, as stored (BF16, (out, in))."""
    import torch
    from safetensors import safe_open
    from safetensors.torch import save_file

    def tensors(fname):
        if fname.endswith(".safetensors"):
            f = safe_open(str(HF / fname), "pt")
            return ((k, f.get_tensor(k)) for k in f.keys())
        sd_ = torch.load(HF / fname, map_location="cpu", weights_only=True)
        return (((k[7:] if k.startswith("module.") else k), v) for k, v in sd_.items())

    files = [("", "model.safetensors", vla.state_dict()),
             ("action_head.", "action_head--checkpoint.pt", head.state_dict()),
             ("proprio_projector.", "proprio_projector--checkpoint.pt", proj.state_dict())]
    sd, kept, skipped = {}, [], []
    for prefix, fname, model_sd in files:
        for k, t in tensors(fname):
            name = prefix + k
            module = name.rsplit(".", 1)[0]
            why = skip_reason(name)
            if why is not None:
                ran = module in rec.called
                assert ran == (".blocks." in name), f"{name}: module ran = {ran}"
                skipped.append(f"{name}\t{list(t.shape)}\t{str(t.dtype).replace('torch.', '')}\t{why}")
                continue
            assert module in rec.called or name == "action_queries.weight", f"{name}: its module never ran"
            assert torch.equal(t.float(), model_sd[k]), f"{name} differs from the loaded fp32 model"
            sd[name] = t.contiguous()
            kept.append(f"{name}\t{list(t.shape)}\t{str(t.dtype).replace('torch.', '')}")
    # film_gen 24 x (w, b) + attn_pool 13 + final norms 2 x 2 + DINOv2 block 23 (14) + SigLIP block 26 (12)
    assert len(skipped) == 48 + 13 + 4 + 14 + 12, len(skipped)
    lm = vla.language_model
    assert lm.lm_head.weight.data_ptr() == lm.model.embed_tokens.weight.data_ptr()  # tied: no separate lm_head tensor
    save_file(sd, str(B / "vla_adapter.safetensors"),
              metadata={"source": f"{HF_REPO}@{REV_HF}", "code": f"{GH_REPO}@{REV_GH}"})
    n = sum(t.numel() for t in sd.values())
    head_lines = [
        f"# {len(sd)} tensors, {n:,} params, dtype as stored (BF16); Linear weights (out, in) as in PyTorch.",
        "# VLM names as in model.safetensors; action_head.* = action_head--checkpoint.pt without 'module.'; "
        "proprio_projector.* likewise.",
        "# Every kept tensor equals the loaded fp32 model's (upcast) and its module ran in the fp32 reference run;",
        "# action_queries.weight is read directly (.weight), not called. lm_head is tied to embed_tokens (no tensor).",
        "# Not stored anywhere: the policy RoPE inv_freq (non-persistent buffer; see ref/rope_cos.f32).",
        "# name\tshape\tdtype",
    ]
    lines = head_lines + kept + [f"# skipped ({len(skipped)} tensors): name\tshape\tdtype\treason"] + \
        [f"# {s}" for s in skipped]
    (B / "export_names.txt").write_text("\n".join(lines) + "\n")
    print(f"wrote {B / 'vla_adapter.safetensors'} ({len(sd)} tensors, {n:,} params); skipped {len(skipped)}")


if __name__ == "__main__":
    main()
