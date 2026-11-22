"""Figures for BLOG-ABLAS.md (docs/img/ablas-*.png). Numbers are the measurements quoted in the post."""
import pathlib
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

OUT = pathlib.Path(__file__).resolve().parent.parent / "docs/img"
SURFACE, INK, INK2, GRID, REF = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df", "#8a8984"
BLUE, ORANGE = "#2a78d6", "#eb6834"
plt.rcParams.update({"font.size": 10, "axes.edgecolor": GRID, "axes.labelcolor": INK2, "xtick.color": INK2,
                     "ytick.color": INK, "figure.facecolor": SURFACE, "axes.facecolor": SURFACE})

def bars(ax, y, vals, color, h):
    for yi, v in zip(y, vals):  # 4px-ish rounded data end, square at the baseline
        ax.add_patch(FancyBboxPatch((0, yi - h / 2), v, h, boxstyle="round,pad=0,rounding_size=0.06",
                                    mutation_aspect=1 / 18, fc=color, ec="none"))
        ax.add_patch(plt.Rectangle((0, yi - h / 2), min(v, 0.3), h, fc=color, ec="none"))

def frame(ax, xmax, title, sub, xlabel="TFLOP/s"):
    ax.set_xlim(0, xmax)
    ax.grid(axis="x", color=GRID, lw=0.8)
    ax.set_axisbelow(True)
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlabel(xlabel)
    fig = ax.figure  # title and subtitle anchored at the figure's left edge (long y labels push the axes right)
    fig.text(0.015, 0.97, title, color=INK, fontsize=12, fontweight="bold", va="top")
    fig.text(0.015, 0.905, sub, color=INK2, fontsize=9.5, va="top")

def ref(ax, x, label, y, ha="left", dx=0.15):
    ax.axvline(x, color=REF, lw=1)
    ax.text(x + (dx if ha == "left" else -dx), y, label, color=INK2, fontsize=8.5, va="center", ha=ha)

def progress():
    rows = [("Start: Mojo cooperative-matrix kernel (tuned on the 840)", 4.25),
            ("Generated kernels, A stored [M,K] (NN)", 8.17),
            ("A stored [K,M] (TN): 128-byte tile rows", 10.81),
            ("Panels, one 64×64 tile per subgroup", 13.94),
            ("+ K contiguous inside each tile", 14.71),
            ("4096³, TN", 8.77),
            ("4096³, panels, 64×32 tiles", 12.78),
            ("4096³, panels, one 64×64 tile per subgroup", 15.34),
            ("4096³, + K contiguous inside each tile", 16.36),
            ("4096² × 8192, same kernel", 16.99)]
    fig, ax = plt.subplots(figsize=(8.4, 5.6), dpi=150)
    y = list(range(len(rows)))[::-1]
    bars(ax, y, [v for _, v in rows], BLUE, 0.5)
    for yi, (_, v) in zip(y, rows):
        ax.text(v + 0.2, yi, f"{v:.2f}", va="center", color=INK, fontsize=9)
    ax.set_yticks(y, [r for r, _ in rows])
    ax.axhline(4.5, color=GRID, lw=0.8)
    frame(ax, 19, "fp16 GEMM on the Adreno 850, step by step", "2048³ unless marked; library calls with operands pre-packed where noted; every call checked against fp32")
    ax.set_ylim(-0.6, len(rows) - 0.1)
    ref(ax, 8.36, "fp16 ALU peak 8.36", len(rows) - 0.4, "right")
    ref(ax, 17.5, "matrix peak 17.5", len(rows) - 0.4, "right")
    fig.tight_layout(rect=(0, 0, 1, 0.86))
    fig.savefig(OUT / "ablas-progress.png")

def layouts():
    lays = ["TN  A [K,M], B [K,N]", "NN  A [M,K], B [K,N]", "TT  A [K,M], B [N,K]", "NT  A [M,K], B [N,K]"]
    direct = [10.81, 8.17, 7.60, 2.38]
    packed = [11.63, 9.71, 9.72, 10.72]
    fig, ax = plt.subplots(figsize=(8.4, 4.0), dpi=150)
    y = [3, 2, 1, 0]
    bars(ax, [v + 0.16 for v in y], direct, ORANGE, 0.28)
    bars(ax, [v - 0.16 for v in y], packed, BLUE, 0.28)
    for yi, d, p in zip(y, direct, packed):
        ax.text(d + 0.15, yi + 0.16, f"{d:.1f}", va="center", color=INK2, fontsize=8.5)
        ax.text(p + 0.15, yi - 0.16, f"{p:.1f}", va="center", color=INK, fontsize=8.5)
    ax.set_yticks(y, lays)
    frame(ax, 16, "Layout matters: 2048³ by operand layout", "C = A·B, fp16; direct 64×32-tile kernel for the layout vs the library, which packs operands first")
    ax.set_ylim(-0.55, 3.7)
    h1 = plt.Rectangle((0, 0), 1, 1, fc=ORANGE); h2 = plt.Rectangle((0, 0), 1, 1, fc=BLUE)
    ax.axvline(14.71, color=REF, lw=1)
    ax.text(14.56, 3.42, "operands pre-packed 14.7", color=INK2, fontsize=8.5, va="center", ha="right")
    ax.legend([h1, h2], ["direct kernel", "library (packs operands)"], loc="upper center", bbox_to_anchor=(0.5, -0.2),
              ncol=2, frameon=False, fontsize=9)
    fig.tight_layout(rect=(0, 0, 1, 0.84))
    fig.savefig(OUT / "ablas-layouts.png")

def peaks():
    rows = [("fp32 multiply-add (ALU)", 4.41), ("fp32 cooperative matrix", 4.05), ("fp16 multiply-add (ALU)", 8.36),
            ("fp16 cooperative matrix, fp32 accumulate", 15.93), ("fp16 cooperative matrix, fp16 accumulate", 17.54)]
    fig, ax = plt.subplots(figsize=(8.4, 3.3), dpi=150)
    y = list(range(len(rows)))[::-1]
    bars(ax, y, [v for _, v in rows], BLUE, 0.5)
    for yi, (_, v) in zip(y, rows):
        ax.text(v + 0.2, yi, f"{v:.2f}", va="center", color=INK, fontsize=9)
    ax.set_yticks(y, [r for r, _ in rows])
    frame(ax, 20, "What the Adreno 850 can do", "measured peaks at 1.45 GHz, stock Vulkan driver")
    ax.set_ylim(-0.6, len(rows) - 0.4)
    fig.tight_layout(rect=(0, 0, 1, 0.82))
    fig.savefig(OUT / "ablas-peaks.png")

GRAY = "#9b9a95"

def llama():
    """Llama 3.2 3B prefill, tokens/s by prompt length: llama.cpp OpenCL Q4_0 vs AdrenoBLAS fp16 and Q4_0 (cooled)."""
    Ms = ["512 tokens", "1,024 tokens", "2,048 tokens"]
    lcpp, f16, q4 = [456, 418, 366], [2318, 2305, 2143], [2602, 2410, 2248]
    fig, ax = plt.subplots(figsize=(8.4, 4.4), dpi=150)
    y = [2, 1, 0]
    h = 0.24
    for off, vals, col in ((0.27, q4, BLUE), (0.0, f16, ORANGE), (-0.27, lcpp, GRAY)):
        bars(ax, [v + off for v in y], vals, col, h)
        for yi, v in zip(y, vals):
            ax.text(v + 30, yi + off, f"{v:,}", va="center", color=INK, fontsize=8.5)
    ax.set_yticks(y, Ms)
    frame(ax, 3000, "Llama 3.2 3B prefill on the Adreno 850",
          "tokens/s, every GEMM through AdrenoBLAS; llama.cpp 1fdda89 OpenCL (Adreno kernels), same Q4_0 weights; cooled runs",
          "tokens/s")
    ax.set_ylim(-0.6, 2.6)
    for b in ax.patches:  # FancyBboxPatch rounding is in data units: rescale for the tokens/s axis
        if isinstance(b, FancyBboxPatch):
            b.set_mutation_aspect(1 / 3000)
    hs = [plt.Rectangle((0, 0), 1, 1, fc=c) for c in (BLUE, ORANGE, GRAY)]
    ax.legend(hs, ["AdrenoBLAS, Q4_0", "AdrenoBLAS, fp16", "llama.cpp OpenCL, Q4_0"], loc="upper center",
              bbox_to_anchor=(0.5, -0.17), ncol=3, frameon=False, fontsize=9)
    fig.tight_layout(rect=(0, 0, 1, 0.86))
    fig.savefig(OUT / "ablas-llama3b.png")

def llama_steps():
    rows = [("First correct version (GEMMs in AdrenoBLAS)", 1647),
            ("Elementwise kernels write whole tiles", 2087),
            ("Flash attention (two-pass, shared-memory scores)", 2166),
            ("SwiGLU fused into the gate/up GEMM", 2388),
            ("RoPE fused into qkv; residual + RMS into o/down", 2560),
            ("Flash attention, score work split (fa3)", 2588),
            ("Tuned for the model's shapes (cooled)", 2602)]
    fig, ax = plt.subplots(figsize=(8.4, 4.2), dpi=150)
    y = list(range(len(rows)))[::-1]
    bars(ax, y, [v for _, v in rows], BLUE, 0.5)
    for b in ax.patches:
        if isinstance(b, FancyBboxPatch):
            b.set_mutation_aspect(1 / 3000)
    for yi, (_, v) in zip(y, rows):
        ax.text(v + 30, yi, f"{v:,}", va="center", color=INK, fontsize=9)
    ax.set_yticks(y, [r for r, _ in rows])
    frame(ax, 3000, "Llama 3.2 3B prefill, Q4_0, 512 tokens, step by step",
          "tokens/s on the Adreno 850; llama.cpp OpenCL with the same weights: 456", "tokens/s")
    ax.set_ylim(-0.6, len(rows) - 0.4)
    ref(ax, 456, "llama.cpp 456", len(rows) - 0.55, dx=25)
    fig.tight_layout(rect=(0, 0, 1, 0.84))
    fig.savefig(OUT / "ablas-llama3b-steps.png")

if __name__ == "__main__":
    progress(); layouts(); peaks(); llama(); llama_steps()
    print("wrote", sorted(p.name for p in OUT.glob("ablas-*.png")))
