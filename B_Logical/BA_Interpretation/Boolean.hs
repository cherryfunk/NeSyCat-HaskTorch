{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

-- | Logical interpretation: Classical Boolean Logic ($\Omega = \{\text{True}, \text{False}\}$)
--
--   This module provides the interpretation of TwoMonBLatTheory and A2MonBLatTheory
--   in the FrmwkMeas framework with Omega = Bool.
module B_Logical.BA_Interpretation.Boolean
  ( Omega,
    -- * Re-exported typeclass interface
    module B_Logical.B_Theory.TwoMonBLatTheory,
    module B_Logical.B_Theory.A2MonBLatTheory,
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

import A_Categorical.BA_Interpretation.StarIntp (FrmwkMeas)
import A_Categorical.DA_Realization.Dist ()  -- Monad instance for Dist
import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))

import C_Domain.BA_Interpretation.Supremum (EnumAll (..))

infix 4 .==, ./=, .<, .>, .<=, .>=

-- | Omega := I(tau) = {True, False}
type Omega = Bool

------------------------------------------------------
-- TwoMonBLatTheory instance: Boolean lattice operations
------------------------------------------------------

instance TwoMonBLatTheory FrmwkMeas Bool where
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

-- | Boolean quantifiers for Bool (FrmwkMeas: Mon = Dist)
instance A2MonBLatTheory Bool FrmwkMeas Bool where
  type Domain Bool = [Bool]
  bigWedge _ domain phi = do
    omegas <- mapM phi domain
    return (and omegas)
  bigVee _ domain phi = do
    omegas <- mapM phi domain
    return (or omegas)
  bigOplus domain phi = bigVee () domain phi
  bigOtimes domain phi = bigWedge () domain phi

-- | Boolean quantifiers for (Float, Float) -- training points
instance A2MonBLatTheory (Float, Float) FrmwkMeas Bool where
  type Domain (Float, Float) = [(Float, Float)]
  bigWedge _ domain phi = do
    omegas <- mapM phi domain
    return (and omegas)
  bigVee _ domain phi = do
    omegas <- mapM phi domain
    return (or omegas)
  bigOplus domain phi = bigVee () domain phi
  bigOtimes domain phi = bigWedge () domain phi

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
