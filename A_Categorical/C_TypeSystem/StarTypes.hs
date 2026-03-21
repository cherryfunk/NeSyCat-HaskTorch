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

-- | CatFunTyp: categorical function types (type constructors)
class CatFunTyp (f :: k)

instance CatFunTyp () -- terminal constant type constructor

instance CatFunTyp Void -- initial constant type constructor

-- Endofunctor/Monad symbols: Type -> Type
instance {-# OVERLAPPABLE #-} (Monad m) => CatFunTyp m

-- Bi-endofunctor symbols: (Type, Type) -> Type  (curried as Type -> Type -> Type)
instance CatFunTyp (,) -- product type constructor

instance CatFunTyp Either -- coproduct type constructor

instance CatFunTyp (->) -- exponential type constructor

-- | CatRelTyp: categorical relation types (type-level predicates)
--   The dualizing object in Star is Constraint.
class CatRelTyp (r :: k)

-- Unary relations on types: Type -> Constraint (type classes)
instance CatRelTyp Eq

instance CatRelTyp Ord

instance CatRelTyp Num

instance CatRelTyp Integral

instance CatRelTyp RealFloat

instance CatRelTyp Bounded
