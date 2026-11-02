// Bonsai 2 2B's weights.bin from the published checkpoint, without Python: the export of the
// Android port's prepare.py (mav3ri3k/modular, max/examples/android-llm/bonsai), in C++, so that a
// phone can download prism-ml/Ternary-Bonsai-2-2B-mlx-2bit from Hugging Face and convert it itself
// instead of receiving 596 MB over adb.
//
//   bonsai_convert <model.safetensors> <weights.bin> [capacity, default 128]
//
// prepare.py loads the checkpoint with mlx-lm in FP32 and writes, per module, the packed 2-bit
// codes transposed (uint32 [in/16, out]), the scales and biases transposed and interleaved
// (float32 [in/128, out, 2]) and the Hadamard signs; the norms, the gated-delta projections and
// constants; then a RoPE table for `capacity` positions. The reference logits (MLX) stay on the
// Mac. All 604 weight tensors come out byte for byte as prepare.py writes them; the RoPE table,
// computed with libm instead of numpy, is within 1 ulp.
#include "../runner/safetensors.h"

#include <cmath>

namespace {

std::map<std::string, Tensor> tensors;
FILE *out;
int written;

const Tensor &get(const std::string &name, const char *dtype, std::vector<int64_t> shape) {
  return tensorOf(tensors, "language_model.model." + name, dtype, shape);
}

void emit(const void *data, uint64_t bytes) {
  if (fwrite(&bytes, 8, 1, out) != 1 || fwrite(data, 1, bytes, out) != bytes)
    throw std::runtime_error("write failed");
  ++written;
}

void emitF32(const std::string &name, int64_t n) {
  const Tensor &t = get(name, "F32", {n});
  emit(t.data, n * 4);
}

void emitTransposed(const char *data, int64_t rows, int64_t cols) {
  std::vector<uint32_t> t = transposed(data, rows, cols);
  emit(t.data(), t.size() * 4);
}

// A packed module: codes [out, in/16] -> [in/16, out]; scales and biases [out, in/128] (fp16) ->
// [in/128, out, 2] (fp32); signs [in].
void emitPacked(const std::string &name, int64_t outDim, int64_t inDim) {
  const Tensor &w = get(name + ".weight", "U32", {outDim, inDim / 16});
  const Tensor &s = get(name + ".scales", "F16", {outDim, inDim / 128});
  const Tensor &b = get(name + ".biases", "F16", {outDim, inDim / 128});
  emitTransposed(w.data, outDim, inDim / 16);
  int64_t groups = inDim / 128;
  std::vector<float> params(groups * outDim * 2);
  const uint16_t *sp = reinterpret_cast<const uint16_t *>(s.data), *bp = reinterpret_cast<const uint16_t *>(b.data);
  for (int64_t o = 0; o < outDim; ++o)
    for (int64_t g = 0; g < groups; ++g) {
      params[(g * outDim + o) * 2] = halfToFloat(sp[o * groups + g]);
      params[(g * outDim + o) * 2 + 1] = halfToFloat(bp[o * groups + g]);
    }
  emit(params.data(), params.size() * 4);
  emitF32(name + ".signs", inDim);
}

}  // namespace

int main(int argc, char **argv) {
  if (argc < 3 || argc > 4) {
    fprintf(stderr, "usage: %s <model.safetensors> <weights.bin> [capacity]\n", argv[0]);
    return 2;
  }
  uint32_t capacity = argc == 4 ? static_cast<uint32_t>(atoi(argv[3])) : 128;
  try {
    if (capacity < 1 || capacity > 8192)
      throw std::runtime_error("capacity must be 1-8192");
    tensors = loadSafetensors(argv[1]);

    out = fopen(argv[2], "wb");
    if (!out)
      throw std::runtime_error(std::string("cannot write ") + argv[2]);
    uint32_t count = 605;
    fwrite("BONSAI01", 1, 8, out);
    fwrite(&count, 4, 1, out);
    fwrite(&capacity, 4, 1, out);
    emitPacked("embed_tokens", 248320, 2048);
    emitF32("norm.weight", 2048);
    for (int i = 0; i < 24; ++i) {
      std::string p = "layers." + std::to_string(i) + ".";
      emitF32(p + "input_layernorm.weight", 2048);
      emitF32(p + "post_attention_layernorm.weight", 2048);
      emitPacked(p + "mlp.gate_proj", 6144, 2048);
      emitPacked(p + "mlp.up_proj", 6144, 2048);
      emitPacked(p + "mlp.down_proj", 2048, 6144);
      if ((i + 1) % 4) {  // gated DeltaNet
        std::string a = p + "linear_attn.";
        emitPacked(a + "in_proj_qkv", 6144, 2048);
        emitPacked(a + "in_proj_z", 2048, 2048);
        emitPacked(a + "out_proj", 2048, 2048);
        emitTransposed(get(a + "in_proj_a.weight", "F32", {16, 2048}).data, 16, 2048);
        emitTransposed(get(a + "in_proj_b.weight", "F32", {16, 2048}).data, 16, 2048);
        std::vector<float> decay(32);
        memcpy(decay.data(), get(a + "A_log", "F32", {16}).data, 64);
        memcpy(decay.data() + 16, get(a + "dt_bias", "F32", {16}).data, 64);
        emit(decay.data(), 128);
        emitTransposed(get(a + "conv1d.weight", "F32", {6144, 4, 1}).data, 6144, 4);
        emitF32(a + "norm.weight", 128);
      } else {  // full attention
        std::string a = p + "self_attn.";
        emitPacked(a + "q_proj", 4096, 2048);
        emitPacked(a + "k_proj", 512, 2048);
        emitPacked(a + "v_proj", 512, 2048);
        emitPacked(a + "o_proj", 2048, 2048);
        emitF32(a + "q_norm.weight", 256);
        emitF32(a + "k_norm.weight", 256);
      }
    }
    // cos and sin of position * 1e7^(-2j/64), j < 32, as prepare.py computes them in float32.
    std::vector<float> rope(capacity * 64);
    for (uint32_t pos = 0; pos < capacity; ++pos)
      for (int j = 0; j < 32; ++j) {
        float inv = 1.0f / std::pow(10000000.0f, static_cast<float>(2 * j) / 64.0f);
        float angle = static_cast<float>(pos) * inv;
        rope[pos * 64 + j] = std::cos(angle);
        rope[pos * 64 + 32 + j] = std::sin(angle);
      }
    emit(rope.data(), rope.size() * 4);
    if (written != 605)
      throw std::runtime_error("wrote " + std::to_string(written) + " tensors, not 605");
    if (fclose(out))
      throw std::runtime_error("write failed");
    printf("%s: 605 tensors, context %u\n", argv[2], capacity);
    return 0;
  } catch (const std::exception &e) {
    fprintf(stderr, "bonsai_convert: %s\n", e.what());
    return 1;
  }
}
