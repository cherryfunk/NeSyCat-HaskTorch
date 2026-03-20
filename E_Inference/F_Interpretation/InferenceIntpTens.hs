{-# LANGUAGE TypeFamilies #-}

-- | Inference interpretation for TensReal logic.
--   Connects theory roles to vocabulary symbols via inhabitation.
module E_Inference.F_Interpretation.InferenceIntpTens
  ()
where

import E_Inference.B_Vocabulary.InferenceVocabTens (InferenceVocab (..))
import E_Inference.C_Inhabitation.InferenceInhabTens ()
import E_Inference.D_Theory.InferenceTheory (InferenceFun (..))
import qualified Torch

-- | TensReal inference interpretation:
--     lossKnow ↦  softplus     (from vocabulary)
--     lossData ↦  crossEntropy (from vocabulary)
--     lossComb ↦  convex       (from vocabulary)
instance InferenceFun Torch.Tensor where
  type Loss Torch.Tensor = Torch.Tensor
  lossKnow = softplus
  lossData = crossEntropy
  lossComb = convex
