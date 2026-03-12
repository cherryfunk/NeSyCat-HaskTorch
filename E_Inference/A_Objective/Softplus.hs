-- | Softplus penalty: pen(sat) = -log(σ(sat)) = softplus(-sat).
--
--   For TensReal interpretations where sat ∈ ℝ (unbounded logits).
--   This is the canonical loss for the LogSumExp logic:
--   it turns an unbounded logit-space satisfaction into a non-negative loss.
--
--   Corresponds to the paper's pen(v), specialized for ℝ-valued truth.
module E_Inference.A_Objective.Softplus
  ( softplusLoss,
  )
where

import qualified Torch

-- | pen(sat) = -log(σ(sat))
--
--   Properties:
--     • pen(0) = log(2) ≈ 0.693
--     • pen(∞) → 0      (high satisfaction → low loss)
--     • pen(-∞) → ∞     (low satisfaction → high loss)
--     • Smooth, monotonically decreasing, always ≥ 0.
softplusLoss :: Torch.Tensor -> Torch.Tensor
softplusLoss sat = negate (Torch.log (Torch.sigmoid sat))
