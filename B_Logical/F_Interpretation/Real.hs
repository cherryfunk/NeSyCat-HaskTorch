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
  bigVee d _guard = sup d

  -- \| \$\mathcal{I}(\bigwedge)$ : Infimum
  bigWedge d _guard = inf d

  -- \| \$\mathcal{I}(\bigoplus)$ : Infinitary Sum = $\mathbb{E}_\mu[\varphi]$ (integral w.r.t.\ canonical measure)
  --   Each quantifier chooses its density per domain type (uniform for finite, etc.)
  bigOplus Reals _guard phi = expect Reals (Uniform 0.0 1.0) phi
  bigOplus (Finite xs) _guard phi = expect (Finite xs) (DisUniform xs) phi
  bigOplus Booleans _guard phi = expect Booleans (DisUniform [True, False]) phi
  bigOplus (Prod d1 d2) _guard phi =
    bigOplus d1 (\_ -> top) (\a -> bigOplus d2 (\_ -> top) (\b -> phi (a, b)))
  bigOplus Naturals _guard phi = expect Naturals (fmap fromIntegral (Geometric 0.5)) phi
  bigOplus d _ _ = error $ "bigOplus: no density chosen for this domain"

  -- \| \$\mathcal{I}(\bigotimes)$ : Infinitary Product = $\exp(\mathbb{E}_\mu[\log \circ \varphi])$ (product integral)
  bigOtimes obj _guard phi = exp (bigOplus obj _guard (log . phi))

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
