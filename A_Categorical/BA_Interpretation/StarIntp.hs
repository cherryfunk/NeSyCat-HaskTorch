{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

-- | Star interpretation: assigns concrete monads and categories
--   to the abstract roles declared in StarTheory.
--
--   Also provides the two concrete universes:
--     GeomU : geometry paradigm (tensors + Identity)
--     MeasU : measure theory paradigm (data + Dist)
module A_Categorical.BA_Interpretation.StarIntp
  ( GeomU,
    MeasU,
  )
where

import A_Categorical.B_Theory.StarTheory (Universe (..))
import qualified A_Categorical.D_Vocabulary.StarVocab as StarVocab
import C_Domain.C_TypeSystem.Data (DataObj)
import C_Domain.C_TypeSystem.Tens (TensObj)
import Data.Functor.Identity (Identity)

-- | Geometry paradigm: tensors + Identity monad.
data GeomU

-- | Measure theory paradigm: data types + Dist monad.
data MeasU

instance Universe GeomU where
  type Cat GeomU = TensObj
  type M GeomU = Identity

instance Universe MeasU where
  type Cat MeasU = DataObj
  type M MeasU = StarVocab.Dist

