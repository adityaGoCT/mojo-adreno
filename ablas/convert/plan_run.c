// plan_run: runs a plan written by lt-convert (convert.py) on the Adreno 850 through AdrenoBLASLt (../lt/ablasLt.h).
//   plan_run -p model.plan [-w weights.bin] -t tokens.bin [-n N] [-g G] [-r R] [-b BUCKETS] [-o DIR] [-P] [-d]
// It knows no model. The plan (text, README.md) has a weights index into weights.bin, activation buffers of
// a*M + b bytes (M = the prompt's rows padded to its bucket), host steps (a RoPE table, embedding rows) and one
// AdrenoBLASLt call per line. plan_run allocates the buffers for the longest run, loads the weights (mmap, copied
// into host-visible Vulkan buffers), records the calls into one command buffer per prompt-length bucket on its
// first use (the calls that depend on T, the last token's 64-row tile: the LM head, into a second one per bucket
// and T), and replays them.
//   -n N      prefill the first N tokens of tokens.bin (int32 ids; default 512)
//   -g G      then predict G tokens greedily, each by prefilling again with it appended (no KV cache yet)
//   -r R      timed runs after a warm-up (default 3): GPU timestamps around the command buffer
//   -b LIST   prompt-length buckets, e.g. 512,1024,2048 (default: every multiple of 64)
//   -o DIR    DIR/logits.bin (the last token's) and DIR/hidden.bin (the hidden output, fp32 rows) for
//             ../llama3b/ref.py cmp
//   -P        a timestamp after every call: time per kind of call
//   -d        dry run: parse, check the weights file and print the calls for M = the prompt's bucket; no GPU
#include <ctype.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include "../llama3b/vkutil.h"  // first: VK_NO_PROTOTYPES
#include "../lt/ablasLt.h"

#define MAXW 2048
#define MAXB 64
#define MAXOPS 8192
#define DIE(...) do { fprintf(stderr, __VA_ARGS__); fputc('\n', stderr); exit(1); } while (0)

// a * M + b + c * T: M = the run's rows (the prompt padded to its bucket), T = the first row of the 64-row tile that
// holds the prompt's last token (the LM head's rows); T is set per run
typedef struct { int64_t a, b, c; } lin_t;
static uint32_t RT;
static int64_t ev(lin_t e, uint32_t M) { return e.a * (int64_t)M + e.b + e.c * (int64_t)RT; }

typedef struct {
  char name[96];
  ablasLtType type;  // F32 for vectors
  uint32_t rows, cols;
  ablasLtWeightUse use;
  uint64_t off, bytes;
  vbuf_t buf;
} weight_t;

typedef struct { char name[64]; int64_t per_m, fixed; int workspace; vbuf_t buf; } buffer_t;

enum { RK_NONE = 0, RK_BUF, RK_WEIGHT };  // what a ref names
typedef struct { int kind, idx; lin_t off; } ref_t;
typedef struct { int set; ablasLtType type; ablasLtOrder order; lin_t rows; uint32_t cols; } lay_t;

// operand keys (refs), integer keys (a*M + b) and float keys of a plan line
#define REF_KEYS(X) X(A) X(W) X(D) X(aux) X(rope) X(q) X(k) X(vt) X(bias) X(x) X(sumsq) X(weight) X(out) X(ws) \
  X(table) X(inv_freq)
#define INT_KEYS(X) X(M) X(cols) X(heads) X(kv_heads) X(head_dim) X(head_dim_valid) X(kv_rows) X(kv_offset) X(dim) \
  X(batches) X(kv_batch) X(keys) X(key_valid) X(suffix_base) X(suffix_count) X(suffix_causal) X(out_cols) X(key_splits)
#define ENUM_R(k) R_##k,
#define ENUM_I(k) I_##k,
#define NAME(k) #k,
enum { REF_KEYS(ENUM_R) NREF };
enum { INT_KEYS(ENUM_I) NINT };
static const char* ref_keys[] = {REF_KEYS(NAME)};
static const char* int_keys[] = {INT_KEYS(NAME)};

enum { OP_RMSNORM, OP_LAYERNORM, OP_MATMUL, OP_ATTENTION, OP_ATTENTION_MASKED, OP_EMBED, OP_ROPE_TABLE, NKINDS };
static const char* kinds[] = {"rmsnorm", "layernorm", "matmul", "attention", "attention_masked", "embed", "rope_table"};
static const char* epis[] = {"default", "residual", "swiglu", "rope_qkv", "geglu", "bias_gelu", "residual_bias"};

typedef struct {
  int kind, line, host;
  char label[40];  // kind, or matmul.<epilogue>: the profile's rows
  ablasLtEpilogue epi;
  ref_t r[NREF];
  lin_t i[NINT];
  lay_t a, d;
  float eps, scale;
} op_t;

static weight_t W[MAXW];
static buffer_t BUF[MAXB];
static op_t OPS[MAXOPS];
static int nw, nb, nops;
static struct { int set; int buf; lay_t lay; lin_t row0; } out_logits, out_hidden;
static char weights_file[512], wtype_name[16] = "?";
static uint64_t weights_total;
static vk_t v;
static ablasLtHandle lt;
static int dry;

// ---- plan parsing -----------------------------------------------------------------------------------------------

static lin_t parse_lin(const char* s, int line) {
  lin_t e = {0, 0, 0};
  const char* p = s;
  while (*p) {
    int64_t sign = 1, val = 1;
    int num = 0;
    if (*p == '+' || *p == '-') sign = *p++ == '-' ? -1 : 1;
    if (isdigit((unsigned char)*p)) val = strtoll(p, (char**)&p, 10), num = 1;
    if (*p == '*') ++p;
    if (*p == 'M') e.a += sign * val, ++p;
    else if (*p == 'T') e.c += sign * val, ++p;
    else if (num) e.b += sign * val;
    else DIE("plan line %d: bad expression '%s'", line, s);
  }
  return e;
}

static int find_buf(const char* name) {
  for (int i = 0; i < nb; ++i)
    if (!strcmp(BUF[i].name, name)) return i;
  return -1;
}
static int find_w(const char* name) {
  for (int i = 0; i < nw; ++i)
    if (!strcmp(W[i].name, name)) return i;
  return -1;
}

// "-", "name" or "name@expr" (a byte offset)
static ref_t parse_ref(const char* s, int line) {
  ref_t r = {RK_NONE, 0, {0, 0, 0}};
  if (!strcmp(s, "-")) return r;
  char name[96];
  const char* at = strchr(s, '@');
  size_t n = at ? (size_t)(at - s) : strlen(s);
  if (n >= sizeof name) DIE("plan line %d: name too long", line);
  memcpy(name, s, n), name[n] = 0;
  if (at) r.off = parse_lin(at + 1, line);
  if ((r.idx = find_buf(name)) >= 0) r.kind = RK_BUF;
  else if ((r.idx = find_w(name)) >= 0) r.kind = RK_WEIGHT;
  else DIE("plan line %d: no buffer or weight '%s'", line, name);
  return r;
}

static ablasLtType parse_type(const char* s, int line) {
  if (!strcmp(s, "f16")) return ABLASLT_F16;
  if (!strcmp(s, "f32")) return ABLASLT_F32;
  if (!strcmp(s, "q4_0")) return ABLASLT_Q4_0;
  DIE("plan line %d: type '%s'", line, s);
}

// type:order:rows:cols, order row | tiled
static lay_t parse_layout(const char* s, int line) {
  char t[16], o[16], rows[64];
  unsigned cols;
  if (sscanf(s, "%15[^:]:%15[^:]:%63[^:]:%u", t, o, rows, &cols) != 4) DIE("plan line %d: layout '%s'", line, s);
  lay_t l = {1, parse_type(t, line), ABLASLT_ORDER_ROW, parse_lin(rows, line), cols};
  if (!strcmp(o, "tiled")) l.order = ABLASLT_ORDER_TILED;
  else if (strcmp(o, "row")) DIE("plan line %d: order '%s'", line, o);
  return l;
}

static void parse_op(op_t* op, char** tok, int ntok, int line, int host) {
  memset(op, 0, sizeof *op);
  op->line = line, op->host = host, op->kind = -1;
  for (int k = 0; k < NKINDS; ++k)
    if (!strcmp(tok[1], kinds[k])) op->kind = k;
  if (op->kind < 0 || host != (op->kind >= OP_EMBED)) DIE("plan line %d: unknown %s '%s'", line, tok[0], tok[1]);
  snprintf(op->label, sizeof op->label, "%s", tok[1]);
  for (int t = 2; t < ntok; ++t) {
    char* eq = strchr(tok[t], '=');
    if (!eq) DIE("plan line %d: '%s' is not key=value", line, tok[t]);
    *eq = 0;
    const char *key = tok[t], *val = eq + 1;
    int done = 0;
    if (!strcmp(key, "epi")) {
      for (int e = 0; e < (int)(sizeof epis / sizeof *epis); ++e)
        if (!strcmp(val, epis[e])) op->epi = (ablasLtEpilogue)e, done = 1;
      if (!done) DIE("plan line %d: epilogue '%s'", line, val);
      snprintf(op->label, sizeof op->label, "matmul.%s", val);
    } else if (!strcmp(key, "a")) op->a = parse_layout(val, line), done = 1;
    else if (!strcmp(key, "d")) op->d = parse_layout(val, line), done = 1;
    else if (!strcmp(key, "eps")) op->eps = strtof(val, NULL), done = 1;
    else if (!strcmp(key, "scale")) op->scale = strtof(val, NULL), done = 1;
    else if (!strcmp(key, "D") && op->kind != OP_MATMUL) op->i[I_cols] = parse_lin(val, line), done = 1;  // norms' D
    for (int k = 0; !done && k < NREF; ++k)
      if (!strcmp(key, ref_keys[k])) op->r[k] = parse_ref(val, line), done = 1;
    for (int k = 0; !done && k < NINT; ++k)
      if (!strcmp(key, int_keys[k])) op->i[k] = parse_lin(val, line), done = 1;
    if (!done) DIE("plan line %d: unknown key '%s'", line, key);
  }
}

static void load_plan(const char* path) {
  FILE* f = fopen(path, "r");
  if (!f) DIE("cannot open %s", path);
  char line[4096];
  int ln = 0, version = -1;
  while (fgets(line, sizeof line, f)) {
    ++ln;
    char* tok[64];
    int n = 0;
    char* sp;
    for (char* p = strtok_r(line, " \t\r\n", &sp); p && n < 64; p = strtok_r(NULL, " \t\r\n", &sp)) tok[n++] = p;
    if (!n || tok[0][0] == '#') continue;
    if (!strcmp(tok[0], "ltplan")) {
      version = atoi(tok[1]);
      if (version != 0) DIE("%s: plan version %d, this plan_run reads 0", path, version);
    } else if (version < 0) {
      DIE("%s: not a plan (no ltplan line first)", path);
    } else if (!strcmp(tok[0], "model")) {  // informational, but for the weights' type in the RESULT line
      for (int t = 1; t < n; ++t)
        if (!strncmp(tok[t], "wtype=", 6)) snprintf(wtype_name, sizeof wtype_name, "%s", tok[t] + 6);
    } else if (!strcmp(tok[0], "weights") && n == 3) {
      snprintf(weights_file, sizeof weights_file, "%s", tok[1]);
      weights_total = strtoull(tok[2], NULL, 10);
    } else if (!strcmp(tok[0], "weight") && n == 8) {
      if (nw == MAXW) DIE("too many weights");
      weight_t* w = &W[nw++];
      snprintf(w->name, sizeof w->name, "%s", tok[1]);
      w->type = parse_type(tok[2], ln), w->rows = atoi(tok[3]), w->cols = atoi(tok[4]);
      w->use = !strcmp(tok[5], "gate_up") ? ABLASLT_WEIGHT_GATE_UP : ABLASLT_WEIGHT_PLAIN;
      w->off = strtoull(tok[6], NULL, 10), w->bytes = strtoull(tok[7], NULL, 10);
      uint64_t want = w->type == ABLASLT_F32 ? (uint64_t)w->rows * w->cols * 4 : ablasLtWeightSize(w->type, w->rows, w->cols);
      if (w->bytes != want) DIE("plan line %d: %s has %llu bytes, its format %llu", ln, w->name,
                                (unsigned long long)w->bytes, (unsigned long long)want);
    } else if (!strcmp(tok[0], "buffer") && n == 4) {
      if (nb == MAXB) DIE("too many buffers");
      buffer_t* b = &BUF[nb++];
      snprintf(b->name, sizeof b->name, "%s", tok[1]);
      b->per_m = strtoll(tok[2], NULL, 10), b->fixed = strtoll(tok[3], NULL, 10);
    } else if (!strcmp(tok[0], "workspace") && n == 2) {
      if (nb == MAXB) DIE("too many buffers");
      snprintf(BUF[nb].name, sizeof BUF[nb].name, "%s", tok[1]);
      BUF[nb++].workspace = 1;
    } else if ((!strcmp(tok[0], "call") || !strcmp(tok[0], "host")) && n >= 2) {
      if (nops == MAXOPS) DIE("too many calls");
      parse_op(&OPS[nops++], tok, n, ln, !strcmp(tok[0], "host"));
    } else if (!strcmp(tok[0], "output") && n >= 3) {
      int is_logits = !strcmp(tok[1], "logits");
      if (!is_logits && strcmp(tok[1], "hidden")) DIE("plan line %d: output '%s'", ln, tok[1]);
      __typeof__(out_logits)* o = is_logits ? &out_logits : &out_hidden;
      o->set = 1;
      for (int t = 2; t < n; ++t) {
        char* eq = strchr(tok[t], '=');
        if (!eq) DIE("plan line %d: '%s'", ln, tok[t]);
        *eq = 0;
        if (!strcmp(tok[t], "buf")) { if ((o->buf = find_buf(eq + 1)) < 0) DIE("plan line %d: buffer %s", ln, eq + 1); }
        else if (!strcmp(tok[t], "layout")) o->lay = parse_layout(eq + 1, ln);
        else if (!strcmp(tok[t], "row0")) o->row0 = parse_lin(eq + 1, ln);
        else DIE("plan line %d: output key '%s'", ln, tok[t]);
      }
    } else {
      DIE("plan line %d: cannot read '%s'", ln, tok[0]);
    }
  }
  fclose(f);
  if (version < 0) DIE("%s: empty plan", path);
}

// ---- operands ---------------------------------------------------------------------------------------------------

static ablas_buf R(const ref_t* r, uint32_t M) {
  if (r->kind == RK_NONE) return (ablas_buf){0};
  VkBuffer b = r->kind == RK_BUF ? BUF[r->idx].buf.buf : W[r->idx].buf.buf;
  return (ablas_buf){b, (VkDeviceSize)ev(r->off, M), 0};
}
static void* host_ptr(const ref_t* r, uint32_t M) {
  void* base = r->kind == RK_BUF ? BUF[r->idx].buf.map : W[r->idx].buf.map;
  return (uint8_t*)base + ev(r->off, M);
}
static ablasLtLayout L(const lay_t* l, uint32_t M) {
  return (ablasLtLayout){l->type, l->order, (uint32_t)ev(l->rows, M), l->cols, ABLASLT_WEIGHT_PLAIN};
}
static ablasLtLayout WL(const ref_t* r) {
  if (r->kind != RK_WEIGHT) DIE("matmul W is not a weight");
  const weight_t* w = &W[r->idx];
  return (ablasLtLayout){w->type, ABLASLT_ORDER_WEIGHT, w->rows, w->cols, w->use};
}
#define IV(op, k) ((uint32_t)ev((op)->i[I_##k], M))

static void matmul_desc(const op_t* op, uint32_t M, ablasLtMatmulDesc* d) {
  memset(d, 0, sizeof *d);
  d->epilogue = op->epi, d->aux = R(&op->r[R_aux], M), d->rope = R(&op->r[R_rope], M);
  d->q = R(&op->r[R_q], M), d->k = R(&op->r[R_k], M), d->vt = R(&op->r[R_vt], M), d->bias = R(&op->r[R_bias], M);
  d->n_heads = IV(op, heads), d->n_kv_heads = IV(op, kv_heads), d->head_dim = IV(op, head_dim);
  d->head_dim_valid = IV(op, head_dim_valid), d->kv_rows = IV(op, kv_rows), d->kv_offset = IV(op, kv_offset);
}

static void attn_desc(const op_t* op, uint32_t M, ablasLtAttentionDesc* d) {
  memset(d, 0, sizeof *d);
  d->M = IV(op, M), d->batches = IV(op, batches), d->n_heads = IV(op, heads), d->n_kv_heads = IV(op, kv_heads);
  d->head_dim = IV(op, head_dim), d->head_dim_valid = IV(op, head_dim_valid), d->kv_rows = IV(op, kv_rows);
  d->kv_batch = IV(op, kv_batch), d->keys = IV(op, keys), d->key_valid = IV(op, key_valid);
  d->suffix_base = IV(op, suffix_base), d->suffix_count = IV(op, suffix_count), d->suffix_causal = IV(op, suffix_causal);
  d->scale = op->scale, d->out_cols = IV(op, out_cols), d->key_splits = IV(op, key_splits);
  d->workspace = R(&op->r[R_ws], M);
}

// Workspace bytes an operation needs at M (0 when it is given none).
static size_t workspace_bytes(const op_t* op, uint32_t M) {
  if (op->r[R_ws].kind == RK_NONE) return 0;
  switch (op->kind) {
  case OP_RMSNORM: return ablasLtRmsNormWorkspaceSize(IV(op, M));
  case OP_LAYERNORM: return ablasLtLayerNormWorkspaceSize(IV(op, M));
  case OP_MATMUL: {
    ablasLtMatmulDesc d;
    matmul_desc(op, M, &d);
    ablasLtLayout a = L(&op->a, M), w = WL(&op->r[R_W]), dl = L(&op->d, M);
    return ablasLtMatmulWorkspaceSize(&d, &a, &w, op->d.set ? &dl : NULL);
  }
  case OP_ATTENTION_MASKED: {
    ablasLtAttentionDesc d;
    attn_desc(op, M, &d);
    return ablasLtAttentionWorkspaceSize(&d);
  }
  default: return 0;
  }
}

// ---- recording ----------------------------------------------------------------------------------------------------

static ablas_status record_op(VkCommandBuffer c, const op_t* op, uint32_t M) {
  const ref_t* r = op->r;
  switch (op->kind) {
  case OP_RMSNORM:
    return ablasLtRmsNorm(lt, c, IV(op, M), IV(op, cols), R(&r[R_x], M), R(&r[R_sumsq], M), R(&r[R_weight], M), op->eps,
                          R(&r[R_out], M), R(&r[R_ws], M));
  case OP_LAYERNORM:
    return ablasLtLayerNorm(lt, c, IV(op, M), IV(op, cols), R(&r[R_x], M), R(&r[R_weight], M), R(&r[R_bias], M),
                            op->eps, R(&r[R_out], M), R(&r[R_ws], M));
  case OP_MATMUL: {
    ablasLtMatmulDesc d;
    matmul_desc(op, M, &d);
    ablasLtLayout a = L(&op->a, M), w = WL(&r[R_W]), dl = L(&op->d, M);
    return ablasLtMatmul(lt, c, &d, R(&r[R_A], M), &a, R(&r[R_W], M), &w, R(&r[R_D], M), op->d.set ? &dl : NULL,
                         R(&r[R_ws], M));
  }
  case OP_ATTENTION:
    return ablasLtAttention(lt, c, IV(op, M), IV(op, heads), IV(op, kv_heads), op->scale, R(&r[R_q], M), R(&r[R_k], M),
                            R(&r[R_vt], M), R(&r[R_out], M));
  case OP_ATTENTION_MASKED: {
    ablasLtAttentionDesc d;
    attn_desc(op, M, &d);
    return ablasLtAttentionMasked(lt, c, &d, R(&r[R_q], M), R(&r[R_k], M), R(&r[R_vt], M), R(&r[R_out], M));
  }
  }
  return ABLAS_BAD_SHAPE;
}

// The calls that use T, and every call after the first of them, form the tail: recorded per (M, T) into a second
// command buffer, so that the body is one command buffer per bucket whatever the prompt's length within it.
static int first_tail;
static int uses_t(const op_t* op) {
  int t = op->a.rows.c || op->d.rows.c;
  for (int k = 0; k < NREF; ++k) t |= op->r[k].off.c != 0;
  for (int k = 0; k < NINT; ++k) t |= op->i[k].c != 0;
  return t;
}

// Calls [from, to) at M into c. Queries: 0 before the first call (in the body), with `profile` i + 1 after call i,
// else 1 after the last (in the tail, or in the body when there is none).
static void record(VkCommandBuffer c, int from, int to, uint32_t M, int profile) {
  vk_begin(c);
  uint32_t q = 1;
  for (int i = 0; i < from; ++i) q += !OPS[i].host;
  if (!from) {
    vkCmdResetQueryPool(c, v.qp, 0, v.nq);
    vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, v.qp, 0);
  }
  for (int i = from; i < to; ++i) {
    if (OPS[i].host) continue;
    ablas_status s = record_op(c, &OPS[i], M);
    if (s) DIE("plan line %d (%s, M = %u, T = %u): AdrenoBLASLt status %d", OPS[i].line, OPS[i].label, M, RT, s);
    if (profile) vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, q++);
  }
  if (!profile && to == nops) vkCmdWriteTimestamp(c, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, v.qp, 1);
  CK(vkEndCommandBuffer(c));
}

// Body then tail in one submission (the body's last call ends with a barrier, which orders it before the tail)
static void submit(VkCommandBuffer body, VkCommandBuffer tail) {
  VkCommandBuffer cb[2] = {body, tail};
  VkSubmitInfo si = {VK_STRUCTURE_TYPE_SUBMIT_INFO, NULL, 0, NULL, NULL, tail ? 2 : 1, cb};
  CK(vkQueueSubmit(v.queue, 1, &si, VK_NULL_HANDLE));
  CK(vkQueueWaitIdle(v.queue));
}

// ---- host steps -------------------------------------------------------------------------------------------------------

// RoPE table for positions [0, rows): cos(p * f) | sin(p * f) per row, as ../lt/llama_lt.c computes it
static void rope_table(const op_t* op, uint32_t rows) {
  uint32_t dim = (uint32_t)ev(op->i[I_dim], rows), half = dim / 2;
  const weight_t* f = &W[op->r[R_inv_freq].idx];
  if (op->r[R_inv_freq].kind != RK_WEIGHT || f->type != ABLASLT_F32 || f->rows * f->cols != half)
    DIE("plan line %d: inv_freq must be %u fp32 values", op->line, half);
  const float* inv = f->buf.map;
  float* cs = host_ptr(&op->r[R_out], rows);
  for (uint32_t p = 0; p < rows; ++p)
    for (uint32_t i = 0; i < half; ++i) {
      float a = (float)p * inv[i];
      cs[(size_t)p * dim + i] = cosf(a), cs[(size_t)p * dim + half + i] = sinf(a);
    }
}

// Embedding rows of the prompt into M rows (padding rows repeat the last token)
static void embed(const op_t* op, const int32_t* tokens, uint32_t len, uint32_t M) {
  const weight_t* t = &W[op->r[R_table].idx];
  if (op->r[R_table].kind != RK_WEIGHT || t->type == ABLASLT_F32 || t->use != ABLASLT_WEIGHT_PLAIN)
    DIE("plan line %d: embed needs a packed plain weight", op->line);
  float* x = host_ptr(&op->r[R_out], M);
  for (uint32_t r = 0; r < M; ++r) {
    int32_t id = tokens[r < len ? r : len - 1];
    if (id < 0 || (uint32_t)id >= t->rows) DIE("token %d out of the table's %u rows", id, t->rows);
    ablasLtWeightRow(t->type, t->buf.map, t->rows, t->cols, (uint32_t)id, x + (size_t)r * t->cols);
  }
}

// ---- main -------------------------------------------------------------------------------------------------------------

static uint32_t buckets[256];
static int nbuckets;
static uint32_t bucket(uint32_t len) {
  if (!nbuckets) return (len + 63) / 64 * 64;
  for (int i = 0; i < nbuckets; ++i)
    if (buckets[i] >= len) return buckets[i];
  DIE("no bucket holds %u tokens", len);
}

static const char* tname(ablasLtType t) { return t == ABLASLT_F16 ? "f16" : t == ABLASLT_F32 ? "f32" : "q4_0"; }

static void print_ref(const char* key, const ref_t* r, uint32_t M) {
  if (r->kind == RK_NONE) return;
  const char* name = r->kind == RK_BUF ? BUF[r->idx].name : W[r->idx].name;
  int64_t off = ev(r->off, M);
  if (off) printf(" %s=%s+%lld", key, name, (long long)off);
  else printf(" %s=%s", key, name);
}

static void dry_print(uint32_t M) {
  printf("calls at M = %u:\n", M);
  for (int i = 0; i < nops; ++i) {
    const op_t* op = &OPS[i];
    printf("%4d %-18s", op->line, op->label);
    for (int k = 0; k < NREF; ++k) print_ref(ref_keys[k], &op->r[k], M);
    for (int k = 0; k < NINT; ++k)
      if (ev(op->i[k], M)) printf(" %s=%lld", int_keys[k], (long long)ev(op->i[k], M));
    if (op->a.set) printf(" a=%s:%s:%lld:%u", tname(op->a.type), op->a.order ? "tiled" : "row", (long long)ev(op->a.rows, M), op->a.cols);
    if (op->d.set) printf(" d=%s:%s:%lld:%u", tname(op->d.type), op->d.order ? "tiled" : "row", (long long)ev(op->d.rows, M), op->d.cols);
    if (op->eps) printf(" eps=%g", op->eps);
    if (op->scale) printf(" scale=%.9g", op->scale);
    size_t ws = op->host ? 0 : workspace_bytes(op, M);
    if (ws) printf(" [workspace %zu]", ws);
    putchar('\n');
  }
}

int main(int argc, char** argv) {
  setvbuf(stdout, NULL, _IOLBF, 0);
  const char *ppath = NULL, *wpath = NULL, *tpath = "tokens.bin", *odir = NULL;
  uint32_t n = 512, gen = 0;
  int reps = 3, profile = 0;
  for (int i = 1; i < argc; ++i) {
    if (!strcmp(argv[i], "-p") && i + 1 < argc) ppath = argv[++i];
    else if (!strcmp(argv[i], "-w") && i + 1 < argc) wpath = argv[++i];
    else if (!strcmp(argv[i], "-t") && i + 1 < argc) tpath = argv[++i];
    else if (!strcmp(argv[i], "-n") && i + 1 < argc) n = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-g") && i + 1 < argc) gen = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-r") && i + 1 < argc) reps = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-o") && i + 1 < argc) odir = argv[++i];
    else if (!strcmp(argv[i], "-P")) profile = 1;
    else if (!strcmp(argv[i], "-d")) dry = 1;
    else if (!strcmp(argv[i], "-b") && i + 1 < argc) {
      char* sp;
      for (char* s = strtok_r(argv[++i], ",", &sp); s && nbuckets < 256; s = strtok_r(NULL, ",", &sp)) buckets[nbuckets++] = atoi(s);
      for (int a = 0; a < nbuckets; ++a)
        for (int b = a + 1; b < nbuckets; ++b)
          if (buckets[b] < buckets[a]) { uint32_t t = buckets[a]; buckets[a] = buckets[b]; buckets[b] = t; }
      for (int a = 0; a < nbuckets; ++a)
        if (!buckets[a] || buckets[a] % 64) DIE("buckets must be multiples of 64");
    } else DIE("usage: plan_run -p model.plan [-w weights.bin] -t tokens.bin [-n N] [-g G] [-r R] [-b 512,1024] [-o DIR] [-P] [-d]");
  }
  if (!ppath) DIE("plan_run: -p model.plan is required");
  load_plan(ppath);
  char wbuf[1024];
  if (!wpath) {  // the plan's weights file, next to the plan
    const char* slash = strrchr(ppath, '/');
    snprintf(wbuf, sizeof wbuf, "%.*s%s", slash ? (int)(slash - ppath + 1) : 0, ppath, weights_file);
    wpath = wbuf;
  }
  int calls = 0;
  for (int i = 0; i < nops; ++i) calls += !OPS[i].host;

  // the prompt
  size_t tb;
  int32_t* file_tokens = read_file(tpath, &tb);
  if (tb / 4 < n || n < 1) DIE("%s: need at least %u tokens", tpath, n);
  uint32_t Mmax = bucket(n + gen);
  int32_t* tokens = calloc(Mmax, 4);
  memcpy(tokens, file_tokens, (size_t)n * 4);

  // weights: mapped, checked against the index
  int fd = open(wpath, O_RDONLY);
  if (fd < 0) DIE("cannot open %s", wpath);
  struct stat st;
  fstat(fd, &st);
  if ((uint64_t)st.st_size != weights_total) DIE("%s: %lld bytes, the plan says %llu", wpath, (long long)st.st_size,
                                                 (unsigned long long)weights_total);
  for (int i = 0; i < nw; ++i)
    if (W[i].off + W[i].bytes > weights_total) DIE("weight %s past the end of %s", W[i].name, wpath);
  printf("plan %s: %d weights (%.3f GB), %d buffers, %d calls; prompt %u tokens, rows up to %u\n", ppath, nw,
         weights_total / 1e9, nb, calls, n, Mmax);

  if (dry) {  // fake handles: nothing reaches Vulkan, the library's size queries only test them for null
    for (int i = 0; i < nb; ++i) BUF[i].buf.buf = (VkBuffer)(uintptr_t)(i + 1);
    for (int i = 0; i < nw; ++i) W[i].buf.buf = (VkBuffer)(uintptr_t)(1000 + i);
    size_t ws = 0;
    for (int i = 0; i < nops; ++i) {
      size_t s = OPS[i].host ? 0 : workspace_bytes(&OPS[i], Mmax);
      ws = s > ws ? s : ws;
    }
    for (int i = 0; i < nb; ++i)
      printf("buffer %-8s %12lld bytes\n", BUF[i].name,
             BUF[i].workspace ? (long long)ws : (long long)(BUF[i].per_m * Mmax + BUF[i].fixed));
    RT = (n - 1) / 64 * 64;
    dry_print(bucket(n));
    return 0;
  }

  vk_init(&v, profile ? (uint32_t)calls + 1 : 2);
  ablas_handle ab;
  if (ablas_create(&ab, v.pd, v.dev, v.gipa, v.inst) || ablasLtCreate(&lt, ab, v.dev, v.gipa, v.inst, 0))
    DIE("AdrenoBLAS: no device support");
  double t0 = now_ms();
  const uint8_t* map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
  if (map == MAP_FAILED) DIE("mmap %s failed", wpath);
  for (int i = 0; i < nw; ++i) {
    W[i].buf = vk_buffer(&v, W[i].bytes);
    memcpy(W[i].buf.map, map + W[i].off, W[i].bytes);
  }
  munmap((void*)map, st.st_size);
  close(fd);
  printf("device %s, weights loaded in %.1f s\n", v.name, (now_ms() - t0) / 1e3);

  // buffers for the longest run, then the workspace the calls ask for (at every bucket up to it)
  for (int i = 0; i < nb; ++i)
    if (!BUF[i].workspace) BUF[i].buf = vk_buffer(&v, (size_t)(BUF[i].per_m * Mmax + BUF[i].fixed));
  size_t wsz = 256;
  for (uint32_t M = 64; M <= Mmax; M += 64)
    for (int i = 0; i < nops; ++i) {
      size_t s = OPS[i].host ? 0 : workspace_bytes(&OPS[i], M);
      wsz = s > wsz ? s : wsz;
    }
  for (int i = 0; i < nb; ++i)
    if (BUF[i].workspace) BUF[i].buf = vk_buffer(&v, wsz);
  for (int i = 0; i < nops; ++i)
    if (OPS[i].kind == OP_ROPE_TABLE) rope_table(&OPS[i], Mmax);

  first_tail = nops;
  for (int i = nops - 1; i >= 0; --i)
    if (!OPS[i].host && uses_t(&OPS[i])) first_tail = i;
  for (int i = first_tail; i < nops; ++i)
    if (OPS[i].host) DIE("plan line %d: a host step after a call that depends on T", OPS[i].line);
  // command buffers recorded on first use: the body per bucket, the tail per (bucket, T)
  uint32_t nm = Mmax / 64 + 1;
  VkCommandBuffer *cmds = calloc(nm, sizeof *cmds), *tails = calloc((size_t)nm * nm, sizeof *tails);
  int recorded = 0, recorded_tails = 0;
  uint32_t len = n;
  for (uint32_t step = 0; step <= gen; ++step) {
    uint32_t M = bucket(len);
    RT = (len - 1) / 64 * 64;
    VkCommandBuffer c = cmds[M / 64], tail = first_tail < nops ? tails[M / 64 * nm + RT / 64] : NULL;
    if (!c) {
      double tr = now_ms();
      c = cmds[M / 64] = vk_cmd(&v);
      record(c, 0, first_tail, M, profile);
      ++recorded;
      if (!step) printf("recorded %d calls for %u rows in %.1f ms\n", calls, M, now_ms() - tr);
    }
    if (first_tail < nops && !tail) {
      tail = tails[M / 64 * nm + RT / 64] = vk_cmd(&v);
      record(tail, first_tail, nops, M, profile);
      ++recorded_tails;
    }
    double best = 1e30;
    for (int rep = 0; rep < (step ? 1 : reps + 1); ++rep) {  // the first prompt: a warm-up, then `reps` timed runs
      for (int i = 0; i < nops; ++i)
        if (OPS[i].kind == OP_EMBED) embed(&OPS[i], tokens, len, M);
      submit(c, tail);
      uint64_t ts[MAXOPS + 2];
      uint32_t nq = profile ? (uint32_t)calls + 1 : 2;
      CK(vkGetQueryPoolResults(v.dev, v.qp, 0, nq, nq * 8, ts, 8, VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT));
      double ms = (ts[nq - 1] - ts[0]) * v.ts_ns * 1e-6;
      if (!step && rep) printf("prefill %u tokens (%u rows): %.2f ms, %.1f tok/s\n", len, M, ms, len / ms * 1e3);
      if (rep || step) best = ms < best ? ms : best;
      if (profile && !step && rep == reps) {  // the last timed run, by kind of call
        double by[64] = {0};
        int cnt[64] = {0}, nl = 0;
        const char* labels[64];
        uint32_t qi = 1;
        for (int i = 0; i < nops; ++i) {
          if (OPS[i].host) continue;
          int j = 0;
          while (j < nl && strcmp(labels[j], OPS[i].label)) ++j;
          if (j == nl && nl < 64) labels[nl++] = OPS[i].label;
          by[j] += (ts[qi] - ts[qi - 1]) * v.ts_ns * 1e-6, ++cnt[j], ++qi;
        }
        for (int j = 0; j < nl; ++j)
          printf("  %-20s %4d calls %8.2f ms %5.1f%%\n", labels[j], cnt[j], by[j], 100 * by[j] / ms);
      }
    }
    if (!out_logits.set) DIE("the plan has no logits output");
    const buffer_t* lb = &BUF[out_logits.buf];
    uint32_t V = out_logits.lay.cols;
    int64_t row = (int64_t)len - 1 - ev(out_logits.row0, M);
    if (row < 0 || row >= ev(out_logits.lay.rows, M)) DIE("the last token is not in the logits rows");
    const float* lg = (const float*)lb->buf.map + (size_t)row * V;
    uint32_t next = 0;
    for (uint32_t i = 1; i < V; ++i)
      if (lg[i] > lg[next]) next = i;
    if (!step) {
      printf("RESULT plan %s prefill %u tokens: best %.2f ms (%.1f tok/s); next token %u\n", wtype_name, len, best,
             len / best * 1e3, next);
      if (odir) {
        char p[512];
        snprintf(p, sizeof p, "%s/logits.bin", odir);
        FILE* f = fopen(p, "wb");
        if (!f) DIE("cannot write %s", p);
        fwrite(lg, 4, V, f);
        fclose(f);
        if (out_hidden.set) {
          const lay_t* hl = &out_hidden.lay;
          uint32_t rows = (uint32_t)ev(hl->rows, M), D = hl->cols;
          const uint8_t* base = BUF[out_hidden.buf].buf.map;
          float* hid = malloc((size_t)len * D * 4);
          for (uint32_t r = 0; r < len; ++r) {
            if (hl->order == ABLASLT_ORDER_TILED) ablasLtWeightRow(ABLASLT_F16, base, rows, D, r, hid + (size_t)r * D);
            else memcpy(hid + (size_t)r * D, base + (size_t)r * D * 4, (size_t)D * 4);
          }
          snprintf(p, sizeof p, "%s/hidden.bin", odir);
          f = fopen(p, "wb");
          fwrite(hid, 4, (size_t)len * D, f);
          fclose(f);
          free(hid);
        }
        printf("wrote %s/logits.bin%s\n", odir, out_hidden.set ? ", hidden.bin" : "");
      }
    } else {
      printf("token %u: %u (%.1f ms)\n", step, next, best);
    }
    if (step < gen) tokens[len++] = (int32_t)next;
  }
  printf("command buffers recorded: %d bodies (one per bucket), %d tails (per bucket and last-token tile)\n", recorded,
         recorded_tails);
  return 0;
}
