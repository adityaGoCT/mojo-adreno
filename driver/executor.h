// The Vulkan side of the driver plugin: owns the GPU's buffers and pipelines and runs the requests
// of driver/protocol.h. The plugin calls it directly on the phone (driver/local.cpp); remote/
// vk_server.c runs it for the plugin on the Mac.
#ifndef DRIVER_EXECUTOR_H
#define DRIVER_EXECUTOR_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Answers INFO, READ and SYNC: status 0 and the data, or 1 and the first error since the last answer.
typedef void (*vkx_answer_fn)(void* ctx, int status, const void* data, uint32_t n);

// Creates the Vulkan device. `submit_every` commands share a queue submission (VK_SUBMIT_EVERY
// overrides it). Returns 0, or -1 with the reason in vkx_take_error().
int vkx_init(int submit_every);

// Runs one request. Its payload is `p` (n bytes) followed by `tail` (ntail bytes): WRITE's data and
// LOAD's SPIR-V can come apart from their headers, so the plugin need not copy them into one piece.
void vkx_handle(uint32_t op, const char* p, uint32_t n, const char* tail, uint64_t ntail, vkx_answer_fn answer,
                void* ctx);

// The first error since the last answer, which it clears; NULL if none.
const char* vkx_take_error(void);

// Waits for the GPU, then frees every buffer and module: the client went away.
void vkx_reset(void);

#ifdef __cplusplus
}
#endif

#endif  // DRIVER_EXECUTOR_H
