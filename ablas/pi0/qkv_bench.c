// qkv_bench: Lt ROPE_QKV's general form at SigLIP's and Gemma's shapes, timed, and its GEMM alone (packed tiles
// out): the difference is qksplit + vsplit.
//   qkv_bench [siglip|gemma]
#include <math.h>
#include <stdint.h>
#include "../llama3b/vkutil.h"
#include "../lt/ablasLt.h"
static vk_t v;
static ablasLtHandle lt;
static ablas_handle ab;
static ablas_buf B(vbuf_t* b) { return (ablas_buf){b->buf, 0, 0}; }
int main(int argc, char** argv) {
  int gemma = argc > 1 && !strcmp(argv[1], "gemma");
  uint32_t M = gemma ? 832 : 768, K = gemma ? 2048 : 1152, nh = gemma ? 8 : 16, nkv = gemma ? 1 : 16,
           hd = gemma ? 256 : 128, hdv = gemma ? 256 : 72, N = (nh + 2 * nkv) * hdv, KR = gemma ? 896 : M;
  vk_init(&v, 8);
  ablas_create(&ab, v.pd, v.dev, v.gipa, v.inst);
  ablasLtCreate(&lt, ab, v.dev, v.gipa, v.inst, 0);
  vbuf_t A = vk_buffer(&v, (size_t)M * K * 2), W = vk_buffer(&v, (size_t)N * K * 2), bias = vk_buffer(&v, N * 4),
         cs = vk_buffer(&v, (size_t)M * hd * 4), q = vk_buffer(&v, (size_t)nh * M * hd * 2),
         k = vk_buffer(&v, (size_t)nkv * KR * hd * 2), vt = vk_buffer(&v, (size_t)nkv * KR * hd * 2),
         ws = vk_buffer(&v, 16u << 20), C = vk_buffer(&v, (size_t)M * N * 2);
  memset(A.map, 0, A.size), memset(W.map, 0, W.size), memset(bias.map, 0, bias.size), memset(cs.map, 0, cs.size);
  ablasLtLayout al = {ABLASLT_F16, ABLASLT_ORDER_TILED, M, K}, wl = {ABLASLT_F16, ABLASLT_ORDER_WEIGHT, N, K},
                cl = {ABLASLT_F16, ABLASLT_ORDER_TILED, M, N};
  ablasLtMatmulDesc d = {ABLASLT_EPILOGUE_ROPE_QKV, .n_heads = nh, .n_kv_heads = nkv, .q = B(&q), .k = B(&k), .vt = B(&vt),
                         .head_dim = hd, .head_dim_valid = hdv, .kv_rows = KR};
  if (gemma) d.rope = B(&cs); else d.bias = B(&bias);
  ablasLtMatmulDesc plain = {ABLASLT_EPILOGUE_DEFAULT};
  VkCommandBuffer c = vk_cmd(&v);
  for (int mode = 0; mode < 2; ++mode) {
    double best = 1e30;
    for (int r = 0; r < 11; ++r) {
      vk_begin(c);
      vkCmdResetQueryPool(c, v.qp, 0, 2);
      vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, v.qp, 0);
      ablas_status st = mode ? ablasLtMatmul(lt, c, &plain, B(&A), &al, B(&W), &wl, B(&C), &cl, B(&ws))
                             : ablasLtMatmul(lt, c, &d, B(&A), &al, B(&W), &wl, (ablas_buf){0}, NULL, B(&ws));
      if (st) { printf("status %d\n", st); return 1; }
      vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, 1);
      CK(vkEndCommandBuffer(c));
      vk_submit_wait(&v, c);
      uint64_t ts[2];
      CK(vkGetQueryPoolResults(v.dev, v.qp, 0, 2, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
      if (r) best = fmin(best, (ts[1] - ts[0]) * v.ts_ns * 1e-6);
    }
    printf("%s %s: %.3f ms (%s)\n", gemma ? "gemma" : "siglip", mode ? "GEMM only, packed out" : "ROPE_QKV general",
           best, ablasLtLastKernel(lt));
  }
  return 0;
}
