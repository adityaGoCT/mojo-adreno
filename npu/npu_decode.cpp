// Llama 3.2 1B entirely on the Hexagon NPU: the prompt through npu_prefill.cpp's prefill graphs, then decode one
// token at a time through npu/export_decode.py's graphs (decode<i>.onnx), against a KV cache in host memory that the
// HTP reads every step. Built by npu/build.py decode, linked with npu_prefill.cpp (its C interface, unchanged).
//
//   npu_decode compile <dir> <i>                 compile decode<i>.onnx for the HTP and save its context, once
//   npu_decode <dir> <max new> <token ids...>    prefill, then greedy decode; prints llama.mojo's "tok <id> <ms>"
//
// <dir> holds the prefill parts (part<i>_ctx.onnx), the decode parts (decode<i>_ctx.onnx), weights.bin and
// manifest.txt. The prefill graphs' K/V outputs are bound to the decode cache, so the prefill writes it directly.
// The prefill contexts are released before the decode contexts load: both together are 5 GB.
//   NPU_RUNS=<k>   prefills before the one decode starts from (default 2)
//   LLAMA_EOS      stop tokens, as llama.mojo
#include <onnxruntime_cxx_api.h>

#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

extern "C" {  // npu_prefill.cpp
int npu_open(const char* dir, const char* model_dir, double* ms, int* compiled);
int npu_rows();
int npu_prefill(const int32_t* tokens, int n, double* ms);
int npu_kv_slots();
int npu_bind_kv(int layer, int which, void* buf);
void npu_logits(float* dst);
void npu_close();
}

namespace {

constexpr int D = 2048, L = 16, KVH = 8, HD = 64, V = 128256, CHUNK_ROWS = V / 4, CTX = 512;

double now_ms() {
  return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

std::string exe_dir() {
  char buf[4096];
  ssize_t n = readlink("/proc/self/exe", buf, sizeof buf - 1);
  if (n <= 0) return ".";
  buf[n] = 0;
  std::string s(buf);
  return s.substr(0, s.rfind('/'));
}

void ORT_API_CALL log_line(void*, OrtLoggingLevel severity, const char*, const char*, const char* where,
                           const char* message) {
  fprintf(stderr, "[ort %d] %s %s\n", int(severity), where, message);
}

Ort::SessionOptions options(const std::string& ctx_out) {
  Ort::SessionOptions so;
  so.SetIntraOpNumThreads(1);
  so.AppendExecutionProvider("QNN", {{"backend_path", exe_dir() + "/libQnnHtp.so"},
                                     {"htp_performance_mode", "burst"},
                                     {"htp_graph_finalization_optimization_mode", "3"}});
  so.AddConfigEntry("session.disable_cpu_ep_fallback", "1");
  if (!ctx_out.empty()) {
    so.AddConfigEntry("ep.context_enable", "1");
    so.AddConfigEntry("ep.context_file_path", ctx_out.c_str());
    so.AddConfigEntry("ep.context_embed_mode", "0");
  }
  return so;
}

void set_adsp_path() {
  if (!getenv("ADSP_LIBRARY_PATH")) {
    std::string p = exe_dir() + ";/vendor/dsp/cdsp;/vendor/lib/rfsa/adsp;/system/lib/rfsa/adsp;/dsp";
    setenv("ADSP_LIBRARY_PATH", p.c_str(), 1);
  }
}

std::unordered_map<std::string, uint64_t> manifest_offsets(const std::string& dir) {
  std::unordered_map<std::string, uint64_t> off;
  std::ifstream man(dir + "/manifest.txt");
  std::string line;
  std::getline(man, line);
  while (std::getline(man, line)) {
    std::istringstream f(line);
    std::string name;
    uint64_t o, bytes;
    if (f >> name >> o >> bytes) off[name] = o;
  }
  return off;
}

}  // namespace

int main(int argc, char** argv) {
  set_adsp_path();
  if (argc == 4 && std::string(argv[1]) == "compile") {
    double t0 = now_ms();
    Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "npu", log_line, nullptr);
    std::string d(argv[2]), i(argv[3]);
    try {
      Ort::Session s(env, (d + "/decode" + i + ".onnx").c_str(), options(d + "/decode" + i + "_ctx.onnx"));
    } catch (const Ort::Exception& e) {
      fprintf(stderr, "npu: %s\n", e.what());
      return 1;
    }
    printf("decode part %s compiled and saved in %.1f s\n", argv[3], (now_ms() - t0) / 1e3);
    return 0;
  }
  if (argc < 4) {
    fprintf(stderr, "usage: npu_decode compile <dir> <i> | npu_decode <dir> <max new> <token ids...>\n");
    return 2;
  }
  std::string dir = argv[1];
  int max_new = atoi(argv[2]);
  std::vector<int32_t> prompt;
  for (int i = 3; i < argc; i++) prompt.push_back(atoi(argv[i]));
  int n = prompt.size();
  if (n + max_new > CTX) {
    fprintf(stderr, "prompt + new tokens > %d\n", CTX);
    return 2;
  }
  std::vector<int> eos;
  if (const char* e = getenv("LLAMA_EOS")) {
    std::stringstream ss(e);
    std::string t;
    while (std::getline(ss, t, ',')) eos.push_back(atoi(t.c_str()));
  }
  int runs = getenv("NPU_RUNS") ? atoi(getenv("NPU_RUNS")) : 2;

  // Prefill on the NPU, as hybrid does, with each layer's K/V output bound to the decode graphs' cache: the
  // prefill graphs write [8][512][64] fp16 (export.py --kv-slots 512), the cache's own layout, so the prompt's
  // K/V need no copy.
  double ms = 0;
  int compiled = 0;
  if (npu_open(dir.c_str(), dir.c_str(), &ms, &compiled)) return 1;
  printf("npu: prefill graphs loaded in %.2f s\n", ms / 1e3);
  Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "npu", log_line, nullptr);  // holds ORT's environment past npu_close
  std::vector<std::vector<__fp16>> cache(2 * L, std::vector<__fp16>(size_t(KVH) * CTX * HD, 0));  // [l][k, v]
  if (npu_kv_slots() != CTX) {
    fprintf(stderr, "the prefill graphs' K/V hold %d positions, the decode cache %d: export.py --kv-slots %d\n",
            npu_kv_slots(), CTX, CTX);
    return 1;
  }
  for (int l = 0; l < L; l++)
    for (int w = 0; w < 2; w++)
      if (npu_bind_kv(l, w, cache[2 * l + w].data())) return 1;
  for (int r = 0; r <= runs; r++) {
    if (npu_prefill(prompt.data(), n, &ms)) return 1;
    printf("npu prefill %d: %d tokens in %.1f ms (%.0f tokens/s)%s\n", r, n, ms, n * 1e3 / ms, r ? "" : " cold");
  }
  double t_hand = now_ms();
  std::vector<float> logits32(V);
  npu_logits(logits32.data());
  printf("handoff: the prompt's K/V already in the decode cache; the logits in %.2f ms\n", now_ms() - t_hand);
  npu_close();

  // The decode parts, each bound once to the cache and the step's buffers.
  std::ifstream meta(dir + "/decode.txt");
  std::string word;
  int ctx = 0, nparts = 0;
  meta >> word >> word >> ctx >> word >> nparts >> word;
  std::vector<int> bounds(nparts + 1);
  for (int& b : bounds) meta >> b;
  if (!meta || ctx != CTX || bounds[nparts] != L) {
    fprintf(stderr, "%s/decode.txt: not npu/export_decode.py's\n", dir.c_str());
    return 1;
  }
  Ort::MemoryInfo cpu = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
  auto f16 = ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16;
  std::vector<std::vector<__fp16>> x(nparts + 1, std::vector<__fp16>(D));
  std::vector<__fp16> cosv(HD), sinv(HD), mask(CTX + 1, __fp16(-30000.f)), logits(V);
  std::vector<std::vector<__fp16>> knew(2 * L, std::vector<__fp16>(KVH * HD));
  std::vector<Ort::Session> parts;
  std::vector<Ort::IoBinding> bindings;
  std::vector<Ort::Value> values;
  values.reserve(16 * nparts + 64);
  double t_load = now_ms();
  try {
    for (int i = 0; i < nparts; i++) {
      std::string c = dir + "/decode" + std::to_string(i) + "_ctx.onnx";
      parts.emplace_back(env, c.c_str(), options(""));
      Ort::IoBinding b(parts.back());
      auto bind = [&](bool in, const std::string& name, __fp16* p, std::vector<int64_t> shape) {
        size_t count = 1;
        for (int64_t s : shape) count *= s;
        values.push_back(Ort::Value::CreateTensor(cpu, p, count * 2, shape.data(), shape.size(), f16));
        if (in)
          b.BindInput(name.c_str(), values.back());
        else
          b.BindOutput(name.c_str(), values.back());
      };
      bind(true, "x", x[i].data(), {1, D});
      bind(true, "cos", cosv.data(), {1, 1, HD});
      bind(true, "sin", sinv.data(), {1, 1, HD});
      bind(true, "mask", mask.data(), {1, 1, CTX + 1});
      for (int l = bounds[i]; l < bounds[i + 1]; l++) {
        bind(true, "pk" + std::to_string(l), cache[2 * l].data(), {KVH, CTX, HD});
        bind(true, "pv" + std::to_string(l), cache[2 * l + 1].data(), {KVH, CTX, HD});
        bind(false, "k" + std::to_string(l), knew[2 * l].data(), {KVH, 1, HD});
        bind(false, "v" + std::to_string(l), knew[2 * l + 1].data(), {KVH, 1, HD});
      }
      if (i == nparts - 1)
        bind(false, "logits", logits.data(), {1, V});
      else
        bind(false, "x_out", x[i + 1].data(), {1, D});
      bindings.push_back(std::move(b));
    }
  } catch (const Ort::Exception& e) {
    fprintf(stderr, "npu: %s (compile the decode parts first: npu_decode compile %s <i>)\n", e.what(), dir.c_str());
    return 1;
  }
  printf("npu: decode graphs loaded in %.2f s\n", (now_ms() - t_load) / 1e3);

  // The embedding rows and RoPE tables, from weights.bin.
  auto off = manifest_offsets(dir);
  int wfd = open((dir + "/weights.bin").c_str(), O_RDONLY);
  std::vector<float> rcos(CTX * HD / 2), rsin(CTX * HD / 2);
  if (wfd < 0 || pread(wfd, rcos.data(), rcos.size() * 4, off["rope.cos"]) != ssize_t(rcos.size() * 4) ||
      pread(wfd, rsin.data(), rsin.size() * 4, off["rope.sin"]) != ssize_t(rsin.size() * 4)) {
    fprintf(stderr, "%s/weights.bin: cannot read the RoPE tables\n", dir.c_str());
    return 1;
  }
  for (int j = 0; j < n; j++) mask[j] = 0;
  mask[CTX] = 0;  // the new token itself

  auto argmax = [](const float* v, int len) {
    int best = 0;
    for (int i = 1; i < len; i++)
      if (v[i] > v[best]) best = i;
    return best;
  };
  int tok = argmax(logits32.data(), V);
  printf("tok %d 0.0\n", tok);
  int ngen = 1;
  double tgen = 0, first_step = 0;
  std::vector<float> lg(V);
  Ort::RunOptions ro;
  for (int p = n; ngen < max_new; p++) {
    bool stop = false;
    for (int e : eos) stop = stop || tok == e;
    if (stop) break;
    double ts = now_ms();
    int c = tok / CHUNK_ROWS, r = tok % CHUNK_ROWS;
    if (pread(wfd, x[0].data(), D * 2, off["embed." + std::to_string(c)] + uint64_t(r) * D * 2) != D * 2) return 1;
    for (int i = 0; i < HD / 2; i++) {
      cosv[i] = cosv[i + HD / 2] = __fp16(rcos[p * HD / 2 + i]);
      sinv[i] = sinv[i + HD / 2] = __fp16(rsin[p * HD / 2 + i]);
    }
    try {
      for (int i = 0; i < nparts; i++) parts[i].Run(ro, bindings[i]);
    } catch (const Ort::Exception& e) {
      fprintf(stderr, "npu: %s\n", e.what());
      return 1;
    }
    for (int l = 0; l < 2 * L; l++)  // the new token's K/V into slot p of each layer's cache
      for (int h = 0; h < KVH; h++) memcpy(&cache[l][(size_t(h) * CTX + p) * HD], &knew[l][h * HD], HD * 2);
    mask[p] = 0;
    for (int i = 0; i < V; i++) lg[i] = logits[i];
    tok = argmax(lg.data(), V);
    double step = now_ms() - ts;
    if (ngen == 1) first_step = step;
    tgen += step;
    printf("tok %d %.1f\n", tok, step);
    fflush(stdout);
    ngen++;
  }
  if (ngen > 1)
    printf("decode: %d tokens, %.1f ms/token (%.2f tokens/s); after the first step %.1f ms/token\n", ngen - 1,
           tgen / (ngen - 1), (ngen - 1) * 1e3 / tgen, ngen > 2 ? (tgen - first_step) / (ngen - 2) : 0.0);
  printf("done\n");
  return 0;
}
