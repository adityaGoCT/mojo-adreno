// repro: reproduces the Adreno 850 Vulkan driver bugs in this directory, one test per process.
//   repro <test> [shader_dir]      (repro list: all tests)
// Each test creates one compute pipeline from shaders/<test>.spv, runs it on deterministic inputs and checks the
// output on the CPU. It prints one line:
//   RESULT <test> PASS|WRONG|PIPELINE_ERROR|DEVICE_LOST <details>
// A compiler crash inside vkCreateComputePipelines kills the process before RESULT (run_all.sh reports the signal).
// Standalone: needs only libvulkan.so and the SPIR-V files. Build: see build.sh.
#define VK_NO_PROTOTYPES
#include <dlfcn.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <vulkan/vulkan.h>

#define VK_FUNCS(X)                                                                                         \
  X(vkCreateInstance) X(vkEnumeratePhysicalDevices) X(vkGetPhysicalDeviceProperties)                        \
  X(vkGetPhysicalDeviceMemoryProperties) X(vkCreateDevice) X(vkGetDeviceProcAddr)                           \
  X(vkGetPhysicalDeviceProperties2)
#define VK_DFUNCS(X)                                                                                        \
  X(vkGetDeviceQueue) X(vkCreateBuffer) X(vkGetBufferMemoryRequirements) X(vkAllocateMemory)                \
  X(vkBindBufferMemory) X(vkMapMemory) X(vkCreateCommandPool) X(vkAllocateCommandBuffers)                   \
  X(vkBeginCommandBuffer) X(vkEndCommandBuffer) X(vkResetCommandBuffer) X(vkQueueSubmit) X(vkQueueWaitIdle) \
  X(vkCreateQueryPool) X(vkCmdResetQueryPool) X(vkCmdWriteTimestamp) X(vkGetQueryPoolResults)               \
  X(vkCreateShaderModule) X(vkCreateComputePipelines) X(vkCreateDescriptorSetLayout)                        \
  X(vkCreatePipelineLayout) X(vkCmdBindPipeline) X(vkCmdDispatch) X(vkCmdPushConstants)                     \
  X(vkCmdPushDescriptorSetKHR) X(vkCreateDescriptorPool) X(vkAllocateDescriptorSets)                    \
  X(vkUpdateDescriptorSets) X(vkCmdBindDescriptorSets) X(vkCmdPipelineBarrier)
#define VKFN(f) static PFN_##f f;
VK_FUNCS(VKFN)
VK_DFUNCS(VKFN)

static VkDevice dev;
static VkQueue queue;
static VkPhysicalDeviceMemoryProperties memprops;
static double ts_ns;
static char devname[256], drvinfo[256];

#define CK(x) do { VkResult r_ = (x); if (r_) { printf("vulkan error %d at %s\n", r_, #x); exit(3); } } while (0)

typedef struct { VkBuffer buf; void* map; size_t size; } buf_t;

static buf_t mkbuf(size_t size) {
  buf_t b = {0};
  b.size = size;
  VkBufferCreateInfo bi = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  bi.size = size;
  bi.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
  CK(vkCreateBuffer(dev, &bi, NULL, &b.buf));
  VkMemoryRequirements mr;
  vkGetBufferMemoryRequirements(dev, b.buf, &mr);
  uint32_t want = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, type = 0;
  for (uint32_t i = 0; i < memprops.memoryTypeCount; ++i)
    if ((mr.memoryTypeBits >> i & 1) && (memprops.memoryTypes[i].propertyFlags & want) == want) { type = i; break; }
  VkMemoryAllocateInfo ai = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO, NULL, mr.size, type};
  VkDeviceMemory mem;
  CK(vkAllocateMemory(dev, &ai, NULL, &mem));
  CK(vkBindBufferMemory(dev, b.buf, mem, 0));
  CK(vkMapMemory(dev, mem, 0, VK_WHOLE_SIZE, 0, &b.map));
  memset(b.map, 0, size);
  return b;
}

static void init_vulkan(void) {
  void* lib = dlopen("libvulkan.so", RTLD_NOW);
  PFN_vkGetInstanceProcAddr gipa = (PFN_vkGetInstanceProcAddr)dlsym(lib, "vkGetInstanceProcAddr");
  vkCreateInstance = (PFN_vkCreateInstance)gipa(NULL, "vkCreateInstance");
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO, NULL, "adreno-repro", 1, NULL, 0, VK_API_VERSION_1_3};
  VkInstanceCreateInfo ici = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, NULL, 0, &app};
  VkInstance inst;
  CK(vkCreateInstance(&ici, NULL, &inst));
#define LI(f) f = (PFN_##f)gipa(inst, #f);
  VK_FUNCS(LI)
  uint32_t n = 1;
  VkPhysicalDevice pd;
  vkEnumeratePhysicalDevices(inst, &n, &pd);
  VkPhysicalDeviceDriverProperties drv = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DRIVER_PROPERTIES};
  VkPhysicalDeviceProperties2 p2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2, &drv};
  vkGetPhysicalDeviceProperties2(pd, &p2);
  snprintf(devname, sizeof devname, "%s", p2.properties.deviceName);
  snprintf(drvinfo, sizeof drvinfo, "%s %s (driverVersion 0x%x, Vulkan %u.%u.%u)", drv.driverName, drv.driverInfo,
           p2.properties.driverVersion, VK_API_VERSION_MAJOR(p2.properties.apiVersion),
           VK_API_VERSION_MINOR(p2.properties.apiVersion), VK_API_VERSION_PATCH(p2.properties.apiVersion));
  ts_ns = p2.properties.limits.timestampPeriod;
  vkGetPhysicalDeviceMemoryProperties(pd, &memprops);
  float prio = 1;
  VkDeviceQueueCreateInfo q = {VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, NULL, 0, 0, 1, &prio};
  VkPhysicalDeviceCooperativeMatrixFeaturesKHR cm = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
  cm.cooperativeMatrix = VK_TRUE;
  VkPhysicalDeviceVulkan12Features v12 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES, &cm};
  v12.shaderFloat16 = v12.shaderInt8 = v12.storageBuffer8BitAccess = VK_TRUE;
  v12.vulkanMemoryModel = v12.vulkanMemoryModelDeviceScope = VK_TRUE;
  VkPhysicalDeviceVulkan11Features v11 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES, &v12};
  v11.storageBuffer16BitAccess = VK_TRUE;
  VkPhysicalDeviceFeatures2 f2 = {VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2, &v11};
  const char* exts[] = {"VK_KHR_push_descriptor", "VK_KHR_cooperative_matrix"};
  VkDeviceCreateInfo dci = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO, &f2, 0, 1, &q, 0, NULL, 2, exts};
  CK(vkCreateDevice(pd, &dci, NULL, &dev));
#define LD(f) f = (PFN_##f)vkGetDeviceProcAddr(dev, #f);
  VK_DFUNCS(LD)
  vkGetDeviceQueue(dev, 0, 0, &queue);
}

// ---- inputs -------------------------------------------------------------------------------------------------
static uint32_t rng = 1;
static float frand(void) {  // [-1, 1)
  rng = rng * 1664525u + 1013904223u;
  return (float)(rng >> 8) / (float)(1u << 23) - 1.0f;
}
static void fill_f16(buf_t* b) {
  _Float16* h = b->map;
  for (size_t i = 0; i < b->size / 2; ++i) h[i] = (_Float16)frand();
}
static void fill_i8(buf_t* b) {
  int8_t* p = b->map;
  for (size_t i = 0; i < b->size; ++i) p[i] = (int8_t)((int)(frand() * 50));
}

// ---- tests --------------------------------------------------------------------------------------------------
enum { GEMM, ADD_F16, ADD_I8, MM_F16OUT, MM_F32OUT, SHARED_COPY, IDENT_B, ACC_COPY, BRANCH, FA, Q4ID, COMPILE, INTERLEAVE };
typedef struct {
  const char* name;
  int kind;
  uint32_t M, N, K;       // GEMM shape
  char la;                // GEMM: 'N' A stored [M,K], 'T' A stored [K,M]; B always [K,N]
  uint32_t gx, gy;        // dispatch
  int spec;               // pass M, N, K as specialization constants 0, 1, 2
  const char* what;       // one-line description
} test_t;

static const test_t tests[] = {
  // bug 1: K unrolled by 2 with two 64 x 32 accumulators per subgroup -> GPU hang
  {"b01_min_two_acc_kunroll2", GEMM, 1024, 1024, 1024, 'N', 16, 16, 0, "two 64x32 accumulators, K unrolled by 2"},
  {"b01_min_control_two_acc_ku1", GEMM, 1024, 1024, 1024, 'N', 16, 16, 0, "control: two accumulators, K not unrolled"},
  {"b01_note_one_acc_kunroll2", GEMM, 1024, 1024, 1024, 'N', 32, 16, 0, "note: one accumulator, K unrolled by 2 (runs)"},
  {"b01_kunroll2_gemm_tn_1024", GEMM, 1024, 1024, 1024, 'T', 8, 8, 0, "AdrenoBLAS kernel, K unrolled by 2, 64x32 tiles"},
  {"b01_control_ku1_gemm_tn_1024", GEMM, 1024, 1024, 1024, 'T', 8, 8, 0, "control: same kernel, K not unrolled"},
  // bug 2: adding two cooperative matrices
  {"b02_add_f16", ADD_F16, 0, 0, 0, 0, 1, 1, 0, "c0 + c1 on two fp16 accumulators"},
  {"b02_control_add_elementwise", ADD_F16, 0, 0, 0, 0, 1, 1, 0, "control: element-wise sum"},
  {"b02_add_i8_loop", COMPILE, 0, 0, 0, 0, 2048, 1, 0, "int8 multiplies with ma = ma + ma between them"},
  {"b02_control_i8_loop_noadd", COMPILE, 0, 0, 0, 0, 2048, 1, 0, "control: the same loop without ma + ma"},
  // bug 3: fp32 accumulator converted to fp16
  {"b03_f32_to_f16", MM_F16OUT, 0, 0, 0, 0, 1, 1, 0, "fp32 accumulator converted to an fp16 accumulator"},
  {"b03_control_store_f32", MM_F32OUT, 0, 0, 0, 0, 1, 1, 0, "control: fp32 accumulator stored as fp32"},
  // bug 4: two 64 x 64 accumulators per subgroup -> GPU hang
  {"b04_min_two_acc64", GEMM, 2048, 2048, 2048, 'N', 16, 32, 0, "two 64x64 accumulators per subgroup"},
  {"b04_min_control_one_acc64", GEMM, 2048, 2048, 2048, 'N', 32, 32, 0, "control: one 64x64 accumulator per subgroup"},
  {"b04_two_acc64_gemm_tn_2048", GEMM, 2048, 2048, 2048, 'T', 8, 16, 0, "AdrenoBLAS kernel, two 64x64 tiles per subgroup"},
  {"b04_control_one_acc64_gemm_tn_2048", GEMM, 2048, 2048, 2048, 'T', 16, 16, 0, "control: one 64x64 tile per subgroup"},
  // bug 5: coopMatLoad from uint / uvec4 shared memory
  {"b05_shared_uvec4", SHARED_COPY, 0, 0, 0, 0, 1, 1, 0, "coopMatLoad from a uvec4 shared array"},
  {"b05_shared_uint", SHARED_COPY, 0, 0, 0, 0, 1, 1, 0, "coopMatLoad from a uint shared array"},
  {"b05_control_shared_f16vec4", SHARED_COPY, 0, 0, 0, 0, 1, 1, 0, "control: coopMatLoad from an f16vec4 shared array"},
  // bug 6: four accumulators combined element-wise -> pipeline creation fails
  {"b06_dual_t1x2_gemm_tn_1024", GEMM, 1024, 1024, 1024, 'T', 8, 8, 0, "four 64x32 accumulators, two chains combined element-wise"},
  {"b06_control_dual_t1x1_gemm_tn_1024", GEMM, 1024, 1024, 1024, 'T', 16, 8, 0, "control: two accumulators combined element-wise"},
  // bug 7: specialization constants
  {"b07_nn_2048_specconst", GEMM, 2048, 2048, 2048, 'N', 8, 16, 1, "M, N, K as specialization constants (timed)"},
  {"b07_control_nn_2048_literals", GEMM, 2048, 2048, 2048, 'N', 8, 16, 0, "control: M, N, K as literals (timed)"},
  {"b07_tn_1024_specconst", GEMM, 1024, 1024, 1024, 'T', 8, 8, 1, "M, N, K as specialization constants"},
  {"b07_control_tn_1024_literals", GEMM, 1024, 1024, 1024, 'T', 8, 8, 0, "control: literals"},
  // bugs 8 and 9: element writes into a B matrix (AdrenoBLAS's Q4_0 kernel); control for both: b09_q4_control_runtime_index
  {"b08_q4_uninit", Q4ID, 64, 64, 64, 0, 1, 1, 0, "Q4_0 kernel, B matrices not initialized before element writes"},
  {"b09_q4_elem4_const", Q4ID, 64, 64, 64, 0, 1, 1, 0, "Q4_0 kernel, element 4 of B written with a constant index"},
  {"b09_q4_control_runtime_index", Q4ID, 64, 64, 64, 0, 1, 1, 0, "control: initialized, element 4 written with a runtime index"},
  // bug 10: constant-index accumulator element reads into a vector constructor
  {"b10_const_acc_element_read", ACC_COPY, 0, 0, 0, 0, 1, 1, 0, "constant-index accumulator element reads into f16vec4"},
  {"b10_control_loop_read", ACC_COPY, 0, 0, 0, 0, 1, 1, 0, "control: the same reads with a loop index"},
  // bug 11: multiplies under a branch that differs between the subgroups of a workgroup
  {"b11_branch_mma", BRANCH, 0, 0, 0, 0, 1, 1, 0, "multiplies under a branch that differs between subgroups"},
  {"b11_control_unconditional", BRANCH, 0, 0, 0, 0, 1, 1, 0, "control: no multiply under a branch"},
  {"b11_fa3_original", FA, 512, 0, 0, 0, 8, 24, 0, "flash attention with per-subgroup branches around multiplies"},
  {"b11_control_fa3_workaround", FA, 512, 0, 0, 0, 8, 24, 0, "control: the same kernel, every multiply unconditional"},
  // bug 12 (candidate): straight-line element writes into a B matrix
  {"b12_elem_write_straightline", IDENT_B, 0, 0, 0, 0, 1, 1, 0, "16 element writes into an initialized B matrix, one multiply"},
  {"b12_control_coopmatload", IDENT_B, 0, 0, 0, 0, 1, 1, 0, "control: the same B loaded with coopMatLoad"},

  {"b13_push_then_bound_set", INTERLEAVE, 0, 0, 0, 0, 1024, 1, 0, "3 push-descriptor dispatches, each followed by a dispatch with an ordinary descriptor set"},
  {"b13_control_no_bound_set", INTERLEAVE, 0, 0, 0, 0, 1024, 1, 0, "control: the same 3 push-descriptor dispatches only"},
};
#define NTESTS (sizeof tests / sizeof tests[0])

static VkPipeline make_pipeline(const char* path, const test_t* t, VkPipelineLayout layout) {
  FILE* f = fopen(path, "rb");
  if (!f) { printf("cannot open %s\n", path); exit(2); }
  fseek(f, 0, SEEK_END);
  size_t n = ftell(f);
  fseek(f, 0, SEEK_SET);
  uint32_t* code = malloc(n);
  if (fread(code, 1, n, f) != n) exit(2);
  fclose(f);
  VkShaderModuleCreateInfo mi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, n, code};
  VkShaderModule mod;
  CK(vkCreateShaderModule(dev, &mi, NULL, &mod));
  uint32_t sv[3] = {t->M, t->N, t->K};
  VkSpecializationMapEntry me[3] = {{0, 0, 4}, {1, 4, 4}, {2, 8, 4}};
  VkSpecializationInfo si = {3, me, sizeof sv, sv};
  VkComputePipelineCreateInfo ci = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
  ci.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
  ci.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
  ci.stage.module = mod;
  ci.stage.pName = "main";
  ci.stage.pSpecializationInfo = t->spec ? &si : NULL;
  ci.layout = layout;
  VkPipeline p;
  printf("creating pipeline (vkCreateComputePipelines)...\n");
  fflush(stdout);
  VkResult r = vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &ci, NULL, &p);
  if (r) {
    printf("RESULT %s PIPELINE_ERROR vkCreateComputePipelines returned %d\n", t->name, r);
    exit(1);
  }
  printf("pipeline created\n");
  return p;
}

static uint8_t q4ref[64][64];
static float q4d[64][2];
static float h2f(const void* p, size_t i) { return (float)((const _Float16*)p)[i]; }

// ---- bug 13: push-descriptor dispatches interleaved with ordinary-descriptor-set dispatches ----------------------
static void barrier(VkCommandBuffer cmd) {
  VkMemoryBarrier mb = {VK_STRUCTURE_TYPE_MEMORY_BARRIER, NULL, VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT,
                        VK_ACCESS_SHADER_READ_BIT | VK_ACCESS_SHADER_WRITE_BIT};
  vkCmdPipelineBarrier(cmd, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 0, 1, &mb, 0, NULL, 0, NULL);
}

static int run_interleave(const test_t* t, VkPipeline pipe, VkPipelineLayout layout, const char* dir) {
  const int other = strstr(t->name, "control") == NULL, n = 3;
  const uint32_t len = t->gx * 64;
  // the other pipeline: its own layout, an ordinary descriptor set with one storage buffer
  VkDescriptorSetLayoutBinding ob = {0, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo odli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, 1, &ob};
  VkDescriptorSetLayout odsl;
  CK(vkCreateDescriptorSetLayout(dev, &odli, NULL, &odsl));
  VkPipelineLayoutCreateInfo opli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &odsl, 0, NULL};
  VkPipelineLayout olayout;
  CK(vkCreatePipelineLayout(dev, &opli, NULL, &olayout));
  char path[512];
  snprintf(path, sizeof path, "%s/b13_bound_set_dispatch.spv", dir);
  VkPipeline opipe = make_pipeline(path, t, olayout);
  VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1};
  VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1, 1, &ps};
  VkDescriptorPool dpool;
  CK(vkCreateDescriptorPool(dev, &dpi, NULL, &dpool));
  VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, dpool, 1, &odsl};
  VkDescriptorSet oset;
  CK(vkAllocateDescriptorSets(dev, &dai, &oset));
  buf_t scratch = mkbuf((size_t)len * 4), out[3];
  VkDescriptorBufferInfo sbi = {scratch.buf, 0, VK_WHOLE_SIZE};
  VkWriteDescriptorSet sw = {VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, oset, 0, 0, 1, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &sbi, NULL};
  vkUpdateDescriptorSets(dev, 1, &sw, 0, NULL);

  VkCommandPoolCreateInfo cpi = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL, 0, 0};
  VkCommandPool pool;
  CK(vkCreateCommandPool(dev, &cpi, NULL, &pool));
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, pool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  VkCommandBuffer cmd;
  CK(vkAllocateCommandBuffers(dev, &cai, &cmd));
  VkCommandBufferBeginInfo cbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  CK(vkBeginCommandBuffer(cmd, &cbi));
  for (int i = 0; i < n; ++i) {
    out[i] = mkbuf((size_t)len * 4);
    VkDescriptorBufferInfo bi = {out[i].buf, 0, VK_WHOLE_SIZE};
    VkWriteDescriptorSet w = {VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, VK_NULL_HANDLE, 0, 0, 1, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi, NULL};
    uint32_t tag = (uint32_t)i + 1;
    vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pipe);
    vkCmdPushDescriptorSetKHR(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, layout, 0, 1, &w);
    vkCmdPushConstants(cmd, layout, VK_SHADER_STAGE_COMPUTE_BIT, 0, 4, &tag);
    vkCmdDispatch(cmd, t->gx, 1, 1);
    barrier(cmd);
    if (other) {
      vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, opipe);
      vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, olayout, 0, 1, &oset, 0, NULL);
      vkCmdDispatch(cmd, t->gx, 1, 1);
      barrier(cmd);
    }
  }
  CK(vkEndCommandBuffer(cmd));
  VkSubmitInfo sub = {VK_STRUCTURE_TYPE_SUBMIT_INFO, NULL, 0, NULL, NULL, 1, &cmd};
  printf("submitting...\n");
  CK(vkQueueSubmit(queue, 1, &sub, VK_NULL_HANDLE));
  CK(vkQueueWaitIdle(queue));
  char detail[512] = "";
  int bad_bufs = 0;
  for (int i = 0; i < n; ++i) {
    uint32_t bad = 0, zero = 0;
    for (uint32_t j = 0; j < len; ++j) {
      uint32_t v = ((uint32_t*)out[i].map)[j];
      bad += v != (uint32_t)(i + 1) * 65536u + j, zero += v == 0;
    }
    bad_bufs += bad != 0;
    snprintf(detail + strlen(detail), sizeof detail - strlen(detail), "%sdispatch %d: %u of %u wrong (%u still 0, o[0] = %u * 65536 + %u)",
             i ? "; " : "", i + 1, bad, len, zero, ((uint32_t*)out[i].map)[0] >> 16, ((uint32_t*)out[i].map)[0] & 65535);
  }
  if (other)
    snprintf(detail + strlen(detail), sizeof detail - strlen(detail), "; other dispatch ran %u times", ((uint32_t*)scratch.map)[0]);
  printf("RESULT %s %s %s\n", t->name, bad_bufs ? "WRONG" : "PASS", detail);
  return bad_bufs ? 1 : 0;
}

int main(int argc, char** argv) {
  if (argc < 2 || !strcmp(argv[1], "list")) {
    for (size_t i = 0; i < NTESTS; ++i) printf("%-38s %s\n", tests[i].name, tests[i].what);
    return 0;
  }
  const test_t* t = NULL;
  for (size_t i = 0; i < NTESTS; ++i)
    if (!strcmp(tests[i].name, argv[1])) t = &tests[i];
  if (!t) { printf("unknown test %s\n", argv[1]); return 2; }
  const char* dir = argc > 2 ? argv[2] : "shaders";
  setvbuf(stdout, NULL, _IOLBF, 0);
  init_vulkan();
  printf("device: %s; driver: %s\ntest: %s: %s\n", devname, drvinfo, t->name, t->what);

  // layout: 4 storage buffers (push descriptors) + 64 bytes of push constants
  VkDescriptorSetLayoutBinding lb[4];
  for (uint32_t i = 0; i < 4; ++i)
    lb[i] = (VkDescriptorSetLayoutBinding){i, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
  VkDescriptorSetLayoutCreateInfo dli = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL,
                                         VK_DESCRIPTOR_SET_LAYOUT_CREATE_PUSH_DESCRIPTOR_BIT_KHR, 4, lb};
  VkDescriptorSetLayout dsl;
  CK(vkCreateDescriptorSetLayout(dev, &dli, NULL, &dsl));
  VkPushConstantRange pcr = {VK_SHADER_STAGE_COMPUTE_BIT, 0, 64};
  VkPipelineLayoutCreateInfo pli = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &dsl, 1, &pcr};
  VkPipelineLayout layout;
  CK(vkCreatePipelineLayout(dev, &pli, NULL, &layout));

  char path[512];
  snprintf(path, sizeof path, "%s/%s.spv", dir, t->name);
  VkPipeline pipe = make_pipeline(path, t, layout);
  if (t->kind == INTERLEAVE) return run_interleave(t, pipe, layout, dir);

  // buffers per kind
  buf_t b[4] = {{0}};
  uint32_t pc[16] = {0};
  uint32_t npc = 0;
  switch (t->kind) {
    case GEMM:
      b[0] = mkbuf((size_t)t->M * t->K * 2), b[1] = mkbuf((size_t)t->K * t->N * 2), b[2] = mkbuf((size_t)t->M * t->N * 2);
      fill_f16(&b[0]), fill_f16(&b[1]);
      break;
    case ADD_F16: b[0] = mkbuf(4096 * 2), b[2] = mkbuf(2048 * 2), fill_f16(&b[0]); break;
    case ADD_I8: b[0] = mkbuf(2048), b[2] = mkbuf(2048), fill_i8(&b[0]); break;
    case MM_F16OUT: case MM_F32OUT:
      b[0] = mkbuf(64 * 16 * 2), b[1] = mkbuf(16 * 32 * 2), b[2] = mkbuf(64 * 32 * 4);
      fill_f16(&b[0]), fill_f16(&b[1]);
      break;
    case SHARED_COPY: b[0] = mkbuf(1024 * 2), b[2] = mkbuf(1024 * 2), fill_f16(&b[0]); break;
    case IDENT_B: {
      b[0] = mkbuf(64 * 16 * 2), b[1] = mkbuf(64 * 16 * 2), b[2] = mkbuf(64 * 64 * 2);
      _Float16* a = b[0].map;
      for (int r = 0; r < 64; ++r)
        for (int k = 0; k < 16; ++k) a[r * 16 + k] = (_Float16)(k == r % 16 ? 1.0f : 0.0f);
      _Float16* w = b[1].map;  // w[n * 16 + k] = B[k][n]: distinct, exactly representable, nonzero
      for (int n = 0; n < 64; ++n)
        for (int k = 0; k < 16; ++k) w[n * 16 + k] = (_Float16)(1 + n + 64 * k) / (_Float16)8;
      break;
    }
    case ACC_COPY: b[0] = mkbuf(4096 * 2), b[2] = mkbuf(4096 * 2), fill_f16(&b[0]); break;
    case Q4ID: {  // A = identity 64 x 64 in 64 x 16 tiles; W: random Q4_0 (q 0..15, d multiple of 1/64 in [0.25, 1))
      b[0] = mkbuf(64 * 64 * 2), b[1] = mkbuf(64 * 64 / 2 + 64 * 2 * 2), b[2] = mkbuf(64 * 64 * 2);
      _Float16* a = b[0].map;
      for (int r = 0; r < 64; ++r) a[(r / 16) * 1024 + r * 16 + r % 16] = (_Float16)1.0f;  // tile r/16 holds k = 16(r/16)..
      uint32_t* qw = b[1].map;
      _Float16* sd = (_Float16*)((uint8_t*)b[1].map + 64 * 64 / 2);
      for (int n = 0; n < 64; ++n)
        for (int kb = 0; kb < 2; ++kb) {
          uint8_t q[32];
          for (int i = 0; i < 32; ++i) q[i] = (uint8_t)((frand() + 1.0f) * 8.0f) & 15, q4ref[n][kb * 32 + i] = q[i];
          _Float16 d = (_Float16)(16 + (int)((frand() + 1.0f) * 24.0f)) / (_Float16)64;
          q4d[n][kb] = (float)d;
          for (int h = 0; h < 2; ++h) {
            uint32_t w2[2] = {0, 0};
            for (int i = 0; i < 8; ++i)
              w2[i / 4] |= (uint32_t)q[16 * h + 2 * i] << (4 * (i % 4)) | (uint32_t)q[16 * h + 2 * i + 1] << (16 + 4 * (i % 4));
            size_t idx = ((size_t)kb * 2 + h) * 64 + n;
            qw[2 * idx] = w2[0], qw[2 * idx + 1] = w2[1];
          }
          sd[kb * 64 + n] = d;
        }
      break;
    }
    case COMPILE: b[0] = mkbuf(1 << 16), b[1] = mkbuf(1 << 16), b[2] = mkbuf(1 << 20); fill_i8(&b[0]); break;
    case BRANCH: b[0] = mkbuf(8192 * 2), b[1] = mkbuf(24 * 1024 * 2), b[2] = mkbuf(8192 * 2), fill_f16(&b[0]), fill_f16(&b[1]); pc[0] = 3, npc = 1; break;
    case FA: {
      uint32_t M = t->M;
      b[0] = mkbuf((size_t)24 * M * 128 * 2), b[1] = mkbuf((size_t)8 * M * 128 * 2), b[2] = mkbuf((size_t)8 * 128 * M * 2);
      b[3] = mkbuf((size_t)M * 3072 * 2);
      for (int i = 0; i < 3; ++i) fill_f16(&b[i]);
      float sc = 1.0f / sqrtf(128.0f);
      pc[0] = M, memcpy(&pc[1], &sc, 4), npc = 2;
      break;
    }
  }

  VkCommandPoolCreateInfo cpi = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO, NULL, VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, 0};
  VkCommandPool pool;
  CK(vkCreateCommandPool(dev, &cpi, NULL, &pool));
  VkCommandBufferAllocateInfo cai = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO, NULL, pool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1};
  VkCommandBuffer cmd;
  CK(vkAllocateCommandBuffers(dev, &cai, &cmd));
  VkQueryPoolCreateInfo qpi = {VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO, NULL, 0, VK_QUERY_TYPE_TIMESTAMP, 2};
  VkQueryPool qp;
  CK(vkCreateQueryPool(dev, &qpi, NULL, &qp));
  VkDescriptorBufferInfo bi[4];
  VkWriteDescriptorSet w[4];
  uint32_t nw = 0;
  for (uint32_t i = 0; i < 4; ++i)
    if (b[i].buf) {
      bi[nw] = (VkDescriptorBufferInfo){b[i].buf, 0, VK_WHOLE_SIZE};
      w[nw] = (VkWriteDescriptorSet){VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, VK_NULL_HANDLE, i, 0, 1,
                                     VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &bi[nw], NULL};
      ++nw;
    }
  // reps back-to-back dispatches between two timestamps; the first run (reps = 1) is the one checked
  double best = 1e30;
  for (int run = 0; run < (t->kind == GEMM ? 6 : 1); ++run) {
    int reps = run == 0 ? 1 : 10;
    VkCommandBufferBeginInfo cbi = {VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    CK(vkResetCommandBuffer(cmd, 0));
    CK(vkBeginCommandBuffer(cmd, &cbi));
    vkCmdResetQueryPool(cmd, qp, 0, 2);
    vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, qp, 0);
    for (int r = 0; r < reps; ++r) {
      vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pipe);
      vkCmdPushDescriptorSetKHR(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, layout, 0, nw, w);
      if (npc) vkCmdPushConstants(cmd, layout, VK_SHADER_STAGE_COMPUTE_BIT, 0, npc * 4, pc);
      vkCmdDispatch(cmd, t->gx, t->gy, 1);
    }
    vkCmdWriteTimestamp(cmd, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, qp, 1);
    CK(vkEndCommandBuffer(cmd));
    VkSubmitInfo sub = {VK_STRUCTURE_TYPE_SUBMIT_INFO, NULL, 0, NULL, NULL, 1, &cmd};
    printf("submitting%s...\n", run == 0 ? "" : " (timing)");
    VkResult r = vkQueueSubmit(queue, 1, &sub, VK_NULL_HANDLE);
    if (!r) r = vkQueueWaitIdle(queue);
    if (r) {
      printf("RESULT %s %s vkQueueSubmit/vkQueueWaitIdle returned %d\n", t->name,
             r == VK_ERROR_DEVICE_LOST ? "DEVICE_LOST" : "VK_ERROR", r);
      return 1;
    }
    uint64_t ts[2];
    CK(vkGetQueryPoolResults(dev, qp, 0, 2, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
    double us = (ts[1] - ts[0]) * ts_ns * 1e-3 / reps;
    if (run > 0 && us < best) best = us;
  }

  // check
  char detail[256] = "";
  int ok = 1;
  switch (t->kind) {
    case GEMM: {  // 1,024 sampled elements against an fp32 reference, relative to the largest |C| sampled
      double maxerr = 0, maxref = 0;
      uint32_t s = 7;
      for (int i = 0; i < 1024; ++i) {
        s = s * 1664525u + 1013904223u;
        uint32_t m = (s >> 8) % t->M;
        s = s * 1664525u + 1013904223u;
        uint32_t nn = (s >> 8) % t->N;
        double ref = 0;
        for (uint32_t k = 0; k < t->K; ++k)
          ref += (double)h2f(b[0].map, t->la == 'N' ? (size_t)m * t->K + k : (size_t)k * t->M + m) *
                 h2f(b[1].map, (size_t)k * t->N + nn);
        double got = h2f(b[2].map, (size_t)m * t->N + nn);
        if (fabs(got - ref) > maxerr || isnan(got)) maxerr = isnan(got) ? 1e30 : fabs(got - ref);
        if (fabs(ref) > maxref) maxref = fabs(ref);
      }
      double rel = maxerr / maxref, tf = 2.0 * t->M * t->N * t->K / (best * 1e-6) / 1e12;
      ok = rel < 2e-2;
      snprintf(detail, sizeof detail, "max error %.2e of max |C|; %.1f us per dispatch (%.2f TFLOP/s)", rel, best, tf);
      break;
    }
    case ADD_F16: {
      int bad = 0;
      for (int i = 0; i < 2048; ++i)
        if (fabsf(h2f(b[2].map, i) - (float)(_Float16)(h2f(b[0].map, i) + h2f(b[0].map, 2048 + i))) > 1e-3f) ++bad;
      ok = !bad;
      snprintf(detail, sizeof detail, "%d of 2048 sums wrong", bad);
      break;
    }
    case ADD_I8: {
      int bad = 0;
      for (int i = 0; i < 2048; ++i)
        if (((int8_t*)b[2].map)[i] != (int8_t)(2 * ((int8_t*)b[0].map)[i])) ++bad;
      ok = !bad;
      snprintf(detail, sizeof detail, "%d of 2048 values wrong", bad);
      break;
    }
    case MM_F16OUT: case MM_F32OUT: {
      double maxerr = 0;
      for (int r = 0; r < 64; ++r)
        for (int n = 0; n < 32; ++n) {
          double ref = 0;
          for (int k = 0; k < 16; ++k) ref += (double)h2f(b[0].map, r * 16 + k) * h2f(b[1].map, k * 32 + n);
          double got = t->kind == MM_F32OUT ? ((float*)b[2].map)[r * 32 + n] : h2f(b[2].map, r * 32 + n);
          if (fabs(got - ref) > maxerr) maxerr = fabs(got - ref);
        }
      ok = maxerr < 1e-2;
      snprintf(detail, sizeof detail, "max abs error %.2e", maxerr);
      break;
    }
    case SHARED_COPY: case ACC_COPY: {
      int n = t->kind == SHARED_COPY ? 1024 : 4096, bad = 0;
      double rel = 0, mx = 0;
      for (int i = 0; i < n; ++i) {
        float x = h2f(b[0].map, i), y = h2f(b[2].map, i);
        if (x != y) ++bad;
        rel += fabs(x - y), mx += fabs(x);
      }
      ok = !bad;
      snprintf(detail, sizeof detail, "%d of %d values differ from the input (sum|y - x| / sum|x| = %.2f)", bad, n, rel / mx);
      break;
    }
    case IDENT_B: {  // c[r][n] = B[r % 16][n] = w[n * 16 + r % 16]
      int bad = 0, badk[16] = {0};
      for (int r = 0; r < 64; ++r)
        for (int n = 0; n < 64; ++n)
          if (h2f(b[2].map, r * 64 + n) != h2f(b[1].map, n * 16 + r % 16)) ++bad, ++badk[r % 16];
      ok = !bad;
      if (getenv("REPRO_DUMP"))
        for (int i = 0; i < 4; ++i)
          printf("c[%d][0] = %g (expected %g), c[0][%d] = %g (expected %g)\n", i, h2f(b[2].map, i * 64),
                 h2f(b[1].map, i % 16), i, h2f(b[2].map, i), h2f(b[1].map, i * 16));
      char ks[96] = "";
      for (int k = 0; k < 16; ++k)
        if (badk[k]) snprintf(ks + strlen(ks), sizeof ks - strlen(ks), " %d", k);
      snprintf(detail, sizeof detail, "%d of 4096 values wrong%s%s", bad, bad ? "; wrong for k =" : "", ks);
      break;
    }
    case Q4ID: {  // C[r][n] = W[n][r] = (q - 8) * d, exact
      int bad = 0, badk[16] = {0};
      for (int r = 0; r < 64; ++r)
        for (int n = 0; n < 64; ++n) {
          float want = ((float)q4ref[n][r] - 8.0f) * q4d[n][r / 32];
          if (h2f(b[2].map, r * 64 + n) != want) ++bad, ++badk[r % 16];
        }
      ok = !bad;
      char ks[96] = "";
      for (int k = 0; k < 16; ++k)
        if (badk[k]) snprintf(ks + strlen(ks), sizeof ks - strlen(ks), " %d", k);
      snprintf(detail, sizeof detail, "%d of 4096 values wrong%s%s", bad, bad ? "; wrong for k % 16 =" : "", ks);
      break;
    }
    case COMPILE:
      snprintf(detail, sizeof detail, "compiled and ran (compile test; output not checked)");
      break;
    case BRANCH: case FA:
      snprintf(detail, sizeof detail, "compiled and ran (compile test; output not checked)");
      break;
  }
  printf("RESULT %s %s %s\n", t->name, ok ? "PASS" : "WRONG", detail);
  return ok ? 0 : 1;
}
