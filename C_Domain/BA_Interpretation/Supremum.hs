{-# LANGUAGE FlexibleInstances #-}

-- | Supremum, Infimum, Enumeration -- type class dispatch, no GADT.
module C_Domain.BA_Interpretation.Supremum
  ( HasSup (..),
    HasInf (..),
    EnumAll (..),
  )
where

import Numeric.Natural (Natural)

maxBudget :: Int
maxBudget = 10000

class HasSup a where
  sup :: (a -> Double) -> Double

class HasInf a where
  inf :: (a -> Double) -> Double

class EnumAll a where
  enumAll :: [a]

instance HasSup Bool where sup phi = max (phi True) (phi False)
instance HasInf Bool where inf phi = min (phi True) (phi False)
instance EnumAll Bool where enumAll = [True, False]

instance HasSup () where sup phi = phi ()
instance HasInf () where inf phi = phi ()
instance EnumAll () where enumAll = [()]

instance HasSup Natural where sup phi = lazyFold max (-(1.0/0.0)) (map phi [0..])
instance HasInf Natural where inf phi = lazyFold min (1.0/0.0) (map phi [0..])
instance EnumAll Natural where enumAll = [0..]

instance HasSup Integer where sup phi = lazyFold max (-(1.0/0.0)) (map phi (0 : concatMap (\n -> [n,-n]) [1..]))
instance HasInf Integer where inf phi = lazyFold min (1.0/0.0) (map phi (0 : concatMap (\n -> [n,-n]) [1..]))
instance EnumAll Integer where enumAll = 0 : concatMap (\n -> [n,-n]) [1..]

instance EnumAll Char where enumAll = [minBound .. maxBound]

instance HasSup Double where sup _ = error "sup over R requires numerical optimization"
instance HasInf Double where inf _ = error "inf over R requires numerical optimization"

instance (HasSup a, HasSup b) => HasSup (a, b) where
  sup phi = sup (\a -> sup (\b -> phi (a, b)))
instance (HasInf a, HasInf b) => HasInf (a, b) where
  inf phi = inf (\a -> inf (\b -> phi (a, b)))
instance (EnumAll a, EnumAll b) => EnumAll (a, b) where
  enumAll = [(a,b) | a <- enumAll, b <- enumAll]

lazyFold :: (b -> a -> b) -> b -> [a] -> b
lazyFold f = go 0
  where
    go _ acc [] = acc
    go n acc _ | n >= maxBudget = acc
    go n acc (x : xs) = go (n + 1) (f acc x) xs
