// Writes gemma.bin, the fp16 copy of π0's Gemma 2B layers that npu/export_pi0.py's graphs read, from the checkpoint's
// fp32 model.safetensors, on the phone (or the Mac), following export_pi0.py's recipe.txt:
//   size <bytes>                      the output size (gaps stay zero: alignment padding)
//   conv <out offset> <src offset> <n>  n fp32 values at src -> fp16 at out (round to nearest even)
//
//   pi0_f16 <model.safetensors> <recipe.txt> <gemma.bin>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char** argv) {
  if (argc != 4) {
    fprintf(stderr, "usage: pi0_f16 model.safetensors recipe.txt gemma.bin\n");
    return 2;
  }
  int in = open(argv[1], O_RDONLY), out = open(argv[3], O_RDWR | O_CREAT | O_TRUNC, 0644);
  FILE* r = fopen(argv[2], "r");
  if (in < 0 || out < 0 || !r) {
    perror("open");
    return 2;
  }
  enum { CH = 1 << 22 };
  float* src = malloc(CH * 4);
  __fp16* dst = malloc(CH * 2);
  char kind[16];
  long long a, b, n, done = 0, inf = 0;
  while (fscanf(r, "%15s", kind) == 1) {
    if (!strcmp(kind, "size")) {
      if (fscanf(r, "%lld", &a) != 1 || ftruncate(out, a)) {
        perror("size");
        return 2;
      }
    } else if (!strcmp(kind, "conv")) {
      if (fscanf(r, "%lld %lld %lld", &a, &b, &n) != 3) return 2;
      for (long long i = 0; i < n; i += CH) {
        long long m = n - i < CH ? n - i : CH;
        if (pread(in, src, m * 4, b + i * 4) != m * 4) {
          perror("read");
          return 2;
        }
        for (long long j = 0; j < m; ++j) {
          dst[j] = (__fp16)src[j];
          float h = dst[j];
          inf += !(h >= -65504.0f && h <= 65504.0f);  // inf or nan
        }
        if (pwrite(out, dst, m * 2, a + i * 2) != m * 2) {
          perror("write");
          return 2;
        }
      }
      done += n;
    } else {
      fprintf(stderr, "recipe: unknown line %s\n", kind);
      return 2;
    }
  }
  close(out);
  printf("%lld values converted to fp16 (%.2f GB), %lld out of fp16's range\n", done, done * 2 / 1e9, inf);
  return inf ? 1 : 0;
}
