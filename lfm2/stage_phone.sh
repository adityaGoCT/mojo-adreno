#!/bin/bash
# Re-stages a wiped lab phone for lfm2/ (Samsung RTL phones come back empty): the phone downloads the QAD GGUF (and the
# DSpark drafter) from Hugging Face itself and writes the weight files with lfm2_convert; the Mac pushes only programs,
# manifests, recipes, graphs. One plain command per adb shell (a lab bridge drops on &&, &, loops).
#   lfm2/stage_phone.sh [gpu] [npu] [dspark]     (default: gpu)
set -e
S=${ANDROID_SERIAL:-localhost:41661}; D=/data/local/tmp/lfm2
ROOT=$(cd "$(dirname "$0")/.." && pwd)
B=$ROOT/build/lfm2
GGUF=https://huggingface.co/LiquidAI/LFM2.5-2.6B-GGUF/resolve/e7caca5d835a3901a8e0d63e94009429bafafdfc/LFM2.5-2.6B-QAD-Q4_0.gguf
DS=https://huggingface.co/LiquidAI/LFM2.5-2.6B-DSpark/resolve/458cedab07d0f7b2b05700c77e1aa463d43d6f04/model.safetensors
WANT="${*:-gpu}"
a() { adb -s $S shell "$1"; }
a "mkdir -p $D/q4 $D/f16 $D/npu $D/qnn $D/runs $D/dspark"
if ! a "ls $D/qad_q4_0.gguf" >/dev/null 2>&1; then
  a "cd $D; curl -sSL -o qad_q4_0.gguf $GGUF"
fi
echo "gguf: $(a "sha256sum $D/qad_q4_0.gguf")"
adb -s $S push $ROOT/build/android/lfm2 $D/ >/dev/null
adb -s $S push $B/rope.f32 $D/ >/dev/null
for s in q4 f16 npu; do adb -s $S push $B/$s/manifest.txt $B/$s/recipe.txt $D/$s/ >/dev/null; done
a "cd $D/q4; $D/lfm2/lfm2_convert $D/qad_q4_0.gguf recipe.txt lfm2_q4.bin"
for w in $WANT; do
  case $w in
    f16) a "cd $D/f16; $D/lfm2/lfm2_convert $D/qad_q4_0.gguf recipe.txt lfm2_f16.bin" ;;
    npu)
      a "cd $D/npu; $D/lfm2/lfm2_convert $D/qad_q4_0.gguf recipe.txt npu_w8.bin"
      P=$ROOT/build/npu/phone
      adb -s $S push $P/graph_tool $P/lfm2_npu $P/lfm2_hybrid $P/libonnxruntime.so $P/libQnnHtp.so $P/libQnnHtpPrepare.so \
        $P/libQnnHtpV81Stub.so $P/libQnnHtpV81Skel.so $P/libQnnSystem.so $P/libKGENCompilerRTShared.so \
        $P/libAsyncRTRuntimeGlobals.so $P/libMSupportGlobals.so $P/libM_driver_vulkan.so $P/libc++_shared.so $D/qnn/ >/dev/null
      adb -s $S push $B/npu/*.onnx $D/npu/ >/dev/null
      $ROOT/lfm2/compile_npu.sh p0 p1 p2 p3 p4 head d0 d1 d2 d3 d4 ;;
    dspark)
      if ! a "ls $D/dspark/model.safetensors" >/dev/null 2>&1; then a "cd $D/dspark; curl -sSL -o model.safetensors $DS"; fi
      adb -s $S push $B/dspark/manifest.txt $D/dspark/ >/dev/null  # dspark_ref.py --export
      echo "dspark: $(a "sha256sum $D/dspark/model.safetensors")" ;;
  esac
done
echo "q4: $(a "sha256sum $D/q4/lfm2_q4.bin")"
