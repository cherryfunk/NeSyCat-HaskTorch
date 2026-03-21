{-# LANGUAGE InstanceSigs #-}

-- | Inference realization: concrete implementations of all vocabulary symbols.
module E_Inferential.DA_Realization.InferenceRlzTens () where

import E_Inferential.D_Vocabulary.InferenceVocabTens (InferenceVocab (..))
import qualified Torch

-- | Realization of InferenceVocab for Torch.Tensor.
instance InferenceVocab Torch.Tensor where
  -- \| softplus(sat) = -log(sigma(sat))
  softplus :: Torch.Tensor -> Torch.Tensor
  softplus sat = negate (Torch.log (Torch.sigmoid sat))

  -- \| oneMinus(oneTens, sat) = 1 - sat
  oneMinus :: Torch.Tensor -> Torch.Tensor -> Torch.Tensor
  oneMinus oneTens sat = oneTens `Torch.sub` sat

  -- \| negLog(p) = -log(p)
  negLog :: Torch.Tensor -> Torch.Tensor
  negLog p = negate (Torch.log p)

  -- \| crossEntropy(p, y) = -[y*log(p) + (1-y)*log(1-p)]
  crossEntropy :: Torch.Tensor -> Torch.Tensor -> Torch.Tensor
  crossEntropy p y =
    let logP = Torch.log p
        log1P = Torch.log (Torch.onesLike p `Torch.sub` p)
        yLogP = y `Torch.mul` logP
        y1Log1P = (Torch.onesLike y `Torch.sub` y) `Torch.mul` log1P
     in negate (yLogP `Torch.add` y1Log1P)

  -- \| convex(J_data, J_know, lambda) = lambda * J_data + (1-lambda) * J_know
  convex :: Torch.Tensor -> Torch.Tensor -> Torch.Tensor -> Torch.Tensor
  convex dataLoss knowLoss lambda =
    let oneMinusLambda = Torch.onesLike lambda `Torch.sub` lambda
     in (lambda `Torch.mul` dataLoss) `Torch.add` (oneMinusLambda `Torch.mul` knowLoss)
