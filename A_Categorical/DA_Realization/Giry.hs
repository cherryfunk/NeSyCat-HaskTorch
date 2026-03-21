{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

-- | Realization of the Giry monad: free monad (symbolic/lazy).
--   The Giry GADT itself lives in StarVocab (vocabulary).
module A_Categorical.DA_Realization.Giry
  ( module A_Categorical.D_Vocabulary.StarVocab
  ) where

import A_Categorical.D_Vocabulary.StarVocab (Giry (..))
import Control.Monad (ap)

instance Functor Giry where
  fmap :: (a -> b) -> Giry a -> Giry b
  fmap f m = GBind m (GPure . f)

instance Applicative Giry where
  pure :: a -> Giry a
  pure = GPure

  (<*>) :: Giry (a -> b) -> Giry a -> Giry b
  (<*>) = ap

instance Monad Giry where
  return :: a -> Giry a
  return = pure

  (>>=) :: Giry a -> (a -> Giry b) -> Giry b
  (>>=) = GBind
