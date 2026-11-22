#!/bin/sh
# Build the repro harness and the SPIR-V. Needs glslc (shaderc) and the Android NDK; Vulkan headers 1.3.250+.
set -e
cd "$(dirname "$0")"
NDK_CLANG=${NDK_CLANG:-/opt/homebrew/share/android-ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android33-clang}
VK_INC=${VK_INC:-/usr/local/include}
rm -f shaders/*.spv shaders/*.spvasm
for f in shaders/*.comp; do
  glslc --target-env=vulkan1.3 -O "$f" -o "${f%.comp}.spv"
  spirv-dis "${f%.comp}.spv" -o "${f%.comp}.spvasm" 2>/dev/null || true
done
$NDK_CLANG -O2 -Wall -I"$VK_INC" -o repro repro.c -ldl -lm
echo "built repro and $(ls shaders/*.spv | wc -l) shaders"
