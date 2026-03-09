{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- | Logic on the REAL LINE (ℝ) — PARAMETERIZED by β.
--
--   Identical to TensReal, but every smooth connective takes β explicitly
--   rather than using a hardcoded constant.  This enables:
--
--     • Joint optimization of β + θ
--     • β-only optimization (θ frozen)
--     • Hyperparameter sweeps
--     • Inductive / sampling-based β learning (future)
--
--   β controls the LogSumExp sharpness:
--     vee(a, b)  = (1/β) · logaddexp(β·a, β·b)
--     wedge(a,b) = ¬vee(¬a, ¬b)
--     ∃ = logsumexp with β scaling
--     ∀ = De Morgan dual of ∃
module B_Interpretation.C_Logical.TensRealBeta
  ( BatchOmega,

    -- * TwoMonBLat-R-β: Binary Logical Operations (β-parameterized)
    veeRBeta,
    wedgeRBeta,

    -- * A2MonBLat-R-β: Quantifiers (β-parameterized)
    bigVeeRBeta,
    bigWedgeRBeta,

    -- * Non-parameterized operations (re-exported from TensReal)
    vdashR,
    botR,
    topR,
    oplusR,
    otimesR,
    v0R,
    v1R,
    negR,
    impliesRBeta,

    -- * Re-exports from Tensor.hs (for scalar Omega operations)
    module B_Interpretation.C_Logical.Tensor,
  )
where

import B_Interpretation.C_Logical.Tensor
import B_Interpretation.C_Logical.TensReal
  ( BatchOmega,
    botR,
    negR,
    oplusR,
    otimesR,
    topR,
    v0R,
    v1R,
    vdashR,
  )
import qualified Torch
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- ============================================================
--  TwoMonBLat-R-β: pointwise batch operations, β-parameterized
-- ============================================================

-- | Disjunction (∨ = smooth max), parameterized by β:
--   vee_β(a, b) = (1/β) · logaddexp(β·a, β·b)
veeRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> BatchOmega
veeRBeta betaT a b =
  let pa = a `Torch.mul` betaT
      pb = b `Torch.mul` betaT
   in F.logaddexp pa pb `Torch.div` betaT

-- | Conjunction (∧ = smooth min), parameterized by β:
--   wedge_β(a, b) = ¬vee_β(¬a, ¬b)
wedgeRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> BatchOmega
wedgeRBeta betaT a b = negR (veeRBeta betaT (negR a) (negR b))

-- | Implication parameterized by β: (a → b) = vee_β(¬a, b)
impliesRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> BatchOmega
impliesRBeta betaT a b = veeRBeta betaT (negR a) b

-- ============================================================
--  A2MonBLat-R-β: quantifiers, β-parameterized
-- ============================================================

-- | Guarded ∃ over finite uniform measure, parameterized by β:
--
--   ∃_{x|g}^{unif,β} φ  =  (1/β) · logsumexp(β·φ + log(g)) − log(Σg)
bigVeeRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> Omega
bigVeeRBeta betaT g phi =
  let eps = epsLikeBeta g
      logG = Torch.log (g `Torch.add` eps)
      pphi = (phi `Torch.mul` betaT) `Torch.add` logG
      lse = F.logsumexp pphi 0 False
      sG = Torch.sumAll g
      res = (lse `Torch.sub` Torch.log sG) `Torch.div` betaT
   in UnsafeMkTensor (Torch.reshape [1] res)

-- | Guarded ∀ over finite uniform measure, parameterized by β:
--
--   ∀_{x|g}^{unif,β} φ  =  ¬ ∃_{x|g}^{unif,β} (¬φ)
bigWedgeRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> Omega
bigWedgeRBeta betaT g phi =
  let nPhi = negR phi
      nLse = bigVeeRBeta betaT g nPhi
   in UnsafeMkTensor (Torch.reshape [1] (negR (toDynamic nLse)))

-- ============================================================
--  Internal: JIT-safe epsilon
-- ============================================================

-- | 1e-8 synthesized from onesLike for JIT safety.
epsLikeBeta :: Torch.Tensor -> Torch.Tensor
epsLikeBeta x =
  let one = Torch.onesLike x
      two = one `Torch.add` one
      four = two `Torch.mul` two
      five = four `Torch.add` one
      ten = five `Torch.mul` two
      ten2 = ten `Torch.mul` ten
      ten4 = ten2 `Torch.mul` ten2
      ten8 = ten4 `Torch.mul` ten4
   in one `Torch.div` ten8
