{-# LANGUAGE GADTs #-}

-- | Star vocabulary: the monad types available in the universe.
--   These are names with their data structure -- realizations (Monad instances)
--   live in DA_Realization/.
module A_Categorical.D_Vocabulary.StarVocab
  ( Dist (..),
    Giry (..),
  )
where

import Statistics.Distribution (ContDistr, Mean, Variance)

-- | The Dist Monad: finitely supported probability distributions.
--   Represented as a free monad (symbolic/lazy) -- evaluation via expect.
--   Only finite support constructors are allowed.
data Dist a where
  Pure :: a -> Dist a
  Bind :: Dist x -> (x -> Dist a) -> Dist a
  FiniteSupp :: [(a, Double)] -> Dist a
  FinUniform :: [a] -> Dist a

-- | The Giry Monad: general probability measures (finite, countable, continuous).
--   Also a free monad -- evaluation via expect.
data Giry a where
  -- Monadic structure
  GPure :: a -> Giry a
  GBind :: Giry x -> (x -> Giry a) -> Giry a
  -- Finitely supported
  GFiniteSupp :: [(a, Double)] -> Giry a
  GFinUniform :: [a] -> Giry a
  -- Countably infinite support
  Poisson :: Double -> Giry Int
  Geometric :: Double -> Giry Int
  -- Continuous (over Reals)
  Normal :: Double -> Double -> Giry Double
  Uniform :: Double -> Double -> Giry Double
  -- and more standard distributions...
  Exponential :: Double -> Giry Double
  Beta :: Double -> Double -> Giry Double
  Gamma :: Double -> Double -> Giry Double
  Laplace :: Double -> Double -> Giry Double
  StudentT :: Double -> Giry Double
  GenericCont :: (ContDistr d, Mean d, Variance d) => d -> Giry Double
  ContinuousPdf :: (Double -> Double) -> (Double, Double) -> Giry Double
