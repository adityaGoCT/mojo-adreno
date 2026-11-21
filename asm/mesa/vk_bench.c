// vk_bench: on-device Vulkan harness (from iree-adreno-genai-tuner gemm/harness/vk_gemm_bench.c),
// extended to Vulkan 1.3 features and VK_KHR_cooperative_matrix for the Adreno 8xx GEMM work.
//
// Reads a manifest of candidates; each candidate is one or more compute dispatches (SPIR-V files)
// run in order on a shape's buffers:
//   binding 0: A (f16, stored layout)   binding 1: B (f16, stored layout)   binding 2: C (f16, M x N)
//   binding 3: scratch S0 (>= M*K f16)  binding 4: scratch S1 (>= K*N f16)  (materialized transposes)
// For each candidate: create pipelines (with VK_EXT_subgroup_size_control's required subgroup size),
// run once, check C against the reference, then time it with GPU timestamps (median of --reps).
//
// Manifest line:  <name> <shape_dir> <subgroup_size> <n_dispatch> {<spv> <gx> <gy> <gz>}*n_dispatch
// shape_dir/meta.txt: "M N K LA LB TOL [ESZ]"  (TOL < 0: no check, e.g. microbenchmarks; ESZ = bytes per
// A/B element, default 2 (f16); asm/mesa copy: ESZ 4 lets fp32 kernels read fp32 operands)
// shape_dir/A.bin, B.bin: f16 in stored layout;  Cref.bin: f32 row-major M x N (absent if TOL < 0)
// Output: one JSON object per candidate on stdout.
//
// Vulkan is reached through dlopen("libvulkan.so"): LD_LIBRARY_PATH=/data/local/tmp/turnip selects
// Mesa Turnip (via our shim); without it the system loader + vendor driver are used.

#include <dlfcn.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#define VK_NO_PROTOTYPES
#include <vulkan/vulkan.h>

#define CHECK(x)                                                                         \
  do {                                                                                   \
    VkResult r_ = (x);                                                                   \
    if (r_ != VK_SUCCESS) {                                                              \
      fprintf(stderr, "%s:%d %s -> %d\n", __FILE__, __LINE__, #x, (int)r_);              \
      if (r_ == VK_ERROR_DEVICE_LOST) {                                                  \
        printf("{\"name\":\"%s\",\"ok\":false,\"error\":\"device_lost\"}\n", g_cur);    \
        fflush(stdout);                                                                  \
        exit(3);                                                                         \
      }                                                                                  \
      return r_;                                                                         \
    }                                                                                    \
  } while (0)

static char g_cur[256] = "";
// VK_BENCH_CACHE_IN=file seeds the pipeline cache (e.g. a blob with patched ISA);
// VK_BENCH_CACHE_OUT=file saves the cache after the first pipeline is created.
static VkPipelineCache g_cache = VK_NULL_HANDLE;
static int g_ssc = 0;  // subgroup size control enabled
static double g_warmup_ms = 500;  // --warmup-ms: GPU busy time before the first measurement

// ---- Vulkan function table -------------------------------------------------------------
#define VK_FUNCS(X)                                                                      \
  X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties)     \
  X(vkGetPhysicalDeviceQueueFamilyProperties) X(vkGetPhysicalDeviceMemoryProperties)     \
  X(vkCreateDevice) X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkDestroyBuffer)             \
  X(vkGetBufferMemoryRequirements) X(vkAllocateMemory) X(vkFreeMemory)                   \
  X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateShaderModule) X(vkDestroyShaderModule)  \
  X(vkCreateDescriptorSetLayout) X(vkCreatePipelineLayout) X(vkCreateComputePipelines)   \
  X(vkDestroyPipeline) X(vkCreateDescriptorPool) X(vkAllocateDescriptorSets)             \
  X(vkUpdateDescriptorSets) X(vkCreateCommandPool) X(vkAllocateCommandBuffers)           \
  X(vkBeginCommandBuffer) X(vkEndCommandBuffer) X(vkResetCommandBuffer)                  \
  X(vkCmdBindPipeline) X(vkCmdBindDescriptorSets) X(vkCmdDispatch)                       \
  X(vkCmdPipelineBarrier) X(vkCmdWriteTimestamp) X(vkCmdResetQueryPool)                  \
  X(vkCreateQueryPool) X(vkGetQueryPoolResults) X(vkQueueSubmit) X(vkQueueWaitIdle)       \
  X(vkCmdFillBuffer) X(vkResetDescriptorPool) X(vkGetPhysicalDeviceFeatures2) \
  X(vkCreatePipelineCache) X(vkGetPipelineCacheData)

#define DECL(f) static PFN_##f f;
VK_FUNCS(DECL)
static PFN_vkGetInstanceProcAddr gipa;

typedef struct {
  VkInstance inst;
  VkPhysicalDevice pd;
  VkDevice dev;
  VkQueue q;
  uint32_t qfam;
  VkPhysicalDeviceMemoryProperties memprops;
  float ts_period;
  VkCommandPool pool;
  VkCommandBuffer cmd;
  VkQueryPool qpool;
  VkDescriptorSetLayout dsl;
  VkPipelineLayout pl;
  VkDescriptorPool dpool;
} ctx_t;

typedef struct {
  VkBuffer buf;
  VkDeviceMemory mem;
  void* map;
  VkDeviceSize size;
} buffer_t;

typedef struct {
  char dir[512];
  int M, N, K;
  char la, lb;
  double tol;
  buffer_t b[5];  // A, B, C, S0, S1
  float* cref;
  VkDescriptorSet ds;
} shape_t;

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

static float half_to_float(uint16_t h) {
  uint32_t s = (h >> 15) & 1, e = (h >> 10) & 31, m = h & 1023, f;
  if (e == 0) {
    if (m == 0) { f = s << 31; }
    else { e = 1; while (!(m & 1024)) { m <<= 1; e--; } m &= 1023; f = (s << 31) | ((e + 112) << 23) | (m << 13); }
  } else if (e == 31) {
    f = (s << 31) | 0x7f800000 | (m << 13);
  } else {
    f = (s << 31) | ((e + 112) << 23) | (m << 13);
  }
  float out;
  memcpy(&out, &f, 4);
  return out;
}

static void* read_file(const char* path, size_t* size) {
  FILE* f = fopen(path, "rb");
  if (!f) return NULL;
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  fseek(f, 0, SEEK_SET);
  void* p = malloc(n ? n : 1);
  if (fread(p, 1, n, f) != (size_t)n) { fclose(f); free(p); return NULL; }
  fclose(f);
  if (size) *size = n;
  return p;
}

static int find_mem(ctx_t* c, uint32_t bits) {
  // Prefer device-local + host-visible + coherent (unified memory on mobile).
  VkMemoryPropertyFlags want[2] = {
      VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT | VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
      VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT};
  for (int w = 0; w < 2; ++w)
    for (uint32_t i = 0; i < c->memprops.memoryTypeCount; ++i)
      if ((bits & (1u << i)) && (c->memprops.memoryTypes[i].propertyFlags & want[w]) == want[w]) return (int)i;
  return -1;
}

static VkResult make_buffer(ctx_t* c, VkDeviceSize size, buffer_t* b) {
  b->size = size;
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
  CHECK(vkCreateBuffer(c->dev, &bi, NULL, &b->buf));
  VkMemoryRequirements req;
  vkGetBufferMemoryRequirements(c->dev, b->buf, &req);
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};
  ai.allocationSize = req.size;
  ai.memoryTypeIndex = (uint32_t)find_mem(c, req.memoryTypeBits);
  CHECK(vkAllocateMemory(c->dev, &ai, NULL, &b->mem));
  CHECK(vkBindBufferMemory(c->dev, b->buf, b->mem, 0));
  CHECK(vkMapMemory(c->dev, b->mem, 0, VK_WHOLE_SIZE, 0, &b->map));
  return VK_SUCCESS;
}

static void free_buffer(ctx_t* c, buffer_t* b) {
  if (b->buf) vkDestroyBuffer(c->dev, b->buf, NULL);
  if (b->mem) vkFreeMemory(c->dev, b->mem, NULL);
  memset(b, 0, sizeof(*b));
}

static VkResult init(ctx_t* c) {
  void* lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) { fprintf(stderr, "dlopen libvulkan.so: %s\n", dlerror()); return VK_ERROR_INITIALIZATION_FAILED; }
  gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  if (!gipa) gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "_ZN11qglinternal21vkGetInstanceProcAddrEP12VkInstance_TPKc");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "vk_bench", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO};
  ici.pApplicationInfo = &app;
  CHECK(vkCreateInstance(&ici, NULL, &c->inst));
#define LOAD(f) f = (PFN_##f)gipa(c->inst, #f);
  VK_FUNCS(LOAD)
  uint32_t n = 1;
  CHECK(vkEnumeratePhysicalDevices(c->inst, &n, &c->pd));
  VkPhysicalDeviceProperties props;
  vkGetPhysicalDeviceProperties(c->pd, &props);
  c->ts_period = props.limits.timestampPeriod;
  vkGetPhysicalDeviceMemoryProperties(c->pd, &c->memprops);
  uint32_t nq = 0;
  vkGetPhysicalDeviceQueueFamilyProperties(c->pd, &nq, NULL);
  VkQueueFamilyProperties qf[16];
  if (nq > 16) nq = 16;
  vkGetPhysicalDeviceQueueFamilyProperties(c->pd, &nq, qf);
  c->qfam = 0;
  for (uint32_t i = 0; i < nq; ++i) if (qf[i].queueFlags & VK_QUEUE_COMPUTE_BIT) { c->qfam = i; break; }
  fprintf(stderr, "device: %s  api %u.%u  timestampPeriod %.3f ns\n", props.deviceName,
          VK_API_VERSION_MAJOR(props.apiVersion), VK_API_VERSION_MINOR(props.apiVersion), c->ts_period);

  float prio = 1.0f;
  VkDeviceQueueCreateInfo qci = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO};
  qci.queueFamilyIndex = c->qfam;
  qci.queueCount = 1;
  qci.pQueuePriorities = &prio;
  // Features (Vulkan 1.3 core structs + cooperative matrix): query, then enable what the driver has.
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  VkPhysicalDeviceVulkan13Features v13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES, &cm};
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &v13};
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  vkGetPhysicalDeviceFeatures2(c->pd, &f2);
  g_ssc = v13.subgroupSizeControl;
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm_on = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  cm_on.cooperativeMatrix = cm.cooperativeMatrix;
  VkPhysicalDeviceVulkan13Features v13_on = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES, cm.cooperativeMatrix ? &cm_on : NULL};
  v13_on.subgroupSizeControl = v13.subgroupSizeControl;
  v13_on.computeFullSubgroups = v13.computeFullSubgroups;
  VkPhysicalDeviceVulkan12Features v12_on = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &v13_on};
  v12_on.shaderFloat16 = v12.shaderFloat16;
  v12_on.shaderInt8 = v12.shaderInt8;
  v12_on.storageBuffer8BitAccess = v12.storageBuffer8BitAccess;
  v12_on.vulkanMemoryModel = v12.vulkanMemoryModel;
  v12_on.vulkanMemoryModelDeviceScope = v12.vulkanMemoryModelDeviceScope;
  VkPhysicalDeviceVulkan11Features v11_on = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12_on};
  v11_on.storageBuffer16BitAccess = v11.storageBuffer16BitAccess;
  VkPhysicalDeviceFeatures2 f2_on = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11_on};
  f2_on.features.shaderInt16 = f2.features.shaderInt16;
  f2_on.features.shaderInt64 = f2.features.shaderInt64;
  fprintf(stderr, "features: shaderFloat16=%u shaderInt8=%u subgroupSizeControl=%u cooperativeMatrix=%u\n",
          v12.shaderFloat16, v12.shaderInt8, v13.subgroupSizeControl, cm.cooperativeMatrix);
  const char* exts[] = {"VK_KHR_cooperative_matrix"};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &f2_on};
  dci.queueCreateInfoCount = 1;
  dci.pQueueCreateInfos = &qci;
  dci.enabledExtensionCount = cm.cooperativeMatrix ? 1 : 0;
  dci.ppEnabledExtensionNames = exts;
  CHECK(vkCreateDevice(c->pd, &dci, NULL, &c->dev));
  vkGetDeviceQueue(c->dev, c->qfam, 0, &c->q);

  VkCommandPoolCreateInfo cpi = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
  cpi.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
  cpi.queueFamilyIndex = c->qfam;
  CHECK(vkCreateCommandPool(c->dev, &cpi, NULL, &c->pool));
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
  cai.commandPool = c->pool;
  cai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
  cai.commandBufferCount = 1;
  CHECK(vkAllocateCommandBuffers(c->dev, &cai, &c->cmd));
  VkQueryPoolCreateInfo qpi = {VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO};
  qpi.queryType = VK_QUERY_TYPE_TIMESTAMP;
  qpi.queryCount = 2;
  CHECK(vkCreateQueryPool(c->dev, &qpi, NULL, &c->qpool));

  VkDescriptorSetLayoutBinding binds[5];
  for (int i = 0; i < 5; ++i) {
    binds[i] = (VkDescriptorSetLayoutBinding){(uint32_t)i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  }
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO};
  dli.bindingCount = 5;
  dli.pBindings = binds;
  CHECK(vkCreateDescriptorSetLayout(c->dev, &dli, NULL, &c->dsl));
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO};
  pli.setLayoutCount = 1;
  pli.pSetLayouts = &c->dsl;
  CHECK(vkCreatePipelineLayout(c->dev, &pli, NULL, &c->pl));
  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 5 * 4};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO};
  dpi.maxSets = 4;
  dpi.poolSizeCount = 1;
  dpi.pPoolSizes = &ps;
  CHECK(vkCreateDescriptorPool(c->dev, &dpi, NULL, &c->dpool));
  return VK_SUCCESS;
}

static VkResult load_shape(ctx_t* c, const char* dir, shape_t* s) {
  if (strcmp(s->dir, dir) == 0) return VK_SUCCESS;  // cached
  for (int i = 0; i < 5; ++i) free_buffer(c, &s->b[i]);
  free(s->cref);
  s->cref = NULL;
  vkResetDescriptorPool(c->dev, c->dpool, 0);
  snprintf(s->dir, sizeof(s->dir), "%s", dir);
  char path[600];
  snprintf(path, sizeof(path), "%s/meta.txt", dir);
  FILE* f = fopen(path, "r");
  if (!f) { fprintf(stderr, "no %s\n", path); return VK_ERROR_INITIALIZATION_FAILED; }
  int esz = 2;
  if (fscanf(f, "%d %d %d %c %c %lf", &s->M, &s->N, &s->K, &s->la, &s->lb, &s->tol) != 6) {
    fclose(f);
    return VK_ERROR_INITIALIZATION_FAILED;
  }
  if (fscanf(f, "%d", &esz) != 1 || esz < 1) esz = 2;
  fclose(f);
  VkDeviceSize sz[5] = {(VkDeviceSize)s->M * s->K * esz, (VkDeviceSize)s->K * s->N * esz, (VkDeviceSize)s->M * s->N * 2,
                        (VkDeviceSize)s->M * s->K * esz, (VkDeviceSize)s->K * s->N * esz};
  for (int i = 0; i < 5; ++i) CHECK(make_buffer(c, sz[i] < 256 ? 256 : sz[i], &s->b[i]));
  const char* names[2] = {"A.bin", "B.bin"};
  for (int i = 0; i < 2; ++i) {
    snprintf(path, sizeof(path), "%s/%s", dir, names[i]);
    size_t n = 0;
    void* p = read_file(path, &n);
    if (p) { memcpy(s->b[i].map, p, n < sz[i] ? n : sz[i]); free(p); }
    else memset(s->b[i].map, 0, sz[i]);  // microbenchmarks: content irrelevant
  }
  if (s->tol >= 0) {
    snprintf(path, sizeof(path), "%s/Cref.bin", dir);
    s->cref = (float*)read_file(path, NULL);
    if (!s->cref) { fprintf(stderr, "no %s\n", path); return VK_ERROR_INITIALIZATION_FAILED; }
  }
  VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO};
  dai.descriptorPool = c->dpool;
  dai.descriptorSetCount = 1;
  dai.pSetLayouts = &c->dsl;
  CHECK(vkAllocateDescriptorSets(c->dev, &dai, &s->ds));
  VkDescriptorBufferInfo bi[5];
  VkWriteDescriptorSet w[5];
  for (int i = 0; i < 5; ++i) {
    bi[i] = (VkDescriptorBufferInfo){s->b[i].buf, 0, VK_WHOLE_SIZE};
    w[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, s->ds, (uint32_t)i, 0, 1,
                                  VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi[i], NULL};
  }
  vkUpdateDescriptorSets(c->dev, 5, w, 0, NULL);
  return VK_SUCCESS;
}

#define MAXD 4
typedef struct {
  char name[256], shape[512];
  uint32_t sg;
  int nd;
  char spv[MAXD][512];
  uint32_t g[MAXD][3];
} cand_t;

/* spv is "path" or "path@entry" (IREE kernels are not called "main") */
static VkResult make_pipeline(ctx_t* c, const char* spv_arg, uint32_t sg, VkPipeline* out) {
  char spv[512], entry[256] = "main";
  snprintf(spv, sizeof(spv), "%s", spv_arg);
  char* at = strchr(spv, '@');
  if (at) { *at = 0; snprintf(entry, sizeof(entry), "%s", at + 1); }
  size_t n = 0;
  uint32_t* code = (uint32_t*)read_file(spv, &n);
  if (!code) { fprintf(stderr, "no %s\n", spv); return VK_ERROR_INITIALIZATION_FAILED; }
  VkShaderModuleCreateInfo smi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO};
  smi.codeSize = n;
  smi.pCode = code;
  VkShaderModule sm;
  VkResult r = vkCreateShaderModule(c->dev, &smi, NULL, &sm);
  free(code);
  CHECK(r);
  VkPipelineShaderStageRequiredSubgroupSizeCreateInfoEXT rss = {
      VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO_EXT};
  rss.requiredSubgroupSize = sg;
  VkComputePipelineCreateInfo ci = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  ci.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  ci.stage.pNext = (sg && g_ssc) ? &rss : NULL;
  ci.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  ci.stage.module = sm;
  ci.stage.pName = entry;
  ci.layout = c->pl;
  if (!g_cache) {
    VkPipelineCacheCreateInfo pci = {VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO};
    const char* in = getenv("VK_BENCH_CACHE_IN");
    size_t n = 0;
    void* data = in ? read_file(in, &n) : NULL;
    pci.initialDataSize = n;
    pci.pInitialData = data;
    VkResult cr = vkCreatePipelineCache(c->dev, &pci, NULL, &g_cache);
    fprintf(stderr, "pipeline cache: seeded with %zu bytes from %s -> %d\n", n, in ? in : "(none)", (int)cr);
    free(data);
  }
  double tc0 = now_ms();
  r = vkCreateComputePipelines(c->dev, g_cache, 1, &ci, NULL, out);
  fprintf(stderr, "pipeline create: %.2f ms\n", now_ms() - tc0);
  const char* outp = getenv("VK_BENCH_CACHE_OUT");
  if (outp && r == VK_SUCCESS) {
    size_t n = 0;
    vkGetPipelineCacheData(c->dev, g_cache, &n, NULL);
    void* data = malloc(n);
    vkGetPipelineCacheData(c->dev, g_cache, &n, data);
    FILE* f = fopen(outp, "wb");
    if (f) { fwrite(data, 1, n, f); fclose(f); }
    free(data);
    fprintf(stderr, "pipeline cache: %zu bytes -> %s\n", n, outp);
  }
  vkDestroyShaderModule(c->dev, sm, NULL);
  return r;
}

static VkResult record(ctx_t* c, shape_t* s, cand_t* k, VkPipeline* p, int iters, int timed) {
  CHECK(vkResetCommandBuffer(c->cmd, 0));
  VkCommandBufferBeginInfo bi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  bi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
  CHECK(vkBeginCommandBuffer(c->cmd, &bi));
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT | VK_ACCESS_TRANSFER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT};
  if (timed) {
    vkCmdResetQueryPool(c->cmd, c->qpool, 0, 2);
    vkCmdWriteTimestamp(c->cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, c->qpool, 0);
  }
  vkCmdBindDescriptorSets(c->cmd, VK_PIPELINE_BIND_POINT_COMPUTE, c->pl, 0, 1, &s->ds, 0, NULL);
  for (int it = 0; it < iters; ++it) {
    for (int d = 0; d < k->nd; ++d) {
      vkCmdBindPipeline(c->cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p[d]);
      vkCmdDispatch(c->cmd, k->g[d][0], k->g[d][1], k->g[d][2]);
      vkCmdPipelineBarrier(c->cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT | VK_PIPELINE_STAGE_TRANSFER_BIT,
                           VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &mb, 0, NULL, 0, NULL);
    }
  }
  if (timed) vkCmdWriteTimestamp(c->cmd, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, c->qpool, 1);
  CHECK(vkEndCommandBuffer(c->cmd));
  VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
  si.commandBufferCount = 1;
  si.pCommandBuffers = &c->cmd;
  CHECK(vkQueueSubmit(c->q, 1, &si, VK_NULL_HANDLE));
  CHECK(vkQueueWaitIdle(c->q));
  return VK_SUCCESS;
}

static double read_ts_us(ctx_t* c, int iters) {
  uint64_t t[2];
  vkGetQueryPoolResults(c->dev, c->qpool, 0, 2, sizeof(t), t, sizeof(uint64_t),
                        VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT);
  return (double)(t[1] - t[0]) * c->ts_period / 1e3 / iters;
}

static int cmp_d(const void* a, const void* b) {
  double x = *(const double*)a, y = *(const double*)b;
  return (x > y) - (x < y);
}

static VkResult run_candidate(ctx_t* c, shape_t* s, cand_t* k, double target_ms, int reps) {
  snprintf(g_cur, sizeof(g_cur), "%s", k->name);
  if (load_shape(c, k->shape, s) != VK_SUCCESS) {  // don't keep a half-loaded shape cached
    s->dir[0] = 0;
    printf("{\"name\":\"%s\",\"ok\":false,\"error\":\"shape load failed\"}\n", k->name);
    fflush(stdout);
    return VK_SUCCESS;
  }
  VkPipeline p[MAXD] = {0};
  for (int d = 0; d < k->nd; ++d) {
    VkResult r = make_pipeline(c, k->spv[d], k->sg, &p[d]);
    if (r != VK_SUCCESS) {
      printf("{\"name\":\"%s\",\"ok\":false,\"error\":\"pipeline %d\"}\n", k->name, (int)r);
      for (int j = 0; j < d; ++j) vkDestroyPipeline(c->dev, p[j], NULL);
      return VK_SUCCESS;
    }
  }
  // Correctness: poison C, run once, compare with the reference.
  memset(s->b[2].map, 0xFF, s->b[2].size);  // f16 NaNs
  double err = -1;
  int ok = 1;
  CHECK(record(c, s, k, p, 1, 0));
  if (s->tol >= 0) {
    const uint16_t* C = (const uint16_t*)s->b[2].map;
    double maxref = 1e-6, maxerr = 0;
    size_t n = (size_t)s->M * s->N;
    for (size_t i = 0; i < n; ++i) if (fabs(s->cref[i]) > maxref) maxref = fabs(s->cref[i]);
    for (size_t i = 0; i < n; ++i) {
      double v = half_to_float(C[i]);
      double e = fabs(v - s->cref[i]);
      if (!(e == e)) { maxerr = INFINITY; break; }  // NaN
      if (e > maxerr) maxerr = e;
    }
    err = maxerr / maxref;
    ok = err <= s->tol;
    if (!isfinite(err)) err = 1e30;  /* NaN/Inf output: keep the JSON valid */
  }
  // Warm-up: the GPU's DVFS governor drops the clock while idle (between adb round trips), and the
  // first candidate of a batch measured 1.6-1.9x slow. Keep the GPU busy before timing: ~500 ms
  // before the first candidate of the process, ~50 ms before every other one.
  static int warmed = 0;
  double t0 = now_ms(), budget = warmed ? 50.0 : g_warmup_ms;
  while (now_ms() - t0 < budget) CHECK(record(c, s, k, p, 1, 0));
  warmed = 1;
  // Timing: estimate one iteration, then time `iters` back-to-back iterations per rep.
  CHECK(record(c, s, k, p, 1, 1));
  double one = read_ts_us(c, 1);
  if (one > 100e3) reps = 1;  /* >100 ms per run: one timed run is plenty (and spares the GPU) */
  int iters = (int)(target_ms * 1e3 / (one > 1 ? one : 1));
  if (iters < 1) iters = 1;
  if (iters > 2000) iters = 2000;
  double t[64];
  if (reps > 64) reps = 64;
  for (int r = 0; r < reps; ++r) {
    CHECK(record(c, s, k, p, iters, 1));
    t[r] = read_ts_us(c, iters);
  }
  qsort(t, reps, sizeof(double), cmp_d);
  printf("{\"name\":\"%s\",\"ok\":%s,\"err\":%.3e,\"us\":%.3f,\"us_min\":%.3f,\"iters\":%d,\"reps\":%d}\n", k->name,
         ok ? "true" : "false", err, t[reps / 2], t[0], iters, reps);
  fflush(stdout);
  for (int d = 0; d < k->nd; ++d) vkDestroyPipeline(c->dev, p[d], NULL);
  return VK_SUCCESS;
}

int main(int argc, char** argv) {
  const char* manifest = NULL;
  double target_ms = 30;
  int reps = 5;
  for (int i = 1; i < argc; ++i) {
    if (!strncmp(argv[i], "--manifest=", 11)) manifest = argv[i] + 11;
    else if (!strncmp(argv[i], "--target-ms=", 12)) target_ms = atof(argv[i] + 12);
    else if (!strncmp(argv[i], "--reps=", 7)) reps = atoi(argv[i] + 7);
    else if (!strncmp(argv[i], "--warmup-ms=", 12)) g_warmup_ms = atof(argv[i] + 12);
  }
  if (!manifest) { fprintf(stderr, "usage: %s --manifest=FILE [--target-ms=30] [--reps=5]\n", argv[0]); return 2; }
  ctx_t c = {0};
  if (init(&c) != VK_SUCCESS) return 1;
  shape_t s = {0};
  FILE* f = fopen(manifest, "r");
  if (!f) { fprintf(stderr, "no manifest %s\n", manifest); return 2; }
  char line[8192];
  while (fgets(line, sizeof(line), f)) {
    cand_t k = {0};
    char* sp = NULL;
    char* tok = strtok_r(line, " \t\n", &sp);
    if (!tok || tok[0] == '#') continue;
    snprintf(k.name, sizeof(k.name), "%s", tok);
    snprintf(k.shape, sizeof(k.shape), "%s", strtok_r(NULL, " \t\n", &sp));
    k.sg = (uint32_t)atoi(strtok_r(NULL, " \t\n", &sp));
    k.nd = atoi(strtok_r(NULL, " \t\n", &sp));
    if (k.nd < 1 || k.nd > MAXD) continue;
    for (int d = 0; d < k.nd; ++d) {
      snprintf(k.spv[d], sizeof(k.spv[d]), "%s", strtok_r(NULL, " \t\n", &sp));
      for (int j = 0; j < 3; ++j) k.g[d][j] = (uint32_t)atoi(strtok_r(NULL, " \t\n", &sp));
    }
    if (run_candidate(&c, &s, &k, target_ms, reps) != VK_SUCCESS) {
      printf("{\"name\":\"%s\",\"ok\":false,\"error\":\"vk\"}\n", k.name);
      fflush(stdout);
    }
  }
  fclose(f);
  return 0;
}
