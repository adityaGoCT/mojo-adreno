"""Causal attention GEMMs for the Llama 3.2 3B prefill (one 64 x 64 tile per subgroup, as AdrenoBLAS's RC kernels),
batched over the 24 query heads (grid z), grouped-query (KV head = z / 3), M as a push constant.
  qk: S_z = Q_z K_g^T  (M x M x 128), tiles entirely above the diagonal skipped; S as R tiles [24][M, M] fp16
  pv: O_z = P_z V_g    (M x 128 x M), K loop stops at the end of the row block's diagonal (P is 0 beyond);
      stored straight into R tiles of O [M, 3072] (column z*128 + d): on the 850 an accumulator lane holds one row
      and element e is column e (probe/map.comp), so each lane writes four 32-byte runs.
"""
import pathlib, subprocess, sys

HDR = ["#version 450",
       "#extension GL_KHR_cooperative_matrix : require",
       "#extension GL_KHR_memory_scope_semantics : require",
       "#extension GL_EXT_shader_explicit_arithmetic_types : require",
       "#extension GL_EXT_shader_16bit_storage : require",
       "#extension GL_KHR_shader_subgroup_basic : require"]
S = "gl_ScopeSubgroup"
A_ = f"coopmat<float16_t, {S}, 64, 16, gl_MatrixUseA>"
B_ = f"coopmat<float16_t, {S}, 16, 64, gl_MatrixUseB>"
C_ = f"coopmat<float16_t, {S}, 64, 64, gl_MatrixUseAccumulator>"
RM, CM = "gl_CooperativeMatrixLayoutRowMajor", "gl_CooperativeMatrixLayoutColumnMajor"
# Accumulator -> four 32-byte runs per lane (ob in uvec4 units; a 16-column chunk is 1024 halves = 128 uvec4 apart).
# The elements are read in a loop: on the 850 driver (E17.52.10.04) reading accumulator elements with constant
# indices into a vector constructor crashes the compiler (SPIRVCodeGen::handleOpLoad); a loop index works.
STORE = ("  for (int e = 0; e < 64; e += 8) s[ob + uint(e / 16) * 128u + uint(e % 16) / 8u] = uvec4("
         "packFloat2x16(f16vec2(acc[e], acc[e + 1])), packFloat2x16(f16vec2(acc[e + 2], acc[e + 3])), "
         "packFloat2x16(f16vec2(acc[e + 4], acc[e + 5])), packFloat2x16(f16vec2(acc[e + 6], acc[e + 7])));")

def qk(wm, wn):
    BM, BN = 64 * wm, 64 * wn
    return "\n".join(HDR + [
        f"layout(local_size_x = {64 * wm * wn}) in;",
        "layout(push_constant) uniform P { uint M; } pc;",
        "layout(std430, binding = 0) readonly buffer Q { float16_t q[]; };",
        "layout(std430, binding = 1) readonly buffer K { float16_t k[]; };",
        "layout(std430, binding = 2) writeonly buffer SS { uvec4 s[]; };",
        "void main() {",
        "  uint M = pc.M, z = gl_WorkGroupID.z, sg = gl_SubgroupID;",
        f"  uint row0 = gl_WorkGroupID.y * {BM}u + (sg / {wn}u) * 64u, col0 = gl_WorkGroupID.x * {BN}u + (sg % {wn}u) * 64u;",
        "  if (col0 > row0 + 63u) return;  // above the diagonal: the softmax never reads it",
        "  uint qa = z * M * 128u + (row0 / 64u) * 8192u, kb = (z / 3u) * M * 128u + (col0 / 64u) * 8192u;",
        f"  {C_} acc = {C_}(0);",
        "  for (uint kk = 0u; kk < 8u; ++kk) {",
        f"    {A_} a; coopMatLoad(a, q, qa + kk * 1024u, 16u, {RM});",
        f"    {B_} b; coopMatLoad(b, k, kb + kk * 1024u, 16u, {CM});",
        "    acc = coopMatMulAdd(a, b, acc);",
        "  }",
        "  // lane l = row row0 + l, element e = key col0 + e -> R tiles of S [24][M, M] (the softmax runs in place)",
        "  uint l = gl_SubgroupInvocationID;",
        "  uint ob = (z * M * M + ((row0 / 64u) * (M / 16u) + col0 / 16u) * 1024u + l * 16u) / 8u;",
        STORE, "}"]) + "\n"

def pv(wm, wn):
    BM, BN = 64 * wm, 64 * wn
    L = HDR + [
        f"layout(local_size_x = {64 * wm * wn}) in;",
        "layout(push_constant) uniform P { uint M; } pc;",
        "layout(std430, binding = 0) readonly buffer PP { float16_t p[]; };",
        "layout(std430, binding = 1) readonly buffer VT { float16_t vt[]; };",
        "layout(std430, binding = 2) writeonly buffer O { uvec4 o[]; };",
        "void main() {",
        "  uint M = pc.M, z = gl_WorkGroupID.z, sg = gl_SubgroupID, l = gl_SubgroupInvocationID;",
        f"  uint row0 = gl_WorkGroupID.y * {BM}u + (sg / {wn}u) * 64u, col0 = gl_WorkGroupID.x * {BN}u + (sg % {wn}u) * 64u;",
        "  uint pa = z * M * M + (row0 / 64u) * (M / 16u) * 1024u, vb = (z / 3u) * 128u * M + (col0 / 64u) * (M / 16u) * 1024u;",
        f"  {C_} acc = {C_}(0);",
        "  uint nk = (row0 + 64u) / 16u;",
        "  for (uint kk = 0u; kk < nk; ++kk) {",
        f"    {A_} a; coopMatLoad(a, p, pa + kk * 1024u, 16u, {RM});",
        f"    {B_} b; coopMatLoad(b, vt, vb + kk * 1024u, 16u, {CM});",
        "    acc = coopMatMulAdd(a, b, acc);",
        "  }",
        "  // lane l = row row0 + l, element e = column col0 + e -> R tiles of O [M, 3072]",
        "  uint ob = (((row0 / 64u) * 192u + (z * 128u + col0) / 16u) * 1024u + l * 16u) / 8u;",
        STORE.replace("s[ob", "o[ob")]
    L.append("}")
    return "\n".join(L) + "\n"

def build(out=pathlib.Path(__file__).resolve().parent / "kernels"):
    for nm, src in [(f"qk_w{wm}x{wn}", qk(wm, wn)) for wm, wn in ((1, 1), (2, 1), (2, 2), (4, 1), (4, 2))] + \
                   [(f"pv_w{wm}x{wn}", pv(wm, wn)) for wm, wn in ((1, 1), (2, 1), (1, 2), (2, 2), (4, 1), (4, 2))]:
        (out / f"{nm}.comp").write_text(src)
        subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(out / f"{nm}.comp"), "-o", str(out / f"{nm}.spv")], check=True)

if __name__ == "__main__":
    build()

def fa():
    """Causal flash attention, one workgroup per (query head, 64-row query block), two subgroups = the two 64-wide
    halves of the head dim (two 64 x 64 accumulators in one subgroup hang the 850, so each subgroup recomputes the
    scores: +50% attention FLOPs, still on the matrix unit). Per 64-key block: S = Q K^T into an accumulator whose
    lane l holds query row l and element e key e, so the online softmax is lane-local; P (fp16) is written element
    by element into the A operands of O += P V. Output: R tiles of O [M, 3072]. Longest query blocks first."""
    L = HDR + [
        "layout(local_size_x = 128) in;",
        "layout(push_constant) uniform P { uint M; float scale; } pc;",
        "layout(std430, binding = 0) readonly buffer Q { float16_t q[]; };",
        "layout(std430, binding = 1) readonly buffer K { float16_t k[]; };",
        "layout(std430, binding = 2) readonly buffer VT { float16_t vt[]; };",
        "layout(std430, binding = 3) writeonly buffer O { uvec4 o[]; };",
        "void main() {",
        "  uint M = pc.M, z = gl_WorkGroupID.y, g = z / 3u, sg = gl_SubgroupID, l = gl_SubgroupInvocationID;",
        "  uint qb = M / 64u - 1u - gl_WorkGroupID.x, row0 = qb * 64u, d0 = sg * 64u;",
        "  uint qa = z * M * 128u + qb * 8192u, kbase = g * M * 128u, vbase = g * 128u * M + sg * (M / 16u) * 1024u;",
        "  float scale = pc.scale, m = -1e30, lsum = 0.0;",
        f"  {C_} acc = {C_}(0);",
        "  for (uint kb = 0u; kb <= qb; ++kb) {",
        f"    {C_} s = {C_}(0);",
        "    for (uint kk = 0u; kk < 8u; ++kk) {",
        f"      {A_} a; coopMatLoad(a, q, qa + kk * 1024u, 16u, {RM});",
        f"      {B_} b; coopMatLoad(b, k, kbase + (kb * 8u + kk) * 1024u, 16u, {CM});",
        "      s = coopMatMulAdd(a, b, s);",
        "    }",
        "    uint lim = kb == qb ? l : 63u;  // causal: key kb*64 + e visible to row row0 + l iff e <= lim",
        "    float mx = m;",
        "    for (int e = 0; e < 64; ++e) mx = max(mx, uint(e) <= lim ? float(s[e]) * scale : -1e30);",
        "    float f = exp(m - mx);",
        "    m = mx;",
        "    lsum *= f;",
        "    for (int e = 0; e < 64; ++e) acc[e] = float16_t(float(acc[e]) * f);",
        "    for (uint kc = 0u; kc < 4u; ++kc) {",
        f"      {A_} pa = {A_}(0.0hf);",
        "      for (int e = 0; e < 16; ++e) {",
        "        int ke = int(kc) * 16 + e;",
        "        float p = uint(ke) <= lim ? exp(float(s[ke]) * scale - m) : 0.0;",
        "        lsum += p;",
        "        pa[e] = float16_t(p);",
        "      }",
        f"      {B_} vb; coopMatLoad(vb, vt, vbase + (kb * 4u + kc) * 1024u, 16u, {CM});",
        "      acc = coopMatMulAdd(pa, vb, acc);",
        "    }",
        "  }",
        "  float inv = 1.0 / lsum;",
        "  for (int e = 0; e < 64; ++e) acc[e] = float16_t(float(acc[e]) * inv);",
        "  uint ob = (((row0 / 64u) * 192u + (z * 128u + d0) / 16u) * 1024u + l * 16u) / 8u;",
        STORE.replace("s[ob", "o[ob"),
        "}"]
    return "\n".join(L) + "\n"

def build_fa(out=pathlib.Path(__file__).resolve().parent / "kernels"):
    (out / "fa.comp").write_text(fa())
    subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(out / "fa.comp"), "-o", str(out / "fa.spv")], check=True)

if __name__ == "__main__" and len(sys.argv) > 1 and sys.argv[1] == "fa":
    build_fa()

def fa2():
    """Two-pass causal flash attention without element-wise accumulator access (on the 850 driver reading and
    rewriting accumulator elements costs ~20 clocks each, and a matrix-times-scalar rescale is slower still).
    Pass 1: per 64-key block S = Q K^T, coopMatStore to shared memory, each lane reads its row and keeps the
    running max m and sum l (scalars). Pass 2: S again, lanes write P = exp(S*scale - m) / l back to shared,
    four coopMatLoads make the A operands of O += P V. No rescaling of O. Rows padded to 17 x 8 bytes in shared
    against bank conflicts. Workgroup = 2 subgroups (the two 64-wide halves of the head dim)."""
    ST = 17
    L = HDR + [
        "layout(local_size_x = 128) in;",
        "layout(push_constant) uniform P { uint M; float scale; } pc;",
        "layout(std430, binding = 0) readonly buffer Q { float16_t q[]; };",
        "layout(std430, binding = 1) readonly buffer K { float16_t k[]; };",
        "layout(std430, binding = 2) readonly buffer VT { float16_t vt[]; };",
        "layout(std430, binding = 3) writeonly buffer O { uvec4 o[]; };",
        f"shared f16vec4 sh[2 * 64 * {ST}];",
        "uint pk(f16vec4 a, f16vec4 b) { return 0u; }",
        "void main() {",
        "  uint M = pc.M, z = gl_WorkGroupID.y, g = z / 3u, sg = gl_SubgroupID, l = gl_SubgroupInvocationID;",
        "  uint qb = M / 64u - 1u - gl_WorkGroupID.x, row0 = qb * 64u, d0 = sg * 64u;",
        "  uint qa = z * M * 128u + qb * 8192u, kbase = g * M * 128u, vbase = g * 128u * M + sg * (M / 16u) * 1024u;",
        f"  uint sb = sg * 64u * {ST}u, sr = sb + l * {ST}u;",
        "  float scale = pc.scale, m = -1e30, lsum = 0.0;",
        "  for (uint kb = 0u; kb <= qb; ++kb) {",
        f"    {C_} s = {C_}(0);",
        "    for (uint kk = 0u; kk < 8u; ++kk) {",
        f"      {A_} a; coopMatLoad(a, q, qa + kk * 1024u, 16u, {RM});",
        f"      {B_} b; coopMatLoad(b, k, kbase + (kb * 8u + kk) * 1024u, 16u, {CM});",
        "      s = coopMatMulAdd(a, b, s);",
        "    }",
        f"    coopMatStore(s, sh, sb, {ST}u, {RM});",
        "    subgroupMemoryBarrierShared(); subgroupBarrier();",
        "    uint lim = kb == qb ? l : 63u;",
        "    float bm = -1e30;",
        "    for (uint j = 0u; j < 16u; ++j) { vec4 v = vec4(sh[sr + j]); for (uint i = 0u; i < 4u; ++i) if (4u * j + i <= lim) bm = max(bm, v[i]); }",
        "    float mn = max(m, bm * scale);",
        "    lsum *= exp(m - mn);",
        "    for (uint j = 0u; j < 16u; ++j) { vec4 v = vec4(sh[sr + j]); for (uint i = 0u; i < 4u; ++i) if (4u * j + i <= lim) lsum += exp(v[i] * scale - mn); }",
        "    m = mn;",
        "    subgroupBarrier();",
        "  }",
        "  float inv = 1.0 / lsum;",
        f"  {C_} acc = {C_}(0);",
        "  for (uint kb = 0u; kb <= qb; ++kb) {",
        f"    {C_} s = {C_}(0);",
        "    for (uint kk = 0u; kk < 8u; ++kk) {",
        f"      {A_} a; coopMatLoad(a, q, qa + kk * 1024u, 16u, {RM});",
        f"      {B_} b; coopMatLoad(b, k, kbase + (kb * 8u + kk) * 1024u, 16u, {CM});",
        "      s = coopMatMulAdd(a, b, s);",
        "    }",
        f"    coopMatStore(s, sh, sb, {ST}u, {RM});",
        "    subgroupMemoryBarrierShared(); subgroupBarrier();",
        "    uint lim = kb == qb ? l : 63u;",
        "    for (uint j = 0u; j < 16u; ++j) {",
        "      vec4 v = vec4(sh[sr + j]), p;",
        "      for (uint i = 0u; i < 4u; ++i) p[i] = 4u * j + i <= lim ? exp(v[i] * scale - m) * inv : 0.0;",
        "      sh[sr + j] = f16vec4(p);",
        "    }",
        "    subgroupMemoryBarrierShared(); subgroupBarrier();",
        "    for (uint kc = 0u; kc < 4u; ++kc) {",
        f"      {A_} pa; coopMatLoad(pa, sh, sb + kc * 4u, {ST}u, {RM});",
        f"      {B_} vb; coopMatLoad(vb, vt, vbase + (kb * 4u + kc) * 1024u, 16u, {CM});",
        "      acc = coopMatMulAdd(pa, vb, acc);",
        "    }",
        "    subgroupBarrier();",
        "  }",
        f"  coopMatStore(acc, sh, sb, {ST}u, {RM});",
        "  subgroupMemoryBarrierShared(); subgroupBarrier();",
        "  uint ob = (((row0 / 64u) * 192u + (z * 128u + d0) / 16u) * 1024u + l * 16u) / 8u;",
        "  for (uint c = 0u; c < 4u; ++c)",
        "    for (uint h = 0u; h < 2u; ++h) {",
        "      f16vec4 x = sh[sr + c * 4u + h * 2u], y = sh[sr + c * 4u + h * 2u + 1u];",
        "      o[ob + c * 128u + h] = uvec4(packFloat2x16(x.xy), packFloat2x16(x.zw), packFloat2x16(y.xy), packFloat2x16(y.zw));",
        "    }",
        "}"]
    return "\n".join(l for l in L if not l.startswith("uint pk(")) + "\n"

if __name__ == "__main__" and len(sys.argv) > 1 and sys.argv[1] == "fa2":
    out = pathlib.Path(__file__).resolve().parent / "kernels"
    (out / "fa2.comp").write_text(fa2())
    subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(out / "fa2.comp"), "-o", str(out / "fa2.spv")], check=True)

def fa3():
    """fa2 with the score work split instead of duplicated: the two subgroups (head-dim halves) take alternate
    key blocks. Pass 1: each subgroup's running (max, sum) over its blocks, merged through shared memory.
    Pass 2: per pair of key blocks each subgroup computes one S tile and writes its P (normalized) to its shared
    tile; after a workgroup barrier both subgroups multiply both P tiles into their half of O.
    Matrix work per 64 x 64 block: 2 x QK (two passes) + PV = 1.5x the minimum (fa2: 2.5x)."""
    ST = 17
    QK = [f"    {C_} s = {C_}(0);",
          "    for (uint kk = 0u; kk < 8u; ++kk) {",
          f"      {A_} a; coopMatLoad(a, q, qa + kk * 1024u, 16u, {RM});",
          f"      {B_} b; coopMatLoad(b, k, kbase + (kb * 8u + kk) * 1024u, 16u, {CM});",
          "      s = coopMatMulAdd(a, b, s);",
          "    }",
          f"    coopMatStore(s, sh, sb, {ST}u, {RM});",
          "    subgroupMemoryBarrierShared(); subgroupBarrier();",
          "    uint lim = kb == qb ? l : 63u;"]
    L = HDR + [
        "layout(local_size_x = 128) in;",
        "layout(push_constant) uniform P { uint M; float scale; } pc;",
        "layout(std430, binding = 0) readonly buffer Q { float16_t q[]; };",
        "layout(std430, binding = 1) readonly buffer K { float16_t k[]; };",
        "layout(std430, binding = 2) readonly buffer VT { float16_t vt[]; };",
        "layout(std430, binding = 3) writeonly buffer O { uvec4 o[]; };",
        f"shared f16vec4 sh[2 * 64 * {ST}];",
        "shared vec2 stat[2 * 64];",
        "void main() {",
        "  uint M = pc.M, z = gl_WorkGroupID.y, g = z / 3u, sg = gl_SubgroupID, l = gl_SubgroupInvocationID;",
        "  uint qb = M / 64u - 1u - gl_WorkGroupID.x, row0 = qb * 64u, d0 = sg * 64u;",
        "  uint qa = z * M * 128u + qb * 8192u, kbase = g * M * 128u, vbase = g * 128u * M + sg * (M / 16u) * 1024u;",
        f"  uint sb = sg * 64u * {ST}u, sr = sb + l * {ST}u;",
        "  float scale = pc.scale, m = -1e30, lsum = 0.0;",
        "  // every cooperative-matrix op runs unconditionally: the 850 compiler crashes (CoopMatLayoutNode) on",
        "  // multiplies under per-subgroup branches, so a subgroup without a block redoes the last one and ignores it",
        "  for (uint kp = 0u; 2u * kp <= qb; ++kp) {",
        "    bool valid = 2u * kp + sg <= qb;",
        "    uint kb = min(2u * kp + sg, qb);"] + QK + [
        "    if (valid) {",
        "      float bm = -1e30;",
        "      for (uint j = 0u; j < 16u; ++j) { vec4 v = vec4(sh[sr + j]); for (uint i = 0u; i < 4u; ++i) if (4u * j + i <= lim) bm = max(bm, v[i]); }",
        "      float mn = max(m, bm * scale);",
        "      lsum *= exp(m - mn);",
        "      for (uint j = 0u; j < 16u; ++j) { vec4 v = vec4(sh[sr + j]); for (uint i = 0u; i < 4u; ++i) if (4u * j + i <= lim) lsum += exp(v[i] * scale - mn); }",
        "      m = mn;",
        "    }",
        "    subgroupBarrier();",
        "  }",
        "  stat[sg * 64u + l] = vec2(m, lsum);",
        "  barrier();",
        "  vec2 o2 = stat[(1u - sg) * 64u + l];",
        "  float mm = max(m, o2.x);",
        "  float inv = 1.0 / (lsum * exp(m - mm) + o2.y * exp(o2.x - mm));",
        "  m = mm;",
        f"  {C_} acc = {C_}(0);",
        "  for (uint kp = 0u; 2u * kp <= qb; ++kp) {",
        "    bool valid = 2u * kp + sg <= qb;",
        "    uint kb = min(2u * kp + sg, qb);"] + QK + [
        "    for (uint j = 0u; j < 16u; ++j) {",
        "      vec4 v = vec4(sh[sr + j]), p;",
        "      for (uint i = 0u; i < 4u; ++i) p[i] = valid && 4u * j + i <= lim ? exp(v[i] * scale - m) * inv : 0.0;",
        "      sh[sr + j] = f16vec4(p);",
        "    }",
        "    barrier();",
        "    for (uint t = 0u; t < 2u; ++t) {",
        "      uint kt = min(2u * kp + t, qb);  // past the diagonal: that P tile is all zero",
        "      for (uint kc = 0u; kc < 4u; ++kc) {",
        f"        {A_} pa; coopMatLoad(pa, sh, t * 64u * {ST}u + kc * 4u, {ST}u, {RM});",
        f"        {B_} vb; coopMatLoad(vb, vt, vbase + (kt * 4u + kc) * 1024u, 16u, {CM});",
        "        acc = coopMatMulAdd(pa, vb, acc);",
        "      }",
        "    }",
        "    barrier();",
        "  }",
        f"  coopMatStore(acc, sh, sb, {ST}u, {RM});",
        "  subgroupMemoryBarrierShared(); subgroupBarrier();",
        "  uint ob = (((row0 / 64u) * 192u + (z * 128u + d0) / 16u) * 1024u + l * 16u) / 8u;",
        "  for (uint c = 0u; c < 4u; ++c)",
        "    for (uint h = 0u; h < 2u; ++h) {",
        "      f16vec4 x = sh[sr + c * 4u + h * 2u], y = sh[sr + c * 4u + h * 2u + 1u];",
        "      o[ob + c * 128u + h] = uvec4(packFloat2x16(x.xy), packFloat2x16(x.zw), packFloat2x16(y.xy), packFloat2x16(y.zw));",
        "    }",
        "}"]
    return "\n".join(L) + "\n"

if __name__ == "__main__" and len(sys.argv) > 1 and sys.argv[1] == "fa3":
    out = pathlib.Path(__file__).resolve().parent / "kernels"
    (out / "fa3.comp").write_text(fa3())
    subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(out / "fa3.comp"), "-o", str(out / "fa3.spv")], check=True)
