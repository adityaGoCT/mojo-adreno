// VK_QCOM_cooperative_matrix_conversion (Vulkan 1.4.342): moves data between a thread's registers and
// a cooperative matrix. Declared here because the NDK's Vulkan headers predate it (extension 173).
// The runners enable it when the driver has it and then prefer kernels from <kernel dir>/qcom/
// (qcom/*.comp, built with glslang); set QCOM_COOPMAT=0 to keep the KHR-only kernels.
#pragma once
#include <stdlib.h>
#include <string.h>
#include <vulkan/vulkan.h>

#define QCOM_CONVERSION_NAME "VK_QCOM_cooperative_matrix_conversion"
#define QCOM_CONVERSION_STYPE ((VkStructureType)1000172000)
typedef struct {
  VkStructureType sType;
  void* pNext;
  VkBool32 cooperativeMatrixConversion;
} QcomConversionFeatures;

static inline int qcom_wanted(void) {
  const char* e = getenv("QCOM_COOPMAT");
  return !e || strcmp(e, "0");
}
