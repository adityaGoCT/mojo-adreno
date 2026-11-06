// Writes gemma4.bin from a Gemma 4 checkpoint's model.safetensors (bf16), following export.py's recipe.txt:
//   size <bytes>                          the output's size (alignment gaps stay zero)
//   src <file>                            the input for the lines that follow (a file in <checkpoint dir>)
//   f32 <out> <src> <n>                   n bf16 values -> fp32 (exact)
//   q4 <out q> <out s> <src> <rows> <cols> <group>   a bf16 matrix -> int4: an fp16 scale per `group` weights of a row,
//                                         q = rint(w / scale) clamped to -8..7, as 4-bit two's complement, 8 a uint32,
//                                         low nibble first (llama/kernels' gemv_q4 storage). The scale is the fp16 of
//                                         max |w| / d for the d in 6.5 .. 9 (steps of 0.25) with the least squared
//                                         error (qwen3moe/convert.c's choice).
//   q8 <out q> <out s> <src> <rows> <cols> <group>   a bf16 matrix -> int8: an fp16 scale per `group` weights of a row,
//                                         the fp16 of max |w| / 127, q = rint(w / scale) clamped to -127..127, 4 a
//                                         uint32, low byte first (g4k's gemv[True] and p_gemm_q8's storage).
// The q4 and q8 lines run a block of rows at a time, so the phone never holds a whole 262144-row head.
//
//   convert <checkpoint dir> <recipe.txt> <gemma4.bin>
// Builds for macOS (cc) and Android (the NDK's clang), both with -ffp-contract=off, so both write the same bytes.
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static float bf16(uint16_t b) {
  uint32_t u = (uint32_t)b << 16;
  float f;
  memcpy(&f, &u, 4);
  return f;
}

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

// One group of gs weights: its scale and gs / 8 words.
static void quantize(const uint16_t *src, int gs, uint32_t *q, __fp16 *s) {
  float w[256], m = 0;
  for (int j = 0; j < gs; ++j) {
    w[j] = bf16(src[j]);
    m = fmaxf(m, fabsf(w[j]));
  }
  float best = INFINITY, sf = 0;
  for (float d = 6.5f; d <= 9.0f; d += 0.25f) {  // the scale with the least squared error
    float t = (float)(__fp16)(m / d), e = 0;
    if (!(t > 0)) break;
    for (int j = 0; j < gs; ++j) {
      float v = fminf(fmaxf(rintf(w[j] / t), -8.0f), 7.0f);
      float r = w[j] - v * t;
      e += r * r;
    }
    if (e < best) best = e, sf = t;
  }
  *s = (__fp16)sf;
  for (int k = 0; k < gs / 8; ++k) {
    uint32_t word = 0;
    for (int j = 0; j < 8; ++j) {
      float v = sf > 0 ? fminf(fmaxf(rintf(w[k * 8 + j] / sf), -8.0f), 7.0f) : 0.0f;
      word |= (uint32_t)((int)v & 15) << (4 * j);
    }
    q[k] = word;
  }
}

// One group of gs weights in int8: its scale and gs / 4 words.
static void quantize8(const uint16_t *src, int gs, uint32_t *q, __fp16 *s) {
  float w[256], m = 0;
  for (int j = 0; j < gs; ++j) {
    w[j] = bf16(src[j]);
    m = fmaxf(m, fabsf(w[j]));
  }
  __fp16 h = (__fp16)(m / 127.0f);
  float sf = (float)h;
  *s = h;
  for (int k = 0; k < gs / 4; ++k) {
    uint32_t word = 0;
    for (int j = 0; j < 4; ++j) {
      float v = sf > 0 ? fminf(fmaxf(rintf(w[k * 4 + j] / sf), -127.0f), 127.0f) : 0.0f;
      word |= (uint32_t)((int)v & 255) << (8 * j);
    }
    q[k] = word;
  }
}

int main(int argc, char **argv) {
  if (argc != 4) {
    fprintf(stderr, "usage: convert <checkpoint dir> <recipe.txt> <gemma4.bin>\n");
    return 2;
  }
  FILE *r = fopen(argv[2], "r"), *out = fopen(argv[3], "w+b"), *in = NULL;
  if (!r || !out) {
    perror("open");
    return 2;
  }
  char kind[16], name[512];
  long long a, b, c, n, rows, cols, gs, size = 0, values = 0;
  uint16_t *src = NULL;
  void *dst = NULL, *dst2 = NULL;
  size_t cap_src = 0, cap_dst = 0, cap_dst2 = 0;
  while (fscanf(r, "%15s", kind) == 1) {
    if (!strcmp(kind, "size")) {
      if (fscanf(r, "%lld", &size) != 1) return 2;
      char zero = 0;
      put(out, size - 1, &zero, 1);  // the full size, gaps zero
    } else if (!strcmp(kind, "src")) {
      if (fscanf(r, "%511s", name) != 1) return 2;
      if (in) fclose(in);
      char path[1100];
      snprintf(path, sizeof path, "%s/%s", argv[1], name);
      in = fopen(path, "rb");
      if (!in) {
        perror(path);
        return 2;
      }
    } else if (!strcmp(kind, "f32")) {
      if (fscanf(r, "%lld %lld %lld", &a, &b, &n) != 3) return 2;
      src = grow(src, &cap_src, n * 2);
      dst = grow(dst, &cap_dst, n * 4);
      get(in, b, src, n * 2);
      for (long long j = 0; j < n; ++j) ((float *)dst)[j] = bf16(src[j]);
      put(out, a, dst, n * 4);
      values += n;
    } else if (!strcmp(kind, "q4") || !strcmp(kind, "q8")) {
      int bits = kind[1] == '8' ? 8 : 4;
      if (fscanf(r, "%lld %lld %lld %lld %lld %lld", &a, &c, &b, &rows, &cols, &gs) != 6 || cols % gs || gs % 8 ||
          gs > 256)
        return 2;
      long long qb = cols * bits / 8;  // bytes of q a row
      long long block = (64ll << 20) / (cols * 2);  // rows of 64 MB of bf16 at a time
      if (block < 1) block = 1;
      for (long long r0 = 0; r0 < rows; r0 += block) {
        long long m = rows - r0 < block ? rows - r0 : block;
        src = grow(src, &cap_src, m * cols * 2);
        dst = grow(dst, &cap_dst, m * qb);
        dst2 = grow(dst2, &cap_dst2, m * cols / gs * 2);
        get(in, b + r0 * cols * 2, src, m * cols * 2);
        for (long long g = 0; g < m * cols / gs; ++g)
          if (bits == 8)
            quantize8(src + g * gs, (int)gs, (uint32_t *)dst + g * gs / 4, (__fp16 *)dst2 + g);
          else
            quantize(src + g * gs, (int)gs, (uint32_t *)dst + g * gs / 8, (__fp16 *)dst2 + g);
        put(out, a + r0 * qb, dst, m * qb);
        put(out, c + r0 * cols / gs * 2, dst2, m * cols / gs * 2);
      }
      values += rows * cols;
    } else {
      fprintf(stderr, "recipe: unknown line %s\n", kind);
      return 2;
    }
  }
  fclose(out);
  printf("%lld values converted (%.3f GB written)\n", values, size / 1e9);
  return 0;
}
