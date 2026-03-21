-- | Grammatical theory: Crossing domain formulas (Dist monad).
module D_Grammatical.B_Theory.CrossingFormulas
  ( crossingSen,
  )
where

import A_Categorical.DA_Realization.Dist (Dist)
import B_Logical.BA_Interpretation.Boolean
import C_Domain.BA_Interpretation.Crossing

-- | "Only continue driving if there is a green light."
--   ¬drive ∨ light = Green
crossingSen :: Dist Omega
crossingSen = do
  l <- lightDetector
  d <- drivingDecision l
  return (vee () (neg (d .== 1)) (l .== "Green"))
