// The driver plugin's executor in the same process: the plugin runs on the phone, and each request
// is a call into driver/executor.c, which reports its errors at once.
#include "executor.h"
#include "protocol.h"
#include "transport.h"

namespace {

struct Answer {
  int status = 0;
  std::string *out;
};

void answer(void *ctx, int status, const void *data, uint32_t n) {
  auto *a = static_cast<Answer *>(ctx);
  a->status = status;
  a->out->assign(static_cast<const char *>(data), n);
}

}  // namespace

const char *transportKind() { return "local"; }

bool transportCall(uint32_t op, const void *a, size_t na, const void *b, size_t nb, std::string *out,
                   std::string &error) {
  // Several commands a submission: decode launches hundreds of small kernels a token.
  static const char *initError = vkx_init(64) ? vkx_take_error() : nullptr;
  if (initError) {
    error = initError;
    return false;
  }
  std::string scratch;
  Answer result{0, out ? out : &scratch};
  vkx_handle(op, static_cast<const char *>(a), static_cast<uint32_t>(na), static_cast<const char *>(b), nb, answer,
             &result);
  if (result.status) {
    error = *result.out;
    return false;
  }
  if (const char *failure = vkx_take_error()) {
    error = failure;
    return false;
  }
  return true;
}
