{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE NoStarIsType #-}

module A_Categorical.B_Theory.StarTheory
  ( StarTheory (..),
  )
where

import Data.Kind (Type)

-- | Higher-Order Categorical Theory Sum_alpha
--
-- The three monad roles correspond to the three paradigms of NeSyCat:
--   MonadSetTh  -- set theory
--   MonadMeasTh -- measure / probability theory
--   MonadGeomTh -- geometry / differential geometry
--
-- Natural transformations (eta, mu) are already given by Haskell's Monad class.
class StarTheory where
  -- | Set theory monad.
  type MonadSetTh :: Type -> Type

  -- | Measure theory monad.
  type MonadMeasTh :: Type -> Type

  -- | Geometry monad.
  type MonadGeomTh :: Type -> Type
