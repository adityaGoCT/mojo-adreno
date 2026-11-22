"""GEMM epilogues for the 64 x 64-tile kernels (gen.py RC with tm = tn = 1, nt = 64, and gen_q4.py).

After the K loop each subgroup holds one 64 x 64 fp16 accumulator. Reading its elements directly is slow on the
850 driver (~20 clocks per element, and constant indices can crash the compiler), so the epilogue stages it
through shared memory: coopMatStore to a padded 64 x 68-half tile (rows 17 x 8 bytes apart: no bank conflicts),
then lane l works on row l. Two subgroups stage at a time (2 x 8.7 KB), in rounds separated by barriers.

  'p'  packed: C written as AdrenoBLAS's packed A operand (R tiles) of an [M, N] matrix, so the next GEMM can
       take it as ABLAS_OP_P without a pack pass.
  'g'  SwiGLU: B's columns come in interleaved 64-column groups [32 gate | 32 up]; writes
       silu(gate) * up as R tiles of an [M, N/2] matrix (fp32 math).
  'f'  fp32 output: C is fp32 row-major [M, N]; only rows < the push constant mrows are written (M is padded to the
       tile, e.g. for a llama.cpp matmul with a few tokens).
  'a'  residual + RMS statistics: C is an fp32 row-major [M, N] residual stream, C += A B; the workspace (binding 3)
       receives each row's sum of squares of the updated C per 64-column tile, ws[r * (N/64) + col0/64].
  'l'  GeGLU: as 'g', with gelu_tanh(gate) * up (Gemma's MLP), written as gate * sigmoid(1.5957691 (gate + 0.044715
       gate^3)), the same function in a form that cannot overflow.
  'b'  bias + GELU: as 'p', with gelu_tanh(C + bias) (a ViT's fc1); bias fp32 [N] at binding 3.
  'r'  residual + bias: C (fp32 row-major [M, N]) += A B + bias (a ViT's attention output and fc2); bias fp32 [N] at
       binding 3.
"""
ST = 17  # padded row stride of the staging tile, in f16vec4

def decls(nsg, ep=None):
    d = [f"shared f16vec4 ep_sh[{min(nsg, 2)} * 64 * {ST}];"]
    if ep == "f":
        d += ["layout(push_constant) uniform EPC { uint mrows; } epc;",
              "layout(std430, binding = 2) writeonly buffer CF4 { vec4 cf4[]; };"]
    if ep == "a":
        d += ["layout(std430, binding = 2) buffer CF { vec4 cf[]; };",
              "layout(std430, binding = 3) writeonly buffer WS { float wsf[]; };"]
    if ep == "r":
        d += ["layout(std430, binding = 2) buffer CF { vec4 cf[]; };"]
    if ep in "br":
        d += ["layout(std430, binding = 3) readonly buffer BI { vec4 bias4[]; };"]
    if ep in "lb":
        d += ["vec4 gelu_t(vec4 x) { return x / (1.0 + exp(-1.5957691 * x * (1.0 + 0.044715 * x * x))); }"]
    return d

def body(ep, nsg, N, acc="acc", out="c4"):
    """GLSL for the epilogue. Needs: sg, row0, col0, acc (64 x 64 f16 accumulator); `out` a uvec4 view of C."""
    L = ["  {", "  uint el = gl_SubgroupInvocationID;",
         f"  uint sb = (sg % 2u) * 64u * {ST}u, sr = sb + el * {ST}u, r = row0 + el;"]
    for rd in range((nsg + 1) // 2):
        L.append(f"  if (sg / 2u == {rd}u) {{")
        L.append(f"    coopMatStore({acc}, ep_sh, sb, {ST}u, gl_CooperativeMatrixLayoutRowMajor);")
        L.append("    subgroupMemoryBarrierShared(); subgroupBarrier();")
        if ep == "p":
            L += [f"    uint ob = (((r / 64u) * ({N} / 16u) + col0 / 16u) * 1024u + el * 16u) / 8u;",
                  "    for (uint c = 0u; c < 4u; ++c)",
                  "      for (uint h = 0u; h < 2u; ++h) {",
                  "        f16vec4 x = ep_sh[sr + c * 4u + h * 2u], y = ep_sh[sr + c * 4u + h * 2u + 1u];",
                  f"        {out}[ob + c * 128u + h] = uvec4(packFloat2x16(x.xy), packFloat2x16(x.zw), packFloat2x16(y.xy), packFloat2x16(y.zw));",
                  "      }"]
        elif ep == "b":
            L += [f"    uint ob = (((r / 64u) * ({N} / 16u) + col0 / 16u) * 1024u + el * 16u) / 8u;",
                  "    for (uint c = 0u; c < 4u; ++c)",
                  "      for (uint h = 0u; h < 2u; ++h) {",
                  "        uint bi = (col0 + c * 16u + h * 8u) / 4u;",
                  "        vec4 x = gelu_t(vec4(ep_sh[sr + c * 4u + h * 2u]) + bias4[bi]);",
                  "        vec4 y = gelu_t(vec4(ep_sh[sr + c * 4u + h * 2u + 1u]) + bias4[bi + 1u]);",
                  f"        {out}[ob + c * 128u + h] = uvec4(packFloat2x16(f16vec2(x.xy)), packFloat2x16(f16vec2(x.zw)), packFloat2x16(f16vec2(y.xy)), packFloat2x16(f16vec2(y.zw)));",
                  "      }"]
        elif ep in "gl":
            L += [f"    uint ob = (((r / 64u) * ({N} / 32u) + col0 / 32u) * 1024u + el * 16u) / 8u;",
                  "    for (uint c = 0u; c < 2u; ++c)",
                  "      for (uint h = 0u; h < 2u; ++h) {",
                  "        uvec2 w[2];",
                  "        for (uint i = 0u; i < 2u; ++i) {",
                  "          vec4 gg = vec4(ep_sh[sr + c * 4u + h * 2u + i]), uu = vec4(ep_sh[sr + 8u + c * 4u + h * 2u + i]);",
                  "          vec4 a = gg / (1.0 + exp(-gg)) * uu;" if ep == "g" else "          vec4 a = gelu_t(gg) * uu;",
                  "          w[i] = uvec2(packFloat2x16(f16vec2(a.xy)), packFloat2x16(f16vec2(a.zw)));",
                  "        }",
                  f"        {out}[ob + c * 128u + h] = uvec4(w[0], w[1]);",
                  "      }"]
        elif ep == "f":
            L += ["    if (r < epc.mrows) {",
                  f"      uint xi = (r * {N} + col0) / 4u;",
                  "      for (uint j = 0u; j < 16u; ++j) cf4[xi + j] = vec4(ep_sh[sr + j]);",
                  "    }"]
        elif ep == "a":
            L += [f"    uint xi = (r * {N} + col0) / 4u;",
                  "    float ss = 0.0;",
                  "    for (uint j = 0u; j < 16u; ++j) {",
                  "      vec4 xv = cf[xi + j] + vec4(ep_sh[sr + j]);",
                  "      cf[xi + j] = xv;",
                  "      ss += dot(xv, xv);",
                  "    }",
                  f"    wsf[r * ({N} / 64u) + col0 / 64u] = ss;"]
        elif ep == "r":
            L += [f"    uint xi = (r * {N} + col0) / 4u;",
                  "    for (uint j = 0u; j < 16u; ++j) cf[xi + j] += vec4(ep_sh[sr + j]) + bias4[col0 / 4u + j];"]
        else:
            raise ValueError(ep)
        L.append("  }")
        if rd + 1 < (nsg + 1) // 2:
            L.append("  barrier();")
    L.append("  }")
    return L
