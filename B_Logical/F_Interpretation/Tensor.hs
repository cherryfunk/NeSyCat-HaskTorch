{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeSynonymInstances #-}

-- | Logical interpretation: Tensor-valued Logic on ℝ (Ω = R^1, a tensor space).
--
--   All operations work on logits in ℝ (no sigmoid, no [0,1] restriction):
--     • neg x  = −x              (additive inverse)
--     • ∨      = smooth max      (LogSumExp)
--     • ∧      = smooth min      (De Morgan dual)
--     • True   = +∞,  False = −∞
--
--   This is standard model theory over (ℝ, +, ×, ≤).
module B_Logical.F_Interpretation.Tensor
  ( module B_Logical.F_Interpretation.Tensor,
    module B_Logical.D_Theory.A2MonBLatTheory,
    module B_Logical.D_Theory.TwoMonBLatTheory,
    module B_Logical.A_Category.Tens,
  )
where

import B_Logical.D_Theory.A2MonBLatTheory
import B_Logical.D_Theory.TwoMonBLatTheory
import B_Logical.A_Category.Tens (TENS (..))
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Ω := I(τ) = R^1 (a tensor space)
type Omega = Tensor '( 'CPU, 0) 'Float '[1]

-- ============================================================
--  TwoMonBLat: Binary Logical Operations on Omega (ℝ-valued)
-- ============================================================

instance TwoMonBLatTheory Omega where
  vdash a b = Torch.asValue (toDynamic a) <= (Torch.asValue (toDynamic b) :: Float)

  -- | Conjunction (∧ = smooth min): De Morgan dual of smooth max.
  --   wedge(a, b) = −vee(−a, −b)
  wedge a b = neg (vee (neg a) (neg b))

  -- | Disjunction (∨ = smooth max):
  --   vee(a, b) = (1/β) · logaddexp(β·a, β·b)
  vee a b =
    let a' = toDynamic a; b' = toDynamic b
        p  = beta a'
        pa = a' `Torch.mul` p
        pb = b' `Torch.mul` p
     in UnsafeMkTensor (F.logaddexp pa pb `Torch.div` p)

  bot = UnsafeMkTensor (Torch.asTensor [(-1.0 / 0.0) :: Float])
  top = UnsafeMkTensor (Torch.asTensor [(1.0 / 0.0) :: Float])
  oplus a b = UnsafeMkTensor (Torch.add (toDynamic a) (toDynamic b))
  otimes a b = UnsafeMkTensor (Torch.mul (toDynamic a) (toDynamic b))
  v0 = UnsafeMkTensor (Torch.asTensor [0.0 :: Float])
  v1 = UnsafeMkTensor (Torch.asTensor [1.0 :: Float])

  -- | Negation: −x (additive inverse on ℝ)
  neg a = UnsafeMkTensor (negate (toDynamic a))

  -- | Implication: max(−a, b) = vee(neg a, b)
  implies a b = vee (neg a) b

------------------------------------------------------
-- Guarded Quantifiers with canonical measure (A2MonBLat)
------------------------------------------------------

instance A2MonBLatTheory TENS Omega where
  -- | Guarded forall: De Morgan dual of exists.
  --   forall_{x|g} φ(x) = −exists_{x|g} (−φ(x))
  bigWedge dom guard phi = neg (bigVee dom guard (neg . phi))

  -- | Guarded exists (LogSumExp aggregation):
  --   exists_{x|g} φ  =  (1/β) · logsumexp(β·φ + log(g)) − log(Σg)
  --   The domain object carries the concrete batch (TensorBatch).
  bigVee (TensorBatch batch) guard phi =
    let batchPt = UnsafeMkTensor batch
        evals  = toDynamic (phi batchPt)
        guards = toDynamic (guard batchPt)
        p      = beta evals
        logG   = logSigmoid guards
        pphi   = (evals `Torch.mul` p) `Torch.add` logG
        lse    = F.logsumexp pphi 0 False
        sG     = Torch.sumAll (Torch.sigmoid guards)
        res    = F.divScalar (lse `Torch.sub` Torch.log sG) betaVal
     in UnsafeMkTensor (Torch.reshape [1] res)
  bigVee TensorSpace _ _ = error "bigVee on abstract TensorSpace requires TensorBatch"
  bigVee TensProd {} _ _ = error "bigVee over TensProd not yet supported"
  bigVee TensUnit _ phi = phi ()

  bigOplus = error "bigOplus over TENS not yet supported"
  bigOtimes = error "bigOtimes over TENS not yet supported"

------------------------------------------------------
-- Internal Constants
------------------------------------------------------

-- | LogSumExp smoothing parameter β.
betaVal :: Float
betaVal = 1.2

-- | β as a tensor matching shape/device of input.
beta :: Torch.Tensor -> Torch.Tensor
beta x = F.mulScalar (Torch.onesLike x) betaVal

-- | Numerically stable log-sigmoid: log σ(x) = −log(1 + exp(−x))
--   Maps ℝ → (−∞, 0]: large positive → 0, large negative → −∞.
logSigmoid :: Torch.Tensor -> Torch.Tensor
logSigmoid x = negate (Torch.log (Torch.exp (negate x) `Torch.add` Torch.onesLike x))

one :: Torch.Tensor
one = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0 :: Float)

eps :: Torch.Tensor
eps = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0e-8 :: Float)
