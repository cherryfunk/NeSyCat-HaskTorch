{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}

module A_Categorical.C_Vocabulary.CatVocab where

import Data.Functor.Identity (Identity)
import Data.Kind (Type)
import Data.Void (Void)

-- | Categorical Vocabulary κ
--
-- Enumerates the available categorical symbols.
-- Analogous to DataVocab (which types are valid DATA objects)
-- and TensVocab (which types are valid TENS objects),
-- CatVocab declares which type constructors are valid
-- functor/monad symbols in the system.

-- ============================================================
--  CatVocab: available sort symbols (types as objects of Hask)
-- ============================================================

-- | Marker: a is a valid object (type) in Hask.
class CatObjVocab a

instance CatObjVocab ()       -- terminal object ⊤
instance CatObjVocab Void     -- initial object ⊥
instance CatObjVocab Bool
instance CatObjVocab Float
instance CatObjVocab Double
instance (CatObjVocab a, CatObjVocab b) => CatObjVocab (a, b)   -- product
instance (CatObjVocab a, CatObjVocab b) => CatObjVocab (Either a b)  -- coproduct

-- ============================================================
--  CatFunVocab: available functor symbols (1-cells)
-- ============================================================

-- | Marker: f is a valid functor symbol C → C.
class CatFunVocab (f :: Type -> Type)

instance CatFunVocab Identity   -- id functor
instance CatFunVocab Maybe      -- partial functor
instance CatFunVocab []         -- list functor

-- ============================================================
--  CatMonadVocab: available monad symbols (functors with η, μ)
-- ============================================================

-- | Marker: m is a valid monad symbol (an endofunctor with unit + multiplication).
--   Every monad is also a functor.
class (CatFunVocab m) => CatMonadVocab (m :: Type -> Type)

instance CatMonadVocab Identity  -- trivial monad (Kl(Id) ≅ Hask)
instance CatMonadVocab Maybe     -- partial monad
instance CatMonadVocab []        -- list/nondeterminism monad
-- Dist is defined in D_Interpretation/Monads/, add here when needed
