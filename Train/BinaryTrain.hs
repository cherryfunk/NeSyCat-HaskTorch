{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- | Train binary classification (TensReal).
--
--   Finds optimal theta* by minimizing:
--     J(theta) = lambda * J_data(theta) + (1-lambda) * J_know(theta)
--
--   J_data = cross-entropy between sigma(h_theta(x)) and labels
--   J_know = softplus penalty on axiom satisfaction
--
--   Usage:
--     cabal run binary-test-real              -- default beta=1.0
--     cabal run binary-test-real -- 1.5       -- single run with beta=1.5
module Main where

import C_Domain.A_Category.Data (DATA (..))
import C_Domain.D_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import qualified B_Logical.F_Interpretation.Tensor as TENS
import C_Domain.F_Interpretation.BinaryReal (setGlobalBinaryMLP)
import C_Domain.F_Interpretation.BinaryRealMLP (Binary_MLP, binarySpecReal, hThetaReal)
import D_Grammatical.F_Interpretation.BinaryIntpTens (binaryAxiomTens)
import E_Inference.D_Theory.InferenceTheory (InferenceFun (..))
import E_Inference.F_Interpretation.InferenceIntpTens ()
import F_Benchmark.Metrics.Metrics (evaluateMetrics)
import Data.Time.Clock (diffUTCTime, getCurrentTime)
import System.Environment (getArgs)
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (Adam (..), mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

main :: IO ()
main = do
  args <- getArgs
  let beta = case args of { (x:_) -> read x; _ -> 1.0 :: Float }

  -- Generate dataset
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

  -- Train: optimize theta to satisfy the axiom
  finalModel <- trainBinaryReal 1000 0.001 0.0 beta trainData trainLabels binaryAxiomTens

  -- Evaluate
  evaluateMetrics
    (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels
    (Torch.sigmoid (hThetaReal finalModel testData)) testLabels

  -- Inference in DATA category
  print (classifierA @DATA () (0.5 :: Float, 0.5 :: Float))
  print (classifierA @DATA () (0.9 :: Float, 0.9 :: Float))

-- | Training loop for Binary Classification using TensReal logic.
trainBinaryReal ::
  Int -> Float -> Float -> Float ->
  Torch.Tensor -> Torch.Tensor ->
  (Torch.Tensor -> Torch.Tensor -> Binary_MLP -> TENS.Omega) ->
  IO Binary_MLP
trainBinaryReal numEpochs learningRate lambda betaFixed trainData trainLabels kbSatFormula = do
  initModel <- return . toDevice (Device CPU 0) =<< sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)

  putStrLn $ "[Training] " ++ show numEpochs ++ " epochs, beta=" ++ show betaFixed
          ++ ", Adam lr=" ++ show learningRate ++ ", lambda=" ++ show lambda

  let !_ = trainData `seq` trainLabels `seq` ()

  startTime <- getCurrentTime
  let betaT = Torch.asTensor betaFixed
      lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)
      nTens = Torch.toDevice (Device CPU 0) (Torch.asTensor (50.0 :: Float))
      zeroTens = Torch.asTensor (0.0 :: Float)
      lambdaTens = Torch.asTensor lambda

  (finalModel, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do
    let dataLoss = if lambda == 0.0 then zeroTens
                   else let preds = Torch.sigmoid (hThetaReal model trainData)
                        in Torch.sumAll (lossData preds trainLabels) `Torch.div` nTens
    let knowLoss = if lambda == 1.0 then zeroTens
                   else lossKnow (toDynamic (kbSatFormula betaT trainData model))
    let totalLoss = lossComb dataLoss knowLoss lambdaTens
    (newModel, newOpt) <- runStep model opt totalLoss lrTens
    if epoch `mod` 100 == 0 || epoch == numEpochs || epoch == 1
      then do
        epochEnd <- getCurrentTime
        let dataVal = Torch.asValue dataLoss :: Float
        let knowVal = Torch.asValue knowLoss :: Float
        let totalVal = Torch.asValue totalLoss :: Float
        let diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
        putStrLn $ printf "[Epoch %3d/%d] J_data=%7.5f J_know=%7.5f J=%7.5f | %.2fms"
            epoch numEpochs dataVal knowVal totalVal diffMs
      else return ()
    return (newModel, newOpt)

  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  putStrLn $ printf "[Training complete] Total Time: %5.2fs" totalDiff

  setGlobalBinaryMLP finalModel
  return finalModel

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
