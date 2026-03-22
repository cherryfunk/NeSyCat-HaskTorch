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
--   Quantifiers are monadic: they take a Kleisli predicate (a -> Mon frmwk tau)
--   and return Mon frmwk tau. The monad comes from the framework.
--   For Identity monad (FrmwkGeom), this is pure computation.
--   For Dist (FrmwkMeas), this is the Kleisli lift (commutator + fold).
class (TwoMonBLatTheory frmwk tau, Framework frmwk, Monad (Mon frmwk)) => A2MonBLatTheory a frmwk tau where
  type Domain a :: Type
  bigWedge  :: ParamsLogic tau -> Domain a -> (a -> Mon frmwk tau) -> Mon frmwk tau
  bigVee    :: ParamsLogic tau -> Domain a -> (a -> Mon frmwk tau) -> Mon frmwk tau
  bigOplus  :: Domain a -> (a -> Mon frmwk tau) -> Mon frmwk tau
  bigOtimes :: Domain a -> (a -> Mon frmwk tau) -> Mon frmwk tau
