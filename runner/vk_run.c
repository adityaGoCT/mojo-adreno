// Minimal Vulkan compute runner for the phone: runs one SPIR-V kernel that computes
// C[i] = A[i] + B[i] (float32) and checks the result.
//
//   vk_run <kernel.spv> <entry> <n> <workgroups_x> [subgroup_size]
//
// Bindings (set 0): 0 = A, 1 = B, 2 = C (n floats each), 3 = params (int64[4]: params[0] = n).
// A[i] = i, B[i] = 2i, C is poisoned with NaN before the dispatch.
// Loads libvulkan.so with dlopen so LD_LIBRARY_PATH can select Mesa Turnip or the stock driver.
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <vulkan/vulkan.h>

#define CHECK(x)                                                              \
  do {                                                                        \
    VkResult r_ = (x);                                                        \
    if (r_ != VK_SUCCESS) {                                                   \
      fprintf(stderr, "%s:%d %s -> %d\n", __FILE__, __LINE__, #x, (int)r_);   \
      exit(2);                                                                \
    }                                                                         \
  } while (0)

#define VK_FUNCS(X)                                                                      \
  X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties)     \
  X(vkGetPhysicalDeviceQueueFamilyProperties) X(vkGetPhysicalDeviceMemoryProperties)     \
  X(vkCreateDevice) X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkGetBufferMemoryRequirements) \
  X(vkAllocateMemory) X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateShaderModule)       \
  X(vkCreateDescriptorSetLayout) X(vkCreatePipelineLayout) X(vkCreateComputePipelines)   \
  X(vkCreateDescriptorPool) X(vkAllocateDescriptorSets) X(vkUpdateDescriptorSets)        \
  X(vkCreateCommandPool) X(vkAllocateCommandBuffers) X(vkBeginCommandBuffer)             \
  X(vkEndCommandBuffer) X(vkCmdBindPipeline) X(vkCmdBindDescriptorSets) X(vkCmdDispatch) \
  X(vkQueueSubmit) X(vkQueueWaitIdle) X(vkGetPhysicalDeviceFeatures2) X(vkEnumerateDeviceExtensionProperties)

#define DECL(f) static PFN_##f f;
VK_FUNCS(DECL)

static VkDevice dev;
static VkPhysicalDeviceMemoryProperties memprops;

typedef struct { VkBuffer buf; VkDeviceMemory mem; void* map; } buf_t;

static buf_t make_buffer(size_t size) {
  buf_t b;
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
  CHECK(vkCreateBuffer(dev, &bi, NULL, &b.buf));
  VkMemoryRequirements mr;
  vkGetBufferMemoryRequirements(dev, b.buf, &mr);
  uint32_t want = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, ti = 0;
  for (uint32_t i = 0; i < memprops.memoryTypeCount; ++i)
    if ((mr.memoryTypeBits & (1u << i)) && (memprops.memoryTypes[i].propertyFlags & want) == want) { ti = i; break; }
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, NULL, mr.size, ti};
  CHECK(vkAllocateMemory(dev, &ai, NULL, &b.mem));
  CHECK(vkBindBufferMemory(dev, b.buf, b.mem, 0));
  CHECK(vkMapMemory(dev, b.mem, 0, size, 0, &b.map));
  return b;
}

static void* read_file(const char* path, size_t* n) {
  FILE* f = fopen(path, "rb");
  if (!f) return NULL;
  fseek(f, 0, SEEK_END);
  *n = (size_t)ftell(f);
  fseek(f, 0, SEEK_SET);
  void* p = malloc(*n);
  if (fread(p, 1, *n, f) != *n) { free(p); p = NULL; }
  fclose(f);
  return p;
}

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: %s kernel.spv entry n workgroups_x [subgroup_size]\n", argv[0]); return 2; }
  const char* spv_path = argv[1];
  const char* entry = argv[2];
  int64_t n = atoll(argv[3]);
  uint32_t groups = (uint32_t)atoi(argv[4]);

  void* lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) { fprintf(stderr, "dlopen libvulkan.so: %s\n", dlerror()); return 2; }
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "vk_run", 1, NULL, 0, VK_API_VERSION_1_1};
  const char* api = getenv("VK_RUN_API");  // "1.3" for SPIR-V 1.6 modules on Turnip
  if (api && !strcmp(api, "1.3")) app.apiVersion = VK_API_VERSION_1_3;
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO};
  ici.pApplicationInfo = &app;
  VkInstance inst;
  CHECK(vkCreateInstance(&ici, NULL, &inst));
#define LOAD(f) f = (PFN_##f)gipa(inst, #f);
  VK_FUNCS(LOAD)
  uint32_t npd = 1;
  VkPhysicalDevice pd;
  CHECK(vkEnumeratePhysicalDevices(inst, &npd, &pd));
  VkPhysicalDeviceProperties props;
  vkGetPhysicalDeviceProperties(pd, &props);
  vkGetPhysicalDeviceMemoryProperties(pd, &memprops);
  printf("device: %s  Vulkan %u.%u  driver 0x%x\n", props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion),
         VK_API_VERSION_MINOR(props.apiVersion), props.driverVersion);

  uint32_t nq = 0;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, NULL);
  VkQueueFamilyProperties qf[16];
  if (nq > 16) nq = 16;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, qf);
  uint32_t qfam = 0;
  for (uint32_t i = 0; i < nq; ++i) if (qf[i].queueFlags & VK_QUEUE_COMPUTE_BIT) { qfam = i; break; }

  // Enable what LLVM-generated SPIR-V may declare (Int8 / Int64 / 8-bit storage), if supported.
  VkPhysicalDevice8BitStorageFeatures s8 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES};
  VkPhysicalDeviceShaderFloat16Int8Features f16i8 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES, &s8};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &f16i8};
  vkGetPhysicalDeviceFeatures2(pd, &f2);
  VkPhysicalDeviceFeatures2 en = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &f16i8};
  en.features.shaderInt64 = f2.features.shaderInt64;
  en.features.shaderInt16 = f2.features.shaderInt16;
  s8.uniformAndStorageBuffer8BitAccess = VK_FALSE;
  s8.storagePushConstant8 = VK_FALSE;
  printf("features: shaderInt64=%u shaderInt8=%u storageBuffer8BitAccess=%u\n", f2.features.shaderInt64,
         f16i8.shaderInt8, s8.storageBuffer8BitAccess);
  float prio = 1.0f;
  VkDeviceQueueCreateInfo qci = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, qfam, 1, &prio};
  // Enable each wanted extension only if this driver has it (stock 1.1 driver vs Turnip 1.4).
  const char* want[] = {"VK_KHR_shader_float16_int8", "VK_KHR_8bit_storage", "VK_KHR_storage_buffer_storage_class",
                        "VK_KHR_spirv_1_4", "VK_KHR_shader_float_controls"};
  uint32_t nx = 0;
  vkEnumerateDeviceExtensionProperties(pd, NULL, &nx, NULL);
  VkExtensionProperties* xp = calloc(nx, sizeof *xp);
  vkEnumerateDeviceExtensionProperties(pd, NULL, &nx, xp);
  const char* exts[8];
  uint32_t ne = 0;
  printf("extensions enabled:");
  for (int i = 0; i < 5; ++i)
    for (uint32_t j = 0; j < nx; ++j)
      if (!strcmp(want[i], xp[j].extensionName)) { exts[ne++] = want[i]; printf(" %s", want[i]); break; }
  printf("\n");
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &en};
  dci.queueCreateInfoCount = 1;
  dci.pQueueCreateInfos = &qci;
  dci.enabledExtensionCount = ne;
  dci.ppEnabledExtensionNames = exts;
  CHECK(vkCreateDevice(pd, &dci, NULL, &dev));
  VkQueue q;
  vkGetDeviceQueue(dev, qfam, 0, &q);

  buf_t A = make_buffer(n * 4), B = make_buffer(n * 4), C = make_buffer(n * 4), P = make_buffer(32);
  for (int64_t i = 0; i < n; ++i) {
    ((float*)A.map)[i] = (float)i;
    ((float*)B.map)[i] = (float)(2 * i);
  }
  memset(C.map, 0xFF, n * 4);  // NaN poison
  ((int64_t*)P.map)[0] = n;

  VkDescriptorSetLayoutBinding binds[4];
  for (int i = 0; i < 4; ++i)
    binds[i] = (VkDescriptorSetLayoutBinding){(uint32_t)i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, 4, binds};
  VkDescriptorSetLayout dsl;
  CHECK(vkCreateDescriptorSetLayout(dev, &dli, NULL, &dsl));
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &dsl};
  VkPipelineLayout pl;
  CHECK(vkCreatePipelineLayout(dev, &pli, NULL, &pl));
  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 4};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1, 1, &ps};
  VkDescriptorPool dp;
  CHECK(vkCreateDescriptorPool(dev, &dpi, NULL, &dp));
  VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, dp, 1, &dsl};
  VkDescriptorSet ds;
  CHECK(vkAllocateDescriptorSets(dev, &dai, &ds));
  VkDescriptorBufferInfo dbi[4] = {{A.buf, 0, VK_WHOLE_SIZE}, {B.buf, 0, VK_WHOLE_SIZE}, {C.buf, 0, VK_WHOLE_SIZE}, {P.buf, 0, VK_WHOLE_SIZE}};
  VkWriteDescriptorSet w[4];
  for (int i = 0; i < 4; ++i)
    w[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, ds, (uint32_t)i, 0, 1, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &dbi[i], NULL};
  vkUpdateDescriptorSets(dev, 4, w, 0, NULL);

  size_t nspv = 0;
  uint32_t* code = (uint32_t*)read_file(spv_path, &nspv);
  if (!code) { fprintf(stderr, "cannot read %s\n", spv_path); return 2; }
  VkShaderModuleCreateInfo smi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, nspv, code};
  VkShaderModule sm;
  CHECK(vkCreateShaderModule(dev, &smi, NULL, &sm));
  VkComputePipelineCreateInfo cpi = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  cpi.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  cpi.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  cpi.stage.module = sm;
  cpi.stage.pName = entry;
  cpi.layout = pl;
  VkPipeline pipe;
  double t0 = now_ms();
  CHECK(vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &cpi, NULL, &pipe));
  printf("pipeline created in %.1f ms\n", now_ms() - t0);

  VkCommandPoolCreateInfo cpo = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL, 0, qfam};
  VkCommandPool pool;
  CHECK(vkCreateCommandPool(dev, &cpo, NULL, &pool));
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, pool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  VkCommandBuffer cmd;
  CHECK(vkAllocateCommandBuffers(dev, &cai, &cmd));
  VkCommandBufferBeginInfo bbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  CHECK(vkBeginCommandBuffer(cmd, &bbi));
  vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pipe);
  vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pl, 0, 1, &ds, 0, NULL);
  vkCmdDispatch(cmd, groups, 1, 1);
  CHECK(vkEndCommandBuffer(cmd));
  VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
  si.commandBufferCount = 1;
  si.pCommandBuffers = &cmd;
  t0 = now_ms();
  CHECK(vkQueueSubmit(q, 1, &si, VK_NULL_HANDLE));
  CHECK(vkQueueWaitIdle(q));
  double ms = now_ms() - t0;

  int64_t bad = 0, first_bad = -1;
  for (int64_t i = 0; i < n; ++i) {
    float c = ((float*)C.map)[i];
    if (!(c == (float)(3 * i))) { if (first_bad < 0) first_bad = i; ++bad; }
  }
  float* c = (float*)C.map;
  printf("n=%lld groups=%u  C[0..3]=%g %g %g %g  C[n-1]=%g  mismatches=%lld (first %lld)  submit+wait %.2f ms\n",
         (long long)n, groups, c[0], c[1], c[2], c[3], c[n - 1], (long long)bad, (long long)first_bad, ms);
  printf(bad ? "FAIL\n" : "PASS\n");
  return bad ? 1 : 0;
}
