#!/system/bin/sh
# run.sh: run every kernel in runlist.txt through bench, one process each, on a phone that throttles.
# Before each kernel: wait until no llama.cpp process or other GEMM benchmark (vk_gemm_bench) is running, the thermal cap is off and gpuss-0 <= 45 C
# (max 180 s); sample the GPU clock while it runs.
#   cd /data/local/tmp/worklog && ./run.sh 4096 [name-substring] [runlist]
S=$1; F=$2; L=${3:-runlist.txt}
K=/sys/class/kgsl/kgsl-3d0
Z=""
for z in /sys/class/thermal/thermal_zone*; do [ "$(cat $z/type)" = gpuss-0 ] && Z=$z/temp; done
while read name gx gy la lb ch; do
  case "$name" in *"$F"*) ;; *) continue ;; esac
  n=0
  while pidof llama-bench llama-completion llama-perplexity vk_gemm_bench > /dev/null || [ "$(cat $K/thermal_pwrlevel)" != 0 ] || [ "$(cat $Z)" -gt 45000 ]; do
    sleep 2; n=$((n + 2)); [ $n -ge 180 ] && break
  done
  t0=$(cat $Z)
  (while true; do cat $K/gpuclk; sleep 0.1; done) > clk.txt &
  sp=$!
  out=$(BENCH_CHUNKS=${ch:-1} timeout 600 ./bench spv/$name.spv $S $S $S $gx $gy $la $lb 2>&1 | grep RESULT)
  kill $sp
  top=$(grep -c "^1450000000" clk.txt)
  all=$(wc -l < clk.txt)
  [ -z "$out" ] && out="RESULT $name FAILED"
  echo "$out [waited ${n}s, start ${t0}mC, ${top}/${all} clock samples at 1.45 GHz]"
done < $L
