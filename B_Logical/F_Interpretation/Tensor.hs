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
import A_Categorical.F_Interpretation.Monads.Giry (Giry (..))
import B_Logical.A_Category.Tens (TENS (..))
import A_Categorical.F_Interpretation.Monads.Expectation_TENS (expectTENS)
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
-- Guarded Quantifiers with explicit measure (A2MonBLat)
------------------------------------------------------

instance A2MonBLatTheory TENS Omega where
  -- | Guarded forall: De Morgan dual of exists.
  --   forall_{x|g}^μ φ(x) = −exists_{x|g}^μ (−φ(x))
  bigWedge :: TENS a -> Giry a -> (a -> Omega) -> (a -> Omega) -> Omega
  bigWedge dom mu guard phi = neg (bigVee dom mu guard (neg . phi))

  -- | Guarded exists with measure μ (LogSumExp aggregation):
  --   exists_{x|g}^μ φ  =  (1/β) · logsumexp(β·φ + log(g)) − log(Σg)
  bigVee :: TENS a -> Giry a -> (a -> Omega) -> (a -> Omega) -> Omega
  bigVee TensorSpace mu guard phi =
    let evals  = expectTENS TensorSpace mu (\x -> toDynamic (phi x))
        guards = expectTENS TensorSpace mu (\x -> toDynamic (guard x))
        p      = beta evals
        logG   = logSigmoid guards    -- ℝ guard → log-weight
        pphi   = (evals `Torch.mul` p) `Torch.add` logG
        lse    = F.logsumexp pphi 0 False
        sG     = Torch.sumAll (Torch.sigmoid guards)  -- soft count
        res    = F.divScalar (lse `Torch.sub` Torch.log sG) betaVal
     in UnsafeMkTensor (Torch.reshape [1] res)
  bigVee TensProd {} _ _ _ = error "bigVee over TensProd not yet supported"
  bigVee TensUnit _ _ phi = phi ()

  bigOplus :: TENS a -> Giry a -> (a -> Omega) -> (a -> Omega) -> Omega
  bigOplus = error "bigOplus over TENS not yet supported"
  bigOtimes :: TENS a -> Giry a -> (a -> Omega) -> (a -> Omega) -> Omega
  bigOtimes = error "bigOtimes over TENS not yet supported"

------------------------------------------------------
-- Internal Constants
------------------------------------------------------

-- | LogSumExp smoothing parameter β.
betaVal :: Float
betaVal = 1.25

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
