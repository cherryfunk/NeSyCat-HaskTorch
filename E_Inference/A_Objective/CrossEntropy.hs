-- | Bernoulli cross-entropy: loss(p, y) = -[y·log(p) + (1-y)·log(1-p)].
--
--   The canonical pointwise loss for binary classification with
--   predictions p ∈ (0,1) and targets y ∈ {0,1} or y ∈ [0,1].
--
--   Matches the paper's definition:
--     loss : [0,1] × [0,1] → ℝ≥0
--
--   Note: pen(v) = crossEntropyLoss(v, 1) = -log(v) = negLogLoss(v),
--   confirming that penalties are a special case of loss with target y=1.
module E_Inference.A_Objective.CrossEntropy
  ( crossEntropyLoss,
  )
where

import qualified Torch

-- | loss(p, y) = -[y·log(p) + (1-y)·log(1-p)]
--
--   For numerical stability, if p is very close to 0 or 1,
--   consider using a softplus-based formulation instead.
crossEntropyLoss :: Torch.Tensor -> Torch.Tensor -> Torch.Tensor
crossEntropyLoss p y =
  let logP = Torch.log p
      log1P = Torch.log (Torch.onesLike p `Torch.sub` p)
      yLogP = y `Torch.mul` logP
      y1Log1P = (Torch.onesLike y `Torch.sub` y) `Torch.mul` log1P
   in negate (yLogP `Torch.add` y1Log1P)
