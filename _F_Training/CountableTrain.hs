-- | Evaluate countable domain formulas (no learnable params).
module Main where

import A_Categorical.BA_Interpretation.Monads.Expectation (probGiry)
import D_Grammatical.B_Theory.CountableFormulas (countableSen1, countableSenHeavy, countableSenLazy)

main :: IO ()
main = do
  print (probGiry countableSen1)
  print (probGiry countableSenLazy)
  print (probGiry countableSenHeavy)
