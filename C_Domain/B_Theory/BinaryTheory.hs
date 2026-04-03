{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module C_Domain.B_Theory.BinaryTheory where

import A_Categorical.B_Theory.StarTheory (Universe (..))
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import Data.Kind (Type)

-- | Non-Logical Theory Sigma_gamma for the Binary Classification domain.
--
-- Sorts  = {Point, Omega}
-- Rel    = {labelA : Point -> Omega}          (Tarski relation)
-- KlRel  = {classifierA : Theta -> Point -> M(Omega)}  (Kleisli relation)
--
-- The monad comes from the universe (M u).
-- The parameter Theta (= ParamsMLP) is external (from Para), curried in.

-- | BinarySorts: assigns sort names to concrete Haskell types.
class (Universe u) => BinarySorts u where
  type Point u :: Type
  type Omega u :: Type

class (BinarySorts u) => BinaryRel u where
  labelA :: Point u -> Omega u

class (BinaryRel u, Monad (M u)) => BinaryKlRel u where
  classifierA :: ParamsMLP -> Point u -> M u (Omega u)

-- | Bridge for encoding/decoding between two universe interpretations.
class (BinarySorts from, BinarySorts to) => BinaryBridge from to where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> M from (Omega from)
