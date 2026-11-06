// A MAX driver plugin (the M_driver_* HAL interface in modular/modular's SDK/include/HAL) for a
// Vulkan device: MAX's DeviceContext allocates, copies and launches through it. It runs
//  - on the phone, with the Vulkan executor in the same process (driver/local.cpp):
//      MODULAR_DRIVER_PLUGINS="vulkan@/data/local/tmp/.../libM_driver_vulkan.so"
//  - on the Mac, as a remote device whose executor runs on the phone (remote/transport.cpp,
//    remote/vk_server.c, `adb forward tcp:7788 tcp:7788`):
//      MODULAR_DRIVER_PLUGINS="vulkan@/path/to/libM_driver_vulkan_remote.dylib"
//
// Kernels come from Mojo's Vulkan SPIR-V target (adreno710, adreno840), whose modules carry a
// launch description (OpModuleProcessed "mojo.vulkan.abi {json}"). A launch passes each argument as
// bytes, as for CUDA; the description says where each pointer and scalar inside them goes: a
// pointer (a device address this plugin handed out) becomes a storage-buffer binding at the
// allocation and offset it points into, a scalar a 64-bit slot of the params buffer.
//
// Requests go to the executor in order without waiting for it, and it batches the GPU work; the
// plugin waits only for data it reads back and at synchronization points (queue or event
// synchronize, a host function), which also report errors from the requests before them.
#include "HAL/M_driver_api.h"
#include "json.h"
#include "protocol.h"
#include "transport.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace {

// --- requests to the executor ----------------------------------------------------------------

std::mutex lock;  // one request at a time
std::string lastError;

// VK_DRIVER_<name>, or the remote device's older VK_REMOTE_<name>.
const char *env(const char *name) {
  std::string driver = std::string("VK_DRIVER_") + name, remote = std::string("VK_REMOTE_") + name;
  const char *value = getenv(driver.c_str());
  return value ? value : getenv(remote.c_str());
}

const char *opNames[] = {"", "info", "alloc", "free", "write", "read", "fill", "copy", "load", "launch", "sync",
                         "file", "gather", "record", "replay", "npu_open", "npu_rope", "npu_prefix", "npu_time",
                         "npug_open", "npug_run", "npug_time"};

// VK_DRIVER_PROFILE: per request type, how many, how long the plugin waited, and bytes sent and
// received, printed at exit.
struct Profile {
  struct Entry { uint64_t count = 0, sent = 0, received = 0; double seconds = 0; };
  Entry ops[OP_LAST + 1];
  bool on = env("PROFILE") != nullptr;
  ~Profile() {
    if (!on)
      return;
    fprintf(stderr, "vulkan driver profile (%s):\n", transportKind());
    for (int op = 1; op <= OP_LAST; ++op)
      if (ops[op].count)
        fprintf(stderr, "  %-7s %6llu requests %9.3f s  sent %8.2f MB  received %8.2f MB\n", opNames[op],
                static_cast<unsigned long long>(ops[op].count), ops[op].seconds, ops[op].sent / 1e6,
                ops[op].received / 1e6);
  }
} profile;

// Sends one request (its payload in up to two pieces). INFO, READ and SYNC wait for the answer:
// its payload goes to `out`, or its message (the first error since the last answer) to
// `lastError`.
bool call(uint32_t op, const void *a, size_t na, const void *b = nullptr, size_t nb = 0,
          std::string *out = nullptr) {
  std::lock_guard<std::mutex> guard(lock);
  auto start = std::chrono::steady_clock::now();
  if (env("DEBUG") && op != OP_LAUNCH) {  // every request but launches (logged in full)
    fprintf(stderr, "vulkan driver: %s", op <= OP_LAST ? opNames[op] : "?");
    for (size_t i = 0; i < std::min<size_t>(na / 8, 5); ++i)
      fprintf(stderr, " %llx", static_cast<unsigned long long>(static_cast<const uint64_t *>(a)[i]));
    fprintf(stderr, " (+%zu bytes)\n", nb);
  }
  std::string answer, error;
  if (!transportCall(op, a, na, b, nb, &answer, error)) {
    lastError = error;
    fprintf(stderr, "vulkan driver: %s\n", lastError.c_str());
    return false;
  }
  if (profile.on && op <= OP_LAST) {
    Profile::Entry &e = profile.ops[op];
    e.count++;
    e.sent += na + nb;
    e.received += answer.size();
    e.seconds += std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();
  }
  if (out)
    *out = std::move(answer);
  return true;
}

// What the executor reports of its device (OP_INFO), asked once.
struct DeviceInfo {
  std::string name, arch;
  uint64_t alignment = 64;
  int64_t sharedMemory = 32768, invocations = 1024, size[3] = {1024, 1024, 64}, subgroup = 64;
};

const DeviceInfo &deviceInfo() {
  static DeviceInfo info = [] {
    DeviceInfo d;
    std::string text;
    if (call(OP_INFO, nullptr, 0, nullptr, 0, &text)) {
      std::vector<std::string> fields;
      for (size_t at = 0;;) {
        size_t bar = text.find('|', at);
        fields.push_back(text.substr(at, bar - at));
        if (bar == std::string::npos)
          break;
        at = bar + 1;
      }
      d.name = fields[0];
      auto number = [&](size_t i, int64_t fallback) {
        return i < fields.size() && !fields[i].empty() ? strtoll(fields[i].c_str(), nullptr, 10) : fallback;
      };
      d.alignment = static_cast<uint64_t>(number(2, 64));
      d.sharedMemory = number(3, d.sharedMemory);
      d.invocations = number(4, d.invocations);
      for (int i = 0; i < 3; ++i)
        d.size[i] = number(5 + i, d.size[i]);
      d.subgroup = number(8, d.subgroup);
    }
    // The compiler's arch: "adreno" and the model number in the driver's name ("Adreno (TM) 840",
    // "Turnip Adreno (TM) 710"), unless VK_DRIVER_ARCH names it.
    if (const char *arch = env("ARCH"))
      d.arch = arch;
    else if (size_t at = d.name.find("Adreno"); at != std::string::npos) {
      size_t digit = d.name.find_first_of("0123456789", at);
      if (digit != std::string::npos)
        d.arch = "adreno" + d.name.substr(digit, d.name.find_first_not_of("0123456789", digit) - digit);
    }
    if (d.arch.empty())
      d.arch = "adreno710";
    return d;
  }();
  return info;
}

M_driver_status_t failed() { return M_DRIVER_STATUS_UNKNOWN_ERROR; }

// --- launch descriptions -------------------------------------------------------------------

struct Leaf {
  int64_t arg = -1, offset = 0, bytes = 8;  // where the value sits in the arguments
  int blockDim = -1;                         // or a params slot holding block_dim.x/.y/.z
  bool used = true;                          // a buffer the kernel reads or writes
};

struct Description {
  std::vector<Leaf> buffers;  // binding k: the k-th
  std::vector<Leaf> slots;    // params slots, in order
  bool hasParams = false;
};

int64_t scalarBytes(const std::string &type) {
  if (type == "i1" || type == "i8")
    return 1;
  if (type == "i16" || type == "half" || type == "bfloat")
    return 2;
  if (type == "i32" || type == "float")
    return 4;
  return 8;
}

bool describe(const std::string &spirv, Description &out) {
  const uint32_t *words = reinterpret_cast<const uint32_t *>(spirv.data());
  size_t count = spirv.size() / 4;
  if (count < 5 || words[0] != 0x07230203)
    return lastError = "not a SPIR-V module", false;
  Json json;
  if (!launchDescription(words, count, json))
    return lastError = "SPIR-V module without a mojo.vulkan.abi launch description", false;
  if (const Json *buffers = json.get("buffers"))
    for (const Json &b : buffers->items) {
      const Json *access = b.get("access");
      out.buffers.push_back({b.integer("arg"), b.integer("offset"), 8, -1, !access || access->text != "none"});
    }
  if (const Json *params = json.get("params"); params && params->kind == Json::Object) {
    out.hasParams = true;
    if (const Json *slots = params->get("slots"))
      for (const Json &s : slots->items) {
        Leaf leaf;
        if (const Json *value = s.get("value"))
          leaf.blockDim = value->text.back() - 'x';
        else
          leaf = {s.integer("arg"), s.integer("offset"), scalarBytes(s.get("type") ? s.get("type")->text : "")};
        out.slots.push_back(leaf);
      }
  }
  return true;
}

// --- objects -------------------------------------------------------------------------------

struct Memory {
  uint64_t buffer = 0;    // the server's buffer, for device memory
  uint64_t base = 0;      // where this handle starts in it (a wrapped view)
  uint64_t address = 0;   // the device address MAX sees
  uint64_t size = 0;
  void *host = nullptr;   // pinned host memory instead
  bool owning = true;
};

struct Function {
  uint64_t module = 0;
  Description description;
};

struct Bundle {
  std::string spirv;
  uint64_t module = 0;  // loaded on the phone at the first function_load
};

int driverSentinel, deviceSentinel, contextSentinel, queueSentinel, eventSentinel;
std::map<uint64_t, Memory *> byAddress;  // device memory by address
uint64_t nextAddress = 1ull << 40;
Memory *nullBuffer;  // bound for a null pointer argument
uint64_t nextBuffer = 1, nextModule = 1;  // the server's names, chosen here

Memory *memoryAt(uint64_t address, uint64_t &offset) {
  auto it = byAddress.upper_bound(address);
  if (it == byAddress.begin())
    return nullptr;
  --it;
  if (address >= it->first + it->second->size + 1)
    return nullptr;
  offset = address - it->first;
  return it->second;
}

M_driver_status_t allocate(uint64_t size, M_driver_memory_t *memory) {
  if (!memory || !size)
    return M_DRIVER_STATUS_INVALID_ARG;
  uint64_t request[2] = {nextBuffer, size};
  if (!call(OP_ALLOC, request, 16))
    return failed();
  auto *m = new Memory;
  m->buffer = nextBuffer++;
  m->size = size;
  m->address = nextAddress;
  nextAddress += (size + 0xffff) & ~0xffffull;  // 64 KiB apart: never adjacent
  byAddress[m->address] = m;
  if (env("DEBUG"))
    fprintf(stderr, "vulkan driver: alloc %llu bytes at %llx\n", static_cast<unsigned long long>(size),
            static_cast<unsigned long long>(m->address));
  *memory = reinterpret_cast<M_driver_memory_t>(m);
  return M_DRIVER_STATUS_SUCCESS;
}

M_driver_status_t release(M_driver_memory_t memory) {
  auto *m = reinterpret_cast<Memory *>(memory);
  if (!m)
    return M_DRIVER_STATUS_SUCCESS;
  if (m->host) {
    if (m->owning)
      free(m->host);
  } else {
    // A wrapped view shares its allocation's address: only the allocation's
    // own handle is in the map.
    if (auto it = byAddress.find(m->address); it != byAddress.end() && it->second == m)
      byAddress.erase(it);
    if (m->owning && !call(OP_FREE, &m->buffer, 8))
      return failed();
  }
  delete m;
  return M_DRIVER_STATUS_SUCCESS;
}

Memory *mem(M_driver_memory_view_t view) {
  return view ? reinterpret_cast<Memory *>(view->memory) : nullptr;
}

M_driver_status_t write(M_driver_memory_view_t dst, const void *src) {
  Memory *m = mem(dst);
  if (!m || !src)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (!dst->size)
    return M_DRIVER_STATUS_SUCCESS;
  if (m->host) {
    memcpy(static_cast<char *>(m->host) + dst->offset, src, dst->size);
    return M_DRIVER_STATUS_SUCCESS;
  }
  // In pieces: a request carries at most 4 GiB, and smaller ones keep memory use flat.
  constexpr uint64_t piece = 64ull << 20;
  for (uint64_t done = 0; done < dst->size; done += piece) {
    uint64_t header[2] = {m->buffer, m->base + dst->offset + done};
    uint64_t n = std::min(piece, dst->size - done);
    if (!call(OP_WRITE, header, 16, static_cast<const char *>(src) + done, n))
      return failed();
  }
  return M_DRIVER_STATUS_SUCCESS;
}

M_driver_status_t read(void *dst, M_driver_memory_view_t src) {
  Memory *m = mem(src);
  if (!m || !dst)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (m->host) {
    memcpy(dst, static_cast<char *>(m->host) + src->offset, src->size);
    return M_DRIVER_STATUS_SUCCESS;
  }
  constexpr uint64_t piece = 64ull << 20;
  for (uint64_t done = 0; done < src->size; done += piece) {
    uint64_t n = std::min(piece, src->size - done);
    uint64_t request[3] = {m->buffer, m->base + src->offset + done, n};
    std::string out;
    if (!call(OP_READ, request, 24, nullptr, 0, &out))
      return failed();
    memcpy(static_cast<char *>(dst) + done, out.data(), n);
  }
  return M_DRIVER_STATUS_SUCCESS;
}

M_driver_status_t copy(M_driver_memory_view_t dst, M_driver_memory_view_t src) {
  Memory *d = mem(dst), *s = mem(src);
  if (!d || !s)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (!dst->size)
    return M_DRIVER_STATUS_SUCCESS;
  if (s->host) {
    M_driver_memory_view view = *dst;
    return write(&view, static_cast<char *>(s->host) + src->offset);
  }
  if (d->host)
    return read(static_cast<char *>(d->host) + dst->offset, src);
  uint64_t request[5] = {d->buffer, d->base + dst->offset, s->buffer, s->base + src->offset, dst->size};
  return call(OP_COPY, request, 40) ? M_DRIVER_STATUS_SUCCESS : failed();
}

M_driver_status_t fill(M_driver_memory_view_t dst, uint64_t value, uint64_t valueSize) {
  Memory *m = mem(dst);
  if (!m || !valueSize || valueSize > 8)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (!dst->size)
    return M_DRIVER_STATUS_SUCCESS;
  if (m->host) {
    char *p = static_cast<char *>(m->host) + dst->offset;
    for (uint64_t i = 0; i < dst->size; i += valueSize)
      memcpy(p + i, &value, std::min(valueSize, dst->size - i));
    return M_DRIVER_STATUS_SUCCESS;
  }
  uint64_t request[5] = {m->buffer, m->base + dst->offset, dst->size, value, valueSize};
  return call(OP_FILL, request, 40) ? M_DRIVER_STATUS_SUCCESS : failed();
}

M_driver_status_t execute(Function *f, const M_driver_dim_t &grid, const M_driver_dim_t &block,
                          void **args, uint64_t *argSizes, uint32_t numArgs) {
  const Description &d = f->description;
  if (env("DEBUG")) {  // the launch as MAX passes it
    fprintf(stderr, "vulkan driver: launch grid %u %u %u block %u %u %u, %u args:", grid.x, grid.y, grid.z,
            block.x, block.y, block.z, numArgs);
    for (uint32_t i = 0; i < numArgs; ++i) {
      fprintf(stderr, "\n  arg %u (%llu bytes):", i, static_cast<unsigned long long>(argSizes[i]));
      for (uint64_t at = 0; at + 8 <= argSizes[i] && at < 512; at += 8)
        fprintf(stderr, " %llx", static_cast<unsigned long long>(*reinterpret_cast<const uint64_t *>(
                                     static_cast<const char *>(args[i]) + at)));
    }
    fprintf(stderr, "\n  description: %zu buffers, %zu params slots\n", d.buffers.size(), d.slots.size());
    for (const Leaf &leaf : d.buffers)
      fprintf(stderr, "    buffer: arg %lld offset %lld\n", static_cast<long long>(leaf.arg),
              static_cast<long long>(leaf.offset));
  }
  auto valueAt = [&](const Leaf &leaf, void *out) {
    if (leaf.arg < 0 || leaf.arg >= numArgs || !args[leaf.arg] ||
        static_cast<uint64_t>(leaf.offset + leaf.bytes) > argSizes[leaf.arg])
      return false;
    memcpy(out, static_cast<const char *>(args[leaf.arg]) + leaf.offset, leaf.bytes);
    return true;
  };
  launch_t launch{};
  launch.module = f->module;
  launch.groups[0] = grid.x, launch.groups[1] = grid.y, launch.groups[2] = grid.z;
  launch.block[0] = block.x, launch.block[1] = block.y, launch.block[2] = block.z;
  launch.nbind = static_cast<uint32_t>(d.buffers.size());
  std::vector<binding_t> bindings;
  for (const Leaf &leaf : d.buffers) {
    uint64_t address = 0, offset = 0;
    if (!valueAt(leaf, &address))
      return lastError = "launch arguments do not match the kernel's description", M_DRIVER_STATUS_INVALID_ARG;
    // A pointer field the kernel never dereferences may hold anything (the
    // host can store other data in it): bind the placeholder.
    Memory *m = address && leaf.used ? memoryAt(address, offset) : nullBuffer;
    if (!m && (!address || !leaf.used)) {
      M_driver_memory_t placeholder;
      if (M_driver_status_t status = allocate(256, &placeholder))
        return status;
      m = nullBuffer = reinterpret_cast<Memory *>(placeholder);
    }
    if (!m || m->host)
      return lastError = "kernel argument is not a device address of this plugin", M_DRIVER_STATUS_INVALID_ARG;
    if (m == nullBuffer)
      offset = 0;
    bindings.push_back({m->buffer, m->base + offset});
  }
  std::string params;
  for (const Leaf &leaf : d.slots) {
    uint64_t value = 0;
    if (leaf.blockDim >= 0)
      value = leaf.blockDim == 0 ? block.x : leaf.blockDim == 1 ? block.y : block.z;
    else if (!valueAt(leaf, &value))
      return lastError = "launch arguments do not match the kernel's description", M_DRIVER_STATUS_INVALID_ARG;
    params.append(reinterpret_cast<const char *>(&value), 8);
  }
  if (d.hasParams && params.empty())
    params.assign(8, '\0');
  launch.params_len = static_cast<uint32_t>(params.size());
  std::string body(reinterpret_cast<const char *>(&launch), sizeof launch);
  body.append(reinterpret_cast<const char *>(bindings.data()), bindings.size() * sizeof(binding_t));
  body += params;
  return call(OP_LAUNCH, body.data(), body.size()) ? M_DRIVER_STATUS_SUCCESS : failed();
}

}  // namespace

// --- driver --------------------------------------------------------------------------------

extern "C" {

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_status_message(M_driver_driver_t, M_driver_status_t status, char *buffer,
                                          int64_t size) {
  if (!buffer || size <= 0)
    return M_DRIVER_STATUS_ARGUMENT_OUT_OF_RANGE;
  std::string message = status == M_DRIVER_STATUS_SUCCESS ? "success"
                        : lastError.empty() ? "vulkan driver error " + std::to_string(status)
                                            : lastError;
  snprintf(buffer, static_cast<size_t>(size), "%s", message.c_str());
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_create(M_driver_version *version, M_driver_driver_t *driver) {
  if (!version || !driver)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (version->major != M_DRIVER_INTERFACE_VERSION_MAJOR)
    return M_DRIVER_STATUS_INCOMPATIBLE_VERSION;
  version->major = M_DRIVER_INTERFACE_VERSION_MAJOR;
  version->minor = M_DRIVER_INTERFACE_VERSION_MINOR;
  version->patch = M_DRIVER_INTERFACE_VERSION_PATCH;
  *driver = reinterpret_cast<M_driver_driver_t>(&driverSentinel);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_destroy(M_driver_driver_t) { return M_DRIVER_STATUS_SUCCESS; }

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_property(M_driver_driver_t, const char *name, void *value) {
  if (!name || !value)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (!strcmp(name, M_DRIVER_PROPERTY_API)) {
    *static_cast<const char **>(value) = "vulkan";
    return M_DRIVER_STATUS_SUCCESS;
  }
  if (!strcmp(name, M_DRIVER_PROPERTY_VERSION)) {
    auto *v = static_cast<M_driver_version *>(value);
    v->major = M_DRIVER_INTERFACE_VERSION_MAJOR;
    v->minor = M_DRIVER_INTERFACE_VERSION_MINOR;
    v->patch = M_DRIVER_INTERFACE_VERSION_PATCH;
    return M_DRIVER_STATUS_SUCCESS;
  }
  return M_DRIVER_STATUS_UNKNOWN_PROPERTY_NAME;
}

// --- device: the phone's GPU ------------------------------------------------------------------

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_device_count(M_driver_driver_t, int64_t *count) {
  if (!count)
    return M_DRIVER_STATUS_INVALID_ARG;
  *count = 1;
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_device_get(M_driver_driver_t, int64_t id, M_driver_device_t *device) {
  if (!device)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (id != 0)
    return M_DRIVER_STATUS_BAD_DEVICE;
  *device = reinterpret_cast<M_driver_device_t>(&deviceSentinel);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_device_property(M_driver_device_t, const char *name, void *value) {
  if (!name || !value)
    return M_DRIVER_STATUS_INVALID_ARG;
  auto text = [&](const char *s) {
    snprintf(static_cast<char *>(value), M_DRIVER_DEVICE_PROPERTY_MAX_LEN + 1, "%s", s);
    return M_DRIVER_STATUS_SUCCESS;
  };
  if (!strcmp(name, M_DRIVER_DEVICE_PROPERTY_NAME))
    return text((deviceInfo().name + " (" + transportKind() + ", Vulkan)").c_str());
  if (!strcmp(name, M_DRIVER_DEVICE_PROPERTY_ARCH))
    return text(deviceInfo().arch.c_str());
  if (!strcmp(name, M_DRIVER_DEVICE_PROPERTY_HOST_UNIFIED)) {
    *static_cast<int64_t *>(value) = 0;
    return M_DRIVER_STATUS_SUCCESS;
  }
  if (!strcmp(name, M_DRIVER_DEVICE_PROPERTY_MAX_ALLOCATION_SIZE)) {
    *static_cast<int64_t *>(value) = 1ll << 30;
    return M_DRIVER_STATUS_SUCCESS;
  }
  if (!strcmp(name, M_DRIVER_DEVICE_PROPERTY_DLPACK_DEVICE) ||
      !strcmp(name, M_DRIVER_DEVICE_PROPERTY_DLPACK_DEVICE_PINNED)) {
    // kDLVulkan for device memory, kDLCPU for pinned host memory.
    bool pinned = !strcmp(name, M_DRIVER_DEVICE_PROPERTY_DLPACK_DEVICE_PINNED);
    *static_cast<M_driver_dlpack_device *>(value) = {pinned ? 1 : 7, 0};
    return M_DRIVER_STATUS_SUCCESS;
  }
  return M_DRIVER_STATUS_UNKNOWN_PROPERTY_NAME;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_device_attribute(M_driver_device_t, int32_t attribute, int32_t *value) {
  if (!value)
    return M_DRIVER_STATUS_INVALID_ARG;
  // CUDA's numbering, as MAX's DeviceAttribute: the device's Vulkan limits where it has them.
  const DeviceInfo &d = deviceInfo();
  auto narrow = [](int64_t v) { return static_cast<int32_t>(std::min<int64_t>(v, INT32_MAX)); };
  switch (attribute) {
  case 1: case 39: *value = narrow(d.invocations); break;  // max threads per block, per multiprocessor
  case 2: case 3: case 4: *value = narrow(d.size[attribute - 2]); break;  // max block dim x, y, z
  case 5: case 6: case 7: *value = 65535; break;  // max grid dim
  case 8: case 81: case 97: *value = narrow(d.sharedMemory); break;  // shared memory per block, opt-in, per SM
  case 10: *value = 64; break;             // warp size (a Mojo warp: 64 lanes)
  case 12: case 82: *value = 65536; break; // registers
  case 13: *value = 950000; break;         // clock rate, kHz
  case 16: *value = 2; break;              // multiprocessors (a guess for grid sizing)
  case 75: case 76: {                      // "compute capability": 7.10 for adreno710, 8.40 for adreno840
    int model = atoi(d.arch.c_str() + std::min<size_t>(d.arch.size(), 6));
    *value = attribute == 75 ? model / 100 : model % 100;
    break;
  }
  case 106: *value = 16; break;            // max blocks per multiprocessor
  default: *value = 0; break;
  }
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_device_can_access_peer(M_driver_device_t device, M_driver_device_t peer,
                                                  bool *can) {
  if (!device || !peer)
    return M_DRIVER_STATUS_BAD_DEVICE;
  if (!can)
    return M_DRIVER_STATUS_INVALID_ARG;
  *can = false;
  return M_DRIVER_STATUS_SUCCESS;
}

// --- context -------------------------------------------------------------------------------

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_context_create(M_driver_device_t, M_driver_context_t *context) {
  if (!context)
    return M_DRIVER_STATUS_INVALID_ARG;
  *context = reinterpret_cast<M_driver_context_t>(&contextSentinel);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_context_destroy(M_driver_context_t) { return M_DRIVER_STATUS_SUCCESS; }

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_context_enable_peer_access(M_driver_context_t context, M_driver_context_t peer) {
  if (!context || !peer)
    return M_DRIVER_STATUS_BAD_CONTEXT;
  return M_DRIVER_STATUS_INCOMPATIBLE;
}

static M_driver_native_handle_t currentDriverContext = 0;

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_context_set_current(M_driver_context_t context) {
  if (!context)
    return M_DRIVER_STATUS_BAD_CONTEXT;
  currentDriverContext = reinterpret_cast<M_driver_native_handle_t>(context);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_context_get_current_driver_context(M_driver_context_t context,
                                                              M_driver_native_handle_t *handle) {
  if (!context)
    return M_DRIVER_STATUS_BAD_CONTEXT;
  if (!handle)
    return M_DRIVER_STATUS_INVALID_ARG;
  *handle = currentDriverContext;
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_context_set_current_driver_context(M_driver_context_t context,
                                                              M_driver_native_handle_t handle) {
  if (!context)
    return M_DRIVER_STATUS_BAD_CONTEXT;
  currentDriverContext = handle;
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_context_memory_info(M_driver_context_t context, uint64_t *free, uint64_t *total) {
  if (!context)
    return M_DRIVER_STATUS_BAD_CONTEXT;
  if (!free || !total)
    return M_DRIVER_STATUS_INVALID_ARG;
  *total = 4ull << 30;  // a share of the phone's 8 GB
  *free = 3ull << 30;
  return M_DRIVER_STATUS_SUCCESS;
}

// --- memory --------------------------------------------------------------------------------

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_alloc_pinned(M_driver_context_t, uint64_t size, M_driver_memory_t *memory) {
  if (!memory || !size)
    return M_DRIVER_STATUS_INVALID_ARG;
  auto *m = new Memory;
  m->host = malloc(size);
  m->size = size;
  if (!m->host) {
    delete m;
    return M_DRIVER_STATUS_OUT_OF_MEMORY;
  }
  *memory = reinterpret_cast<M_driver_memory_t>(m);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_free_pinned(M_driver_context_t, M_driver_memory_t memory) {
  return release(memory);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_alloc_sync(M_driver_context_t, uint64_t size, M_driver_memory_t *memory) {
  return allocate(size, memory);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_free_sync(M_driver_context_t, M_driver_memory_t memory) {
  return release(memory);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_alloc_async(M_driver_queue_t, uint64_t size, M_driver_memory_t *memory) {
  return allocate(size, memory);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_free_async(M_driver_queue_t, M_driver_memory_t memory) {
  return release(memory);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_wrap(M_driver_context_t, uint64_t address, uint64_t size, bool owning,
                                       M_driver_memory_t *memory) {
  if (!memory || !address)
    return M_DRIVER_STATUS_INVALID_ARG;
  // A view of an allocation of this plugin (its device address), or of host memory.
  uint64_t offset = 0;
  auto *m = new Memory;
  if (Memory *base = memoryAt(address, offset); base && !base->host) {
    // A view of (part of) an allocation of this plugin.
    m->buffer = base->buffer;
    m->base = base->base + offset;
    m->address = address;
    m->size = size;
    m->owning = false;
  } else {
    m->host = reinterpret_cast<void *>(address);
    m->size = size;
    m->owning = owning;
  }
  *memory = reinterpret_cast<M_driver_memory_t>(m);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_unwrap(M_driver_context_t, M_driver_memory_t memory, uint64_t *address) {
  auto *m = reinterpret_cast<Memory *>(memory);
  if (!m || !address)
    return M_DRIVER_STATUS_INVALID_ARG;
  m->owning = false;
  *address = m->host ? reinterpret_cast<uint64_t>(m->host) : m->address;
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_memory_property(M_driver_memory_t memory, const char *name, void *value) {
  auto *m = reinterpret_cast<Memory *>(memory);
  if (!m || !name || !value)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (!strcmp(name, M_DRIVER_MEMORY_PROPERTY_ADDRESS)) {
    *static_cast<void **>(value) = m->host ? m->host : reinterpret_cast<void *>(m->address);
    return M_DRIVER_STATUS_SUCCESS;
  }
  if (!strcmp(name, M_DRIVER_MEMORY_PROPERTY_HOST_ADDRESS)) {
    if (!m->host)
      return M_DRIVER_STATUS_INVALID_ARG;
    *static_cast<void **>(value) = m->host;
    return M_DRIVER_STATUS_SUCCESS;
  }
  return M_DRIVER_STATUS_UNKNOWN_PROPERTY_NAME;
}

// --- queues: synchronous -------------------------------------------------------------------

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_create(M_driver_context_t, M_driver_queue_t *queue) {
  if (!queue)
    return M_DRIVER_STATUS_INVALID_ARG;
  *queue = reinterpret_cast<M_driver_queue_t>(&queueSentinel);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_destroy(M_driver_context_t, M_driver_queue_t) { return M_DRIVER_STATUS_SUCCESS; }

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_property(M_driver_queue_t queue, const char *name, void *value) {
  if (!queue)
    return M_DRIVER_STATUS_BAD_QUEUE;
  if (!name || !value)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (!strcmp(name, M_DRIVER_QUEUE_PROPERTY_NATIVE_HANDLE)) {
    *static_cast<uint64_t *>(value) = reinterpret_cast<uint64_t>(queue);
    return M_DRIVER_STATUS_SUCCESS;
  }
  return M_DRIVER_STATUS_UNKNOWN_PROPERTY_NAME;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_copy_to_device(M_driver_queue_t, M_driver_memory_view_t dst, const void *src) {
  return write(dst, src);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_copy_from_device(M_driver_queue_t, void *dst, M_driver_memory_view_t src) {
  return read(dst, src);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_copy_intra_device(M_driver_queue_t, M_driver_memory_view_t dst,
                                                   M_driver_memory_view_t src) {
  return copy(dst, src);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_copy_inter_device(M_driver_queue_t, M_driver_memory_view_t dst,
                                                   M_driver_memory_view_t src, M_driver_context_t) {
  return copy(dst, src);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_copy_to_device_sync(M_driver_context_t, M_driver_memory_view_t dst, const void *src) {
  return write(dst, src);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_copy_from_device_sync(M_driver_context_t, void *dst, M_driver_memory_view_t src) {
  return read(dst, src);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_copy_intra_device_sync(M_driver_context_t, M_driver_memory_view_t dst,
                                                  M_driver_memory_view_t src) {
  return copy(dst, src);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_copy_inter_device_sync(M_driver_context_t, M_driver_memory_view_t dst,
                                                  M_driver_memory_view_t src, M_driver_context_t) {
  return copy(dst, src);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_set_memory_sync(M_driver_context_t, M_driver_memory_view_t dst, uint8_t value) {
  return fill(dst, value, 1);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_fill_sync(M_driver_context_t, M_driver_memory_view_t dst, uint64_t value,
                                     uint64_t value_size) {
  return fill(dst, value, value_size);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_set_memory(M_driver_queue_t, M_driver_memory_view_t dst, uint8_t value) {
  return fill(dst, value, 1);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_fill(M_driver_queue_t, M_driver_memory_view_t dst, uint64_t value,
                                      uint64_t value_size) {
  return fill(dst, value, value_size);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_execute(M_driver_queue_t, M_driver_function_t function,
                                         M_driver_queue_execute_config_t *config, void **args,
                                         uint64_t *arg_sizes, uint32_t num_args) {
  auto *f = reinterpret_cast<Function *>(function);
  if (!f)
    return M_DRIVER_STATUS_BAD_FUNCTION;
  if (!config || config->mode != M_DRIVER_QUEUE_EXECUTE_MODE_GPU)
    return M_DRIVER_STATUS_INVALID_ARG;
  return execute(f, config->config.gpu.grid, config->config.gpu.block, args, arg_sizes, num_args);
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_record_event(M_driver_queue_t, M_driver_event_t) { return M_DRIVER_STATUS_SUCCESS; }

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_wait_for_events(M_driver_queue_t, M_driver_event_t *, uint32_t) {
  return M_DRIVER_STATUS_SUCCESS;
}

// Waits for everything sent so far; reports the first error among it.
static M_driver_status_t synchronize() { return call(OP_SYNC, nullptr, 0) ? M_DRIVER_STATUS_SUCCESS : failed(); }

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_synchronize(M_driver_queue_t) { return synchronize(); }

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_is_stream(M_driver_queue_t, bool *is_stream) {
  if (!is_stream)
    return M_DRIVER_STATUS_INVALID_ARG;
  *is_stream = false;
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_launch_host_func(M_driver_queue_t queue, void (*fn)(void *), void *user_data) {
  if (!queue)
    return M_DRIVER_STATUS_BAD_QUEUE;
  if (!fn)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (M_driver_status_t status = synchronize())  // the function runs after everything before it
    return status;
  fn(user_data);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_wait_value64(M_driver_queue_t, uint64_t, uint64_t) {
  return M_DRIVER_STATUS_INCOMPATIBLE;
}

// --- events: one in-order queue, so an event has happened once everything before it has ----------

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_event_create(M_driver_context_t, M_driver_event_flags_t flags, M_driver_event_t *event) {
  if ((flags & ~M_DRIVER_EVENT_FLAGS_ALL) || !event)
    return M_DRIVER_STATUS_INVALID_ARG;
  *event = reinterpret_cast<M_driver_event_t>(&eventSentinel);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_event_destroy(M_driver_context_t, M_driver_event_t) { return M_DRIVER_STATUS_SUCCESS; }

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_event_synchronize(M_driver_context_t, M_driver_event_t) { return synchronize(); }

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_is_event_ready(M_driver_context_t, M_driver_event_t, bool *ready) {
  if (!ready)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (M_driver_status_t status = synchronize())
    return status;
  *ready = true;
  return M_DRIVER_STATUS_SUCCESS;
}

// --- kernels -------------------------------------------------------------------------------

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_bundle_load(M_driver_context_t, M_driver_static_bundle_t bundle,
                                       M_driver_bundle_compilation_options_t,
                                       M_driver_runtime_bundle_t *runtime_bundle) {
  if (!bundle || !runtime_bundle || !bundle->mapped_data.data)
    return M_DRIVER_STATUS_INVALID_ARG;
  auto *b = new Bundle;
  b->spirv.assign(bundle->mapped_data.data, bundle->mapped_data.size);
  *runtime_bundle = reinterpret_cast<M_driver_runtime_bundle_t>(b);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_bundle_unload(M_driver_context_t, M_driver_runtime_bundle_t bundle) {
  delete reinterpret_cast<Bundle *>(bundle);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_function_load(M_driver_context_t, M_driver_runtime_bundle_t bundle, const char *,
                                         uint64_t, M_driver_function_t *function) {
  // A module holds one kernel, whose entry point is "main", whatever MAX calls it.
  auto *b = reinterpret_cast<Bundle *>(bundle);
  if (!b || !function)
    return M_DRIVER_STATUS_INVALID_ARG;
  auto f = std::make_unique<Function>();
  if (!describe(b->spirv, f->description))
    return M_DRIVER_STATUS_BAD_FUNCTION;
  if (!b->module) {
    uint64_t id = nextModule;
    if (!call(OP_LOAD, &id, 8, b->spirv.data(), b->spirv.size()))
      return failed();
    b->module = nextModule++;
  }
  f->module = b->module;
  *function = reinterpret_cast<M_driver_function_t>(f.release());
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_function_unload(M_driver_context_t, M_driver_function_t function) {
  delete reinterpret_cast<Function *>(function);
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_function_property(M_driver_context_t, M_driver_function_t function, const char *name,
                                             void *value) {
  if (!function)
    return M_DRIVER_STATUS_BAD_FUNCTION;
  if (!name || !value)
    return M_DRIVER_STATUS_INVALID_ARG;
  if (!strcmp(name, M_DRIVER_FUNCTION_PROPERTY_NATIVE_HANDLE)) {
    *static_cast<uint64_t *>(value) = reinterpret_cast<Function *>(function)->module;
    return M_DRIVER_STATUS_SUCCESS;
  }
  return M_DRIVER_STATUS_UNKNOWN_PROPERTY_NAME;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_function_set_attribute(M_driver_context_t, M_driver_function_t function, int32_t,
                                                  int32_t) {
  return function ? M_DRIVER_STATUS_SUCCESS : M_DRIVER_STATUS_BAD_FUNCTION;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_function_occupancy_max_active_blocks(M_driver_context_t, M_driver_function_t function,
                                                                int32_t block_size, uint64_t, int32_t *num_blocks) {
  if (!function)
    return M_DRIVER_STATUS_BAD_FUNCTION;
  if (!num_blocks)
    return M_DRIVER_STATUS_INVALID_ARG;
  *num_blocks = block_size > 0 ? std::max(1, 1024 / block_size) : 1;
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_tensor_map_encode_tiled(M_driver_context_t, void *, int32_t, uint32_t, uint64_t,
                                                   const uint64_t *, const uint64_t *, const uint32_t *,
                                                   const uint32_t *, int32_t, int32_t, int32_t, int32_t) {
  return M_DRIVER_STATUS_INCOMPATIBLE;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_tensor_map_encode_im2col(M_driver_context_t, void *, int32_t, uint32_t, uint64_t,
                                                    const uint64_t *, const uint64_t *, const int32_t *,
                                                    const int32_t *, int32_t, int32_t, const uint32_t *,
                                                    int32_t, int32_t, int32_t, int32_t) {
  return M_DRIVER_STATUS_INCOMPATIBLE;
}

// The executor reads `size` bytes of the file `path`, from `file_offset`, into the device memory at `address` (an
// address this plugin handed out). The file is on the executor's side: for the remote plugin, the device running
// vk_server, so weights already there need not cross the transport. Programs reach this with dlopen/dlsym of the
// plugin (Mojo: OwnedDLHandle(path).call["M_driver_remote_file", Int32](...)). Returns 0, or -1; a read error is
// reported at the next synchronize.
__attribute__((visibility("default"))) int M_driver_remote_file(uint64_t address, uint64_t size, const char *path,
                                                                 uint64_t file_offset) {
  uint64_t offset = 0;
  Memory *m = memoryAt(address, offset);
  if (!m || m->host || !path || offset + size > m->size) {
    fprintf(stderr, "vulkan driver: file read into unknown device memory %llx (+%llu bytes)\n",
            static_cast<unsigned long long>(address), static_cast<unsigned long long>(size));
    return -1;
  }
  uint64_t header[4] = {m->buffer, m->base + offset, file_offset, size};
  return call(OP_FILE, header, 32, path, strlen(path)) ? 0 : -1;
}

// When the work before it is done, the executor copies row t of a table in the file `path` (rows of `row_bytes` from
// `file_offset`) into the device memory at `address`, t being the int32 at device address `token`: an embedding row
// for a token the GPU chose (its argmax), without a round trip to the host. Returns 0, or -1.
__attribute__((visibility("default"))) int M_driver_remote_gather(uint64_t address, uint64_t token, const char *path,
                                                                   uint64_t file_offset, uint64_t row_bytes) {
  uint64_t offset = 0, toffset = 0;
  Memory *m = memoryAt(address, offset), *tm = memoryAt(token, toffset);
  if (!m || m->host || !tm || tm->host || !path || offset + row_bytes > m->size || toffset + 4 > tm->size) {
    fprintf(stderr, "vulkan driver: gather into or from unknown device memory\n");
    return -1;
  }
  uint64_t header[6] = {m->buffer, m->base + offset, tm->buffer, tm->base + toffset, file_offset, row_bytes};
  return call(OP_GATHER, header, 48, path, strlen(path)) ? 0 : -1;
}

// Timing without the transport (vla/x2's vk_server): M_driver_remote_record(1) has the server keep a copy of the
// requests that follow, (0) stops; M_driver_remote_replay(n) runs them n more times there and returns the server's
// milliseconds for it (through a final wait), or a negative number.
__attribute__((visibility("default"))) int M_driver_remote_record(int on) {
  uint32_t v = on ? 1 : 0;
  return call(OP_RECORD, &v, 4) ? 0 : -1;
}

__attribute__((visibility("default"))) double M_driver_remote_replay(int count) {
  uint32_t v = static_cast<uint32_t>(count);
  std::string out;
  if (!call(OP_REPLAY, &v, 4, nullptr, 0, &out) || out.size() != 8)
    return -1;
  double ms;
  memcpy(&ms, out.data(), 8);
  return ms;
}

// π0's Gemma prefix on the NPU of the device running vla/x2's vk_server_npu (npu/pi0_prefix.cpp there), its K/V
// written straight into this plugin's device memory, so they never cross the transport (pi0/pi0npu.mojo built for
// vla/x2). M_driver_remote_npu_open loads the compiled graphs in `dir` (a path there): *ms the time it took, *rows the
// rows of a prefix, *parts the graphs. Returns 0, or -1.
__attribute__((visibility("default"))) int M_driver_remote_npu_open(const char *dir, double *ms, int32_t *rows,
                                                                     int32_t *parts) {
  std::string out;
  if (!dir || !call(OP_NPU_OPEN, dir, strlen(dir), nullptr, 0, &out) || out.size() != 16)
    return -1;
  memcpy(ms, out.data(), 8);
  memcpy(rows, out.data() + 8, 4);
  memcpy(parts, out.data() + 12, 4);
  return 0;
}

// The n prefix rows' positions and key mask: `rope` is transformers' table ([2][1024][128] fp32: cos, then sin),
// pos[r] row r's position, valid[r] whether keys may attend to it. Returns 0, or -1.
__attribute__((visibility("default"))) int M_driver_remote_npu_rope(const float *rope, const int32_t *pos,
                                                                     const int32_t *valid, int32_t n) {
  constexpr size_t table = 2 * 1024 * 128;
  std::string payload(4 + table * 4 + 8 * static_cast<size_t>(n), '\0');
  uint32_t rows = static_cast<uint32_t>(n);
  memcpy(payload.data(), &rows, 4);
  memcpy(payload.data() + 4, rope, table * 4);
  memcpy(payload.data() + 4 + table * 4, pos, 4 * static_cast<size_t>(n));
  memcpy(payload.data() + 4 + table * 4 + 4 * n, valid, 4 * static_cast<size_t>(n));
  return call(OP_NPU_ROPE, payload.data(), payload.size(), nullptr, 0, nullptr) ? 0 : -1;
}

// The prefix: once the work before it is done, the n rows of 2048 fp32 at device address x through the graphs, and
// layer l's K and V (after RoPE; fp32 [n][256]) into the device memory at k[l] and v[l], l < layers, as each graph
// finishes. Not waited for: the requests after it run when it is done, and its errors come with the next answer.
// Returns 0, or -1 for addresses this plugin did not hand out.
__attribute__((visibility("default"))) int M_driver_remote_npu_prefix(uint64_t x, int32_t n, const uint64_t *k,
                                                                       const uint64_t *v, int32_t layers) {
  std::vector<uint64_t> request;  // x's buffer and offset, n, then each layer's K and V
  auto place = [&](uint64_t address, uint64_t size) {
    uint64_t offset = 0;
    Memory *m = memoryAt(address, offset);
    if (!m || m->host || offset + size > m->size) {
      fprintf(stderr, "vulkan driver: NPU prefix with unknown device memory %llx (+%llu bytes)\n",
              static_cast<unsigned long long>(address), static_cast<unsigned long long>(size));
      return false;
    }
    request.push_back(m->buffer);
    request.push_back(m->base + offset);
    return true;
  };
  if (!place(x, 2048ull * 4 * n))
    return -1;
  request.push_back(static_cast<uint64_t>(n));
  for (int l = 0; l < layers; ++l)
    if (!place(k[l], 256ull * 4 * n) || !place(v[l], 256ull * 4 * n))
      return -1;
  return call(OP_NPU_PREFIX, request.data(), request.size() * 8) ? 0 : -1;
}

// The last prefix's times on the server's clock (ms): converting x to fp16, the graphs, and all of it through the last
// K/V written. Waits for the work before it. Returns 0, or -1.
__attribute__((visibility("default"))) int M_driver_remote_npu_time(double *convert, double *graphs, double *total) {
  std::string out;
  if (!call(OP_NPU_TIME, nullptr, 0, nullptr, 0, &out) || out.size() != 24)
    return -1;
  memcpy(convert, out.data(), 8);
  memcpy(graphs, out.data() + 8, 8);
  memcpy(total, out.data() + 16, 8);
  return 0;
}

// Any static ONNX graph on the NPU of the device running vla/x2's vk_server_npu (npu/graph.cpp there).
// M_driver_remote_npug_open loads the compiled graph at `path` (a path there): returns its handle, *ms the time it
// took; or -1.
__attribute__((visibility("default"))) int M_driver_remote_npug_open(const char *path, double *ms) {
  std::string out;
  if (!path || !call(OP_NPUG_OPEN, path, strlen(path), nullptr, 0, &out) || out.size() != 12)
    return -1;
  int32_t handle;
  memcpy(&handle, out.data(), 4);
  memcpy(ms, out.data() + 4, 8);
  return handle;
}

// Graph `handle` on nin inputs at the device addresses in[i] (in_bytes[i] each: fp32 or int32, as the graph takes
// them), its nout fp32 outputs written to the device memory at out[i], once the work before it is done. Not waited
// for: the requests after it run when it is done, and its errors come with the next answer. Returns 0, or -1 for
// addresses this plugin did not hand out.
__attribute__((visibility("default"))) int M_driver_remote_npug_run(int32_t handle, int32_t nin, const uint64_t *in,
                                                                     const uint64_t *in_bytes, int32_t nout,
                                                                     const uint64_t *out, const uint64_t *out_bytes) {
  std::vector<uint64_t> request(2, 0);
  uint32_t head[4] = {static_cast<uint32_t>(handle), static_cast<uint32_t>(nin), static_cast<uint32_t>(nout), 0};
  memcpy(request.data(), head, 16);
  auto place = [&](uint64_t address, uint64_t size) {
    uint64_t offset = 0;
    Memory *m = memoryAt(address, offset);
    if (!m || m->host || offset + size > m->size) {
      fprintf(stderr, "vulkan driver: NPU graph with unknown device memory %llx (+%llu bytes)\n",
              static_cast<unsigned long long>(address), static_cast<unsigned long long>(size));
      return false;
    }
    request.push_back(m->buffer);
    request.push_back(m->base + offset);
    request.push_back(size);
    return true;
  };
  for (int i = 0; i < nin; ++i)
    if (!place(in[i], in_bytes[i]))
      return -1;
  for (int i = 0; i < nout; ++i)
    if (!place(out[i], out_bytes[i]))
      return -1;
  return call(OP_NPUG_RUN, request.data(), request.size() * 8) ? 0 : -1;
}

// The last graph run's time on the server's clock (ms). Waits for the work before it. Returns 0, or -1.
__attribute__((visibility("default"))) int M_driver_remote_npug_time(double *ms) {
  std::string out;
  if (!call(OP_NPUG_TIME, nullptr, 0, nullptr, 0, &out) || out.size() != 8)
    return -1;
  memcpy(ms, out.data(), 8);
  return 0;
}

}  // extern "C"
