#!/bin/sh
# Builds the vla/ programs (smolvla, pi0) as macOS programs whose kernels are adreno840 SPIR-V, for the remote
# driver plugin (driver/plugin.cpp + remote/transport.cpp) and vla/x2's Vulkan server on a Windows-on-ARM
# Snapdragon X2 Elite laptop; and the server itself (Zig's clang for aarch64-windows-gnu). Outputs: build/vla/x2.
#   vla/x2/build_mac.sh [smolvla] [pi0]
set -e
cd "$(dirname "$0")/../.."
MOJO_SRC=${MOJO_SRC:-../modular}
R=$(cd "$MOJO_SRC" && pwd)/bazel-bin
OUT=build/vla/x2
ZIG=${ZIG:-build/vla/zig/zig}
mkdir -p $OUT
"$ZIG" cc -target aarch64-windows-gnu -O2 -I vla/x2/shim -I /opt/homebrew/opt/vulkan-headers/include \
    -o $OUT/vk_server.exe vla/x2/vk_server_win.c vla/x2/executor_win.c -lws2_32
clang++ -std=c++17 -O1 -shared -fPIC -I"$MOJO_SRC/SDK/include" -o $OUT/libM_driver_vulkan_remote.dylib \
    driver/plugin.cpp remote/transport.cpp
for name in ${@:-smolvla pi0}; do
  MODULAR_MAX_PACKAGE_ROOT=$PWD/.venv-mojo/lib/python3.12/site-packages/modular "$R/Mojo/tools/mojo/mojo" build \
      --emit object -O3 --target-accelerator adreno840 -I build/android/packages -I $name -I vla -I vla/kernels \
      -o $OUT/$name.o $name/$name.mojo
  clang++ -o $OUT/$name $OUT/$name.o -L"$R/Mojo" -lKGENCompilerRTShared -Wl,-rpath,"$R/Mojo" \
      -Wl,-rpath,"$R/AsyncRT" -Wl,-rpath,"$R/Support"
done
