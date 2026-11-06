// π0's Gemma 2B prefix on the Hexagon NPU (HTP), through ONNX Runtime's QNN execution provider: the graphs of
// npu/export_pi0.py, run one after another. A C interface for pi0/pi0npu.mojo, which hands each layer's K/V to the
// GPU expert's cache; and pi0npu_tool (built with -DNPU_TOOL), which compiles, times and dumps on its own.
//
// pi0npu_open loads <dir>/part<i>_ctx.onnx, the HTP context binary that pi0npu_compile (pi0npu_tool compile <dir> <i>)
// saved, a part a process, as npu/npu_prefill.cpp does for Llama: compiling holds several copies of a part's weights.
// Inputs and outputs are bound once to fixed host buffers: each part's x (part i's x_out is part i+1's x), the shared
// cos, sin and mask, and every layer's K and V. Environment:
//   NPU_LOG=v           ONNX Runtime's verbose log (which nodes QNN takes, and why not)
//   NPU_FALLBACK=1      allow nodes on the CPU (otherwise every node must run on the HTP)
//   NPU_OPT=<0..3>      QNN's graph finalization optimization mode (default 3, the slowest compile)
//   NPU_UDMA=1          QNN's extended UDMA mode
//
// It also builds for Windows on ARM (a Snapdragon X2 Elite laptop's Hexagon NPU, the same V81 HTP), with Zig's clang
// for aarch64-windows-gnu against ONNX Runtime's QNN NuGet package: npu/build_win.sh.
#include "pi0_prefix.h"

#include <onnxruntime_cxx_api.h>

#include <sys/stat.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <mutex>
#include <string>
#include <thread>
#include <tuple>
#include <unordered_map>
#include <vector>

namespace {

constexpr int D = 2048, L = 18, HD = 256, MAXPOS = 1024;

double now_ms() {
  return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

bool exists(const std::string& p) {
  struct stat st;
  return stat(p.c_str(), &st) == 0;
}

#ifdef _WIN32
constexpr const char* QNN_HTP = "QnnHtp.dll";

std::string exe_dir() {
  char buf[4096];
  DWORD n = GetModuleFileNameA(nullptr, buf, sizeof buf);
  std::string s(buf, n);
  return s.substr(0, s.find_last_of("\\/"));
}

std::wstring ort_path(const std::string& p) { return std::wstring(p.begin(), p.end()); }  // ASCII paths
#else
constexpr const char* QNN_HTP = "libQnnHtp.so";

std::string exe_dir() {
  char buf[4096];
  ssize_t n = readlink("/proc/self/exe", buf, sizeof buf - 1);
  if (n <= 0) return ".";
  buf[n] = 0;
  std::string s(buf);
  return s.substr(0, s.rfind('/'));
}

const std::string& ort_path(const std::string& p) { return p; }
#endif

void dsp_path() {  // where the DSP side looks for libQnnHtpV81Skel.so (on Windows: next to the stub DLL)
#ifndef _WIN32
  if (getenv("ADSP_LIBRARY_PATH")) return;
  std::string p = exe_dir() + ";/vendor/dsp/cdsp;/vendor/lib/rfsa/adsp;/system/lib/rfsa/adsp;/dsp";
  setenv("ADSP_LIBRARY_PATH", p.c_str(), 1);
#endif
}

struct Npu {
  Ort::Env env{nullptr};
  std::vector<Ort::Session> parts;
  std::vector<Ort::IoBinding> bindings;
  std::vector<std::vector<Ort::Value>> values;  // the tensors each binding refers to
  int rows = 0, nparts = 0;
  std::vector<int> bounds;                      // part i: layers bounds[i] .. bounds[i+1]-1
  std::vector<std::vector<__fp16>> x;           // x[i]: part i's input [rows, 2048]
  std::vector<__fp16> cos, sin, mask;           // [rows, 1, 256] twice, [1, rows]
  std::vector<std::vector<__fp16>> k, v;        // [layer][rows * 256]
  std::string error;
  std::thread worker;  // a prefix's parts, one after another (pi0npu_start)
  std::mutex mu;
  std::condition_variable cv;
  int parts_done = 0;  // under mu
  std::string run_error;
  double t_start = 0, run_ms = 0;
};

Npu* g = nullptr;

void ORT_API_CALL log_line(void*, OrtLoggingLevel severity, const char*, const char*, const char* code_location,
                           const char* message) {
  fprintf(stderr, "[ort %d] %s %s\n", int(severity), code_location, message);
}

int fail(const std::string& msg) {
  if (g) g->error = msg;
  fprintf(stderr, "pi0npu: %s\n", msg.c_str());
  return -1;
}

Ort::SessionOptions options(const std::string& ctx_out) {
  Ort::SessionOptions so;
  so.SetIntraOpNumThreads(1);
  const char* opt = getenv("NPU_OPT");
  std::unordered_map<std::string, std::string> qnn = {
      {"backend_path", exe_dir() + "/" + QNN_HTP},
      {"htp_performance_mode", "burst"},
      {"htp_graph_finalization_optimization_mode", opt ? opt : "3"},
  };
  if (getenv("NPU_UDMA")) qnn["extended_udma"] = "1";
  so.AppendExecutionProvider("QNN", qnn);
  if (!getenv("NPU_FALLBACK")) so.AddConfigEntry("session.disable_cpu_ep_fallback", "1");
  if (!ctx_out.empty()) {
    so.AddConfigEntry("ep.context_enable", "1");
    so.AddConfigEntry("ep.context_file_path", ctx_out.c_str());
    so.AddConfigEntry("ep.context_embed_mode", "0");
  }
  return so;
}

Ort::Env make_env() {
  const char* log = getenv("NPU_LOG");
  return Ort::Env(log && log[0] == 'v' ? ORT_LOGGING_LEVEL_VERBOSE : ORT_LOGGING_LEVEL_WARNING, "pi0npu", log_line,
                  nullptr);
}

}  // namespace

extern "C" {

// Loads the compiled parts in `dir` (npu/export_pi0.py's npu.txt, and part<i>_ctx.onnx). *ms: the time to load them.
int pi0npu_open(const char* dir, double* ms) {
  double t0 = now_ms();
  g = new Npu();
  dsp_path();
  g->env = make_env();
  std::string d(dir), word;
  std::ifstream meta(d + "/npu.txt");
  meta >> word;
  if (word != "pi0-prefix") return fail(d + "/npu.txt: not npu/export_pi0.py's");
  meta >> word >> g->rows >> word >> g->nparts >> word;
  g->bounds.resize(g->nparts + 1);
  for (int& b : g->bounds) meta >> b;
  if (!meta || g->bounds[0] != 0 || g->bounds[g->nparts] != L) return fail("npu.txt: bad layer bounds");

  const int R = g->rows;
  g->x.assign(g->nparts, std::vector<__fp16>(size_t(R) * D, 0));
  g->cos.assign(size_t(R) * HD, 0);
  g->sin.assign(size_t(R) * HD, 0);
  g->mask.assign(R, 0);
  g->k.assign(L, std::vector<__fp16>(size_t(R) * HD, 0));
  g->v.assign(L, std::vector<__fp16>(size_t(R) * HD, 0));
  Ort::MemoryInfo cpu = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
  auto f16 = ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16;
  try {
    for (int i = 0; i < g->nparts; i++) {
      std::string ctx = d + "/part" + std::to_string(i) + "_ctx.onnx";
      if (!exists(ctx)) return fail(ctx + " missing: run pi0npu_tool compile " + d + " " + std::to_string(i) + " first");
      double ts = now_ms();
      g->parts.emplace_back(g->env, ort_path(ctx).c_str(), options(""));
      fprintf(stderr, "pi0npu: part %d (layers %d..%d) loaded in %.2f s\n", i, g->bounds[i], g->bounds[i + 1] - 1,
              (now_ms() - ts) / 1e3);
      Ort::Session& s = g->parts.back();
      Ort::IoBinding b(s);
      std::vector<Ort::Value> vals;
      int64_t xs[2] = {R, D}, cs[3] = {R, 1, HD}, ms_[2] = {1, R}, kvs[2] = {R, HD};
      auto bind_in = [&](const char* name, __fp16* p, size_t n, const int64_t* shape, size_t rank) {
        vals.push_back(Ort::Value::CreateTensor(cpu, p, n * 2, shape, rank, f16));
        b.BindInput(name, vals.back());
      };
      auto bind_out = [&](const std::string& name, __fp16* p, size_t n, const int64_t* shape, size_t rank) {
        vals.push_back(Ort::Value::CreateTensor(cpu, p, n * 2, shape, rank, f16));
        b.BindOutput(name.c_str(), vals.back());
      };
      bind_in("x", g->x[i].data(), g->x[i].size(), xs, 2);
      bind_in("cos", g->cos.data(), g->cos.size(), cs, 3);
      bind_in("sin", g->sin.data(), g->sin.size(), cs, 3);
      bind_in("mask", g->mask.data(), g->mask.size(), ms_, 2);
      for (int l = g->bounds[i]; l < g->bounds[i + 1]; l++) {
        bind_out("k" + std::to_string(l), g->k[l].data(), g->k[l].size(), kvs, 2);
        bind_out("v" + std::to_string(l), g->v[l].data(), g->v[l].size(), kvs, 2);
      }
      if (i < g->nparts - 1) bind_out("x_out", g->x[i + 1].data(), g->x[i + 1].size(), xs, 2);
      g->bindings.push_back(std::move(b));
      g->values.push_back(std::move(vals));
    }
  } catch (const Ort::Exception& e) {
    return fail(e.what());
  }
  if (ms) *ms = now_ms() - t0;
  return 0;
}

int pi0npu_rows() { return g ? g->rows : 0; }
int pi0npu_parts() { return g ? g->nparts : 0; }

// The first layer of part `part` (part == pi0npu_parts(): one past the last layer).
int pi0npu_part_first(int part) { return g->bounds[part]; }

// The example's positions and key mask, for n prefix rows: RoPE's cos and sin at pos[r] from `rope` (transformers'
// table, [2][1024][128]: cos, then sin, first half), and mask 0 where valid[r] (else -30000, as for rows n..rows-1).
int pi0npu_set_rope(const float* rope, const int32_t* pos, const int32_t* valid, int n) {
  if (!g || n > g->rows) return fail("pi0npu_set_rope: " + std::to_string(n) + " rows");
  for (int r = 0; r < g->rows; r++) {
    int p = r < n ? pos[r] : 0;
    if (p < 0 || p >= MAXPOS) return fail("pi0npu_set_rope: position " + std::to_string(p));
    for (int j = 0; j < HD; j++) {
      g->cos[size_t(r) * HD + j] = rope[size_t(p) * (HD / 2) + j % (HD / 2)];
      g->sin[size_t(r) * HD + j] = rope[size_t(MAXPOS + p) * (HD / 2) + j % (HD / 2)];
    }
    g->mask[r] = r < n && valid[r] ? 0 : -30000;
  }
  return 0;
}

// The prefix embeddings: n rows of fp32 [n][2048] into part 0's x (fp16), the rest zero.
int pi0npu_set_x(const float* x, int n) {
  if (!g || n > g->rows) return fail("pi0npu_set_x: " + std::to_string(n) + " rows");
  __fp16* dst = g->x[0].data();
  for (size_t i = 0; i < size_t(n) * D; i++) dst[i] = x[i];
  memset(dst + size_t(n) * D, 0, size_t(g->rows - n) * D * 2);
  return 0;
}

// The parts on a worker thread: pi0npu_start returns at once; pi0npu_part_wait(i) returns when part i's K/V (layers
// pi0npu_part_first(i) .. pi0npu_part_first(i + 1) - 1) are written, so they can be handed to the GPU while the NPU
// runs the next parts; pi0npu_finish waits for the last part. *ms: the time from start to the last part.
int pi0npu_start() {
  if (!g) return fail("pi0npu_start: not open");
  if (g->worker.joinable()) return fail("pi0npu_start: a prefix is running");
  g->t_start = now_ms();
  g->parts_done = 0;
  g->run_error.clear();
  g->worker = std::thread([] {
    Ort::RunOptions ro;
    for (int i = 0; i < g->nparts; i++) {
      std::string err;
      try {
        g->parts[i].Run(ro, g->bindings[i]);
      } catch (const Ort::Exception& e) {
        err = e.what();
      }
      std::lock_guard<std::mutex> lock(g->mu);
      g->parts_done = err.empty() ? i + 1 : g->nparts;  // an error wakes every waiter
      if (!err.empty()) g->run_error = err;
      if (i == g->nparts - 1 || !err.empty()) g->run_ms = now_ms() - g->t_start;
      g->cv.notify_all();
      if (!err.empty()) return;
    }
  });
  return 0;
}

int pi0npu_part_wait(int part) {
  std::unique_lock<std::mutex> lock(g->mu);
  g->cv.wait(lock, [part] { return g->parts_done > part; });
  return g->run_error.empty() ? 0 : fail(g->run_error);
}

int pi0npu_finish(double* ms) {
  if (g->worker.joinable()) g->worker.join();
  if (!g->run_error.empty()) return fail(g->run_error);
  if (ms) *ms = g->run_ms;
  return 0;
}

int pi0npu_run(double* ms) {
  if (pi0npu_start()) return -1;
  return pi0npu_finish(ms);
}

// Layer `layer`'s K (which 0, after RoPE) or V (which 1), rows 0 .. n-1, into dst as fp32 [n][256]: the expert's
// prefix cache layout (pi0/model.mojo's kc / vc).
void pi0npu_kv(int layer, int which, float* dst, int n) {
  const __fp16* src = (which ? g->v : g->k)[layer].data();
  for (size_t i = 0; i < size_t(n) * HD; i++) dst[i] = src[i];
}

const char* pi0npu_error() { return g ? g->error.c_str() : "pi0npu_open not called"; }

void pi0npu_close() {
  if (!g) return;
  if (g->worker.joinable()) g->worker.join();
  delete g;
  g = nullptr;
}

// Compiles <dir>/part<part>.onnx for the HTP and saves its context binary (<dir>/part<part>_ctx.onnx and its .bin),
// in a process of its own.
int pi0npu_compile(const char* dir, int part, double* ms) {
  double t0 = now_ms();
  dsp_path();
  Ort::Env env = make_env();
  std::string d(dir), i = std::to_string(part);
  try {
    Ort::Session s(env, ort_path(d + "/part" + i + ".onnx").c_str(), options(d + "/part" + i + "_ctx.onnx"));
  } catch (const Ort::Exception& e) {
    fprintf(stderr, "pi0npu: %s\n", e.what());
    return -1;
  }
  if (ms) *ms = now_ms() - t0;
  return 0;
}

}  // extern "C"

#ifdef NPU_TOOL
// pi0npu_tool compile <graph dir> <part>         compile one part and save its context
// pi0npu_tool <graph dir> <ref dir> <runs> <dump dir or ->
//   Loads the compiled parts, runs the prefix `runs` times on pi0/reference.py's prefix embeddings (prefix.f32,
//   lang_mask.i32, rope.f32), and writes the last run's K/V (fp16 [layer][k, v][816][256]) to <dump dir>/kv.f16.
static std::vector<char> slurp(const std::string& path) {
  std::ifstream f(path, std::ios::binary);
  return std::vector<char>((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

int main(int argc, char** argv) {
  if (argc == 4 && std::string(argv[1]) == "compile") {
    double ms = 0;
    if (pi0npu_compile(argv[2], atoi(argv[3]), &ms)) return 1;
    printf("part %s compiled and saved in %.1f s\n", argv[3], ms / 1e3);
    return 0;
  }
  if (argc != 5) {
    fprintf(stderr, "usage: pi0npu_tool compile <graph dir> <part> | <graph dir> <ref dir> <runs> <dump dir or ->\n");
    return 2;
  }
  constexpr int PLEN = 816, VROWS = 768;
  std::string ref = argv[2];
  std::vector<char> x = slurp(ref + "/prefix.f32"), rope = slurp(ref + "/rope.f32"), lm = slurp(ref + "/lang_mask.i32");
  if (x.size() != size_t(PLEN) * D * 4 || rope.size() != size_t(2) * MAXPOS * HD / 2 * 4 ||
      lm.size() != size_t(PLEN - VROWS) * 4) {
    fprintf(stderr, "%s: not pi0/reference.py's\n", ref.c_str());
    return 2;
  }
  std::vector<int32_t> pos(PLEN), valid(PLEN);
  int count = 0;
  for (int r = 0; r < PLEN; r++) {  // cumsum(pad mask) - 1
    valid[r] = r < VROWS || reinterpret_cast<const int32_t*>(lm.data())[r - VROWS] != 0;
    count += valid[r];
    pos[r] = count > 0 ? count - 1 : 0;
  }
  double ms = 0;
  if (pi0npu_open(argv[1], &ms)) return 1;
  printf("open: %d parts loaded in %.2f s; %d rows (%d of %d valid)\n", g->nparts, ms / 1e3, g->rows, count, PLEN);
  if (pi0npu_set_rope(reinterpret_cast<const float*>(rope.data()), pos.data(), valid.data(), PLEN)) return 1;
  int runs = atoi(argv[3]);
  for (int r = 0; r < runs; r++) {
    double t0 = now_ms();
    if (pi0npu_set_x(reinterpret_cast<const float*>(x.data()), PLEN)) return 1;
    double t1 = now_ms();
    if (pi0npu_run(&ms)) return 1;
    printf("prefix %d: %.1f ms on the NPU (+ %.1f ms converting the embeddings to fp16)\n", r, ms, t1 - t0);
    fflush(stdout);
  }
  std::string dump = argv[4];
  if (dump != "-") {
    FILE* f = fopen((dump + "/kv.f16").c_str(), "wb");
    for (int l = 0; l < L; l++)
      for (const auto* kv : {&g->k[l], &g->v[l]}) fwrite(kv->data(), 2, size_t(PLEN) * HD, f);
    fclose(f);
  }
  pi0npu_close();
  printf("done\n");
  return 0;
}
#endif
