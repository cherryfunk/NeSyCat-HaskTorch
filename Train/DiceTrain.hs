-- | Evaluate dice domain formulas (no learnable params).
module Main where

import A_Categorical.F_Interpretation.Monads.Expectation (probDist)
import D_Grammatical.D_Theory.DiceFormulas (dieSen1, dieSen2)

main :: IO ()
main = do
  print (probDist dieSen1)
  print (probDist dieSen2)
