// LFM2.5-2.6B on the Hexagon NPU: export_npu.py's graphs (w8a16, fp16 down projections) through npu/graph.cpp (ONNX
// Runtime's QNN execution provider, HTP backend). A C interface for lfm2/hybrid.mojo (NPU prefill, GPU decode) and,
// built with -DLFM2_NPU_MAIN, lfm2_npu: prefill and decode both on the NPU.
//
//   lfm2_npu <npu dir> <model.gguf> <max new> @<ids file>
//     NPU_RUNS=k            prefill k times (default 3): the first is cold; the decode starts from the last
//     LFM2_EOS=a,b          stop after one of these tokens
//     LFM2_LOGITS=<file>    the logits after the prompt and after generated tokens, appended (fp32)
//     LFM2_LOGITS_EVERY=k   only every k-th of those
//
// <npu dir> holds npu_w8.bin, export.py's manifest.txt (its npu storage), the compiled contexts p<i>_ctx.onnx,
// d<i>_ctx.onnx, head_ctx.onnx (graph_tool compile), and ../rope.f32. The prompt's embedding rows are the GGUF's
// Q6_K rows, dequantized here as ggml does. The prefill contexts and the decode contexts (3.4 GB each) do not fit in
// the phone's memory together, so the decode's are loaded after the prefill's are released (the handoff).
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

#include "../npu/graph.h"

namespace {

constexpr int D = 2048, V = 128000, KVH = 8, HD = 64;
constexpr float NEG = -30000.0f;

double now_ms() {
  return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

struct Graph {
  int h = -1;
  std::map<std::string, int> in, out;  // name -> index
  std::vector<std::vector<float>> outs;
  std::vector<const void*> args;
};

std::string dir_, err_;
int L = 0, R = 0, C = 0, P = 0;  // layers, prefill rows, decode cache slots, parts
std::vector<bool> attn_;
std::vector<float> rope_;  // [2048][64]: cos | sin of the first half
FILE* gguf_ = nullptr;
long long emb_off_ = 0;
std::vector<Graph> pre_, dec_;
Graph head_;
std::vector<float> x0_;          // the prefill's input rows [R][D]
int32_t sel_[2];
std::vector<std::vector<float>> kc_, vc_, st_;  // decode: caches [KVH][C][HD] (attention layers), conv states [2][D]
std::vector<float> logits_;

int fail(const std::string& s) {
  err_ = s + (npug_error() && *npug_error() ? std::string(": ") + npug_error() : "");
  return -1;
}

float half(const uint8_t* p) {
  __fp16 h;
  memcpy(&h, p, 2);
  return (float)h;
}

// A Q6_K row (8 super-blocks of 256) as ggml's dequantize_row_q6_K computes it.
int embed_row(int tok, float* y) {
  uint8_t b[8 * 210];
  if (fseeko(gguf_, emb_off_ + (long long)tok * sizeof b, SEEK_SET) || fread(b, 1, sizeof b, gguf_) != sizeof b)
    return fail("embedding row read");
  for (int s = 0; s < 8; s++) {
    const uint8_t *ql = b + s * 210, *qh = ql + 128;
    const int8_t* sc = (const int8_t*)(ql + 192);
    float d = half(ql + 208);
    float* o = y + s * 256;
    for (int n = 0; n < 256; n += 128) {
      for (int l = 0; l < 32; ++l) {
        int is = l / 16;
        o[l] = d * sc[is] * (float)((int)((ql[l] & 15) | (((qh[l] >> 0) & 3) << 4)) - 32);
        o[l + 32] = d * sc[is + 2] * (float)((int)((ql[l + 32] & 15) | (((qh[l] >> 2) & 3) << 4)) - 32);
        o[l + 64] = d * sc[is + 4] * (float)((int)((ql[l] >> 4) | (((qh[l] >> 4) & 3) << 4)) - 32);
        o[l + 96] = d * sc[is + 6] * (float)((int)((ql[l + 32] >> 4) | (((qh[l] >> 6) & 3) << 4)) - 32);
      }
      o += 128;
      ql += 64;
      qh += 32;
      sc += 8;
    }
  }
  return 0;
}

int open_graph(const std::string& name, Graph& g, double* ms) {
  double t = 0;
  g.h = npug_open((dir_ + "/" + name + "_ctx.onnx").c_str(), &t);
  if (g.h < 0) return fail("open " + name);
  if (ms) *ms += t;
  g.in.clear();
  g.out.clear();
  g.outs.clear();
  for (int i = 0; i < npug_count(g.h, 0); i++) g.in[npug_name(g.h, 0, i)] = i;
  for (int i = 0; i < npug_count(g.h, 1); i++) {
    g.out[npug_name(g.h, 1, i)] = i;
    g.outs.emplace_back(npug_numel(g.h, 1, i));
  }
  g.args.assign(npug_count(g.h, 0), nullptr);
  return 0;
}

int run_graph(Graph& g) {
  std::vector<float*> o;
  for (auto& v : g.outs) o.push_back(v.data());
  for (auto a : g.args)
    if (!a) return fail("an input not set");
  if (npug_run(g.h, g.args.data(), o.data(), nullptr)) return fail("run");
  return 0;
}

void set(Graph& g, const std::string& name, const void* p) {
  auto it = g.in.find(name);
  if (it != g.in.end()) g.args[it->second] = p;
}

float* out(Graph& g, const std::string& name) {
  auto it = g.out.find(name);
  return it == g.out.end() ? nullptr : g.outs[it->second].data();
}

}  // namespace

extern "C" {

const char* lfm2n_error() { return err_.c_str(); }
int lfm2n_rows() { return R; }

// dir: the npu directory (manifest.txt, contexts); gguf: the QAD Q4_0 GGUF (the embedding rows).
int lfm2n_open(const char* dir, const char* gguf, int rows, int slots, int parts) {
  dir_ = dir;
  R = rows;
  C = slots;
  P = parts;
  std::ifstream man(dir_ + "/manifest.txt");
  if (!man) return fail("no manifest.txt in " + dir_);
  std::string line;
  attn_.clear();
  while (std::getline(man, line)) {
    std::istringstream s(line);
    std::string a, b, c;
    s >> a >> b >> c;
    if (a == "layer") attn_.push_back(c == "attn");
    if (a == "embed_q6k") emb_off_ = std::stoll(b);
  }
  L = int(attn_.size());
  if (L == 0 || emb_off_ == 0) return fail("manifest.txt: no layers or no embed_q6k line");
  std::ifstream rf(dir_ + "/../rope.f32", std::ios::binary);
  rope_.assign(2048 * 64, 0);
  if (!rf.read((char*)rope_.data(), rope_.size() * 4)) return fail("rope.f32");
  gguf_ = fopen(gguf, "rb");
  if (!gguf_) return fail(std::string("cannot open ") + gguf);
  logits_.assign(V, 0);
  return 0;
}

int lfm2n_prefill_open(double* ms) {
  if (ms) *ms = 0;
  pre_.assign(P, Graph());
  for (int i = 0; i < P; i++)
    if (open_graph("p" + std::to_string(i), pre_[i], ms)) return -1;
  if (head_.h < 0 && open_graph("head", head_, ms)) return -1;
  return 0;
}

// The prompt's n tokens through the prefill parts and the head: K/V, conv states and the last row's logits.
int lfm2n_prefill(const int32_t* ids, int n, double* ms) {
  if (n < 2 || n > R) return fail("prompt length");
  double t0 = now_ms();
  x0_.assign((size_t)R * D, 0.f);
  for (int i = 0; i < n; i++)
    if (embed_row(ids[i], x0_.data() + (size_t)i * D)) return -1;
  sel_[0] = n - 2;
  sel_[1] = n - 1;
  const float* x = x0_.data();
  for (int i = 0; i < P; i++) {
    set(pre_[i], "x", x);
    set(pre_[i], "sel", sel_);
    if (run_graph(pre_[i])) return -1;
    x = pre_[i].outs[0].data();  // x_out, or the last part's xl
  }
  set(head_, "x", x);
  if (run_graph(head_)) return -1;
  memcpy(logits_.data(), head_.outs[0].data(), V * 4);
  if (ms) *ms = now_ms() - t0;
  return 0;
}

// After a prefill: layer l's K or V [KVH][R][HD] (attention layers), its conv state [2][D] (Bx at rows n - 2, n - 1),
// the last row's logits.
const float* lfm2n_k(int l) {
  for (auto& g : pre_)
    if (float* p = out(g, "k" + std::to_string(l))) return p;
  return nullptr;
}
const float* lfm2n_v(int l) {
  for (auto& g : pre_)
    if (float* p = out(g, "v" + std::to_string(l))) return p;
  return nullptr;
}
const float* lfm2n_state(int l) {
  for (auto& g : pre_)
    if (float* p = out(g, "s" + std::to_string(l))) return p;
  return nullptr;
}
const float* lfm2n_logits() { return logits_.data(); }

int lfm2n_prefill_close() {
  for (auto& g : pre_)
    if (g.h >= 0 && npug_close(g.h)) return fail("close");
  return 0;
}

int lfm2n_head_close() {
  if (head_.h >= 0 && npug_close(head_.h)) return fail("close");
  head_.h = -1;
  return 0;
}

// Decode: the decode parts (and the head), and the caches from the prefill's outputs (n prompt rows).
int lfm2n_decode_open(int n, double* ms) {
  if (ms) *ms = 0;
  dec_.assign(P, Graph());
  for (int i = 0; i < P; i++)
    if (open_graph("d" + std::to_string(i), dec_[i], ms)) return -1;
  if (head_.h < 0 && open_graph("head", head_, ms)) return -1;
  kc_.assign(L, {});
  vc_.assign(L, {});
  st_.assign(L, {});
  for (int l = 0; l < L; l++) {
    if (attn_[l]) {
      kc_[l].assign((size_t)KVH * C * HD, 0.f);
      vc_[l].assign((size_t)KVH * C * HD, 0.f);
      const float *k = lfm2n_k(l), *v = lfm2n_v(l);
      if (!k || !v) return fail("no prefill K/V");
      for (int g = 0; g < KVH; g++)
        for (int p = 0; p < n; p++) {
          memcpy(&kc_[l][((size_t)g * C + p) * HD], k + ((size_t)g * R + p) * HD, HD * 4);
          memcpy(&vc_[l][((size_t)g * C + p) * HD], v + ((size_t)g * R + p) * HD, HD * 4);
        }
    } else {
      const float* s = lfm2n_state(l);
      if (!s) return fail("no prefill conv state");
      st_[l].assign(s, s + 2 * D);
    }
  }
  return 0;
}

// The token at position pos through the decode parts and the head; returns its argmax (logits in lfm2n_logits()).
int lfm2n_step(int tok, int pos, double* ms) {
  if (pos >= C) return fail("past the cache");
  double t0 = now_ms();
  static std::vector<float> x(D), cs(32), sn(32), mask;
  mask.assign(C, NEG);
  for (int j = 0; j < pos; j++) mask[j] = 0;
  memcpy(cs.data(), &rope_[(size_t)pos * 64], 32 * 4);
  memcpy(sn.data(), &rope_[(size_t)pos * 64 + 32], 32 * 4);
  if (embed_row(tok, x.data())) return -1;
  const float* xi = x.data();
  for (auto& g : dec_) {
    set(g, "x", xi);
    set(g, "cos", cs.data());
    set(g, "sin", sn.data());
    set(g, "mask", mask.data());
    for (int l = 0; l < L; l++) {
      auto s = std::to_string(l);
      if (attn_[l]) {
        set(g, "kc" + s, kc_[l].data());
        set(g, "vc" + s, vc_[l].data());
      } else {
        set(g, "s" + s, st_[l].data());
      }
    }
    if (run_graph(g)) return -1;
    xi = g.outs[0].data();
  }
  set(head_, "x", xi);
  if (run_graph(head_)) return -1;
  memcpy(logits_.data(), head_.outs[0].data(), V * 4);
  for (auto& g : dec_)  // this position's K/V into the caches, the conv states one row on
    for (int l = 0; l < L; l++) {
      auto s = std::to_string(l);
      if (attn_[l]) {
        const float *k = out(g, "k" + s), *v = out(g, "v" + s);
        if (!k) continue;
        for (int h = 0; h < KVH; h++) {
          memcpy(&kc_[l][((size_t)h * C + pos) * HD], k + h * HD, HD * 4);
          memcpy(&vc_[l][((size_t)h * C + pos) * HD], v + h * HD, HD * 4);
        }
      } else if (const float* b = out(g, "b" + s)) {
        memcpy(st_[l].data(), st_[l].data() + D, D * 4);
        memcpy(st_[l].data() + D, b, D * 4);
      }
    }
  int best = 0;
  for (int i = 1; i < V; i++)
    if (logits_[i] > logits_[best]) best = i;
  if (ms) *ms = now_ms() - t0;
  return best;
}

}  // extern "C"

#ifdef LFM2_NPU_MAIN
int main(int argc, char** argv) {
  setvbuf(stdout, NULL, _IONBF, 0);
  if (argc < 5) {
    fprintf(stderr, "usage: lfm2_npu <npu dir> <model.gguf> <max new> @<ids file>\n");
    return 1;
  }
  std::vector<int32_t> ids;
  for (int a = 4; a < argc; a++) {
    if (argv[a][0] == '@') {
      std::ifstream f(argv[a] + 1);
      int v;
      while (f >> v) ids.push_back(v);
    } else {
      ids.push_back(atoi(argv[a]));
    }
  }
  int max_new = atoi(argv[3]);
  int n = int(ids.size());
  std::vector<int> eos;
  if (const char* e = getenv("LFM2_EOS")) {
    std::stringstream s(e);
    std::string t;
    while (std::getline(s, t, ',')) eos.push_back(atoi(t.c_str()));
  }
  const char* lpath = getenv("LFM2_LOGITS");
  int every = getenv("LFM2_LOGITS_EVERY") ? atoi(getenv("LFM2_LOGITS_EVERY")) : 1;
  int runs = getenv("NPU_RUNS") ? atoi(getenv("NPU_RUNS")) : 3;
  int rows = getenv("LFM2_ROWS") ? atoi(getenv("LFM2_ROWS")) : 416;
  int slots = getenv("LFM2_SLOTS") ? atoi(getenv("LFM2_SLOTS")) : 512;
  int parts = getenv("LFM2_PARTS") ? atoi(getenv("LFM2_PARTS")) : 5;
  if (n + max_new > slots) return fprintf(stderr, "prompt + new tokens > %d\n", slots), 1;
  if (lfm2n_open(argv[1], argv[2], rows, slots, parts)) return fprintf(stderr, "%s\n", lfm2n_error()), 1;
  double ms = 0;
  if (lfm2n_prefill_open(&ms)) return fprintf(stderr, "%s\n", lfm2n_error()), 1;
  printf("npu: prefill contexts loaded in %.2f s\n", ms / 1e3);
  double best = 1e30;
  for (int r = 0; r < runs; r++) {
    if (lfm2n_prefill(ids.data(), n, &ms)) return fprintf(stderr, "%s\n", lfm2n_error()), 1;
    if (r > 0 || runs == 1) best = std::min(best, ms);
    printf("prefill %d: %d tokens in %.1f ms (%.1f tokens/s)%s\n", r, n, ms, n * 1e3 / ms, r == 0 ? " cold" : "");
  }
  printf("prompt: %d tokens in %.1f ms ( %.1f tokens/s, NPU prefill, best warm )\n", n, best, n * 1e3 / best);
  int tok = 0;
  {
    const float* lg = lfm2n_logits();
    for (int i = 1; i < V; i++)
      if (lg[i] > lg[tok]) tok = i;
  }
  double t0 = now_ms(), open_ms = 0;
  if (lfm2n_prefill_close()) return fprintf(stderr, "%s\n", lfm2n_error()), 1;
  if (lfm2n_decode_open(n, &open_ms)) return fprintf(stderr, "%s\n", lfm2n_error()), 1;
  printf("handoff: prefill contexts released, decode contexts loaded and caches filled in %.2f s\n",
         (now_ms() - t0) / 1e3);
  FILE* lf = lpath ? fopen(lpath, "wb") : nullptr;
  double t_dec = 0;
  int gen = 0;
  double step_ms = best;
  for (int i = 0; i < max_new; i++) {
    if (lf && i % every == 0) fwrite(lfm2n_logits(), 4, V, lf);
    printf("tok %d %.2f\n", tok, step_ms);
    gen++;
    bool stop = i == max_new - 1;
    for (int e : eos) stop |= tok == e;
    if (stop) break;
    tok = lfm2n_step(tok, n + i, &step_ms);
    if (tok < 0) return fprintf(stderr, "%s\n", lfm2n_error()), 1;
    t_dec += step_ms;
  }
  if (lf) fclose(lf);
  if (gen > 1) printf("decode: %d steps, %.2f ms/token ( %.2f tokens/s )\n", gen - 1, t_dec / (gen - 1),
                      (gen - 1) * 1e3 / t_dec);
  fflush(stdout);
  _Exit(0);
}
#endif
