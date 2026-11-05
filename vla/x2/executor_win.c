// driver/executor.c, unchanged, built for Windows on ARM (the Snapdragon X2 Elite): dlopen comes from shim/dlfcn.h,
// and rename replaces the pipeline cache file as it does on POSIX (Windows' rename refuses an existing target).
#include <stdio.h>
#include <windows.h>

static int win_rename(const char* from, const char* to) { return MoveFileExA(from, to, MOVEFILE_REPLACE_EXISTING) ? 0 : -1; }
#define rename(from, to) win_rename(from, to)

#include "../../driver/executor.c"
