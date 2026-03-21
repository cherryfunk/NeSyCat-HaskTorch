{-# LANGUAGE TypeFamilies #-}

-- | Inference interpretation for TensReal logic.
--   Connects theory roles to vocabulary symbols via inhabitation.
module E_Inferential.BA_Interpretation.InferenceIntpTens
  ()
where

import E_Inferential.D_Vocabulary.InferenceVocabTens (InferenceVocab (..))
import E_Inferential.DA_Realization.InferenceRlzTens ()
import E_Inferential.B_Theory.InferenceTheory (InferenceFun (..))
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
