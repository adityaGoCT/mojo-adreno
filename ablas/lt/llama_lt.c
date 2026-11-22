// Llama 3.2 3B on the Adreno 850 through AdrenoBLASLt (ablasLt.h): the model as a list of library calls.
//   llama_lt -w <weights prefix> -t tokens.bin [-n N] [-g G] [-r R] [-o dir]
// Weights: ../llama3b/export.py's llama3b_{f16,q4}.bin + .idx (AdrenoBLAS's B format). tokens.bin: int32 ids.
// Prefills the first N tokens (any N: rows are padded to 64; causal attention keeps the padding out of real rows),
// R timed runs after a warm-up, then predicts G tokens greedily by prefilling again with each one appended (this
// runner has no KV cache yet: see README.md). -o: logits.bin and hidden.bin for ../llama3b/ref.py cmp.
#include <math.h>
#include <stdint.h>

#include "../llama3b/vkutil.h"  // first: VK_NO_PROTOTYPES
#include "ablasLt.h"

enum { D = 3072, NH = 24, NKV = 8, HD = 128, FF = 8192, V = 128256, NL = 28, QKV = (NH + 2 * NKV) * HD };

typedef struct { char name[64]; size_t off, bytes; vbuf_t buf; } tensor_t;
static tensor_t tens[256];
static int ntens;
static ablasLtType wtype;
static vk_t v;
static ablasLtHandle lt;

static tensor_t* T(const char* fmt, int l) {
  char name[64];
  snprintf(name, sizeof name, fmt, l);
  for (int i = 0; i < ntens; ++i)
    if (!strcmp(tens[i].name, name)) return &tens[i];
  fprintf(stderr, "missing tensor %s\n", name);
  exit(1);
}

// Each tensor into its own host-visible buffer; gate|up laid out for the SwiGLU epilogue as it is loaded.
static void load_weights(const char* prefix) {
  char path[512];
  snprintf(path, sizeof path, "%s.idx", prefix);
  FILE* f = fopen(path, "r");
  if (!f) { fprintf(stderr, "cannot open %s\n", path); exit(1); }
  while (ntens < 256 && fscanf(f, "%63s %zu %zu", tens[ntens].name, &tens[ntens].off, &tens[ntens].bytes) == 3) ++ntens;
  fclose(f);
  snprintf(path, sizeof path, "%s.bin", prefix);
  f = fopen(path, "rb");
  if (!f) { fprintf(stderr, "cannot open %s\n", path); exit(1); }
  for (int i = 0; i < ntens; ++i) {
    tensor_t* t = &tens[i];
    t->buf = vk_buffer(&v, t->bytes);
    int gu = strstr(t->name, ".wgu") != NULL;
    void* dst = gu ? malloc(t->bytes) : t->buf.map;
    fseeko(f, (off_t)t->off, SEEK_SET);
    if (fread(dst, 1, t->bytes, f) != t->bytes) { fprintf(stderr, "short read %s\n", t->name); exit(1); }
    if (gu) {
      ablasLtWeightPack(wtype, ABLASLT_WEIGHT_GATE_UP, ABLASLT_SRC_PACKED, dst, 2 * FF, D, t->buf.map);
      free(dst);
    }
  }
  fclose(f);
}

#define CHECK(call) do { ablas_status s_ = (call); if (s_) { fprintf(stderr, "%s: status %d\n", #call, s_); exit(1); } } while (0)
static ablas_buf B(vbuf_t* b) { return (ablas_buf){b->buf, 0, 0}; }

// Activations, sized for the longest prefill
static vbuf_t x, h, q, k, vt, attn, act, ssp, cs, logits, ws;

// One prefill of M rows (M multiple of 64) in one command buffer: 28 layers, the final norm, the LM head on the last
// 64 rows (fp32 logits [64, V]).
static void forward(VkCommandBuffer c, uint32_t M) {
  const ablasLtLayout hl = {ABLASLT_F16, ABLASLT_ORDER_TILED, M, D}, al = {ABLASLT_F16, ABLASLT_ORDER_TILED, M, FF},
                      xl = {ABLASLT_F32, ABLASLT_ORDER_ROW, M, D};
  const ablasLtLayout wqkv = {wtype, ABLASLT_ORDER_WEIGHT, QKV, D}, wo = {wtype, ABLASLT_ORDER_WEIGHT, D, D},
                      wgu = {wtype, ABLASLT_ORDER_WEIGHT, 2 * FF, D, ABLASLT_WEIGHT_GATE_UP},
                      wd = {wtype, ABLASLT_ORDER_WEIGHT, D, FF};
  const ablasLtMatmulDesc rope = {ABLASLT_EPILOGUE_ROPE_QKV, .n_heads = NH, .n_kv_heads = NKV, .rope = B(&cs),
                                  .q = B(&q), .k = B(&k), .vt = B(&vt)};
  const ablasLtMatmulDesc residual = {ABLASLT_EPILOGUE_RESIDUAL, .aux = B(&ssp)}, swiglu = {ABLASLT_EPILOGUE_SWIGLU};
  const ablas_buf none = {0};
  for (int l = 0; l < NL; ++l) {
    // attention block; the first layer's norm computes its own sums of squares, later ones take the residual
    // GEMM's
    CHECK(ablasLtRmsNorm(lt, c, M, D, B(&x), l ? B(&ssp) : none, B(&T("L%d.attn_norm", l)->buf), 1e-5f, B(&h), B(&ws)));
    CHECK(ablasLtMatmul(lt, c, &rope, B(&h), &hl, B(&T("L%d.wqkv", l)->buf), &wqkv, none, NULL, B(&ws)));
    CHECK(ablasLtAttention(lt, c, M, NH, NKV, 1.0f / sqrtf((float)HD), B(&q), B(&k), B(&vt), B(&attn)));
    CHECK(ablasLtMatmul(lt, c, &residual, B(&attn), &hl, B(&T("L%d.wo", l)->buf), &wo, B(&x), &xl, none));
    // MLP block
    CHECK(ablasLtRmsNorm(lt, c, M, D, B(&x), B(&ssp), B(&T("L%d.ffn_norm", l)->buf), 1e-5f, B(&h), none));
    CHECK(ablasLtMatmul(lt, c, &swiglu, B(&h), &hl, B(&T("L%d.wgu", l)->buf), &wgu, B(&act), &al, none));
    CHECK(ablasLtMatmul(lt, c, &residual, B(&act), &al, B(&T("L%d.wd", l)->buf), &wd, B(&x), &xl, none));
  }
  CHECK(ablasLtRmsNorm(lt, c, M, D, B(&x), B(&ssp), B(&T("out_norm", 0)->buf), 1e-5f, B(&h), none));
  // LM head (the tied embedding) on the last 64 rows: their row of tiles is contiguous at the end of h
  const ablasLtLayout last = {ABLASLT_F16, ABLASLT_ORDER_TILED, 64, D}, wtok = {wtype, ABLASLT_ORDER_WEIGHT, V, D},
                      ll = {ABLASLT_F32, ABLASLT_ORDER_ROW, 64, V};
  const ablasLtMatmulDesc plain = {ABLASLT_EPILOGUE_DEFAULT};
  ablas_buf hlast = {h.buf, (VkDeviceSize)(M - 64) * D * 2, 0};
  CHECK(ablasLtMatmul(lt, c, &plain, hlast, &last, B(&T("tok", 0)->buf), &wtok, B(&logits), &ll, none));
}

int main(int argc, char** argv) {
  setvbuf(stdout, NULL, _IOLBF, 0);
  const char *wpath = "w/llama3b_q4", *tpath = "tokens.bin", *odir = NULL;
  uint32_t n = 512, gen = 0;
  int reps = 3;
  for (int i = 1; i < argc; ++i) {
    if (!strcmp(argv[i], "-w")) wpath = argv[++i];
    else if (!strcmp(argv[i], "-t")) tpath = argv[++i];
    else if (!strcmp(argv[i], "-n")) n = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-g")) gen = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-r")) reps = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-o")) odir = argv[++i];
  }
  wtype = strstr(wpath, "q4") ? ABLASLT_Q4_0 : ABLASLT_F16;
  size_t tb;
  int32_t* file_tokens = read_file(tpath, &tb);
  if (!file_tokens || tb / 4 < n || n < 1) { fprintf(stderr, "%s: need at least %u tokens\n", tpath, n); return 1; }
  uint32_t Mmax = (n + gen + 63) / 64 * 64;
  int32_t* tokens = calloc(Mmax, 4);
  memcpy(tokens, file_tokens, (size_t)n * 4);

  vk_init(&v, 4);
  ablas_handle ab;
  if (ablas_create(&ab, v.pd, v.dev, v.gipa, v.inst) || ablasLtCreate(&lt, ab, v.dev, v.gipa, v.inst, 0)) {
    fprintf(stderr, "AdrenoBLAS: no device support\n");
    return 1;
  }
  double t0 = now_ms();
  load_weights(wpath);
  printf("device %s, %s weights loaded in %.1f s, prompt %u tokens\n", v.name, wtype == ABLASLT_Q4_0 ? "Q4_0" : "fp16",
         (now_ms() - t0) / 1e3, n);

  x = vk_buffer(&v, (size_t)Mmax * D * 4), h = vk_buffer(&v, (size_t)Mmax * D * 2);
  q = vk_buffer(&v, (size_t)NH * Mmax * HD * 2), k = vk_buffer(&v, (size_t)NKV * Mmax * HD * 2);
  vt = vk_buffer(&v, (size_t)NKV * HD * Mmax * 2), attn = vk_buffer(&v, (size_t)Mmax * D * 2);
  act = vk_buffer(&v, (size_t)Mmax * FF * 2), ssp = vk_buffer(&v, (size_t)Mmax * (D / 64) * 4);
  cs = vk_buffer(&v, (size_t)Mmax * HD * 4), logits = vk_buffer(&v, (size_t)64 * V * 4);
  const ablasLtLayout hl = {ABLASLT_F16, ABLASLT_ORDER_TILED, Mmax, D},
                      wqkv = {wtype, ABLASLT_ORDER_WEIGHT, QKV, D};
  const ablasLtMatmulDesc rope = {ABLASLT_EPILOGUE_ROPE_QKV, .n_heads = NH, .n_kv_heads = NKV};
  size_t wsz = ablasLtMatmulWorkspaceSize(&rope, &hl, &wqkv, NULL), wn = ablasLtRmsNormWorkspaceSize(Mmax);
  ws = vk_buffer(&v, wsz > wn ? wsz : wn);
  const float* inv_freq = T("inv_freq", 0)->buf.map;  // RoPE table: cos | sin of position * inv_freq, as transformers
  for (uint32_t p = 0; p < Mmax; ++p)
    for (int i = 0; i < 64; ++i) {
      float a = (float)p * inv_freq[i];
      ((float*)cs.map)[p * 128 + i] = cosf(a), ((float*)cs.map)[p * 128 + 64 + i] = sinf(a);
    }

  VkCommandBuffer c = vk_cmd(&v);
  uint32_t len = n;
  for (uint32_t step = 0; step <= gen; ++step) {
    uint32_t M = (len + 63) / 64 * 64;
    double best = 1e30;
    for (int rep = 0; rep < (step ? 1 : reps + 1); ++rep) {  // the first prompt: a warm-up, then `reps` timed runs
      for (uint32_t r = 0; r < M; ++r)  // embeddings (CPU); padding rows repeat the last token
        ablasLtWeightRow(wtype, T("tok", 0)->buf.map, V, D, (uint32_t)tokens[r < len ? r : len - 1],
                         (float*)x.map + (size_t)r * D);
      vk_begin(c);
      vkCmdResetQueryPool(c, v.qp, 0, 2);
      vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, v.qp, 0);
      forward(c, M);
      vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, 1);
      CK(vkEndCommandBuffer(c));
      vk_submit_wait(&v, c);
      uint64_t ts[2];
      CK(vkGetQueryPoolResults(v.dev, v.qp, 0, 2, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
      double ms = (ts[1] - ts[0]) * v.ts_ns * 1e-6;
      if (!step && rep) printf("prefill %u tokens (%u rows): %.2f ms, %.1f tok/s\n", len, M, ms, len / ms * 1e3);
      if (rep || step) best = ms < best ? ms : best;
    }
    // the prediction: the last real row of the LM head's 64
    const float* lg = (const float*)logits.map + (size_t)(len - 1 - (M - 64)) * V;
    uint32_t next = 0;
    for (uint32_t i = 1; i < V; ++i)
      if (lg[i] > lg[next]) next = i;
    if (!step) {
      printf("RESULT %s prefill %u tokens: best %.2f ms (%.1f tok/s); next token %u\n",
             wtype == ABLASLT_Q4_0 ? "q4_0" : "fp16", len, best, len / best * 1e3, next);
      if (odir) {  // logits of the last token, the final norm's output for the prompt (fp32), for ref.py cmp
        char p[512];
        snprintf(p, sizeof p, "%s/logits.bin", odir);
        FILE* f = fopen(p, "wb");
        fwrite(lg, 4, V, f);
        fclose(f);
        float* hid = malloc((size_t)len * D * 4);
        for (uint32_t r = 0; r < len; ++r) ablasLtWeightRow(ABLASLT_F16, h.map, M, D, r, hid + (size_t)r * D);
        snprintf(p, sizeof p, "%s/hidden.bin", odir);
        f = fopen(p, "wb");
        fwrite(hid, 4, (size_t)len * D, f);
        fclose(f);
        free(hid);
        printf("wrote %s/logits.bin, hidden.bin\n", odir);
      }
    } else {
      printf("token %u: %u (%.1f ms)\n", step, next, best);
    }
    if (step < gen) tokens[len++] = (int32_t)next;
  }
  return 0;
}
