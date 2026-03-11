{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE RankNTypes #-}

module A_Categorical.A_Signature.HaskSig where

import Data.Kind (Type)

-- | Higher-order Categorical Signature Σ_α
--
-- This is the signature of the 2-category Cat.
-- At the α-level, the ambient category Hask is implicit,
-- so there is no 'cat' parameter (unlike BinarySig at the γ-level).
--
-- We declare abstract NAMES that will be interpreted in D_Interpretation.
--
--   CatObjS:  sort symbols      (0-cells)
--   CatFunS:  function symbols  (1-cells)
--   Cat2FunS: 2-cell symbols    (natural transformations)

-- ============================================================
--  CatObjS: Sort Symbols (0-cells)
-- ============================================================

-- | Obj: the sort of objects in Hask.
--   Realized as Data.Kind.Type.
type Obj = Type

-- ============================================================
--  CatFunS: Function Symbols (1-cells)
-- ============================================================

-- | ident: unwrapping from Identity.
--   Signature: Identity a → a
--   Interpretation (D_Interpretation): ident = runIdentity
ident :: forall f a. (forall x. f x -> x) -> f a -> a
ident unwrap = unwrap

-- ============================================================
--  Cat2FunS: Natural Transformation Symbols (2-cells)
-- ============================================================

-- | η: unit of a monad (return).
--   Signature: ∀a. a → m a
--   Interpretation: η = return
type Eta  m = forall a. a -> m a

-- | μ: multiplication of a monad (join).
--   Signature: ∀a. m (m a) → m a
--   Interpretation: μ = join
type Mu   m = forall a. m (m a) -> m a
