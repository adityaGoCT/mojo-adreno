// Vulkan executor of the driver plugin: owns the GPU's buffers and pipelines and runs the requests
// of driver/protocol.h, which name buffers and modules by numbers the plugin chooses.
//
// Launches, device-side copies and fills are recorded into command buffers of `submit_every`
// commands each, every command after a barrier on the ones before it, and a command buffer is
// submitted once full: nothing waits for the GPU until the host needs memory (WRITE, READ, FREE, a
// fill Vulkan cannot do) or at SYNC. A launch of BIG_LAUNCH threads or more ends its command buffer
// and is submitted at once: 64 large prefill launches together outlast the driver's watchdog and
// lose the device, while decode's launches (under 100K threads) stay batched. The remote device
// submits each command alone: one submission of many slow kernels can outlast the GPU driver's
// timeout and lose the device. Buffers are host-visible and coherent, so host access is memcpy.
//
// Pipelines require 64-lane subgroups where the driver lets them (a Mojo warp is 64 lanes, and
// cooperative matrices on the Adreno 840 need it), and the device enables what LLVM's SPIR-V may
// declare: 8-, 16- and 64-bit integers, fp16, 8- and 16-bit storage, the Vulkan memory model and
// KHR cooperative matrices.
//
// Pipelines go through a VkPipelineCache kept in a file (VK_PIPELINE_CACHE, by default
// $TMPDIR/mojo-vulkan-pipelines.bin; empty: none), so the driver compiles each one once per device:
// one Android 17 driver build takes 39 s for Llama's fused prefill attention.
#define VK_NO_PROTOTYPES
#include "executor.h"

#include <dlfcn.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <vulkan/vulkan.h>

#include "protocol.h"

#ifdef _WIN32
#define file_seek _fseeki64
#else
#define file_seek fseeko
#endif

#define VK_FUNCS(X)                                                                              \
  X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties)             \
  X(vkGetPhysicalDeviceProperties2) X(vkGetPhysicalDeviceQueueFamilyProperties)                  \
  X(vkGetPhysicalDeviceMemoryProperties) X(vkEnumerateDeviceExtensionProperties)                 \
  X(vkCreateDevice) X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkGetBufferMemoryRequirements)       \
  X(vkAllocateMemory) X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateShaderModule)               \
  X(vkCreateDescriptorSetLayout) X(vkCreatePipelineLayout) X(vkCreateComputePipelines)           \
  X(vkCreateDescriptorPool) X(vkAllocateDescriptorSets) X(vkUpdateDescriptorSets)                \
  X(vkResetDescriptorPool) X(vkCreateCommandPool) X(vkAllocateCommandBuffers)                    \
  X(vkBeginCommandBuffer) X(vkEndCommandBuffer) X(vkResetCommandBuffer)                          \
  X(vkCmdBindPipeline) X(vkCmdBindDescriptorSets) X(vkCmdDispatch) X(vkQueueSubmit)              \
  X(vkQueueWaitIdle) X(vkGetPhysicalDeviceFeatures2) X(vkDestroyBuffer) X(vkFreeMemory)          \
  X(vkCmdPipelineBarrier) X(vkCmdCopyBuffer) X(vkCmdFillBuffer) X(vkDestroyShaderModule)         \
  X(vkDestroyPipeline) X(vkDestroyPipelineLayout) X(vkDestroyDescriptorSetLayout)                 \
  X(vkCreatePipelineCache) X(vkGetPipelineCacheData)

#define DECL(f) static PFN_##f f;
VK_FUNCS(DECL)

// Commands between two waits for the GPU (their descriptor sets and params), and command buffers.
#define MAX_PENDING 4096
#define MAX_SUBMITS 256
#define PARAMS_ARENA (1 << 20)
#define BIG_LAUNCH (1 << 18)

static VkDevice dev;
static VkQueue queue;
static VkPhysicalDeviceMemoryProperties memprops;
static VkPhysicalDeviceProperties props;
static uint32_t subgroup;      // the required subgroup size, or 0
static int full_subgroups;     // computeFullSubgroups
static VkDescriptorPool pool;
static VkCommandBuffer cmds[MAX_SUBMITS];
static VkCommandBuffer cmd;    // the one being recorded, or NULL
static int submit_every = 1;
static int in_cmd;             // commands in `cmd`
static int nsubmitted;         // command buffers submitted since the last wait
static int pending;            // commands since the last wait
static int profile;
static VkPipelineCache pipeline_cache;
static char pipeline_cache_path[512];
static char error[512];        // the first error since the last answer
static char taken[512];

static void fail(const char* format, ...) {
  va_list ap;
  va_start(ap, format);
  char message[sizeof error];
  vsnprintf(message, sizeof message, format, ap);
  va_end(ap);
  fprintf(stderr, "vulkan executor: %s\n", message);
  if (!error[0]) memcpy(error, message, sizeof error);
}

const char* vkx_take_error(void) {
  if (!error[0]) return NULL;
  memcpy(taken, error, sizeof taken);
  error[0] = 0;
  return taken;
}

// Answers INFO, READ or SYNC: the data, or the first error since the last answer.
static void reply(vkx_answer_fn answer, void* ctx, const void* data, uint32_t n) {
  if (error[0]) {
    answer(ctx, 1, error, (uint32_t)strlen(error));
    error[0] = 0;
  } else {
    answer(ctx, 0, data, n);
  }
}

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e3 + t.tv_nsec / 1e6;
}

// --- objects, named by the client ------------------------------------------------------------

typedef struct {
  VkBuffer buf;
  VkDeviceMemory mem;
  char* map;
  uint64_t size;
} buffer_t;

typedef struct {
  VkShaderModule module;
  // Pipelines by (block size, binding count): Vulkan fixes both at pipeline creation.
  struct { uint32_t block[3], nbind; VkPipeline pipe; VkPipelineLayout layout; VkDescriptorSetLayout dsl; } *cache;
  int ncache;
} module_t;

static buffer_t* buffers;
static uint64_t nbuffers;
static module_t* modules;
static uint64_t nmodules;
static buffer_t params;      // the arena for launches' params buffers
static uint64_t params_used;

static buffer_t* buffer(uint64_t id) {
  return id && id <= nbuffers && buffers[id - 1].buf ? &buffers[id - 1] : NULL;
}

static int make_buffer(buffer_t* b, uint64_t size) {
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size ? size : 4;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
  memset(b, 0, sizeof *b);
  b->size = bi.size;
  if (vkCreateBuffer(dev, &bi, NULL, &b->buf) != VK_SUCCESS) return -1;
  VkMemoryRequirements mr;
  vkGetBufferMemoryRequirements(dev, b->buf, &mr);
  uint32_t want = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, ti = 0;
  for (uint32_t i = 0; i < memprops.memoryTypeCount; ++i)
    if ((mr.memoryTypeBits & (1u << i)) && (memprops.memoryTypes[i].propertyFlags & want) == want) { ti = i; break; }
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, NULL, mr.size, ti};
  if (vkAllocateMemory(dev, &ai, NULL, &b->mem) != VK_SUCCESS) {
    vkDestroyBuffer(dev, b->buf, NULL);
    b->buf = VK_NULL_HANDLE;
    return -1;
  }
  vkBindBufferMemory(dev, b->buf, b->mem, 0);
  if (vkMapMemory(dev, b->mem, 0, b->size, 0, (void**)&b->map) != VK_SUCCESS || !b->map) {
    fprintf(stderr, "executor: vkMapMemory failed for a buffer of %llu bytes (memory type %u)\n",
            (unsigned long long)b->size, ti);
    vkFreeMemory(dev, b->mem, NULL);
    vkDestroyBuffer(dev, b->buf, NULL);
    b->buf = VK_NULL_HANDLE;
    b->map = NULL;
    return -1;
  }
  return 0;
}

static int in_range(buffer_t* b, uint64_t offset, uint64_t size) {
  return b && offset <= b->size && size <= b->size - offset;
}

// --- the batch -------------------------------------------------------------------------------

static double batch_start;

// Every command waits for the writes of the ones before it, in this command buffer or an earlier
// submission.
static void record_barrier(void) {
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL,
                        VK_ACCESS_SHADER_WRITE_BIT | VK_ACCESS_TRANSFER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT | VK_ACCESS_TRANSFER_READ_BIT |
                            VK_ACCESS_TRANSFER_WRITE_BIT};
  VkPipelineStageFlags stages = VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT | VK_PIPELINE_STAGE_TRANSFER_BIT;
  vkCmdPipelineBarrier(cmd, stages, stages, 0, 1, &mb, 0, NULL, 0, NULL);
}

static void flush(void);

// Submits the command buffer being recorded without waiting for it.
static void submit(void) {
  if (!cmd) return;
  vkEndCommandBuffer(cmd);
  VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
  si.commandBufferCount = 1;
  si.pCommandBuffers = &cmd;
  VkResult r = vkQueueSubmit(queue, 1, &si, VK_NULL_HANDLE);
  if (r != VK_SUCCESS) fail("submit failed: VkResult %d", (int)r);
  ++nsubmitted;
  cmd = VK_NULL_HANDLE;
  in_cmd = 0;
}

// Starts recording the next command, after a barrier on the ones before it.
static void begin_command(void) {
  if (pending == MAX_PENDING) flush();
  if (!cmd) {
    if (nsubmitted == MAX_SUBMITS) flush();
    if (!pending) batch_start = now_ms();
    cmd = cmds[nsubmitted];
    VkCommandBufferBeginInfo bbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    bbi.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    vkResetCommandBuffer(cmd, 0);
    vkBeginCommandBuffer(cmd, &bbi);
  }
  record_barrier();
}

static void end_command(void) {
  ++pending;
  if (++in_cmd >= submit_every) submit();
}

// Waits for the commands in flight: before the host touches memory, and at SYNC.
static void flush(void) {
  submit();
  if (!nsubmitted) return;
  double t0 = now_ms();
  VkResult r = vkQueueWaitIdle(queue);
  if (profile)
    fprintf(stderr, "%d commands in %d submissions: recorded over %.1f ms, then waited %.1f ms\n", pending,
            nsubmitted, t0 - batch_start, now_ms() - t0);
  if (r != VK_SUCCESS) fail("%d commands failed: VkResult %d", pending, (int)r);
  nsubmitted = 0;
  pending = 0;
  params_used = 0;
  vkResetDescriptorPool(dev, pool, 0);
}

// Destroys a module and the pipelines made from it.
static void drop_module(module_t* m) {
  for (int i = 0; i < m->ncache; ++i) {
    vkDestroyPipeline(dev, m->cache[i].pipe, NULL);
    vkDestroyPipelineLayout(dev, m->cache[i].layout, NULL);
    vkDestroyDescriptorSetLayout(dev, m->cache[i].dsl, NULL);
  }
  free(m->cache);
  if (m->module) vkDestroyShaderModule(dev, m->module, NULL);
  memset(m, 0, sizeof *m);
}

// Frees what a client created: the next one names its buffers and modules from 1 again.
void vkx_reset(void) {
  flush();
  for (uint64_t i = 0; i < nbuffers; ++i)
    if (buffers[i].buf) {
      vkDestroyBuffer(dev, buffers[i].buf, NULL);
      vkFreeMemory(dev, buffers[i].mem, NULL);
    }
  for (uint64_t i = 0; i < nmodules; ++i) drop_module(&modules[i]);
  free(buffers), free(modules);
  buffers = NULL, modules = NULL;
  nbuffers = nmodules = 0;
  error[0] = 0;
}

// --- kernels ---------------------------------------------------------------------------------

// The pipeline cache file: its data for the cache, or none.
static void open_pipeline_cache(void) {
  const char* env = getenv("VK_PIPELINE_CACHE");
  if (env && !*env) return;
  const char* tmp = getenv("TMPDIR");
  if (env) snprintf(pipeline_cache_path, sizeof pipeline_cache_path, "%s", env);
  else snprintf(pipeline_cache_path, sizeof pipeline_cache_path, "%s/mojo-vulkan-pipelines.bin", tmp ? tmp : "/data/local/tmp");
  void* data = NULL;
  long n = 0;
  FILE* f = fopen(pipeline_cache_path, "rb");
  if (f) {
    fseek(f, 0, SEEK_END);
    n = ftell(f);
    fseek(f, 0, SEEK_SET);
    data = n > 0 ? malloc((size_t)n) : NULL;
    if (!data || fread(data, 1, (size_t)n, f) != (size_t)n) n = 0;
    fclose(f);
  }
  // A driver ignores data from another driver or device (the header names them).
  VkPipelineCacheCreateInfo ci = {VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO, NULL, 0, (size_t)n, data};
  if (vkCreatePipelineCache(dev, &ci, NULL, &pipeline_cache) != VK_SUCCESS) pipeline_cache = VK_NULL_HANDLE;
  free(data);
  if (profile) fprintf(stderr, "pipeline cache: %s, %ld bytes\n", pipeline_cache_path, n);
}

// Writes the cache out after a new pipeline: to a temporary file, then renamed over the old one.
static void save_pipeline_cache(void) {
  size_t n = 0;
  if (!pipeline_cache || vkGetPipelineCacheData(dev, pipeline_cache, &n, NULL) != VK_SUCCESS || !n) return;
  void* data = malloc(n);
  if (data && vkGetPipelineCacheData(dev, pipeline_cache, &n, data) == VK_SUCCESS) {
    char tmp[sizeof pipeline_cache_path + 8];
    snprintf(tmp, sizeof tmp, "%s.tmp", pipeline_cache_path);
    FILE* f = fopen(tmp, "wb");
    if (f && fwrite(data, 1, n, f) == n && !fclose(f)) rename(tmp, pipeline_cache_path);
    else if (f) fclose(f);
  }
  free(data);
}

static int pipeline(module_t* m, const uint32_t block[3], uint32_t nbind, VkPipeline* pipe,
                    VkPipelineLayout* layout, VkDescriptorSetLayout* dsl) {
  for (int i = 0; i < m->ncache; ++i)
    if (!memcmp(m->cache[i].block, block, 12) && m->cache[i].nbind == nbind) {
      *pipe = m->cache[i].pipe, *layout = m->cache[i].layout, *dsl = m->cache[i].dsl;
      return 0;
    }
  VkDescriptorSetLayoutBinding binds[MAX_BINDINGS + 1];
  for (uint32_t i = 0; i < nbind; ++i)
    binds[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, nbind, binds};
  if (vkCreateDescriptorSetLayout(dev, &dli, NULL, dsl) != VK_SUCCESS) return -1;
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, dsl};
  if (vkCreatePipelineLayout(dev, &pli, NULL, layout) != VK_SUCCESS) return -1;
  // The block size as specialization constants 0-2 (a module without them ignores the entries).
  VkSpecializationMapEntry entries[3] = {{0, 0, 4}, {1, 4, 4}, {2, 8, 4}};
  VkSpecializationInfo spec = {3, entries, 12, block};
  VkPipelineShaderStageRequiredSubgroupSizeCreateInfo rss = {
      VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO, NULL, subgroup};
  VkComputePipelineCreateInfo cpi = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  cpi.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  cpi.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  cpi.stage.module = m->module;
  cpi.stage.pName = "main";
  cpi.stage.pSpecializationInfo = &spec;
  if (subgroup) {
    cpi.stage.pNext = &rss;
    // Full subgroups only where the block's rows fill them; Vulkan rejects it otherwise.
    if (full_subgroups && block[0] % subgroup == 0)
      cpi.stage.flags = VK_PIPELINE_SHADER_STAGE_CREATE_REQUIRE_FULL_SUBGROUPS_BIT;
  }
  cpi.layout = *layout;
  double t0 = now_ms();
  if (vkCreateComputePipelines(dev, pipeline_cache, 1, &cpi, NULL, pipe) != VK_SUCCESS) return -1;
  if (profile)
    fprintf(stderr, "pipeline: module %ld, block %u %u %u, %u bindings: %.1f ms\n", (long)(m - modules), block[0],
            block[1], block[2], nbind, now_ms() - t0);
  m->cache = realloc(m->cache, (m->ncache + 1) * sizeof *m->cache);
  memcpy(m->cache[m->ncache].block, block, 12);
  m->cache[m->ncache].nbind = nbind;
  m->cache[m->ncache].pipe = *pipe;
  m->cache[m->ncache].layout = *layout;
  m->cache[m->ncache].dsl = *dsl;
  m->ncache++;
  save_pipeline_cache();
  return 0;
}

static void launch(const char* p, uint32_t n) {
  const launch_t* l = (const launch_t*)p;
  if (n < sizeof *l || l->nbind > MAX_BINDINGS ||
      n < sizeof *l + l->nbind * sizeof(binding_t) + l->params_len)
    return fail("malformed launch");
  if (!l->module || l->module > nmodules || !modules[l->module - 1].module)
    return fail("bad module %llu", (unsigned long long)l->module);
  const binding_t* binds = (const binding_t*)(p + sizeof *l);
  const char* args = (const char*)(binds + l->nbind);
  uint32_t nbind = l->nbind + (l->params_len ? 1 : 0);
  VkPipeline pipe;
  VkPipelineLayout layout;
  VkDescriptorSetLayout dsl;
  if (pipeline(&modules[l->module - 1], l->block, nbind, &pipe, &layout, &dsl))
    return fail("cannot create a pipeline for module %llu, block %u %u %u", (unsigned long long)l->module,
                l->block[0], l->block[1], l->block[2]);
  uint64_t align = props.limits.minStorageBufferOffsetAlignment;
  uint64_t params_at = (params_used + align - 1) / align * align;
  if (pending == MAX_PENDING || params_at + l->params_len > PARAMS_ARENA) flush(), params_at = 0;
  VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, pool, 1, &dsl};
  VkDescriptorSet ds;
  if (vkAllocateDescriptorSets(dev, &dai, &ds) != VK_SUCCESS) {  // the pool is full: a new batch
    flush();
    params_at = 0;
    if (vkAllocateDescriptorSets(dev, &dai, &ds) != VK_SUCCESS) return fail("cannot allocate a descriptor set");
  }
  VkDescriptorBufferInfo infos[MAX_BINDINGS + 1];
  VkWriteDescriptorSet writes[MAX_BINDINGS + 1];
  for (uint32_t i = 0; i < nbind; ++i) {
    if (i < l->nbind) {
      buffer_t* b = buffer(binds[i].buffer);
      if (!b || binds[i].offset >= b->size)
        return fail("binding %u: bad buffer %llu", i, (unsigned long long)binds[i].buffer);
      if (binds[i].offset % align)
        return fail("binding %u: offset %llu is not a multiple of %llu", i, (unsigned long long)binds[i].offset,
                    (unsigned long long)align);
      infos[i] = (VkDescriptorBufferInfo){b->buf, binds[i].offset, VK_WHOLE_SIZE};
    } else {  // the params, in the arena
      memcpy(params.map + params_at, args, l->params_len);
      infos[i] = (VkDescriptorBufferInfo){params.buf, params_at, l->params_len};
      params_used = params_at + l->params_len;
    }
    writes[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, ds, i, 0, 1,
                                       VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &infos[i], NULL};
  }
  vkUpdateDescriptorSets(dev, nbind, writes, 0, NULL);
  begin_command();
  vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pipe);
  vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, layout, 0, 1, &ds, 0, NULL);
  vkCmdDispatch(cmd, l->groups[0], l->groups[1], l->groups[2]);
  end_command();
  uint64_t threads = (uint64_t)l->groups[0] * l->groups[1] * l->groups[2] * l->block[0] * l->block[1] * l->block[2];
  if (threads >= BIG_LAUNCH) submit();
  if (profile > 1) flush();  // VK_SERVER_PROFILE=2: each launch on its own, to time it
}

// --- requests --------------------------------------------------------------------------------

// The file named by n bytes at p, kept open from one request to the next (a model's tensors come from one file).
static FILE* open_file(const char* p, uint32_t n) {
  static FILE* file;
  static char file_path[1024];
  char path[1024];
  uint32_t len = n < sizeof path - 1 ? n : (uint32_t)sizeof path - 1;
  memcpy(path, p, len);
  path[len] = 0;
  if (!file || strcmp(path, file_path)) {
    if (file) fclose(file);
    file = fopen(path, "rb");
    if (!file) {
      file_path[0] = 0;
      fail("cannot open %s", path);
      return NULL;
    }
    strcpy(file_path, path);
  }
  return file;
}

void vkx_handle(uint32_t op, const char* p, uint32_t n, const char* tail, uint64_t ntail, vkx_answer_fn answer,
                void* ctx) {
  const uint64_t* w = (const uint64_t*)p;
  switch (op) {
  case OP_INFO: {
    char info[512];
    const VkPhysicalDeviceLimits* lim = &props.limits;
    int k = snprintf(info, sizeof info, "%s|%u.%u|%llu|%u|%u|%u|%u|%u|%u", props.deviceName,
                     VK_API_VERSION_MAJOR(props.apiVersion), VK_API_VERSION_MINOR(props.apiVersion),
                     (unsigned long long)lim->minStorageBufferOffsetAlignment, lim->maxComputeSharedMemorySize,
                     lim->maxComputeWorkGroupInvocations, lim->maxComputeWorkGroupSize[0],
                     lim->maxComputeWorkGroupSize[1], lim->maxComputeWorkGroupSize[2], subgroup ? subgroup : 64);
    return reply(answer, ctx, info, (uint32_t)k);
  }
  case OP_ALLOC: {  // id, size
    if (n != 16 || !w[0]) return fail("malformed alloc");
    if (w[0] > nbuffers) {
      buffers = realloc(buffers, w[0] * sizeof *buffers);
      memset(buffers + nbuffers, 0, (w[0] - nbuffers) * sizeof *buffers);
      nbuffers = w[0];
    }
    if (buffers[w[0] - 1].buf) return fail("buffer %llu already exists", (unsigned long long)w[0]);
    if (make_buffer(&buffers[w[0] - 1], w[1])) return fail("cannot allocate %llu bytes", (unsigned long long)w[1]);
    return;
  }
  case OP_FREE: {
    buffer_t* b = n == 8 ? buffer(w[0]) : NULL;
    if (!b) return fail("bad buffer to free");
    flush();  // the batch may still use it
    vkDestroyBuffer(dev, b->buf, NULL);
    vkFreeMemory(dev, b->mem, NULL);
    b->buf = VK_NULL_HANDLE;
    return;
  }
  case OP_WRITE: {  // id, offset, bytes
    if (n < 16) return fail("malformed write");
    const char* data = ntail ? tail : p + 16;
    uint64_t size = ntail ? ntail : n - 16;
    buffer_t* b = buffer(w[0]);
    if (!in_range(b, w[1], size)) return fail("write out of range");
    flush();
    memcpy(b->map + w[1], data, size);
    return;
  }
  case OP_READ: {
    buffer_t* b = n == 24 ? buffer(w[0]) : NULL;
    flush();
    if (!in_range(b, w[1], w[2]) || w[2] > 0xffffffffu) {
      fail("read out of range");
      return reply(answer, ctx, NULL, 0);
    }
    return reply(answer, ctx, b->map + w[1], (uint32_t)w[2]);
  }
  case OP_FILL: {  // id, offset, size, value, value size
    buffer_t* b = n == 40 ? buffer(w[0]) : NULL;
    if (!in_range(b, w[1], w[2]) || !w[4] || w[4] > 8) return fail("bad fill");
    // vkCmdFillBuffer repeats a 32-bit word over whole words.
    uint32_t word = 0;
    int on_gpu = w[1] % 4 == 0 && w[2] % 4 == 0 && w[4] <= 4 && 4 % w[4] == 0;
    for (uint64_t i = 0; on_gpu && i < 4; i += w[4]) memcpy((char*)&word + i, &w[3], w[4]);
    if (on_gpu && w[2]) {
      begin_command();
      vkCmdFillBuffer(cmd, b->buf, w[1], w[2], word);
      end_command();
      return;
    }
    flush();
    for (uint64_t i = 0; i < w[2]; i += w[4]) memcpy(b->map + w[1] + i, &w[3], w[2] - i < w[4] ? w[2] - i : w[4]);
    return;
  }
  case OP_COPY: {  // dst, dst offset, src, src offset, size
    buffer_t *d = n == 40 ? buffer(w[0]) : NULL, *s = n == 40 ? buffer(w[2]) : NULL;
    if (!in_range(d, w[1], w[4]) || !in_range(s, w[3], w[4])) return fail("copy out of range");
    if (!w[4]) return;
    begin_command();
    VkBufferCopy region = {w[3], w[1], w[4]};
    vkCmdCopyBuffer(cmd, s->buf, d->buf, 1, &region);
    end_command();
    return;
  }
  case OP_LOAD: {  // id, SPIR-V
    const char* code = ntail ? tail : p + 8;
    uint64_t size = ntail ? ntail : n - 8;
    if (n < 8 || !w[0] || !size || size % 4) return fail("malformed load");
    if (w[0] > nmodules) {
      modules = realloc(modules, w[0] * sizeof *modules);
      memset(modules + nmodules, 0, (w[0] - nmodules) * sizeof *modules);
      nmodules = w[0];
    }
    flush();
    drop_module(&modules[w[0] - 1]);  // a name used again: never its old pipelines
    VkShaderModuleCreateInfo smi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, size, (const uint32_t*)code};
    if (vkCreateShaderModule(dev, &smi, NULL, &modules[w[0] - 1].module) != VK_SUCCESS)
      return fail("bad SPIR-V module %llu", (unsigned long long)w[0]);
    return;
  }
  case OP_LAUNCH:
    return launch(p, n);
  case OP_SYNC:
    flush();
    return reply(answer, ctx, NULL, 0);
  case OP_FILE: {  // buffer, offset, file offset, size, path
    buffer_t* b = n > 32 ? buffer(w[0]) : NULL;
    if (!in_range(b, w[1], w[3])) return fail("file read out of range");
    FILE* f = open_file(p + 32, n - 32);
    if (!f) return;
    flush();  // the batch may still use the buffer
    if (file_seek(f, (long long)w[2], SEEK_SET) || fread(b->map + w[1], 1, w[3], f) != w[3])
      return fail("cannot read %llu bytes at %llu", (unsigned long long)w[3], (unsigned long long)w[2]);
    return;
  }
  case OP_GATHER: {  // buffer, offset, token buffer, token offset, file offset, row bytes, path
    buffer_t* b = n > 48 ? buffer(w[0]) : NULL;
    buffer_t* tb = n > 48 ? buffer(w[2]) : NULL;
    if (!in_range(b, w[1], w[5]) || !in_range(tb, w[3], 4)) return fail("gather out of range");
    FILE* f = open_file(p + 48, n - 48);
    if (!f) return;
    flush();  // the token is the GPU's, and the batch may still use the buffer
    int32_t t;
    memcpy(&t, tb->map + w[3], 4);
    if (t < 0 || file_seek(f, (long long)(w[4] + (uint64_t)t * w[5]), SEEK_SET) ||
        fread(b->map + w[1], 1, w[5], f) != w[5])
      return fail("cannot gather row %d", (int)t);
    return;
  }
  default:
    return fail("unknown request %u", op);
  }
}

// --- the device ------------------------------------------------------------------------------

static int has_extension(VkPhysicalDevice pd, const char* name) {
  uint32_t n = 0;
  vkEnumerateDeviceExtensionProperties(pd, NULL, &n, NULL);
  VkExtensionProperties* xp = calloc(n ? n : 1, sizeof *xp);
  vkEnumerateDeviceExtensionProperties(pd, NULL, &n, xp);
  int found = 0;
  for (uint32_t i = 0; i < n; ++i) found |= !strcmp(xp[i].extensionName, name);
  free(xp);
  return found;
}

int vkx_init(int submit_every_default) {
  const char* env = getenv("VK_SERVER_PROFILE");
  profile = env && *env ? atoi(env) : 0;
  env = getenv("VK_SUBMIT_EVERY");
  submit_every = env && atoi(env) > 0 ? atoi(env) : submit_every_default > 0 ? submit_every_default : 1;
  void* lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) return fail("dlopen libvulkan.so: %s", dlerror()), -1;
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  if (!gipa) return fail("libvulkan.so has no vkGetInstanceProcAddr"), -1;
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "mojo-vulkan", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO};
  ici.pApplicationInfo = &app;
  VkInstance inst;
  if (vkCreateInstance(&ici, NULL, &inst) != VK_SUCCESS) return fail("no Vulkan 1.3 instance"), -1;
#define LOAD(f) f = (PFN_##f)gipa(inst, #f);
  VK_FUNCS(LOAD)
  uint32_t npd = 1;
  VkPhysicalDevice pd;
  if (vkEnumeratePhysicalDevices(inst, &npd, &pd) < 0 || !npd) return fail("no Vulkan device"), -1;
  VkPhysicalDeviceVulkan13Properties p13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_PROPERTIES};
  VkPhysicalDeviceProperties2 p2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2, &p13};
  vkGetPhysicalDeviceProperties2(pd, &p2);
  props = p2.properties;
  vkGetPhysicalDeviceMemoryProperties(pd, &memprops);
  if (getenv("VKX_MEMINFO")) {  // the device's memory heaps and types (which one buffers come from: make_buffer)
    for (uint32_t i = 0; i < memprops.memoryHeapCount; ++i)
      fprintf(stderr, "executor: heap %u: %.2f GB, flags 0x%x\n", i, memprops.memoryHeaps[i].size / 1e9,
              memprops.memoryHeaps[i].flags);
    for (uint32_t i = 0; i < memprops.memoryTypeCount; ++i)
      fprintf(stderr, "executor: memory type %u: heap %u, flags 0x%x\n", i, memprops.memoryTypes[i].heapIndex,
              memprops.memoryTypes[i].propertyFlags);
  }
  uint32_t nq = 0;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, NULL);
  VkQueueFamilyProperties qf[16];
  if (nq > 16) nq = 16;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, qf);
  uint32_t qfam = 0;
  for (uint32_t i = 0; i < nq; ++i) if (qf[i].queueFlags & VK_QUEUE_COMPUTE_BIT) { qfam = i; break; }

  // Enable what the device has of what LLVM-generated SPIR-V may declare.
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  VkPhysicalDeviceVulkan13Features v13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES};
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &v13};
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  int coopmat = has_extension(pd, VK_KHR_COOPERATIVE_MATRIX_EXTENSION_NAME);
  if (coopmat) v13.pNext = &cm;
  vkGetPhysicalDeviceFeatures2(pd, &f2);
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR encm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  encm.cooperativeMatrix = cm.cooperativeMatrix;
  coopmat = coopmat && cm.cooperativeMatrix;
  VkPhysicalDeviceVulkan13Features en13 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES, coopmat ? &encm : NULL};
  en13.subgroupSizeControl = v13.subgroupSizeControl;
  en13.computeFullSubgroups = v13.computeFullSubgroups;
  VkPhysicalDeviceVulkan12Features en12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &en13};
  en12.shaderInt8 = v12.shaderInt8;
  en12.shaderFloat16 = v12.shaderFloat16;
  en12.storageBuffer8BitAccess = v12.storageBuffer8BitAccess;
  en12.shaderBufferInt64Atomics = v12.shaderBufferInt64Atomics;
  en12.shaderSubgroupExtendedTypes = v12.shaderSubgroupExtendedTypes;
  en12.vulkanMemoryModel = v12.vulkanMemoryModel;
  en12.vulkanMemoryModelDeviceScope = v12.vulkanMemoryModelDeviceScope;
  VkPhysicalDeviceVulkan11Features en11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &en12};
  en11.storageBuffer16BitAccess = v11.storageBuffer16BitAccess;
  VkPhysicalDeviceFeatures2 en = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &en11};
  en.features.shaderInt64 = f2.features.shaderInt64;
  en.features.shaderInt16 = f2.features.shaderInt16;
  float prio = 1.0f;
  VkDeviceQueueCreateInfo qci = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, qfam, 1, &prio};
  const char* cm_ext = VK_KHR_COOPERATIVE_MATRIX_EXTENSION_NAME;
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &en};
  dci.queueCreateInfoCount = 1;
  dci.pQueueCreateInfos = &qci;
  dci.enabledExtensionCount = coopmat ? 1 : 0;
  dci.ppEnabledExtensionNames = &cm_ext;
  if (vkCreateDevice(pd, &dci, NULL, &dev) != VK_SUCCESS) return fail("cannot create the Vulkan device"), -1;
  vkGetDeviceQueue(dev, qfam, 0, &queue);

  // 64-lane subgroups where the driver can be asked for them (VK_SUBGROUP_SIZE overrides; 0: the
  // driver's choice).
  env = getenv("VK_SUBGROUP_SIZE");
  uint32_t want = env && *env ? (uint32_t)atoi(env) : 64;
  if (want && v13.subgroupSizeControl && (p13.requiredSubgroupSizeStages & VK_SHADER_STAGE_COMPUTE_BIT) &&
      p13.minSubgroupSize <= want && want <= p13.maxSubgroupSize)
    subgroup = want;
  full_subgroups = subgroup && v13.computeFullSubgroups;

  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, MAX_PENDING * 8};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, MAX_PENDING, 1, &ps};
  vkCreateDescriptorPool(dev, &dpi, NULL, &pool);
  VkCommandPoolCreateInfo cpo = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL,
                                 VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, qfam};
  VkCommandPool cpool;
  vkCreateCommandPool(dev, &cpo, NULL, &cpool);
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, cpool,
                                     VK_COMMAND_BUFFER_LEVEL_PRIMARY, MAX_SUBMITS};
  vkAllocateCommandBuffers(dev, &cai, cmds);
  if (make_buffer(&params, PARAMS_ARENA)) return fail("cannot allocate the params arena"), -1;
  open_pipeline_cache();
  if (profile)
    fprintf(stderr, "vulkan executor: %s, Vulkan %u.%u, subgroup %u%s, cooperative matrices %s, %d commands a submission\n",
            props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion), VK_API_VERSION_MINOR(props.apiVersion),
            subgroup, full_subgroups ? " (full)" : "", coopmat ? "on" : "off", submit_every);
  return 0;
}
