// Writes qwen3moe.bin from Qwen3-30B-A3B's 16 bf16 safetensors shards, following export.py's recipe.txt:
//   size <bytes>                          the output's size (alignment gaps stay zero)
//   src <shard>                           the input for the lines that follow (a file in <shard dir>)
//   f16 <out> <src> <n>                   n bf16 values -> fp16
//   f32 <out> <src> <n>                   n bf16 values -> fp32 (exact)
//   q4 <out q> <out s> <src> <rows> <cols> <group>   a bf16 matrix -> int4: an fp16 scale per `group` weights of a row,
//                                         q = rint(w / scale) clamped to -8..7, as 4-bit two's complement, 8 a uint32,
//                                         low nibble first (llama/kernels' gemv_q4 storage). The scale is the fp16 of
//                                         max |w| / d for the d in 6.5 .. 9 (steps of 0.25) with the least squared
//                                         error; d = 7 is llama/run.py's quantize4.
//
//   convert <shard dir> <recipe.txt> <qwen3moe.bin>
// Builds for macOS (cc) and Windows on ARM (zig cc -target aarch64-windows-gnu).
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <io.h>
#define seek64 _fseeki64
#else
#include <unistd.h>
#define seek64 fseeko
#endif

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
  if (seek64(f, off, SEEK_SET) || fread(dst, 1, n, f) != n) {
    fprintf(stderr, "read of %zu bytes at %lld failed\n", n, off);
    exit(2);
  }
}

static void put(FILE *f, long long off, const void *src, size_t n) {
  if (seek64(f, off, SEEK_SET) || fwrite(src, 1, n, f) != n) {
    fprintf(stderr, "write of %zu bytes at %lld failed\n", n, off);
    exit(2);
  }
}

int main(int argc, char **argv) {
  if (argc != 4) {
    fprintf(stderr, "usage: convert <shard dir> <recipe.txt> <qwen3moe.bin>\n");
    return 2;
  }
  FILE *r = fopen(argv[2], "r"), *out = fopen(argv[3], "w+b"), *in = NULL;
  if (!r || !out) {
    perror("open");
    return 2;
  }
  char kind[16], name[512];
  long long a, b, c, n, rows, cols, size = 0, values = 0;
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
      fprintf(stderr, "%s\n", name);
    } else if (!strcmp(kind, "f16") || !strcmp(kind, "f32")) {
      if (fscanf(r, "%lld %lld %lld", &a, &b, &n) != 3) return 2;
      int wide = kind[1] == '3';
      const long long CH = 1 << 22;
      src = grow(src, &cap_src, CH * 2);
      dst = grow(dst, &cap_dst, CH * 4);
      for (long long i = 0; i < n; i += CH) {
        long long m = n - i < CH ? n - i : CH;
        get(in, b + i * 2, src, m * 2);
        for (long long j = 0; j < m; ++j) {
          float f = bf16(src[j]);
          if (wide)
            ((float *)dst)[j] = f;
          else
            ((__fp16 *)dst)[j] = (__fp16)f;
        }
        put(out, a + i * (wide ? 4 : 2), dst, m * (wide ? 4 : 2));
      }
      values += n;
    } else if (!strcmp(kind, "q4")) {
      long long gs;
      if (fscanf(r, "%lld %lld %lld %lld %lld %lld", &a, &c, &b, &rows, &cols, &gs) != 6 || cols % gs || gs % 8 ||
          gs > 256)
        return 2;
      src = grow(src, &cap_src, rows * cols * 2);
      dst = grow(dst, &cap_dst, rows * cols / 2);
      dst2 = grow(dst2, &cap_dst2, rows * cols / gs * 2);
      get(in, b, src, rows * cols * 2);
      uint32_t *q = dst;
      __fp16 *s = dst2;
      for (long long g = 0; g < rows * cols / gs; ++g) {
        float w[256], m = 0;
        for (int j = 0; j < gs; ++j) {
          w[j] = bf16(src[g * gs + j]);
          m = fmaxf(m, fabsf(w[j]));
        }
        float best = INFINITY, sf = 0;
        for (float d = 6.5f; d <= 9.0f; d += 0.25f) {  // the scale with the least squared error
          float t = (float)(__fp16)(m / d), e = 0;
          if (!(t > 0)) break;
          for (int j = 0; j < gs; ++j) {
            float v = fminf(fmaxf(rintf(w[j] / t), -8.0f), 7.0f);
            e += (w[j] - v * t) * (w[j] - v * t);
          }
          if (e < best) best = e, sf = t;
        }
        s[g] = (__fp16)sf;
        for (int k = 0; k < gs / 8; ++k) {
          uint32_t word = 0;
          for (int j = 0; j < 8; ++j) {
            float v = sf > 0 ? fminf(fmaxf(rintf(w[k * 8 + j] / sf), -8.0f), 7.0f) : 0.0f;
            word |= (uint32_t)((int)v & 15) << (4 * j);
          }
          q[g * gs / 8 + k] = word;
        }
      }
      put(out, a, q, rows * cols / 2);
      put(out, c, s, rows * cols / gs * 2);
      values += rows * cols;
    } else {
      fprintf(stderr, "recipe: unknown line %s\n", kind);
      return 2;
    }
  }
  fclose(out);
  printf("%lld values converted (%.2f GB written)\n", values, size / 1e9);
  return 0;
}
