-- | Inference vocabulary: type signatures of all available loss functions.
--
--   These are the "raw symbols" — named by what they ARE.
--   Inhabitation (C_Inhabitation/) provides the implementations.
--   The theory (D_Theory/) picks from these and assigns roles.
module E_Inferential.D_Vocabulary.InferenceVocabTens
  ( InferenceVocab (..),
  )
where

-- | All available loss function symbols with their type signatures.
class InferenceVocab cat where
  -- Penalty functions: Ω → ℝ
  softplus :: cat -> cat
  oneMinus :: cat -> cat -> cat
  negLog   :: cat -> cat

  -- Data loss functions: Ω × Ω → ℝ
  crossEntropy :: cat -> cat -> cat

  -- Combination functions: ℝ × ℝ × λ → ℝ
  convex :: cat -> cat -> cat -> cat
