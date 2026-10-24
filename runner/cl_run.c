// Minimal OpenCL runner for the phone's Adreno (Qualcomm OpenCL 3.0): builds one kernel from
// OpenCL C source or from SPIR-V IL and runs C[i] = A[i] + B[i] (float32), or a warp sum of it
// (RUN_CHECK, see check.h), with signature (global float* a, global float* b, global float* c, long n),
// then checks the result.
//
//   cl_run src <kernel.cl>  <kernel_name> <n> [local_size]
//   cl_run il  <kernel.spv> <kernel_name> <n> [local_size]
//
// No OpenCL headers ship with the NDK: minimal declarations, libOpenCL.so loaded with dlopen.
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "check.h"

typedef int32_t cl_int;
typedef uint32_t cl_uint;
typedef uint64_t cl_ulong;
typedef void *cl_platform_id, *cl_device_id, *cl_context, *cl_command_queue, *cl_mem, *cl_program, *cl_kernel;
#define CL_DEVICE_TYPE_GPU (1 << 2)
#define CL_MEM_READ_WRITE (1 << 0)
#define CL_MEM_COPY_HOST_PTR (1 << 5)
#define CL_PROGRAM_BUILD_LOG 0x1183
#define CL_TRUE 1

#define FN(X)                                                                                         \
  X(cl_int, clGetPlatformIDs, (cl_uint, cl_platform_id*, cl_uint*))                                   \
  X(cl_int, clGetDeviceIDs, (cl_platform_id, cl_ulong, cl_uint, cl_device_id*, cl_uint*))             \
  X(cl_context, clCreateContext, (const intptr_t*, cl_uint, const cl_device_id*, void*, void*, cl_int*)) \
  X(cl_command_queue, clCreateCommandQueueWithProperties, (cl_context, cl_device_id, const cl_ulong*, cl_int*)) \
  X(cl_mem, clCreateBuffer, (cl_context, cl_ulong, size_t, void*, cl_int*))                           \
  X(cl_program, clCreateProgramWithSource, (cl_context, cl_uint, const char**, const size_t*, cl_int*)) \
  X(cl_program, clCreateProgramWithIL, (cl_context, const void*, size_t, cl_int*))                    \
  X(cl_int, clBuildProgram, (cl_program, cl_uint, const cl_device_id*, const char*, void*, void*))   \
  X(cl_int, clGetProgramBuildInfo, (cl_program, cl_device_id, cl_uint, size_t, void*, size_t*))      \
  X(cl_kernel, clCreateKernel, (cl_program, const char*, cl_int*))                                    \
  X(cl_int, clSetKernelArg, (cl_kernel, cl_uint, size_t, const void*))                                \
  X(cl_int, clEnqueueNDRangeKernel, (cl_command_queue, cl_kernel, cl_uint, const size_t*, const size_t*, const size_t*, cl_uint, void*, void*)) \
  X(cl_int, clEnqueueReadBuffer, (cl_command_queue, cl_mem, cl_uint, size_t, size_t, void*, cl_uint, void*, void*)) \
  X(cl_int, clFinish, (cl_command_queue))
#define DECL(r, n, a) typedef r(*PFN_##n) a; static PFN_##n n;
FN(DECL)

#define CK(e) do { cl_int r_ = (e); if (r_) { fprintf(stderr, "%s:%d %s -> %d\n", __FILE__, __LINE__, #e, r_); exit(2); } } while (0)

static char* read_file(const char* path, size_t* n) {
  FILE* f = fopen(path, "rb");
  if (!f) return NULL;
  fseek(f, 0, SEEK_END);
  *n = (size_t)ftell(f);
  fseek(f, 0, SEEK_SET);
  char* p = malloc(*n + 1);
  if (fread(p, 1, *n, f) != *n) { free(p); fclose(f); return NULL; }
  p[*n] = 0;
  fclose(f);
  return p;
}

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: %s src|il file kernel_name n [local]\n", argv[0]); return 2; }
  int il = !strcmp(argv[1], "il");
  const char* name = argv[3];
  int64_t n = atoll(argv[4]);
  size_t local = argc > 5 ? (size_t)atoi(argv[5]) : 64;
  void* h = dlopen("libOpenCL.so", RTLD_NOW);
  if (!h) { fprintf(stderr, "dlopen: %s\n", dlerror()); return 2; }
#define LOAD(r, n, a) n = (PFN_##n)dlsym(h, #n);
  FN(LOAD)
  cl_platform_id plat;
  cl_device_id dev;
  CK(clGetPlatformIDs(1, &plat, NULL));
  CK(clGetDeviceIDs(plat, CL_DEVICE_TYPE_GPU, 1, &dev, NULL));
  cl_int err;
  cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
  CK(err);
  cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, NULL, &err);
  CK(err);

  size_t len = 0;
  char* text = read_file(argv[2], &len);
  if (!text) { fprintf(stderr, "cannot read %s\n", argv[2]); return 2; }
  cl_program prog;
  double t0 = now_ms();
  if (il) {
    prog = clCreateProgramWithIL(ctx, text, len, &err);
    if (err) { printf("clCreateProgramWithIL -> %d (SPIR-V IL not accepted)\nFAIL\n", err); return 1; }
  } else {
    const char* src = text;
    prog = clCreateProgramWithSource(ctx, 1, &src, &len, &err);
    CK(err);
  }
  err = clBuildProgram(prog, 1, &dev, "", NULL, NULL);
  char log[16384] = {0};
  clGetProgramBuildInfo(prog, dev, CL_PROGRAM_BUILD_LOG, sizeof log - 1, log, NULL);
  if (err) { printf("clBuildProgram -> %d\n%s\nFAIL\n", err, log); return 1; }
  printf("built in %.1f ms%s%s\n", now_ms() - t0, log[0] ? ", log: " : "", log);
  cl_kernel k = clCreateKernel(prog, name, &err);
  CK(err);

  float *a = malloc(n * 4), *b = malloc(n * 4), *c = malloc(n * 4);
  check_t ck = get_check(n);
  fill_inputs(a, b, n, ck);
  memset(c, 0xFF, n * 4);
  int64_t kn = kernel_n(n, ck);
  cl_mem A = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, n * 4, a, &err); CK(err);
  cl_mem B = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, n * 4, b, &err); CK(err);
  cl_mem C = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, n * 4, c, &err); CK(err);
  CK(clSetKernelArg(k, 0, sizeof(cl_mem), &A));
  CK(clSetKernelArg(k, 1, sizeof(cl_mem), &B));
  CK(clSetKernelArg(k, 2, sizeof(cl_mem), &C));
  CK(clSetKernelArg(k, 3, sizeof(int64_t), &kn));
  size_t global = (size_t)((n + local - 1) / local * local);
  int nrep = reps();
  double* ms = malloc(nrep * sizeof *ms);
  for (int r = 0; r < nrep; ++r) {
    t0 = now_ms();
    CK(clEnqueueNDRangeKernel(q, k, 1, NULL, &global, &local, 0, NULL, NULL));
    CK(clFinish(q));
    ms[r] = now_ms() - t0;
  }
  qsort(ms, nrep, sizeof *ms, cmp_double);
  CK(clEnqueueReadBuffer(q, C, CL_TRUE, 0, n * 4, c, 0, NULL, NULL));
  int64_t first_bad;
  int64_t bad = count_bad(a, b, c, n, ck, &first_bad);
  printf("n=%lld global=%zu local=%zu check=%s  C[0..3]=%g %g %g %g  C[n-1]=%g  mismatches=%lld (first %lld)  run %.2f ms",
         (long long)n, global, local, getenv("RUN_CHECK") ? getenv("RUN_CHECK") : "add", c[0], c[1], c[2], c[3],
         c[n - 1], (long long)bad, (long long)first_bad, ms[0]);
  printf(nrep > 1 ? " (best of %d, median %.2f ms)\n" : "\n", nrep, ms[nrep / 2]);
  printf(bad ? "FAIL\n" : "PASS\n");
  return bad ? 1 : 0;
}
