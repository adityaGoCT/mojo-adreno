"""AdrenoBLAS kernel generator: fp16 GEMM C[M,N] = A[M,K] @ B[K,N] on VK_KHR_cooperative_matrix (Adreno 8xx).

Layout 'P' (panel): A packed as 64 x 16 tiles and B as 16 x 32 tiles ('Q': 16 x 64), each tile contiguous and K-adjacent;
'R'/'C': the same panels with K contiguous inside each tile (A row-major, B column-major), so each lane's operand
elements are adjacent and load as 16-byte vectors
(see sweep.make_shape for the exact element order); the runtime's pack kernel produces it.
A kernel config is a dict:
  wm, wn   subgroups per workgroup along M and N (64 lanes each)
  tm, tn   cooperative-matrix tiles per subgroup along M and N (tile = 64 x nt)
  nt       N width of one tile: 16 or 32 (the 850 driver hangs on 64-wide tiles fed fresh data each step)
  acc      accumulator type: f16 or f32 (stored as f16)
  ku       K steps (of 16) unrolled per loop iteration
  la, lb   layouts: 'N' row-major A[M,K] / B[K,N]; 'T' = stored transposed (A as [K,M], B as [N,K])
Workgroup tile: BM = 64*tm*wm, BN = nt*tn*wn.
Avoids the 850 driver bugs found in asm/README.md: no adds of two cooperative matrices.
"""
import itertools, json, pathlib, re, subprocess, sys
import epilogue

HERE = pathlib.Path(__file__).resolve().parent
KT = 16  # K of one fp16 multiply on the 850

def U(x):
    """A shape value in GLSL: an int literal (tuning kernels) or a specialization-constant name (library kernels)."""
    return f"{x}u" if isinstance(x, int) else x

def name(c):
    return (f"g{c['la']}{c['lb']}_w{c['wm']}x{c['wn']}_t{c['tm']}x{c['tn']}_n{c['nt']}_{c['acc']}_k{c['ku']}"
            + ("_p1" if c.get("pf") else "") + (f"_s{c['sw']}" if c.get("sw") else "")
            + (f"_sh{'a' if c.get('sa') else ''}{'b' if c.get('sb') else ''}{c['kc']}" if c.get("sa") or c.get("sb") else "")
            + ("_d2" if c.get("dual") else "") + (f"_ps{c['ps']}" if c.get("ps") else "")
            + (f"_e{c['ep']}" if c.get("ep") else ""))

def tile(c):
    return 64 * c["tm"] * c["wm"], c["nt"] * c["tn"] * c["wn"]

def glsl(c, M, N, K, spec=False):
    """spec=True: M, N, K become specialization constants 0, 1, 2 (one SPIR-V module per config for the library)."""
    if spec:
        assert not c.get("sw"), "grouped order needs the grid size at generation time"
        M, N, K = "M_", "N_", "K_"
    nt, tm, tn = c["nt"], c["tm"], c["tn"]
    acc = {"f16": "float16_t", "f32": "float"}[c["acc"]]
    BM, BN = tile(c)
    S = "gl_ScopeSubgroup"
    A_ = f"coopmat<float16_t, {S}, 64, {KT}, gl_MatrixUseA>"
    B_ = f"coopmat<float16_t, {S}, {KT}, {nt}, gl_MatrixUseB>"
    C_ = f"coopmat<{acc}, {S}, 64, {nt}, gl_MatrixUseAccumulator>"
    H_ = f"coopmat<float16_t, {S}, 64, {nt}, gl_MatrixUseAccumulator>"
    RM, CM = "gl_CooperativeMatrixLayoutRowMajor", "gl_CooperativeMatrixLayoutColumnMajor"
    # A: 'N' = row-major [M,K] (element (r,k) at r*K+k);  'T' = stored [K,M] -> column-major view, stride M
    if c["la"] == "R":  # A panels, K contiguous inside the tile: 64 x 16 row-major tiles (a lane's 16 halves are adjacent)
        a_off = lambda r, k: f"((({r}) / 64u) * ({U(K)} / 16u) + ({k}) / 16u) * 1024u"
        a_lay, a_str = RM, 16
    elif c["la"] == "P":  # A panels: 64 x 16 tiles (column-major, 2 KB contiguous), K-tiles adjacent per 64-row panel
        a_off = lambda r, k: f"((({r}) / 64u) * ({U(K)} / 16u) + ({k}) / 16u) * 1024u"
        a_lay, a_str = CM, 64
    else:
        a_off = (lambda r, k: f"({r}) * {U(K)} + ({k})") if c["la"] == "N" else (lambda r, k: f"({k}) * {U(M)} + ({r})")
        a_lay, a_str = (RM, K) if c["la"] == "N" else (CM, M)
    # B: 'N' = row-major [K,N];  'T' = stored [N,K] -> column-major view, stride K
    if c["lb"] == "P":  # B panels: 16 x 32 tiles (row-major, 1 KB contiguous), K-tiles adjacent per 32-column panel
        assert nt == 32
        b_off = lambda k, n: f"((({n}) / 32u) * ({U(K)} / 16u) + ({k}) / 16u) * 512u"
        b_lay, b_str = RM, 32
    elif c["lb"] == "C":  # B panels 64 wide, K contiguous inside the tile: 16 x 64 tiles stored column-major
        b_off = lambda k, n: f"((({n}) / 64u) * ({U(K)} / 16u) + ({k}) / 16u) * 1024u + (({n}) % 64u) * 16u"
        b_lay, b_str = CM, 16
    elif c["lb"] == "Q":  # B panels 64 wide: 16 x 64 tiles (2 KB contiguous); 32-wide tiles read half a panel row
        b_off = lambda k, n: f"((({n}) / 64u) * ({U(K)} / 16u) + ({k}) / 16u) * 1024u + ({n}) % 64u"
        b_lay, b_str = RM, 64
    else:
        b_off = (lambda k, n: f"({k}) * {U(N)} + ({n})") if c["lb"] == "N" else (lambda k, n: f"({n}) * {U(K)} + ({k})")
        b_lay, b_str = (RM, N) if c["lb"] == "N" else (CM, K)
    L = ["#version 450",
         "#extension GL_KHR_cooperative_matrix : require",
         "#extension GL_KHR_memory_scope_semantics : require",
         "#extension GL_EXT_shader_explicit_arithmetic_types : require",
         "#extension GL_EXT_shader_16bit_storage : require",
         "#extension GL_KHR_shader_subgroup_basic : require",
         f"layout(local_size_x = {64 * c['wm'] * c['wn']}) in;",
         ] + (["layout(constant_id = 0) const uint M_ = 1024u;", "layout(constant_id = 1) const uint N_ = 1024u;",
               "layout(constant_id = 2) const uint K_ = 1024u;"] if spec else []) + [
         "layout(std430, binding = 0) readonly buffer A { float16_t a[]; };",
         "layout(std430, binding = 1) readonly buffer B { float16_t b[]; };",
         "layout(std430, binding = 2) writeonly buffer C { float16_t c[]; };",
         "layout(std430, binding = 0) readonly buffer A4 { uvec4 a4[]; };",
         "layout(std430, binding = 1) readonly buffer B4 { uvec4 b4[]; };",
         "layout(std430, binding = 2) writeonly buffer C4 { uvec4 c4[]; };",
         ] + staged_decls(c, M, N, K) + (epilogue.decls(c["wm"] * c["wn"], c["ep"]) if c.get("ep") else []) + [
         "void main() {",
         f"  uint sg = gl_SubgroupID;",
         ]
    gx, gy = (N // BN, M // BM) if not spec else (None, None)
    if c.get("sw"):  # grouped order: consecutive workgroups walk sw block-rows before moving right (L2 reuse)
        G = c["sw"]
        L += [f"  uint pid = gl_WorkGroupID.y * {gx}u + gl_WorkGroupID.x;",
              f"  uint first = (pid / {G * gx}u) * {G}u;",
              f"  uint gsz = min({gy}u - first, {G}u);",
              f"  uint wy = first + (pid % gsz);",
              f"  uint wx = (pid % {G * gx}u) / gsz;"]
    elif c.get("ps"):  # persistent: fewer workgroups, each loops over output tiles, so one tile's C store overlaps
        # the next tile's K loop (the store is ~5% of a 4096^3 run when every workgroup stores at the same moment)
        L += [f"  uint ntx = {U(N)} / {BN}u, ntiles = ({U(M)} / {BM}u) * ntx;",
              f"  for (uint t = gl_WorkGroupID.x; t < ntiles; t += {-(-(N // BN) * (M // BM) // c['ps'])}u) {{" if not spec else
              "  for (uint t = gl_WorkGroupID.x; t < ntiles; t += gl_NumWorkGroups.x) {",
              "  uint wy = t / ntx;", "  uint wx = t % ntx;"]
    else:
        L += ["  uint wy = gl_WorkGroupID.y;", "  uint wx = gl_WorkGroupID.x;"]
    L += [f"  uint row0 = wy * {BM}u + (sg / {c['wn']}u) * {64 * tm}u;",
          f"  uint col0 = wx * {BN}u + (sg % {c['wn']}u) * {nt * tn}u;"]
    for i in range(tm):
        for j in range(tn):
            L.append(f"  {C_} c{i}{j} = {C_}(0);")
            if c.get("dual"):
                L.append(f"  {C_} d{i}{j} = {C_}(0);")
    if c.get("sa") or c.get("sb"):
        staged_loop(L, c, M, N, K, A_, B_, a_off, a_str, a_lay, b_off, b_str, b_lay)
    elif c.get("pf"):  # software prefetch: issue step k+16's loads before step k's multiplies
        def loads(kk, sfx):
            for i in range(tm):
                L.append(f"    {A_} a{i}{sfx}; coopMatLoad(a{i}{sfx}, a, {a_off(f'row0 + {64 * i}u', kk)}, {a_str}, {a_lay});")
            for j in range(tn):
                L.append(f"    {B_} b{j}{sfx}; coopMatLoad(b{j}{sfx}, b, {b_off(kk, f'col0 + {nt * j}u')}, {b_str}, {b_lay});")
        L.append("  {")
        loads("0u", "_c")
        L.append(f"  for (uint k = {KT}u; k < {U(K)}; k += {KT}u) {{")
        loads("k", "_n")
        for i in range(tm):
            for j in range(tn):
                L.append(f"    c{i}{j} = coopMatMulAdd(a{i}_c, b{j}_c, c{i}{j});")
        for i in range(tm):
            L.append(f"    a{i}_c = a{i}_n;")
        for j in range(tn):
            L.append(f"    b{j}_c = b{j}_n;")
        L.append("  }")
        for i in range(tm):
            for j in range(tn):
                L.append(f"  c{i}{j} = coopMatMulAdd(a{i}_c, b{j}_c, c{i}{j});")
        L.append("  }")
    else:
     L.append(f"  for (uint k = 0u; k < {U(K)}; k += {KT * c['ku']}u) {{")
     for u in range(c["ku"]):
         kk = f"k + {KT * u}u"
         for i in range(tm):
             L.append(f"    {A_} a{i}_{u}; coopMatLoad(a{i}_{u}, a, {a_off(f'row0 + {64 * i}u', kk)}, {a_str}, {a_lay});")
         for j in range(tn):
             L.append(f"    {B_} b{j}_{u}; coopMatLoad(b{j}_{u}, b, {b_off(kk, f'col0 + {nt * j}u')}, {b_str}, {b_lay});")
         for i in range(tm):
             for j in range(tn):
                 acc_ = ("d" if c.get("dual") and u % 2 else "c") + f"{i}{j}"
                 L.append(f"    {acc_} = coopMatMulAdd(a{i}_{u}, b{j}_{u}, {acc_});")
     L.append("  }")
    if c.get("dual"):
        for i in range(tm):
            for j in range(tn):
                L.append(f"  for (int e = 0; e < c{i}{j}.length(); ++e) c{i}{j}[e] += d{i}{j}[e];")
    if c.get("ep"):  # fused epilogue (epilogue.py): one 64 x 64 f16 tile per subgroup
        assert tm == tn == 1 and nt == 64 and acc == "float16_t"
        L += epilogue.body(c["ep"], c["wm"] * c["wn"], U(N), acc="c00")
    else:
     for i in range(tm):
        for j in range(tn):
            src = f"c{i}{j}" if acc == "float16_t" else f"{H_}(c{i}{j})"
            L.append(f"  coopMatStore({src}, c, (row0 + {64 * i}u) * {U(N)} + col0 + {nt * j}u, {N}, {RM});")
    if c.get("ps"):
        L.append("  }")
    L.append("}")
    return "\n".join(L) + "\n"

SHU = 2  # shared tiles are f16vec4 arrays: offsets/strides below are in uvec4 units x 2

def staged_decls(c, M, N, K):
    """Shared-memory tiles for the staged variants. f16vec4 arrays: on the 850 driver (E17.52.10.04) a
    cooperative load from a uint or uvec4 shared array returns wrong data; float16_t/f16vec4 arrays work."""
    BM, BN = tile(c)
    kc, d = c.get("kc", 32), []
    if c.get("sa"):
        d.append(f"shared f16vec4 shA[{kc * BM // 4}];")
    if c.get("sb"):
        d.append(f"shared f16vec4 shB[{kc * BN // 4}];")
    return d

def staged_loop(L, c, M, N, K, A_, B_, a_off, a_str, a_lay, b_off, b_str, b_lay):
    """K loop in chunks of kc: the workgroup copies the A and/or B chunk to shared memory with 128-bit
    loads, then each subgroup feeds its multiplies from shared (unstaged operands still load from global)."""
    BM, BN = tile(c)
    kc, nt, tm, tn = c.get("kc", 32), c["nt"], c["tm"], c["tn"]
    T = 64 * c["wm"] * c["wn"]
    RM, CM = "gl_CooperativeMatrixLayoutRowMajor", "gl_CooperativeMatrixLayoutColumnMajor"
    L.append(f"  uint tid = gl_LocalInvocationIndex;")
    L.append(f"  uint rowb = wy * {BM}u, colb = wx * {BN}u;")
    L.append(f"  uint srow = (sg / {c['wn']}u) * {64 * tm}u, scol = (sg % {c['wn']}u) * {nt * tn}u;")
    L.append(f"  for (uint k0 = 0u; k0 < {U(K)}; k0 += {kc}u) {{")
    L.append("    barrier();")
    def copy(arr, src, rows, w8, goff):  # rows x w8 uvec4 block; goff(r, q) -> global uvec4 index
        n = rows * w8
        for it in range((n + T - 1) // T):
            idx = f"tid + {it * T}u"
            guard = f"if ({idx} < {n}u) " if (it + 1) * T > n else ""
            L.append(f"    {{ uint e = {idx}; uint r = e / {w8}u, q = e % {w8}u; {guard}{{ uvec4 v = {src}[{goff('r', 'q')}]; "
                     f"{arr}[2u * e] = f16vec4(unpackFloat2x16(v.x), unpackFloat2x16(v.y)); "
                     f"{arr}[2u * e + 1u] = f16vec4(unpackFloat2x16(v.z), unpackFloat2x16(v.w)); }} }}")
    if c.get("sa"):
        if c["la"] == "T":   # A stored [K, M]: chunk = kc rows of BM halves
            copy("shA", "a4", kc, BM // 8, lambda r, q: f"((k0 + {r}) * {U(M)} + rowb) / 8u + {q}")
        else:                # A stored [M, K]: chunk = BM rows of kc halves
            copy("shA", "a4", BM, kc // 8, lambda r, q: f"((rowb + {r}) * {U(K)} + k0) / 8u + {q}")
    if c.get("sb"):
        if c["lb"] == "N":   # B stored [K, N]: chunk = kc rows of BN halves
            copy("shB", "b4", kc, BN // 8, lambda r, q: f"((k0 + {r}) * {U(N)} + colb) / 8u + {q}")
        else:                # B stored [N, K]: chunk = BN rows of kc halves
            copy("shB", "b4", BN, kc // 8, lambda r, q: f"((colb + {r}) * {U(K)} + k0) / 8u + {q}")
    L.append("    memoryBarrierShared();")
    L.append("    barrier();")
    for u in range(kc // 16):
        for i in range(tm):
            if c.get("sa"):
                if c["la"] == "T":
                    off, st, lay = f"({u * 16 * BM // 8}u + (srow + {64 * i}u) / 8u) * {SHU}u", BM // 8 * SHU, CM
                else:
                    off, st, lay = f"((srow + {64 * i}u) * {kc // 8}u + {u * 2}u) * {SHU}u", kc // 8 * SHU, RM
                L.append(f"    {A_} a{i}_{u}; coopMatLoad(a{i}_{u}, shA, {off}, {st}, {lay});")
            else:
                L.append(f"    {A_} a{i}_{u}; coopMatLoad(a{i}_{u}, a, {a_off(f'rowb + srow + {64 * i}u', f'k0 + {16 * u}u')}, {a_str}, {a_lay});")
        for j in range(tn):
            if c.get("sb"):
                if c["lb"] == "N":
                    off, st, lay = f"({u * 16 * BN // 8}u + (scol + {nt * j}u) / 8u) * {SHU}u", BN // 8 * SHU, RM
                else:
                    off, st, lay = f"((scol + {nt * j}u) * {kc // 8}u + {u * 2}u) * {SHU}u", kc // 8 * SHU, CM
                L.append(f"    {B_} b{j}_{u}; coopMatLoad(b{j}_{u}, shB, {off}, {st}, {lay});")
            else:
                L.append(f"    {B_} b{j}_{u}; coopMatLoad(b{j}_{u}, b, {b_off(f'k0 + {16 * u}u', f'colb + scol + {nt * j}u')}, {b_str}, {b_lay});")
        for i in range(tm):
            for j in range(tn):
                acc_ = ("d" if c.get("dual") and u % 2 else "c") + f"{i}{j}"
                L.append(f"    {acc_} = coopMatMulAdd(a{i}_{u}, b{j}_{u}, {acc_});")
    L.append("  }")

def build(c, M, N, K, out):
    n = name(c)
    src = out / f"{n}_{M}x{N}x{K}.comp"
    spv = src.with_suffix(".spv")
    src.write_text(glsl(c, M, N, K))
    r = subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(src), "-o", str(spv)], capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError(f"{n}: {r.stderr[:500]}")
    return spv

# Known 850 (driver E17.52.10.04) failures, so excluded: f32 accumulators (the f32->f16 conversion for the
# store segfaults the compiler), ku=2 (device lost), nt=64 (device lost); nt=16 runs but is 3x slower.
def space(la="N", lb="N", accs=("f16",), kus=(1,), nts=(32,), pfs=(0,), sws=(0,), wms=(1, 2, 4), wns=(1, 2, 4), max_sg=8, stages=((0, 0, 0),), duals=(0,), pss=(0,)):  # sw=4/8 measured slower at 4096^3 TN  # pf=1 measured slower (2048^3 TN: 8.7 vs 10.8)
    for wm, wn, tm, tn, nt, acc, ku, pf, sw in itertools.product(wms, wns, (1, 2), (1, 2, 4), nts, accs, kus, pfs, sws):
      for (sa, sb, kc), dual, ps in itertools.product(stages, duals, pss):
        regs = tm * tn * nt * (1 if acc == "f16" else 2) // 2  # 32-bit registers per lane for accumulators
        if regs > 64 or tm * tn > 4 or wm * wn > max_sg:
            continue
        BM, BN = 64 * tm * wm, nt * tn * wn
        if kc and (sa * kc * BM + sb * kc * BN) * 2 > 16384:  # stay at <= 16 KB shared (32 KB misbehaved on the 840)
            continue
        steps = kc // 16 if kc else ku
        if dual and steps < 2:
            continue
        if ps and sw:
            continue
        yield dict(wm=wm, wn=wn, tm=tm, tn=tn, nt=nt, acc=acc, ku=ku, la=la, lb=lb, pf=pf, sw=sw, sa=sa, sb=sb, kc=kc, dual=dual, ps=ps)

if __name__ == "__main__":
    print(sum(1 for _ in space()), "configs in the NN space")
    c = dict(wm=2, wn=2, tm=1, tn=2, nt=32, acc="f32", ku=1, la="N", lb="N")
    print(glsl(c, 2048, 2048, 2048))

def parse(n):
    """Inverse of name(): config dict from a kernel name."""
    ep = None
    if (e := re.search(r"_e([pgaflbr])$", n)):
        ep, n = e.group(1), n[:e.start()]
    m = re.match(r"g([NTPR])([NTPQC])_w(\d+)x(\d+)_t(\d+)x(\d+)_n(\d+)_(f16|f32)_k(\d+)(.*)$", n)
    la, lb, wm, wn, tm, tn, nt, acc, ku, rest = m.groups()
    c = dict(la=la, lb=lb, wm=int(wm), wn=int(wn), tm=int(tm), tn=int(tn), nt=int(nt), acc=acc, ku=int(ku),
             pf=int("_p1" in rest), sw=0, sa=0, sb=0, kc=0, dual=int("_d2" in rest))
    if (s := re.search(r"_s(\d+)", rest)) and not re.search(r"_sh", rest[:s.start() + 3]):
        c["sw"] = int(s.group(1))
    if (s := re.search(r"_ps(\d+)", rest)):
        c["ps"] = int(s.group(1))
    if (s := re.search(r"_sh(a?)(b?)(\d+)", rest)):
        c.update(sa=int(bool(s.group(1))), sb=int(bool(s.group(2))), kc=int(s.group(3)))
    if ep:
        c["ep"] = ep
    assert name(c) == n + (f"_e{ep}" if ep else ""), (name(c), n)
    return c
