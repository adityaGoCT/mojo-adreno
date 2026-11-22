#!/bin/sh
# Builds plan_run for Android (Adreno 850) and, for dry runs (-d) on this host, build/plan_run_host.
# Needs the Android NDK ($NDK_CLANG, default below) and Vulkan headers ($VK_INC). The AdrenoBLASLt kernels
# (../lt/ablaslt_kernels.h) come from ../lt/build.sh.
set -e
cd "$(dirname "$0")"
NDK_CLANG=${NDK_CLANG:-/opt/homebrew/share/android-ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android33-clang}
VK_INC=${VK_INC:-/usr/local/include}
[ -f ../lt/ablaslt_kernels.h ] || (cd ../lt && python3 gen_kernels.py)
mkdir -p build
$NDK_CLANG -O2 -Wall -Wno-unused-function -I$VK_INC -o build/plan_run plan_run.c ../lt/ablasLt.c ../ablas.c -ldl -lm
cc -O2 -Wall -Wno-unused-function -I$VK_INC -o build/plan_run_host plan_run.c ../lt/ablasLt.c ../ablas.c -lm

# llama_lt from the same library sources, for the A/B on the phone (stage.sh, bench.sh)
$NDK_CLANG -O2 -Wall -Wno-unused-function -I$VK_INC -o build/llama_lt ../lt/llama_lt.c ../lt/ablasLt.c ../ablas.c -ldl -lm
echo "built build/plan_run, build/llama_lt (Android) and build/plan_run_host (dry runs)"
