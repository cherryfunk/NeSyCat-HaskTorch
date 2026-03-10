#!/usr/bin/env bash
# Master binary classification benchmark runner.
# Runs all 10 trials for each model and saves output to E_Benchmark/results/.
# Usage: cd /Users/cherryfunk/Repos/NeSyCat-HaskTorch && bash E_Benchmark/run_all_binary.sh

set -euo pipefail
REPO="/Users/cherryfunk/Repos/NeSyCat-HaskTorch"
RESULTS="$REPO/E_Benchmark/results/raw/haskell"
N=10
# Haskell RTS flags: -A64m allocates 64MB nursery (reduces GC frequency),
# -N1 disables multi-threaded RTS overhead for these serial CPU benchmarks.
RTS_FLAGS="+RTS -A64m -N1 -RTS"

mkdir -p "$RESULTS"

echo "=== Building all binary executables ==="
cd "$REPO"
cabal build binary-test binary-test-jit binary-test-real binary-test-jit-real binary-test-real-beta 2>&1

# Locate built executables
BIN_UNIFORM=$(cabal list-bin binary-test 2>/dev/null)
BIN_UNIFORM_JIT=$(cabal list-bin binary-test-jit 2>/dev/null)
BIN_REAL=$(cabal list-bin binary-test-real 2>/dev/null)
BIN_REAL_JIT=$(cabal list-bin binary-test-jit-real 2>/dev/null)
BIN_REAL_BETA=$(cabal list-bin binary-test-real-beta 2>/dev/null)

run_haskell() {
  local name="$1"; local bin="$2"
  echo ""; echo "=== HaskTorch $name (${N} runs) ==="
  for i in $(seq 1 $N); do
    echo "--- Run $i ---"
    "$bin" $RTS_FLAGS 2>&1 | tee -a "$RESULTS/${name}_run${i}.txt"
  done
}

run_haskell "uniform_eager"    "$BIN_UNIFORM"
run_haskell "uniform_compiled" "$BIN_UNIFORM_JIT"
run_haskell "real_eager"       "$BIN_REAL"
run_haskell "real_compiled"    "$BIN_REAL_JIT"
run_haskell "real_beta"        "$BIN_REAL_BETA"

# ---- Python benchmarks ----
TORCH_VENV="$REPO/E_Benchmark/nesy_approaches/LTNtorch_reference/venv"
TF_VENV="$REPO/E_Benchmark/nesy_approaches/logictensornetworks_reference/venv"

echo ""; echo "=== MLP Baseline (pure BCE, PyTorch) ==="
"$TORCH_VENV/bin/python3" "$REPO/E_Benchmark/bench_mlp_baseline.py" 2>&1 | tee "$RESULTS/mlp_baseline.txt"

echo ""; echo "=== LTNtorch fair benchmark ==="
"$TORCH_VENV/bin/python3" "$REPO/E_Benchmark/bench_ltn_torch.py" 2>&1 | tee "$RESULTS/ltn_torch.txt"

echo ""; echo "=== LTN TensorFlow (eager + compiled) ==="
"$TF_VENV/bin/python3" "$REPO/E_Benchmark/bench_ltn_tf.py" 2>&1 | tee "$RESULTS/ltn_tf.txt"

echo ""; echo "=== All benchmarks complete. Results in $RESULTS ==="
