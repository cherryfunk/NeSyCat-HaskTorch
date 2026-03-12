{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- | Specialized logic for the FINITE UNIFORM EMPIRICAL MEASURE case.
--
--   Mirrors Tensor.hs (TwoMonBLat_Sig + A2MonBLat) exactly, but optimized for:
--     μ = (1/N) Σᵢ delta(x − xᵢ)   (uniform over a finite dataset)
--
--   All operations are on BatchOmega (= Torch.Tensor, pre-evaluated batches),
--   not on individual Omega values with Giry measures.
--
--   For non-uniform measures, use the general instances in Tensor.hs.
module B_Logical.D_Interpretation.TensUniform
  ( BatchOmega,

    -- * TwoMonBLat-U: Binary Logical Operations on BatchOmega
    vdashU,
    wedgeU,
    veeU,
    botU,
    topU,
    oplusU,
    otimesU,
    v0U,
    v1U,

    -- * Derived Operations
    negU,
    impliesU,

    -- * A2MonBLat-U: Quantifiers (finite uniform measure)
    bigWedgeU,
    bigVeeU,
    bigOplusU,
    bigOtimesU,

    -- * Re-exports from Tensor.hs (for scalar Omega operations)
    module B_Logical.D_Interpretation.Tensor,
  )
where

import B_Logical.D_Interpretation.Tensor
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- ============================================================
--  BatchOmega = Torch.Tensor (a batch of truth values)
-- ============================================================

-- | A batch of truth values — just Torch.Tensor of shape [N] or [N, 1].
--   Represents φ(x₁), …, φ(xₙ) evaluated on a finite dataset.
type BatchOmega = Torch.Tensor

-- ============================================================
--  TwoMonBLat-U: pointwise batch operations
--  (mirrors TwoMonBLat_Sig Omega in Tensor.hs)
-- ============================================================

-- | Entailment (lattice ordering ⊑): true iff foralli. aᵢ <= bᵢ
vdashU :: BatchOmega -> BatchOmega -> Bool
vdashU a b =
  let maxDiff = Torch.asValue (Torch.max (Torch.sub a b)) :: Float
   in maxDiff <= 0.0

-- | p-Mean conjunction (De Morgan dual):
--   wedgeU(a, b)ᵢ = not(veeU(nota, notb))ᵢ
wedgeU :: BatchOmega -> BatchOmega -> BatchOmega
wedgeU a b = negU (veeU (negU a) (negU b))

-- | p-Mean disjunction (primitive, with π₀ stability):
--   veeU(a, b)ᵢ = ((π₀(aᵢ)^p + π₀(bᵢ)^p) / 2)^{1/p}
--
--   Optimized native C++ kernel (p=2): sqrt((a²+b²)/2) = hypot(a, b) * sqrt(0.5)
veeU :: BatchOmega -> BatchOmega -> BatchOmega
veeU a b =
  let hypot = F.hypot (pi0U a) (pi0U b)
   in F.mulScalar hypot 0.70710678118

-- | Bottom: −∞
botU :: BatchOmega
botU = Torch.asTensor [(-1.0 / 0.0) :: Float]

-- | Top: +∞
topU :: BatchOmega
topU = Torch.asTensor [(1.0 / 0.0) :: Float]

-- | Additive monoidal operation (pointwise addition)
oplusU :: BatchOmega -> BatchOmega -> BatchOmega
oplusU = Torch.add

-- | Multiplicative monoidal operation (pointwise multiplication)
otimesU :: BatchOmega -> BatchOmega -> BatchOmega
otimesU = Torch.mul

-- | Additive unit: 0
v0U :: BatchOmega
v0U = Torch.asTensor [0.0 :: Float]

-- | Multiplicative unit: 1
v1U :: BatchOmega
v1U = Torch.asTensor [1.0 :: Float]

-- ============================================================
--  Derived Operations
-- ============================================================

-- | Pointwise negation: notφᵢ = 1 − φᵢ
negU :: BatchOmega -> BatchOmega
negU t = F.sub (Torch.onesLike t) t 1.0

-- | Fuzzy implication: (a -> b)ᵢ = veeU(notaᵢ, bᵢ)
impliesU :: BatchOmega -> BatchOmega -> BatchOmega
impliesU a b = veeU (negU a) b

-- ============================================================
--  A2MonBLat-U: quantifiers (finite uniform measure)
--  (mirrors A2MonBLat_Sig TENS Omega in Tensor.hs)
-- ============================================================

-- | Guarded forall over finite uniform measure (De Morgan dual of exists):
--
--   forall_{x|g}^unif φ  =  1 − ( Σᵢ gᵢ · (1 − π₁(φᵢ))^p  /  Σᵢ gᵢ )^{1/p}
bigWedgeU :: BatchOmega -> BatchOmega -> Omega
bigWedgeU g phi =
  let e = pi1U phi -- π₁ stability
      e' = F.sub (Torch.onesLike e) e 1.0 -- (1 − φ)
      ep = powPU e' -- (1 − φ)^p
      w = g `Torch.mul` ep -- gᵢ · (1−φᵢ)^p
      sW = Torch.sumAll w
      sG = Torch.sumAll g
      m = sW `Torch.div` F.addScalar sG 1.0e-8 1.0
      res = F.sub (Torch.onesLike m) (powInvPU m) 1.0
   in UnsafeMkTensor (Torch.reshape [1] res)

-- | Guarded exists over finite uniform measure:
--
--   exists_{x|g}^unif φ  =  ( Σᵢ gᵢ · π₀(φᵢ)^p  /  Σᵢ gᵢ )^{1/p}
bigVeeU :: BatchOmega -> BatchOmega -> Omega
bigVeeU g phi =
  let ep = powPU (pi0U phi) -- π₀ stability
      w = g `Torch.mul` ep
      sW = Torch.sumAll w
      sG = Torch.sumAll g
      m = sW `Torch.div` F.addScalar sG 1.0e-8 1.0
   in UnsafeMkTensor (Torch.reshape [1] (powInvPU m))

-- | Guarded `oplus`-aggregation over finite uniform measure
bigOplusU :: BatchOmega -> BatchOmega -> Omega
bigOplusU g phi =
  let w = g `Torch.mul` phi
      sW = Torch.sumAll w
      sG = Torch.sumAll g
   in UnsafeMkTensor (Torch.reshape [1] (sW `Torch.div` F.addScalar sG 1.0e-8 1.0))

-- | Guarded `tensor`-aggregation over finite uniform measure
bigOtimesU :: BatchOmega -> BatchOmega -> Omega
bigOtimesU g phi =
  let w = g `Torch.mul` phi
      sW = Torch.sumAll w
      sG = Torch.sumAll g
   in UnsafeMkTensor (Torch.reshape [1] (sW `Torch.div` F.addScalar sG 1.0e-8 1.0))

-- ============================================================
--  Internal Constants & Stability Projections
-- ============================================================

{-# NOINLINE oneU #-}
oneU :: Torch.Tensor
oneU = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0 :: Float)

{-# NOINLINE halfU #-}
halfU :: Torch.Tensor
halfU = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (0.5 :: Float)

{-# NOINLINE sqrtHalfU #-}
sqrtHalfU :: Torch.Tensor
sqrtHalfU = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (0.70710678118 :: Float)

{-# NOINLINE epsU #-}
epsU :: Torch.Tensor
epsU = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0e-8 :: Float)

{-# NOINLINE stableEpsU #-}
stableEpsU :: Torch.Tensor
stableEpsU = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0e-4 :: Float)

{-# NOINLINE stableScaleU #-}
stableScaleU :: Torch.Tensor
stableScaleU = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (0.9999 :: Float)

-- | π₀: maps [0,1] -> (0, 1]
pi0U :: Torch.Tensor -> Torch.Tensor
pi0U x = F.addScalar (F.mulScalar x 0.9999) 1.0e-4 1.0

-- | π₁: maps [0,1] -> [0, 1)
pi1U :: Torch.Tensor -> Torch.Tensor
pi1U x = F.mulScalar x 0.9999

-- | p-Mean parameter (p = 2)
powPU :: Torch.Tensor -> Torch.Tensor
powPU t = Torch.mul t t -- t²

powInvPU :: Torch.Tensor -> Torch.Tensor
powInvPU t = Torch.sqrt t -- t^(1/2)
