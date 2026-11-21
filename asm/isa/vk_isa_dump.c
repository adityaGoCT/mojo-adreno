// vk_isa_dump: build one compute pipeline on the stock driver and dump what it exposes about the
// compiled hardware shader: VK_KHR_pipeline_executable_properties (statistics + internal
// representations, e.g. ISA disassembly) and the raw pipeline-cache blob.
//   vk_isa_dump <shader.spv> <out_prefix>
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vulkan/vulkan.h>

#define CK(x) do { VkResult r_ = (x); if (r_) { fprintf(stderr, "%s -> %d\n", #x, r_); return 1; } } while (0)
static PFN_vkGetInstanceProcAddr gipa;
static PFN_vkGetDeviceProcAddr gdpa;
#define I(f) PFN_##f f = (PFN_##f)gipa(inst, #f)
#define D(f) PFN_##f f = (PFN_##f)gdpa(dev, #f)

int main(int argc, char** argv) {
  if (argc < 3) { fprintf(stderr, "usage: %s shader.spv out_prefix\n", argv[0]); return 2; }
  void* lib = dlopen("libvulkan.so", RTLD_NOW);
  gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  PFN_vkCreateInstance vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "isa", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL, 0, &app};
  VkInstance inst;
  CK(vkCreateInstance(&ici, NULL, &inst));
  I(vkEnumeratePhysicalDevices); I(vkCreateDevice); I(vkEnumerateDeviceExtensionProperties); I(vkGetPhysicalDeviceFeatures2);
  gdpa = (PFN_vkGetDeviceProcAddr)gipa(inst, "vkGetDeviceProcAddr");
  uint32_t n = 1; VkPhysicalDevice pd; vkEnumeratePhysicalDevices(inst, &n, &pd);
  uint32_t nx = 0; vkEnumerateDeviceExtensionProperties(pd, NULL, &nx, NULL);
  VkExtensionProperties* xp = calloc(nx, sizeof *xp); vkEnumerateDeviceExtensionProperties(pd, NULL, &nx, xp);
  int has_exec = 0, has_cm = 0;
  for (uint32_t i = 0; i < nx; ++i) {
    if (!strcmp(xp[i].extensionName, "VK_KHR_pipeline_executable_properties")) has_exec = 1;
    if (!strcmp(xp[i].extensionName, "VK_KHR_cooperative_matrix")) has_cm = 1;
  }
  printf("VK_KHR_pipeline_executable_properties: %s\n", has_exec ? "yes" : "no");
  VkPhysicalDevicePipelineExecutablePropertiesFeaturesKHR pe = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_EXECUTABLE_PROPERTIES_FEATURES_KHR};
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR, &pe};
  VkPhysicalDeviceVulkan13Features v13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES, &cm};
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &v13};
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  vkGetPhysicalDeviceFeatures2(pd, &f2);
  printf("pipelineExecutableInfo feature: %u\n", pe.pipelineExecutableInfo);
  float prio = 1;
  VkDeviceQueueCreateInfo q = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, 0, 1, &prio};
  const char* exts[2]; uint32_t ne = 0;
  if (has_exec) exts[ne++] = "VK_KHR_pipeline_executable_properties";
  if (has_cm) exts[ne++] = "VK_KHR_cooperative_matrix";
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &f2, 0, 1, &q, 0, NULL, ne, exts};
  VkDevice dev;
  CK(vkCreateDevice(pd, &dci, NULL, &dev));
  D(vkCreateShaderModule); D(vkCreateDescriptorSetLayout); D(vkCreatePipelineLayout); D(vkCreateComputePipelines);
  D(vkCreatePipelineCache); D(vkGetPipelineCacheData);
  FILE* f = fopen(argv[1], "rb"); fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
  void* code = malloc(sz); fread(code, 1, sz, f); fclose(f);
  VkShaderModuleCreateInfo smi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, (size_t)sz, code};
  VkShaderModule sm; CK(vkCreateShaderModule(dev, &smi, NULL, &sm));
  VkDescriptorSetLayoutBinding b[5];
  for (int i = 0; i < 5; ++i) b[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, 5, b};
  VkDescriptorSetLayout dsl; CK(vkCreateDescriptorSetLayout(dev, &dli, NULL, &dsl));
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &dsl};
  VkPipelineLayout pl; CK(vkCreatePipelineLayout(dev, &pli, NULL, &pl));
  VkPipelineCacheCreateInfo pci = {VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO};
  VkPipelineCache cache; CK(vkCreatePipelineCache(dev, &pci, NULL, &cache));
  VkComputePipelineCreateInfo ci = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  if (pe.pipelineExecutableInfo)
    ci.flags = VK_PIPELINE_CREATE_CAPTURE_STATISTICS_BIT_KHR | VK_PIPELINE_CREATE_CAPTURE_INTERNAL_REPRESENTATIONS_BIT_KHR;
  ci.stage = (VkPipelineShaderStageCreateInfo){VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO, NULL, 0, VK_SHADER_STAGE_COMPUTE_BIT, sm, "main"};
  ci.layout = pl;
  VkPipeline p; CK(vkCreateComputePipelines(dev, cache, 1, &ci, NULL, &p));
  char path[512];
  size_t cs = 0; vkGetPipelineCacheData(dev, cache, &cs, NULL);
  void* cd = malloc(cs); vkGetPipelineCacheData(dev, cache, &cs, cd);
  snprintf(path, sizeof path, "%s.cache.bin", argv[2]); f = fopen(path, "wb"); fwrite(cd, 1, cs, f); fclose(f);
  printf("pipeline cache: %zu bytes -> %s\n", cs, path);
  if (!pe.pipelineExecutableInfo) return 0;
  D(vkGetPipelineExecutablePropertiesKHR); D(vkGetPipelineExecutableStatisticsKHR); D(vkGetPipelineExecutableInternalRepresentationsKHR);
  VkPipelineInfoKHR pi = {VK_STRUCTURE_TYPE_PIPELINE_INFO_KHR, NULL, p};
  uint32_t nexe = 0; vkGetPipelineExecutablePropertiesKHR(dev, &pi, &nexe, NULL);
  VkPipelineExecutablePropertiesKHR* ep = calloc(nexe, sizeof *ep);
  for (uint32_t i = 0; i < nexe; ++i) ep[i].sType = VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_PROPERTIES_KHR;
  vkGetPipelineExecutablePropertiesKHR(dev, &pi, &nexe, ep);
  for (uint32_t e = 0; e < nexe; ++e) {
    printf("executable %u: %s | %s | subgroup %u\n", e, ep[e].name, ep[e].description, ep[e].subgroupSize);
    VkPipelineExecutableInfoKHR ei = {VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_INFO_KHR, NULL, p, e};
    uint32_t ns = 0; vkGetPipelineExecutableStatisticsKHR(dev, &ei, &ns, NULL);
    VkPipelineExecutableStatisticKHR* st = calloc(ns, sizeof *st);
    for (uint32_t i = 0; i < ns; ++i) st[i].sType = VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_STATISTIC_KHR;
    vkGetPipelineExecutableStatisticsKHR(dev, &ei, &ns, st);
    for (uint32_t i = 0; i < ns; ++i) {
      printf("  stat %-32s = ", st[i].name);
      switch (st[i].format) {
        case VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_BOOL32_KHR: printf("%u", st[i].value.b32); break;
        case VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_INT64_KHR: printf("%lld", (long long)st[i].value.i64); break;
        case VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_UINT64_KHR: printf("%llu", (unsigned long long)st[i].value.u64); break;
        default: printf("%f", st[i].value.f64);
      }
      printf("   (%s)\n", st[i].description);
    }
    uint32_t nr = 0; vkGetPipelineExecutableInternalRepresentationsKHR(dev, &ei, &nr, NULL);
    VkPipelineExecutableInternalRepresentationKHR* ir = calloc(nr, sizeof *ir);
    for (uint32_t i = 0; i < nr; ++i) ir[i].sType = VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_INTERNAL_REPRESENTATION_KHR;
    vkGetPipelineExecutableInternalRepresentationsKHR(dev, &ei, &nr, ir);
    for (uint32_t i = 0; i < nr; ++i) ir[i].pData = calloc(1, ir[i].dataSize + 1);
    vkGetPipelineExecutableInternalRepresentationsKHR(dev, &ei, &nr, ir);
    for (uint32_t i = 0; i < nr; ++i) {
      snprintf(path, sizeof path, "%s.exe%u.ir%u.%s", argv[2], e, i, ir[i].isText ? "txt" : "bin");
      f = fopen(path, "wb"); fwrite(ir[i].pData, 1, ir[i].dataSize, f); fclose(f);
      printf("  internal representation %u: %s | %s | %zu bytes (%s) -> %s\n", i, ir[i].name, ir[i].description,
             ir[i].dataSize, ir[i].isText ? "text" : "binary", path);
    }
  }
  return 0;
}
