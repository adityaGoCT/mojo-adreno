#!/bin/sh
# Builds AdrenoBLASLt's kernels (ablaslt_kernels.h) and, for Android (Adreno 850), lt_test and the llama_lt runner.
# Needs glslc and the Android NDK ($NDK_CLANG, default below); the AdrenoBLAS catalogue (../build_lib.py) is reused.
set -e
cd "$(dirname "$0")"
NDK_CLANG=${NDK_CLANG:-/opt/homebrew/share/android-ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android33-clang}
VK_INC=${VK_INC:-/usr/local/include}
python3 gen_kernels.py
mkdir -p build
$NDK_CLANG -O2 -Wall -I$VK_INC -o build/lt_test lt_test.c ablasLt.c ../ablas.c -ldl -lm
$NDK_CLANG -O2 -Wall -I$VK_INC -o build/llama_lt llama_lt.c ablasLt.c ../ablas.c -ldl -lm
echo "built build/lt_test and build/llama_lt"
