// A Qwen3-MoE layer on the Hexagon NPU (HTP) of the Snapdragon X2 Elite laptop, through ONNX Runtime's QNN execution
// provider (Microsoft.ML.OnnxRuntime.QNN 1.24.4 for Windows on ARM): compile an ONNX graph to an HTP context once, then
// load it, bind raw input files and time runs. Built by qwen3moe/npu/build_win.sh (Zig, aarch64-windows-gnu).
//
//   npu_run compile <model.onnx> <context.onnx>         compile for the HTP (fp16), save the context
//   npu_run run <context.onnx> <runs> <out prefix> <input files...>
//       the inputs in the model's order, raw (their element type and shape); writes each output to
//       <out prefix><name>.bin and prints each run's time
// Every node must run on the HTP (CPU fallback is disabled). NPU_OPT=<0..3>: QNN's finalization mode (default 3).
#include <onnxruntime_cxx_api.h>

#include <windows.h>

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>

static double now_ms() {
  return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

static std::string exe_dir() {
  char buf[4096];
  DWORD n = GetModuleFileNameA(nullptr, buf, sizeof buf);
  std::string s(buf, n);
  return s.substr(0, s.find_last_of("\\/"));
}

static std::wstring wide(const std::string& s) { return std::wstring(s.begin(), s.end()); }

static void ORT_API_CALL log_line(void*, OrtLoggingLevel severity, const char*, const char*, const char* where,
                                  const char* message) {
  fprintf(stderr, "[ort %d] %s %s\n", int(severity), where, message);
}

static Ort::SessionOptions options(const std::string& ctx_out) {
  Ort::SessionOptions so;
  so.SetIntraOpNumThreads(1);
  const char* opt = getenv("NPU_OPT");
  std::unordered_map<std::string, std::string> qnn = {
      {"backend_path", exe_dir() + "\\QnnHtp.dll"},
      {"htp_performance_mode", "burst"},
      {"htp_graph_finalization_optimization_mode", opt ? opt : "3"},
  };
  so.AppendExecutionProvider("QNN", qnn);
  so.AddConfigEntry("session.disable_cpu_ep_fallback", "1");
  if (!ctx_out.empty()) {
    so.AddConfigEntry("ep.context_enable", "1");
    so.AddConfigEntry("ep.context_file_path", ctx_out.c_str());
    so.AddConfigEntry("ep.context_embed_mode", "0");
  }
  return so;
}

static size_t elem_size(ONNXTensorElementDataType t) {
  switch (t) {
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16: return 2;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT: return 4;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32: return 4;
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64: return 8;
    default: return 0;
  }
}

int main(int argc, char** argv) {
  const char* log = getenv("NPU_LOG");
  Ort::Env env(log ? ORT_LOGGING_LEVEL_VERBOSE : ORT_LOGGING_LEVEL_WARNING, "npu_run", log_line, nullptr);
  try {
    if (argc == 4 && std::string(argv[1]) == "compile") {
      double t0 = now_ms();
      Ort::Session s(env, wide(argv[2]).c_str(), options(argv[3]));
      printf("compiled %s into %s in %.1f s\n", argv[2], argv[3], (now_ms() - t0) / 1e3);
      return 0;
    }
    if (argc < 5 || std::string(argv[1]) != "run") {
      fprintf(stderr, "usage: npu_run compile <model.onnx> <ctx.onnx> | run <ctx.onnx> <runs> <out prefix> <inputs...>\n");
      return 2;
    }
    double t0 = now_ms();
    Ort::Session s(env, wide(argv[2]).c_str(), options(""));
    printf("loaded %s in %.2f s\n", argv[2], (now_ms() - t0) / 1e3);
    int runs = atoi(argv[3]);
    std::string prefix = argv[4];
    Ort::MemoryInfo cpu = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
    Ort::AllocatorWithDefaultOptions alloc;
    Ort::IoBinding b(s);
    std::vector<std::vector<char>> data;
    std::vector<Ort::Value> vals;
    std::vector<std::string> out_names;
    data.reserve(s.GetInputCount() + s.GetOutputCount());
    if (size_t(argc - 5) != s.GetInputCount()) {
      fprintf(stderr, "the model has %zu inputs, %d files given\n", s.GetInputCount(), argc - 5);
      return 2;
    }
    for (size_t i = 0; i < s.GetInputCount(); i++) {
      auto info = s.GetInputTypeInfo(i).GetTensorTypeAndShapeInfo();
      std::vector<int64_t> shape = info.GetShape();
      size_t n = elem_size(info.GetElementType()) * info.GetElementCount();
      std::ifstream f(argv[5 + i], std::ios::binary);
      data.emplace_back((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
      if (data.back().size() != n) {
        fprintf(stderr, "%s: %zu bytes, the input takes %zu\n", argv[5 + i], data.back().size(), n);
        return 2;
      }
      vals.push_back(Ort::Value::CreateTensor(cpu, data.back().data(), n, shape.data(), shape.size(),
                                              info.GetElementType()));
      b.BindInput(s.GetInputNameAllocated(i, alloc).get(), vals.back());
    }
    for (size_t i = 0; i < s.GetOutputCount(); i++) {
      auto info = s.GetOutputTypeInfo(i).GetTensorTypeAndShapeInfo();
      std::vector<int64_t> shape = info.GetShape();
      size_t n = elem_size(info.GetElementType()) * info.GetElementCount();
      data.emplace_back(n);
      vals.push_back(Ort::Value::CreateTensor(cpu, data.back().data(), n, shape.data(), shape.size(),
                                              info.GetElementType()));
      out_names.push_back(s.GetOutputNameAllocated(i, alloc).get());
      b.BindOutput(out_names.back().c_str(), vals.back());
    }
    Ort::RunOptions ro;
    for (int r = 0; r < runs; r++) {
      double t = now_ms();
      s.Run(ro, b);
      printf("run %d: %.2f ms\n", r, now_ms() - t);
      fflush(stdout);
    }
    for (size_t i = 0; i < out_names.size(); i++) {
      const std::vector<char>& d = data[s.GetInputCount() + i];
      FILE* f = fopen((prefix + out_names[i] + ".bin").c_str(), "wb");
      fwrite(d.data(), 1, d.size(), f);
      fclose(f);
    }
    printf("done\n");
  } catch (const Ort::Exception& e) {
    fprintf(stderr, "npu_run: %s\n", e.what());
    return 1;
  }
  return 0;
}
