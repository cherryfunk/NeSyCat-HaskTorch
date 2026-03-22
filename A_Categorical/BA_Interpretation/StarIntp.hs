{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

-- | Star interpretation: assigns concrete monads and categories
--   to the abstract roles declared in StarTheory.
--
--   Also provides the two concrete frameworks:
--     FrmwkGeom : geometry paradigm (tensors + Identity)
--     FrmwkMeas : measure theory paradigm (data + Dist)
module A_Categorical.BA_Interpretation.StarIntp
  ( FrmwkGeom,
    FrmwkMeas,
  )
where

import A_Categorical.B_Theory.StarTheory (StarTheory (..), Framework (..))
import qualified A_Categorical.D_Vocabulary.StarVocab as StarVocab
import C_Domain.C_TypeSystem.Data (DataObj)
import Data.Functor.Identity (Identity)

-- | Geometry paradigm: tensors + Identity monad.
data FrmwkGeom

-- | Measure theory paradigm: data types + Dist monad.
data FrmwkMeas

instance Framework FrmwkGeom where
  type Cat FrmwkGeom = DataObj  -- TODO: TensObj when ready
  type M FrmwkGeom = Identity

instance Framework FrmwkMeas where
  type Cat FrmwkMeas = DataObj
  type M FrmwkMeas = StarVocab.Dist

-- | The three semantic frameworks (legacy StarTheory interface):
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
