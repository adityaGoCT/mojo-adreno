// remote/vk_server.c for Windows on ARM: the Vulkan executor (driver/executor.c) of the remote MAX device on a
// Snapdragon X2 Elite laptop, serving the driver plugin on the Mac (driver/plugin.cpp with remote/transport.cpp)
// over one TCP connection on 127.0.0.1 (reached through an SSH port forward). The same protocol, with Winsock.
//
//   vk_server.exe [port]        VK_SERVER_PROFILE=1: the executor's batches; VK_PIPELINE_CACHE: the cache file
//
// VK_SERVER_SEGMENTS=1 prints, at each synchronize or read, the time from the first request after the previous one
// to its answer, and the launches in between: the GPU's time for that stretch of work without the network's round
// trip, which through an SSH tunnel is a few hundred ms (the requests still stream in at the tunnel's rate).
//
// Built with -DVK_SERVER_NPU (vk_server_npu.exe, linked with npu/pi0_prefix.cpp and ONNX Runtime's QNN package, and run
// from the directory of its DLLs), it also runs π0's Gemma prefix on the laptop's Hexagon NPU (OP_NPU_*): the K/V that
// the NPU computes go straight into the GPU's buffers, instead of 30 MB a prefix through the tunnel.
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

static void answer_error(const char* message) { answer(NULL, 1, message, (uint32_t)strlen(message)); }

// VK_SERVER_SEGMENTS: an answer ends a segment, which began at the first request after the previous answer.
static double segment_start = -1;
static int launches, prefixes;  // in the segment: OP_LAUNCH, OP_NPU_PREFIX

static void end_segment(int segments) {
  if (segments && (launches || prefixes))
    fprintf(stderr, "segment: %d launches%s, %.1f ms\n", launches, prefixes ? " and the NPU prefix" : "",
            now_ms() - segment_start);
  segment_start = -1;
  launches = 0;
  prefixes = 0;
}

#ifdef VK_SERVER_NPU
#include "../../npu/pi0_prefix.h"

char* vkx_host(uint64_t id, uint64_t offset, uint64_t size);  // executor_win.c
void vkx_fail(const char* message);

enum { NPU_D = 2048, NPU_HD = 256, NPU_L = 18 };
static double npu_times[3];  // the last prefix (ms): x to fp16, the graphs, all of it through the last K/V written

// The prefix (OP_NPU_PREFIX): once the GPU is done, x from its buffer through the graphs; as each graph finishes, its
// layers' K and V converted to fp32 into the GPU's buffers, while the NPU runs the next graph. Errors go to the next
// answer.
static void npu_prefix(const char* p, uint32_t n, int segments) {
  const uint64_t* w = (const uint64_t*)p;
  if (n != 24 + 32 * NPU_L) return vkx_fail("malformed NPU prefix");
  int rows = (int)w[2];
  const float* x = (const float*)vkx_host(w[0], w[1], (uint64_t)rows * NPU_D * 4);  // waits for the GPU
  if (!x) return vkx_fail("NPU prefix: x out of range");
  double t0 = now_ms();
  if (pi0npu_set_x(x, rows)) return vkx_fail(pi0npu_error());
  double t1 = now_ms();
  if (pi0npu_start()) return vkx_fail(pi0npu_error());
  for (int i = 0; i < pi0npu_parts(); i++) {
    if (pi0npu_part_wait(i)) break;
    for (int l = pi0npu_part_first(i); l < pi0npu_part_first(i + 1); l++)
      for (int which = 0; which < 2; which++) {
        const uint64_t* kv = w + 3 + 4 * l + 2 * which;
        float* dst = (float*)vkx_host(kv[0], kv[1], (uint64_t)rows * NPU_HD * 4);
        if (!dst) {
          pi0npu_finish(NULL);
          return vkx_fail("NPU prefix: K/V out of range");
        }
        pi0npu_kv(l, which, dst, rows);
      }
  }
  double graphs = 0;
  if (pi0npu_finish(&graphs)) return vkx_fail(pi0npu_error());
  npu_times[0] = t1 - t0;
  npu_times[1] = graphs;
  npu_times[2] = now_ms() - t0;
  if (segments)
    fprintf(stderr, "npu prefix: x to fp16 %.1f ms, graphs %.1f ms, through the last K/V %.1f ms\n", npu_times[0],
            npu_times[1], npu_times[2]);
}

// OP_NPU_OPEN, OP_NPU_ROPE and OP_NPU_TIME, answered.
static void npu_answered(uint32_t op, const char* p, uint32_t n) {
  if (op == OP_NPU_OPEN) {
    char dir[1024];
    snprintf(dir, sizeof dir, "%.*s", (int)n, p);
    double ms = 0;
    pi0npu_close();  // a client before this one may have opened them
    if (pi0npu_open(dir, &ms)) {
      answer_error(pi0npu_error());
      pi0npu_close();
      return;
    }
    char out[16];
    int32_t rows = pi0npu_rows(), parts = pi0npu_parts();
    memcpy(out, &ms, 8);
    memcpy(out + 8, &rows, 4);
    memcpy(out + 12, &parts, 4);
    fprintf(stderr, "npu: %d graphs loaded in %.2f s, %d rows\n", parts, ms / 1e3, rows);
    answer(NULL, 0, out, 16);
  } else if (op == OP_NPU_ROPE) {
    uint32_t rows = 0;
    const size_t table = 2 * 1024 * 128 * 4;
    if (n >= 4) memcpy(&rows, p, 4);
    if (n < 4 || n != 4 + table + 8 * (size_t)rows) return answer_error("malformed NPU rope");
    if (pi0npu_set_rope((const float*)(p + 4), (const int32_t*)(p + 4 + table),
                        (const int32_t*)(p + 4 + table + 4 * (size_t)rows), (int)rows))
      return answer_error(pi0npu_error());
    answer(NULL, 0, NULL, 0);
  } else {  // OP_NPU_TIME, or the prefix's error
    const char* e = vkx_take_error();
    if (e) return answer_error(e);
    answer(NULL, 0, npu_times, sizeof npu_times);
  }
}
#endif

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
    end_segment(0);
    char* kept = NULL;  // OP_RECORD's copy of the requests: {u32 op, u32 n, n bytes} each
    size_t nkept = 0, capkept = 0;
    int recording = 0;
    while (!recv_all(header, sizeof header)) {
      if (segment_start < 0) segment_start = now_ms();
      payload = realloc(payload, header[1] ? header[1] : 1);
      if (recv_all(payload, header[1])) break;
      if (header[0] >= OP_NPU_OPEN && header[0] <= OP_NPU_TIME) {
#ifdef VK_SERVER_NPU
        if (header[0] == OP_NPU_PREFIX) {
          npu_prefix(payload, header[1], segments);
          prefixes++;
          continue;
        }
        npu_answered(header[0], payload, header[1]);
#else
        if (header[0] != OP_NPU_PREFIX) answer_error("no NPU in this vk_server (vk_server_npu.exe has one)");
#endif
        end_segment(segments);
        continue;
      }
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
      if (header[0] == OP_SYNC || header[0] == OP_READ) end_segment(segments);
    }
    vkx_reset();
    free(kept);
    free(payload);
    closesocket(client);
    client = INVALID_SOCKET;
  }
}
