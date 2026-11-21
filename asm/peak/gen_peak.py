"""Generate peak-ALU microbenchmark shaders (GLSL compute) for the Adreno 840.

Each invocation runs CHAINS independent multiply-add chains for ITERS iterations.
FLOPs per dispatch = groups * LOCAL * ITERS * CHAINS * WIDTH * 2.
Variants: fp32 / fp16, vector width 1/2/4, chain counts.
"""
import pathlib, subprocess, sys

HERE = pathlib.Path(__file__).resolve().parent
ITERS = 512
LOCAL = 128

def shader(dtype, width, chains):
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
         f"  {t} m = {t}({s}(a[0])); {t} d = {t}({s}(a[1]));",
         f"  {s} seed = {s}(gl_LocalInvocationID.x) * {s}(0.0009765625);"]
    for i in range(chains):
        L.append(f"  {t} x{i} = {t}(seed + {s}({i}));")
    L.append(f"  for (int i = 0; i < {ITERS}; ++i) {{")
    for i in range(chains):
        L.append(f"    x{i} = x{i} * m + d;")
    L.append("  }")
    acc = " + ".join(f"x{i}" for i in range(chains))
    L.append(f"  {t} sum = {acc};")
    comp = {1: "float(sum)", 2: "float(sum.x + sum.y)", 4: "float(sum.x + sum.y + sum.z + sum.w)"}[width]
    L.append(f"  float r = {comp};")
    L.append("  if (r == 1234.0) c[gl_GlobalInvocationID.x] = r;")
    L.append("}")
    return "\n".join(L) + "\n"

def main():
    out = HERE / "spv"
    out.mkdir(exist_ok=True)
    variants = []
    for dtype in ("f32", "f16"):
        for width in (1, 2, 4):
            for chains in (8, 16, 32):
                if width * chains > 64:
                    continue
                name = f"peak_{dtype}_w{width}_c{chains}"
                src = out / f"{name}.comp"
                src.write_text(shader(dtype, width, chains))
                subprocess.run(["glslc", "--target-env=vulkan1.1", "-O", str(src), "-o", str(out / f"{name}.spv")], check=True)
                variants.append((name, ITERS * chains * width * 2 * LOCAL))
    (out / "variants.txt").write_text("".join(f"{n} {f}\n" for n, f in variants))
    print(f"{len(variants)} shaders in {out}")

if __name__ == "__main__":
    main()
