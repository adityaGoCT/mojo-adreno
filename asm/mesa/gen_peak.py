"""Peak-ALU shaders for the 840 (copy of ../peak/gen_peak.py writing into this folder, plus a manifest).

Each invocation runs CHAINS independent multiply-add chains (x = x*m + d) for ITERS iterations.
FLOPs per workgroup = LOCAL * ITERS * CHAINS * WIDTH * 2.  Output: spv/peak_*.spv, manifest_peak.txt.
"""
import pathlib, subprocess

HERE = pathlib.Path(__file__).resolve().parent
ITERS = 512
LOCAL = 128
GROUPS = 8192


def shader(dtype, width, chains, iters=ITERS, ops="cc"):
    """ops: where m and d live. cc = both uniform (compiler puts them in the const file), rc = m in a register
    (per-lane value), rr = m and d both in registers (like a GEMM mad: 3 register operands)."""
    t = {("f32", 1): "float", ("f32", 2): "vec2", ("f32", 4): "vec4",
         ("f16", 1): "float16_t", ("f16", 2): "f16vec2", ("f16", 4): "f16vec4"}[(dtype, width)]
    s = "float16_t" if dtype == "f16" else "float"
    L = ["#version 450",
         "#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require",
         "#extension GL_EXT_shader_16bit_storage : require",
         f"layout(local_size_x = {LOCAL}) in;",
         "layout(std430, binding = 0) readonly buffer A { float16_t a[]; };",
         "layout(std430, binding = 2) writeonly buffer C { float c[]; };",
         "void main() {",
         {"cc": f"  {t} m = {t}({s}(a[0])); {t} d = {t}({s}(a[1]));",
          "rc": f"  {t} m = {t}({s}(a[gl_LocalInvocationID.x & 1u])); {t} d = {t}({s}(a[1]));",
          "rr": f"  {t} m = {t}({s}(a[gl_LocalInvocationID.x & 1u])); {t} d = {t}({s}(a[(gl_LocalInvocationID.x + 1u) & 1u]));"}[ops],
         f"  {s} seed = {s}(gl_LocalInvocationID.x) * {s}(0.0009765625);"]
    for i in range(chains):
        L.append(f"  {t} x{i} = {t}(seed + {s}({i}));")
    L.append(f"  for (int i = 0; i < {iters}; ++i) {{")
    for i in range(chains):
        L.append(f"    x{i} = x{i} * m + d;")
    L.append("  }")
    acc = " + ".join(f"x{i}" for i in range(chains))
    L.append(f"  {t} sum = {acc};")
    comp = {1: "float(sum)", 2: "float(sum.x + sum.y)", 4: "float(sum.x + sum.y + sum.z + sum.w)"}[width]
    L.append(f"  float r = {comp};")
    # Not provably false (1234.0 is representable in fp16 and fp32), so the loop survives.
    L.append("  if (r == 1234.0) c[gl_GlobalInvocationID.x] = r;")
    L.append("}")
    return "\n".join(L) + "\n"


def main():
    out = HERE / "spv"
    out.mkdir(exist_ok=True)
    man = []
    combos = [(dt, w, c, "cc") for dt in ("f32", "f16") for w in (1, 2, 4) for c in (8, 16, 32) if w * c <= 64]
    combos += [(dt, w, c, ops) for ops in ("rc", "rr") for dt, w, c in
               (("f32", 1, 32), ("f32", 2, 16), ("f32", 4, 16), ("f16", 2, 32), ("f16", 4, 16))]
    for dtype, width, chains, ops in combos:
                name = f"peak_{dtype}_w{width}_c{chains}" + ("" if ops == "cc" else f"_{ops}")
                src = out / f"{name}.comp"
                src.write_text(shader(dtype, width, chains, ops=ops))
                subprocess.run(["glslc", "--target-env=vulkan1.1", "-O", str(src), "-o", str(out / f"{name}.spv")],
                               check=True)
                man.append(f"{name} shape/peak 64 1 spv/{name}.spv {GROUPS} 1 1 # flops={ITERS * chains * width * 2 * LOCAL}")
    (HERE / "manifest_peak.txt").write_text("\n".join(man) + "\n")
    print(f"{len(man)} shaders -> {out}, manifest_peak.txt")


if __name__ == "__main__":
    main()
