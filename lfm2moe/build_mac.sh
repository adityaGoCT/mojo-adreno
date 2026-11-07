#!/bin/sh
# Builds LFM2.5-24B-A2B for the QDC laptop (vla/x2's setup): vk_server.exe (OP_FILE, OP_RECORD/OP_REPLAY; Zig for
# aarch64-windows-gnu) and convert.exe (lfm2/convert.c: the weight file from the GGUF, on the laptop); the remote
# driver plugin and lfm2moe (Mojo for the Mac, kernels as adreno840 SPIR-V). Outputs: build/lfm2moe/x2.
#   lfm2moe/build_mac.sh
set -e
cd "$(dirname "$0")/.."
MOJO_SRC=${MOJO_SRC:-../modular}
R=$(cd "$MOJO_SRC" && pwd)/bazel-bin
OUT=build/lfm2moe/x2
ZIG=${ZIG:-build/vla/zig/zig}
mkdir -p $OUT
"$ZIG" cc -target aarch64-windows-gnu -O2 -I vla/x2/shim -I /opt/homebrew/opt/vulkan-headers/include \
    -o $OUT/vk_server.exe vla/x2/vk_server_win.c vla/x2/executor_win.c -lws2_32
"$ZIG" cc -target aarch64-windows-gnu -O2 -ffp-contract=off -D_FILE_OFFSET_BITS=64 -o $OUT/convert.exe lfm2/convert.c
clang++ -std=c++17 -O1 -shared -fPIC -I"$MOJO_SRC/SDK/include" -o $OUT/libM_driver_vulkan_remote.dylib \
    driver/plugin.cpp remote/transport.cpp
MODULAR_MAX_PACKAGE_ROOT=$PWD/.venv-mojo/lib/python3.12/site-packages/modular "$R/Mojo/tools/mojo/mojo" build \
    --emit object -O3 --target-accelerator adreno840 -I build/android/packages -I lfm2moe -I lfm2moe/kernels \
    -I lfm2/kernels -I gemma4/kernels -o $OUT/lfm2moe.o lfm2moe/lfm2moe.mojo
clang++ -o $OUT/lfm2moe $OUT/lfm2moe.o -L"$R/Mojo" -lKGENCompilerRTShared -Wl,-rpath,"$R/Mojo" \
    -Wl,-rpath,"$R/AsyncRT" -Wl,-rpath,"$R/Support"
ls -la $OUT
