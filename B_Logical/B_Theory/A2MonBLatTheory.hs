{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module B_Logical.B_Theory.A2MonBLatTheory where

import A_Categorical.B_Theory.StarTheory (Framework (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import Data.Kind (Type)

-- | Theory of an aggregated 2-monoid bounded lattice (A2Mon-BLat).
--   Quantifiers are monadic: they take a Kleisli predicate (a -> M frmwk tau)
--   and return M frmwk tau. The monad comes from the framework.
--   For Identity monad (FrmwkGeom), this is pure computation.
--   For Dist (FrmwkMeas), this is the Kleisli lift (commutator + fold).
class
  (TwoMonBLatTheory frmwk tau, Framework frmwk, Monad (M frmwk)) =>
  A2MonBLatTheory a frmwk tau
  where
  type Dom a :: Type
  bigWedge :: ParamsLogic tau -> Dom a -> (a -> M frmwk tau) -> M frmwk tau
  bigVee :: ParamsLogic tau -> Dom a -> (a -> M frmwk tau) -> M frmwk tau
  bigOplus :: Dom a -> (a -> M frmwk tau) -> M frmwk tau
  bigOtimes :: Dom a -> (a -> M frmwk tau) -> M frmwk tau
