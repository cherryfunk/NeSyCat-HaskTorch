{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoStarIsType #-}

-- | Haskell signature realization: assigns concrete Haskell types to the
--   abstract names declared in HaskSig.
module A_Categorical.B_Realization.HaskRlz where

import A_Categorical.A_Signature.HaskSig (CatFunS (..))
import qualified A_Categorical.C_Vocabulary.HaskVocab as V
import Data.Functor.Identity (Identity)
import qualified A_Categorical.D_Interpretation.Monads.Giry as M

-- ============================================================
--  CatObjS: Object Types (0-cells)
-- ============================================================

-- instance CatObjS where
--   type Type = Type

-- ============================================================
--  CatFunS: Functor Types (1-cells)
-- ============================================================

instance CatFunS where
  type Ident = Identity
  type Dist  = V.Dist
  type Giry  = M.Giry
