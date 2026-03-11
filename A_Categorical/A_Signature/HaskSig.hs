{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.A_Signature.HaskSig where

-- | Categorical Signature Σ_α for the Hask category.
--
-- The α-layer defines the ambient category (always Hask, implicit).
-- Following the 2-categorical view of Cat:
--
--   0-cells (sorts)         → CatObjS
--   1-cells (functors)      → CatFunS
--   2-cells (nat. transf.)  → Cat2FunS
--
-- These are abstract NAMES only (pure syntax).
-- The vocabulary (HaskVocab) provides the real Haskell kinds.

-- ============================================================
--  CatObjS: Sort Symbols (0-cells)
-- ============================================================

-- | Abstract name for the object sort.
--   Just a name — realized as Data.Kind.Type in HaskVocab.
class CatObjS (a :: k)

-- ============================================================
--  CatFunS: Function Symbols (1-cells / endofunctors)
-- ============================================================

-- | Abstract name for functor symbols.
--   Just a name — the vocabulary lists the real functors.
class CatFunS (f :: k)

-- ============================================================
--  Cat2FunS: Natural Transformation Symbols (2-cells)
-- ============================================================

-- | Abstract name for 2-cell symbols (natural transformations).
--   η, μ, etc. — just names at the signature level.
class Cat2FunS (f :: k)
