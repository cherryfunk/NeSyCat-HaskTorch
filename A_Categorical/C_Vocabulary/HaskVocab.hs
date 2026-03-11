{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE UndecidableInstances #-}

module A_Categorical.C_Vocabulary.HaskVocab where

import Data.Kind (Type)
import Data.Void (Void)

-- | Categorical Vocabulary κ
--
-- CatObjT — object types (tuple-kinds): (), Type, (Type,Type), ...
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

-- Endofunctor/Monad symbols: Type → Type
-- All Monads are automatically functor symbols.
instance {-# OVERLAPPABLE #-} (Monad m) => CatFunT m

-- Biendofunctor symbols: (Type, Type) → Type  (curried as Type → Type → Type)
instance CatFunT (,) -- product

instance CatFunT Either -- coproduct symbol

instance CatFunT (->) -- exponential / Hom symbol

-- Constant functor symbols (0-ary): Type (curried as simply Type)
instance CatFunT () -- terminal constant symbol

instance CatFunT Void -- initial constant symbol
