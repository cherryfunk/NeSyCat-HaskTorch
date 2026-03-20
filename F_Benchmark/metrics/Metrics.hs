{-# LANGUAGE ScopedTypeVariables #-}

module F_Benchmark.Metrics.Metrics
  ( evaluateMetrics,
  )
where

import qualified Torch

-- | Evaluates Accuracy, F1 Score, and Mean Probability Confidence (P+, P-)
--   for a binary classification problem.
evaluateMetrics :: Torch.Tensor -> Torch.Tensor -> Torch.Tensor -> Torch.Tensor -> IO ()
evaluateMetrics probsTrain labelsTrain probsTest labelsTest = do
  let predsTrain = probsTrain `Torch.gt` Torch.asTensor (0.5 :: Float)
      labelsBoolTrain = labelsTrain `Torch.gt` Torch.asTensor (0.5 :: Float)
      correctsTrain = predsTrain `Torch.eq` labelsBoolTrain
      -- Assuming batch size = 50 for the binary example
      accTrain = (Torch.asValue (Torch.sumAll (Torch.toType Torch.Float correctsTrain)) :: Float) / 50.0

  let predsTest = probsTest `Torch.gt` Torch.asTensor (0.5 :: Float)
      labelsBoolTest = labelsTest `Torch.gt` Torch.asTensor (0.5 :: Float)
      correctsTest = predsTest `Torch.eq` labelsBoolTest
      accTest = (Torch.asValue (Torch.sumAll (Torch.toType Torch.Float correctsTest)) :: Float) / 50.0

  let allProbs = Torch.cat (Torch.Dim 0) [probsTrain, probsTest]
      allLabels = Torch.cat (Torch.Dim 0) [labelsTrain, labelsTest]
      posMaskFloat = Torch.toType Torch.Float (allLabels `Torch.gt` Torch.asTensor (0.5 :: Float))
      negMaskFloat = Torch.toType Torch.Float (allLabels `Torch.lt` Torch.asTensor (0.5 :: Float))
      nPos = Torch.asValue (Torch.sumAll posMaskFloat) :: Float
      nNeg = Torch.asValue (Torch.sumAll negMaskFloat) :: Float

      meanPos = if nPos > 0 then Torch.asValue (Torch.sumAll (allProbs * posMaskFloat)) / nPos :: Float else 0.0
      meanNeg = if nNeg > 0 then Torch.asValue (Torch.sumAll (allProbs * negMaskFloat)) / nNeg :: Float else 0.0

  let allPredsF = Torch.toType Torch.Float (allProbs `Torch.gt` Torch.asTensor (0.5 :: Float))
      allLabelsBoolF = Torch.toType Torch.Float (allLabels `Torch.gt` Torch.asTensor (0.5 :: Float))
      notPredsF = Torch.onesLike allPredsF - allPredsF
      notLabelsF = Torch.onesLike allLabelsBoolF - allLabelsBoolF
      tp = Torch.asValue (Torch.sumAll (allPredsF * allLabelsBoolF)) :: Float
      fp = Torch.asValue (Torch.sumAll (allPredsF * notLabelsF)) :: Float
      fn = Torch.asValue (Torch.sumAll (notPredsF * allLabelsBoolF)) :: Float
      precision = if tp + fp > 0 then tp / (tp + fp) else 0.0
      recall = if tp + fn > 0 then tp / (tp + fn) else 0.0
      f1 = if precision + recall > 0 then 2.0 * precision * recall / (precision + recall) else 0.0

  putStrLn $ "Final Evaluation Metrics:"
  putStrLn $ "  Accuracy: Train=" ++ show accTrain ++ ", Test=" ++ show accTest
  putStrLn $ "  Mean Confidence: P+=" ++ show meanPos ++ ", P-=" ++ show meanNeg
  putStrLn $ "  F1 Score: " ++ show f1
