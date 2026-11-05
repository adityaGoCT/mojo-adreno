#!/bin/sh
# Builds Qwen3-30B-A3B for the Snapdragon X2 Elite laptop (vla/x2's setup): vk_server.exe (with OP_FILE, Zig for
# aarch64-windows-gnu) and convert.exe for the laptop; the remote driver plugin and qwen3moe (Mojo, kernels as
# adreno840 SPIR-V) for the Mac. Outputs: build/qwen3moe/x2.
#   qwen3moe/build_mac.sh
set -e
cd "$(dirname "$0")/.."
MOJO_SRC=${MOJO_SRC:-../modular}
R=$(cd "$MOJO_SRC" && pwd)/bazel-bin
OUT=build/qwen3moe/x2
ZIG=${ZIG:-build/vla/zig/zig}
mkdir -p $OUT
"$ZIG" cc -target aarch64-windows-gnu -O2 -I vla/x2/shim -I /opt/homebrew/opt/vulkan-headers/include \
    -o $OUT/vk_server.exe vla/x2/vk_server_win.c vla/x2/executor_win.c -lws2_32
"$ZIG" cc -target aarch64-windows-gnu -O2 -o $OUT/convert.exe qwen3moe/convert.c
clang++ -std=c++17 -O1 -shared -fPIC -I"$MOJO_SRC/SDK/include" -o $OUT/libM_driver_vulkan_remote.dylib \
    driver/plugin.cpp remote/transport.cpp
MODULAR_MAX_PACKAGE_ROOT=$PWD/.venv-mojo/lib/python3.12/site-packages/modular "$R/Mojo/tools/mojo/mojo" build \
    --emit object -O3 --target-accelerator adreno840 -I build/android/packages -I qwen3moe -I qwen3moe/kernels \
    -I llama/kernels -o $OUT/qwen3moe.o qwen3moe/qwen3moe.mojo
clang++ -o $OUT/qwen3moe $OUT/qwen3moe.o -L"$R/Mojo" -lKGENCompilerRTShared -Wl,-rpath,"$R/Mojo" \
    -Wl,-rpath,"$R/AsyncRT" -Wl,-rpath,"$R/Support"
ls -la $OUT
