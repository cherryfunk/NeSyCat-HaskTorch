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
class CatObjT a

instance CatObjT ()       -- terminal object ⊤
instance CatObjT Void     -- initial object ⊥
instance CatObjT Bool
instance CatObjT Float
instance CatObjT Double
instance (CatObjT a, CatObjT b) => CatObjT (a, b)   -- product
instance (CatObjT a, CatObjT b) => CatObjT (Either a b)  -- coproduct

-- ============================================================
--  CatFunT: available functor/monad symbols (1-cells)
-- ============================================================

-- | Marker: f is a valid functor/monad symbol C → C.
class CatFunT (f :: Type -> Type)

instance CatFunT Identity   -- id functor / trivial monad
instance CatFunT Maybe      -- partial monad
instance CatFunT []         -- list / nondeterminism monad
-- Dist is defined in D_Interpretation/Monads/, add here when needed
