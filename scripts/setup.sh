#!/usr/bin/env bash
# Host setup for mojo-adreno (macOS, Apple silicon). Requires Homebrew and uv (https://docs.astral.sh/uv/).
#   .venv-mojo   Mojo 1.2.0 + MAX 26.7.0 (MAX provides the `gpu` module)
#   llvm         llc with the SPIR-V backend (LLVM 22.1.2 used); spirv-tools for spirv-val
#   android-ndk  aarch64 Android clang + Vulkan headers (r30 used); android-platform-tools for adb
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
brew install llvm spirv-tools
brew install --cask android-ndk android-platform-tools
uv venv "$ROOT/.venv-mojo" --python 3.12
uv pip install --python "$ROOT/.venv-mojo/bin/python" mojo==1.2.0 max==26.7.0
"$ROOT/.venv-mojo/bin/mojo" --version
/opt/homebrew/opt/llvm/bin/llc --version | head -2
