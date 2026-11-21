"""Small edits on ir3 .asm dumps (for diagnostics; the results of a stripped kernel are wrong by design).

  python3 asm_edit.py strip <in.asm> <out.asm> <regex>    # delete matching instructions inside the main loop
  python3 asm_edit.py noconst <in.asm> <out.asm>          # drop @const lines (see README: they are re-added at
                                                          # an offset on override; the compiled values stay)

The main loop is the last `lN:` label that a later `jump #lN` targets.
"""
import re, sys


def loop_range(L):
    for j in range(len(L) - 1, -1, -1):
        m = re.match(r"^\S*jump #(l\d+)", L[j])
        if m:
            i = L.index(m.group(1) + ":")
            return i, j
    raise SystemExit("no loop")


def main():
    cmd, src, dst = sys.argv[1:4]
    L = open(src).read().split("\n")
    if cmd == "strip":
        rx = re.compile(r"^(\([^)]*\))*\s*" + sys.argv[4])
        i, j = loop_range(L)
        keep = [l for n, l in enumerate(L) if not (i < n < j and rx.match(l))]
        print(f"loop lines {i + 1}-{j + 1}: removed {len(L) - len(keep)}")
        L = keep
    elif cmd == "noconst":
        L = [l for l in L if not l.startswith("@const(")]
    open(dst, "w").write("\n".join(L))


if __name__ == "__main__":
    main()
