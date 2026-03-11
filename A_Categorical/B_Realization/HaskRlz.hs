{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module A_Categorical.B_Realization.HaskRlz where

import A_Categorical.A_Signature.HaskSig (CatObjS (..))
import Data.Kind (Type)

-- | Hask Realization: assigns concrete Haskell kinds to the
--   abstract sort symbols declared in HaskSig.
--
--   The single realization: Obj is realized as the kind Type.
--   Objects of Hask = Haskell types of kind Type.
instance CatObjS where
  type Obj = Type
