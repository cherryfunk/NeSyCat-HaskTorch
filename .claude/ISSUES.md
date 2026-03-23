# Current Issues

_Last verified: 2026-03-23_

## Experiment Results

| Experiment | Final Loss | Accuracy | F1 | Time | Memory |
|---|---|---|---|---|---|
| binary-benchmark | 0.028 | Train=100%/Test=92% | 0.882 | 0.31s | 6 MiB |
| binary-test-real | 0.120 | — | — | 0.30s | 6 MiB |
| **binary-test-jit-real** | **NaN** | — | — | 0.37s | 6 MiB |
| binary-test-real-beta | 0.054 (β→1.96) | — | — | 0.38s | 6 MiB |

## BLOCKING

None

## BUG

- **`binary-test-jit-real` NaN divergence**: Loss is `Infinity` at epoch 1 and `NaN` for all 1000 subsequent epochs. The JIT-traced forward pass has a numerical instability (likely log(0), division by zero, or overflow in the traced computation graph). The eager execution path (`binary-test-real`) works fine with identical logic, so the bug is in the JIT tracing, not the model. Location: `_F_Training/BinaryTrainJIT.hs`.

## DEBT

- **5 orphaned modules** (exposed in .cabal, never imported by anything):
  - `A_Categorical.A_Category.STAR` — comment-only placeholder
  - `A_Categorical.C_TypeSystem.StarTypes` — defines `CatObjTyp`/`CatFunTyp`/`CatRelTyp`, unused
  - `B_Logical.C_TypeSystem.FTens` — defines `FTensObj`, unused
  - `B_Logical.C_TypeSystem.FData` — defines `FDataObj`, unused
  - `E_Inferential.A_Category.Diff` — comment-only placeholder
- **3 unused-but-valid modules** (have working code, but nothing calls them):
  - `B_Logical.DA_Realization.Supremum` — `QuantVocabLattice` instances
  - `B_Logical.DA_Realization.ExpectGiry` — `QuantVocabGiry` instances
  - `D_Grammatical.BA_Interpretation.BinaryIntpData` — `binaryAxiomData` function
- **2 placeholder modules** with no executable code: `STAR.hs`, `Diff.hs`
- **Stale build artifacts** in `dist-newstyle/` for removed executables (countable-test, dice-test, crossing-test, weather-test, mnist-test)

## INFO

- Binary is the only domain (MNIST, Dice, Crossing, Weather, Countable were removed)
- Core active pipeline (Binary domain, FrmwkGeom/FrmwkMeas training) is internally consistent and complete
- Layer consistency verdict: LAYERS_INCONSISTENT (due to orphaned/dead modules, not pipeline breaks)
