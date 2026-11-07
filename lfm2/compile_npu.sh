#!/bin/bash
# Compiles export_npu.py's graphs for the phone's HTP, a graph a process (graph_tool compile; a lab phone takes one plain
# command per adb shell): lfm2/compile_npu.sh p0 p1 p2 p3 p4 head d0 d1 d2 d3 d4
S=${ANDROID_SERIAL:-localhost:41661}; D=/data/local/tmp/lfm2; N=${NPU_DIR:-$D/npu}  # NPU_DIR: another graph directory
for g in "$@"; do
  adb -s $S shell "rm -f $N/${g}_ctx.onnx $N/${g}_ctx_qnn.bin"
  adb -s $S shell "cd $N; LD_LIBRARY_PATH=$D/qnn:/system/lib64:/vendor/lib64 ADSP_LIBRARY_PATH=$D/qnn $D/qnn/graph_tool compile $g.onnx ${g}_ctx.onnx > compile_$g.log 2>&1; echo exit \$? >> compile_$g.log"
  echo "$g: $(adb -s $S shell "tail -2 $N/compile_$g.log" | tr '\n' ' ')"
done
