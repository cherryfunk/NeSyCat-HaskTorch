{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Training loop for Binary Classification using TensReal logic.
--
--   Objective: J(θ) = λ · J_data(θ) + (1-λ) · J_know(θ)
--     • J_data = cross-entropy between σ(h_θ(x)) and labels
--     • J_know = softplus penalty on axiom satisfaction
module C_NonLogical.G_Parameters.BinaryTrainingReal
  ( trainBinaryReal,
  )
where

import C_NonLogical.D_Theory.BinaryTheory (BinaryFun (..), BinarySorts (..))
import qualified B_Logical.F_Interpretation.Tensor as TENS
import C_NonLogical.F_Interpretation.BinaryReal (setGlobalBinaryMLP)
import C_NonLogical.F_Interpretation.BinaryRealMLP (Binary_MLP, binarySpecReal, hThetaReal)
import E_Inference.A_Objective.Combined (combinedObjective)
import E_Inference.A_Objective.CrossEntropy (crossEntropyLoss)
import E_Inference.A_Objective.Softplus (softplusLoss)
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | Training loop for Binary Classification using TensReal logic.
--
--   J(θ) = λ · J_data(θ) + (1-λ) · J_know(θ)
--
--   J_data: pointwise cross-entropy between σ(h_θ(x)) and labels y.
--   J_know: softplus penalty on the axiom satisfaction level.
--
--   When λ=0, this is pure axiom-driven learning.
--   When λ=1, this is pure data-driven learning (cross-entropy only).
trainBinaryReal ::
  Int ->
  Float ->
  Float ->
  (Torch.Tensor -> Binary_MLP -> TENS.Omega) ->
  IO (Binary_MLP, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor)
trainBinaryReal numEpochs learningRate lambda kbSatFormula = do
  initModel <- return . toDevice (Device CPU 0) =<< sample binarySpecReal
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

  putStrLn $
    "[Training] "
      ++ show numEpochs
      ++ " epochs, empirical measure ("
      ++ show (50 :: Int)
      ++ " pts), Adam lr="
      ++ show learningRate
      ++ ", lambda="
      ++ show lambda

  let !_ = trainData `seq` trainLabels `seq` testData `seq` testLabels `seq` ()

  startTime <- getCurrentTime
  let lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)
      nTens = Torch.toDevice (Device CPU 0) (Torch.asTensor (50.0 :: Float))
      zeroTens = Torch.asTensor (0.0 :: Float)
      lambdaTens = Torch.asTensor lambda

  (finalModel, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do
    -- -- J_data: pointwise cross-entropy (skipped when lambda=0) -------
    let dataLoss = if lambda == 0.0 then zeroTens
                   else let preds = Torch.sigmoid (hThetaReal model trainData)
                        in Torch.sumAll (crossEntropyLoss preds trainLabels) `Torch.div` nTens

    -- -- J_know: axiom satisfaction penalty (skipped when lambda=1) ----
    let knowLoss = if lambda == 1.0 then zeroTens
                   else softplusLoss (toDynamic (kbSatFormula trainData model))

    -- -- J = lambda * J_data + (1-lambda) * J_know --------------------
    let totalLoss = combinedObjective dataLoss knowLoss lambdaTens

    (newModel, newOpt) <- runStep model opt totalLoss lrTens

    -- Metrics: only evaluated every 100 epochs (NOT in the hot path)
    if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
      then do
        epochEnd <- getCurrentTime
        let dataVal = Torch.asValue dataLoss :: Float
        let knowVal = Torch.asValue knowLoss :: Float
        let totalVal = Torch.asValue totalLoss :: Float
        let diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
        putStrLn $
          printf
            "[Epoch %3d/%d] J_data=%7.5f J_know=%7.5f J=%7.5f | %.2fms"
            epoch numEpochs dataVal knowVal totalVal diffMs
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
