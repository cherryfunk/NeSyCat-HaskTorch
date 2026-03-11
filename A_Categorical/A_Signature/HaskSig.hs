{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module A_Categorical.A_Signature.HaskSig where

import Data.Kind (Type)

-- | Higher-Order Categorical Signature Σ_α
--
-- This is the signature of the 2-category Hask.
-- In Haskell, the ambient category Hask is the only choice,
-- so there is no 'cat' parameter (unlike BinarySig at the γ-level).
--
--   CatObjS:  category name                     (0-cell name)
--   CatFunS:  functor names                     (1-cell names)
--   Cat2FunS: natural transformation names      (2-cell names)

-- ============================================================
--  CatObjS: Object Sort (0-cells)
-- ============================================================

-- | The abstract name for the category is 'Type'.
--   Since the name coincides with Haskell's built-in kind 'Type',
--   and also because otherwise we'd run into type resolution errors,
--   we cannot (and need not) redeclare it. It is listed here
--   to preserve the structure of the signature:
--
--   class CatObjS where
--     type Type :: Kind

-- ============================================================
--  CatFunS: Functor Names (1-cells)
-- ============================================================

class CatFunS where
  -- | Abstract name for the identity monad.
  type Ident :: Type -> Type
  -- | Abstract name for the distribution monad.
  type Dist :: Type -> Type
  -- | Abstract name for the Giry monad.
  type Giry :: Type -> Type

-- ============================================================
--  Cat2FunS: Natural Transformation Names (2-cells)
-- ============================================================

-- | Abstract natural transformation names, parameterized by an
--   endofunctor declared in CatFunS (e.g. Ident, Dist, Giry).
class Cat2FunS (m :: Type -> Type) where
  -- | η: abstract name for monadic unit (return).
  eta :: a -> m a
  -- | μ: abstract name for monadic multiplication (join).
  mu  :: m (m a) -> m a
