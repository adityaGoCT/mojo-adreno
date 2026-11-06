// driver/executor.c, unchanged, built for Windows on ARM (the Snapdragon X2 Elite): dlopen comes from shim/dlfcn.h,
// and rename replaces the pipeline cache file as it does on POSIX (Windows' rename refuses an existing target).
#include <stdio.h>
#include <windows.h>

static int win_rename(const char* from, const char* to) { return MoveFileExA(from, to, MOVEFILE_REPLACE_EXISTING) ? 0 : -1; }
#define rename(from, to) win_rename(from, to)

#include "../../driver/executor.c"

// For vk_server's own requests (the NPU's prefix): the host address of `size` bytes of a buffer from `offset`, once the
// GPU's work so far is done (the buffers are host-visible and coherent), or NULL; and an error for the next answer.
char* vkx_host(uint64_t id, uint64_t offset, uint64_t size) {
  buffer_t* b = buffer(id);
  if (!in_range(b, offset, size)) return NULL;
  flush();
  return b->map + offset;
}

void vkx_fail(const char* message) { fail("%s", message); }
