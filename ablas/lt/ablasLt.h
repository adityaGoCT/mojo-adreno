// AdrenoBLASLt: a hipBLASLt-style layer over AdrenoBLAS (../ablas.h) for LLM inference on the Adreno 850.
//
// AdrenoBLAS (like rocBLAS) has the kernels: packed fp16 and Q4_0 GEMMs on the matrix units, pack routines, fused
// epilogues, tuning tables. This layer (like hipBLASLt) says what a matmul is with descriptors: the layout of each
// operand and what happens to the result, and picks the AdrenoBLAS calls, workspace, packing and barriers. Only the
// epilogues LLMs need, plus the few non-GEMM operations a transformer layer has (RMSNorm into the next GEMM's
// format, causal attention), so a model runner is a list of calls with no layout code of its own.
//
// Every call records into the caller's VkCommandBuffer; nothing is submitted. With auto barriers (the default) each
// call ends with a compute barrier, so calls can be chained in one command buffer as a model's layers chain.
// Hosts that track dependencies themselves (llama.cpp's ggml-vulkan) turn them off.
//
// The matmul is D = epilogue(A W^T): A [M, K] activations, W [N, K] a weight (a PyTorch Linear's layout), N and K
// multiples of 64. M is any size where A is fp32 row-major (rows padded to 64 inside), else a multiple of 64.
#ifndef ABLAS_LT_H
#define ABLAS_LT_H

#include "../ablas.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ablasLt_ctx* ablasLtHandle;

typedef enum { ABLASLT_F16 = 0, ABLASLT_F32 = 1, ABLASLT_Q4_0 = 2 } ablasLtType;

typedef enum {
  ABLASLT_ORDER_ROW = 0,    // row-major [rows, cols], contiguous
  ABLASLT_ORDER_TILED = 1,  // activation tiles: the packed A format of an [rows, cols] matrix (rows multiple of 64);
                            // what EPILOGUE_TILED, SWIGLU, the attention and RMSNorm ops write
  ABLASLT_ORDER_WEIGHT = 2, // a weight from ablasLtWeightPack: AdrenoBLAS's B format (fp16 tiles or Q4_0)
} ablasLtOrder;

// How a weight is laid out for its epilogue (ablasLtWeightPack writes it so; ablasLtMatmul checks it).
typedef enum {
  ABLASLT_WEIGHT_PLAIN = 0,
  ABLASLT_WEIGHT_GATE_UP = 1,  // rows: gate [N/2] then up [N/2]; packed as 64-row groups [32 gate | 32 up] for SWIGLU
} ablasLtWeightUse;

typedef struct {
  ablasLtType type;
  ablasLtOrder order;
  uint32_t rows, cols;   // logical [rows, cols]; for a weight [N, K]
  ablasLtWeightUse use;  // weights only
} ablasLtLayout;

typedef enum {
  // D = A W^T. D: fp32 or fp16 row-major, or fp16 TILED (straight into the next GEMM's A).
  ABLASLT_EPILOGUE_DEFAULT = 0,
  // D (fp32 row-major [M, N]: a residual stream) += A W^T. aux (optional): fp32 [M][N/64] per-row sums of squares of
  // the updated D per 64 columns, which ablasLtRmsNorm takes instead of computing them. A must be TILED.
  ABLASLT_EPILOGUE_RESIDUAL = 1,
  // W packed with ABLASLT_WEIGHT_GATE_UP ([2F, K]); D (fp16 TILED [M, F]) = silu(gate) * up. A must be TILED.
  ABLASLT_EPILOGUE_SWIGLU = 2,
  // W = q_proj ; k_proj ; v_proj rows ([(nh + 2 nkv) * 128, K]). RoPE (rotate_half pairs d, d + 64, head dim 128)
  // on Q and K, then the attention operands: q = Q tiles [nh][M, 128], k = K tiles [nkv][M, 128], vt = V^T tiles
  // [nkv][128, M] (ablasLtAttention's inputs). D unused. rope: fp32 [M][128], cos[64] | sin[64] per position.
  ABLASLT_EPILOGUE_ROPE_QKV = 3,
} ablasLtEpilogue;

typedef struct {
  ablasLtEpilogue epilogue;
  ablas_buf aux;                   // RESIDUAL: row sums of squares (optional)
  uint32_t n_heads, n_kv_heads;    // ROPE_QKV
  ablas_buf rope, q, k, vt;        // ROPE_QKV
} ablasLtMatmulDesc;

// flags for ablasLtCreate
enum {
  ABLASLT_NO_AUTO_BARRIER = 1,     // the host puts the barriers between calls
  ABLASLT_DESCRIPTOR_SETS = 2,     // ordinary descriptor sets, not push descriptors (hosts that mix in their own
                                   // descriptor-set dispatches: driver bug #13); free them with ablasLtReset
};

// Takes ownership of nothing: `ab` is an AdrenoBLAS handle on the same device, which this layer uses for the GEMMs
// (and puts in descriptor-set mode with ABLASLT_DESCRIPTOR_SETS, which must then come before any AdrenoBLAS call).
ablas_status ablasLtCreate(ablasLtHandle* lt, ablas_handle ab, VkDevice dev, PFN_vkGetInstanceProcAddr gipa,
                           VkInstance inst, uint32_t flags);
void ablasLtDestroy(ablasLtHandle lt);
// Descriptor-set mode: frees the descriptor sets of every call so far; only when none of them is still pending.
void ablasLtReset(ablasLtHandle lt);

// Bytes of workspace ablasLtMatmul needs for these operands (packing an fp32 A, ROPE_QKV's intermediate).
size_t ablasLtMatmulWorkspaceSize(const ablasLtMatmulDesc* desc, const ablasLtLayout* a, const ablasLtLayout* w,
                                  const ablasLtLayout* d);
// D = epilogue(A W^T). ABLAS_BAD_SHAPE for an unsupported combination of layouts and epilogue.
ablas_status ablasLtMatmul(ablasLtHandle lt, VkCommandBuffer cmd, const ablasLtMatmulDesc* desc, ablas_buf A,
                           const ablasLtLayout* a, ablas_buf W, const ablasLtLayout* w, ablas_buf D,
                           const ablasLtLayout* d, ablas_buf workspace);
// The AdrenoBLAS kernel the last matmul ran (and, for ROPE_QKV, the RoPE kernel after it).
const char* ablasLtLastKernel(ablasLtHandle lt);

// Activations [M, K] (fp32 or fp16 row-major) -> tiles [roundup(M, 64), K], padding rows zero: for hosts that pack once
// for several matmuls on the same input (q/k/v, gate/up). A matmul given tiles of roundup(M, 64) rows may then write
// only M rows of an fp32 row-major D (EPILOGUE_DEFAULT): d->rows = M, a->rows = roundup(M, 64).
ablas_status ablasLtPack(ablasLtHandle lt, VkCommandBuffer cmd, ablas_buf A, const ablasLtLayout* a, ablas_buf out);

// ---- weights (host side: the weight's memory is host-visible, as on the Adreno's unified memory) ----

typedef enum {
  ABLASLT_SRC_F32_ROWS = 0,  // fp32 [N, K] row-major
  ABLASLT_SRC_F16_ROWS = 1,  // fp16 [N, K] row-major (a PyTorch Linear weight)
  ABLASLT_SRC_GGML_Q4_0 = 2, // ggml block_q4_0 rows (a GGUF tensor); type must be Q4_0
  ABLASLT_SRC_PACKED = 3,    // already in AdrenoBLAS's B format (export.py), use PLAIN: only `use` is applied
} ablasLtWeightSource;

size_t ablasLtWeightSize(ablasLtType type, uint32_t N, uint32_t K);
// Writes the weight in AdrenoBLAS's B format of `type` (F16 or Q4_0: fp32/fp16 sources are quantized with ggml's
// reference rounding), laid out for `use`. src and dst must not overlap. Returns ABLAS_BAD_SHAPE for N or K not a
// multiple of 64 (GATE_UP: N multiple of 128).
ablas_status ablasLtWeightPack(ablasLtType type, ablasLtWeightUse use, ablasLtWeightSource src_kind, const void* src,
                               uint32_t N, uint32_t K, void* dst);
// The same on the GPU, recorded into cmd (PLAIN only; fp16 rows or ggml Q4_0 blocks): for weights already in device
// memory (a GGUF loaded by llama.cpp). src and dst must not overlap.
ablas_status ablasLtWeightPackDevice(ablasLtHandle lt, VkCommandBuffer cmd, ablasLtType type, ablasLtWeightSource src_kind,
                                     ablas_buf src, uint32_t N, uint32_t K, ablas_buf dst);
// Row n of a packed PLAIN weight as fp32 (K values): an embedding row of a tied embedding / LM head.
void ablasLtWeightRow(ablasLtType type, const void* w, uint32_t N, uint32_t K, uint32_t n, float* out);

// ---- LLM operations (Adreno 850) ----

// out (fp16 TILED [M, D]) = weight * x * rsqrt(mean(x^2) + eps) per row of x (fp32 row-major [M, D]), M multiple of
// 64. sumsq: the RESIDUAL epilogue's aux for this x ([M][D/64]), or {0} to compute the sums here.
ablas_status ablasLtRmsNorm(ablasLtHandle lt, VkCommandBuffer cmd, uint32_t M, uint32_t D, ablas_buf x,
                            ablas_buf sumsq, ablas_buf weight, float eps, ablas_buf out, ablas_buf workspace);
size_t ablasLtRmsNormWorkspaceSize(uint32_t M);

// Causal self-attention over M positions from 0 (prefill), head dim 128, n_heads a multiple of n_kv_heads:
// out (fp16 TILED [M, n_heads * 128]) = softmax(Q K^T * scale, causal) V, from ROPE_QKV's q, k, vt. M multiple of 64.
ablas_status ablasLtAttention(ablasLtHandle lt, VkCommandBuffer cmd, uint32_t M, uint32_t n_heads,
                              uint32_t n_kv_heads, float scale, ablas_buf q, ablas_buf k, ablas_buf vt,
                              ablas_buf out);

// The compute barrier the auto mode puts after each call (for hosts that turn it off).
void ablasLtBarrier(ablasLtHandle lt, VkCommandBuffer cmd);

#ifdef __cplusplus
}
#endif
#endif
