#!/bin/sh
# π0's prefix on the Adreno 850 phone: GPU (pi0_lt) against the Hexagon NPU (npu/export_pi0.py --random graphs), from
# the Mac, on a freshly assigned phone (QDC wipes them). Stages everything, writes the random gemma.bin on the phone,
# compiles the six NPU parts (once: about 20-40 minutes), times the NPU prefix, then the GPU chunk.
#   ablas/pi0/compare.sh [stage|compile|npu|gpu|all]       (ADB_SERVER_SOCKET / ANDROID_SERIAL as usual)
set -e
cd "$(dirname "$0")/../.."
P=/data/local/tmp/pi0npu N=/data/local/tmp/npu G=/data/local/tmp/pi0
step=${1:-all}
if [ $step = stage ] || [ $step = all ]; then
  [ -d build/npu/pi0rand ] || PYTHONPATH=build/npu/pydeps python3 npu/export_pi0.py --random --out build/npu/pi0rand
  [ -x build/npu/pi0phone/pi0npu_tool ] || python3 npu/build.py pi0tool
  ablas/pi0/build.sh
  adb shell mkdir -p $N $P/ref $G
  adb push build/npu/pi0phone/. $N/
  for f in part0.onnx part1.onnx part2.onnx part3.onnx part4.onnx part5.onnx npu.txt recipe.txt manifest.txt; do
    adb push build/npu/pi0rand/$f $P/
  done
  adb push build/npu/pi0rand/ref/. $P/ref/
  adb push npu/run_pi0npu.sh $P/
  adb shell "cd $P && $N/pi0_f16 - recipe.txt gemma.bin"
  adb push ablas/pi0/build/pi0_lt $G/
fi
if [ $step = compile ] || [ $step = all ]; then
  adb shell "cd $P && sh run_pi0npu.sh compile"
fi
if [ $step = npu ] || [ $step = all ]; then
  adb shell "cd $P && sh run_pi0npu.sh run 5"
fi
if [ $step = gpu ] || [ $step = all ]; then
  adb shell "cd $G && ./pi0_lt -r 5"
fi
