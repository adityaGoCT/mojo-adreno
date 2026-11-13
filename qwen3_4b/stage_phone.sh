#!/bin/bash
# Stages a phone for qwen3_4b/ (Samsung RTL phones come back wiped): the phone downloads Qwen/Qwen3-4B's bf16 shards from
# Hugging Face itself and writes the int4 weight file with qwen3_4b_convert (about 15 s); the Mac pushes only the program,
# the manifest, the recipe and the RoPE table. One plain command per adb shell (a lab bridge drops on &&, &, loops).
# A phone without internet (Qualcomm Device Cloud's QRD): stream each shard from the Mac instead,
#   curl -sSL <url> | adb exec-in "cat > /data/local/tmp/q4b/hf/<shard>"
#
#   python3 android/build.py qwen3_4b; build/vla/venv/bin/python qwen3_4b/export.py; qwen3_4b/stage_phone.sh
set -e
S=${ANDROID_SERIAL:-localhost:41661}; D=/data/local/tmp/q4b
ROOT=$(cd "$(dirname "$0")/.." && pwd)
B=$ROOT/build/qwen3_4b
HF=https://huggingface.co/Qwen/Qwen3-4B/resolve/1cfa9a7208912126459214e8b04321603b3df60c
a() { adb -s $S shell "$1"; }
a "mkdir -p $D/hf $D/q4 $D/runs"
for i in 1 2 3; do
  f=model-0000$i-of-00003.safetensors
  if ! a "ls $D/hf/$f" >/dev/null 2>&1; then a "cd $D/hf; curl -sSL -C - -o $f $HF/$f"; fi
done
# the shards' SHA-256 (Hugging Face's LFS ids): 328a91d3..., 6cd087b3..., e4bf4369...
for i in 1 2 3; do a "sha256sum $D/hf/model-0000$i-of-00003.safetensors"; done
adb -s $S push $ROOT/build/android/qwen3_4b $D/ >/dev/null
adb -s $S push $B/rope.f32 $D/ >/dev/null
adb -s $S push $B/q4/manifest.txt $B/q4/recipe.txt $D/q4/ >/dev/null
a "cd $D/q4; $D/qwen3_4b/qwen3_4b_convert recipe.txt qwen3_4b_q4.bin $D/hf/model-00001-of-00003.safetensors $D/hf/model-00002-of-00003.safetensors $D/hf/model-00003-of-00003.safetensors"
echo "q4: $(a "sha256sum $D/q4/qwen3_4b_q4.bin")"
