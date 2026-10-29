// qwen3_vk: PrismML's Ternary-Bonsai-8B (Qwen3-8B, ternary weights) decode on the Adreno 840 with
// Vulkan. The projections are bonsai/kernels/kernels.mojo's packed ternary kernels (from mav3ri3k/
// modular's Android port, unchanged); qwen3/kernels/qwen3k.mojo has the rest. Batch 1, fp32
// activations and KV cache, the embedding dequantized on the CPU.
//
//   qwen3_vk <model dir> <kernel dir> <max new tokens> <prompt token ids...>
//
// <model dir>: weights.bin + manifest.txt from qwen3/export.py. The prompt runs one token at a time,
// then up to max_new tokens greedily (argmax on the CPU) until <|im_end|> or <|endoftext|>.
// Output: "tok <id> <ms>" lines.
//   QWEN3_REF=<reference.f32>  compare all logits after the prompt and after each token with the
//                              exporter's MLX reference; runs max_new steps even past the stop tokens
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <vulkan/vulkan.h>

#include "../runner/qcom_coopmat.h"

// Qwen3-8B; must match qwen3k.mojo and export.py
enum { D = 4096, L = 36, F = 12288, QKV = 6144, V = 151669, HEAD0 = 74 * 1024 };
enum { EOS = 151645, EOS2 = 151643 };

#define CHECK(x)                                                                         \
  do {                                                                                   \
    VkResult r_ = (x);                                                                   \
    if (r_ != VK_SUCCESS) { fprintf(stderr, "%s:%d %s -> %d\n", __FILE__, __LINE__, #x, (int)r_); exit(2); } \
  } while (0)

#define VK_FUNCS(X)                                                                                   \
  X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties)                  \
  X(vkGetPhysicalDeviceQueueFamilyProperties) X(vkGetPhysicalDeviceMemoryProperties)                  \
  X(vkCreateDevice) X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkGetBufferMemoryRequirements)            \
  X(vkAllocateMemory) X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateShaderModule)                    \
  X(vkCreateDescriptorSetLayout) X(vkCreatePipelineLayout) X(vkCreateComputePipelines)                \
  X(vkCreateDescriptorPool) X(vkAllocateDescriptorSets) X(vkUpdateDescriptorSets)                     \
  X(vkCreateCommandPool) X(vkAllocateCommandBuffers) X(vkBeginCommandBuffer) X(vkEndCommandBuffer)    \
  X(vkCmdBindPipeline) X(vkCmdBindDescriptorSets) X(vkCmdDispatch) X(vkCmdPipelineBarrier)            \
  X(vkQueueSubmit) X(vkQueueWaitIdle) X(vkGetPhysicalDeviceFeatures2) X(vkEnumerateDeviceExtensionProperties)
#define DECL(f) static PFN_##f f;
VK_FUNCS(DECL)

static VkDevice dev;
static VkPhysicalDeviceMemoryProperties memprops;

typedef struct { VkBuffer buf; VkDeviceMemory mem; void* map; VkDeviceSize size; } buf_t;

static buf_t make_buffer(VkDeviceSize size) {
  buf_t b = {0};
  b.size = size;
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
  CHECK(vkCreateBuffer(dev, &bi, NULL, &b.buf));
  VkMemoryRequirements mr;
  vkGetBufferMemoryRequirements(dev, b.buf, &mr);
  uint32_t want = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, ti = 0;
  for (uint32_t i = 0; i < memprops.memoryTypeCount; ++i)
    if ((mr.memoryTypeBits & (1u << i)) && (memprops.memoryTypes[i].propertyFlags & want) == want) { ti = i; break; }
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, NULL, mr.size, ti};
  CHECK(vkAllocateMemory(dev, &ai, NULL, &b.mem));
  CHECK(vkBindBufferMemory(dev, b.buf, b.mem, 0));
  CHECK(vkMapMemory(dev, b.mem, 0, size, 0, &b.map));
  memset(b.map, 0, size);
  return b;
}

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

// ---- weights: manifest lines "<name> <offset> <bytes>" after "qwen3 <capacity>"; the embedding stays
// in host memory (the CPU dequantizes one row per token), everything else becomes a storage buffer
typedef struct { char name[32]; buf_t b; void* host; } tensor_t;
static tensor_t tensors[512];
static int ntensors;

static tensor_t* tensor(const char* name) {
  for (int i = 0; i < ntensors; ++i)
    if (!strcmp(tensors[i].name, name)) return &tensors[i];
  fprintf(stderr, "missing tensor %s\n", name);
  exit(2);
}

static uint32_t load_weights(const char* dir) {
  char path[512];
  snprintf(path, sizeof path, "%s/manifest.txt", dir);
  FILE* m = fopen(path, "r");
  uint32_t cap;
  if (!m || fscanf(m, "qwen3 %u", &cap) != 1) { fprintf(stderr, "bad %s\n", path); exit(2); }
  snprintf(path, sizeof path, "%s/weights.bin", dir);
  int fd = open(path, O_RDONLY);
  if (fd < 0) { fprintf(stderr, "cannot open %s\n", path); exit(2); }
  char name[32];
  long long off, bytes, total = 0;
  double t0 = now_ms();
  while (fscanf(m, "%31s %lld %lld", name, &off, &bytes) == 3) {
    tensor_t* t = &tensors[ntensors++];
    snprintf(t->name, sizeof t->name, "%s", name);
    void* dst;
    if (!strncmp(name, "emb.", 4)) dst = t->host = malloc(bytes);
    else dst = (t->b = make_buffer(bytes)).map;
    for (long long done = 0; done < bytes;) {
      ssize_t r = pread(fd, (char*)dst + done, bytes - done, off + done);
      if (r <= 0) { fprintf(stderr, "read %s failed\n", name); exit(2); }
      done += r;
    }
    total += bytes;
  }
  fclose(m);
  close(fd);
  printf("weights: %d tensors, %.2f GB in %.1f s, context %u\n", ntensors, total / 1e9, (now_ms() - t0) / 1e3, cap);
  return cap;
}

// x = row `token` of the 2-bit embedding: code * scale + bias per group of 128
static void embed(float* x, int token) {
  const uint32_t* w = (const uint32_t*)tensor("emb.w")->host + (size_t)token * (D / 16);
  const __fp16* s = (const __fp16*)tensor("emb.s")->host + (size_t)token * (D / 128);
  const __fp16* b = (const __fp16*)tensor("emb.b")->host + (size_t)token * (D / 128);
  for (int i = 0; i < D; ++i) x[i] = (float)((w[i / 16] >> (2 * (i % 16))) & 3) * (float)s[i / 128] + (float)b[i / 128];
}

// ---- kernels: bindings = the Mojo signature's pointers, then the params buffer if it has scalars
typedef struct { const char* name; int nbind, local; VkDescriptorSetLayout dsl; VkPipelineLayout pl; VkPipeline pipe; } kernel_t;
static kernel_t kernels[] = {{"packed_linear", 5, 64}, {"packed_reduce", 3, 64}, {"packed_head", 6, 128},
                             {"rmsnorm_pack", 4, 64}, {"pack_half", 3, 64}, {"swiglu_pack", 3, 64},
                             {"qk_norm_rope", 7, 64}, {"attn_scores", 4, 64}, {"attn_values", 4, 64}, {"add", 3, 64}};
enum { K_LINEAR, K_REDUCE, K_HEAD, K_RMSNORM, K_PACK, K_SWIGLU, K_QK, K_SCORES, K_VALUES, K_ADD, NKERNELS };

static void load_kernels(const char* dir, int subgroup_control, int full_subgroups) {
  for (int k = 0; k < NKERNELS; ++k) {
    kernel_t* kn = &kernels[k];
    char path[512];
    snprintf(path, sizeof path, "%s/%s.spv", dir, kn->name);
    FILE* f = fopen(path, "rb");
    if (!f) { fprintf(stderr, "cannot open %s\n", path); exit(2); }
    fseek(f, 0, SEEK_END);
    size_t n = (size_t)ftell(f);
    fseek(f, 0, SEEK_SET);
    uint32_t* code = malloc(n);
    if (fread(code, 1, n, f) != n) exit(2);
    fclose(f);
    VkShaderModuleCreateInfo smi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, n, code};
    VkShaderModule sm;
    CHECK(vkCreateShaderModule(dev, &smi, NULL, &sm));
    VkDescriptorSetLayoutBinding bd[8];
    for (int i = 0; i < kn->nbind; ++i)
      bd[i] = (VkDescriptorSetLayoutBinding){(uint32_t)i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
    VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, (uint32_t)kn->nbind, bd};
    CHECK(vkCreateDescriptorSetLayout(dev, &dli, NULL, &kn->dsl));
    VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &kn->dsl};
    CHECK(vkCreatePipelineLayout(dev, &pli, NULL, &kn->pl));
    VkPipelineShaderStageRequiredSubgroupSizeCreateInfo rss = {
        VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO, NULL, 64};
    VkComputePipelineCreateInfo cpi = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
    cpi.stage = (VkPipelineShaderStageCreateInfo){VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
                                                  subgroup_control ? &rss : NULL,
                                                  full_subgroups ? VK_PIPELINE_SHADER_STAGE_CREATE_REQUIRE_FULL_SUBGROUPS_BIT : 0,
                                                  VK_SHADER_STAGE_COMPUTE_BIT, sm, "main", NULL};
    cpi.layout = kn->pl;
    CHECK(vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &cpi, NULL, &kn->pipe));
    free(code);
  }
}

// ---- dispatches: a buffer slice per binding; scalars in 64-bit slots of `par`, one slice each
typedef struct { const buf_t* b; VkDeviceSize off, size; } arg_t;
typedef struct { int k; VkDescriptorSet set; uint32_t gx, gy; } dispatch_t;
static dispatch_t plan[1024];
static int nplan;
static VkDescriptorPool pool;
static buf_t par;
static VkDeviceSize par_slot, par_used;
static int64_t* pos_fields[128];
static int npos;

static arg_t whole(const buf_t* x) { return (arg_t){x, 0, x->size}; }
#define T(name) whole(&tensor(name)->b)
#define B(x) whole(&x)

static arg_t params(int n, const int64_t* v) {
  arg_t a = {&par, par_used, (VkDeviceSize)n * 8};
  memcpy((char*)par.map + par_used, v, (size_t)n * 8);
  par_used += par_slot;
  return a;
}
#define P(...) params(sizeof((int64_t[]){__VA_ARGS__}) / 8, (int64_t[]){__VA_ARGS__})
static int64_t* field(arg_t a, int i) { return (int64_t*)((char*)par.map + a.off) + i; }

static void add(int k, uint32_t gx, uint32_t gy, const arg_t* args) {
  dispatch_t d = {k, VK_NULL_HANDLE, gx, gy};
  VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, pool, 1, &kernels[k].dsl};
  CHECK(vkAllocateDescriptorSets(dev, &dai, &d.set));
  VkDescriptorBufferInfo bi[8];
  VkWriteDescriptorSet wr[8];
  for (int i = 0; i < kernels[k].nbind; ++i) {
    bi[i] = (VkDescriptorBufferInfo){args[i].b->buf, args[i].off, args[i].size};
    wr[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, d.set, (uint32_t)i, 0, 1,
                                   VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi[i], NULL};
  }
  vkUpdateDescriptorSets(dev, (uint32_t)kernels[k].nbind, wr, 0, NULL);
  plan[nplan++] = d;
}

static uint32_t groups(uint32_t work, uint32_t per) { return (work + per - 1) / per; }

static buf_t x, xq, gq, qkv, att, y, gu, partials, scores, logits, cand, kc[L], vc[L];

// y = W q for the packed tensor `name` (n outputs, k inputs): eight-group partials, then their sum
static void project(const char* name, arg_t in, arg_t out, int n, int k) {
  char w[40], s[40];
  snprintf(w, sizeof w, "%s.w", name);
  snprintf(s, sizeof s, "%s.s", name);
  add(K_LINEAR, groups(n, 64), groups(k, 1024), (arg_t[]){in, T(w), T(s), B(partials), P(n, k)});
  add(K_REDUCE, groups(n, 64), 1, (arg_t[]){B(partials), out, P(n, groups(k, 1024))});
}

static void build_plan(uint32_t cap) {
  char nm[40];
#define N(fmt) (snprintf(nm, sizeof nm, fmt, l), nm)
  for (int l = 0; l < L; ++l) {
    add(K_RMSNORM, 1, 1, (arg_t[]){B(x), T(N("l%d.in_norm")), B(xq), P(D)});
    project(N("l%d.qkv"), B(xq), B(qkv), QKV, D);
    arg_t p = P(0);
    pos_fields[npos++] = field(p, 0);
    char q[40], k[40];
    snprintf(q, sizeof q, "l%d.q_norm", l);
    snprintf(k, sizeof k, "l%d.k_norm", l);
    add(K_QK, 48, 1, (arg_t[]){B(qkv), T(q), T(k), T("rope"), B(kc[l]), B(vc[l]), p});
    arg_t ps = P(0, cap), pv = P(0, cap);
    pos_fields[npos++] = field(ps, 0);
    pos_fields[npos++] = field(pv, 0);
    add(K_SCORES, groups(32 * cap, 64), 1, (arg_t[]){B(qkv), B(kc[l]), B(scores), ps});
    add(K_VALUES, D / 64, 1, (arg_t[]){B(scores), B(vc[l]), B(att), pv});
    add(K_PACK, D / 2 / 64, 1, (arg_t[]){B(att), B(xq), P(D)});
    project(N("l%d.o"), B(xq), B(y), D, D);
    add(K_ADD, D / 64, 1, (arg_t[]){B(x), B(y), P(D)});
    add(K_RMSNORM, 1, 1, (arg_t[]){B(x), T(N("l%d.post_norm")), B(xq), P(D)});
    project(N("l%d.gu"), B(xq), B(gu), 2 * F, D);
    add(K_SWIGLU, F / 2 / 64, 1, (arg_t[]){B(gu), B(gq), P(F)});
    project(N("l%d.down"), B(gq), B(y), D, F);
    add(K_ADD, D / 64, 1, (arg_t[]){B(x), B(y), P(D)});
  }
  add(K_RMSNORM, 1, 1, (arg_t[]){B(x), T("final_norm"), B(xq), P(D)});
  arg_t l0 = {&logits, 0, (VkDeviceSize)HEAD0 * 4}, l1 = {&logits, (VkDeviceSize)HEAD0 * 4, (VkDeviceSize)(V - HEAD0) * 4};
  add(K_HEAD, groups(HEAD0, 1024), 1, (arg_t[]){B(xq), T("head0.w"), T("head0.s"), l0, B(cand), P(HEAD0, D, 0)});
  add(K_HEAD, groups(V - HEAD0, 1024), 1, (arg_t[]){B(xq), T("head1.w"), T("head1.s"), l1, B(cand), P(V - HEAD0, D, 0)});
}

static void record(VkCommandBuffer cmd) {
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT};
  VkMemoryBarrier host = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_HOST_READ_BIT};
  VkCommandBufferBeginInfo bbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  CHECK(vkBeginCommandBuffer(cmd, &bbi));
  for (int i = 0; i < nplan; ++i) {
    vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, kernels[plan[i].k].pipe);
    vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, kernels[plan[i].k].pl, 0, 1, &plan[i].set, 0, NULL);
    vkCmdDispatch(cmd, plan[i].gx, plan[i].gy, 1);
    vkCmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
                         i == nplan - 1 ? VK_PIPELINE_STAGE_HOST_BIT : VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0,
                         1, i == nplan - 1 ? &host : &mb, 0, NULL, 0, NULL);
  }
  CHECK(vkEndCommandBuffer(cmd));
}

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: %s model_dir kernel_dir max_new token_ids...\n", argv[0]); return 2; }
  int max_new = atoi(argv[3]), nprompt = argc - 4;
  const char* ref_path = getenv("QWEN3_REF");

  void* lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) { fprintf(stderr, "dlopen libvulkan.so: %s\n", dlerror()); return 2; }
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "qwen3_vk", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO};
  ici.pApplicationInfo = &app;
  VkInstance inst;
  CHECK(vkCreateInstance(&ici, NULL, &inst));
#define LOAD(f) f = (PFN_##f)gipa(inst, #f);
  VK_FUNCS(LOAD)
  uint32_t npd = 1;
  VkPhysicalDevice pd;
  CHECK(vkEnumeratePhysicalDevices(inst, &npd, &pd));
  VkPhysicalDeviceProperties props;
  vkGetPhysicalDeviceProperties(pd, &props);
  vkGetPhysicalDeviceMemoryProperties(pd, &memprops);
  printf("device: %s  Vulkan %u.%u  max storage buffer %u MB\n", props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion),
         VK_API_VERSION_MINOR(props.apiVersion), props.limits.maxStorageBufferRange >> 20);
  uint32_t nq = 0, qfam = 0;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, NULL);
  VkQueueFamilyProperties qf[16];
  if (nq > 16) nq = 16;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, qf);
  for (uint32_t i = 0; i < nq; ++i) if (qf[i].queueFlags & VK_QUEUE_COMPUTE_BIT) { qfam = i; break; }
  VkPhysicalDeviceVulkan13Features v13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES};
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &v13};
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  vkGetPhysicalDeviceFeatures2(pd, &f2);
  // Decode is matrix-vector work, so no cooperative matrices: only report the QCOM extension, for
  // the prompt kernels a batched prefill would add (qcom/p_gemm_t2.comp reads this weight layout).
  uint32_t nx = 0;
  vkEnumerateDeviceExtensionProperties(pd, NULL, &nx, NULL);
  VkExtensionProperties* xp = calloc(nx ? nx : 1, sizeof *xp);
  vkEnumerateDeviceExtensionProperties(pd, NULL, &nx, xp);
  int has_qcom = 0;
  for (uint32_t i = 0; i < nx; ++i) has_qcom |= !strcmp(xp[i].extensionName, QCOM_CONVERSION_NAME);
  free(xp);
  printf("VK_QCOM_cooperative_matrix_conversion: %s (decode does not use matrix units)\n", has_qcom ? "yes" : "no");
  VkPhysicalDeviceVulkan13Features en13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES};
  en13.subgroupSizeControl = v13.subgroupSizeControl;
  en13.computeFullSubgroups = v13.computeFullSubgroups;
  VkPhysicalDeviceVulkan12Features en12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &en13};
  en12.shaderInt8 = v12.shaderInt8;
  en12.shaderFloat16 = v12.shaderFloat16;
  en12.storageBuffer8BitAccess = v12.storageBuffer8BitAccess;
  VkPhysicalDeviceVulkan11Features en11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &en12};
  en11.storageBuffer16BitAccess = v11.storageBuffer16BitAccess;
  VkPhysicalDeviceFeatures2 en = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &en11};
  en.features.shaderInt64 = f2.features.shaderInt64;
  en.features.shaderInt16 = f2.features.shaderInt16;
  float prio = 1.0f;
  VkDeviceQueueCreateInfo qci = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, qfam, 1, &prio};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &en};
  dci.queueCreateInfoCount = 1;
  dci.pQueueCreateInfos = &qci;
  CHECK(vkCreateDevice(pd, &dci, NULL, &dev));
  VkQueue q;
  vkGetDeviceQueue(dev, qfam, 0, &q);

  uint32_t cap = load_weights(argv[1]);
  if (nprompt + max_new > (int)cap) { fprintf(stderr, "prompt + new tokens > context %u\n", cap); return 2; }
  load_kernels(argv[2], v13.subgroupSizeControl, v13.computeFullSubgroups);
  x = make_buffer(D * 4), xq = make_buffer(D * 2), gq = make_buffer(F * 2), qkv = make_buffer(QKV * 4);
  att = make_buffer(D * 4), y = make_buffer(D * 4), gu = make_buffer(2 * F * 4), partials = make_buffer(4 * 2 * F * 4);
  scores = make_buffer(32ull * cap * 4), logits = make_buffer((VkDeviceSize)V * 4), cand = make_buffer(3 * 1024 * 4);
  for (int l = 0; l < L; ++l) kc[l] = make_buffer(1024ull * cap * 4), vc[l] = make_buffer(1024ull * cap * 4);
  par_slot = props.limits.minStorageBufferOffsetAlignment < 64 ? 64 : props.limits.minStorageBufferOffsetAlignment;
  par = make_buffer(2048 * par_slot);
  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 8192};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1024, 1, &ps};
  CHECK(vkCreateDescriptorPool(dev, &dpi, NULL, &pool));
  build_plan(cap);
  printf("plan: %d dispatches per token\n", nplan);
  VkCommandPoolCreateInfo cpo = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL, VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, qfam};
  VkCommandPool cpool;
  CHECK(vkCreateCommandPool(dev, &cpo, NULL, &cpool));
  VkCommandBuffer cmd;
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, cpool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  CHECK(vkAllocateCommandBuffers(dev, &cai, &cmd));
  record(cmd);

  FILE* ref = ref_path ? fopen(ref_path, "rb") : NULL;
  if (ref_path && !ref) { fprintf(stderr, "cannot open %s\n", ref_path); return 2; }
  float* expect = ref ? malloc((size_t)V * 4) : NULL;
  int tok = 0, ngen = 0, failed = 0;
  double t0 = now_ms(), tgen = 0, worst = 0;
  for (int p = 0; p < nprompt + max_new; ++p) {
    if (p < nprompt) tok = atoi(argv[4 + p]);
    if (tok < 0 || tok >= V) { fprintf(stderr, "token %d out of range\n", tok); return 2; }
    double ts = now_ms();
    embed(x.map, tok);
    for (int i = 0; i < npos; ++i) *pos_fields[i] = p;
    VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
    si.commandBufferCount = 1;
    si.pCommandBuffers = &cmd;
    CHECK(vkQueueSubmit(q, 1, &si, VK_NULL_HANDLE));
    CHECK(vkQueueWaitIdle(q));
    if (p < nprompt - 1) continue;
    const float* lg = logits.map;
    int next = 0;
    for (int i = 1; i < V; ++i) if (lg[i] > lg[next]) next = i;
    double ms = now_ms() - ts;
    if (p == nprompt - 1) printf("prompt: %d tokens in %.0f ms\n", nprompt, now_ms() - t0);
    else tgen += ms;
    if (ref) {
      if (fread(expect, 4, V, ref) != V) { fprintf(stderr, "reference has only %d steps\n", ngen); return 2; }
      double maxerr = 0, d2 = 0, r2 = 0;
      int rbest = 0;
      for (int i = 0; i < V; ++i) {
        if (!isfinite(lg[i])) { fprintf(stderr, "logit %d nonfinite\n", i); return 1; }
        double e = fabs((double)lg[i] - expect[i]);
        maxerr = e > maxerr ? e : maxerr;
        d2 += e * e;
        r2 += (double)expect[i] * expect[i];
        if (expect[i] > expect[rbest]) rbest = i;
      }
      failed |= next != rbest;
      worst = maxerr > worst ? maxerr : worst;
      printf("check %2d: token %6d reference %6d  max abs %.6f  rel L2 %.8f %s\n", ngen, next, rbest, maxerr,
             sqrt(d2 / r2), next == rbest ? "OK" : "MISMATCH");
    }
    tok = next;
    printf("tok %d %.1f\n", tok, ms);
    fflush(stdout);
    if (++ngen >= max_new || (!ref && (tok == EOS || tok == EOS2))) break;
  }
  if (ngen > 1) printf("decode: %d tokens, %.1f ms/token (%.2f tokens/s)\n", ngen - 1, tgen / (ngen - 1), (ngen - 1) * 1e3 / tgen);
  if (ref) printf("validation: %d steps, max abs logit error %.6f, %s\n", ngen, worst, failed ? "FAILED" : "all greedy ids match");
  printf("done\n");
  return failed;
}
