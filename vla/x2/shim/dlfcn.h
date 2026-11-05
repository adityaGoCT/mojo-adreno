// dlopen for driver/executor.c on Windows: its one dlopen("libvulkan.so") loads the Vulkan loader, vulkan-1.dll.
#pragma once
#include <windows.h>
#define RTLD_NOW 0
#define RTLD_LOCAL 0
static inline void* dlopen(const char* name, int flags) {
  (void)name;
  (void)flags;
  return (void*)LoadLibraryA("vulkan-1.dll");
}
static inline void* dlsym(void* lib, const char* name) { return (void*)GetProcAddress((HMODULE)lib, name); }
static inline const char* dlerror(void) { return "LoadLibrary(vulkan-1.dll) failed"; }
