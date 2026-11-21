"""Hand-written GEMM main loops in ir3 assembly for the Adreno 840, injected through IR3_SHADER_OVERRIDE_PATH.

Template: Turnip's compiled gemm_f16_gg_128x128 (both operands straight from global memory via isam, 8x8 fp16
thread tile). Its prologue (thread ids in r0.x/r0.w, accumulators hr2..hr17 = 0, workgroup base addresses in
shared regs) and epilogue (stores acc[i][h] from hr(17-2i-h)) are kept; the loop between `l97:` and `l349:` is
replaced by generated code.

What the hand-written loops change:
  * register banks: a mad whose three register sources share a component (x/y/z/w) issues at 1/3 rate (README).
    The accumulator's component equals the B column's component (fixed by the epilogue's register layout), so B
    vectors are loaded starting one component late (.y): src1 (B) and src3 (acc) never share a bank.
  * (rpt3) mads: the 4 columns of one accumulator vector in one instruction (16 per k-step instead of 64).
  * incremental addressing: one add per row instead of the compiler's per-iteration shift/sad recomputation.
  * dbuf: software pipelining. ir3's (sy) waits for *all* outstanding loads, so the next batch is issued right
    after the wait for the current one, into a second register set (loop body = 2 batches). Half registers end
    at hr47 (hr48+ are the shared registers), so the two sets are packed densely below it.

  python3 gen_asm_gemm.py   ->  edits/asmgemm_f16_<variant>/<hash>.asm
"""
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
H16 = "71722f6082a37ecd5c983d3bacb192704522de5bf0bf8a36341c8c27fd520b8f"   # gemm_f16_gg_128x128 (Turnip)
C = "xyzw"
ROW = ["0", "c1.x", "c1.z", "c1.y"]   # +0, +2048, +4096, +6144 halves: k-step offsets (one row of At / B)


def hreg(i):                # half register by scalar index (hr0.x = 0)
    return f"hr{i // 4}.{C[i % 4]}"


class Set:
    """Operands of one batch of `ku` k-steps, from half index `start` (must be 1 mod 4: B rotated by one):
    B vectors (2 per k-step) first, then A vectors (2 per k-step), all packed back to back."""

    def __init__(self, start, ku):
        assert start % 4 == 1
        self.start, self.ku = start, ku
        self.end = start + 16 * ku
        assert self.end <= 192, "half registers end at hr47.w"

    def b(self, kk, h):
        return self.start + 4 * (2 * kk + h)

    def a(self, kk, half):
        return self.start + 8 * self.ku + 4 * (2 * kk + half)


def loads(s, ra, rb):
    """isam for one batch; ra/rb: address registers of each k-step (half index of row kk)."""
    L = []
    for kk in range(s.ku):
        L.append(f"isam.v.base0 (u16)(xyzw){hreg(s.a(kk, 0))}, {ra[kk]}, s#0, t#0")
        L.append(f"isam.v.base0 (u16)(xyzw){hreg(s.a(kk, 1))}, {ra[kk]}+64, s#0, t#0")
        L.append(f"isam.v.base0 (u16)(xyzw){hreg(s.b(kk, 0))}, {rb[kk]}, s#0, t#2")
        L.append(f"isam.v.base0 (u16)(xyzw){hreg(s.b(kk, 1))}, {rb[kk]}+64, s#0, t#2")
    return L


def mads(s, first=""):
    L = []
    for kk in range(s.ku):
        for i in range(8):
            ai = hreg(s.a(kk, i // 4) + i % 4)
            for h in range(2):
                acc = f"hr{17 - 2 * i - h}.x"
                L.append(f"{first if not L else ''}(rpt3)mad.f16 {acc}, (r){hreg(s.b(kk, h))}, {ai}, (r){acc}")
    return L


BASE = ["(rpt1)shr.b r53.z, (r)r52.w, 2",           # shared: bm/4, bn/4 (template code, k0 = 0)
        "shl.b r54.x, r53.y, 9",
        "(ss)(nop2) sad.s32 {RA}, r54.x, r0.w, r53.z",  # A row 0 vec4 index: bm/4 + ty
        "sad.s32 {RB}, r54.x, r0.x, r53.w",             # B row 0 vec4 index: bn/4 + tx
        "(nop2) shl.b {RA}, {RA}, 2",                    # -> half index
        "shl.b {RB}, {RB}, 2",
        "(rpt2)nop"]


def base(RA, RB):
    return [l.format(RA=RA, RB=RB) for l in BASE]


def v_single():
    """Load 4 k-steps, wait, 64 (rpt3) mads. Same structure as Turnip's loop."""
    s = Set(18 * 4 + 1, 4)                      # hr18.y .. hr34.x
    RA = ["r18.x", "r18.z", "r19.x", "r19.z"]
    RB = ["r18.y", "r18.w", "r19.y", "r19.w"]
    pre = base(RA[0], RB[0])
    body = ["l97:", "add.u r53.y, r53.y, 4", "cmps.u.ge up0.x, r53.y, c1.x"]
    for kk in (1, 2, 3):
        body += [f"add.u {RA[kk]}, {RA[0]}, {ROW[kk]}", f"add.u {RB[kk]}, {RB[0]}, {ROW[kk]}"]
    L = loads(s, RA, RB)
    # (ss): isam may read its address register after issue (ir3_legalize WAR rule)
    body += L[:4] + [f"(ss)add.u {RA[0]}, {RA[3]}, c1.x", f"add.u {RB[0]}, {RB[3]}, c1.x"] + L[4:]
    body += mads(s, "(sy)") + ["(ss)br p0.x, #l349", "jump #l97"]
    return pre, body


def v_dbuf(ku=2):
    """Double-buffered, batches of `ku` k-steps; loop body = 2 batches; the last trip is peeled so that no load
    reads past the end of the matrices."""
    S = [Set(18 * 4 + 1, ku), None]
    S[1] = Set(S[0].end, ku)
    RA, RB = ["r18.x", "r18.z", "r19.x", "r19.z"][:ku], ["r18.y", "r18.w", "r19.y", "r19.w"][:ku]
    assert S[1].end <= 18 * 8, "operands must stay below the address registers (r18 = hr36)"
    step = {1: "c1.x", 2: "c1.z"}[ku]           # rows per batch, in halves (2048 * ku)

    def issue(s):
        L = [f"add.u {RA[kk]}, {RA[0]}, {ROW[kk]}" for kk in range(1, ku)] + \
            [f"add.u {RB[kk]}, {RB[0]}, {ROW[kk]}" for kk in range(1, ku)]
        ld = loads(s, RA, RB)
        L += ld[:4] + ["(rpt1)nop"] + ld[4:]
        L += [f"(ss)add.u {RA[0]}, {RA[0]}, {step}", f"add.u {RB[0]}, {RB[0]}, {step}"]   # (ss): WAR vs isam
        return L

    per_trip = 2 * ku
    pre = base(RA[0], RB[0]) + ["(rpt5)nop"] + issue(S[0]) + [f"add.u r53.y, r53.y, {per_trip}"]
    body = ["l97:"]
    for half in (0, 1):
        cur, nxt = S[half], S[1 - half]
        body += ["(sy)nop"] + (["add.u r53.y, r53.y, %d" % per_trip, "cmps.u.ge up0.x, r53.y, c1.x"] if half == 0 else [])
        body += issue(nxt) + mads(cur)
    body += ["(ss)br p0.x, #l900", "jump #l97", "l900:"]
    # peeled last trip: batch n-2 (set 0, prefetch n-1 into set 1), batch n-1 (set 1, nothing to prefetch)
    body += ["(jp)(sy)nop"] + issue(S[1]) + mads(S[0]) + ["(sy)nop"] + mads(S[1])
    return pre, body


def build(tpl, variant):
    L = [l for l in tpl.split("\n") if not l.startswith("@const(")]
    i, j = L.index("l97:"), L.index("l349:")
    pre, body = variant()
    epi = L[j:]
    assert epi[1].startswith("(jp)")
    epi[1] = "(jp)(sy)" + epi[1][4:]           # nothing may still be loading into registers the epilogue reuses
    return "\n".join(L[:i] + pre + body + epi)


VARIANTS = {"single": v_single, "dbuf2": lambda: v_dbuf(2), "dbuf1": lambda: v_dbuf(1)}


# ---------------------------------------------------------------------------------------------------------------
# Split-path kernel: A tile staged through shared memory (ldl, broadcast within a wave), B straight from global
# memory (isam), so the two operand streams use two different memory paths. Template: Turnip's compiled
# gemm_f16_lg_64x128x16 (64x128 workgroup tile, 128 threads, BK = 16). Its epilogue expects acc[i][h] in the
# half-vector starting at hr(17-2i-h).z, r11.y = ty << 2 and r1.x = tx (r0.w = ty, r0.x = local id).
H16LG = "7b2ef20afcac7b40f68acadfc50e52b3b352941a25526475161f0dee9de7e3fe"


def lg_build(tpl, ku=4):
    L = [l for l in tpl.split("\n") if not l.startswith("@const(")]
    i, j = L.index("l128:"), L.index("l1097:")
    acc = lambda i_, h: (17 - 2 * i_ - h) * 4 + 2          # half index of acc[i][h].x  (bank = (c + 2) % 4)
    OPS = 75                                                # 75 = 3 mod 4: B component c sits in bank (c + 3) % 4
    bvec = lambda kk, h: OPS + 4 * (2 * kk + h)
    avec = lambda kk, half: OPS + 8 * ku + 4 * (2 * kk + half)
    ST = OPS + 16 * ku                                      # staging: 2 vectors of A per thread per tile
    assert ST + 8 <= 19 * 8, "halves must stay below the full address registers (r19 = hr38)"
    R = dict(c16="r19.x", RB=["r19.y", "r19.z", "r19.w", "r20.x"], RA0="r20.y", RA1="r20.z", LMst="r20.w", LMa="r21.x")
    ROWS = ["0", "c1.x", "c4.z", "c4.y"]                     # 0, 2048, 4096, 6144 halves; c4.x = 8192, c3.x = 16384
    # (nopN) = N nops after the instruction; ALU -> ALU needs 3 slots, ALU -> load/store 6
    pre = ["mov.u32u32 r19.x, 0x8000",                       # 16 rows of At / B, in halves
           "(rpt1)shr.b r52.z, (r)r51.w, 2",                 # bm/4, bn/4 (shared regs, as the template)
           "shl.b r20.w, r0.x, 3",                           # LM staging offset: tid * 8 bytes
           "shl.b r21.x, r0.w, 3",                           # LM read offset: ty * 8 bytes
           "shl.b r20.y, r0.w, 9",                           # ty * 512 (A row ty, vec4 units)
           "(ss)add.u r19.y, r52.w, r1.x",                   # B: bn/4 + tx
           "(rpt2)nop",
           "add.u r20.y, r20.y, r52.z",
           "shl.b r19.y, r19.y, 2",                          # B address (halves), k-step 0
           "(rpt2)nop",
           "add.u r20.y, r20.y, r1.x",
           "(rpt2)nop",
           "shl.b r20.y, r20.y, 2",                          # A staging address (halves), rows k0 + ty
           "(rpt2)nop",
           "add.u r20.z, r20.y, c3.x",                       # ... and rows k0 + ty + 8
           "(rpt5)nop"]
    body = ["l128:", "add.u r52.y, r52.y, 16", "cmps.u.ge up0.x, r52.y, c1.x",
            f"isam.v.base0 (u16)(xyzw){hreg(ST)}, {R['RA0']}, s#0, t#0",
            f"isam.v.base0 (u16)(xyzw){hreg(ST + 4)}, {R['RA1']}, s#0, t#0",
            f"(ss)add.u {R['RA0']}, {R['RA0']}, {R['c16']}",
            f"add.u {R['RA1']}, {R['RA1']}, {R['c16']}",
            f"(sy)stl.u16 l[{R['LMst']}], {hreg(ST)[1:]}, 4",
            f"stl.u16 l[{R['LMst']}+1024], {hreg(ST + 4)[1:]}, 4",
            "fence.r.w", "(sy)(ss)bar.g"]
    RB = R["RB"]
    for b in range(16 // ku):
        body += [f"add.u {RB[kk]}, {RB[0]}, {ROWS[kk]}" for kk in range(1, ku)] + ["(rpt5)nop"]
        for kk in range(ku):
            k = b * ku + kk
            for half in (0, 1):
                off = 128 * k + 64 * half
                body.append(f"ldl.u16 {hreg(avec(kk, half))[1:]}, l[{R['LMa']}{'+%d' % off if off else ''}], 4")
            for h in (0, 1):
                body.append(f"isam.v.base0 (u16)(xyzw){hreg(bvec(kk, h))}, {RB[kk]}{'+64' if h else ''}, s#0, t#2")
        body += [f"(ss)add.u {RB[0]}, {RB[0]}, {'c4.x' if ku == 4 else ROWS[ku]}"]
        first = "(sy)(ss)"
        for kk in range(ku):
            for i_ in range(8):
                ai = hreg(avec(kk, i_ // 4) + i_ % 4)
                for h in range(2):
                    a = hreg(acc(i_, h))
                    body.append(f"{first}(rpt3)mad.f16 {a}, (r){hreg(bvec(kk, h))}, {ai}, (r){a}")
                    first = ""
    body += ["(ss)bar.g", "(ss)br p0.x, #l1097", "jump #l128"]
    epi = L[j:]
    assert epi[1] == "(jp)(eolm)nop"
    epi = epi[:2] + ["shl.b r11.y, r0.w, 2", "(rpt2)nop"] + epi[2:]   # r11.y was reused for operands
    return "\n".join(L[:i] + pre + body + epi)


def lg_pipe_build(tpl):
    """lg with the B loads (global, long latency) software-pipelined one batch ahead in two register sets; A
    (shared memory, short latency) is loaded per batch. 4 k-steps per batch, 4 batches per 16-deep tile. The
    B prefetch address wraps (and 0x3fffff) so the final prefetch stays inside the matrix."""
    ku = 4
    L = [l for l in tpl.split("\n") if not l.startswith("@const(")]
    i, j = L.index("l128:"), L.index("l1097:")
    acc = lambda i_, h: (17 - 2 * i_ - h) * 4 + 2
    BS = [75, 107]                                          # two B sets, both 3 mod 4 (conflict-free vs acc)
    bvec = lambda st, kk, h: st + 4 * (2 * kk + h)
    A0 = 139
    avec = lambda kk, half: A0 + 4 * (2 * kk + half)
    ST = A0 + 32
    assert ST + 8 <= 23 * 8
    c16, RB, RA0, RA1, LMst, LMa, MASK = "r23.x", ["r23.y", "r23.z", "r23.w", "r24.x"], "r24.y", "r24.z", "r24.w", "r25.x", "r25.y"
    ROWS = ["0", "c1.x", "c4.z", "c4.y"]

    def bload(st):
        out = [f"add.u {RB[kk]}, {RB[0]}, {ROWS[kk]}" for kk in range(1, ku)] + ["(rpt5)nop"]
        for kk in range(ku):
            for h in (0, 1):
                out.append(f"isam.v.base0 (u16)(xyzw){hreg(bvec(st, kk, h))}, {RB[kk]}{'+64' if h else ''}, s#0, t#2")
        out += [f"(ss)(nop3) add.u {RB[0]}, {RB[0]}, c4.x", f"and.b {RB[0]}, {RB[0]}, {MASK}"]
        return out

    pre = [f"mov.u32u32 {c16}, 0x8000", f"mov.u32u32 {MASK}, 0x3fffff",
           "(rpt1)shr.b r52.z, (r)r51.w, 2",
           f"shl.b {LMst}, r0.x, 3", f"shl.b {LMa}, r0.w, 3", f"shl.b {RA0}, r0.w, 9",
           f"(ss)add.u {RB[0]}, r52.w, r1.x", "(rpt2)nop",
           f"add.u {RA0}, {RA0}, r52.z", f"shl.b {RB[0]}, {RB[0]}, 2", "(rpt2)nop",
           f"add.u {RA0}, {RA0}, r1.x", "(rpt2)nop", f"shl.b {RA0}, {RA0}, 2", "(rpt2)nop",
           f"add.u {RA1}, {RA0}, c3.x", "(rpt2)nop"] + bload(BS[0])
    body = ["l128:", "add.u r52.y, r52.y, 16", "cmps.u.ge up0.x, r52.y, c1.x",
            f"isam.v.base0 (u16)(xyzw){hreg(ST)}, {RA0}, s#0, t#0",
            f"isam.v.base0 (u16)(xyzw){hreg(ST + 4)}, {RA1}, s#0, t#0",
            f"(ss)add.u {RA0}, {RA0}, {c16}", f"add.u {RA1}, {RA1}, {c16}",
            f"(sy)stl.u16 l[{LMst}], {hreg(ST)[1:]}, 4", f"stl.u16 l[{LMst}+1024], {hreg(ST + 4)[1:]}, 4",
            "fence.r.w", "(sy)(ss)bar.g"]
    for b in range(4):
        cur, nxt = BS[b % 2], BS[(b + 1) % 2]
        body.append("(sy)nop")                              # B of this batch has landed
        for kk in range(ku):
            for half in (0, 1):
                off = 128 * (b * ku + kk) + 64 * half
                body.append(f"ldl.u16 {hreg(avec(kk, half))[1:]}, l[{LMa}{'+%d' % off if off else ''}], 4")
        body += bload(nxt)                                  # next batch's B (next tile's first batch at b = 3)
        first = "(ss)"
        for kk in range(ku):
            for i_ in range(8):
                ai = hreg(avec(kk, i_ // 4) + i_ % 4)
                for h in range(2):
                    a = hreg(acc(i_, h))
                    body.append(f"{first}(rpt3)mad.f16 {a}, (r){hreg(bvec(cur, kk, h))}, {ai}, (r){a}")
                    first = ""
    body += ["(ss)bar.g", "(ss)br p0.x, #l1097", "jump #l128"]
    epi = L[j:]
    assert epi[1] == "(jp)(eolm)nop"
    epi = epi[:2] + ["(sy)nop", "shl.b r11.y, r0.w, 2", "(rpt2)nop"] + epi[2:]
    return "\n".join(L[:i] + pre + body + epi)


def main():
    tpl = (HERE / "asm_dump" / f"{H16LG}.asm").read_text()
    d = HERE / "edits" / "asmgemm_f16_lg_pipe"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{H16LG}.asm").write_text(lg_pipe_build(tpl))
    print(d)
    tpl = (HERE / "asm_dump" / f"{H16}.asm").read_text()
    for name, fn in VARIANTS.items():
        d = HERE / "edits" / f"asmgemm_f16_{name}"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{H16}.asm").write_text(build(tpl, fn))
        print(d)
    tpl = (HERE / "asm_dump" / f"{H16LG}.asm").read_text()
    for ku in (4, 2):
        d = HERE / "edits" / f"asmgemm_f16_lg_ku{ku}"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{H16LG}.asm").write_text(lg_build(tpl, ku))
        print(d)


if __name__ == "__main__":
    main()
