{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DefaultSignatures #-}

module B_Logical.B_Theory.TwoMonBLatTheory where

import Data.Kind (Type)

-- | Theory of a double monoid bounded lattice (2Mon-BLat), still without axioms.
--   Parameterized by the framework (frmwk) and truth value type (tau).
--   The functional dependency tau -> frmwk ensures each truth type
--   is interpreted in exactly one framework.
class TwoMonBLatTheory frmwk tau | tau -> frmwk where
  -- | Logic parameters (Para morphism parameter space).
  --   Default: () (no parameters, e.g. classical real-valued logic).
  type ParamsLogic tau :: Type
  type ParamsLogic tau = ()

  -- Comparison:
  vdash :: tau -> tau -> Bool

  -- Bounded Lattice:
  -- Join Lattice:
  vee :: ParamsLogic tau -> tau -> tau -> tau
  bot :: tau

  -- Meet Lattice:
  wedge :: ParamsLogic tau -> tau -> tau -> tau
  top :: tau

  -- Negation:
  neg :: tau -> tau

  -- Implication:
  implies :: ParamsLogic tau -> tau -> tau -> tau

  -- Monoids:
  -- Monoid 1:
  oplus :: tau -> tau -> tau
  v0 :: tau

  -- Monoid 2:
  otimes :: tau -> tau -> tau
  v1 :: tau

  -- Default implementations (De Morgan):
  default wedge :: ParamsLogic tau -> tau -> tau -> tau
  wedge lp a b = neg (vee lp (neg a) (neg b))

  default implies :: ParamsLogic tau -> tau -> tau -> tau
  implies lp a b = vee lp (neg a) b
