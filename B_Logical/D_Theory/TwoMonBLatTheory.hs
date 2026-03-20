module B_Logical.D_Theory.TwoMonBLatTheory where

-- | Theory of a double monoid bounded lattice (2Mon-BLat), still without axioms.
class TwoMonBLatTheory tau where
  -- Comparison:
  vdash :: tau -> tau -> Bool

  -- Bounded Lattice:
  -- Join Lattice:
  vee :: tau -> tau -> tau
  bot :: tau

  -- Meet Lattice:
  wedge :: tau -> tau -> tau
  top :: tau

  -- Negation:
  neg :: tau -> tau

  -- Implication:
  implies :: tau -> tau -> tau

  -- Monoids:
  -- Monoid 1:
  oplus :: tau -> tau -> tau
  v0 :: tau

  -- Monoid 2:
  otimes :: tau -> tau -> tau
  v1 :: tau
