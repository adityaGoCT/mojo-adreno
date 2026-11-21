"""Cooperative-matrix throughput with a fresh A tile loaded every iteration (nothing can be hoisted).

Per iteration, per subgroup: load A_i (64 x K) from global memory (L1/L2-resident, 32 rotating tiles), then
NB multiply-adds c_j += A_i * B_j against NB distinct B tiles loaded once. FLOPs = 2*64*N*K*NB per iteration.
"""
import pathlib, subprocess

HERE = pathlib.Path(__file__).resolve().parent
ITERS, SUBGROUPS, GROUPS = 64, 2, 2048
TYPES = {"f16f16": ("float16_t", "float16_t", 16), "f16f32": ("float16_t", "float", 16), "f32f32": ("float", "float", 8)}

def shader(ab, acc, N, K, nb):
    T = lambda use, r, c, t=ab: f"coopmat<{t}, gl_ScopeSubgroup, {r}, {c}, {use}>"
    L = ["#version 450",
         "#extension GL_KHR_cooperative_matrix : require",
         "#extension GL_KHR_memory_scope_semantics : require",
         "#extension GL_EXT_shader_explicit_arithmetic_types : require",
         "#extension GL_EXT_shader_16bit_storage : require",
         "#extension GL_KHR_shader_subgroup_basic : require",
         f"layout(local_size_x = {64 * SUBGROUPS}) in;",
         f"layout(std430, binding = 0) readonly buffer A {{ {ab} a[]; }};",
         f"layout(std430, binding = 1) readonly buffer B {{ {ab} b[]; }};",
         f"layout(std430, binding = 2) writeonly buffer C {{ {acc} c[]; }};",
         "layout(std430, binding = 3) readonly buffer F { float16_t flag[]; };",
         "void main() {",
         f"  {T('gl_MatrixUseA', 64, K)} ma;"]
    for j in range(nb):
        L.append(f"  {T('gl_MatrixUseB', K, N)} mb{j}; coopMatLoad(mb{j}, b, {j * K * N}, {N}, gl_CooperativeMatrixLayoutRowMajor);")
        L.append(f"  {T('gl_MatrixUseAccumulator', 64, N, acc)} c{j} = {T('gl_MatrixUseAccumulator', 64, N, acc)}(0);")
    L.append("  uint base = (gl_WorkGroupID.x * 7u + gl_SubgroupID * 3u) & 31u;")
    L.append(f"  for (uint i = 0; i < {ITERS}; ++i) {{")
    L.append(f"    coopMatLoad(ma, a, ((base + i) & 31u) * {64 * K}u, {K}, gl_CooperativeMatrixLayoutRowMajor);")
    for j in range(nb):
        L.append(f"    c{j} = coopMatMulAdd(ma, mb{j}, c{j});")
    L.append("  }")
    L.append("  if (flag[0] == float16_t(1.0)) {")
    for j in range(nb):
        L.append(f"    coopMatStore(c{j}, c, {j * 64 * N}, {N}, gl_CooperativeMatrixLayoutRowMajor);")
    L.append("  }")
    L.append("}")
    return "\n".join(L) + "\n"

def main():
    out = HERE / "spv_cml"
    out.mkdir(exist_ok=True)
    lines, var = [], []
    for tname, (ab, acc, K) in TYPES.items():
        for N in (32, 64):
            for nb in (1, 2, 4):
                name = f"cml_{tname}_n{N}k{K}_b{nb}"
                src = out / f"{name}.comp"
                src.write_text(shader(ab, acc, N, K, nb))
                r = subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(src), "-o", str(out / f"{name}.spv")],
                                   capture_output=True, text=True)
                if r.returncode:
                    print(name, r.stderr[:400]); continue
                lines.append(f"{name} shape_cml 64 1 spv_cml/{name}.spv {GROUPS} 1 1\n")
                var.append(f"{name} {SUBGROUPS * ITERS * nb * 2 * 64 * N * K}\n")
    (HERE / "manifest_cml.txt").write_text("".join(lines))
    (out / "variants.txt").write_text("".join(var))
    print(len(lines), "shaders")

if __name__ == "__main__":
    main()
