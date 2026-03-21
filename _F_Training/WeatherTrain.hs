-- | Evaluate weather domain formulas (no learnable params).
module Main where

import A_Categorical.BA_Interpretation.Monads.Expectation (probGiry)
import D_Grammatical.B_Theory.WeatherFormulas (weatherSen1, weatherSen2, weatherSen3)

main :: IO ()
main = do
  print (probGiry weatherSen1)
  print (probGiry weatherSen2)
  print (probGiry weatherSen3)
  putStrLn $ "Berlin entails Hamburg: " ++ show (probGiry weatherSen1 <= probGiry weatherSen2)
