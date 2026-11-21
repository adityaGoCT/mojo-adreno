"""Hand-written peak-ALU loops in ir3 assembly, injected through IR3_SHADER_OVERRIDE_PATH.

The template is Turnip's own compiled peak_f32_w2_c16 (dumps/: blake3 fdf23a19...): its preamble (m, d -> c0.x,
c0.y as fp32), accumulator setup (r1.x..r8.w), loop counter (shared reg r49.z vs c5.x = 512) and epilogue are
kept; only the loop body is replaced. Each variant goes to edits/<name>/<hash>.asm and a manifest line with its
FLOP count (the kernel is still launched as peak_f32_w2_c16.spv: 8192 groups x 128 lanes x 512 iterations).

Accumulators: fp32 r1.x..r8.w (32), fp16 hr2.x..hr17.w (64; merged register file, same storage).
Register operands: m in r9.*/hr18.*, d in r10.*/hr19.* (set up before the loop).
"""
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
H = "fdf23a19210f62b9f92556aac599fc0002237ec1220da00824725cf5aecd5d98"
C = "xyzw"
ITERS, LOCAL, GROUPS = 512, 128, 8192


def acc32(i):
    return f"r{1 + i // 4}.{C[i % 4]}"


def acc16(i):
    return f"hr{2 + i // 4}.{C[i % 4]}"


SETUP32 = [f"mov.u32u32 r9.{c}, c0.x" for c in C] + [f"mov.u32u32 r10.{c}, c0.x" for c in "x"] + \
          [f"mov.u32u32 r10.{c}, c0.y" for c in "yzw"] + [f"mov.u32u32 r11.{c}, c0.y" for c in C] + ["(rpt5)nop"]
SETUP16 = [f"cov.f32f16 hr18.{c}, c0.x" for c in C] + [f"cov.f32f16 hr19.{c}, c0.y" for c in C] + \
          [f"cov.f32f16 hr20.{c}, c0.y" for c in C] + ["(rpt5)nop"]


def variants():
    v = {}
    v["f32_cc"] = ([], [f"mad.f32 {acc32(i)}, c0.x, {acc32(i)}, c0.y" for i in range(32)], 32)
    v["f32_cc_rpt3"] = ([], [f"(rpt3)mad.f32 r{n}.x, c0.x, (r)r{n}.x, c0.y" for n in range(1, 9)], 32)
    v["f32_rr_same"] = (SETUP32, [f"mad.f32 {acc32(i)}, r9.{C[i % 4]}, {acc32(i)}, r11.{C[i % 4]}" for i in range(32)], 32)
    v["f32_rr_diff"] = (SETUP32, [f"mad.f32 {acc32(i)}, r9.{C[(i + 1) % 4]}, {acc32(i)}, r11.{C[(i + 2) % 4]}"
                                  for i in range(32)], 32)
    # all three operands repeat through the same components (x,y,z,w) ...
    v["f32_rr_same_rpt3"] = (SETUP32, [f"(rpt3)mad.f32 r{n}.x, (r)r9.x, (r)r{n}.x, (r)r11.x" for n in range(1, 9)], 32)
    # ... or are staggered by one and two components (m: r9.y..r10.x, d: r10.z..r11.y)
    v["f32_rr_diff_rpt3"] = (SETUP32, [f"(rpt3)mad.f32 r{n}.x, (r)r9.y, (r)r{n}.x, (r)r10.z" for n in range(1, 9)], 32)
    v["f16_cc"] = ([], [f"mad.f16 {acc16(i)}, hc0.x, {acc16(i)}, hc0.y" for i in range(64)], 64)
    v["f16_cc_rpt3"] = ([], [f"(rpt3)mad.f16 hr{n}.x, hc0.x, (r)hr{n}.x, hc0.y" for n in range(2, 18)], 64)
    v["f16_rr_same"] = (SETUP16, [f"mad.f16 {acc16(i)}, hr18.{C[i % 4]}, {acc16(i)}, hr19.{C[i % 4]}" for i in range(64)], 64)
    v["f16_rr_diff"] = (SETUP16, [f"mad.f16 {acc16(i)}, hr18.{C[(i + 1) % 4]}, {acc16(i)}, hr19.{C[(i + 2) % 4]}"
                                  for i in range(64)], 64)
    # Which operand pairs conflict? GEMM operand order: mad acc, src1=m, src2=d, src3=acc. Offsets are the
    # component of m / d / acc relative to the accumulator's component.
    for tag, om, od in (("p12", 1, 1), ("p13", 0, 1), ("p23", 1, 0), ("pall", 0, 0), ("pnone", 1, 2)):
        v[f"f32_{tag}"] = (SETUP32, [f"mad.f32 {acc32(i)}, r9.{C[(i + om) % 4]}, r11.{C[(i + od) % 4]}, {acc32(i)}"
                                     for i in range(32)], 32)
        v[f"f16_{tag}"] = (SETUP16, [f"mad.f16 {acc16(i)}, hr18.{C[(i + om) % 4]}, hr20.{C[(i + od) % 4]}, {acc16(i)}"
                                     for i in range(64)], 64)
    # fp32: three sources with the same component parity but not the same letter (acc c, m c+2, d c / c+2)
    for tag, om, od in (("par_m2d0", 2, 0), ("par_m2d2", 2, 2), ("par_m0d2", 0, 2)):
        v[f"f32_{tag}"] = (SETUP32, [f"mad.f32 {acc32(i)}, r9.{C[(i + om) % 4]}, r11.{C[(i + od) % 4]}, {acc32(i)}"
                                     for i in range(32)], 32)
    return v


def build(template, setup, body):
    L = template.split("\n")
    L = [l for l in L if not l.startswith("@const(")]   # compiled immediates stay; re-adding shifts them (README)
    i, j = L.index("l70:"), L.index("(ss)br p0.y, #l98")
    return "\n".join(L[:i] + setup + ["l70:", "add.u r49.z, r49.z, 1", "cmps.s.ge up0.y, r49.z, c5.x"] + body + L[j:])


def main():
    tpl = (HERE / "asm_dump" / f"{H}.asm").read_text()
    man = []
    for name, (setup, body, fma) in variants().items():
        d = HERE / "edits" / f"asmpeak_{name}"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{H}.asm").write_text(build(tpl, setup, body))
        man.append(f"asmpeak_{name} shape/peak 64 1 spv/peak_f32_w2_c16.spv {GROUPS} 1 1 # flops={ITERS * LOCAL * fma * 2}")
    (HERE / "manifest_asmpeak.txt").write_text("\n".join(man) + "\n")
    print("\n".join(man))


if __name__ == "__main__":
    main()
