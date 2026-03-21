-- | Benchmark vocabulary: type signatures of all available metric primitives.
--
--   These are the "raw symbols" — named by what they ARE.
--   Inhabitation (C_Inhabitation/) provides the implementations.
--   The theory (D_Theory/) picks from these and assigns roles.
module F_Benchmark.B_Vocabulary.BenchmarkVocab
  ( BenchmarkVocab (..),
  )
where

-- | All available metric primitive symbols with their type signatures.
--   Parameterized by the metric value type (e.g. Double, Tensor).
class BenchmarkVocab cat where
  -- | threshold : cat × cat → Bool.  Predicted probability > threshold.
  threshold :: cat -> cat -> Bool

  -- | countTrue : [Bool] → cat.  Fraction of True values (count / total).
  fractionTrue :: [Bool] -> cat

  -- | harmonicMean : cat × cat → cat.  2ab/(a+b).
  harmonicMean :: cat -> cat -> cat

  -- | meanWhere : [cat] × [Bool] → cat.  Mean of values where mask is True.
  meanWhere :: [cat] -> [Bool] -> cat
