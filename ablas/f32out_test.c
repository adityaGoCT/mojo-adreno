// f32out_test: ablas_pack_a_f32 + ablas_q4_0_pack_ggml / ablas_pack_b + ablas_gemm_f32out vs a CPU reference.
//   f32out_test M N K q4(0|1)        (BOUND_SET_*: needs dummy.spv, glslc bound_set_dummy.comp -o dummy.spv, in the working directory)
// Environment:
//   REPEAT=n              n GEMMs with their own inputs and outputs in one command buffer (like a llama.cpp graph)
//   BOUND_SET_BETWEEN=1   a llama.cpp-style dispatch (own layout, ordinary descriptor set) after each GEMM: driver
//                         bug #13 makes every GEMM but the last write nothing of its own unless USE_SETS=1
//   BETWEEN_SKIP=pscd     leave out of that dispatch: pipeline bind, set bind, push constants, the dispatch
//   BOUND_SET_FIRST=1     one such dispatch before everything
//   USE_SETS=1            ablas_use_descriptor_sets (the workaround)
//   PLAIN=1               the fp16-output GEMM (ablas_hgemm / ablas_hgemm_q4_0) instead of ablas_gemm_f32out
//   TIME=n                time n x (pack A + GEMM) and n x GEMM; ABLAS_KERNEL_EP=<name> forces the kernel
#include "llama3b/vkutil.h"
#include "ablas.h"
#include <math.h>

static float frand2(uint32_t* s) { *s = *s * 1664525u + 1013904223u; return (float)(*s >> 8) / (float)(1u << 23) - 1.0f; }

// A llama.cpp-style dispatch: its own pipeline layout, an ordinary descriptor set bound at set 0, 128 bytes of
// push constants.
static VkPipeline g_pp; static VkPipelineLayout g_lay; static VkDescriptorSet g_set;
static void bound_set_dispatch(vk_t* vp, VkCommandBuffer c) {
  vk_t v = *vp;
  if (!g_pp) {
    static const char* dummy_spv_path = "dummy.spv";
    size_t n; uint32_t* code = read_file(dummy_spv_path, &n);
    VkShaderModuleCreateInfo mi = {VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO, NULL, 0, n, code};
    VkShaderModule mod; CK(vkCreateShaderModule(v.dev, &mi, NULL, &mod));
    VkDescriptorSetLayoutBinding b0 = {0, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, VK_SHADER_STAGE_COMPUTE_BIT, NULL};
    VkDescriptorSetLayoutCreateInfo dl = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO, NULL, 0, 1, &b0};
    VkDescriptorSetLayout dsl; CK(vkCreateDescriptorSetLayout(v.dev, &dl, NULL, &dsl));
    VkPushConstantRange dpcr = {VK_SHADER_STAGE_COMPUTE_BIT, 0, 128};
    VkPipelineLayoutCreateInfo pl = {VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO, NULL, 0, 1, &dsl, 1, &dpcr};
    VkPipelineLayout lay; CK(vkCreatePipelineLayout(v.dev, &pl, NULL, &lay));
    VkComputePipelineCreateInfo ci = {VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
    ci.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO; ci.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
    ci.stage.module = mod; ci.stage.pName = "main"; ci.layout = lay;
    VkPipeline pp; CK(vkCreateComputePipelines(v.dev, VK_NULL_HANDLE, 1, &ci, NULL, &pp));
    VkDescriptorPoolSize ps = {VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 4};
    VkDescriptorPoolCreateInfo dpi = {VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO, NULL, 0, 1, 1, &ps};
    VkDescriptorPool pool; CK(((PFN_vkCreateDescriptorPool)vkGetDeviceProcAddr(v.dev, "vkCreateDescriptorPool"))(v.dev, &dpi, NULL, &pool));
    VkDescriptorSetAllocateInfo dai = {VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO, NULL, pool, 1, &dsl};
    VkDescriptorSet set; CK(((PFN_vkAllocateDescriptorSets)vkGetDeviceProcAddr(v.dev, "vkAllocateDescriptorSets"))(v.dev, &dai, &set));
    vbuf_t junk = vk_buffer(&v, 1 << 20);
    VkDescriptorBufferInfo jb = {junk.buf, 0, VK_WHOLE_SIZE};
    VkWriteDescriptorSet w = {VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET, NULL, set, 0, 0, 1, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, NULL, &jb, NULL};
    ((PFN_vkUpdateDescriptorSets)vkGetDeviceProcAddr(v.dev, "vkUpdateDescriptorSets"))(v.dev, 1, &w, 0, NULL);
    g_pp = pp, g_lay = lay, g_set = set;
  }
  {
    VkPipeline pp = g_pp; VkPipelineLayout lay = g_lay; VkDescriptorSet set = g_set;
    // BETWEEN_SKIP: letters of the steps to leave out (p = pipeline bind, s = set bind, c = push constants, d = dispatch)
    const char* skip = getenv("BETWEEN_SKIP") ? getenv("BETWEEN_SKIP") : "";
    if (!strchr(skip, 'p')) vkCmdBindPipeline(c, VK_PIPELINE_BIND_POINT_COMPUTE, pp);
    if (!strchr(skip, 's')) ((PFN_vkCmdBindDescriptorSets)vkGetDeviceProcAddr(v.dev, "vkCmdBindDescriptorSets"))(c, VK_PIPELINE_BIND_POINT_COMPUTE, lay, 0, 1, &set, 0, NULL);
    uint32_t junkpc[32] = {0};
    if (!strchr(skip, 'c')) vkCmdPushConstants(c, lay, VK_SHADER_STAGE_COMPUTE_BIT, 0, sizeof junkpc, junkpc);
    if (!strchr(skip, 'd')) vkCmdDispatch(c, 16, 1, 1);
    vk_barrier(c);
  }
}

int main(int argc, char** argv) {
  uint32_t M = atoi(argv[1]), N = atoi(argv[2]), K = atoi(argv[3]);
  int q4 = atoi(argv[4]);
  setvbuf(stdout, NULL, _IOLBF, 0);
  vk_t v;
  vk_init(&v, 4);
  ablas_handle h;
  if (ablas_create(&h, v.pd, v.dev, v.gipa, v.inst)) { printf("ablas_create failed\n"); return 1; }
  if (getenv("USE_SETS") && ablas_use_descriptor_sets(h)) { printf("ablas_use_descriptor_sets failed\n"); return 1; }
  uint32_t Mp = (M + 63) / 64 * 64, s = 1;
  vbuf_t X = vk_buffer(&v, (size_t)M * K * 4), A = vk_buffer(&v, (size_t)Mp * K * 2), C = vk_buffer(&v, (size_t)M * N * 4);
  size_t wsz = q4 ? (size_t)N * K / 32 * 18 : (size_t)N * K * 2;
  vbuf_t Wg = vk_buffer(&v, wsz), W = vk_buffer(&v, wsz);
  float* x = X.map;
  for (size_t i = 0; i < (size_t)M * K; ++i) x[i] = frand2(&s);
  float* wref = malloc((size_t)N * K * 4);
  if (q4) {  // ggml block_q4_0
    uint8_t* b = Wg.map;
    for (uint32_t n = 0; n < N; ++n)
      for (uint32_t kb = 0; kb < K / 32; ++kb) {
        uint8_t* blk = b + ((size_t)n * (K / 32) + kb) * 18;
        _Float16 d = (_Float16)(0.01f + 0.02f * (frand2(&s) + 1.0f));
        memcpy(blk, &d, 2);
        for (int j = 0; j < 16; ++j) {
          uint8_t lo = (uint8_t)((frand2(&s) + 1.0f) * 8.0f) & 15, hi = (uint8_t)((frand2(&s) + 1.0f) * 8.0f) & 15;
          blk[2 + j] = lo | hi << 4;
          wref[(size_t)n * K + kb * 32 + j] = ((float)lo - 8.0f) * (float)d;
          wref[(size_t)n * K + kb * 32 + j + 16] = ((float)hi - 8.0f) * (float)d;
        }
      }
  } else {
    _Float16* w = Wg.map;
    for (size_t i = 0; i < (size_t)N * K; ++i) w[i] = (_Float16)(0.05f * frand2(&s)), wref[i] = (float)w[i];
  }
  VkCommandBuffer c = vk_cmd(&v);
  vk_begin(c);
  if (getenv("BOUND_SET_FIRST")) bound_set_dispatch(&v, c);
  ablas_buf bW = {W.buf, 0, wsz}, bWg = {Wg.buf, 0, wsz},
            bA = {A.buf, 0, (VkDeviceSize)Mp * K * 2};
  printf("repack...\n");
  ablas_status st = q4 ? ablas_q4_0_pack_ggml(h, c, N, K, bWg, bW) : ablas_pack_b(h, c, ABLAS_OP_T, K, N, bWg, bW);
  printf("repack status %d\n", st);
  vk_barrier(c);
  // REPEAT=n: n GEMMs with their own input and output buffers in the one command buffer (pack A, barrier, GEMM,
  // barrier each), like llama.cpp's graph; BOUND_SET_BETWEEN=1 adds a llama.cpp-style dispatch after each GEMM.
  int reps = getenv("REPEAT") ? atoi(getenv("REPEAT")) : 1, between = getenv("BOUND_SET_BETWEEN") != NULL;
  int plain = getenv("PLAIN") != NULL;
  vbuf_t Xs[16], Cs[16], Hs[16];
  for (int r = 0; r < reps && plain; ++r) Hs[r] = vk_buffer(&v, (size_t)Mp * N * 2), memset(Hs[r].map, 0, (size_t)Mp * N * 2);
  Xs[0] = X, Cs[0] = C;
  for (int r = 1; r < reps; ++r) {
    Xs[r] = vk_buffer(&v, (size_t)M * K * 4), Cs[r] = vk_buffer(&v, (size_t)M * N * 4);
    float* xr = Xs[r].map;
    for (size_t i = 0; i < (size_t)M * K; ++i) xr[i] = frand2(&s);
  }
  for (int r = 0; r < reps; ++r) {
    ablas_buf bXr = {Xs[r].buf, 0, (VkDeviceSize)M * K * 4}, bCr = {Cs[r].buf, 0, (VkDeviceSize)M * N * 4};
    memset(Cs[r].map, 0, (size_t)M * N * 4);
    st = ablas_pack_a_f32(h, c, M, K, bXr, bA);
    vk_barrier(c);
    if (plain) {  // PLAIN=1: the fp16-output GEMM (no push constants), M rounded up to 64; rows >= M ignored
      ablas_buf bH = {Hs[r].buf, 0, (VkDeviceSize)Mp * N * 2}, ws = {0};
      st |= q4 ? ablas_hgemm_q4_0(h, c, ABLAS_OP_P, Mp, N, K, bA, bW, bH, ws) : ablas_hgemm(h, c, ABLAS_OP_P, ABLAS_OP_P, Mp, N, K, bA, bW, bH, ws);
    } else
      st |= ablas_gemm_f32out(h, c, q4, M, N, K, bA, bW, bCr);
    vk_barrier(c);
    if (between) bound_set_dispatch(&v, c);
    if (st) printf("status %d\n", st);
  }
  printf("%d GEMM(s)%s, kernel %s\n", reps, between ? " with a bound-set dispatch after each" : "", ablas_last_kernel(h));
  CK(vkEndCommandBuffer(c));
  vk_submit_wait(&v, c);
  for (int r = 0; r < reps && plain; ++r) {
    _Float16* hm = Hs[r].map; float* cm = Cs[r].map;
    for (size_t i = 0; i < (size_t)M * N; ++i) cm[i] = (float)hm[i];
  }
  int fails = 0;
  for (int r = 0; r < reps; ++r) {
    double maxerr = 0, maxref = 0, maxc = 0;
    float* cm = Cs[r].map; float* xr = Xs[r].map;
    for (size_t i = 0; i < (size_t)M * N; ++i) maxc = fmax(maxc, fabs(cm[i]));
    for (int i = 0; i < 256; ++i) {
      uint32_t m = (uint32_t)((frand2(&s) + 1.0f) * 0.5f * M) % M, n = (uint32_t)((frand2(&s) + 1.0f) * 0.5f * N) % N;
      double ref = 0;
      for (uint32_t k = 0; k < K; ++k) ref += (double)(float)(_Float16)xr[(size_t)m * K + k] * wref[(size_t)n * K + k];
      maxerr = fmax(maxerr, fabs(cm[(size_t)m * N + n] - ref)), maxref = fmax(maxref, fabs(ref));
    }
    int ok = maxerr / maxref < 2e-2;
    fails += !ok;
    printf("  GEMM %d: max error %.2e of max |ref| %.3f, max |C| %.3f -> %s\n", r, maxerr / maxref, maxref, maxc, ok ? "PASS" : "FAIL");
  }
  printf("RESULT M=%u N=%u K=%u q4=%d reps=%d: %s\n", M, N, K, q4, reps, fails ? "FAIL" : "PASS");
  if (getenv("TIME")) {  // TIME=n: wall time of n x (pack A, barrier, GEMM, barrier), and of n x (GEMM, barrier)
    int n = atoi(getenv("TIME"));
    ablas_buf bX0 = {Xs[0].buf, 0, (VkDeviceSize)M * K * 4}, bC0 = {Cs[0].buf, 0, (VkDeviceSize)M * N * 4};
    for (int pass = 0; pass < 3; ++pass) {
      double best[2] = {1e30, 1e30};
      for (int it = 0; it < 3; ++it)
        for (int g = 0; g < 2; ++g) {
          VkCommandBuffer tc = vk_cmd(&v);
          vk_begin(tc);
          for (int r = 0; r < n; ++r) {
            if (g == 0) { ablas_pack_a_f32(h, tc, M, K, bX0, bA); vk_barrier(tc); }
            ablas_gemm_f32out(h, tc, q4, M, N, K, bA, bW, bC0);
            vk_barrier(tc);
          }
          CK(vkEndCommandBuffer(tc));
          double t0 = now_ms();
          vk_submit_wait(&v, tc);
          double t = (now_ms() - t0) / n;
          if (t < best[g]) best[g] = t;
          if (getenv("USE_SETS")) ablas_reset_descriptor_sets(h);
        }
      if (pass == 2)
        printf("TIME M=%u N=%u K=%u q4=%d %s: pack+gemm %.1f us, gemm %.1f us (%.2f TFLOP/s), pack %.1f us\n", M, N, K, q4, ablas_last_kernel(h),
               best[0] * 1e3, best[1] * 1e3, 2.0 * M * N * K / (best[1] * 1e-3) / 1e12, (best[0] - best[1]) * 1e3);
    }
  }
  return 0;
}
