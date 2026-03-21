-- | Evaluate dice domain formulas (no learnable params).
module Main where

import B_Logical.DA_Realization.ExpectDist (pTrueDist)
import D_Grammatical.B_Theory.DiceFormulas (dieSen1, dieSen2)

main :: IO ()
main = do
  print (pTrueDist dieSen1)
  print (pTrueDist dieSen2)
