#!/system/bin/sh
# bench.sh: plan_run against llama_lt (../lt/llama_lt.c) under ../llama3b/bench.sh's thermal gate: before each run,
# wait until the thermal cap is off and gpuss-0 <= 45 C (max 180 s). Run from /data/local/tmp/ltc (stage.sh).
#   sh bench.sh "plan l3b_q4 512" "lt q4 512" "plan l3b_f16 512" "lt f16 512" ...
K=/sys/class/kgsl/kgsl-3d0
Z=""
for z in /sys/class/thermal/thermal_zone*; do [ "$(cat $z/type)" = gpuss-0 ] && Z=$z/temp; done
for s in "$@"; do
  set -- $s
  n=0
  while [ "$(cat $K/thermal_pwrlevel)" != 0 ] || [ "$(cat $Z)" -gt 45000 ]; do
    sleep 2; n=$((n + 2)); [ $n -ge 180 ] && break
  done
  t0=$(cat $Z)
  if [ "$1" = plan ]; then out=$(./plan_run -p $2/model.plan -t tokens.bin -n $3 -r 3 2>&1 | grep RESULT)
  else out=$(./llama_lt -w w/llama3b_$2 -t tokens.bin -n $3 -r 3 2>&1 | grep RESULT); fi
  echo "$1 $2 $3: $out   [waited ${n}s, start ${t0}mC]"
done
