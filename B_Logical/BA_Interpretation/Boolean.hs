{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeApplications #-}
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

import A_Categorical.DA_Realization.Dist (Dist)
import C_Domain.C_TypeSystem.Data (DATA)
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

-- | Boolean quantifiers for Bool + Dist (Kleisli)
instance A2MonBLatTheory Bool DATA Bool Dist where
  type Domain Bool = [Bool]
  bigWedge _ domain phi = do
    omegas <- mapM phi domain
    return (and omegas)
  bigVee _ domain phi = do
    omegas <- mapM phi domain
    return (or omegas)
  bigOplus domain phi = bigVee @Bool @DATA @Bool @Dist () domain phi
  bigOtimes domain phi = bigWedge @Bool @DATA @Bool @Dist () domain phi

-- | Boolean quantifiers for (Float, Float) + Dist — training points
instance A2MonBLatTheory (Float, Float) DATA Bool Dist where
  type Domain (Float, Float) = [(Float, Float)]
  bigWedge _ domain phi = do
    omegas <- mapM phi domain
    return (and omegas)
  bigVee _ domain phi = do
    omegas <- mapM phi domain
    return (or omegas)
  bigOplus domain phi = bigVee @(Float,Float) @DATA @Bool @Dist () domain phi
  bigOtimes domain phi = bigWedge @(Float,Float) @DATA @Bool @Dist () domain phi

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
