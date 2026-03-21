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
  bigVee _ _guard phi = sup phi
  bigWedge _ _guard phi = inf phi
  bigOplus _guard phi = expectGiry (Uniform 0.0 1.0) phi
  bigOtimes _guard phi = exp (bigOplus @Double @DATA @Omega _guard (log . phi))

instance A2MonBLatTheory Bool DATA Omega where
  bigVee _ _guard phi = sup phi
  bigWedge _ _guard phi = inf phi
  bigOplus _guard phi = expectGiry (GFinUniform [True, False]) phi
  bigOtimes _guard phi = exp (bigOplus @Bool @DATA @Omega _guard (log . phi))

instance A2MonBLatTheory Natural DATA Omega where
  bigVee _ _guard phi = sup phi
  bigWedge _ _guard phi = inf phi
  bigOplus _guard phi = expectGiry (fmap fromIntegral (Geometric 0.5)) phi
  bigOtimes _guard phi = exp (bigOplus @Natural @DATA @Omega _guard (log . phi))

instance A2MonBLatTheory () DATA Omega where
  bigVee _ _guard phi = phi ()
  bigWedge _ _guard phi = phi ()
  bigOplus _guard phi = phi ()
  bigOtimes _guard phi = phi ()

instance (A2MonBLatTheory a DATA Omega, A2MonBLatTheory b DATA Omega) => A2MonBLatTheory (a, b) DATA Omega where
  bigVee lp _guard phi = bigVee @a @DATA @Omega lp (\_ -> top) (\a -> bigVee @b @DATA @Omega lp (\_ -> top) (\b -> phi (a, b)))
  bigWedge lp _guard phi = bigWedge @a @DATA @Omega lp (\_ -> top) (\a -> bigWedge @b @DATA @Omega lp (\_ -> top) (\b -> phi (a, b)))
  bigOplus _guard phi = bigOplus @a @DATA @Omega (\_ -> top) (\a -> bigOplus @b @DATA @Omega (\_ -> top) (\b -> phi (a, b)))
  bigOtimes _guard phi = exp (bigOplus @(a,b) @DATA @Omega (\_ -> top) (log . phi))

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
