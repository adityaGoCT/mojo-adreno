"""Tables for the fp16 placement sweep (gen_f16_sweep.py). TFLOP/s per variant from results/f16sweep_<name>.jsonl."""
import json, pathlib

HERE = pathlib.Path(__file__).resolve().parent


def tf(name):
    p = HERE / "results" / f"f16sweep_{name}.jsonl"
    if not p.exists():
        return None
    rows = [json.loads(l) for l in p.read_text().splitlines() if l.strip()]
    return max(r.get("tflops", 0) for r in rows)


def fmt(x):
    return f"{x:5.2f}" if x else "  -  "


def main():
    for layout, desc in (("s1", "mad acc, acc, m, d"), ("s3", "mad acc, m, d, acc")):
        print(f"\nE1 {layout} ({desc}); accumulators hr2.x..hr17.w; rows m = hr20.c, columns d = hr21.c")
        print("       d.x   d.y   d.z   d.w")
        for cm in "xyzw":
            print(f"m.{cm}  " + " ".join(fmt(tf(f"e1{layout}_m{cm}_d{cd}")) for cd in "xyzw"))
        print(f"E2 {layout}: accumulators only in low (.x/.z) or high (.y/.w) halves")
        print("            m.x d.x  m.x d.y  m.y d.x  m.y d.y")
        for an in ("lo", "hi"):
            print(f"  acc {an}   " + "  ".join(fmt(tf(f"e2{layout}_acc{an}_m{cm}_d{cd}")) + "  "
                                      for cm in "xy" for cd in "xy"))
    print("\nE4 (s1): operand reuse")
    for n in ("e4s1_mrot_dy", "e4s1_mx_drot", "e4s1_mrot_drot"):
        print(f"  {n:16s} {fmt(tf(n))}")


if __name__ == "__main__":
    main()
