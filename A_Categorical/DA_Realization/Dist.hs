{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

-- | Realization of the Dist monad: free monad (symbolic/lazy).
--   The Dist type itself lives in StarVocab (vocabulary).
module A_Categorical.DA_Realization.Dist
  ( module A_Categorical.D_Vocabulary.StarVocab
  ) where

import A_Categorical.D_Vocabulary.StarVocab (Dist (..))
import Control.Monad (ap)

instance Functor Dist where
  fmap :: (a -> b) -> Dist a -> Dist b
  fmap f m = Bind m (Pure . f)

instance Applicative Dist where
  pure :: a -> Dist a
  pure = Pure

  (<*>) :: Dist (a -> b) -> Dist a -> Dist b
  (<*>) = ap

instance Monad Dist where
  return :: a -> Dist a
  return = pure

  (>>=) :: Dist a -> (a -> Dist b) -> Dist b
  (>>=) = Bind
