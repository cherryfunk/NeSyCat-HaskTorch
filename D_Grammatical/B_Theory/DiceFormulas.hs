{-# LANGUAGE ScopedTypeVariables #-}

-- | Grammatical theory: Dice domain formulas (Dist monad).
module D_Grammatical.B_Theory.DiceFormulas
  ( dieSen1,
    dieSen2,
  )
where

import A_Categorical.DA_Realization.Dist (Dist)
import B_Logical.BA_Interpretation.Boolean
import C_Domain.BA_Interpretation.Dice

-- | "The die shows 6 AND is even"
dieSen1 :: Dist Omega
dieSen1 = do
  x <- die
  return (wedge () (x .== 6) (b2o (even x)))

-- | "The die shows 6" AND "the die is even" (independent draws)
dieSen2 :: Dist Omega
dieSen2 = do
  p <- do x <- die; return (x .== 6)
  q <- do x <- die; return (b2o (even x))
  return (wedge () p q)
