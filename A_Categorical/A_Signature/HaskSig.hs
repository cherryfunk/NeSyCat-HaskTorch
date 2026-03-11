{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module A_Categorical.A_Signature.HaskSig where

import Data.Kind (Type)

-- | Higher-Order Categorical Signature Σ_α
--
-- This is the signature of the 2-category Cat.
-- At the α-level, the ambient category Hask is implicit,
-- so there is no 'cat' parameter (unlike BinarySig at the γ-level).
--
--   CatFunS:  functor names                     (1-cell names)
--   Cat2FunS: natural transformation names      (2-cell names)


-- ============================================================
--  CatFunS: Functor Names (1-cells)
-- ============================================================

-- | Abstract functor names.
--   Annotated as Type -> Type, which equals Obj -> Obj
--   since the object sort of Hask is simply Type.
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

-- | Abstract name for natural transformation names.
class Cat2FunS where
  -- | η: abstract name for monadic unit (return).
  eta :: Monad m => a -> m a
  -- | μ: abstract name for monadic multiplication (join).
  mu  :: Monad m => m (m a) -> m a
