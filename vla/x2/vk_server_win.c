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
    while (!recv_all(header, sizeof header)) {
      if (first < 0) first = now_ms();
      payload = realloc(payload, header[1] ? header[1] : 1);
      if (recv_all(payload, header[1])) break;
      if (header[0] == OP_LAUNCH) launches++;
      vkx_handle(header[0], payload, header[1], NULL, 0, answer, NULL);
      if (header[0] == OP_SYNC || header[0] == OP_READ) {
        if (segments && launches) fprintf(stderr, "segment: %d launches, %.1f ms\n", launches, now_ms() - first);
        first = -1;
        launches = 0;
      }
    }
    vkx_reset();
    free(payload);
    closesocket(client);
    client = INVALID_SOCKET;
  }
}
