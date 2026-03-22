{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Benchmark for binary classification with learnable beta.
--   Trains jointly on theta and beta, then evaluates via classifierA @FrmwkMeas.
module Main where

import A_Categorical.BA_Interpretation.StarIntp (FrmwkMeas)
import B_Logical.DA_Realization.ExpectDist (pTrueDist)
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import qualified B_Logical.BA_Interpretation.Tensor as TENS
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP, binarySpecReal, hThetaReal)
import D_Grammatical.BA_Interpretation.BinaryIntpTens (binaryAxiomTens)
import E_Inferential.B_Theory.InferenceTheory (InferenceFun (..))
import E_Inferential.BA_Interpretation.InferenceIntpTens ()
import F_Statistical.B_Theory.BenchmarkTheory (BenchmarkFun (..))
import F_Statistical.BA_Interpretation.BenchmarkIntpData ()

import Data.Time.Clock (diffUTCTime, getCurrentTime)
import System.Environment (getArgs)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Autograd (IndependentTensor, makeIndependent, toDependent)
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

main :: IO ()
main = do
  args <- getArgs
  let initBeta = case args of { (x:_) -> read x; _ -> 2.0 :: Float }

  -- Train with learnable beta
  (paramMLPOpti, learnedBeta, trainData, _, testData, _) <-
    trainBinaryBeta 1000 0.001 initBeta 1.0 binaryAxiomTens
  let learnedBetaVal = Torch.asValue learnedBeta :: Float

  -- Evaluate via classifierA @FrmwkMeas (pass theta* directly)
  let toPairs pts = [(predProb pt, labelA @FrmwkMeas pt) | pt <- pts]
        where predProb pt = pTrueDist (classifierA @FrmwkMeas paramMLPOpti pt)
      trainPts = map (\[x1,x2] -> (x1,x2)) (Torch.asValue trainData :: [[Float]]) :: [Point FrmwkMeas]
      testPts  = map (\[x1,x2] -> (x1,x2)) (Torch.asValue testData  :: [[Float]]) :: [Point FrmwkMeas]
      trainPairs = toPairs trainPts
      testPairs  = toPairs testPts
      accTrain = accuracy trainPairs
      accTest  = accuracy testPairs
      f1   = f1Score testPairs
      prec = precision testPairs
      rec  = recall testPairs
      (pPos, pNeg) = confidence testPairs

  putStrLn $ printf "Binary Benchmark Beta (learned beta=%.4f):" learnedBetaVal
  putStrLn $ printf "  Accuracy:        Train=%.4f  Test=%.4f" accTrain accTest
  putStrLn $ printf "  F1 Score:        %.4f" f1
  putStrLn $ printf "  Precision:       %.4f  Recall: %.4f" prec rec
  putStrLn $ printf "  Confidence:      P+=%.4f  P-=%.4f" pPos pNeg

-- | Joint beta + theta training loop.
trainBinaryBeta ::
  Int -> Float -> Float -> Float ->
  (Torch.Tensor -> Torch.Tensor -> ParamsMLP -> TENS.Omega) ->
  IO (ParamsMLP, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor, Torch.Tensor)
trainBinaryBeta numEpochs learningRate initBeta lambda kbSatFormula = do
  initModel <- toDevice (Device CPU 0) <$> sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
  betaInd <- makeIndependent (Torch.asTensor initBeta)

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

  let !_ = trainData `seq` trainLabels `seq` testData `seq` testLabels `seq` ()

  startTime <- getCurrentTime
  let lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)
      nTens = Torch.toDevice (Device CPU 0) (Torch.asTensor (50.0 :: Float))
      zeroTens = Torch.asTensor (0.0 :: Float)
      lambdaTens = Torch.asTensor lambda

  (paramMLPOpti, _, finalBetaInd) <-
    foldLoop (initModel, initOpt, betaInd) [1 .. numEpochs] $ \(model, opt, bInd) epoch -> do
      let betaVal = toDependent bInd
      let dataLoss = if lambda == 1.0 then zeroTens
                     else let preds = Torch.sigmoid (hThetaReal model trainData)
                          in Torch.sumAll (lossData preds trainLabels) `Torch.div` nTens
      let knowLoss = if lambda == 0.0 then zeroTens
                     else lossKnow (toDynamic (kbSatFormula betaVal trainData model))
      let totalLoss = lossComb dataLoss knowLoss lambdaTens
      (newModel, newOpt) <- runStep model opt totalLoss lrTens
      newBInd <- if lambda == 0.0 then return bInd
                 else stepBeta bInd totalLoss learningRate
      if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
        then do
          epochEnd <- getCurrentTime
          let totalVal = Torch.asValue totalLoss :: Float
          let currentBeta = Torch.asValue (toDependent newBInd) :: Float
          let diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
          putStrLn $ printf "[Epoch %3d/%d] J=%7.5f beta=%.4f | %.2fms" epoch numEpochs totalVal currentBeta diffMs
        else return ()
      return (newModel, newOpt, newBInd)

  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  let learnedBeta = toDependent finalBetaInd
  putStrLn $ printf "[Training complete] %.2fs" totalDiff
  return (paramMLPOpti, learnedBeta, trainData, trainLabels, testData, testLabels)

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

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
