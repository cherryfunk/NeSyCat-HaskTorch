{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}

module B_Logical.D_Theory.A2MonBLatTheory where

-- | Theory of an aggregated 2-monoid bounded lattice (A2Mon-BLat).
--   Extends 2Mon-BLat with four infinitary guarded quantifiers.
--   Each quantifier takes:
--     1. dom a   — the domain (object of the category)
--     2. guard   — subobject classifier (conditioning predicate)
--     3. phi     — the formula to quantify over
--   The density is canonical: chosen by the quantifier for each domain type,
--   not passed as a parameter.
class A2MonBLatTheory dom tau | tau -> dom where
  -- Infinitary Lattice (guarded):
  bigVee    :: forall a. dom a -> (a -> tau) -> (a -> tau) -> tau
  bigWedge  :: forall a. dom a -> (a -> tau) -> (a -> tau) -> tau

  -- Infinitary Monoids (guarded):
  bigOplus  :: forall a. dom a -> (a -> tau) -> (a -> tau) -> tau
  bigOtimes :: forall a. dom a -> (a -> tau) -> (a -> tau) -> tau
