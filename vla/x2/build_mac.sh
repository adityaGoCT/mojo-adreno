#!/bin/sh
# Builds the vla/ programs (smolvla, pi0) as macOS programs whose kernels are adreno840 SPIR-V, for the remote
# driver plugin (driver/plugin.cpp + remote/transport.cpp) and vla/x2's Vulkan server on a Windows-on-ARM
# Snapdragon X2 Elite laptop; and the server itself (Zig's clang for aarch64-windows-gnu). Outputs: build/vla/x2.
#   vla/x2/build_mac.sh [smolvla] [pi0] [pi0npu]
# pi0npu is pi0/pi0npu.mojo with its prefix on the laptop's NPU (-D PI0NPU_REMOTE), for vk_server_npu.exe: the server
# with npu/pi0_prefix.cpp inside, linked against ONNX Runtime's QNN NuGet package as npu/build_win.sh downloads it.
set -e
cd "$(dirname "$0")/../.."
MOJO_SRC=${MOJO_SRC:-../modular}
R=$(cd "$MOJO_SRC" && pwd)/bazel-bin
OUT=${OUT:-build/vla/x2}
ZIG=${ZIG:-build/vla/zig/zig}
ORT=${ORT_WIN_DIR:-build/npu/dl/ortwin}
VK="-I vla/x2/shim -I /opt/homebrew/opt/vulkan-headers/include"
mkdir -p $OUT
"$ZIG" cc -target aarch64-windows-gnu -O2 $VK -o $OUT/vk_server.exe vla/x2/vk_server_win.c vla/x2/executor_win.c -lws2_32
if [ ! -f "$ORT/runtimes/win-arm64/native/onnxruntime.lib" ]; then
  mkdir -p "$ORT"
  curl -sSL -o "$ORT/ortqnn.nupkg" https://www.nuget.org/api/v2/package/Microsoft.ML.OnnxRuntime.QNN/1.24.4
  (cd "$ORT" && unzip -q -o ortqnn.nupkg 'build/native/include/*' 'runtimes/win-arm64/native/onnxruntime.lib' && rm ortqnn.nupkg)
fi
"$ZIG" cc -target aarch64-windows-gnu -O2 $VK -DVK_SERVER_NPU -c -o $OUT/vk_server_npu.o vla/x2/vk_server_win.c
"$ZIG" cc -target aarch64-windows-gnu -O2 $VK -c -o $OUT/executor_win.o vla/x2/executor_win.c
"$ZIG" c++ -target aarch64-windows-gnu -O2 -std=c++17 -I "$ORT/build/native/include" -c -o $OUT/pi0_prefix.o \
    npu/pi0_prefix.cpp
"$ZIG" c++ -target aarch64-windows-gnu -O2 -std=c++17 -I "$ORT/build/native/include" -c -o $OUT/graph.o npu/graph.cpp
"$ZIG" c++ -target aarch64-windows-gnu -o $OUT/vk_server_npu.exe $OUT/vk_server_npu.o $OUT/executor_win.o \
    $OUT/pi0_prefix.o $OUT/graph.o "$ORT/runtimes/win-arm64/native/onnxruntime.lib" -lws2_32
clang++ -std=c++17 -O1 -shared -fPIC -I"$MOJO_SRC/SDK/include" -o $OUT/libM_driver_vulkan_remote.dylib \
    driver/plugin.cpp remote/transport.cpp
for name in ${@:-smolvla pi0}; do
  dir=$name
  defines=
  if [ $name = pi0npu ]; then dir=pi0; defines=-DPI0NPU_REMOTE=1; fi
  MODULAR_MAX_PACKAGE_ROOT=$PWD/.venv-mojo/lib/python3.12/site-packages/modular "$R/Mojo/tools/mojo/mojo" build \
      --emit object -O3 --target-accelerator adreno840 $defines -I build/android/packages -I $dir -I vla \
      -I vla/kernels -o $OUT/$name.o $dir/$name.mojo
  clang++ -o $OUT/$name $OUT/$name.o -L"$R/Mojo" -lKGENCompilerRTShared -Wl,-rpath,"$R/Mojo" \
      -Wl,-rpath,"$R/AsyncRT" -Wl,-rpath,"$R/Support"
done
