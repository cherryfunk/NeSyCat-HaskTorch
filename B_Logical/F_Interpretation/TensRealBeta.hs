{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- | Logic on the REAL LINE (ℝ) — PARAMETERIZED by beta.
--
--   Identical to TensReal, but every smooth connective takes beta explicitly
--   rather than using a hardcoded constant.  This enables:
--
--     • Joint optimization of beta + theta
--     • beta-only optimization (theta frozen)
--     • Hyperparameter sweeps
--     • Inductive / sampling-based beta learning (future)
--
--   beta controls the LogSumExp sharpness:
--     vee(a, b)  = (1/beta) · logaddexp(beta·a, beta·b)
--     wedge(a,b) = notvee(nota, notb)
--     exists = logsumexp with beta scaling
--     forall = De Morgan dual of exists
module B_Logical.F_Interpretation.TensRealBeta
  ( BatchOmega,

    -- * TwoMonBLat-R-beta: Binary Logical Operations (beta-parameterized)
    veeRBeta,
    wedgeRBeta,

    -- * A2MonBLat-R-beta: Quantifiers (beta-parameterized)
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
    module B_Logical.F_Interpretation.Tensor,
  )
where

import B_Logical.F_Interpretation.Tensor
import B_Logical.F_Interpretation.TensReal
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
--  TwoMonBLat-R-beta: pointwise batch operations, beta-parameterized
-- ============================================================

-- | Disjunction (\/ = smooth max), parameterized by beta:
--   vee_beta(a, b) = (1/beta) · logaddexp(beta·a, beta·b)
veeRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> BatchOmega
veeRBeta betaT a b =
  let pa = a `Torch.mul` betaT
      pb = b `Torch.mul` betaT
   in F.logaddexp pa pb `Torch.div` betaT

-- | Conjunction (/\ = smooth min), parameterized by beta:
--   wedge_beta(a, b) = notvee_beta(nota, notb)
wedgeRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> BatchOmega
wedgeRBeta betaT a b = negR (veeRBeta betaT (negR a) (negR b))

-- | Implication parameterized by beta: (a -> b) = vee_beta(nota, b)
impliesRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> BatchOmega
impliesRBeta betaT a b = veeRBeta betaT (negR a) b

-- ============================================================
--  A2MonBLat-R-beta: quantifiers, beta-parameterized
-- ============================================================

-- | Guarded exists over finite uniform measure, parameterized by beta:
--
--   exists_{x|g}^{unif,beta} φ  =  (1/beta) · logsumexp(beta·φ + log(g)) − log(Σg)
bigVeeRBeta :: Torch.Tensor -> BatchOmega -> BatchOmega -> Omega
bigVeeRBeta betaT g phi =
  let logG = logSigmoid g               -- ℝ guard → log-weight
      pphi = (phi `Torch.mul` betaT) `Torch.add` logG
      lse = F.logsumexp pphi 0 False
      sG = Torch.sumAll (Torch.sigmoid g) -- soft count
      res = (lse `Torch.sub` Torch.log sG) `Torch.div` betaT
   in UnsafeMkTensor (Torch.reshape [1] res)

-- | Guarded forall over finite uniform measure, parameterized by beta:
--
--   forall_{x|g}^{unif,beta} φ  =  not exists_{x|g}^{unif,beta} (notφ)
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
