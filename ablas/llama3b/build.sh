#!/bin/sh
# Build the Llama 3.2 3B benchmark: kernels (GLSL -> SPIR-V, generated attention and fused qkv kernels), the
# AdrenoBLAS catalogue, and the Android binaries. Needs glslc and the Android NDK ($NDK_CLANG, default below).
set -e
cd "$(dirname "$0")"
NDK_CLANG=${NDK_CLANG:-/opt/homebrew/share/android-ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android33-clang}
VK_INC=${VK_INC:-/usr/local/include}
(cd .. && python3 build_lib.py > /dev/null)
for k in addsq normtile normtile2 rmsnorm rope rope2 vt softmax silu silu2; do
  glslc --target-env=vulkan1.3 -O kernels/$k.comp -o kernels/$k.spv
done
python3 gen_attn.py && python3 gen_attn.py fa && python3 gen_attn.py fa2 && python3 gen_attn.py fa3
python3 gen_fused.py > /dev/null
$NDK_CLANG -O2 -I$VK_INC -o llama3b llama3b.c ../ablas.c -ldl -lm
$NDK_CLANG -O2 -I$VK_INC -o vkrun vkrun.c -ldl -lm
echo "built llama3b, vkrun and kernels/*.spv"
