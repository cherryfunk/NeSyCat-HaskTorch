{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}

-- | Logical interpretation: Classical Boolean Logic ($\Omega = \{\text{True}, \text{False}\}$)
--
--   This module provides the interpretation of TwoMonBLatTheory and A2MonBLatTheory
--   in the DATA category with Omega = Bool.
module B_Logical.F_Interpretation.Boolean
  ( Omega,
    -- * Re-exported typeclass interface
    module B_Logical.D_Theory.TwoMonBLatTheory,
    module B_Logical.D_Theory.A2MonBLatTheory,
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

import B_Logical.D_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.D_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import C_Domain.A_Category.Data (DATA (..))
import C_Domain.F_Interpretation.Supremum (enumAll)

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
  bigVee _ d _guard phi = any phi (enumAll d)
  bigWedge _ d _guard phi = all phi (enumAll d)
  bigOplus d _guard phi = any phi (enumAll d)
  bigOtimes d _guard phi = all phi (enumAll d)

------------------------------------------------------
-- Monadic quantifier helpers
------------------------------------------------------

-- | Monadic lift: $\bigwedge$ for predicates returning in a monad
bigWedgeM :: (Monad m) => DATA a -> (a -> m Omega) -> m Omega
bigWedgeM d phi = do
  omegas <- mapM phi (enumAll d)
  return (and omegas)

-- | Monadic lift: $\bigvee$ for predicates returning in a monad
bigVeeM :: (Monad m) => DATA a -> (a -> m Omega) -> m Omega
bigVeeM d phi = do
  omegas <- mapM phi (enumAll d)
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
