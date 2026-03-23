{-# LANGUAGE FlexibleInstances #-}

-- | Realization of QuantVocabLattice: sup and inf per domain type.
module B_Logical.DA_Realization.Supremum () where

import B_Logical.D_Vocabulary.QuantifierVocab (QuantVocabLattice (..))
import Numeric.Natural (Natural)

maxBudget :: Int
maxBudget = 10000

-- Bool: finite
instance QuantVocabLattice Bool where
  sup phi = max (phi True) (phi False)
  inf phi = min (phi True) (phi False)

-- Unit: trivial
instance QuantVocabLattice () where
  sup phi = phi ()
  inf phi = phi ()

-- Natural: countable
instance QuantVocabLattice Natural where
  sup phi = lazyFold max (-(1.0/0.0)) (map phi [0..])
  inf phi = lazyFold min (1.0/0.0) (map phi [0..])

-- Integer: countable (interleaved)
instance QuantVocabLattice Integer where
  sup phi = lazyFold max (-(1.0/0.0)) (map phi (0 : concatMap (\n -> [n,-n]) [1..]))
  inf phi = lazyFold min (1.0/0.0) (map phi (0 : concatMap (\n -> [n,-n]) [1..]))

-- Double: continuous (not supported)
instance QuantVocabLattice Double where
  sup _ = error "sup over R requires numerical optimization"
  inf _ = error "inf over R requires numerical optimization"

-- Products
instance (QuantVocabLattice a, QuantVocabLattice b) => QuantVocabLattice (a, b) where
  sup phi = sup (\a -> sup (\b -> phi (a, b)))
  inf phi = inf (\a -> inf (\b -> phi (a, b)))

lazyFold :: (b -> a -> b) -> b -> [a] -> b
lazyFold f = go 0
  where
    go _ acc [] = acc
    go n acc _ | n >= maxBudget = acc
    go n acc (x : xs) = go (n + 1) (f acc x) xs
