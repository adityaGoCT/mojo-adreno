#!/bin/sh
# Builds the Vulkan driver plugin for the phone, build/driver/libM_driver_vulkan.so, and its test,
# build/driver/test_plugin (driver/test_plugin.cpp), with the Android NDK.
#
#   driver/build.sh          ANDROID_NDK and MOJO_SRC (the modular checkout, for SDK/include) as needed
set -e
cd "$(dirname "$0")/.."
NDK=${ANDROID_NDK:-/opt/homebrew/share/android-ndk}
MOJO_SRC=${MOJO_SRC:-../modular}
BIN="$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin"
OUT=build/driver
mkdir -p $OUT
"$BIN/aarch64-linux-android34-clang" -O2 -Wall -fPIC -c -o $OUT/executor.o driver/executor.c
"$BIN/aarch64-linux-android34-clang++" -std=c++17 -O2 -Wall -Wextra -fPIC -shared -static-libstdc++ \
    -I"$MOJO_SRC/SDK/include" -o $OUT/libM_driver_vulkan.so driver/plugin.cpp driver/local.cpp $OUT/executor.o -ldl
"$BIN/aarch64-linux-android34-clang++" -std=c++17 -O2 -Wall -Wextra -static-libstdc++ -I"$MOJO_SRC/SDK/include" \
    -o $OUT/test_plugin driver/test_plugin.cpp -ldl
