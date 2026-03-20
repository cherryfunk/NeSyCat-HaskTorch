{-# LANGUAGE ScopedTypeVariables #-}

-- | Grammatical theory: Countable domain formulas (Giry monad).
module D_Grammatical.D_Theory.CountableFormulas
  ( countableSen1,
    countableSenLazy,
    countableSenHeavy,
  )
where

import A_Categorical.F_Interpretation.Monads.Giry (Giry)
import B_Logical.F_Interpretation.Boolean
import C_Domain.F_Interpretation.Countable
import Data.List (isPrefixOf)

-- | "x > 3 AND y starts with TT"
countableSen1 :: Giry Omega
countableSen1 = do
  x <- drawInt
  y <- drawStr
  return (x .> 3 `wedge` b2o (isPrefixOf "TT" y))

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
