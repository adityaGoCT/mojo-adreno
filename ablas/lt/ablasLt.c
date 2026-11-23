// AdrenoBLASLt (ablasLt.h): descriptors -> AdrenoBLAS calls, plus RMSNorm and causal attention kernels.
#include "ablasLt.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ablaslt_kernels.h"

#define NBIND 6
#define PC_BYTES 64
#define SETS_PER_POOL 1024u

struct ablasLt_ctx {
  ablas_handle ab;
  VkDevice dev;
  uint32_t flags;
  VkDescriptorSetLayout dsl;
  VkPipelineLayout layout;
  VkPipeline pipes[LT_NKERNELS];
  VkDescriptorPool* pools;  // descriptor-set mode
  uint32_t npools, cur_pool, used_in_pool;
  char last[192];
  PFN_vkCreateShaderModule CreateShaderModule;
  PFN_vkDestroyShaderModule DestroyShaderModule;
  PFN_vkCreateComputePipelines CreateComputePipelines;
  PFN_vkDestroyPipeline DestroyPipeline;
  PFN_vkCreateDescriptorSetLayout CreateDescriptorSetLayout;
  PFN_vkDestroyDescriptorSetLayout DestroyDescriptorSetLayout;
  PFN_vkCreatePipelineLayout CreatePipelineLayout;
  PFN_vkDestroyPipelineLayout DestroyPipelineLayout;
  PFN_vkCmdBindPipeline CmdBindPipeline;
  PFN_vkCmdPushDescriptorSetKHR CmdPushDescriptorSetKHR;
  PFN_vkCmdPushConstants CmdPushConstants;
  PFN_vkCmdDispatch CmdDispatch;
  PFN_vkCmdPipelineBarrier CmdPipelineBarrier;
  PFN_vkCreateDescriptorPool CreateDescriptorPool;
  PFN_vkDestroyDescriptorPool DestroyDescriptorPool;
  PFN_vkResetDescriptorPool ResetDescriptorPool;
  PFN_vkAllocateDescriptorSets AllocateDescriptorSets;
  PFN_vkUpdateDescriptorSets UpdateDescriptorSets;
  PFN_vkCmdBindDescriptorSets CmdBindDescriptorSets;
};

static size_t up64(size_t x) { return (x + 63) / 64 * 64; }
static size_t up256(size_t x) { return (x + 255) / 256 * 256; }

// ---- handle -------------------------------------------------------------------------------------

ablas_status ablasLtCreate(ablasLtHandle* out, ablas_handle ab, VkDevice dev, PFN_vkGetInstanceProcAddr gipa,
                           VkInstance inst, uint32_t flags) {
  if (!out || !ab) return ABLAS_BAD_SHAPE;
  PFN_vkGetDeviceProcAddr gdpa = (PFN_vkGetDeviceProcAddr)gipa(inst, "vkGetDeviceProcAddr");
  struct ablasLt_ctx* h = calloc(1, sizeof *h);
  h->ab = ab, h->dev = dev, h->flags = flags;
#define LOAD(f) h->f = (PFN_vk##f)gdpa(dev, "vk" #f)
  LOAD(CreateShaderModule); LOAD(DestroyShaderModule); LOAD(CreateComputePipelines); LOAD(DestroyPipeline);
  LOAD(CreateDescriptorSetLayout); LOAD(DestroyDescriptorSetLayout); LOAD(CreatePipelineLayout);
  LOAD(DestroyPipelineLayout); LOAD(CmdBindPipeline); LOAD(CmdPushDescriptorSetKHR); LOAD(CmdPushConstants);
  LOAD(CmdDispatch); LOAD(CmdPipelineBarrier); LOAD(CreateDescriptorPool); LOAD(DestroyDescriptorPool);
  LOAD(ResetDescriptorPool); LOAD(AllocateDescriptorSets); LOAD(UpdateDescriptorSets); LOAD(CmdBindDescriptorSets);
#undef LOAD
  int sets = (flags & ABLASLT_DESCRIPTOR_SETS) || !h->CmdPushDescriptorSetKHR;
  if (sets) {
    h->flags |= ABLASLT_DESCRIPTOR_SETS;
    if (ablas_use_descriptor_sets(ab)) { free(h); return ABLAS_UNSUPPORTED; }  // AdrenoBLAS already has pipelines
  }
  VkDescriptorSetLayoutBinding b[NBIND];
  for (uint32_t i = 0; i < NBIND; ++i)
    b[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL,
                                         sets ? 0 : VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR, NBIND, b};
  VkPushConstantRange pcr = {VK_SHADER_STAGE_COMPUTE_BIT, 0, PC_BYTES};
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &h->dsl, 1, &pcr};
  if (h->CreateDescriptorSetLayout(dev, &dli, NULL, &h->dsl) || h->CreatePipelineLayout(dev, &pli, NULL, &h->layout)) {
    ablasLtDestroy(h);
    return ABLAS_VK_ERROR;
  }
  *out = h;
  return ABLAS_OK;
}

void ablasLtDestroy(ablasLtHandle h) {
  if (!h) return;
  for (int i = 0; i < LT_NKERNELS; ++i)
    if (h->pipes[i]) h->DestroyPipeline(h->dev, h->pipes[i], NULL);
  for (uint32_t i = 0; i < h->npools; ++i) h->DestroyDescriptorPool(h->dev, h->pools[i], NULL);
  if (h->layout) h->DestroyPipelineLayout(h->dev, h->layout, NULL);
  if (h->dsl) h->DestroyDescriptorSetLayout(h->dev, h->dsl, NULL);
  free(h->pools);
  free(h);
}

void ablasLtReset(ablasLtHandle h) {
  if (!(h->flags & ABLASLT_DESCRIPTOR_SETS)) return;
  for (uint32_t i = 0; i < h->npools && i <= h->cur_pool; ++i) h->ResetDescriptorPool(h->dev, h->pools[i], 0);
  h->cur_pool = 0, h->used_in_pool = 0;
  ablas_reset_descriptor_sets(h->ab);
}

const char* ablasLtLastKernel(ablasLtHandle h) { return h->last; }

void ablasLtBarrier(ablasLtHandle h, VkCommandBuffer cmd) {
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT};
  h->CmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &mb, 0,
                        NULL, 0, NULL);
}

static void done(ablasLtHandle h, VkCommandBuffer cmd) {
  if (!(h->flags & ABLASLT_NO_AUTO_BARRIER)) ablasLtBarrier(h, cmd);
}

// ---- operation kernels --------------------------------------------------------------------------

static VkPipeline pipeline(ablasLtHandle h, int k) {
  if (h->pipes[k]) return h->pipes[k];
  VkShaderModuleCreateInfo mi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, lt_kernels[k].words * 4,
                                 lt_kernels[k].spv};
  VkShaderModule mod;
  if (h->CreateShaderModule(h->dev, &mi, NULL, &mod)) return VK_NULL_HANDLE;
  VkComputePipelineCreateInfo ci = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  ci.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  ci.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  ci.stage.module = mod;
  ci.stage.pName = "main";
  ci.layout = h->layout;
  VkPipeline p = VK_NULL_HANDLE;
  if (h->CreateComputePipelines(h->dev, VK_NULL_HANDLE, 1, &ci, NULL, &p)) p = VK_NULL_HANDLE;
  h->DestroyShaderModule(h->dev, mod, NULL);
  return h->pipes[k] = p;
}

static VkDescriptorSet alloc_set(ablasLtHandle h) {
  if (h->npools && h->used_in_pool == SETS_PER_POOL) ++h->cur_pool, h->used_in_pool = 0;
  if (h->cur_pool == h->npools) {
    VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NBIND * SETS_PER_POOL};
    VkDescriptorPoolCreateInfo pi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, SETS_PER_POOL, 1, &ps};
    VkDescriptorPool pool;
    if (h->CreateDescriptorPool(h->dev, &pi, NULL, &pool)) return VK_NULL_HANDLE;
    h->pools = realloc(h->pools, (h->npools + 1) * sizeof *h->pools);
    h->pools[h->npools++] = pool;
    h->used_in_pool = 0;
  }
  VkDescriptorSetAllocateInfo ai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, h->pools[h->cur_pool], 1,
                                    &h->dsl};
  VkDescriptorSet set = VK_NULL_HANDLE;
  if (h->AllocateDescriptorSets(h->dev, &ai, &set)) return VK_NULL_HANDLE;
  ++h->used_in_pool;
  return set;
}

// Records one operation kernel: n buffers at bindings 0..n-1, push constants, a grid.
static ablas_status dispatch(ablasLtHandle h, VkCommandBuffer cmd, int k, const ablas_buf* b, uint32_t n,
                             const void* pc, uint32_t pcsize, uint32_t gx, uint32_t gy, uint32_t gz) {
  VkPipeline p = pipeline(h, k);
  if (!p) return ABLAS_VK_ERROR;
  VkDescriptorBufferInfo bi[NBIND];
  VkWriteDescriptorSet w[NBIND];
  for (uint32_t i = 0; i < n; ++i) {
    bi[i] = (VkDescriptorBufferInfo){b[i].buffer, b[i].offset, b[i].range ? b[i].range : VK_WHOLE_SIZE};
    w[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, VK_NULL_HANDLE, i, 0, 1,
                                  VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi[i], NULL};
  }
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  if (h->flags & ABLASLT_DESCRIPTOR_SETS) {
    VkDescriptorSet set = alloc_set(h);
    if (!set) return ABLAS_VK_ERROR;
    for (uint32_t i = 0; i < n; ++i) w[i].dstSet = set;
    h->UpdateDescriptorSets(h->dev, n, w, 0, NULL);
    h->CmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, h->layout, 0, 1, &set, 0, NULL);
  } else {
    h->CmdPushDescriptorSetKHR(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, h->layout, 0, n, w);
  }
  if (pcsize) h->CmdPushConstants(cmd, h->layout, VK_SHADER_STAGE_COMPUTE_BIT, 0, pcsize, pc);
  h->CmdDispatch(cmd, gx, gy, gz);
  return ABLAS_OK;
}

static ablas_buf sub(ablas_buf b, VkDeviceSize off, VkDeviceSize range) {
  return (ablas_buf){b.buffer, b.offset + off, range};
}

// ---- matmul -------------------------------------------------------------------------------------

// Workspace regions: the packed A (when A is not already TILED), then the epilogue's scratch.
static size_t a_pack_bytes(const ablasLtLayout* a) {
  return a->order == ABLASLT_ORDER_TILED ? 0 : up256(up64(a->rows) * a->cols * 2);
}

static size_t scratch_bytes(const ablasLtMatmulDesc* desc, const ablasLtLayout* a, const ablasLtLayout* w) {
  size_t M = up64(a->rows);
  if (desc->epilogue == ABLASLT_EPILOGUE_RESIDUAL && !desc->aux.buffer) return up256(M * (w->rows / 64) * 4);
  if (desc->epilogue == ABLASLT_EPILOGUE_ROPE_QKV) return up256(M * w->rows * 2);
  return 0;
}

size_t ablasLtMatmulWorkspaceSize(const ablasLtMatmulDesc* desc, const ablasLtLayout* a, const ablasLtLayout* w,
                                  const ablasLtLayout* d) {
  (void)d;
  return a_pack_bytes(a) + scratch_bytes(desc, a, w);
}

static ablas_status gemm1(ablasLtHandle h, VkCommandBuffer cmd, int q4, uint32_t M, uint32_t N, uint32_t K,
                          ablas_buf A, ablas_buf W, ablas_buf C, ablas_buf ws, ablas_epilogue ep) {
  return q4 ? ablas_hgemm_q4_0_ex(h->ab, cmd, ABLAS_OP_P, M, N, K, A, W, C, ws, ep)
            : ablas_hgemm_ex(h->ab, cmd, ABLAS_OP_P, ABLAS_OP_P, M, N, K, A, W, C, ws, ep);
}

// Bytes per output row of each epilogue's C (and of its row statistics, RESIDUAL_RMS's workspace)
static VkDeviceSize c_row_bytes(ablas_epilogue ep, uint32_t N) {
  switch (ep) {
  case ABLAS_EPI_RESIDUAL_RMS: case ABLAS_EPI_RESIDUAL_BIAS: return (VkDeviceSize)N * 4;
  case ABLAS_EPI_SWIGLU: case ABLAS_EPI_GEGLU: return (VkDeviceSize)N;  // N/2 fp16 columns
  default: return (VkDeviceSize)N * 2;                                   // fp16 rows or tiles
  }
}

// A GEMM whose M is not a multiple of 256 (more than 256 rows) and whose N is at most 4096 runs as two: the rows up
// to the last multiple of 256, where AdrenoBLAS's 256 x 128 tiles fit, then the rest (64 or more rows). One call on
// all M rows gets only the tiles that divide M. Measured in π0's prefix (832 rows, ../pi0/README.md): the down
// projection (N 2048, K 16384) 6.7 -> 4.0 ms a layer and o proj (N 2048) 1.06 -> 0.69 ms split, while gate|up (N
// 32768) went 6.4 -> 8.0 ms: with that many columns the 64-row tiles already fill the GPU. Every output format is
// row-separable: A tiles, C rows or tiles and the row statistics are offset by the first part's rows.
// ABLASLT_NO_ROW_SPLIT=1 turns it off (for comparisons).
static ablas_status gemm(ablasLtHandle h, VkCommandBuffer cmd, int q4, uint32_t M, uint32_t N, uint32_t K, ablas_buf A,
                         ablas_buf W, ablas_buf C, ablas_buf ws, ablas_epilogue ep) {
  uint32_t M0 = M / 256 * 256;
  if (M < 256 || M == M0 || N > 4096 || getenv("ABLASLT_NO_ROW_SPLIT"))
    return gemm1(h, cmd, q4, M, N, K, A, W, C, ws, ep);
  ablas_status st = gemm1(h, cmd, q4, M0, N, K, A, W, C, ws, ep);
  if (st) return st;
  ablas_buf A1 = sub(A, (VkDeviceSize)M0 * K * 2, 0), C1 = sub(C, (VkDeviceSize)M0 * c_row_bytes(ep, N), 0), ws1 = ws;
  if (ep == ABLAS_EPI_RESIDUAL_RMS) ws1 = sub(ws, (VkDeviceSize)M0 * (N / 64) * 4, 0);  // else the bias, or unused
  return gemm1(h, cmd, q4, M - M0, N, K, A1, W, C1, ws1, ep);
}

// ROPE_QKV's general form: the qkv GEMM into fp16 tiles (the packed epilogue, so the next kernels read 2 KB tiles
// whole: from row-major fp16 the split took longer than SigLIP's GEMM), then qksplit (Q, K: bias, RoPE, padding,
// cache rows) and vsplit (V^T: bias, padding, cache keys).
static ablas_status qkv_general(ablasLtHandle h, VkCommandBuffer cmd, const ablasLtMatmulDesc* desc, uint32_t M,
                                uint32_t N, uint32_t K, int q4, ablas_buf Ap, ablas_buf W, ablas_buf scratch) {
  uint32_t nh = desc->n_heads, nkv = desc->n_kv_heads, hd = desc->head_dim ? desc->head_dim : 128;
  uint32_t hdv = desc->head_dim_valid ? desc->head_dim_valid : hd, krows = desc->kv_rows ? desc->kv_rows : M;
  uint32_t koff = desc->kv_offset;
  if (!nh || !nkv || (hd != 128 && hd != 256) || hdv > hd || hdv % 8 || N != (nh + 2 * nkv) * hdv || M % 64 ||
      koff % 64 || koff + M > krows || krows % 64 || (desc->rope.buffer && hdv != hd) || !scratch.buffer ||
      !desc->q.buffer || !desc->k.buffer || !desc->vt.buffer)
    return ABLAS_BAD_SHAPE;
  ablas_buf qkv = sub(scratch, 0, (VkDeviceSize)M * N * 2);
  ablas_buf none = {0};
  ablas_status st = gemm(h, cmd, q4, M, N, K, Ap, W, qkv, none, ABLAS_EPI_PACKED);
  if (st) return st;
  snprintf(h->last, sizeof h->last, "%s + qksplit + vsplit", ablas_last_kernel(h->ab));
  ablasLtBarrier(h, cmd);
  uint32_t flags = (desc->rope.buffer ? 1u : 0u) | (desc->bias.buffer ? 2u : 0u);
  ablas_buf bias = desc->bias.buffer ? desc->bias : qkv, rope = desc->rope.buffer ? desc->rope : qkv;
  struct { uint32_t M, ncols, nh, hdv, HD, qrows, krows, koff, flags; float qscale; } pq =
      {M, N, nh, hdv, hd, M, krows, koff, flags, ABLASLT_Q_SCALE};
  ablas_buf qb[5] = {qkv, rope, desc->q, desc->k, bias};
  if ((st = dispatch(h, cmd, LT_QKSPLIT, qb, 5, &pq, sizeof pq, nh + nkv, M / 64, hd / 128))) return st;
  struct { uint32_t M, ncols, vcol0, hdv, HD, krows, koff, flags; } pv = {M, N, (nh + nkv) * hdv, hdv, hd, krows, koff, flags};
  ablas_buf vb[3] = {qkv, desc->vt, bias};
  if ((st = dispatch(h, cmd, LT_VSPLIT, vb, 3, &pv, sizeof pv, M / 16, nkv, 1))) return st;
  done(h, cmd);
  return ABLAS_OK;
}

ablas_status ablasLtMatmul(ablasLtHandle h, VkCommandBuffer cmd, const ablasLtMatmulDesc* desc, ablas_buf A,
                           const ablasLtLayout* a, ablas_buf W, const ablasLtLayout* w, ablas_buf D,
                           const ablasLtLayout* d, ablas_buf ws) {
  // padded tiles in, fewer fp32 rows out (ablasLtPack): M is the output's rows
  uint32_t M = a->rows;
  if (desc->epilogue == ABLASLT_EPILOGUE_DEFAULT && a->order == ABLASLT_ORDER_TILED && d && d->type == ABLASLT_F32 &&
      d->order == ABLASLT_ORDER_ROW && d->rows < a->rows && up64(d->rows) == a->rows)
    M = d->rows;
  const uint32_t K = a->cols, N = w->rows, Mp = (uint32_t)up64(M);
  if (w->order != ABLASLT_ORDER_WEIGHT || (w->type != ABLASLT_F16 && w->type != ABLASLT_Q4_0) || w->cols != K ||
      N % 64 || K % 64 || !M)
    return ABLAS_BAD_SHAPE;
  const int q4 = w->type == ABLASLT_Q4_0;
  const ablasLtEpilogue ep = desc->epilogue;
  if ((ep == ABLASLT_EPILOGUE_SWIGLU || ep == ABLASLT_EPILOGUE_GEGLU) != (w->use == ABLASLT_WEIGHT_GATE_UP))
    return ABLAS_BAD_SHAPE;
  // fp32 rows out is the only form that writes just M rows; every other one writes all Mp
  int f32_rows_out = ep == ABLASLT_EPILOGUE_DEFAULT && d && d->type == ABLASLT_F32 && d->order == ABLASLT_ORDER_ROW;
  if (Mp != M && !f32_rows_out) return ABLAS_BAD_SHAPE;

  // A -> packed tiles
  ablas_buf Ap = A;
  size_t apack = a_pack_bytes(a);
  ablas_status st = ABLAS_OK;
  if (a->order == ABLASLT_ORDER_TILED && a->type == ABLASLT_F16) {
    if (a->rows % 64) return ABLAS_BAD_SHAPE;
  } else if (a->order == ABLASLT_ORDER_ROW && a->type == ABLASLT_F32) {
    if (!ws.buffer) return ABLAS_BAD_SHAPE;
    Ap = sub(ws, 0, (VkDeviceSize)Mp * K * 2);
    if ((st = ablas_pack_a_f32(h->ab, cmd, M, K, A, Ap))) return st;
    ablasLtBarrier(h, cmd);
  } else if (a->order == ABLASLT_ORDER_ROW && a->type == ABLASLT_F16) {
    if (!ws.buffer || M % 64) return ABLAS_BAD_SHAPE;
    Ap = sub(ws, 0, (VkDeviceSize)M * K * 2);
    if ((st = ablas_pack_a(h->ab, cmd, ABLAS_OP_N, M, K, A, Ap))) return st;
    ablasLtBarrier(h, cmd);
  } else {
    return ABLAS_BAD_SHAPE;
  }
  ablas_buf scratch = sub(ws, apack, 0), none = {0};

  switch (ep) {
  case ABLASLT_EPILOGUE_DEFAULT:
    if (!d || d->rows != M || d->cols != N) return ABLAS_BAD_SHAPE;
    if (f32_rows_out) st = ablas_gemm_f32out(h->ab, cmd, q4, M, N, K, Ap, W, D);
    else if (d->type == ABLASLT_F16 && d->order == ABLASLT_ORDER_ROW) st = gemm(h, cmd, q4, M, N, K, Ap, W, D, none, ABLAS_EPI_NONE);
    else if (d->type == ABLASLT_F16 && d->order == ABLASLT_ORDER_TILED) st = gemm(h, cmd, q4, M, N, K, Ap, W, D, none, ABLAS_EPI_PACKED);
    else return ABLAS_BAD_SHAPE;
    break;
  case ABLASLT_EPILOGUE_RESIDUAL:
    if (!d || d->type != ABLASLT_F32 || d->order != ABLASLT_ORDER_ROW || d->rows != M || d->cols != N) return ABLAS_BAD_SHAPE;
    if (!desc->aux.buffer && !ws.buffer) return ABLAS_BAD_SHAPE;
    st = gemm(h, cmd, q4, M, N, K, Ap, W, D, desc->aux.buffer ? desc->aux : scratch, ABLAS_EPI_RESIDUAL_RMS);
    break;
  case ABLASLT_EPILOGUE_SWIGLU:
  case ABLASLT_EPILOGUE_GEGLU:
    if (!d || d->type != ABLASLT_F16 || d->order != ABLASLT_ORDER_TILED || d->rows != M || d->cols * 2 != N || N % 128)
      return ABLAS_BAD_SHAPE;
    st = gemm(h, cmd, q4, M, N, K, Ap, W, D, none, ep == ABLASLT_EPILOGUE_GEGLU ? ABLAS_EPI_GEGLU : ABLAS_EPI_SWIGLU);
    break;
  case ABLASLT_EPILOGUE_BIAS_GELU:
    if (!d || d->type != ABLASLT_F16 || d->order != ABLASLT_ORDER_TILED || d->rows != M || d->cols != N ||
        !desc->bias.buffer)
      return ABLAS_BAD_SHAPE;
    st = gemm(h, cmd, q4, M, N, K, Ap, W, D, desc->bias, ABLAS_EPI_BIAS_GELU);
    break;
  case ABLASLT_EPILOGUE_RESIDUAL_BIAS:
    if (!d || d->type != ABLASLT_F32 || d->order != ABLASLT_ORDER_ROW || d->rows != M || d->cols != N ||
        !desc->bias.buffer)
      return ABLAS_BAD_SHAPE;
    st = gemm(h, cmd, q4, M, N, K, Ap, W, D, desc->bias, ABLAS_EPI_RESIDUAL_BIAS);
    break;
  case ABLASLT_EPILOGUE_ROPE_QKV: {
    uint32_t nh = desc->n_heads, nkv = desc->n_kv_heads;
    if (desc->head_dim || desc->head_dim_valid || desc->bias.buffer || desc->kv_rows || desc->kv_offset ||
        !desc->rope.buffer)
      return qkv_general(h, cmd, desc, M, N, K, q4, Ap, W, scratch);
    if (!nh || !nkv || N != (nh + 2 * nkv) * 128 || !ws.buffer || !desc->rope.buffer || !desc->q.buffer ||
        !desc->k.buffer || !desc->vt.buffer)
      return ABLAS_BAD_SHAPE;
    // The qkv GEMM into fp16 rows, then RoPE into the attention's Q/K tiles and V^T (one fused kernel per shape,
    // as ../llama3b/gen_fused.py builds, is the faster form; this one takes any M and head count).
    ablas_buf qkv = sub(scratch, 0, (VkDeviceSize)M * N * 2);
    if ((st = gemm(h, cmd, q4, M, N, K, Ap, W, qkv, none, ABLAS_EPI_NONE))) return st;
    snprintf(h->last, sizeof h->last, "%s + rope_qk + vtrans", ablas_last_kernel(h->ab));
    ablasLtBarrier(h, cmd);
    struct { uint32_t M, ncols, nh; float qscale; } prq = {M, N, nh, ABLASLT_Q_SCALE};
    ablas_buf rb[4] = {qkv, desc->rope, desc->q, desc->k};
    if ((st = dispatch(h, cmd, LT_ROPE_QK, rb, 4, &prq, sizeof prq, nh + nkv, M / 64, 1))) return st;
    struct { uint32_t M, ncols, vcol0; } pvt = {M, N, (nh + nkv) * 128};
    ablas_buf vb[2] = {qkv, desc->vt};
    if ((st = dispatch(h, cmd, LT_VTRANS, vb, 2, &pvt, sizeof pvt, M / 16, nkv, 1))) return st;
    done(h, cmd);
    return ABLAS_OK;
  }
  default:
    return ABLAS_BAD_SHAPE;
  }
  if (st) return st;
  snprintf(h->last, sizeof h->last, "%s", ablas_last_kernel(h->ab));
  done(h, cmd);
  return ABLAS_OK;
}

ablas_status ablasLtPack(ablasLtHandle h, VkCommandBuffer cmd, ablas_buf A, const ablasLtLayout* a, ablas_buf out) {
  if (a->order != ABLASLT_ORDER_ROW || !a->rows || a->cols % 64) return ABLAS_BAD_SHAPE;
  ablas_status st;
  if (a->type == ABLASLT_F32) st = ablas_pack_a_f32(h->ab, cmd, a->rows, a->cols, A, out);
  else if (a->type == ABLASLT_F16 && a->rows % 64 == 0) st = ablas_pack_a(h->ab, cmd, ABLAS_OP_N, a->rows, a->cols, A, out);
  else return ABLAS_BAD_SHAPE;
  if (st) return st;
  snprintf(h->last, sizeof h->last, "%s", a->type == ABLASLT_F32 ? "pack_a_f32" : "pack_a");
  done(h, cmd);
  return ABLAS_OK;
}

ablas_status ablasLtWeightPackDevice(ablasLtHandle h, VkCommandBuffer cmd, ablasLtType type, ablasLtWeightSource kind,
                                     ablas_buf src, uint32_t N, uint32_t K, ablas_buf dst) {
  ablas_status st;
  if (type == ABLASLT_Q4_0 && kind == ABLASLT_SRC_GGML_Q4_0) st = ablas_q4_0_pack_ggml(h->ab, cmd, N, K, src, dst);
  else if (type == ABLASLT_F16 && kind == ABLASLT_SRC_F16_ROWS) st = ablas_pack_b(h->ab, cmd, ABLAS_OP_T, K, N, src, dst);
  else return ABLAS_UNSUPPORTED;
  if (st) return st;
  done(h, cmd);
  return ABLAS_OK;
}

// ---- LLM operations -----------------------------------------------------------------------------

size_t ablasLtRmsNormWorkspaceSize(uint32_t M) { return up256((size_t)up64(M) * 4); }

ablas_status ablasLtRmsNorm(ablasLtHandle h, VkCommandBuffer cmd, uint32_t M, uint32_t D, ablas_buf x,
                            ablas_buf sumsq, ablas_buf weight, float eps, ablas_buf out, ablas_buf ws) {
  if (!M || M % 64 || !D || D % 256) return ABLAS_BAD_SHAPE;
  ablas_status st;
  struct { uint32_t D; float eps; uint32_t nparts, stride; } pn = {D, eps, D / 64, D / 64};
  ablas_buf ss = sumsq;
  if (!sumsq.buffer) {  // the row totals here first
    if (!ws.buffer) return ABLAS_BAD_SHAPE;
    ss = sub(ws, 0, (VkDeviceSize)M * 4);
    ablas_buf rb[2] = {x, ss};
    uint32_t pd = D;
    if ((st = dispatch(h, cmd, LT_ROWSS, rb, 2, &pd, 4, M / 4, 1, 1))) return st;
    ablasLtBarrier(h, cmd);
    pn.nparts = pn.stride = 1;
  }
  ablas_buf nb[4] = {x, ss, weight, out};
  if ((st = dispatch(h, cmd, LT_NORMTILES, nb, 4, &pn, sizeof pn, D / 256, M / 64, 1))) return st;
  snprintf(h->last, sizeof h->last, "%snormtiles", sumsq.buffer ? "" : "rowss + ");
  done(h, cmd);
  return ABLAS_OK;
}

ablas_status ablasLtAttention(ablasLtHandle h, VkCommandBuffer cmd, uint32_t M, uint32_t n_heads,
                              uint32_t n_kv_heads, float scale, ablas_buf q, ablas_buf k, ablas_buf vt,
                              ablas_buf out) {
  if (!M || M % 64 || !n_heads || !n_kv_heads || n_heads % n_kv_heads) return ABLAS_BAD_SHAPE;
  struct { uint32_t M; float scale; uint32_t group; } pa = {M, scale / ABLASLT_Q_SCALE, n_heads / n_kv_heads};  // q is Q * ABLASLT_Q_SCALE
  ablas_buf b[4] = {q, k, vt, out};
  ablas_status st = dispatch(h, cmd, LT_FA3, b, 4, &pa, sizeof pa, M / 64, n_heads, 1);
  if (st) return st;
  snprintf(h->last, sizeof h->last, "fa3");
  done(h, cmd);
  return ABLAS_OK;
}

// The key splits for a masked attention: 1 when its query workgroups (M / 64 x heads x batches) already number 64,
// else enough for about 64 workgroups, each split visiting at least 2 key blocks (one per subgroup and pass).
static uint32_t key_splits(const ablasLtAttentionDesc* d, uint32_t nkb) {
  uint32_t nb = d->batches ? d->batches : 1, wgs = d->M / 64 * d->n_heads * nb, n = d->key_splits;
  if (!n) {
    const char* e = getenv("ABLASLT_ATTN_SPLITS");
    n = e ? (uint32_t)atoi(e) : wgs >= 64 ? 1 : (64 + wgs - 1) / wgs;
  }
  uint32_t most = (nkb + 1) / 2;
  n = n < 1 ? 1 : n > 16 ? 16 : n;
  return n > most ? most : n;
}

static void attn_dims(const ablasLtAttentionDesc* d, uint32_t* nb, uint32_t* hdv, uint32_t* kvb, uint32_t* krows,
                      uint32_t* keys, uint32_t* outw) {
  *nb = d->batches ? d->batches : 1, *hdv = d->head_dim_valid ? d->head_dim_valid : d->head_dim;
  *kvb = d->kv_batch ? d->kv_batch : d->M, *krows = d->kv_rows ? d->kv_rows : *nb * d->M;
  *keys = d->keys ? d->keys : *kvb, *outw = d->out_cols ? d->out_cols : d->n_heads * *hdv;
}

size_t ablasLtAttentionWorkspaceSize(const ablasLtAttentionDesc* d) {
  uint32_t nb, hdv, kvb, krows, keys, outw;
  attn_dims(d, &nb, &hdv, &kvb, &krows, &keys, &outw);
  uint32_t ns = key_splits(d, (keys + 63) / 64);
  if (ns == 1) return 0;
  return up256((size_t)ns * d->n_heads * nb * d->M * d->head_dim * 2) + up256((size_t)ns * d->n_heads * nb * d->M * 8);
}

ablas_status ablasLtAttentionMasked(ablasLtHandle h, VkCommandBuffer cmd, const ablasLtAttentionDesc* d, ablas_buf q,
                                    ablas_buf k, ablas_buf vt, ablas_buf out) {
  uint32_t nb, hdv, kvb, krows, keys, outw, hd = d->head_dim;
  attn_dims(d, &nb, &hdv, &kvb, &krows, &keys, &outw);
  uint32_t kvalid = d->key_valid ? d->key_valid : keys, nkb = (keys + 63) / 64;
  if (!d->M || d->M % 64 || !d->n_heads || !d->n_kv_heads || d->n_heads % d->n_kv_heads || (hd != 128 && hd != 256) ||
      hdv > hd || hdv % 8 || outw % 16 || krows % 64 || kvb % 16 || (nb - 1) * kvb + keys > krows || !keys)
    return ABLAS_BAD_SHAPE;
  uint32_t ns = d->workspace.buffer ? key_splits(d, nkb) : 1, bps = (nkb + ns - 1) / ns;
  ns = (nkb + bps - 1) / bps;
  uint32_t qrows = nb * d->M;
  ablas_buf part = out, st = out;  // with splits: partial outputs and their (max, sum) in the workspace
  if (ns > 1) {
    VkDeviceSize pbytes = up256((size_t)ns * d->n_heads * qrows * hd * 2);
    part = sub(d->workspace, 0, pbytes), st = sub(d->workspace, pbytes, (VkDeviceSize)ns * d->n_heads * qrows * 8);
  }
  struct { uint32_t nq, qrows, krows, kbatch, nkb, kvalid, sbase, scount, scausal; float scale; uint32_t group, outw, hdv, nsplit, bps; } pa =
      {d->M, qrows, krows, kvb, nkb, kvalid, d->suffix_base, d->suffix_count, d->suffix_causal, d->scale / ABLASLT_Q_SCALE,
       d->n_heads / d->n_kv_heads, outw, hdv, ns, bps};
  ablas_buf b[5] = {q, k, vt, part, st};
  int kern = (hd == 256 ? LT_FAMASK256 : LT_FAMASK128) + (ns == 1 ? 0 : bps <= 2 ? 2 : 1);  // "", "s", "s1"
  ablas_status s = dispatch(h, cmd, kern, b, 5, &pa, sizeof pa, d->M / 64, d->n_heads, nb * ns);
  if (s) return s;
  if (ns > 1) {
    ablasLtBarrier(h, cmd);
    struct { uint32_t nsplit, qrows, outw, hdv, HD; } pc = {ns, qrows, outw, hdv, hd};
    ablas_buf cb[3] = {part, st, out};
    if ((s = dispatch(h, cmd, LT_FACOMBINE, cb, 3, &pc, sizeof pc, qrows / 64, d->n_heads, 1))) return s;
  }
  snprintf(h->last, sizeof h->last, ns > 1 ? "famask%u%s x %u key splits + facombine" : "famask%u", hd,
           bps <= 2 ? "s1" : "s", ns);
  done(h, cmd);
  return ABLAS_OK;
}

size_t ablasLtLayerNormWorkspaceSize(uint32_t M) { return up256((size_t)up64(M) * 8); }

ablas_status ablasLtLayerNorm(ablasLtHandle h, VkCommandBuffer cmd, uint32_t M, uint32_t D, ablas_buf x,
                              ablas_buf weight, ablas_buf bias, float eps, ablas_buf out, ablas_buf ws) {
  if (!M || M % 64 || !D || D % 64 || !ws.buffer) return ABLAS_BAD_SHAPE;
  ablas_buf st = sub(ws, 0, (VkDeviceSize)M * 8);
  struct { uint32_t D; float eps; } ps = {D, eps};
  ablas_buf sb[2] = {x, st};
  ablas_status s;
  if ((s = dispatch(h, cmd, LT_LNSTATS, sb, 2, &ps, sizeof ps, M / 4, 1, 1))) return s;
  ablasLtBarrier(h, cmd);
  ablas_buf nb[5] = {x, st, weight, bias, out};
  if ((s = dispatch(h, cmd, LT_LNTILES, nb, 5, &D, 4, D / 64, M / 64, 1))) return s;
  snprintf(h->last, sizeof h->last, "lnstats + lntiles");
  done(h, cmd);
  return ABLAS_OK;
}

// ---- weights (host) -----------------------------------------------------------------------------

size_t ablasLtWeightSize(ablasLtType type, uint32_t N, uint32_t K) {
  return type == ABLASLT_Q4_0 ? ablas_q4_0_size(N, K) : (size_t)N * K * 2;
}

static size_t tile_index(uint32_t n, uint32_t k, uint32_t K) {
  return ((size_t)(n / 64) * (K / 16) + k / 16) * 1024 + (n % 64) * 16 + k % 16;
}

static float src_value(ablasLtWeightSource kind, const void* src, size_t i) {
  return kind == ABLASLT_SRC_F32_ROWS ? ((const float*)src)[i] : (float)((const _Float16*)src)[i];
}

// ggml's quantize_row_q4_0_ref: per 32 values, d = (the value of largest magnitude) / -8, q = min(15, (int8)(x/d + 8.5))
static void quantize_q4_0_row(const float* x, uint32_t K, uint8_t* blocks) {
  for (uint32_t b = 0; b < K / 32; ++b) {
    const float* v = x + b * 32;
    float amax = 0, max = 0;
    for (int j = 0; j < 32; ++j)
      if (amax < fabsf(v[j])) amax = fabsf(v[j]), max = v[j];
    float d = max / -8, id = d ? 1.0f / d : 0.0f;
    uint8_t* blk = blocks + (size_t)b * 18;
    _Float16 dh = (_Float16)d;
    memcpy(blk, &dh, 2);
    for (int j = 0; j < 16; ++j) {
      int q0 = (int8_t)(v[j] * id + 8.5f), q1 = (int8_t)(v[16 + j] * id + 8.5f);
      q0 = q0 > 15 ? 15 : q0, q1 = q1 > 15 ? 15 : q1;
      blk[2 + j] = (uint8_t)(q0 | q1 << 4);
    }
  }
}

// The packed layout's runs for GATE_UP: 64-row groups [32 gate | 32 up], group j = half (j % 2) of gate panel j / 2
// and of up panel N/128 + j / 2. fp16 tiles hold a panel's rows 0-31 / 32-63 in the first / second 1 KB of each 2 KB
// K-tile; Q4_0 holds them in the first / second 256 bytes of each 512-byte quant run and 64 bytes of each 128-byte
// scale run.
static void interleave_gate_up(ablasLtType type, const uint8_t* src, uint32_t N, uint32_t K, uint8_t* dst) {
  uint32_t NP = N / 64, UP = N / 128;
  if (type == ABLASLT_F16) {
    size_t KT = K / 16;
    for (uint32_t j = 0; j < NP; ++j)
      for (size_t kt = 0; kt < KT; ++kt) {
        uint8_t* o = dst + ((size_t)j * KT + kt) * 2048;
        memcpy(o, src + ((size_t)(j / 2) * KT + kt) * 2048 + (j % 2) * 1024, 1024);
        memcpy(o + 1024, src + ((size_t)(UP + j / 2) * KT + kt) * 2048 + (j % 2) * 1024, 1024);
      }
  } else {
    size_t KB = K / 32, qbytes = (size_t)N * K / 2;
    for (uint32_t j = 0; j < NP; ++j)
      for (size_t kb = 0; kb < KB; ++kb) {
        for (int hh = 0; hh < 2; ++hh) {
          uint8_t* o = dst + (((size_t)j * KB + kb) * 2 + hh) * 512;
          memcpy(o, src + (((size_t)(j / 2) * KB + kb) * 2 + hh) * 512 + (j % 2) * 256, 256);
          memcpy(o + 256, src + (((size_t)(UP + j / 2) * KB + kb) * 2 + hh) * 512 + (j % 2) * 256, 256);
        }
        uint8_t* o = dst + qbytes + ((size_t)j * KB + kb) * 128;
        memcpy(o, src + qbytes + ((size_t)(j / 2) * KB + kb) * 128 + (j % 2) * 64, 64);
        memcpy(o + 64, src + qbytes + ((size_t)(UP + j / 2) * KB + kb) * 128 + (j % 2) * 64, 64);
      }
  }
}

ablas_status ablasLtWeightPack(ablasLtType type, ablasLtWeightUse use, ablasLtWeightSource kind, const void* src,
                               uint32_t N, uint32_t K, void* dst) {
  if ((type != ABLASLT_F16 && type != ABLASLT_Q4_0) || N % 64 || K % 64 || !src || !dst) return ABLAS_BAD_SHAPE;
  if (use == ABLASLT_WEIGHT_GATE_UP && N % 128) return ABLAS_BAD_SHAPE;
  if (kind == ABLASLT_SRC_GGML_Q4_0 && type != ABLASLT_Q4_0) return ABLAS_UNSUPPORTED;
  size_t bytes = ablasLtWeightSize(type, N, K);
  uint8_t* plain = use == ABLASLT_WEIGHT_PLAIN ? dst : malloc(bytes);
  if (!plain) return ABLAS_VK_ERROR;
  if (kind == ABLASLT_SRC_PACKED) {
    memcpy(plain, src, bytes);
  } else if (type == ABLASLT_F16) {
    _Float16* o = (_Float16*)plain;
    for (uint32_t n = 0; n < N; ++n)
      for (uint32_t k = 0; k < K; ++k) o[tile_index(n, k, K)] = (_Float16)src_value(kind, src, (size_t)n * K + k);
  } else if (kind == ABLASLT_SRC_GGML_Q4_0) {
    ablas_q4_0_from_ggml(src, N, K, plain);
  } else {  // fp32 / fp16 rows -> ggml Q4_0 blocks -> AdrenoBLAS's layout
    uint8_t* blocks = malloc((size_t)N * (K / 32) * 18);
    float* row = malloc((size_t)K * 4);
    for (uint32_t n = 0; n < N; ++n) {
      for (uint32_t k = 0; k < K; ++k) row[k] = src_value(kind, src, (size_t)n * K + k);
      quantize_q4_0_row(row, K, blocks + (size_t)n * (K / 32) * 18);
    }
    ablas_q4_0_from_ggml(blocks, N, K, plain);
    free(row), free(blocks);
  }
  if (use == ABLASLT_WEIGHT_GATE_UP) {
    interleave_gate_up(type, plain, N, K, dst);
    free(plain);
  }
  return ABLAS_OK;
}

void ablasLtWeightRow(ablasLtType type, const void* w, uint32_t N, uint32_t K, uint32_t n, float* out) {
  const uint8_t* base = w;
  for (uint32_t k = 0; k < K; ++k) {
    if (type == ABLASLT_F16) {
      out[k] = (float)((const _Float16*)base)[tile_index(n, k, K)];
    } else {
      size_t KB = K / 32, blk = (size_t)(n / 64) * KB + k / 32;
      uint32_t kk = k % 16, hh = (k % 32) / 16, wd = kk / 8, j = (kk % 8) / 2, hi = kk % 2;
      uint32_t word = ((const uint32_t*)base)[((blk * 2 + hh) * 64 + n % 64) * 2 + wd];
      uint32_t nib = (word >> (4 * j + 16 * hi)) & 15;
      const _Float16* sc = (const _Float16*)(base + (size_t)N * K / 2);
      out[k] = ((float)nib - 8.0f) * (float)sc[blk * 64 + n % 64];
    }
  }
}
