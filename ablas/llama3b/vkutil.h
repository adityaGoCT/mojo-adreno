// Minimal Vulkan compute helpers for the Llama 3.2 3B benchmark and the kernel runner (vkrun).
// One device, one queue, host-visible coherent buffers (the Adreno's memory is unified), push descriptors
// and push constants, GPU timestamps.
#pragma once
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <vulkan/vulkan.h>

#define CK(x) do { VkResult r_ = (x); if (r_) { fprintf(stderr, "%s:%d %s -> %d\n", __FILE__, __LINE__, #x, r_); exit(1); } } while (0)

#define VK_FUNCS(X)                                                                                         \
  X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties)                        \
  X(vkGetPhysicalDeviceMemoryProperties) X(vkCreateDevice) X(vkGetDeviceProcAddr)                           \
  X(vkEnumerateDeviceExtensionProperties) X(vkGetPhysicalDeviceProperties2)
#define VK_DFUNCS(X)                                                                                        \
  X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkGetBufferMemoryRequirements) X(vkAllocateMemory)                \
  X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateCommandPool) X(vkAllocateCommandBuffers)                   \
  X(vkBeginCommandBuffer) X(vkEndCommandBuffer) X(vkResetCommandBuffer) X(vkQueueSubmit) X(vkQueueWaitIdle) \
  X(vkCreateQueryPool) X(vkCmdResetQueryPool) X(vkCmdWriteTimestamp) X(vkGetQueryPoolResults)               \
  X(vkCmdPipelineBarrier) X(vkCreateShaderModule) X(vkDestroyShaderModule) X(vkCreateComputePipelines)      \
  X(vkCreateDescriptorSetLayout) X(vkCreatePipelineLayout) X(vkCmdBindPipeline) X(vkCmdDispatch)            \
  X(vkCmdPushConstants) X(vkCmdPushDescriptorSetKHR) X(vkDestroyBuffer) X(vkFreeMemory)                     \
  X(vkCreateFence) X(vkWaitForFences) X(vkResetFences)
#define VKFN(f) static PFN_##f f;
VK_FUNCS(VKFN)
VK_DFUNCS(VKFN)

typedef struct {
  PFN_vkGetInstanceProcAddr gipa;
  VkInstance inst;
  VkPhysicalDevice pd;
  VkDevice dev;
  VkQueue queue;
  VkCommandPool pool;
  VkQueryPool qp;
  uint32_t nq;
  double ts_ns;  // ns per timestamp tick
  VkPhysicalDeviceMemoryProperties mem;
  VkDescriptorSetLayout dsl;
  VkPipelineLayout layout;  // NBIND storage buffers (push descriptors) + 64 bytes of push constants
  char name[256];
  int bda;  // VK_ALL_FEATURES: bufferDeviceAddress on
} vk_t;

#define NBIND 8

typedef struct { VkBuffer buf; VkDeviceMemory mem; void* map; size_t size; } vbuf_t;

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec * 1e-6;
}

static void vk_init(vk_t* v, uint32_t nqueries) {
  void* lib = dlopen("libvulkan.so", RTLD_NOW);
  v->gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)v->gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "llama3b", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL, 0, &app};
  CK(vkCreateInstance(&ici, NULL, &v->inst));
#define LOADI(f) f = (PFN_##f)v->gipa(v->inst, #f);
  VK_FUNCS(LOADI)
  uint32_t n = 1;
  vkEnumeratePhysicalDevices(v->inst, &n, &v->pd);
  VkPhysicalDeviceProperties props;
  vkGetPhysicalDeviceProperties(v->pd, &props);
  snprintf(v->name, sizeof v->name, "%s", props.deviceName);
  v->ts_ns = props.limits.timestampPeriod;
  vkGetPhysicalDeviceMemoryProperties(v->pd, &v->mem);
  float prio = 1;
  VkDeviceQueueCreateInfo q = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, 0, 1, &prio};
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  cm.cooperativeMatrix = VK_TRUE;
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &cm};
  v12.shaderFloat16 = v12.vulkanMemoryModel = v12.vulkanMemoryModelDeviceScope = VK_TRUE;
  v12.storageBuffer8BitAccess = v12.shaderInt8 = VK_TRUE;
  VkPhysicalDeviceVulkan13Features v13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES};
  if (getenv("VK_SUBGROUP_SIZE_CONTROL")) {  // test: what llama.cpp's Vulkan backend enables
    v13.subgroupSizeControl = v13.computeFullSubgroups = VK_TRUE;
    cm.pNext = &v13;
  }
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  v11.storageBuffer16BitAccess = VK_TRUE;
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  f2.features.shaderInt16 = VK_TRUE;
  if (getenv("VK_ALL_FEATURES")) {  // test: every supported core feature on, as llama.cpp's Vulkan backend does
    VkPhysicalDeviceCooperativeMatrixFeaturesKHR qcm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
    v13 = (VkPhysicalDeviceVulkan13Features){VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES, &qcm};
    v12 = (VkPhysicalDeviceVulkan12Features){VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &v13};
    v11 = (VkPhysicalDeviceVulkan11Features){VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
    f2 = (VkPhysicalDeviceFeatures2){VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
    ((PFN_vkGetPhysicalDeviceFeatures2)v->gipa(v->inst, "vkGetPhysicalDeviceFeatures2"))(v->pd, &f2);
    cm = qcm;
    v->bda = v12.bufferDeviceAddress;
    fprintf(stderr, "all features: robustBufferAccess %d bufferDeviceAddress %d descriptorIndexing %d\n",
            f2.features.robustBufferAccess, v12.bufferDeviceAddress, v12.descriptorIndexing);
  }
  const char* exts[] = {"VK_KHR_push_descriptor", "VK_KHR_cooperative_matrix"};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &f2, 0, 1, &q, 0, NULL, 2, exts};
  CK(vkCreateDevice(v->pd, &dci, NULL, &v->dev));
#define LOADD(f) f = (PFN_##f)vkGetDeviceProcAddr(v->dev, #f);
  VK_DFUNCS(LOADD)
  vkGetDeviceQueue(v->dev, 0, 0, &v->queue);
  VkCommandPoolCreateInfo cpi = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL,
                                 VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, 0};
  CK(vkCreateCommandPool(v->dev, &cpi, NULL, &v->pool));
  v->nq = nqueries;
  VkQueryPoolCreateInfo qpi = {VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO, NULL, 0, VK_QUERY_TYPE_TIMESTAMP, nqueries};
  CK(vkCreateQueryPool(v->dev, &qpi, NULL, &v->qp));
  VkDescriptorSetLayoutBinding b[NBIND];
  for (uint32_t i = 0; i < NBIND; ++i)
    b[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL,
                                         VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR, NBIND, b};
  CK(vkCreateDescriptorSetLayout(v->dev, &dli, NULL, &v->dsl));
  VkPushConstantRange pcr = {VK_SHADER_STAGE_COMPUTE_BIT, 0, 64};
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &v->dsl, 1, &pcr};
  CK(vkCreatePipelineLayout(v->dev, &pli, NULL, &v->layout));
}

static vbuf_t vk_buffer(vk_t* v, size_t size) {
  vbuf_t b = {0};
  b.size = size;
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size ? size : 16;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
  CK(vkCreateBuffer(v->dev, &bi, NULL, &b.buf));
  VkMemoryRequirements mr;
  vkGetBufferMemoryRequirements(v->dev, b.buf, &mr);
  uint32_t want = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, type = 0;
  for (uint32_t i = 0; i < v->mem.memoryTypeCount; ++i)
    if ((mr.memoryTypeBits >> i & 1) && (v->mem.memoryTypes[i].propertyFlags & want) == want) { type = i; break; }
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, NULL, mr.size, type};
  CK(vkAllocateMemory(v->dev, &ai, NULL, &b.mem));
  CK(vkBindBufferMemory(v->dev, b.buf, b.mem, 0));
  CK(vkMapMemory(v->dev, b.mem, 0, VK_WHOLE_SIZE, 0, &b.map));
  return b;
}

static void vk_free(vk_t* v, vbuf_t* b) {
  if (!b->buf) return;
  vkDestroyBuffer(v->dev, b->buf, NULL);
  vkFreeMemory(v->dev, b->mem, NULL);
  memset(b, 0, sizeof *b);
}

static VkPipeline vk_pipeline(vk_t* v, const uint32_t* spv, size_t bytes) {
  VkShaderModuleCreateInfo mi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, bytes, spv};
  VkShaderModule mod;
  CK(vkCreateShaderModule(v->dev, &mi, NULL, &mod));
  VkComputePipelineCreateInfo ci = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  ci.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  ci.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  ci.stage.module = mod;
  ci.stage.pName = "main";
  ci.layout = v->layout;
  VkPipeline p;
  CK(vkCreateComputePipelines(v->dev, VK_NULL_HANDLE, 1, &ci, NULL, &p));
  vkDestroyShaderModule(v->dev, mod, NULL);
  return p;
}

static void* read_file(const char* path, size_t* size) {
  FILE* f = fopen(path, "rb");
  if (!f) { fprintf(stderr, "cannot open %s\n", path); exit(1); }
  fseek(f, 0, SEEK_END);
  *size = ftell(f);
  fseek(f, 0, SEEK_SET);
  void* p = malloc(*size ? *size : 1);
  if (fread(p, 1, *size, f) != *size) { fprintf(stderr, "short read %s\n", path); exit(1); }
  fclose(f);
  return p;
}

static VkPipeline vk_pipeline_file(vk_t* v, const char* path) {
  size_t n;
  uint32_t* w = read_file(path, &n);
  VkPipeline p = vk_pipeline(v, w, n);
  free(w);
  return p;
}

// Binds nb buffers (slots 0..nb-1; a NULL buffer is skipped) + push constants, dispatches.
static void vk_dispatch(vk_t* v, VkCommandBuffer cmd, VkPipeline p, const VkDescriptorBufferInfo* bufs, int nb,
                        const void* pc, uint32_t pcbytes, uint32_t gx, uint32_t gy, uint32_t gz) {
  vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  VkWriteDescriptorSet w[NBIND];
  int n = 0;
  for (int i = 0; i < nb; ++i) {
    if (!bufs[i].buffer) continue;
    w[n++] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, VK_NULL_HANDLE, (uint32_t)i, 0, 1,
                                    VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bufs[i], NULL};
  }
  vkCmdPushDescriptorSetKHR(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, v->layout, 0, n, w);
  if (pcbytes) vkCmdPushConstants(cmd, v->layout, VK_SHADER_STAGE_COMPUTE_BIT, 0, pcbytes, pc);
  vkCmdDispatch(cmd, gx, gy, gz);
}

static void vk_barrier(VkCommandBuffer cmd) {
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT};
  vkCmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &mb, 0,
                       NULL, 0, NULL);
}

static VkCommandBuffer vk_cmd(vk_t* v) {
  VkCommandBufferAllocateInfo ai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, v->pool,
                                    VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  VkCommandBuffer c;
  CK(vkAllocateCommandBuffers(v->dev, &ai, &c));
  return c;
}

static void vk_begin(VkCommandBuffer c) {
  VkCommandBufferBeginInfo bi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  CK(vkResetCommandBuffer(c, 0));
  CK(vkBeginCommandBuffer(c, &bi));
}

static void vk_submit_wait(vk_t* v, VkCommandBuffer c) {
  VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO, NULL, 0, NULL, NULL, 1, &c};
  CK(vkQueueSubmit(v->queue, 1, &si, VK_NULL_HANDLE));
  CK(vkQueueWaitIdle(v->queue));
}
