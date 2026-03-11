{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE DataKinds #-}

module A_Categorical.B_Realization.HaskRlz where

import A_Categorical.A_Signature.HaskSig (CatObjS (..), CatFunS (..))
import Data.Kind (Type)
import Data.Functor.Identity (Identity)
import qualified A_Categorical.D_Interpretation.Monads.Dist as M
import qualified A_Categorical.D_Interpretation.Monads.Giry as M

-- | Hask Realization: assigns concrete Haskell kinds to the
--   abstract sort symbols declared in HaskSig.
--
--   The single realization: Obj is realized as the kind Type.
--   Objects of Hask = Haskell types of kind Type.
instance CatObjS where
  type Obj = Type

-- | Realization of functor names to actual Functors/Monads in Hask.
instance CatFunS where
  type Ident = Identity
  type Dist = M.Dist
  type Giry = M.Giry
  type Dist = M.Dist
  type Giry = M.Giry
