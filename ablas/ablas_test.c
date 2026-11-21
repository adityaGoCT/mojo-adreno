// ablas_test: correctness + speed of ablas_hgemm on the phone.
//   ablas_test [opA opB M N K]...      (op: N, T, or P; default: a built-in list)
// P: the data is K-major (A as [K,M], B as [K,N]) and is packed once with ablas_pack_a/_b before the timed
// calls, which then pass ABLAS_OP_P (the weights-packed-ahead-of-time case).
// Checks 1024 random elements of C against an fp32 CPU reference (relative to max |C|), then times the
// call with GPU timestamps (warm-up, then the best of 5 runs of back-to-back calls).
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "ablas.h"

#define CK(x) do { VkResult r_ = (x); if (r_) { fprintf(stderr, "%s:%d %s -> %d\n", __FILE__, __LINE__, #x, r_); exit(1); } } while (0)

static PFN_vkGetInstanceProcAddr gipa;
static VkInstance inst;
static VkDevice dev;
#define FN(f) static PFN_##f f;
#define VK_FUNCS(X)                                                                                        \
  X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties)                       \
  X(vkGetPhysicalDeviceMemoryProperties) X(vkGetPhysicalDeviceQueueFamilyProperties) X(vkCreateDevice)     \
  X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkGetBufferMemoryRequirements) X(vkAllocateMemory)               \
  X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateCommandPool) X(vkAllocateCommandBuffers)                  \
  X(vkBeginCommandBuffer) X(vkEndCommandBuffer) X(vkResetCommandBuffer) X(vkQueueSubmit) X(vkQueueWaitIdle) \
  X(vkCreateQueryPool) X(vkCmdResetQueryPool) X(vkCmdWriteTimestamp) X(vkGetQueryPoolResults)              \
  X(vkCmdPipelineBarrier)
VK_FUNCS(FN)

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec * 1e-6;
}

typedef struct { VkBuffer buf; void* map; size_t size; } buffer_t;
static VkPhysicalDeviceMemoryProperties memprops;

static buffer_t make_buffer(size_t size) {
  buffer_t b = {0};
  b.size = size;
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
  CK(vkCreateBuffer(dev, &bi, NULL, &b.buf));
  VkMemoryRequirements mr;
  vkGetBufferMemoryRequirements(dev, b.buf, &mr);
  uint32_t want = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, type = 0;
  for (uint32_t i = 0; i < memprops.memoryTypeCount; ++i)
    if ((mr.memoryTypeBits >> i & 1) && (memprops.memoryTypes[i].propertyFlags & want) == want) { type = i; break; }
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, NULL, mr.size, type};
  VkDeviceMemory mem;
  CK(vkAllocateMemory(dev, &ai, NULL, &mem));
  CK(vkBindBufferMemory(dev, b.buf, mem, 0));
  CK(vkMapMemory(dev, mem, 0, VK_WHOLE_SIZE, 0, &b.map));
  return b;
}

static uint32_t rng = 12345;
static float frand(void) {
  rng = rng * 1664525u + 1013904223u;
  return (float)(rng >> 8) / (float)(1u << 24) * 2.0f - 1.0f;
}

int main(int argc, char** argv) {
  void* lib = dlopen("libvulkan.so", RTLD_NOW);
  gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "ablas_test", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL, 0, &app};
  CK(vkCreateInstance(&ici, NULL, &inst));
#define LOAD(f) f = (PFN_##f)gipa(inst, #f);
  VK_FUNCS(LOAD)
  uint32_t n = 1;
  VkPhysicalDevice pd;
  vkEnumeratePhysicalDevices(inst, &n, &pd);
  VkPhysicalDeviceProperties props;
  vkGetPhysicalDeviceProperties(pd, &props);
  vkGetPhysicalDeviceMemoryProperties(pd, &memprops);
  float prio = 1;
  VkDeviceQueueCreateInfo q = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, 0, 1, &prio};
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  cm.cooperativeMatrix = VK_TRUE;
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &cm};
  v12.shaderFloat16 = v12.vulkanMemoryModel = v12.vulkanMemoryModelDeviceScope = VK_TRUE;
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  v11.storageBuffer16BitAccess = VK_TRUE;
  const char* exts[] = {"VK_KHR_push_descriptor", "VK_KHR_cooperative_matrix"};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &v11, 0, 1, &q, 0, NULL, 2, exts};
  CK(vkCreateDevice(pd, &dci, NULL, &dev));
  VkQueue queue;
  vkGetDeviceQueue(dev, 0, 0, &queue);
  printf("device: %s\n", props.deviceName);

  ablas_handle h;
  ablas_status st = ablas_create(&h, pd, dev, gipa, inst);
  if (st) { printf("ablas_create: %d\n", st); return 1; }
  if (getenv("ABLAS_PACK")) ablas_set_pack(h, atoi(getenv("ABLAS_PACK")));

  // Shapes: argv, or a default list covering every layout plus untuned shapes.
  static const char* defaults[] = {"T", "N", "2048", "2048", "2048", "N", "N", "2048", "2048", "2048",
                                   "T", "T", "2048", "2048", "2048", "N", "T", "2048", "2048", "2048",
                                   "T", "N", "1024", "1024", "1024", "T", "N", "512", "2048", "2048",
                                   "T", "N", "768", "1536", "1024", "N", "T", "512", "8192", "2048",
                                   "T", "N", "4096", "4096", "4096"};
  int nargs = argc > 1 ? argc - 1 : (int)(sizeof defaults / sizeof *defaults);
  const char** args = argc > 1 ? (const char**)argv + 1 : defaults;
  size_t maxA = 0, maxB = 0, maxC = 0;
  for (int i = 0; i + 4 < nargs; i += 5) {
    size_t M = atoi(args[i + 2]), N = atoi(args[i + 3]), K = atoi(args[i + 4]);
    if (M * K > maxA) maxA = M * K;
    if (K * N > maxB) maxB = K * N;
    if (M * N > maxC) maxC = M * N;
  }
  buffer_t A = make_buffer(maxA * 2), B = make_buffer(maxB * 2), C = make_buffer(maxC * 2), W = make_buffer((maxA + maxB) * 2);
  buffer_t PA = make_buffer(maxA * 2), PB = make_buffer(maxB * 2);  // pre-packed panels for 'P' 
  _Float16* a = A.map;
  _Float16* b = B.map;
  for (size_t i = 0; i < maxA; ++i) a[i] = (_Float16)frand();
  for (size_t i = 0; i < maxB; ++i) b[i] = (_Float16)frand();

  VkCommandPoolCreateInfo cpi = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL,
                                 VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, 0};
  VkCommandPool pool;
  CK(vkCreateCommandPool(dev, &cpi, NULL, &pool));
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, pool,
                                     VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  VkCommandBuffer cmd;
  CK(vkAllocateCommandBuffers(dev, &cai, &cmd));
  VkQueryPoolCreateInfo qpi = {VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO, NULL, 0, VK_QUERY_TYPE_TIMESTAMP, 2};
  VkQueryPool qp;
  CK(vkCreateQueryPool(dev, &qpi, NULL, &qp));
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT};

  for (int s = 0; s + 4 < nargs; s += 5) {
    ablas_op opA = args[s][0] == 'T' ? ABLAS_OP_T : args[s][0] == 'P' ? ABLAS_OP_P : ABLAS_OP_N;
    ablas_op opB = args[s + 1][0] == 'T' ? ABLAS_OP_T : args[s + 1][0] == 'P' ? ABLAS_OP_P : ABLAS_OP_N;
    uint32_t M = atoi(args[s + 2]), N = atoi(args[s + 3]), K = atoi(args[s + 4]);
    ablas_buf bA = {A.buf, 0}, bB = {B.buf, 0}, bC = {C.buf, 0}, bW = {W.buf, 0};
    // reference layouts: P data is K-major (A [K,M] like T, B [K,N] like N)
    ablas_op refA = opA == ABLAS_OP_P ? ABLAS_OP_T : opA, refB = opB == ABLAS_OP_P ? ABLAS_OP_N : opB;
    if (opA == ABLAS_OP_P || opB == ABLAS_OP_P) {  // pack once, outside the timed region
      CK(vkResetCommandBuffer(cmd, 0));
      VkCommandBufferBeginInfo pbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
      CK(vkBeginCommandBuffer(cmd, &pbi));
      if (opA == ABLAS_OP_P) st = ablas_pack_a(h, cmd, ABLAS_OP_T, M, K, bA, (ablas_buf){PA.buf, 0});
      if (opB == ABLAS_OP_P && !st) st = ablas_pack_b(h, cmd, ABLAS_OP_N, K, N, bB, (ablas_buf){PB.buf, 0});
      vkCmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &mb, 0, NULL, 0, NULL);
      CK(vkEndCommandBuffer(cmd));
      VkSubmitInfo psi = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
      psi.commandBufferCount = 1;
      psi.pCommandBuffers = &cmd;
      CK(vkQueueSubmit(queue, 1, &psi, VK_NULL_HANDLE));
      CK(vkQueueWaitIdle(queue));
      if (st) { printf("%s%s %ux%ux%u: pack status %d\n", args[s], args[s + 1], M, N, K, st); continue; }
      if (opA == ABLAS_OP_P) bA = (ablas_buf){PA.buf, 0};
      if (opB == ABLAS_OP_P) bB = (ablas_buf){PB.buf, 0};
    }
    // run(reps, timed): record reps back-to-back calls; returns GPU microseconds per call when timed
    double t0 = 0;
#define RUN(reps, timed)                                                                                     \
  do {                                                                                                       \
    CK(vkResetCommandBuffer(cmd, 0));                                                                        \
    VkCommandBufferBeginInfo bi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, NULL,                        \
                                   VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT};                             \
    CK(vkBeginCommandBuffer(cmd, &bi));                                                                      \
    if (timed) { vkCmdResetQueryPool(cmd, qp, 0, 2); vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, qp, 0); } \
    for (int r_ = 0; r_ < (reps); ++r_) {                                                                    \
      st = ablas_hgemm(h, cmd, opA, opB, M, N, K, bA, bB, bC, bW);                                          \
      vkCmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &mb, 0, NULL, 0, NULL); \
    }                                                                                                        \
    if (timed) vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, qp, 1);                       \
    CK(vkEndCommandBuffer(cmd));                                                                             \
    VkSubmitInfo si_ = {VK_STRUCTURE_TYPE_SUBMIT_INFO};                                                      \
    si_.commandBufferCount = 1;                                                                              \
    si_.pCommandBuffers = &cmd;                                                                              \
    CK(vkQueueSubmit(queue, 1, &si_, VK_NULL_HANDLE));                                                       \
    CK(vkQueueWaitIdle(queue));                                                                              \
  } while (0)
    memset(C.map, 0xff, (size_t)M * N * 2);  // NaN poison
    double tc = now_ms();
    RUN(1, 0);
    tc = now_ms() - tc;
    if (st) { printf("%s%s %ux%ux%u: status %d\n", args[s], args[s + 1], M, N, K, st); continue; }
    // check sampled elements against an fp32 CPU reference
    _Float16* c = C.map;
    double maxref = 1e-6, maxerr = 0;
    for (int t = 0; t < 1024; ++t) {
      rng = rng * 1664525u + 1013904223u;
      uint32_t i = (rng >> 4) % M;
      rng = rng * 1664525u + 1013904223u;
      uint32_t j = (rng >> 4) % N;
      float ref = 0;
      for (uint32_t k = 0; k < K; ++k) {
        float x = refA == ABLAS_OP_N ? (float)a[(size_t)i * K + k] : (float)a[(size_t)k * M + i];
        float y = refB == ABLAS_OP_N ? (float)b[(size_t)k * N + j] : (float)b[(size_t)j * K + k];
        ref += x * y;
      }
      double e = fabs((double)c[(size_t)i * N + j] - ref);
      if (!(e == e)) e = INFINITY;
      if (fabs(ref) > maxref) maxref = fabs(ref);
      if (e > maxerr) maxerr = e;
    }
    double err = maxerr / maxref;
    // timing: ~300 ms warm-up, then best of 5 runs of `reps` calls (~100 ms each)
    t0 = now_ms();
    while (now_ms() - t0 < 300) RUN(1, 0);
    uint64_t ts[2];
    RUN(1, 1);
    vkGetQueryPoolResults(dev, qp, 0, 2, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT);
    double one = (ts[1] - ts[0]) * props.limits.timestampPeriod * 1e-3;
    int reps = (int)(100e3 / (one > 1 ? one : 1));
    if (reps < 1) reps = 1;
    if (reps > 500) reps = 500;
    double best = 1e30;
    for (int r = 0; r < 5; ++r) {
      RUN(reps, 1);
      vkGetQueryPoolResults(dev, qp, 0, 2, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT);
      double us = (ts[1] - ts[0]) * props.limits.timestampPeriod * 1e-3 / reps;
      if (us < best) best = us;
    }
    printf("%s%s %5ux%5ux%5u  %-34s %6.2f TFLOP/s  %8.1f us  err %.1e %s  (first call %.0f ms incl. pipeline)\n",
           args[s], args[s + 1], M, N, K, ablas_last_kernel(h), 2.0 * M * N * K / (best * 1e-6) / 1e12, best, err,
           err < 2e-2 ? "PASS" : "FAIL", tc);
    fflush(stdout);
  }
  ablas_destroy(h);
  return 0;
}
