// Any static ONNX graph on the Hexagon NPU (HTP), through ONNX Runtime's QNN execution provider: the generic piece the
// VLA ports share (TurboVLA's vision, text and head graphs first). fp32 graphs run in fp16 on the HTP
// (enable_htp_fp16_precision); inputs may be fp32 or int32, outputs fp32. A C interface (graph.h) for programs and
// vk_server; built with -DNPU_TOOL it is graph_tool:
//
//   graph_tool compile <model.onnx> <context.onnx>          the HTP context binary, saved (a graph a process)
//   graph_tool run <context.onnx> <runs> <input files...> [-o <dir>]
//                                                           inputs as raw fp32 / int32 files in the graph's input
//                                                           order; times each run; writes the outputs (fp32) to dir
//   graph_tool chain <runs> <context.onnx> <inputs...> [+ <context.onnx> <inputs...>]... [-o <dir>]
//                                                           graphs back to back, timed end to end; an input @g:i is
//                                                           graph g's output i (the same host buffer)
//   graph_tool serve <port> <context.onnx> <inputs or ->... [+ ...]...
//                                                           a chain kept open for a TCP client (see serve())
// Environment: NPU_LOG=v (ONNX Runtime's verbose log), NPU_FALLBACK=1 (allow nodes on the CPU; otherwise every node
// must run on the HTP), NPU_OPT=<0..3> (QNN's graph finalization optimization mode, default 3), NPU_FILE_MAP=1
// (ONNX Runtime's file-mapped weights; off by default, see options()), NPU_PROFILE=basic|detailed|optrace (QNN's
// profile, as CSV to NPU_PROFILE_FILE).
//
// Built for Windows on ARM (the Snapdragon X2 Elite laptop) by npu/build_win.sh, and for Android by npu/build.py.
#include "graph.h"

#include <onnxruntime_cxx_api.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

double now_ms() {
  return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

#ifdef _WIN32
constexpr const char* QNN_HTP = "QnnHtp.dll";
std::string exe_dir() {
  char buf[4096];
  DWORD n = GetModuleFileNameA(nullptr, buf, sizeof buf);
  std::string s(buf, n);
  return s.substr(0, s.find_last_of("\\/"));
}
std::wstring ort_path(const std::string& p) { return std::wstring(p.begin(), p.end()); }
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

struct Graph {
  std::string path;
  Ort::Session session{nullptr};
  std::vector<std::string> in_names, out_names;
  std::vector<std::vector<int64_t>> in_shapes, out_shapes;
  std::vector<ONNXTensorElementDataType> in_types;
};

// Never destroyed: tearing ONNX Runtime down in static destructors hangs the process on Windows (the tool _Exits).
Ort::Env* env = nullptr;
std::vector<Graph*> graphs;
std::string error;

int fail(const std::string& msg) {
  error = msg;
  fprintf(stderr, "npu graph: %s\n", msg.c_str());
  return -1;
}

void ORT_API_CALL log_line(void*, OrtLoggingLevel severity, const char*, const char*, const char* where,
                           const char* message) {
  fprintf(stderr, "[ort %d] %s %s\n", int(severity), where, message);
}

Ort::Env& get_env() {
  if (!env) {
    const char* log = getenv("NPU_LOG");
    env = new Ort::Env(log ? ORT_LOGGING_LEVEL_VERBOSE : ORT_LOGGING_LEVEL_WARNING, "npu");
  }
  return *env;
}

Ort::SessionOptions options(const std::string& ctx_out) {
  Ort::SessionOptions so;
  so.SetIntraOpNumThreads(1);
  const char* opt = getenv("NPU_OPT");
  std::unordered_map<std::string, std::string> qnn = {
      {"backend_path", exe_dir() + "/" + QNN_HTP},
      {"htp_performance_mode", "burst"},
      {"htp_graph_finalization_optimization_mode", opt ? opt : "3"},
      {"enable_htp_fp16_precision", "1"},
  };
  // File-mapped weights: where the HTP lacks them (the X1 Elite's V73), ONNX Runtime 1.24.4's fallback reads a large
  // context binary out of bounds (an access violation in memcpy); off unless NPU_FILE_MAP=1.
  if (!getenv("NPU_FILE_MAP")) qnn["disable_file_mapped_weights"] = "1";
  // NPU_PROFILE=basic|detailed|optrace: QNN's profile of each run (per op with detailed), as CSV to NPU_PROFILE_FILE
  // (default qnn_profile.csv in the working directory).
  if (const char* prof = getenv("NPU_PROFILE")) {
    qnn["profiling_level"] = prof;
    const char* f = getenv("NPU_PROFILE_FILE");
    qnn["profiling_file_path"] = f ? f : "qnn_profile.csv";
  }
  so.AppendExecutionProvider("QNN", qnn);
  if (!getenv("NPU_FALLBACK")) so.AddConfigEntry("session.disable_cpu_ep_fallback", "1");
  if (!ctx_out.empty()) {
    so.AddConfigEntry("ep.context_enable", "1");
    so.AddConfigEntry("ep.context_file_path", ctx_out.c_str());
    so.AddConfigEntry("ep.context_embed_mode", getenv("NPU_EMBED") ? "1" : "0");  // NPU_EMBED=1: inside the .onnx
  }
  return so;
}

int64_t numel(const std::vector<int64_t>& s) {
  int64_t n = 1;
  for (auto d : s) n *= d < 0 ? 1 : d;
  return n;
}

}  // namespace

extern "C" {

const char* npug_error() { return error.c_str(); }

int npug_compile(const char* model, const char* ctx_out, double* ms) {
  try {
    double t0 = now_ms();
    new Ort::Session(get_env(), ort_path(model).c_str(), options(ctx_out));  // saved as it is created; never freed
    if (ms) *ms = now_ms() - t0;
    return 0;
  } catch (const std::exception& e) {
    return fail(std::string("compile ") + model + ": " + e.what());
  }
}

int npug_open(const char* ctx, double* ms) {
  // A context already open (by a server's earlier client) is shared, not loaded again.
  for (size_t i = 0; i < graphs.size(); i++)
    if (graphs[i]->path == ctx) {
      if (ms) *ms = 0;
      return int(i);
    }
  try {
    double t0 = now_ms();
    auto g = new Graph();
    g->path = ctx;
    g->session = Ort::Session(get_env(), ort_path(ctx).c_str(), options(""));
    Ort::AllocatorWithDefaultOptions alloc;
    for (size_t i = 0; i < g->session.GetInputCount(); i++) {
      g->in_names.push_back(g->session.GetInputNameAllocated(i, alloc).get());
      auto type = g->session.GetInputTypeInfo(i);  // owns what info views: keep it alive while info is used
      auto info = type.GetTensorTypeAndShapeInfo();
      g->in_shapes.push_back(info.GetShape());
      g->in_types.push_back(info.GetElementType());
    }
    for (size_t i = 0; i < g->session.GetOutputCount(); i++) {
      g->out_names.push_back(g->session.GetOutputNameAllocated(i, alloc).get());
      g->out_shapes.push_back(g->session.GetOutputTypeInfo(i).GetTensorTypeAndShapeInfo().GetShape());
    }
    graphs.push_back(g);
    if (ms) *ms = now_ms() - t0;
    return int(graphs.size()) - 1;
  } catch (const std::exception& e) {
    return fail(std::string("open ") + ctx + ": " + e.what());
  }
}

const char* npug_name(int h, int output, int i) {
  if (h < 0 || h >= int(graphs.size())) return nullptr;
  auto& names = output ? graphs[h]->out_names : graphs[h]->in_names;
  return i >= 0 && i < int(names.size()) ? names[i].c_str() : nullptr;
}

int npug_close(int h) {
  if (h < 0 || h >= int(graphs.size())) return fail("no such graph");
  graphs[h]->session = Ort::Session(nullptr);  // the context's memory goes; the handle stays (unusable)
  graphs[h]->path.clear();
  return 0;
}

int npug_count(int h, int output) {
  if (h < 0 || h >= int(graphs.size())) return -1;
  return int(output ? graphs[h]->out_names.size() : graphs[h]->in_names.size());
}

int64_t npug_numel(int h, int output, int i) {
  if (h < 0 || h >= int(graphs.size())) return -1;
  auto& shapes = output ? graphs[h]->out_shapes : graphs[h]->in_shapes;
  if (i < 0 || i >= int(shapes.size())) return -1;
  return numel(shapes[i]);
}

int npug_input_is_int(int h, int i) {
  if (h < 0 || h >= int(graphs.size()) || i < 0 || i >= int(graphs[h]->in_types.size())) return -1;
  return graphs[h]->in_types[i] == ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32 ? 1 : 0;
}

int npug_run(int h, const void* const* inputs, float* const* outputs, double* ms) {
  if (h < 0 || h >= int(graphs.size())) return fail("no such graph");
  auto& g = *graphs[h];
  try {
    auto mem = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
    std::vector<Ort::Value> in, out;
    std::vector<const char*> in_names, out_names;
    for (size_t i = 0; i < g.in_names.size(); i++) {
      auto& sh = g.in_shapes[i];
      if (g.in_types[i] == ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32)
        in.push_back(Ort::Value::CreateTensor<int32_t>(mem, (int32_t*)inputs[i], numel(sh), sh.data(), sh.size()));
      else if (g.in_types[i] == ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT)
        in.push_back(Ort::Value::CreateTensor<float>(mem, (float*)inputs[i], numel(sh), sh.data(), sh.size()));
      else
        return fail("input " + g.in_names[i] + ": only fp32 and int32 inputs");
      in_names.push_back(g.in_names[i].c_str());
    }
    for (size_t i = 0; i < g.out_names.size(); i++) {
      auto& sh = g.out_shapes[i];
      out.push_back(Ort::Value::CreateTensor<float>(mem, outputs[i], numel(sh), sh.data(), sh.size()));
      out_names.push_back(g.out_names[i].c_str());
    }
    double t0 = now_ms();
    g.session.Run(Ort::RunOptions{nullptr}, in_names.data(), in.data(), in.size(), out_names.data(), out.data(),
                  out.size());
    if (ms) *ms = now_ms() - t0;
    return 0;
  } catch (const std::exception& e) {
    return fail(std::string("run: ") + e.what());
  }
}

}  // extern "C"

#ifdef NPU_TOOL
static std::vector<char> read_file(const std::string& p) {
  std::ifstream f(p, std::ios::binary);
  return std::vector<char>((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

static int tool(int argc, char** argv);

#ifdef _WIN32
// A crash says where it happened (module and offset) before the process dies; stdout is unbuffered so nothing printed
// before it is lost.
static LONG WINAPI on_crash(EXCEPTION_POINTERS* e) {
  void* at = e->ExceptionRecord->ExceptionAddress;
  HMODULE mod = NULL;
  char name[MAX_PATH] = "?";
  if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                         (LPCSTR)at, &mod))
    GetModuleFileNameA(mod, name, sizeof name);
  fprintf(stderr, "graph_tool: exception 0x%08lx at %s+0x%llx", (unsigned long)e->ExceptionRecord->ExceptionCode, name,
          (unsigned long long)((char*)at - (char*)mod));
  if (e->ExceptionRecord->ExceptionCode == EXCEPTION_ACCESS_VIOLATION && e->ExceptionRecord->NumberParameters >= 2)
    fprintf(stderr, " (%s address 0x%llx)", e->ExceptionRecord->ExceptionInformation[0] ? "writing" : "reading",
            (unsigned long long)e->ExceptionRecord->ExceptionInformation[1]);
  fprintf(stderr, "\n");
#if defined(_M_ARM64) || defined(__aarch64__)
  CONTEXT c = *e->ContextRecord;  // the callers, by unwinding from the faulting frame
  for (int i = 0; i < 12 && c.Pc; i++) {
    DWORD64 base = 0;
    PRUNTIME_FUNCTION f = RtlLookupFunctionEntry(c.Pc, &base, NULL);
    if (f) {
      void* hd;
      DWORD64 ef;
      RtlVirtualUnwind(UNW_FLAG_NHANDLER, base, c.Pc, f, &c, &hd, &ef, NULL);
    } else {
      c.Pc = c.Lr;  // a leaf
    }
    mod = NULL;
    strcpy(name, "?");
    if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                           (LPCSTR)c.Pc, &mod))
      GetModuleFileNameA(mod, name, sizeof name);
    const char* tail = strrchr(name, '\\');
    fprintf(stderr, "  called from %s+0x%llx\n", tail ? tail + 1 : name, (unsigned long long)(c.Pc - (DWORD64)mod));
  }
#endif
  fflush(stderr);
  return EXCEPTION_CONTINUE_SEARCH;
}
#endif

int main(int argc, char** argv) {
#ifdef _WIN32
  SetUnhandledExceptionFilter(on_crash);
#endif
  setvbuf(stdout, NULL, _IONBF, 0);
  int rc = tool(argc, argv);
  fflush(stdout);
  fflush(stderr);
  _Exit(rc);  // skip ONNX Runtime's teardown (see env above)
}

// graph_tool chain <runs> <context.onnx> <inputs...> [+ <context.onnx> <inputs...>]... [-o <dir>]
// Graphs run back to back in one process, each run timed end to end; an input "@g:i" is output i of graph g (0-based,
// in chain order), passed as the same host buffer. Outputs (fp32) written as <dir>/<g>_<name>.f32.
static int chain(int argc, char** argv) {
  int runs = atoi(argv[2]);
  struct Step {
    int h;
    std::vector<std::string> args;
  };
  std::vector<Step> steps;
  std::string outdir;
  for (int a = 3; a < argc; a++) {
    std::string s = argv[a];
    if (s == "-o" && a + 1 < argc) {
      outdir = argv[++a];
    } else if (s == "+" || steps.empty()) {
      if (s == "+" && a + 1 >= argc) return fail("+ needs a context"), 1;
      if (s == "+") s = argv[++a];
      double ms = 0;
      int h = npug_open(s.c_str(), &ms);
      if (h < 0) return 1;
      printf("graph %zu: %s opened in %.1f ms\n", steps.size(), s.c_str(), ms);
      steps.push_back({h, {}});
    } else {
      steps.back().args.push_back(s);
    }
  }
  std::vector<std::vector<std::vector<float>>> out(steps.size());
  std::vector<std::vector<char>> files;
  files.reserve(256);
  std::vector<std::vector<const void*>> ip(steps.size());
  std::vector<std::vector<float*>> op(steps.size());
  for (size_t g = 0; g < steps.size(); g++) {
    int h = steps[g].h;
    out[g].resize(npug_count(h, 1));
    for (int i = 0; i < int(out[g].size()); i++) {
      out[g][i].resize(npug_numel(h, 1, i));
      op[g].push_back(out[g][i].data());
    }
    if (int(steps[g].args.size()) != npug_count(h, 0))
      return fail("graph " + std::to_string(g) + " needs " + std::to_string(npug_count(h, 0)) + " inputs"), 1;
    for (int i = 0; i < int(steps[g].args.size()); i++) {
      auto& s = steps[g].args[i];
      int64_t bytes;
      if (s[0] == '@') {
        size_t c = s.find(':');
        int src = atoi(s.substr(1, c - 1).c_str()), k = atoi(s.substr(c + 1).c_str());
        if (src < 0 || src >= int(g) || k < 0 || k >= int(out[src].size())) return fail("bad reference " + s), 1;
        ip[g].push_back(out[src][k].data());
        bytes = int64_t(out[src][k].size()) * 4;
      } else {
        files.push_back(read_file(s));
        ip[g].push_back(files.back().data());
        bytes = int64_t(files.back().size());
      }
      if (bytes != npug_numel(h, 0, i) * 4)
        return fail("graph " + std::to_string(g) + " input " + std::to_string(i) + ": " + std::to_string(bytes) +
                    " bytes, want " + std::to_string(npug_numel(h, 0, i) * 4)), 1;
    }
  }
  for (int r = 0; r < runs; r++) {
    double t0 = now_ms(), ms = 0;
    std::string each;
    for (size_t g = 0; g < steps.size(); g++) {
      if (npug_run(steps[g].h, ip[g].data(), op[g].data(), &ms)) return 1;
      char b[32];
      snprintf(b, sizeof b, "%s%.2f", g ? " + " : "", ms);
      each += b;
    }
    printf("run %d: %.2f ms (%s)\n", r, now_ms() - t0, each.c_str());
  }
  if (!outdir.empty()) {
    for (size_t g = 0; g < steps.size(); g++)
      for (int i = 0; i < int(out[g].size()); i++) {
        std::ofstream f(outdir + "/" + std::to_string(g) + "_" + graphs[steps[g].h]->out_names[i] + ".f32",
                        std::ios::binary);
        f.write((const char*)out[g][i].data(), out[g][i].size() * 4);
      }
    printf("outputs in %s\n", outdir.c_str());
  }
  return 0;
}

// graph_tool serve <port> <context.onnx> <inputs...> [+ <context.onnx> <inputs...>]...
// A chain (as chain's arguments) kept open for a client on 127.0.0.1:<port> (through ssh -L from another machine), one
// client at a time. An input is a file (its initial content), @g:i (graph g's output i) or - (zeros until set). Every
// input that is not an @ reference is a slot, numbered in chain order. Requests, little-endian:
//   SET  {u32 1, u32 slot, u32 format, u32 0, u64 n} + n bytes   the slot's content: format 0 the graph's own type
//                                                                (fp32 or int32), 1 fp16 for an fp32 input, 2 images
//                                                                as PNG for an fp32 [.., V, 3, H, W] input (below);
//                                                                answer {i32 status, u32 0, f64 0}
//   GET  {u32 3, u32 slot, u32 0, u32 0, u64 0}                  answer {i32 status, u32 n, f64 0} + the slot's bytes
//   RUN  {u32 2, u32 0, u32 0, u32 0, u64 0}                     the chain once; answer {i32 status, u32 n, f64 ms}
//                                                                + n bytes: the last graph's outputs (fp32), in order
// Format 2 (camera frames through a slow link): {u32 V, f32 mean[3], f32 std[3]} then V times {u32 length, PNG bytes},
// each an H x W RGB image; the slot gets (x * (1/255) - mean[c]) / std[c] in fp32, channels first, view by view, the
// arithmetic of the policies' own preprocessors (x / 255 normalized with the backbone's mean and std).
// A failed request answers status 1 with the message as its n bytes. The client sends RUN after its SETs; inputs
// keep their content between runs (an instruction's tensors are set once).
#ifdef _WIN32
#include <winsock2.h>
typedef SOCKET sock_t;
#define CLOSESOCK closesocket
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
typedef int sock_t;
#define CLOSESOCK close
#define INVALID_SOCKET (-1)
#endif

static bool io_all(sock_t c, void* data, size_t n, bool out) {
  char* p = (char*)data;
  while (n) {
    int k = out ? send(c, p, n > (1u << 30) ? (1 << 30) : (int)n, 0) : recv(c, p, n > (1u << 30) ? (1 << 30) : (int)n, 0);
    if (k <= 0) return false;
    p += k;
    n -= (size_t)k;
  }
  return true;
}

static float f16_to_f32(uint16_t h) {
  uint32_t sign = (uint32_t)(h & 0x8000) << 16, e = (h >> 10) & 0x1f, m = h & 0x3ff, bits;
  if (e == 0) {
    if (m == 0) bits = sign;
    else {  // subnormal: normalize
      e = 127 - 15 + 1;
      while (!(m & 0x400)) { m <<= 1; e--; }
      bits = sign | (e << 23) | ((m & 0x3ff) << 13);
    }
  } else if (e == 31) bits = sign | 0x7f800000 | (m << 13);
  else bits = sign | ((e + 127 - 15) << 23) | (m << 13);
  float f;
  memcpy(&f, &bits, 4);
  return f;
}

#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
#define STBI_NO_STDIO
#include "third_party/stb_image.h"

// SET format 2: V PNG images into an fp32 [.., V, 3, H, W] slot of `bytes` bytes; an empty string on success.
static std::string set_png(const std::vector<char>& in, std::vector<char>& slot) {
  if (in.size() < 28) return "PNG set: short header";
  uint32_t nv;
  float mean[3], sd[3];
  memcpy(&nv, in.data(), 4);
  memcpy(mean, in.data() + 4, 12);
  memcpy(sd, in.data() + 16, 12);
  if (nv == 0 || slot.size() % (nv * 3 * 4)) return "PNG set: the slot is not V x 3 x H x W fp32";
  size_t hw = slot.size() / (nv * 3 * 4), at = 28;
  float* dst = (float*)slot.data();
  const float scale = 1.0f / 255.0f;
  for (uint32_t v = 0; v < nv; v++) {
    uint32_t len;
    if (at + 4 > in.size()) return "PNG set: truncated";
    memcpy(&len, in.data() + at, 4);
    at += 4;
    if (at + len > in.size()) return "PNG set: truncated";
    int w, h, c;
    unsigned char* px = stbi_load_from_memory((const unsigned char*)in.data() + at, (int)len, &w, &h, &c, 3);
    at += len;
    if (!px) return std::string("PNG set: ") + stbi_failure_reason();
    if (size_t(w) * size_t(h) != hw) {
      stbi_image_free(px);
      return "PNG set: image " + std::to_string(w) + " x " + std::to_string(h) + " does not fit the slot";
    }
    for (int ch = 0; ch < 3; ch++)
      for (size_t i = 0; i < hw; i++) dst[(v * 3 + ch) * hw + i] = ((float)px[3 * i + ch] * scale - mean[ch]) / sd[ch];
    stbi_image_free(px);
  }
  return "";
}

static int serve(int argc, char** argv) {
  int port = atoi(argv[2]);
  struct Step {
    int h;
    std::vector<std::string> args;
  };
  std::vector<Step> steps;
  for (int a = 3; a < argc; a++) {
    std::string s = argv[a];
    if (s == "+" || steps.empty()) {
      if (s == "+") s = argv[++a];
      double ms = 0;
      int h = npug_open(s.c_str(), &ms);
      if (h < 0) return 1;
      printf("graph %zu: %s opened in %.1f ms\n", steps.size(), s.c_str(), ms);
      steps.push_back({h, {}});
    } else {
      steps.back().args.push_back(s);
    }
  }
  std::vector<std::vector<std::vector<float>>> out(steps.size());
  std::vector<std::vector<std::vector<char>>> slots_in(steps.size());  // each step's own input buffers
  std::vector<std::vector<const void*>> ip(steps.size());
  std::vector<std::vector<float*>> op(steps.size());
  struct Slot {
    std::vector<char>* buf;
    bool fp32;
  };
  std::vector<Slot> slots;
  for (size_t g = 0; g < steps.size(); g++) {
    int h = steps[g].h;
    out[g].resize(npug_count(h, 1));
    for (int i = 0; i < int(out[g].size()); i++) {
      out[g][i].resize(npug_numel(h, 1, i));
      op[g].push_back(out[g][i].data());
    }
    if (int(steps[g].args.size()) != npug_count(h, 0))
      return fail("graph " + std::to_string(g) + " needs " + std::to_string(npug_count(h, 0)) + " inputs"), 1;
    slots_in[g].reserve(steps[g].args.size());
    for (int i = 0; i < int(steps[g].args.size()); i++) {
      auto& s = steps[g].args[i];
      int64_t bytes = npug_numel(h, 0, i) * 4;
      if (s[0] == '@') {
        size_t c = s.find(':');
        int src = atoi(s.substr(1, c - 1).c_str()), k = atoi(s.substr(c + 1).c_str());
        if (src < 0 || src >= int(g) || k < 0 || k >= int(out[src].size())) return fail("bad reference " + s), 1;
        ip[g].push_back(out[src][k].data());
        continue;
      }
      slots_in[g].push_back(s == "-" ? std::vector<char>(bytes, 0) : read_file(s));
      auto& b = slots_in[g].back();
      if (int64_t(b.size()) != bytes)
        return fail("graph " + std::to_string(g) + " input " + std::to_string(i) + ": " + std::to_string(b.size()) +
                    " bytes, want " + std::to_string(bytes)), 1;
      ip[g].push_back(b.data());
      slots.push_back({&b, graphs[h]->in_types[i] == ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT});
      printf("slot %zu: graph %zu input %d (%s), %lld bytes\n", slots.size() - 1, g, i, graphs[h]->in_names[i].c_str(),
             (long long)bytes);
    }
  }
#ifdef _WIN32
  WSADATA wsa;
  WSAStartup(MAKEWORD(2, 2), &wsa);
#endif
  sock_t s = socket(AF_INET, SOCK_STREAM, 0);
  int one = 1;
  setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char*)&one, sizeof one);
  sockaddr_in addr = {};
  addr.sin_family = AF_INET;
  addr.sin_port = htons((uint16_t)port);
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  if (bind(s, (sockaddr*)&addr, sizeof addr) || listen(s, 1)) return fail("serve: cannot listen on the port"), 1;
  printf("serving on 127.0.0.1:%d\n", port);
  std::vector<char> payload, reply;
  for (;;) {
    sock_t c = accept(s, NULL, NULL);
    if (c == INVALID_SOCKET) continue;
    setsockopt(c, IPPROTO_TCP, TCP_NODELAY, (const char*)&one, sizeof one);
    printf("client connected\n");
    uint32_t hdr[6];  // op, slot, format, 0, n (u64)
    while (io_all(c, hdr, sizeof hdr, false)) {
      uint64_t n;
      memcpy(&n, hdr + 4, 8);
      payload.resize(n);
      if (n && !io_all(c, payload.data(), n, false)) break;
      int32_t status = 0;
      uint32_t rn = 0;
      double ms = 0;
      std::string msg;
      reply.clear();
      if (hdr[0] == 1) {
        if (hdr[1] >= slots.size()) msg = "no such slot";
        else {
          auto& sl = slots[hdr[1]];
          if (hdr[2] == 2 && sl.fp32) {
            msg = set_png(payload, *sl.buf);
          } else if (hdr[2] == 1 && sl.fp32 && n * 2 == sl.buf->size()) {
            const uint16_t* hp = (const uint16_t*)payload.data();
            float* fp = (float*)sl.buf->data();
            for (uint64_t i = 0; i < n / 2; i++) fp[i] = f16_to_f32(hp[i]);
          } else if (hdr[2] == 0 && n == sl.buf->size()) {
            memcpy(sl.buf->data(), payload.data(), n);
          } else {
            msg = "slot " + std::to_string(hdr[1]) + ": " + std::to_string(n) + " bytes in format " +
                  std::to_string(hdr[2]) + ", want " + std::to_string(sl.buf->size()) + " (fp32/int32)";
          }
        }
      } else if (hdr[0] == 3) {
        if (hdr[1] >= slots.size()) msg = "no such slot";
        else reply.assign(slots[hdr[1]].buf->begin(), slots[hdr[1]].buf->end());
      } else if (hdr[0] == 2) {
        double t0 = now_ms(), each = 0;
        for (size_t g = 0; g < steps.size() && msg.empty(); g++)
          if (npug_run(steps[g].h, ip[g].data(), op[g].data(), &each)) msg = error;
        ms = now_ms() - t0;
        if (msg.empty())
          for (auto& o : out.back()) reply.insert(reply.end(), (char*)o.data(), (char*)(o.data() + o.size()));
      } else {
        msg = "unknown request";
      }
      if (!msg.empty()) {
        status = 1;
        reply.assign(msg.begin(), msg.end());
      }
      rn = (uint32_t)reply.size();
      char head[16];
      memcpy(head, &status, 4);
      memcpy(head + 4, &rn, 4);
      memcpy(head + 8, &ms, 8);
      if (!io_all(c, head, 16, true) || (rn && !io_all(c, reply.data(), rn, true))) break;
    }
    CLOSESOCK(c);
    printf("client left\n");
  }
}

static int tool(int argc, char** argv) {
  if (argc >= 4 && std::string(argv[1]) == "chain") return chain(argc, argv);
  if (argc >= 4 && std::string(argv[1]) == "serve") return serve(argc, argv);
  if (argc == 4 && std::string(argv[1]) == "compile") {
    double ms = 0;
    if (npug_compile(argv[2], argv[3], &ms)) return 1;
    printf("compiled %s into %s in %.1f s\n", argv[2], argv[3], ms / 1e3);
    return 0;
  }
  if (argc < 4 || std::string(argv[1]) != "run") {
    fprintf(stderr, "usage: graph_tool compile <model.onnx> <context.onnx> | run <context.onnx> <runs> <inputs...> "
                    "[-o <dir>] | chain <runs> <context.onnx> <inputs...> [+ <context.onnx> <inputs...>]... "
                    "[-o <dir>] | serve <port> <context.onnx> <inputs or -...> [+ ...]...\n");
    return 2;
  }
  double ms = 0;
  int h = npug_open(argv[2], &ms);
  if (h < 0) return 1;
  printf("opened %s in %.1f ms: %d inputs, %d outputs\n", argv[2], ms, npug_count(h, 0), npug_count(h, 1));
  int runs = atoi(argv[3]);
  std::vector<std::vector<char>> in;
  std::string outdir;
  for (int a = 4; a < argc; a++) {
    if (std::string(argv[a]) == "-o" && a + 1 < argc) {
      outdir = argv[++a];
      continue;
    }
    in.push_back(read_file(argv[a]));
  }
  if (int(in.size()) != npug_count(h, 0)) return fail("need " + std::to_string(npug_count(h, 0)) + " inputs"), 1;
  std::vector<const void*> ip;
  for (int i = 0; i < int(in.size()); i++) {
    if (int64_t(in[i].size()) != npug_numel(h, 0, i) * 4)
      return fail("input " + std::to_string(i) + ": " + std::to_string(in[i].size()) + " bytes, want " +
                  std::to_string(npug_numel(h, 0, i) * 4)), 1;
    ip.push_back(in[i].data());
  }
  std::vector<std::vector<float>> out(npug_count(h, 1));
  std::vector<float*> op;
  for (int i = 0; i < int(out.size()); i++) {
    out[i].resize(npug_numel(h, 1, i));
    op.push_back(out[i].data());
  }
  for (int r = 0; r < runs; r++) {
    if (npug_run(h, ip.data(), op.data(), &ms)) return 1;
    printf("run %d: %.2f ms\n", r, ms);
  }
  if (!outdir.empty()) {
    auto& g = *graphs[h];
    for (int i = 0; i < int(out.size()); i++) {
      std::ofstream f(outdir + "/" + g.out_names[i] + ".f32", std::ios::binary);
      f.write((const char*)out[i].data(), out[i].size() * 4);
    }
    printf("outputs in %s\n", outdir.c_str());
  }
  return 0;
}
#endif
