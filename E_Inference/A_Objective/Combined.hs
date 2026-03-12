-- | Combined objective: J(θ) = λ · J_data(θ) + (1-λ) · J_know(θ).
--
--   Convex combination of data loss and knowledge penalty.
--   Training modules only handle the optimization algorithm.
--
--   λ is a Tensor so it can be either:
--     • A fixed hyperparameter: Torch.asTensor 0.5
--     • A learnable parameter: toDependent lambdaInd (gradients flow)
--
--   Special cases (callers should short-circuit computation):
--     λ = 0:  pure knowledge-driven (axiom-only)
--     λ = 1:  pure data-driven (standard cross-entropy)
--     λ ∈ (0,1): combined neurosymbolic training
module E_Inference.A_Objective.Combined
  ( combinedObjective,
  )
where

import qualified Torch

-- | J(θ) = λ · J_data + (1-λ) · J_know
--
--   λ is a Tensor to support both fixed and learnable trade-off.
--   Callers should short-circuit J_data/J_know computation when λ∈{0,1}.
combinedObjective ::
  Torch.Tensor ->  -- ^ J_data: data loss
  Torch.Tensor ->  -- ^ J_know: knowledge penalty
  Torch.Tensor ->  -- ^ λ: trade-off (0 = pure axiom, 1 = pure data)
  Torch.Tensor     -- ^ J = λ · J_data + (1-λ) · J_know
combinedObjective dataLoss knowLoss lambda =
  let oneMinusLambda = Torch.onesLike lambda `Torch.sub` lambda
   in (lambda `Torch.mul` dataLoss) `Torch.add` (oneMinusLambda `Torch.mul` knowLoss)
