{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Train binary classification (TensRealBeta, learnable beta).
--
--   Finds optimal (theta*, beta*) by jointly minimizing:
--     J(theta,beta) = lambda * J_data(theta) + (1-lambda) * J_know(theta,beta)
--
--   Beta controls the sharpness of soft logical connectives.
module Main where

import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import qualified B_Logical.BA_Interpretation.Tensor as TENS
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP, binarySpecReal, hThetaReal)
import D_Grammatical.BA_Interpretation.BinaryIntpTens (binaryAxiomTens)
import E_Inferential.B_Theory.InferenceTheory (InferenceFun (..))
import E_Inferential.BA_Interpretation.InferenceIntpTens ()

import Data.Time.Clock (diffUTCTime, getCurrentTime)
import System.Environment (getArgs)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Autograd (IndependentTensor, makeIndependent, toDependent)
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

main :: IO ()
main = do
  args <- getArgs
  let lambda = case args of { (x:_) -> read x; _ -> 1.0 :: Float }

  -- Train: optimize theta and beta jointly
  (paramMLPOpti, learnedBeta, trainData, trainLabels, testData, testLabels) <-
    trainBinaryRealBeta 1000 0.001 2.0 lambda binaryAxiomTens

  putStrLn $ "Learned beta: " ++ show (Torch.asValue learnedBeta :: Float)

  return ()

-- | One beta-optimization step via manual SGD on the gradient.
--   Clamps beta > 0.01 to stay positive.
stepBeta :: IndependentTensor -> Torch.Tensor -> Float -> IO IndependentTensor
stepBeta betaInd lossTensor lr = do
  let grads = Torch.grad lossTensor [betaInd]
      gradBeta = head grads
      betaDep = toDependent betaInd
      lrT = Torch.asTensor lr
      newBeta = betaDep `Torch.sub` (gradBeta `Torch.mul` lrT)
      epsT = Torch.asTensor (0.01 :: Float)
      clamped = Torch.relu (newBeta `Torch.sub` epsT) `Torch.add` epsT
  makeIndependent clamped

-- | Joint beta + theta training loop.
trainBinaryRealBeta ::
  Int ->
  Float ->
  Float ->
  Float ->
  (Torch.Tensor -> Torch.Tensor -> ParamsMLP -> TENS.Omega) ->
  IO (ParamsMLP, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor)
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

  (paramMLPOpti, _, finalBetaInd) <-
    foldLoop (initModel, initOpt, betaInd) [1 .. numEpochs] $ \(model, opt, bInd) epoch -> do
      let betaVal = toDependent bInd

      -- J_data: pointwise cross-entropy (skipped when lambda=1)
      let dataLoss = if lambda == 1.0 then zeroTens
                     else let preds = Torch.sigmoid (hThetaReal model trainData)
                          in Torch.sumAll (lossData preds trainLabels) `Torch.div` nTens

      -- J_know: axiom satisfaction penalty (skipped when lambda=0)
      let knowLoss = if lambda == 0.0 then zeroTens
                     else lossKnow (toDynamic (kbSatFormula betaVal trainData model))

      -- J = (1-lambda) * J_data + lambda * J_know
      let totalLoss = lossComb dataLoss knowLoss lambdaTens

      -- Step 1: Update theta (MLP weights) via Adam
      (newModel, newOpt) <- runStep model opt totalLoss lrTens

      -- Step 2: Update beta via stepBeta (skipped when lambda=0: no axiom -> no gradient)
      newBInd <- if lambda == 0.0 then return bInd
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


  return (paramMLPOpti, learnedBeta, trainData, trainLabels, testData, testLabels)

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
