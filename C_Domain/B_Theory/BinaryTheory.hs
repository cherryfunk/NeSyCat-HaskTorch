{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}


module C_Domain.B_Theory.BinaryTheory where

import Data.Kind (Type)
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)

-- | Non-Logical Theory Sigma_gamma for the Binary Classification domain.
--
-- Sorts  = {Point, Omega, M}
-- Fun    = {labelA : Point -> Omega}
-- KlFun  = {classifierA : Theta -> Point -> M(Omega)}
--
-- The parameter Theta (= ParamsMLP) is external to the domain category:
-- it lives in the tensor parameter space (Para), not as a sort.
-- It is curried into the signature as a fixed type.

-- | BinarySorts: assigns abstract sort names to concrete Haskell types.
class BinarySorts (cat :: Type -> Type) where
  type Point cat :: Type         -- sort: input data point (e.g. R^2)
  type Omega cat :: Type         -- sort: truth value (e.g. Bool, [0,1])
  type M cat :: Type -> Type     -- monad M defining the Kleisli category Kl(M)

-- | BinaryFun: plain (deterministic) function symbols.
class (BinarySorts cat) => BinaryFun (cat :: Type -> Type) where
  labelA :: Point cat -> Omega cat

-- | BinaryKlFun: Kleisli function symbols (morphisms in Kl(M)).
--   The parameter ParamsMLP is external (from Para), not a sort.
class (BinaryFun cat) => BinaryKlFun (cat :: Type -> Type) where
  classifierA :: ParamsMLP -> Point cat -> (M cat) (Omega cat)

-- | Bridge for encoding/decoding between two category interpretations.
--   Only requires BinarySorts: encPoint/decOmega use only sort assignments.
class (BinarySorts from, BinarySorts to) => BinaryBridge (from :: Type -> Type) (to :: Type -> Type) where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> (M from) (Omega from)
