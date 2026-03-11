{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}

module A_Categorical.C_Vocabulary.CatVocab where

import Data.Functor.Identity (Identity)
import Data.Kind (Type)
import Data.Void (Void)

-- | Categorical Vocabulary κ
--
-- CatObjT — object types (tuple-kinds): Type, (Type,Type), ...
-- CatFunT — functor types: map between object types

-- ============================================================
--  CatObjT: object types (the kinds)
-- ============================================================

-- | The object types at the α-level are tuple-kinds.
class CatObjT (a :: k)

instance CatObjT () -- = 0-ary objects

instance CatObjT Type -- = 1-ary objects

instance CatObjT (Type, Type) -- = 2-ary objects (for bifunctor symbols)

-- ============================================================
--  CatFunT: functor types (1-cells mapping between object types)
-- ============================================================

-- | f is a valid functor symbol.
class CatFunT (f :: k)

-- Endofunctors: Type → Type
instance CatFunT Identity -- id functor

instance CatFunT Maybe -- partial

instance CatFunT [] -- list / nondeterminism

-- Bifunctors: (Type, Type) → Type  (curried as Type → Type → Type)
instance CatFunT (,) -- product ⊗

instance CatFunT Either -- coproduct ⊕

instance CatFunT (->) -- exponential / Hom

-- Constants (0-ary): Type
instance CatFunT () -- terminal object ⊤

instance CatFunT Void -- initial object ⊥
