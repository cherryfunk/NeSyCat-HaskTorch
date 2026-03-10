{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}

module A_Syntax.B_Logical.A2MonBLat where

import C_Semantics.A_Categorical.Monads.Giry (Giry)

-- | Theory of an aggregated 2-monoid bounded lattice (A2Mon-BLat).
--   Extends 2Mon-BLat with four infinitary guarded quantifiers.
--   Each quantifier takes:
--     1. dom a   — the domain (object of the category)
--     2. Giry a  — the probability measure on the domain
--     3. guard   — subobject classifier (conditioning predicate)
--     4. phi     — the formula to quantify over
class A2MonBLat dom tau | tau -> dom where
  -- Infinitary Lattice (guarded, measure-parameterized):
  bigVee    :: forall a. dom a -> Giry a -> (a -> tau) -> (a -> tau) -> tau
  bigWedge  :: forall a. dom a -> Giry a -> (a -> tau) -> (a -> tau) -> tau

  -- Infinitary Monoids (guarded, measure-parameterized):
  bigOplus  :: forall a. dom a -> Giry a -> (a -> tau) -> (a -> tau) -> tau
  bigOtimes :: forall a. dom a -> Giry a -> (a -> tau) -> (a -> tau) -> tau
