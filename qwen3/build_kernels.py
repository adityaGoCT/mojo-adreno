"""Compile qwen3_vk's kernels to SPIR-V for the Adreno 840 -> build/qwen3/<kernel>.spv: those of
qwen3/kernels/qwen3k.mojo, plus the ternary projections of bonsai/kernels/kernels.mojo (packed_linear,
packed_reduce, packed_head), unchanged, as bonsai/build_kernels.py compiles them."""

import pathlib
import shutil
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "bonsai"))
import build_kernels as bk  # noqa: E402

F32, U32 = bk.F32, bk.U32
QWEN3 = {  # name: (workgroup size, pointer element types, Int32 scalars)
    "rmsnorm_pack": (64, [F32, F32, U32], 1), "pack_half": (64, [F32, U32], 1), "swiglu_pack": (64, [F32, U32], 1),
    "qk_norm_rope": (64, [F32] * 6, 1), "attn_scores": (64, [F32] * 3, 2), "attn_values": (64, [F32] * 3, 2),
    "add": (64, [F32] * 2, 1),
}
BONSAI = ("packed_linear", "packed_reduce", "packed_head")

if __name__ == "__main__":
    out = bk.ROOT / "build/qwen3"
    bonsai = bk.ROOT / "build/bonsai"
    if not all((bonsai / f"{k}.spv").exists() for k in BONSAI):
        bk.build("kernels", {k: bk.KERNELS[k] for k in BONSAI}, bonsai)
    out.mkdir(parents=True, exist_ok=True)
    for k in BONSAI:
        shutil.copy(bonsai / f"{k}.spv", out / f"{k}.spv")
    bk.HERE = HERE  # -I qwen3/kernels
    bk.build("qwen3k", QWEN3, out)
