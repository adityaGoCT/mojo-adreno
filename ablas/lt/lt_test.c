// lt_test: AdrenoBLASLt against CPU references.
//   lt_test          host checks (weight packing, quantization, layouts), then every matmul epilogue and LLM operation
//                    on the GPU (Adreno 850), each against double-precision math on the same fp16-rounded inputs
//   lt_test host     host checks only (any machine; no Vulkan)
#include <math.h>
#include <stdint.h>

#include "../llama3b/vkutil.h"  // first: VK_NO_PROTOTYPES
#include "ablasLt.h"

static int failures;
static uint32_t seed = 1;
static float frand(void) { seed = seed * 1664525u + 1013904223u; return (float)(seed >> 8) / (float)(1u << 23) - 1.0f; }
static float h16(float x) { return (float)(_Float16)x; }
static size_t tidx(uint32_t r, uint32_t k, uint32_t K) {  // tiles (A and B formats alike)
  return ((size_t)(r / 64) * (K / 16) + k / 16) * 1024 + (r % 64) * 16 + k % 16;
}
static void report(const char* name, int ok, double err) {
  printf("%-52s %s  max error %.2e\n", name, ok ? "PASS" : "FAIL", err);
  failures += !ok;
}

// ggml's Q4_0 reference rounding, written out independently of the library, dequantized
static void q4_reference_row(const float* x, uint32_t K, float* out) {
  for (uint32_t b = 0; b < K / 32; ++b) {
    float amax = 0, max = 0;
    for (int j = 0; j < 32; ++j)
      if (fabsf(x[b * 32 + j]) > amax) amax = fabsf(x[b * 32 + j]), max = x[b * 32 + j];
    float d = max / -8, id = d ? 1.0f / d : 0.0f, dh = h16(d);
    for (int j = 0; j < 32; ++j) {
      int qv = (int8_t)(x[b * 32 + j] * id + 8.5f);
      out[b * 32 + j] = ((qv > 15 ? 15 : qv) - 8) * dh;
    }
  }
}

static void host_tests(void) {
  const uint32_t N = 256, K = 192;
  float* w = malloc((size_t)N * K * 4);
  for (size_t i = 0; i < (size_t)N * K; ++i) w[i] = frand() * 0.1f;
  float* row = malloc(K * 4), *ref = malloc(K * 4);
  for (int t = 0; t < 2; ++t) {  // H1/H2: plain packing, decoded back row by row
    ablasLtType ty = t ? ABLASLT_Q4_0 : ABLASLT_F16;
    uint8_t* p = malloc(ablasLtWeightSize(ty, N, K));
    ablasLtWeightPack(ty, ABLASLT_WEIGHT_PLAIN, ABLASLT_SRC_F32_ROWS, w, N, K, p);
    double err = 0;
    for (uint32_t n = 0; n < N; ++n) {
      ablasLtWeightRow(ty, p, N, K, n, row);
      if (ty == ABLASLT_Q4_0) q4_reference_row(w + (size_t)n * K, K, ref);
      for (uint32_t k = 0; k < K; ++k) err = fmax(err, fabs(row[k] - (ty == ABLASLT_Q4_0 ? ref[k] : h16(w[(size_t)n * K + k]))));
    }
    report(t ? "host: Q4_0 pack (ggml rounding) and row decode" : "host: fp16 pack and row decode", err == 0, err);
    free(p);
  }
  for (int t = 0; t < 2; ++t) {  // H3: GATE_UP: logical column n = gate row 32(n/64) + n%64, or up row, for n%64 >= 32
    ablasLtType ty = t ? ABLASLT_Q4_0 : ABLASLT_F16;
    size_t bytes = ablasLtWeightSize(ty, N, K);
    uint8_t *gu = malloc(bytes), *plain = malloc(bytes), *gu2 = malloc(bytes);
    ablasLtWeightPack(ty, ABLASLT_WEIGHT_GATE_UP, ABLASLT_SRC_F32_ROWS, w, N, K, gu);
    double err = 0;
    for (uint32_t n = 0; n < N; ++n) {
      uint32_t src = n % 64 < 32 ? 32 * (n / 64) + n % 64 : N / 2 + 32 * (n / 64) + n % 64 - 32;
      ablasLtWeightRow(ty, gu, N, K, n, row);
      if (ty == ABLASLT_Q4_0) q4_reference_row(w + (size_t)src * K, K, ref);
      for (uint32_t k = 0; k < K; ++k) err = fmax(err, fabs(row[k] - (ty == ABLASLT_Q4_0 ? ref[k] : h16(w[(size_t)src * K + k]))));
    }
    report(t ? "host: Q4_0 gate|up interleave" : "host: fp16 gate|up interleave", err == 0, err);
    // H4: the same from an already packed weight (export.py's files)
    ablasLtWeightPack(ty, ABLASLT_WEIGHT_PLAIN, ABLASLT_SRC_F32_ROWS, w, N, K, plain);
    ablasLtWeightPack(ty, ABLASLT_WEIGHT_GATE_UP, ABLASLT_SRC_PACKED, plain, N, K, gu2);
    report(t ? "host: Q4_0 gate|up from a packed weight" : "host: fp16 gate|up from a packed weight",
           !memcmp(gu, gu2, bytes), 0);
    free(gu), free(plain), free(gu2);
  }
  {  // H5: ggml block_q4_0 rows (a GGUF tensor) give the same bytes as quantizing here
    uint8_t* blocks = malloc((size_t)N * (K / 32) * 18);
    for (uint32_t n = 0; n < N; ++n)
      for (uint32_t b = 0; b < K / 32; ++b) {
        const float* x = w + (size_t)n * K + b * 32;
        float amax = 0, max = 0;
        for (int j = 0; j < 32; ++j)
          if (fabsf(x[j]) > amax) amax = fabsf(x[j]), max = x[j];
        float d = max / -8, id = d ? 1.0f / d : 0.0f;
        uint8_t* blk = blocks + ((size_t)n * (K / 32) + b) * 18;
        _Float16 dh = (_Float16)d;
        memcpy(blk, &dh, 2);
        for (int j = 0; j < 16; ++j) {
          int q0 = (int8_t)(x[j] * id + 8.5f), q1 = (int8_t)(x[16 + j] * id + 8.5f);
          blk[2 + j] = (uint8_t)((q0 > 15 ? 15 : q0) | (q1 > 15 ? 15 : q1) << 4);
        }
      }
    size_t bytes = ablasLtWeightSize(ABLASLT_Q4_0, N, K);
    uint8_t *a = malloc(bytes), *b = malloc(bytes);
    ablasLtWeightPack(ABLASLT_Q4_0, ABLASLT_WEIGHT_PLAIN, ABLASLT_SRC_F32_ROWS, w, N, K, a);
    ablasLtWeightPack(ABLASLT_Q4_0, ABLASLT_WEIGHT_PLAIN, ABLASLT_SRC_GGML_Q4_0, blocks, N, K, b);
    report("host: Q4_0 from ggml blocks == from fp32 rows", !memcmp(a, b, bytes), 0);
    free(a), free(b), free(blocks);
  }
  free(w), free(row), free(ref);
}

// ---- GPU ----------------------------------------------------------------------------------------

static vk_t v;
static ablasLtHandle lt;
static ablas_buf B(vbuf_t* b) { return (ablas_buf){b->buf, 0, 0}; }

static void run(void (*record)(VkCommandBuffer, void*), void* ctx) {
  VkCommandBuffer c = vk_cmd(&v);
  vk_begin(c);
  record(c, ctx);
  CK(vkEndCommandBuffer(c));
  vk_submit_wait(&v, c);
}

// fp16-rounded random matrix [R, C] as fp32
static float* rmat(uint32_t R, uint32_t C, float scale) {
  float* m = malloc((size_t)R * C * 4);
  for (size_t i = 0; i < (size_t)R * C; ++i) m[i] = h16(frand() * scale);
  return m;
}
static vbuf_t tiles_of(const float* m, uint32_t R, uint32_t C) {  // host -> fp16 tiles buffer
  vbuf_t b = vk_buffer(&v, (size_t)R * C * 2);
  for (uint32_t r = 0; r < R; ++r)
    for (uint32_t k = 0; k < C; ++k) ((_Float16*)b.map)[tidx(r, k, C)] = (_Float16)m[(size_t)r * C + k];
  return b;
}
static float tile_at(const vbuf_t* b, uint32_t r, uint32_t k, uint32_t C) { return (float)((_Float16*)b->map)[tidx(r, k, C)]; }
// a weight [N, K] packed by the library, and its exact values (fp16 or dequantized Q4_0) for the reference
static vbuf_t weight(ablasLtType ty, ablasLtWeightUse use, const float* w, uint32_t N, uint32_t K, float** exact) {
  vbuf_t b = vk_buffer(&v, ablasLtWeightSize(ty, N, K));
  ablasLtWeightPack(ty, use, ABLASLT_SRC_F32_ROWS, w, N, K, b.map);
  *exact = malloc((size_t)N * K * 4);
  for (uint32_t n = 0; n < N; ++n) ablasLtWeightRow(ty, b.map, N, K, n, *exact + (size_t)n * K);  // logical column n
  return b;
}
static double dot(const float* a, const float* b, uint32_t K) {
  double s = 0;
  for (uint32_t k = 0; k < K; ++k) s += (double)a[k] * b[k];
  return s;
}

typedef struct { ablasLtMatmulDesc desc; ablas_buf A, W, D, ws; ablasLtLayout a, w, d; ablas_status st; } mm_t;
static void rec_mm(VkCommandBuffer c, void* p) {
  mm_t* m = p;
  m->st = ablasLtMatmul(lt, c, &m->desc, m->A, &m->a, m->W, &m->w, m->D, &m->d, m->ws);
}

static void test_default(ablasLtType ty, uint32_t M, uint32_t N, uint32_t K) {  // fp32 rows in, fp32 rows out
  float *a = rmat(M, K, 1.0f), *w = rmat(N, K, 0.05f), *we;
  vbuf_t A = vk_buffer(&v, (size_t)M * K * 4), W = weight(ty, ABLASLT_WEIGHT_PLAIN, w, N, K, &we),
         Dv = vk_buffer(&v, (size_t)M * N * 4);
  memcpy(A.map, a, (size_t)M * K * 4);
  mm_t m = {{ABLASLT_EPILOGUE_DEFAULT}, B(&A), B(&W), B(&Dv), {0}, {ABLASLT_F32, ABLASLT_ORDER_ROW, M, K},
            {ty, ABLASLT_ORDER_WEIGHT, N, K}, {ABLASLT_F32, ABLASLT_ORDER_ROW, M, N}};
  vbuf_t ws = vk_buffer(&v, ablasLtMatmulWorkspaceSize(&m.desc, &m.a, &m.w, &m.d));
  m.ws = B(&ws);
  run(rec_mm, &m);
  double err = 0, mx = 0;
  for (uint32_t r = 0; r < M; ++r)
    for (uint32_t n = 0; n < N; ++n) {
      double ref = dot(a + (size_t)r * K, we + (size_t)n * K, K);
      err = fmax(err, fabs(((float*)Dv.map)[(size_t)r * N + n] - ref)), mx = fmax(mx, fabs(ref));
    }
  char name[96];
  snprintf(name, sizeof name, "matmul %s %ux%ux%u fp32 rows -> fp32 rows (%s)", ty ? "Q4_0" : "fp16", M, N, K,
           ablasLtLastKernel(lt));
  report(name, !m.st && err / mx < 2e-2, err / mx);
}

static void test_residual(uint32_t M, uint32_t N, uint32_t K) {
  float *a = rmat(M, K, 1.0f), *w = rmat(N, K, 0.05f), *we, *x0 = rmat(M, N, 1.0f);
  vbuf_t A = tiles_of(a, M, K), W = weight(ABLASLT_Q4_0, ABLASLT_WEIGHT_PLAIN, w, N, K, &we),
         X = vk_buffer(&v, (size_t)M * N * 4), aux = vk_buffer(&v, (size_t)M * (N / 64) * 4);
  memcpy(X.map, x0, (size_t)M * N * 4);
  mm_t m = {{ABLASLT_EPILOGUE_RESIDUAL, .aux = B(&aux)}, B(&A), B(&W), B(&X), {0},
            {ABLASLT_F16, ABLASLT_ORDER_TILED, M, K}, {ABLASLT_Q4_0, ABLASLT_ORDER_WEIGHT, N, K},
            {ABLASLT_F32, ABLASLT_ORDER_ROW, M, N}};
  run(rec_mm, &m);
  double err = 0, mx = 0, serr = 0;
  for (uint32_t r = 0; r < M; ++r) {
    for (uint32_t c = 0; c < N / 64; ++c) {
      double ss = 0;
      for (uint32_t n = c * 64; n < c * 64 + 64; ++n) {
        double ref = x0[(size_t)r * N + n] + dot(a + (size_t)r * K, we + (size_t)n * K, K);
        float got = ((float*)X.map)[(size_t)r * N + n];
        err = fmax(err, fabs(got - ref)), mx = fmax(mx, fabs(ref)), ss += (double)got * got;
      }
      serr = fmax(serr, fabs(((float*)aux.map)[r * (N / 64) + c] - ss) / (ss + 1e-6));
    }
  }
  report("matmul RESIDUAL (x += A W^T, row sums of squares)", !m.st && err / mx < 2e-2 && serr < 1e-3, fmax(err / mx, serr));
}

static void test_swiglu(uint32_t M, uint32_t F, uint32_t K) {
  float *a = rmat(M, K, 1.0f), *w = rmat(2 * F, K, 0.05f), *we;  // rows: gate [F], up [F]
  vbuf_t A = tiles_of(a, M, K), W = weight(ABLASLT_F16, ABLASLT_WEIGHT_GATE_UP, w, 2 * F, K, &we),
         O = vk_buffer(&v, (size_t)M * F * 2);
  mm_t m = {{ABLASLT_EPILOGUE_SWIGLU}, B(&A), B(&W), B(&O), {0}, {ABLASLT_F16, ABLASLT_ORDER_TILED, M, K},
            {ABLASLT_F16, ABLASLT_ORDER_WEIGHT, 2 * F, K, ABLASLT_WEIGHT_GATE_UP}, {ABLASLT_F16, ABLASLT_ORDER_TILED, M, F}};
  run(rec_mm, &m);
  double err = 0, mx = 0;
  for (uint32_t r = 0; r < M; ++r)
    for (uint32_t f = 0; f < F; ++f) {
      double g = dot(a + (size_t)r * K, w + (size_t)f * K, K), u = dot(a + (size_t)r * K, w + (size_t)(F + f) * K, K);
      double ref = g / (1 + exp(-g)) * u;
      err = fmax(err, fabs(tile_at(&O, r, f, F) - ref)), mx = fmax(mx, fabs(ref));
    }
  report("matmul SWIGLU (silu(gate) * up, tiles out)", !m.st && err / mx < 2e-2, err / mx);
  free(we);
}

typedef struct { uint32_t M, nh, nkv; vbuf_t *q, *k, *vt, *O; ablas_status st; } at_t;
static void rec_at(VkCommandBuffer c, void* p) {
  at_t* a = p;
  a->st = ablasLtAttention(lt, c, a->M, a->nh, a->nkv, 1.0f / sqrtf(128.0f), B(a->q), B(a->k), B(a->vt), B(a->O));
}

static void test_rope_attention(uint32_t M, uint32_t nh, uint32_t nkv, uint32_t K) {
  uint32_t N = (nh + 2 * nkv) * 128;
  float *a = rmat(M, K, 1.0f), *w = rmat(N, K, 0.05f), *we;
  vbuf_t A = tiles_of(a, M, K), W = weight(ABLASLT_F16, ABLASLT_WEIGHT_PLAIN, w, N, K, &we);
  vbuf_t cs = vk_buffer(&v, (size_t)M * 128 * 4), q = vk_buffer(&v, (size_t)nh * M * 128 * 2),
         k = vk_buffer(&v, (size_t)nkv * M * 128 * 2), vt = vk_buffer(&v, (size_t)nkv * 128 * M * 2),
         O = vk_buffer(&v, (size_t)M * nh * 128 * 2);
  for (uint32_t p = 0; p < M; ++p)
    for (int i = 0; i < 64; ++i) {
      float ang = p * powf(500000.0f, -i / 64.0f);
      ((float*)cs.map)[p * 128 + i] = cosf(ang), ((float*)cs.map)[p * 128 + 64 + i] = sinf(ang);
    }
  mm_t m = {{ABLASLT_EPILOGUE_ROPE_QKV, .n_heads = nh, .n_kv_heads = nkv, .rope = B(&cs), .q = B(&q), .k = B(&k),
             .vt = B(&vt)}, B(&A), B(&W), {0}, {0}, {ABLASLT_F16, ABLASLT_ORDER_TILED, M, K},
            {ABLASLT_F16, ABLASLT_ORDER_WEIGHT, N, K}, {0}};
  vbuf_t ws = vk_buffer(&v, ablasLtMatmulWorkspaceSize(&m.desc, &m.a, &m.w, NULL));
  m.ws = B(&ws);
  run(rec_mm, &m);
  // reference: qkv = A W^T rounded to fp16 as the GEMM writes it, RoPE in fp32, then rounded again
  float* qkv = malloc((size_t)M * N * 4);
  for (uint32_t r = 0; r < M; ++r)
    for (uint32_t n = 0; n < N; ++n) qkv[(size_t)r * N + n] = h16((float)dot(a + (size_t)r * K, we + (size_t)n * K, K));
  double err = 0, mx = 0;
  float* Q = malloc((size_t)nh * M * 128 * 4), *Kk = malloc((size_t)nkv * M * 128 * 4);
  for (uint32_t hd = 0; hd < nh + nkv; ++hd)
    for (uint32_t r = 0; r < M; ++r)
      for (uint32_t d = 0; d < 128; ++d) {
        const float* x = qkv + (size_t)r * N + hd * 128;
        const float* c = (float*)cs.map + r * 128;
        float ref = d < 64 ? x[d] * c[d] - x[d + 64] * c[64 + d] : x[d] * c[d - 64] + x[d - 64] * c[d];
        int isq = hd < nh;
        vbuf_t* t = isq ? &q : &k;
        uint32_t hh = isq ? hd : hd - nh;
        float got = (float)((_Float16*)t->map)[(size_t)hh * M * 128 + tidx(r, d, 128)];
        err = fmax(err, fabs(got - ref)), mx = fmax(mx, fabs(ref));
        (isq ? Q : Kk)[((size_t)hh * M + r) * 128 + d] = got;
      }
  for (uint32_t g = 0; g < nkv; ++g)
    for (uint32_t key = 0; key < M; ++key)
      for (uint32_t d = 0; d < 128; ++d) {
        float ref = qkv[(size_t)key * N + (nh + nkv) * 128 + g * 128 + d];
        float got = (float)((_Float16*)vt.map)[(size_t)g * 128 * M + tidx(d, key, M)];
        err = fmax(err, fabs(got - ref));
      }
  report("matmul ROPE_QKV (Q/K tiles with RoPE, V^T tiles)", !m.st && err / mx < 2e-2, err / mx);
  // attention on those operands: causal softmax(Q K^T * scale) V per query head (KV head = head / group)
  at_t at = {M, nh, nkv, &q, &k, &vt, &O};
  run(rec_at, &at);
  float scale = 1.0f / sqrtf(128.0f);
  double aerr = 0, amx = 0;
  double* s = malloc(M * sizeof *s);
  for (uint32_t hd = 0; hd < nh; ++hd) {
    uint32_t g = hd / (nh / nkv);
    for (uint32_t r = 0; r < M; ++r) {
      double mxs = -1e30, sum = 0;
      for (uint32_t key = 0; key <= r; ++key) {
        s[key] = dot(Q + ((size_t)hd * M + r) * 128, Kk + ((size_t)g * M + key) * 128, 128) * scale;
        mxs = fmax(mxs, s[key]);
      }
      for (uint32_t key = 0; key <= r; ++key) sum += (s[key] = exp(s[key] - mxs));
      for (uint32_t d = 0; d < 128; ++d) {
        double o = 0;
        for (uint32_t key = 0; key <= r; ++key)
          o += s[key] / sum * (double)((_Float16*)vt.map)[(size_t)g * 128 * M + tidx(d, key, M)];
        float got = tile_at(&O, r, hd * 128 + d, nh * 128);
        aerr = fmax(aerr, fabs(got - o)), amx = fmax(amx, fabs(o));
      }
    }
  }
  report("attention (causal, grouped KV heads)", !at.st && aerr / amx < 2e-2, aerr / amx);
  free(s), free(Q), free(Kk), free(qkv), free(we);
}

typedef struct { uint32_t M, D; vbuf_t *x, *ss, *w, *o, *ws; ablas_status st; } nm_t;
static void rec_nm(VkCommandBuffer c, void* p) {
  nm_t* n = p;
  ablas_buf none = {0};
  n->st = ablasLtRmsNorm(lt, c, n->M, n->D, B(n->x), n->ss ? B(n->ss) : none, B(n->w), 1e-5f, B(n->o), B(n->ws));
}

static void test_rmsnorm(uint32_t M, uint32_t D) {
  float *x = rmat(M, D, 2.0f), *w = rmat(1, D, 1.0f);
  vbuf_t X = vk_buffer(&v, (size_t)M * D * 4), W = vk_buffer(&v, (size_t)D * 4), O = vk_buffer(&v, (size_t)M * D * 2),
         SS = vk_buffer(&v, (size_t)M * (D / 64) * 4), ws = vk_buffer(&v, ablasLtRmsNormWorkspaceSize(M));
  memcpy(X.map, x, (size_t)M * D * 4), memcpy(W.map, w, (size_t)D * 4);
  for (uint32_t r = 0; r < M; ++r)
    for (uint32_t c = 0; c < D / 64; ++c) {
      double s = 0;
      for (uint32_t k = c * 64; k < c * 64 + 64; ++k) s += (double)x[(size_t)r * D + k] * x[(size_t)r * D + k];
      ((float*)SS.map)[r * (D / 64) + c] = (float)s;
    }
  for (int mode = 0; mode < 2; ++mode) {
    nm_t n = {M, D, &X, mode ? &SS : NULL, &W, &O, &ws};
    run(rec_nm, &n);
    double err = 0;
    for (uint32_t r = 0; r < M; ++r) {
      double ss = 0;
      for (uint32_t k = 0; k < D; ++k) ss += (double)x[(size_t)r * D + k] * x[(size_t)r * D + k];
      double sc = 1 / sqrt(ss / D + 1e-5);
      for (uint32_t k = 0; k < D; ++k) {
        double ref = w[k] * x[(size_t)r * D + k] * sc;
        err = fmax(err, fabs(tile_at(&O, r, k, D) - ref) / (fabs(ref) + 1e-2));
      }
    }
    report(mode ? "rmsnorm from the residual epilogue's sums" : "rmsnorm (sums computed)", !n.st && err < 1e-2, err);
  }
}

int main(int argc, char** argv) {
  setvbuf(stdout, NULL, _IOLBF, 0);
  host_tests();
  if (argc > 1 && !strcmp(argv[1], "host")) return failures != 0;
  vk_init(&v, 4);
  ablas_handle ab;
  if (ablas_create(&ab, v.pd, v.dev, v.gipa, v.inst) || ablasLtCreate(&lt, ab, v.dev, v.gipa, v.inst, 0)) {
    printf("no AdrenoBLAS on %s\n", v.name);
    return 1;
  }
  printf("device: %s\n", v.name);
  test_default(ABLASLT_F16, 100, 512, 256);   // M not a multiple of 64: fp32 rows in and out
  test_default(ABLASLT_Q4_0, 128, 1024, 512);
  test_residual(128, 512, 256);
  test_swiglu(128, 256, 256);
  test_rope_attention(128, 6, 2, 256);         // 3 query heads per KV head, as Llama 3.2 3B
  test_rmsnorm(128, 512);
  printf("\n%s\n", failures ? "FAILED" : "all passed");
  return failures != 0;
}
