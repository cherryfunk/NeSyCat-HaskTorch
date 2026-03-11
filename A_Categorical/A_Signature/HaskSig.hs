{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.A_Signature.HaskSig where

import Data.Kind (Type)

-- | Categorical Signature Σ_α for the Hask category.
--
-- The α-layer defines the ambient category (always Hask).
-- Following the 2-categorical view of Cat:
--
--   0-cells (sorts)         → CatObjS
--   1-cells (functors)      → CatFunS
--   2-cells (nat. transf.)  → Cat2FunS
--
-- These are abstract NAMES (pure syntax).
-- The vocabulary (HaskVocab) provides the real Haskell kinds.

-- ============================================================
--  CatObjS: Sort Symbols (0-cells)
-- ============================================================

-- | Object sort symbols.
class CatObjS (cat :: Type -> Type) where
  type Obj cat :: Type

-- ============================================================
--  CatFunS: Function Symbols (1-cells)
-- ============================================================

-- | Functor function symbols.
class (CatObjS cat) => CatFunS (cat :: Type -> Type) where
  ident :: cat a -> a

-- ============================================================
--  Cat2FunS: Natural Transformation Symbols (2-cells)
-- ============================================================

-- | 2-cell symbols (natural transformations).
class (CatFunS m) => Cat2FunS (m :: Type -> Type) where
  eta :: a -> m a
  mu  :: m (m a) -> m a
