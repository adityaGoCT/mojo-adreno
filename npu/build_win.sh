#!/bin/sh
# π0's NPU prefix tool (pi0_prefix.cpp, -DNPU_TOOL) and the fp16 converter (pi0_f16.c) for Windows on ARM: a Snapdragon
# X2 Elite laptop's Hexagon NPU (V81, as the phones'). Zig's clang for aarch64-windows-gnu, against ONNX Runtime's QNN
# NuGet package (Microsoft.ML.OnnxRuntime.QNN 1.24.4: its headers and onnxruntime.lib here; the laptop unpacks the same
# package for the DLLs, QnnHtp.dll, QnnHtpPrepare.dll, QnnHtpV81Stub.dll and libQnnHtpV81Skel.so). Outputs: build/npu/pi0win.
#   npu/build_win.sh
set -e
cd "$(dirname "$0")/.."
ZIG=${ZIG:-build/vla/zig/zig}
ORT=${ORT_WIN_DIR:-build/npu/dl/ortwin}
OUT=build/npu/pi0win
if [ ! -f "$ORT/runtimes/win-arm64/native/onnxruntime.lib" ]; then
  mkdir -p "$ORT"
  curl -sSL -o "$ORT/ortqnn.nupkg" https://www.nuget.org/api/v2/package/Microsoft.ML.OnnxRuntime.QNN/1.24.4
  (cd "$ORT" && unzip -q -o ortqnn.nupkg 'build/native/include/*' 'runtimes/win-arm64/native/onnxruntime.lib' && rm ortqnn.nupkg)
fi
mkdir -p $OUT
"$ZIG" c++ -target aarch64-windows-gnu -O2 -std=c++17 -DNPU_TOOL -I "$ORT/build/native/include" \
    -o $OUT/pi0npu_tool.exe npu/pi0_prefix.cpp "$ORT/runtimes/win-arm64/native/onnxruntime.lib"
"$ZIG" cc -target aarch64-windows-gnu -O2 -o $OUT/pi0_f16.exe npu/pi0_f16.c
# graph_tool: any static ONNX graph on the HTP (npu/graph.cpp): compile a context, time it, dump its outputs
"$ZIG" c++ -target aarch64-windows-gnu -O2 -std=c++17 -DNPU_TOOL -I "$ORT/build/native/include" \
    -o $OUT/graph_tool.exe npu/graph.cpp "$ORT/runtimes/win-arm64/native/onnxruntime.lib"
ls -la $OUT
