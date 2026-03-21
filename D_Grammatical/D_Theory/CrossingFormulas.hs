-- | Grammatical theory: Crossing domain formulas (Dist monad).
module D_Grammatical.D_Theory.CrossingFormulas
  ( crossingSen,
  )
where

import A_Categorical.F_Interpretation.Monads.Dist (Dist)
import B_Logical.F_Interpretation.Boolean
import C_Domain.F_Interpretation.Crossing

-- | "Only continue driving if there is a green light."
--   ¬drive ∨ light = Green
crossingSen :: Dist Omega
crossingSen = do
  l <- lightDetector
  d <- drivingDecision l
  return (vee () (neg (d .== 1)) (l .== "Green"))
