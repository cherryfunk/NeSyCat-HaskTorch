{-# LANGUAGE NoStarIsType #-}

module A_Categorical.A_Signature.HaskSig where

-- | Higher-Order Categorical Signature Σ_α
--
-- This is the signature of the 2-category Cat.
-- It declares abstract NAMES only (pure syntax).
-- No realizations, no implementations.
--
--   CatObjS:  sort symbols      (0-cells)
--   CatFunS:  function symbols  (1-cells)
--   Cat2FunS: 2-cell symbols    (natural transformations)
--
-- Realizations: HaskRlz.hs  (Obj → Type, ident → runIdentity, ...)
-- Vocabulary:   HaskVocab.hs (which monads/functors are available)

-- ============================================================
--  CatObjS: Sort Symbols (0-cells)
-- ============================================================

-- | Obj: abstract name for "object of the category".
--   Realized in HaskRlz as Data.Kind.Type.
data Obj

-- ============================================================
--  CatFunS: Function Symbols (1-cells)
-- ============================================================

-- | Ident: abstract name for the identity unwrapping.
--   Realized in HaskRlz as runIdentity :: Identity a → a.
data Ident

-- ============================================================
--  Cat2FunS: Natural Transformation Symbols (2-cells)
-- ============================================================

-- | Eta: abstract name for monadic unit (η).
--   Realized in HaskRlz as return :: a → m a.
data Eta

-- | Mu: abstract name for monadic multiplication (μ).
--   Realized in HaskRlz as join :: m (m a) → m a.
data Mu
