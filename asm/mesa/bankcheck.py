"""Count register-bank conflicts in ir3 mad instructions.

Measured rule on the Adreno 840 (asm peak loops, README): a cat3 mad whose three sources are all registers in the
same component (x/y/z/w, of the register as named, also for half registers) runs 3x slower; any two matching is
free; const and immediate sources do not count. (rptN) is expanded: sources marked (r) advance one component per
repeat.

  python3 bankcheck.py file.asm [...]      # per file: mads, conflicting mads, inside the main loop / total
"""
import re, sys

REG = re.compile(r"^(h?)r(\d+)\.([xyzw])$")


def comps(src, k):
    rep = "(r)" in src
    s = re.sub(r"\((r|last|neg|abs)\)", "", src).strip()
    s = s.lstrip("-")
    m = REG.match(s)
    if not m:
        return None
    i = int(m.group(2)) * 4 + "xyzw".index(m.group(3)) + (k if rep else 0)
    return "xyzw"[i % 4]


def scan(lines):
    total = conf = 0
    for l in lines:
        m = re.match(r"^((?:\([^)]*\))*)\s*(mad\.[fsu]\d+|mad\.f16|madsh\.\w+)\s+(.*)$", l)
        if not m:
            continue
        flags, ops = m.group(1), m.group(3)
        rpt = re.search(r"rpt(\d)", flags)
        n = int(rpt.group(1)) + 1 if rpt else 1
        parts = [p.strip() for p in ops.split(",")]
        srcs = parts[1:4]
        for k in range(n):
            total += 1
            c = [comps(s, k) for s in srcs]
            if None not in c and c[0] == c[1] == c[2]:
                conf += 1
    return total, conf


def main():
    for f in sys.argv[1:]:
        L = open(f).read().split("\n")
        loop = L
        for j in range(len(L) - 1, -1, -1):
            mm = re.match(r"^\S*jump #(l\d+)", L[j])
            if mm:
                loop = L[L.index(mm.group(1) + ":"):j]
                break
        t, c = scan(loop)
        T, Cc = scan(L)
        print(f"{f}: loop {c}/{t} mads conflict ({100 * c / max(t, 1):.0f}%), whole shader {Cc}/{T}")


if __name__ == "__main__":
    main()
