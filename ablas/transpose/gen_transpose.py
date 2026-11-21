"""Transpose kernel variants for AdrenoBLAS packing: dst[C, R] = transpose(src[R, C]), fp16.

Bindings: 0 = src, 2 = dst (as in the library). R, C are literals here (spec constants in the library).
  copy   - 128-bit copy of src to dst (bandwidth ceiling, not a transpose)
  t32    - the library's first kernel: 32x32 shared tile, scalar fp16 loads/stores
  reg8   - each thread loads an 8x8 block (8 x 128-bit rows), transposes in registers, stores 8 x 128-bit
  sh64   - 64x64 shared tile: 128-bit loads, 128-bit stores (8 halves gathered from a tile column)
"""
import pathlib, subprocess

HERE = pathlib.Path(__file__).resolve().parent
HDR = """#version 450
#extension GL_EXT_shader_explicit_arithmetic_types : require
#extension GL_EXT_shader_16bit_storage : require
layout(std430, binding = 0) readonly buffer S { float16_t s[]; };
layout(std430, binding = 0) readonly buffer S4 { uvec4 s4[]; };
layout(std430, binding = 2) writeonly buffer D { float16_t d[]; };
layout(std430, binding = 2) writeonly buffer D4 { uvec4 d4[]; };
"""

def copy(R, C):
    return HDR + f"""layout(local_size_x = 256) in;
void main() {{ uint i = gl_GlobalInvocationID.x; d4[i] = s4[i]; }}
""", (R * C // 8 // 256, 1)

def t32(R, C):
    return HDR + f"""layout(local_size_x = 32, local_size_y = 8) in;
shared float16_t tile[32][33];
void main() {{
  uint tx = gl_LocalInvocationID.x, ty = gl_LocalInvocationID.y;
  uint r0 = gl_WorkGroupID.y * 32u, c0 = gl_WorkGroupID.x * 32u;
  for (uint i = ty; i < 32u; i += 8u) tile[i][tx] = s[(r0 + i) * {C}u + c0 + tx];
  barrier();
  for (uint i = ty; i < 32u; i += 8u) d[(c0 + i) * {R}u + r0 + tx] = tile[tx][i];
}}
""", (C // 32, R // 32)

def reg8(R, C, wgr):
    # workgroup: 64 threads along C (8 halves each = 512 columns) x wgr row-blocks of 8 rows
    return HDR + f"""layout(local_size_x = 64, local_size_y = {wgr}) in;
uint half_of(uvec4 v, uint j) {{ uint w = j < 2u ? v.x : j < 4u ? v.y : j < 6u ? v.z : v.w; return (j & 1u) == 0u ? (w & 0xffffu) : (w >> 16); }}
void main() {{
  uint c0 = (gl_WorkGroupID.x * 64u + gl_LocalInvocationID.x) * 8u;
  uint r0 = (gl_WorkGroupID.y * {wgr}u + gl_LocalInvocationID.y) * 8u;
  uvec4 v[8];
  for (uint i = 0u; i < 8u; ++i) v[i] = s4[((r0 + i) * {C}u + c0) / 8u];
  for (uint j = 0u; j < 8u; ++j) {{
    uvec4 o;
    o.x = half_of(v[0], j) | (half_of(v[1], j) << 16);
    o.y = half_of(v[2], j) | (half_of(v[3], j) << 16);
    o.z = half_of(v[4], j) | (half_of(v[5], j) << 16);
    o.w = half_of(v[6], j) | (half_of(v[7], j) << 16);
    d4[((c0 + j) * {R}u + r0) / 8u] = o;
  }}
}}
""", (C // 512, R // (8 * wgr))

def sh64(R, C):
    # 256 threads; tile 64 x 64 halves = 512 uvec4 in, 512 uvec4 out (2 per thread each way)
    return HDR + f"""layout(local_size_x = 256) in;
shared uint tile[64][33];  // 64 rows x 64 halves as 32 packed uints (+1 pad)
void main() {{
  uint t = gl_LocalInvocationIndex;
  uint r0 = gl_WorkGroupID.y * 64u, c0 = gl_WorkGroupID.x * 64u;
  for (uint e = t; e < 512u; e += 256u) {{  // row e/8, 8-half chunk e%8
    uint r = e >> 3, q = e & 7u;
    uvec4 v = s4[((r0 + r) * {C}u + c0) / 8u + q];
    tile[r][q * 4u] = v.x; tile[r][q * 4u + 1u] = v.y; tile[r][q * 4u + 2u] = v.z; tile[r][q * 4u + 3u] = v.w;
  }}
  barrier();
  for (uint e = t; e < 512u; e += 256u) {{  // output row (= tile column) e/8, 8-half chunk e%8 (tile rows 8q..8q+7)
    uint col = e >> 3, q = e & 7u;
    uint w = col >> 1, sh = (col & 1u) * 16u;
    uint h[8];
    for (uint i = 0u; i < 8u; ++i) h[i] = (tile[q * 8u + i][w] >> sh) & 0xffffu;
    d4[((c0 + col) * {R}u + r0) / 8u + q] = uvec4(h[0] | (h[1] << 16), h[2] | (h[3] << 16), h[4] | (h[5] << 16), h[6] | (h[7] << 16));
  }}
}}
""", (C // 64, R // 64)

VARIANTS = {"copy": copy, "t32": t32, "reg8_1": lambda R, C: reg8(R, C, 1), "reg8_4": lambda R, C: reg8(R, C, 4),
            "sh64": sh64}

if __name__ == "__main__":
    import sys
    R, C = int(sys.argv[1]), int(sys.argv[2])
    out = HERE / f"spv_{R}x{C}"; out.mkdir(exist_ok=True)
    lines = []
    for n, f in VARIANTS.items():
        src, (gx, gy) = f(R, C)
        p = out / f"{n}.comp"; p.write_text(src)
        subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(p), "-o", str(p.with_suffix(".spv"))], check=True)
        shape = f"tr_{R}x{C}" if n != "copy" else f"cp_{R}x{C}"
        lines.append(f"{n} {shape} 64 1 transpose/spv_{R}x{C}/{n}.spv {gx} {gy} 1\n")
    (out / "manifest.txt").write_text("".join(lines))
    print("".join(lines))
