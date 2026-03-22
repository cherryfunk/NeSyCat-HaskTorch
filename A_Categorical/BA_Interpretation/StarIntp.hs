{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

-- | Star interpretation: assigns concrete monads and categories
--   to the abstract roles declared in StarTheory.
module A_Categorical.BA_Interpretation.StarIntp () where

import A_Categorical.B_Theory.StarTheory (StarTheory (..))
import qualified A_Categorical.D_Vocabulary.StarVocab as StarVocab
import C_Domain.C_TypeSystem.Data (DataObj)
import Data.Functor.Identity (Identity)

-- | The three semantic frameworks:
--     Set theory:     (Identity, DataObj)
--     Measure theory: (Dist,     DataObj)
--     Geometry:       (Identity, TensObj)  -- TensObj TODO
instance StarTheory where
  type MonadSetTh  = Identity
  type MonadMeasTh = StarVocab.Dist
  type MonadGeomTh = Identity
  type CatSetTh    = DataObj
  type CatMeasTh   = DataObj
  type CatGeomTh   = DataObj  -- TODO: TensObj when TENS GADT is replaced
