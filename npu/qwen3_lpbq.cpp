// The weights.bin and manifest.txt of npu/export_qwen3.py's w4a16 graphs, from the published checkpoint, on the
// phone: ternary Qwen3-8B (prism-ml/Ternary-Bonsai-8B-mlx-2bit) as LPBQ int4 (npu/quant.py's "fc" layout), so the
// phone writes the 4 GB file from the checkpoint it downloads instead of receiving it over adb. It is
// export_qwen3.py's quantize_weights in C++, the same float32 operations in the same order, and its output is
// byte for byte the same (run.py checks the SHA-256 against the Mac's).
//
//   qwen3_lpbq <model.safetensors> <out dir> pc4|fc
//
// pc4: per-channel int4 (export_qwen3.ternary_pc4); fc: LPBQ in FullyConnected chunks (ternary_lpbq).
#include "../runner/safetensors.h"

#include <cmath>
#include <set>

namespace {

constexpr int64_t D = 4096, L = 36, F = 12288, V = 151669, KMAX = 2048, UMAX = 15;
const int64_t HEAD_BOUNDS[5] = {0, 37917, 75834, 113752, V};  // export_qwen3.head_chunks(): round(i * V / 4)

std::map<std::string, Tensor> tensors;
FILE *weights;
std::vector<std::string> lines;
std::vector<float> products;  // k * u, k in 1..7, u in 1..15, ascending
int factor_k[106], factor_u[106];  // the factorization with the largest k

void add(const std::string &name, const void *data, uint64_t bytes) {
  long pos = ftell(weights);
  static const char zeros[256] = {};
  if (pos % 256) fwrite(zeros, 1, 256 - pos % 256, weights);
  pos = ftell(weights);
  if (fwrite(data, 1, bytes, weights) != bytes) throw std::runtime_error("write failed");
  lines.push_back(name + " " + std::to_string(pos) + " " + std::to_string(bytes));
}

void addNorm(const std::string &name, const std::string &src, int64_t n) {
  const uint16_t *h = reinterpret_cast<const uint16_t *>(tensorOf(tensors, src, "F16", {n}).data);
  std::vector<float> v(n);
  for (int64_t i = 0; i < n; ++i) v[i] = halfToFloat(h[i]);
  add(name, v.data(), n * 4);
}

// Ternary rows: t [rows][k] in -1..1 and s [rows][k / 128], of the projections `prefixes` fused along rows
// (rows [begin, end) of a single one when end > 0).
struct Ternary {
  int64_t rows = 0, k = 0;
  std::vector<int8_t> t;
  std::vector<float> s;
};

Ternary ternary(const std::vector<std::string> &prefixes, int64_t k, int64_t begin = 0, int64_t end = 0) {
  Ternary out;
  out.k = k;
  for (const std::string &p : prefixes) {
    int64_t n = tensors.at(p + ".weight").shape[0];
    const uint32_t *w = reinterpret_cast<const uint32_t *>(tensorOf(tensors, p + ".weight", "U32", {n, k / 16}).data);
    const uint16_t *s = reinterpret_cast<const uint16_t *>(tensorOf(tensors, p + ".scales", "F16", {n, k / 128}).data);
    const uint16_t *b = reinterpret_cast<const uint16_t *>(tensorOf(tensors, p + ".biases", "F16", {n, k / 128}).data);
    int64_t lo = begin, hi = end ? end : n;
    for (int64_t r = lo; r < hi; ++r) {
      for (int64_t g = 0; g < k / 128; ++g) {
        float sv = halfToFloat(s[r * (k / 128) + g]);
        if (halfToFloat(b[r * (k / 128) + g]) != -sv) throw std::runtime_error(p + ": not ternary (bias != -scale)");
        out.s.push_back(sv);
      }
      for (int64_t c = 0; c < k; ++c) {
        uint32_t code = (w[r * (k / 16) + c / 16] >> (2 * (c % 16))) & 3;
        if (code == 3) throw std::runtime_error(p + ": code 3 in a ternary tensor");
        out.t.push_back(int8_t(code) - 1);
      }
    }
    out.rows += hi - lo;
  }
  return out;
}

// The product nearest `target` (np.searchsorted, then the nearer neighbor, ties to the lower).
float nearest(float target) {
  size_t i = std::lower_bound(products.begin(), products.end(), target) - products.begin();
  i = std::min(std::max<size_t>(i, 1), products.size() - 1);
  float lo = products[i - 1], hi = products[i];
  return std::fabs(lo - target) <= std::fabs(hi - target) ? lo : hi;
}

// export_qwen3.ternary_lpbq + write_lpbq for one matrix: chunks of KMAX inputs, each q (int4, packed), u, c.
float writeLpbq(const std::string &name, const Ternary &m) {
  const int64_t n = m.rows, k = m.k, groups = KMAX / 128;
  float worst = 0;
  std::vector<uint8_t> q(n * KMAX / 2), u(n * KMAX / 64);
  std::vector<float> c(n);
  for (int64_t j = 0; j < k / KMAX; ++j) {
    for (int64_t r = 0; r < n; ++r) {
      const float *s = &m.s[r * (k / 128) + j * groups];
      float smax = s[0];
      for (int g = 1; g < groups; ++g) smax = std::max(smax, s[g]);
      if (!(smax > 0)) smax = 1;
      float mm[16];
      for (int g = 0; g < groups; ++g) mm[g] = s[g] / smax;
      float best_err = INFINITY, best_top = 0;
      for (float top : products) {
        if (top < 40) continue;
        float err = 0;
        for (int g = 0; g < groups; ++g) {
          float target = mm[g] * top;
          float near = target < products[0] ? products[0] : nearest(target);
          float e = s[g] > 0 ? std::fabs(near / target - 1.0f) : 0.0f;
          err = std::max(err, e);
        }
        if (err < best_err) best_err = err, best_top = top;
      }
      worst = std::max(worst, best_err);
      float cr = smax / best_top;
      c[r] = cr;
      for (int g = 0; g < groups; ++g) {
        int p = int(nearest(s[g] / cr));
        int kk = s[g] > 0 ? factor_k[p] : 1, uu = s[g] > 0 ? factor_u[p] : 1;
        u[r * (KMAX / 64) + 2 * g] = u[r * (KMAX / 64) + 2 * g + 1] = uint8_t(uu);
        for (int i = 0; i < 128; ++i) {
          int64_t col = g * 128 + i;  // within the chunk
          int8_t v = int8_t(m.t[r * k + j * KMAX + col] * kk);
          int64_t e = r * KMAX + col;  // element of the chunk, row-major
          uint8_t nib = uint8_t(v) & 0xF;
          if (e % 2 == 0)
            q[e / 2] = nib;
          else
            q[e / 2] |= uint8_t(nib << 4);
        }
      }
    }
    std::string pre = name + ".k" + std::to_string(j);
    add(pre + ".q", q.data(), q.size());
    add(pre + ".u", u.data(), u.size());
    add(pre + ".c", c.data(), c.size() * 4);
  }
  return worst;
}

// export_qwen3.ternary_pc4 + write_pc4 for one matrix: per-channel int4, q = t * kk, c per row.
float writePc4(const std::string &name, const Ternary &m) {
  const int64_t n = m.rows, k = m.k, groups = k / 128;
  float worst = 0;
  std::vector<uint8_t> q(n * k / 2);
  std::vector<float> c(n);
  std::vector<double> kk(groups), best_kk(groups);
  for (int64_t r = 0; r < n; ++r) {
    const float *s = &m.s[r * groups];
    float smax = s[0];
    for (int64_t g = 1; g < groups; ++g) smax = std::max(smax, s[g]);
    if (!(smax > 0)) smax = 1;
    float best_c = 0;
    double best_e = INFINITY;
    for (int top = 5; top <= 7; ++top) {
      float cr = smax / float(top);
      for (int it = 0; it < 4; ++it) {
        double num = 0, den = 0;
        for (int64_t g = 0; g < groups; ++g) {
          double kv = std::min(std::max(double(std::nearbyint(s[g] / cr)), 1.0), 7.0);
          num += kv * double(s[g]), den += kv * kv;
        }
        cr = float(num / den);
      }
      double e = 0;
      for (int64_t g = 0; g < groups; ++g) {
        kk[g] = std::min(std::max(double(std::nearbyint(s[g] / cr)), 1.0), 7.0);
        double d = kk[g] * double(cr) - double(s[g]);
        e += d * d;
      }
      if (top == 5 || e < best_e) best_e = e, best_c = cr, best_kk = kk;
    }
    c[r] = best_c;
    for (int64_t g = 0; g < groups; ++g) {
      if (s[g] > 0) worst = std::max(worst, std::fabs(float(best_kk[g]) * best_c / s[g] - 1.0f));
      for (int i = 0; i < 128; ++i) {
        int64_t e = r * k + g * 128 + i;
        uint8_t nib = uint8_t(int8_t(m.t[e] * int8_t(best_kk[g]))) & 0xF;
        if (e % 2 == 0)
          q[e / 2] = nib;
        else
          q[e / 2] |= uint8_t(nib << 4);
      }
    }
  }
  add(name + ".q", q.data(), q.size());
  add(name + ".c", c.data(), c.size() * 4);
  return worst;
}

}  // namespace

int main(int argc, char **argv) {
  if (argc != 4 || (std::string(argv[3]) != "pc4" && std::string(argv[3]) != "fc")) {
    fprintf(stderr, "usage: %s <model.safetensors> <out dir> pc4|fc\n", argv[0]);
    return 2;
  }
  const bool pc4 = std::string(argv[3]) == "pc4";
  auto write = [&](const std::string &name, const Ternary &m) { return pc4 ? writePc4(name, m) : writeLpbq(name, m); };
  try {
    std::set<int> seen;
    for (int kk = 1; kk <= 7; ++kk)
      for (int uu = 1; uu <= UMAX; ++uu) {
        seen.insert(kk * uu);
        factor_k[kk * uu] = kk, factor_u[kk * uu] = uu;
      }
    for (int p : seen) products.push_back(float(p));
    tensors = loadSafetensors(argv[1]);
    std::string dir = argv[2];
    weights = fopen((dir + "/weights.bin").c_str(), "wb");
    if (!weights) throw std::runtime_error("cannot write to " + dir);
    lines.push_back(std::string("qwen3-w4a16 4096 36 32 8 128 12288 151669 form ") + argv[3] + " keep -");
    float worst = 0;
    for (int i = 0; i < L; ++i) {
      std::string p = "model.layers." + std::to_string(i) + ".", l = "l" + std::to_string(i) + ".";
      addNorm(l + "in_norm", p + "input_layernorm.weight", D);
      addNorm(l + "post_norm", p + "post_attention_layernorm.weight", D);
      addNorm(l + "q_norm", p + "self_attn.q_norm.weight", 128);
      addNorm(l + "k_norm", p + "self_attn.k_norm.weight", 128);
      worst = std::max(worst, write(l + "qkv", ternary({p + "self_attn.q_proj", p + "self_attn.k_proj",
                                                       p + "self_attn.v_proj"}, D)));
      worst = std::max(worst, write(l + "o", ternary({p + "self_attn.o_proj"}, D)));
      worst = std::max(worst, write(l + "gu", ternary({p + "mlp.gate_proj", p + "mlp.up_proj"}, D)));
      worst = std::max(worst, write(l + "down", ternary({p + "mlp.down_proj"}, F)));
      fprintf(stderr, "layer %d\r", i);
    }
    addNorm("final_norm", "model.norm.weight", D);
    for (int c = 0; c < 4; ++c)
      worst = std::max(worst, write("head." + std::to_string(c),
                                    ternary({"lm_head"}, D, HEAD_BOUNDS[c], HEAD_BOUNDS[c + 1])));
    long total = ftell(weights);
    if (fclose(weights)) throw std::runtime_error("write failed");
    FILE *man = fopen((dir + "/manifest.txt").c_str(), "w");
    for (const std::string &line : lines) fprintf(man, "%s\n", line.c_str());
    fclose(man);
    printf("%s: %ld bytes; worst relative error of a group's scale %.2e\n", dir.c_str(), total, worst);
    return 0;
  } catch (const std::exception &e) {
    fprintf(stderr, "qwen3_lpbq: %s\n", e.what());
    return 1;
  }
}
