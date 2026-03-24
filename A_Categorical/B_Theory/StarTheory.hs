{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.B_Theory.StarTheory
  ( StarTheory (..),
    Universe (..),
  )
where

import Data.Kind (Constraint, Type)

-- | Semantic Universe: a (category, monad) pair that determines
--   the entire interpretation pipeline.
--
--   Cat frmwk : Type -> Constraint  (which types are objects)
--   M frmwk   : Type -> Type        (the Kleisli monad)
class Universe frmwk where
  type Cat frmwk :: Type -> Constraint
  type M frmwk :: Type -> Type

-- | Higher-Order Categorical Theory Sum_alpha
--
-- Three paradigms, each with a monad and a category:
--   Set theory:     (MonadSetTh,  CatSetTh)
--   Measure theory: (MonadMeasTh, CatMeasTh)
--   Geometry:       (MonadGeomTh, CatGeomTh)
--
-- The monad determines the Kleisli structure.
-- The category (as a constraint) determines which types are objects.
class StarTheory where
  -- Monads
  type MonadSetTh  :: Type -> Type
  type MonadMeasTh :: Type -> Type
  type MonadGeomTh :: Type -> Type
  -- Categories (as object membership constraints)
  type CatSetTh    :: Type -> Constraint
  type CatMeasTh   :: Type -> Constraint
  type CatGeomTh   :: Type -> Constraint
