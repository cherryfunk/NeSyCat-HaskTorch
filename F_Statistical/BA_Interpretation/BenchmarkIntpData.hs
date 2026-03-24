{-# LANGUAGE TypeFamilies #-}

-- | Benchmark interpretation for the DATA category.
--   Connects theory roles to vocabulary symbols via inhabitation.
--
--   Prediction = Double (expectation of Dist Bool from classifierA @MeasU)
--   Label      = Bool   (from labelA @MeasU)
module F_Statistical.BA_Interpretation.BenchmarkIntpData
  ()
where

import F_Statistical.D_Vocabulary.BenchmarkVocab (BenchmarkVocab (..))
import F_Statistical.DA_Realization.BenchmarkRlzData ()
import F_Statistical.B_Theory.BenchmarkTheory (BenchmarkFun (..))

-- | DATA benchmark interpretation:
--     accuracy   |->  fractionTrue(pred > 0.5 == label)
--     precision  |->  fractionTrue(label | pred > 0.5)
--     recall     |->  fractionTrue(pred > 0.5 | label)
--     f1Score    |->  harmonicMean(precision, recall)
--     confidence |->  (meanWhere preds posLabels, meanWhere preds negLabels)
instance BenchmarkFun Double where
  type MetricVal Double = Double

  accuracy pairs =
    let correct = [threshold p 0.5 == l | (p, l) <- pairs]
     in fractionTrue correct

  precision pairs =
    let predicted = [(p, l) | (p, l) <- pairs, threshold p 0.5]
     in if null predicted then 0.0
        else fractionTrue [l | (_, l) <- predicted]

  recall pairs =
    let positives = [(p, l) | (p, l) <- pairs, l]
     in if null positives then 0.0
        else fractionTrue [threshold p 0.5 | (p, _) <- positives]

  f1Score pairs = harmonicMean (precision pairs) (recall pairs)

  confidence pairs =
    let preds = map fst pairs
        labels = map snd pairs
     in (meanWhere preds labels, meanWhere preds (map not labels))
