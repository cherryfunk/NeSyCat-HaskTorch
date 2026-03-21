{-# LANGUAGE ScopedTypeVariables #-}

-- | Grammatical theory: Countable domain formulas (Giry monad).
module D_Grammatical.B_Theory.CountableFormulas
  ( countableSen1,
    countableSenLazy,
    countableSenHeavy,
  )
where

import A_Categorical.DA_Realization.Giry (Giry)
import B_Logical.BA_Interpretation.Boolean
import C_Domain.BA_Interpretation.Countable
import Data.List (isPrefixOf)

-- | "x > 3 AND y starts with TT"
countableSen1 :: Giry Omega
countableSen1 = do
  x <- drawInt
  y <- drawStr
  return (wedge () (x .> 3) (b2o (isPrefixOf "TT" y)))

-- | Lazy distribution: "x is even"
countableSenLazy :: Giry Omega
countableSenLazy = do
  x <- drawLazy
  return (b2o (even x))

-- | Heavy-tailed distribution: trivially true
countableSenHeavy :: Giry Omega
countableSenHeavy = do
  x <- drawHeavy
  return top
