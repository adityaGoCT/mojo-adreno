"""Model-specific fused GEMMs for the Llama 3.2 3B prefill, built from AdrenoBLAS's kernel templates (gen.py RC /
gen_q4.py) with a custom epilogue, one SPIR-V per (format, M) (M, N, K are literal constants: the 850 driver runs
specialization constants slowly).

qkv_rope: the qkv projection [M, 5120] with RoPE in the epilogue, writing the attention kernel's operands directly:
  Q (cols 0..3071) and K (3072..4095) rotated and stored as packed tiles per head ([24][M,128], [8][M,128]);
  V (4096..5119) stored transposed as V^T tiles per KV head ([8][128,M]).
  The Q and K weight rows of every head are permuted to [0, 64, 1, 65, ...] at load time (llama3b.c), so the
  rotate_half pair (d, d + 64) is adjacent in one lane's row; Q K^T is unchanged by the common permutation.
  Staging through shared memory as in epilogue.py; V tiles are staged column-major so lane l holds head dim l.
"""
import pathlib, subprocess, sys
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import epilogue, gen, gen_q4

ST = epilogue.ST

def rope_body(nsg, N, acc="acc", M="M_"):
    L = ["  {", "  uint el = gl_SubgroupInvocationID;",
         f"  uint sb = (sg % 2u) * 64u * {ST}u, sr = sb + el * {ST}u, r = row0 + el;"]
    rounds = (nsg + 1) // 2
    for rd in range(rounds):
        L += [f"  if (sg / 2u == {rd}u) {{",
              "    bool isv = col0 >= 4096u;",
              f"    if (isv) coopMatStore({acc}, ep_sh, sb, {ST}u, gl_CooperativeMatrixLayoutColumnMajor);",
              f"    else coopMatStore({acc}, ep_sh, sb, {ST}u, gl_CooperativeMatrixLayoutRowMajor);",
              "    subgroupMemoryBarrierShared(); subgroupBarrier();",
              "    if (isv) {",
              "      // lane el = head dim d = (col0 - 4096) % 128 + el of KV head g; 64 keys row0 .. row0 + 63",
              "      uint g = (col0 - 4096u) / 128u, d = (col0 - 4096u) % 128u + el;",
              f"      uint ob = (g * 128u * {M} + ((d / 64u) * ({M} / 16u) + row0 / 16u) * 1024u + (d % 64u) * 16u) / 8u;",
              "      for (uint c = 0u; c < 4u; ++c)",
              "        for (uint h = 0u; h < 2u; ++h) {",
              "          f16vec4 x = ep_sh[sr + c * 4u + h * 2u], y = ep_sh[sr + c * 4u + h * 2u + 1u];",
              "          vt4[ob + c * 128u + h] = uvec4(packFloat2x16(x.xy), packFloat2x16(x.zw), packFloat2x16(y.xy), packFloat2x16(y.zw));",
              "        }",
              "    } else {",
              "      bool isq = col0 < 3072u;",
              "      uint head = (isq ? col0 : col0 - 3072u) / 128u, half_ = (col0 % 128u) / 64u;",
              "      uint d0 = half_ * 32u;  // pairs (d, d + 64) for d = d0 .. d0 + 31",
              f"      uint ob = (head * {M} * 128u + ((r / 64u) * 8u + half_ * 4u) * 1024u + el * 16u) / 8u;",
              "      for (uint c = 0u; c < 4u; ++c)",
              "        for (uint h = 0u; h < 2u; ++h) {",
              "          uvec2 w[2];",
              "          for (uint i = 0u; i < 2u; ++i) {",
              "            vec4 x = vec4(ep_sh[sr + c * 4u + h * 2u + i]);  // (x_d, x_d+64, x_d', x_d'+64)",
              "            uint d = d0 + c * 8u + h * 4u + i * 2u;",
              "            vec2 co = vec2(cs[r * 128u + d], cs[r * 128u + d + 1u]), si = vec2(cs[r * 128u + 64u + d], cs[r * 128u + 65u + d]);",
              "            vec4 y = vec4(x.x * co.x - x.y * si.x, x.y * co.x + x.x * si.x, x.z * co.y - x.w * si.y, x.w * co.y + x.z * si.y);",
              "            w[i] = uvec2(packFloat2x16(f16vec2(y.xy)), packFloat2x16(f16vec2(y.zw)));",
              "          }",
              "          if (isq) q4o[ob + c * 128u + h] = uvec4(w[0], w[1]); else k4o[ob + c * 128u + h] = uvec4(w[0], w[1]);",
              "        }",
              "    }",
              "  }"]
        if rd + 1 < rounds:
            L.append("  barrier();")
    L.append("  }")
    return L

DECLS = ["layout(std430, binding = 3) readonly buffer CS { float cs[]; };",
         "layout(std430, binding = 4) writeonly buffer QO { uvec4 q4o[]; };",
         "layout(std430, binding = 5) writeonly buffer KO { uvec4 k4o[]; };",
         "layout(std430, binding = 6) writeonly buffer VTO { uvec4 vt4[]; };"]

def qkv_rope(fmt, cfg, M, N=5120, K=3072):
    c = dict(cfg, ep="p")  # build with the packed epilogue, then swap in the RoPE body
    src = gen.glsl(c, M, N, K) if fmt == "f16" else gen_q4.glsl(c, M, N, K)
    nsg = c["wm"] * c["wn"]
    acc = "c00" if fmt == "f16" else "acc"
    old = "\n".join(epilogue.body("p", nsg, f"{N}u", acc=acc))
    assert old in src, "epilogue not found"
    src = src.replace(old, "\n".join(rope_body(nsg, N, acc=acc, M=f"{M}u")))
    src = src.replace("void main() {", "\n".join(DECLS) + "\nvoid main() {", 1)
    return src

def build(fmt, cfg, M, out=HERE / "kernels"):
    nm = f"qkv_rope_{fmt}_{M}"
    (out / f"{nm}.comp").write_text(qkv_rope(fmt, cfg, M))
    subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(out / f"{nm}.comp"), "-o", str(out / f"{nm}.spv")], check=True)
    return out / f"{nm}.spv"

def tuned(fmt, M):
    """The fastest qkv-shape config from sweep_llm.py (results/llm_<fmt>_<M>x5120x3072.json), else 2 x 2."""
    import json
    f = HERE.parent / "results" / f"llm_{fmt}_{M}x5120x3072.json"
    if f.exists():
        n = json.load(open(f))[0]["name"]
        return gen.parse(n) if fmt == "f16" else gen_q4.parse(n)
    if fmt == "f16":
        return dict(la="R", lb="C", wm=2, wn=2, tm=1, tn=1, nt=64, acc="f16", ku=1, pf=0, sw=0, sa=0, sb=0, kc=0, dual=0)
    return dict(wm=2, wn=2, ks=32)

if __name__ == "__main__":
    # tile sizes go to kernels/qkv_rope_tiles.txt for llama3b.c (fmt M BM BN)
    lines = []
    for fmt in ("f16", "q4"):
        for M in (512, 1024, 2048):
            c = tuned(fmt, M)
            print(build(fmt, c, M), c["wm"], c["wn"])
            lines.append(f"{fmt} {M} {64 * c['wm']} {64 * c['wn']}")
    (HERE / "kernels/qkv_rope_tiles.txt").write_text("\n".join(lines) + "\n")
