// Inputs and result check shared by vk_run.c and cl_run.c, selected by RUN_CHECK:
//   unset or "add"           A[i] = i, B[i] = 2i; C[i] = A[i] + B[i] = 3i, exactly
//   "warpsum:W", "blocksum:W" same inputs; C[i] = sum of A[j] + B[j] over i's aligned group of W
//                            lanes (j < n), within a relative 1e-5 (float sums in any order)
//   "matmul:N"               n = N * N; A[i] = i % 7 - 3, B[i] = i % 5 - 2; the kernel's n argument
//                            is N and C = A @ B (row-major), exactly (small integers stay exact)
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { int kind, w; int64_t dim; } check_t;  // kind: 0 add, 1 group sum, 2 matmul

static check_t get_check(int64_t n) {
  check_t ck = {0, 0, 0};
  const char* s = getenv("RUN_CHECK");
  if (s && (!strncmp(s, "warpsum:", 8) || !strncmp(s, "blocksum:", 9))) ck = (check_t){1, atoi(strchr(s, ':') + 1), 0};
  if (s && !strncmp(s, "matmul:", 7)) {
    ck = (check_t){2, 0, atoll(s + 7)};
    if (ck.dim * ck.dim != n) { fprintf(stderr, "RUN_CHECK=%s needs n = %lld\n", s, (long long)(ck.dim * ck.dim)); exit(2); }
  }
  return ck;
}

static void fill_inputs(float* a, float* b, int64_t n, check_t ck) {
  for (int64_t i = 0; i < n; ++i) {
    a[i] = ck.kind == 2 ? (float)(i % 7 - 3) : (float)i;
    b[i] = ck.kind == 2 ? (float)(i % 5 - 2) : (float)(2 * i);
  }
}

static int64_t kernel_n(int64_t n, check_t ck) { return ck.kind == 2 ? ck.dim : n; }

static int64_t count_bad(const float* a, const float* b, const float* c, int64_t n, check_t ck, int64_t* first) {
  int64_t bad = 0;
  *first = -1;
  if (ck.kind == 2) {  // reference row by row, in double
    int64_t d = ck.dim;
    double* row = malloc(d * sizeof *row);
    for (int64_t i = 0; i < d; ++i) {
      memset(row, 0, d * sizeof *row);
      for (int64_t k = 0; k < d; ++k)
        for (int64_t j = 0; j < d; ++j) row[j] += (double)a[i * d + k] * b[k * d + j];
      for (int64_t j = 0; j < d; ++j)
        if (!(c[i * d + j] == (float)row[j])) { if (*first < 0) *first = i * d + j; ++bad; }
    }
    free(row);
    return bad;
  }
  for (int64_t i = 0; i < n; ++i) {
    double e = 3.0 * (double)i;
    if (ck.kind == 1) {
      int64_t lo = i - i % ck.w, hi = lo + ck.w < n ? lo + ck.w : n;  // [lo, hi)
      e = 3.0 * (double)(hi - lo) * (double)(lo + hi - 1) / 2.0;
    }
    int ok = ck.kind ? fabs(c[i] - e) <= 1e-5 * fabs(e) : c[i] == (float)e;  // NaN fails both
    if (!ok) { if (*first < 0) *first = i; ++bad; }
  }
  return bad;
}

static int reps(void) {
  const char* s = getenv("RUN_REPS");  // timed dispatches (the result is checked after the last)
  return s && atoi(s) > 0 ? atoi(s) : 1;
}

static int cmp_double(const void* x, const void* y) {
  double a = *(const double*)x, b = *(const double*)y;
  return (a > b) - (a < b);
}
