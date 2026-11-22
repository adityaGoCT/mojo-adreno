// π0 on the Adreno 850's GPU through AdrenoBLASLt (../lt/ablasLt.h): one action chunk as a list of library calls.
//   pi0_lt [-r R] [-p] [-q]
// The architecture is lerobot/pi0_base's (../../pi0/README.md):
//   vision   SigLIP So400m: 27 layers of 1152 (16 heads of 72, MLP 4304), 3 images x 256 patches, then the
//            projector to 2048 for the 768 image rows of the prefix
//   prefix   PaliGemma's Gemma 2B: 18 layers of 2048 (8 query heads and 1 KV head of 256, GeGLU 16384) over the
//            816-row prefix (768 image rows + 48 language rows, 783 valid), bidirectional; it keeps each layer's
//            K and V (the last layer computes only those)
//   steps    10 Euler steps of the action expert (Gemma 300M: 18 layers of 1024, the same heads, GeGLU 4096) over
//            51 rows (the state and 50 actions), which see the prefix's K/V and, block-causally, each other
// No checkpoint is read: the weights are random (fp16, or Q4_0 with -q), so this is the architecture and its
// timing, not the model's actions. Shapes that are not multiples of 64 are padded: SigLIP's heads of 72 to 128
// inside attention, its MLP to 4352, the patch vectors (588) to 640, the 816 prefix rows to 832, the 51 expert
// rows to 64, the 32 action dims to 64. -r: timed chunks after a warm-up. -p: a GPU timestamp after every
// operation, summed by kind per stage.
#include <math.h>
#include <pthread.h>
#include <stdint.h>

#include "../llama3b/vkutil.h"  // first: VK_NO_PROTOTYPES
#include "../lt/ablasLt.h"
#include "build/glue_spv.h"

enum {
  NIMG = 3, T = 256, VM = NIMG * T, VD = 1152, VL = 27, VH = 16, VHDV = 72, VHD = 128, VFF = 4352, PATCH = 640,
  VQKV = 3 * VH * VHDV,
  D = 2048, L = 18, NH = 8, HD = 256, FF = 16384, QKV = (NH + 2) * HD, VALID = 783, PM = 832, LANG = 64,
  ED = 1024, EFF = 4096, S = 51, SM = 64, KR = PM + SM, STEPS = 10, AD = 64,
  NTS = 4096,
};

#define CHECK(call) do { ablas_status s_ = (call); if (s_) { fprintf(stderr, "%s:%d %s: status %d\n", __FILE__, __LINE__, #call, s_); exit(1); } } while (0)

static vk_t v;
static ablasLtHandle lt;
static ablasLtType wt = ABLASLT_F16;
static VkPipeline glue_p;
static ablas_buf B(vbuf_t* b) { return (ablas_buf){b->buf, 0, 0}; }
static const ablas_buf none = {0};

// ---- random contents, filled by 8 threads ----

typedef struct { void* p; size_t n; int kind; float lo, hi; uint32_t seed; } fill_t;
enum { F16 = 0, F32 = 1, BYTES = 2 };
static void* fill_job(void* arg) {
  fill_t* j = arg;
  uint32_t s = j->seed * 2654435761u + 1;
  for (size_t i = 0; i < j->n; ++i) {
    s ^= s << 13, s ^= s >> 17, s ^= s << 5;
    float u = j->lo + (j->hi - j->lo) * (float)(s >> 8) * (1.0f / 16777216.0f);
    if (j->kind == F16) ((_Float16*)j->p)[i] = (_Float16)u;
    else if (j->kind == F32) ((float*)j->p)[i] = u;
    else ((uint32_t*)j->p)[i] = s;
  }
  return NULL;
}
static uint32_t seed_counter = 1;
static void fill(void* p, size_t n, int kind, float lo, float hi) {
  enum { NT = 8 };
  pthread_t th[NT];
  fill_t jobs[NT];
  size_t es = kind == F16 ? 2 : 4, per = (n + NT - 1) / NT;
  for (int t = 0; t < NT; ++t) {
    size_t a = t * per < n ? t * per : n, b = (t + 1) * per < n ? (t + 1) * per : n;
    jobs[t] = (fill_t){(char*)p + a * es, b - a, kind, lo, hi, seed_counter++};
    pthread_create(&th[t], NULL, fill_job, &jobs[t]);
  }
  for (int t = 0; t < NT; ++t) pthread_join(th[t], NULL);
}

static size_t weight_bytes;
// A weight [N, K] in AdrenoBLAS's B format, random: fp16 uniform with standard deviation 1/sqrt(K), or Q4_0 random
// quants with scales giving about the same spread. The layout does not matter for random values (gate|up included).
static vbuf_t wmat(uint32_t N, uint32_t K) {
  size_t bytes = ablasLtWeightSize(wt, N, K);
  vbuf_t b = vk_buffer(&v, bytes);
  float a = sqrtf(3.0f / K);
  if (wt == ABLASLT_F16) {
    fill(b.map, (size_t)N * K, F16, -a, a);
  } else {
    fill(b.map, (size_t)N * K / 8, BYTES, 0, 0);
    fill((char*)b.map + (size_t)N * K / 2, (size_t)N * K / 32, F16, 0.5f * a / 4.6f, 1.5f * a / 4.6f);
  }
  weight_bytes += bytes;
  return b;
}
static vbuf_t fvec(size_t n, float lo, float hi) {
  vbuf_t b = vk_buffer(&v, n * 4);
  fill(b.map, n, F32, lo, hi);
  weight_bytes += n * 4;
  return b;
}
static vbuf_t zeros(size_t bytes) {
  vbuf_t b = vk_buffer(&v, bytes);
  memset(b.map, 0, bytes);
  return b;
}

// ---- weights ----

typedef struct { vbuf_t ln1w, ln1b, qkv, qkvb, o, ob, ln2w, ln2b, fc1, fc1b, fc2, fc2b; } vit_layer;
typedef struct { vbuf_t n1, qkv, o, n2, gu, d; } gemma_layer;
static vit_layer vl[VL];
static gemma_layer gl_[L], el[L];
static vbuf_t patch_w, patch_b, pos, post_w, post_b, proj, proj_b;
static vbuf_t e_win, e_wtime, e_b1, e_w2, e_b2, e_out, e_bout, e_fnorm, state_emb;

static void make_weights(void) {
  patch_w = wmat(VD, PATCH), patch_b = fvec(VD, -0.1f, 0.1f), pos = fvec((size_t)T * VD, -0.5f, 0.5f);
  for (int l = 0; l < VL; ++l) {
    vit_layer* w = &vl[l];
    w->ln1w = fvec(VD, 0.5f, 1.5f), w->ln1b = fvec(VD, -0.1f, 0.1f);
    w->qkv = wmat(VQKV, VD), w->qkvb = fvec(VQKV, -0.1f, 0.1f);
    w->o = wmat(VD, VD), w->ob = fvec(VD, -0.1f, 0.1f);
    w->ln2w = fvec(VD, 0.5f, 1.5f), w->ln2b = fvec(VD, -0.1f, 0.1f);
    w->fc1 = wmat(VFF, VD), w->fc1b = fvec(VFF, -0.1f, 0.1f);
    w->fc2 = wmat(VD, VFF), w->fc2b = fvec(VD, -0.1f, 0.1f);
  }
  post_w = fvec(VD, 0.5f, 1.5f), post_b = fvec(VD, -0.1f, 0.1f);
  proj = wmat(D, VD), proj_b = fvec(D, -0.1f, 0.1f);
  for (int l = 0; l < L; ++l) {  // Gemma's RMSNorm weight is 1 + w: random around 1
    gemma_layer* w = &gl_[l];
    w->n1 = fvec(D, 0.5f, 1.5f), w->qkv = wmat(QKV, D);
    if (l == L - 1) continue;  // the last prefix layer only gives K and V
    w->o = wmat(D, NH * HD), w->n2 = fvec(D, 0.5f, 1.5f), w->gu = wmat(2 * FF, D), w->d = wmat(D, FF);
  }
  for (int l = 0; l < L; ++l) {
    gemma_layer* w = &el[l];
    w->n1 = fvec(ED, 0.5f, 1.5f), w->qkv = wmat(QKV, ED), w->o = wmat(ED, NH * HD);
    w->n2 = fvec(ED, 0.5f, 1.5f), w->gu = wmat(2 * EFF, ED), w->d = wmat(ED, EFF);
  }
  // The action-time MLP: mlp_in([action_in(x_t), time_emb(t)]) splits into an action part, folded with action_in
  // ([1024, 32] -> one [1024, 32] matrix, padded to 64), and a time part, computed for all 10 steps at once.
  e_win = wmat(ED, AD), e_wtime = wmat(ED, ED), e_b1 = fvec(ED, -0.1f, 0.1f);
  e_w2 = wmat(ED, ED), e_b2 = fvec(ED, -0.1f, 0.1f);
  e_fnorm = fvec(ED, 0.5f, 1.5f), e_out = wmat(AD, ED), e_bout = fvec(AD, -0.1f, 0.1f);
  state_emb = fvec(ED, -1.0f, 1.0f);  // state_proj(state): 32 x 1024 multiply-adds, on the CPU once per chunk
}

// ---- activations ----

static vbuf_t patches, xv, hv, qv, kv, vtv, attnv, actv;                       // vision
static vbuf_t x, lang, h, q, kc[L], vc[L], attn, act, ssp, cs;                 // prefix
static vbuf_t xe, he, qe, attne, acte, sspe, cse, xt, noise, h1, h2, tau, tc, vout;  // expert
static vbuf_t ws;

static void rope_table(float* t, uint32_t rows, uint32_t pos0, uint32_t last) {  // cos[128] | sin[128] per row
  for (uint32_t r = 0; r < rows; ++r) {
    uint32_t p = pos0 + (r < last ? r : last);
    for (int i = 0; i < HD / 2; ++i) {
      float a = (float)p * powf(10000.0f, -2.0f * i / HD);
      t[r * HD + i] = cosf(a), t[r * HD + HD / 2 + i] = sinf(a);
    }
  }
}

static void make_activations(void) {
  patches = vk_buffer(&v, (size_t)VM * PATCH * 4);  // the images' 14 x 14 x 3 patches (CPU pre-processing)
  fill(patches.map, (size_t)VM * PATCH, F32, -1, 1);
  for (uint32_t r = 0; r < VM; ++r) memset((float*)patches.map + (size_t)r * PATCH + 588, 0, (PATCH - 588) * 4);
  xv = vk_buffer(&v, (size_t)VM * VD * 4), hv = vk_buffer(&v, (size_t)VM * VD * 2);
  qv = vk_buffer(&v, (size_t)VH * VM * VHD * 2), kv = vk_buffer(&v, (size_t)VH * VM * VHD * 2);
  vtv = vk_buffer(&v, (size_t)VH * VHD * VM * 2), attnv = vk_buffer(&v, (size_t)VM * VD * 2);
  actv = vk_buffer(&v, (size_t)VM * VFF * 2);

  x = vk_buffer(&v, (size_t)PM * D * 4);
  lang = zeros((size_t)LANG * D * 4);  // language embeddings x sqrt(2048) (CPU): 15 tokens, 48 rows with padding
  fill(lang.map, (size_t)15 * D, F32, -1, 1);
  h = vk_buffer(&v, (size_t)PM * D * 2), q = vk_buffer(&v, (size_t)NH * PM * HD * 2);
  for (int l = 0; l < L; ++l) kc[l] = zeros((size_t)KR * HD * 2), vc[l] = zeros((size_t)HD * KR * 2);
  attn = vk_buffer(&v, (size_t)PM * NH * HD * 2), act = vk_buffer(&v, (size_t)PM * FF * 2);
  ssp = vk_buffer(&v, (size_t)PM * (D / 64) * 4), cs = vk_buffer(&v, (size_t)PM * HD * 4);
  rope_table(cs.map, PM, 0, VALID - 1);  // positions: cumsum of the pad mask - 1

  xe = vk_buffer(&v, (size_t)SM * ED * 4), he = vk_buffer(&v, (size_t)SM * ED * 2);
  qe = vk_buffer(&v, (size_t)NH * SM * HD * 2), attne = vk_buffer(&v, (size_t)SM * NH * HD * 2);
  acte = vk_buffer(&v, (size_t)SM * EFF * 2), sspe = vk_buffer(&v, (size_t)SM * (ED / 64) * 4);
  cse = vk_buffer(&v, (size_t)SM * HD * 4);
  rope_table(cse.map, SM, VALID, S - 1);
  xt = zeros((size_t)SM * AD * 4), noise = zeros((size_t)SM * AD * 4);
  for (int r = 0; r < 50; ++r) fill((float*)noise.map + r * AD, 32, F32, -1.7f, 1.7f);
  h1 = vk_buffer(&v, (size_t)SM * ED * 4), h2 = vk_buffer(&v, (size_t)SM * ED * 4);
  tau = zeros((size_t)SM * ED * 4), tc = vk_buffer(&v, (size_t)SM * ED * 4);
  for (int s = 0; s < STEPS; ++s) {  // sinusoidal embedding of t = 1, 0.9, ..., 0.1 (periods 4e-3 .. 4)
    float t = 1.0f - s * (1.0f / STEPS), *row = (float*)tau.map + s * ED;
    for (int i = 0; i < ED / 2; ++i) {
      float period = 4e-3f * powf(4.0f / 4e-3f, (float)i / (ED / 2 - 1)), a = 2 * (float)M_PI * t / period;
      row[i] = sinf(a), row[ED / 2 + i] = cosf(a);
    }
  }
  vout = vk_buffer(&v, (size_t)SM * AD * 4);
  ws = vk_buffer(&v, 8u << 20);
}

// ---- recording ----

static int prof;
static uint32_t nts;
static const char* ts_name[NTS];
static int ts_stage[NTS], stage;
static void stamp(VkCommandBuffer c, const char* name) {
  vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, nts);
  ts_name[nts] = name, ts_stage[nts] = stage, ++nts;
}
#define OP(name, call) do { CHECK(call); if (prof) stamp(c, name); } while (0)

static void glue(VkCommandBuffer c, uint32_t mode, vbuf_t* src, vbuf_t* dst, vbuf_t* a, vbuf_t* b, uint32_t rows,
                 uint32_t cols, uint32_t srows, uint32_t step, uint32_t r0, float dt) {
  VkDescriptorBufferInfo bi[4] = {{(src ? src : dst)->buf, 0, VK_WHOLE_SIZE}, {dst->buf, 0, VK_WHOLE_SIZE},
                                  {(a ? a : dst)->buf, 0, VK_WHOLE_SIZE}, {(b ? b : dst)->buf, 0, VK_WHOLE_SIZE}};
  struct { uint32_t mode, rows, cols, srows, step, r0; float dt; } pc = {mode, rows, cols, srows, step, r0, dt};
  vk_dispatch(&v, c, glue_p, bi, 4, &pc, sizeof pc, (rows * cols + 255) / 256, 1, 1);
  ablasLtBarrier(lt, c);
  if (prof) stamp(c, "glue");
}

static ablasLtLayout wl(uint32_t N, uint32_t K) { return (ablasLtLayout){wt, ABLASLT_ORDER_WEIGHT, N, K}; }
static ablasLtLayout wgu(uint32_t N, uint32_t K) { return (ablasLtLayout){wt, ABLASLT_ORDER_WEIGHT, N, K, ABLASLT_WEIGHT_GATE_UP}; }
static ablasLtLayout tl(uint32_t M, uint32_t K) { return (ablasLtLayout){ABLASLT_F16, ABLASLT_ORDER_TILED, M, K}; }
static ablasLtLayout fl(uint32_t M, uint32_t N) { return (ablasLtLayout){ABLASLT_F32, ABLASLT_ORDER_ROW, M, N}; }

static void vision(VkCommandBuffer c) {
  ablasLtLayout pl = fl(VM, PATCH), w0 = wl(VD, PATCH), xl = fl(VM, VD), hl = tl(VM, VD), wq = wl(VQKV, VD),
                wo = wl(VD, VD), w1 = wl(VFF, VD), al = tl(VM, VFF), w2 = wl(VD, VFF), pjl = wl(D, VD), x0 = fl(VM, D);
  glue(c, 3, &pos, &xv, NULL, NULL, VM, VD, T, 0, 0, 0);  // x = position embeddings, per image
  ablasLtMatmulDesc pe = {ABLASLT_EPILOGUE_RESIDUAL_BIAS, .bias = B(&patch_b)};
  OP("patch embed", ablasLtMatmul(lt, c, &pe, B(&patches), &pl, B(&patch_w), &w0, B(&xv), &xl, B(&ws)));
  for (int l = 0; l < VL; ++l) {
    vit_layer* w = &vl[l];
    ablasLtMatmulDesc qkv = {ABLASLT_EPILOGUE_ROPE_QKV, .n_heads = VH, .n_kv_heads = VH, .q = B(&qv), .k = B(&kv),
                             .vt = B(&vtv), .bias = B(&w->qkvb), .head_dim = VHD, .head_dim_valid = VHDV};
    ablasLtAttentionDesc ad = {.M = T, .batches = NIMG, .n_heads = VH, .n_kv_heads = VH, .head_dim = VHD,
                               .head_dim_valid = VHDV, .scale = 1.0f / sqrtf((float)VHDV)};
    ablasLtMatmulDesc ro = {ABLASLT_EPILOGUE_RESIDUAL_BIAS, .bias = B(&w->ob)};
    ablasLtMatmulDesc up = {ABLASLT_EPILOGUE_BIAS_GELU, .bias = B(&w->fc1b)};
    ablasLtMatmulDesc dn = {ABLASLT_EPILOGUE_RESIDUAL_BIAS, .bias = B(&w->fc2b)};
    OP("layernorm", ablasLtLayerNorm(lt, c, VM, VD, B(&xv), B(&w->ln1w), B(&w->ln1b), 1e-6f, B(&hv), B(&ws)));
    OP("qkv + split", ablasLtMatmul(lt, c, &qkv, B(&hv), &hl, B(&w->qkv), &wq, none, NULL, B(&ws)));
    OP("attention", ablasLtAttentionMasked(lt, c, &ad, B(&qv), B(&kv), B(&vtv), B(&attnv)));
    OP("o proj", ablasLtMatmul(lt, c, &ro, B(&attnv), &hl, B(&w->o), &wo, B(&xv), &xl, none));
    OP("layernorm", ablasLtLayerNorm(lt, c, VM, VD, B(&xv), B(&w->ln2w), B(&w->ln2b), 1e-6f, B(&hv), B(&ws)));
    OP("mlp up (gelu)", ablasLtMatmul(lt, c, &up, B(&hv), &hl, B(&w->fc1), &w1, B(&actv), &al, none));
    OP("mlp down", ablasLtMatmul(lt, c, &dn, B(&actv), &al, B(&w->fc2), &w2, B(&xv), &xl, none));
  }
  OP("layernorm", ablasLtLayerNorm(lt, c, VM, VD, B(&xv), B(&post_w), B(&post_b), 1e-6f, B(&hv), B(&ws)));
  glue(c, 3, NULL, &x, NULL, NULL, VM, D, 0, 0, 0, 0);           // prefix rows 0-767: 0, then += projector
  glue(c, 3, &lang, &x, NULL, NULL, LANG, D, LANG, 0, VM, 0);    // rows 768-831: language (and padding)
  ablasLtMatmulDesc pj = {ABLASLT_EPILOGUE_RESIDUAL_BIAS, .bias = B(&proj_b)};
  OP("projector", ablasLtMatmul(lt, c, &pj, B(&hv), &hl, B(&proj), &pjl, B(&x), &x0, none));
}

// Gemma 2B over the prefix; layer l's K and V go to rows 0-831 of kc[l] / vc[l], the expert's cache.
static void prefix(VkCommandBuffer c) {
  ablasLtLayout hl = tl(PM, D), xl = fl(PM, D), al = tl(PM, FF), wq = wl(QKV, D), wo = wl(D, NH * HD),
                wg = wgu(2 * FF, D), wd = wl(D, FF);
  ablasLtMatmulDesc res = {ABLASLT_EPILOGUE_RESIDUAL, .aux = B(&ssp)}, geglu = {ABLASLT_EPILOGUE_GEGLU};
  ablasLtAttentionDesc ad = {.M = PM, .n_heads = NH, .n_kv_heads = 1, .head_dim = HD, .kv_rows = KR, .kv_batch = KR,
                             .keys = PM, .key_valid = VALID, .scale = 1.0f / 16};
  for (int l = 0; l < L; ++l) {
    gemma_layer* w = &gl_[l];
    ablasLtMatmulDesc rope = {ABLASLT_EPILOGUE_ROPE_QKV, .n_heads = NH, .n_kv_heads = 1, .rope = B(&cs), .q = B(&q),
                              .k = B(&kc[l]), .vt = B(&vc[l]), .head_dim = HD, .kv_rows = KR, .kv_offset = 0};
    OP("rmsnorm", ablasLtRmsNorm(lt, c, PM, D, B(&x), l ? B(&ssp) : none, B(&w->n1), 1e-6f, B(&h), B(&ws)));
    OP("qkv + rope", ablasLtMatmul(lt, c, &rope, B(&h), &hl, B(&w->qkv), &wq, none, NULL, B(&ws)));
    if (l == L - 1) break;
    OP("attention", ablasLtAttentionMasked(lt, c, &ad, B(&q), B(&kc[l]), B(&vc[l]), B(&attn)));
    OP("o proj", ablasLtMatmul(lt, c, &res, B(&attn), &hl, B(&w->o), &wo, B(&x), &xl, none));
    OP("rmsnorm", ablasLtRmsNorm(lt, c, PM, D, B(&x), B(&ssp), B(&w->n2), 1e-6f, B(&h), none));
    OP("gate|up (geglu)", ablasLtMatmul(lt, c, &geglu, B(&h), &hl, B(&w->gu), &wg, B(&act), &al, none));
    OP("down", ablasLtMatmul(lt, c, &res, B(&act), &al, B(&w->d), &wd, B(&x), &xl, none));
  }
}

// 10 Euler steps of the action expert from x_t = noise at t = 1 to t = 0.
static void steps(VkCommandBuffer c) {
  ablasLtLayout hl = tl(SM, ED), xl = fl(SM, ED), al = tl(SM, EFF), atl = tl(SM, NH * HD), wq = wl(QKV, ED),
                wo = wl(ED, NH * HD), wg = wgu(2 * EFF, ED), wd = wl(ED, EFF), xtl = fl(SM, AD), wi = wl(ED, AD),
                we = wl(ED, ED), outl = wl(AD, ED), vl_ = fl(SM, AD);
  ablasLtMatmulDesc plain = {ABLASLT_EPILOGUE_DEFAULT}, res = {ABLASLT_EPILOGUE_RESIDUAL, .aux = B(&sspe)},
                    geglu = {ABLASLT_EPILOGUE_GEGLU};
  ablasLtAttentionDesc ad = {.M = SM, .n_heads = NH, .n_kv_heads = 1, .head_dim = HD, .kv_rows = KR, .kv_batch = KR,
                             .keys = KR, .key_valid = VALID, .suffix_base = PM, .suffix_count = S,
                             .suffix_causal = 1, .scale = 1.0f / 16, .workspace = B(&ws)};  // keys split
  if (getenv("PI0_NO_KEY_SPLIT")) ad.workspace = none;
  glue(c, 3, &noise, &xt, NULL, NULL, SM, AD, SM, 0, 0, 0);
  OP("time mlp", ablasLtMatmul(lt, c, &plain, B(&tau), &xl, B(&e_wtime), &we, B(&tc), &xl, B(&ws)));  // all steps
  for (int s = 0; s < STEPS; ++s) {
    OP("action in", ablasLtMatmul(lt, c, &plain, B(&xt), &xtl, B(&e_win), &wi, B(&h1), &xl, B(&ws)));
    glue(c, 0, NULL, &h1, &tc, &e_b1, SM, ED, 0, (uint32_t)s, 0, 0);
    OP("action in", ablasLtMatmul(lt, c, &plain, B(&h1), &xl, B(&e_w2), &we, B(&h2), &xl, B(&ws)));
    glue(c, 1, &h2, &xe, &state_emb, &e_b2, SM, ED, 0, 0, 0, 0);
    for (int l = 0; l < L; ++l) {
      gemma_layer* w = &el[l];
      ablasLtMatmulDesc rope = {ABLASLT_EPILOGUE_ROPE_QKV, .n_heads = NH, .n_kv_heads = 1, .rope = B(&cse),
                                .q = B(&qe), .k = B(&kc[l]), .vt = B(&vc[l]), .head_dim = HD, .kv_rows = KR,
                                .kv_offset = PM};
      OP("rmsnorm", ablasLtRmsNorm(lt, c, SM, ED, B(&xe), l ? B(&sspe) : none, B(&w->n1), 1e-6f, B(&he), B(&ws)));
      OP("qkv + rope", ablasLtMatmul(lt, c, &rope, B(&he), &hl, B(&w->qkv), &wq, none, NULL, B(&ws)));
      OP("attention", ablasLtAttentionMasked(lt, c, &ad, B(&qe), B(&kc[l]), B(&vc[l]), B(&attne)));
      OP("o proj", ablasLtMatmul(lt, c, &res, B(&attne), &atl, B(&w->o), &wo, B(&xe), &xl, none));
      OP("rmsnorm", ablasLtRmsNorm(lt, c, SM, ED, B(&xe), B(&sspe), B(&w->n2), 1e-6f, B(&he), none));
      OP("gate|up (geglu)", ablasLtMatmul(lt, c, &geglu, B(&he), &hl, B(&w->gu), &wg, B(&acte), &al, none));
      OP("down", ablasLtMatmul(lt, c, &res, B(&acte), &al, B(&w->d), &wd, B(&xe), &xl, none));
    }
    OP("rmsnorm", ablasLtRmsNorm(lt, c, SM, ED, B(&xe), B(&sspe), B(&e_fnorm), 1e-6f, B(&he), none));
    OP("action out", ablasLtMatmul(lt, c, &plain, B(&he), &hl, B(&e_out), &outl, B(&vout), &vl_, none));
    glue(c, 2, &vout, &xt, NULL, &e_bout, SM, AD, 0, 0, 0, -1.0f / STEPS);
  }
}

static const char* stage_names[3] = {"vision", "prefix", "10 steps"};

static void record(VkCommandBuffer c) {
  nts = 0;
  vk_begin(c);
  vkCmdResetQueryPool(c, v.qp, 0, NTS);
  stage = -1;
  vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, v.qp, nts);
  ts_name[nts] = "start", ts_stage[nts] = -1, ++nts;
  stage = 0, vision(c);
  if (!prof) stamp(c, "vision");
  stage = 1, prefix(c);
  if (!prof) stamp(c, "prefix");
  stage = 2, steps(c);
  if (!prof) stamp(c, "steps");
  CK(vkEndCommandBuffer(c));
}

int main(int argc, char** argv) {
  setvbuf(stdout, NULL, _IOLBF, 0);
  int reps = 5;
  for (int i = 1; i < argc; ++i) {
    if (!strcmp(argv[i], "-r")) reps = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-p")) prof = 1;
    else if (!strcmp(argv[i], "-q")) wt = ABLASLT_Q4_0;
  }
  vk_init(&v, NTS);
  ablas_handle ab;
  if (ablas_create(&ab, v.pd, v.dev, v.gipa, v.inst) || ablasLtCreate(&lt, ab, v.dev, v.gipa, v.inst, 0)) {
    fprintf(stderr, "AdrenoBLAS: no device support\n");
    return 1;
  }
  glue_p = vk_pipeline(&v, glue_spv, sizeof glue_spv);
  double t0 = now_ms();
  make_weights();
  make_activations();
  printf("device %s; %s weights (random) %.2f GB, made in %.1f s\n", v.name, wt == ABLASLT_Q4_0 ? "Q4_0" : "fp16",
         weight_bytes / 1e9, (now_ms() - t0) / 1e3);

  VkCommandBuffer c = vk_cmd(&v);
  t0 = now_ms();
  record(c);
  printf("recorded %u timestamps in %.0f ms (pipelines built on first use)\n", nts, now_ms() - t0);
  double best[4] = {1e30, 1e30, 1e30, 1e30};
  double* sums = calloc(NTS, sizeof *sums);  // per stamp, summed over the timed runs
  for (int rep = 0; rep <= reps; ++rep) {
    vk_submit_wait(&v, c);
    uint64_t ts[NTS];
    CK(vkGetQueryPoolResults(v.dev, v.qp, 0, nts, nts * 8, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
    double st[3] = {0}, prev = 0;
    for (uint32_t i = 1; i < nts; ++i) {
      double ms = (ts[i] - ts[i - 1]) * v.ts_ns * 1e-6;
      st[ts_stage[i]] += ms;
      if (rep) sums[i] += ms;
      prev += ms;
    }
    printf("%s %d: vision %.1f ms, prefix %.1f ms, 10 steps %.1f ms (%.2f ms/step); chunk %.1f ms\n",
           rep ? "run" : "warm-up", rep, st[0], st[1], st[2], st[2] / STEPS, prev);
    if (rep)
      for (int s = 0; s < 3; ++s) best[s] = fmin(best[s], st[s]);
    if (rep) best[3] = fmin(best[3], prev);
  }
  // the actions are random numbers here, but they must be finite
  double amax = 0;
  int finite = 1;
  for (int r = 0; r < 50; ++r)
    for (int j = 0; j < 32; ++j) {
      float a = ((float*)xt.map)[r * AD + j];
      finite &= isfinite(a), amax = fmax(amax, fabs(a));
    }
  printf("actions (50 x 32): %s, max |a| %.3g\n", finite ? "finite" : "NOT FINITE", amax);
  printf("RESULT %s best of %d: vision %.1f ms, prefix %.1f ms, 10 steps %.1f ms, chunk %.1f ms\n",
         wt == ABLASLT_Q4_0 ? "q4_0" : "fp16", reps, best[0], best[1], best[2], best[3]);
  if (prof && reps && getenv("PI0_LAYERS")) {  // every operation of the prefix, in order
    for (uint32_t i = 1; i < nts; ++i)
      if (ts_stage[i] == 1) printf("  prefix op %3u %-18s %.3f ms\n", i, ts_name[i], sums[i] / reps);
  }
  if (prof && reps) {  // per kind of operation, per stage (mean over the timed runs)
    for (int s = 0; s < 3; ++s) {
      const char* names[32];
      double ms[32];
      int cnt[32], n = 0;
      double tot = 0;
      for (uint32_t i = 1; i < nts; ++i) {
        if (ts_stage[i] != s) continue;
        int j = 0;
        while (j < n && strcmp(names[j], ts_name[i])) ++j;
        if (j == n) names[n] = ts_name[i], ms[n] = 0, cnt[n] = 0, ++n;
        ms[j] += sums[i] / reps, cnt[j]++, tot += sums[i] / reps;
      }
      printf("\n%s: %.1f ms\n", stage_names[s], tot);
      for (int j = 0; j < n; ++j) printf("  %-18s %8.2f ms  %5.1f%%  (%d calls)\n", names[j], ms[j], 100 * ms[j] / tot, cnt[j]);
    }
  }
  return 0;
}
