{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- | Logic on the REAL LINE (ℝ) for the FINITE UNIFORM EMPIRICAL MEASURE case.
--
--   TensReal operates on ℝ with:
--
--     • notx = −x            (additive inverse)
--     • MLP outputs logits  (no sigmoid)
--     • `tensor` = ×,  `oplus` = +      (standard real arithmetic)
--     • /\ = smooth min,  \/ = smooth max (LogSumExp)
--     • True = +∞,  False = −∞
--
--   This is just standard model theory over (ℝ, +, ×, <=).
--   All operations are on BatchOmega (= Torch.Tensor, pre-evaluated batches).
module B_Logical.BA_Interpretation.TensReal
  ( BatchOmega,

    -- * TwoMonBLat-R: Binary Logical Operations on BatchOmega
    vdashR,
    wedgeR,
    veeR,
    botR,
    topR,
    oplusR,
    otimesR,
    v0R,
    v1R,

    -- * Derived Operations
    negR,
    impliesR,

    -- * A2MonBLat-R: Quantifiers (finite uniform measure)
    bigWedgeR,
    bigVeeR,
    bigOplusR,
    bigOtimesR,

    -- * Re-exports from Tensor.hs (for scalar Omega operations)
    module B_Logical.BA_Interpretation.Tensor,
  )
where

import B_Logical.BA_Interpretation.Tensor
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- ============================================================
--  Internal Constants (local, standalone — not from typeclass)
-- ============================================================

-- | LogSumExp smoothing parameter beta (fixed default).
betaVal :: Float
betaVal = 1.0

-- | beta as a tensor matching shape/device of input.
beta :: Torch.Tensor -> Torch.Tensor
beta x = F.mulScalar (Torch.onesLike x) betaVal

-- ============================================================
--  BatchOmega = Torch.Tensor (a batch of truth degrees in ℝ)
-- ============================================================

-- | A batch of truth degrees — Torch.Tensor of shape [N] or [N, 1].
--   Values are in ℝ (logits), NOT restricted to [0,1].
type BatchOmega = Torch.Tensor

-- ============================================================
--  TwoMonBLat-R: pointwise batch operations on ℝ
-- ============================================================

-- | Entailment (lattice ordering <=): true iff forall i. a_i <= b_i
vdashR :: BatchOmega -> BatchOmega -> Bool
vdashR a b =
  let maxDiff = Torch.asValue (Torch.max (Torch.sub a b)) :: Float
   in maxDiff <= 0.0

-- | Conjunction (/\ = smooth min):
--   De Morgan dual of smooth max: wedge(a, b) = notvee(nota, notb)
wedgeR :: BatchOmega -> BatchOmega -> BatchOmega
wedgeR a b = negR (veeR (negR a) (negR b))

-- | Disjunction (\/ = smooth max):
--   vee(a, b) = (1/p) * logaddexp(p*a, p*b)
--   Uses native fused logaddexp kernel for two scalars.
veeR :: BatchOmega -> BatchOmega -> BatchOmega
veeR a b =
  let p = beta a
      pa = a `Torch.mul` p
      pb = b `Torch.mul` p
   in F.logaddexp pa pb `Torch.div` p

-- | Bottom: -inf
botR :: BatchOmega
botR = Torch.asTensor [(-1.0 / 0.0) :: Float]

-- | Top: +inf
topR :: BatchOmega
topR = Torch.asTensor [(1.0 / 0.0) :: Float]

-- | Additive monoidal operation (pointwise addition)
oplusR :: BatchOmega -> BatchOmega -> BatchOmega
oplusR = Torch.add

-- | Multiplicative monoidal operation (pointwise multiplication)
otimesR :: BatchOmega -> BatchOmega -> BatchOmega
otimesR = Torch.mul

-- | Additive unit: 0
v0R :: BatchOmega
v0R = Torch.asTensor [0.0 :: Float]

-- | Multiplicative unit: 1
v1R :: BatchOmega
v1R = Torch.asTensor [1.0 :: Float]

-- ============================================================
--  Derived Operations
-- ============================================================

-- | Pointwise negation: notφᵢ = −φᵢ  (additive inverse on ℝ)
negR :: BatchOmega -> BatchOmega
negR = negate -- Prelude negate, works on Torch.Tensor via Num instance

-- | Implication: (a -> b)ᵢ = max(−aᵢ, bᵢ) = vee(nota, b)
impliesR :: BatchOmega -> BatchOmega -> BatchOmega
impliesR a b = veeR (negR a) b

-- ============================================================
--  A2MonBLat-R: quantifiers (finite uniform measure, ℝ-valued)
-- ============================================================

-- | Guarded forall over finite uniform measure (De Morgan dual of exists):
--
--   forall_{x|g}^unif φ  =  not exists_{x|g}^unif (notφ)
--
--   Equivalent to the negative LogSumExp of −φ.
bigWedgeR :: BatchOmega -> BatchOmega -> Omega
bigWedgeR g phi =
  let nPhi = negR phi -- −φ
      nLse = bigVeeR g nPhi -- exists_{g}(−φ)
   in UnsafeMkTensor (Torch.reshape [1] (negR (toDynamic nLse)))

-- | Guarded exists over finite uniform measure (ℝ-valued guards):
--
--   exists_{x|g}^unif φ  =  (1/β) * logsumexp(β·φ + log σ(g)) − log(Σ σ(g))
--
--   Guards g are ℝ logits: positive = include, negative = exclude.
--   log_sigmoid(g) maps ℝ → (−∞, 0]: large positive → 0 (keep),
--   large negative → −∞ (mask). No {0,1} conversion needed.
bigVeeR :: BatchOmega -> BatchOmega -> Omega
bigVeeR g phi =
  let logG = logSigmoid g              -- ℝ guard → log-weight
      p = beta phi
      pphi = (phi `Torch.mul` p) `Torch.add` logG
      lse = F.logsumexp pphi 0 False
      sG = Torch.sumAll (Torch.sigmoid g) -- soft count of active elements
      res = F.divScalar (lse `Torch.sub` Torch.log sG) betaVal
   in UnsafeMkTensor (Torch.reshape [1] res)

-- | Guarded `oplus`-aggregation (weighted mean):
--   `oplus`_{x|g}^unif φ  =  Σᵢ gᵢ · φᵢ  /  Σᵢ gᵢ
bigOplusR :: BatchOmega -> BatchOmega -> Omega
bigOplusR g phi =
  let w = g `Torch.mul` phi
      sW = Torch.sumAll w
      sG = Torch.sumAll g
   in UnsafeMkTensor (Torch.reshape [1] (sW `Torch.div` (sG `Torch.add` epsLike sG)))

-- | Guarded `tensor`-aggregation (weighted mean):
--   `tensor`_{x|g}^unif φ  =  Σᵢ gᵢ · φᵢ  /  Σᵢ gᵢ
bigOtimesR :: BatchOmega -> BatchOmega -> Omega
bigOtimesR g phi =
  let w = g `Torch.mul` phi
      sW = Torch.sumAll w
      sG = Torch.sumAll g
   in UnsafeMkTensor (Torch.reshape [1] (sW `Torch.div` (sG `Torch.add` epsLike sG)))

-- ============================================================
--  Internal Helpers
-- ============================================================

-- | Synthesizes a constant tensor of 1e-8 dynamically using pure graph mathematics.
--   PyTorch's JIT compiler will perform constant-folding to optimize this entirely.
epsLike :: Torch.Tensor -> Torch.Tensor
epsLike x =
  let one = Torch.onesLike x
      two = one `Torch.add` one
      four = two `Torch.mul` two
      five = four `Torch.add` one
      ten = five `Torch.mul` two
      ten2 = ten `Torch.mul` ten
      ten4 = ten2 `Torch.mul` ten2
      ten8 = ten4 `Torch.mul` ten4
   in one `Torch.div` ten8
