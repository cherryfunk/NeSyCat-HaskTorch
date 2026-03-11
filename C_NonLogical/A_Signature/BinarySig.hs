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

-- | Layer B_Realization — BinarySorts: assigns abstract sort names to concrete Haskell types.
--   Instances live in B_Realization/.
class BinarySorts (cat :: Type -> Type) where
  type Point cat :: Type          -- sort: input data point (e.g. ℝ²)
  type Omega cat :: Type          -- sort: truth value (e.g. Bool, [0,1])
  type M     cat :: Type -> Type  -- sort: computational context (monad)

-- | Layer D_Interpretation — BinaryFuns: interprets the function symbols classifierA and labelA.
--   Requires BinarySorts (sort assignment must be given first).
--   Instances live in D_Interpretation/.
--
--   Note: `Params` is not a sort or function symbol from the abstract signature;
--   it is an implementation parameter needed to express the type of classifierA in Haskell.
class BinarySorts cat => BinaryFuns (cat :: Type -> Type) where
  type Params cat :: Type
  classifierA :: Params cat -> Point cat -> (M cat) (Omega cat)
  labelA      :: Point cat -> (M cat) (Omega cat)

-- | Bridge for encoding/decoding between two category interpretations.
class (BinaryFuns from, BinaryFuns to) => Binary_Bridge (from :: Type -> Type) (to :: Type -> Type) where
  encPoint :: Point from -> Point to
  decOmega :: Omega to -> (M from) (Omega from)
