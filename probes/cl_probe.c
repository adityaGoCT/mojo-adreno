// OpenCL capability probe for the phone (no CL headers in the NDK: minimal declarations).
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef int32_t cl_int;
typedef uint32_t cl_uint;
typedef void* cl_platform_id;
typedef void* cl_device_id;
#define CL_PLATFORM_VERSION 0x0901
#define CL_PLATFORM_NAME 0x0902
#define CL_DEVICE_TYPE_ALL 0xFFFFFFFF
#define CL_DEVICE_NAME 0x102B
#define CL_DRIVER_VERSION 0x102D
#define CL_DEVICE_VERSION 0x102F
#define CL_DEVICE_EXTENSIONS 0x1030
#define CL_DEVICE_OPENCL_C_VERSION 0x103D
#define CL_DEVICE_IL_VERSION 0x105B

typedef cl_int (*GetPlatformIDs)(cl_uint, cl_platform_id*, cl_uint*);
typedef cl_int (*GetPlatformInfo)(cl_platform_id, cl_uint, size_t, void*, size_t*);
typedef cl_int (*GetDeviceIDs)(cl_platform_id, uint64_t, cl_uint, cl_device_id*, cl_uint*);
typedef cl_int (*GetDeviceInfo)(cl_device_id, cl_uint, size_t, void*, size_t*);

int main(void) {
  void* h = dlopen("libOpenCL.so", RTLD_NOW);
  if (!h) h = dlopen("/vendor/lib64/libOpenCL.so", RTLD_NOW);
  if (!h) { printf("dlopen failed: %s\n", dlerror()); return 1; }
  GetPlatformIDs gp = (GetPlatformIDs)dlsym(h, "clGetPlatformIDs");
  GetPlatformInfo gpi = (GetPlatformInfo)dlsym(h, "clGetPlatformInfo");
  GetDeviceIDs gd = (GetDeviceIDs)dlsym(h, "clGetDeviceIDs");
  GetDeviceInfo gdi = (GetDeviceInfo)dlsym(h, "clGetDeviceInfo");
  printf("clCreateProgramWithIL symbol: %s\n", dlsym(h, "clCreateProgramWithIL") ? "present" : "absent");
  cl_platform_id p[4]; cl_uint np = 0;
  cl_int e = gp(4, p, &np);
  printf("platforms: %u (err %d)\n", np, e);
  char buf[8192];
  for (cl_uint i = 0; i < np; ++i) {
    gpi(p[i], CL_PLATFORM_NAME, sizeof buf, buf, NULL); printf("platform: %s\n", buf);
    gpi(p[i], CL_PLATFORM_VERSION, sizeof buf, buf, NULL); printf("  version: %s\n", buf);
    cl_device_id d[4]; cl_uint nd = 0;
    gd(p[i], CL_DEVICE_TYPE_ALL, 4, d, &nd);
    for (cl_uint j = 0; j < nd; ++j) {
      cl_uint keys[] = {CL_DEVICE_NAME, CL_DEVICE_VERSION, CL_DRIVER_VERSION, CL_DEVICE_OPENCL_C_VERSION, CL_DEVICE_IL_VERSION, CL_DEVICE_EXTENSIONS};
      const char* names[] = {"name", "version", "driver", "opencl_c", "il_version", "extensions"};
      for (int k = 0; k < 6; ++k) {
        size_t n = 0; buf[0] = 0;
        cl_int r = gdi(d[j], keys[k], sizeof buf, buf, &n);
        printf("  %-10s: %s%s\n", names[k], r ? "(error) " : "", r ? "" : buf);
        if (r) printf("             err=%d\n", r);
      }
    }
  }
  return 0;
}
