#!/bin/sh
# Builds turbovla as a macOS program whose kernels are adreno840 SPIR-V, for the remote driver plugin and vla/x2's
# Vulkan server on the Snapdragon X2 Elite laptop (both from vla/x2/build_mac.sh). Output: build/turbovla/x2/turbovla.
#   turbovla/build_mac.sh
set -e
cd "$(dirname "$0")/.."
MOJO_SRC=${MOJO_SRC:-../modular}
R=$(cd "$MOJO_SRC" && pwd)/bazel-bin
OUT=${OUT:-build/turbovla/x2}
mkdir -p $OUT
if [ ! -f build/vla/x2/libM_driver_vulkan_remote.dylib ]; then vla/x2/build_mac.sh; fi
MODULAR_MAX_PACKAGE_ROOT=$PWD/.venv-mojo/lib/python3.12/site-packages/modular "$R/Mojo/tools/mojo/mojo" build \
    --emit object -O3 --target-accelerator adreno840 -I build/android/packages -I turbovla -I turbovla/kernels \
    -I vla -I vla/kernels -o $OUT/turbovla.o turbovla/turbovla.mojo
clang++ -o $OUT/turbovla $OUT/turbovla.o -L"$R/Mojo" -lKGENCompilerRTShared -Wl,-rpath,"$R/Mojo" \
    -Wl,-rpath,"$R/AsyncRT" -Wl,-rpath,"$R/Support"
ls -la $OUT/turbovla
