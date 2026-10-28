// A MAX driver plugin (the M_driver_* HAL interface in modular/modular's SDK/include/HAL) for a
// remote Vulkan device: MAX runs on the Mac, and every allocation, copy and kernel launch goes to
// remote/vk_server.c on the phone over TCP (`adb forward tcp:7788 tcp:7788`).
//
//   MODULAR_DRIVER_PLUGINS="vulkan@/path/to/libM_driver_vulkan_remote.dylib"
//
// Kernels come from Mojo's Vulkan SPIR-V target (`adreno710`), whose modules carry a launch
// description (OpModuleProcessed "mojo.vulkan.abi {json}"). A launch passes each argument as
// bytes, as for CUDA; the description says where each pointer and scalar inside them goes: a
// pointer (a device address this plugin handed out) becomes a storage-buffer binding at the
// allocation and offset it points into, a scalar a 64-bit slot of the params buffer.
//
// Queues are synchronous: the server runs each request to completion, in order.
#include "HAL/M_driver_api.h"
#include "protocol.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace {

// --- connection ----------------------------------------------------------------------------

std::mutex lock;  // one request at a time on the one connection
int sock = -1;
std::string lastError;

bool connectServer() {
  if (sock >= 0)
    return true;
  const char *env = getenv("VK_REMOTE_PORT");
  int port = env ? atoi(env) : DEFAULT_PORT;
  sock = socket(AF_INET, SOCK_STREAM, 0);
  sockaddr_in addr{};
  addr.sin_family = AF_INET;
  addr.sin_port = htons(static_cast<uint16_t>(port));
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  if (connect(sock, reinterpret_cast<sockaddr *>(&addr), sizeof addr)) {
    close(sock);
    sock = -1;
    lastError = "cannot reach vk_server on 127.0.0.1:" + std::to_string(port) +
                " (adb forward tcp:" + std::to_string(port) + " tcp:" + std::to_string(port) +
                ", and start it on the phone)";
    return false;
  }
  int one = 1;
  setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
  return true;
}

bool sendAll(const void *data, size_t n) {
  const char *p = static_cast<const char *>(data);
  while (n) {
    ssize_t k = send(sock, p, n, 0);
    if (k <= 0)
      return false;
    p += k;
    n -= static_cast<size_t>(k);
  }
  return true;
}

bool recvAll(void *data, size_t n) {
  char *p = static_cast<char *>(data);
  while (n) {
    ssize_t k = recv(sock, p, n, 0);
    if (k <= 0)
      return false;
    p += k;
    n -= static_cast<size_t>(k);
  }
  return true;
}

// Sends one request (its payload in up to two pieces) and returns whether it succeeded; the
// reply's payload goes to `out`, or its message to `lastError`.
bool call(uint32_t op, const void *a, size_t na, const void *b = nullptr, size_t nb = 0,
          std::string *out = nullptr) {
  std::lock_guard<std::mutex> guard(lock);
  if (!connectServer())
    return false;
  uint32_t header[2] = {op, static_cast<uint32_t>(na + nb)};
  uint32_t reply[2];
  if (!sendAll(header, sizeof header) || (na && !sendAll(a, na)) || (nb && !sendAll(b, nb)) ||
      !recvAll(reply, sizeof reply)) {
    close(sock);
    sock = -1;
    lastError = "lost the connection to vk_server";
    return false;
  }
  std::string payload(reply[1], '\0');
  if (reply[1] && !recvAll(payload.data(), reply[1])) {
    close(sock);
    sock = -1;
    lastError = "lost the connection to vk_server";
    return false;
  }
  if (reply[0]) {
    lastError = "vk_server: " + payload;
    fprintf(stderr, "vulkan_remote: %s\n", lastError.c_str());
    return false;
  }
  if (out)
    *out = std::move(payload);
  return true;
}

M_driver_status_t failed() { return M_DRIVER_STATUS_UNKNOWN_ERROR; }

// --- a minimal JSON reader, for launch descriptions ----------------------------------------

struct Json {
  enum Kind { Null, Bool, Number, String, Array, Object } kind = Null;
  double number = 0;
  std::string text;
  std::vector<Json> items;
  std::vector<std::pair<std::string, Json>> fields;

  const Json *get(const char *key) const {
    for (auto &field : fields)
      if (field.first == key)
        return &field.second;
    return nullptr;
  }
  int64_t integer(const char *key, int64_t fallback = -1) const {
    const Json *value = get(key);
    return value && value->kind == Number ? static_cast<int64_t>(value->number) : fallback;
  }
};

struct JsonParser {
  const char *p, *end;
  void space() {
    while (p < end && isspace(static_cast<unsigned char>(*p)))
      ++p;
  }
  bool parse(Json &out) {
    space();
    if (p >= end)
      return false;
    if (*p == '{') {
      out.kind = Json::Object;
      ++p;
      space();
      if (p < end && *p == '}')
        return ++p, true;
      for (;;) {
        Json key, value;
        if (!parse(key) || key.kind != Json::String)
          return false;
        space();
        if (p >= end || *p++ != ':' || !parse(value))
          return false;
        out.fields.emplace_back(key.text, std::move(value));
        space();
        if (p < end && *p == ',') { ++p; continue; }
        return p < end && *p++ == '}';
      }
    }
    if (*p == '[') {
      out.kind = Json::Array;
      ++p;
      space();
      if (p < end && *p == ']')
        return ++p, true;
      for (;;) {
        Json value;
        if (!parse(value))
          return false;
        out.items.push_back(std::move(value));
        space();
        if (p < end && *p == ',') { ++p; continue; }
        return p < end && *p++ == ']';
      }
    }
    if (*p == '"') {
      out.kind = Json::String;
      for (++p; p < end && *p != '"'; ++p) {
        if (*p == '\\' && p + 1 < end)
          ++p;  // the descriptions only escape quotes and backslashes
        out.text += *p;
      }
      return p < end && *p++ == '"';
    }
    if (!strncmp(p, "null", 4)) { p += 4; return true; }
    if (!strncmp(p, "true", 4)) { out.kind = Json::Bool; out.number = 1; p += 4; return true; }
    if (!strncmp(p, "false", 5)) { out.kind = Json::Bool; p += 5; return true; }
    char *next;
    out.kind = Json::Number;
    out.number = strtod(p, &next);
    if (next == p)
      return false;
    p = next;
    return true;
  }
};

// --- launch descriptions -------------------------------------------------------------------

struct Leaf {
  int64_t arg = -1, offset = 0, bytes = 8;  // where the value sits in the arguments
  int blockDim = -1;                         // or a params slot holding block_dim.x/.y/.z
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
  static const char prefix[] = "mojo.vulkan.abi ";
  for (size_t at = 5; at < count;) {
    uint32_t n = words[at] >> 16, opcode = words[at] & 0xffff;
    if (!n || at + n > count)
      break;
    if (opcode == 330) {  // OpModuleProcessed
      const char *text = reinterpret_cast<const char *>(&words[at + 1]);
      size_t length = strnlen(text, (n - 1) * 4);
      if (length > sizeof prefix - 1 && !strncmp(text, prefix, sizeof prefix - 1)) {
        Json json;
        JsonParser parser{text + sizeof prefix - 1, text + length};
        if (!parser.parse(json) || json.kind != Json::Object)
          return lastError = "malformed launch description", false;
        if (const Json *buffers = json.get("buffers"))
          for (const Json &b : buffers->items)
            out.buffers.push_back({b.integer("arg"), b.integer("offset"), 8});
        if (const Json *params = json.get("params"); params && params->kind == Json::Object) {
          out.hasParams = true;
          if (const Json *slots = params->get("slots"))
            for (const Json &s : slots->items) {
              Leaf leaf;
              if (const Json *value = s.get("value"))
                leaf.blockDim = value->text.back() - 'x';
              else
                leaf = {s.integer("arg"), s.integer("offset"),
                        scalarBytes(s.get("type") ? s.get("type")->text : "")};
              out.slots.push_back(leaf);
            }
        }
        return true;
      }
    }
    at += n;
  }
  return lastError = "SPIR-V module without a mojo.vulkan.abi launch description", false;
}

// --- objects -------------------------------------------------------------------------------

struct Memory {
  uint64_t buffer = 0;    // the server's buffer, for device memory
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
  std::string out;
  if (!call(OP_ALLOC, &size, 8, nullptr, 0, &out))
    return failed();
  auto *m = new Memory;
  memcpy(&m->buffer, out.data(), 8);
  m->size = size;
  m->address = nextAddress;
  nextAddress += (size + 0xffff) & ~0xffffull;  // 64 KiB apart: never adjacent
  byAddress[m->address] = m;
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
    byAddress.erase(m->address);
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
    uint64_t header[2] = {m->buffer, dst->offset + done};
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
    uint64_t request[3] = {m->buffer, src->offset + done, n};
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
  uint64_t request[5] = {d->buffer, dst->offset, s->buffer, src->offset, dst->size};
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
  uint64_t request[5] = {m->buffer, dst->offset, dst->size, value, valueSize};
  return call(OP_FILL, request, 40) ? M_DRIVER_STATUS_SUCCESS : failed();
}

M_driver_status_t execute(Function *f, const M_driver_dim_t &grid, const M_driver_dim_t &block,
                          void **args, uint64_t *argSizes, uint32_t numArgs) {
  const Description &d = f->description;
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
    Memory *m = address ? memoryAt(address, offset) : nullBuffer;
    if (!m && !address) {
      M_driver_memory_t placeholder;
      if (M_driver_status_t status = allocate(256, &placeholder))
        return status;
      m = nullBuffer = reinterpret_cast<Memory *>(placeholder);
    }
    if (!m || m->host)
      return lastError = "kernel argument is not a device address of this plugin", M_DRIVER_STATUS_INVALID_ARG;
    bindings.push_back({m->buffer, offset});
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
                        : lastError.empty() ? "vulkan_remote error " + std::to_string(status)
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

// --- device: the phone's Adreno 710 ----------------------------------------------------------

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
    return text("Adreno 710 (remote, Vulkan)");
  if (!strcmp(name, M_DRIVER_DEVICE_PROPERTY_ARCH))
    return text(getenv("VK_REMOTE_ARCH") ? getenv("VK_REMOTE_ARCH") : "adreno710");
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
  // CUDA's numbering, as MAX's DeviceAttribute: what Adreno 710 offers through Vulkan.
  switch (attribute) {
  case 1: *value = 1024; break;            // max threads per block
  case 2: case 3: *value = 1024; break;    // max block dim x, y
  case 4: *value = 64; break;              // max block dim z
  case 5: case 6: case 7: *value = 65535; break;  // max grid dim
  case 8: case 97: *value = 32768; break;  // shared memory per block (and opt-in)
  case 10: *value = 64; break;             // warp size (subgroup size of the target)
  case 12: case 82: *value = 65536; break; // registers
  case 13: *value = 950000; break;         // clock rate, kHz
  case 16: *value = 2; break;              // multiprocessors (shader processors)
  case 39: *value = 1024; break;           // max threads per multiprocessor
  case 75: *value = 7; break;              // "compute capability": Adreno 7xx
  case 76: *value = 10; break;
  case 81: *value = 32768; break;          // shared memory per multiprocessor
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
    if (offset)
      return delete m, lastError = "wrapping the inside of an allocation", M_DRIVER_STATUS_INVALID_ARG;
    *m = *base;
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

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_synchronize(M_driver_queue_t) { return M_DRIVER_STATUS_SUCCESS; }

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
  fn(user_data);  // the queue is synchronous: everything before has finished
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_queue_wait_value64(M_driver_queue_t, uint64_t, uint64_t) {
  return M_DRIVER_STATUS_INCOMPATIBLE;
}

// --- events: the queue is synchronous, so every event has happened ----------------------------

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
M_driver_status_t M_driver_event_synchronize(M_driver_context_t, M_driver_event_t) {
  return M_DRIVER_STATUS_SUCCESS;
}

M_DRIVER_API_EXPORT
M_driver_status_t M_driver_is_event_ready(M_driver_context_t, M_driver_event_t, bool *ready) {
  if (!ready)
    return M_DRIVER_STATUS_INVALID_ARG;
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
    std::string out;
    if (!call(OP_LOAD, b->spirv.data(), b->spirv.size(), nullptr, 0, &out))
      return failed();
    memcpy(&b->module, out.data(), 8);
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

}  // extern "C"
