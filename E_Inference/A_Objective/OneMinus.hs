-- | One-minus penalty: pen(sat) = 1 - sat.
--
--   For interpretations where sat ∈ [0,1].
--   This is the simplest penalty: perfect satisfaction (sat=1) → 0 loss,
--   no satisfaction (sat=0) → 1 loss.
--
--   Matches the LTN default: loss = 1 - SatAgg(axioms).
--   Corresponds to the paper's pen(v) = 1-v.
module E_Inference.A_Objective.OneMinus
  ( oneMinusLoss,
  )
where

import qualified Torch

-- | pen(sat) = 1 - sat
--
--   Properties:
--     • pen(1) = 0  (full satisfaction → zero loss)
--     • pen(0) = 1  (no satisfaction → unit loss)
--     • Linear, monotonically decreasing on [0,1].
oneMinusLoss :: Torch.Tensor -> Torch.Tensor -> Torch.Tensor
oneMinusLoss oneTens sat = oneTens `Torch.sub` sat
