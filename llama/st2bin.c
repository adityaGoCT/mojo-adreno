// Builds llama_vk's weights.bin from Llama's model.safetensors on the phone, following a recipe
// written on the Mac from the same file's header (llama/run.py's export, without Python):
//   size <bytes>                      the output size (gaps stay zero: alignment padding)
//   conv <out offset> <src offset> <n> n bf16 values at src -> fp16 at out
//   file <out offset> <name>          a file from <dir> (the RoPE tables, computed by transformers)
//   q4 <out q> <out s> <src> <rows> <cols>   a bf16 matrix as int4 (run.py's quantize4: fp16 values,
//                                     an fp16 scale per 64 of a row, 8 weights a word, low nibble first)
//   st2bin <model.safetensors> <recipe> <dir> <weights.bin>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int main(int argc, char** argv) {
  if (argc != 5) { fprintf(stderr, "usage: st2bin model.safetensors recipe dir weights.bin\n"); return 2; }
  int in = open(argv[1], O_RDONLY), out = open(argv[4], O_RDWR | O_CREAT | O_TRUNC, 0644);
  FILE* r = fopen(argv[2], "r");
  if (in < 0 || out < 0 || !r) { perror("open"); return 2; }
  enum { CH = 1 << 22 };
  uint16_t* src = malloc(CH * 2);
  __fp16* dst = malloc(CH * 2);
  char kind[16], name[256];
  long long a, b, n;
  long long done = 0;
  while (fscanf(r, "%15s", kind) == 1) {
    if (!strcmp(kind, "size")) {
      if (fscanf(r, "%lld", &a) != 1 || ftruncate(out, a)) { perror("size"); return 2; }
    } else if (!strcmp(kind, "conv")) {
      if (fscanf(r, "%lld %lld %lld", &a, &b, &n) != 3) return 2;
      for (long long i = 0; i < n; i += CH) {
        long long m = n - i < CH ? n - i : CH;
        if (pread(in, src, m * 2, b + i * 2) != m * 2) { perror("read"); return 2; }
        for (long long j = 0; j < m; ++j) {
          uint32_t bits = (uint32_t)src[j] << 16;
          float f;
          memcpy(&f, &bits, 4);
          dst[j] = (__fp16)f;
        }
        if (pwrite(out, dst, m * 2, a + i * 2) != m * 2) { perror("write"); return 2; }
      }
      done += n * 2;
    } else if (!strcmp(kind, "q4")) {
      long long os, rows, cols;
      if (fscanf(r, "%lld %lld %lld %lld %lld", &a, &os, &b, &rows, &cols) != 5 || cols % 64 || cols > CH) return 2;
      uint32_t* words = malloc(cols / 2);
      __fp16* scales = malloc(cols / 64 * 2);
      for (long long row = 0; row < rows; ++row) {
        if (pread(in, src, cols * 2, b + row * cols * 2) != cols * 2) { perror("read"); return 2; }
        memset(words, 0, cols / 2);
        for (long long g = 0; g < cols / 64; ++g) {
          float w[64], maxabs = 0;
          for (int j = 0; j < 64; ++j) {
            uint32_t bits = (uint32_t)src[g * 64 + j] << 16;
            float f;
            memcpy(&f, &bits, 4);
            w[j] = (float)(__fp16)f;
            maxabs = fmaxf(maxabs, fabsf(w[j]));
          }
          __fp16 s16 = (__fp16)(maxabs / 7.0f);
          float sf = (float)s16;
          scales[g] = s16;
          for (int j = 0; j < 64; ++j) {
            float q = sf > 0 ? rintf(w[j] / sf) : 0.0f;
            int qi = q < -8 ? -8 : q > 7 ? 7 : (int)q;
            long long k = g * 64 + j;
            words[k / 8] |= (uint32_t)(qi & 15) << (4 * (k % 8));
          }
        }
        if (pwrite(out, words, cols / 2, a + row * cols / 2) != cols / 2 ||
            pwrite(out, scales, cols / 64 * 2, os + row * (cols / 64) * 2) != cols / 64 * 2) { perror("write"); return 2; }
      }
      free(words);
      free(scales);
      done += rows * (cols / 2 + cols / 64 * 2);
    } else if (!strcmp(kind, "file")) {
      if (fscanf(r, "%lld %255s", &a, name) != 2) return 2;
      char path[512];
      snprintf(path, sizeof path, "%s/%s", argv[3], name);
      FILE* f = fopen(path, "rb");
      if (!f) { perror(path); return 2; }
      static char buf[1 << 20];
      size_t k = fread(buf, 1, sizeof buf, f);
      fclose(f);
      if (pwrite(out, buf, k, a) != (ssize_t)k) { perror("write"); return 2; }
      done += k;
    }
  }
  close(out);
  printf("st2bin: %.2f GB written\n", done / 1e9);
  return 0;
}
