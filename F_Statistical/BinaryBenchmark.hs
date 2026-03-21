{-# LANGUAGE TypeApplications #-}

-- | Benchmark executable for binary classification.
--
--   1. Trains in TENS (produces theta*)
--   2. Evaluates classifierA @DATA per test point -> Dist Bool -> Double
--   3. Compares to labelA @DATA ground truth
--   4. Reports accuracy, confidence, F1 via BenchmarkTheory
--
--   Usage:
--     cabal run binary-benchmark              -- default beta=1.0
--     cabal run binary-benchmark -- 1.5       -- single run with beta=1.5
module Main where

import A_Categorical.DA_Realization.Dist (Dist)
import B_Logical.DA_Realization.ExpectDist (pTrueDist)
import C_Domain.C_TypeSystem.Data (DATA (..))
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
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

main :: IO ()
main = do
  args <- getArgs
  let beta = case args of { (x:_) -> read x; _ -> 1.0 :: Float }

  -- Generate dataset (same circle-in-square)
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

  -- Train in TENS -> theta*
  paramMLPOpti <- trainBinary 1000 0.001 0.0 beta trainData trainLabels binaryAxiomTens

  -- Evaluate via classifierA @DATA (pass theta* directly, no global state)
  let toPairs pts = [(predProb pt, labelA @DATA pt) | pt <- pts]
        where predProb pt = pTrueDist (classifierA @DATA @Dist paramMLPOpti pt)
      -- Train + test points
      trainPts = map (\[x1,x2] -> (x1,x2)) (Torch.asValue trainData :: [[Float]]) :: [Point DATA]
      testPts  = map (\[x1,x2] -> (x1,x2)) (Torch.asValue testData  :: [[Float]]) :: [Point DATA]
      trainPairs = toPairs trainPts
      testPairs  = toPairs testPts
      -- Accuracy: report both train and test
      accTrain = accuracy trainPairs
      accTest  = accuracy testPairs
      -- F1/precision/recall/confidence: test only (standard practice)
      f1   = f1Score testPairs
      prec = precision testPairs
      rec  = recall testPairs
      (pPos, pNeg) = confidence testPairs

  putStrLn "Binary Benchmark (classifierA @DATA):"
  putStrLn $ printf "  Accuracy:        Train=%.4f  Test=%.4f" accTrain accTest
  putStrLn $ printf "  F1 Score:        %.4f" f1
  putStrLn $ printf "  Precision:       %.4f  Recall: %.4f" prec rec
  putStrLn $ printf "  Confidence:      P+=%.4f  P-=%.4f" pPos pNeg


-- | Training loop (TENS only, produces theta*).
trainBinary ::
  Int -> Float -> Float -> Float ->
  Torch.Tensor -> Torch.Tensor ->
  (Torch.Tensor -> Torch.Tensor -> ParamsMLP -> TENS.Omega) ->
  IO ParamsMLP
trainBinary numEpochs learningRate lambda betaFixed trainData trainLabels kbSatFormula = do
  initModel <- toDevice (Device CPU 0) <$> sample binarySpecReal
  let initOpt = mkAdam 0 0.9 0.999 (flattenParameters initModel)
      betaT = Torch.asTensor betaFixed
      lrTens = Torch.toDevice (Device CPU 0) (Torch.asTensor learningRate)
      nTens = Torch.toDevice (Device CPU 0) (Torch.asTensor (50.0 :: Float))
      zeroTens = Torch.asTensor (0.0 :: Float)
      lambdaTens = Torch.asTensor lambda

  startTime <- getCurrentTime
  (paramMLPOpti, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) epoch -> do
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
        let diffMs = (realToFrac (diffUTCTime epochEnd startTime) :: Double) * 1000
        let totalVal = Torch.asValue totalLoss :: Float
        putStrLn $ printf "[Epoch %3d/%d] J=%7.5f | %.2fms" epoch numEpochs totalVal diffMs
      else return ()
    return (newModel, newOpt)

  totalEnd <- getCurrentTime
  let totalDiff = realToFrac (diffUTCTime totalEnd startTime) :: Double
  putStrLn $ printf "[Training complete] %.2fs" totalDiff
  return paramMLPOpti

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
