#!/system/bin/sh
# vkbench.sh: llama-bench (Vulkan builds) under the thermal gate of ablas/llama3b/bench.sh.
#   vkbench.sh <dir with llama-bench> model.gguf "pp512 pp1024 pp2048 tg32" [extra llama-bench args]
K=/sys/class/kgsl/kgsl-3d0
Z=""
for z in /sys/class/thermal/thermal_zone*; do [ "$(cat $z/type)" = gpuss-0 ] && Z=$z/temp; done
d=$1; shift; m=$1; shift; tests=$1; shift
for t in $tests; do
  n=0
  while [ "$(cat $K/thermal_pwrlevel)" != 0 ] || [ "$(cat $Z)" -gt 45000 ]; do
    sleep 2; n=$((n + 2)); [ $n -ge 180 ] && break
  done
  t0=$(cat $Z)
  case $t in
    pp*) a="-p ${t#pp} -n 0";;
    tg*) a="-p 0 -n ${t#tg}";;
  esac
  out=$(./$d/llama-bench -m $m $a -r 3 -ngl 99 "$@" 2>&1 | grep -E " $t |error|failed")
  echo "$d $out   [waited ${n}s, start ${t0}mC]"
done
