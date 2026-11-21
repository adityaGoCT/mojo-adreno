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

def frame(ax, xmax, title, sub):
    ax.set_xlim(0, xmax)
    ax.grid(axis="x", color=GRID, lw=0.8)
    ax.set_axisbelow(True)
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlabel("TFLOP/s")
    fig = ax.figure  # title and subtitle anchored at the figure's left edge (long y labels push the axes right)
    fig.text(0.015, 0.97, title, color=INK, fontsize=12, fontweight="bold", va="top")
    fig.text(0.015, 0.905, sub, color=INK2, fontsize=9.5, va="top")

def ref(ax, x, label, y, ha="left"):
    ax.axvline(x, color=REF, lw=1)
    ax.text(x + (0.15 if ha == "left" else -0.15), y, label, color=INK2, fontsize=8.5, va="center", ha=ha)

def progress():
    rows = [("Start: Mojo cooperative-matrix kernel (tuned on the 840)", 4.25),
            ("Generated kernels, A stored [M,K] (NN)", 8.17),
            ("A stored [K,M] (TN): 128-byte tile rows", 10.81),
            ("AdrenoBLAS library call, TN", 11.02),
            ("4096³, TN", 8.77),
            ("4096³, operands in panels", 12.78)]
    fig, ax = plt.subplots(figsize=(8.4, 4.2), dpi=150)
    y = list(range(len(rows)))[::-1]
    bars(ax, y, [v for _, v in rows], BLUE, 0.5)
    for yi, (_, v) in zip(y, rows):
        ax.text(v + 0.2, yi, f"{v:.2f}", va="center", color=INK, fontsize=9)
    ax.set_yticks(y, [r for r, _ in rows])
    ax.axhline(1.5, color=GRID, lw=0.8)
    frame(ax, 19, "fp16 GEMM on the Adreno 850, step by step", "2048³ unless marked; every kernel checked against an fp32 reference")
    ax.set_ylim(-0.6, len(rows) - 0.1)
    ref(ax, 8.36, "fp16 ALU peak 8.36", len(rows) - 0.4, "right")
    ref(ax, 17.5, "matrix peak 17.5", len(rows) - 0.4, "right")
    fig.tight_layout(rect=(0, 0, 1, 0.86))
    fig.savefig(OUT / "ablas-progress.png")

def layouts():
    lays = ["TN  A [K,M], B [K,N]", "NN  A [M,K], B [K,N]", "TT  A [K,M], B [N,K]", "NT  A [M,K], B [N,K]"]
    direct = [10.81, 8.17, 7.60, 2.38]
    packed = [11.02, 9.60, 9.59, 8.52]
    fig, ax = plt.subplots(figsize=(8.4, 3.7), dpi=150)
    y = [3, 2, 1, 0]
    bars(ax, [v + 0.16 for v in y], direct, ORANGE, 0.28)
    bars(ax, [v - 0.16 for v in y], packed, BLUE, 0.28)
    for yi, d, p in zip(y, direct, packed):
        ax.text(d + 0.15, yi + 0.16, f"{d:.1f}", va="center", color=INK2, fontsize=8.5)
        ax.text(p + 0.15, yi - 0.16, f"{p:.1f}", va="center", color=INK, fontsize=8.5)
    ax.set_yticks(y, lays)
    frame(ax, 13, "Layout matters: 2048³ by operand layout", "C = A·B, fp16; direct kernel for the layout vs the library, which packs operands to TN first")
    ax.set_ylim(-0.55, 3.55)
    h1 = plt.Rectangle((0, 0), 1, 1, fc=ORANGE); h2 = plt.Rectangle((0, 0), 1, 1, fc=BLUE)
    ax.legend([h1, h2], ["direct kernel", "library (packs to TN)"], loc="lower right", frameon=False, fontsize=9)
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

if __name__ == "__main__":
    progress(); layouts(); peaks()
    print("wrote", sorted(p.name for p in OUT.glob("ablas-*.png")))
