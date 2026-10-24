// Result check shared by vk_run.c and cl_run.c. Inputs are A[i] = i, B[i] = 2i.
//   RUN_CHECK unset or "add":  C[i] = A[i] + B[i] = 3i, exactly
//   RUN_CHECK="warpsum:W":     C[i] = sum of A[j] + B[j] over i's aligned group of W lanes (j < n),
//                              within a relative 1e-5 (float sums in any order)
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static int check_width(void) {
  const char* s = getenv("RUN_CHECK");
  return s && !strncmp(s, "warpsum:", 8) ? atoi(s + 8) : 0;
}

static double expected(int64_t i, int64_t n, int w) {
  if (!w) return 3.0 * (double)i;
  int64_t lo = i - i % w, hi = lo + w < n ? lo + w : n;  // [lo, hi)
  return 3.0 * (double)(hi - lo) * (double)(lo + hi - 1) / 2.0;
}

static int64_t count_bad(const float* c, int64_t n, int w, int64_t* first) {
  int64_t bad = 0;
  *first = -1;
  for (int64_t i = 0; i < n; ++i) {
    double e = expected(i, n, w);
    int ok = w ? fabs(c[i] - e) <= 1e-5 * fabs(e) : c[i] == (float)e;  // NaN fails both
    if (!ok) { if (*first < 0) *first = i; ++bad; }
  }
  return bad;
}
