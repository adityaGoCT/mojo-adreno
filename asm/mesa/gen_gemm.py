"""ALU GEMM kernels (GLSL -> SPIR-V) and test data for the Adreno 840 compiler-vs-assembly study.

C[M,N] = A[M,K] @ B[K,N]. A is stored transposed (At = K x M row-major, harness layout 'C'), so both operands
are read as rows of 4-vectors. C is fp16. Two math types:
  f32: fp32 operands in memory (harness ESZ=4), fp32 mad and accumulate
  f16: fp16 operands, fp16 mad and accumulate (like the 840 stock cooperative-matrix path)

Workgroup tile BM x BN, thread tile 8 x 8 as two 4-wide chunks each way: thread (tx, ty) owns rows
{ty*4+i, BM/2+ty*4+i} and columns {tx*4+j, BN/2+tx*4+j}, so neighbouring threads read neighbouring vec4s.
Operand source per k step (`src`, A then B): l = shared memory tile (BK deep, staged with barriers),
g = straight from the global buffer (L1/texture path), e.g. "lg" = A from shared memory, B from global.

  python3 gen_gemm.py [S]   # spv/gemm_*.spv, shape/g<S>_{h,s}/, manifest_gemm.txt
"""
import pathlib, subprocess, sys
import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
S = int(sys.argv[1]) if len(sys.argv) > 1 else 2048


def shader(dt, src, BM, BN, BK, M=S, N=S, K=S, kunroll=4):
    T, V = ("float", "vec4") if dt == "f32" else ("float16_t", "f16vec4")
    TX, TY = BN // 8, BM // 8
    NT = TX * TY
    sa, sb = src
    L = ["#version 450",
         "#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require",
         "#extension GL_EXT_shader_16bit_storage : require",
         "#extension GL_EXT_control_flow_attributes : require",
         f"layout(local_size_x = {NT}) in;",
         f"layout(std430, binding = 0) readonly buffer A {{ {V} at4[]; }};   // K x M (A transposed)",
         f"layout(std430, binding = 1) readonly buffer B {{ {V} b4[]; }};    // K x N",
         "layout(std430, binding = 2) writeonly buffer C { f16vec4 c4[]; };   // M x N"]
    if sa == "l":
        L.append(f"shared {V} As[{BK}][{BM // 4}];")
    if sb == "l":
        L.append(f"shared {V} Bs[{BK}][{BN // 4}];")
    L += ["void main() {",
          "  uint tid = gl_LocalInvocationID.x;",
          f"  uint tx = tid % {TX}u, ty = tid / {TX}u;",
          f"  uint bm = gl_WorkGroupID.y * {BM}u, bn = gl_WorkGroupID.x * {BN}u;",
          f"  {V} acc[8][2];",
          f"  for (int i = 0; i < 8; ++i) {{ acc[i][0] = {V}(0); acc[i][1] = {V}(0); }}"]
    staged = "l" in src
    step = BK if staged else kunroll
    L.append(f"  for (uint k0 = 0; k0 < {K}u; k0 += {step}u) {{")
    if sa == "l":
        for r in range(BK * BM // 4 // NT):
            L.append(f"    {{ uint i = tid + {r * NT}u; uint kk = i / {BM // 4}u, mm = i % {BM // 4}u;")
            L.append(f"      As[kk][mm] = at4[(k0 + kk) * {M // 4}u + bm / 4u + mm]; }}")
    if sb == "l":
        for r in range(BK * BN // 4 // NT):
            L.append(f"    {{ uint i = tid + {r * NT}u; uint kk = i / {BN // 4}u, nn = i % {BN // 4}u;")
            L.append(f"      Bs[kk][nn] = b4[(k0 + kk) * {N // 4}u + bn / 4u + nn]; }}")
    if staged:
        L.append("    barrier();")
    L.append(f"    [[unroll]] for (uint k = 0; k < {step}u; ++k) {{")
    if sa == "l":
        L.append(f"      {V} a0 = As[k][ty], a1 = As[k][ty + {BM // 8}u];")
    else:
        L.append(f"      uint ar = (k0 + k) * {M // 4}u + bm / 4u + ty;")
        L.append(f"      {V} a0 = at4[ar], a1 = at4[ar + {BM // 8}u];")
    if sb == "l":
        L.append(f"      {V} b0 = Bs[k][tx], b1 = Bs[k][tx + {BN // 8}u];")
    else:
        L.append(f"      uint br = (k0 + k) * {N // 4}u + bn / 4u + tx;")
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
            L.append(f"  c4[({row}) * {N // 4}u + bn / 4u + {h * BN // 8}u + tx] = f16vec4(acc[{i}][{h}]);")
    L.append("}")
    return "\n".join(L) + "\n"


def write_data():
    h, s = HERE / "shape" / f"g{S}_h", HERE / "shape" / f"g{S}_s"
    h.mkdir(parents=True, exist_ok=True)
    s.mkdir(parents=True, exist_ok=True)
    (h / "meta.txt").write_text(f"{S} {S} {S} C R 0.03\n")
    (s / "meta.txt").write_text(f"{S} {S} {S} C R 0.004 4\n")   # Cref.bin: symlink to g<S>_h on the phone
    if (h / "Cref.bin").exists() and (s / "A.bin").exists():
        return
    rng = np.random.default_rng(0)
    A = rng.uniform(-1, 1, (S, S)).astype(np.float16)
    B = rng.uniform(-1, 1, (S, S)).astype(np.float16)
    A.T.copy().tofile(h / "A.bin")
    B.tofile(h / "B.bin")
    A.T.astype(np.float32).tofile(s / "A.bin")
    B.astype(np.float32).tofile(s / "B.bin")
    (A.astype(np.float32) @ B.astype(np.float32)).astype(np.float32).tofile(h / "Cref.bin")


CONFIGS = [  # (src, BM, BN, BK)
    ("ll", 128, 128, 16), ("ll", 64, 128, 8), ("ll", 64, 64, 16),
    ("lg", 128, 128, 16), ("lg", 64, 128, 16), ("lg", 64, 64, 16),
    ("gl", 128, 128, 16), ("gl", 64, 64, 16),
    ("gg", 128, 128, 0), ("gg", 64, 128, 0), ("gg", 64, 64, 0),
]


def main():
    out = HERE / "spv"
    out.mkdir(exist_ok=True)
    write_data()
    man = []
    for dt in ("f32", "f16"):
        for src, BM, BN, BK in CONFIGS:
            name = f"gemm_{dt}_{src}_{BM}x{BN}" + (f"x{BK}" if BK else "")
            p = out / f"{name}.comp"
            p.write_text(shader(dt, src, BM, BN, BK))
            subprocess.run(["glslc", "--target-env=vulkan1.1", "-O", str(p), "-o", str(out / f"{name}.spv")], check=True)
            shape = f"shape/g{S}_{'s' if dt == 'f32' else 'h'}"
            man.append(f"{name} {shape} 64 1 spv/{name}.spv {S // BN} {S // BM} 1 # flops={2 * S ** 3 // ((S // BN) * (S // BM))}")
    (HERE / f"manifest_gemm{'' if S == 2048 else S}.txt").write_text("\n".join(man) + "\n")
    print(len(man), "kernels")


if __name__ == "__main__":
    main()
