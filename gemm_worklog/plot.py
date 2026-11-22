"""The worklog chart from results/run_4096_headline.txt (run.sh output, three rounds): median per kernel.
Writes ../docs/img/worklog-steps.png and prints the table.
  python3 plot.py"""
import pathlib, re
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

HERE = pathlib.Path(__file__).resolve().parent
IMG = HERE.parent / "docs" / "img"
SURFACE, INK, INK2, GRID, REF = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df", "#8a8984"
BLUE, ORANGE = "#2a78d6", "#eb6834"
plt.rcParams.update({"font.size": 10, "axes.edgecolor": GRID, "axes.labelcolor": INK2, "xtick.color": INK2,
                     "ytick.color": INK, "figure.facecolor": SURFACE, "axes.facecolor": SURFACE})

def results(path):
    runs = {}
    for line in open(path):
        m = re.match(r"RESULT (\S+?)(?:\.spv)? ([\d.]+) TFLOP/s ([\d.]+) us err (\S+) (\w+)", line)
        if m:
            assert m.group(5) == "PASS", line
            runs.setdefault(m.group(1), []).append(float(m.group(2)))
    return {k: dict(tf=sorted(v)[len(v) // 2], all=v) for k, v in runs.items()}

def bars(ax, y, vals, colors, h=0.62):
    for yi, v, c in zip(y, vals, colors):  # rounded data end, square at the baseline
        ax.add_patch(FancyBboxPatch((0, yi - h / 2), v, h, boxstyle="round,pad=0,rounding_size=0.12",
                                    mutation_aspect=1 / 6, fc=c, ec="none"))
        ax.add_patch(plt.Rectangle((0, yi - h / 2), min(v, 0.3), h, fc=c, ec="none"))

STEPS = [  # (label, kernel, group)
    ("1  naive", "01_naive", "alu"),
    ("2  coalesced", "02_coalesced", "alu"),
    ("3  readonly inputs", "03_readonly", "alu"),
    ("4  shared-memory tiles", "04_shared", "alu"),
    ("5  1D register tiles", "05_1d_tiling", "alu"),
    ("6  2D register tiles", "06_2d_tiling", "alu"),
    ("7  128-bit loads", "07_vectorized", "alu"),
    ("8  fp16 arithmetic", "08_fp16_math", "alu"),
    ("9  tile-size sweep (best)", "09_alu_b64x128x16_t8x8", "alu"),
    ("10  matrix units", "10_coopmat", "mx"),
    ("11  A stored K-major", "11_kmajor", "mx"),
    ("12  packed panels", "12_panels", "mx"),
    ("13  one 64x64 tile per subgroup", "13_tile64", "mx"),
    ("14  4x2 subgroups per workgroup", "14_wg_4x2", "mx"),
    ("15  K contiguous in tiles", "15_kminor_2x2", "mx"),
]

def step_values(r):
    return [(label, key, r[key]["tf"], grp) for label, key, grp in STEPS]

def main():
    r = results(HERE / "results" / "run_4096_headline.txt")
    sv = step_values(r)
    fig, ax = plt.subplots(figsize=(8.6, 6.4))
    fig.subplots_adjust(left=0.30, right=0.95, top=0.84, bottom=0.09)
    y = list(range(len(sv)))[::-1]
    bars(ax, y, [v for _, _, v, _ in sv], [BLUE if g == "alu" else ORANGE for *_, g in sv])
    for yi, (_, _, v, _) in zip(y, sv):
        lab = f"{v:.3f}" if v < 0.1 else f"{v:.2f}" if v < 1 else f"{v:.1f}"
        if v > 16:  # would run into the peak line: inside the bar end
            ax.text(v - 0.2, yi, lab, va="center", ha="right", color=INK, fontsize=9)
        else:
            ax.text(v + 0.18, yi, lab, va="center", color=INK, fontsize=9)
    ax.set_yticks(y)
    ax.set_yticklabels([l for l, *_ in sv])
    ax.set_xlim(0, 19.5)
    ax.set_ylim(-0.7, len(sv) - 0.3)
    ax.set_xlabel("TFLOP/s, fp16 GEMM 4096 x 4096 x 4096")
    ax.grid(axis="x", color=GRID, lw=0.8)
    ax.set_axisbelow(True)
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)
    ax.tick_params(axis="y", length=0)
    for x, lab, yy in [(8.36, "ALU peak 8.36", len(sv) - 1.0), (17.5, "matrix peak 17.5", len(sv) - 1.0)]:
        ax.axvline(x, color=REF, lw=1, ls=(0, (3, 2)))
        ax.text(x - 0.15, yy, lab, color=INK2, fontsize=8.5, va="center", ha="right")
    h = [plt.Rectangle((0, 0), 1, 1, fc=BLUE), plt.Rectangle((0, 0), 1, 1, fc=ORANGE)]
    ax.legend(h, ["ALUs (shader cores)", "matrix units (cooperative matrices)"], loc="upper right", bbox_to_anchor=(1.0, 0.9), frameon=False, fontsize=9)
    fig.text(0.015, 0.97, "Fifteen kernels, one GEMM, one phone GPU", color=INK, fontsize=12, fontweight="bold", va="top")
    fig.text(0.015, 0.925, "Adreno 850 (SM8975), fp16 in and out, 4096 x 4096 x 4096; median of three cooled runs per kernel",
             color=INK2, fontsize=9.5, va="top")
    IMG.mkdir(parents=True, exist_ok=True)
    fig.savefig(IMG / "worklog-steps.png", dpi=160)
    print("wrote", IMG / "worklog-steps.png")
    prev = None
    for label, name, v, _ in sv:
        print(f"{label:34s} {name:28s} median {v:7.3f}  rounds {r[name]['all']}  x{v / prev if prev else 0:.2f}  {100 * v / 17.5:.1f}%")
        prev = v
    if "16_adrenoblas_gRC_w2x2" in r:
        print("AdrenoBLAS generated kernel:", r["16_adrenoblas_gRC_w2x2"])

main()
