"""Count register-bank conflicts in ir3 mad instructions.

Measured rule on the Adreno 840 (asm peak loops and the fp16 placement sweep, README): a cat3 mad whose three
sources are registers whose scalar indices all have the same parity runs ~3x slower: for full registers all in
{x,z} or all in {y,w}; for half registers all in the low (.x/.z) or all in the high (.y/.w) 16-bit halves. Any
mix is free; const and immediate sources do not count. (rptN) is expanded: sources marked (r) advance one
component per repeat. --comp counts the older, narrower same-component rule instead.

  python3 bankcheck.py file.asm [...]      # per file: mads, conflicting mads, inside the main loop / total
"""
import re, sys

COMP = "--comp" in sys.argv

REG = re.compile(r"^(h?)r(\d+)\.([xyzw])$")


def comps(src, k):
    rep = "(r)" in src
    s = re.sub(r"\((r|last|neg|abs)\)", "", src).strip()
    s = s.lstrip("-")
    m = REG.match(s)
    if not m:
        return None
    i = int(m.group(2)) * 4 + "xyzw".index(m.group(3)) + (k if rep else 0)
    return i % (4 if COMP else 2)


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
    for f in [a for a in sys.argv[1:] if not a.startswith("--")]:
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
