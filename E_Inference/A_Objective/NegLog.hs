-- | Negative log-likelihood: loss(p) = -log(p).
--
--   For direct probability outputs where p ∈ (0,1].
--   This is the standard NLL for outputs that are already probabilities.
--   Used by MNIST where digitEq directly produces log-probabilities.
--
--   Corresponds to the paper's pen(v) = -log(v).
module E_Inference.A_Objective.NegLog
  ( negLogLoss,
  )
where

import qualified Torch

-- | loss(p) = -log(p)
--
--   Properties:
--     • loss(1) = 0      (perfect confidence → zero loss)
--     • loss(0+) → ∞     (zero confidence → infinite loss)
--     • Convex, monotonically decreasing on (0,1].
negLogLoss :: Torch.Tensor -> Torch.Tensor
negLogLoss p = negate (Torch.log p)
