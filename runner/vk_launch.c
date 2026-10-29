// Generic Vulkan compute launcher for the phone: runs one kernel from Mojo's Vulkan SPIR-V target
// as a launch spec describes it, and writes chosen buffers back to files.
//
//   vk_launch <dir>
//
// <dir>/kernel.spv is the module (entry point "main"); <dir>/launch.txt holds, one per line:
//   groups X Y Z               workgroups to dispatch
//   block X Y Z                block size: specialization constants 0, 1, 2 (a kernel compiled
//                              without MOJO_SPIRV_LOCAL_SIZE takes its workgroup size from them)
//   buffer BINDING BYTES INIT  a storage buffer at (set 0, BINDING); INIT is "zero", "nan" (0xFF
//                              bytes) or a file name in <dir> with the initial contents
//   out BINDING FILE           after the run, write the buffer to <dir>/FILE
//   reps N                     timed dispatches (default 1)
//   subgroup N                 require subgroup size N (cooperative matrices on the Adreno 840 need 64)
// Loads libvulkan.so with dlopen, so LD_LIBRARY_PATH can select Mesa Turnip.
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
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
  X(vkQueueSubmit) X(vkQueueWaitIdle) X(vkGetPhysicalDeviceFeatures2)                    \
  X(vkEnumerateDeviceExtensionProperties)

#define DECL(f) static PFN_##f f;
VK_FUNCS(DECL)

static VkDevice dev;
static VkPhysicalDeviceMemoryProperties memprops;

typedef struct { VkBuffer buf; VkDeviceMemory mem; void* map; size_t size; } buf_t;

static buf_t make_buffer(size_t size) {
  buf_t b = {0};
  b.size = size;
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
  void* p = malloc(*n ? *n : 1);
  if (fread(p, 1, *n, f) != *n) { free(p); p = NULL; }
  fclose(f);
  return p;
}

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

static int cmp_double(const void* a, const void* b) {
  double x = *(const double*)a, y = *(const double*)b;
  return x < y ? -1 : x > y;
}

#define MAX_BINDINGS 64

int main(int argc, char** argv) {
  if (argc < 2) { fprintf(stderr, "usage: %s <launch dir>\n", argv[0]); return 2; }
  const char* dir = argv[1];
  char path[1024];

  uint32_t groups[3] = {1, 1, 1}, block[3] = {0, 0, 0};
  int nbuf = 0, nout = 0, nrep = 1;
  uint32_t subgroup = 0;
  struct { uint32_t binding; size_t bytes; char init[256]; } bufs[MAX_BINDINGS];
  struct { uint32_t binding; char file[256]; } outs[MAX_BINDINGS];
  snprintf(path, sizeof path, "%s/launch.txt", dir);
  FILE* spec = fopen(path, "r");
  if (!spec) { fprintf(stderr, "cannot read %s\n", path); return 2; }
  char line[512];
  while (fgets(line, sizeof line, spec)) {
    unsigned long long bytes;
    if (sscanf(line, "groups %u %u %u", &groups[0], &groups[1], &groups[2]) == 3) continue;
    if (sscanf(line, "block %u %u %u", &block[0], &block[1], &block[2]) == 3) continue;
    if (sscanf(line, "reps %d", &nrep) == 1) continue;
    if (sscanf(line, "subgroup %u", &subgroup) == 1) continue;
    if (nbuf < MAX_BINDINGS &&
        sscanf(line, "buffer %u %llu %255s", &bufs[nbuf].binding, &bytes, bufs[nbuf].init) == 3) {
      bufs[nbuf++].bytes = (size_t)bytes;
      continue;
    }
    if (nout < MAX_BINDINGS && sscanf(line, "out %u %255s", &outs[nout].binding, outs[nout].file) == 2) {
      ++nout;
      continue;
    }
    if (line[0] != '\n' && line[0] != '#') { fprintf(stderr, "bad launch line: %s", line); return 2; }
  }
  fclose(spec);
  if (nrep < 1) nrep = 1;

  void* lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) { fprintf(stderr, "dlopen libvulkan.so: %s\n", dlerror()); return 2; }
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "vk_launch", 1, NULL, 0, VK_API_VERSION_1_3};
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
  printf("device: %s  Vulkan %u.%u\n", props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion),
         VK_API_VERSION_MINOR(props.apiVersion));

  uint32_t nq = 0;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, NULL);
  VkQueueFamilyProperties qf[16];
  if (nq > 16) nq = 16;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, qf);
  uint32_t qfam = 0;
  for (uint32_t i = 0; i < nq; ++i) if (qf[i].queueFlags & VK_QUEUE_COMPUTE_BIT) { qfam = i; break; }

  // Enable what LLVM-generated SPIR-V may declare (Int8, Int16, Int64, 8- and 16-bit storage), and
  // for cooperative matrices the extension, the Vulkan memory model and subgroup size control.
  uint32_t next = 0;
  CHECK(vkEnumerateDeviceExtensionProperties(pd, NULL, &next, NULL));
  VkExtensionProperties* exts = calloc(next ? next : 1, sizeof *exts);
  CHECK(vkEnumerateDeviceExtensionProperties(pd, NULL, &next, exts));
  int coopmat = 0;
  for (uint32_t i = 0; i < next; ++i) coopmat |= !strcmp(exts[i].extensionName, VK_KHR_COOPERATIVE_MATRIX_EXTENSION_NAME);
  free(exts);
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  VkPhysicalDeviceVulkan13Features v13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES, coopmat ? &cm : NULL};
  int v13ok = props.apiVersion >= VK_API_VERSION_1_3;
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, v13ok ? &v13 : NULL};
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  vkGetPhysicalDeviceFeatures2(pd, &f2);
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR encm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  encm.cooperativeMatrix = cm.cooperativeMatrix;
  VkPhysicalDeviceVulkan13Features en13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES, coopmat ? &encm : NULL};
  en13.subgroupSizeControl = v13.subgroupSizeControl;
  en13.computeFullSubgroups = v13.computeFullSubgroups;
  VkPhysicalDeviceVulkan12Features en12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, v13ok ? &en13 : NULL};
  en12.shaderInt8 = v12.shaderInt8;
  en12.shaderFloat16 = v12.shaderFloat16;
  en12.storageBuffer8BitAccess = v12.storageBuffer8BitAccess;
  en12.vulkanMemoryModel = v12.vulkanMemoryModel;
  en12.vulkanMemoryModelDeviceScope = v12.vulkanMemoryModelDeviceScope;
  VkPhysicalDeviceVulkan11Features en11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &en12};
  en11.storageBuffer16BitAccess = v11.storageBuffer16BitAccess;
  VkPhysicalDeviceFeatures2 en = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &en11};
  en.features.shaderInt64 = f2.features.shaderInt64;
  en.features.shaderInt16 = f2.features.shaderInt16;
  float prio = 1.0f;
  VkDeviceQueueCreateInfo qci = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, qfam, 1, &prio};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &en};
  dci.queueCreateInfoCount = 1;
  dci.pQueueCreateInfos = &qci;
  const char* cm_ext = VK_KHR_COOPERATIVE_MATRIX_EXTENSION_NAME;
  if (coopmat && cm.cooperativeMatrix) {
    dci.enabledExtensionCount = 1;
    dci.ppEnabledExtensionNames = &cm_ext;
  }
  printf("cooperative matrices: %s, Vulkan memory model: %s\n", coopmat && cm.cooperativeMatrix ? "on" : "off",
         v12.vulkanMemoryModel ? "on" : "off");
  CHECK(vkCreateDevice(pd, &dci, NULL, &dev));
  VkQueue q;
  vkGetDeviceQueue(dev, qfam, 0, &q);

  buf_t b[MAX_BINDINGS];
  VkDescriptorSetLayoutBinding binds[MAX_BINDINGS];
  VkDescriptorBufferInfo dbi[MAX_BINDINGS];
  for (int i = 0; i < nbuf; ++i) {
    size_t bytes = bufs[i].bytes ? bufs[i].bytes : 4;
    b[i] = make_buffer(bytes);
    if (!strcmp(bufs[i].init, "zero")) {
      memset(b[i].map, 0, bytes);
    } else if (!strcmp(bufs[i].init, "nan")) {
      memset(b[i].map, 0xFF, bytes);
    } else {
      size_t n = 0;
      snprintf(path, sizeof path, "%s/%s", dir, bufs[i].init);
      void* data = read_file(path, &n);
      if (!data || n > bytes) { fprintf(stderr, "bad init file %s\n", path); return 2; }
      memset(b[i].map, 0, bytes);
      memcpy(b[i].map, data, n);
      free(data);
    }
    binds[i] = (VkDescriptorSetLayoutBinding){bufs[i].binding, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1,
                                              VK_SHADER_STAGE_COMPUTE_BIT, NULL};
    dbi[i] = (VkDescriptorBufferInfo){b[i].buf, 0, VK_WHOLE_SIZE};
  }
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0,
                                         (uint32_t)nbuf, binds};
  VkDescriptorSetLayout dsl;
  CHECK(vkCreateDescriptorSetLayout(dev, &dli, NULL, &dsl));
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &dsl};
  VkPipelineLayout pl;
  CHECK(vkCreatePipelineLayout(dev, &pli, NULL, &pl));
  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, (uint32_t)(nbuf ? nbuf : 1)};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1, 1, &ps};
  VkDescriptorPool dp;
  CHECK(vkCreateDescriptorPool(dev, &dpi, NULL, &dp));
  VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, dp, 1, &dsl};
  VkDescriptorSet ds;
  CHECK(vkAllocateDescriptorSets(dev, &dai, &ds));
  VkWriteDescriptorSet w[MAX_BINDINGS];
  for (int i = 0; i < nbuf; ++i)
    w[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, ds, bufs[i].binding, 0, 1,
                                  VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &dbi[i], NULL};
  vkUpdateDescriptorSets(dev, (uint32_t)nbuf, w, 0, NULL);

  size_t nspv = 0;
  snprintf(path, sizeof path, "%s/kernel.spv", dir);
  uint32_t* code = (uint32_t*)read_file(path, &nspv);
  if (!code) { fprintf(stderr, "cannot read %s\n", path); return 2; }
  VkShaderModuleCreateInfo smi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, nspv, code};
  VkShaderModule sm;
  CHECK(vkCreateShaderModule(dev, &smi, NULL, &sm));
  // The block size as specialization constants 0-2 (ignored by a module that has none).
  VkSpecializationMapEntry entries[3] = {{0, 0, 4}, {1, 4, 4}, {2, 8, 4}};
  VkSpecializationInfo spec_info = {3, entries, sizeof block, block};
  VkComputePipelineCreateInfo cpi = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  cpi.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  cpi.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  cpi.stage.module = sm;
  cpi.stage.pName = "main";
  if (block[0]) cpi.stage.pSpecializationInfo = &spec_info;
  VkPipelineShaderStageRequiredSubgroupSizeCreateInfo rss = {
      VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO, NULL, subgroup};
  if (subgroup) {
    if (!en13.subgroupSizeControl) { fprintf(stderr, "subgroup %u: no subgroup size control\n", subgroup); return 2; }
    cpi.stage.pNext = &rss;
    if (en13.computeFullSubgroups) cpi.stage.flags = VK_PIPELINE_SHADER_STAGE_CREATE_REQUIRE_FULL_SUBGROUPS_BIT;
  }
  cpi.layout = pl;
  VkPipeline pipe;
  CHECK(vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &cpi, NULL, &pipe));

  VkCommandPoolCreateInfo cpo = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL, 0, qfam};
  VkCommandPool pool;
  CHECK(vkCreateCommandPool(dev, &cpo, NULL, &pool));
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, pool,
                                     VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  VkCommandBuffer cmd;
  CHECK(vkAllocateCommandBuffers(dev, &cai, &cmd));
  VkCommandBufferBeginInfo bbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  CHECK(vkBeginCommandBuffer(cmd, &bbi));
  vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pipe);
  vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pl, 0, 1, &ds, 0, NULL);
  vkCmdDispatch(cmd, groups[0], groups[1], groups[2]);
  CHECK(vkEndCommandBuffer(cmd));
  VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
  si.commandBufferCount = 1;
  si.pCommandBuffers = &cmd;

  // The outputs come from the first run: later runs would see their own results as inputs.
  double* ms = malloc(nrep * sizeof *ms);
  for (int r = 0; r < nrep; ++r) {
    double t0 = now_ms();
    CHECK(vkQueueSubmit(q, 1, &si, VK_NULL_HANDLE));
    CHECK(vkQueueWaitIdle(q));
    ms[r] = now_ms() - t0;
    if (r == 0)
      for (int o = 0; o < nout; ++o) {
        int i = 0;
        while (i < nbuf && bufs[i].binding != outs[o].binding) ++i;
        if (i == nbuf) { fprintf(stderr, "out: no buffer at binding %u\n", outs[o].binding); return 2; }
        snprintf(path, sizeof path, "%s/%s", dir, outs[o].file);
        FILE* f = fopen(path, "wb");
        if (!f || fwrite(b[i].map, 1, b[i].size, f) != b[i].size) { fprintf(stderr, "cannot write %s\n", path); return 2; }
        fclose(f);
      }
  }
  qsort(ms, nrep, sizeof *ms, cmp_double);
  printf("groups %u %u %u  block %u %u %u  submit+wait %.3f ms (best of %d, median %.3f ms)\n", groups[0], groups[1],
         groups[2], block[0], block[1], block[2], ms[0], nrep, ms[nrep / 2]);
  return 0;
}
