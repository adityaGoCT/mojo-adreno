// Lists whether the Vulkan driver offers VK_KHR_cooperative_matrix, and its supported shapes.
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vulkan/vulkan.h>
int main(void) {
  void* lib = dlopen("libvulkan.so", RTLD_NOW);
  if (!lib) { printf("no libvulkan\n"); return 1; }
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  PFN_vkCreateInstance ci = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "probe", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL, 0, &app};
  VkInstance inst;
  if (ci(&ici, NULL, &inst)) { printf("no instance\n"); return 1; }
  PFN_vkEnumeratePhysicalDevices epd = (PFN_vkEnumeratePhysicalDevices)gipa(inst, "vkEnumeratePhysicalDevices");
  PFN_vkGetPhysicalDeviceProperties gpp = (PFN_vkGetPhysicalDeviceProperties)gipa(inst, "vkGetPhysicalDeviceProperties");
  PFN_vkEnumerateDeviceExtensionProperties edep = (PFN_vkEnumerateDeviceExtensionProperties)gipa(inst, "vkEnumerateDeviceExtensionProperties");
  uint32_t n = 1; VkPhysicalDevice pd; epd(inst, &n, &pd);
  VkPhysicalDeviceProperties p; gpp(pd, &p);
  printf("device: %s, Vulkan %u.%u, driver 0x%x\n", p.deviceName, VK_API_VERSION_MAJOR(p.apiVersion), VK_API_VERSION_MINOR(p.apiVersion), p.driverVersion);
  uint32_t nx = 0; edep(pd, NULL, &nx, NULL);
  VkExtensionProperties* xp = calloc(nx, sizeof *xp); edep(pd, NULL, &nx, xp);
  int found = 0;
  for (uint32_t i = 0; i < nx; ++i)
    if (strstr(xp[i].extensionName, "cooperative") || strstr(xp[i].extensionName, "integer_dot") ||
        strstr(xp[i].extensionName, "shader_float16") || strstr(xp[i].extensionName, "subgroup") ||
        strstr(xp[i].extensionName, "QCOM") || strstr(xp[i].extensionName, "tensor") || strstr(xp[i].extensionName, "matrix"))
      printf("  %s (spec %u)\n", xp[i].extensionName, xp[i].specVersion), found |= !!strstr(xp[i].extensionName, "cooperative_matrix");
  printf("%u extensions; VK_KHR_cooperative_matrix: %s\n", nx, found ? "yes" : "no");
  if (found) {
    PFN_vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR gcm = (PFN_vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR)gipa(inst, "vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR");
    uint32_t np = 0; gcm(pd, &np, NULL);
    VkCooperativeMatrixPropertiesKHR* cp = calloc(np, sizeof *cp);
    for (uint32_t i = 0; i < np; ++i) cp[i].sType = VK_STRUCTURE_TYPE_COOPERATIVE_MATRIX_PROPERTIES_KHR;
    gcm(pd, &np, cp);
    for (uint32_t i = 0; i < np; ++i)
      printf("  M%u N%u K%u  A %d B %d C %d Result %d  scope %d\n", cp[i].MSize, cp[i].NSize, cp[i].KSize, cp[i].AType, cp[i].BType, cp[i].CType, cp[i].ResultType, cp[i].scope);
  }
  return 0;
}
