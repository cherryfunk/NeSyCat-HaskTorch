{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Logical interpretation: Real-valued Logic ($\Omega = \mathbb{R}$)
module B_Logical.BA_Interpretation.Real where

import C_Domain.C_TypeSystem.Data (DATA)
import B_Logical.B_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.B_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import A_Categorical.DA_Realization.Giry (Giry (..))
import Numeric.Natural (Natural)

import C_Domain.BA_Interpretation.Supremum (HasSup (..), HasInf (..))
import B_Logical.DA_Realization.ExpectGiry (HasExpectGiry (..))

infix 4 .==, ./=, .<, .>, .<=, .>=

-- | \$\Omega := \mathcal{I}(\tau) = \mathbb{R}$ (approximated by IEEE 754 Double)
type Omega = Double

instance TwoMonBLatTheory DATA Omega where
  type ParamsLogic Omega = ()

  -- \| \$\mathcal{I}(\vdash)$ : Comparison
  vdash = (<=)

  -- \| \$\mathcal{I}(\vee)$ : Join
  vee _ = max

  -- \| \$\mathcal{I}(\wedge)$ : Meet
  wedge _ = min

  -- \| \$\mathcal{I}(\bot)$ : Bottom
  bot = -1.0 / 0.0

  -- \| \$\mathcal{I}(\top)$ : Top
  top = 1.0 / 0.0

  -- \| \I(+) : Additive monoid
  oplus = (+)

  -- \| \I(*) : Multiplicative monoid
  otimes = (*)

  -- \| \$\mathcal{I}(\vec{0})$ : Additive unit
  v0 = 0.0

  -- \| \$\mathcal{I}(\vec{1})$ : Multiplicative unit
  v1 = 1.0
  neg x = -x
  implies _ a b = vee () (neg a) b

------------------------------------------------------
-- Quantifiers ($Q_a :: (a \to \Omega) \to \Omega$)
------------------------------------------------------

-- Per-type quantifier instances for real-valued logic:

instance A2MonBLatTheory Double DATA Omega where
  type Domain Double = ()  -- continuous: domain is implicit (R)
  bigVee _ _ phi = sup phi
  bigWedge _ _ phi = inf phi
  bigOplus _ phi = expectGiry (Uniform 0.0 1.0) phi
  bigOtimes _ phi = exp (bigOplus @Double @DATA @Omega () (log . phi))

instance A2MonBLatTheory Bool DATA Omega where
  type Domain Bool = [Bool]
  bigVee _ domain phi = sup phi
  bigWedge _ domain phi = inf phi
  bigOplus domain phi = expectGiry (GFinUniform domain) phi
  bigOtimes domain phi = exp (bigOplus @Bool @DATA @Omega domain (log . phi))

instance A2MonBLatTheory Natural DATA Omega where
  type Domain Natural = ()  -- countable: domain is implicit (N)
  bigVee _ _ phi = sup phi
  bigWedge _ _ phi = inf phi
  bigOplus _ phi = expectGiry (fmap fromIntegral (Geometric 0.5)) phi
  bigOtimes _ phi = exp (bigOplus @Natural @DATA @Omega () (log . phi))

instance A2MonBLatTheory () DATA Omega where
  type Domain () = [()]
  bigVee _ domain phi = phi ()
  bigWedge _ domain phi = phi ()
  bigOplus domain phi = phi ()
  bigOtimes domain phi = phi ()

------------------------------------------------------
-- General predicates
------------------------------------------------------

(.==) :: (Eq a) => a -> a -> Omega
x .== y = if x == y then top else bot

(.<) :: (Ord a) => a -> a -> Omega
x .< y = if x < y then top else bot

(.>) :: (Ord a) => a -> a -> Omega
x .> y = if x > y then top else bot

(.<=) :: (Ord a) => a -> a -> Omega
x .<= y = if x <= y then top else bot

(.>=) :: (Ord a) => a -> a -> Omega
x .>= y = if x >= y then top else bot

(./=) :: (Eq a) => a -> a -> Omega
x ./= y = if x /= y then top else bot

b2o :: Bool -> Omega
b2o b = if b then top else bot
