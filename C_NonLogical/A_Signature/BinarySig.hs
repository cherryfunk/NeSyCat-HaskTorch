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
-- (Def. parameterized-interpretation). It is not a sort of Σ_γ
-- but is associated with the category for Haskell's type system.

-- | BinarySorts: assigns abstract sort names to concrete Haskell types,
--   plus the parameter space Θ of the parameterized interpretation.
--   Instances live in B_Realization/.
class BinarySorts (cat :: Type -> Type) where
  type Point  cat :: Type          -- sort: input data point (e.g. ℝ²)
  type Omega  cat :: Type          -- sort: truth value (e.g. Bool, [0,1])
  type M      cat :: Type -> Type  -- sort: computational context (monad)
  type Params cat :: Type          -- Θ: parameter space of I_θ (not a sort of Σ_γ)

-- | BinaryFuns: interprets the function symbols classifierA and labelA.
--   Requires BinarySorts. Instances live in D_Interpretation/.
class BinarySorts cat => BinaryFuns (cat :: Type -> Type) where
  classifierA :: Params cat -> Point cat -> (M cat) (Omega cat)
  labelA      :: Point cat -> (M cat) (Omega cat)

-- | Bridge for encoding/decoding between two category interpretations.
class (BinaryFuns from, BinaryFuns to) => Binary_Bridge (from :: Type -> Type) (to :: Type -> Type) where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> (M from) (Omega from)
