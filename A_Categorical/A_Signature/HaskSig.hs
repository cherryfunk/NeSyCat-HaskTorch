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
--   hierarchy. Since GHC 8.0, Haskell uses the "Type in Type" axiom, meaning
--   the type of 'Type' is just 'Type' (Type : Type). We introduce this 'Kind'
--   synonym to conceptually distinguish the level of our signature's Object sort.
type Kind = Type

-- | Higher-Order Categorical Signature Σ_α
--
-- This is the signature of the 2-category Cat.
-- At the α-level, the ambient category Hask is implicit,
-- so there is no 'cat' parameter (unlike BinarySig at the γ-level).
--
--   CatObjS:  category names                  (0-cell names)
--   CatFunS:  functor names                   (1-cell names)
--   Cat2FunS: natural transformation names    (2-cell names)


-- ============================================================
--  CatObjS: Category Names (0-cells)
-- ============================================================

-- | Abstract name for the object sort.
class CatObjS where
  type Obj :: Kind


-- ============================================================
--  CatFunS: Functor Names (1-cells)
-- ============================================================
-- | Abstract name for functor names.
class CatObjS => CatFunS where
  -- | Abstract name for the identity functor.
  type Ident :: Obj -> Obj
  -- | Abstract name for the discrete distribution functor.
  type Dist :: Obj -> Obj
  -- | Abstract name for the continuous (or general) distribution functor.
  type Giry :: Obj -> Obj


-- ============================================================
--  Cat2FunS: Natural Transformation Names (2-cells)
-- ============================================================

-- | Abstract name for natural transformation names.
class Cat2FunS where
  -- | η: abstract name for monadic unit (return).
  eta :: Monad m => a -> m a
  -- | μ: abstract name for monadic multiplication (join).
  mu  :: Monad m => m (m a) -> m a
