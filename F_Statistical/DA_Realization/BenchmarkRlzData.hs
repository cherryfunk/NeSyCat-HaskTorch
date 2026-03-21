{-# LANGUAGE InstanceSigs #-}

-- | Benchmark realization: concrete implementations of vocabulary symbols
--   for plain Haskell types (Double).
module F_Statistical.DA_Realization.BenchmarkRlzData () where

import F_Statistical.D_Vocabulary.BenchmarkVocab (BenchmarkVocab (..))

-- | Realization of BenchmarkVocab for Double.
instance BenchmarkVocab Double where
  threshold :: Double -> Double -> Bool
  threshold p t = p > t

  fractionTrue :: [Bool] -> Double
  fractionTrue bs =
    let n = length bs
        k = length (filter id bs)
     in if n > 0 then fromIntegral k / fromIntegral n else 0.0

  harmonicMean :: Double -> Double -> Double
  harmonicMean a b
    | a + b > 0 = 2.0 * a * b / (a + b)
    | otherwise = 0.0

  meanWhere :: [Double] -> [Bool] -> Double
  meanWhere vals mask =
    let selected = [v | (v, True) <- zip vals mask]
     in if null selected then 0.0
        else sum selected / fromIntegral (length selected)
