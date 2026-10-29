// Builds llama_vk's weights.bin from Llama's model.safetensors on the phone, following a recipe
// written on the Mac from the same file's header (llama/run.py's export, without Python):
//   size <bytes>                      the output size (gaps stay zero: alignment padding)
//   conv <out offset> <src offset> <n> n bf16 values at src -> fp16 at out
//   file <out offset> <name>          a file from <dir> (the RoPE tables, computed by transformers)
//   st2bin <model.safetensors> <recipe> <dir> <weights.bin>
#include <fcntl.h>
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
