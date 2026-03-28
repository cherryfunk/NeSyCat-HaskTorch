{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Star type system: picks which Haskell kinds, type constructors,
--   and type-level predicates we work with.
module A_Categorical.C_TypeSystem.StarTypes where

import Data.Kind (Type)
import Data.Void (Void)

-- | CatObjTyp: categorical object types (the object kinds)
class CatObjTyp (o :: k)

instance CatObjTyp () -- = 0-ary object kind

instance CatObjTyp Type -- = 1-ary object kind

instance CatObjTyp (Type, Type) -- = 2-ary object kind

class CatFunTyp (f :: k)

instance {-# OVERLAPPABLE #-} (Monad m) => CatFunTyp m

instance CatFunTyp (,) -- product

instance CatFunTyp (->) -- exponential

class CatRelTyp (r :: k)

instance CatRelTyp Eq

instance CatRelTyp Ord

instance CatRelTyp Num
