#!/bin/bash
# Compiles coopmat/matmul_coopmat_gpu.mojo for the adreno840 target with a source-built Mojo (the
# adreno-spirv-target branch of the modular fork) and validates each kernel's SPIR-V for Vulkan 1.3.
#   MOJO_SRC=~/runix/modular coopmat/check.sh
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
MOJO_SRC=${MOJO_SRC:-$HERE/../modular}
BIN=$MOJO_SRC/bazel-bin
OUT=$HERE/build/coopmat
rm -rf "$OUT" && mkdir -p "$OUT"
# the MAX gate only checks that a MAX install exists; the compile never loads it
MODULAR_MAX_PACKAGE_ROOT=$HERE/.venv-mojo/lib/python3.12/site-packages/modular \
  "$BIN/Mojo/tools/mojo/mojo" build --emit asm -O3 --target-accelerator adreno840 \
  -I "$BIN/Mojo/stdlib/std" -I "$BIN/max/mojo/max" -o "$OUT/host.s" "$HERE/coopmat/matmul_coopmat_gpu.mojo"
for spv in "$OUT"/*.spv; do
  spirv-val --target-env vulkan1.3 "$spv"
  echo "$(basename "$spv"): valid for Vulkan 1.3"
  spirv-dis "$spv" | grep -oE "Op(Capability CooperativeMatrixKHR|CooperativeMatrix[A-Za-z]+KHR|FConvert)" | sort | uniq -c
done
