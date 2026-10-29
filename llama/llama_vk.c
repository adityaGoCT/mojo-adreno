// llama_vk: Llama 3.2 1B decode on the phone's GPU, with the Mojo-compiled SPIR-V kernels of
// llama/kernels (Vulkan). Batch 1, fp16 weights, fp32 activations and KV cache.
//
//   llama_vk <model dir> <kernel dir> <max new tokens> <prompt token ids...>
//
// <model dir>: weights.bin + manifest.txt from llama/export.py. <kernel dir>: <kernel>.spv from
// llama/build_kernels.py (stock or turnip flavour; LD_LIBRARY_PATH picks the driver, VK_RUN_API=1.3
// for Turnip). The prompt runs one token at a time through the decode path; then max_new tokens are
// generated greedily (argmax on the CPU). Output: one line per generated token, "tok <id> <ms>".
//   LLAMA_EOS=128001,128009   stop tokens          LLAMA_LOGITS=<file>   logits after the prompt (fp32)
//   LLAMA_DEBUG=1             first token one dispatch per submit, reporting each kernel and x[0..1]
//   LLAMA_PREFILL=<dir>       batched prefill with the prefill840 kernels in <dir> (build_kernels.py):
//                             all prompt tokens at once, the matmuls on KHR cooperative matrices
//                             (Adreno 8xx, Vulkan 1.3), then decode as above
//   LLAMA_PROFILE=1           with LLAMA_PREFILL: first each prefill dispatch alone, time per kernel
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <vulkan/vulkan.h>

// Llama 3.2 1B; must match llama/kernels and the manifest header
enum { D = 2048, L = 16, H = 32, KVH = 8, HD = 64, F = 8192, V = 128256, MAXPOS = 512, CHUNKS = 4 };
enum { QKV = (H + 2 * KVH) * HD, CHUNK_ROWS = V / CHUNKS };

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
static VkDeviceSize align;  // minStorageBufferOffsetAlignment

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
  return b;
}

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

// ---- weights: manifest lines "<name> <offset> <bytes>" after a header "llama D L H KVH HD F V MAXPOS"
typedef struct { char name[32]; buf_t b; } tensor_t;
static tensor_t tensors[256];
static int ntensors;

static buf_t* tensor(const char* name) {
  for (int i = 0; i < ntensors; ++i)
    if (!strcmp(tensors[i].name, name)) return &tensors[i].b;
  fprintf(stderr, "missing tensor %s\n", name);
  exit(2);
}

static void load_weights(const char* dir) {
  char path[512];
  snprintf(path, sizeof path, "%s/manifest.txt", dir);
  FILE* m = fopen(path, "r");
  if (!m) { fprintf(stderr, "cannot open %s\n", path); exit(2); }
  int hd[9];
  if (fscanf(m, "llama %d %d %d %d %d %d %d %d %d", &hd[0], &hd[1], &hd[2], &hd[3], &hd[4], &hd[5], &hd[6], &hd[7], &hd[8]) != 9 ||
      hd[0] != D || hd[1] != L || hd[2] != H || hd[3] != KVH || hd[4] != HD || hd[5] != F || hd[6] != V || hd[7] != MAXPOS ||
      hd[8] != CHUNKS) {
    fprintf(stderr, "manifest does not match the compiled model shape\n");
    exit(2);
  }
  snprintf(path, sizeof path, "%s/weights.bin", dir);
  int fd = open(path, O_RDONLY);
  if (fd < 0) { fprintf(stderr, "cannot open %s\n", path); exit(2); }
  char name[32];
  long long off, bytes, total = 0;
  double t0 = now_ms();
  while (fscanf(m, "%31s %lld %lld", name, &off, &bytes) == 3) {
    tensor_t* t = &tensors[ntensors++];
    snprintf(t->name, sizeof t->name, "%s", name);
    t->b = make_buffer(bytes);
    for (long long done = 0; done < bytes;) {
      ssize_t r = pread(fd, (char*)t->b.map + done, bytes - done, off + done);
      if (r <= 0) { fprintf(stderr, "read %s failed\n", name); exit(2); }
      done += r;
    }
    total += bytes;
  }
  fclose(m);
  close(fd);
  printf("weights: %d tensors, %.2f GB in %.1f s\n", ntensors, total / 1e9, (now_ms() - t0) / 1e3);
}

// ---- kernels: binding counts follow the Mojo signatures (pointer args, then a params buffer)
typedef struct { const char* name; int nbind; VkDescriptorSetLayout dsl; VkPipelineLayout pl; VkPipeline pipe; } kernel_t;
static kernel_t kernels[] = {{"embed", 3}, {"rmsnorm", 3}, {"gemv", 4}, {"gemv_add", 4},
                             {"rope_kv", 6}, {"attention", 5}, {"silu_mul", 2},
                             {"p_rmsnorm", 3}, {"p_gemm", 4}, {"p_add", 2},
                             {"p_rope_kv", 5}, {"p_attention", 4}, {"p_silu_mul", 2}};
enum { K_EMBED, K_RMSNORM, K_GEMV, K_GEMV_ADD, K_ROPE_KV, K_ATTENTION, K_SILU_MUL, NKERNELS,
       K_P_RMSNORM = NKERNELS, K_P_GEMM, K_P_ADD, K_P_ROPE_KV, K_P_ATTENTION, K_P_SILU_MUL, NALL };

static void load_kernels(const char* dir, int first, int last) {
  for (int k = first; k < last; ++k) {
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
    VkDescriptorSetLayoutBinding b[8];
    for (int i = 0; i < kn->nbind; ++i)
      b[i] = (VkDescriptorSetLayoutBinding){(uint32_t)i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
    VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, (uint32_t)kn->nbind, b};
    CHECK(vkCreateDescriptorSetLayout(dev, &dli, NULL, &kn->dsl));
    VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &kn->dsl};
    CHECK(vkCreatePipelineLayout(dev, &pli, NULL, &kn->pl));
    VkComputePipelineCreateInfo cpi = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
    cpi.stage = (VkPipelineShaderStageCreateInfo){VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO, NULL, 0,
                                                  VK_SHADER_STAGE_COMPUTE_BIT, sm, "main", NULL};
    cpi.layout = kn->pl;
    CHECK(vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &cpi, NULL, &kn->pipe));
    free(code);
  }
}

// ---- dispatches: a buffer slice per binding
typedef struct { const buf_t* b; VkDeviceSize off, size; } arg_t;
typedef struct { int k; VkDescriptorSet set; uint32_t groups, gy; } dispatch_t;
static dispatch_t plan[CHUNKS][256];
static int nplan;
static VkDescriptorPool pool;

static arg_t whole(const buf_t* b) { return (arg_t){b, 0, b->size}; }

static dispatch_t make_dispatch2(int k, uint32_t groups, uint32_t gy, const arg_t* args) {
  dispatch_t d = {k, VK_NULL_HANDLE, groups, gy};
  VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, pool, 1, &kernels[k].dsl};
  CHECK(vkAllocateDescriptorSets(dev, &dai, &d.set));
  VkDescriptorBufferInfo bi[8];
  VkWriteDescriptorSet w[8];
  for (int i = 0; i < kernels[k].nbind; ++i) {
    bi[i] = (VkDescriptorBufferInfo){args[i].b->buf, args[i].off, args[i].size};
    w[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, d.set, (uint32_t)i, 0, 1,
                                  VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi[i], NULL};
  }
  vkUpdateDescriptorSets(dev, (uint32_t)kernels[k].nbind, w, 0, NULL);
  return d;
}

static dispatch_t make_dispatch(int k, uint32_t groups, const arg_t* args) { return make_dispatch2(k, groups, 1, args); }

// Records dispatches with a barrier after each, the last one to the host.
static void record(VkCommandBuffer cmd, const dispatch_t* ds, int n) {
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT};
  VkMemoryBarrier host = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_HOST_READ_BIT};
  VkCommandBufferBeginInfo bbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  CHECK(vkBeginCommandBuffer(cmd, &bbi));
  for (int i = 0; i < n; ++i) {
    vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, kernels[ds[i].k].pipe);
    vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, kernels[ds[i].k].pl, 0, 1, &ds[i].set, 0, NULL);
    vkCmdDispatch(cmd, ds[i].groups, ds[i].gy, 1);
    vkCmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
                         i == n - 1 ? VK_PIPELINE_STAGE_HOST_BIT : VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0,
                         1, i == n - 1 ? &host : &mb, 0, NULL, 0, NULL);
  }
  CHECK(vkEndCommandBuffer(cmd));
}

static void submit_wait(VkQueue q, VkCommandBuffer cmd) {
  VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
  si.commandBufferCount = 1;
  si.pCommandBuffers = &cmd;
  CHECK(vkQueueSubmit(q, 1, &si, VK_NULL_HANDLE));
  CHECK(vkQueueWaitIdle(q));
}

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: %s model_dir kernel_dir max_new token_ids...\n", argv[0]); return 2; }
  int max_new = atoi(argv[3]), nprompt = argc - 4;
  if (nprompt + max_new > MAXPOS) { fprintf(stderr, "prompt + new tokens > %d\n", MAXPOS); return 2; }
  int eos[8], neos = 0;
  for (char* s = getenv("LLAMA_EOS"); s && *s && neos < 8; s = strchr(s, ',') ? strchr(s, ',') + 1 : "") eos[neos++] = atoi(s);
  const char* prefill = getenv("LLAMA_PREFILL");
  int tp = (nprompt + 127) / 128 * 128;  // prefill rows: the prompt padded to the matmul block
  if (prefill && tp > MAXPOS) { fprintf(stderr, "prefill: %d padded prompt rows > %d\n", tp, MAXPOS); return 2; }

  // ---- Vulkan device: fp16 math and storage, 8-bit storage (resource names), int64 where available
  void* lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) { fprintf(stderr, "dlopen libvulkan.so: %s\n", dlerror()); return 2; }
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "llama_vk", 1, NULL, 0, VK_API_VERSION_1_1};
  const char* api = getenv("VK_RUN_API");
  if ((api && !strcmp(api, "1.3")) || prefill) app.apiVersion = VK_API_VERSION_1_3;
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
  align = props.limits.minStorageBufferOffsetAlignment;
  printf("device: %s  Vulkan %u.%u\n", props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion), VK_API_VERSION_MINOR(props.apiVersion));
  if ((CHUNK_ROWS * 4) % align) { fprintf(stderr, "logits chunk offset not aligned to %llu\n", (unsigned long long)align); return 2; }

  uint32_t nq = 0, qfam = 0;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, NULL);
  VkQueueFamilyProperties qf[16];
  if (nq > 16) nq = 16;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, qf);
  for (uint32_t i = 0; i < nq; ++i) if (qf[i].queueFlags & VK_QUEUE_COMPUTE_BIT) { qfam = i; break; }
  VkPhysicalDevice16BitStorageFeatures s16 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES};
  VkPhysicalDevice8BitStorageFeatures s8 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES, &s16};
  VkPhysicalDeviceShaderFloat16Int8Features f16i8 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES, &s8};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &f16i8};
  // prefill: cooperative matrices, which need the Vulkan memory model
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  VkPhysicalDeviceVulkanMemoryModelFeatures vmm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES, &cm};
  if (prefill) s16.pNext = &vmm;
  vkGetPhysicalDeviceFeatures2(pd, &f2);
  if (prefill && (!cm.cooperativeMatrix || !vmm.vulkanMemoryModel)) { fprintf(stderr, "prefill: no cooperative matrices\n"); return 2; }
  if (!f16i8.shaderFloat16 || !s16.storageBuffer16BitAccess) { fprintf(stderr, "need shaderFloat16 + storageBuffer16BitAccess\n"); return 2; }
  VkPhysicalDeviceFeatures2 en = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &f16i8};
  en.features.shaderInt64 = f2.features.shaderInt64;
  en.features.shaderInt16 = f2.features.shaderInt16;
  s16.uniformAndStorageBuffer16BitAccess = s16.storagePushConstant16 = s16.storageInputOutput16 = VK_FALSE;
  s8.uniformAndStorageBuffer8BitAccess = s8.storagePushConstant8 = VK_FALSE;
  const char* want[] = {"VK_KHR_16bit_storage", "VK_KHR_8bit_storage", "VK_KHR_shader_float16_int8",
                        "VK_KHR_storage_buffer_storage_class", "VK_KHR_spirv_1_4", "VK_KHR_shader_float_controls",
                        "VK_KHR_cooperative_matrix"};
  uint32_t nx = 0, ne = 0;
  vkEnumerateDeviceExtensionProperties(pd, NULL, &nx, NULL);
  VkExtensionProperties* xp = calloc(nx, sizeof *xp);
  vkEnumerateDeviceExtensionProperties(pd, NULL, &nx, xp);
  const char* exts[8];
  for (int i = 0; i < (prefill ? 7 : 6); ++i)
    for (uint32_t j = 0; j < nx; ++j)
      if (!strcmp(want[i], xp[j].extensionName)) { exts[ne++] = want[i]; break; }
  float prio = 1.0f;
  VkDeviceQueueCreateInfo qci = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, qfam, 1, &prio};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &en};
  dci.queueCreateInfoCount = 1;
  dci.pQueueCreateInfos = &qci;
  dci.enabledExtensionCount = ne;
  dci.ppEnabledExtensionNames = exts;
  CHECK(vkCreateDevice(pd, &dci, NULL, &dev));
  VkQueue q;
  vkGetDeviceQueue(dev, qfam, 0, &q);

  load_weights(argv[1]);
  load_kernels(argv[2], 0, NKERNELS);
  if (prefill) load_kernels(prefill, NKERNELS, NALL);

  // ---- activations, KV cache, scalar parameters (int64 slots: row, pos, 2048, 8192)
  buf_t x = make_buffer(D * 4), xn = make_buffer(D * 4), qkv = make_buffer(QKV * 4), att = make_buffer(D * 4);
  buf_t gu = make_buffer(2 * F * 4), act = make_buffer(F * 4), logits = make_buffer((VkDeviceSize)V * 4);
  buf_t kc[L], vc[L];
  for (int l = 0; l < L; ++l) {
    kc[l] = make_buffer((VkDeviceSize)KVH * MAXPOS * HD * 4);
    vc[l] = make_buffer((VkDeviceSize)KVH * MAXPOS * HD * 4);
  }
  VkDeviceSize slot = align < 64 ? 64 : align;
  buf_t par = make_buffer(4 * slot);
  int64_t* row = (int64_t*)par.map;
  int64_t* pos = (int64_t*)((char*)par.map + slot);
  *(int64_t*)((char*)par.map + 2 * slot) = D;
  *(int64_t*)((char*)par.map + 3 * slot) = F;
  arg_t p_row = {&par, 0, 64}, p_pos = {&par, slot, 64}, p_d = {&par, 2 * slot, 64}, p_f = {&par, 3 * slot, 64};

  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 4096};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1024, 1, &ps};
  CHECK(vkCreateDescriptorPool(dev, &dpi, NULL, &pool));

  // ---- the per-token plan (the same for every embedding chunk except the first dispatch)
  dispatch_t body[256];
  int nb = 0;
  char nm[32];
  for (int l = 0; l < L; ++l) {
#define T(fmt) (snprintf(nm, sizeof nm, fmt, l), tensor(nm))
    body[nb++] = make_dispatch(K_RMSNORM, 1, (arg_t[]){whole(&x), whole(T("l%d.attn_norm")), whole(&xn)});
    body[nb++] = make_dispatch(K_GEMV, QKV, (arg_t[]){whole(T("l%d.wqkv")), whole(&xn), whole(&qkv), p_d});
    body[nb++] = make_dispatch(K_ROPE_KV, 5, (arg_t[]){whole(&qkv), whole(tensor("rope.cos")), whole(tensor("rope.sin")),
                                                        whole(&kc[l]), whole(&vc[l]), p_pos});
    body[nb++] = make_dispatch(K_ATTENTION, H, (arg_t[]){whole(&qkv), whole(&kc[l]), whole(&vc[l]), whole(&att), p_pos});
    body[nb++] = make_dispatch(K_GEMV_ADD, D, (arg_t[]){whole(T("l%d.wo")), whole(&att), whole(&x), p_d});
    body[nb++] = make_dispatch(K_RMSNORM, 1, (arg_t[]){whole(&x), whole(T("l%d.mlp_norm")), whole(&xn)});
    body[nb++] = make_dispatch(K_GEMV, 2 * F, (arg_t[]){whole(T("l%d.wgu")), whole(&xn), whole(&gu), p_d});
    body[nb++] = make_dispatch(K_SILU_MUL, F / 256, (arg_t[]){whole(&gu), whole(&act)});
    body[nb++] = make_dispatch(K_GEMV_ADD, D, (arg_t[]){whole(T("l%d.wdown")), whole(&act), whole(&x), p_f});
  }
  body[nb++] = make_dispatch(K_RMSNORM, 1, (arg_t[]){whole(&x), whole(tensor("final_norm")), whole(&xn)});
  for (int c = 0; c < CHUNKS; ++c) {  // lm_head = the (tied) embedding table, one chunk at a time
    snprintf(nm, sizeof nm, "embed.%d", c);
    arg_t out = {&logits, (VkDeviceSize)c * CHUNK_ROWS * 4, (VkDeviceSize)CHUNK_ROWS * 4};
    body[nb++] = make_dispatch(K_GEMV, CHUNK_ROWS, (arg_t[]){whole(tensor(nm)), whole(&xn), out, p_d});
  }

  // ---- one command buffer per embedding chunk: embed(row of chunk c), then the body
  VkCommandPoolCreateInfo cpo = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL, VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, qfam};
  VkCommandPool cpool;
  CHECK(vkCreateCommandPool(dev, &cpo, NULL, &cpool));
  VkCommandBuffer cmd[CHUNKS];
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, cpool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, CHUNKS};
  CHECK(vkAllocateCommandBuffers(dev, &cai, cmd));
  VkMemoryBarrier host = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_HOST_READ_BIT};
  for (int c = 0; c < CHUNKS; ++c) {
    snprintf(nm, sizeof nm, "embed.%d", c);
    plan[c][0] = make_dispatch(K_EMBED, D / 256, (arg_t[]){whole(tensor(nm)), whole(&x), p_row});
    memcpy(&plan[c][1], body, nb * sizeof *body);
    record(cmd[c], plan[c], nb + 1);
  }
  nplan = nb + 1;
  printf("plan: %d dispatches per token\n", nplan);

  // ---- batched prefill: per layer the decode body's steps for all tp rows at once, then the final
  // norm and lm_head (the decode body's last 1 + CHUNKS dispatches) on the last prompt token
  buf_t xr = {0};
  VkCommandBuffer pcmd = VK_NULL_HANDLE, tcmd = VK_NULL_HANDLE;
  if (prefill) {
    xr = make_buffer((VkDeviceSize)tp * D * 4);
    buf_t xnr = make_buffer((VkDeviceSize)tp * D * 4), qkvr = make_buffer((VkDeviceSize)tp * QKV * 4);
    buf_t attr = make_buffer((VkDeviceSize)tp * D * 4), gur = make_buffer((VkDeviceSize)tp * 2 * F * 4);
    buf_t actr = make_buffer((VkDeviceSize)tp * F * 4), yr = make_buffer((VkDeviceSize)tp * D * 4);
    buf_t pg = make_buffer(4 * slot);  // p_gemm's (n, k): qkv, o, gate/up, down
    int64_t nk[4][2] = {{QKV, D}, {D, D}, {2 * F, D}, {D, F}};
    for (int i = 0; i < 4; ++i) memcpy((char*)pg.map + i * slot, nk[i], 16);
    arg_t g_qkv = {&pg, 0, 16}, g_o = {&pg, slot, 16}, g_gu = {&pg, 2 * slot, 16}, g_down = {&pg, 3 * slot, 16};
    static dispatch_t pp[L * 11];
    int npp = 0;
    uint32_t rb = tp / 128;
    for (int l = 0; l < L; ++l) {
      pp[npp++] = make_dispatch2(K_P_RMSNORM, tp, 1, (arg_t[]){whole(&xr), whole(T("l%d.attn_norm")), whole(&xnr)});
      pp[npp++] = make_dispatch2(K_P_GEMM, QKV / 128, rb, (arg_t[]){whole(T("l%d.wqkv")), whole(&xnr), whole(&qkvr), g_qkv});
      pp[npp++] = make_dispatch2(K_P_ROPE_KV, 5, tp, (arg_t[]){whole(&qkvr), whole(tensor("rope.cos")), whole(tensor("rope.sin")),
                                                                 whole(&kc[l]), whole(&vc[l])});
      pp[npp++] = make_dispatch2(K_P_ATTENTION, H, tp / 64, (arg_t[]){whole(&qkvr), whole(&kc[l]), whole(&vc[l]), whole(&attr)});
      pp[npp++] = make_dispatch2(K_P_GEMM, D / 128, rb, (arg_t[]){whole(T("l%d.wo")), whole(&attr), whole(&yr), g_o});
      pp[npp++] = make_dispatch2(K_P_ADD, D / 256, tp, (arg_t[]){whole(&xr), whole(&yr)});
      pp[npp++] = make_dispatch2(K_P_RMSNORM, tp, 1, (arg_t[]){whole(&xr), whole(T("l%d.mlp_norm")), whole(&xnr)});
      pp[npp++] = make_dispatch2(K_P_GEMM, 2 * F / 128, rb, (arg_t[]){whole(T("l%d.wgu")), whole(&xnr), whole(&gur), g_gu});
      pp[npp++] = make_dispatch2(K_P_SILU_MUL, F / 256, tp, (arg_t[]){whole(&gur), whole(&actr)});
      pp[npp++] = make_dispatch2(K_P_GEMM, D / 128, rb, (arg_t[]){whole(T("l%d.wdown")), whole(&actr), whole(&yr), g_down});
      pp[npp++] = make_dispatch2(K_P_ADD, D / 256, tp, (arg_t[]){whole(&xr), whole(&yr)});
    }
    VkCommandBuffer two[2];
    VkCommandBufferAllocateInfo ai2 = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, cpool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 2};
    CHECK(vkAllocateCommandBuffers(dev, &ai2, two));
    pcmd = two[0];
    tcmd = two[1];
    record(pcmd, pp, npp);
    record(tcmd, body + nb - 1 - CHUNKS, 1 + CHUNKS);
    printf("prefill: %d dispatches for %d rows (%d prompt tokens)\n", npp, tp, nprompt);
    if (getenv("LLAMA_PROFILE")) {  // each prefill dispatch on its own submit, time per kernel
      double per[NALL] = {0};
      for (int i = 0; i < npp; ++i) {
        double ts = now_ms();
        record(two[0], &pp[i], 1);
        submit_wait(q, two[0]);
        per[pp[i].k] += now_ms() - ts;
      }
      for (int k = NKERNELS; k < NALL; ++k) printf("prefill profile: %-11s %8.1f ms\n", kernels[k].name, per[k]);
      record(pcmd, pp, npp);
    }
  }

  if (getenv("LLAMA_DEBUG")) {  // step through the first token: which dispatch faults or produces NaN?
    int t0k = atoi(argv[4]);
    *row = t0k % CHUNK_ROWS;
    *pos = 0;
    VkCommandBuffer one;
    VkCommandBufferAllocateInfo ai1 = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, cpool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
    CHECK(vkAllocateCommandBuffers(dev, &ai1, &one));
    VkCommandBufferBeginInfo bbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO, NULL, VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT};
    for (int i = 0; i < nplan; ++i) {
      dispatch_t* d = &plan[t0k / CHUNK_ROWS][i];
      CHECK(vkBeginCommandBuffer(one, &bbi));
      vkCmdBindPipeline(one, VK_PIPELINE_BIND_POINT_COMPUTE, kernels[d->k].pipe);
      vkCmdBindDescriptorSets(one, VK_PIPELINE_BIND_POINT_COMPUTE, kernels[d->k].pl, 0, 1, &d->set, 0, NULL);
      vkCmdDispatch(one, d->groups, d->gy, 1);
      vkCmdPipelineBarrier(one, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_HOST_BIT, 0, 1, &host, 0, NULL, 0, NULL);
      CHECK(vkEndCommandBuffer(one));
      VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
      si.commandBufferCount = 1;
      si.pCommandBuffers = &one;
      double ts = now_ms();
      CHECK(vkQueueSubmit(q, 1, &si, VK_NULL_HANDLE));
      VkResult r = vkQueueWaitIdle(q);
      printf("dispatch %3d %-9s groups %6u %8.2f ms  x %.6g %.6g  xn %.6g  qkv %.6g %.6g  att %.6g %.6g  gu %.6g  act %.6g -> %d\n",
             i, kernels[d->k].name, d->groups, now_ms() - ts, ((float*)x.map)[0], ((float*)x.map)[1], ((float*)xn.map)[0],
             ((float*)qkv.map)[0], ((float*)qkv.map)[2048], ((float*)att.map)[0], ((float*)att.map)[1],
             ((float*)gu.map)[0], ((float*)act.map)[0], (int)r);
      fflush(stdout);
      if (r != VK_SUCCESS) return 1;
    }
    return 0;
  }

  // ---- prompt, then greedy decode
  int tok = atoi(argv[4]), ngen = 0;
  double t0 = now_ms(), tgen = 0;
  for (int p = prefill ? nprompt - 1 : 0; p < nprompt + max_new; ++p) {
    double ts = now_ms();
    if (prefill && p == nprompt - 1) {  // the whole prompt at once; the embedding rows on the CPU
      float* xm = (float*)xr.map;
      memset(xm, 0, (size_t)tp * D * 4);
      for (int t = 0; t < nprompt; ++t) {
        int id = atoi(argv[4 + t]);
        snprintf(nm, sizeof nm, "embed.%d", id / CHUNK_ROWS);
        const __fp16* e = (const __fp16*)tensor(nm)->map + (size_t)(id % CHUNK_ROWS) * D;
        for (int i = 0; i < D; ++i) xm[(size_t)t * D + i] = e[i];
      }
      double tg = now_ms();
      submit_wait(q, pcmd);
      double tl = now_ms();
      memcpy(x.map, xm + (size_t)(nprompt - 1) * D, D * 4);
      submit_wait(q, tcmd);
      printf("prefill: embed %.1f ms, layers %.1f ms, lm_head %.1f ms\n", tg - ts, tl - tg, now_ms() - tl);
    } else {
      if (p < nprompt) tok = atoi(argv[4 + p]);
      *row = tok % CHUNK_ROWS;
      *pos = p;
      submit_wait(q, cmd[tok / CHUNK_ROWS]);
    }
    if (p < nprompt - 1) continue;
    const float* lg = (const float*)logits.map;
    if (p == nprompt - 1) {
      printf("prompt: %d tokens in %.0f ms\n", nprompt, now_ms() - t0);
      const char* lf = getenv("LLAMA_LOGITS");
      FILE* f = lf ? fopen(lf, "wb") : NULL;
      if (f) { fwrite(lg, 4, V, f); fclose(f); }
    }
    int best = 0;
    for (int i = 1; i < V; ++i) if (lg[i] > lg[best]) best = i;
    double ms = now_ms() - ts;
    if (p >= nprompt) tgen += ms;
    tok = best;
    printf("tok %d %.1f\n", tok, ms);
    fflush(stdout);
    int stop = ++ngen >= max_new;
    for (int i = 0; i < neos; ++i) stop |= tok == eos[i];
    if (stop) break;
  }
  if (ngen > 1) printf("decode: %d tokens, %.1f ms/token (%.2f tokens/s)\n", ngen - 1, tgen / (ngen - 1), (ngen - 1) * 1e3 / tgen);
  printf("done\n");
  return 0;
}
