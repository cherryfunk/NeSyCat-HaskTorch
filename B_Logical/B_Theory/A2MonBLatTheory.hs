{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module B_Logical.B_Theory.A2MonBLatTheory where

import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import Data.Kind (Type)

-- | Theory of an aggregated 2-monoid bounded lattice (A2Mon-BLat).
--   Quantifiers are monadic: they take a Kleisli predicate (a -> m tau)
--   and return m tau. For Identity monad, this is just pure computation.
--   For Dist, this is the Kleisli lift (commutator + fold).
class (TwoMonBLatTheory dom tau, Monad m) => A2MonBLatTheory a dom tau m where
  type Domain a :: Type
  bigWedge  :: ParamsLogic tau -> Domain a -> (a -> m tau) -> m tau
  bigVee    :: ParamsLogic tau -> Domain a -> (a -> m tau) -> m tau
  bigOplus  :: Domain a -> (a -> m tau) -> m tau
  bigOtimes :: Domain a -> (a -> m tau) -> m tau
