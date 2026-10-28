#!/bin/sh
# Builds vk_server and the driver plugin, starts vk_server on the phone and forwards its port.
# The server runs as long as this script (adb keeps the shell open while it runs): leave it
# running, and stop it with Ctrl-C.
#
#   remote/start_server.sh [port]       then, in another terminal, run MAX with
#   MODULAR_DRIVER_PLUGINS="cpu@<modular>/bazel-bin/Target/CPUPlugin.so;vulkan@$PWD/build/remote/libM_driver_vulkan_remote.dylib"
set -e
cd "$(dirname "$0")/.."
PORT=${1:-7788}
NDK=${ANDROID_NDK:-/opt/homebrew/share/android-ndk}
MOJO_SRC=${MOJO_SRC:-../modular}
DEV=/data/local/tmp/mojo/remote
mkdir -p build/remote
clang++ -std=c++17 -O1 -shared -fPIC -I"$MOJO_SRC/SDK/include" -o build/remote/libM_driver_vulkan_remote.dylib \
    remote/vulkan_remote_plugin.cpp
"$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang" -O2 -o build/remote/vk_server \
    remote/vk_server.c -ldl
adb shell pkill -x vk_server || true   # -x: the server, not this shell, whose command names it
adb shell mkdir -p $DEV
adb push build/remote/vk_server $DEV/ > /dev/null
adb forward tcp:$PORT tcp:$PORT
exec adb shell "cd $DEV && VK_SERVER_PROFILE=${VK_SERVER_PROFILE:-} LD_LIBRARY_PATH=/data/local/tmp/turnip exec ./vk_server $PORT"
