"""AdrenoBLAS Adreno 840 backend: fp16 GEMM on the ALUs (no matrix unit on the 840).

C[M,N] = A[M,K] @ B[K,N], fp16 in, fp16 multiply-add and accumulate, fp16 out, in the layout AdrenoBLAS calls
TN: A stored [K,M] (binding 0), B stored [K,N] (binding 1), C [M,N] (binding 2), all read as f16vec4.

Config (name alu_<src>_<BM>x<BN>[x<BK>]): workgroup tile BM x BN, thread tile 8 x 8 (two 4-wide chunks each way,
(BN/8) x (BM/8) threads). src gives where A and B come from in each k step: l = a BK-deep shared-memory tile
staged with barriers, g = straight from the buffer (L1/texture path); gg kernels step K by 4.
Measured on the 840 in ../asm/mesa (README there): the operand paths matter more than the compiler, and the
best compiler differs per kernel (Qualcomm's stock driver, or Mesa Turnip with or without its bank-aware RA).

glsl(c, M, N, K, spec=True) makes M, N, K specialization constants 0, 1, 2 (the library form; ablas.c rewrites
them to OpConstant per shape); with spec=False they are literals (tuning form).
mark_nobankra(words) tags a SPIR-V module so Turnip built with turnip-ra-bank.patch compiles it without the
bank-aware RA (the per-kernel form of IR3_SHADER_DEBUG=nobankra; the stock driver ignores it).
"""
import re

CONFIGS = [  # (src, BM, BN, BK)
    ("ll", 128, 128, 16), ("ll", 64, 128, 8), ("ll", 64, 64, 16),
    ("lg", 128, 128, 16), ("lg", 64, 128, 16), ("lg", 64, 64, 16),
    ("gl", 128, 128, 16), ("gl", 64, 64, 16),
    ("gg", 128, 128, 0), ("gg", 64, 128, 0), ("gg", 64, 64, 0),
]


def name(c):
    src, BM, BN, BK = c
    return f"alu_{src}_{BM}x{BN}" + (f"x{BK}" if BK else "")


def parse(n):
    m = re.match(r"alu_(ll|lg|gl|gg)_(\d+)x(\d+)(?:x(\d+))?$", n)
    return (m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4) or 0))


def kstep(c):
    return c[3] if c[3] else 4


def threads(c):
    return (c[2] // 8) * (c[1] // 8)


def fits(c, M, N, K):
    return M % c[1] == 0 and N % c[2] == 0 and K % kstep(c) == 0


def glsl(c, M, N, K, spec=False):
    src, BM, BN, BK = c
    if spec:
        M, N, K = "M_", "N_", "K_"
    u = lambda x: f"{x}u" if isinstance(x, int) else x
    TX, TY = BN // 8, BM // 8
    NT = TX * TY
    sa, sb = src
    V = "f16vec4"
    L = ["#version 450",
         "#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require",
         "#extension GL_EXT_shader_16bit_storage : require",
         "#extension GL_EXT_control_flow_attributes : require",
         f"layout(local_size_x = {NT}) in;"]
    if spec:
        L += ["layout(constant_id = 0) const uint M_ = 1024u;", "layout(constant_id = 1) const uint N_ = 1024u;",
              "layout(constant_id = 2) const uint K_ = 1024u;"]
    L += [f"layout(std430, binding = 0) readonly buffer A {{ {V} at4[]; }};   // [K,M]",
          f"layout(std430, binding = 1) readonly buffer B {{ {V} b4[]; }};    // [K,N]",
          "layout(std430, binding = 2) writeonly buffer C { f16vec4 c4[]; };   // [M,N]"]
    if sa == "l":
        L.append(f"shared {V} As[{BK}][{BM // 4}];")
    if sb == "l":
        L.append(f"shared {V} Bs[{BK}][{BN // 4}];")
    L += ["void main() {",
          "  uint tid = gl_LocalInvocationID.x;",
          f"  uint tx = tid % {TX}u, ty = tid / {TX}u;",
          f"  uint bm = gl_WorkGroupID.y * {BM}u, bn = gl_WorkGroupID.x * {BN}u;",
          f"  uint M4 = {u(M)}, N4 = {u(N)};",       # runtime ops, not spec-constant ops (ablas.c's specialize()
          "  M4 >>= 2; N4 >>= 2;",                    # only rewrites OpSpecConstant)
          f"  {V} acc[8][2];",
          f"  for (int i = 0; i < 8; ++i) {{ acc[i][0] = {V}(0); acc[i][1] = {V}(0); }}"]
    staged = "l" in src
    step = kstep(c)
    L.append(f"  for (uint k0 = 0; k0 < {u(K)}; k0 += {step}u) {{")
    if sa == "l":
        for r in range(BK * BM // 4 // NT):
            L.append(f"    {{ uint i = tid + {r * NT}u; uint kk = i / {BM // 4}u, mm = i % {BM // 4}u;")
            L.append(f"      As[kk][mm] = at4[(k0 + kk) * M4 + bm / 4u + mm]; }}")
    if sb == "l":
        for r in range(BK * BN // 4 // NT):
            L.append(f"    {{ uint i = tid + {r * NT}u; uint kk = i / {BN // 4}u, nn = i % {BN // 4}u;")
            L.append(f"      Bs[kk][nn] = b4[(k0 + kk) * N4 + bn / 4u + nn]; }}")
    if staged:
        L.append("    barrier();")
    L.append(f"    [[unroll]] for (uint k = 0; k < {step}u; ++k) {{")
    if sa == "l":
        L.append(f"      {V} a0 = As[k][ty], a1 = As[k][ty + {BM // 8}u];")
    else:
        L.append("      uint ar = (k0 + k) * M4 + bm / 4u + ty;")
        L.append(f"      {V} a0 = at4[ar], a1 = at4[ar + {BM // 8}u];")
    if sb == "l":
        L.append(f"      {V} b0 = Bs[k][tx], b1 = Bs[k][tx + {BN // 8}u];")
    else:
        L.append("      uint br = (k0 + k) * N4 + bn / 4u + tx;")
        L.append(f"      {V} b0 = b4[br], b1 = b4[br + {BN // 8}u];")
    for i in range(8):
        a = f"a{i // 4}.{'xyzw'[i % 4]}"
        L.append(f"      acc[{i}][0] = {a} * b0 + acc[{i}][0]; acc[{i}][1] = {a} * b1 + acc[{i}][1];")
    L.append("    }")
    if staged:
        L.append("    barrier();")
    L.append("  }")
    for i in range(8):
        row = f"bm + {'0u' if i < 4 else f'{BM // 2}u'} + ty * 4u + {i % 4}u"
        for h in range(2):
            L.append(f"  c4[({row}) * N4 + bn / 4u + {h * BN // 8}u + tx] = acc[{i}][{h}];")
    L.append("}")
    return "\n".join(L) + "\n"


def mark_nobankra(words, label="ablas_nobankra"):
    """Give the module an OpSource whose file name (a new OpString) contains 'nobankra'; returns new words.
    glslc -O strips OpSource, so both go into the debug section right after the execution modes."""
    w = list(words)
    bound = w[3]
    s = label.encode() + b"\0"
    s += b"\0" * (-len(s) % 4)
    sw = [int.from_bytes(s[k:k + 4], "little") for k in range(0, len(s), 4)]
    head = {17, 10, 11, 14, 15, 16, 331}  # Capability Extension ExtInstImport MemoryModel EntryPoint ExecutionMode(Id)
    i, out, done = 5, w[:5], False
    while i < len(w):
        op, n = w[i] & 0xffff, w[i] >> 16
        if not done and op not in head:
            assert op != 3, "module already has an OpSource"
            out += [((2 + len(sw)) << 16) | 7, bound] + sw              # OpString %bound "label"
            out += [(4 << 16) | 3, 2, 450, bound]                        # OpSource GLSL 450 %bound
            done = True
        out += w[i:i + n]
        i += n
    out[3] = bound + 1
    return out
