// Vulkan executor on the phone for the remote MAX device: runs driver/executor.c for the driver
// plugin on the Mac (driver/plugin.cpp with remote/transport.cpp) over one TCP connection
// (`adb forward tcp:7788 tcp:7788`).
//
//   LD_LIBRARY_PATH=/data/local/tmp/turnip vk_server [port]
//
// Protocol (little-endian, driver/protocol.h): a request is {u32 op, u32 length, payload}. Only
// INFO, READ and SYNC are answered, with {i32 status, u32 length, payload}; status 0 is success,
// otherwise the payload is the first error since the last answer. The plugin names buffers and
// modules itself, so it streams everything else without waiting.
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
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
    while (!recv_all(header, sizeof header)) {
      payload = realloc(payload, header[1] ? header[1] : 1);
      if (recv_all(payload, header[1])) break;
      vkx_handle(header[0], payload, header[1], NULL, 0, answer, NULL);
    }
    vkx_reset();
    free(payload);
    close(client);
    client = -1;
  }
}
