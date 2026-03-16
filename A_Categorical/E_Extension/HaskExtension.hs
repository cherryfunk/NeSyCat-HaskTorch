{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoStarIsType #-}

-- | Haskell theory extension: assigns concrete Haskell types to the
--   abstract names declared in HaskTheory.
module A_Categorical.E_Extension.HaskExtension where

import A_Categorical.D_Theory.HaskTheory (CatFunTheory (..))
import qualified A_Categorical.B_Vocabulary.HaskVocab as HaskVocab
import Data.Functor.Identity (Identity)
import qualified A_Categorical.F_Interpretation.Monads.Giry as M

-- ============================================================
--  CatObjS: Object Types (0-cells)
-- ============================================================

-- instance CatObjS where
--   type Type = Type

-- ============================================================
--  CatFunTheory: Functor Types (1-cells)
-- ============================================================

instance CatFunTheory where
  type Ident = Identity
  type Dist  = HaskVocab.Dist
  type Giry  = M.Giry
