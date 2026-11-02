// On-phone test of the Vulkan driver plugin: loads it as MAX's runtime does (dlopen, every symbol
// of SDK/include/HAL/M_driver_hal_symbols.inc), allocates and copies through it, loads kernels'
// SPIR-V and launches them with CUDA-style arguments (a pointer to each argument's bytes, laid out
// as MAX's host code lays them out), and checks the results on the CPU.
//
//   test_plugin <libM_driver_vulkan.so> <kernel dir>
//
// <kernel dir> holds MAX's kernels as max_kernels/test_max_kernels.py --compile leaves them
// (matmul_f32_256x256/, matmul__gemv__1x2048x2048/, add/), coopmat/ with the fp32 kernels of
// coopmat/check.sh (adreno840 only) and Bonsai's residual.spv (bonsai/build_kernels.py). The last
// test launches residual 721 times, as many launches as a Bonsai token, to time a launch through
// the plugin.
#include "HAL/M_driver_api.h"
#include "json.h"

#include <dirent.h>
#include <dlfcn.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

namespace {

#define M_DRIVER_HAL_SYMBOL(name) M_driver_##name##_func_ptr_t name = nullptr;
struct Api {
#include "HAL/M_driver_hal_symbols.inc"
} api;
#undef M_DRIVER_HAL_SYMBOL

M_driver_driver_t driver;
M_driver_context_t context;
M_driver_queue_t queue;
int failures;

void check(M_driver_status_t status, const char *what) {
  if (!status)
    return;
  char message[512];
  api.status_message(driver, status, message, sizeof message);
  fprintf(stderr, "%s: %s\n", what, message);
  exit(1);
}

struct Buffer {
  M_driver_memory_t memory;
  uint64_t address, size;
};

Buffer alloc(uint64_t size) {
  Buffer b{nullptr, 0, size};
  check(api.memory_alloc_sync(context, size, &b.memory), "memory_alloc_sync");
  void *address = nullptr;
  check(api.memory_property(b.memory, M_DRIVER_MEMORY_PROPERTY_ADDRESS, &address), "memory_property");
  b.address = reinterpret_cast<uint64_t>(address);
  return b;
}

template <typename T> Buffer upload(const std::vector<T> &data) {
  Buffer b = alloc(data.size() * sizeof(T));
  M_driver_memory_view view{b.memory, 0, b.size};
  check(api.queue_copy_to_device(queue, &view, data.data()), "queue_copy_to_device");
  return b;
}

template <typename T> std::vector<T> download(const Buffer &b) {
  std::vector<T> out(b.size / sizeof(T));
  M_driver_memory_view view{b.memory, 0, b.size};
  check(api.queue_copy_from_device(queue, out.data(), &view), "queue_copy_from_device");
  check(api.queue_synchronize(queue), "queue_synchronize");
  return out;
}

std::string readFile(const std::string &path) {
  std::ifstream f(path, std::ios::binary);
  return std::string(std::istreambuf_iterator<char>(f), {});
}

// A kernel: its function and its launch description.
struct Kernel {
  std::string spirv;
  M_driver_function_t function = nullptr;
  Json description;
};

Kernel load(const std::string &path) {
  Kernel k;
  k.spirv = readFile(path);
  if (k.spirv.size() < 20 ||
      !launchDescription(reinterpret_cast<const uint32_t *>(k.spirv.data()), k.spirv.size() / 4, k.description)) {
    fprintf(stderr, "%s: no SPIR-V with a launch description\n", path.c_str());
    exit(1);
  }
  M_driver_static_bundle bundle{{k.spirv.data(), k.spirv.size()}, "spirv", 5};
  M_driver_runtime_bundle_t runtime;
  check(api.bundle_load(context, &bundle, nullptr, &runtime), "bundle_load");
  check(api.function_load(context, runtime, "main", 4, &k.function), "function_load");
  return k;
}

// The arguments' bytes, as the host lays them out: each leaf (pointers and scalars, in argument
// and offset order) at its offset. Pointers take device addresses.
std::vector<std::string> pack(const Json &d, const std::vector<int64_t> &values) {
  struct Leaf { int64_t arg, offset; std::string type; };
  std::vector<Leaf> leaves;
  for (const Json &b : d.get("buffers")->items)
    leaves.push_back({b.integer("arg"), b.integer("offset"), "ptr"});
  if (const Json *params = d.get("params"); params && params->kind == Json::Object)
    for (const Json &s : params->get("slots")->items)
      if (s.get("arg"))
        leaves.push_back({s.integer("arg"), s.integer("offset"), s.get("type")->text});
  std::sort(leaves.begin(), leaves.end(),
            [](const Leaf &a, const Leaf &b) { return a.arg != b.arg ? a.arg < b.arg : a.offset < b.offset; });
  if (leaves.size() != values.size()) {
    fprintf(stderr, "the kernel has %zu leaves, the test gives %zu values\n", leaves.size(), values.size());
    exit(1);
  }
  std::vector<std::string> args;
  for (const Json &a : d.get("args")->items)
    args.emplace_back(static_cast<size_t>(a.integer("bytes")), '\0');
  for (size_t i = 0; i < leaves.size(); ++i) {
    const Leaf &l = leaves[i];
    size_t bytes = l.type == "i1" || l.type == "i8" ? 1 : l.type == "i16" ? 2 : l.type == "i32" ? 4 : 8;
    memcpy(&args[l.arg][l.offset], &values[i], bytes);  // little-endian: the low bytes
  }
  return args;
}

void launch(const Kernel &k, std::vector<std::string> &args, M_driver_dim_t grid, M_driver_dim_t block) {
  std::vector<void *> pointers;
  std::vector<uint64_t> sizes;
  for (std::string &a : args)
    pointers.push_back(a.data()), sizes.push_back(a.size());
  M_driver_queue_execute_config_t config{};
  config.mode = M_DRIVER_QUEUE_EXECUTE_MODE_GPU;
  config.config.gpu.grid = grid;
  config.config.gpu.block = block;
  check(api.queue_execute(queue, k.function, &config, pointers.data(), sizes.data(),
                          static_cast<uint32_t>(args.size())),
        "queue_execute");
}

uint64_t rngState = 1;
float random1() {  // in [-1, 1)
  rngState = rngState * 6364136223846793005ull + 1442695040888963407ull;
  return static_cast<float>((rngState >> 40) & 0xffffff) / 8388608.0f - 1.0f;
}

void report(const std::string &name, bool ok, double error, double ms) {
  printf("%-48s %s  max error %.2e  %7.2f ms\n", name.c_str(), ok ? "PASS" : "FAIL", error, ms);
  failures += !ok;
}

double msSince(std::chrono::steady_clock::time_point start) {
  return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
}

std::vector<std::string> spvFiles(const std::string &dir, const char *contains) {
  std::vector<std::string> out;
  if (DIR *d = opendir(dir.c_str())) {
    while (dirent *e = readdir(d)) {
      std::string name = e->d_name;
      if (name.size() > 4 && name.substr(name.size() - 4) == ".spv" && name.find(contains) != std::string::npos)
        out.push_back(dir + "/" + name);
    }
    closedir(d);
  }
  std::sort(out.begin(), out.end());
  return out;
}

// MAX's naive matmul, c = a @ b, in 16x16 blocks: (c, a, b, m, n, k).
void testMatmul(const std::string &dir, const char *name, int m, int n, int k) {
  std::vector<std::string> files = spvFiles(dir + "/" + name, "matmul_kernel_naive");
  if (files.empty())
    return (void)printf("%-48s skipped: no kernel in %s/%s\n", name, dir.c_str(), name);
  std::vector<float> a(m * k), b(k * n), c(m * n, NAN);
  for (float &x : a) x = random1();
  for (float &x : b) x = random1();
  Buffer ba = upload(a), bb = upload(b), bc = upload(c);
  Kernel kernel = load(files[0]);
  auto args = pack(kernel.description, {static_cast<int64_t>(bc.address), static_cast<int64_t>(ba.address),
                                        static_cast<int64_t>(bb.address), m, n, k});
  auto start = std::chrono::steady_clock::now();
  launch(kernel, args, {static_cast<uint32_t>((m + 15) / 16), static_cast<uint32_t>((n + 15) / 16), 1}, {16, 16, 1});
  std::vector<float> out = download<float>(bc);
  double ms = msSince(start), error = 0;
  for (int i = 0; i < m; ++i)
    for (int j = 0; j < n; ++j) {
      double ref = 0;
      for (int p = 0; p < k; ++p)
        ref += static_cast<double>(a[i * k + p]) * b[p * n + j];
      error = std::max(error, std::fabs(out[i * n + j] - ref));
    }
  report(name, error < 1e-3 * std::sqrt(static_cast<double>(k)), error, ms);
}

// MAX's elementwise add, every compiled variant: each tensor is (pointer, size, stride), then the
// launch's (n, n / 4, 0, n).
void testAdd(const std::string &dir) {
  const int n = 1024;
  for (const std::string &file : spvFiles(dir + "/add", "mogg.foreach")) {
    std::vector<float> x(n), y(n), o(n, NAN);
    for (float &v : x) v = random1();
    for (float &v : y) v = random1();
    Buffer bx = upload(x), by = upload(y), bo = upload(o);
    Kernel kernel = load(file);
    std::vector<int64_t> values;
    const Buffer *inputs[] = {&bx, &by};
    int next = 0;
    for (const Json &b : kernel.description.get("buffers")->items) {
      std::string access = b.get("access")->text;
      const Buffer *buffer = access == "write" || access == "read_write" ? &bo : inputs[next++ % 2];
      values.insert(values.end(), {static_cast<int64_t>(buffer->address), n, 1});
    }
    values.insert(values.end(), {n, n / 4, 0, n});
    auto args = pack(kernel.description, values);
    auto start = std::chrono::steady_clock::now();
    launch(kernel, args, {1, 1, 1}, {256, 1, 1});
    std::vector<float> out = download<float>(bo);
    double ms = msSince(start), error = 0;
    for (int i = 0; i < n; ++i)
      error = std::max(error, static_cast<double>(std::fabs(out[i] - (x[i] + y[i]))));
    report("add " + file.substr(file.rfind('/') + 1, 40), error == 0, error, ms);
  }
}

// coopmat/matmul_coopmat_gpu.mojo's fp32 matmuls on KHR cooperative matrices, c = a @ b (n x n): one
// 64-lane subgroup a 64x64 tile of c, or four a 128x128 tile staged in shared memory. (a, b, c, n).
void testCoopmat(const std::string &dir) {
  const int n = 256;
  struct Case { const char *name; int tile, threads; } cases[] = {{"matmul_coopmat_f32_", 64, 64},
                                                                  {"matmul_coopmat_smem_f32_", 128, 256}};
  for (const Case &c : cases) {
    std::vector<std::string> files = spvFiles(dir + "/coopmat", c.name);
    if (files.empty()) {
      printf("%-48s skipped: no kernel in %s/coopmat\n", c.name, dir.c_str());
      continue;
    }
    std::vector<float> a(n * n), b(n * n), out(n * n, NAN);
    for (float &x : a) x = random1();
    for (float &x : b) x = random1();
    Buffer ba = upload(a), bb = upload(b), bc = upload(out);
    Kernel kernel = load(files[0]);
    auto args = pack(kernel.description, {static_cast<int64_t>(ba.address), static_cast<int64_t>(bb.address),
                                          static_cast<int64_t>(bc.address), n});
    auto start = std::chrono::steady_clock::now();
    uint32_t groups = static_cast<uint32_t>(n / c.tile);
    launch(kernel, args, {groups, groups, 1}, {static_cast<uint32_t>(c.threads), 1, 1});
    out = download<float>(bc);
    double ms = msSince(start), error = 0;
    for (int i = 0; i < n; ++i)
      for (int j = 0; j < n; ++j) {
        double ref = 0;
        for (int p = 0; p < n; ++p)
          ref += static_cast<double>(a[i * n + p]) * b[p * n + j];
        error = std::max(error, std::fabs(out[i * n + j] - ref));
      }
    std::string name = c.name;
    report("cooperative matrices: " + name.substr(0, name.size() - 1), error < 1e-3 * std::sqrt(n * 1.0), error, ms);
  }
}

// A fill and a device-side copy, through a view at an offset.
void testFillCopy() {
  const uint64_t n = 4096;
  Buffer a = alloc(n * 4), b = alloc(n * 4);
  M_driver_memory_view whole{a.memory, 0, n * 4}, half{a.memory, n * 2, n * 2}, dst{b.memory, 0, n * 4};
  check(api.queue_fill(queue, &whole, 0x3f800000, 4), "queue_fill");  // 1.0f
  check(api.queue_fill(queue, &half, 0x40000000, 4), "queue_fill");   // 2.0f in the second half
  check(api.queue_copy_intra_device(queue, &dst, &whole), "queue_copy_intra_device");
  std::vector<float> out = download<float>(b);
  bool ok = true;
  for (uint64_t i = 0; i < n; ++i)
    ok &= out[i] == (i < n / 2 ? 1.0f : 2.0f);
  report("fill, then copy on the device", ok, 0, 0);
}

// Bonsai's residual (x += y over 2048 floats, fixed 64-lane workgroups), `count` launches in a row
// as a decode step makes them, then one synchronize: x ends at x0 + count * y.
void testResidual(const std::string &dir, int count) {
  std::string file = dir + "/residual.spv";
  if (readFile(file).empty())
    return (void)printf("%-48s skipped: no %s\n", "residual", file.c_str());
  const int n = 2048;
  std::vector<float> x(n), y(n);
  for (int i = 0; i < n; ++i)
    x[i] = static_cast<float>(i % 7), y[i] = static_cast<float>(i % 3);
  Buffer bx = upload(x), by = upload(y);
  Kernel kernel = load(file);
  auto args = pack(kernel.description, {static_cast<int64_t>(bx.address), static_cast<int64_t>(by.address)});
  check(api.queue_synchronize(queue), "queue_synchronize");
  M_driver_event_t done;
  check(api.event_create(context, M_DRIVER_EVENT_FLAG_CPU_VISIBLE, &done), "event_create");
  auto start = std::chrono::steady_clock::now();
  for (int i = 0; i < count; ++i)
    launch(kernel, args, {n / 64, 1, 1}, {64, 1, 1});
  double enqueued = msSince(start);
  check(api.queue_record_event(queue, done), "queue_record_event");
  check(api.event_synchronize(context, done), "event_synchronize");
  double ms = msSince(start);
  check(api.event_destroy(context, done), "event_destroy");
  std::vector<float> out = download<float>(bx);
  double error = 0;
  for (int i = 0; i < n; ++i)
    error = std::max(error, static_cast<double>(std::fabs(out[i] - (x[i] + count * y[i]))));
  report("residual x" + std::to_string(count), error == 0, error, ms);
  printf("  %d launches: enqueued in %.2f ms (%.1f us each), done in %.2f ms (%.1f us each)\n", count, enqueued,
         enqueued * 1e3 / count, ms, ms * 1e3 / count);
}

}  // namespace

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "usage: %s <libM_driver_vulkan.so> <kernel dir>\n", argv[0]);
    return 2;
  }
  void *lib = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
  if (!lib) {
    fprintf(stderr, "dlopen %s: %s\n", argv[1], dlerror());
    return 1;
  }
  int missing = 0;
#define M_DRIVER_HAL_SYMBOL(name)                                                               \
  api.name = reinterpret_cast<M_driver_##name##_func_ptr_t>(dlsym(lib, "M_driver_" #name));     \
  if (!api.name) fprintf(stderr, "missing M_driver_" #name "\n"), ++missing;
#include "HAL/M_driver_hal_symbols.inc"
#undef M_DRIVER_HAL_SYMBOL
  if (missing)
    return 1;
  M_driver_version version{M_DRIVER_INTERFACE_VERSION_MAJOR, M_DRIVER_INTERFACE_VERSION_MINOR,
                           M_DRIVER_INTERFACE_VERSION_PATCH};
  check(api.create(&version, &driver), "create");
  const char *apiName = nullptr;
  check(api.property(driver, M_DRIVER_PROPERTY_API, &apiName), "property");
  int64_t count = 0;
  check(api.device_count(driver, &count), "device_count");
  M_driver_device_t device;
  check(api.device_get(driver, 0, &device), "device_get");
  char name[M_DRIVER_DEVICE_PROPERTY_MAX_LEN + 1], arch[M_DRIVER_DEVICE_PROPERTY_MAX_LEN + 1];
  check(api.device_property(device, M_DRIVER_DEVICE_PROPERTY_NAME, name), "device_property");
  check(api.device_property(device, M_DRIVER_DEVICE_PROPERTY_ARCH, arch), "device_property");
  int32_t shared = 0, threads = 0;
  check(api.device_attribute(device, 8, &shared), "device_attribute");
  check(api.device_attribute(device, 1, &threads), "device_attribute");
  printf("plugin api \"%s\", %lld device: %s, arch %s, %d threads and %d bytes shared memory a block\n\n", apiName,
         static_cast<long long>(count), name, arch, threads, shared);
  check(api.context_create(device, &context), "context_create");
  check(api.queue_create(context, &queue), "queue_create");

  std::string dir = argv[2];
  testFillCopy();
  testMatmul(dir, "matmul_f32_256x256", 256, 256, 256);
  testMatmul(dir, "matmul__gemv__1x2048x2048", 1, 2048, 2048);
  testAdd(dir);
  testCoopmat(dir);
  testResidual(dir, 721);
  testResidual(dir, 721);  // again, with its pipeline made
  printf("\n%s\n", failures ? "FAILED" : "all passed");
  check(api.queue_destroy(context, queue), "queue_destroy");
  check(api.context_destroy(context), "context_destroy");
  check(api.destroy(driver), "destroy");
  return failures ? 1 : 0;
}
