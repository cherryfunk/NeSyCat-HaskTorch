{-# LANGUAGE TypeFamilies #-}

-- | The inference theory (level ε) declares the function symbols needed
--   to turn a parameterized formula into an optimization problem.
--
--   Function symbols:
--     lossKnow : Ω → ℝ           knowledge loss (how unsatisfied is the axiom?)
--     lossData : Ω × Ω → ℝ      data loss (how far is prediction from label?)
--     lossComb : ℝ × ℝ × λ → ℝ  combined objective  J = λ·J_data + (1-λ)·J_know
--
--   Categorically, the inference level works in Para(C_δ) (Gavranovic 2024).
module E_Inferential.B_Theory.InferenceTheory
  ( InferenceFun (..),
  )
where

-- | Function symbols of the inference theory.
--   Each interpretation (instance) assigns concrete morphisms.
class InferenceFun cat where
  type Loss cat :: *

  -- | lossKnow : Ω → ℝ. Knowledge loss / penalty on axiom satisfaction.
  lossKnow :: cat -> Loss cat

  -- | lossData : prediction × label → ℝ. Pointwise data loss.
  lossData :: cat -> cat -> Loss cat

  -- | lossComb : J_data × J_know × λ → J. Combined objective.
  lossComb :: Loss cat -> Loss cat -> cat -> Loss cat
