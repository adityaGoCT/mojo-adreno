// Writes the Qwen3.5-4B weight file (qwen3_5_4b_q4.bin) from unsloth's Q4_0 GGUF, following export.py's recipe.txt.
// Every line reads rows of one GGUF tensor at an absolute offset, so a fused matrix is several lines:
//   size <bytes>                                     the output's size (alignment gaps stay zero)
//   f32 <src> <n> <out>                              copied
//   q4 <src> <rows> <cols> <out q> <out s>           Q4_0 (blocks of 32: fp16 d, 16 bytes; element j = lo nibble of
//                                                    byte j, element j + 16 = hi nibble, value nibble - 8) -> int4
//                                                    words (8 a uint32, element 8w + k in bits 4k, 4-bit two's
//                                                    complement: nibble ^ 8; lfm2/kernels/lk.mojo's storage) and the
//                                                    fp16 scales d, unchanged
//   q6 <src> <rows> <cols> <out q> <out d>           Q6_K -> 208 bytes a super-block (ql, qh, scales) and the d's
//                                                    apart, unchanged (lk's embed_q6 / head_q6)
//   q8f <src> <rows> <cols> <out>                    Q8_0 -> fp32 (q d: an exact product)
//   a41 <src> <rows> <cols> <out q> <out d> <out c>  Q4_1 (fp16 d, fp16 m, 16 bytes; w = q d + m, q the unsigned
//                                                    nibble) -> the affine storage below, without high bits
//   a5k <src> <rows> <cols> <out q> <out h> <out d> <out c>
//                                                    Q5_K (super-blocks of 256: fp16 d, fp16 dmin, 12 bytes of 6-bit
//                                                    scales and mins, qh[32], qs[128]; sub-block j of 32:
//                                                    w = (d sc_j) q - (dmin m_j), q = 4 low bits + 16 x high bit)
//                                                    -> the affine storage with high bits
// The affine storage (q35k.gemv_aff / gemm_aff), a block of 32 weights: the 4 low bits as the int4 words above (low
// nibble ^ 8, i.e. lo - 8), [a uint32 of high bits, bit l = element l's 5th bit], and fp32 d and c with
// w = d (lo - 8 + 16 hi) + c, c = 8 d + m (Q4_1) or 8 d1 - m1 (Q5_K, d1 = d sc and m1 = dmin m as ggml computes
// them). A block of rows at a time, so the phone never holds a whole matrix.
//
//   qwen3_5_4b_convert <model.gguf> <recipe.txt> <out.bin>
// Builds for macOS (cc) and Android (the NDK's clang), both with -ffp-contract=off, so both write the same bytes.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

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

static float half(const uint8_t *p) {
  __fp16 h;
  memcpy(&h, p, 2);
  return (float)h;
}

// 32 unsigned 4-bit values (element e in nib[e]) as 4 int4 words of nibble ^ 8.
static void words(const uint8_t *nib, uint32_t *q) {
  for (int w = 0; w < 4; ++w) {
    uint32_t word = 0;
    for (int k = 0; k < 8; ++k) word |= (uint32_t)(nib[8 * w + k] ^ 8) << (4 * k);
    q[w] = word;
  }
}

static void q4_0_block(const uint8_t *b, uint32_t *q, uint8_t *s) {
  uint8_t nib[32];
  memcpy(s, b, 2);
  for (int j = 0; j < 16; ++j) {
    nib[j] = b[2 + j] & 15;
    nib[j + 16] = b[2 + j] >> 4;
  }
  words(nib, q);
}

static void q4_1_block(const uint8_t *b, uint32_t *q, float *d, float *c) {
  uint8_t nib[32];
  float dd = half(b), m = half(b + 2);
  for (int j = 0; j < 16; ++j) {
    nib[j] = b[4 + j] & 15;
    nib[j + 16] = b[4 + j] >> 4;
  }
  words(nib, q);
  *d = dd;
  *c = 8.0f * dd + m;
}

static void scale_min_k4(int j, const uint8_t *q, uint8_t *d, uint8_t *m) {  // ggml's get_scale_min_k4
  if (j < 4) {
    *d = q[j] & 63;
    *m = q[j + 4] & 63;
  } else {
    *d = (q[j + 4] & 0xF) | ((q[j - 4] >> 6) << 4);
    *m = (q[j + 4] >> 4) | ((q[j - 0] >> 6) << 4);
  }
}

// One Q5_K super-block (256 weights) as 8 affine blocks: 32 words, 8 high-bit words, 8 d's and 8 c's.
static void q5_k_block(const uint8_t *b, uint32_t *q, uint32_t *h, float *d, float *c) {
  float dd = half(b), dmin = half(b + 2);
  const uint8_t *sc = b + 4, *qh = b + 16, *qs = b + 48;
  for (int j = 0; j < 8; ++j) {
    uint8_t s, m, nib[32];
    scale_min_k4(j, sc, &s, &m);
    const uint8_t *lo = qs + 32 * (j / 2);
    uint32_t hi = 0;
    for (int l = 0; l < 32; ++l) {
      nib[l] = j % 2 ? lo[l] >> 4 : lo[l] & 15;
      hi |= (uint32_t)((qh[l] >> j) & 1) << l;
    }
    words(nib, q + 4 * j);
    h[j] = hi;
    float d1 = dd * s, m1 = dmin * m;
    d[j] = d1;
    c[j] = 8.0f * d1 - m1;
  }
}

int main(int argc, char **argv) {
  if (argc != 4) {
    fprintf(stderr, "usage: qwen3_5_4b_convert <model.gguf> <recipe.txt> <out.bin>\n");
    return 1;
  }
  FILE *in = fopen(argv[1], "rb"), *rc = fopen(argv[2], "r"), *out = fopen(argv[3], "wb");
  if (!in || !rc || !out) {
    fprintf(stderr, "cannot open the inputs or the output\n");
    return 1;
  }
  char op[16];
  uint8_t *src = 0, *d1 = 0, *d2 = 0, *d3 = 0, *d4 = 0;
  size_t cs = 0, c1 = 0, c2 = 0, c3 = 0, c4 = 0;
  long long total = 0;
  while (fscanf(rc, "%15s", op) == 1) {
    if (!strcmp(op, "size")) {
      if (fscanf(rc, "%lld", &total) != 1) return 1;
      continue;
    }
    if (!strcmp(op, "f32")) {
      long long s, n, o;
      if (fscanf(rc, "%lld %lld %lld", &s, &n, &o) != 3) return 1;
      src = grow(src, &cs, n * 4);
      get(in, s, src, n * 4);
      put(out, o, src, n * 4);
      continue;
    }
    long long s, rows, cols, o1, o2 = 0, o3 = 0, o4 = 0;
    if (fscanf(rc, "%lld %lld %lld %lld", &s, &rows, &cols, &o1) != 4) return 1;
    long long bs, bb;  // weights and bytes a block
    if (!strcmp(op, "q4")) {
      bs = 32, bb = 18;
      if (fscanf(rc, "%lld", &o2) != 1) return 1;
    } else if (!strcmp(op, "q6")) {
      bs = 256, bb = 210;
      if (fscanf(rc, "%lld", &o2) != 1) return 1;
    } else if (!strcmp(op, "q8f")) {
      bs = 32, bb = 34;
    } else if (!strcmp(op, "a41")) {
      bs = 32, bb = 20;
      if (fscanf(rc, "%lld %lld", &o2, &o3) != 2) return 1;
    } else if (!strcmp(op, "a5k")) {
      bs = 256, bb = 176;
      if (fscanf(rc, "%lld %lld %lld", &o2, &o3, &o4) != 3) return 1;
    } else {
      fprintf(stderr, "unknown recipe line %s\n", op);
      return 1;
    }
    long long nb = cols / bs, rb = nb * bb;  // blocks and bytes a row
    long long g = cols / 32;                 // 32-weight blocks a row
    long long R = 1024;
    for (long long r0 = 0; r0 < rows; r0 += R) {
      long long n = rows - r0 < R ? rows - r0 : R;
      src = grow(src, &cs, n * rb);
      get(in, s + r0 * rb, src, n * rb);
      if (!strcmp(op, "q4")) {
        d1 = grow(d1, &c1, n * cols / 2);
        d2 = grow(d2, &c2, n * g * 2);
        for (long long b = 0; b < n * nb; ++b) q4_0_block(src + b * 18, (uint32_t *)d1 + b * 4, d2 + b * 2);
        put(out, o1 + r0 * cols / 2, d1, n * cols / 2);
        put(out, o2 + r0 * g * 2, d2, n * g * 2);
      } else if (!strcmp(op, "q6")) {
        d1 = grow(d1, &c1, n * nb * 208);
        d2 = grow(d2, &c2, n * nb * 2);
        for (long long b = 0; b < n * nb; ++b) {
          memcpy(d1 + b * 208, src + b * 210, 208);
          memcpy(d2 + b * 2, src + b * 210 + 208, 2);
        }
        put(out, o1 + r0 * nb * 208, d1, n * nb * 208);
        put(out, o2 + r0 * nb * 2, d2, n * nb * 2);
      } else if (!strcmp(op, "q8f")) {
        d1 = grow(d1, &c1, n * cols * 4);
        float *y = (float *)d1;
        for (long long b = 0; b < n * nb; ++b) {
          float d = half(src + b * 34);
          for (int j = 0; j < 32; ++j) y[b * 32 + j] = (float)(int8_t)src[b * 34 + 2 + j] * d;
        }
        put(out, o1 + r0 * cols * 4, d1, n * cols * 4);
      } else {
        int five = !strcmp(op, "a5k");
        d1 = grow(d1, &c1, n * cols / 2);
        d2 = grow(d2, &c2, n * g * 4);
        d3 = grow(d3, &c3, n * g * 4);
        d4 = grow(d4, &c4, n * g * 4);
        for (long long b = 0; b < n * nb; ++b) {
          if (five)
            q5_k_block(src + b * 176, (uint32_t *)d1 + b * 32, (uint32_t *)d2 + b * 8, (float *)d3 + b * 8,
                       (float *)d4 + b * 8);
          else
            q4_1_block(src + b * 20, (uint32_t *)d1 + b * 4, (float *)d3 + b, (float *)d4 + b);
        }
        put(out, o1 + r0 * cols / 2, d1, n * cols / 2);
        if (five) put(out, o2 + r0 * g * 4, d2, n * g * 4);
        put(out, (five ? o3 : o2) + r0 * g * 4, d3, n * g * 4);
        put(out, (five ? o4 : o3) + r0 * g * 4, d4, n * g * 4);
      }
    }
  }
  fflush(out);
  if (total && ftruncate(fileno(out), total)) {  // the size, with any trailing alignment gap
    fprintf(stderr, "cannot set the output's size\n");
    return 2;
  }
  fclose(out);
  fclose(in);
  printf("wrote %s (%lld bytes)\n", argv[3], total);
  return 0;
}
