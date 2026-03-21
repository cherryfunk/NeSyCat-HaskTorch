-- | Grammatical theory: Weather domain formulas (Giry monad).
module D_Grammatical.D_Theory.WeatherFormulas
  ( weatherSen1,
    weatherSen2,
    weatherSen3,
  )
where

import A_Categorical.F_Interpretation.Monads.Giry (Giry)
import B_Logical.F_Interpretation.Boolean
import C_Domain.F_Interpretation.Weather

-- | Weather scenario 1: "it is humid AND hot (t > 30)"
weatherSen1 :: Giry Omega
weatherSen1 = do
  h <- bernoulli (humidDetect data1)
  t <- normalDist (tempPredict data1)
  return (wedge () (h .== 1) (t .> 30.0))

-- | Weather scenario 2: "it is humid AND warm (t > 25)"
weatherSen2 :: Giry Omega
weatherSen2 = do
  h <- bernoulli (humidDetect data1)
  t <- normalDist (tempPredict data1)
  return (wedge () (h .== 1) (t .> 25.0))

-- | Weather scenario 3: "it is humid AND average (t > 0)"
weatherSen3 :: Giry Omega
weatherSen3 = do
  h <- bernoulli (humidDetect data3)
  t <- normalDist (tempPredict data3)
  return (wedge () (h .== 1) (t .> 0.0))
