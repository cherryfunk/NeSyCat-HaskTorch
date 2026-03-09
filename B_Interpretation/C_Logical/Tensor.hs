{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- | Logical interpretation: Tensor-valued Logic (Ω = R^1, a tensor space)
--   Analogous to Real.hs, but all operations are on typed tensors.
module B_Interpretation.C_Logical.Tensor
  ( module B_Interpretation.C_Logical.Tensor,
    module A_Syntax.C_Logical.A2MonBLat,
    module A_Syntax.C_Logical.TwoMonBLat,
    module B_Interpretation.B_Typological.TENS,
  )
where

import A_Syntax.C_Logical.A2MonBLat
import A_Syntax.C_Logical.TwoMonBLat
import C_Semantics.A_Categorical.Monads.Giry (Giry (..))
import B_Interpretation.B_Typological.TENS (TENS (..))
import C_Semantics.A_Categorical.Monads.Expectation_TENS (expectTENS)
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Ω := I(τ) = R^1 (a tensor space)
type Omega = Tensor '( 'CPU, 0) 'Float '[1]

-- ============================================================
--  TwoMonBLat: Binary Logical Operations on Omega
-- ============================================================

instance TwoMonBLat Omega where
  vdash a b = Torch.asValue (toDynamic a) <= (Torch.asValue (toDynamic b) :: Float)

  -- | p-Mean conjunction (De Morgan dual of vee):
  --   wedge(a, b) = ¬(vee(¬a, ¬b)) = 1 - ((  (1-a)^p + (1-b)^p  ) / 2)^{1/p}
  --   This IS LTN's pMeanError formula aggregation.
  wedge a b = neg (vee (neg a) (neg b))

  -- | p-Mean disjunction (primitive):
  --   vee(a, b) = ((a^p + b^p) / 2)^{1/p}
  --   with pi_0 stability: clamp inputs away from 0 to prevent gradient death.
  --   This makes the De Morgan wedge(a,b) = ¬vee(¬a,¬b) stable at x→1,
  --   matching LTNtorch's pi_1 clamping inside pMeanError.
  vee a b =
    let a' = toDynamic a; b' = toDynamic b
        ap = powP (pi0 a') -- pi_0 stability + fast square for p=2.0
        bp = powP (pi0 b')
        meanP = (ap `Torch.add` bp) `Torch.mul` half
     in UnsafeMkTensor (powInvP meanP)


  bot = UnsafeMkTensor (Torch.asTensor [(-1.0 / 0.0) :: Float])
  top = UnsafeMkTensor (Torch.asTensor [(1.0 / 0.0) :: Float])
  oplus a b = UnsafeMkTensor (Torch.add (toDynamic a) (toDynamic b))
  otimes a b = UnsafeMkTensor (Torch.mul (toDynamic a) (toDynamic b))
  v0 = UnsafeMkTensor (Torch.asTensor [0.0 :: Float])
  v1 = UnsafeMkTensor (Torch.asTensor [1.0 :: Float])



-- | \mathcal{I}(\neg) : Negation
neg :: Omega -> Omega
neg a = UnsafeMkTensor (one `Torch.sub` toDynamic a)

-- | Fuzzy implication: a → b = max(1-a, b)
implies :: Omega -> Omega -> Omega
implies a b = vee (neg a) b


------------------------------------------------------
-- Guarded Quantifiers with explicit measure (A2MonBLat)
------------------------------------------------------

instance A2MonBLat TENS Omega where
  -- | Guarded ∀ with measure μ:  ∀_{x|g}^μ. φ(x) = ¬ ∃_{x|g}^μ. ¬φ(x)
  bigWedge :: TENS a -> Giry a -> (a -> Omega) -> (a -> Omega) -> Omega
  bigWedge dom mu guard phi = neg (bigVee dom mu guard (neg . phi))

  -- | Guarded ∃ with measure μ: conditional p-Mean.
  --   E_μ[ φ^p · 1_guard ] / E_μ[ 1_guard ]  raised to 1/p
  --
  --   This IS the conditional expectation under measure μ:
  --     bigVee dom μ guard φ  =  pMean_μ(φ | guard)
  bigVee :: TENS a -> Giry a -> (a -> Omega) -> (a -> Omega) -> Omega
  bigVee TensorSpace mu guard phi =
    let evals  = expectTENS TensorSpace mu (\x -> toDynamic (phi x))
        guards = expectTENS TensorSpace mu (\x -> toDynamic (guard x))
        evals_p  = powP (pi0 evals)  -- pi_0 stability: prevent gradient death at x=0
        weighted = guards `Torch.mul` evals_p
        sumW     = Torch.sumAll weighted
        sumG     = Torch.sumAll guards
        meanP    = sumW `Torch.div` (sumG `Torch.add` eps)
        rootP    = powInvP meanP
     in UnsafeMkTensor (Torch.reshape [1] rootP)
  bigVee TensProd {} _ _ _ = error "bigVee over TensProd not yet supported"
  bigVee TensUnit _ _ phi = phi ()

  bigOplus :: TENS a -> Giry a -> (a -> Omega) -> (a -> Omega) -> Omega
  bigOplus = error "bigOplus over TENS not yet supported"
  bigOtimes :: TENS a -> Giry a -> (a -> Omega) -> (a -> Omega) -> Omega
  bigOtimes = error "bigOtimes over TENS not yet supported"

-- | Fused ∀ quantifier operating on pre-computed guard and phi tensors.
--   Avoids re-evaluating the MLP and labelA through expectTENS lambdas.
--   bigWedgeDirect guard phi  =  1 − ( E[guard · (1−φ)^p] / E[guard] )^{1/p}
bigWedgeDirect :: Omega -> Omega -> Omega
bigWedgeDirect guardT phiT =
  let g  = toDynamic guardT
      e  = pi1 (toDynamic phiT)       -- pi_1 stability: prevent gradient death at x=1
      e' = one `Torch.sub` e          -- (1 − φ)
      ep = powP e'                     -- (1 − φ)^p
      w  = g `Torch.mul` ep            -- guard · (1−φ)^p
      sW = Torch.sumAll w
      sG = Torch.sumAll g
      meanP = sW `Torch.div` (sG `Torch.add` eps)
   in UnsafeMkTensor (Torch.reshape [1] (one `Torch.sub` powInvP meanP))

------------------------------------------------------
-- Gradient Stability Projections (matching LTN's stable=True)
------------------------------------------------------

-- | pi_0: maps [0,1] → (0, 1], prevents gradient death at x=0.
--   Matches LTNtorch: pi_0(x) = (1-eps_s)*x + eps_s
pi0 :: Torch.Tensor -> Torch.Tensor
pi0 x = (x `Torch.mul` stableScale) `Torch.add` stableEps

-- | pi_1: maps [0,1] → [0, 1), prevents gradient death at x=1.
--   Matches LTNtorch: pi_1(x) = (1-eps_s)*x
pi1 :: Torch.Tensor -> Torch.Tensor
pi1 x = x `Torch.mul` stableScale

{-# NOINLINE stableEps #-}
stableEps :: Torch.Tensor
stableEps = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0e-4 :: Float)

{-# NOINLINE stableScale #-}
stableScale :: Torch.Tensor
stableScale = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (0.9999 :: Float)

------------------------------------------------------
-- Internal Helper Constants & Parameters
------------------------------------------------------

-- | Scalar tensors pre-allocated on CPU to avoid FFI allocation overhead in hot loops
one :: Torch.Tensor
one = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0 :: Float)

half :: Torch.Tensor
half = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (0.5 :: Float)

eps :: Torch.Tensor
eps = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0e-8 :: Float)

-- | Logic Tensor Networks `p`-parameter for generalized p-Mean
ltnP :: Float
ltnP = 2.0

powP :: Torch.Tensor -> Torch.Tensor
powP t = Torch.mul t t

powInvP :: Torch.Tensor -> Torch.Tensor
powInvP t = Torch.sqrt t
