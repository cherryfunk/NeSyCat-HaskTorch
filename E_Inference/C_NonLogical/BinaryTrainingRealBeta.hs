{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Joint β + θ training for Binary Classification on TensReal.
--
--   This module lives in D_Inference/D_NonLogical and IMPORTS
--   E_Inference.B_Logical.BetaTrainingReal (the β update step).
--
--   Architecture:
--     B/C_Logical/TensRealBeta  →  E_Grammatical/BinaryFormulasRealBeta
--       →  D/C_Logical/BetaTrainingReal  →  THIS MODULE
--
--   Each epoch:
--     1. Forward: compute sat = axiomRealBeta β data model
--     2. Loss = −log(σ(sat))
--     3. Update θ (MLP weights) via Adam
--     4. Update β via stepBeta from C_Logical
module E_Inference.C_NonLogical.BinaryTrainingRealBeta
  ( trainBinaryRealBeta,
  )
where

import C_NonLogical.A_Signature.BinarySig (Binary_Sig (..))
import qualified B_Logical.C_Category.Tensor as TENS
import C_NonLogical.C_Category.BinaryReal (setGlobalBinaryMLP)
import C_NonLogical.C_Category.BinaryRealMLP (Binary_MLP, binarySpecReal, hThetaReal)
import E_Inference.B_Logical.BetaTrainingReal (stepBeta)
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Autograd (makeIndependent, toDependent)
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Joint β + θ training loop for Binary Classification using TensRealBeta.
--
--   Returns (finalModel, learnedBeta, trainData, trainLabels, testData, testLabels).
trainBinaryRealBeta ::
  Int ->
  Float ->
  Float ->
  (Torch.Tensor -> Torch.Tensor -> Binary_MLP -> TENS.Omega) ->
  IO (Binary_MLP, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor)
trainBinaryRealBeta numEpochs learningRate initBeta kbSatFormula = do
  initModel <- return . toDevice (Device CPU 0) =<< sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)

  -- Initialize β as learnable parameter
  betaInd <- makeIndependent (Torch.asTensor initBeta)

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

  putStrLn $
    "[Joint beta+theta Training] "
      ++ show numEpochs
      ++ " epochs, lr="
      ++ show learningRate
      ++ ", init_beta="
      ++ show initBeta

  let !_ = trainData `seq` trainLabels `seq` testData `seq` testLabels `seq` ()

  startTime <- getCurrentTime
  let lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)

  (finalModel, _, finalBetaInd) <-
    foldLoop (initModel, initOpt, betaInd) [1 .. numEpochs] $ \(model, opt, bInd) epoch -> do
      let betaVal = toDependent bInd
          kbSat = kbSatFormula betaVal trainData model
          kbSatDyn = toDynamic kbSat
          avgLoss = negate (Torch.log (Torch.sigmoid kbSatDyn))

      -- Step 1: Update θ (MLP weights) via Adam
      (newModel, newOpt) <- runStep model opt avgLoss lrTens

      -- Step 2: Update β via stepBeta from C_Logical
      newBInd <- stepBeta bInd avgLoss learningRate

      -- Metrics: only every 100 epochs
      if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
        then do
          epochEnd <- getCurrentTime
          let lossVal = Torch.asValue avgLoss :: Float
          let satLevel = Torch.asValue kbSatDyn :: Float
          let currentBeta = Torch.asValue (toDependent newBInd) :: Float
          let diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
          putStrLn $
            printf
              "[Epoch %3d/%d] Loss=%7.5f Sat=%.3f beta=%.6f | %.2fms"
              epoch numEpochs lossVal satLevel currentBeta diffMs
        else return ()

      return (newModel, newOpt, newBInd)

  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  let learnedBeta = toDependent finalBetaInd
  let learnedBetaVal = Torch.asValue learnedBeta :: Float
  putStrLn $ printf "[Training complete] Total: %5.2fs | Learned beta=%.6f" totalDiff learnedBetaVal

  setGlobalBinaryMLP finalModel

  return (finalModel, learnedBeta, trainData, trainLabels, testData, testLabels)

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
