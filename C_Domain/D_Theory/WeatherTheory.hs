{-# LANGUAGE AllowAmbiguousTypes #-}

module C_Domain.D_Theory.WeatherTheory where

-- | Non-Logical Vocabulary for the Weather domain.

-- | Sorts:
type Worlds = String

-- | Data schema:
data WorldsRow = WorldsRow
  { worldId :: Worlds,
    humidityPval :: Double,
    tempMean :: Double,
    tempStd :: Double
  }

-- | Signature:
class WeatherTheory m where
  -- Con:
  data1 :: Worlds
  data2 :: Worlds
  data3 :: Worlds

  -- Fun (Tarski):
  humidDetect :: Worlds -> Double
  tempPredict :: Worlds -> (Double, Double)

  -- mFun (Kleisli):
  bernoulli :: Double -> m Int
  normalDist :: (Double, Double) -> m Double
