{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Joint beta + theta training for Binary Classification on TensRealBeta.
--
--   Objective: J(θ,β) = λ · J_data(θ) + (1-λ) · J_know(θ,β)
--     • J_data = cross-entropy between σ(h_θ(x)) and labels
--     • J_know = softplus penalty on axiom satisfaction (depends on β)
module C_NonLogical.G_Parameters.BinaryTrainingRealBeta
  ( trainBinaryRealBeta,
  )
where

import C_NonLogical.D_Theory.BinaryTheory (BinaryFun (..), BinarySorts (..))
import qualified B_Logical.F_Interpretation.Tensor as TENS
import C_NonLogical.F_Interpretation.BinaryReal (setGlobalBinaryMLP)
import C_NonLogical.F_Interpretation.BinaryRealMLP (Binary_MLP, binarySpecReal, hThetaReal)
import E_Inference.A_Objective.Combined (combinedObjective)
import E_Inference.A_Objective.CrossEntropy (crossEntropyLoss)
import E_Inference.A_Objective.Softplus (softplusLoss)
import B_Logical.G_Parameters.BetaTrainingReal (stepBeta)
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Autograd (makeIndependent, toDependent)
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Joint beta + theta training loop.
--
--   J(θ,β) = λ · J_data(θ) + (1-λ) · J_know(θ,β)
trainBinaryRealBeta ::
  Int ->
  Float ->
  Float ->
  Float ->
  (Torch.Tensor -> Torch.Tensor -> Binary_MLP -> TENS.Omega) ->
  IO (Binary_MLP, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor)
trainBinaryRealBeta numEpochs learningRate initBeta lambda kbSatFormula = do
  initModel <- return . toDevice (Device CPU 0) =<< sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)

  -- Initialize beta as learnable parameter
  betaInd <- makeIndependent (Torch.asTensor initBeta)

  -- Generate 100 random points in [0, 1]^2
  dataset <- Torch.toDevice (Device CPU 0) <$> Torch.randIO' [100, 2]
  let center = Torch.toDevice (Device CPU 0) (Torch.asTensor ([0.5, 0.5] :: [Float]))
      diffs = dataset - center
      sq = diffs * diffs
      distances = Torch.sumDim (Torch.Dim 1) Torch.RemoveDim Torch.Float sq
      labelsBool = distances `Torch.lt` Torch.asTensor (0.09 :: Float)
      labels = Torch.toType Torch.Float labelsBool

      trainData = Torch.sliceDim 0 0 50 1 dataset
      trainLabels = Torch.reshape [50, 1] (Torch.sliceDim 0 0 50 1 labels)

      testData = Torch.sliceDim 0 0 50 1 (Torch.sliceDim 0 50 100 1 dataset)
      testLabels = Torch.reshape [50, 1] (Torch.sliceDim 0 0 50 1 (Torch.sliceDim 0 50 100 1 labels))

  putStrLn $
    "[Joint beta+theta Training] "
      ++ show numEpochs
      ++ " epochs, lr="
      ++ show learningRate
      ++ ", init_beta="
      ++ show initBeta
      ++ ", lambda="
      ++ show lambda

  let !_ = trainData `seq` trainLabels `seq` testData `seq` testLabels `seq` ()

  startTime <- getCurrentTime
  let lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)
      nTens = Torch.toDevice (Device CPU 0) (Torch.asTensor (50.0 :: Float))
      zeroTens = Torch.asTensor (0.0 :: Float)
      lambdaTens = Torch.asTensor lambda

  (finalModel, _, finalBetaInd) <-
    foldLoop (initModel, initOpt, betaInd) [1 .. numEpochs] $ \(model, opt, bInd) epoch -> do
      let betaVal = toDependent bInd

      -- ── J_data: pointwise cross-entropy (skipped when λ=0) ───────────
      let dataLoss = if lambda == 0.0 then zeroTens
                     else let preds = Torch.sigmoid (hThetaReal model trainData)
                          in Torch.sumAll (crossEntropyLoss preds trainLabels) `Torch.div` nTens

      -- ── J_know: axiom satisfaction penalty (skipped when λ=1) ────────
      let knowLoss = if lambda == 1.0 then zeroTens
                     else softplusLoss (toDynamic (kbSatFormula betaVal trainData model))

      -- ── J = λ · J_data + (1-λ) · J_know ─────────────────────────────
      let totalLoss = combinedObjective dataLoss knowLoss lambdaTens

      -- Step 1: Update theta (MLP weights) via Adam
      (newModel, newOpt) <- runStep model opt totalLoss lrTens

      -- Step 2: Update beta via stepBeta (skipped when λ=1: no axiom → no gradient)
      newBInd <- if lambda == 1.0 then return bInd
                 else stepBeta bInd totalLoss learningRate

      -- Metrics: only every 100 epochs
      if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
        then do
          epochEnd <- getCurrentTime
          let dataVal = Torch.asValue dataLoss :: Float
          let knowVal = Torch.asValue knowLoss :: Float
          let totalVal = Torch.asValue totalLoss :: Float
          let currentBeta = Torch.asValue (toDependent newBInd) :: Float
          let diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
          putStrLn $
            printf
              "[Epoch %3d/%d] J_data=%7.5f J_know=%7.5f J=%7.5f beta=%.6f | %.2fms"
              epoch numEpochs dataVal knowVal totalVal currentBeta diffMs
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
