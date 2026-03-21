-- | Evaluate countable domain formulas (no learnable params).
module Main where

import B_Logical.DA_Realization.ExpectGiry (pTrueGiry)
import D_Grammatical.B_Theory.CountableFormulas (countableSen1, countableSenHeavy, countableSenLazy)

main :: IO ()
main = do
  print (pTrueGiry countableSen1)
  print (pTrueGiry countableSenLazy)
  print (pTrueGiry countableSenHeavy)
