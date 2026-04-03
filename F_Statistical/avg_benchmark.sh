#!/usr/bin/env bash
# Average benchmark over N runs of binary-benchmark.
# Usage: ./F_Statistical/avg_benchmark.sh [N]
#   N = number of runs (default: 10)

N=${1:-10}

echo "Running binary-benchmark $N times..."
echo "========================================"

acc_train=0; acc_test=0; f1=0; prec=0; conf_p=0; conf_n=0; loss=0

for i in $(seq 1 "$N"); do
  out=$(cabal run binary-benchmark 2>&1)

  j=$(echo "$out" | grep 'Epoch 1000' | grep -oE 'J=[0-9.]+' | cut -d= -f2)
  at=$(echo "$out" | grep 'Accuracy' | grep -oE 'Train=[0-9.]+' | cut -d= -f2)
  ae=$(echo "$out" | grep 'Accuracy' | grep -oE 'Test=[0-9.]+' | cut -d= -f2)
  f=$(echo "$out" | grep 'F1 Score' | grep -oE '[0-9.]+$')
  p=$(echo "$out" | grep 'Precision' | grep -oE '[0-9.]+$')
  cp=$(echo "$out" | grep 'Confidence' | grep -oE 'P\+=[0-9.]+' | cut -d= -f2)
  cn=$(echo "$out" | grep 'Confidence' | grep -oE 'P-=[0-9.]+' | cut -d= -f2)

  printf "  Run %2d: J=%-8s Acc=%-6s F1=%-6s Prec=%-6s\n" "$i" "$j" "$ae" "$f" "$p"

  loss=$(echo "$loss + $j" | bc)
  acc_train=$(echo "$acc_train + $at" | bc)
  acc_test=$(echo "$acc_test + $ae" | bc)
  f1=$(echo "$f1 + $f" | bc)
  prec=$(echo "$prec + $p" | bc)
  conf_p=$(echo "$conf_p + $cp" | bc)
  conf_n=$(echo "$conf_n + $cn" | bc)
done

echo "========================================"
printf "Average over %d runs:\n" "$N"
printf "  Final Loss:    %.5f\n" "$(echo "$loss / $N" | bc -l)"
printf "  Accuracy:      Train=%.4f  Test=%.4f\n" "$(echo "$acc_train / $N" | bc -l)" "$(echo "$acc_test / $N" | bc -l)"
printf "  F1 Score:      %.4f\n" "$(echo "$f1 / $N" | bc -l)"
printf "  Precision:     %.4f\n" "$(echo "$prec / $N" | bc -l)"
printf "  Confidence:    P+=%.4f  P-=%.4f\n" "$(echo "$conf_p / $N" | bc -l)" "$(echo "$conf_n / $N" | bc -l)"
