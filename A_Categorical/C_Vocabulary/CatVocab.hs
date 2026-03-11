{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}

module A_Categorical.C_Vocabulary.CatVocab where

import Data.Functor.Identity (Identity)
import Data.Kind (Type)

-- | Categorical Vocabulary κ
--
-- The vocabulary at the α-level is minimal:
--   CatObjT — the single object type: Type (the Haskell kind)
--   CatFunT — which type constructors (functors/monads) are available

-- ============================================================
--  CatObjT: the object type is the kind Type
-- ============================================================

-- | At the categorical level, there is exactly one object type: Type.
--   Individual types (Bool, Float, ...) belong at lower-layer vocabularies
--   (DATA_Vocab, TENS_Vocab).
class CatObjT (a :: Type)

instance CatObjT Type  -- the kind Type is the single object type

-- ============================================================
--  CatFunT: available functor/monad symbols (1-cells)
-- ============================================================

-- | Marker: f is a valid functor/monad symbol C → C.
class CatFunT (f :: Type -> Type)

instance CatFunT Identity   -- id functor / trivial monad
instance CatFunT Maybe      -- partial monad
instance CatFunT []         -- list / nondeterminism monad
-- Dist is defined in D_Interpretation/Monads/, add here when needed
