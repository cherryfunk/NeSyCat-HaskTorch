{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | Binary classification training library.
--   Exports the training loop and dataset generation.
--   Training only -- no benchmarking, no metrics.
module BinaryTrainLib
  ( trainBinary,
    trainBinaryBeta,
    generateBinaryDataset,
    BinaryDataset (..),
  )
where

import qualified B_Logical.BA_Interpretation.Tensor as TENS
import C_Domain.BA_Interpretation.BinaryRealMLP (ParamsMLP, binarySpecReal, hThetaReal)
import D_Grammatical.BA_Interpretation.BinaryIntpTens (binaryAxiomTens)
import E_Inferential.B_Theory.InferenceTheory (InferenceFun (..))
import E_Inferential.BA_Interpretation.InferenceIntpTens ()

import Data.Time.Clock (diffUTCTime, getCurrentTime)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Autograd (IndependentTensor (..), makeIndependent, toDependent)
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.NN ()
import Torch.Typed.Tensor (Tensor (..), toDynamic)

-- | A binary classification dataset (circle-in-square).
data BinaryDataset = BinaryDataset
  { trainData :: Torch.Tensor,
    trainLabels :: Torch.Tensor,
    testData :: Torch.Tensor,
    testLabels :: Torch.Tensor
  }

-- | Generate 100 random points in [0,1]^2 with circle-in-square labels.
--   50 train / 50 test split.
generateBinaryDataset :: IO BinaryDataset
generateBinaryDataset = do
  dataset <- Torch.toDevice (Device CPU 0) <$> Torch.randIO' [100, 2]
  let center = Torch.toDevice (Device CPU 0) (Torch.asTensor ([0.5, 0.5] :: [Float]))
      diffs = dataset - center
      sq = diffs * diffs
      distances = Torch.sumDim (Torch.Dim 1) Torch.RemoveDim Torch.Float sq
      labelsBool = distances `Torch.lt` Torch.asTensor (0.09 :: Float)
      labels = Torch.toType Torch.Float labelsBool
  return
    BinaryDataset
      { trainData = Torch.sliceDim 0 0 50 1 dataset,
        trainLabels = Torch.reshape [50, 1] (Torch.sliceDim 0 0 50 1 labels),
        testData = Torch.sliceDim 0 0 50 1 (Torch.sliceDim 0 50 100 1 dataset),
        testLabels = Torch.reshape [50, 1] (Torch.sliceDim 0 0 50 1 (Torch.sliceDim 0 50 100 1 labels))
      }

-- | Train binary classification via the inferential level.
--   J(theta) = (1-lambda) * J_data + lambda * J_know
--   Returns optimized parameters theta*.
trainBinary ::
  Int ->    -- epochs
  Float ->  -- learning rate
  Float ->  -- lambda (0=pure data, 1=pure axiom)
  Float ->  -- beta (LogSumExp sharpness)
  BinaryDataset ->
  IO ParamsMLP
trainBinary numEpochs learningRate lambda betaFixed ds = do
  initModel <- toDevice (Device CPU 0) <$> sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
      td = trainData ds
      tl = trainLabels ds

  putStrLn $
    printf "[Training] %d epochs, beta=%.2f, lr=%.4f, lambda=%.2f"
      numEpochs betaFixed learningRate lambda

  let !_ = td `seq` tl `seq` ()

  startTime <- getCurrentTime
  let betaT = Torch.asTensor betaFixed
      lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)
      nTens = Torch.toDevice (Device CPU 0) (Torch.asTensor (fromIntegral (head (Torch.shape td)) :: Float))
      zeroTens = Torch.asTensor (0.0 :: Float)
      lambdaTens = Torch.asTensor lambda

  (paramMLPOpti, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do
    let dataLoss =
          if lambda == 1.0
            then zeroTens
            else
              let preds = Torch.sigmoid (hThetaReal model td)
               in Torch.sumAll (lossData preds tl) `Torch.div` nTens
    let knowLoss =
          if lambda == 0.0
            then zeroTens
            else lossKnow (toDynamic (binaryAxiomTens betaT td model))
    let totalLoss = lossComb dataLoss knowLoss lambdaTens
    (newModel, newOpt) <- runStep model opt totalLoss lrTens
    if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
      then do
        epochEnd <- getCurrentTime
        let totalVal = Torch.asValue totalLoss :: Float
            diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
        putStrLn $ printf "[Epoch %3d/%d] J=%7.5f | %.2fms" epoch numEpochs totalVal diffMs
      else return ()
    return (newModel, newOpt)

  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  putStrLn $ printf "[Training complete] %.2fs" totalDiff

  return paramMLPOpti

-- | Train binary classification with learnable beta.
--   J(theta,beta) = (1-lambda) * J_data + lambda * J_know
--   Returns (theta*, learned beta).
trainBinaryBeta ::
  Int ->    -- epochs
  Float ->  -- learning rate
  Float ->  -- initial beta
  Float ->  -- lambda (0=pure data, 1=pure axiom)
  BinaryDataset ->
  IO (ParamsMLP, Torch.Tensor)
trainBinaryBeta numEpochs learningRate initBeta lambda ds = do
  initModel <- toDevice (Device CPU 0) <$> sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
      td = trainData ds
      tl = trainLabels ds
  betaInd <- makeIndependent (Torch.asTensor initBeta)

  putStrLn $
    printf "[Training] %d epochs, init_beta=%.2f, lr=%.4f, lambda=%.2f"
      numEpochs initBeta learningRate lambda

  let !_ = td `seq` tl `seq` ()

  startTime <- getCurrentTime
  let lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)
      nTens = Torch.toDevice (Device CPU 0) (Torch.asTensor (fromIntegral (head (Torch.shape td)) :: Float))
      zeroTens = Torch.asTensor (0.0 :: Float)
      lambdaTens = Torch.asTensor lambda

  (paramMLPOpti, _, finalBetaInd) <-
    foldLoop (initModel, initOpt, betaInd) [1 .. numEpochs] $ \(model, opt, bInd) epoch -> do
      let betaVal = toDependent bInd
      let dataLoss =
            if lambda == 1.0
              then zeroTens
              else
                let preds = Torch.sigmoid (hThetaReal model td)
                 in Torch.sumAll (lossData preds tl) `Torch.div` nTens
      let knowLoss =
            if lambda == 0.0
              then zeroTens
              else lossKnow (toDynamic (binaryAxiomTens betaVal td model))
      let totalLoss = lossComb dataLoss knowLoss lambdaTens
      (newModel, newOpt) <- runStep model opt totalLoss lrTens
      newBInd <-
        if lambda == 0.0
          then return bInd
          else stepBeta bInd totalLoss learningRate
      if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
        then do
          epochEnd <- getCurrentTime
          let totalVal = Torch.asValue totalLoss :: Float
              currentBeta = Torch.asValue (toDependent newBInd) :: Float
              diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
          putStrLn $ printf "[Epoch %3d/%d] J=%7.5f beta=%.4f | %.2fms" epoch numEpochs totalVal currentBeta diffMs
        else return ()
      return (newModel, newOpt, newBInd)

  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
      learnedBeta = toDependent finalBetaInd
      learnedBetaVal = Torch.asValue learnedBeta :: Float
  putStrLn $ printf "[Training complete] %.2fs | learned beta=%.4f" totalDiff learnedBetaVal

  return (paramMLPOpti, learnedBeta)

-- | One beta-optimization step via manual SGD. Clamps beta > 0.01.
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
