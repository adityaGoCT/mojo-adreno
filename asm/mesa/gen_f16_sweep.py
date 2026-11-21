"""fp16 register-placement sweep: which source positions make a 3-register mad.f16 slow?

Template: Turnip's compiled peak_f16_w4_c16_rr (m, d loaded per lane into hr2.x / hr9.y; 64 fp16 mads per
iteration, 512 iterations, 8192 groups x 128 lanes). The loop body is replaced with 64 mads whose accumulator,
m and d registers are chosen here; m, d and the accumulators are copied/initialised before the loop. Every
variant touches hr31.w so the register footprint (16 full regs, 16 waves) is the same for all of them.

layout "s1": mad.f16 acc, acc, m, d   (compiled peak kernel: accumulator is src1)
layout "s3": mad.f16 acc, m, d, acc   (GEMM order: accumulator is src3)

  python3 gen_f16_sweep.py   ->  edits/f16sweep_<name>/<hash>.asm, f16sweep_names.txt
"""
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
H = "13282b39739e61eef5254b7f96ea897fa0ca935a00c63b1c9b1cf6369e8a8ba1"
C = "xyzw"
ALL64 = [f"hr{2 + i // 4}.{C[i % 4]}" for i in range(64)]
LOW32 = [f"hr{2 + i // 2}.{'xz'[i % 2]}" for i in range(32)]
HIGH32 = [f"hr{2 + i // 2}.{'yw'[i % 2]}" for i in range(32)]


def build(tpl, accs, ms, ds, layout):
    L = [l for l in tpl.split("\n") if not l.startswith("@const(")]
    i, j = L.index("l98:"), L.index("jump #l98")
    regs = sorted(set(ms + ds))
    setup = ["(sy)nop"]
    setup += [f"mov.u16u16 {r}, hr2.x" for r in sorted(set(ms))]
    setup += [f"mov.u16u16 {r}, hr9.y" for r in sorted(set(ds))]
    setup += ["mov.u16u16 hr31.w, hr9.y", "(rpt5)nop"]
    setup += [f"mov.u16u16 {a}, {ds[0]}" for a in dict.fromkeys(accs)] + ["(rpt5)nop"]
    body = L[i:i + 3]                                   # label, counter add, compare
    assert body[1].startswith("add.u") and body[2].startswith("cmps"), body
    for k in range(64):
        a, m, d = accs[k % len(accs)], ms[k % len(ms)], ds[k % len(ds)]
        body.append(f"mad.f16 {a}, {a}, {m}, {d}" if layout == "s1" else f"mad.f16 {a}, {m}, {d}, {a}")
    tail = [l for l in L[i + 3:j + 1] if not l.lstrip("(sy)(ss)(rpt1)").startswith("mad.f16") and "mad.f16" not in l]
    return "\n".join(L[:i] + setup + body + tail + L[j + 1:])


def variants():
    v = {}
    for layout in ("s1", "s3"):
        for cm in C:
            for cd in C:
                v[f"e1{layout}_m{cm}_d{cd}"] = (ALL64, [f"hr20.{cm}"], [f"hr21.{cd}"], layout)
        for an, accs in (("lo", LOW32), ("hi", HIGH32)):
            for cm in "xy":
                for cd in "xy":
                    v[f"e2{layout}_acc{an}_m{cm}_d{cd}"] = (accs, [f"hr20.{cm}"], [f"hr21.{cd}"], layout)
    v["e4s1_mrot_dy"] = (ALL64, [f"hr20.{c}" for c in C], ["hr21.y"], "s1")
    v["e4s1_mx_drot"] = (ALL64, ["hr20.x"], [f"hr21.{c}" for c in C], "s1")
    v["e4s1_mrot_drot"] = (ALL64, [f"hr20.{c}" for c in C], [f"hr21.{c}" for c in "yzwx"], "s1")
    return v


def main():
    tpl = (HERE / "asm_final_peak_nb" / f"{H}.asm").read_text()
    names = []
    for name, (accs, ms, ds, layout) in variants().items():
        d = HERE / "edits" / f"f16sweep_{name}"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{H}.asm").write_text(build(tpl, accs, ms, ds, layout))
        names.append(name)
    (HERE / "f16sweep_names.txt").write_text("\n".join(names) + "\n")
    print(len(names), "variants")


if __name__ == "__main__":
    main()
