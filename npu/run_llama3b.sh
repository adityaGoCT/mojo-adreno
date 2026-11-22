#!/system/bin/sh
# Llama 3.2 3B prefill on the HTP (export_llama3b.py's graphs), on the phone: compile each graph in its own process
# (once), then run the 7 parts and the head back to back with graph_tool chain.
#   run_llama3b.sh compile | run <runs> [outdir]
# The graphs (l3b_*.onnx) and the F16 GGUF they read sit in /data/local/tmp/lcpp; graph_tool and QNN's libraries in
# /data/local/tmp/npu.
cd /data/local/tmp/lcpp
export LD_LIBRARY_PATH=/data/local/tmp/npu:/system/lib64:/vendor/lib64 ADSP_LIBRARY_PATH=/data/local/tmp/npu
T=/data/local/tmp/npu/graph_tool
if [ "$1" = compile ]; then
  for g in p0 p1 p2 p3 p4 p5 p6 head; do
    [ -f l3b_${g}_ctx.onnx ] && continue
    $T compile l3b_$g.onnx l3b_${g}_ctx.onnx 2>&1 | grep -E "compiled|rror|failed"
  done
else
  out=${3:-n3b/out}
  mkdir -p $out
  $T chain ${2:-5} l3b_p0_ctx.onnx n3b/x.bin + l3b_p1_ctx.onnx @0:0 + l3b_p2_ctx.onnx @1:0 + l3b_p3_ctx.onnx @2:0 \
    + l3b_p4_ctx.onnx @3:0 + l3b_p5_ctx.onnx @4:0 + l3b_p6_ctx.onnx @5:0 + l3b_head_ctx.onnx @6:0 n3b/sel.bin -o $out
fi
