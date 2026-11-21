"""Post-schedule register renaming for the register-bank rule (prototype of an ir3 pass that would run between
ir3_postsched and ir3_merge_rpt), applied to a final ir3 disassembly.

The instruction order and sync flags stay exactly as Turnip scheduled them. Inside the main loop, a loaded
operand vector (isam / ldl destination) is moved to other registers only if those are idle for the vector's
whole lifetime: not accessed between the load and the vector's last use, holding no live value (their next
access afterwards is a write), and not last read by an asynchronous instruction (no new WAR hazard). The move is
taken only if it reduces the mads whose three register sources share a bank (register-index parity). The
register footprint is never grown.

  python3 bank_rename.py <in.asm> <out.asm> [--grow N]   # --grow: allow N more full vec4 registers (default 0)
"""
import re, sys

TOK = re.compile(r"((?:\((?:r|last|neg|abs)\))*)(h?)r(\d+)\.([xyzw])")
C = "xyzw"


class Ins:
    def __init__(self, pos, line):
        self.pos, self.line = pos, line
        m = re.match(r"^((?:\([^)]*\))*)\s*([a-z][\w.]*)\s*(.*)$", line)
        self.flags, self.op, self.args = (m.group(1), m.group(2), m.group(3)) if m else ("", "", "")
        r = re.search(r"rpt(\d)", self.flags)
        self.rpt = int(r.group(1)) + 1 if r else 1
        self.kind = self.classify()

    def classify(self):
        op = self.op
        if op.startswith(("nop", "br", "jump", "end", "bar", "fence", "shps", "shpe", "getone", "predt", "prede")):
            return "ctl"
        if op.startswith(("isam", "sam")):
            return "tex"
        if op.startswith("ldl"):
            return "ldl"
        if op.startswith(("stl", "stib", "stg")):
            return "store"
        if re.match(r"^(mad|add|sub|mul|shl|shr|and|or|xor|sad|sel|cmps|cmpv|mov|cov|absneg|min|max|not|rcp|rsq|sqrt|"
                    r"floor|ceil|rndne|sign|bary|cbits|clz|madsh|mull|dp)", op):
            return "alu"
        return "unknown"

    def half16(self):
        return bool(re.search(r"\.(u16|s16|f16|b16)\b", self.op))


def units(half, num, comps):
    """register index -> merged half-register units"""
    if half:
        return [num + i for i in range(comps)]
    return [u for i in range(comps) for u in (2 * (num + i), 2 * (num + i) + 1)]


def tokens(ins):
    """[(role, start_char, end_char, half, printed_h, num, comps, rflag)] for GPR operands of an instruction."""
    out = []
    parts, depth, cur, starts, start = [], 0, "", [], 0
    s = ins.args
    for k, ch in enumerate(s):
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append((start, k)); start = k + 1
    parts.append((start, len(s)))
    base = len(ins.line) - len(s)
    vec = None
    mm = re.search(r",\s*(\d+)\s*$", s)
    if ins.kind in ("ldl", "store") and mm:
        vec = int(mm.group(1))
    wm = re.search(r"\(([xyzw]+)\)(?=h?r\d)", s)
    for idx, (a, b) in enumerate(parts):
        for t in TOK.finditer(s, a, b):
            pre, h, n, c = t.group(1), t.group(2), int(t.group(3)), t.group(4)
            num = n * 4 + C.index(c)
            half = bool(h) or (ins.kind in ("ldl", "store") and ins.half16() and "[" not in s[a:t.start()])
            if not half and num >= 48 * 4:
                continue                                            # shared registers: other file
            if half and num >= 48 * 4:
                continue
            inbr = "[" in s[a:t.start()]
            comps = 1
            if ins.kind == "tex" and idx == 0:
                comps = len(wm.group(1)) if wm else 1
            elif ins.kind == "ldl" and idx == 0:
                comps = vec or 1
            elif ins.kind == "store" and not inbr and idx == 1:
                comps = vec or 1
            elif ins.kind == "store" and h and idx == 0:
                comps = vec or 4                                     # stib value operand
            role = "W" if (idx == 0 and ins.kind in ("alu", "tex", "ldl")) else "R"
            if ins.kind == "unknown":
                role = "RW"
            out.append(dict(role=role, a=base + t.start(2), b=base + t.end(),
                            pstart=base + t.start(), half=half, ph=bool(h), num=num, comps=comps,
                            r="(r)" in pre))
    return out


def accesses(block):
    acc = {}
    for ins in block:
        for t in tokens(ins):
            for k in range(ins.rpt):
                if ins.rpt > 1 and not (t["r"] or t["role"] == "W"):
                    off = 0
                else:
                    off = k if ins.rpt > 1 else 0
                for u in units(t["half"], t["num"] + off, t["comps"]):
                    for role in t["role"]:
                        acc.setdefault(u, []).append((ins.pos, role, ins, t))
    for u in acc:
        acc[u].sort(key=lambda x: (x[0], 0 if x[1] == "R" else 1))
    return acc


def parity(t, num):
    return num % 2


def mad_conflicts(block, rename=None):
    """count mads (expanded) whose three register sources share register-index parity."""
    n = 0
    for ins in block:
        if not ins.op.startswith("mad"):
            continue
        ts = [t for t in tokens(ins) if t["role"] == "R"]
        if len(ts) != 3 or len(re.findall(r",", ins.args)) != 3:
            continue
        for k in range(ins.rpt):
            par = []
            for t in ts:
                num = t["num"] + (k if (t["r"] and ins.rpt > 1) else 0)
                if rename:
                    num = rename(ins, t, num)
                par.append(num % 2)
            if par[0] == par[1] == par[2]:
                n += 1
    return n


def regname(t, num):
    return f"{'h' if t['ph'] else ''}r{num // 4}.{C[num % 4]}"


def rewrite(line, edits):
    for a, b, new in sorted(edits, reverse=True):
        line = line[:a] + new + line[b:]
    return line


def main():
    src, dst = sys.argv[1], sys.argv[2]
    grow = int(sys.argv[sys.argv.index("--grow") + 1]) if "--grow" in sys.argv else 0
    L = open(src).read().split("\n")
    j = max(i for i, l in enumerate(L) if re.match(r"^\S*jump #(l\d+)", l))
    i = L.index(re.match(r"^\S*jump #(l\d+)", L[j]).group(1) + ":")
    maxreg = 0
    for l in L:
        if l.startswith((";", "@")):
            continue
        for t in TOK.finditer(l):
            n = int(t.group(3))
            full = n // 2 if t.group(2) else n
            if full < 48:
                maxreg = max(maxreg, full)
    limit = 8 * (maxreg + 1 + grow)                                 # half units
    def touched():
        used = set()
        for p, l in enumerate(L):
            if l.startswith((";", "@")) or not l.strip():
                continue
            ins = Ins(p, l)
            for t in tokens(ins):
                used |= set(units(t["half"], t["num"], t["comps"] + (ins.rpt - 1 if t["r"] else 0)))
        return used
    moved = 0
    for _ in range(64):
        used_anywhere = touched()
        block = [Ins(p, L[p]) for p in range(i + 1, j)]
        N = len(block)
        acc = accesses(block)
        before = mad_conflicts(block)

        def cyc(u):
            """accesses of unit u over two iterations of the loop body (second copy shifted by N)"""
            lst = acc.get(u, [])
            return lst + [(x[0] + N, x[1], x[2], x[3]) for x in lst]
        best = None
        for d in block:
            if d.kind not in ("tex", "ldl"):
                continue
            dt = [t for t in tokens(d) if t["role"] == "W"]
            if len(dt) != 1:
                continue
            dt = dt[0]
            U = units(dt["half"], dt["num"], dt["comps"])
            last, ok, uses = d.pos, True, []
            for u in U:
                after = [x for x in cyc(u) if x[0] > d.pos]
                end = next((x for x in after if x[1] == "W"), None)
                if end is None:
                    ok = False; break
                for x in after:
                    if x is end:
                        break
                    t = x[3]
                    tu = set()
                    for k in range(x[2].rpt):
                        off = k if (x[2].rpt > 1 and t["r"]) else 0
                        tu |= set(units(t["half"], t["num"] + off, t["comps"]))
                    if x[0] >= N + i + 1 or not tu <= set(U) or x[2].kind not in ("alu",):
                        ok = False; break                           # loop-carried or odd use
                    uses.append(x)
                    last = max(last, x[0])
                if not ok:
                    break
            if not ok or not uses:
                continue
            mine = {(x[0], x[3]["a"]) for x in uses} | {(d.pos, dt["a"])}
            step = 1 if dt["half"] else 2
            lim = min(limit, 192) if dt["half"] else limit
            base = U[0]
            n_units = len(U)
            for nb in range(0, lim - n_units + 1, step):
                if nb == base:
                    continue
                free = True
                for u in range(nb, nb + n_units):
                    if u not in used_anywhere:
                        continue                                    # never touched by the shader
                    lst = [x for x in cyc(u) if (x[0] % N if False else (x[0], x[3]["a"])) not in mine
                           and not (x[0] - N, x[3]["a"]) in mine]
                    inwin = [x for x in lst if d.pos <= x[0] <= last]
                    nxt = next((x for x in lst if x[0] > last), None)
                    prv = [x for x in lst if x[0] < d.pos]
                    if inwin or nxt is None or nxt[1] != "W":
                        free = False; break
                    if prv and prv[-1][1] == "R" and prv[-1][2].kind in ("tex", "ldl", "store"):
                        free = False; break
                if not free:
                    continue
                delta = nb - base

                def ren(ins, t, num, _u=set(U), _d=delta, _m=mine):
                    us = units(t["half"], num, 1)
                    if (ins.pos, t["a"]) in _m and us[0] in _u:
                        return num + (_d if t["half"] else _d // 2)
                    return num
                after = mad_conflicts(block, ren)
                if after < before and (best is None or after < best[0]):
                    best = (after, d, dt, uses, delta)
        if best is None:
            break
        after, d, dt, uses, delta = best
        sh = delta if dt["half"] else delta // 2
        edits = {}
        edits.setdefault(d.pos, []).append((dt["a"], dt["b"], regname(dt, dt["num"] + sh)))
        for x in uses:
            t = x[3]
            edits.setdefault(x[0], []).append((t["a"], t["b"], regname(t, t["num"] + sh)))
        for p, e in edits.items():
            L[p] = rewrite(L[p], sorted(set(e)))
        moved += 1
        print(f"moved {d.line.strip()[:60]} by {delta:+d} units: loop conflicts {before} -> {after}")
    block = [Ins(p, L[p]) for p in range(i + 1, j)]
    print(f"{moved} vectors moved; loop conflicts now {mad_conflicts(block)}; footprint limit {limit // 8} full regs")
    open(dst, "w").write("\n".join(L))


if __name__ == "__main__":
    main()
