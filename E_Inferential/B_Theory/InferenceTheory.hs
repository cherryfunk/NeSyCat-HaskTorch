{-# LANGUAGE TypeFamilies #-}

-- | The inference theory (level epsilon) declares the function symbols needed
--   to turn a parameterized formula into an optimization problem.
--
--   Function symbols:
--     lossKnow : Omega -> R           knowledge loss (how unsatisfied is the axiom?)
--     lossData : Omega x Omega -> R   data loss (how far is prediction from label?)
--     lossComb : R x R x lam -> R     combined objective  J = lam*J_data + (1-lam)*J_know
--
--   Categorically, the inference level works in Para(C_delta) (Gavranovic 2024).
module E_Inferential.B_Theory.InferenceTheory
  ( InferenceFun (..),
  )
where

-- | Function symbols of the inference theory.
--   Each interpretation (instance) assigns concrete morphisms.
class InferenceFun cat where
  type Loss cat :: *

  lossKnow :: cat -> Loss cat

  lossData :: cat -> cat -> Loss cat

  lossComb :: Loss cat -> Loss cat -> cat -> Loss cat
