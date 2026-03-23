---
name: run-experiments-and-capture-scorestimes
description: Run experiments and capture scores/times
tools: Bash, Read
model: sonnet
---
Run the NeSyCat-HaskTorch experiments and capture performance metrics.

1. Run `cabal run binary-test-real -- +RTS -s` and capture:
   - Final accuracy/scores from stdout
   - Wall clock time and memory usage from RTS stats

2. If `cabal run binary-test-jit-real` exists and builds, run it too.

3. If `cabal run binary-test-real-beta` exists and builds, run it too.

For each experiment, report:
- Experiment name
- Accuracy/classification scores
- Training time (wall clock)
- Peak memory usage

Format results as a clear table. Flag any experiment that fails to run. Output EXPERIMENTS_PASS if all ran successfully, EXPERIMENTS_FAIL if any failed.