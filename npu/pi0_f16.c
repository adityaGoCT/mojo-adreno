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
#ifdef _WIN32  // Windows on ARM (npu/build_win.sh): positioned reads and writes through the CRT
#include <io.h>
#undef O_RDONLY
#undef O_RDWR
#define O_RDONLY (_O_RDONLY | _O_BINARY)
#define O_RDWR (_O_RDWR | _O_BINARY)
static long long pio(int fd, void* p, long long n, long long off, int w) {
  if (_lseeki64(fd, off, SEEK_SET) != off) return -1;
  long long done = 0;
  while (done < n) {
    unsigned k = n - done > (1u << 30) ? (1u << 30) : (unsigned)(n - done);
    int r = w ? _write(fd, (char*)p + done, k) : _read(fd, (char*)p + done, k);
    if (r <= 0) return -1;
    done += r;
  }
  return done;
}
#define pread(fd, p, n, off) pio(fd, p, n, off, 0)
#define pwrite(fd, p, n, off) pio(fd, (void*)(p), n, off, 1)
#define ftruncate(fd, n) _chsize_s(fd, n)
#define close _close
#else
#include <unistd.h>
#endif

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
