// Calls the Mojo-compiled mojo_vecadd (C ABI) on the phone's CPU and checks the result.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
void mojo_vecadd(const float* a, const float* b, float* c, int64_t n);
int main(int argc, char** argv) {
  int64_t n = argc > 1 ? atoll(argv[1]) : 4096, bad = 0;
  float *a = malloc(n * 4), *b = malloc(n * 4), *c = malloc(n * 4);
  for (int64_t i = 0; i < n; ++i) { a[i] = (float)i; b[i] = (float)(2 * i); c[i] = -1; }
  mojo_vecadd(a, b, c, n);
  for (int64_t i = 0; i < n; ++i) bad += c[i] != (float)(3 * i);
  printf("Mojo vecadd on the phone CPU: n=%lld C[0..3]=%g %g %g %g C[n-1]=%g mismatches=%lld\n%s\n",
         (long long)n, c[0], c[1], c[2], c[3], c[n - 1], (long long)bad, bad ? "FAIL" : "PASS");
  return bad != 0;
}
