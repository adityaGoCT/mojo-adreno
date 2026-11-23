"""The ALU kernels of the worklog (kernels 1 to 6): C[M,N] = A[M,K] @ B[K,N], fp16 in and out, row-major (NN).

  python3 alu_kernels.py M N K outdir   -> outdir/<kernel>.comp, .spv and manifest lines on stdout

Bindings follow asm/peak/vk_bench.c: 0 = A, 1 = B, 2 = C. M, N and K are literals (#define), because the
Adreno 850's driver runs specialization constants up to 2x slower (AdrenoBLAS's BLOG-ABLAS.md, Step 6).
"""
import pathlib, subprocess, sys

HEAD = """#version 450
#extension GL_EXT_shader_explicit_arithmetic_types_float16 : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_EXT_control_flow_attributes : require
#define M {M}u
#define N {N}u
#define K {K}u
"""

H_BUFS = """layout(std430, binding = 0) readonly buffer A_ { float16_t a[]; };
layout(std430, binding = 1) readonly buffer B_ { float16_t b[]; };
layout(std430, binding = 2) writeonly buffer C_ { float16_t c[]; };
"""

# Kernel 1: one thread per output; neighbouring lanes take neighbouring ROWS of C.
K1 = H_BUFS + """layout(local_size_x = 64, local_size_y = 4) in;
void main() {
  uint row = gl_GlobalInvocationID.x, col = gl_GlobalInvocationID.y;
  float acc = 0.0;
  for (uint k = 0u; k < K; ++k) acc += float(a[row * K + k]) * float(b[k * N + col]);
  c[row * N + col] = float16_t(acc);
}
"""

# Kernel 2: the same, but neighbouring lanes take neighbouring COLUMNS: a subgroup's 64 lanes read one
# 128-byte run of a B row and one shared A value per k.
K2 = H_BUFS + """layout(local_size_x = 64, local_size_y = 4) in;
void main() {
  uint col = gl_GlobalInvocationID.x, row = gl_GlobalInvocationID.y;
  float acc = 0.0;
  for (uint k = 0u; k < K; ++k) acc += float(a[row * K + k]) * float(b[k * N + col]);
  c[row * N + col] = float16_t(acc);
}
"""

# Kernel 3: shared-memory tiles, BS x BS outputs per workgroup, one per thread.
K3 = H_BUFS + """#define BS {BS}u
layout(local_size_x = {BS}, local_size_y = {BS}) in;
shared float As[BS * BS];
shared float Bs[BS * BS];
void main() {
  uint tx = gl_LocalInvocationID.x, ty = gl_LocalInvocationID.y;
  uint row = gl_WorkGroupID.y * BS + ty, col = gl_WorkGroupID.x * BS + tx;
  float acc = 0.0;
  for (uint k0 = 0u; k0 < K; k0 += BS) {
    As[ty * BS + tx] = float(a[row * K + k0 + tx]);
    Bs[ty * BS + tx] = float(b[(k0 + ty) * N + col]);
    barrier();
    [[unroll]] for (uint k = 0u; k < BS; ++k) acc += As[ty * BS + k] * Bs[k * BS + tx];
    barrier();
  }
  c[row * N + col] = float16_t(acc);
}
"""

# Kernel 4: 1D register tiling. 64 x 64 outputs per workgroup, BK = 8, each of 512 threads computes TM = 8
# outputs down a column, reusing one B value from shared memory 8 times.
K4 = H_BUFS + """#define BM 64u
#define BN 64u
#define BK 8u
#define TM 8u
layout(local_size_x = 512) in;
shared float As[BM * BK];
shared float Bs[BK * BN];
void main() {
  uint t = gl_LocalInvocationID.x;
  uint m0 = gl_WorkGroupID.y * BM, n0 = gl_WorkGroupID.x * BN;
  uint tcol = t % BN, trow = t / BN;          // trow 0..7: rows trow*TM .. trow*TM+7
  uint arow = t / BK, acol = t % BK;          // A tile 64 x 8: one element per thread
  uint brow = t / BN, bcol = t % BN;          // B tile 8 x 64: one element per thread
  float acc[TM];
  [[unroll]] for (uint i = 0u; i < TM; ++i) acc[i] = 0.0;
  for (uint k0 = 0u; k0 < K; k0 += BK) {
    As[arow * BK + acol] = float(a[(m0 + arow) * K + k0 + acol]);
    Bs[brow * BN + bcol] = float(b[(k0 + brow) * N + n0 + bcol]);
    barrier();
    [[unroll]] for (uint d = 0u; d < BK; ++d) {
      float bv = Bs[d * BN + tcol];
      [[unroll]] for (uint i = 0u; i < TM; ++i) acc[i] += As[(trow * TM + i) * BK + d] * bv;
    }
    barrier();
  }
  [[unroll]] for (uint i = 0u; i < TM; ++i) c[(m0 + trow * TM + i) * N + n0 + tcol] = float16_t(acc[i]);
}
"""

# Kernel 5: 2D register tiling. 128 x 128 outputs per workgroup, BK = 8, each of 256 threads computes an
# 8 x 8 block: per k step 8 + 8 shared loads feed 64 FMAs.
K5 = H_BUFS + """#define BM 128u
#define BN 128u
#define BK 8u
#define TM 8u
#define TN 8u
layout(local_size_x = 256) in;
shared float As[BM * BK];
shared float Bs[BK * BN];
void main() {
  uint t = gl_LocalInvocationID.x;
  uint m0 = gl_WorkGroupID.y * BM, n0 = gl_WorkGroupID.x * BN;
  uint tcol = t % (BN / TN), trow = t / (BN / TN);
  float acc[TM * TN], rm[TM], rn[TN];
  [[unroll]] for (uint i = 0u; i < TM * TN; ++i) acc[i] = 0.0;
  for (uint k0 = 0u; k0 < K; k0 += BK) {
    [[unroll]] for (uint l = 0u; l < 4u; ++l) {       // A tile 128 x 8 and B tile 8 x 128: 4 elements each
      uint i = t + l * 256u;
      As[i] = float(a[(m0 + i / BK) * K + k0 + i % BK]);
      Bs[i] = float(b[(k0 + i / BN) * N + n0 + i % BN]);
    }
    barrier();
    [[unroll]] for (uint d = 0u; d < BK; ++d) {
      [[unroll]] for (uint i = 0u; i < TM; ++i) rm[i] = As[(trow * TM + i) * BK + d];
      [[unroll]] for (uint j = 0u; j < TN; ++j) rn[j] = Bs[d * BN + tcol * TN + j];
      [[unroll]] for (uint i = 0u; i < TM; ++i)
        [[unroll]] for (uint j = 0u; j < TN; ++j) acc[i * TN + j] += rm[i] * rn[j];
    }
    barrier();
  }
  [[unroll]] for (uint i = 0u; i < TM; ++i)
    [[unroll]] for (uint j = 0u; j < TN; ++j) c[(m0 + trow * TM + i) * N + n0 + tcol * TN + j] = float16_t(acc[i * TN + j]);
}
"""

# Kernel 6: vectorized. 128-bit global loads (8 halves), A transposed into shared memory so each thread
# reads its 8 rows as two vectors, B read as two vectors, 128-bit stores of C. ACC picks the arithmetic:
#   f32: fp16 values converted to fp32, fp32 FMAs (fp32 ALU peak)
#   f16: packed fp16 FMAs into fp16 accumulators (fp16 ALU peak, 2x; accumulation error grows with K)
#   mix: fp16 FMAs within each BK slice, added into fp32 accumulators after it
K6 = """layout(std430, binding = 0) readonly buffer A_ {{ uvec4 a4[]; }};
layout(std430, binding = 1) readonly buffer B_ {{ uvec4 b4[]; }};
layout(std430, binding = 2) writeonly buffer C_ {{ uvec4 c4[]; }};
#define BM 128u
#define BN 128u
#define BK 16u
#define TM 8u
#define TN 8u
#define {ACCDEF}
layout(local_size_x = 256) in;
shared f16vec4 As[BK * BM / 4u];   // [k][m / 4]: A transposed
shared f16vec4 Bs[BK * BN / 4u];   // [k][n / 4]
f16vec4 lo(uvec4 v) {{ return f16vec4(unpackFloat2x16(v.x), unpackFloat2x16(v.y)); }}
f16vec4 hi(uvec4 v) {{ return f16vec4(unpackFloat2x16(v.z), unpackFloat2x16(v.w)); }}
void main() {{
  uint t = gl_LocalInvocationID.x;
  uint m0 = gl_WorkGroupID.y * BM, n0 = gl_WorkGroupID.x * BN;
  uint tcol = t % (BN / TN), trow = t / (BN / TN);
  // loaders: A tile 128 x 16 = 256 vectors of 8 (row t/2, k half t%2); B tile 16 x 128 = 256 vectors (row t/16)
  uint ar = t / 2u, ak = (t % 2u) * 8u, br = t / 16u, bc = (t % 16u) * 8u;
#if defined(ACC_F32)
  vec4 acc[TM][TN / 4u];
#else
  f16vec4 acc[TM][TN / 4u];
#endif
#if defined(ACC_MIX)
  vec4 tot[TM][TN / 4u];
  [[unroll]] for (uint i = 0u; i < TM; ++i) [[unroll]] for (uint j = 0u; j < TN / 4u; ++j) tot[i][j] = vec4(0.0);
#endif
  [[unroll]] for (uint i = 0u; i < TM; ++i) [[unroll]] for (uint j = 0u; j < TN / 4u; ++j) acc[i][j] = {ZERO};
  for (uint k0 = 0u; k0 < K; k0 += BK) {{
    uvec4 av = a4[((m0 + ar) * K + k0 + ak) / 8u];
    uvec4 bv = b4[((k0 + br) * N + n0 + bc) / 8u];
    f16vec4 a0 = lo(av), a1 = hi(av);
    [[unroll]] for (uint j = 0u; j < 4u; ++j) {{       // transpose: element k of row ar -> As[k][ar]
      As[(ak + j) * (BM / 4u) + ar / 4u][ar % 4u] = a0[j];
      As[(ak + 4u + j) * (BM / 4u) + ar / 4u][ar % 4u] = a1[j];
    }}
    Bs[br * (BN / 4u) + bc / 4u] = lo(bv);
    Bs[br * (BN / 4u) + bc / 4u + 1u] = hi(bv);
    barrier();
    [[unroll]] for (uint d = 0u; d < BK; ++d) {{
      f16vec4 m4[2], n4[2];
      m4[0] = As[d * (BM / 4u) + trow * 2u]; m4[1] = As[d * (BM / 4u) + trow * 2u + 1u];
      n4[0] = Bs[d * (BN / 4u) + tcol * 2u]; n4[1] = Bs[d * (BN / 4u) + tcol * 2u + 1u];
      [[unroll]] for (uint i = 0u; i < TM; ++i) {{
#if defined(ACC_F32)
        float x = float(m4[i / 4u][i % 4u]);
        acc[i][0] += x * vec4(n4[0]); acc[i][1] += x * vec4(n4[1]);
#else
        float16_t x = m4[i / 4u][i % 4u];
        acc[i][0] += x * n4[0]; acc[i][1] += x * n4[1];
#endif
      }}
    }}
#if defined(ACC_MIX)
    [[unroll]] for (uint i = 0u; i < TM; ++i) [[unroll]] for (uint j = 0u; j < TN / 4u; ++j) {{
      tot[i][j] += vec4(acc[i][j]); acc[i][j] = f16vec4(0.0);
    }}
#endif
    barrier();
  }}
#if defined(ACC_MIX)
#define OUT(i, j) f16vec4(tot[i][j])
#else
#define OUT(i, j) f16vec4(acc[i][j])
#endif
  [[unroll]] for (uint i = 0u; i < TM; ++i) {{
    f16vec4 x0 = OUT(i, 0), x1 = OUT(i, 1);
    c4[((m0 + trow * TM + i) * N + n0 + tcol * TN) / 8u] =
        uvec4(packFloat2x16(x0.xy), packFloat2x16(x0.zw), packFloat2x16(x1.xy), packFloat2x16(x1.zw));
  }}
}}
"""

def kernels(M, N, K):
    hd = HEAD.format(M=M, N=N, K=K)
    yield "k1_naive", hd + K1, (M // 64, N // 4)
    yield "k2_coalesced", hd + K2, (N // 64, M // 4)
    for bs in (16, 32):
        yield f"k3_shared_bs{bs}", hd + K3.replace("{BS}", str(bs)), (N // bs, M // bs)
    yield "k4_regtile_1d", hd + K4, (N // 64, M // 64)
    yield "k5_regtile_2d", hd + K5, (N // 128, M // 128)
    for acc, zero in (("f32", "vec4(0.0)"), ("f16", "f16vec4(0.0)"), ("mix", "f16vec4(0.0)")):
        yield f"k6_vec_{acc}", hd + K6.format(ACCDEF=f"ACC_{acc.upper()}", ZERO=zero), (N // 128, M // 128)

def main():
    M, N, K = map(int, sys.argv[1:4])
    out = pathlib.Path(sys.argv[4])
    out.mkdir(parents=True, exist_ok=True)
    shape = sys.argv[5] if len(sys.argv) > 5 else f"{M}x{N}x{K}_NN"
    for name, src, (gx, gy) in kernels(M, N, K):
        comp = out / f"{name}.comp"
        comp.write_text(src)
        r = subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(comp), "-o", str(comp.with_suffix(".spv"))],
                           capture_output=True, text=True)
        if r.returncode:
            sys.exit(f"{name}: {r.stderr}")
        print(f"{name} {shape} 64 1 {out.name}/{name}.spv {gx} {gy} 1")

if __name__ == "__main__":
    main()
