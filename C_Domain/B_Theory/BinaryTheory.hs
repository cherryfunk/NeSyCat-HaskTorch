{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module C_Domain.B_Theory.BinaryTheory where

import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP)
import Data.Kind (Type)

-- | Non-Logical Theory Sigma_gamma for the Binary Classification domain.
--
-- Sorts  = {Point, Omega}
-- Fun    = {labelA : Point -> Omega}
-- KlFun  = {classifierA : Theta -> Point -> m(Omega)}
--
-- The monad m is NOT a sort -- it is a categorical-level choice (from StarTheory).
-- The parameter Theta (= ParamsMLP) is external (from Para), curried in.
-- Both m and Theta are separate axes from the type system (cat).

-- | BinarySorts: assigns sort names to concrete Haskell types.
class BinarySorts (cat :: Type -> Type) where
  type Point cat :: Type -- sort: input data point (e.g. R^2)
  type Omega cat :: Type -- sort: truth value (e.g. Bool, [0,1])

-- | BinaryFun: plain (deterministic) function symbols.
class (BinarySorts cat) => BinaryFun (cat :: Type -> Type) where
  labelA :: Point cat -> Omega cat

-- | BinaryKlFun: Kleisli function symbols (morphisms in Kl(m)).
--   Parameterized by both the type system (cat) and the monad (m).
class (BinaryFun cat, Monad m) => BinaryKlFun (cat :: Type -> Type) (m :: Type -> Type) where
  classifierA :: ParamsMLP -> Point cat -> m (Omega cat)

-- | Bridge for encoding/decoding between two type system interpretations.
--   The monad m is the target monad for decoding (e.g. Dist for DATA).
class
  (BinarySorts from, BinarySorts to) =>
  BinaryBridge
    (from :: Type -> Type)
    (to :: Type -> Type)
    (m :: Type -> Type)
  where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> m (Omega from)
