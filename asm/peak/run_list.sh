#!/bin/bash
# run_list.sh <manifest> <variants> <groups> [env...]: run each manifest line in its own process on the phone
# (a crashing pipeline only loses that line) and print TFLOP/s from the GPU timestamps.
set -u
M=$1; V=$2; G=$3; shift 3
DEV=/data/local/tmp/asm_peak
adb shell "cd $DEV && while read l; do echo \"\$l\" > one.txt; $* ./vk_gemm_bench --manifest=one.txt --target-ms=100 --reps=3 2>/dev/null || echo \"CRASH \${l%% *} rc=\$?\"; done < $M" > /tmp/run_list.out 2>&1
python3 - "$V" "$G" <<'PY'
import json, sys
fl = dict(l.split() for l in open(sys.argv[1])); G = int(sys.argv[2])
for line in open("/tmp/run_list.out"):
    line = line.strip()
    if line.startswith("{"):
        j = json.loads(line)
        if "us_min" in j: print(f'{j["name"]:28s} {int(fl[j["name"]])*G/(j["us_min"]*1e-6)/1e12:7.2f} TFLOP/s  {j["us_min"]:9.0f} us')
        else: print(f'{j["name"]:28s} FAILED {j.get("error")}')
    elif line: print(line)
PY
