// AdrenoBLAS runtime: kernel selection from the on-device tuning table, pipeline creation per shape,
// push-descriptor dispatch. See ablas.h.
//
// Kernels carry M, N, K as SPIR-V specialization constants, but each pipeline is built from a copy in which
// they are rewritten to plain OpConstant values (specialize()): with real specialization the Adreno 850
// driver (E17.52.10.04) made the NN kernel 2x slower and one TN kernel hang the GPU.
#include "ablas.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "ablas_kernels.h"

#define NKERNELS (sizeof(ablas_kernels) / sizeof(ablas_kernels[0]))
#define NTUNED (sizeof(ablas_tuning) / sizeof(ablas_tuning[0]))
#define TRANSPOSE_KERNEL 0xffff    // 32x32 tile, any multiple of 32
#define TRANSPOSE64_KERNEL 0xfffe  // 64x64 tile, 128-bit loads/stores, multiples of 64; optional panel output
#define PANEL_COPY_KERNEL 0xfffd   // K-major source -> panel layout

typedef struct {
  uint32_t kernel, m, n, k;
  VkPipeline pipeline;
} pipe_t;

struct ablas_ctx {
  VkDevice dev;
  VkDescriptorSetLayout dsl;
  VkPipelineLayout layout;
  VkPipelineCache cache;
  pipe_t* pipes;
  size_t npipes, cap;
  const char* last;
  int pack_to_tn;
  PFN_vkCreateShaderModule CreateShaderModule;
  PFN_vkDestroyShaderModule DestroyShaderModule;
  PFN_vkCreateDescriptorSetLayout CreateDescriptorSetLayout;
  PFN_vkDestroyDescriptorSetLayout DestroyDescriptorSetLayout;
  PFN_vkCreatePipelineLayout CreatePipelineLayout;
  PFN_vkDestroyPipelineLayout DestroyPipelineLayout;
  PFN_vkCreatePipelineCache CreatePipelineCache;
  PFN_vkDestroyPipelineCache DestroyPipelineCache;
  PFN_vkCreateComputePipelines CreateComputePipelines;
  PFN_vkDestroyPipeline DestroyPipeline;
  PFN_vkCmdBindPipeline CmdBindPipeline;
  PFN_vkCmdPushDescriptorSetKHR CmdPushDescriptorSetKHR;
  PFN_vkCmdDispatch CmdDispatch;
  PFN_vkCmdPipelineBarrier CmdPipelineBarrier;
};

ablas_status ablas_create(ablas_handle* out, VkPhysicalDevice pd, VkDevice dev, PFN_vkGetInstanceProcAddr gipa,
                          VkInstance inst) {
  PFN_vkGetPhysicalDeviceProperties2 props2 =
      (PFN_vkGetPhysicalDeviceProperties2)gipa(inst, "vkGetPhysicalDeviceProperties2");
  VkPhysicalDeviceSubgroupProperties sg = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES};
  VkPhysicalDeviceProperties2 p2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2, &sg};
  props2(pd, &p2);
  if (sg.subgroupSize != 64) return ABLAS_UNSUPPORTED;  // the kernels map one 64-lane subgroup per tile
  PFN_vkGetDeviceProcAddr gdpa = (PFN_vkGetDeviceProcAddr)gipa(inst, "vkGetDeviceProcAddr");
  struct ablas_ctx* h = calloc(1, sizeof *h);
  h->dev = dev;
  h->pack_to_tn = 1;
#define LOAD(f) h->f = (PFN_vk##f)gdpa(dev, "vk" #f)
  LOAD(CreateShaderModule); LOAD(DestroyShaderModule); LOAD(CreateDescriptorSetLayout);
  LOAD(DestroyDescriptorSetLayout); LOAD(CreatePipelineLayout); LOAD(DestroyPipelineLayout);
  LOAD(CreatePipelineCache); LOAD(DestroyPipelineCache); LOAD(CreateComputePipelines); LOAD(DestroyPipeline);
  LOAD(CmdBindPipeline); LOAD(CmdPushDescriptorSetKHR); LOAD(CmdDispatch); LOAD(CmdPipelineBarrier);
#undef LOAD
  if (!h->CmdPushDescriptorSetKHR) { free(h); return ABLAS_UNSUPPORTED; }
  VkDescriptorSetLayoutBinding b[3];
  for (uint32_t i = 0; i < 3; ++i)
    b[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO};
  dli.flags = VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR;
  dli.bindingCount = 3;
  dli.pBindings = b;
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO};
  pli.setLayoutCount = 1;
  pli.pSetLayouts = &h->dsl;
  VkPipelineCacheCreateInfo pci = {VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO};
  if (h->CreateDescriptorSetLayout(dev, &dli, NULL, &h->dsl) || h->CreatePipelineLayout(dev, &pli, NULL, &h->layout) ||
      h->CreatePipelineCache(dev, &pci, NULL, &h->cache)) {
    ablas_destroy(h);
    return ABLAS_VK_ERROR;
  }
  *out = h;
  return ABLAS_OK;
}

void ablas_destroy(ablas_handle h) {
  if (!h) return;
  for (size_t i = 0; i < h->npipes; ++i) h->DestroyPipeline(h->dev, h->pipes[i].pipeline, NULL);
  if (h->cache) h->DestroyPipelineCache(h->dev, h->cache, NULL);
  if (h->layout) h->DestroyPipelineLayout(h->dev, h->layout, NULL);
  if (h->dsl) h->DestroyDescriptorSetLayout(h->dev, h->dsl, NULL);
  free(h->pipes);
  free(h);
}

const char* ablas_last_kernel(ablas_handle h) { return h->last; }

size_t ablas_hgemm_workspace_size(ablas_op opA, ablas_op opB, uint32_t M, uint32_t N, uint32_t K) {
  // worst case: every operand not given as P gets packed (to TN or to panels)
  return (opA != ABLAS_OP_P ? (size_t)M * K * 2 : 0) + (opB != ABLAS_OP_P ? (size_t)K * N * 2 : 0);
}

void ablas_set_pack(ablas_handle h, int pack_to_tn) { h->pack_to_tn = pack_to_tn; }

// Copy of a SPIR-V module with the constants decorated SpecId 0..2 turned into OpConstant vals[0..2] and
// their SpecId decorations removed. Returns the word count of out (out has room for `words`).
static size_t specialize(const uint32_t* in, size_t words, const uint32_t vals[3], uint32_t* out) {
  uint32_t ids[3] = {0, 0, 0};
  for (size_t i = 5; i < words; i += in[i] >> 16)  // OpDecorate <id> SpecId <n>
    if ((in[i] & 0xffff) == 71 && in[i + 2] == 1 && in[i + 3] < 3) ids[in[i + 3]] = in[i + 1];
  size_t o = 5;
  memcpy(out, in, 5 * 4);
  for (size_t i = 5; i < words; i += in[i] >> 16) {
    uint32_t op = in[i] & 0xffff, n = in[i] >> 16;
    int spec = -1;
    for (int j = 0; j < 3; ++j)
      if (ids[j] && ((op == 71 && in[i + 2] == 1 && in[i + 1] == ids[j]) || (op == 50 && in[i + 2] == ids[j]))) spec = j;
    if (spec >= 0 && op == 71) continue;  // drop the decoration
    if (spec >= 0 && op == 50) {          // OpSpecConstant <type> <id> <v> -> OpConstant <type> <id> <vals[j]>
      out[o++] = (4u << 16) | 43u;
      out[o++] = in[i + 1];
      out[o++] = in[i + 2];
      out[o++] = vals[spec];
      continue;
    }
    memcpy(out + o, in + i, n * 4);
    o += n;
  }
  return o;
}

// Pipeline for (kernel, m, n, k); pack kernels take their own three constants (see their .comp files).
static VkPipeline get_pipeline(ablas_handle h, uint32_t kernel, uint32_t m, uint32_t n, uint32_t k) {
  for (size_t i = 0; i < h->npipes; ++i) {
    pipe_t* p = &h->pipes[i];
    if (p->kernel == kernel && p->m == m && p->n == n && p->k == k) return p->pipeline;
  }
  uint32_t vals[3] = {m, n, k};
  const uint32_t* spv = kernel == TRANSPOSE_KERNEL     ? ablas_transpose_spv
                        : kernel == TRANSPOSE64_KERNEL ? ablas_transpose64_spv
                        : kernel == PANEL_COPY_KERNEL  ? ablas_panel_copy_spv
                                                       : ablas_kernels[kernel].spv;
  size_t words = kernel == TRANSPOSE_KERNEL     ? sizeof(ablas_transpose_spv) / 4
                 : kernel == TRANSPOSE64_KERNEL ? sizeof(ablas_transpose64_spv) / 4
                 : kernel == PANEL_COPY_KERNEL  ? sizeof(ablas_panel_copy_spv) / 4
                                                : ablas_kernels[kernel].words;
  uint32_t* code = malloc(words * 4);
  VkShaderModuleCreateInfo mi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO};
  mi.codeSize = specialize(spv, words, vals, code) * 4;
  mi.pCode = code;
  VkShaderModule mod;
  VkResult r = h->CreateShaderModule(h->dev, &mi, NULL, &mod);
  free(code);
  if (r) return VK_NULL_HANDLE;
  VkComputePipelineCreateInfo ci = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  ci.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  ci.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  ci.stage.module = mod;
  ci.stage.pName = "main";
  ci.layout = h->layout;
  VkPipeline pl;
  r = h->CreateComputePipelines(h->dev, h->cache, 1, &ci, NULL, &pl);
  h->DestroyShaderModule(h->dev, mod, NULL);
  if (r) return VK_NULL_HANDLE;
  if (h->npipes == h->cap) {
    h->cap = h->cap ? 2 * h->cap : 16;
    h->pipes = realloc(h->pipes, h->cap * sizeof *h->pipes);
  }
  h->pipes[h->npipes++] = (pipe_t){kernel, m, n, k, pl};
  return pl;
}

// Kernel for a layout and shape: the tuned entry nearest in log-space whose tile divides the shape;
// otherwise the smallest-tile kernel of that layout that divides it.
static int select_kernel(char la, char lb, uint32_t M, uint32_t N, uint32_t K) {
  int best = -1;
  double bestd = 1e30;
  for (size_t i = 0; i < NTUNED; ++i) {
    const ablas_tune_t* t = &ablas_tuning[i];
    const ablas_kernel_t* kk = &ablas_kernels[t->kernel];
    if (t->la != la || t->lb != lb || M % kk->bm || N % kk->bn) continue;
    double d = fabs(log((double)M / t->m)) + fabs(log((double)N / t->n)) + fabs(log((double)K / t->k));
    if (d < bestd) bestd = d, best = t->kernel;
  }
  if (best >= 0) return best;
  for (size_t i = 0; i < NKERNELS; ++i) {
    const ablas_kernel_t* kk = &ablas_kernels[i];
    if (kk->la == la && kk->lb == lb && M % kk->bm == 0 && N % kk->bn == 0 &&
        (best < 0 || kk->bm * kk->bn < ablas_kernels[best].bm * ablas_kernels[best].bn))
      best = (int)i;
  }
  return best;
}

static void push(ablas_handle h, VkCommandBuffer cmd, ablas_buf a, ablas_buf b, ablas_buf c) {
  VkDescriptorBufferInfo bi[3] = {{a.buffer, a.offset, VK_WHOLE_SIZE},
                                  {b.buffer, b.offset, VK_WHOLE_SIZE},
                                  {c.buffer, c.offset, VK_WHOLE_SIZE}};
  VkWriteDescriptorSet w[3];
  for (uint32_t i = 0; i < 3; ++i)
    w[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, VK_NULL_HANDLE, i, 0, 1,
                                  VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi[i], NULL};
  h->CmdPushDescriptorSetKHR(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, h->layout, 0, 3, w);
}

// Records dst[C,R] = transpose(src[R,C]) (R, C multiples of 32); W = 64 / 32 writes A / B panels instead
// (dst row = k, needs R, C multiples of 64).
static ablas_status transpose(ablas_handle h, VkCommandBuffer cmd, ablas_buf src, ablas_buf dst, uint32_t R, uint32_t C,
                              uint32_t W) {
  int wide = R % 64 == 0 && C % 64 == 0;
  if (W && !wide) return ABLAS_BAD_SHAPE;
  VkPipeline tp = get_pipeline(h, wide ? TRANSPOSE64_KERNEL : TRANSPOSE_KERNEL, R, C, W);
  if (!tp) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, tp);
  push(h, cmd, src, src, dst);
  h->CmdDispatch(cmd, C / (wide ? 64 : 32), R / (wide ? 64 : 32), 1);
  return ABLAS_OK;
}

// Panel packing: K-major sources are re-tiled by a 128-bit copy, the others transposed straight into panels.
static ablas_status pack_panel(ablas_handle h, VkCommandBuffer cmd, int kmajor, uint32_t X, uint32_t K, uint32_t W,
                               ablas_buf src, ablas_buf dst) {
  if (X % W || K % 16) return ABLAS_BAD_SHAPE;
  if (!kmajor) return transpose(h, cmd, src, dst, X, K, W);  // src [X, K]
  VkPipeline p = get_pipeline(h, PANEL_COPY_KERNEL, K, X, W);  // src [K, X]
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push(h, cmd, src, src, dst);
  h->CmdDispatch(cmd, (uint32_t)(((size_t)K * X / 8 + 255) / 256), 1, 1);
  return ABLAS_OK;
}

ablas_status ablas_pack_a(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, uint32_t M, uint32_t K, ablas_buf A,
                          ablas_buf dst) {
  return opA == ABLAS_OP_P ? ABLAS_BAD_SHAPE : pack_panel(h, cmd, opA == ABLAS_OP_T, M, K, 64, A, dst);
}

ablas_status ablas_pack_b(ablas_handle h, VkCommandBuffer cmd, ablas_op opB, uint32_t K, uint32_t N, ablas_buf B,
                          ablas_buf dst) {
  return opB == ABLAS_OP_P ? ABLAS_BAD_SHAPE : pack_panel(h, cmd, opB == ABLAS_OP_N, N, K, 64, B, dst);  // 16 x 64 B tiles
}

static void compute_barrier(ablas_handle h, VkCommandBuffer cmd) {
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT};
  h->CmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &mb, 0,
                        NULL, 0, NULL);
}

ablas_status ablas_hgemm(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, ablas_op opB, uint32_t M, uint32_t N,
                         uint32_t K, ablas_buf A, ablas_buf B, ablas_buf C, ablas_buf ws) {
  if (M % 64 || N % 32 || K % 32 || !M || !N || !K) return ABLAS_BAD_SHAPE;
  // Panels: operands given as P, or big GEMMs. Panel kernels with one 64 x 64 tile per subgroup reach 13.8 TFLOP/s
  // at 2048^3 and 14.1 at 4096^3 (TN: 10.8 / 9.4); packing both operands costs ~0.4 ms at 2048^3, about what
  // panels save there, so on-the-fly packing starts at 2^35 multiply-adds. B panels are 64 wide: N % 64.
  int panel_ok = N % 64 == 0 && (opA != ABLAS_OP_N || K % 64 == 0) && (opB != ABLAS_OP_T || K % 64 == 0);
  // NT (X @ W^T with a PyTorch weight) transposes both operands on either path, so from 2^31 multiply-adds it
  // goes to panels (2048^3: 10.1 vs 8.7 TFLOP/s); below that, packing B only and running NN is faster (1024^3).
  int nt = opA == ABLAS_OP_N && opB == ABLAS_OP_T && (double)M * N * K >= 2147483648.0;
  if (opA == ABLAS_OP_P || opB == ABLAS_OP_P ||
      (h->pack_to_tn && panel_ok && (nt || (double)M * N * K >= 34359738368.0))) {
    ablas_status st;
    ablas_buf wsA = ws, wsB = {ws.buffer, ws.offset + (opA != ABLAS_OP_P ? (VkDeviceSize)M * K * 2 : 0)};
    if (opA != ABLAS_OP_P || opB != ABLAS_OP_P) {
      if (!ws.buffer) return ABLAS_BAD_SHAPE;
      if (opA != ABLAS_OP_P && (st = ablas_pack_a(h, cmd, opA, M, K, A, wsA))) return st;
      if (opB != ABLAS_OP_P && (st = ablas_pack_b(h, cmd, opB, K, N, B, wsB))) return st;
      if (opA != ABLAS_OP_P) A = wsA;
      if (opB != ABLAS_OP_P) B = wsB;
      compute_barrier(h, cmd);
    }
    opA = opB = ABLAS_OP_P;
  }
  // Packing: the 850 is fastest with both operands K-major (TN). With pack_to_tn (the default) A stored [M,K]
  // is transposed to [K,M] and B stored [N,K] to [K,N] in the workspace first; without it only NT packs B
  // (direct NT kernels run at 2.4 TFLOP/s) and NN/TT use their own kernels.
  // Measured on the 850 with transpose64 (79 GB/s): packing B [N,K] always pays (TT 1024^3: 9.3 packed vs
  // 7.7 direct; direct NT kernels: 2.4 TFLOP/s), packing A [M,K] only for big GEMMs (NN 2048^3: 9.6 packed vs
  // 8.1 direct; NN 1024^3: 9.2 packed vs 10.1 direct), so A is packed from 2^31 multiply-adds up.
  int big = (double)M * N * K >= 2147483648.0 || h->pack_to_tn == 2;
  int packA = opA == ABLAS_OP_N && h->pack_to_tn && big;  // (no-ops once both are panels)
  int packB = opB == ABLAS_OP_T && (h->pack_to_tn || opA == ABLAS_OP_N);
  if (packA || packB) {
    if (!ws.buffer) return ABLAS_BAD_SHAPE;
    ablas_buf wsA = ws, wsB = {ws.buffer, ws.offset + (packA ? (VkDeviceSize)M * K * 2 : 0)};
    ablas_status st;
    if (packA) {  // A [M,K] -> [K,M]
      if ((st = transpose(h, cmd, A, wsA, M, K, 0))) return st;
      A = wsA, opA = ABLAS_OP_T;
    }
    if (packB) {  // B [N,K] -> [K,N]
      if ((st = transpose(h, cmd, B, wsB, N, K, 0))) return st;
      B = wsB, opB = ABLAS_OP_N;
    }
    compute_barrier(h, cmd);
  }
  char la = "NTP"[opA], lb = "NTQ"[opB];  // panels: A 'P' (64 x 16 tiles), B 'Q' (16 x 64 tiles)
  int kernel = select_kernel(la, lb, M, N, K);
  if (kernel < 0) return ABLAS_BAD_SHAPE;
  const ablas_kernel_t* kk = &ablas_kernels[kernel];
  VkPipeline p = get_pipeline(h, (uint32_t)kernel, M, N, K);
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push(h, cmd, A, B, C);
  h->CmdDispatch(cmd, N / kk->bn, M / kk->bm, 1);
  h->last = kk->name;
  return ABLAS_OK;
}
