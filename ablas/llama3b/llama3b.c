// Llama 3.2 3B prefill on the Adreno 850 with every GEMM in AdrenoBLAS (fp16 or Q4_0 weights).
//   llama3b -w w/llama3b_q4 -t tokens.bin -m M [-r REPS] [-o DUMPDIR] [-p]
// tokens.bin: int32 token ids (the first M are used). One command buffer runs the whole prefill: 28 layers of
//   rmsnorm -> qkv GEMM -> RoPE / V^T -> S = Q K^T (causal, batched over heads) -> softmax -> O = P V -> o GEMM
//   -> residual + rmsnorm -> gate|up GEMM -> SiLU*up -> down GEMM -> residual, then the final norm and the LM head
//   (logits of the last 64 tokens; the last one is the prediction). The embedding gather runs on the CPU.
// -p: a timestamp after every op, summed per op kind (the timestamps serialize nothing extra: there is a barrier
// between all ops anyway). -o: writes logits.bin (fp32 [V], last token) and hidden.bin (fp32 [M, D], final norm).
#include <math.h>
#include <stdint.h>

#include "vkutil.h"  // first: defines VK_NO_PROTOTYPES
#include "../ablas.h"

enum { D = 3072, NH = 24, NKV = 8, HD = 128, FF = 8192, V = 128256, NL = 28, QKV = 5120 };

typedef struct { char name[64]; size_t off, bytes; vbuf_t buf; } tensor_t;
static tensor_t tens[256];
static int ntens;
static int q4;
static vk_t v;
static ablas_handle ab;

static void interleave_gu(tensor_t* t);
static void permute_qk(tensor_t* t);
static int fused_qkv;

static tensor_t* T(const char* name) {
  for (int i = 0; i < ntens; ++i)
    if (!strcmp(tens[i].name, name)) return &tens[i];
  fprintf(stderr, "missing tensor %s\n", name);
  exit(1);
}

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
  double t0 = now_ms(), total = 0;
  for (int i = 0; i < ntens; ++i) {
    tens[i].buf = vk_buffer(&v, tens[i].bytes);
    fseeko(f, (off_t)tens[i].off, SEEK_SET);
    if (fread(tens[i].buf.map, 1, tens[i].bytes, f) != tens[i].bytes) { fprintf(stderr, "short read %s\n", tens[i].name); exit(1); }
    total += tens[i].bytes;
  }
  fclose(f);
  for (int i = 0; i < ntens; ++i)
    if (strstr(tens[i].name, ".wgu")) interleave_gu(&tens[i]);
    else if (fused_qkv && strstr(tens[i].name, ".wqkv")) permute_qk(&tens[i]);
  printf("weights: %d tensors, %.2f GB in %.1f s\n", ntens, total / 1e9, (now_ms() - t0) / 1e3);
}

// Row v of the tied embedding (the LM head weight, [V, D] in the GEMM's B format) as fp32.
static void embed_row(uint32_t tok, float* out) {
  const uint8_t* base = T("tok")->buf.map;
  for (uint32_t k = 0; k < D; ++k) {
    if (!q4) {
      const _Float16* t = (const _Float16*)base;
      out[k] = (float)t[((size_t)(tok / 64) * (D / 16) + k / 16) * 1024 + (tok % 64) * 16 + k % 16];
    } else {
      size_t KB = D / 32, blk = (size_t)(tok / 64) * KB + k / 32;
      uint32_t kk = k % 16, h = (k % 32) / 16, w = kk / 8, j = (kk % 8) / 2, hi = kk % 2;
      const uint32_t* qw = (const uint32_t*)base;
      uint32_t word = qw[((blk * 2 + h) * 64 + tok % 64) * 2 + w];
      uint32_t nib = (word >> (4 * j + 16 * hi)) & 15;
      const _Float16* sc = (const _Float16*)(base + (size_t)V * D / 2);
      out[k] = ((float)nib - 8.0f) * (float)sc[blk * 64 + tok % 64];
    }
  }
}

// gate|up weight [2*FF, D] (gate rows, then up rows) -> 64-row groups [32 gate | 32 up], the layout
// ABLAS_EPI_SWIGLU wants. In the B formats a 64-row panel's rows 0-31 and 32-63 are separate runs: fp16 tiles hold
// 32 rows in the first 1 KB of each 2 KB K-tile; Q4_0 holds them in the first 256 bytes of each 512-byte quant run
// and the first 64 bytes of each 128-byte scale run. So group j takes the half (j % 2) of gate panel j / 2 and of
// up panel FF/64 + j / 2.
static void interleave_gu(tensor_t* t) {
  size_t bytes = t->bytes;
  uint8_t *src = malloc(bytes), *dst = t->buf.map;
  memcpy(src, dst, bytes);
  uint32_t NP = 2 * FF / 64, UP = FF / 64;  // panels; up panels start at UP
  if (!q4) {
    size_t KT = D / 16;  // K tiles per panel, 2 KB each
    for (uint32_t j = 0; j < NP; ++j)
      for (size_t kt = 0; kt < KT; ++kt) {
        uint8_t* o = dst + ((size_t)j * KT + kt) * 2048;
        memcpy(o, src + ((size_t)(j / 2) * KT + kt) * 2048 + (j % 2) * 1024, 1024);
        memcpy(o + 1024, src + ((size_t)(UP + j / 2) * KT + kt) * 2048 + (j % 2) * 1024, 1024);
      }
  } else {
    size_t KB = D / 32, qbytes = (size_t)2 * FF * D / 2;
    for (uint32_t j = 0; j < NP; ++j)
      for (size_t kb = 0; kb < KB; ++kb) {
        for (int h = 0; h < 2; ++h) {  // quants: (panel, kb, h) runs of 64 lanes x 8 bytes
          uint8_t* o = dst + (((size_t)j * KB + kb) * 2 + h) * 512;
          memcpy(o, src + (((size_t)(j / 2) * KB + kb) * 2 + h) * 512 + (j % 2) * 256, 256);
          memcpy(o + 256, src + (((size_t)(UP + j / 2) * KB + kb) * 2 + h) * 512 + (j % 2) * 256, 256);
        }
        uint8_t* o = dst + qbytes + ((size_t)j * KB + kb) * 128;  // scales: (panel, kb) runs of 64 halves
        memcpy(o, src + qbytes + ((size_t)(j / 2) * KB + kb) * 128 + (j % 2) * 64, 64);
        memcpy(o + 64, src + qbytes + ((size_t)(UP + j / 2) * KB + kb) * 128 + (j % 2) * 64, 64);
      }
  }
  free(src);
}

// qkv weight [5120, D]: permute the 128 rows of every Q and K head (rows 0..4095) to [0, 64, 1, 65, ...] so the
// fused qkv+RoPE kernel (gen_fused.py) finds each rotate_half pair (d, d + 64) in adjacent columns. Rows are
// 32-byte runs of the fp16 tiles (64 per 2 KB K-tile), 8-byte runs of the Q4_0 quants (64 per 512-byte run) and
// 2-byte scales (64 per 128-byte run).
static void permute_qk(tensor_t* t) {
  size_t bytes = t->bytes;
  uint8_t *src = malloc(bytes), *dst = t->buf.map;
  memcpy(src, dst, bytes);
  for (uint32_t hb = 0; hb < (NH + NKV); ++hb)
    for (uint32_t j = 0; j < 128; ++j) {
      uint32_t nd = hb * 128 + j, ns = hb * 128 + (j % 2 ? 64 + j / 2 : j / 2);  // dest row <- source row
      if (!q4) {
        size_t KT = D / 16;
        for (size_t kt = 0; kt < KT; ++kt)
          memcpy(dst + ((size_t)(nd / 64) * KT + kt) * 2048 + (nd % 64) * 32,
                 src + ((size_t)(ns / 64) * KT + kt) * 2048 + (ns % 64) * 32, 32);
      } else {
        size_t KB = D / 32, qbytes = (size_t)QKV * D / 2;
        for (size_t kb = 0; kb < KB; ++kb) {
          for (int h = 0; h < 2; ++h)
            memcpy(dst + (((size_t)(nd / 64) * KB + kb) * 2 + h) * 512 + (nd % 64) * 8,
                   src + (((size_t)(ns / 64) * KB + kb) * 2 + h) * 512 + (ns % 64) * 8, 8);
          memcpy(dst + qbytes + ((size_t)(nd / 64) * KB + kb) * 128 + (nd % 64) * 2,
                 src + qbytes + ((size_t)(ns / 64) * KB + kb) * 128 + (ns % 64) * 2, 2);
        }
      }
    }
  free(src);
}

static ablas_buf AB(vbuf_t* b, size_t off) { return (ablas_buf){b->buf, off}; }
static VkDescriptorBufferInfo DB(vbuf_t* b) { return (VkDescriptorBufferInfo){b ? b->buf : VK_NULL_HANDLE, 0, VK_WHOLE_SIZE}; }

enum { OP_NORM, OP_QKV, OP_ROPE, OP_QK, OP_SOFTMAX, OP_PV, OP_FA, OP_O, OP_GU, OP_SILU, OP_DOWN, OP_HEAD, NOPS };
static const char* opname[NOPS] = {"rmsnorm", "qkv gemm", "rope+v^T", "QK^T", "softmax", "PV", "flash attn", "o gemm",
                                   "gate|up gemm", "silu*up", "down gemm", "lm head"};
static int opkind[1024];
static uint32_t nts;
static int profile;

static void mark(VkCommandBuffer c, int kind) {
  vk_barrier(c);
  if (!profile) return;
  opkind[nts] = kind;
  vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, nts++);
}

static const char* gemm_kernel[NOPS];
static void gemm(VkCommandBuffer c, int kind, ablas_buf A, tensor_t* W, vbuf_t* C, uint32_t M, uint32_t N, uint32_t K,
                 ablas_epilogue ep) {
  ablas_buf w = {W->buf.buf, 0}, cc = {C->buf, 0}, none = {0};
  ablas_status st = q4 ? ablas_hgemm_q4_0_ex(ab, c, ABLAS_OP_P, M, N, K, A, w, cc, none, ep)
                       : ablas_hgemm_ex(ab, c, ABLAS_OP_P, ABLAS_OP_P, M, N, K, A, w, cc, none, ep);
  if (st) { fprintf(stderr, "gemm %s %ux%ux%u: status %d\n", W->name, M, N, K, st); exit(1); }
  gemm_kernel[kind] = ablas_last_kernel(ab);
  mark(c, kind);
}

// GEMM with the residual epilogue: x (fp32 [M, N]) += A W^T, ssp receives row sums of squares per 64 columns
static void gemm_res(VkCommandBuffer c, int kind, ablas_buf A, tensor_t* W, vbuf_t* X, vbuf_t* SS, uint32_t M,
                     uint32_t N, uint32_t K) {
  ablas_buf w = {W->buf.buf, 0}, xx = {X->buf, 0}, ws = {SS->buf, 0};
  ablas_status st = q4 ? ablas_hgemm_q4_0_ex(ab, c, ABLAS_OP_P, M, N, K, A, w, xx, ws, ABLAS_EPI_RESIDUAL_RMS)
                       : ablas_hgemm_ex(ab, c, ABLAS_OP_P, ABLAS_OP_P, M, N, K, A, w, xx, ws, ABLAS_EPI_RESIDUAL_RMS);
  if (st) { fprintf(stderr, "gemm_res %s %ux%ux%u: status %d\n", W->name, M, N, K, st); exit(1); }
  gemm_kernel[kind] = ablas_last_kernel(ab);
  mark(c, kind);
}

int main(int argc, char** argv) {
  setvbuf(stdout, NULL, _IOLBF, 0);
  const char *wpath = "w/llama3b_q4", *tpath = "tokens.bin", *odir = NULL;
  uint32_t M = 512;
  int reps = 3, nlayers = NL;
  for (int i = 1; i < argc; ++i) {
    if (!strcmp(argv[i], "-w")) wpath = argv[++i];
    else if (!strcmp(argv[i], "-t")) tpath = argv[++i];
    else if (!strcmp(argv[i], "-m")) M = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-r")) reps = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-o")) odir = argv[++i];
    else if (!strcmp(argv[i], "-p")) profile = 1;
    else if (!strcmp(argv[i], "-L")) nlayers = atoi(argv[++i]);  // debug: run n layers, dump the residual x
  }
  q4 = strstr(wpath, "q4") != NULL;
  fused_qkv = !getenv("L3B_NOFUSEQKV");
  if (M % 128 || M < 128) { fprintf(stderr, "M must be a multiple of 128\n"); return 1; }
  vk_init(&v, 1024);
  printf("device: %s, weights %s, M = %u\n", v.name, q4 ? "Q4_0" : "fp16", M);
  if (ablas_create(&ab, v.pd, v.dev, v.gipa, v.inst)) { fprintf(stderr, "ablas_create failed\n"); return 1; }
  load_weights(wpath);

  // activations
  vbuf_t x = vk_buffer(&v, (size_t)M * D * 4), hA = vk_buffer(&v, (size_t)M * D * 2),
         qkv = vk_buffer(&v, (size_t)M * QKV * 2), Q = vk_buffer(&v, (size_t)NH * M * HD * 2),
         Kt = vk_buffer(&v, (size_t)NKV * M * HD * 2), VT = vk_buffer(&v, (size_t)NKV * HD * M * 2),
         S = vk_buffer(&v, (size_t)NH * M * M * 2), Oa = vk_buffer(&v, (size_t)M * D * 2),
         o = vk_buffer(&v, (size_t)M * D * 2),
         act = vk_buffer(&v, (size_t)M * FF * 2), dn = vk_buffer(&v, (size_t)M * D * 2),
         logits = vk_buffer(&v, (size_t)64 * V * 2), cs = vk_buffer(&v, (size_t)M * HD * 4),
         ss = vk_buffer(&v, (size_t)M * 4), ssp = vk_buffer(&v, (size_t)M * 48 * 4);

  // tokens -> embeddings (CPU), RoPE table: cos/sin(pos * inv_freq) in fp32 like transformers
  size_t tb;
  int32_t* tok = read_file(tpath, &tb);
  if (tb / 4 < M) { fprintf(stderr, "%s has %zu tokens < M\n", tpath, tb / 4); return 1; }
  const float* inv_freq = T("inv_freq")->buf.map;
  float* csm = cs.map;
  for (uint32_t p = 0; p < M; ++p)
    for (int i = 0; i < 64; ++i) {
      float a = (float)p * inv_freq[i];
      csm[p * 128 + i] = cosf(a), csm[p * 128 + 64 + i] = sinf(a);
    }

  char kp[512];
  const char* kdir = getenv("L3B_KERNELS") ? getenv("L3B_KERNELS") : "kernels";
#define PIPE(var, file) snprintf(kp, sizeof kp, "%s/%s.spv", kdir, file); VkPipeline var = vk_pipeline_file(&v, kp);
  PIPE(p_addsq, "addsq") PIPE(p_ntile, "normtile") PIPE(p_ntile2, "normtile2")
  int fused_res = !getenv("L3B_NOFUSERES"); PIPE(p_vt, "vt") PIPE(p_soft, "softmax")
  PIPE(p_rope, "rope2")
  char qkvname[64];
  snprintf(qkvname, sizeof qkvname, "qkv_rope_%s_%u", q4 ? "q4" : "f16", M);
  VkPipeline p_qkv = VK_NULL_HANDLE;
  uint32_t qkv_bm = 128, qkv_bn = 128;  // the fused kernel's workgroup tile (gen_fused.py writes it per fmt, M)
  if (fused_qkv) {
    PIPE(p_qkv_, qkvname) p_qkv = p_qkv_;
    snprintf(kp, sizeof kp, "%s/qkv_rope_tiles.txt", kdir);
    FILE* tf = fopen(kp, "r");
    char f[8];
    uint32_t tm_, bm_, bn_;
    while (tf && fscanf(tf, "%7s %u %u %u", f, &tm_, &bm_, &bn_) == 4)
      if (!strcmp(f, q4 ? "q4" : "f16") && tm_ == M) qkv_bm = bm_, qkv_bn = bn_;
    if (tf) fclose(tf);
  }
  const char* qkn = getenv("L3B_QK") ? getenv("L3B_QK") : "qk_w2x2";
  const char* pvn = getenv("L3B_PV") ? getenv("L3B_PV") : "pv_w2x2";
  PIPE(p_qk, qkn) PIPE(p_pv, pvn) PIPE(p_fa, getenv("L3B_FA") ? getenv("L3B_FA") : "fa3")
  int use_fa = !getenv("L3B_NOFA");
  uint32_t qk_wm = qkn[4] - '0', qk_wn = qkn[6] - '0', pv_wm = pvn[4] - '0', pv_wn = pvn[6] - '0';
  float eps = getenv("L3B_EPS") ? (float)atof(getenv("L3B_EPS")) : 1e-5f;
  // RMSNorm (with the residual add when y != NULL): x += y, ss = row sums of squares; then the R-tile writer
#define NORM(y, wname)                                                                               \
  do {                                                                                               \
    uint32_t add = (y) != NULL;                                                                      \
    VkDescriptorBufferInfo nb[4] = {DB(&x), DB(y), DB(&ss)};                                         \
    vk_dispatch(&v, c, p_addsq, nb, 3, &add, 4, M / 4, 1, 1);                                        \
    vk_barrier(c);                                                                                   \
    VkDescriptorBufferInfo tb2[4] = {DB(&x), DB(&ss), DB(&T(wname)->buf), DB(&hA)};                  \
    vk_dispatch(&v, c, p_ntile, tb2, 4, &eps, 4, D / 64, M / 64, 1);                                 \
    mark(c, OP_NORM);                                                                                \
  } while (0)
  // RMSNorm after a residual-epilogue GEMM: x and its per-64-column sums of squares are already there
#define NORM2(wname)                                                                                 \
  do {                                                                                               \
    struct { float eps; uint32_t nparts; } pn2 = {eps, 48};                                          \
    VkDescriptorBufferInfo tb3[4] = {DB(&x), DB(&ssp), DB(&T(wname)->buf), DB(&hA)};                 \
    vk_dispatch(&v, c, p_ntile2, tb3, 4, &pn2, sizeof pn2, D / 256, M / 64, 1);                      \
    mark(c, OP_NORM);                                                                                \
  } while (0)
  struct { uint32_t M; float scale; } pm = {M, 1.0f / sqrtf((float)HD)};

  VkCommandBuffer c = vk_cmd(&v);
  float* xm = x.map;
  double best = 1e30, tsum = 0;
  int runs = 0;
  for (int rep = 0; rep < reps + 1; ++rep) {  // rep 0: warm-up (pipeline creation), not counted
    for (uint32_t r = 0; r < M; ++r) embed_row((uint32_t)tok[r], xm + (size_t)r * D);
    nts = 0;
    vk_begin(c);
    vkCmdResetQueryPool(c, v.qp, 0, 1024);
    vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, v.qp, nts++);
    char nm[64];
    for (int l = 0; l < nlayers; ++l) {
      VkDescriptorBufferInfo b[4];
      snprintf(nm, sizeof nm, "L%d.attn_norm", l);
      if (fused_res && l > 0) NORM2(nm);
      else NORM(l > 0 ? &dn : NULL, nm);
      snprintf(nm, sizeof nm, "L%d.wqkv", l);
      if (fused_qkv) {  // qkv GEMM + RoPE + Q/K/V^T layouts in one kernel
        VkDescriptorBufferInfo fb[7] = {DB(&hA), DB(&T(nm)->buf), DB(&Q), DB(&cs), DB(&Q), DB(&Kt), DB(&VT)};
        vk_dispatch(&v, c, p_qkv, fb, 7, NULL, 0, QKV / qkv_bn, M / qkv_bm, 1);
        gemm_kernel[OP_QKV] = qkvname;
        mark(c, OP_QKV);
      } else {
        gemm(c, OP_QKV, AB(&hA, 0), T(nm), &qkv, M, QKV, D, ABLAS_EPI_NONE);
        b[0] = DB(&qkv), b[1] = DB(&cs), b[2] = DB(&Q), b[3] = DB(&Kt);
        vk_dispatch(&v, c, p_rope, b, 4, &pm, 4, 32, M / 64, 1);
        b[0] = DB(&qkv), b[1] = DB(NULL), b[2] = DB(&VT);
        vk_dispatch(&v, c, p_vt, b, 3, &pm, 4, M / 16, NKV, 1);
        mark(c, OP_ROPE);
      }
      if (use_fa) {
        b[0] = DB(&Q), b[1] = DB(&Kt), b[2] = DB(&VT), b[3] = DB(&Oa);
        vk_dispatch(&v, c, p_fa, b, 4, &pm, sizeof pm, M / 64, NH, 1);
        mark(c, OP_FA);
      } else {
        b[0] = DB(&Q), b[1] = DB(&Kt), b[2] = DB(&S);
        vk_dispatch(&v, c, p_qk, b, 3, &pm, 4, M / (64 * qk_wn), M / (64 * qk_wm), NH);
        mark(c, OP_QK);
        b[0] = DB(&S);
        vk_dispatch(&v, c, p_soft, b, 1, &pm, sizeof pm, M, NH, 1);
        mark(c, OP_SOFTMAX);
        b[0] = DB(&S), b[1] = DB(&VT), b[2] = DB(&Oa);
        vk_dispatch(&v, c, p_pv, b, 3, &pm, 4, HD / (64 * pv_wn), M / (64 * pv_wm), NH);
        mark(c, OP_PV);
      }
      snprintf(nm, sizeof nm, "L%d.wo", l);
      if (fused_res) {
        gemm_res(c, OP_O, AB(&Oa, 0), T(nm), &x, &ssp, M, D, D);  // x += attn @ Wo^T, row sums of squares
        snprintf(nm, sizeof nm, "L%d.ffn_norm", l);
        NORM2(nm);
      } else {
        gemm(c, OP_O, AB(&Oa, 0), T(nm), &o, M, D, D, ABLAS_EPI_NONE);
        snprintf(nm, sizeof nm, "L%d.ffn_norm", l);
        NORM(&o, nm);
      }
      snprintf(nm, sizeof nm, "L%d.wgu", l);
      gemm(c, OP_GU, AB(&hA, 0), T(nm), &act, M, 2 * FF, D, ABLAS_EPI_SWIGLU);  // silu(gate) * up, packed
      snprintf(nm, sizeof nm, "L%d.wd", l);
      if (fused_res) gemm_res(c, OP_DOWN, AB(&act, 0), T(nm), &x, &ssp, M, D, FF);
      else gemm(c, OP_DOWN, AB(&act, 0), T(nm), &dn, M, D, FF, ABLAS_EPI_NONE);
    }
    if (nlayers < NL && fused_res) {
      // x already holds the residual after the last layer run
    } else if (nlayers < NL) {
      uint32_t add = 1;
      VkDescriptorBufferInfo nb[3] = {DB(&x), DB(&dn), DB(&ss)};
      vk_dispatch(&v, c, p_addsq, nb, 3, &add, 4, M / 4, 1, 1);
      mark(c, OP_NORM);
    } else {
      if (fused_res) NORM2("out_norm");
      else NORM(&dn, "out_norm");
      // LM head on the last 64 rows: their R-tile panel is contiguous at the end of hA
      gemm(c, OP_HEAD, AB(&hA, (size_t)(M - 64) * D * 2), T("tok"), &logits, 64, V, D, ABLAS_EPI_NONE);
    }
    if (!profile) vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, nts++);
    CK(vkEndCommandBuffer(c));
    double t0 = now_ms();
    vk_submit_wait(&v, c);
    double wall = now_ms() - t0;
    uint64_t ts[1024];
    CK(vkGetQueryPoolResults(v.dev, v.qp, 0, nts, sizeof ts, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
    double gpu = (ts[nts - 1] - ts[0]) * v.ts_ns * 1e-6;
    if (rep == 0) { printf("warm-up: gpu %.1f ms, wall %.1f ms\n", gpu, wall); continue; }
    printf("run %d: gpu %.2f ms, wall %.2f ms, %.1f tok/s\n", rep, gpu, wall, M / gpu * 1e3);
    if (gpu < best) best = gpu;
    tsum += gpu, ++runs;
    if (profile && rep == reps) {
      double ms[NOPS] = {0};
      for (uint32_t i = 1; i < nts; ++i) ms[opkind[i]] += (ts[i] - ts[i - 1]) * v.ts_ns * 1e-6;
      double fl[NOPS] = {0};
      fl[OP_QKV] = 2.0 * M * QKV * D * NL, fl[OP_O] = 2.0 * M * D * D * NL, fl[OP_GU] = 2.0 * M * 2 * FF * D * NL;
      fl[OP_DOWN] = 2.0 * M * D * FF * NL, fl[OP_HEAD] = 2.0 * 64 * V * D;
      fl[OP_QK] = fl[OP_PV] = 2.0 * NH * HD * ((double)M * (M + 1) / 2) * NL;  // causal (useful) FLOPs
      fl[OP_FA] = 2 * fl[OP_QK];
      printf("%-14s %9s %6s %9s  kernel\n", "op", "ms", "share", "TFLOP/s");
      for (int k = 0; k < NOPS; ++k) {
        char tf[16] = "";
        if (fl[k]) snprintf(tf, sizeof tf, "%.2f", fl[k] / (ms[k] * 1e-3) / 1e12);
        printf("%-14s %9.2f %5.1f%% %9s  %s\n", opname[k], ms[k], 100 * ms[k] / gpu, tf, gemm_kernel[k] ? gemm_kernel[k] : "");
      }
    }
  }
  double lin = 2.0 * M * NL * ((double)QKV * D + (double)D * D + 2.0 * FF * D + (double)D * FF) + 2.0 * 64 * V * D;
  double att = 2.0 * 2.0 * NH * HD * ((double)M * (M + 1) / 2) * NL;
  printf("RESULT %s M=%u best %.2f ms (%.1f tok/s), mean %.2f ms; linear+head %.2f TFLOP, attention %.3f TFLOP "
         "(causal) -> %.2f TFLOP/s overall\n", q4 ? "q4_0" : "fp16", M, best, M / best * 1e3, tsum / runs, lin / 1e12,
         att / 1e12, (lin + att) / (best * 1e-3) / 1e12);
  if (odir) {
    char p[512];
    const _Float16* lg = logits.map;
    float* out = malloc((size_t)M * D * 4);
    for (int i = 0; i < V; ++i) out[i] = (float)lg[(size_t)63 * V + i];
    snprintf(p, sizeof p, "%s/logits.bin", odir);
    FILE* f = fopen(p, "wb");
    fwrite(out, 4, V, f);
    fclose(f);
    const _Float16* hm = hA.map;
    for (uint32_t r = 0; r < M; ++r)
      for (uint32_t k = 0; k < D; ++k)
        out[(size_t)r * D + k] = (float)hm[((size_t)(r / 64) * (D / 16) + k / 16) * 1024 + (r % 64) * 16 + k % 16];
    snprintf(p, sizeof p, "%s/hidden.bin", odir);
    f = fopen(p, "wb");
    fwrite(out, 4, (size_t)M * D, f);
    fclose(f);
    printf("wrote %s/logits.bin, hidden.bin\n", odir);
    if (nlayers < NL) {
      snprintf(p, sizeof p, "%s/x%d.bin", odir, nlayers);
      f = fopen(p, "wb");
      fwrite(x.map, 4, (size_t)M * D, f);
      fclose(f);
    }
  }
  return 0;
}
