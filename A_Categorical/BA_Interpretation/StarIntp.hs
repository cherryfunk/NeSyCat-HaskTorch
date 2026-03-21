{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

-- | Star interpretation: assigns concrete Haskell types to the abstract
--   monad roles declared in StarTheory.
--   At the type level, this IS the interpretation — types are values here.
module A_Categorical.BA_Interpretation.StarIntp () where

import qualified A_Categorical.DA_Realization.Giry as M
import A_Categorical.B_Theory.StarTheory (StarTheory (..))
import qualified A_Categorical.D_Vocabulary.StarVocab as StarVocab
import Data.Functor.Identity (Identity)

-- | Type-level interpretation of StarTheory:
instance StarTheory where
  type MonadSetTh = Identity
  type MonadMeasTh = StarVocab.Dist
  type MonadGeomTh = M.Giry
