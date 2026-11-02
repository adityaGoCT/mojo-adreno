// How the driver plugin reaches its Vulkan executor: in the same process on the phone
// (driver/local.cpp), or over TCP from the Mac (remote/transport.cpp).
#ifndef DRIVER_TRANSPORT_H
#define DRIVER_TRANSPORT_H

#include <cstddef>
#include <cstdint>
#include <string>

// Runs or sends one request of driver/protocol.h, its payload in two pieces (`b` may be empty).
// INFO, READ and SYNC wait for the answer, whose payload goes to `out`. Returns false with the
// reason in `error`: the request's own error, or for INFO, READ and SYNC the first error since the
// last answer.
bool transportCall(uint32_t op, const void *a, size_t na, const void *b, size_t nb, std::string *out,
                   std::string &error);

// "local" or "remote", for the device's name and messages.
const char *transportKind();

#endif  // DRIVER_TRANSPORT_H
