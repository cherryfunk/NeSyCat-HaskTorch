{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

{- HLINT ignore "Use camelCase" -}

module C_NonLogical.A_Signature.BinarySig where

import Data.Kind (Type)

-- | Non-Logical Signature Σ for the Binary Classification domain.
--
-- Sorts  = {Point, Omega, M}
-- Funs   = {classifierA : Params × Point → M Omega,
--           labelA      : Point → M Omega}

-- | Layer 1 — BinarySorts: assigns abstract sort names to Haskell types.
--   Instances live in B_Realization/.
--   Params is NOT a sort; it is interpretation-specific and lives in BinarySig.
class BinarySorts (cat :: Type -> Type) where
  -- | The sort of a single data example
  type Point cat :: Type
  -- | The sort of truth values
  type Omega cat :: Type
  -- | The computational context (effect monad)
  type M     cat :: Type -> Type

-- | Layer 2 — BinarySig: function interpretation + Params type.
--   Requires BinarySorts. Instances live in D_Interpretation/.
class BinarySorts cat => BinarySig (cat :: Type -> Type) where
  -- | Parameter type for classifierA (e.g., neural network weights).
  --   Interpretation-specific: Real uses BinaryRealMLP, Uniform uses BinaryUniformMLP.
  type Params cat :: Type
  -- | Predicate A: trainable classifier
  classifierA :: Params cat -> Point cat -> (M cat) (Omega cat)
  -- | Ground truth label: computable predicate
  labelA :: Point cat -> (M cat) (Omega cat)

-- | Bridge for encoding/decoding between categories.
class (BinarySig from, BinarySig to) => Binary_Bridge (from :: Type -> Type) (to :: Type -> Type) where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> (M from) (Omega from)
