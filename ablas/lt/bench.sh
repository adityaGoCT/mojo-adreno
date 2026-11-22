#!/system/bin/sh
# bench.sh: llama_lt (and, for comparison, ../llama3b's llama3b) under ../llama3b/bench.sh's thermal gate.
# Before each run: wait until the thermal cap is off and gpuss-0 <= 45 C (max 180 s).
#   bench.sh "lt q4 512" "old q4 512" "lt f16 2048" ...     (run from the directory holding both binaries)
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
  if [ "$1" = lt ]; then out=$(./llama_lt -w w/llama3b_$2 -t tokens.bin -n $3 -r 3 2>&1 | grep RESULT)
  else out=$(./llama3b -w w/llama3b_$2 -t tokens.bin -m $3 -r 3 2>&1 | grep RESULT); fi
  echo "$1: $out   [waited ${n}s, start ${t0}mC]"
done
