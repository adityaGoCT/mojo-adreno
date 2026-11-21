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
//
// Adreno 840 backend (chosen by device in ablas_create, not by cooperative-matrix support): the 840 has no
// matrix unit, so it runs fp16 ALU kernels (ablas_kernels_840.h, tuned by sweep_alu.py) in the TN layout, with
// fp16 multiply-add and accumulate. On the 840 only VK_KHR_push_descriptor, shaderFloat16 and
// storageBuffer16BitAccess are required (cooperative matrices are not used; Mesa Turnip does not offer them).
// It works with Qualcomm's driver and with Mesa Turnip; each has its own tuned kernels (with Turnip built with
// asm/mesa/turnip-ra-bank.patch, each kernel also carries the bank-aware register allocation choice).
#ifndef ABLAS_H
#define ABLAS_H

#include <stddef.h>
#include <stdint.h>
#include <vulkan/vulkan.h>

#ifdef __cplusplus
extern "C" {
#endif

// ABLAS_OP_P: the operand is already in AdrenoBLAS's packed format (ablas_pack_a / ablas_pack_b): 64-row (A) or
// 64-column (B) panels of 16-deep tiles, K contiguous inside each tile, K tiles adjacent. The fastest layout
// (4096^3: 16.5 TFLOP/s vs 9.4 for [K,M]/[K,N]; 2048^3: 14.8 vs 10.8). Pack weights once and pass them as P;
// a PyTorch Linear weight [N,K] packs with a plain copy.
// The packed format is device-specific: on the Adreno 840 it is plain TN (A [K,M], B [K,N]). Pre-packed
// weights are not portable between the 840 and 850 builds; pack them on the device that uses them.
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
// ABLAS_BAD_SHAPE otherwise. On the Adreno 840: M and N multiples of 64, K of 4 (32 when an operand has to be
// transposed, i.e. opA = N or opB = T). The caller synchronizes C with whatever reads it next.
ablas_status ablas_hgemm(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, ablas_op opB, uint32_t M, uint32_t N,
                         uint32_t K, ablas_buf A, ablas_buf B, ablas_buf C, ablas_buf workspace);

// Packs an operand into panel format (dst: M*K*2 or K*N*2 bytes). opA/opB: how the source is stored (N or T).
// Records into cmd; the caller puts a barrier between this and the GEMM that reads dst.
// M, N and K must be multiples of 64. On the Adreno 840 the result is TN (a transpose or a copy; multiples of 32).
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
