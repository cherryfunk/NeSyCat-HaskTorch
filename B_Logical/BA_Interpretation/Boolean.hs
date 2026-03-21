{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}

-- | Logical interpretation: Classical Boolean Logic ($\Omega = \{\text{True}, \text{False}\}$)
--
--   This module provides the interpretation of TwoMonBLatTheory and A2MonBLatTheory
--   in the DATA category with Omega = Bool.
module B_Logical.BA_Interpretation.Boolean
  ( Omega,
    -- * Re-exported typeclass interface
    module B_Logical.B_Theory.TwoMonBLatTheory,
    module B_Logical.B_Theory.A2MonBLatTheory,
    -- * Monadic quantifier helpers
    bigWedgeM,
    bigVeeM,
    -- * Comparison predicates
    (.==),
    (./=),
    (.<),
    (.>),
    (.<=),
    (.>=),
    b2o,
  )
where

import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))

import C_Domain.BA_Interpretation.Supremum (EnumAll (..))

infix 4 .==, ./=, .<, .>, .<=, .>=

-- | Omega := I(tau) = {True, False}
type Omega = Bool

------------------------------------------------------
-- TwoMonBLatTheory instance: Boolean lattice operations
------------------------------------------------------

instance TwoMonBLatTheory DATA Bool where
  type ParamsLogic Bool = ()
  vdash = (<=)
  vee _ = (||)
  wedge _ = (&&)
  bot = False
  top = True
  neg = not
  implies _ a b = not a || b
  oplus = (||)
  otimes = (&&)
  v0 = False
  v1 = True

------------------------------------------------------
-- A2MonBLatTheory instance: quantifiers over DATA domains
------------------------------------------------------

instance A2MonBLatTheory DATA Bool where
  bigVee _ d _guard phi = any phi (enumAll)
  bigWedge _ d _guard phi = all phi (enumAll)
  bigOplus d _guard phi = any phi (enumAll)
  bigOtimes d _guard phi = all phi (enumAll)

------------------------------------------------------
-- Monadic quantifier helpers
------------------------------------------------------

-- | Monadic lift: $\bigwedge$ for predicates returning in a monad
bigWedgeM :: (Monad m) => DATA a -> (a -> m Omega) -> m Omega
bigWedgeM d phi = do
  omegas <- mapM phi (enumAll)
  return (and omegas)

-- | Monadic lift: $\bigvee$ for predicates returning in a monad
bigVeeM :: (Monad m) => DATA a -> (a -> m Omega) -> m Omega
bigVeeM d phi = do
  omegas <- mapM phi (enumAll)
  return (or omegas)

------------------------------------------------------
-- Comparison predicates
------------------------------------------------------

(.==) :: (Eq a) => a -> a -> Omega
x .== y = x == y

(.<) :: (Ord a) => a -> a -> Omega
x .< y = x < y

(.>) :: (Ord a) => a -> a -> Omega
x .> y = x > y

(.<=) :: (Ord a) => a -> a -> Omega
x .<= y = x <= y

(.>=) :: (Ord a) => a -> a -> Omega
x .>= y = x >= y

(./=) :: (Eq a) => a -> a -> Omega
x ./= y = x /= y

b2o :: Bool -> Omega
b2o = id
