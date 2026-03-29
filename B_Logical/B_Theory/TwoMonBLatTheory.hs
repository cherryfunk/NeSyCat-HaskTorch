{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module B_Logical.B_Theory.TwoMonBLatTheory where

import Data.Kind (Type)

-- | Theory of a double monoid bounded lattice (2Mon-BLat), still without axioms.
--   Parameterized by the universe (u) and truth value type (tau).
--   The fundep tau -> u encodes that objects in different categories are
--   genuinely different: Bool in Set vs Bool in Meas are distinct objects
--   even if they share the same underlying elements. To reuse a type
--   across universes, use newtypes (e.g. newtype SetBool = SetBool Bool).
class TwoMonBLatTheory u tau | tau -> u where
  vdash :: tau -> tau -> Bool

  vee :: ParamsLogic tau -> tau -> tau -> tau
  bot :: tau

  wedge :: ParamsLogic tau -> tau -> tau -> tau
  top :: tau

  neg :: tau -> tau

  implies :: ParamsLogic tau -> tau -> tau -> tau

  oplus :: tau -> tau -> tau
  v0 :: tau

  otimes :: tau -> tau -> tau
  v1 :: tau

  -- \| Logic parameters (Para morphism parameter space).
  --   Default: () (no parameters, e.g. classical real-valued logic).
  type ParamsLogic tau :: Type
  type ParamsLogic tau = ()

  -- Default implementations (De Morgan):
  default wedge :: ParamsLogic tau -> tau -> tau -> tau
  wedge lp a b = neg (vee lp (neg a) (neg b))

  default implies :: ParamsLogic tau -> tau -> tau -> tau
  implies lp a b = vee lp (neg a) b
