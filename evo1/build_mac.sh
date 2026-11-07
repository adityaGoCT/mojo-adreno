#!/bin/sh
# Builds evo1 as a macOS program whose kernels are adreno840 SPIR-V, for the remote driver plugin and vla/x2's
# Vulkan server on the Snapdragon X2 Elite laptop (both from vla/x2/build_mac.sh). Output: build/evo1/x2/evo1.
#   evo1/build_mac.sh
set -e
cd "$(dirname "$0")/.."
MOJO_SRC=${MOJO_SRC:-../modular}
R=$(cd "$MOJO_SRC" && pwd)/bazel-bin
OUT=${OUT:-build/evo1/x2}
mkdir -p $OUT
if [ ! -f build/vla/x2/libM_driver_vulkan_remote.dylib ]; then vla/x2/build_mac.sh; fi
MODULAR_MAX_PACKAGE_ROOT=$PWD/.venv-mojo/lib/python3.12/site-packages/modular "$R/Mojo/tools/mojo/mojo" build \
    --emit object -O3 --target-accelerator adreno840 -I build/android/packages -I evo1 -I evo1/kernels -I vla_adapter/kernels \
    -I vla -I vla/kernels -o $OUT/evo1.o evo1/evo1.mojo
clang++ -o $OUT/evo1 $OUT/evo1.o -L"$R/Mojo" -lKGENCompilerRTShared -Wl,-rpath,"$R/Mojo" \
    -Wl,-rpath,"$R/AsyncRT" -Wl,-rpath,"$R/Support"
ls -la $OUT/evo1
