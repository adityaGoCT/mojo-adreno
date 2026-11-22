#!/system/bin/sh
# π0's Gemma prefix on the HTP, on the phone (npu/export_pi0.py's graphs in /data/local/tmp/pi0npu, pi0npu_tool and
# QNN's libraries in /data/local/tmp/npu): compile each part in its own process (once), or time the prefix.
#   run_pi0npu.sh compile | run <runs>
cd /data/local/tmp/pi0npu
export LD_LIBRARY_PATH=/data/local/tmp/npu:/system/lib64:/vendor/lib64 ADSP_LIBRARY_PATH=/data/local/tmp/npu
T=/data/local/tmp/npu/pi0npu_tool
if [ "$1" = compile ]; then
  for i in 0 1 2 3 4 5; do
    [ -f part${i}_ctx.onnx ] && continue
    $T compile . $i 2>&1 | grep -E "compiled|rror|fail"
  done
else
  $T . ref ${2:-5} -
fi
