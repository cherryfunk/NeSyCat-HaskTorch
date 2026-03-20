-- | Grammatical interpretation: Crossing domain.
module Main where

import A_Categorical.F_Interpretation.Monads.Expectation (probDist)
import D_Grammatical.D_Theory.CrossingFormulas (crossingSen)

main :: IO ()
main = do
  print (probDist crossingSen)
