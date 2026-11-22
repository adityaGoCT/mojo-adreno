#!/system/bin/sh
# Runs every test in its own process (a compiler crash or a lost device only ends that test) and prints a summary.
# On the phone:  cd /data/local/tmp/adreno_repro && ./run_all.sh [test ...]
cd "$(dirname "$0")"
tests="$*"
[ -z "$tests" ] && tests=$(./repro list | awk '{print $1}')
mkdir -p logs
for t in $tests; do
  logcat -c 2>/dev/null
  timeout 120 ./repro $t > logs/$t.log 2>&1
  rc=$?
  [ $rc = 139 ] && { sleep 3; logcat -d 2>/dev/null | grep -A20 "backtrace:" > logs/$t.backtrace.txt; }
  res=$(grep "^RESULT" logs/$t.log)
  if [ -z "$res" ]; then
    case $rc in
      139) res="RESULT $t CRASH (SIGSEGV; last step: $(tail -1 logs/$t.log))" ;;
      134) res="RESULT $t CRASH (SIGABRT; last step: $(tail -1 logs/$t.log))" ;;
      124) res="RESULT $t TIMEOUT (no completion in 120 s; last step: $(tail -1 logs/$t.log))" ;;
      *) res="RESULT $t EXIT $rc (last step: $(tail -1 logs/$t.log))" ;;
    esac
  fi
  echo "$res"
  sleep 2
done
