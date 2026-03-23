{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module B_Logical.B_Theory.A2MonBLatTheory
  ( A2MonBLatTheory (..),
    Guard,
  )
where

import A_Categorical.B_Theory.StarTheory (Framework (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import Data.Kind (Type)

-- | Guard: the subset that a guarded quantifier ranges over.
--   Indexed by framework and element type.
--   FrmwkMeas: Guard = [a]  (finite subset as a list)
--   FrmwkGeom: Guard = Torch.Tensor  (batch tensor)
type family Guard frmwk a :: Type

-- | Theory of an aggregated 2-monoid bounded lattice (A2Mon-BLat).
--   Guarded quantifiers: given a pointwise predicate (a -> M frmwk tau)
class
  (TwoMonBLatTheory frmwk tau, Framework frmwk, Monad (M frmwk)) =>
  A2MonBLatTheory a frmwk tau
  where
  bigWedge :: ParamsLogic tau -> Guard frmwk a -> (a -> M frmwk tau) -> M frmwk tau
  bigVee :: ParamsLogic tau -> Guard frmwk a -> (a -> M frmwk tau) -> M frmwk tau
  bigOplus :: Guard frmwk a -> (a -> M frmwk tau) -> M frmwk tau
  bigOtimes :: Guard frmwk a -> (a -> M frmwk tau) -> M frmwk tau
