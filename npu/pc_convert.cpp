// The weights.bin and manifest.txt of npu/export.py's per-channel quantized graphs (forms pc8 and pc4), written on
// the phone from the fp16 weights.bin it already has, so the quantized copy is not pushed over adb. export.py
// writes recipe.txt next to its own weights.bin; this program follows it with the same float32 operations as
// npu/quant.py's perchannel, so the output is byte for byte the Mac's (run.py checks the SHA-256).
//
//   pc_convert <fp16 model dir> <recipe.txt> <out dir>
//
// recipe.txt: the manifest's header line, then one line a tensor, in file order:
//   f32 <name> <src>               an fp16 vector as fp32
//   f16 <name> <src>               an fp16 tensor copied
//   pc8 <name> <src> <rows> <cols> per-channel int8: <name>.q (int8 [rows, cols]) and <name>.c (fp32 [rows])
//   pc4 <name> <src> <rows> <cols> per-channel int4: <name>.q (ONNX INT4, packed) and <name>.c
#include <algorithm>
#include <cmath>
#include <cstring>
#include <sys/types.h>
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

std::map<std::string, std::pair<uint64_t, uint64_t>> manifest;
FILE *src, *out;
std::vector<std::string> lines;

float half(uint16_t h) {
  uint32_t s = uint32_t(h >> 15) << 31, e = (h >> 10) & 31, m = h & 1023;
  uint32_t bits;
  if (e == 0) {
    if (m == 0) {
      bits = s;
    } else {  // subnormal
      e = 127 - 15 + 1;
      while (!(m & 1024)) m <<= 1, e--;
      bits = s | (e << 23) | ((m & 1023) << 13);
    }
  } else if (e == 31) {
    bits = s | 0x7f800000 | (m << 13);
  } else {
    bits = s | ((e + 127 - 15) << 23) | (m << 13);
  }
  float f;
  memcpy(&f, &bits, 4);
  return f;
}

std::vector<uint16_t> read16(const std::string &name, uint64_t count) {
  auto it = manifest.find(name);
  if (it == manifest.end()) throw std::runtime_error("no tensor " + name);
  if (it->second.second != count * 2) throw std::runtime_error(name + ": unexpected size");
  std::vector<uint16_t> v(count);
  if (fseeko(src, off_t(it->second.first), SEEK_SET) || fread(v.data(), 2, count, src) != count)
    throw std::runtime_error(name + ": short read");
  return v;
}

void add(const std::string &name, const void *data, uint64_t bytes) {
  static const char zeros[256] = {};
  long pos = ftell(out);
  if (pos % 256) fwrite(zeros, 1, 256 - pos % 256, out);
  pos = ftell(out);
  if (fwrite(data, 1, bytes, out) != bytes) throw std::runtime_error("write failed");
  lines.push_back(name + " " + std::to_string(pos) + " " + std::to_string(bytes));
}

}  // namespace

int main(int argc, char **argv) {
  if (argc != 4) {
    fprintf(stderr, "usage: %s <fp16 model dir> <recipe.txt> <out dir>\n", argv[0]);
    return 2;
  }
  try {
    std::string dir = argv[1], outdir = argv[3];
    std::ifstream man(dir + "/manifest.txt");
    std::string line;
    std::getline(man, line);
    while (std::getline(man, line)) {
      std::istringstream f(line);
      std::string name;
      uint64_t off, bytes;
      if (f >> name >> off >> bytes) manifest[name] = {off, bytes};
    }
    src = fopen((dir + "/weights.bin").c_str(), "rb");
    out = fopen((outdir + "/weights.bin").c_str(), "wb");
    if (!src || !out) throw std::runtime_error("cannot open the weights");
    std::ifstream recipe(argv[2]);
    std::getline(recipe, line);
    lines.push_back(line);
    while (std::getline(recipe, line)) {
      std::istringstream f(line);
      std::string op, name, from;
      uint64_t rows = 0, cols = 0;
      f >> op >> name >> from >> rows >> cols;
      if (op.empty()) continue;
      if (op == "f32" || op == "f16") {
        uint64_t n = manifest.at(from).second / 2;
        std::vector<uint16_t> h = read16(from, n);
        if (op == "f16") {
          add(name, h.data(), n * 2);
        } else {
          std::vector<float> v(n);
          for (uint64_t i = 0; i < n; i++) v[i] = half(h[i]);
          add(name, v.data(), n * 4);
        }
        continue;
      }
      if (op != "pc8" && op != "pc4") throw std::runtime_error("recipe: unknown step " + op);
      const bool int8 = op == "pc8";
      const float qmax = int8 ? 127.0f : 7.0f, qmin = int8 ? -127.0f : -8.0f;
      std::vector<uint16_t> h = read16(from, rows * cols);
      std::vector<int8_t> q(rows * cols);
      std::vector<float> c(rows), w(cols);
      for (uint64_t r = 0; r < rows; r++) {
        float amax = 0;
        for (uint64_t i = 0; i < cols; i++) w[i] = half(h[r * cols + i]), amax = std::max(amax, std::fabs(w[i]));
        float s = amax / qmax;
        if (!(s > 0)) s = 1;
        c[r] = s;
        for (uint64_t i = 0; i < cols; i++)
          q[r * cols + i] = int8_t(std::min(std::max(std::nearbyint(w[i] / s), qmin), qmax));
      }
      if (int8) {
        add(name + ".q", q.data(), q.size());
      } else {
        std::vector<uint8_t> packed(q.size() / 2);
        for (size_t i = 0; i < packed.size(); i++)
          packed[i] = uint8_t((uint8_t(q[2 * i]) & 0xF) | ((uint8_t(q[2 * i + 1]) & 0xF) << 4));
        add(name + ".q", packed.data(), packed.size());
      }
      add(name + ".c", c.data(), c.size() * 4);
    }
    long total = ftell(out);
    if (fclose(out)) throw std::runtime_error("write failed");
    FILE *m = fopen((outdir + "/manifest.txt").c_str(), "w");
    for (const std::string &l : lines) fprintf(m, "%s\n", l.c_str());
    fclose(m);
    printf("%s/weights.bin: %ld bytes, %zu tensors\n", outdir.c_str(), total, lines.size() - 1);
    return 0;
  } catch (const std::exception &e) {
    fprintf(stderr, "pc_convert: %s\n", e.what());
    return 1;
  }
}
