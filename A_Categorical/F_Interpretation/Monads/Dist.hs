{-# LANGUAGE InstanceSigs #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

-- | Interpretation of the Dist monad: Functor, Applicative and Monad
--   instances. The Dist type itself lives in StarVocab (vocabulary).
module A_Categorical.F_Interpretation.Monads.Dist
  ( module A_Categorical.B_Vocabulary.StarVocab
  ) where

import A_Categorical.B_Vocabulary.StarVocab (Dist (..))
import Control.Monad (ap, liftM)

-- | Standard Haskell Monad Hierarchy for Dist
instance Functor Dist where
  fmap :: (a -> b) -> Dist a -> Dist b
  fmap = liftM

instance Applicative Dist where
  pure :: a -> Dist a
  pure x = Dist [(x, 1.0)]

  (<*>) :: Dist (a -> b) -> Dist a -> Dist b
  (<*>) = ap

instance Monad Dist where
  return :: a -> Dist a
  return = pure

  (>>=) :: Dist a -> (a -> Dist b) -> Dist b
  (Dist xs) >>= f =
    Dist $
      concat
        [[(y, p * q) | (y, q) <- runDist (f x)] | (x, p) <- xs]
