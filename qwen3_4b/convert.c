// Writes Qwen3-4B's weight file (qwen3_4b_q4.bin) on the phone from the bf16 checkpoint it downloads
// (model-0000{1,2,3}-of-00003.safetensors), following export.py's recipe.txt. Every line reads one tensor at its
// absolute offset in one of the shards (index 0, 1, 2 on the command line):
//   size <bytes>                                     the output's size (alignment gaps stay zero)
//   q4 <shard> <src> <rows> <cols> <out q> <out s>   bf16 -> ggml's Q4_0 (quantize_row_q4_0_ref: per 32 weights,
//                                                    d = the value of largest magnitude / -8, q = min(15, (int)
//                                                    (w / d + 8.5)), d stored fp16) -> int4 words (8 a uint32,
//                                                    element 8w + k in bits 4k, 4-bit two's complement q - 8) and the
//                                                    fp16 d's: lfm2/kernels/lk.mojo's q4 storage
//   q6 <shard> <src> <rows> <cols> <out q> <out d>   bf16 -> ggml's Q6_K (quantize_row_q6_K_ref with make_qx_quants)
//                                                    -> 208 bytes a super-block of 256 (ql, qh, int8 scales) and the
//                                                    fp16 d's apart: lk.mojo's tied embedding / head storage
//   f32 <shard> <src> <n> <out>                      bf16 -> fp32 (the norms)
// A block of rows at a time (threads split each block), so the phone never holds a whole matrix.
//
//   qwen3_4b_convert <recipe.txt> <out.bin> <shard 1> <shard 2> <shard 3>
//
// The quantizers are also the reference's (reference.py loads this file as a library, q4b_q4_0 and q4b_q6_k, which
// write ggml's own block layouts): built for macOS (cc -shared) and Android (the NDK's clang), both with
// -ffp-contract=off, so the phone's weights and the Mac's are the same bytes.
#include <math.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define GROUP_MAX_EPS 1e-15f

static inline int nearest_int(float fval) {
  float val = fval + 12582912.f;
  int i;
  memcpy(&i, &val, sizeof(int));
  return (i & 0x007fffff) - 0x00400000;
}

static inline uint16_t to_half(float f) {
  __fp16 h = (__fp16)f;
  uint16_t u;
  memcpy(&u, &h, 2);
  return u;
}

static inline float from_half(uint16_t u) {
  __fp16 h;
  memcpy(&h, &u, 2);
  return (float)h;
}

// ggml's quantize_row_q4_0_ref: n weights (a multiple of 32) -> n / 32 blocks of 18 bytes (fp16 d, 16 bytes: element j
// in the low nibble of byte j, element j + 16 in its high nibble).
void q4b_q4_0(const float *x, long long n, uint8_t *out) {
  for (long long i = 0; i < n / 32; ++i) {
    const float *v = x + i * 32;
    uint8_t *b = out + i * 18;
    float amax = 0.0f, max = 0.0f;
    for (int j = 0; j < 32; ++j) {
      if (amax < fabsf(v[j])) {
        amax = fabsf(v[j]);
        max = v[j];
      }
    }
    const float d = max / -8;
    const float id = d ? 1.0f / d : 0.0f;
    uint16_t h = to_half(d);
    memcpy(b, &h, 2);
    for (int j = 0; j < 16; ++j) {
      const float x0 = v[j] * id;
      const float x1 = v[16 + j] * id;
      int q0 = (int8_t)(x0 + 8.5f);
      int q1 = (int8_t)(x1 + 8.5f);
      q0 = q0 < 15 ? q0 : 15;
      q1 = q1 < 15 ? q1 : 15;
      b[2 + j] = (uint8_t)(q0 | (q1 << 4));
    }
  }
}

// ggml's make_qx_quants (rmse_type 1, no importance weights).
static float make_qx_quants(int n, int nmax, const float *x, int8_t *L) {
  float max = 0, amax = 0;
  for (int i = 0; i < n; ++i) {
    float ax = fabsf(x[i]);
    if (ax > amax) {
      amax = ax;
      max = x[i];
    }
  }
  if (amax < GROUP_MAX_EPS) {
    for (int i = 0; i < n; ++i) L[i] = 0;
    return 0.f;
  }
  float iscale = -nmax / max;
  float sumlx = 0, suml2 = 0;
  for (int i = 0; i < n; ++i) {
    int l = nearest_int(iscale * x[i]);
    l = l < -nmax ? -nmax : (l > nmax - 1 ? nmax - 1 : l);
    L[i] = l + nmax;
    float w = x[i] * x[i];
    sumlx += w * x[i] * l;
    suml2 += w * l * l;
  }
  float scale = suml2 ? sumlx / suml2 : 0.0f;
  float best = scale * sumlx;
  for (int is = -9; is <= 9; ++is) {
    if (is == 0) continue;
    iscale = -(nmax + 0.1f * is) / max;
    sumlx = suml2 = 0;
    for (int i = 0; i < n; ++i) {
      int l = nearest_int(iscale * x[i]);
      l = l < -nmax ? -nmax : (l > nmax - 1 ? nmax - 1 : l);
      float w = x[i] * x[i];
      sumlx += w * x[i] * l;
      suml2 += w * l * l;
    }
    if (suml2 > 0 && sumlx * sumlx > best * suml2) {
      for (int i = 0; i < n; ++i) {
        int l = nearest_int(iscale * x[i]);
        L[i] = nmax + (l < -nmax ? -nmax : (l > nmax - 1 ? nmax - 1 : l));
      }
      scale = sumlx / suml2;
      best = scale * sumlx;
    }
  }
  return scale;
}

// ggml's quantize_row_q6_K_ref: n weights (a multiple of 256) -> n / 256 super-blocks of 210 bytes (ql[128], qh[64],
// int8 scales[16], fp16 d).
void q4b_q6_k(const float *x, long long n, uint8_t *out) {
  for (long long i = 0; i < n / 256; ++i, x += 256) {
    uint8_t *ql = out + i * 210, *qh = ql + 128;
    int8_t *sc = (int8_t *)(ql + 192);
    int8_t L[256];
    float scales[16];
    float max_scale = 0, max_abs_scale = 0;
    for (int ib = 0; ib < 16; ++ib) {
      const float scale = make_qx_quants(16, 32, x + 16 * ib, L + 16 * ib);
      scales[ib] = scale;
      if (fabsf(scale) > max_abs_scale) {
        max_abs_scale = fabsf(scale);
        max_scale = scale;
      }
    }
    if (max_abs_scale < GROUP_MAX_EPS) {
      memset(ql, 0, 210);
      continue;
    }
    float iscale = -128.f / max_scale;
    uint16_t dh = to_half(1 / iscale);
    memcpy(ql + 208, &dh, 2);
    for (int ib = 0; ib < 16; ++ib) {
      int s = nearest_int(iscale * scales[ib]);
      sc[ib] = (int8_t)(s < 127 ? s : 127);
    }
    for (int j = 0; j < 16; ++j) {
      float d = from_half(dh) * sc[j];
      if (!d) continue;
      for (int ii = 0; ii < 16; ++ii) {
        int l = nearest_int(x[16 * j + ii] / d);
        l = l < -32 ? -32 : (l > 31 ? 31 : l);
        L[16 * j + ii] = l + 32;
      }
    }
    for (int j = 0; j < 256; j += 128) {
      for (int l = 0; l < 32; ++l) {
        const uint8_t q1 = L[j + l + 0] & 0xF, q2 = L[j + l + 32] & 0xF;
        const uint8_t q3 = L[j + l + 64] & 0xF, q4 = L[j + l + 96] & 0xF;
        ql[l + 0] = q1 | (q3 << 4);
        ql[l + 32] = q2 | (q4 << 4);
        qh[l] = (L[j + l] >> 4) | ((L[j + l + 32] >> 4) << 2) | ((L[j + l + 64] >> 4) << 4) |
                ((L[j + l + 96] >> 4) << 6);
      }
      ql += 64;
      qh += 32;
    }
  }
}

// ---- the converter ------------------------------------------------------------------------------------------------

static void *grow(void *p, size_t *cap, size_t need) {
  if (need <= *cap) return p;
  free(p);
  *cap = need;
  p = malloc(need);
  if (!p) {
    fprintf(stderr, "out of memory (%zu bytes)\n", need);
    exit(2);
  }
  return p;
}

static void get(FILE *f, long long off, void *dst, size_t n) {
  if (fseeko(f, off, SEEK_SET) || fread(dst, 1, n, f) != n) {
    fprintf(stderr, "read of %zu bytes at %lld failed\n", n, off);
    exit(2);
  }
}

static void put(FILE *f, long long off, const void *src, size_t n) {
  if (fseeko(f, off, SEEK_SET) || fwrite(src, 1, n, f) != n) {
    fprintf(stderr, "write of %zu bytes at %lld failed\n", n, off);
    exit(2);
  }
}

// One Q4_0 block (18 bytes) -> 4 int4 words and its fp16 scale (lfm2/convert.c's q4_block).
static void q4_words(const uint8_t *b, uint32_t *q, uint8_t *s) {
  memcpy(s, b, 2);
  const uint8_t *qs = b + 2;
  for (int w = 0; w < 4; ++w) {
    uint32_t word = 0;
    for (int k = 0; k < 8; ++k) {
      int e = 8 * w + k;
      int nib = e < 16 ? (qs[e] & 15) : (qs[e - 16] >> 4);
      word |= (uint32_t)(nib ^ 8) << (4 * k);
    }
    q[w] = word;
  }
}

typedef struct {
  const uint16_t *src;  // bf16 rows
  float *row;           // a row's fp32 scratch
  uint8_t *blocks;      // a row's ggml blocks
  uint8_t *q, *s;       // outputs of the whole block of rows
  long long r0, r1, cols;
  int q6;
} job;

static void *work(void *arg) {
  job *j = arg;
  long long bs = j->q6 ? 256 : 32, nb = j->cols / bs;
  for (long long r = j->r0; r < j->r1; ++r) {
    for (long long c = 0; c < j->cols; ++c) {
      uint32_t u = (uint32_t)j->src[r * j->cols + c] << 16;
      memcpy(&j->row[c], &u, 4);
    }
    if (j->q6) {
      q4b_q6_k(j->row, j->cols, j->blocks);
      for (long long b = 0; b < nb; ++b) {
        memcpy(j->q + (r * nb + b) * 208, j->blocks + b * 210, 208);
        memcpy(j->s + (r * nb + b) * 2, j->blocks + b * 210 + 208, 2);
      }
    } else {
      q4b_q4_0(j->row, j->cols, j->blocks);
      for (long long b = 0; b < nb; ++b)
        q4_words(j->blocks + b * 18, (uint32_t *)j->q + (r * nb + b) * 4, j->s + (r * nb + b) * 2);
    }
  }
  return 0;
}

#define THREADS 6

int main(int argc, char **argv) {
  if (argc != 6) {
    fprintf(stderr, "usage: qwen3_4b_convert <recipe.txt> <out.bin> <shard 1> <shard 2> <shard 3>\n");
    return 1;
  }
  FILE *rc = fopen(argv[1], "r"), *out = fopen(argv[2], "wb"), *in[3];
  for (int i = 0; i < 3; ++i) in[i] = fopen(argv[3 + i], "rb");
  if (!rc || !out || !in[0] || !in[1] || !in[2]) {
    fprintf(stderr, "cannot open the inputs or the output\n");
    return 1;
  }
  char op[16];
  uint8_t *src = 0, *dq = 0, *ds = 0;
  size_t cs = 0, cq = 0, cds = 0;
  float *rows[THREADS] = {0};
  uint8_t *blocks[THREADS] = {0};
  size_t crow[THREADS] = {0}, cblk[THREADS] = {0};
  long long total = 0;
  while (fscanf(rc, "%15s", op) == 1) {
    if (!strcmp(op, "size")) {
      if (fscanf(rc, "%lld", &total) != 1) return 1;
      continue;
    }
    int sh;
    if (!strcmp(op, "f32")) {
      long long s, n, o;
      if (fscanf(rc, "%d %lld %lld %lld", &sh, &s, &n, &o) != 4) return 1;
      src = grow(src, &cs, n * 2);
      dq = grow(dq, &cq, n * 4);
      get(in[sh], s, src, n * 2);
      for (long long i = 0; i < n; ++i) ((uint32_t *)dq)[i] = (uint32_t)((uint16_t *)src)[i] << 16;
      put(out, o, dq, n * 4);
      continue;
    }
    long long s, nrows, cols, o1, o2;
    if (fscanf(rc, "%d %lld %lld %lld %lld %lld", &sh, &s, &nrows, &cols, &o1, &o2) != 6) return 1;
    int q6 = !strcmp(op, "q6");
    if (!q6 && strcmp(op, "q4")) {
      fprintf(stderr, "unknown recipe line %s\n", op);
      return 1;
    }
    long long bs = q6 ? 256 : 32, nb = cols / bs;
    long long qrow = q6 ? nb * 208 : cols / 2;  // output bytes a row
    long long R = 1024;
    for (long long r0 = 0; r0 < nrows; r0 += R) {
      long long n = nrows - r0 < R ? nrows - r0 : R;
      src = grow(src, &cs, n * cols * 2);
      dq = grow(dq, &cq, n * qrow);
      ds = grow(ds, &cds, n * nb * 2);
      get(in[sh], s + r0 * cols * 2, src, n * cols * 2);
      pthread_t th[THREADS];
      job jobs[THREADS];
      for (int t = 0; t < THREADS; ++t) {
        rows[t] = grow(rows[t], &crow[t], cols * 4);
        blocks[t] = grow(blocks[t], &cblk[t], nb * 210);
        jobs[t] = (job){(const uint16_t *)src, rows[t], blocks[t], dq, ds, n * t / THREADS, n * (t + 1) / THREADS,
                        cols, q6};
        pthread_create(&th[t], 0, work, &jobs[t]);
      }
      for (int t = 0; t < THREADS; ++t) pthread_join(th[t], 0);
      put(out, o1 + r0 * qrow, dq, n * qrow);
      put(out, o2 + r0 * nb * 2, ds, n * nb * 2);
    }
  }
  fflush(out);
  if (total && ftruncate(fileno(out), total)) {
    fprintf(stderr, "cannot set the output's size\n");
    return 2;
  }
  fclose(out);
  printf("wrote %s (%lld bytes)\n", argv[2], total);
  return 0;
}
