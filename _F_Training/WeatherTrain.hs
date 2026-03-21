-- | Evaluate weather domain formulas (no learnable params).
module Main where

import B_Logical.DA_Realization.ExpectGiry (pTrueGiry)
import D_Grammatical.B_Theory.WeatherFormulas (weatherSen1, weatherSen2, weatherSen3)

main :: IO ()
main = do
  print (pTrueGiry weatherSen1)
  print (pTrueGiry weatherSen2)
  print (pTrueGiry weatherSen3)
  putStrLn $ "Berlin entails Hamburg: " ++ show (pTrueGiry weatherSen1 <= pTrueGiry weatherSen2)
