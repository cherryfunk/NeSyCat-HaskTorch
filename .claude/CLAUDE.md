---
description: 
alwaysApply: true
---

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Haskell implementation of the **NeSyCat** neurosymbolic framework using HaskTorch (Haskell bindings to libtorch). The code is a typed tensor-category realization of the theory described in the companion paper repo (`../NeSyCat Papers/`).

## Build & Run Commands

```bash
# Build the library and all executables
cabal build all

# Run the executables
cabal run binary-benchmark        # Binary classification with benchmarks (accuracy, F1)
cabal run binary-test-real        # Binary classification with TensReal logic
cabal run binary-test-real-beta   # Beta-distribution variant

# Run with RTS options (executables with -rtsopts)
cabal run binary-test-real -- +RTS -s
```

Requires `hasktorch` and its libtorch dependency to be available. HLS is configured via `hie.yaml` (cabal cradle).

## Architecture: The ABCDEFG Pipeline

The codebase mirrors the paper's layered categorical structure. Each top-level directory is a **layer** of the framework, and within each layer modules follow the same **A→B→C→D→E→F→G sub-pipeline**:

| Sub-step | Role | What it defines |
|----------|------|----------------|
| **A_Category** | Category GADTs | GADT witnesses for the interpreting category (DATA, TENS) |
| **B_Theory** | Abstract theory | Type classes declaring sort/function/relation symbols |
| **BA_Interpretation** | Semantics | Concrete functions implementing the abstract operations |
| **BC_Extension** | Theory → Vocab | Type family instances mapping abstract names → Haskell types |
| **C_TypeSystem** | Type universe | Which Haskell types/functors are valid at this layer |
| **D_Vocabulary** | Vocabulary | Vocabulary types for the layer |
| **DA_Realization** | Realization | Connects vocabulary to concrete implementations |

### Layers (top-level directories)

- **`A_Categorical/`** — Alpha-level: the ambient 2-category (Hask). Defines monad theories (`Ident`, `Dist`, `Giry`) and their natural transformations (`eta`/`mu`). This is the categorical foundation that all other layers build on.

- **`B_Logical/`** — Beta-level: logical connectives. The `TwoMonBLatTheory` class defines a double-monoid bounded lattice (∨, ∧, ⊕, ⊗ with bounds). Interpretations: `Boolean`, `Real` (LogSumExp/TensReal). The `TENS` and `FDATA` modules are the two main tensor-based interpretations.

- **`C_Domain/`** — Gamma-level: domain-specific theories. Currently only the Binary domain exists, with its own theory declaring domain sorts and relation symbols (Tarski and Kleisli), plus extensions and interpretations using HaskTorch tensors.

- **`D_Grammatical/`** — Delta-level: formulas/axioms. Combines logical connectives with domain interpretations to express axioms (e.g., `axiomReal` builds ∀-quantified classification constraints). Executables live here.

- **`E_Inferential/`** — Objective functions: `Softplus` (pen(sat) = -log(σ(sat))), `CrossEntropy`, `NegLog`, `OneMinus`, `Combined` (λ·J_data + (1-λ)·J_know).

- **`F_Statistical/`** — Evaluation metrics (accuracy, F1, confidence).

### Data flow

Theory (D) → Extension (E) → Vocabulary (B) → Category (A) → Interpretation (F) → Training (G)

A domain problem is defined by choosing: a gamma-level theory (e.g., `BinaryTheory`), a logical interpretation (e.g., `TensReal`), an axiom formula (e.g., `axiomReal`), an objective function (e.g., `combinedObjective`), and a training loop.

## Key Patterns

- **Type families + type classes** are used throughout to achieve the theory/extension separation. `@TENS` type applications select the tensor interpretation.
- The training objective `J(θ) = λ·J_data(θ) + (1-λ)·J_know(θ)` blends data-driven (cross-entropy) and knowledge-driven (axiom satisfaction) losses. `λ=0` is pure axiom-driven; `λ=1` is pure data-driven.
- `Torch.Typed.Tensor` is used for typed tensors; `toDynamic` bridges to untyped `Torch.Tensor` when needed.
