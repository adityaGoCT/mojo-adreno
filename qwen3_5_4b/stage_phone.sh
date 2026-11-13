#!/bin/bash
# Stages a phone for qwen3_5_4b/ (Samsung RTL phones come back wiped): the phone downloads unsloth's Q4_0 GGUF from
# Hugging Face itself (2.58 GB, about a minute) and writes the weight file with qwen3_5_4b_convert (a few seconds); the
# Mac pushes only the program, the manifest, the recipe and the RoPE table. One plain command per adb shell (a lab
# bridge drops on &&, &, loops). A phone without internet (Qualcomm Device Cloud's QRD): stream the GGUF from the Mac,
#   curl -sSL <url> | adb exec-in "cat > /data/local/tmp/q35/gguf/Qwen3.5-4B-Q4_0.gguf"
#
#   python3 android/build.py qwen3_5_4b; build/vla/venv/bin/python qwen3_5_4b/export.py; qwen3_5_4b/stage_phone.sh
set -e
S=${ANDROID_SERIAL:-localhost:41661}; D=/data/local/tmp/q35
ROOT=$(cd "$(dirname "$0")/.." && pwd)
B=$ROOT/build/qwen3_5_4b
F=Qwen3.5-4B-Q4_0.gguf
URL=https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/e87f176479d0855a907a41277aca2f8ee7a09523/$F
a() { adb -s $S shell "$1"; }
a "mkdir -p $D/gguf $D/q4 $D/runs"
if ! a "ls $D/gguf/$F" >/dev/null 2>&1; then a "cd $D/gguf; curl -sSL -C - -o $F $URL"; fi
# Hugging Face's LFS id of the file: 298fcb5fe7a77ccc79745ae24751560c5ac56874caff4bb39b1f2055bd72b8bb
a "sha256sum $D/gguf/$F"
adb -s $S push $ROOT/build/android/qwen3_5_4b $D/ >/dev/null
adb -s $S push $B/rope.f32 $D/ >/dev/null
adb -s $S push $B/q4/manifest.txt $B/q4/recipe.txt $D/q4/ >/dev/null
a "cd $D/q4; $D/qwen3_5_4b/qwen3_5_4b_convert $D/gguf/$F recipe.txt qwen3_5_4b_q4.bin"
echo "q4: $(a "sha256sum $D/q4/qwen3_5_4b_q4.bin")"
