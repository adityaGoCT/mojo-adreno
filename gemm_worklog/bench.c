// bench: time one fp16 GEMM kernel C[M,N] = A[M,K] B[K,N] on a Vulkan GPU, and check it.
//   bench <kernel.spv> M N K gx gy la lb
// The kernel binds A, B and C at bindings 0, 1, 2 (fp16 storage buffers) and has M, N, K compiled in.
// A and B are random fp16 values in [-1, 1). They are stored in the layout the kernel expects:
//   la: N  A as [M,K] row-major            T  A as [K,M] (K-major)
//       P  64 x 16 tiles, column-major inside (each tile 2 KB contiguous, K tiles adjacent)
//       R  64 x 16 tiles, row-major inside (each row's 16 K values adjacent)
//   lb: N  B as [K,N] row-major            T  B as [N,K]
//       P  16 x 32 tiles, row-major inside (1 KB)    Q  16 x 64 tiles, row-major inside (2 KB)
//       C  16 x 64 tiles, column-major inside (each column's 16 K values adjacent)
// C is always [M,N] row-major fp16. One run is checked: 1,024 sampled outputs against a double-precision
// reference (error relative to the largest |C| sampled). Then the kernel is timed with GPU timestamps: best of
// 5 runs of `reps` back-to-back dispatches, reps chosen so one run takes about 100 ms.
// Prints:  RESULT <kernel> <TFLOP/s> <us per GEMM> err <e> PASS|WRONG
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vulkan/vulkan.h>

#define VK_FUNCS(X) X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties) \
  X(vkGetPhysicalDeviceMemoryProperties) X(vkCreateDevice) X(vkGetDeviceProcAddr)
#define VK_DFUNCS(X)                                                                                        \
  X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkGetBufferMemoryRequirements) X(vkAllocateMemory)                \
  X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateCommandPool) X(vkAllocateCommandBuffers)                   \
  X(vkBeginCommandBuffer) X(vkEndCommandBuffer) X(vkResetCommandBuffer) X(vkQueueSubmit) X(vkQueueWaitIdle) \
  X(vkCreateQueryPool) X(vkCmdResetQueryPool) X(vkCmdWriteTimestamp) X(vkGetQueryPoolResults)               \
  X(vkCreateShaderModule) X(vkCreateComputePipelines) X(vkCreateDescriptorSetLayout)                        \
  X(vkCreatePipelineLayout) X(vkCmdBindPipeline) X(vkCmdDispatch) X(vkCmdPushDescriptorSetKHR) X(vkCmdDispatchBase)
#define VKFN(f) static PFN_##f f;
VK_FUNCS(VKFN)
VK_DFUNCS(VKFN)
#define CK(x) do { VkResult r_ = (x); if (r_) { printf("vulkan error %d at %s\n", r_, #x); exit(3); } } while (0)

static VkDevice dev;
static VkQueue queue;
static VkPhysicalDeviceMemoryProperties memprops;
static double ts_ns;

typedef struct { VkBuffer buf; void* map; } buf_t;

static VkCommandBuffer cmd;
static VkQueryPool qp;
static VkPipeline pipe;
static VkPipelineLayout layout;
static VkWriteDescriptorSet w[3];
static uint32_t gx, gy, chunks = 1;

// reps dispatches between two timestamps; returns microseconds per dispatch. With chunks > 1 (env BENCH_CHUNKS) the
// grid is split along y into that many slices, each submitted on its own (vkCmdDispatchBase), and their times are
// added: Android's GPU watchdog declares a hang when one submission runs for more than about two seconds.
static double run(int reps) {
  double total = 0;
  for (uint32_t ch = 0; ch < chunks; ++ch) {
    uint32_t gy0 = gy * ch / chunks, gy1 = gy * (ch + 1) / chunks;
    VkCommandBufferBeginInfo cbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    CK(vkResetCommandBuffer(cmd, 0));
    CK(vkBeginCommandBuffer(cmd, &cbi));
    vkCmdResetQueryPool(cmd, qp, 0, 2);
    vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, qp, 0);
    for (int r = 0; r < reps; ++r) {
      vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pipe);
      vkCmdPushDescriptorSetKHR(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, layout, 0, 3, w);
      if (chunks == 1) vkCmdDispatch(cmd, gx, gy, 1);
      else vkCmdDispatchBase(cmd, 0, gy0, 0, gx, gy1 - gy0, 1);
    }
    vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, qp, 1);
    CK(vkEndCommandBuffer(cmd));
    VkSubmitInfo sub = {VK_STRUCTURE_TYPE_SUBMIT_INFO, NULL, 0, NULL, NULL, 1, &cmd};
    CK(vkQueueSubmit(queue, 1, &sub, VK_NULL_HANDLE));
    CK(vkQueueWaitIdle(queue));
    uint64_t ts[2];
    CK(vkGetQueryPoolResults(dev, qp, 0, 2, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
    total += (ts[1] - ts[0]) * ts_ns * 1e-3;
  }
  return total / reps;
}

static buf_t mkbuf(size_t size) {
  buf_t b = {0};
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

static void init_vulkan(void) {
  void* lib = dlopen("libvulkan.so", RTLD_NOW);
  if (!lib) lib = dlopen("libvulkan.so.1", RTLD_NOW);
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "gemm-worklog", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL, 0, &app};
  VkInstance inst;
  CK(vkCreateInstance(&ici, NULL, &inst));
#define LI(f) f = (PFN_##f)gipa(inst, #f);
  VK_FUNCS(LI)
  uint32_t n = 1;
  VkPhysicalDevice pd;
  vkEnumeratePhysicalDevices(inst, &n, &pd);
  VkPhysicalDeviceProperties props;
  vkGetPhysicalDeviceProperties(pd, &props);
  ts_ns = props.limits.timestampPeriod;
  vkGetPhysicalDeviceMemoryProperties(pd, &memprops);
  float prio = 1;
  VkDeviceQueueCreateInfo q = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, 0, 1, &prio};
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  cm.cooperativeMatrix = VK_TRUE;
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &cm};
  v12.shaderFloat16 = v12.vulkanMemoryModel = v12.vulkanMemoryModelDeviceScope = VK_TRUE;
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  v11.storageBuffer16BitAccess = VK_TRUE;
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  const char* exts[] = {"VK_KHR_push_descriptor", "VK_KHR_cooperative_matrix"};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &f2, 0, 1, &q, 0, NULL, 2, exts};
  CK(vkCreateDevice(pd, &dci, NULL, &dev));
#define LD(f) f = (PFN_##f)vkGetDeviceProcAddr(dev, #f);
  VK_DFUNCS(LD)
  vkGetDeviceQueue(dev, 0, 0, &queue);
}

// where element (r, k) of A and (k, n) of B live, per layout
static size_t a_index(char l, uint32_t M, uint32_t K, uint32_t r, uint32_t k) {
  switch (l) {
    case 'N': return (size_t)r * K + k;
    case 'T': return (size_t)k * M + r;
    case 'P': return ((size_t)(r / 64) * (K / 16) + k / 16) * 1024 + (k % 16) * 64 + r % 64;
    case 'R': return ((size_t)(r / 64) * (K / 16) + k / 16) * 1024 + (r % 64) * 16 + k % 16;
  }
  printf("bad A layout %c\n", l), exit(2);
}
static size_t b_index(char l, uint32_t N, uint32_t K, uint32_t k, uint32_t n) {
  switch (l) {
    case 'N': return (size_t)k * N + n;
    case 'T': return (size_t)n * K + k;
    case 'P': return ((size_t)(n / 32) * (K / 16) + k / 16) * 512 + (k % 16) * 32 + n % 32;
    case 'Q': return ((size_t)(n / 64) * (K / 16) + k / 16) * 1024 + (k % 16) * 64 + n % 64;
    case 'C': return ((size_t)(n / 64) * (K / 16) + k / 16) * 1024 + (n % 64) * 16 + k % 16;
  }
  printf("bad B layout %c\n", l), exit(2);
}

static uint32_t rng = 12345;
static float frand(void) { rng = rng * 1664525u + 1013904223u; return (float)(rng >> 8) / (float)(1u << 23) - 1.0f; }

int main(int argc, char** argv) {
  if (argc < 9) { printf("usage: bench kernel.spv M N K gx gy la lb\n"); return 2; }
  const char* path = argv[1];
  uint32_t M = atoi(argv[2]), N = atoi(argv[3]), K = atoi(argv[4]);
  gx = atoi(argv[5]), gy = atoi(argv[6]);
  char la = argv[7][0], lb = argv[8][0];
  const char* name = strrchr(path, '/') ? strrchr(path, '/') + 1 : path;
  setvbuf(stdout, NULL, _IOLBF, 0);
  init_vulkan();

  // inputs: logical A [M,K] and B [K,N] in fp16, scattered into the kernel's layouts
  _Float16* A = malloc((size_t)M * K * 2);
  _Float16* B = malloc((size_t)K * N * 2);
  for (size_t i = 0; i < (size_t)M * K; ++i) A[i] = (_Float16)frand();
  for (size_t i = 0; i < (size_t)K * N; ++i) B[i] = (_Float16)frand();
  buf_t ba = mkbuf((size_t)M * K * 2), bb = mkbuf((size_t)K * N * 2), bc = mkbuf((size_t)M * N * 2);
  for (uint32_t r = 0; r < M; ++r)
    for (uint32_t k = 0; k < K; ++k) ((_Float16*)ba.map)[a_index(la, M, K, r, k)] = A[(size_t)r * K + k];
  for (uint32_t k = 0; k < K; ++k)
    for (uint32_t n = 0; n < N; ++n) ((_Float16*)bb.map)[b_index(lb, N, K, k, n)] = B[(size_t)k * N + n];
  memset(bc.map, 0xff, (size_t)M * N * 2);  // NaNs: an output the kernel never writes fails the check

  // pipeline: three storage buffers, pushed
  VkDescriptorSetLayoutBinding lbd[3];
  for (uint32_t i = 0; i < 3; ++i)
    lbd[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL,
                                         VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR, 3, lbd};
  VkDescriptorSetLayout dsl;
  CK(vkCreateDescriptorSetLayout(dev, &dli, NULL, &dsl));
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &dsl, 0, NULL};
  CK(vkCreatePipelineLayout(dev, &pli, NULL, &layout));
  FILE* f = fopen(path, "rb");
  if (!f) { printf("cannot open %s\n", path); return 2; }
  fseek(f, 0, SEEK_END);
  size_t sz = ftell(f);
  fseek(f, 0, SEEK_SET);
  uint32_t* code = malloc(sz);
  if (fread(code, 1, sz, f) != sz) return 2;
  fclose(f);
  VkShaderModuleCreateInfo mi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, sz, code};
  VkShaderModule mod;
  CK(vkCreateShaderModule(dev, &mi, NULL, &mod));
  VkComputePipelineCreateInfo ci = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  ci.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  ci.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  ci.stage.module = mod;
  ci.stage.pName = "main";
  ci.layout = layout;
  if (getenv("BENCH_CHUNKS")) chunks = atoi(getenv("BENCH_CHUNKS"));
  if (chunks > 1) ci.flags = VK_PIPELINE_CREATE_DISPATCH_BASE_BIT;
  CK(vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &ci, NULL, &pipe));

  VkCommandPoolCreateInfo cpi = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL, VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, 0};
  VkCommandPool pool;
  CK(vkCreateCommandPool(dev, &cpi, NULL, &pool));
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, pool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  CK(vkAllocateCommandBuffers(dev, &cai, &cmd));
  VkQueryPoolCreateInfo qpi = {VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO, NULL, 0, VK_QUERY_TYPE_TIMESTAMP, 2};
  CK(vkCreateQueryPool(dev, &qpi, NULL, &qp));
  VkDescriptorBufferInfo bi[3] = {{ba.buf, 0, VK_WHOLE_SIZE}, {bb.buf, 0, VK_WHOLE_SIZE}, {bc.buf, 0, VK_WHOLE_SIZE}};
  for (uint32_t i = 0; i < 3; ++i)
    w[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, VK_NULL_HANDLE, i, 0, 1,
                                  VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi[i], NULL};

  double first = run(1);

  // check 1,024 sampled outputs
  double maxerr = 0, maxref = 0;
  uint32_t s = 7;
  for (int i = 0; i < 1024; ++i) {
    s = s * 1664525u + 1013904223u;
    uint32_t m = (s >> 8) % M;
    s = s * 1664525u + 1013904223u;
    uint32_t n = (s >> 8) % N;
    double ref = 0;
    for (uint32_t k = 0; k < K; ++k) ref += (double)A[(size_t)m * K + k] * (double)B[(size_t)k * N + n];
    double got = (double)((_Float16*)bc.map)[(size_t)m * N + n];
    double e = isnan(got) ? 1e30 : fabs(got - ref);
    if (e > maxerr) maxerr = e;
    if (fabs(ref) > maxref) maxref = fabs(ref);
  }
  double err = maxerr / maxref;

  int reps = (int)(100000.0 / first);
  if (reps < 1) reps = 1;
  if (reps > 200) reps = 200;
  run(reps);  // warm-up at the timed length
  double best = 1e30;
  for (int i = 0; i < 5; ++i) {
    double us = run(reps);
    if (us < best) best = us;
  }
  double tf = 2.0 * M * N * K / (best * 1e-6) / 1e12;
  printf("RESULT %s %.3f TFLOP/s %.1f us err %.1e %s\n", name, tf, best, err, err < 2e-2 ? "PASS" : "WRONG");
  return err < 2e-2 ? 0 : 1;
}
