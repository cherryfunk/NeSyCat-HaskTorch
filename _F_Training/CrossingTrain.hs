-- | Evaluate crossing domain formula (no learnable params).
module Main where

import B_Logical.DA_Realization.ExpectDist (pTrueDist)
import D_Grammatical.B_Theory.CrossingFormulas (crossingSen)

main :: IO ()
main = do
  print (pTrueDist crossingSen)
