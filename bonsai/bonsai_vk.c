// bonsai_vk: Bonsai 2 2B (prism-ml/Ternary-Bonsai-2-2B-mlx-2bit, text only) decode on the Adreno 840
// with Vulkan, running the Mojo kernels of mav3ri3k/modular's Android port (bonsai/kernels/kernels.mojo,
// unchanged) compiled to SPIR-V by bonsai/build_kernels.py. The dispatches follow that port's
// model.mojo forward(), the weight loading its engine.cpp and model_spec.h: batch 1, packed 2-bit
// ternary weights with fp16 group scales, fp32 activations, DeltaNet state and KV caches.
//
//   bonsai_vk <weights.bin> <kernel dir> <max new tokens> <prompt token ids...>
//
// <weights.bin>: from the port's bonsai/prepare.py ("BONSAI01"). The prompt runs one token at a time
// through the decode path, then up to max_new tokens are generated greedily (the head's per-subgroup
// candidates, finished on the CPU) until <|im_end|> or <|endoftext|>. Output: "tok <id> <ms>" lines.
//   BONSAI_REF=<reference.f32>  validate against prepare.py's FP32 logits: after the prompt and after
//                               each token, all 248,320 logits (max abs error, relative L2, greedy
//                               id); runs max_new steps even past the stop tokens
//   BONSAI_PROFILE=1            first token one dispatch per submit, time per kernel
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include <vulkan/vulkan.h>

// Bonsai 2 2B text model; must match kernels.mojo and prepare.py
enum { D = 2048, F = 6144, V = 248320, LAYERS = 24, NW = 605, NB = 69, NCAND = V / 512 };
enum { EOS = 248046, EOS2 = 248044 };

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
  X(vkQueueSubmit) X(vkQueueWaitIdle) X(vkGetPhysicalDeviceFeatures2)
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
  return b;
}

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

// ---- weights: the port's tensor order and sizes (model_spec.h). Per layer 25 tensors from 4 + 25 l:
// input/post norm; gate, up, down (each packed codes, scale/bias pairs, Hadamard signs); then DeltaNet
// layers: in_proj_qkv, in_proj_z, out_proj (packed), in_proj_a, in_proj_b, decay constants, conv,
// gated norm; attention layers (every 4th): q, k, v, o (packed), q norm, k norm. 0-2: the packed
// embedding (also the tied head), 3: final norm, 604: the rope table.
static uint64_t packed_bytes(int part, uint64_t out, uint64_t in) {
  return part == 0 ? out * in / 16 * 4 : part == 1 ? out * in / 128 * 2 * 4 : in * 4;
}

static uint64_t weight_bytes(int i, uint32_t cap) {
  if (i < 3) return packed_bytes(i, V, D);
  if (i == 3) return D * 4;
  if (i == 604) return cap * 64ull * 4;
  int layer = (i - 4) / 25, slot = (i - 4) % 25;
  if (slot < 2) return D * 4;
  if (slot < 11) {
    int group = (slot - 2) / 3, part = (slot - 2) % 3;
    return packed_bytes(part, group == 2 ? D : F, group == 2 ? F : D);
  }
  if ((layer + 1) % 4 == 0) {
    static const int width[] = {4096, 512, 512, 2048};
    return slot >= 23 ? 256 * 4 : packed_bytes((slot - 11) % 3, width[(slot - 11) / 3], D);
  }
  if (slot < 20) return packed_bytes((slot - 11) % 3, slot < 14 ? F : D, D);
  if (slot < 22) return D * 16 * 4;
  if (slot == 22) return 32 * 4;
  if (slot == 23) return F * 4 * 4;
  return 128 * 4;
}

// The scale/bias pairs of packed tensors: groups with bias == -scale, so the kernels take only the
// scale, in fp16 (exact, checked), and compute (code - 1) * scale.
static int centered(int i) {
  if (i == 1) return 1;
  if (i < 4 || i >= 604) return 0;
  int layer = (i - 4) / 25, slot = (i - 4) % 25;
  return slot == 3 || slot == 6 || slot == 9 || slot == 12 || slot == 15 || slot == 18 ||
         ((layer + 1) % 4 == 0 && slot == 21);
}

// Scratch buffers (fp32 elements): 0 residual, 1-12 activations, 13 scores, 14-16 q/k/v, 17 logits,
// 18 rope (the weight), 19 + 2 l / 20 + 2 l per layer conv history and DeltaNet state or K and V
// caches, 67 projection partials, 68 head candidates.
static uint64_t buffer_elements(int i, uint32_t cap) {
  static const uint64_t scratch[] = {2048, 2048, 6144, 6144, 6144, 4096, 16, 16, 32,
                                     6144, 2048, 6144, 6144, 0, 2048, 512, 512, V};
  if (i == 68) return NCAND * 3;
  if (i == 67) return 12288;
  if (i < 18) return i == 13 ? 8ull * cap : scratch[i];
  int layer = (i - 19) / 2, part = (i - 19) % 2;
  return (layer + 1) % 4 == 0 ? 512ull * cap : part == 0 ? 3ull * 6144 : 16ull * 128 * 128;
}

static buf_t w[NW], b[NB];

static void read_at(int fd, void* dst, uint64_t n, uint64_t off) {
  for (uint64_t done = 0; done < n;) {
    ssize_t r = pread(fd, (char*)dst + done, n - done, (off_t)(off + done));
    if (r <= 0) { fprintf(stderr, "truncated weights\n"); exit(2); }
    done += (uint64_t)r;
  }
}

static uint32_t load_weights(const char* path) {
  int fd = open(path, O_RDONLY);
  if (fd < 0) { fprintf(stderr, "cannot open %s\n", path); exit(2); }
  char magic[8];
  uint32_t hdr[2];
  read_at(fd, magic, 8, 0);
  read_at(fd, hdr, 8, 8);
  uint32_t cap = hdr[1];
  if (memcmp(magic, "BONSAI01", 8) || hdr[0] != NW || cap < 1 || cap > 8192) { fprintf(stderr, "not a Bonsai export\n"); exit(2); }
  uint64_t off = 16, total = 0;
  double t0 = now_ms();
  for (int i = 0; i < NW; ++i) {
    uint64_t size;
    read_at(fd, &size, 8, off);
    off += 8;
    if (size != weight_bytes(i, cap)) { fprintf(stderr, "tensor %d: %llu bytes\n", i, (unsigned long long)size); exit(2); }
    if (centered(i)) {
      float* pairs = malloc(size);
      read_at(fd, pairs, size, off);
      w[i] = make_buffer(size / 4);
      __fp16* s = w[i].map;
      for (uint64_t g = 0; g < size / 8; ++g) {
        s[g] = (__fp16)pairs[2 * g];
        if (!isfinite(pairs[2 * g]) || pairs[2 * g + 1] != -pairs[2 * g] || (float)s[g] != pairs[2 * g]) {
          fprintf(stderr, "tensor %d: group %llu is not centered with an fp16 scale\n", i, (unsigned long long)g);
          exit(2);
        }
      }
      free(pairs);
    } else {
      w[i] = make_buffer(size);
      read_at(fd, w[i].map, size, off);
    }
    off += size;
    total += w[i].size;
  }
  struct stat st;
  fstat(fd, &st);
  if ((uint64_t)st.st_size != off) { fprintf(stderr, "trailing data in %s\n", path); exit(2); }
  close(fd);
  printf("weights: %d tensors, %.1f MiB on the GPU in %.1f s, context %u\n", NW, total / 1048576.0, (now_ms() - t0) / 1e3, cap);
  return cap;
}

// ---- kernels: bindings = the Mojo signature's pointers, then the params buffer if it has scalars
typedef struct { const char* name; int nbind, local; VkDescriptorSetLayout dsl; VkPipelineLayout pl; VkPipeline pipe; } kernel_t;
static kernel_t kernels[] = {
    {"hadamard", 5, 64}, {"packed_linear", 5, 64}, {"packed_reduce", 3, 64}, {"packed_head", 6, 128},
    {"embedding", 4, 64}, {"rms_partials", 2, 64}, {"rms_norm", 4, 64}, {"gate_partials", 4, 64},
    {"convolve", 4, 64}, {"normalize_qk", 2, 64}, {"delta_gates", 3, 64}, {"delta_update", 4, 64},
    {"gated_norm", 4, 64}, {"head_norm", 4, 64}, {"rope", 3, 64}, {"cache_kv", 5, 64},
    {"attention_scores", 4, 64}, {"attention_values", 5, 64}, {"residual", 2, 64}, {"swiglu", 2, 64},
    {"copy", 2, 64}};
enum { K_HADAMARD, K_PACKED_LINEAR, K_PACKED_REDUCE, K_PACKED_HEAD, K_EMBEDDING, K_RMS_PARTIALS, K_RMS_NORM,
       K_GATE_PARTIALS, K_CONVOLVE, K_NORMALIZE_QK, K_DELTA_GATES, K_DELTA_UPDATE, K_GATED_NORM, K_HEAD_NORM,
       K_ROPE, K_CACHE_KV, K_ATTENTION_SCORES, K_ATTENTION_VALUES, K_RESIDUAL, K_SWIGLU, K_COPY, NKERNELS };

// The kernels shuffle across 64 lanes (Hadamard stages, reductions): require 64-lane subgroups.
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

static arg_t whole(const buf_t* x) { return (arg_t){x, 0, x->size}; }
#define W(i) whole(&w[i])
#define B(i) whole(&b[i])

static arg_t params(int n, const int64_t* v) {
  arg_t a = {&par, par_used, (VkDeviceSize)n * 8};
  if (par_used + par_slot > par.size) { fprintf(stderr, "params buffer full\n"); exit(2); }
  memcpy((char*)par.map + par_used, v, (size_t)n * 8);
  par_used += par_slot;
  return a;
}
#define P(...) params(sizeof((int64_t[]){__VA_ARGS__}) / 8, (int64_t[]){__VA_ARGS__})

// Scalars that change per token: the token id and the position.
static int64_t* field(arg_t a, int i) { return (int64_t*)((char*)par.map + a.off) + i; }
static int64_t* token_field;
static int64_t* pos_fields[64];
static int npos;

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

// model.mojo's rotate(): the block-512 Hadamard transform of x into b[2] (fp32) and b[3] (fp16 pairs,
// the packed projections' input)
static void rotate(arg_t x, int signs, int width, int inverse) {
  add(K_HADAMARD, groups(width / 8, 64), 1, (arg_t[]){x, W(signs), B(2), B(3), P(width, 0, inverse)});
}

// model.mojo's project(): y = W x for the packed tensors from `slot` (codes, scales, signs); reuse:
// x's transform is still in b[3]. The vocabulary head also selects one candidate per 64 logits.
static void project(int slot, arg_t x, arg_t y, int width, int reduction, int reuse) {
  if (!reuse) rotate(x, slot + 2, reduction, 0);
  if (width == V) {
    add(K_PACKED_HEAD, groups(width, 1024), 1, (arg_t[]){B(3), W(slot), W(slot + 1), y, B(68), P(width, reduction, 1)});
    return;
  }
  add(K_PACKED_LINEAR, groups(width, 64), groups(reduction, 1024),
      (arg_t[]){B(3), W(slot), W(slot + 1), B(67), P(width, reduction)});
  add(K_PACKED_REDUCE, groups(width, 64), 1, (arg_t[]){B(67), y, P(width, groups(reduction, 1024))});
}

static void norm(int weight) {  // b[1] = rmsnorm(b[0]) * w[weight], partial sums in b[3]
  add(K_RMS_PARTIALS, 1, 1, (arg_t[]){B(0), B(3)});
  add(K_RMS_NORM, groups(D, 64), 1, (arg_t[]){B(0), W(weight), B(1), B(3)});
}

// model.mojo's forward(): one token at the position in the params
static void build_forward(uint32_t cap) {
  arg_t t = P(0);
  token_field = field(t, 0);
  add(K_EMBEDDING, groups(D, 64), 1, (arg_t[]){W(0), W(1), B(1), t});
  rotate(B(1), 2, D, 1);
  add(K_COPY, groups(D, 64), 1, (arg_t[]){B(2), B(0)});
  for (int l = 0; l < LAYERS; ++l) {
    int off = 4 + 25 * l;
    arg_t hist = B(19 + 2 * l), state = B(20 + 2 * l);  // attention layers: K and V caches
    norm(off);
    if ((l + 1) % 4) {  // gated DeltaNet
      project(off + 11, B(1), B(4), F, D, 0);
      project(off + 14, B(1), B(5), D, D, 1);
      add(K_GATE_PARTIALS, groups(1024, 64), 1, (arg_t[]){B(1), W(off + 20), W(off + 21), B(2)});
      add(K_CONVOLVE, groups(F, 64), 1, (arg_t[]){B(4), hist, W(off + 23), B(9)});
      add(K_NORMALIZE_QK, groups(F, 64), 1, (arg_t[]){B(9), B(4)});
      add(K_DELTA_GATES, 1, 1, (arg_t[]){B(2), W(off + 22), B(8)});
      add(K_DELTA_UPDATE, groups(D * 8, 64), 1, (arg_t[]){B(4), B(8), state, B(10)});
      add(K_GATED_NORM, groups(D, 64), 1, (arg_t[]){B(10), B(5), W(off + 24), B(1)});
      project(off + 17, B(1), B(1), D, D, 0);
    } else {  // gated full attention
      project(off + 11, B(1), B(5), 4096, D, 0);
      project(off + 14, B(1), B(15), 512, D, 1);
      project(off + 17, B(1), B(16), 512, D, 1);
      add(K_HEAD_NORM, groups(D, 64), 1, (arg_t[]){B(5), W(off + 23), B(14), P(0)});
      add(K_HEAD_NORM, groups(512, 64), 1, (arg_t[]){B(15), W(off + 24), B(9), P(1)});
      arg_t p[5] = {P(2048, 0), P(512, 0), P(0), P(0, cap), P(0, cap)};
      pos_fields[npos++] = field(p[0], 1);
      pos_fields[npos++] = field(p[1], 1);
      for (int i = 2; i < 5; ++i) pos_fields[npos++] = field(p[i], 0);
      add(K_ROPE, groups(256, 64), 1, (arg_t[]){B(14), W(604), p[0]});
      add(K_ROPE, groups(64, 64), 1, (arg_t[]){B(9), W(604), p[1]});
      add(K_CACHE_KV, groups(512, 64), 1, (arg_t[]){B(9), B(16), hist, state, p[2]});
      // the scores for every cached position: the kernel skips those past the current one
      add(K_ATTENTION_SCORES, groups(8 * cap, 64), 1, (arg_t[]){B(14), hist, B(13), p[3]});
      add(K_ATTENTION_VALUES, groups(D, 64), 1, (arg_t[]){B(13), state, B(5), B(10), p[4]});
      project(off + 20, B(10), B(1), D, D, 0);
    }
    add(K_RESIDUAL, groups(D, 64), 1, (arg_t[]){B(0), B(1)});
    norm(off + 1);
    project(off + 2, B(1), B(11), F, D, 0);
    project(off + 5, B(1), B(12), F, D, 1);
    add(K_SWIGLU, groups(F, 64), 1, (arg_t[]){B(11), B(12)});
    project(off + 8, B(11), B(1), D, F, 0);
    add(K_RESIDUAL, groups(D, 64), 1, (arg_t[]){B(0), B(1)});
  }
  norm(3);
  project(0, B(1), B(17), V, D, 0);
}

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
    vkCmdDispatch(cmd, ds[i].gx, ds[i].gy, 1);
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

// Greedy from the head's candidates (value, index, nonfinite flag per 64 x 8 logits), lowest index on ties.
static int greedy(void) {
  const float* c = b[68].map;
  int best = 0;
  for (int i = 0; i < NCAND; ++i) {
    if (c[3 * i + 2] != 0) { fprintf(stderr, "nonfinite logits\n"); exit(1); }
    if (c[3 * i] > c[3 * best] || (c[3 * i] == c[3 * best] && c[3 * i + 1] < c[3 * best + 1])) best = i;
  }
  return (int)c[3 * best + 1];
}

int main(int argc, char** argv) {
  if (argc < 5) { fprintf(stderr, "usage: %s weights.bin kernel_dir max_new token_ids...\n", argv[0]); return 2; }
  int max_new = atoi(argv[3]), nprompt = argc - 4;
  const char* ref_path = getenv("BONSAI_REF");

  // ---- Vulkan 1.3 device: fp16, int8 and int64 in shaders, 16-bit storage, 64-lane subgroups
  void* lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) { fprintf(stderr, "dlopen libvulkan.so: %s\n", dlerror()); return 2; }
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "bonsai_vk", 1, NULL, 0, VK_API_VERSION_1_3};
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
  printf("device: %s  Vulkan %u.%u\n", props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion), VK_API_VERSION_MINOR(props.apiVersion));
  if (props.apiVersion < VK_API_VERSION_1_3) { fprintf(stderr, "need Vulkan 1.3\n"); return 2; }

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
  if (!v12.shaderFloat16 || !v11.storageBuffer16BitAccess || !f2.features.shaderInt64) {
    fprintf(stderr, "need shaderFloat16, storageBuffer16BitAccess and shaderInt64\n");
    return 2;
  }
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
  if (!v13.subgroupSizeControl) printf("warning: no subgroup size control; the kernels assume 64-lane subgroups\n");
  load_kernels(argv[2], v13.subgroupSizeControl, v13.computeFullSubgroups);

  // ---- scratch buffers (zeroed: the convolution history and DeltaNet state start empty), params, plan
  uint64_t scratch = 0;
  for (int i = 0; i < NB; ++i) {
    if (i == 18) { b[i] = w[604]; continue; }
    b[i] = make_buffer(buffer_elements(i, cap) * 4);
    memset(b[i].map, 0, b[i].size);
    scratch += b[i].size;
  }
  par_slot = props.limits.minStorageBufferOffsetAlignment < 64 ? 64 : props.limits.minStorageBufferOffsetAlignment;
  par = make_buffer(1024 * par_slot);
  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 8192};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1024, 1, &ps};
  CHECK(vkCreateDescriptorPool(dev, &dpi, NULL, &pool));
  build_forward(cap);
  printf("plan: %d dispatches per token, scratch and caches %.1f MiB\n", nplan, scratch / 1048576.0);

  VkCommandPoolCreateInfo cpo = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL, VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, qfam};
  VkCommandPool cpool;
  CHECK(vkCreateCommandPool(dev, &cpo, NULL, &cpool));
  VkCommandBuffer cmd;
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, cpool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  CHECK(vkAllocateCommandBuffers(dev, &cai, &cmd));

  if (getenv("BONSAI_PROFILE")) {  // the first token one dispatch per submit; restores the state after
    *token_field = atoi(argv[4]);
    for (int i = 0; i < npos; ++i) *pos_fields[i] = 0;
    double per[NKERNELS] = {0}, all = 0;
    int count[NKERNELS] = {0};
    for (int i = 0; i < nplan; ++i) {
      record(cmd, &plan[i], 1);
      double ts = now_ms();
      submit_wait(q, cmd);
      per[plan[i].k] += now_ms() - ts;
      count[plan[i].k]++;
    }
    for (int k = 0; k < NKERNELS; ++k) all += per[k];
    for (int k = 0; k < NKERNELS; ++k)
      if (count[k]) printf("profile: %-17s %4d dispatches %7.2f ms\n", kernels[k].name, count[k], per[k]);
    printf("profile: total %.2f ms (one submit per dispatch)\n", all);
    for (int i = 19; i < 67; ++i) memset(b[i].map, 0, b[i].size);
  }
  record(cmd, plan, nplan);

  // ---- prompt, then greedy decode (or the reference's steps)
  FILE* ref = ref_path ? fopen(ref_path, "rb") : NULL;
  if (ref_path && !ref) { fprintf(stderr, "cannot open %s\n", ref_path); return 2; }
  float* expect = ref ? malloc((size_t)V * 4) : NULL;
  int tok = atoi(argv[4]), ngen = 0, failed = 0;
  double t0 = now_ms(), tgen = 0, worst = 0;
  for (int p = 0; p < nprompt + max_new; ++p) {
    if (p < nprompt) tok = atoi(argv[4 + p]);
    if (tok < 0 || tok >= V) { fprintf(stderr, "token %d out of range\n", tok); return 2; }
    *token_field = tok;
    for (int i = 0; i < npos; ++i) *pos_fields[i] = p;
    double ts = now_ms();
    submit_wait(q, cmd);
    if (p < nprompt - 1) continue;
    int next = greedy();
    double ms = now_ms() - ts;
    if (p == nprompt - 1) printf("prompt: %d tokens in %.0f ms\n", nprompt, now_ms() - t0);
    else tgen += ms;
    if (ref) {  // all logits against the FP32 reference
      if (fread(expect, 4, V, ref) != V) { fprintf(stderr, "reference has only %d steps\n", ngen); return 2; }
      const float* lg = b[17].map;
      double maxerr = 0, d2 = 0, r2 = 0;
      int best = 0, rbest = 0;
      for (int i = 0; i < V; ++i) {
        if (!isfinite(lg[i])) { fprintf(stderr, "logit %d nonfinite\n", i); return 1; }
        double e = fabs((double)lg[i] - expect[i]);
        maxerr = e > maxerr ? e : maxerr;
        d2 += e * e;
        r2 += (double)expect[i] * expect[i];
        if (lg[i] > lg[best]) best = i;
        if (expect[i] > expect[rbest]) rbest = i;
      }
      int ok = next == rbest && best == rbest;
      failed |= !ok;
      worst = maxerr > worst ? maxerr : worst;
      printf("check %2d: token %6d reference %6d  max abs %.6f  rel L2 %.8f %s\n", ngen, next, rbest, maxerr,
             sqrt(d2 / r2), ok ? "OK" : "MISMATCH");
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
