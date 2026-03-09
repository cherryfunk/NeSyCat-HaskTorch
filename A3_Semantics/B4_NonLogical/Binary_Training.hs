{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module A3_Semantics.B4_NonLogical.Binary_Training
  ( trainBinary,
  )
where

import A1_Syntax.B4_NonLogical.Binary_Vocab (Binary_Vocab (..))
import qualified A2_Interpretation.B3_Logical.Tensor as TENS
import A2_Interpretation.B4_NonLogical.Binary (setGlobalBinaryMLP)
import A2_Interpretation.B4_NonLogical.Binary_MLP (Binary_MLP, binarySpec, hTheta)
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Training loop for Binary Classification.
--   The axiom takes training data (empirical measure) and the model.
trainBinary :: Int -> Float -> (Torch.Tensor -> Binary_MLP -> TENS.Omega) -> IO Binary_MLP
trainBinary numEpochs learningRate kbSatFormula = do
  initModel <- return . toDevice (Device CPU 0) =<< sample binarySpec
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)

  -- Generate 100 random points in [0, 1]^2
  dataset <- Torch.toDevice (Device CPU 0) <$> Torch.randIO' [100, 2]
  let center = Torch.toDevice (Device CPU 0) (Torch.asTensor ([0.5, 0.5] :: [Float]))
      diffs = dataset - center
      sq = diffs * diffs
      distances = Torch.sumDim (Torch.Dim 1) Torch.RemoveDim Torch.Float sq
      labelsBool = distances `Torch.lt` Torch.asTensor (0.09 :: Float)
      labels = Torch.toType Torch.Float labelsBool

      -- subset the first 50 for training
      trainData = Torch.sliceDim 0 0 50 1 dataset
      trainLabels = Torch.reshape [50, 1] (Torch.sliceDim 0 0 50 1 labels)

      -- subset the remaining 50 for testing
      testData = Torch.sliceDim 0 0 50 1 (Torch.sliceDim 0 50 100 1 dataset)
      testLabels = Torch.reshape [50, 1] (Torch.sliceDim 0 0 50 1 (Torch.sliceDim 0 50 100 1 labels))

  putStrLn $ "[Training] " ++ show numEpochs ++ " epochs, empirical measure (" ++ show (50 :: Int) ++ " pts), Adam lr=" ++ show learningRate

  let !_ = trainData `seq` trainLabels `seq` testData `seq` testLabels `seq` ()

  startTime <- getCurrentTime
  let oneTens = Torch.toDevice (Device CPU 0) (Torch.asTensor (1.0 :: Float))
  let lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)

  (finalModel, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do

    -- Hot inner loop: ONLY axiom + loss + optimizer step
    let kbSat = kbSatFormula trainData model
        kbSatDyn = toDynamic kbSat
        avgLoss = oneTens `Torch.sub` kbSatDyn

    (newModel, newOpt) <- runStep model opt avgLoss lrTens

    -- Metrics: only evaluated every 100 epochs (NOT in the hot path)
    if epoch `mod` 100 == 0 || epoch == 1000 || epoch == 1
      then do
        epochStart <- getCurrentTime
        setGlobalBinaryMLP model
        let lossVal = Torch.asValue avgLoss :: Float
        -- Sat Level (matching LTN's metric: the pME value itself)
        let satLevel = Torch.asValue kbSatDyn :: Float

        -- Train Accuracy + Confidence
        let probsTrain = hTheta model trainData
            predsTrain = probsTrain `Torch.gt` Torch.asTensor (0.5 :: Float)
            labelsBoolTrain = trainLabels `Torch.gt` Torch.asTensor (0.5 :: Float)
            correctsTrain = predsTrain `Torch.eq` labelsBoolTrain
            accTrain = (Torch.asValue (Torch.sumAll (Torch.toType Torch.Float correctsTrain)) :: Float) / 50.0

        -- Test Accuracy + Confidence
        let probsTest = hTheta model testData
            predsTest = probsTest `Torch.gt` Torch.asTensor (0.5 :: Float)
            labelsBoolTest = testLabels `Torch.gt` Torch.asTensor (0.5 :: Float)
            correctsTest = predsTest `Torch.eq` labelsBoolTest
            accTest = (Torch.asValue (Torch.sumAll (Torch.toType Torch.Float correctsTest)) :: Float) / 50.0

        -- Mean Confidence per class (over combined train+test)
        let allProbs = Torch.cat (Torch.Dim 0) [probsTrain, probsTest]
            allLabels = Torch.cat (Torch.Dim 0) [trainLabels, testLabels]
            posMaskFloat = Torch.toType Torch.Float (allLabels `Torch.gt` Torch.asTensor (0.5 :: Float))
            negMaskFloat = Torch.toType Torch.Float (allLabels `Torch.lt` Torch.asTensor (0.5 :: Float))
            nPos = Torch.asValue (Torch.sumAll posMaskFloat) :: Float
            nNeg = Torch.asValue (Torch.sumAll negMaskFloat) :: Float
            -- Mean P(A|x) for positive class (should be close to 1.0)
            meanPos = if nPos > 0 then Torch.asValue (Torch.sumAll (allProbs * posMaskFloat)) / nPos :: Float else 0.0
            -- Mean P(A|x) for negative class (should be close to 0.0)
            meanNeg = if nNeg > 0 then Torch.asValue (Torch.sumAll (allProbs * negMaskFloat)) / nNeg :: Float else 0.0

        -- F1 Score (over combined train+test, threshold=0.5)
        let allPredsF = Torch.toType Torch.Float (allProbs `Torch.gt` Torch.asTensor (0.5 :: Float))
            allLabelsBoolF = Torch.toType Torch.Float (allLabels `Torch.gt` Torch.asTensor (0.5 :: Float))
            notPredsF = Torch.onesLike allPredsF - allPredsF
            notLabelsF = Torch.onesLike allLabelsBoolF - allLabelsBoolF
            tp = Torch.asValue (Torch.sumAll (allPredsF * allLabelsBoolF)) :: Float
            fp = Torch.asValue (Torch.sumAll (allPredsF * notLabelsF)) :: Float
            fn = Torch.asValue (Torch.sumAll (notPredsF * allLabelsBoolF)) :: Float
            precision = if tp + fp > 0 then tp / (tp + fp) else 0.0
            recall    = if tp + fn > 0 then tp / (tp + fn) else 0.0
            f1        = if precision + recall > 0 then 2.0 * precision * recall / (precision + recall) else 0.0

        epochEnd <- getCurrentTime
        let diffMs = (realToFrac (diffUTCTime epochEnd epochStart) :: Double) * 1000
        putStrLn $ printf "[Epoch %3d/%d] Loss=%7.5f Sat=%.3f | Acc Tr=%.2f Te=%.2f | MeanPos=%.3f MeanNeg=%.3f | F1=%.3f | %.2fms" epoch numEpochs lossVal satLevel accTrain accTest meanPos meanNeg f1 diffMs
      else return ()

    return (newModel, newOpt)
  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  putStrLn $ printf "[Training complete] Total Time: %5.2fs" totalDiff

  setGlobalBinaryMLP finalModel

  -- Export to Python for Plotting
  putStrLn "\n--- HASKELL_EXPORT_START ---"
  putStrLn "TRAIN_DATA"
  print (Torch.asValue trainData :: [[Float]])
  putStrLn "TRAIN_LABELS"
  print (Torch.asValue trainLabels :: [[Float]])
  putStrLn "TRAIN_PROBS"
  print (Torch.asValue (hTheta finalModel trainData) :: [[Float]])
  putStrLn "TEST_DATA"
  print (Torch.asValue testData :: [[Float]])
  putStrLn "TEST_LABELS"
  print (Torch.asValue testLabels :: [[Float]])
  putStrLn "TEST_PROBS"
  print (Torch.asValue (hTheta finalModel testData) :: [[Float]])
  putStrLn "--- HASKELL_EXPORT_END ---\n"

  return finalModel

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
