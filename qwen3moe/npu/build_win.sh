#!/bin/sh
# npu_run.exe (and convert.exe) for the X2 Elite laptop: Zig's clang for aarch64-windows-gnu against ONNX Runtime's QNN
# NuGet package (Microsoft.ML.OnnxRuntime.QNN 1.24.4: its headers and onnxruntime.lib; the laptop unpacks the same
# package's runtimes/win-arm64/native as npu\bin, next to npu_run.exe). Output: build/qwen3moe/npu.
set -e
cd "$(dirname "$0")/../.."
ZIG=${ZIG:-build/vla/zig/zig}
ORT=${ORT_WIN_DIR:-build/npu/dl/ortwin}
OUT=build/qwen3moe/npu
if [ ! -f "$ORT/runtimes/win-arm64/native/onnxruntime.lib" ]; then
  mkdir -p "$ORT"
  curl -sSL -o "$ORT/ortqnn.nupkg" https://www.nuget.org/api/v2/package/Microsoft.ML.OnnxRuntime.QNN/1.24.4
  (cd "$ORT" && unzip -q -o ortqnn.nupkg 'build/native/include/*' 'runtimes/win-arm64/native/onnxruntime.lib' && rm ortqnn.nupkg)
fi
mkdir -p $OUT
"$ZIG" c++ -target aarch64-windows-gnu -O2 -std=c++17 -I "$ORT/build/native/include" -o $OUT/npu_run.exe \
    qwen3moe/npu/npu_run.cpp "$ORT/runtimes/win-arm64/native/onnxruntime.lib"
"$ZIG" cc -target aarch64-windows-gnu -O2 -o $OUT/convert.exe qwen3moe/convert.c
