// Requests from the driver plugin (driver/plugin.cpp) to its Vulkan executor (driver/executor.c),
// in the same process on the phone or over TCP from the Mac (remote/). A request is {u32 op, u32
// length, payload}. INFO, READ and SYNC are answered with {i32 status, u32 length, payload}, which
// reports the first error since the last answer; the plugin names buffers and modules itself, so
// it streams every other request without waiting.
#ifndef DRIVER_PROTOCOL_H
#define DRIVER_PROTOCOL_H

#include <stdint.h>

#define DEFAULT_PORT 7788
#define MAX_BINDINGS 64

enum {
  OP_INFO = 1,  // -> "device name|vulkan version|storage buffer offset alignment|shared memory bytes|
                //     workgroup invocations|workgroup size x|y|z|subgroup size"
  OP_ALLOC,     // u64 buffer, u64 size
  OP_FREE,      // u64 buffer
  OP_WRITE,     // u64 buffer, u64 offset, bytes
  OP_READ,      // u64 buffer, u64 offset, u64 size -> bytes
  OP_FILL,      // u64 buffer, u64 offset, u64 size, u64 value, u64 value size
  OP_COPY,      // u64 dst buffer, u64 dst offset, u64 src buffer, u64 src offset, u64 size
  OP_LOAD,      // u64 module, SPIR-V
  OP_LAUNCH,    // launch_t, nbind binding_t, params_len bytes of params
  OP_SYNC,      // waits for everything before it
  OP_FILE,      // u64 buffer, u64 offset, u64 file offset, u64 size, path: a file's bytes into the buffer, read on the
                // executor's side (weights already on the device running it, not sent through the transport)
  OP_GATHER,    // u64 buffer, u64 offset, u64 token buffer, u64 token offset, u64 file offset, u64 row bytes, path:
                // when the GPU is done, row t of a table in the file, t the int32 the GPU left at the token offset
                // (an embedding row for a token the GPU chose, without asking the host)
  OP_RECORD,    // u32 1: keep a copy of the requests that follow (still running them); 0: stop (vla/x2's vk_server)
  OP_REPLAY,    // u32 count: run the kept requests `count` times more -> f64 milliseconds on the server's clock,
                // through a final wait: the GPU's time for them without the transport (vla/x2's vk_server)
  // π0's Gemma prefix on the executor's NPU (npu/pi0_prefix.cpp inside vla/x2's vk_server_npu): its K/V go straight
  // into the GPU's buffers, without crossing the transport.
  OP_NPU_OPEN,    // path of the compiled graphs -> f64 ms to load them, i32 rows, i32 graphs
  OP_NPU_ROPE,    // u32 n, f32 rope [2][1024][128], i32 pos [n], i32 valid [n]: the rows' positions and key mask -> -
  OP_NPU_PREFIX,  // u64 x buffer, u64 x offset, u64 n, then per layer u64 K buffer, K offset, V buffer, V offset:
                  // when the GPU is done, x (n rows of 2048 fp32) through the graphs; as each graph finishes, its
                  // layers' K and V (fp32 [n][256]) written there. Not answered: the launches after it queue behind it
  OP_NPU_TIME,    // -> f64 x 3: the last prefix's ms: x to fp16, the graphs, all of it through the last K/V written
  // Any static ONNX graph on the executor's NPU (npu/graph.cpp inside vla/x2's vk_server_npu), reading its inputs from
  // and writing its outputs to the GPU's buffers: the VLA ports' NPU parts (turbovla/ first).
  OP_NPUG_OPEN,   // path of a compiled graph (an HTP context: npu/graph.cpp's graph_tool compile) -> i32 handle, f64 ms
  OP_NPUG_RUN,    // u32 handle, u32 inputs, u32 outputs, u32 0, then per input and per output u64 buffer, offset, bytes:
                  // when the GPU is done, the graph on its inputs (fp32 or int32 in the GPU's memory), its fp32 outputs
                  // written there. Not answered: the launches after it queue behind it; errors come with the next answer
  OP_NPUG_TIME,   // -> f64: the last run's ms on the server's clock
  OP_LAST = OP_NPUG_TIME,
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

#endif  // DRIVER_PROTOCOL_H
