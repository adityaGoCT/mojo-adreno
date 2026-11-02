// Reads a safetensors checkpoint (memory-mapped) for the weight converters that run on the phone
// (bonsai/convert.cpp, qwen3/convert.cpp), and writes their output tensors.
#ifndef RUNNER_SAFETENSORS_H
#define RUNNER_SAFETENSORS_H

#include "../driver/json.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <cstdio>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>

struct Tensor {
  std::string dtype;
  std::vector<int64_t> shape;
  const char *data = nullptr;
};

// The checkpoint's tensors by name; their data stays mapped.
inline std::map<std::string, Tensor> loadSafetensors(const char *path) {
  int fd = open(path, O_RDONLY);
  struct stat st;
  if (fd < 0 || fstat(fd, &st))
    throw std::runtime_error(std::string("cannot open ") + path);
  const char *file = static_cast<const char *>(mmap(nullptr, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0));
  if (file == MAP_FAILED)
    throw std::runtime_error("cannot map the checkpoint");
  uint64_t headerBytes;
  memcpy(&headerBytes, file, 8);
  if (headerBytes + 8 > static_cast<uint64_t>(st.st_size))
    throw std::runtime_error("not a safetensors file");
  Json header;
  JsonParser parser{file + 8, file + 8 + headerBytes};
  if (!parser.parse(header) || header.kind != Json::Object)
    throw std::runtime_error("malformed safetensors header");
  std::map<std::string, Tensor> tensors;
  const char *data = file + 8 + headerBytes;
  for (const auto &[name, value] : header.fields) {
    if (name == "__metadata__")
      continue;
    Tensor t;
    t.dtype = value.get("dtype")->text;
    for (const Json &d : value.get("shape")->items)
      t.shape.push_back(static_cast<int64_t>(d.number));
    t.data = data + static_cast<int64_t>(value.get("data_offsets")->items[0].number);
    tensors[name] = t;
  }
  return tensors;
}

// The tensor `name`, which must have this dtype and shape.
inline const Tensor &tensorOf(const std::map<std::string, Tensor> &tensors, const std::string &name,
                              const char *dtype, const std::vector<int64_t> &shape) {
  auto it = tensors.find(name);
  if (it == tensors.end())
    throw std::runtime_error("missing tensor " + name);
  if (it->second.dtype != dtype || it->second.shape != shape)
    throw std::runtime_error("unexpected dtype or shape: " + name);
  return it->second;
}

inline float halfToFloat(uint16_t h) {
  uint32_t sign = (h & 0x8000u) << 16, exp = (h >> 10) & 0x1f, mant = h & 0x3ff, bits;
  if (exp == 0) {
    if (!mant) {
      bits = sign;
    } else {  // subnormal: normalize
      exp = 1;
      while (!(mant & 0x400))
        mant <<= 1, --exp;
      bits = sign | ((exp + 112) << 23) | ((mant & 0x3ff) << 13);
    }
  } else if (exp == 31) {
    bits = sign | 0x7f800000u | (mant << 13);
  } else {
    bits = sign | ((exp + 112) << 23) | (mant << 13);
  }
  float f;
  memcpy(&f, &bits, 4);
  return f;
}

// `rows` x `cols` of 4-byte elements, transposed.
inline std::vector<uint32_t> transposed(const char *data, int64_t rows, int64_t cols) {
  std::vector<uint32_t> t(rows * cols);
  const uint32_t *src = reinterpret_cast<const uint32_t *>(data);
  for (int64_t r = 0; r < rows; ++r)
    for (int64_t c = 0; c < cols; ++c)
      t[c * rows + r] = src[r * cols + c];
  return t;
}

#endif  // RUNNER_SAFETENSORS_H
