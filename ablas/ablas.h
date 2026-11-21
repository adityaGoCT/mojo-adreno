// AdrenoBLAS: GEMM for Adreno GPUs on Vulkan cooperative matrices (VK_KHR_cooperative_matrix).
//
// Row-major convention (as in PyTorch): C[M,N] = A[M,K] * B[K,N], fp16 in and out.
//   opA = ABLAS_OP_N: A stored [M,K]      opA = ABLAS_OP_T: A stored [K,M] (A transposed)
//   opB = ABLAS_OP_N: B stored [K,N]      opB = ABLAS_OP_T: B stored [N,K] (a PyTorch Linear weight)
// The Adreno 850 is fastest with both operands K-major (opA = T, opB = N): pack weights that way once.
//
// The application owns the VkDevice. It must enable VK_KHR_push_descriptor and VK_KHR_cooperative_matrix,
// and the features shaderFloat16, storageBuffer16BitAccess, vulkanMemoryModel and cooperativeMatrix.
// Kernels are compiled on first use for each shape and kept for the life of the handle.
#ifndef ABLAS_H
#define ABLAS_H

#include <stddef.h>
#include <stdint.h>
#include <vulkan/vulkan.h>

#ifdef __cplusplus
extern "C" {
#endif

// ABLAS_OP_P: the operand is already in AdrenoBLAS panel format (ablas_pack_a / ablas_pack_b): the fastest
// layout for big GEMMs (4096^3: 12.5 TFLOP/s vs 9.4 for [K,M]/[K,N]). Pack weights once and pass them as P.
typedef enum { ABLAS_OP_N = 0, ABLAS_OP_T = 1, ABLAS_OP_P = 2 } ablas_op;
typedef enum { ABLAS_OK = 0, ABLAS_UNSUPPORTED = 1, ABLAS_VK_ERROR = 2, ABLAS_BAD_SHAPE = 3 } ablas_status;

typedef struct ablas_ctx* ablas_handle;
typedef struct {
  VkBuffer buffer;
  VkDeviceSize offset;  // multiple of 16 bytes
} ablas_buf;

// gipa + inst resolve every Vulkan entry point the library uses (the application's loader).
ablas_status ablas_create(ablas_handle* h, VkPhysicalDevice pd, VkDevice dev, PFN_vkGetInstanceProcAddr gipa,
                          VkInstance inst);
void ablas_destroy(ablas_handle h);

// Bytes of workspace ablas_hgemm needs for this call (0 for most layouts).
size_t ablas_hgemm_workspace_size(ablas_op opA, ablas_op opB, uint32_t M, uint32_t N, uint32_t K);

// Records C = op(A) op(B) into cmd (no submit). Shapes must be multiples of 64 (M), 32 (N) and 32 (K);
// ABLAS_BAD_SHAPE otherwise. The caller synchronizes C with whatever reads it next.
ablas_status ablas_hgemm(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, ablas_op opB, uint32_t M, uint32_t N,
                         uint32_t K, ablas_buf A, ablas_buf B, ablas_buf C, ablas_buf workspace);

// Packs an operand into panel format (dst: M*K*2 or K*N*2 bytes). opA/opB: how the source is stored (N or T).
// Records into cmd; the caller puts a barrier between this and the GEMM that reads dst.
// M % 64, N % 32, K % 16; sources that are not K-major (A stored [M,K], B stored [N,K]) need multiples of 64.
ablas_status ablas_pack_a(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, uint32_t M, uint32_t K, ablas_buf A,
                          ablas_buf dst);
ablas_status ablas_pack_b(ablas_handle h, VkCommandBuffer cmd, ablas_op opB, uint32_t K, uint32_t N, ablas_buf B,
                          ablas_buf dst);

// 1 (default): transpose operands into the fastest layout (A [K,M], B [K,N]) in the workspace: B whenever it is
// stored [N,K], A when the GEMM is big (>= 2^31 multiply-adds); from 2^35 multiply-adds both go to panels.
// 2: always pack. 0: run layout-specific kernels directly (NT still packs B).
void ablas_set_pack(ablas_handle h, int pack_to_tn);

// Name of the kernel the last ablas_hgemm call used (for logs and benchmarks).
const char* ablas_last_kernel(ablas_handle h);

#ifdef __cplusplus
}
#endif
#endif
