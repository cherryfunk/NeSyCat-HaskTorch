{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.B_Realization.HaskRlz where

import A_Categorical.A_Signature.HaskSig (CatFunS (..))
import Data.Functor.Identity (Identity)
import qualified A_Categorical.D_Interpretation.Monads.Dist as M
import qualified A_Categorical.D_Interpretation.Monads.Giry as M

-- | Hask Realization: assigns concrete Haskell types to the
--   abstract names declared in HaskSig.

-- | Functor names realized as concrete Haskell monads.
instance CatFunS where
  type Ident = Identity
  type Dist = M.Dist
  type Giry = M.Giry
