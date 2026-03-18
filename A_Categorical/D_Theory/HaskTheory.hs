{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.D_Theory.HaskTheory where

import Data.Kind (Type)

-- | Higher-Order Categorical Theory Σ_alpha
--
-- This is the theory of the 2-category Hask.
-- In Haskell, the ambient category Hask is the only choice,
-- so there is no 'cat' parameter (unlike BinaryTheory at the gamma-level).
--
--   CatObjS:  category name                     (0-cell name)
--   CatFunTheory:  functor names                     (1-cell names)
--   Cat2FunTheory: natural transformation names      (2-cell names)

-- | The abstract name for the category is 'Type'.
--   The name coincides with Haskell's built-in kind 'Type',
--   otherwise we'd run into type resolution errors.
--
--   class CatObjS where
--     type Type :: Kind

-- | Functor Names (1-cells)
class CatFunTheory where
  -- | Abstract name for the identity monad.
  type Ident :: Type -> Type

  -- | Abstract name for the distribution monad.
  type Dist :: Type -> Type

  -- | Abstract name for the Giry monad.
  type Giry :: Type -> Type

-- | Abstract natural transformation names, parameterized by an
--   endofunctor declared in CatFunTheory (e.g. Ident, Dist, Giry).
class Cat2FunTheory (m :: Type -> Type) where
  -- | eta: abstract name for monadic unit (return).
  eta :: a -> m a

  -- | mu: abstract name for monadic multiplication (join).
  mu :: m (m a) -> m a
