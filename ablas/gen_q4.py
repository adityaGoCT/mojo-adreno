"""AdrenoBLAS Q4_0 GEMM: C[M,N] = A[M,K] @ dequant(W[N,K])^T on cooperative matrices, dequantized in registers.

On the 850 driver a 16 x 64 B matrix (gl_MatrixUseB) holds column n in lane n and k in element k (probe/map.comp),
so each lane dequantizes its own output column's 4-bit weights and fills the B matrix element by element:
no shared memory, and B traffic drops from 2 bytes to 0.5625 bytes per weight.

A: fp16 K-minor tiles (layout R, as in gen.py).  B: 'Q4' layout, per 64-column panel p and 32-deep K block kb:
  quants: uvec2 index ((p*(K/32) + kb)*2 + h)*64 + n%64, h = k%32/16 (16 nibbles = column n, k 16h..16h+15)
          word w, nibble j: low half (bits 4j..4j+3) = q[8w+2j], high half (bits 16+4j..) = q[8w+2j+1]
  scales: fp16 at half index N*K/4 + (p*(K/32) + kb)*64 + n%64   (after the quants in the same buffer)
  value = (q - 8) * d (ggml Q4_0 semantics, blocks of 32 along K).
Dequant: ((w >> 4j) & 0x000F000F) | 0x64006400 is (1024 + q) as two halves; - 1032 is exact; * d rounds once.
"""
import pathlib, re, subprocess, sys
import epilogue

def name(c):
    return (f"q4_w{c['wm']}x{c['wn']}_k{c['ks']}" + ("_p1" if c.get("pf") else "") + ("_dq0" if c.get("dq", 1) == 0 else "")
            + (f"_e{c['ep']}" if c.get("ep") else ""))

def glsl(c, M, N, K, spec=False):
    wm, wn, ks = c["wm"], c["wn"], c["ks"]
    U = (lambda x: f"{x}u") if not spec else (lambda x: x)
    if spec:
        M, N, K = "M_", "N_", "K_"
    BM, BN = 64 * wm, 64 * wn
    S = "gl_ScopeSubgroup"
    A_ = f"coopmat<float16_t, {S}, 64, 16, gl_MatrixUseA>"
    B_ = f"coopmat<float16_t, {S}, 16, 64, gl_MatrixUseB>"
    C_ = f"coopmat<float16_t, {S}, 64, 64, gl_MatrixUseAccumulator>"
    RM = "gl_CooperativeMatrixLayoutRowMajor"
    L = ["#version 450",
         "#extension GL_KHR_cooperative_matrix : require",
         "#extension GL_KHR_memory_scope_semantics : require",
         "#extension GL_EXT_shader_explicit_arithmetic_types : require",
         "#extension GL_EXT_shader_16bit_storage : require",
         "#extension GL_KHR_shader_subgroup_basic : require",
         f"layout(local_size_x = {64 * wm * wn}) in;"]
    if spec:
        L += ["layout(constant_id = 0) const uint M_ = 1024u;", "layout(constant_id = 1) const uint N_ = 1024u;",
              "layout(constant_id = 2) const uint K_ = 1024u;"]
    L += ["layout(std430, binding = 0) readonly buffer A { float16_t a[]; };",
          "layout(std430, binding = 1) readonly buffer BQ { uvec2 bq[]; };",
          "layout(std430, binding = 1) readonly buffer BD { float16_t bd[]; };",
          "layout(std430, binding = 2) writeonly buffer C { float16_t c[]; };",
          "layout(std430, binding = 2) writeonly buffer C4 { uvec4 c4[]; };"] + (epilogue.decls(wm * wn, c["ep"]) if c.get("ep") else []) + [
          # (850 driver E17.52.10.04: element writes into a cooperative matrix that was never initialized
          # segfault the compiler; initialize it first.)
          "void deq(uvec2 q, float16_t d, inout " + B_ + " b) {",
          "  f16vec2 dd = f16vec2(d), off = f16vec2(1032.0hf);"]
    dq = c.get("dq", 1)
    for w, comp in enumerate("xy"):
        for j in range(4):
            e = 8 * w + 2 * j
            if dq == 0:  # assign as computed: element 4 is silently lost on the 850 driver (stays 0)
                L.append(f"  {{ f16vec2 v = (unpackFloat2x16(((q.{comp} >> {4 * j}u) & 0x000F000Fu) | 0x64006400u) - off) * dd; "
                         f"b[{e}] = v.x; b[{e + 1}] = v.y; }}")
            else:        # compute all eight pairs first, then assign elements 0..15 in order
                L.append(f"  f16vec2 v{e // 2} = (unpackFloat2x16(((q.{comp} >> {4 * j}u) & 0x000F000Fu) | 0x64006400u) - off) * dd;")
    if dq != 0:
        # 850 driver bug: a write to element 4 with a constant index is dropped (the element keeps its initial
        # value; elements 0-3 and 5-15 are fine). A runtime index the compiler can't fold (always 0) works.
        L.append("  int z = int(gl_SubgroupInvocationID >> 8u);")
        L.append("  " + " ".join(f"b[{'z + 4' if e == 4 else e}] = v{e // 2}.{'xy'[e % 2]};" for e in range(16)))
    L += ["}",
          "void main() {",
          "  uint sg = gl_SubgroupID, l = gl_SubgroupInvocationID;",
          f"  uint row0 = gl_WorkGroupID.y * {BM}u + (sg / {wn}u) * 64u;",
          f"  uint col0 = gl_WorkGroupID.x * {BN}u + (sg % {wn}u) * 64u;",
          f"  uint KB = {U(K)} / 32u;",
          "  uint qb = (col0 / 64u) * KB * 128u + l;",            # uvec2 index of (kb=0, h=0) for this lane
          f"  uint db = {U(N)} * {U(K)} / 4u + (col0 / 64u) * KB * 64u + l;",
          f"  uint ab = (row0 / 64u) * ({U(K)} / 16u) * 1024u;",   # A panel base (halves)
          f"  {C_} acc = {C_}(0);"]
    if ks == 16:  # one multiply per loop iteration (the fp16 kernels' shape)
        L += [f"  for (uint k = 0u; k < {U(K)} / 16u; ++k) {{",
              "    uvec2 q = bq[qb + k * 64u];",
              "    float16_t d = bd[db + (k / 2u) * 64u];",
              f"    {A_} a0; coopMatLoad(a0, a, ab + k * 1024u, 16u, {RM});",
              f"    {B_} b0 = {B_}(0.0hf); deq(q, d, b0);",
              "    acc = coopMatMulAdd(a0, b0, acc);",
              "  }"]
    else:  # one 32-deep block per iteration: two multiplies on the one 64 x 64 accumulator
        if c.get("pf"):
            L += ["  uvec2 q0 = bq[qb], q1 = bq[qb + 64u]; float16_t d = bd[db];",
                  "  for (uint kb = 0u; kb < KB; ++kb) {",
                  "    uint nb = min(kb + 1u, KB - 1u);",
                  "    uvec2 n0 = bq[qb + nb * 128u], n1 = bq[qb + nb * 128u + 64u]; float16_t nd = bd[db + nb * 64u];"]
        else:
            L += ["  for (uint kb = 0u; kb < KB; ++kb) {",
                  "    uvec2 q0 = bq[qb + kb * 128u], q1 = bq[qb + kb * 128u + 64u];",
                  "    float16_t d = bd[db + kb * 64u];"]
        L += [f"    {A_} a0; coopMatLoad(a0, a, ab + kb * 2048u, 16u, {RM});",
              f"    {A_} a1; coopMatLoad(a1, a, ab + kb * 2048u + 1024u, 16u, {RM});",
              f"    {B_} b0 = {B_}(0.0hf); deq(q0, d, b0);",
              f"    {B_} b1 = {B_}(0.0hf); deq(q1, d, b1);",
              "    acc = coopMatMulAdd(a0, b0, acc);",
              "    acc = coopMatMulAdd(a1, b1, acc);"]
        if c.get("pf"):
            L.append("    q0 = n0; q1 = n1; d = nd;")
        L.append("  }")
    if c.get("ep"):
        L += epilogue.body(c["ep"], wm * wn, U(N)) + ["}"]
    else:
        L += [f"  coopMatStore(acc, c, row0 * {U(N)} + col0, {U(N)}, {RM});", "}"]
    return "\n".join(L) + "\n"

def parse(n):
    m = re.match(r"q4_w(\d+)x(\d+)_k(\d+)(_p1)?(_dq0)?(_e[pgaf])?$", n)
    c = dict(wm=int(m[1]), wn=int(m[2]), ks=int(m[3]), pf=int(bool(m[4])), dq=0 if m[5] else 1)
    if m[6]:
        c["ep"] = m[6][2]
    assert name(c) == n, (name(c), n)
    return c

def build(c, M, N, K, out):
    out.mkdir(parents=True, exist_ok=True)
    src = out / f"{name(c)}_{M}x{N}x{K}.comp"
    src.write_text(glsl(c, M, N, K))
    spv = src.with_suffix(".spv")
    subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(src), "-o", str(spv)], check=True)
    return spv

if __name__ == "__main__":
    print(glsl(dict(wm=2, wn=2, ks=32, pf=1), 2048, 2048, 2048))
