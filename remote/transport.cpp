// The driver plugin's executor over TCP: the plugin runs on the Mac, and remote/vk_server.c runs the
// executor on the phone (`adb forward tcp:7788 tcp:7788`, VK_REMOTE_PORT for another port). Only
// INFO, READ and SYNC are answered, so every other request streams without waiting, and its errors
// arrive with the next answer.
#include "../driver/protocol.h"
#include "../driver/transport.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cstdlib>

namespace {

int sock = -1;

bool connectServer(std::string &error) {
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
    error = "cannot reach vk_server on 127.0.0.1:" + std::to_string(port) + " (adb forward tcp:" +
            std::to_string(port) + " tcp:" + std::to_string(port) + ", and start it on the phone)";
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

bool lost(std::string &error) {
  close(sock);
  sock = -1;
  error = "lost the connection to vk_server";
  return false;
}

}  // namespace

const char *transportKind() { return "remote"; }

bool transportCall(uint32_t op, const void *a, size_t na, const void *b, size_t nb, std::string *out,
                   std::string &error) {
  if (!connectServer(error))
    return false;
  uint32_t header[2] = {op, static_cast<uint32_t>(na + nb)};
  bool answered = op == OP_INFO || op == OP_READ || op == OP_SYNC || op == OP_REPLAY || op == OP_NPU_OPEN ||
                  op == OP_NPU_ROPE || op == OP_NPU_TIME || op == OP_NPUG_OPEN || op == OP_NPUG_TIME;
  if (!sendAll(header, sizeof header) || (na && !sendAll(a, na)) || (nb && !sendAll(b, nb)))
    return lost(error);
  if (!answered)
    return true;
  uint32_t reply[2] = {0, 0};
  if (!recvAll(reply, sizeof reply))
    return lost(error);
  std::string payload(reply[1], '\0');
  if (reply[1] && !recvAll(payload.data(), reply[1]))
    return lost(error);
  if (reply[0]) {
    error = "vk_server: " + payload;
    return false;
  }
  if (out)
    *out = std::move(payload);
  return true;
}
