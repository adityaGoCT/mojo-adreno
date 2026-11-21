#!/bin/bash
# diag.sh <kernel> <hash> <tag> <regex>: strip matching instructions from the main loop of the dumped
# Turnip asm, run the kernel through IR3_SHADER_OVERRIDE_PATH (timing only; results are wrong by design).
set -e
K=$1; H=$2; T=$3; RX=$4
D=/data/local/tmp/asm_mesa
mkdir -p edits/$T
python3 asm_edit.py strip asm_dump/$H.asm edits/$T/$H.asm "$RX"
adb -s ${RTL_SERIAL:-localhost:59796} shell mkdir -p $D/edits/$T
adb -s ${RTL_SERIAL:-localhost:59796} push edits/$T/$H.asm $D/edits/$T/ > /dev/null
python3 run.py run manifest_gemm.txt turnip --only $K --tag $T --env MESA_SHADER_CACHE_DISABLE=true --env IR3_SHADER_OVERRIDE_PATH=$D/edits/$T --reps 3 --target-ms 100
