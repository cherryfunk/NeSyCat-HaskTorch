{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}

-- | Hask Interpretation: assigns concrete Haskell functions to the
--   abstract natural transformation names declared in HaskSig.
module A_Categorical.D_Interpretation.HaskInt where

import A_Categorical.A_Signature.HaskSig (Cat2FunS (..))
import A_Categorical.B_Realization.HaskRlz ()
import Data.Functor.Identity (Identity (..))
import qualified A_Categorical.D_Interpretation.Monads.Dist as M
import qualified A_Categorical.D_Interpretation.Monads.Giry as M
import Control.Monad (join)

-- | Natural transformations for each declared functor.
instance Cat2FunS Identity where
  eta :: a -> Identity a
  eta = Identity
  mu :: Identity (Identity a) -> Identity a
  mu  = runIdentity

instance Cat2FunS M.Dist where
  eta :: a -> M.Dist a
  eta = return
  mu :: M.Dist (M.Dist a) -> M.Dist a
  mu  = join

instance Cat2FunS M.Giry where
  eta :: a -> M.Giry a
  eta = return
  mu :: M.Giry (M.Giry a) -> M.Giry a
  mu  = join
