{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.A_Signature.HaskSig where

import Data.Kind (Type)

-- | Categorical Signature Σ_α for the Hask category.
--
-- The α-layer defines the ambient category (always Hask, implicit).
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

-- | Abstract name for the object sort.
class CatObjS (a :: k)

-- | The object sort symbol, realized as the Haskell kind Type.
type Obj = Type

-- ============================================================
--  CatFunS: Function Symbols (1-cells / endofunctors)
-- ============================================================

-- | Abstract name for functor symbols.
class CatFunS (f :: k)

-- | ident: unwrapping symbol (counit of Identity).
--   Declared here as a name; interpreted in D_Interpretation.
class CatFunS f => CatFunSig (f :: Type -> Type) where
  ident :: f a -> a

-- ============================================================
--  Cat2FunS: Natural Transformation Symbols (2-cells)
-- ============================================================

-- | Abstract name for 2-cell symbols (natural transformations).
class CatFunS m => Cat2FunS (m :: Type -> Type) where
  -- | η: unit of the monad (return)
  eta :: a -> m a
  -- | μ: multiplication of the monad (join)
  mu  :: m (m a) -> m a
