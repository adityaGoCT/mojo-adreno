// Prompt prefill on the Hexagon NPU (HTP), through ONNX Runtime's QNN execution provider: the graphs of
// npu/export.py (Llama 3.2 1B, fp16 or quantized) or npu/export_qwen3.py (ternary Qwen3-8B), run one after another;
// npu.txt says which model. A C interface, for npu/hybrid.mojo, npu/hybrid_qwen3.mojo and npu_decode (which take
// the KV cache and logits) and for npu_tool (built with -DNPU_TOOL: compile, time and dump on its own).
//
// npu_open loads <dir>/part<i>_ctx.onnx, the HTP context binary that npu_compile (npu_tool compile <dir> <i>)
// saved, a part a process: QNN's compile holds several copies of a part's weights, and compiling all four parts in
// one process runs the phone out of memory. (Compiling inside npu_open also failed once with ONNX Runtime 1.29's
// "Input/Output name not found"; a part compiled in a process of its own loads fine.) The embedding rows (part 0's
// input) are read from the GPU model's weights.bin: Llama's fp16 embed.<c> chunks, or Qwen3's 2-bit emb.w with its
// fp16 scales and biases per 128 (emb.s, emb.b), dequantized. Environment:
//   NPU_LOG=v           ONNX Runtime's verbose log (which nodes QNN takes, and why not)
//   NPU_FALLBACK=1      allow nodes on the CPU (otherwise every node must run on the HTP)
//   NPU_OPT=<0..3>      QNN's graph finalization optimization mode (default 3, the slowest compile)
//   NPU_NOCTX=1         compile in memory, without saving or loading a context binary
//   NPU_DUMP_JSON=<dir> QNN's graph of each part as JSON
//   NPU_PROFILE=<csv>   QNN's profile (NPU_PROFILE_LEVEL basic or detailed, the default) of every run
#include <onnxruntime_cxx_api.h>

#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>
#include <tuple>
#include <unordered_map>
#include <vector>

namespace {

constexpr int CHUNKS = 4;  // Llama's embedding: 4 fp16 chunks of V / 4 rows

// The model's shape, from npu.txt's first word.
struct Dims {
  int D, L, KVH, HD, V;
  bool qwen3;
};
Dims dims{2048, 16, 8, 64, 128256, false};

double now_ms() {
  return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

bool exists(const std::string& p) {
  struct stat st;
  return stat(p.c_str(), &st) == 0;
}

std::string exe_dir() {
  char buf[4096];
  ssize_t n = readlink("/proc/self/exe", buf, sizeof buf - 1);
  if (n <= 0) return ".";
  buf[n] = 0;
  std::string s(buf);
  return s.substr(0, s.rfind('/'));
}

struct Npu {
  Ort::Env env{nullptr};
  std::vector<Ort::Session> parts;
  std::vector<Ort::IoBinding> bindings;
  std::vector<std::vector<Ort::Value>> values;  // the tensors each binding refers to
  int rows = 0, nparts = 0;
  std::vector<int> bounds;                      // part i: layers bounds[i] .. bounds[i+1]-1
  std::vector<std::vector<__fp16>> x;           // x[i]: part i's input
  std::vector<std::vector<__fp16>> k, v;        // [layer][8 * slots * 64]: the K/V outputs, unless npu_bind_kv
  std::vector<__fp16*> kp, vp;                  // [layer]: where each layer's K/V output is bound
  std::vector<int64_t> kv_shape;                // a K/V output's shape: [8, slots, 64] (or export.py --leaf-kv's)
  size_t kv_elems = 0;                          // its elements
  int slots = 0;                                // positions a KV head (512 with export.py --kv-slots 512)
  std::vector<__fp16> logits;                   // [V]
  int32_t last = 0;
  int wfd = -1;
  uint64_t embed_off[CHUNKS] = {};          // Llama: embed.<c>
  uint64_t emb_w = 0, emb_s = 0, emb_b = 0;  // Qwen3: emb.w (uint32, D / 16 a row), emb.s, emb.b (fp16, D / 128 a row)
  std::string error;
  std::thread worker;  // a prefill's parts, one after another (npu_prefill_start)
  std::mutex mu;
  std::condition_variable cv;
  int parts_done = 0;  // under mu
  std::string run_error;
  double t_start = 0, run_ms = 0;
};

Npu* g = nullptr;

// ONNX Runtime's log on stderr (on Android it goes to logcat, whose ring buffer drops a verbose compile's lines)
void ORT_API_CALL log_line(void*, OrtLoggingLevel severity, const char*, const char*, const char* code_location,
                           const char* message) {
  fprintf(stderr, "[ort %d] %s %s\n", int(severity), code_location, message);
}

int fail(const std::string& msg) {
  if (g) g->error = msg;
  fprintf(stderr, "npu: %s\n", msg.c_str());
  return -1;
}

Ort::SessionOptions options(const std::string& ctx_out) {
  Ort::SessionOptions so;
  so.SetIntraOpNumThreads(1);
  const char* opt = getenv("NPU_OPT");
  std::unordered_map<std::string, std::string> qnn = {
      {"backend_path", exe_dir() + "/libQnnHtp.so"},
      {"htp_performance_mode", "burst"},
      {"htp_graph_finalization_optimization_mode", opt ? opt : "3"},
  };
  if (const char* dir = getenv("NPU_DUMP_JSON")) {  // QNN's graph as JSON, every tensor with its type
    qnn["dump_json_qnn_graph"] = "1";
    qnn["json_qnn_graph_dir"] = dir;
  }
  if (const char* csv = getenv("NPU_PROFILE")) {  // QNN's per-op profile of every run, as CSV
    qnn["profiling_level"] = getenv("NPU_PROFILE_LEVEL") ? getenv("NPU_PROFILE_LEVEL") : "detailed";
    qnn["profiling_file_path"] = csv;
  }
  so.AppendExecutionProvider("QNN", qnn);
  if (!getenv("NPU_FALLBACK")) so.AddConfigEntry("session.disable_cpu_ep_fallback", "1");
  if (!ctx_out.empty()) {
    so.AddConfigEntry("ep.context_enable", "1");
    so.AddConfigEntry("ep.context_file_path", ctx_out.c_str());
    so.AddConfigEntry("ep.context_embed_mode", "0");
  }
  return so;
}

}  // namespace

extern "C" {

// Opens the prefill graphs in `dir` (npu/export.py's or export_qwen3.py's npu.txt and part<i>.onnx) and the
// embedding of the GPU model in `model_dir`. *ms: the time to load (or compile) them; *compiled: how many parts were compiled now.
int npu_open(const char* dir, const char* model_dir, double* ms, int* compiled) {
  double t0 = now_ms();
  g = new Npu();
  if (!getenv("ADSP_LIBRARY_PATH")) {  // where the DSP side looks for libQnnHtpV81Skel.so
    std::string p = exe_dir() + ";/vendor/dsp/cdsp;/vendor/lib/rfsa/adsp;/system/lib/rfsa/adsp;/dsp";
    setenv("ADSP_LIBRARY_PATH", p.c_str(), 1);
  }
  const char* log = getenv("NPU_LOG");
  g->env = Ort::Env(log && log[0] == 'v' ? ORT_LOGGING_LEVEL_VERBOSE : ORT_LOGGING_LEVEL_WARNING, "npu", log_line,
                    nullptr);
  std::string d(dir);
  std::ifstream meta(d + "/npu.txt");
  std::string word;
  meta >> word;
  if (word == "llama-prefill")
    dims = Dims{2048, 16, 8, 64, 128256, false};
  else if (word == "qwen3-prefill")
    dims = Dims{4096, 36, 8, 128, 151669, true};
  else
    return fail(d + "/npu.txt: not npu/export.py's or npu/export_qwen3.py's");
  const int D = dims.D, L = dims.L, KVH = dims.KVH, HD = dims.HD, V = dims.V;
  meta >> word >> g->rows >> word >> g->nparts >> word;
  g->bounds.resize(g->nparts + 1);
  for (int& b : g->bounds) meta >> b;
  if (!meta || g->bounds[0] != 0 || g->bounds[g->nparts] != L) return fail("npu.txt: bad layer bounds");

  std::ifstream man(std::string(model_dir) + "/manifest.txt");
  std::string line;
  std::getline(man, line);
  while (std::getline(man, line)) {
    std::istringstream f(line);
    std::string name;
    uint64_t off, bytes;
    if (!(f >> name >> off >> bytes)) continue;
    for (int c = 0; c < CHUNKS; c++)
      if (name == "embed." + std::to_string(c)) g->embed_off[c] = off;
    if (name == "emb.w") g->emb_w = off;
    if (name == "emb.s") g->emb_s = off;
    if (name == "emb.b") g->emb_b = off;
  }
  g->wfd = open((std::string(model_dir) + "/weights.bin").c_str(), O_RDONLY);
  if (g->wfd < 0) return fail(std::string(model_dir) + "/weights.bin: cannot open");

  int R = g->rows;
  g->x.assign(g->nparts, std::vector<__fp16>(size_t(R) * D));
  g->k.resize(L);
  g->v.resize(L);
  g->kp.assign(L, nullptr);
  g->vp.assign(L, nullptr);
  g->logits.assign(V, 0);
  Ort::MemoryInfo cpu = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
  auto f16 = ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16;
  int n_compiled = 0;
  try {
    for (int i = 0; i < g->nparts; i++) {
      std::string src = d + "/part" + std::to_string(i) + ".onnx";
      std::string ctx = d + "/part" + std::to_string(i) + "_ctx.onnx";
      double ts = now_ms();
      bool noctx = getenv("NPU_NOCTX") != nullptr;  // compile in memory every time, no context binary
      if (!noctx && !exists(ctx))  // compiling here would hold every part's weights several times over
        return fail(ctx + " missing: run npu_tool compile " + d + " " + std::to_string(i) + " first");
      g->parts.emplace_back(g->env, (noctx ? src : ctx).c_str(), options(""));
      n_compiled += noctx;
      fprintf(stderr, "npu: part %d (layers %d..%d) %s in %.1f s\n", i, g->bounds[i], g->bounds[i + 1] - 1,
              noctx ? "compiled" : "loaded", (now_ms() - ts) / 1e3);
      Ort::Session& s = g->parts.back();
      Ort::IoBinding b(s);
      std::vector<Ort::Value> vals;
      int64_t xs[2] = {R, D}, ls[2] = {1, V}, one[1] = {1};
      std::vector<int64_t> kvs;  // the K/V outputs' shape, from the session: [8, slots, 64]
      for (size_t o = 0; o < s.GetOutputCount(); o++) {
        Ort::AllocatedStringPtr name = s.GetOutputNameAllocated(o, Ort::AllocatorWithDefaultOptions());
        if (name.get()[0] == 'k') kvs = s.GetOutputTypeInfo(o).GetTensorTypeAndShapeInfo().GetShape();
      }
      size_t elems = 1;
      for (int64_t e : kvs) elems *= e;
      if (i == 0) {
        g->kv_shape = kvs;
        g->kv_elems = elems;
        g->slots = elems / (KVH * HD);
      } else if (kvs != g->kv_shape) {
        return fail("part " + std::to_string(i) + ": K/V outputs of another shape than part 0's");
      }
      vals.push_back(Ort::Value::CreateTensor(cpu, g->x[i].data(), g->x[i].size() * 2, xs, 2, f16));
      b.BindInput("x", vals.back());
      for (int l = g->bounds[i]; l < g->bounds[i + 1]; l++) {
        for (auto [kv, buf, ptr] : {std::tuple{'k', &g->k[l], &g->kp[l]}, std::tuple{'v', &g->v[l], &g->vp[l]}}) {
          buf->assign(elems, 0);
          *ptr = buf->data();
          vals.push_back(Ort::Value::CreateTensor(cpu, *ptr, elems * 2, kvs.data(), kvs.size(), f16));
          b.BindOutput((kv + std::to_string(l)).c_str(), vals.back());
        }
      }
      if (i == g->nparts - 1) {
        vals.push_back(Ort::Value::CreateTensor<int32_t>(cpu, &g->last, 1, one, 1));
        b.BindInput("last", vals.back());
        vals.push_back(Ort::Value::CreateTensor(cpu, g->logits.data(), g->logits.size() * 2, ls, 2, f16));
        b.BindOutput("logits", vals.back());
      } else {
        vals.push_back(Ort::Value::CreateTensor(cpu, g->x[i + 1].data(), g->x[i + 1].size() * 2, xs, 2, f16));
        b.BindOutput("x_out", vals.back());
      }
      g->bindings.push_back(std::move(b));
      g->values.push_back(std::move(vals));
    }
  } catch (const Ort::Exception& e) {
    return fail(e.what());
  }
  if (ms) *ms = now_ms() - t0;
  if (compiled) *compiled = n_compiled;
  return 0;
}

int npu_rows() { return g ? g->rows : 0; }

// Row `token` of the embedding into x (fp16 [D]).
static bool embed_row(int token, __fp16* x) {
  const int D = dims.D;
  if (!dims.qwen3) {
    int per = dims.V / CHUNKS, c = token / per, r = token % per;
    return pread(g->wfd, x, D * 2, g->embed_off[c] + uint64_t(r) * D * 2) == D * 2;
  }
  std::vector<uint32_t> w(D / 16);
  std::vector<__fp16> sc(D / 128), b(D / 128);
  if (pread(g->wfd, w.data(), D / 4, g->emb_w + uint64_t(token) * (D / 4)) != D / 4 ||
      pread(g->wfd, sc.data(), D / 64, g->emb_s + uint64_t(token) * (D / 64)) != D / 64 ||
      pread(g->wfd, b.data(), D / 64, g->emb_b + uint64_t(token) * (D / 64)) != D / 64)
    return false;
  for (int i = 0; i < D; i++) {  // code * scale + bias, as qwen3/model.mojo's dequantize (fp32 math)
    uint32_t code = (w[i / 16] >> (2 * (i % 16))) & 3;
    x[i] = __fp16(float(code) * float(sc[i / 128]) + float(b[i / 128]));
  }
  return true;
}

// The prompt's n tokens through every part, on a worker thread: npu_prefill_start returns once the embedding rows
// are gathered and the parts are running; npu_part_wait(i) returns when part i's K/V (layers npu_part_first(i) ..
// npu_part_first(i + 1) - 1) are written, so they can be handed to the GPU while the NPU runs the next parts;
// npu_prefill_finish waits for the last part (the logits of token n-1). *ms: the time from start to the last part.
int npu_prefill_start(const int32_t* tokens, int n) {
  if (!g || n < 1 || n > g->rows) return fail("npu_prefill: " + std::to_string(n) + " tokens");
  if (g->worker.joinable()) return fail("npu_prefill_start: a prefill is running");
  g->t_start = now_ms();
  const int D = dims.D;
  std::vector<__fp16>& x = g->x[0];
  for (int t = 0; t < n; t++)
    if (!embed_row(tokens[t], x.data() + size_t(t) * D)) return fail("weights.bin: short read");
  memset(x.data() + size_t(n) * D, 0, size_t(g->rows - n) * D * 2);
  g->last = n - 1;
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
      if (!err.empty()) {
        g->run_error = err;
        g->parts_done = g->nparts;  // wake every waiter
      } else {
        g->parts_done = i + 1;
      }
      if (i == g->nparts - 1 || !err.empty()) g->run_ms = now_ms() - g->t_start;
      g->cv.notify_all();
      if (!err.empty()) return;
    }
  });
  return 0;
}

int npu_part_wait(int part) {
  std::unique_lock<std::mutex> lock(g->mu);
  g->cv.wait(lock, [part] { return g->parts_done > part; });
  return g->run_error.empty() ? 0 : fail(g->run_error);
}

int npu_prefill_finish(double* ms) {
  if (g->worker.joinable()) g->worker.join();
  if (!g->run_error.empty()) return fail(g->run_error);
  if (ms) *ms = g->run_ms;
  return 0;
}

int npu_prefill(const int32_t* tokens, int n, double* ms) {
  if (npu_prefill_start(tokens, n)) return -1;
  return npu_prefill_finish(ms);
}

int npu_parts() { return g ? g->nparts : 0; }

// The first layer of part `part` (part == npu_parts(): one past the last layer).
int npu_part_first(int part) { return g->bounds[part]; }

// Layer `layer`'s K (which 0) or V (which 1), positions 0 .. n-1, into dst as fp32 [8][maxpos][64]: the GPU
// model's KV cache layout.
void npu_kv(int layer, int which, float* dst, int maxpos, int n) {
  const int KVH = dims.KVH, HD = dims.HD;
  const __fp16* src = (which ? g->vp : g->kp)[layer];
  for (int h = 0; h < KVH; h++)
    for (size_t i = 0; i < size_t(n) * HD; i++) dst[size_t(h) * maxpos * HD + i] = src[size_t(h) * g->slots * HD + i];
}

// The same as fp32 [position][8 * 128]: Qwen3's GPU KV cache layout (qwen3/model.mojo's kc, vc).
void npu_kv_rows(int layer, int which, float* dst, int n) {
  const int KVH = dims.KVH, HD = dims.HD;
  const __fp16* src = (which ? g->vp : g->kp)[layer];
  for (int h = 0; h < KVH; h++)
    for (int t = 0; t < n; t++)
      for (int d = 0; d < HD; d++) dst[(size_t(t) * KVH + h) * HD + d] = src[(size_t(h) * g->slots + t) * HD + d];
}

// Positions a K/V output holds per KV head: its layout is [8][npu_kv_slots()][64] fp16.
int npu_kv_slots() { return g ? g->slots : 0; }

// Binds layer `layer`'s K (which 0) or V (which 1) output to `buf`: fp16 [8][npu_kv_slots()][64], which the
// prefill then writes directly (npu_decode's decode cache). Not while a prefill runs.
int npu_bind_kv(int layer, int which, void* buf) {
  if (!g || layer < 0 || layer >= dims.L || g->worker.joinable()) return fail("npu_bind_kv: no open graphs, or busy");
  int i = 0;
  while (g->bounds[i + 1] <= layer) i++;
  Ort::MemoryInfo cpu = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
  g->values[i].push_back(Ort::Value::CreateTensor(cpu, buf, g->kv_elems * 2, g->kv_shape.data(), g->kv_shape.size(),
                                                  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16));
  g->bindings[i].BindOutput(((which ? "v" : "k") + std::to_string(layer)).c_str(), g->values[i].back());
  (which ? g->vp : g->kp)[layer] = static_cast<__fp16*>(buf);
  return 0;
}

void npu_logits(float* dst) {
  for (int i = 0; i < dims.V; i++) dst[i] = g->logits[i];
}

int npu_vocab() { return dims.V; }

const char* npu_error() { return g ? g->error.c_str() : "npu_open not called"; }

void npu_close() {
  if (!g) return;
  if (g->worker.joinable()) g->worker.join();
  if (g->wfd >= 0) close(g->wfd);
  delete g;
  g = nullptr;
}

}  // extern "C"

// Compiles <dir>/part<part>.onnx for the HTP and saves its context binary (<dir>/part<part>_ctx.onnx and .bin),
// in a process of its own: compiling holds several copies of a part's weights, so all parts at once do not fit.
int npu_compile(const char* dir, int part, double* ms) {
  double t0 = now_ms();
  if (!getenv("ADSP_LIBRARY_PATH")) {
    std::string p = exe_dir() + ";/vendor/dsp/cdsp;/vendor/lib/rfsa/adsp;/system/lib/rfsa/adsp;/dsp";
    setenv("ADSP_LIBRARY_PATH", p.c_str(), 1);
  }
  const char* log = getenv("NPU_LOG");
  Ort::Env env(log && log[0] == 'v' ? ORT_LOGGING_LEVEL_VERBOSE : ORT_LOGGING_LEVEL_WARNING, "npu", log_line, nullptr);
  std::string d(dir), i = std::to_string(part);
  try {
    Ort::Session s(env, (d + "/part" + i + ".onnx").c_str(), options(d + "/part" + i + "_ctx.onnx"));
  } catch (const Ort::Exception& e) {
    fprintf(stderr, "npu: %s\n", e.what());
    return -1;
  }
  if (ms) *ms = now_ms() - t0;
  return 0;
}

#ifdef NPU_TOOL
// npu_tool compile <graph dir> <part>: compile one part and save its context
// npu_tool bench <graph dir> <part> <runs>: time any compiled part<part>_ctx.onnx on zero inputs
// npu_tool <graph dir> <model dir> <runs> <dump dir or -> <token ids...>
// Compiles (the first time) or loads the graphs, runs the prefill `runs` times, and writes the last run's K/V
// (fp16, [layer][k, v][8][n][64]) and logits (fp32) to <dump dir>/kv.f16 and logits.f32.
int main(int argc, char** argv) {
  if (argc == 4 && std::string(argv[1]) == "compile") {
    double ms = 0;
    if (npu_compile(argv[2], atoi(argv[3]), &ms)) return 1;
    printf("part %s compiled and saved in %.1f s\n", argv[3], ms / 1e3);
    return 0;
  }
  if (argc == 4 && std::string(argv[1]) == "load") {  // load one part's context, and nothing else
    double t0 = now_ms();
    Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "npu", log_line, nullptr);
    std::string ctx = std::string(argv[2]) + "/part" + argv[3] + "_ctx.onnx";
    try {
      Ort::Session s(env, ctx.c_str(), options(""));
      printf("loaded %s in %.2f s: %zu inputs, %zu outputs\n", ctx.c_str(), (now_ms() - t0) / 1e3, s.GetInputCount(),
             s.GetOutputCount());
    } catch (const Ort::Exception& e) {
      printf("load failed: %s\n", e.what());
      return 1;
    }
    return 0;
  }
  if (argc == 5 && std::string(argv[1]) == "bench") {  // npu_tool bench <dir> <part> <runs>: any compiled graph
    Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "npu", log_line, nullptr);
    std::string ctx = std::string(argv[2]) + "/part" + argv[3] + "_ctx.onnx";
    try {
      Ort::Session s(env, ctx.c_str(), options(""));
      Ort::MemoryInfo cpu = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
      Ort::IoBinding b(s);
      std::vector<std::vector<uint8_t>> bufs;
      std::vector<Ort::Value> vals;
      std::vector<Ort::AllocatedStringPtr> names;
      Ort::AllocatorWithDefaultOptions alloc;
      for (int io = 0; io < 2; io++) {
        size_t count = io ? s.GetOutputCount() : s.GetInputCount();
        for (size_t i = 0; i < count; i++) {
          names.push_back(io ? s.GetOutputNameAllocated(i, alloc) : s.GetInputNameAllocated(i, alloc));
          auto info = (io ? s.GetOutputTypeInfo(i) : s.GetInputTypeInfo(i)).GetTensorTypeAndShapeInfo();
          std::vector<int64_t> shape = info.GetShape();
          size_t n = 1;
          for (int64_t d : shape) n *= size_t(d);
          size_t esize = info.GetElementType() == ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16 ? 2 : 4;
          bufs.emplace_back(n * esize, 0);
          vals.push_back(Ort::Value::CreateTensor(cpu, bufs.back().data(), bufs.back().size(), shape.data(),
                                                  shape.size(), info.GetElementType()));
          if (io)
            b.BindOutput(names.back().get(), vals.back());
          else
            b.BindInput(names.back().get(), vals.back());
        }
      }
      Ort::RunOptions ro;
      int runs = atoi(argv[4]);
      double best = 1e30, sum = 0;
      for (int r = 0; r < runs; r++) {
        double t0 = now_ms();
        s.Run(ro, b);
        double ms = now_ms() - t0;
        if (r > 0) best = std::min(best, ms), sum += ms;
      }
      printf("bench %s: best %.2f ms, mean %.2f ms over %d warm runs\n", ctx.c_str(), best, sum / (runs - 1), runs - 1);
    } catch (const Ort::Exception& e) {
      printf("bench failed: %s\n", e.what());
      return 1;
    }
    return 0;
  }
  if (argc < 6) {
    fprintf(stderr, "usage: npu_tool <graph dir> <model dir> <runs> <dump dir or -> <token ids...>\n");
    return 2;
  }
  std::vector<int32_t> tokens;
  for (int i = 5; i < argc; i++) tokens.push_back(atoi(argv[i]));
  int n = tokens.size();
  double ms = 0;
  int compiled = 0;
  if (npu_open(argv[1], argv[2], &ms, &compiled)) return 1;
  printf("open: %.2f s (%d of %d parts compiled now)\n", ms / 1e3, compiled, g->nparts);
  int runs = atoi(argv[3]);
  for (int r = 0; r < runs; r++) {
    if (npu_prefill(tokens.data(), n, &ms)) return 1;
    printf("prefill %d: %d tokens (%d rows) in %.1f ms (%.0f tokens/s)\n", r, n, g->rows, ms, n * 1e3 / ms);
    fflush(stdout);
  }
  std::string dump = argv[4];
  if (dump != "-") {
    const int L = dims.L, KVH = dims.KVH, HD = dims.HD, V = dims.V;
    FILE* f = fopen((dump + "/kv.f16").c_str(), "wb");
    for (int l = 0; l < L; l++)
      for (const __fp16* kv : {g->kp[l], g->vp[l]})
        for (int h = 0; h < KVH; h++) fwrite(kv + size_t(h) * g->slots * HD, 2, size_t(n) * HD, f);
    fclose(f);
    std::vector<float> lg(V);
    npu_logits(lg.data());
    f = fopen((dump + "/logits.f32").c_str(), "wb");
    fwrite(lg.data(), 4, V, f);
    fclose(f);
  }
  npu_close();
  printf("done\n");
  return 0;
}
#endif
