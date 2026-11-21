#!/bin/bash
# run_override.sh <manifest> <candidate> <edits-subdir> [tag]: push edits/<subdir>/*.asm to the phone and run
# <candidate> on Turnip with IR3_SHADER_OVERRIDE_PATH pointing there (log kept in out/<tag>.log).
set -e
M=$1; K=$2; E=$3; T=${4:-$3}
D=/data/local/tmp/asm_mesa
S=${RTL_SERIAL:-localhost:59796}
adb -s $S shell mkdir -p $D/edits/$E
adb -s $S push edits/$E/*.asm $D/edits/$E/ > /dev/null
python3 run.py run $M turnip --only $K --tag $T --reps ${REPS:-3} --target-ms ${TARGET_MS:-100} \
  --env MESA_SHADER_CACHE_DISABLE=true --env IR3_SHADER_OVERRIDE_PATH=$D/edits/$E \
  --env IR3_SHADER_DEBUG=cs --env MESA_LOG_FILE=$D/out/$T.log
adb -s $S shell "grep -c 'Native code (overridden)' $D/out/$T.log; grep -i 'error\|fail' $D/out/$T.log | head -3"
