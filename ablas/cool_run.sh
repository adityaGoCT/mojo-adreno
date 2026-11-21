#!/system/bin/sh
# cool_run.sh: run ablas_test one shape at a time on a phone that throttles (QDC SM8975 QRD, root shell).
# Before each shape: wait until the thermal cap is off and gpuss-0 <= 45 C (max 180 s); sample the GPU clock
# while the shape runs and print the share of samples at the top clock.
#   cool_run.sh "P P 4096 4096 4096" "T N 2048 2048 2048" ...
K=/sys/class/kgsl/kgsl-3d0
Z=""
for z in /sys/class/thermal/thermal_zone*; do [ "$(cat $z/type)" = gpuss-0 ] && Z=$z/temp; done
TOP=$(cat $K/max_clock_mhz 2>/dev/null)
for s in "$@"; do
  n=0
  while [ "$(cat $K/thermal_pwrlevel)" != 0 ] || [ "$(cat $Z)" -gt 45000 ]; do
    sleep 2; n=$((n + 2)); [ $n -ge 180 ] && break
  done
  t0=$(cat $Z)
  (while true; do cat $K/gpuclk; sleep 0.1; done) > /data/local/tmp/ablas/clk_one.txt &
  sp=$!
  out=$(./ablas_test $s 2>&1 | grep -v device)
  kill $sp
  top=$(grep -c "^1450000000" /data/local/tmp/ablas/clk_one.txt)
  all=$(wc -l < /data/local/tmp/ablas/clk_one.txt)
  echo "$out   [waited ${n}s, start ${t0}mC, ${top}/${all} clock samples at 1.45 GHz]"
done
