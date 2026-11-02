// glibc names that Mojo's stdlib calls when it compiles for Linux, which Android's Bionic provides
// under other names: the stdlib takes aarch64-unknown-linux-android33 as Linux (FileHandle's errno,
// os.stat and os.makedirs). On arm64, glibc and Bionic share the kernel's struct stat.
#include <errno.h>
#include <sys/stat.h>

int* __errno_location(void) { return __errno(); }

int __xstat(int version, const char* path, struct stat* buf) {
  (void)version;
  return stat(path, buf);
}

int __lxstat(int version, const char* path, struct stat* buf) {
  (void)version;
  return lstat(path, buf);
}

int __fxstat(int version, int fd, struct stat* buf) {
  (void)version;
  return fstat(fd, buf);
}
