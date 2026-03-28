{-# LANGUAGE FlexibleInstances #-}

-- | The DATA type system (set/measure theory paradigm).
--   DataObj marks which Haskell types are objects of the domain category.
--   Integration strategy is NOT a property of the type -- it belongs
--   with the expectation (B_Logical/DA_Realization/ExpectGiry.hs).
module C_Domain.C_TypeSystem.Data
  ( DataObj,
    tableLookup,
  )
where

import Numeric.Natural (Natural)

-- | Type membership in the DATA type system.
class DataObj a

instance (DataObj a, DataObj b) => DataObj (a, b)

instance (DataObj a) => DataObj [a]

instance DataObj Bool

instance DataObj Natural

instance DataObj Integer

instance DataObj Char

instance DataObj Double

instance DataObj Float

instance DataObj Int

instance DataObj ()

-- | Generic table lookup.
tableLookup :: (Eq k, Show k) => (row -> k) -> k -> [row] -> row
tableLookup keyOf k rows = case filter (\r -> keyOf r == k) rows of
  (r : _) -> r
  [] -> error $ "No such key: " ++ show k
