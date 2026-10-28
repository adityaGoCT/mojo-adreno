// Requests between the remote MAX device's driver plugin (Mac) and its Vulkan executor (phone).
// A request is {u32 op, u32 length, payload}. INFO, READ and SYNC are answered with
// {i32 status, u32 length, payload}, which reports the first error since the last answer; the
// plugin names buffers and modules itself, so it streams every other request without waiting.
#ifndef REMOTE_PROTOCOL_H
#define REMOTE_PROTOCOL_H

#include <stdint.h>

#define DEFAULT_PORT 7788
#define MAX_BINDINGS 64

enum {
  OP_INFO = 1,  // -> "device name|vulkan version|storage buffer offset alignment"
  OP_ALLOC,     // u64 buffer, u64 size
  OP_FREE,      // u64 buffer
  OP_WRITE,     // u64 buffer, u64 offset, bytes
  OP_READ,      // u64 buffer, u64 offset, u64 size -> bytes
  OP_FILL,      // u64 buffer, u64 offset, u64 size, u64 value, u64 value size
  OP_COPY,      // u64 dst buffer, u64 dst offset, u64 src buffer, u64 src offset, u64 size
  OP_LOAD,      // u64 module, SPIR-V
  OP_LAUNCH,    // launch_t, nbind binding_t, params_len bytes of params
  OP_SYNC,      // waits for everything before it
};

// A kernel launch: storage buffers at bindings 0..nbind-1, then the params buffer (if any).
typedef struct {
  uint64_t module;
  uint32_t groups[3];
  uint32_t block[3];  // also the workgroup size: specialization constants 0-2
  uint32_t nbind;
  uint32_t params_len;
} launch_t;

typedef struct {
  uint64_t buffer;
  uint64_t offset;
} binding_t;

#endif  // REMOTE_PROTOCOL_H
