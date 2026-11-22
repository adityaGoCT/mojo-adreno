// shape_bench: one AdrenoBLASLt matmul shape, timed (GPU timestamps, best of R after a warm-up).
//   shape_bench M N K epilogue [R]     epilogue: res | geglu | tiles | f32 ; ABLAS_KERNEL_EP picks a kernel by name
//   shape_bench split M0 M1 N K [R]    the residual matmul as two row ranges (M0, then M1 rows) without a barrier
#include <math.h>
#include <stdint.h>
#include "../llama3b/vkutil.h"
#include "../lt/ablasLt.h"
static vk_t v;
static ablasLtHandle lt;
static ablas_buf B(vbuf_t* b) { return (ablas_buf){b->buf, 0, 0}; }
int main(int argc, char** argv) {
  int split = argc > 1 && !strcmp(argv[1], "split");
  uint32_t M0 = 0, M1 = 0, M, N, K;
  const char* ep = "res";
  int R = 10;
  if (split) M0 = atoi(argv[2]), M1 = atoi(argv[3]), M = M0 + M1, N = atoi(argv[4]), K = atoi(argv[5]), R = argc > 6 ? atoi(argv[6]) : 10;
  else M = atoi(argv[1]), N = atoi(argv[2]), K = atoi(argv[3]), ep = argv[4], R = argc > 5 ? atoi(argv[5]) : 10;
  vk_init(&v, 4);
  ablas_handle ab;
  ablas_create(&ab, v.pd, v.dev, v.gipa, v.inst);
  ablasLtCreate(&lt, ab, v.dev, v.gipa, v.inst, ABLASLT_NO_AUTO_BARRIER);
  int gu = !strcmp(ep, "geglu");
  vbuf_t A = vk_buffer(&v, (size_t)M * K * 2), W = vk_buffer(&v, (size_t)N * K * 2), X = vk_buffer(&v, (size_t)M * N * 4),
         S = vk_buffer(&v, (size_t)M * (N / 64) * 4);
  _Float16* a = A.map; for (size_t i = 0; i < (size_t)M * K; ++i) a[i] = (_Float16)((i * 37 % 101) / 101.0f - 0.5f);
  _Float16* w = W.map; for (size_t i = 0; i < (size_t)N * K; ++i) w[i] = (_Float16)((i * 53 % 97) / 970.0f - 0.05f);
  memset(X.map, 0, (size_t)M * N * 4);
  ablasLtMatmulDesc d = {strcmp(ep, "res") == 0 ? ABLASLT_EPILOGUE_RESIDUAL : gu ? ABLASLT_EPILOGUE_GEGLU : ABLASLT_EPILOGUE_DEFAULT,
                         .aux = B(&S)};
  VkCommandBuffer c = vk_cmd(&v);
  double best = 1e30;
  const char* kern = "";
  for (int r = 0; r <= R; ++r) {
    vk_begin(c);
    vkCmdResetQueryPool(c, v.qp, 0, 2);
    vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, v.qp, 0);
    ablas_status st;
    if (split) {
      for (int part = 0; part < 2; ++part) {
        uint32_t m = part ? M1 : M0, r0 = part ? M0 : 0;
        ablasLtLayout al = {ABLASLT_F16, ABLASLT_ORDER_TILED, m, K}, wl = {ABLASLT_F16, ABLASLT_ORDER_WEIGHT, N, K},
                      xl = {ABLASLT_F32, ABLASLT_ORDER_ROW, m, N};
        ablasLtMatmulDesc dd = {ABLASLT_EPILOGUE_RESIDUAL, .aux = {S.buf, (VkDeviceSize)r0 * (N / 64) * 4, 0}};
        st = ablasLtMatmul(lt, c, &dd, (ablas_buf){A.buf, (VkDeviceSize)r0 * K * 2, 0}, &al, B(&W), &wl,
                           (ablas_buf){X.buf, (VkDeviceSize)r0 * N * 4, 0}, &xl, (ablas_buf){0});
        if (st) { printf("status %d\n", st); return 1; }
      }
      kern = "split";
    } else {
      ablasLtLayout al = {ABLASLT_F16, ABLASLT_ORDER_TILED, M, K},
                    wl = {ABLASLT_F16, ABLASLT_ORDER_WEIGHT, N, K, gu ? ABLASLT_WEIGHT_GATE_UP : ABLASLT_WEIGHT_PLAIN},
                    xl = {ABLASLT_F32, ABLASLT_ORDER_ROW, M, N}, tl = {ABLASLT_F16, ABLASLT_ORDER_TILED, M, gu ? N / 2 : N};
      st = ablasLtMatmul(lt, c, &d, B(&A), &al, B(&W), &wl, B(&X), !strcmp(ep, "res") || !strcmp(ep, "f32") ? &xl : &tl, (ablas_buf){0});
      if (st) { printf("status %d\n", st); return 1; }
      kern = ablasLtLastKernel(lt);
    }
    vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, 1);
    CK(vkEndCommandBuffer(c));
    vk_submit_wait(&v, c);
    uint64_t ts[2];
    CK(vkGetQueryPoolResults(v.dev, v.qp, 0, 2, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
    double ms = (ts[1] - ts[0]) * v.ts_ns * 1e-6;
    if (r) best = fmin(best, ms);
  }
  printf("%s M %u N %u K %u (%s): %.3f ms, %.2f TFLOP/s\n", ep, M, N, K, kern, best, 2.0 * M * N * K / best / 1e9);
  return 0;
}
