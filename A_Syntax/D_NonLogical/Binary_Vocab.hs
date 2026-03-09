{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

{- HLINT ignore "Use camelCase" -}

module A_Syntax.D_NonLogical.Binary_Vocab where

import Data.Kind (Type)

-- | Non-Logical Vocabulary Σ for the Binary Classification domain.
--
-- Sor = {Point}
-- Fun = {A : Point → Truth}
class Binary_Vocab (cat :: Type -> Type) where
  -- | The sort representing a single data example (e.g., a 2D coordinate)
  type Point cat :: Type

  -- | The sort representing the truth value -- should be always instantiated with the respective Omega from the logical vocabulary
  type Omega cat :: Type

  -- | The computational context (effect monad)
  type M cat :: Type -> Type

  -- | The parameters required to evaluate predicates (e.g., neural network weights)
  type Params cat :: Type

  -- | Predicate A: The trainable classifier mapping a point to its truth value
  classifierA :: Params cat -> Point cat -> (M cat) (Omega cat)

  -- | Ground truth label: a computable predicate (NOT empirical data)
  labelA :: Point cat -> (M cat) (Omega cat)

-- | Bridge for mapping domains between categories (e.g., DATA -> TENS)
class (Binary_Vocab from, Binary_Vocab to) => Binary_Bridge (from :: Type -> Type) (to :: Type -> Type) where
  encPoint :: Point from -> Point to

  -- | Decode the Truth Value tensor probabilities back into the mathematical distribution model
  decOmega :: Omega to -> (M from) (Omega from)
