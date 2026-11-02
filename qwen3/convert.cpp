// Ternary-Bonsai-8B's weights.bin and manifest.txt from the published checkpoint, without Python:
// qwen3/export.py's export in C++, so that a phone can download prism-ml/Ternary-Bonsai-8B-mlx-2bit
// (2.3 GB) from Hugging Face and convert it itself instead of receiving 2.2 GB over adb.
//
//   qwen3_convert <model.safetensors> <rope.f32> <out dir>
//
// Every tensor is the checkpoint's own (fp16 and packed uint32, transposed and fused as export.py
// does), so weights.bin is byte for byte export.py's. The one exception is the RoPE table: MLX's
// YaRN rope computes it, so it comes from export.py's output (64 KB for a context of 128).
#include "../runner/safetensors.h"

#include <cmath>

namespace {

constexpr int64_t D = 4096, L = 36, HD = 128, F = 12288, HEAD0 = 74 * 1024;

std::map<std::string, Tensor> tensors;
FILE *weights, *manifest;
uint64_t offset;

void add(const std::string &name, const void *data, uint64_t bytes) {
  if (fwrite(data, 1, bytes, weights) != bytes)
    throw std::runtime_error("write failed");
  fprintf(manifest, "%s %llu %llu\n", name.c_str(), static_cast<unsigned long long>(offset),
          static_cast<unsigned long long>(bytes));
  offset += bytes;
}

// An fp16 vector as fp32.
void addNorm(const std::string &name, const std::string &src, int64_t n) {
  const uint16_t *h = reinterpret_cast<const uint16_t *>(tensorOf(tensors, src, "F16", {n}).data);
  std::vector<float> v(n);
  for (int64_t i = 0; i < n; ++i)
    v[i] = halfToFloat(h[i]);
  add(name, v.data(), n * 4);
}

// Packed projections fused along n: codes [n, k/16] -> [k/16, sum n] uint32, scales [n, k/128] ->
// [k/128, sum n] fp16, over rows [begin, end) of each (all of them when end is 0). Every group must
// be ternary: bias == -scale.
void addPacked(const std::string &name, const std::vector<std::string> &prefixes, int64_t k, int64_t begin = 0,
               int64_t end = 0) {
  struct Part { const uint32_t *w; const uint16_t *s; int64_t n; };
  std::vector<Part> parts;
  int64_t total = 0;
  for (const std::string &p : prefixes) {
    int64_t rows = tensors.at(p + ".weight").shape[0];
    const Tensor &w = tensorOf(tensors, p + ".weight", "U32", {rows, k / 16});
    const Tensor &s = tensorOf(tensors, p + ".scales", "F16", {rows, k / 128});
    const Tensor &b = tensorOf(tensors, p + ".biases", "F16", {rows, k / 128});
    int64_t hi = end ? end : rows;
    const uint16_t *sp = reinterpret_cast<const uint16_t *>(s.data), *bp = reinterpret_cast<const uint16_t *>(b.data);
    for (int64_t i = begin * (k / 128); i < hi * (k / 128); ++i)
      if (halfToFloat(bp[i]) != -halfToFloat(sp[i]))
        throw std::runtime_error(p + ": not ternary (bias != -scale)");
    parts.push_back({reinterpret_cast<const uint32_t *>(w.data) + begin * (k / 16), sp + begin * (k / 128), hi - begin});
    total += hi - begin;
  }
  std::vector<uint32_t> w(k / 16 * total);
  std::vector<uint16_t> s(k / 128 * total);
  int64_t col = 0;
  for (const Part &part : parts) {
    for (int64_t r = 0; r < part.n; ++r) {
      for (int64_t c = 0; c < k / 16; ++c)
        w[c * total + col + r] = part.w[r * (k / 16) + c];
      for (int64_t c = 0; c < k / 128; ++c)
        s[c * total + col + r] = part.s[r * (k / 128) + c];
    }
    col += part.n;
  }
  add(name + ".w", w.data(), w.size() * 4);
  add(name + ".s", s.data(), s.size() * 2);
}

}  // namespace

int main(int argc, char **argv) {
  if (argc != 4) {
    fprintf(stderr, "usage: %s <model.safetensors> <rope.f32> <out dir>\n", argv[0]);
    return 2;
  }
  try {
    tensors = loadSafetensors(argv[1]);
    FILE *rope = fopen(argv[2], "rb");
    if (!rope)
      throw std::runtime_error(std::string("cannot open ") + argv[2]);
    std::vector<float> table;
    float value;
    while (fread(&value, 4, 1, rope) == 1)
      table.push_back(value);
    fclose(rope);
    if (table.empty() || table.size() % HD)
      throw std::runtime_error("rope.f32: not a table of 128-float rows");
    uint64_t capacity = table.size() / HD;
    std::string dir = argv[3];
    weights = fopen((dir + "/weights.bin").c_str(), "wb");
    manifest = fopen((dir + "/manifest.txt").c_str(), "w");
    if (!weights || !manifest)
      throw std::runtime_error("cannot write to " + dir);
    fprintf(manifest, "qwen3 %llu\n", static_cast<unsigned long long>(capacity));

    int64_t vocab = tensors.at("model.embed_tokens.weight").shape[0];
    const Tensor &ew = tensorOf(tensors, "model.embed_tokens.weight", "U32", {vocab, D / 16});
    const Tensor &es = tensorOf(tensors, "model.embed_tokens.scales", "F16", {vocab, D / 128});
    const Tensor &eb = tensorOf(tensors, "model.embed_tokens.biases", "F16", {vocab, D / 128});
    add("emb.w", ew.data, vocab * D / 16 * 4);
    add("emb.s", es.data, vocab * D / 128 * 2);
    add("emb.b", eb.data, vocab * D / 128 * 2);
    for (int i = 0; i < L; ++i) {
      std::string p = "model.layers." + std::to_string(i) + ".", l = "l" + std::to_string(i) + ".";
      addNorm(l + "in_norm", p + "input_layernorm.weight", D);
      addNorm(l + "post_norm", p + "post_attention_layernorm.weight", D);
      addNorm(l + "q_norm", p + "self_attn.q_norm.weight", HD);
      addNorm(l + "k_norm", p + "self_attn.k_norm.weight", HD);
      addPacked(l + "qkv", {p + "self_attn.q_proj", p + "self_attn.k_proj", p + "self_attn.v_proj"}, D);
      addPacked(l + "o", {p + "self_attn.o_proj"}, D);
      addPacked(l + "gu", {p + "mlp.gate_proj", p + "mlp.up_proj"}, D);
      addPacked(l + "down", {p + "mlp.down_proj"}, F);
    }
    addNorm("final_norm", "model.norm.weight", D);
    addPacked("head0", {"lm_head"}, D, 0, HEAD0);  // two halves: buffers stay under 128 MB
    addPacked("head1", {"lm_head"}, D, HEAD0, vocab);
    add("rope", table.data(), table.size() * 4);
    if (fclose(weights) || fclose(manifest))
      throw std::runtime_error("write failed");
    printf("%s: %llu bytes, context %llu\n", dir.c_str(), static_cast<unsigned long long>(offset),
           static_cast<unsigned long long>(capacity));
    return 0;
  } catch (const std::exception &e) {
    fprintf(stderr, "qwen3_convert: %s\n", e.what());
    return 1;
  }
}
