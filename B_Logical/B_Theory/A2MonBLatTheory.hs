{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module B_Logical.B_Theory.A2MonBLatTheory where

import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))

-- | Theory of an aggregated 2-monoid bounded lattice (A2Mon-BLat).
--   Quantifiers are indexed by the domain type a.
--   Domain a is the representation of the domain to quantify over
--   (list for finite, tensor for batched, etc.).
class (TwoMonBLatTheory dom tau) => A2MonBLatTheory a dom tau where
  type Domain a :: *
  bigWedge  :: ParamsLogic tau -> Domain a -> (a -> tau) -> tau
  bigVee    :: ParamsLogic tau -> Domain a -> (a -> tau) -> tau
  bigOplus  :: Domain a -> (a -> tau) -> tau
  bigOtimes :: Domain a -> (a -> tau) -> tau
