#!/system/bin/sh
# lcpp_bench.sh: llama.cpp OpenCL llama-bench prefill under the same thermal gate as bench.sh.
#   lcpp_bench.sh model.gguf "512 1024 2048" [extra llama-bench args]
K=/sys/class/kgsl/kgsl-3d0
Z=""
for z in /sys/class/thermal/thermal_zone*; do [ "$(cat $z/type)" = gpuss-0 ] && Z=$z/temp; done
m=$1; shift; ps=$1; shift
for p in $ps; do
  n=0
  while [ "$(cat $K/thermal_pwrlevel)" != 0 ] || [ "$(cat $Z)" -gt 45000 ]; do
    sleep 2; n=$((n + 2)); [ $n -ge 180 ] && break
  done
  t0=$(cat $Z)
  out=$(LD_LIBRARY_PATH=/vendor/lib64 ./llama-bench -m $m -p $p -n 0 -r 3 -ngl 99 "$@" 2>&1 | grep "pp$p")
  echo "$out   [waited ${n}s, start ${t0}mC]"
done
