"""VLA-JEPA (ginwind/VLA-JEPA, LIBERO checkpoint) in fp32 on the Mac's CPU: the reference the GPU/NPU ports are checked
against. It runs the OFFICIAL inference path from the repo's own code (ginwind/VLA-JEPA at a pinned commit, cloned to
build/vla_jepa/src), the way examples/LIBERO/eval_libero.sh drives it:

  deployment/model_server/server_policy.py: baseframework.from_pretrained(VLA-JEPA-LIBERO.pt) -> VLA_JEPA (Qwen3-VL-2B
  _QWen3_VL_Interface, FlowmatchingActionHead, V-JEPA2 encoder + predictor) -> strict load_state_dict -> .eval();
  examples/LIBERO/model2libero_interface.py M1Inference.step (cv2 INTER_AREA resize, request dict) -> msgpack ->
  WebsocketPolicyServer._route_message (image_tools.to_pil_preserve) -> VLA_JEPA.predict_action
  (build_qwenvl_inputs -> Qwen3VLForConditionalGeneration -> hidden_states[-1] at the 32 <|embodied_action|> tokens ->
  FlowmatchingActionHead.predict_action, 4 Euler steps) -> msgpack -> M1Inference.unnormalize_actions (min/max).

and writes every stage's tensors to build/vla_jepa/ref as raw little-endian .f32 / .i32 / .u8 files plus meta.json:

  build/vla_jepa/venv/bin/python vla_jepa/reference.py            # writes build/vla_jepa/ref (fp32 sdpa, eager + bf16)
  build/vla_jepa/venv/bin/python vla_jepa/reference.py --export   # + vla_jepa.safetensors, export_names.txt,
                                                                  #   pt_offsets.txt
  build/vla_jepa/venv/bin/python vla_jepa/reference.py --no-bf16 --no-eager   # the fp32 sdpa run only

About 1.5 minutes on this M4 with --export (each model build ~25 s, the fp32 chunk 4 s with every tap on, the eager
rerun 3 s, the bf16 repeat 8 s, the export ~15 s); peak footprint 10.3 GB (10.7 GB RSS counting the mmap'd .pt). The
fp32 outputs are bit-identical from run to run.

Setup (once): the venv is Python 3.10 with vla_jepa/requirements-reference.txt (transformers 4.57.0, torch 2.6.0 CPU,
torchvision 0.21.0, accelerate 1.5.2, numpy 1.26.4 as the repo pins them; diffusers 0.36.0 and the other unpinned
packages resolved with --exclude-newer 2026-02-12, the day the checkpoints were published). The script clones the code
and downloads what it needs at the pinned revisions if it is missing (build/vla_jepa/src, build/vla_jepa/hf):
  - ginwind/VLA-JEPA @ REV_HF, folder LIBERO/: config.yaml, config.json, dataset_statistics.json, summary.jsonl and
    checkpoints/VLA-JEPA-LIBERO.pt (6,163,579,855 bytes, sha256-checked on download), in the <run>/checkpoints/<x>.pt
    layout read_mode_config expects;
  - Qwen/Qwen3-VL-2B-Instruct @ REV_QWEN: config, generation config, chat template, tokenizer, image and video
    processor configs. Its 4.26 GB model.safetensors is NOT downloaded: a 0-tensor placeholder stands in for it.
    from_pretrained then allocates the parameters and initializes them randomly, and the strict load_state_dict of the
    VLA-JEPA checkpoint replaces every one of them (checked below: every state_dict entry equals the checkpoint's);
  - facebook/vjepa2-vitl-fpc64-256 @ REV_VJ: config.json and video_preprocessor_config.json only (patch 6).
HF_HUB_OFFLINE is set; HF_HUB_CACHE, HF_MODULES_CACHE and MPLCONFIGDIR point into build/vla_jepa.

Input (no simulator): the LIBERO-spatial sample observation VLA-Adapter ships (OpenHelix-Team/VLA-Adapter @ REV_VA
experiments/robot/libero/sample_libero_spatial_observation.pkl, copied from build/vla_adapter/src or fetched from the
raw URL, sha256-checked, read with an unpickler that only admits numpy's array rebuild). full_image and wrist_image are
224x224x3 uint8 RGB, already rotated 180 degrees exactly as eval_libero.py does (obs[...][::-1, ::-1]); state is the 8-D
eef_pos(3) + axis-angle(3) + gripper_qpos(2) float64 vector eval_libero.py builds; the prompt is the task string. They
are fed the way the LIBERO client does:
  eval_libero.py obs_input = {"images": [agentview, wrist], "task_description": task, "step": 0,
  "state": state[None] (1, 8) float64}  (with_state "true", as eval_libero.sh sets) ->
  M1Inference.step: each view cv2.resize(..., (224, 224), INTER_AREA) (the identity at 224: checked bit-exactly; the
  real env renders 256x256, which the client would downsample) -> request {"batch_images": [[agentview, wrist]],
  "instructions": [task], "unnorm_key": None, "do_sample": False, "use_ddim": True, "num_ddim_steps": 10,
  "state": [(1, 8) float64]} -> msgpack_numpy round trip -> _route_message: to_pil_preserve (uint8 HWC -> PIL RGB) ->
  predict_action(**payload) (the extra keys land in **kwargs). The state reaches the action head RAW (not normalized):
  np.array([...]) (1, 1, 8) float64 -> torch -> last_hidden.dtype (fp32 here, bf16 in the bf16 run) -> state_encoder.
The processor (Qwen2VLImageProcessorFast, as preprocessor_config.json names it) resizes each 224x224 view to 256x256
(smart_resize with factor 32 and min_pixels 65536; torchvision bicubic, antialias, on uint8, so the output is uint8),
normalizes to (x - 127.5) / 127.5, duplicates it into 2 temporal frames and flattens 16x16 patches in 2x2 merge order:
pixel_values [512, 1536], image_grid_thw [[1, 16, 16]] x 2, 64 LLM tokens per view.
The prompt is the config's CoT_prompt in a single user turn (chat template, add_generation_prompt), S = 234 tokens.

Runtime patches (nothing in build/vla_jepa/src or in site-packages is edited; module globals are rebound):
  1. device: QWen3.py's Qwen3VLForConditionalGeneration.from_pretrained(device_map="cuda") gets device_map="cpu"
     (a shim object stands in for the class name inside QWen3.py and forwards to the real from_pretrained). Everything
     is built on the CPU, so server_policy.py's vla.to(cuda:<n>) is replaced by no move (the meta modules of patch 6
     could not be moved anyway); its .eval() is kept (it turns the DiT's dropout 0.2 off).
  2. attention: the same shim passes attn_implementation="sdpa" instead of "flash_attention_2". sdpa is the reference.
     The script then switches the loaded model to "eager" (set_attn_implementation) and reruns the whole request with
     the same seed; the eager_* files and checks show the difference (fp32 rounding only: with one unpadded sequence
     the ViT's per-image attention, FA2's cu_seqlens varlen and SDPA's per-chunk path are the same math, and the LLM is
     plain causal attention in all three).
  3. autocast: torch.autocast("cuda", ...) in VLA_JEPA.predict_action (bf16 around the VLM, fp32 around the action
     head) and in _QWen3_VL_Interface.forward (bf16) is a nullcontext in the fp32 run (`torch` inside VLA_JEPA.py and
     QWen3.py is a proxy module whose .autocast is replaced; on a CUDA-less torch these regions would disable
     themselves with a warning anyway).
  4. dtype: the shim passes dtype=torch.float32 instead of torch.bfloat16 (fp32 run only). The checkpoint's bf16 values
     are upcast exactly. The action head is built in the default fp32 already. Downstream bf16 sites follow from it:
     the state cast and the noise's dtype (randn(dtype=vl_embs.dtype)) are fp32.
  5. load: torch.load inside base_framework.py gets mmap=True (weights_only=True is torch 2.6's default anyway), so
     the 6.16 GB state dict is file-backed instead of anonymous memory. Same tensors.
  6. training-only modules on the meta device: VLA_JEPA.__init__ builds vj_encoder with
     AutoModel.from_pretrained(V-JEPA2 ViT-L) and vj_predictor (VisionTransformerPredictorAC). Inside VLA_JEPA.py,
     AutoModel is replaced by a shim that builds the same model from its config, and both it and
     VisionTransformerPredictorAC are constructed under accelerate.init_empty_weights() (parameters on the meta
     device, the few buffers stay on the CPU). Their 487.6 M checkpoint parameters (743 tensors) are
     accepted by the strict load (same keys and shapes) but copied nowhere (torch's "copy into a meta parameter is a
     no-op" warning, silenced). predict_action never calls them: any use of a meta tensor would raise.
  7. config paths: read_mode_config (as imported by base_framework) is wrapped to point framework.qwenvl.base_vlm and
     framework.vj2_model.base_encoder (absolute paths on the authors' machine) at the local snapshots.
lm_head is not a placeholder: Qwen3-VL-2B ties it to embed_tokens (config tie_word_embeddings), so it is the same
Parameter and costs no memory. The checkpoint stores the two as separate storages; the strict load copies embed_tokens
first and lm_head last into the shared Parameter (module order). Their values are identical (checked), so it does not
matter which one the model ends up holding.

What predict_action actually reads: qwenvl_outputs.hidden_states[-1]. In transformers 4.57 the hidden_states tuple is
filled by the check_model_inputs decorator, and only for outputs that have a last_hidden_state field is its last entry
replaced by the post-norm state. Qwen3VLCausalLMOutputWithPast has no such field, so hidden_states (29 entries:
input_embeds, then the 28 decoder-layer outputs) ends with decoder layer 27's RAW output: the 32 embodied-action rows
the action head attends to are taken BEFORE the final RMSNorm (checked bitwise: they equal llm_layer27, not
llm_final_norm). The final norm and lm_head (logits [1, 234, 151936]) still run, but only feed the discarded logits.
Training (VLA_JEPA.forward) reads the same hidden_states[-1], so this is what the model was trained on.

Recording: forward hooks and pre-hooks on the official modules (they copy tensors; the attention-logit and numerics
diagnostics recompute q.k from the modules' own weights inside the hooks and never feed back), an in-process client
that replaces only the websocket transport, and a TorchFunctionMode that records the random draws (the head's
torch.randn is the only one; noise.f32), and in the eager rerun the parameters every torch op reads (for --export).

The bf16 repeat ("as released": eval_libero.sh starts the server with --use_bf16): a second model built without
patch 4 (Qwen3-VL loaded in bf16 as QWen3.py does), then server_policy.py's vla.to(torch.bfloat16) (every parameter
AND floating buffer, so the ViT's and LLM's rotary inv_freq become bf16), sdpa, and the two CUDA autocast regions
emulated on the CPU: autocast("cuda", bf16) -> torch.autocast("cpu", bf16); autocast("cuda", float32) -> a
TorchFunctionMode that casts the floating inputs of linear / matmul / bmm / baddbmm / addmm / sdpa / layer_norm /
softmax to fp32, which is what CUDA's float32 autocast does to those ops (CPU autocast rejects float32 and would leave
the head in bf16; the head's output would then be bf16 and predict_action's .numpy() would fail, as PR #40 reports).
Its randn is replaced by the fp32 run's noise rounded to bf16 (the dtype it is drawn in), so both runs start from the
same x0. CPU and CUDA kernels (SDPA vs flash-attn, bf16 GEMMs) accumulate differently, so this measures the size of
the bf16 effect, not the CUDA output bit for bit.

--export writes build/vla_jepa/vla_jepa.safetensors: the checkpoint tensors the official path reads (passed to a torch
op in the eager rerun), bf16 as stored, under the checkpoint's own names (qwen_vl_interface.model.model.{visual,
language_model}.*, action_model.*), PyTorch (out, in) layouts; export_names.txt lists them and the skipped ones;
pt_offsets.txt gives "name offset" for each exported tensor: its byte offset inside the official VLA-JEPA-LIBERO.pt
(zip local file header of <archive>/data/<storage key> + 30 + name and extra lengths, plus storage_offset * 2; every
entry is ZIP_STORED and every tensor contiguous; checked by reading the bytes back and comparing with the export).
"""

import argparse
import collections
import contextlib
import ctypes
import gc
import hashlib
import io
import json
import math
import os
import pathlib
import pickle
import shutil
import struct
import subprocess
import sys
import time
import types
import urllib.request
import warnings
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
B = ROOT / "build/vla_jepa"
SRC = B / "src"
HF = B / "hf"
RUN = HF / "VLA-JEPA/LIBERO"
CKPT = RUN / "checkpoints/VLA-JEPA-LIBERO.pt"
QWEN = HF / "Qwen3-VL-2B-Instruct"  # the directory name must contain "Qwen3-VL" (get_vlm_model dispatches on it)
VJ = HF / "vjepa2-vitl-fpc64-256"
REV_GH = "ec907778b4af46a45742baf5ebfb2e055560346e"  # ginwind/VLA-JEPA (code)
REV_HF = "db32b4a4457c39921869f667ac76cf8a8fc39da8"  # ginwind/VLA-JEPA (weights)
REV_QWEN = "89644892e4d85e24eaac8bacfd4f463576704203"  # Qwen/Qwen3-VL-2B-Instruct
REV_VJ = "b3c1679b7c34d3255ef3547f27c7b226aefab26f"  # facebook/vjepa2-vitl-fpc64-256
REV_VA = "23fa0c9c159e2aa04341cdd3e924f44061311060"  # OpenHelix-Team/VLA-Adapter (sample observation)
CKPT_SHA256 = "b46c8f268905d50944aea9dc0a087400cdfbc401a8ec9ca22921fa91c0dcb841"
CKPT_SIZE = 6163579855
SAMPLE_SHA256 = "326db6c78dd0a9d91c11f05af03b93fa3095338ee3cb5a5eb15adf3d87eb0109"
SAMPLE_PATH = "experiments/robot/libero/sample_libero_spatial_observation.pkl"
SAMPLE = B / "inputs/sample_libero_spatial_observation.pkl"
RUN_FILES = ["config.yaml", "config.json", "dataset_statistics.json", "summary.jsonl"]
QWEN_FILES = ["chat_template.json", "config.json", "generation_config.json", "merges.txt", "preprocessor_config.json",
              "tokenizer.json", "tokenizer_config.json", "video_preprocessor_config.json", "vocab.json"]
VJ_FILES = ["config.json", "video_preprocessor_config.json"]
SEED = 0
QWEN_PREFIX = "qwen_vl_interface.model."

os.environ.setdefault("HF_HUB_OFFLINE", "1")  # every path below is local
os.environ.setdefault("HF_HUB_CACHE", str(HF / "hub"))
os.environ.setdefault("HF_MODULES_CACHE", str(HF / "modules"))
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
os.environ.setdefault("MPLCONFIGDIR", str(B / "mplconfig"))  # model2libero_interface imports matplotlib
os.environ.setdefault("MPLBACKEND", "Agg")
sys.path.insert(0, str(SRC))

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
    with urllib.request.urlopen(url) as r, open(tmp, "wb") as f:
        shutil.copyfileobj(r, f, 1 << 24)
    if sha is not None:
        assert _sha256(tmp) == sha, f"sha256 mismatch for {url}"
    tmp.rename(dst)


def fetch():
    """Clone VLA-JEPA at REV_GH, download the LIBERO run folder and the base models' configs/tokenizer, write the
    Qwen3-VL weight placeholder, and get the sample observation, if any of it is missing."""
    if not (SRC / "starVLA/model/framework/VLA_JEPA.py").exists():
        subprocess.run(["git", "clone", "-q", "https://github.com/ginwind/VLA-JEPA.git", str(SRC)], check=True)
        subprocess.run(["git", "-C", str(SRC), "checkout", "-q", REV_GH], check=True)
    head = subprocess.run(["git", "-C", str(SRC), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
    assert head == REV_GH, f"build/vla_jepa/src is at {head}, expected {REV_GH}"
    hf = "https://huggingface.co/{}/resolve/{}/{}"
    for f in RUN_FILES:
        _get(hf.format("ginwind/VLA-JEPA", REV_HF, "LIBERO/" + f), RUN / f)
    _get(hf.format("ginwind/VLA-JEPA", REV_HF, "LIBERO/checkpoints/VLA-JEPA-LIBERO.pt"), CKPT, CKPT_SHA256)
    assert CKPT.stat().st_size == CKPT_SIZE, "VLA-JEPA-LIBERO.pt has the wrong size"
    for f in QWEN_FILES:
        _get(hf.format("Qwen/Qwen3-VL-2B-Instruct", REV_QWEN, f), QWEN / f)
    for f in VJ_FILES:
        _get(hf.format("facebook/vjepa2-vitl-fpc64-256", REV_VJ, f), VJ / f)
    if not (QWEN / "model.safetensors").exists():
        from safetensors.torch import save_file
        save_file({}, str(QWEN / "model.safetensors"),
                  metadata={"format": "pt", "note": "0-tensor placeholder written by vla_jepa/reference.py; every "
                                                    "weight comes from VLA-JEPA-LIBERO.pt's strict load_state_dict"})
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


# ---------------------------------------------------------------------------------------------------------- memory
def footprint():
    """(current, lifetime peak) phys_footprint of this process in GB = 1e9 bytes (proc_pid_rusage RUSAGE_INFO_V4; the
    peak is what /usr/bin/time -l calls "peak memory footprint")."""
    try:
        buf = (ctypes.c_uint64 * 48)()
        libc = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
        if libc.proc_pid_rusage(os.getpid(), 4, ctypes.byref(buf)) != 0:
            return None
        # rusage_info_v4: 16-byte uuid, then uint64 fields; ri_phys_footprint is field 7, lifetime max field 28
        return round(buf[2 + 7] / 1e9, 2), round(buf[2 + 28] / 1e9, 2)
    except Exception:
        return None


# ---------------------------------------------------------------------------------------------------------- patches
class _TorchProxy(types.ModuleType):
    """Stands in for `torch` inside one module: only the attributes in `over` differ."""

    def __init__(self, over):
        super().__init__("torch")
        self.over = over

    def __getattr__(self, name):
        over = self.__dict__["over"]
        return over[name] if name in over else getattr(torch, name)


AUTOCAST_CALLS = []
CPU_FLOAT_OPS = {"linear", "matmul", "bmm", "baddbmm", "addmm", "mm", "scaled_dot_product_attention", "layer_norm",
                 "softmax", "log_softmax"}


class CudaFp32Autocast(TorchFunctionMode):
    """bf16 run only: what torch.autocast("cuda", dtype=torch.float32) does to the ops the action head uses (CUDA casts
    the floating inputs of its lower-precision and fp32 op lists to the autocast dtype; the others run as they are)."""

    def __torch_function__(self, func, types_, args=(), kwargs=None):
        kwargs = kwargs or {}
        if getattr(func, "__name__", "") in CPU_FLOAT_OPS:
            up = lambda x: x.float() if isinstance(x, torch.Tensor) and x.dtype in (torch.bfloat16, torch.float16) else x
            args = tuple(up(a) for a in args)
            kwargs = {k: up(v) for k, v in kwargs.items()}
        return func(*args, **kwargs)


def make_autocast(bf16):
    """Patch 3 (fp32 run: no autocast) and the bf16 run's CPU stand-ins for CUDA autocast."""

    def autocast(device_type, dtype=None, **kw):
        AUTOCAST_CALLS.append((device_type, str(dtype)))
        assert device_type == "cuda", device_type
        if not bf16:
            return contextlib.nullcontext()
        if dtype == torch.bfloat16:
            return torch.autocast("cpu", dtype=torch.bfloat16)
        assert dtype == torch.float32, dtype
        return CudaFp32Autocast()

    return autocast


class _QwenShim:
    """Patches 1, 2 and 4: stands in for Qwen3VLForConditionalGeneration inside QWen3.py."""

    def __init__(self, fp32):
        self.fp32 = fp32
        self.calls = []

    def from_pretrained(self, model_id, **kw):
        from transformers import Qwen3VLForConditionalGeneration
        orig = dict(kw)
        assert kw.get("attn_implementation") == "flash_attention_2" and kw.get("device_map") == "cuda"
        assert kw.get("dtype") == torch.bfloat16
        kw["attn_implementation"] = "sdpa"
        kw["device_map"] = "cpu"
        if self.fp32:
            kw["dtype"] = torch.float32
        self.calls.append({"model_id": str(model_id), "official": {k: str(v) for k, v in orig.items()},
                           "patched": {k: str(v) for k, v in kw.items()}})
        return Qwen3VLForConditionalGeneration.from_pretrained(model_id, **kw)


class _MetaAutoModel:
    """Patch 6: AutoModel inside VLA_JEPA.py; V-JEPA2 is built from its config with its parameters on the meta
    device (accelerate.init_empty_weights)."""

    @staticmethod
    def from_pretrained(path, *a, **kw):
        from accelerate import init_empty_weights
        from transformers import AutoConfig, AutoModel
        cfg = AutoConfig.from_pretrained(path)
        with init_empty_weights():
            return AutoModel.from_config(cfg)


def apply_patches(fp32):
    """Rebind the module globals the official code looks up (patches 1-7). Returns the patched modules."""
    import starVLA.model.framework  # noqa: F401  (auto-imports every framework, registers VLA_JEPA)
    import starVLA.model.framework.VLA_JEPA as vj_mod
    import starVLA.model.framework.base_framework as bf_mod
    import starVLA.model.modules.vlm.QWen3 as q3_mod

    from starVLA.model.tools import FRAMEWORK_REGISTRY
    assert "VLA_JEPA" in FRAMEWORK_REGISTRY._registry
    autocast = make_autocast(bf16=not fp32)
    q3_mod.torch = _TorchProxy({"autocast": autocast})
    vj_mod.torch = _TorchProxy({"autocast": autocast})
    shim = _QwenShim(fp32)
    q3_mod.Qwen3VLForConditionalGeneration = shim
    real_load = torch.load
    bf_mod.torch = _TorchProxy({"load": lambda f, map_location=None, **kw: real_load(
        f, map_location=map_location, mmap=True, weights_only=True)})
    vj_mod.AutoModel = _MetaAutoModel
    real_pred = vj_mod.__dict__.get("_real_VisionTransformerPredictorAC", vj_mod.VisionTransformerPredictorAC)
    vj_mod._real_VisionTransformerPredictorAC = real_pred

    def predictor_on_meta(*a, **kw):
        from accelerate import init_empty_weights
        with init_empty_weights():
            return real_pred(*a, **kw)

    vj_mod.VisionTransformerPredictorAC = predictor_on_meta
    real_read = bf_mod.__dict__.get("_real_read_mode_config", bf_mod.read_mode_config)
    bf_mod._real_read_mode_config = real_read

    def read_mode_config(ckpt):
        cfg, stats = real_read(ckpt)
        cfg["framework"]["qwenvl"]["base_vlm"] = str(QWEN)
        cfg["framework"]["vj2_model"]["base_encoder"] = str(VJ)
        return cfg, stats

    bf_mod.read_mode_config = read_mode_config
    return shim


def build(fp32):
    """server_policy.py main() up to the server: from_pretrained, (--use_bf16: .to(bfloat16)), .eval()."""
    import transformers
    from starVLA.model.framework.base_framework import baseframework

    shim = apply_patches(fp32)
    transformers.logging.set_verbosity_error()  # every Qwen weight is "newly initialized" from the placeholder
    t0 = time.time()
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", message=".*copying from a non-meta parameter.*")
        warnings.filterwarnings("ignore", message=".*TypedStorage is deprecated.*")
        vla = baseframework.from_pretrained(str(CKPT))
    if not fp32:
        vla = vla.to(torch.bfloat16)  # server_policy.py --use_bf16
    vla = vla.eval()  # server_policy.py: vla.to(device).eval() (no device move: patch 1)
    print(f"built VLA_JEPA ({'fp32' if fp32 else 'bf16'}) in {time.time() - t0:.1f} s; footprint (now, peak) GB "
          f"{footprint()}")
    return vla, shim


# ---------------------------------------------------------------------------------------------------------- run
class Recorder(TorchFunctionMode):
    """Records every random draw; optionally the id of every tensor passed to a torch op (to tell which weights the
    path reads) and an injected tensor in place of torch.randn's output (bf16 run)."""

    def __init__(self, track=False, inject=None):
        super().__init__()
        self.draws = []
        self.seen = set() if track else None
        self.inject = inject
        self.cuda = 0

    def _note(self, x):
        if isinstance(x, torch.Tensor):
            self.seen.add(id(x))
        elif isinstance(x, (list, tuple)):
            for y in x:
                self._note(y)

    def __torch_function__(self, func, types_, args=(), kwargs=None):
        kwargs = kwargs or {}
        dev = kwargs.get("device")
        if (isinstance(dev, str) and dev.startswith("cuda")) or (isinstance(dev, torch.device) and dev.type == "cuda"):
            self.cuda += 1
        if self.seen is not None:
            self._note(args)
            self._note(list(kwargs.values()))
        out = func(*args, **kwargs)
        name = getattr(func, "__name__", "")
        if name.startswith("rand") or name in ("normal", "normal_", "bernoulli", "multinomial", "uniform_"):
            self.draws.append((name, out.detach().clone() if isinstance(out, torch.Tensor) else None,
                               {k: str(v) for k, v in kwargs.items()}))
            if name == "randn" and self.inject is not None:
                out = self.inject.to(out.dtype).reshape(out.shape).clone()
        return out


class InProcessClient:
    """Replaces only the websocket transport of WebsocketClientPolicy: the request and the reply go through the same
    msgpack_numpy pack/unpack, and the server side is WebsocketPolicyServer._route_message itself."""
    server = None

    def __init__(self, host="127.0.0.1", port=None, api_key=None):
        from deployment.model_server.tools import msgpack_numpy
        self.mp = msgpack_numpy
        self._packer = msgpack_numpy.Packer()

    def infer(self, obs):
        data = self._packer.pack({"payload": obs, "type": "infer"})  # WebsocketClientPolicy.infer
        msg = self.mp.unpackb(data)  # WebsocketPolicyServer._handler
        ret = self.server._route_message(msg)
        reply = self.mp.Packer().pack(ret)
        out = self.mp.unpackb(reply)  # WebsocketClientPolicy.infer
        if out.get("status") != "ok":
            raise RuntimeError(f"server error: {out}")
        return out


def make_client(vla):
    """eval_libero.py's M1Inference(policy_ckpt_path, host, port, image_size=[224, 224]) with the in-process client."""
    import examples.LIBERO.model2libero_interface as m2l
    from deployment.model_server.tools.websocket_policy_server import WebsocketPolicyServer

    m2l.WebsocketClientPolicy = InProcessClient
    InProcessClient.server = WebsocketPolicyServer(policy=vla, host="0.0.0.0", port=15084,
                                                   metadata={"env": "simpler_env"})
    return m2l.M1Inference(policy_ckpt_path=str(CKPT), host="127.0.0.1", port=15084, image_size=[224, 224])


def infer(client, obs_input, track=False, inject=None):
    """One chunk: eval_libero.py's model.step(**obs_input) at step 0 (seeded). Returns the client's unnormalized
    chunk [7, 7], the server's reply data and the Recorder."""
    rec = Recorder(track=track, inject=inject)
    replies = []
    orig = client.client.infer

    def keep(obs):
        out = orig(obs)
        replies.append(out)
        return out

    client.client.infer = keep
    torch.manual_seed(SEED)
    t0 = time.time()
    try:
        with rec, warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always")
            client.step(**obs_input)
    finally:
        client.client.infer = orig
    dt = time.time() - t0
    for msg in sorted({str(w.message).split("\n")[0][:160] for w in caught}):
        print("  warning:", msg)
    data = replies[0]["data"]
    print(f"  M1Inference.step {dt:.1f} s; draws {[d[0] for d in rec.draws]}; cuda device args {rec.cuda}; "
          f"footprint {footprint()}")
    return np.asarray(client.raw_actions, np.float64), data, rec, dt


class Taps:
    """Forward hooks that copy what the official modules see and produce, plus the numerics survey."""

    def __init__(self, vla):
        self.s = collections.defaultdict(list)
        self.maxabs = {}
        self.vit_logit, self.llm_logit, self.dit_logit = {}, {}, {}
        self.h = []
        qwen = vla.qwen_vl_interface.model
        vis = qwen.model.visual
        lm = qwen.model.language_model
        head = vla.action_model
        dit = head.model
        H, keep = self.h, self.keep

        def qwen_pre(m, a, k):
            for n in ("input_ids", "attention_mask", "pixel_values", "image_grid_thw"):
                keep(n, k[n])
            self.s["output_hidden_states"].append(k.get("output_hidden_states"))

        H.append(qwen.register_forward_pre_hook(qwen_pre, with_kwargs=True))
        H.append(qwen.register_forward_hook(lambda m, a, k, o: self.qwen_out(o), with_kwargs=True))
        H.append(vis.patch_embed.register_forward_hook(lambda m, a, o: keep("vit_patch_embed", o)))
        orig_fpe = vis.fast_pos_embed_interpolate

        def fpe(grid_thw):  # pass-through wrapper on the instance (removed in remove())
            out = orig_fpe(grid_thw)
            keep("vit_pos_embed", out)
            return out

        vis.fast_pos_embed_interpolate = fpe
        self.undo = [lambda: vis.__dict__.pop("fast_pos_embed_interpolate", None)]

        def blk0_pre(m, a, k):
            keep("vit_block0_in", a[0])
            keep("vit_rope_cos", k["position_embeddings"][0])
            keep("vit_rope_sin", k["position_embeddings"][1])
            keep("vit_cu_seqlens", k["cu_seqlens"])

        H.append(vis.blocks[0].register_forward_pre_hook(blk0_pre, with_kwargs=True))
        for i, blk in enumerate(vis.blocks):
            H.append(blk.register_forward_hook(lambda m, a, o, i=i: keep(f"vit_block{i:02d}", o)))
            H.append(blk.attn.register_forward_pre_hook(
                lambda m, a, k, i=i: self.vit_logits(i, m, a[0], k), with_kwargs=True))
        H.append(vis.merger.register_forward_hook(lambda m, a, o: keep("vit_merger", o)))
        for j, mg in enumerate(vis.deepstack_merger_list):
            H.append(mg.register_forward_hook(lambda m, a, o, j=j: keep(f"vit_deepstack{j}", o)))

        def lm_pre(m, a, k):
            keep("llm_input_embeds", k["inputs_embeds"])
            keep("position_ids", k["position_ids"])
            keep("visual_pos_masks", k["visual_pos_masks"])
            for j, d in enumerate(k["deepstack_visual_embeds"]):
                keep(f"deepstack_embeds{j}", d)

        H.append(lm.register_forward_pre_hook(lm_pre, with_kwargs=True))
        def rope_out(m, a, o):  # hooks must return None (a returned value replaces the output / the args)
            keep("llm_rope_cos", o[0])
            keep("llm_rope_sin", o[1])

        H.append(lm.rotary_emb.register_forward_hook(rope_out))
        for i, layer in enumerate(lm.layers):
            H.append(layer.register_forward_pre_hook(lambda m, a, k, i=i: keep(f"llm_in{i:02d}", a[0]),
                                                     with_kwargs=True))
            H.append(layer.register_forward_hook(lambda m, a, o, i=i: keep(f"llm_layer{i:02d}", o)))
            H.append(layer.self_attn.register_forward_pre_hook(
                lambda m, a, k, i=i: self.llm_logits(i, m, k), with_kwargs=True))
        H.append(lm.norm.register_forward_hook(lambda m, a, o: keep("llm_final_norm", o)))
        H.append(qwen.lm_head.register_forward_hook(lambda m, a, o: self.s["logits_shape"].append(list(o.shape))))

        H.append(head.state_encoder.register_forward_pre_hook(lambda m, a: keep("state_in", a[0])))
        H.append(head.state_encoder.register_forward_hook(lambda m, a, o: keep("state_token", o)))
        def enc_in(m, a):
            keep("head_x_in", a[0])
            keep("head_t_disc", a[1])

        H.append(head.action_encoder.register_forward_pre_hook(enc_in))
        H.append(head.action_encoder.register_forward_hook(lambda m, a, o: keep("action_encoder_out", o)))
        H.append(head.position_embedding.register_forward_hook(lambda m, a, o: keep("action_pos_emb", o)))

        def dit_pre(m, a, k):
            keep("dit_in", k["hidden_states"])
            keep("dit_context", k["encoder_hidden_states"])
            keep("dit_timestep", k["timestep"])

        H.append(dit.register_forward_pre_hook(dit_pre, with_kwargs=True))
        H.append(dit.register_forward_hook(lambda m, a, o: keep("dit_out", o)))
        H.append(dit.timestep_encoder.time_proj.register_forward_hook(lambda m, a, o: keep("time_proj", o)))
        H.append(dit.timestep_encoder.register_forward_hook(lambda m, a, o: keep("temb", o)))
        for i, blk in enumerate(dit.transformer_blocks):
            H.append(blk.register_forward_hook(lambda m, a, o, i=i: keep(f"dit_block{i:02d}", o)))
            H.append(blk.attn1.register_forward_pre_hook(
                lambda m, a, k, i=i: self.dit_logits(i, m, a[0], k), with_kwargs=True))
        H.append(dit.proj_out_2.register_forward_pre_hook(lambda m, a: keep("dit_final_mod", a[0])))
        H.append(head.action_decoder.register_forward_hook(lambda m, a, o: keep("action_decoder_out", o)))
        for name, mod in vla.named_modules():
            if name and not name.startswith(("vj_encoder", "vj_predictor")):
                H.append(mod.register_forward_hook(lambda m, a, o, name=name: self.survey(name, m, a, o)))

    def keep(self, name, x):
        self.s[name].append(x.detach().clone() if x.dtype in (torch.int32, torch.int64, torch.bool)
                            else x.detach().float().clone())

    def qwen_out(self, o):
        hs = o.hidden_states
        self.s["n_hidden_states"].append(len(hs))
        self.keep("hidden_states_last", hs[-1])

    @staticmethod
    def _argmax(lg):
        flat = int(lg.argmax())
        return [int(v) for v in np.unravel_index(flat, tuple(lg.shape))]

    def vit_logits(self, i, attn, h, k):
        """Qwen3-VL ViT logits (q k^T) * 1/8 after the 2-D RoPE, 16 heads, per image (block-diagonal)."""
        from transformers.models.qwen3_vl.modeling_qwen3_vl import apply_rotary_pos_emb_vision
        n = h.shape[0]
        q, kk, _ = attn.qkv(h).reshape(n, 3, attn.num_heads, -1).permute(1, 0, 2, 3).unbind(0)
        cos, sin = k["position_embeddings"]
        q, kk = apply_rotary_pos_emb_vision(q, kk, cos, sin)
        cu = k["cu_seqlens"].tolist()
        best = self.vit_logit.get(i, {"max": 0.0})
        for v in range(len(cu) - 1):
            qs = q[cu[v]:cu[v + 1]].float().transpose(0, 1)
            ks = kk[cu[v]:cu[v + 1]].float().transpose(0, 1)
            lg = (qs @ ks.transpose(1, 2) * attn.scaling).abs()
            m = float(lg.max())
            if m > best["max"]:
                best = {"max": m, "at_(view,head,q,k)": [v] + self._argmax(lg)}
        self.vit_logit[i] = best

    def llm_logits(self, i, attn, k):
        """Qwen3 logits (q k^T) / sqrt(128) after q_norm/k_norm and MRoPE, GQA 16/8, causal entries only."""
        from transformers.models.qwen3_vl.modeling_qwen3_vl import apply_rotary_pos_emb, repeat_kv
        h = k["hidden_states"]
        shp = (*h.shape[:-1], -1, attn.head_dim)
        q = attn.q_norm(attn.q_proj(h).view(shp)).transpose(1, 2)
        kk = attn.k_norm(attn.k_proj(h).view(shp)).transpose(1, 2)
        cos, sin = k["position_embeddings"]
        q, kk = apply_rotary_pos_emb(q, kk, cos, sin)
        kk = repeat_kv(kk, attn.num_key_value_groups)
        lg = (q.float() @ kk.float().transpose(2, 3))[0] * attn.scaling
        s = lg.shape[-1]
        causal = torch.ones(s, s, dtype=torch.bool).tril()
        lg = torch.where(causal, lg.abs(), torch.zeros(()))
        self.llm_logit[i] = {"max": float(lg.max()), "at_(head,q,k)": self._argmax(lg),
                             "unscaled_qk_max": float(lg.max()) / attn.scaling}

    def dit_logits(self, i, attn, h, k):
        """DiT logits (q k^T) / 8, 12 heads; cross blocks use the 32 VLM tokens as keys. Max over the Euler steps."""
        enc = k.get("encoder_hidden_states")
        src = h if enc is None else enc
        q = attn.to_q(h).float()
        kk = attn.to_k(src).float()
        b, n, _ = q.shape
        q = q.view(b, n, attn.heads, -1).transpose(1, 2)
        kk = kk.view(b, kk.shape[1], attn.heads, -1).transpose(1, 2)
        lg = ((q @ kk.transpose(2, 3)) * attn.scale)[0].abs()
        m = float(lg.max())
        if m > self.dit_logit.get(i, {"max": 0.0})["max"]:
            self.dit_logit[i] = {"max": m, "at_(head,q,k)": self._argmax(lg),
                                 "kind": "self" if enc is None else "cross"}

    def survey(self, name, module, args, out):
        if isinstance(out, torch.Tensor):
            t = out
        elif isinstance(out, (tuple, list)) and out and isinstance(out[0], torch.Tensor):
            t = out[0]
        elif hasattr(out, "last_hidden_state"):
            t = out.last_hidden_state
        elif hasattr(out, "logits") and isinstance(out.logits, torch.Tensor):
            t = out.logits
        else:
            t = None
        if t is not None and t.is_floating_point() and t.numel():
            self.maxabs[name] = max(self.maxabs.get(name, 0.0), float(t.detach().abs().max()))
        if isinstance(module, (torch.nn.Linear, torch.nn.LayerNorm)) and args and isinstance(args[0], torch.Tensor):
            key = name + " (input)"
            self.maxabs[key] = max(self.maxabs.get(key, 0.0), float(args[0].detach().abs().max()))

    def remove(self):
        for h in self.h:
            h.remove()
        for f in self.undo:
            f()


# ---------------------------------------------------------------------------------------------------------- checkpoint
def pt_index(path):
    """{name: (storage key, storage_offset, size, stride, dtype)} from the .pt's data.pkl (no tensor data is read),
    the zip archive prefix and {storage key: byte offset of its data in the file} from the local file headers."""
    zf = zipfile.ZipFile(path)
    infos = {i.filename: i for i in zf.infolist()}
    pkl = [n for n in infos if n.endswith("/data.pkl")]
    assert len(pkl) == 1, pkl
    prefix = pkl[0][: -len("data.pkl")]

    class U(pickle.Unpickler):
        def find_class(self, mod, nm):
            if (mod, nm) == ("collections", "OrderedDict"):
                return collections.OrderedDict
            if (mod, nm) == ("torch._utils", "_rebuild_tensor_v2"):
                return lambda st, off, size, stride, *rest: (st, off, tuple(size), tuple(stride))
            if mod == "torch" and nm.endswith("Storage"):
                return nm
            raise pickle.UnpicklingError(f"blocked global {mod}.{nm}")

        def persistent_load(self, pid):
            assert pid[0] == "storage", pid
            return {"type": pid[1], "key": pid[2], "numel": pid[4]}

    sd = U(io.BytesIO(zf.read(pkl[0]))).load()
    index = {k: (v[0]["key"], v[1], v[2], v[3], v[0]["type"]) for k, v in sd.items()}
    starts = {}
    with open(path, "rb") as f:
        for name, info in infos.items():
            if not name.startswith(prefix + "data/"):
                continue
            assert info.compress_type == zipfile.ZIP_STORED, name
            f.seek(info.header_offset)
            hdr = f.read(30)
            assert hdr[:4] == b"PK\x03\x04", name
            n, m = struct.unpack("<HH", hdr[26:30])
            starts[name[len(prefix + "data/"):]] = info.header_offset + 30 + n + m
    return index, prefix, starts


def load_ckpt():
    """The checkpoint as from_pretrained loads it (torch.load, weights_only, mmap)."""
    return torch.load(str(CKPT), map_location="cpu", weights_only=True, mmap=True)


# ---------------------------------------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=pathlib.Path, default=B / "ref")
    ap.add_argument("--export", action="store_true",
                    help="also write build/vla_jepa/vla_jepa.safetensors, export_names.txt and pt_offsets.txt")
    ap.add_argument("--no-bf16", action="store_true", help="skip the bf16 repeat")
    ap.add_argument("--no-eager", action="store_true", help="skip the eager-attention rerun (and with it --export)")
    a = ap.parse_args()
    if a.export and a.no_eager:
        ap.error("--export needs the eager rerun (it tracks the parameters the path reads)")
    t_start = time.time()
    fetch()

    import cv2

    obs = load_sample()
    full, wrist = obs["full_image"], obs["wrist_image"]
    state8 = np.asarray(obs["state"], np.float64)
    task = str(obs["task_description"])
    # eval_libero.py: the views are obs[...][::-1, ::-1] (already so in the sample); state = concat(eef_pos,
    # quat2axisangle(eef_quat), gripper_qpos); observation.state = state[None]; obs_input as below (with_state true).
    obs_input = {"images": [full, wrist], "task_description": task, "step": 0, "state": state8[None]}
    stats = json.loads((RUN / "dataset_statistics.json").read_text())

    # ------------------------------------------------------------ fp32 model
    vla, shim = build(fp32=True)
    sd = load_ckpt()
    msd = vla.state_dict()
    assert set(msd) == set(sd), (set(msd) ^ set(sd))
    qwen = vla.qwen_vl_interface.model
    emb_w = qwen.model.language_model.embed_tokens.weight
    tied = qwen.lm_head.weight is emb_w
    emb_key, head_key = QWEN_PREFIX + "model.language_model.embed_tokens.weight", QWEN_PREFIX + "lm_head.weight"
    ckpt_emb_eq_head = torch.equal(sd[emb_key], sd[head_key])
    meta_keys = [k for k, v in msd.items() if v.is_meta]
    real_keys = [k for k in sd if k not in meta_keys]
    # the tied Parameter holds lm_head's values (loaded after embed_tokens), so compare the embedding key with them
    load_exact = all(torch.equal(msd[k].to(sd[k].dtype), sd[head_key if k == emb_key and tied else k])
                     for k in real_keys)
    dtypes = collections.Counter(str(v.dtype) for k, v in msd.items() if not v.is_meta)
    n_used_params = sum(p.numel() for p in vla.parameters() if not p.is_meta)
    print(f"checkpoint: {len(sd)} tensors; meta (training-only) {len(meta_keys)}; all real entries equal after load: "
          f"{load_exact}; lm_head tied to embed_tokens: {tied}; ckpt embed_tokens == lm_head: {ckpt_emb_eq_head}; "
          f"dtypes {dict(dtypes)}; {n_used_params} materialized params")
    del msd

    client = make_client(vla)
    stats_used = client.action_norm_stats

    # ------------------------------------------------------------ reference run (fp32, sdpa), every tap on
    taps = Taps(vla)
    sent = []
    orig_resize = client._resize_image

    def resize_rec(img):
        out = orig_resize(img)
        sent.append(np.asarray(out).copy())
        return out

    client._resize_image = resize_rec
    try:
        raw, data, rec, dt_fp32 = infer(client, obs_input)
    finally:
        client._resize_image = orig_resize
        taps.remove()
    S_ = {k: v for k, v in taps.s.items()}
    actn = np.array(data["normalized_actions"], np.float32)[0]  # copies (msgpack arrays are read-only)
    emb_out = np.array(data["embodied_action_tokens"], np.float32)[0]

    # ------------------------------------------------------------ eager rerun (plain eager attention), tracking reads
    eager = None
    read = set()
    if not a.no_eager:
        qwen.set_attn_implementation("eager")
        impl = (qwen.config._attn_implementation, qwen.config.text_config._attn_implementation,
                qwen.config.vision_config._attn_implementation)
        fin_e = []
        h = qwen.model.language_model.norm.register_forward_hook(lambda m, a_, o: fin_e.append(o.detach().clone()))
        raw_e, data_e, rec_e, _ = infer(client, obs_input, track=True)
        h.remove()
        qwen.set_attn_implementation("sdpa")
        idmap = collections.defaultdict(list)
        for n, t in list(vla.named_parameters(remove_duplicate=False)) + list(vla.named_buffers(remove_duplicate=False)):
            idmap[id(t)].append(n)
        read = {n for i in rec_e.seen if i in idmap for n in idmap[i]}
        actn_e = np.array(data_e["normalized_actions"], np.float32)[0]
        emb_e = np.array(data_e["embodied_action_tokens"], np.float32)[0]
        fin = S_["llm_final_norm"][0][0]
        eager = {
            "attn_implementation_(model,text,vision)": impl,
            "same_noise": bool(torch.equal(rec_e.draws[0][1], rec.draws[0][1])),
            "llm_final_norm_maxabs": float((fin_e[0][0].float() - fin).abs().max()),
            "embodied_hidden_maxabs": float(np.abs(emb_e - emb_out).max()),
            "embodied_hidden_rel_rms": float(np.linalg.norm(emb_e - emb_out) / np.linalg.norm(emb_out)),
            "actions_norm_maxabs": float(np.abs(actn_e - actn).max()),
            "actions_unnorm_maxabs": float(np.abs(raw_e - raw).max()),
        }
        print("  sdpa vs eager:", json.dumps(eager))

    # ------------------------------------------------------------ derived records and checks
    ids = S_["input_ids"][0][0].long()
    seq = int(ids.numel())
    tok = vla.qwen_vl_interface.processor.tokenizer
    img_id = qwen.config.image_token_id
    img_pos = torch.nonzero(ids == img_id).flatten()
    act_pos = torch.nonzero(torch.isin(ids, torch.tensor(vla.action_token_ids))).flatten()
    emb_pos = torch.nonzero(ids == vla.embodied_action_token_id).flatten()
    assert img_pos.numel() == 128 and act_pos.numel() == 24 and emb_pos.numel() == 32
    vstart = torch.nonzero(ids == qwen.config.vision_start_token_id).flatten().tolist()
    vend = torch.nonzero(ids == qwen.config.vision_end_token_id).flatten().tolist()
    pix = S_["pixel_values"][0]
    grid = S_["image_grid_thw"][0]
    # inverse of the fast processor's patch flattening: rows (bh, bw, mh, mw), columns (c, t, ph, pw)
    pv = pix.view(2, 8, 8, 2, 2, 3, 2, 16, 16)  # view, bh, bw, mh, mw, c, t, ph, pw
    img256 = pv[:, :, :, :, :, :, 0].permute(0, 5, 1, 3, 6, 2, 4, 7).reshape(2, 3, 256, 256)
    u8f = img256 * 127.5 + 127.5
    u8 = u8f.round().clamp(0, 255)
    integral = float((u8f - u8).abs().max())
    renorm = (u8 - 127.5) / 127.5
    repatch = renorm.view(2, 3, 8, 2, 16, 8, 2, 16).permute(0, 2, 5, 3, 6, 1, 4, 7)  # v, bh, bw, mh, mw, c, ph, pw
    repatch = repatch[:, :, :, :, :, :, None].expand(2, 8, 8, 2, 2, 3, 2, 16, 16).reshape(512, 1536)
    pix_roundtrip = bool(torch.equal(repatch, pix))
    image_256 = u8.to(torch.uint8).permute(0, 2, 3, 1).numpy()  # [2, 256, 256, 3] HWC
    sent_ok = all(np.array_equal(s, v) for s, v in zip(sent, (full, wrist)))

    # ViT
    pe = S_["vit_patch_embed"][0]
    pos_embed = S_["vit_pos_embed"][0]
    pos_views_equal = bool(torch.equal(pos_embed[:256], pos_embed[256:]))
    block_in_ok = bool(torch.equal(S_["vit_block0_in"][0], pe + pos_embed))
    merger = S_["vit_merger"][0]
    ds_out = [S_[f"vit_deepstack{j}"][0] for j in range(3)]
    # LLM
    llm_in = S_["llm_input_embeds"][0][0]
    mask_vis = S_["visual_pos_masks"][0][0]
    scatter_ok = bool(torch.equal(llm_in[img_pos], merger)) and bool(torch.equal(mask_vis.nonzero().flatten(), img_pos))
    text_pos = torch.tensor([i for i in range(seq) if i not in set(img_pos.tolist())])
    embed_ok = bool(torch.equal(llm_in[text_pos], emb_w[ids[text_pos]].float()))
    ds_ok = []
    for j in range(3):
        exp = S_[f"llm_layer{j:02d}"][0][0].clone()
        exp[img_pos] = exp[img_pos] + S_[f"deepstack_embeds{j}"][0]
        ds_ok.append(bool(torch.equal(S_[f"llm_in{j + 1:02d}"][0][0], exp)))
    ds_is_merger = all(torch.equal(S_[f"deepstack_embeds{j}"][0], ds_out[j]) for j in range(3))
    chain_ok = all(torch.equal(S_[f"llm_in{i + 1:02d}"][0][0], S_[f"llm_layer{i:02d}"][0][0]) for i in range(3, 27))
    fin = S_["llm_final_norm"][0][0]
    hs_last = S_["hidden_states_last"][0][0]  # what predict_action reads: qwenvl_outputs.hidden_states[-1]
    hs_is_norm = bool(torch.equal(hs_last, fin))
    hs_is_layer27 = bool(torch.equal(hs_last, S_["llm_layer27"][0][0]))
    emb_hidden = hs_last[emb_pos]
    emb_ok = bool(torch.equal(torch.from_numpy(emb_out), emb_hidden))
    hs_src = ("the final RMSNorm output" if hs_is_norm else
              "decoder layer 27's output BEFORE the final RMSNorm" if hs_is_layer27 else "UNKNOWN")
    pos_ids = S_["position_ids"][0][:, 0]  # [3, S]
    # MRoPE check: inv_freq_j = 5e6^(-2j/128); frequency j takes the H position if j%3==1 and j<60, W if j%3==2 and
    # j<60, else T; emb = [f, f]; cos/sin of that
    jj = torch.arange(64)
    inv = 1.0 / (5000000.0 ** (torch.arange(0, 128, 2, dtype=torch.int64).float() / 128))
    axis = torch.where((jj % 3 == 1) & (jj < 60), 1, torch.where((jj % 3 == 2) & (jj < 60), 2, 0))
    fr = pos_ids.float()[axis].T * inv  # [S, 64]
    cos_np, sin_np = torch.cat([fr, fr], -1).cos(), torch.cat([fr, fr], -1).sin()
    rope_d = max(float((cos_np - S_["llm_rope_cos"][0][0]).abs().max()), float((sin_np - S_["llm_rope_sin"][0][0]).abs().max()))
    # ViT RoPE check: per patch (row, col) in 2x2 merge order, emb = [row * f, col * f] (f_i = 1e4^(-2i/32), 16 of
    # each), cos/sin of [emb, emb]
    rows = (torch.arange(8).view(8, 1, 1, 1) * 2 + torch.arange(2).view(1, 1, 2, 1)).expand(8, 8, 2, 2).reshape(-1)
    cols = (torch.arange(8).view(1, 8, 1, 1) * 2 + torch.arange(2).view(1, 1, 1, 2)).expand(8, 8, 2, 2).reshape(-1)
    fv = 1.0 / (10000 ** (torch.arange(0, 32, 2, dtype=torch.float) / 32))
    ev = torch.cat([rows[:, None].float() * fv, cols[:, None].float() * fv], -1)
    ev = torch.cat([ev, ev], -1)
    vit_rope_d = max(float((ev.cos() - S_["vit_rope_cos"][0][:256]).abs().max()),
                     float((ev.sin() - S_["vit_rope_sin"][0][:256]).abs().max()))

    # head: Euler
    assert len(rec.draws) == 1 and rec.draws[0][0] == "randn", [d[0] for d in rec.draws]
    noise = rec.draws[0][1][0]  # [7, 7]
    torch.manual_seed(SEED)
    seed_ok = bool(torch.equal(torch.randn(1, 7, 7), rec.draws[0][1]))
    steps = vla.action_model.num_inference_timesteps
    xs, x, step_in_ok = [], noise.clone(), True
    vel = [d[0][-7:] for d in S_["action_decoder_out"]]
    assert len(vel) == steps == 4
    for k in range(steps):
        step_in_ok &= bool(torch.equal(S_["head_x_in"][k][0], x))
        x = x + (1.0 / steps) * vel[k]
        xs.append(x.clone())
    final_ok = bool(torch.equal(xs[-1], torch.from_numpy(actn)))
    t_disc = [int(S_["head_t_disc"][k][0]) for k in range(steps)]
    ctx_ok = all(torch.equal(c[0], emb_hidden) for c in S_["dit_context"])
    sa_ok = all(torch.equal(S_["dit_in"][k][0], torch.cat([S_["state_token"][0][0], vla.action_model.future_tokens.weight,
                                                            S_["action_encoder_out"][k][0] + S_["action_pos_emb"][k]]))
                for k in range(steps))
    # client post-processing (M1Inference.unnormalize_actions, min/max) and eval_libero's gripper mapping
    lo, hi = np.array(stats_used["min"]), np.array(stats_used["max"])
    msk = np.array(stats_used["mask"], bool)
    c = np.clip(actn.astype(np.float64), -1, 1)
    c[:, 6] = np.where(c[:, 6] < 0.5, 0, 1)
    unnorm_np = np.where(msk, 0.5 * (c + 1) * (hi - lo) + lo, c)
    env_actions = np.concatenate([raw[:, :6], 1.0 - 2.0 * (raw[:, 6:7] > 0.5)], axis=1)
    checks = {
        "checkpoint_real_entries_equal_after_strict_load": load_exact,
        "lm_head_is_embed_tokens_parameter": tied,
        "ckpt_embed_tokens_equal_ckpt_lm_head": ckpt_emb_eq_head,
        "meta_(training_only)_state_dict_entries": len(meta_keys),
        "autocast_calls_(device,dtype)": [list(c_) for c_ in AUTOCAST_CALLS[:3]],
        "from_pretrained_kwargs": shim.calls,
        "client_cv2_INTER_AREA_224_is_identity": sent_ok,
        "only_rng_draw_is_action_head_randn_1x7x7": True,
        "noise_reproduced_by_manual_seed0_randn_1x7x7": seed_ok,
        "pixel_values_equal_patchify((image_256-127.5)/127.5)_bitwise": pix_roundtrip,
        "image_256_integrality_maxabs": integral,
        "vit_pos_embed_same_for_both_views_bitwise": pos_views_equal,
        "vit_block0_input_equals_patch_embed_plus_pos_embed_bitwise": block_in_ok,
        "lm_head_logits_shape_(computed_and_discarded)": S_["logits_shape"][0],
        "image_rows_of_input_embeds_equal_vit_merger_bitwise": scatter_ok,
        "text_rows_equal_embed_tokens[input_ids]_bitwise": embed_ok,
        "deepstack_embeds_equal_deepstack_merger_outputs_bitwise": bool(ds_is_merger),
        "layer_j+1_input_equals_layer_j_output_plus_deepstack_j_at_image_rows_(j=0,1,2)_bitwise": ds_ok,
        "layer_i+1_input_equals_layer_i_output_(i=3..26)_bitwise": bool(chain_ok),
        "n_hidden_states": S_["n_hidden_states"][0],
        "hidden_states[-1]_equals_final_norm_output_bitwise": hs_is_norm,
        "hidden_states[-1]_equals_layer27_output_bitwise": hs_is_layer27,
        "embodied_tokens_returned_equal_hidden_states[-1]_rows_bitwise": emb_ok,
        "llm_rope_cos_sin_vs_formula_maxabs": rope_d,
        "vit_rope_cos_sin_vs_formula_maxabs": vit_rope_d,
        "dit_context_equals_embodied_hidden_every_step_bitwise": bool(ctx_ok),
        "dit_input_equals_[state_token,future_tokens,action_encoder_out+pos_emb]_bitwise": bool(sa_ok),
        "action_encoder_input_each_step_equals_x_bitwise": bool(step_in_ok),
        "x_after_last_step_equals_normalized_actions_bitwise": final_ok,
        "client_unnormalized_vs_numpy_formula_maxabs": float(np.abs(unnorm_np - raw).max()),
        "t_discretized": t_disc,
        "fp32_step_seconds": round(dt_fp32, 2),
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
    save("image_256", image_256, "[view, 256, 256, 3] RGB u8: the processor's bicubic (antialias) 224->256 resize, "
         "recovered exactly from pixel_values (= 127.5 * pv + 127.5, integral; re-patchify is bitwise equal)", "u8")
    save("pixel_values", pix, "processor output [512, 1536] = 2 views x 256 patches; row = (bh, bw, mh, mw) over the "
         "8x8 grid of 2x2 merge blocks, col = (c, t, ph, pw) with t = 2 identical frames; value (u8 - 127.5) / 127.5")
    save("image_grid_thw", grid, "[[1, 16, 16], [1, 16, 16]]", "i32")
    save("input_ids", ids, f"Qwen3-VL token ids [S={seq}] (chat template, one user turn, add_generation_prompt)", "i32")
    save("attention_mask", S_["attention_mask"][0][0], "all ones (one sequence, no padding)", "i32")
    save("image_token_positions", img_pos.view(2, 64), "positions of <|image_pad|> 151655 per view [2, 64]; "
         "vit_merger rows go there in order", "i32")
    save("action_token_positions", act_pos, "positions of the 24 latent <|action_0..2|> tokens (8 each, ids "
         "151669-151671); their outputs are unused at inference", "i32")
    save("embodied_token_positions", emb_pos, "positions of the 32 <|embodied_action|> 151697 tokens; their final-norm "
         "rows are the action head's context", "i32")
    save("vit_patch_embed", pe.view(2, 256, 1024), "Conv3d(3->1024, k=(2,16,16)) output per view [2, 256, 1024] "
         "(patch order of pixel_values), before the position embedding")
    save("vit_pos_embed", pos_embed[:256], "learned 48x48 pos_embed bilinearly interpolated to 16x16 "
         "(fast_pos_embed_interpolate), in merge-block patch order [256, 1024]; the same for both views")
    save("vit_block_in", S_["vit_block0_in"][0].view(2, 256, 1024), "patch embed + pos embed = block 0 input")
    save("vit_rope_cos", S_["vit_rope_cos"][0][:256], "ViT 2-D RoPE cos table [256, 64] (per patch, merge order; the "
         "same for view 1)")
    save("vit_rope_sin", S_["vit_rope_sin"][0][:256], "ViT 2-D RoPE sin table [256, 64]")
    save("vit_blocks", torch.stack([S_[f"vit_block{i:02d}"][0].view(2, 256, 1024) for i in range(24)]),
         "every ViT block output [24, view, 256, 1024] (attention is per view: block-diagonal)")
    save("vit_merger", merger.view(2, 64, 2048), "final merger output [view, 64, 2048]: LN(1024) per patch, 2x2 concat "
         "-> 4096, fc1 + exact GELU, fc2; scattered into input_embeds at image_token_positions")
    for j, li in enumerate(qwen.config.vision_config.deepstack_visual_indexes):
        save(f"vit_deepstack{j}", ds_out[j].view(2, 64, 2048), f"DeepStack merger {j} output [view, 64, 2048]: taps ViT "
             f"block {li}'s output, LN over the concatenated 4096; ADDED to the LLM residual at image_token_positions "
             f"after decoder layer {j}")
    save("llm_input_embeds", llm_in, f"LLM inputs_embeds [{seq}, 2048]: embed_tokens[input_ids] with the image rows "
         "replaced by vit_merger")
    save("position_ids", pos_ids, f"MRoPE position ids [3 (t, h, w), {seq}] from get_rope_index", "i32")
    save("llm_rope_cos", S_["llm_rope_cos"][0][0], f"LLM rotary cos [{seq}, 128] as used (interleaved MRoPE)")
    save("llm_rope_sin", S_["llm_rope_sin"][0][0], f"LLM rotary sin [{seq}, 128]")
    for i in range(28):
        save(f"llm_layer{i:02d}", S_[f"llm_layer{i:02d}"][0][0], f"decoder layer {i} output [{seq}, 2048]" + (
            f" BEFORE the DeepStack add (llm_layer{i:02d}_deepstack is after)" if i < 3 else ""))
    for j in range(3):
        save(f"llm_layer{j:02d}_deepstack", S_[f"llm_in{j + 1:02d}"][0][0], f"layer {j} output + vit_deepstack{j} at "
             f"image rows = layer {j + 1}'s input [{seq}, 2048]")
    save("llm_final_norm", fin, f"final RMSNorm output [{seq}, 2048] (model.norm(llm_layer27)); predict_action reads "
         f"hidden_states[-1], which is {hs_src}")
    save("embodied_hidden", emb_hidden, "the 32 embodied-action hidden states [32, 2048] = hidden_states[-1]["
         f"embodied_token_positions] = {hs_src} at those rows; the action head's encoder_hidden_states "
         "(cross-attention K/V source)")
    save("state_raw", S_["state_in"][0][0, 0], "state as the head sees it (8,): the float64 sample state cast to fp32, "
         "NOT normalized: eef_pos 3, axis-angle 3, gripper_qpos 2")
    save("state_token", S_["state_token"][0][0, 0], "state_encoder output (768,): Linear 8->1024, ReLU, Linear 1024->768")
    save("future_tokens", vla.action_model.future_tokens.weight, "learned future tokens [32, 768] (checkpoint values)")
    save("noise", noise, "initial x [7, 7]: torch.randn(1, 7, 7) fp32 after torch.manual_seed(0)")
    save("t_discretized", np.array(t_disc), "per-step timestep int(k / 4 * 1000) = 0, 250, 500, 750", "i32")
    save("t_cont", np.array([k / steps for k in range(steps)]), "per-step t = k / 4")
    save("time_proj", torch.stack([v[0] for v in S_["time_proj"]]), "per-step diffusers Timesteps(256, flip_sin_to_cos,"
         " shift 1) of t_disc [4, 256] (fp32)")
    save("temb", torch.stack([v[0] for v in S_["temb"]]), "per-step TimestepEmbedding output [4, 768] (Linear "
         "256->768, SiLU, Linear 768->768); conditions every AdaLayerNorm and the output modulation")
    save("action_encoder_out", torch.stack([v[0] for v in S_["action_encoder_out"]]), "per-step ActionEncoder(x, t_disc)"
         " [4, 7, 768]: W1(x) (7->768) cat sinusoid(t_disc) [sin, cos] (768), W2 1536->768 + swish, W3 768->768")
    save("action_pos_emb", S_["action_pos_emb"][0], "position_embedding rows 0..6 [7, 768], added to "
         "action_encoder_out")
    save("dit_in", torch.stack([v[0] for v in S_["dit_in"]]), "per-step DiT input [4, 40, 768] = [state_token (1), "
         "future_tokens (32), action_encoder_out + action_pos_emb (7)]")
    save("dit_blocks", torch.stack([torch.stack([S_[f"dit_block{i:02d}"][k][0] for i in range(16)])
                                    for k in range(steps)]),
         "every DiT block output [step, block, 40, 768]; step 0 is [0]. Even blocks cross-attend to embodied_hidden "
         "(2048 -> 768 K/V), odd blocks self-attend")
    save("dit_final_mod", torch.stack([v[0] for v in S_["dit_final_mod"]]), "per-step norm_out(h) * (1 + scale) + shift"
         " [4, 40, 768] (shift, scale = proj_out_1(SiLU(temb)).chunk(2)), the input of proj_out_2")
    save("dit_out", torch.stack([v[0] for v in S_["dit_out"]]), "per-step DiT output proj_out_2 [4, 40, 1024]")
    save("action_decoder_out", torch.stack([v[0] for v in S_["action_decoder_out"]]), "per-step action_decoder "
         "(1024 -> 1024 ReLU -> 7) on all 40 tokens [4, 40, 7]")
    save("velocity", torch.stack(vel), "per-step velocity = action_decoder_out[:, -7:] [4, 7, 7]")
    save("x", torch.stack(xs), "per-step x after x += 0.25 * velocity [4, 7, 7]; x[3] = actions_norm")
    save("actions_norm", actn, "final normalized actions [7, 7] (predict_action's normalized_actions)")
    save("actions", raw, "unnormalized chunk [7, 7] (M1Inference.unnormalize_actions, franka min/max): clip to [-1, 1], "
         "gripper -> 1 if >= 0.5 else 0, dims 0-5: 0.5 (a + 1)(max - min) + min; the client executes all 7 open-loop")
    save("env_actions", env_actions, "what eval_libero.py sends to env.step [7, 7]: actions with the gripper mapped to "
         "1 - 2 (g > 0.5) (open = -1, close = +1)")
    save("action_min", lo, "franka action min (7,) as used")
    save("action_max", hi, "franka action max (7,) as used")
    save("action_mask", msk, "franka action mask (7,): 1 = unnormalize (dims 0-5), gripper 0", "i32")
    if eager is not None:
        save("eager_actions_norm", actn_e, "eager attention rerun: normalized actions [7, 7]")
        save("eager_embodied_hidden", emb_e, "eager attention rerun: embodied hidden states [32, 2048]")

    # ------------------------------------------------------------ numerics survey
    def part(name):
        if name.startswith("qwen_vl_interface.model.model.visual"):
            return "vit"
        if name.startswith("qwen_vl_interface.model.lm_head"):
            return "lm_head"
        if name.startswith("qwen_vl_interface"):
            return "llm"
        return "head"

    by_part = collections.defaultdict(dict)
    for k, v in taps.maxabs.items():
        by_part[part(k)][k] = v
    top = {p: dict(sorted(d.items(), key=lambda kv: -kv[1])[:10]) for p, d in by_part.items()}
    over = {k: v for k, v in taps.maxabs.items() if v > 30000}

    def top_entries(y, k=6):
        flat = y.abs().flatten().topk(k)
        return [(int(j // y.shape[1]), int(j % y.shape[1]), round(float(v), 2)) for v, j in zip(flat.values, flat.indices)]

    def massive_channels(y, thr):
        cm = y.abs().max(0)
        cols = torch.nonzero(cm.values > thr).flatten().tolist()
        return {int(cc): {"max": round(float(cm.values[cc]), 1), "at_row": int(cm.indices[cc]),
                          "rows_over_thr": int((y[:, cc].abs() > thr).sum())} for cc in cols}

    llm_top = {f"layer{i:02d}": top_entries(S_[f"llm_layer{i:02d}"][0][0]) for i in range(28)}
    llm_massive = {f"layer{i:02d}": massive_channels(S_[f"llm_layer{i:02d}"][0][0], 100.0) for i in range(28)}
    vit_top = {f"block{i:02d}": top_entries(S_[f"vit_block{i:02d}"][0]) for i in range(24)}
    vit_massive = {f"block{i:02d}": massive_channels(S_[f"vit_block{i:02d}"][0], 100.0) for i in range(24)}
    numerics = {
        "over_30000": over, "top_per_part": top,
        "llm_residual_top6_(row,col,|x|)": llm_top, "llm_residual_channels_over_100": llm_massive,
        "vit_residual_top6_(row,col,|x|)": vit_top, "vit_residual_channels_over_100": vit_massive,
        "attention_logit_maxabs": {
            "vit": {f"block{i:02d}": v for i, v in sorted(taps.vit_logit.items())},
            "llm": {f"layer{i:02d}": v for i, v in sorted(taps.llm_logit.items())},
            "dit": {f"block{i:02d}": v for i, v in sorted(taps.dit_logit.items())}},
        "all_module_outputs_maxabs": taps.maxabs,
    }
    del taps, S_, client, vla, qwen, emb_w, rec
    InProcessClient.server = None
    gc.collect()

    # ------------------------------------------------------------ bf16 repeat (as released, --use_bf16)
    bf16 = None
    if not a.no_bf16:
        vla16, _ = build(fp32=False)
        q16 = vla16.qwen_vl_interface.model
        buf_dtypes = {n: str(b.dtype) for n, b in q16.named_buffers()}
        client16 = make_client(vla16)
        fin16 = []
        h = q16.model.language_model.norm.register_forward_hook(lambda m, a_, o: fin16.append(o.detach().float().clone()))
        raw16, data16, rec16, dt16 = infer(client16, obs_input, inject=noise)
        h.remove()
        actn16 = np.array(data16["normalized_actions"], np.float32)[0]
        emb16 = np.array(data16["embodied_action_tokens"], np.float32)[0]
        e32 = emb_hidden.numpy()
        bf16 = {
            "noise": "fp32 noise rounded to bf16 (injected in place of the bf16 randn)",
            "own_seed0_bf16_draw_differs_from_fp32_draw": not torch.equal(rec16.draws[0][1].float(), noise[None]),
            "normalized_actions_dtype": str(np.asarray(data16["normalized_actions"]).dtype),
            "actions_norm_maxabs": float(np.abs(actn16 - actn).max()),
            "actions_norm_per_dim_maxabs": np.abs(actn16 - actn).max(0).tolist(),
            "actions_unnorm_maxabs": float(np.abs(raw16 - raw).max()),
            "actions_unnorm_per_dim_maxabs": np.abs(raw16 - raw).max(0).tolist(),
            "gripper_decisions_equal": bool(np.array_equal(raw16[:, 6], raw[:, 6])),
            "embodied_hidden_maxabs": float(np.abs(emb16 - e32).max()),
            "embodied_hidden_rel_mse": float(((emb16 - e32) ** 2).sum() / (e32 ** 2).sum()),
            "embodied_hidden_rel_rms": float(np.linalg.norm(emb16 - e32) / np.linalg.norm(e32)),
            "llm_final_norm_maxabs": float((fin16[0][0] - fin).abs().max()),
            "rotary_inv_freq_dtypes_after_to_bf16": {n: d for n, d in buf_dtypes.items() if "inv_freq" in n},
            "seconds": round(dt16, 1),
        }
        save("bf16_actions_norm", actn16, "bf16 repeat (as released: --use_bf16, CPU stand-ins for CUDA autocast, same "
             "x0 rounded to bf16): normalized actions [7, 7]")
        save("bf16_actions", raw16, "bf16 repeat: unnormalized actions [7, 7]")
        save("bf16_embodied_hidden", emb16, "bf16 repeat: embodied hidden states [32, 2048] (as returned, fp32)")
        print("  bf16 vs fp32:", json.dumps(bf16))
        del vla16, q16, client16
        InProcessClient.server = None
        gc.collect()

    layout = {
        "S": seq,
        "tokens": [tok.convert_ids_to_tokens(int(t)) for t in ids],
        "vision_start": vstart, "vision_end": vend,
        "image_tokens": [[int(img_pos[64 * v]), int(img_pos[64 * v + 63])] for v in range(2)],
        "latent_action_tokens": [int(act_pos[0]), int(act_pos[-1])],
        "embodied_action_tokens": [int(emb_pos[0]), int(emb_pos[-1])],
        "after_embodied": tok.convert_ids_to_tokens(ids[int(emb_pos[-1]) + 1:].tolist()),
    }
    meta = {
        "model": "ginwind/VLA-JEPA LIBERO/checkpoints/VLA-JEPA-LIBERO.pt", "hf_revision": REV_HF,
        "checkpoint_sha256": CKPT_SHA256, "code": "ginwind/VLA-JEPA", "code_revision": REV_GH,
        "base_vlm": f"Qwen/Qwen3-VL-2B-Instruct @ {REV_QWEN} (config, tokenizer, processor; weights from the checkpoint)",
        "base_encoder": f"facebook/vjepa2-vitl-fpc64-256 @ {REV_VJ} (config only; training-only module on meta)",
        "sample": f"OpenHelix-Team/VLA-Adapter @ {REV_VA} {SAMPLE_PATH} (sha256 {SAMPLE_SHA256})",
        "task": task, "state_float64": state8.tolist(), "seed": SEED, "layout": layout,
        "embodied_hidden_source": hs_src,
        "prompt_template": "<|im_start|>user\\n<|vision_start|><|image_pad|>x64<|vision_end|> (x2 views) + 'Your task is "
                           "{instruction}. Infer the temporal dynamics from frames {A} and produce the corresponding "
                           "policy actions {E}.<|im_end|>\\n<|im_start|>assistant\\n', A = <|action_0|>x8 <|action_1|>x8 "
                           "<|action_2|>x8, E = <|embodied_action|>x32",
        "versions": {"torch": torch.__version__, "transformers": __import__("transformers").__version__,
                     "diffusers": __import__("diffusers").__version__, "python": sys.version.split()[0]},
        "notes": [
            "Files are raw little-endian, C order, no header; the batch dim (1) is dropped.",
            "fp32 throughout; weights are the checkpoint's bf16 values upcast exactly. Attention: sdpa.",
            "ViT (24 blocks, 1024, 16 heads x 64): pre-LN (eps 1e-6), qkv bias, 2-D RoPE (rotate_half, fp32), scale "
            "1/8, MLP fc1 4096 + gelu_pytorch_tanh, attention block-diagonal per view (cu_seqlens [0, 256, 512]). "
            "Merger: LN(1024) per patch -> view(-1, 4096) -> fc1 4096 -> exact GELU -> fc2 2048. DeepStack mergers "
            "(after blocks 5, 11, 17): view(-1, 4096) -> LN(4096) -> fc1 -> GELU -> fc2; added after LLM layers 0, 1, 2.",
            "LLM (28 layers, 2048, 16 q / 8 kv heads x 128): RMSNorm eps 1e-6 (computed in fp32), q_norm/k_norm "
            "RMSNorm on head_dim before RoPE, scale 1/sqrt(128), causal, SwiGLU 6144 (SiLU), no biases.",
            "MRoPE: inv_freq_j = 5e6^(-2j/128), j = 0..63; frequency j uses position_ids[1] (h) if j % 3 == 1 and "
            "j < 60, position_ids[2] (w) if j % 3 == 2 and j < 60, else position_ids[0] (t); cos/sin of [f, f] "
            "(128); q' = q cos + rotate_half(q) sin, rotate_half(x) = [-x[64:], x[:64]]. Text tokens have t = h = w; "
            "image tokens t = s, h = s + row, w = s + col (s = previous max + 1); text after an image resumes at the "
            "image's max + 1.",
            "ViT RoPE: per patch (row, col) of the 16x16 grid in 2x2 merge order, f_i = 1e4^(-2i/32), i < 16; "
            "emb = [row f, col f] (32); cos/sin of [emb, emb] (64).",
            "Action head (DiT-B, 768 = 12 x 64, 16 blocks): block = AdaLayerNorm (LN eps 1e-5 no affine, x (1 + scale) "
            "+ shift, [scale, shift] = Linear(SiLU(temb)).chunk(2)) -> attn1 (bias, scale 1/8; even blocks cross to "
            "embodied_hidden via to_k/to_v 2048 -> 768, odd blocks self) -> residual -> LN (eps 1e-5, no affine) -> "
            "FF 768 -> 3072 GELU-tanh -> 768 -> residual. Output: LN eps 1e-6 no affine, x (1 + scale) + shift with "
            "[shift, scale] = proj_out_1(SiLU(temb)).chunk(2) (opposite order), proj_out_2 768 -> 1024; "
            "action_decoder 1024 -> 1024 ReLU -> 7 on the last 7 tokens.",
            "Sinusoids: time_proj = diffusers Timesteps(256, flip_sin_to_cos=True, downscale_freq_shift=1): "
            "f_i = exp(-ln(1e4) i / 127), i < 128, out = [cos(t f), sin(t f)]; action encoder: f_i = exp(-ln(1e4) i "
            "/ 384), i < 384, out = [sin(t f), cos(t f)].",
            "Sampler: x0 = noise; for k in 0..3: t_disc = int(k / 4 * 1000); v = head(x, t_disc)[-7:]; x += 0.25 v.",
        ],
        "checks": checks, "sdpa_vs_eager": eager, "bf16_vs_fp32": bf16, "numerics": numerics,
        "seconds_total": None, "footprint_GB_(now,peak)": None, "tensors": tensors,
    }
    np.set_printoptions(precision=5, suppress=True, linewidth=140)
    print("\nprompt:", task, f"(S = {seq})")
    print("normalized actions:\n", actn)
    print("unnormalized actions (franka min/max; gripper 0/1):\n", raw)
    print("largest attention logits:", json.dumps({p: max(v["max"] for v in d.values())
                                                   for p, d in numerics["attention_logit_maxabs"].items()}))
    print("over 30000:", over)
    print("top per part:", json.dumps({p: dict(list(d.items())[:3]) for p, d in top.items()}, indent=1))

    # ------------------------------------------------------------ export
    if a.export:
        export(sd, read, ckpt_emb_eq_head, hs_is_norm)
    del sd
    gc.collect()
    meta["seconds_total"] = round(time.time() - t_start, 1)
    meta["footprint_GB_(now,peak)"] = footprint()
    (out / "meta.json").write_text(json.dumps(meta, indent=1))
    print("wrote", len(tensors), "tensors to", out, f"in {meta['seconds_total']} s; footprint (now, peak) GB "
          f"{meta['footprint_GB_(now,peak)']}")


def export(sd, read, emb_eq_head, hs_is_norm):
    """vla_jepa.safetensors (the checkpoint's bf16 tensors the path reads, its own names), export_names.txt and
    pt_offsets.txt (byte offsets inside VLA-JEPA-LIBERO.pt, verified)."""
    emb_key, head_key = QWEN_PREFIX + "model.language_model.embed_tokens.weight", QWEN_PREFIX + "lm_head.weight"
    norm_key = QWEN_PREFIX + "model.language_model.norm.weight"
    used, skipped = [], {}
    for k in sd:
        if k == norm_key and not hs_is_norm and k in read:
            skipped[k] = ("the final RMSNorm runs, but its output feeds only lm_head (logits, discarded): "
                          "predict_action's hidden_states[-1] is taken before it")
        elif k.startswith(("vj_encoder.", "vj_predictor.")):
            skipped[k] = "training-only (V-JEPA2 target encoder / latent world model), built on meta, never called"
        elif k == head_key:
            skipped[k] = ("tied to embed_tokens (one Parameter); only lm_head reads it as a matrix, and predict_action "
                          "discards the logits" + ("" if emb_eq_head else "; NOTE its values differ from embed_tokens "
                                                   "and are the ones the model holds"))
        elif k in read:
            used.append(k)
        else:
            skipped[k] = "never passed to a torch op on the inference path (eager rerun)"
    if not emb_eq_head:
        # the shared Parameter holds lm_head's values (loaded last); export those under the embedding's name? No:
        # keep the checkpoint's own names and export lm_head.weight too, so the device can use the right one.
        used.append(head_key)
        skipped.pop(head_key)
    index, prefix, starts = pt_index(CKPT)
    # streaming safetensors writer (no full in-memory copy of 4.5 GB)
    header, off = {"__metadata__": {"source": f"ginwind/VLA-JEPA@{REV_HF} LIBERO/checkpoints/VLA-JEPA-LIBERO.pt",
                                    "code": f"ginwind/VLA-JEPA@{REV_GH}"}}, 0
    for k in used:
        t = sd[k]
        assert t.dtype == torch.bfloat16, (k, t.dtype)
        n = t.numel() * 2
        header[k] = {"dtype": "BF16", "shape": list(t.shape), "data_offsets": [off, off + n]}
        off += n
    hb = json.dumps(header, separators=(",", ":")).encode()
    hb += b" " * (-len(hb) % 8)
    dst = B / "vla_jepa.safetensors"
    lines_off, bad = [], []
    with open(dst, "wb") as f, open(CKPT, "rb") as src:
        f.write(struct.pack("<Q", len(hb)))
        f.write(hb)
        for k in used:
            t = sd[k]
            data = t.contiguous().view(torch.uint8).numpy().tobytes() if t.numel() else b""
            f.write(data)
            key, soff, size, stride, styp = index[k]
            assert styp == "BFloat16Storage" and tuple(t.shape) == size, (k, styp, size)
            contig = tuple(torch.empty(size, device="meta").stride()) == stride
            pos = starts[key] + soff * 2
            src.seek(pos)
            same = src.read(len(data)) == data
            if not (contig and same):
                bad.append((k, contig, same))
            lines_off.append(f"{k} {pos}")
    assert not bad, bad
    (B / "pt_offsets.txt").write_text("\n".join(lines_off) + "\n")
    from safetensors import safe_open
    with safe_open(str(dst), "pt") as g:
        assert set(g.keys()) == set(used)
        for k in (used[0], used[len(used) // 2], used[-1]):
            assert torch.equal(g.get_tensor(k), sd[k])
    nbytes = sum(sd[k].numel() * 2 for k in used)
    lines = [f"# {len(used)} tensors ({nbytes / 1e9:.3f} GB) from ginwind/VLA-JEPA@{REV_HF} "
             "LIBERO/checkpoints/VLA-JEPA-LIBERO.pt, bf16 as stored, PyTorch (out, in) layouts, the checkpoint's own "
             f"names (VLA_JEPA state_dict keys, code @ {REV_GH[:7]}); zip archive prefix '{prefix}'",
             "# exported = passed to a torch op by the official predict_action path (eager rerun), minus the ones whose "
             "result predict_action discards (lm_head, the final norm)",
             "# not in the checkpoint, derived from the config at load: ViT rotary inv_freq (theta 1e4, dim 32), LLM "
             "rotary inv_freq (theta 5e6, head_dim 128, mrope_section [24, 20, 20] interleaved)",
             "# pt_offsets.txt: '<name> <byte offset in VLA-JEPA-LIBERO.pt>' for each exported tensor (verified: "
             "ZIP_STORED, contiguous, bytes equal)",
             "# name\tshape\tdtype\tpt_offset"]
    offs = dict(x.split(" ") for x in lines_off)
    for k in used:
        lines.append(f"{k}\t{list(sd[k].shape)}\tbfloat16\t{offs[k]}")
    groups = collections.Counter(v for v in skipped.values())
    lines.append(f"# skipped: {len(skipped)} tensors, "
                 f"{sum(sd[k].numel() for k in skipped) / 1e6:.1f} M params")
    for reason, n in groups.items():
        lines.append(f"#   {n} x {reason}")
    for k, reason in skipped.items():
        lines.append(f"# skipped\t{k}\t{list(sd[k].shape)}")
    (B / "export_names.txt").write_text("\n".join(lines) + "\n")
    print(f"wrote {dst} ({len(used)} tensors, {nbytes / 1e9:.2f} GB; {len(skipped)} skipped) and pt_offsets.txt")


if __name__ == "__main__":
    main()
