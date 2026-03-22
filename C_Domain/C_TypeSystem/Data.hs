{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | The DATA type system (set/measure theory paradigm).
--   DataObj type class replaces the old DATA GADT.
module C_Domain.C_TypeSystem.Data
  ( DataObj (..),
    IntegrationStrategy (..),
    tableLookup,
  )
where

import Numeric.Natural (Natural)

-- | Integration strategy per type.
data IntegrationStrategy
  = FiniteStrategy
  | CountableStrategy
  | ContinuousStrategy
  | TrivialStrategy
  deriving (Show, Eq)

-- | Type membership in the DATA type system.
class DataObj a where
  integrationStrategy :: IntegrationStrategy

instance DataObj Bool where integrationStrategy = FiniteStrategy

instance DataObj Natural where integrationStrategy = CountableStrategy

instance DataObj Integer where integrationStrategy = CountableStrategy

instance DataObj Char where integrationStrategy = FiniteStrategy

instance DataObj Double where integrationStrategy = ContinuousStrategy

instance DataObj Int where integrationStrategy = FiniteStrategy

instance DataObj () where integrationStrategy = TrivialStrategy

instance
  (DataObj a, DataObj b) =>
  DataObj (a, b)
  where
  integrationStrategy = FiniteStrategy

instance
  (DataObj a) =>
  DataObj [a]
  where
  integrationStrategy = CountableStrategy

-- | Generic table lookup.
tableLookup :: (Eq k, Show k) => (row -> k) -> k -> [row] -> row
tableLookup keyOf k rows = case filter (\r -> keyOf r == k) rows of
  (r : _) -> r
  [] -> error $ "No such key: " ++ show k
