#!/system/bin/sh
# bench.sh: the Llama 3.2 3B prefill benchmark on the QDC Adreno 850 (root shell), one configuration at a time.
# Before each run: wait until the thermal cap is off and gpuss-0 <= 45 C (max 180 s); sample the GPU clock during
# the run and report the share of samples at the top clock.  bench.sh "q4 512" "f16 2048" ...
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
  (while true; do cat $K/gpuclk; sleep 0.1; done) > clk_one.txt &
  sp=$!
  out=$(./llama3b -w w/llama3b_$1 -t tokens.bin -m $2 -r 3 $3 2>&1 | grep RESULT)
  kill $sp
  top=$(grep -c "^1450000000" clk_one.txt)
  all=$(wc -l < clk_one.txt)
  echo "$out   [waited ${n}s, start ${t0}mC, ${top}/${all} clock samples at 1.45 GHz]"
done
