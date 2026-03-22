{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

-- | Logical interpretation: Tensor-valued Logic on R (Omega = R^1, a tensor space).
--
--   All operations work on logits in R (no sigmoid, no [0,1] restriction):
--     * neg x  = -x              (additive inverse)
--     * vee    = smooth max      (LogSumExp)
--     * wedge  = smooth min      (De Morgan dual)
--     * True   = +inf,  False = -inf
--
--   ParamsLogic Omega = Torch.Tensor (the beta smoothing parameter).
--   This is standard model theory over (R, +, x, <=).
module B_Logical.BA_Interpretation.Tensor
  ( module B_Logical.BA_Interpretation.Tensor,
    module B_Logical.B_Theory.A2MonBLatTheory,
    module B_Logical.B_Theory.TwoMonBLatTheory,
  )
where

import A_Categorical.BA_Interpretation.StarIntp (FrmwkGeom)
import B_Logical.B_Theory.A2MonBLatTheory
import B_Logical.B_Theory.TwoMonBLatTheory
import Data.Functor.Identity (Identity (..), runIdentity)
import qualified Torch
import Torch.DType (DType (..))
import Torch.Device (DeviceType (..))
import qualified Torch.Functional.Internal as F
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Omega := I(tau) = R^1 (a tensor space)
type Omega = Tensor '( 'CPU, 0) 'Float '[1]

-- ============================================================
--  TwoMonBLat: Binary Logical Operations on Omega (R-valued)
-- ============================================================

instance TwoMonBLatTheory FrmwkGeom Omega where
  type ParamsLogic Omega = Torch.Tensor

  vdash a b = Torch.asValue (toDynamic a) <= (Torch.asValue (toDynamic b) :: Float)

  -- \| Disjunction (vee = smooth max):
  --   vee(a, b) = (1/beta) . logaddexp(beta.a, beta.b)
  vee betaT a b =
    let a' = toDynamic a
        b' = toDynamic b
        pa = a' `Torch.mul` betaT
        pb = b' `Torch.mul` betaT
     in UnsafeMkTensor (F.logaddexp pa pb `Torch.div` betaT)

  -- wedge/implies use defaults (De Morgan via vee)

  bot = UnsafeMkTensor (Torch.asTensor [(-1.0 / 0.0) :: Float])
  top = UnsafeMkTensor (Torch.asTensor [(1.0 / 0.0) :: Float])
  oplus a b = UnsafeMkTensor (Torch.add (toDynamic a) (toDynamic b))
  otimes a b = UnsafeMkTensor (Torch.mul (toDynamic a) (toDynamic b))
  v0 = UnsafeMkTensor (Torch.asTensor [0.0 :: Float])
  v1 = UnsafeMkTensor (Torch.asTensor [1.0 :: Float])

  -- \| Negation: -x (additive inverse on R)
  neg a = UnsafeMkTensor (negate (toDynamic a))

------------------------------------------------------
-- Quantifiers with canonical measure (A2MonBLat)
------------------------------------------------------

-- | FrmwkGeom quantifier: domain is a batch tensor.
--   Applies predicate once (PyTorch broadcasts), then reduces.
instance A2MonBLatTheory (Tensor d dt s) FrmwkGeom Omega where
  type Dom (Tensor d dt s) = Torch.Tensor

  -- bigWedge = forall = smooth min = De Morgan of LogSumExp
  bigWedge betaT batchTensor phi =
    let result = runIdentity (phi (UnsafeMkTensor batchTensor))
        n = head (Torch.shape batchTensor)
        negResult = neg result
        lse = F.logsumexp (toDynamic negResult `Torch.mul` betaT) 0 False
        reduced = negate ((lse `Torch.sub` Torch.log (Torch.asTensor (fromIntegral n :: Float))) `Torch.div` betaT)
     in Identity (UnsafeMkTensor (Torch.reshape [1] reduced))

  -- bigVee = exists = LogSumExp
  bigVee betaT batchTensor phi =
    let result = runIdentity (phi (UnsafeMkTensor batchTensor))
        n = head (Torch.shape batchTensor)
        lse = F.logsumexp (toDynamic result `Torch.mul` betaT) 0 False
        reduced = (lse `Torch.sub` Torch.log (Torch.asTensor (fromIntegral n :: Float))) `Torch.div` betaT
     in Identity (UnsafeMkTensor (Torch.reshape [1] reduced))
  bigOplus _ _ = error "bigOplus over FrmwkGeom not yet supported"
  bigOtimes _ _ = error "bigOtimes over FrmwkGeom not yet supported"

------------------------------------------------------
-- Internal Helpers
------------------------------------------------------

-- | Numerically stable log-sigmoid: log sigma(x) = -log(1 + exp(-x))
--   Maps R -> (-inf, 0]: large positive -> 0, large negative -> -inf.
logSigmoid :: Torch.Tensor -> Torch.Tensor
logSigmoid x = negate (Torch.log (Torch.exp (negate x) `Torch.add` Torch.onesLike x))

one :: Torch.Tensor
one = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0 :: Float)

eps :: Torch.Tensor
eps = Torch.toDevice (Torch.Device CPU 0) $ Torch.asTensor (1.0e-8 :: Float)
