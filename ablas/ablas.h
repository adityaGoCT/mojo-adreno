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
  VkDeviceSize range;   // bytes bound from offset; 0 = to the end of the buffer (keep it <= maxStorageBufferRange)
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

// Q4_0 weights. C[M,N] = op(A)[M,K] * dequant(W)^T for a weight W [N,K] quantized in ggml's Q4_0 (blocks of 32
// along K, value = (q - 8) * d, fp16 d), in AdrenoBLAS's layout: per 64-column panel and 32-deep K block, the
// 4-bit values of each column as 2 x 8 bytes, then all scales (ablas_q4_0_size bytes). The kernels dequantize in
// registers into the matrix unit's B operand (Adreno 850). Build the layout on the host with ablas_q4_0_from_ggml
// (from ggml block_q4_0 rows, e.g. a GGUF tensor) or ablas/q4ref.py. opA: N (A [M,K] row-major, packed into
// ws: M*K*2 bytes) or P (already packed with ablas_pack_a). M, N multiples of 64; K of 64 (N) or 32 (P).
// fp16 out, fp16 accumulation. Not available on the Adreno 840 backend (ABLAS_UNSUPPORTED).
size_t ablas_q4_0_size(uint32_t N, uint32_t K);
void ablas_q4_0_from_ggml(const void* blocks, uint32_t N, uint32_t K, void* dst);
ablas_status ablas_hgemm_q4_0(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, uint32_t M, uint32_t N, uint32_t K,
                              ablas_buf A, ablas_buf W, ablas_buf C, ablas_buf workspace);

// Fused epilogues (Adreno 850 cooperative-matrix backend). The accumulator is staged through shared memory and
// written straight into the format the next operation wants:
//   ABLAS_EPI_PACKED  C written in the packed A format of an [M, N] matrix (ablas_pack_a's output), so it can be
//                     the next GEMM's A with ABLAS_OP_P (no pack pass). N multiple of 64.
//   ABLAS_EPI_SWIGLU  for a gated MLP: B's columns come in 64-column groups [32 gate | 32 up] (interleave the gate
//                     and up weights 32 rows at a time); C receives silu(gate) * up, an [M, N/2] matrix in the
//                     packed A format (the down projection's A operand). fp32 math, fp16 out.
//   ABLAS_EPI_RESIDUAL_RMS  for a pre-norm transformer's residual stream: C is fp32 row-major [M, N] and receives
//                     C += op(A) op(B); the workspace receives each row's sum of squares of the updated C per 64
//                     columns (fp32 [M][N/64]) for the next RMSNorm. The workspace is this output (the operands
//                     must then be given as P).
// The epilogue kernels exist for the packed path (operands are packed first if not given as P) and the Q4_0
// kernels. ABLAS_UNSUPPORTED on the Adreno 840 backend.
typedef enum { ABLAS_EPI_NONE = 0, ABLAS_EPI_PACKED = 1, ABLAS_EPI_SWIGLU = 2, ABLAS_EPI_RESIDUAL_RMS = 3, ABLAS_EPI_F32 = 4 } ablas_epilogue;
ablas_status ablas_hgemm_ex(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, ablas_op opB, uint32_t M, uint32_t N,
                            uint32_t K, ablas_buf A, ablas_buf B, ablas_buf C, ablas_buf workspace, ablas_epilogue ep);
ablas_status ablas_hgemm_q4_0_ex(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, uint32_t M, uint32_t N, uint32_t K,
                                 ablas_buf A, ablas_buf W, ablas_buf C, ablas_buf workspace, ablas_epilogue ep);

// For frameworks that keep activations in fp32 (llama.cpp's ggml): C (fp32 row-major [M, N]) = A W^T, with the weight W
// [N, K] packed once (ablas_pack_b with ABLAS_OP_T for fp16 [N, K], ablas_q4_0_pack_ggml for ggml Q4_0 blocks) and A
// packed per call from fp32 with ablas_pack_a_f32. Any M >= 1: A is packed with M rounded up to 64 rows (zeros) and
// only the first M rows of C are written. N multiple of 64, K of 64. fp16 inputs, fp16 accumulation, fp32 out.
// Descriptor sets instead of push descriptors. AdrenoBLAS pushes its descriptors (VK_KHR_push_descriptor) by
// default. On the Adreno 850 driver, once a dispatch of another pipeline with an ordinary descriptor set bound is
// recorded between push-descriptor dispatches in one command buffer, every push-descriptor dispatch in it uses the
// descriptors pushed last, so earlier GEMMs write into the last GEMM's output (../driver_bugs/ #13). Hosts that
// record their own descriptor-set dispatches between AdrenoBLAS calls (llama.cpp's ggml-vulkan) call
// ablas_use_descriptor_sets right after ablas_create, before any other call. AdrenoBLAS then
// allocates one descriptor set per dispatch from its own pools; ablas_reset_descriptor_sets frees them all and may
// be called only when no command buffer recorded since the last reset is pending. Without VK_KHR_push_descriptor this
// mode is on from the start.
ablas_status ablas_use_descriptor_sets(ablas_handle h);
void ablas_reset_descriptor_sets(ablas_handle h);

ablas_status ablas_pack_a_f32(ablas_handle h, VkCommandBuffer cmd, uint32_t M, uint32_t K, ablas_buf A_f32, ablas_buf dst);
ablas_status ablas_q4_0_pack_ggml(ablas_handle h, VkCommandBuffer cmd, uint32_t N, uint32_t K, ablas_buf blocks, ablas_buf dst);
ablas_status ablas_gemm_f32out(ablas_handle h, VkCommandBuffer cmd, int w_is_q4_0, uint32_t M, uint32_t N, uint32_t K,
                               ablas_buf A_packed, ablas_buf W_packed, ablas_buf C_f32);

// Name of the kernel the last ablas_hgemm call used (for logs and benchmarks).
const char* ablas_last_kernel(ablas_handle h);

#ifdef __cplusplus
}
#endif
#endif
