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
// Environment: NPU_LOG=v (ONNX Runtime's verbose log), NPU_FALLBACK=1 (allow nodes on the CPU; otherwise every node
// must run on the HTP), NPU_OPT=<0..3> (QNN's graph finalization optimization mode, default 3).
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
  so.AppendExecutionProvider("QNN", qnn);
  if (!getenv("NPU_FALLBACK")) so.AddConfigEntry("session.disable_cpu_ep_fallback", "1");
  if (!ctx_out.empty()) {
    so.AddConfigEntry("ep.context_enable", "1");
    so.AddConfigEntry("ep.context_file_path", ctx_out.c_str());
    so.AddConfigEntry("ep.context_embed_mode", "0");
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
      auto info = g->session.GetInputTypeInfo(i).GetTensorTypeAndShapeInfo();
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

int main(int argc, char** argv) {
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

static int tool(int argc, char** argv) {
  if (argc >= 4 && std::string(argv[1]) == "chain") return chain(argc, argv);
  if (argc == 4 && std::string(argv[1]) == "compile") {
    double ms = 0;
    if (npug_compile(argv[2], argv[3], &ms)) return 1;
    printf("compiled %s into %s in %.1f s\n", argv[2], argv[3], ms / 1e3);
    return 0;
  }
  if (argc < 4 || std::string(argv[1]) != "run") {
    fprintf(stderr, "usage: graph_tool compile <model.onnx> <context.onnx> | run <context.onnx> <runs> <inputs...> "
                    "[-o <dir>] | chain <runs> <context.onnx> <inputs...> [+ <context.onnx> <inputs...>]... "
                    "[-o <dir>]\n");
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
