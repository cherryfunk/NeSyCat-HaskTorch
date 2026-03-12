{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

{- HLINT ignore "Use camelCase" -}

module C_NonLogical.A_Signature.BinarySig where

import Data.Kind (Type)

-- | Non-Logical Signature Σ_gamma for the Binary Classification domain.
--
-- Sorts  = {Point, Omega}
-- Fun    = {labelA : Point -> Omega}            — plain (interpreted in C)
-- KlFun  = {classifierA : Point -> Omega}       — Kleisli (interpreted in Kl(M))
--
-- Additionally, Θ (parameter space) parameterizes the interpretation I_theta

-- | BinarySorts: assigns abstract sort names to concrete Haskell types.
--   Instances live in B_Realization/.
class BinarySorts (cat :: Type -> Type) where
  type Point cat :: Type         -- sort: input data point (e.g. ℝ²)
  type Omega cat :: Type         -- sort: truth value (e.g. Bool, [0,1])
  type M cat :: Type -> Type     -- monad M defining the Kleisli category Kl(M)
  type Params cat :: Type        -- Θ: parameter space of I_theta

-- | BinaryFunS: plain (deterministic) function symbols.
--   Interpreted as morphisms in C (not Kl(M)).
--   Instances live in D_Interpretation/.
class (BinarySorts cat) => BinaryFunS (cat :: Type -> Type) where
  labelA :: Point cat -> Omega cat

-- | BinaryKlFunS: Kleisli function symbols.
--   Interpreted as morphisms in Kl(M), i.e. A -> M(B) in Haskell.
--   Instances live in D_Interpretation/.
class (BinaryFunS cat) => BinaryKlFunS (cat :: Type -> Type) where
  classifierA :: Params cat -> Point cat -> (M cat) (Omega cat)

-- | Bridge for encoding/decoding between two category interpretations.
--   Only requires BinarySorts: encPoint/decOmega use only sort assignments.
class (BinarySorts from, BinarySorts to) => Binary_Bridge (from :: Type -> Type) (to :: Type -> Type) where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> (M from) (Omega from)
