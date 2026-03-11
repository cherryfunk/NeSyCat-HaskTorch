{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.A_Signature.CatSig where

import Data.Kind (Type)

-- | Categorical Signature Σ_α for the NeSyCat framework.
--
-- The α-layer defines the ambient category and its structure.
-- Following the 2-categorical view of Cat:
--
--   0-cells = categories           → CatSortS
--   1-cells = functors             → CatFunS
--   2-cells = natural transforms   → Cat2FunS
--
-- This module declares abstract SYMBOLS only.
-- Concrete interpretations live in D_Interpretation/.

-- ============================================================
--  CatSortS: Sort Symbols (0-cells)
-- ============================================================

-- | CatSortS: sort symbols for the categorical layer.
--   Declares the sort Obj (objects of the category).
--   Instances (B_Realization/) assign concrete types.
class CatSortS (cat :: Type -> Type) where
  type Obj cat :: Type  -- sort: objects of the category

-- ============================================================
--  CatFunS: Function Symbols (1-cells / endofunctors)
-- ============================================================

-- | CatFunS: plain function symbols of the categorical layer.
--   These are 1-morphisms (endofunctors C → C).
--   Instances live in D_Interpretation/.
class (CatSortS cat) => CatFunS (cat :: Type -> Type) where
  ident :: cat a -> a              -- Id: unwrap (identity functor counit)

-- ============================================================
--  Cat2FunS: Natural Transformation Symbols (2-cells in Cat)
-- ============================================================

-- | Cat2FunS: 2-cell symbols — natural transformations.
--   For each monad M, the 2-cells are:
--     η : Id ⇒ M    (unit / return)
--     μ : M∘M ⇒ M   (multiplication / join)
--
--   Abstract declarations only; implementations in D_Interpretation/.
class (CatFunS m) => Cat2FunS (m :: Type -> Type) where
  eta :: a -> m a                  -- η: unit of the monad
  mu  :: m (m a) -> m a           -- μ: multiplication of the monad
