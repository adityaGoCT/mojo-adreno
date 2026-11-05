// remote/vk_server.c for Windows on ARM: the Vulkan executor (driver/executor.c) of the remote MAX device on a
// Snapdragon X2 Elite laptop, serving the driver plugin on the Mac (driver/plugin.cpp with remote/transport.cpp)
// over one TCP connection on 127.0.0.1 (reached through an SSH port forward). The same protocol, with Winsock.
//
//   vk_server.exe [port]        VK_SERVER_PROFILE=1: the executor's batches; VK_PIPELINE_CACHE: the cache file
//
// VK_SERVER_SEGMENTS=1 prints, at each synchronize or read, the time from the first request after the previous one
// to its answer, and the launches in between: the GPU's time for that stretch of work without the network's round
// trip, which through an SSH tunnel is a few hundred ms (the requests still stream in at the tunnel's rate).
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../../driver/executor.h"
#include "../../driver/protocol.h"

static SOCKET client = INVALID_SOCKET;

static double now_ms(void) {
  LARGE_INTEGER f, c;
  QueryPerformanceFrequency(&f);
  QueryPerformanceCounter(&c);
  return (double)c.QuadPart * 1e3 / (double)f.QuadPart;
}

static int send_all(const void* data, size_t n) {
  const char* p = data;
  while (n) {
    int k = send(client, p, n > (1u << 30) ? (1 << 30) : (int)n, 0);
    if (k <= 0) return -1;
    p += k;
    n -= (size_t)k;
  }
  return 0;
}

static int recv_all(void* data, size_t n) {
  char* p = data;
  while (n) {
    int k = recv(client, p, n > (1u << 30) ? (1 << 30) : (int)n, 0);
    if (k <= 0) return -1;
    p += k;
    n -= (size_t)k;
  }
  return 0;
}

static int kept_status;  // the replay's waits: their status and error, not sent
static char kept_error[512];

static void keep_answer(void* ctx, int status, const void* data, uint32_t n) {
  (void)ctx;
  kept_status = status;
  if (status) snprintf(kept_error, sizeof kept_error, "%.*s", (int)n, (const char*)data);
}

static void answer(void* ctx, int status, const void* data, uint32_t n) {
  (void)ctx;
  uint32_t header[2] = {(uint32_t)status, n};
  send_all(header, sizeof header);
  if (n) send_all(data, n);
}

int main(int argc, char** argv) {
  int port = argc > 1 ? atoi(argv[1]) : DEFAULT_PORT;
  WSADATA wsa;
  if (WSAStartup(MAKEWORD(2, 2), &wsa)) {
    fprintf(stderr, "vk_server: WSAStartup failed\n");
    return 2;
  }
  // One command a submission, as on the phone: long kernels batched together outlast the driver's timeout.
  if (vkx_init(1)) {
    fprintf(stderr, "vk_server: %s\n", vkx_take_error());
    return 2;
  }
  SOCKET s = socket(AF_INET, SOCK_STREAM, 0);
  int one = 1;
  setsockopt(s, SOL_SOCKET, SO_REUSEADDR, (const char*)&one, sizeof one);
  struct sockaddr_in addr = {0};
  addr.sin_family = AF_INET;
  addr.sin_port = htons((uint16_t)port);
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  if (bind(s, (struct sockaddr*)&addr, sizeof addr) || listen(s, 1)) {
    fprintf(stderr, "vk_server: bind: %d\n", WSAGetLastError());
    return 2;
  }
  printf("vk_server: listening on 127.0.0.1:%d\n", port);
  fflush(stdout);
  for (;;) {  // one client at a time; its buffers and modules are freed when it leaves
    client = accept(s, NULL, NULL);
    if (client == INVALID_SOCKET) continue;
    setsockopt(client, IPPROTO_TCP, TCP_NODELAY, (const char*)&one, sizeof one);
    uint32_t header[2];
    char* payload = NULL;
    const char* env = getenv("VK_SERVER_SEGMENTS");
    int segments = env && *env && *env != '0';
    double first = -1;
    int launches = 0;
    char* kept = NULL;  // OP_RECORD's copy of the requests: {u32 op, u32 n, n bytes} each
    size_t nkept = 0, capkept = 0;
    int recording = 0;
    while (!recv_all(header, sizeof header)) {
      if (first < 0) first = now_ms();
      payload = realloc(payload, header[1] ? header[1] : 1);
      if (recv_all(payload, header[1])) break;
      if (header[0] == OP_RECORD) {
        recording = header[1] == 4 && *(uint32_t*)payload;
        if (recording) nkept = 0;
        continue;
      }
      if (header[0] == OP_REPLAY) {  // the kept requests, `count` times, then a wait: the server's time for them
        uint32_t count = header[1] == 4 ? *(uint32_t*)payload : 0;
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
      if (header[0] == OP_SYNC || header[0] == OP_READ) {
        if (segments && launches) fprintf(stderr, "segment: %d launches, %.1f ms\n", launches, now_ms() - first);
        first = -1;
        launches = 0;
      }
    }
    vkx_reset();
    free(kept);
    free(payload);
    closesocket(client);
    client = INVALID_SOCKET;
  }
}
