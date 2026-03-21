{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module B_Logical.B_Theory.A2MonBLatTheory where

import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))

-- | Theory of an aggregated 2-monoid bounded lattice (A2Mon-BLat).
--   Parameterized by (a, dom, tau):
--     a   = what you quantify over (per-type dispatch, no dom a parameter)
--     dom = category tag (DATA, TENS)
--     tau = truth value type
class (TwoMonBLatTheory dom tau) => A2MonBLatTheory a dom tau where
  bigVee    :: ParamsLogic tau -> (a -> tau) -> (a -> tau) -> tau
  bigWedge  :: ParamsLogic tau -> (a -> tau) -> (a -> tau) -> tau
  bigOplus  :: (a -> tau) -> (a -> tau) -> tau
  bigOtimes :: (a -> tau) -> (a -> tau) -> tau
