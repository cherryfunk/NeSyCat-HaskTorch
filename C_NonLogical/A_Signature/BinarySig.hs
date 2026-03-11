{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

{- HLINT ignore "Use camelCase" -}

module C_NonLogical.A_Signature.BinarySig where

import Data.Kind (Type)

-- | Non-Logical Signature Σ_γ for the Binary Classification domain.
--
-- Sorts = {Point, Omega, M}
-- Funs  = {classifierA : Point → M(Omega),
--          labelA      : Point → M(Omega)}
--
-- Additionally, Θ (parameter space) parameterizes the interpretation I_θ

-- | BinarySorts: assigns abstract sort names to concrete Haskell types,
--   plus the parameter space Θ of the parameterized interpretation.
--   Instances live in B_Realization/.
class BinarySorts (cat :: Type -> Type) where
  type Point cat :: Type -- sort: input data point (e.g. ℝ²)
  type Omega cat :: Type -- sort: truth value (e.g. Bool, [0,1])
  type M cat :: Type -> Type -- sort: computational context (monad)
  type Params cat :: Type -- !!! WIP: NOT SURE YET IF THIS IS THE RIGHT PLACE FOR THIS

-- | BinaryFuns: interprets the function symbols classifierA and labelA.
--   Requires BinarySorts. Instances live in D_Interpretation/.
class (BinarySorts cat) => BinaryFuns (cat :: Type -> Type) where
  classifierA :: Params cat -> Point cat -> (M cat) (Omega cat)
  labelA :: Point cat -> (M cat) (Omega cat)

-- | Bridge for encoding/decoding between two category interpretations.
--   Only requires BinarySorts: encPoint/decOmega use only sort assignments.
class (BinarySorts from, BinarySorts to) => Binary_Bridge (from :: Type -> Type) (to :: Type -> Type) where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> (M from) (Omega from)
