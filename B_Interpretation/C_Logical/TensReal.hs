{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- | Logic on the REAL LINE (ℝ) for the FINITE UNIFORM EMPIRICAL MEASURE case.
--
--   Unlike TensUniform (which operates on [0,1] with ¬x = 1−x and sigmoid outputs),
--   TensReal operates on ℝ with:
--
--     • ¬x = −x            (additive inverse)
--     • MLP outputs logits  (no sigmoid)
--     • ⊗ = ×,  ⊕ = +      (standard real arithmetic)
--     • ∧ = smooth min,  ∨ = smooth max (LogSumExp)
--     • ⊤ = +∞,  ⊥ = −∞
--
--   This is just standard model theory over (ℝ, +, ×, ≤).
--   All operations are on BatchOmega (= Torch.Tensor, pre-evaluated batches).
module B_Interpretation.C_Logical.TensReal
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
    module B_Interpretation.C_Logical.Tensor,
  )
where

import B_Interpretation.C_Logical.Tensor
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- ============================================================
--  BatchOmega = Torch.Tensor (a batch of truth degrees in ℝ)
-- ============================================================

-- | A batch of truth degrees — Torch.Tensor of shape [N] or [N, 1].
--   Values are in ℝ (logits), NOT restricted to [0,1].
type BatchOmega = Torch.Tensor

-- ============================================================
--  TwoMonBLat-R: pointwise batch operations on ℝ
-- ============================================================

-- | Entailment (lattice ordering ⊑): true iff ∀i. aᵢ ≤ bᵢ
vdashR :: BatchOmega -> BatchOmega -> Bool
vdashR a b =
  let maxDiff = Torch.asValue (Torch.max (Torch.sub a b)) :: Float
   in maxDiff <= 0.0

-- | Conjunction (∧ = smooth min):
--   De Morgan dual of smooth max: wedge(a, b) = ¬vee(¬a, ¬b)
wedgeR :: BatchOmega -> BatchOmega -> BatchOmega
wedgeR a b = negR (veeR (negR a) (negR b))

-- | Disjunction (∨ = smooth max):
--   vee(a, b) = (1/p) * logaddexp(p*a, p*b)
--   Uses native fused logaddexp kernel for two scalars.
veeR :: BatchOmega -> BatchOmega -> BatchOmega
veeR a b =
  let p = twoLike a
      pa = a `Torch.mul` p
      pb = b `Torch.mul` p
   in F.logaddexp pa pb `Torch.div` p

-- | Bottom: −∞
botR :: BatchOmega
botR = Torch.asTensor [(-1.0 / 0.0) :: Float]

-- | Top: +∞
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

-- | Pointwise negation: ¬φᵢ = −φᵢ  (additive inverse on ℝ)
negR :: BatchOmega -> BatchOmega
negR = negate -- Prelude negate, works on Torch.Tensor via Num instance

-- | Implication: (a → b)ᵢ = max(−aᵢ, bᵢ) = vee(¬a, b)
impliesR :: BatchOmega -> BatchOmega -> BatchOmega
impliesR a b = veeR (negR a) b

-- ============================================================
--  A2MonBLat-R: quantifiers (finite uniform measure, ℝ-valued)
-- ============================================================

-- | Guarded ∀ over finite uniform measure (De Morgan dual of ∃):
--
--   ∀_{x|g}^unif φ  =  ¬ ∃_{x|g}^unif (¬φ)
--
--   Equivalent to the negative LogSumExp of −φ.
bigWedgeR :: BatchOmega -> BatchOmega -> Omega
bigWedgeR g phi =
  let nPhi = negR phi -- −φ
      nLse = bigVeeR g nPhi -- ∃_{g}(−φ)
   in UnsafeMkTensor (Torch.reshape [1] (negR (toDynamic nLse)))

-- | Guarded ∃ over finite uniform measure:
--
--   ∃_{x|g}^unif φ  =  (1/p) * logsumexp(p*φ + log(g)) - log(Σg)
--
--   Uses native fused logsumexp kernel. Guard masking via log(g):
--   log(0)=-∞ masks elements, log(1)=0 keeps them.
bigVeeR :: BatchOmega -> BatchOmega -> Omega
bigVeeR g phi =
  let eps = epsLike g
      logG = Torch.log (g `Torch.add` eps) -- log(g), with eps to avoid log(0)
      p = twoLike phi
      pphi = (phi `Torch.mul` p) `Torch.add` logG -- p*φ + log(g)
      lse = F.logsumexp pphi 0 False -- native fused kernel
      sG = Torch.sumAll g
      p_scalar = twoLike sG
      res = (lse `Torch.sub` Torch.log sG) `Torch.div` p_scalar
   in UnsafeMkTensor (Torch.reshape [1] res)

-- | Guarded ⊕-aggregation (weighted mean):
--   ⊕_{x|g}^unif φ  =  Σᵢ gᵢ · φᵢ  /  Σᵢ gᵢ
bigOplusR :: BatchOmega -> BatchOmega -> Omega
bigOplusR g phi =
  let w = g `Torch.mul` phi
      sW = Torch.sumAll w
      sG = Torch.sumAll g
   in UnsafeMkTensor (Torch.reshape [1] (sW `Torch.div` (sG `Torch.add` epsLike sG)))

-- | Guarded ⊗-aggregation (weighted mean):
--   ⊗_{x|g}^unif φ  =  Σᵢ gᵢ · φᵢ  /  Σᵢ gᵢ
bigOtimesR :: BatchOmega -> BatchOmega -> Omega
bigOtimesR g phi =
  let w = g `Torch.mul` phi
      sW = Torch.sumAll w
      sG = Torch.sumAll g
   in UnsafeMkTensor (Torch.reshape [1] (sW `Torch.div` (sG `Torch.add` epsLike sG)))

-- ============================================================
--  Dynamic JIT-safe Constants
-- ============================================================

-- | Synthesizes a constant tensor of 2.0 dynamically to avoid JIT empty-variable tracing.
twoLike :: Torch.Tensor -> Torch.Tensor
twoLike x = Torch.onesLike x `Torch.add` Torch.onesLike x

-- | Synthesizes a constant tensor of 0.5 dynamically.
halfLike :: Torch.Tensor -> Torch.Tensor
halfLike x = Torch.onesLike x `Torch.div` twoLike x

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
