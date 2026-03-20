{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- | Logical interpretation: Real-valued Logic ($\Omega = \mathbb{R}$)
module B_Logical.F_Interpretation.Real where

import B_Logical.D_Theory.A2MonBLatTheory (A2MonBLatTheory (..))
import B_Logical.D_Theory.TwoMonBLatTheory (TwoMonBLatTheory (..))
import A_Categorical.F_Interpretation.Monads.Giry (Giry (..))
import C_Domain.A_Category.Data (DATA (..))
import C_Domain.F_Interpretation.Supremum (enumAll, inf, sup)
import A_Categorical.F_Interpretation.Monads.Expectation (HasExpectation (..))
import Numeric.Natural (Natural)

infix 4 .==, ./=, .<, .>, .<=, .>=

-- | \$\Omega := \mathcal{I}(\tau) = \mathbb{R}$ (approximated by IEEE 754 Double)
type Omega = Double

instance TwoMonBLatTheory Omega where
  -- \| \$\mathcal{I}(\vdash)$ : Comparison
  vdash = (<=)

  -- \| \$\mathcal{I}(\wedge)$ : Meet
  wedge = min

  -- \| \$\mathcal{I}(\vee)$ : Join
  vee = max

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
  implies a b = vee (neg a) b

------------------------------------------------------
-- Quantifiers ($Q_a :: (a \to \Omega) \to \Omega$)
------------------------------------------------------

instance A2MonBLatTheory DATA Omega where
  -- \| \$\mathcal{I}(\bigvee)$ : Supremum
  bigVee d _mu _guard = sup d

  -- \| \$\mathcal{I}(\bigwedge)$ : Infimum
  bigWedge d _mu _guard = inf d

  -- \| \$\mathcal{I}(\bigoplus)$ : Infinitary Sum = $\mathbb{E}_\mu[\varphi]$ (integral w.r.t.\ chosen measure)
  --   The measure μ is now an EXPLICIT parameter (Giry a), not hardcoded.
  bigOplus obj mu _guard phi = expect obj mu phi

  -- \| \$\mathcal{I}(\bigotimes)$ : Infinitary Product = $\exp(\mathbb{E}_\mu[\log \circ \varphi])$ (product integral)
  bigOtimes obj mu _guard phi = exp (expect obj mu (log . phi))

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
