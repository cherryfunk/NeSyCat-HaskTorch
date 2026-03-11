{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE FlexibleInstances #-}

module A_Categorical.B_Realization.HaskRlz where

import A_Categorical.A_Signature.HaskSig (CatFunS (..), Cat2FunS (..))
import Data.Functor.Identity (Identity (..))
import qualified A_Categorical.D_Interpretation.Monads.Dist as M
import qualified A_Categorical.D_Interpretation.Monads.Giry as M
import Control.Monad (join)

-- | Hask Realization: assigns concrete Haskell types to the
--   abstract names declared in HaskSig.

-- | Functor names realized as concrete Haskell monads.
instance CatFunS where
  type Ident = Identity
  type Dist = M.Dist
  type Giry = M.Giry

-- | Natural transformations for each declared functor.
instance Cat2FunS Identity where
  eta = Identity
  mu  = runIdentity

instance Cat2FunS M.Dist where
  eta = return
  mu  = join

instance Cat2FunS M.Giry where
  eta = return
  mu  = join
