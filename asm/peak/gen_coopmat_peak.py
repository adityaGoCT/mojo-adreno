"""Cooperative-matrix throughput microbenchmarks: repeated coopMatMulAdd on register-resident tiles.

FLOPs per dispatch = groups * SUBGROUPS * ITERS * ACCS * 2*M*N*K.
"""
import pathlib, subprocess

HERE = pathlib.Path(__file__).resolve().parent
ITERS, SUBGROUPS, GROUPS = 64, 2, 2048
TYPES = {  # name: (A/B type, acc type, K)
    "f16f16": ("float16_t", "float16_t", 16),
    "f16f32": ("float16_t", "float", 16),
    "f32f32": ("float", "float", 8),
    "s8s32": ("int8_t", "int32_t", 32),
}

def shader(ab, acc, M, N, K, accs):
    L = ["#version 450",
         "#extension GL_KHR_cooperative_matrix : require",
         "#extension GL_KHR_memory_scope_semantics : require",
         "#extension GL_EXT_shader_explicit_arithmetic_types : require",
         "#extension GL_EXT_shader_16bit_storage : require",
         "#extension GL_EXT_shader_8bit_storage : require",
         f"layout(local_size_x = {64 * SUBGROUPS}) in;",
         f"layout(std430, binding = 0) readonly buffer A {{ {ab} a[]; }};",
         "layout(std430, binding = 1) readonly buffer F { float16_t flag[]; };",
         f"layout(std430, binding = 2) writeonly buffer C {{ {acc} c[]; }};",
         "void main() {",
         f"  coopmat<{ab}, gl_ScopeSubgroup, {M}, {K}, gl_MatrixUseA> ma;",
         f"  coopmat<{ab}, gl_ScopeSubgroup, {K}, {N}, gl_MatrixUseB> mb;",
         f"  coopMatLoad(ma, a, 0, {K}, gl_CooperativeMatrixLayoutRowMajor);",
         f"  coopMatLoad(mb, a, 0, {N}, gl_CooperativeMatrixLayoutRowMajor);"]
    for i in range(accs):
        L.append(f"  coopmat<{acc}, gl_ScopeSubgroup, {M}, {N}, gl_MatrixUseAccumulator> c{i} = "
                 f"coopmat<{acc}, gl_ScopeSubgroup, {M}, {N}, gl_MatrixUseAccumulator>(0);")
    # A changes every iteration (scalar scale, ~1.5% extra ALU) so the driver cannot hoist A*B out of the loop.
    scale = {"float16_t": "float16_t(1.0009765625)", "float": "1.0001", "int8_t": "int8_t(1)"}[ab]
    L.append(f"  for (int i = 0; i < {ITERS}; ++i) {{")
    for i in range(accs):
        L.append(f"    c{i} = coopMatMulAdd(ma, mb, c{i});")
    L.append(f"    ma = ma * {scale};" if ab != "int8_t" else "    ma = ma + ma;")
    L.append("  }")
    # Adding two coop matrices (c0 + c1) segfaults the 850's stock compiler: store each accumulator instead.
    L.append("  if (flag[0] == float16_t(1.0)) {")
    for i in range(accs):
        L.append(f"    coopMatStore(c{i}, c, {i * 64 * N}, {N}, gl_CooperativeMatrixLayoutRowMajor);")
    L.append("  }")
    L.append("}")
    return "\n".join(L) + "\n"

def main():
    out = HERE / "spv_cm"
    out.mkdir(exist_ok=True)
    lines, var = [], []
    for tname, (ab, acc, K) in TYPES.items():
        for N in (64, 32):
            for accs in (1, 2, 4):
                name = f"cm_{tname}_m64n{N}k{K}_a{accs}"
                src = out / f"{name}.comp"
                src.write_text(shader(ab, acc, 64, N, K, accs))
                r = subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(src), "-o", str(out / f"{name}.spv")],
                                   capture_output=True, text=True)
                if r.returncode:
                    print(name, r.stderr[:300]); continue
                lines.append(f"{name} shape 64 1 spv_cm/{name}.spv {GROUPS} 1 1\n")
                var.append(f"{name} {SUBGROUPS * ITERS * accs * 2 * 64 * N * K}\n")
    (HERE / "manifest_cm.txt").write_text("".join(lines))
    (out / "variants.txt").write_text("".join(var))
    print(len(lines), "coopmat shaders")

if __name__ == "__main__":
    main()
