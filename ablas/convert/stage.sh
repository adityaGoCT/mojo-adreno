#!/bin/sh
# stage.sh: puts plan_run, a converted model and the prompt on the phone. Safe to re-run after a dropped or wiped
# session: a large file already there with the right size is skipped.
#   ./stage.sh OUTDIR [NAME]       -> /data/local/tmp/ltc/{plan_run,llama_lt,tokens.bin,bench.sh} + NAME/{model.plan,weights.bin}
#   LLAMA_LT=q4|f16 ./stage.sh ... also ../llama3b/export.py's weights for llama_lt (the A/B), -> ltc/w/
# ADB_SERVER_SOCKET defaults to the QDC tunnel (tcp:[::1]:5037); ANDROID_SERIAL picks the phone.
set -e
cd "$(dirname "$0")"
OUT=$1
NAME=${2:-$(basename "$OUT")}
export ADB_SERVER_SOCKET=${ADB_SERVER_SOCKET:-tcp:[::1]:5037}
D=/data/local/tmp/ltc
size() { stat -f %z "$1" 2>/dev/null || stat -c %s "$1"; }
push() {  # local remote [big]: big files are skipped when the phone has the same size
  if [ -n "$3" ] && [ "$(size "$1")" = "$(adb shell "stat -c %s $2 2>/dev/null" | tr -d '\r')" ]; then
    echo "have $2"
  else
    adb push "$1" "$2"
  fi
}
adb shell mkdir -p $D/w
[ -n "$OUT" ] && adb shell mkdir -p $D/$NAME
push build/plan_run $D/plan_run
push build/llama_lt $D/llama_lt
push bench.sh $D/bench.sh
push ../llama3b/ref/tokens.bin $D/tokens.bin
adb shell chmod 755 $D/plan_run $D/llama_lt
if [ -n "$OUT" ]; then
  push "$OUT/model.plan" $D/$NAME/model.plan
  push "$OUT/weights.bin" $D/$NAME/weights.bin big
fi
if [ -n "$LLAMA_LT" ]; then
  push ../llama3b/weights/llama3b_$LLAMA_LT.idx $D/w/llama3b_$LLAMA_LT.idx
  push ../llama3b/weights/llama3b_$LLAMA_LT.bin $D/w/llama3b_$LLAMA_LT.bin big
fi
echo "staged in $D"
