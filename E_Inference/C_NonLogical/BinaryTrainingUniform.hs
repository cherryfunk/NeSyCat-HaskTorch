{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

module E_Inference.C_NonLogical.BinaryTrainingUniform
  ( trainBinaryUniform,
  )
where

import C_NonLogical.A_Signature.BinarySig (BinaryFunS (..), BinarySorts (..))
import qualified B_Logical.D_Interpretation.Tensor as TENS
import C_NonLogical.D_Interpretation.BinaryUniform (setGlobalBinaryMLP)
import C_NonLogical.D_Interpretation.BinaryUniformMLP (Binary_MLP, binarySpec, hTheta)
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
trainBinaryUniform :: Int -> Float -> (Torch.Tensor -> Binary_MLP -> TENS.Omega) -> IO (Binary_MLP, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor)
trainBinaryUniform numEpochs learningRate kbSatFormula = do
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

    -- Metrics: only record loss/sat every 100 epochs
    if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
      then do
        epochEnd <- getCurrentTime
        let lossVal = Torch.asValue avgLoss :: Float
        let satLevel = Torch.asValue kbSatDyn :: Float
        let diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
        putStrLn $ printf "[Epoch %3d/%d] Loss=%7.5f Sat=%.3f | %.2fms" epoch numEpochs lossVal satLevel diffMs
      else return ()

    return (newModel, newOpt)
  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  putStrLn $ printf "[Training complete] Total Time: %5.2fs" totalDiff

  setGlobalBinaryMLP finalModel

  return (finalModel, trainData, trainLabels, testData, testLabels)

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
