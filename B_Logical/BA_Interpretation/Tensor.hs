{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
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

import A_Categorical.BA_Interpretation.StarIntp (GeomU)
import B_Logical.B_Theory.A2MonBLatTheory
import B_Logical.B_Theory.TwoMonBLatTheory
import Data.Functor.Identity (Identity (..), runIdentity)
import qualified Torch
import qualified Torch.Functional.Internal as F

-- | Omega := I(tau) = R^1 (a 1-element tensor)
type Omega = Torch.Tensor  -- shape: [1], dtype: Float

-- ============================================================
--  TwoMonBLat: Binary Logical Operations on Omega (R-valued)
-- ============================================================

instance TwoMonBLatTheory GeomU Omega where
  type ParamsLogic Omega = Torch.Tensor

  vdash a b = Torch.asValue a <= (Torch.asValue b :: Float)

  -- \| Disjunction (vee = smooth max):
  --   vee(a, b) = (1/beta) . logaddexp(beta.a, beta.b)
  vee betaT a b =
    let pa = a `Torch.mul` betaT
        pb = b `Torch.mul` betaT
     in F.logaddexp pa pb `Torch.div` betaT

  -- wedge/implies use defaults (De Morgan via vee)

  bot = Torch.asTensor [(-1.0 / 0.0) :: Float]
  top = Torch.asTensor [(1.0 / 0.0) :: Float]
  oplus a b = Torch.add a b
  otimes a b = Torch.mul a b
  v0 = Torch.asTensor [0.0 :: Float]
  v1 = Torch.asTensor [1.0 :: Float]

  -- \| Negation: -x (additive inverse on R)
  neg a = negate a

------------------------------------------------------
-- Guard type instance: GeomU guards are batch tensors
------------------------------------------------------

type instance Guard GeomU Torch.Tensor = Torch.Tensor

------------------------------------------------------
-- Quantifiers with canonical measure (A2MonBLat)
------------------------------------------------------

-- | GeomU quantifier: guard is a batch tensor.
--   Product functor (-)^N applies predicate once (PyTorch broadcasts).
--   Reduction via smooth sup/inf (LogSumExp) -- the geometry paradigm's
--   analogue of the lattice quantifiers.
instance A2MonBLatTheory Torch.Tensor GeomU Omega where
  -- bigWedge = forall = smooth inf = De Morgan of LogSumExp
  bigWedge betaT guard phi =
    let result = runIdentity (phi guard)
        n = head (Torch.shape guard)
        negResult = neg result
        lse = F.logsumexp (negResult `Torch.mul` betaT) 0 False
        reduced = negate ((lse `Torch.sub` Torch.log (Torch.asTensor (fromIntegral n :: Float))) `Torch.div` betaT)
     in Identity (Torch.reshape [1] reduced)

  -- bigVee = exists = LogSumExp
  bigVee betaT guard phi =
    let result = runIdentity (phi guard)
        n = head (Torch.shape guard)
        lse = F.logsumexp (result `Torch.mul` betaT) 0 False
        reduced = (lse `Torch.sub` Torch.log (Torch.asTensor (fromIntegral n :: Float))) `Torch.div` betaT
     in Identity (Torch.reshape [1] reduced)
  bigOplus _ _ = error "bigOplus over GeomU not yet supported"
  bigOtimes _ _ = error "bigOtimes over GeomU not yet supported"

------------------------------------------------------
-- Internal Helpers
------------------------------------------------------

-- | Numerically stable log-sigmoid: log sigma(x) = -log(1 + exp(-x))
--   Maps R -> (-inf, 0]: large positive -> 0, large negative -> -inf.
logSigmoid :: Torch.Tensor -> Torch.Tensor
logSigmoid x = negate (Torch.log (Torch.exp (negate x) `Torch.add` Torch.onesLike x))

one :: Torch.Tensor
one = Torch.toDevice (Torch.Device Torch.CPU 0) $ Torch.asTensor (1.0 :: Float)

eps :: Torch.Tensor
eps = Torch.toDevice (Torch.Device Torch.CPU 0) $ Torch.asTensor (1.0e-8 :: Float)
