// Vulkan executor on the phone for the remote MAX device: runs driver/executor.c for the driver
// plugin on the Mac (driver/plugin.cpp with remote/transport.cpp) over one TCP connection
// (`adb forward tcp:7788 tcp:7788`).
//
//   LD_LIBRARY_PATH=/data/local/tmp/turnip vk_server [port]
//
// Protocol (little-endian, driver/protocol.h): a request is {u32 op, u32 length, payload}. Only
// INFO, READ, SYNC and REPLAY are answered, with {i32 status, u32 length, payload}; status 0 is
// success, otherwise the payload is the first error since the last answer. The plugin names buffers
// and modules itself, so it streams everything else without waiting.
//
// OP_RECORD (1 / 0) keeps the requests between the two (not READ, SYNC or INFO); OP_REPLAY (count)
// runs them count times more, then waits, and answers the phone's time for them (fp64 ms): a chunk
// on the device's own clock, without adb's forwarding (as vla/x2's Windows server does).
// VK_SERVER_SEGMENTS=1: each answer prints the launches since the previous one and their time.
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <time.h>
#include <unistd.h>

#include "../driver/executor.h"
#include "../driver/protocol.h"

static int client = -1;

static int send_all(const void* data, size_t n) {
  const char* p = data;
  while (n) {
    ssize_t k = send(client, p, n, 0);
    if (k <= 0) return -1;
    p += k;
    n -= (size_t)k;
  }
  return 0;
}

static int recv_all(void* data, size_t n) {
  char* p = data;
  while (n) {
    ssize_t k = recv(client, p, n, 0);
    if (k <= 0) return -1;
    p += k;
    n -= (size_t)k;
  }
  return 0;
}

static void answer(void* ctx, int status, const void* data, uint32_t n) {
  (void)ctx;
  uint32_t header[2] = {(uint32_t)status, n};
  send_all(header, sizeof header);
  if (n) send_all(data, n);
}

static double now_ms(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return (double)t.tv_sec * 1e3 + (double)t.tv_nsec / 1e6;
}

static int kept_status;  // the replay's waits: their status and error, not sent
static char kept_error[512];

static void keep_answer(void* ctx, int status, const void* data, uint32_t n) {
  (void)ctx;
  kept_status = status;
  if (status) snprintf(kept_error, sizeof kept_error, "%.*s", (int)n, (const char*)data);
}

static double segment_start = -1;  // VK_SERVER_SEGMENTS: an answer ends a segment
static int launches;

static void end_segment(int segments) {
  if (segments && launches) fprintf(stderr, "segment: %d launches, %.1f ms\n", launches, now_ms() - segment_start);
  segment_start = -1;
  launches = 0;
}

int main(int argc, char** argv) {
  int port = argc > 1 ? atoi(argv[1]) : DEFAULT_PORT;
  // One command a submission: a ResNet's worth of slow kernels in one outlasts the driver's timeout.
  if (vkx_init(1)) {
    fprintf(stderr, "vk_server: %s\n", vkx_take_error());
    return 2;
  }
  int s = socket(AF_INET, SOCK_STREAM, 0);
  int one = 1;
  setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
  struct sockaddr_in addr = {0};
  addr.sin_family = AF_INET;
  addr.sin_port = htons((uint16_t)port);
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  if (bind(s, (struct sockaddr*)&addr, sizeof addr) || listen(s, 1)) { perror("bind"); return 2; }
  printf("vk_server: listening on 127.0.0.1:%d\n", port);
  fflush(stdout);
  // One client at a time; its buffers and modules outlive it until the server exits.
  for (;;) {
    client = accept(s, NULL, NULL);
    if (client < 0) continue;
    setsockopt(client, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
    uint32_t header[2];
    char* payload = NULL;
    const char* env = getenv("VK_SERVER_SEGMENTS");
    int segments = env && *env && *env != '0';
    end_segment(0);
    char* kept = NULL;  // OP_RECORD's copy of the requests: {u32 op, u32 n, n bytes, padded to 8} each
    size_t nkept = 0, capkept = 0;
    int recording = 0;
    while (!recv_all(header, sizeof header)) {
      if (segment_start < 0) segment_start = now_ms();
      payload = realloc(payload, header[1] ? header[1] : 1);
      if (recv_all(payload, header[1])) break;
      if (header[0] >= OP_NPU_OPEN && header[0] <= OP_NPUG_TIME) {  // the NPU is vla/x2's Windows server's
        if (header[0] != OP_NPU_PREFIX && header[0] != OP_NPUG_RUN) {
          const char* m = "no NPU in this vk_server";
          answer(NULL, 1, m, (uint32_t)strlen(m));
        }
        continue;
      }
      if (header[0] == OP_RECORD) {
        recording = header[1] == 4 && *(uint32_t*)payload;
        if (recording) nkept = 0;
        continue;
      }
      if (header[0] == OP_REPLAY) {
        uint32_t count = header[1] == 4 ? *(uint32_t*)payload : 0;
        kept_status = 0;
        vkx_handle(OP_SYNC, NULL, 0, NULL, 0, keep_answer, NULL);
        int failed = kept_status;
        double t0 = now_ms();
        for (uint32_t k = 0; k < count && !failed; ++k)
          for (size_t at = 0; at < nkept;) {
            uint32_t* h = (uint32_t*)(kept + at);
            vkx_handle(h[0], kept + at + 8, h[1], NULL, 0, keep_answer, NULL);
            at += 8 + ((h[1] + 7) & ~7u);
          }
        vkx_handle(OP_SYNC, NULL, 0, NULL, 0, keep_answer, NULL);
        double ms = now_ms() - t0;
        if (failed || kept_status)
          answer(NULL, 1, kept_error, (uint32_t)strlen(kept_error));
        else
          answer(NULL, 0, &ms, 8);
        continue;
      }
      if (recording && header[0] != OP_SYNC && header[0] != OP_READ && header[0] != OP_INFO) {
        size_t need = nkept + 8 + ((header[1] + 7) & ~7u);
        if (need > capkept) kept = realloc(kept, capkept = need * 2);
        memcpy(kept + nkept, header, 8);
        memcpy(kept + nkept + 8, payload, header[1]);
        nkept = need;
      }
      if (header[0] == OP_LAUNCH) launches++;
      vkx_handle(header[0], payload, header[1], NULL, 0, answer, NULL);
      if (header[0] == OP_SYNC || header[0] == OP_READ) end_segment(segments);
    }
    vkx_reset();
    free(kept);
    free(payload);
    close(client);
    client = -1;
  }
}
