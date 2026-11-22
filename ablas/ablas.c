// AdrenoBLAS runtime: kernel selection from the on-device tuning table, pipeline creation per shape,
// push-descriptor dispatch. See ablas.h.
//
// Kernels carry M, N, K as SPIR-V specialization constants, but each pipeline is built from a copy in which
// they are rewritten to plain OpConstant values (specialize()): with real specialization the Adreno 850
// driver (E17.52.10.04) made the NN kernel 2x slower and one TN kernel hang the GPU.
#include "ablas.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ablas_kernels.h"
#include "ablas_kernels_840.h"
#include "ablas_kernels_q4.h"

#define NKERNELS (sizeof(ablas_kernels) / sizeof(ablas_kernels[0]))
#define NTUNED (sizeof(ablas_tuning) / sizeof(ablas_tuning[0]))
#define TRANSPOSE_KERNEL 0xffff    // 32x32 tile, any multiple of 32
#define TRANSPOSE64_KERNEL 0xfffe  // 64x64 tile, 128-bit loads/stores, multiples of 64; optional panel output
#define TILE_COPY_KERNEL 0xfffd    // K-minor source -> K-minor tiles (no transpose)
#define COPY840_KERNEL 0xfffc      // Adreno 840: plain 16-byte copy (pack of an operand already in TN layout)
#define PACKF32_KERNEL 0xfffb      // fp32 [M, K] -> fp16 K-minor tiles, rows padded to 64
#define Q4GGML_KERNEL 0xfffa       // ggml block_q4_0 rows -> AdrenoBLAS Q4_0 layout
#define K840_BASE 0x8000           // Adreno 840: ablas840_kernels[kernel - K840_BASE]
#define Q4_BASE 0x4000             // Q4_0: ablas_q4_kernels[kernel - Q4_BASE]

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
  int a840, turnip;  // Adreno 840 ALU backend (ablas_kernels_840.h); its driver is Mesa Turnip, not Qualcomm's
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
  PFN_vkCmdPushConstants CmdPushConstants;
  PFN_vkCmdPipelineBarrier CmdPipelineBarrier;
  // Descriptor-set mode (ablas_use_descriptor_sets): ordinary descriptor sets from these pools, reset by the caller
  int use_sets;
  VkDescriptorPool* pools;
  uint32_t npools, cur_pool, used_in_pool;
  PFN_vkCreateDescriptorPool CreateDescriptorPool;
  PFN_vkDestroyDescriptorPool DestroyDescriptorPool;
  PFN_vkResetDescriptorPool ResetDescriptorPool;
  PFN_vkAllocateDescriptorSets AllocateDescriptorSets;
  PFN_vkUpdateDescriptorSets UpdateDescriptorSets;
  PFN_vkCmdBindDescriptorSets CmdBindDescriptorSets;
};

#define ABLAS_SETS_PER_POOL 1024u

ablas_status ablas_create(ablas_handle* out, VkPhysicalDevice pd, VkDevice dev, PFN_vkGetInstanceProcAddr gipa,
                          VkInstance inst) {
  PFN_vkGetPhysicalDeviceProperties2 props2 =
      (PFN_vkGetPhysicalDeviceProperties2)gipa(inst, "vkGetPhysicalDeviceProperties2");
  VkPhysicalDeviceDriverProperties drv = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES};
  VkPhysicalDeviceSubgroupProperties sg = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES, &drv};
  VkPhysicalDeviceProperties2 p2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2, &sg};
  props2(pd, &p2);
  if (sg.subgroupSize != 64) return ABLAS_UNSUPPORTED;  // the kernels map one 64-lane subgroup per tile
  PFN_vkGetDeviceProcAddr gdpa = (PFN_vkGetDeviceProcAddr)gipa(inst, "vkGetDeviceProcAddr");
  struct ablas_ctx* h = calloc(1, sizeof *h);
  h->dev = dev;
  h->pack_to_tn = 1;
  // Backend by device, not by cooperative-matrix support (the 840's stock driver offers it too, on the ALUs):
  // Adreno 840 (chip 0x44050a31) -> ALU kernels; everything else keeps the 850 cooperative-matrix path.
  h->a840 = strstr(p2.properties.deviceName, "840") != NULL ||
            (p2.properties.vendorID == 0x5143 && p2.properties.deviceID == 0x44050a31);
  h->turnip = drv.driverID == VK_DRIVER_ID_MESA_TURNIP;
#define LOAD(f) h->f = (PFN_vk##f)gdpa(dev, "vk" #f)
  LOAD(CreateShaderModule); LOAD(DestroyShaderModule); LOAD(CreateDescriptorSetLayout);
  LOAD(DestroyDescriptorSetLayout); LOAD(CreatePipelineLayout); LOAD(DestroyPipelineLayout);
  LOAD(CreatePipelineCache); LOAD(DestroyPipelineCache); LOAD(CreateComputePipelines); LOAD(DestroyPipeline);
  LOAD(CmdBindPipeline); LOAD(CmdPushDescriptorSetKHR); LOAD(CmdDispatch); LOAD(CmdPipelineBarrier);
  LOAD(CmdPushConstants); LOAD(CreateDescriptorPool); LOAD(DestroyDescriptorPool); LOAD(ResetDescriptorPool);
  LOAD(AllocateDescriptorSets); LOAD(UpdateDescriptorSets); LOAD(CmdBindDescriptorSets);
#undef LOAD
  h->use_sets = !h->CmdPushDescriptorSetKHR;  // no VK_KHR_push_descriptor: ordinary descriptor sets
  VkDescriptorSetLayoutBinding b[4];  // A, B, C, epilogue workspace
  for (uint32_t i = 0; i < 4; ++i)
    b[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO};
  dli.flags = h->use_sets ? 0 : VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR;
  dli.bindingCount = 4;
  dli.pBindings = b;
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO};
  VkPushConstantRange pcr = {VK_SHADER_STAGE_COMPUTE_BIT, 0, 16};  // epilogue parameters (ABLAS_EPI_F32: mrows)
  pli.setLayoutCount = 1;
  pli.pSetLayouts = &h->dsl;
  pli.pushConstantRangeCount = 1;
  pli.pPushConstantRanges = &pcr;
  VkPipelineCacheCreateInfo pci = {VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO};
  if (h->CreateDescriptorSetLayout(dev, &dli, NULL, &h->dsl) || h->CreatePipelineLayout(dev, &pli, NULL, &h->layout) ||
      h->CreatePipelineCache(dev, &pci, NULL, &h->cache)) {
    ablas_destroy(h);
    return ABLAS_VK_ERROR;
  }
  *out = h;
  return ABLAS_OK;
}

ablas_status ablas_use_descriptor_sets(ablas_handle h) {
  if (h->use_sets) return ABLAS_OK;
  if (h->npipes) return ABLAS_UNSUPPORTED;  // the pipelines were made with the push-descriptor layout
  h->DestroyPipelineLayout(h->dev, h->layout, NULL);
  h->DestroyDescriptorSetLayout(h->dev, h->dsl, NULL);
  h->layout = VK_NULL_HANDLE, h->dsl = VK_NULL_HANDLE;
  VkDescriptorSetLayoutBinding b[4];
  for (uint32_t i = 0; i < 4; ++i)
    b[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, 4, b};
  VkPushConstantRange pcr = {VK_SHADER_STAGE_COMPUTE_BIT, 0, 16};
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO};
  pli.setLayoutCount = 1, pli.pSetLayouts = &h->dsl, pli.pushConstantRangeCount = 1, pli.pPushConstantRanges = &pcr;
  if (h->CreateDescriptorSetLayout(h->dev, &dli, NULL, &h->dsl) || h->CreatePipelineLayout(h->dev, &pli, NULL, &h->layout))
    return ABLAS_VK_ERROR;
  h->use_sets = 1;
  return ABLAS_OK;
}

void ablas_reset_descriptor_sets(ablas_handle h) {
  for (uint32_t i = 0; i < h->npools && i <= h->cur_pool; ++i) h->ResetDescriptorPool(h->dev, h->pools[i], 0);
  h->cur_pool = 0, h->used_in_pool = 0;
}

static VkDescriptorSet alloc_set(ablas_handle h) {
  if (h->npools && h->used_in_pool == ABLAS_SETS_PER_POOL) ++h->cur_pool, h->used_in_pool = 0;
  if (h->cur_pool == h->npools) {
    VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 4 * ABLAS_SETS_PER_POOL};
    VkDescriptorPoolCreateInfo pi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, ABLAS_SETS_PER_POOL, 1, &ps};
    VkDescriptorPool pool;
    VkResult r = h->CreateDescriptorPool(h->dev, &pi, NULL, &pool);
    if (r) { fprintf(stderr, "ablas: vkCreateDescriptorPool failed (%d)\n", r); return VK_NULL_HANDLE; }
    h->pools = realloc(h->pools, (h->npools + 1) * sizeof *h->pools);
    h->pools[h->npools++] = pool;
    h->used_in_pool = 0;
  }
  VkDescriptorSetAllocateInfo ai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, h->pools[h->cur_pool], 1, &h->dsl};
  VkDescriptorSet set = VK_NULL_HANDLE;
  VkResult r = h->AllocateDescriptorSets(h->dev, &ai, &set);
  if (r) { fprintf(stderr, "ablas: vkAllocateDescriptorSets failed (%d), pool %u, %u used\n", r, h->cur_pool, h->used_in_pool); return VK_NULL_HANDLE; }
  ++h->used_in_pool;
  return set;
}

void ablas_destroy(ablas_handle h) {
  if (!h) return;
  for (uint32_t i = 0; i < h->npools; ++i) h->DestroyDescriptorPool(h->dev, h->pools[i], NULL);
  free(h->pools);
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
  const uint32_t* spv = kernel == PACKF32_KERNEL ? ablas_pack_a_f32_spv
                        : kernel == Q4GGML_KERNEL ? ablas_q4_pack_ggml_spv
                        : kernel == TRANSPOSE_KERNEL     ? ablas_transpose_spv
                        : kernel == TRANSPOSE64_KERNEL ? ablas_transpose64_spv
                        : kernel == TILE_COPY_KERNEL   ? ablas_tile_copy_spv
                        : kernel == COPY840_KERNEL     ? ablas840_copy_spv
                        : kernel >= K840_BASE          ? ablas840_kernels[kernel - K840_BASE].spv
                        : kernel >= Q4_BASE            ? ablas_q4_kernels[kernel - Q4_BASE].spv
                                                       : ablas_kernels[kernel].spv;
  size_t words = kernel == PACKF32_KERNEL ? sizeof(ablas_pack_a_f32_spv) / 4
                 : kernel == Q4GGML_KERNEL ? sizeof(ablas_q4_pack_ggml_spv) / 4
                 : kernel == TRANSPOSE_KERNEL     ? sizeof(ablas_transpose_spv) / 4
                 : kernel == TRANSPOSE64_KERNEL ? sizeof(ablas_transpose64_spv) / 4
                 : kernel == TILE_COPY_KERNEL   ? sizeof(ablas_tile_copy_spv) / 4
                 : kernel == COPY840_KERNEL     ? sizeof(ablas840_copy_spv) / 4
                 : kernel >= K840_BASE          ? ablas840_kernels[kernel - K840_BASE].words
                 : kernel >= Q4_BASE            ? ablas_q4_kernels[kernel - Q4_BASE].words
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
// Epilogues whose workspace argument is bound at binding 3 (their output or a bias)
#define EPI_WS(ep) ((ep) == ABLAS_EPI_RESIDUAL_RMS || (ep) == ABLAS_EPI_BIAS_GELU || (ep) == ABLAS_EPI_RESIDUAL_BIAS)

static int select_kernel_ep(char la, char lb, uint32_t M, uint32_t N, uint32_t K, char ep) {
  int best = -1;
  double bestd = 1e30;
  for (size_t i = 0; i < NTUNED; ++i) {
    const ablas_tune_t* t = &ablas_tuning[i];
    const ablas_kernel_t* kk = &ablas_kernels[t->kernel];
    if (t->la != la || t->lb != lb || t->ep != ep || M % kk->bm || N % kk->bn) continue;
    double d = fabs(log((double)M / t->m)) + fabs(log((double)N / t->n)) + fabs(log((double)K / t->k));
    if (d < bestd) bestd = d, best = t->kernel;
  }
  if (best >= 0 || ep) return best;
  for (size_t i = 0; i < NKERNELS; ++i) {
    const ablas_kernel_t* kk = &ablas_kernels[i];
    if (kk->la == la && kk->lb == lb && !kk->ep && M % kk->bm == 0 && N % kk->bn == 0 &&
        (best < 0 || kk->bm * kk->bn < ablas_kernels[best].bm * ablas_kernels[best].bn))
      best = (int)i;
  }
  return best;
}

static int select_kernel(char la, char lb, uint32_t M, uint32_t N, uint32_t K) {
  return select_kernel_ep(la, lb, M, N, K, 0);
}

static void push4(ablas_handle h, VkCommandBuffer cmd, ablas_buf a, ablas_buf b, ablas_buf c, ablas_buf d) {
  VkDescriptorBufferInfo bi[4] = {{a.buffer, a.offset, a.range ? a.range : VK_WHOLE_SIZE},
                                  {b.buffer, b.offset, b.range ? b.range : VK_WHOLE_SIZE},
                                  {c.buffer, c.offset, c.range ? c.range : VK_WHOLE_SIZE},
                                  {d.buffer, d.offset, d.range ? d.range : VK_WHOLE_SIZE}};
  VkWriteDescriptorSet w[4];
  uint32_t n = d.buffer ? 4 : 3;
  for (uint32_t i = 0; i < n; ++i)
    w[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, VK_NULL_HANDLE, i, 0, 1,
                                  VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi[i], NULL};
  if (h->use_sets) {
    VkDescriptorSet set = alloc_set(h);
    for (uint32_t i = 0; i < n; ++i) w[i].dstSet = set;
    h->UpdateDescriptorSets(h->dev, n, w, 0, NULL);
    h->CmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, h->layout, 0, 1, &set, 0, NULL);
  } else {
    h->CmdPushDescriptorSetKHR(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, h->layout, 0, n, w);
  }
}

static void push(ablas_handle h, VkCommandBuffer cmd, ablas_buf a, ablas_buf b, ablas_buf c) {
  push4(h, cmd, a, b, c, (ablas_buf){0});
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

// Packing into K-minor tiles: element (x, k) of A [M,K] or B^T [N,K] at ((x/64)*(K/16) + k/16)*1024 + (x%64)*16 + k%16.
// A stored [M,K] and B stored [N,K] (PyTorch's layouts) are re-tiled by a 128-bit copy; K-major sources
// (A [K,M], B [K,N]) are transposed straight into tiles.
static ablas_status pack_tiles(ablas_handle h, VkCommandBuffer cmd, int kminor, uint32_t X, uint32_t K, ablas_buf src,
                               ablas_buf dst) {
  if (X % 64 || K % 64) return ABLAS_BAD_SHAPE;
  if (!kminor) return transpose(h, cmd, src, dst, K, X, 1);  // src [K, X]
  VkPipeline p = get_pipeline(h, TILE_COPY_KERNEL, X, K, 0);  // src [X, K]
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push(h, cmd, src, src, dst);
  h->CmdDispatch(cmd, K / 64, X / 32, 1);
  return ABLAS_OK;
}

// Adreno 840: the packed format is plain TN (A [K,M], B [K,N]); src stored [X,K] is transposed, src already
// [K,X] is copied. Shapes: multiples of 32 for a transpose, any size for a copy.
static ablas_status pack_840(ablas_handle h, VkCommandBuffer cmd, int kminor, uint32_t X, uint32_t K, ablas_buf src,
                             ablas_buf dst) {
  if (kminor) return X % 32 || K % 32 ? ABLAS_BAD_SHAPE : transpose(h, cmd, src, dst, X, K, 0);
  uint32_t n16 = (uint32_t)((uint64_t)X * K * 2 / 16), groups = (n16 + 63) / 64;
  if (((uint64_t)X * K * 2) % 16) return ABLAS_BAD_SHAPE;
  VkPipeline p = get_pipeline(h, COPY840_KERNEL, n16, 0, 0);
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push(h, cmd, src, src, dst);
  h->CmdDispatch(cmd, groups < 65535 ? groups : 65535, 1, 1);
  return ABLAS_OK;
}

ablas_status ablas_pack_a(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, uint32_t M, uint32_t K, ablas_buf A,
                          ablas_buf dst) {
  if (opA == ABLAS_OP_P) return ABLAS_BAD_SHAPE;
  if (h->a840) return pack_840(h, cmd, opA == ABLAS_OP_N, M, K, A, dst);
  return pack_tiles(h, cmd, opA == ABLAS_OP_N, M, K, A, dst);
}

ablas_status ablas_pack_b(ablas_handle h, VkCommandBuffer cmd, ablas_op opB, uint32_t K, uint32_t N, ablas_buf B,
                          ablas_buf dst) {
  if (opB == ABLAS_OP_P) return ABLAS_BAD_SHAPE;
  if (h->a840) return pack_840(h, cmd, opB == ABLAS_OP_T, N, K, B, dst);
  return pack_tiles(h, cmd, opB == ABLAS_OP_T, N, K, B, dst);
}

static void compute_barrier(ablas_handle h, VkCommandBuffer cmd) {
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT};
  h->CmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &mb, 0,
                        NULL, 0, NULL);
}

// Adreno 840 kernel for a shape and driver: the tuned entry nearest in log-space whose tile divides the shape;
// otherwise the smallest-tile kernel that divides it.
static int select_840(int driver, uint32_t M, uint32_t N, uint32_t K) {
  int best = -1;
  double bestd = 1e30;
  for (const ablas840_tune_t* t = ablas840_tuning; t->driver != 255; ++t) {
    const ablas840_kernel_t* kk = &ablas840_kernels[t->kernel];
    if (t->driver != driver || M % kk->bm || N % kk->bn || K % kk->kstep) continue;
    double d = fabs(log((double)M / t->m)) + fabs(log((double)N / t->n)) + fabs(log((double)K / t->k));
    if (d < bestd) bestd = d, best = t->kernel;
  }
  if (best >= 0) return best;
  for (size_t i = 0; i < sizeof(ablas840_kernels) / sizeof(ablas840_kernels[0]); ++i) {
    const ablas840_kernel_t* kk = &ablas840_kernels[i];
    if (M % kk->bm == 0 && N % kk->bn == 0 && K % kk->kstep == 0 && !strstr(kk->name, "nobankra") &&
        (best < 0 || kk->bm * kk->bn < ablas840_kernels[best].bm * ablas840_kernels[best].bn))
      best = (int)i;
  }
  return best;
}

// Adreno 840 (no matrix unit): fp16 ALU kernels in the TN layout. A stored [M,K] and B stored [N,K] are
// transposed into the workspace first; P operands are already TN (ablas_pack_a/_b on the 840).
static ablas_status hgemm_840(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, ablas_op opB, uint32_t M, uint32_t N,
                              uint32_t K, ablas_buf A, ablas_buf B, ablas_buf C, ablas_buf ws) {
  if (!M || !N || !K || M % 64 || N % 64 || K % 4) return ABLAS_BAD_SHAPE;
  if (opA == ABLAS_OP_P) opA = ABLAS_OP_T;
  if (opB == ABLAS_OP_P) opB = ABLAS_OP_N;
  int packA = opA == ABLAS_OP_N, packB = opB == ABLAS_OP_T;
  if (packA || packB) {
    if (!ws.buffer || K % 32) return ABLAS_BAD_SHAPE;
    ablas_buf wsA = ws, wsB = {ws.buffer, ws.offset + (packA ? (VkDeviceSize)M * K * 2 : 0)};
    ablas_status st;
    if (packA && (st = transpose(h, cmd, A, wsA, M, K, 0))) return st;  // A [M,K] -> [K,M]
    if (packB && (st = transpose(h, cmd, B, wsB, N, K, 0))) return st;  // B [N,K] -> [K,N]
    if (packA) A = wsA;
    if (packB) B = wsB;
    compute_barrier(h, cmd);
  }
  int kernel = select_840(h->turnip, M, N, K);
  if (kernel < 0) return ABLAS_BAD_SHAPE;
  const ablas840_kernel_t* kk = &ablas840_kernels[kernel];
  VkPipeline p = get_pipeline(h, K840_BASE + (uint32_t)kernel, M, N, K);
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push(h, cmd, A, B, C);
  h->CmdDispatch(cmd, N / kk->bn, M / kk->bm, 1);
  h->last = kk->name;
  return ABLAS_OK;
}

// Epilogue variant of a selected kernel: the same configuration with suffix _e<p|g>, else the epilogue kernel of
// the same family (by name prefix) with the biggest tile that divides the shape.
static int with_epilogue(const char* base, char ep, uint32_t M, uint32_t N, int q4) {
  size_t nk = q4 ? sizeof(ablas_q4_kernels) / sizeof(ablas_q4_kernels[0]) : NKERNELS;
  int best = -1;
  uint32_t bestarea = 0;
  for (size_t i = 0; i < nk; ++i) {
    const char* n = q4 ? ablas_q4_kernels[i].name : ablas_kernels[i].name;
    char e = q4 ? ablas_q4_kernels[i].ep : ablas_kernels[i].ep;
    uint32_t bm = q4 ? ablas_q4_kernels[i].bm : ablas_kernels[i].bm, bn = q4 ? ablas_q4_kernels[i].bn : ablas_kernels[i].bn;
    size_t bl = strlen(base);
    if (e != ep || M % bm || N % bn) continue;
    char suf[4] = {'_', 'e', ep, 0};
    if (!strncmp(n, base, bl) && !strcmp(n + bl, suf)) return (int)i;
    if (strncmp(n, base, 3)) continue;  // same family (gRC / q4_)
    if (bm * bn > bestarea) bestarea = bm * bn, best = (int)i;
  }
  return best;
}

ablas_status ablas_hgemm(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, ablas_op opB, uint32_t M, uint32_t N,
                         uint32_t K, ablas_buf A, ablas_buf B, ablas_buf C, ablas_buf ws) {
  return ablas_hgemm_ex(h, cmd, opA, opB, M, N, K, A, B, C, ws, ABLAS_EPI_NONE);
}

ablas_status ablas_hgemm_ex(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, ablas_op opB, uint32_t M, uint32_t N,
                            uint32_t K, ablas_buf A, ablas_buf B, ablas_buf C, ablas_buf ws, ablas_epilogue ep) {
  if (h->a840) return ep ? ABLAS_UNSUPPORTED : hgemm_840(h, cmd, opA, opB, M, N, K, A, B, C, ws);
  if (M % 64 || N % 32 || K % 32 || !M || !N || !K) return ABLAS_BAD_SHAPE;
  if (ep && (N % 64 || K % 64)) return ABLAS_BAD_SHAPE;
  if (EPI_WS(ep) && (opA != ABLAS_OP_P || opB != ABLAS_OP_P || !ws.buffer)) return ABLAS_BAD_SHAPE;
  // Packed tiles (K-minor 64 x 16 / 16 x 64, one 64 x 64 tile per subgroup): 16.5 TFLOP/s at 4096^3 and 14.8 at
  // 2048^3 (TN: 9.4 / 10.8). Used for operands given as P, for NT at any size (PyTorch's X @ W^T: both operands
  // are K-minor, so packing is a plain re-tiling copy), and for everything else from 2^35 multiply-adds, where
  // the transposes K-major sources need are paid back. Needs M, N, K multiples of 64.
  int panel_ok = N % 64 == 0 && K % 64 == 0;  // tiles are 64 wide; the pack kernels work in 64 x 64 blocks
  int nt = opA == ABLAS_OP_N && opB == ABLAS_OP_T;
  if (opA == ABLAS_OP_P || opB == ABLAS_OP_P || ep ||
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
  char la = "NTR"[opA], lb = "NTC"[opB];  // packed: K-minor tiles, A 'R' (64 x 16 row-major), B 'C' (16 x 64 col-major)
  // with an epilogue: a kernel tuned for it at the nearest shape, else the epilogue variant of the plain choice
  int kernel = ep ? select_kernel_ep(la, lb, M, N, K, "_pgaflbr"[ep]) : -1;
  if (kernel < 0) {
    kernel = select_kernel(la, lb, M, N, K);
    if (kernel >= 0 && ep) kernel = with_epilogue(ablas_kernels[kernel].name, "_pgaflbr"[ep], M, N, 0);
  }
  const char* force = getenv(ep ? "ABLAS_KERNEL_EP" : "ABLAS_KERNEL");  // benchmarking aid: kernel by name
  if (force)
    for (size_t i = 0; i < NKERNELS; ++i)
      if (!strcmp(ablas_kernels[i].name, force) && ablas_kernels[i].la == la && ablas_kernels[i].lb == lb &&
          M % ablas_kernels[i].bm == 0 && N % ablas_kernels[i].bn == 0)
        kernel = (int)i;
  if (kernel < 0) return ABLAS_BAD_SHAPE;
  const ablas_kernel_t* kk = &ablas_kernels[kernel];
  VkPipeline p = get_pipeline(h, (uint32_t)kernel, M, N, K);
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push4(h, cmd, A, B, C, EPI_WS(ep) ? ws : (ablas_buf){0});
  h->CmdDispatch(cmd, N / kk->bn, M / kk->bm, 1);
  h->last = kk->name;
  return ABLAS_OK;
}

// ---- Q4_0 weights ----

size_t ablas_q4_0_size(uint32_t N, uint32_t K) { return (size_t)N * K / 2 + (size_t)N * K / 32 * 2; }

// ggml block_q4_0 {fp16 d; uint8 qs[16]} (q[j] = qs[j] & 15, q[j + 16] = qs[j] >> 4), N rows of K/32 blocks ->
// AdrenoBLAS layout (gen_q4.py): quants as uint2 ((p*(K/32) + kb)*2 + h)*64 + n%64 (p = n/64, h = 16-deep half;
// word w, nibble j: low half q[16h + 8w + 2j], high half q[16h + 8w + 2j + 1]), then fp16 scales at
// (p*(K/32) + kb)*64 + n%64.
void ablas_q4_0_from_ggml(const void* src, uint32_t N, uint32_t K, void* dst) {
  const uint8_t* s = src;
  uint32_t KB = K / 32, *qd = dst;
  uint16_t* sd = (uint16_t*)((uint8_t*)dst + (size_t)N * K / 2);
  for (uint32_t n = 0; n < N; ++n)
    for (uint32_t kb = 0; kb < KB; ++kb) {
      const uint8_t* b = s + ((size_t)n * KB + kb) * 18;
      uint8_t q[32];
      for (int j = 0; j < 16; ++j) q[j] = b[2 + j] & 15, q[j + 16] = b[2 + j] >> 4;
      size_t blk = (size_t)(n / 64) * KB + kb;
      for (int hh = 0; hh < 2; ++hh) {
        uint32_t w[2] = {0, 0};
        for (int i = 0; i < 8; ++i)
          w[i / 4] |= (uint32_t)q[16 * hh + 2 * i] << (4 * (i % 4)) | (uint32_t)q[16 * hh + 2 * i + 1] << (16 + 4 * (i % 4));
        size_t idx = (blk * 2 + hh) * 64 + n % 64;
        qd[2 * idx] = w[0], qd[2 * idx + 1] = w[1];
      }
      sd[blk * 64 + n % 64] = (uint16_t)(b[0] | b[1] << 8);
    }
}

static int select_q4(uint32_t M, uint32_t N, uint32_t K, char ep) {
  int best = -1;
  double bestd = 1e30;
  for (const ablas_q4_tune_t* t = ablas_q4_tuning; t->m; ++t) {
    const ablas_q4_kernel_t* kk = &ablas_q4_kernels[t->kernel];
    if (t->ep != ep || M % kk->bm || N % kk->bn || K % kk->kstep) continue;
    double d = fabs(log((double)M / t->m)) + fabs(log((double)N / t->n)) + fabs(log((double)K / t->k));
    if (d < bestd) bestd = d, best = t->kernel;
  }
  if (best >= 0 || ep) return best;
  for (size_t i = 0; i < sizeof(ablas_q4_kernels) / sizeof(ablas_q4_kernels[0]); ++i) {
    const ablas_q4_kernel_t* kk = &ablas_q4_kernels[i];
    if (!kk->ep && M % kk->bm == 0 && N % kk->bn == 0 && K % kk->kstep == 0 &&
        (best < 0 || kk->bm * kk->bn > ablas_q4_kernels[best].bm * ablas_q4_kernels[best].bn))
      best = (int)i;  // untuned: the biggest tile that divides the shape
  }
  return best;
}

ablas_status ablas_hgemm_q4_0(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, uint32_t M, uint32_t N, uint32_t K,
                              ablas_buf A, ablas_buf W, ablas_buf C, ablas_buf ws) {
  return ablas_hgemm_q4_0_ex(h, cmd, opA, M, N, K, A, W, C, ws, ABLAS_EPI_NONE);
}

ablas_status ablas_hgemm_q4_0_ex(ablas_handle h, VkCommandBuffer cmd, ablas_op opA, uint32_t M, uint32_t N, uint32_t K,
                                 ablas_buf A, ablas_buf W, ablas_buf C, ablas_buf ws, ablas_epilogue ep) {
  if (h->a840) return ABLAS_UNSUPPORTED;
  if (!M || !N || !K || M % 64 || N % 64 || K % 32 || opA == ABLAS_OP_T) return ABLAS_BAD_SHAPE;
  if (EPI_WS(ep) && (opA != ABLAS_OP_P || !ws.buffer)) return ABLAS_BAD_SHAPE;
  if (opA == ABLAS_OP_N) {
    ablas_status st;
    if (!ws.buffer) return ABLAS_BAD_SHAPE;
    if ((st = ablas_pack_a(h, cmd, ABLAS_OP_N, M, K, A, ws))) return st;
    A = ws;
    compute_barrier(h, cmd);
  }
  int kernel = ep ? select_q4(M, N, K, "_pgaflbr"[ep]) : -1;
  if (kernel < 0) {
    kernel = select_q4(M, N, K, 0);
    if (kernel >= 0 && ep) kernel = with_epilogue(ablas_q4_kernels[kernel].name, "_pgaflbr"[ep], M, N, 1);
  }
  const char* force = getenv(ep ? "ABLAS_KERNEL_EP" : "ABLAS_KERNEL");
  if (force)
    for (size_t i = 0; i < sizeof(ablas_q4_kernels) / sizeof(ablas_q4_kernels[0]); ++i)
      if (!strcmp(ablas_q4_kernels[i].name, force) && M % ablas_q4_kernels[i].bm == 0 && N % ablas_q4_kernels[i].bn == 0)
        kernel = (int)i;
  if (kernel < 0) return ABLAS_BAD_SHAPE;
  const ablas_q4_kernel_t* kk = &ablas_q4_kernels[kernel];
  VkPipeline p = get_pipeline(h, Q4_BASE + (uint32_t)kernel, M, N, K);
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push4(h, cmd, A, W, C, EPI_WS(ep) ? ws : (ablas_buf){0});
  h->CmdDispatch(cmd, N / kk->bn, M / kk->bm, 1);
  h->last = kk->name;
  return ABLAS_OK;
}

// ---- fp32 activations (llama.cpp / ggml integration) ----

ablas_status ablas_pack_a_f32(ablas_handle h, VkCommandBuffer cmd, uint32_t M, uint32_t K, ablas_buf A, ablas_buf dst) {
  if (h->a840) return ABLAS_UNSUPPORTED;
  if (!M || !K || K % 64) return ABLAS_BAD_SHAPE;
  uint32_t Mp = (M + 63) / 64 * 64;
  VkPipeline p = get_pipeline(h, PACKF32_KERNEL, M, 0, K);
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push(h, cmd, A, A, dst);
  h->CmdDispatch(cmd, K / 64, Mp / 64, 1);
  return ABLAS_OK;
}

ablas_status ablas_q4_0_pack_ggml(ablas_handle h, VkCommandBuffer cmd, uint32_t N, uint32_t K, ablas_buf blocks, ablas_buf dst) {
  if (h->a840) return ABLAS_UNSUPPORTED;
  if (!N || !K || N % 64 || K % 32) return ABLAS_BAD_SHAPE;
  VkPipeline p = get_pipeline(h, Q4GGML_KERNEL, N, 0, K);
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push(h, cmd, blocks, blocks, dst);
  h->CmdDispatch(cmd, (uint32_t)(((uint64_t)N * (K / 32) + 63) / 64), 1, 1);
  return ABLAS_OK;
}

ablas_status ablas_gemm_f32out(ablas_handle h, VkCommandBuffer cmd, int q4, uint32_t M, uint32_t N, uint32_t K,
                               ablas_buf A, ablas_buf W, ablas_buf C) {
  if (h->a840) return ABLAS_UNSUPPORTED;
  if (!M || !N || !K || N % 64 || K % 64) return ABLAS_BAD_SHAPE;
  uint32_t Mp = (M + 63) / 64 * 64, kernel, bm, bn;
  const char* name;
  if (q4) {
    int k = select_q4(Mp, N, K, 'f');
    if (k < 0) {
      k = select_q4(Mp, N, K, 0);
      if (k >= 0) k = with_epilogue(ablas_q4_kernels[k].name, 'f', Mp, N, 1);
    }
    const char* force = getenv("ABLAS_KERNEL_EP");  // benchmarking aid: kernel by name
    if (force)
      for (size_t i = 0; i < sizeof(ablas_q4_kernels) / sizeof(ablas_q4_kernels[0]); ++i)
        if (!strcmp(ablas_q4_kernels[i].name, force) && Mp % ablas_q4_kernels[i].bm == 0 && N % ablas_q4_kernels[i].bn == 0)
          k = (int)i;
    if (k < 0) return ABLAS_BAD_SHAPE;
    kernel = Q4_BASE + (uint32_t)k, bm = ablas_q4_kernels[k].bm, bn = ablas_q4_kernels[k].bn, name = ablas_q4_kernels[k].name;
  } else {
    int k = select_kernel_ep('R', 'C', Mp, N, K, 'f');
    if (k < 0) {
      k = select_kernel('R', 'C', Mp, N, K);
      if (k >= 0) k = with_epilogue(ablas_kernels[k].name, 'f', Mp, N, 0);
    }
    const char* force = getenv("ABLAS_KERNEL_EP");
    if (force)
      for (size_t i = 0; i < sizeof(ablas_kernels) / sizeof(ablas_kernels[0]); ++i)
        if (!strcmp(ablas_kernels[i].name, force) && ablas_kernels[i].la == 'R' && ablas_kernels[i].lb == 'C' &&
            Mp % ablas_kernels[i].bm == 0 && N % ablas_kernels[i].bn == 0)
          k = (int)i;
    if (k < 0) return ABLAS_BAD_SHAPE;
    kernel = (uint32_t)k, bm = ablas_kernels[k].bm, bn = ablas_kernels[k].bn, name = ablas_kernels[k].name;
  }
  VkPipeline p = get_pipeline(h, kernel, Mp, N, K);
  if (!p) return ABLAS_VK_ERROR;
  h->CmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, p);
  push(h, cmd, A, W, C);
  uint32_t pc[4] = {M, 0, 0, 0};
  h->CmdPushConstants(cmd, h->layout, VK_SHADER_STAGE_COMPUTE_BIT, 0, sizeof pc, pc);
  h->CmdDispatch(cmd, N / bn, Mp / bm, 1);
  h->last = name;
  return ABLAS_OK;
}
