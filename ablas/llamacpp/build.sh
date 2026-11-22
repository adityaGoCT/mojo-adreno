#!/bin/sh
# Builds llama.cpp's Vulkan backend for Android arm64 twice: stock, and with AdrenoBLAS (adrenoblas-ggml-vulkan.patch).
#   LLAMA=~/runix/llama.cpp ./build.sh          (llama.cpp at 1fdda89, patch applied: git apply adrenoblas-ggml-vulkan.patch)
# Needs: Android NDK (NDK), Vulkan headers with spirv/unified1 next to vulkan/ (VK_INC; the NDK's are too old for
# VK_KHR_cooperative_matrix), SPIRV-Headers' CMake package (SPIRV_HEADERS_DIR), glslc on the PATH, Ninja.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
LLAMA=${LLAMA:-$HOME/runix/llama.cpp}
NDK=${NDK:-/opt/homebrew/share/android-ndk}
VK_INC=${VK_INC:-$HOME/runix/llama.cpp-deps/vulkan-headers/include}
SPIRV_HEADERS_DIR=${SPIRV_HEADERS_DIR:-/usr/local/lib/cmake/vulkan/SPIRV-Headers}
STRIP=$NDK/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-strip
cd "$LLAMA"
for v in stock ablas; do
  b=build-android-vulkan$([ $v = ablas ] && echo -ablas)
  extra=$([ $v = ablas ] && echo "-DGGML_VULKAN_ADRENOBLAS=$HERE/..")
  cmake -S . -B $b -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-33 \
    -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DGGML_VULKAN=ON -DGGML_NATIVE=OFF \
    -DGGML_CPU_ARM_ARCH=armv8.7-a+fp16 -DGGML_OPENMP=OFF -DGGML_LLAMAFILE=OFF -DLLAMA_OPENSSL=OFF \
    -DLLAMA_USE_PREBUILT_UI=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
    -DVulkan_INCLUDE_DIR=$VK_INC -DCMAKE_CXX_FLAGS="-I$VK_INC" -DCMAKE_C_FLAGS="-I$VK_INC" \
    -DSPIRV-Headers_DIR=$SPIRV_HEADERS_DIR -DGGML_VULKAN_SPIRV_INCLUDE_DIR=$VK_INC $extra
  ninja -C $b llama-bench llama-completion llama-perplexity
  mkdir -p $b/bin-stripped
  for t in llama-bench llama-completion llama-perplexity; do $STRIP -o $b/bin-stripped/$t $b/bin/$t; done
  echo "built $LLAMA/$b/bin-stripped"
done
