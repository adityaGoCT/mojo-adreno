#!/bin/sh
# Builds vla_jepa as a macOS program whose kernels are adreno840 SPIR-V, for the remote driver plugin and vla/x2's
# Vulkan server on the Snapdragon X2 Elite laptop (both from vla/x2/build_mac.sh). Output: build/vla_jepa/x2/vla_jepa.
#   vla_jepa/build_mac.sh
set -e
cd "$(dirname "$0")/.."
MOJO_SRC=${MOJO_SRC:-../modular}
R=$(cd "$MOJO_SRC" && pwd)/bazel-bin
OUT=${OUT:-build/vla_jepa/x2}
mkdir -p $OUT
if [ ! -f build/vla/x2/libM_driver_vulkan_remote.dylib ]; then vla/x2/build_mac.sh; fi
MODULAR_MAX_PACKAGE_ROOT=$PWD/.venv-mojo/lib/python3.12/site-packages/modular "$R/Mojo/tools/mojo/mojo" build \
    --emit object -O3 --target-accelerator adreno840 -I build/android/packages -I vla_jepa -I vla_jepa/kernels -I vla_adapter/kernels -I octo/kernels -I turbovla/kernels \
    -I vla -I vla/kernels -o $OUT/vla_jepa.o vla_jepa/vla_jepa.mojo
clang++ -o $OUT/vla_jepa $OUT/vla_jepa.o -L"$R/Mojo" -lKGENCompilerRTShared -Wl,-rpath,"$R/Mojo" \
    -Wl,-rpath,"$R/AsyncRT" -Wl,-rpath,"$R/Support"
ls -la $OUT/vla_jepa
