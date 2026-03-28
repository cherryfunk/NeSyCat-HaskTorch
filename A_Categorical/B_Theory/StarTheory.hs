{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.B_Theory.StarTheory
  ( Universe (..),
  )
where

import Data.Kind (Constraint, Type)

-- | Semantic Universe: a (category, monad) pair that determines
-- the entire interpretation pipeline.
--
-- Cat u : Type -> Constraint  (which types are objects)
-- M u   : Type -> Type        (the Kleisli monad)
class Universe u where
  type Cat u :: Type -> Constraint
  type M u :: Type -> Type
