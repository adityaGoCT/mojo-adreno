// Writes an LFM2 weight file (lfm2_q4.bin or lfm2_f16.bin) from the QAD Q4_0 GGUF, following export.py's recipe.txt.
// Every line reads one GGUF tensor at its absolute offset:
//   size <bytes>                                the output's size (alignment gaps stay zero)
//   q4 <src> <rows> <cols> <out q> <out s>      Q4_0 (blocks of 32: fp16 d, 16 bytes; element j = lo nibble of byte j,
//                                               element j + 16 = hi nibble, value nibble - 8) -> the same numbers as
//                                               int4 words (8 a uint32, element 8w + k in bits 4k, 4-bit two's
//                                               complement: nibble ^ 8) and the fp16 scales d, unchanged
//   q6 <src> <rows> <cols> <out q> <out d>      Q6_K (super-blocks of 256: ql[128], qh[64], int8 scales[16], fp16 d)
//                                               -> 208 bytes a super-block (ql, qh, scales) and the d's apart, unchanged
//   h4 / h6 <src> <rows> <cols> <out>           Q4_0 / Q6_K -> fp16, dequantized as ggml does (fp32), then rounded
//   f32 <src> <n> <out>                         copied
//   c8 <src> <rows> <cols> <out q> <out c> <bs> Q4_0 (bs 32) or Q6_K (bs 256), dequantized as ggml does (fp32), ->
//                                               int8 per output channel for the NPU's w8a16 graphs: c = max |w| / 127
//                                               (fp32; 1 for a row of zeros), q = rint(w / c), int8 [rows, cols], c fp32
// A block of rows at a time, so the phone never holds a whole matrix.
//
//   convert <model.gguf> <recipe.txt> <out.bin>
// Builds for macOS (cc) and Android (the NDK's clang), both with -ffp-contract=off, so both write the same bytes.
#include <math.h>
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

// One Q4_0 block (32 weights): 4 int4 words and its scale.
static void q4_block(const uint8_t *b, uint32_t *q, uint8_t *s) {
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

static void q4_dequant(const uint8_t *b, float *y) {
  float d = half(b);
  const uint8_t *qs = b + 2;
  for (int j = 0; j < 16; ++j) {
    y[j] = (float)((qs[j] & 15) - 8) * d;
    y[j + 16] = (float)((qs[j] >> 4) - 8) * d;
  }
}

static void q6_dequant(const uint8_t *b, float *y) {
  const uint8_t *ql = b, *qh = b + 128;
  const int8_t *sc = (const int8_t *)(b + 192);
  float d = half(b + 208);
  for (int n = 0; n < 256; n += 128) {
    for (int l = 0; l < 32; ++l) {
      int is = l / 16;
      int q1 = (int)((ql[l] & 15) | (((qh[l] >> 0) & 3) << 4)) - 32;
      int q2 = (int)((ql[l + 32] & 15) | (((qh[l] >> 2) & 3) << 4)) - 32;
      int q3 = (int)((ql[l] >> 4) | (((qh[l] >> 4) & 3) << 4)) - 32;
      int q4 = (int)((ql[l + 32] >> 4) | (((qh[l] >> 6) & 3) << 4)) - 32;
      y[l] = d * sc[is] * q1;
      y[l + 32] = d * sc[is + 2] * q2;
      y[l + 64] = d * sc[is + 4] * q3;
      y[l + 96] = d * sc[is + 6] * q4;
    }
    y += 128;
    ql += 64;
    qh += 32;
    sc += 8;
  }
}

int main(int argc, char **argv) {
  if (argc != 4) {
    fprintf(stderr, "usage: convert <model.gguf> <recipe.txt> <out.bin>\n");
    return 1;
  }
  FILE *in = fopen(argv[1], "rb"), *rc = fopen(argv[2], "r"), *out = fopen(argv[3], "wb");
  if (!in || !rc || !out) {
    fprintf(stderr, "cannot open the inputs or the output\n");
    return 1;
  }
  char op[16];
  uint8_t *src = 0, *dst = 0, *dst2 = 0;
  size_t cs = 0, cd = 0, cd2 = 0;
  float *row = 0;
  size_t cr = 0;
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
    long long s, rows, cols, o1, o2 = 0;
    if (fscanf(rc, "%lld %lld %lld %lld", &s, &rows, &cols, &o1) != 4) return 1;
    int q6 = !strcmp(op, "q6") || !strcmp(op, "h6");
    if (!strcmp(op, "q4") || !strcmp(op, "q6") || !strcmp(op, "c8"))
      if (fscanf(rc, "%lld", &o2) != 1) return 1;
    if (!strcmp(op, "c8")) {
      long long bsz;
      if (fscanf(rc, "%lld", &bsz) != 1) return 1;
      q6 = bsz == 256;
    }
    long long bs = q6 ? 256 : 32, bb = q6 ? 210 : 18;  // weights and bytes a block
    long long nb = cols / bs, rb = nb * bb;             // blocks and bytes a row
    long long R = 1024;
    for (long long r0 = 0; r0 < rows; r0 += R) {
      long long n = rows - r0 < R ? rows - r0 : R;
      src = grow(src, &cs, n * rb);
      get(in, s + r0 * rb, src, n * rb);
      if (!strcmp(op, "q4")) {
        dst = grow(dst, &cd, n * cols / 2);
        dst2 = grow(dst2, &cd2, n * nb * 2);
        for (long long b = 0; b < n * nb; ++b) q4_block(src + b * 18, (uint32_t *)dst + b * 4, dst2 + b * 2);
        put(out, o1 + r0 * cols / 2, dst, n * cols / 2);
        put(out, o2 + r0 * nb * 2, dst2, n * nb * 2);
      } else if (!strcmp(op, "q6")) {
        dst = grow(dst, &cd, n * nb * 208);
        dst2 = grow(dst2, &cd2, n * nb * 2);
        for (long long b = 0; b < n * nb; ++b) {
          memcpy(dst + b * 208, src + b * 210, 208);
          memcpy(dst2 + b * 2, src + b * 210 + 208, 2);
        }
        put(out, o1 + r0 * nb * 208, dst, n * nb * 208);
        put(out, o2 + r0 * nb * 2, dst2, n * nb * 2);
      } else if (!strcmp(op, "h4") || !strcmp(op, "h6")) {
        row = grow(row, &cr, cols * 4);
        dst = grow(dst, &cd, n * cols * 2);
        __fp16 *h = (__fp16 *)dst;
        for (long long r = 0; r < n; ++r) {
          for (long long b = 0; b < nb; ++b) {
            if (q6)
              q6_dequant(src + r * rb + b * bb, row + b * bs);
            else
              q4_dequant(src + r * rb + b * bb, row + b * bs);
          }
          for (long long c = 0; c < cols; ++c) h[r * cols + c] = (__fp16)row[c];
        }
        put(out, o1 + r0 * cols * 2, dst, n * cols * 2);
      } else if (!strcmp(op, "c8")) {
        row = grow(row, &cr, cols * 4);
        dst = grow(dst, &cd, n * cols);
        dst2 = grow(dst2, &cd2, n * 4);
        for (long long r = 0; r < n; ++r) {
          for (long long b = 0; b < nb; ++b) {
            if (q6)
              q6_dequant(src + r * rb + b * bb, row + b * bs);
            else
              q4_dequant(src + r * rb + b * bb, row + b * bs);
          }
          float m = 0;
          for (long long c = 0; c < cols; ++c) m = fabsf(row[c]) > m ? fabsf(row[c]) : m;
          float sc = m > 0 ? m / 127.0f : 1.0f;
          for (long long c = 0; c < cols; ++c) {
            float q = rintf(row[c] / sc);
            q = q > 127 ? 127 : (q < -127 ? -127 : q);
            ((int8_t *)dst)[r * cols + c] = (int8_t)q;
          }
          memcpy(dst2 + r * 4, &sc, 4);
        }
        put(out, o1 + r0 * cols, dst, n * cols);
        put(out, o2 + r0 * 4, dst2, n * 4);
      } else {
        fprintf(stderr, "unknown recipe line %s\n", op);
        return 1;
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
