// Vulkan executor on the phone for the remote MAX device: owns the GPU's buffers and pipelines and
// runs what the Mac-side driver plugin (remote/vulkan_remote_plugin.cpp) sends over one TCP
// connection (`adb forward tcp:7788 tcp:7788`). Requests run in order, each to completion, so the
// plugin's queues are synchronous.
//
//   LD_LIBRARY_PATH=/data/local/tmp/turnip vk_server [port]
//
// Protocol (little-endian): a request is {u32 op, u32 length, payload}, a reply
// {i32 status, u32 length, payload}; status 0 is success, otherwise the payload is a message.
// Buffers are host-visible and coherent, so copies and fills are memcpy and memset here.
#define VK_NO_PROTOTYPES
#include <arpa/inet.h>
#include <dlfcn.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>
#include <vulkan/vulkan.h>

#include "protocol.h"

#define VK_FUNCS(X)                                                                      \
  X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties)     \
  X(vkGetPhysicalDeviceQueueFamilyProperties) X(vkGetPhysicalDeviceMemoryProperties)     \
  X(vkCreateDevice) X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkGetBufferMemoryRequirements) \
  X(vkAllocateMemory) X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateShaderModule)       \
  X(vkCreateDescriptorSetLayout) X(vkCreatePipelineLayout) X(vkCreateComputePipelines)   \
  X(vkCreateDescriptorPool) X(vkAllocateDescriptorSets) X(vkUpdateDescriptorSets)        \
  X(vkResetDescriptorPool) X(vkCreateCommandPool) X(vkAllocateCommandBuffers)            \
  X(vkBeginCommandBuffer) X(vkEndCommandBuffer) X(vkResetCommandBuffer)                  \
  X(vkCmdBindPipeline) X(vkCmdBindDescriptorSets) X(vkCmdDispatch) X(vkQueueSubmit)      \
  X(vkQueueWaitIdle) X(vkGetPhysicalDeviceFeatures2) X(vkDestroyBuffer) X(vkFreeMemory)  \
  X(vkDestroyShaderModule) X(vkDestroyPipeline)

#define DECL(f) static PFN_##f f;
VK_FUNCS(DECL)

static VkDevice dev;
static VkQueue queue;
static VkPhysicalDeviceMemoryProperties memprops;
static VkPhysicalDeviceProperties props;
static VkDescriptorPool pool;
static VkCommandBuffer cmd;
static int client = -1;

// --- replies -------------------------------------------------------------------------------

static int send_all(const void* data, size_t n) {
  const char* p = data;
  while (n) {
    ssize_t k = send(client, p, n, 0);
    if (k <= 0) return -1;
    p += k;
    n -= (size_t)k;
  }
  return 0;
}

static int recv_all(void* data, size_t n) {
  char* p = data;
  while (n) {
    ssize_t k = recv(client, p, n, 0);
    if (k <= 0) return -1;
    p += k;
    n -= (size_t)k;
  }
  return 0;
}

static void reply(int32_t status, const void* data, uint32_t n) {
  uint32_t header[2] = {(uint32_t)status, n};
  send_all(header, sizeof header);
  if (n) send_all(data, n);
}

static void fail(const char* format, ...) {
  char message[512];
  va_list ap;
  va_start(ap, format);
  vsnprintf(message, sizeof message, format, ap);
  va_end(ap);
  fprintf(stderr, "vk_server: %s\n", message);
  reply(1, message, (uint32_t)strlen(message));
}

// --- buffers -------------------------------------------------------------------------------

typedef struct {
  VkBuffer buf;
  VkDeviceMemory mem;
  char* map;
  uint64_t size;
} buffer_t;

static buffer_t* buffers;
static uint64_t nbuffers;

static buffer_t* buffer(uint64_t id) {
  return id && id <= nbuffers && buffers[id - 1].buf ? &buffers[id - 1] : NULL;
}

static uint64_t alloc_buffer(uint64_t size) {
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size ? size : 4;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
  buffer_t b = {0};
  b.size = bi.size;
  if (vkCreateBuffer(dev, &bi, NULL, &b.buf) != VK_SUCCESS) return 0;
  VkMemoryRequirements mr;
  vkGetBufferMemoryRequirements(dev, b.buf, &mr);
  uint32_t want = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, ti = 0;
  for (uint32_t i = 0; i < memprops.memoryTypeCount; ++i)
    if ((mr.memoryTypeBits & (1u << i)) && (memprops.memoryTypes[i].propertyFlags & want) == want) { ti = i; break; }
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, NULL, mr.size, ti};
  if (vkAllocateMemory(dev, &ai, NULL, &b.mem) != VK_SUCCESS) {
    vkDestroyBuffer(dev, b.buf, NULL);
    return 0;
  }
  vkBindBufferMemory(dev, b.buf, b.mem, 0);
  vkMapMemory(dev, b.mem, 0, b.size, 0, (void**)&b.map);
  buffers = realloc(buffers, (nbuffers + 1) * sizeof *buffers);
  buffers[nbuffers++] = b;
  return nbuffers;
}

static int in_range(buffer_t* b, uint64_t offset, uint64_t size) {
  return b && offset <= b->size && size <= b->size - offset;
}

// --- kernels -------------------------------------------------------------------------------

typedef struct {
  VkShaderModule module;
  // Pipelines by (block size, binding count): Vulkan fixes both at pipeline creation.
  struct { uint32_t block[3], nbind; VkPipeline pipe; VkPipelineLayout layout; VkDescriptorSetLayout dsl; } *cache;
  int ncache;
} module_t;

static module_t* modules;
static uint64_t nmodules;

static int pipeline(module_t* m, const uint32_t block[3], uint32_t nbind, VkPipeline* pipe,
                    VkPipelineLayout* layout, VkDescriptorSetLayout* dsl) {
  for (int i = 0; i < m->ncache; ++i)
    if (!memcmp(m->cache[i].block, block, 12) && m->cache[i].nbind == nbind) {
      *pipe = m->cache[i].pipe, *layout = m->cache[i].layout, *dsl = m->cache[i].dsl;
      return 0;
    }
  VkDescriptorSetLayoutBinding binds[MAX_BINDINGS];
  for (uint32_t i = 0; i < nbind; ++i)
    binds[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, nbind, binds};
  if (vkCreateDescriptorSetLayout(dev, &dli, NULL, dsl) != VK_SUCCESS) return -1;
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, dsl};
  if (vkCreatePipelineLayout(dev, &pli, NULL, layout) != VK_SUCCESS) return -1;
  // The block size as specialization constants 0-2 (a module without them ignores the entries).
  VkSpecializationMapEntry entries[3] = {{0, 0, 4}, {1, 4, 4}, {2, 8, 4}};
  VkSpecializationInfo spec = {3, entries, 12, block};
  VkComputePipelineCreateInfo cpi = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  cpi.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  cpi.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  cpi.stage.module = m->module;
  cpi.stage.pName = "main";
  cpi.stage.pSpecializationInfo = &spec;
  cpi.layout = *layout;
  if (vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &cpi, NULL, pipe) != VK_SUCCESS) return -1;
  m->cache = realloc(m->cache, (m->ncache + 1) * sizeof *m->cache);
  memcpy(m->cache[m->ncache].block, block, 12);
  m->cache[m->ncache].nbind = nbind;
  m->cache[m->ncache].pipe = *pipe;
  m->cache[m->ncache].layout = *layout;
  m->cache[m->ncache].dsl = *dsl;
  m->ncache++;
  return 0;
}

static void launch(const char* p, uint32_t n) {
  const launch_t* l = (const launch_t*)p;
  if (n < sizeof *l || l->nbind > MAX_BINDINGS ||
      n < sizeof *l + l->nbind * sizeof(binding_t) + l->params_len)
    return fail("malformed launch");
  if (!l->module || l->module > nmodules) return fail("bad module %llu", (unsigned long long)l->module);
  const binding_t* binds = (const binding_t*)(p + sizeof *l);
  const char* params = (const char*)(binds + l->nbind);
  uint32_t nbind = l->nbind + (l->params_len ? 1 : 0);
  VkPipeline pipe;
  VkPipelineLayout layout;
  VkDescriptorSetLayout dsl;
  if (pipeline(&modules[l->module - 1], l->block, nbind, &pipe, &layout, &dsl))
    return fail("cannot create a pipeline for module %llu, block %u %u %u", (unsigned long long)l->module,
                l->block[0], l->block[1], l->block[2]);

  // The params buffer, fresh for each launch.
  uint64_t params_id = 0;
  if (l->params_len) {
    params_id = alloc_buffer(l->params_len);
    if (!params_id) return fail("cannot allocate %u bytes of params", l->params_len);
    memcpy(buffer(params_id)->map, params, l->params_len);
  }
  vkResetDescriptorPool(dev, pool, 0);
  VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, pool, 1, &dsl};
  VkDescriptorSet ds;
  if (vkAllocateDescriptorSets(dev, &dai, &ds) != VK_SUCCESS) return fail("cannot allocate a descriptor set");
  VkDescriptorBufferInfo infos[MAX_BINDINGS + 1];
  VkWriteDescriptorSet writes[MAX_BINDINGS + 1];
  uint64_t align = props.limits.minStorageBufferOffsetAlignment;
  for (uint32_t i = 0; i < nbind; ++i) {
    buffer_t* b;
    uint64_t offset = 0;
    if (i < l->nbind) {
      b = buffer(binds[i].buffer);
      offset = binds[i].offset;
      if (!b || offset >= b->size) return fail("binding %u: bad buffer %llu", i, (unsigned long long)binds[i].buffer);
      if (offset % align)
        return fail("binding %u: offset %llu is not a multiple of %llu", i, (unsigned long long)offset,
                    (unsigned long long)align);
    } else {
      b = buffer(params_id);
    }
    infos[i] = (VkDescriptorBufferInfo){b->buf, offset, VK_WHOLE_SIZE};
    writes[i] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, ds, i, 0, 1,
                                       VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &infos[i], NULL};
  }
  vkUpdateDescriptorSets(dev, nbind, writes, 0, NULL);
  vkResetCommandBuffer(cmd, 0);
  VkCommandBufferBeginInfo bbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  vkBeginCommandBuffer(cmd, &bbi);
  vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pipe);
  vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, layout, 0, 1, &ds, 0, NULL);
  vkCmdDispatch(cmd, l->groups[0], l->groups[1], l->groups[2]);
  vkEndCommandBuffer(cmd);
  VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
  si.commandBufferCount = 1;
  si.pCommandBuffers = &cmd;
  VkResult r = vkQueueSubmit(queue, 1, &si, VK_NULL_HANDLE);
  if (r == VK_SUCCESS) r = vkQueueWaitIdle(queue);
  if (params_id) {
    buffer_t* b = buffer(params_id);
    vkDestroyBuffer(dev, b->buf, NULL);
    vkFreeMemory(dev, b->mem, NULL);
    b->buf = VK_NULL_HANDLE;
  }
  if (r != VK_SUCCESS) return fail("dispatch failed: VkResult %d", (int)r);
  reply(0, NULL, 0);
}

// --- requests ------------------------------------------------------------------------------

static void handle(uint32_t op, char* p, uint32_t n) {
  uint64_t* w = (uint64_t*)p;
  switch (op) {
  case OP_INFO: {
    char info[512];
    int k = snprintf(info, sizeof info, "%s|%u.%u|%llu", props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion),
                     VK_API_VERSION_MINOR(props.apiVersion),
                     (unsigned long long)props.limits.minStorageBufferOffsetAlignment);
    return reply(0, info, (uint32_t)k);
  }
  case OP_ALLOC: {
    if (n != 8) return fail("malformed alloc");
    uint64_t id = alloc_buffer(w[0]);
    if (!id) return fail("cannot allocate %llu bytes", (unsigned long long)w[0]);
    return reply(0, &id, 8);
  }
  case OP_FREE: {
    buffer_t* b = n == 8 ? buffer(w[0]) : NULL;
    if (!b) return fail("bad buffer to free");
    vkDestroyBuffer(dev, b->buf, NULL);
    vkFreeMemory(dev, b->mem, NULL);
    b->buf = VK_NULL_HANDLE;
    return reply(0, NULL, 0);
  }
  case OP_WRITE: {
    buffer_t* b = n >= 16 ? buffer(w[0]) : NULL;
    if (!in_range(b, w[1], n - 16)) return fail("write out of range");
    memcpy(b->map + w[1], p + 16, n - 16);
    return reply(0, NULL, 0);
  }
  case OP_READ: {
    buffer_t* b = n == 24 ? buffer(w[0]) : NULL;
    if (!in_range(b, w[1], w[2]) || w[2] > 0xffffffffu) return fail("read out of range");
    return reply(0, b->map + w[1], (uint32_t)w[2]);
  }
  case OP_FILL: {  // id, offset, size, value, value_size
    buffer_t* b = n == 40 ? buffer(w[0]) : NULL;
    if (!in_range(b, w[1], w[2]) || !w[4] || w[4] > 8) return fail("bad fill");
    for (uint64_t i = 0; i < w[2]; i += w[4])
      memcpy(b->map + w[1] + i, &w[3], w[2] - i < w[4] ? w[2] - i : w[4]);
    return reply(0, NULL, 0);
  }
  case OP_COPY: {  // dst, dst offset, src, src offset, size
    buffer_t *d = n == 40 ? buffer(w[0]) : NULL, *s = n == 40 ? buffer(w[2]) : NULL;
    if (!in_range(d, w[1], w[4]) || !in_range(s, w[3], w[4])) return fail("copy out of range");
    memmove(d->map + w[1], s->map + w[3], w[4]);
    return reply(0, NULL, 0);
  }
  case OP_LOAD: {
    VkShaderModuleCreateInfo smi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, n, (uint32_t*)p};
    module_t m = {0};
    if (n % 4 || vkCreateShaderModule(dev, &smi, NULL, &m.module) != VK_SUCCESS) return fail("bad SPIR-V module");
    modules = realloc(modules, (nmodules + 1) * sizeof *modules);
    modules[nmodules++] = m;
    uint64_t id = nmodules;
    return reply(0, &id, 8);
  }
  case OP_LAUNCH:
    return launch(p, n);
  case OP_SYNC:
    return reply(0, NULL, 0);
  default:
    return fail("unknown request %u", op);
  }
}

static void init_vulkan(void) {
  void* lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
  if (!lib) { fprintf(stderr, "dlopen libvulkan.so: %s\n", dlerror()); exit(2); }
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "vk_server", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO};
  ici.pApplicationInfo = &app;
  VkInstance inst;
  if (vkCreateInstance(&ici, NULL, &inst) != VK_SUCCESS) { fprintf(stderr, "no Vulkan instance\n"); exit(2); }
#define LOAD(f) f = (PFN_##f)gipa(inst, #f);
  VK_FUNCS(LOAD)
  uint32_t npd = 1;
  VkPhysicalDevice pd;
  vkEnumeratePhysicalDevices(inst, &npd, &pd);
  vkGetPhysicalDeviceProperties(pd, &props);
  vkGetPhysicalDeviceMemoryProperties(pd, &memprops);
  uint32_t nq = 0;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, NULL);
  VkQueueFamilyProperties qf[16];
  if (nq > 16) nq = 16;
  vkGetPhysicalDeviceQueueFamilyProperties(pd, &nq, qf);
  uint32_t qfam = 0;
  for (uint32_t i = 0; i < nq; ++i) if (qf[i].queueFlags & VK_QUEUE_COMPUTE_BIT) { qfam = i; break; }
  // Enable what LLVM-generated SPIR-V may declare (Int8, Int16, Int64, 8- and 16-bit storage, f16).
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES};
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  vkGetPhysicalDeviceFeatures2(pd, &f2);
  VkPhysicalDeviceVulkan12Features en12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES};
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
  if (vkCreateDevice(pd, &dci, NULL, &dev) != VK_SUCCESS) { fprintf(stderr, "no Vulkan device\n"); exit(2); }
  vkGetDeviceQueue(dev, qfam, 0, &queue);
  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, MAX_BINDINGS + 1};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1, 1, &ps};
  vkCreateDescriptorPool(dev, &dpi, NULL, &pool);
  VkCommandPoolCreateInfo cpo = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL,
                                 VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, qfam};
  VkCommandPool cpool;
  vkCreateCommandPool(dev, &cpo, NULL, &cpool);
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, cpool,
                                     VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  vkAllocateCommandBuffers(dev, &cai, &cmd);
  printf("vk_server: %s, Vulkan %u.%u\n", props.deviceName, VK_API_VERSION_MAJOR(props.apiVersion),
         VK_API_VERSION_MINOR(props.apiVersion));
}

int main(int argc, char** argv) {
  int port = argc > 1 ? atoi(argv[1]) : DEFAULT_PORT;
  init_vulkan();
  int s = socket(AF_INET, SOCK_STREAM, 0);
  int one = 1;
  setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
  struct sockaddr_in addr = {0};
  addr.sin_family = AF_INET;
  addr.sin_port = htons((uint16_t)port);
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  if (bind(s, (struct sockaddr*)&addr, sizeof addr) || listen(s, 1)) { perror("bind"); return 2; }
  printf("vk_server: listening on 127.0.0.1:%d\n", port);
  fflush(stdout);
  // One client at a time; its buffers and modules outlive it until the server exits.
  for (;;) {
    client = accept(s, NULL, NULL);
    if (client < 0) continue;
    setsockopt(client, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
    uint32_t header[2];
    char* payload = NULL;
    while (!recv_all(header, sizeof header)) {
      payload = realloc(payload, header[1] ? header[1] : 1);
      if (recv_all(payload, header[1])) break;
      handle(header[0], payload, header[1]);
    }
    free(payload);
    close(client);
    client = -1;
  }
}
