{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.A_Signature.CatSig where

import Data.Kind (Type)

-- | Categorical Signature Σ_α for the NeSyCat framework.
--
-- The α-layer defines the ambient category Hask and its structure.
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

-- | CatSortS: the category symbol.
--   'Type' (from Data.Kind) is the category symbol C.
--   Its interpretation is Hask.
type C = Type

-- ============================================================
--  CatFunS: Functor Symbols (1-cells in Cat)
-- ============================================================

-- | CatFunS: declares functor symbols available in Cat.
--   These are endofunctors C → C (Type → Type).
--
--   Structural functors:
--     Identity  — id functor
--     (->)      — Hom / exponential
--     (,)       — product ⊗
--     Either    — coproduct ⊕
--     ()        — terminal object ⊤ (as a nullary functor / constant)
--     Void      — initial object ⊥ (as a nullary functor / constant)
--
--   Monad functors (endofunctors with η, μ):
--     []        — list monad
--     Maybe     — partial monad
--     Dist      — distribution monad (Giry)
--     Identity  — trivial monad (Kl(Identity) ≅ Hask)
class CatFunS (f :: k)

-- ============================================================
--  Cat2FunS: Natural Transformation Symbols (2-cells in Cat)
-- ============================================================

-- | Cat2FunS: declares 2-cell symbols — natural transformations.
--   For each monad M, the 2-cells are:
--     η : Id ⇒ M    (unit / return)
--     μ : M∘M ⇒ M   (multiplication / join)
--
--   Abstract declarations only; implementations in D_Interpretation/.
class (CatFunS m) => Cat2FunS (m :: Type -> Type) where
  -- | η: unit of the monad (return)
  eta :: a -> m a
  -- | μ: multiplication of the monad (join)
  mu  :: m (m a) -> m a
