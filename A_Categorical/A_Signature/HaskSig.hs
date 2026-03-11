{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module A_Categorical.A_Signature.HaskSig where

import Data.Kind (Type)

-- | In dependently typed languages, there is an infinite tower of sorts 
--   (e.g., Type 0 : Type 1 : Type 2...). Haskell does not have this infinite
--   hierarchy. Since GHC 0.8, Haskell uses the "Type in Type" axiom, meaning
--   the type of 'Type' is just 'Type' (Type : Type). We introduce this 'Kind'
--   synonym to conceptually distinguish the level of our signature's Object sort.
type Kind = Type

-- | Higher-Order Categorical Signature Σ_α
--
-- This is the signature of the 2-category Cat.
-- At the α-level, the ambient category Hask is implicit,
-- so there is no 'cat' parameter (unlike BinarySig at the γ-level).
--
--   CatObjS:  sort symbols      (0-cells)
--   CatFunS:  function symbols  (1-cells)
--   Cat2FunS: 2-cell symbols    (natural transformations)

-- ============================================================
--  CatObjS: Sort Symbols (0-cells)
-- ============================================================

-- | Abstract name for the object sort.
class CatObjS where
  type Obj :: Kind

-- ============================================================
--  CatFunS: Function Symbols (1-cells)
-- ============================================================

-- | Abstract name for functor symbols.
class CatFunS where
  -- | Abstract name for the identity function.
  ident :: a -> a
--  Cat2FunS: Natural Transformation Symbols (2-cells)
-- ============================================================

-- | Abstract name for 2-cell symbols (natural transformations).
class Cat2FunS where
  -- | η: abstract name for monadic unit (return).
  eta :: Monad m => a -> m a
  -- | μ: abstract name for monadic multiplication (join).
  mu  :: Monad m => m (m a) -> m a
