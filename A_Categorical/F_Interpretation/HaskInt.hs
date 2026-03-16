{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}

-- | Hask Interpretation: assigns concrete Haskell functions to the
--   abstract natural transformation names declared in HaskSig.
module A_Categorical.F_Interpretation.HaskInt where

import A_Categorical.D_Theory.HaskTheory (Cat2FunTheory (..))
import A_Categorical.E_Extension.HaskExtension ()
import Data.Functor.Identity (Identity (..))
import qualified A_Categorical.F_Interpretation.Monads.Dist as M
import qualified A_Categorical.F_Interpretation.Monads.Giry as M
import Control.Monad (join)

-- | Natural transformations for each declared functor.
instance Cat2FunTheory Identity where
  eta :: a -> Identity a
  eta = Identity
  mu :: Identity (Identity a) -> Identity a
  mu  = runIdentity

instance Cat2FunTheory M.Dist where
  eta :: a -> M.Dist a
  eta = return
  mu :: M.Dist (M.Dist a) -> M.Dist a
  mu  = join

instance Cat2FunTheory M.Giry where
  eta :: a -> M.Giry a
  eta = return
  mu :: M.Giry (M.Giry a) -> M.Giry a
  mu  = join
