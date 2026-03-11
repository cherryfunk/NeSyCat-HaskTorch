{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}

module A_Categorical.C_Vocabulary.CatVocab where

import Data.Functor.Identity (Identity)
import Data.Kind (Type)

-- | Categorical Vocabulary κ
--
-- Enumerates the available categorical symbols.
-- At the α-level, every Haskell type (kind Type) is an object of Hask,
-- so CatObjT is trivial. The interesting vocabulary is CatFunT:
-- which type constructors (functors/monads) are available.

-- ============================================================
--  CatObjT: the object type of Hask is just Type (the kind)
-- ============================================================

-- | Every Haskell type is an object of Hask.
--   This is trivially universal — no enumeration needed.
--   Specific sublayers (DATA_Vocab, TENS_Vocab) restrict further.
class CatObjT (a :: Type)

-- ============================================================
--  CatFunT: available functor/monad symbols (1-cells)
-- ============================================================

-- | Marker: f is a valid functor/monad symbol C → C.
class CatFunT (f :: Type -> Type)

instance CatFunT Identity   -- id functor / trivial monad
instance CatFunT Maybe      -- partial monad
instance CatFunT []         -- list / nondeterminism monad
-- Dist is defined in D_Interpretation/Monads/, add here when needed
