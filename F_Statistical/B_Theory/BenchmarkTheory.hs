{-# LANGUAGE TypeFamilies #-}

-- | The benchmark theory (level ζ) declares the function symbols needed
--   to evaluate a trained classifier against ground truth.
--
--   Function symbols:
--     accuracy   : [(pred, label)] → MetricVal   fraction of correct predictions
--     f1Score    : [(pred, label)] → MetricVal   harmonic mean of precision and recall
--     precision  : [(pred, label)] → MetricVal   tp / (tp + fp)
--     recall     : [(pred, label)] → MetricVal   tp / (tp + fn)
--     confidence : [(pred, label)] → (MetricVal, MetricVal)   mean P+ and P-
module F_Statistical.B_Theory.BenchmarkTheory
  ( BenchmarkFun (..),
  )
where

-- | Function symbols of the benchmark theory.
--   Each interpretation (instance) assigns concrete morphisms.
--   Parameterized by the prediction type; label is Bool (binary classification).
class BenchmarkFun pred where
  type MetricVal pred :: *

  -- | accuracy : fraction of predictions matching ground truth.
  accuracy :: [(pred, Bool)] -> MetricVal pred

  -- | f1Score : harmonic mean of precision and recall.
  f1Score :: [(pred, Bool)] -> MetricVal pred

  -- | precision : tp / (tp + fp).
  precision :: [(pred, Bool)] -> MetricVal pred

  -- | recall : tp / (tp + fn).
  recall :: [(pred, Bool)] -> MetricVal pred

  -- | confidence : (mean probability for positive samples, mean for negative).
  confidence :: [(pred, Bool)] -> (MetricVal pred, MetricVal pred)
