{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Lambda sweep benchmark for binary classification.
--
--   Sweeps lambda from 0.0 (pure data) to 1.0 (pure axiom) in steps of 0.25.
--   Each setting is run 10 times with independent random datasets.
--   Reports mean and std of test accuracy and F1 score.
--
--   Convention: J = (1-lambda) * J_data + lambda * J_know
--     lambda=0: pure data supervision
--     lambda=1: pure axiom supervision (knowledge-driven)
--
--   Usage: cabal run lambda-sweep
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
import Text.Printf (printf)
import Torch (Parameterized (..), Randomizable (..))
import qualified Torch
import Torch.Device (Device (..), DeviceType (..))
import Torch.Optim (mkAdam, runStep)
import Torch.Tensor (toDevice)
import Torch.Typed.Tensor (Tensor (..), toDynamic)

main :: IO ()
main = do
  let lambdas = [0.0, 0.25, 0.5, 0.75, 1.0] :: [Float]
      nRuns   = 10 :: Int
      beta    = 1.0 :: Float

  putStrLn "=== Lambda Sweep: lambda=0 (pure data) to lambda=1 (pure axiom) ==="
  putStrLn $ printf "  %d runs per setting, beta=%.1f, 1000 epochs, 50 train / 50 test" nRuns beta
  putStrLn ""

  startTime <- getCurrentTime

  results <- mapM (\lam -> do
    putStrLn $ printf "--- lambda=%.2f ---" lam
    runs <- mapM (\i -> do
      (accTest, f1Test) <- singleRun lam beta
      if i `mod` 5 == 0
        then putStrLn $ printf "  [%2d/%d] Acc=%.4f F1=%.4f" i nRuns accTest f1Test
        else return ()
      return (accTest, f1Test)
      ) [1..nRuns]

    let accs = map fst runs
        f1s  = map snd runs
        avgAcc = avg accs
        stdAcc = std accs
        avgF1  = avg f1s
        stdF1  = std f1s
    putStrLn $ printf "  => Acc=%.4f +/- %.4f  F1=%.4f +/- %.4f" avgAcc stdAcc avgF1 stdF1
    putStrLn ""
    return (lam, avgAcc, stdAcc, avgF1, stdF1)
    ) lambdas

  endTime <- getCurrentTime
  let totalTime = realToFrac (diffUTCTime endTime startTime) :: Double

  -- Print summary table
  putStrLn "========================================"
  putStrLn "Lambda Sweep Summary"
  putStrLn "========================================"
  putStrLn $ printf "%-8s  %-16s  %-16s" ("lambda" :: String) ("Test Accuracy" :: String) ("F1 Score" :: String)
  putStrLn (replicate 44 '-')
  mapM_ (\(lam, aAcc, sAcc, aF1, sF1) ->
    putStrLn $ printf "%-8.2f  %.4f +/- %.4f  %.4f +/- %.4f" lam aAcc sAcc aF1 sF1
    ) results
  putStrLn (replicate 44 '-')
  putStrLn $ printf "Total time: %.1fs" totalTime

-- | Single training + evaluation run.
singleRun :: Float -> Float -> IO (Double, Double)
singleRun lambda beta = do
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

  -- Train
  paramMLPOpti <- trainBinary 1000 0.001 lambda beta trainData trainLabels binaryAxiomTens

  -- Evaluate via classifierA @FrmwkMeas
  let toPairs pts = [(predProb pt, labelA @FrmwkMeas pt) | pt <- pts]
        where predProb pt = pTrueDist (classifierA @FrmwkMeas paramMLPOpti pt)
      testPts = map (\[x1,x2] -> (x1,x2)) (Torch.asValue testData :: [[Float]]) :: [Point FrmwkMeas]
      testPairs = toPairs testPts
      accTest  = accuracy testPairs
      f1Test   = f1Score testPairs

  return (accTest, f1Test)

-- | Training loop.
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

  (paramMLPOpti, _) <- foldLoop (initModel, initOpt) [1 .. numEpochs] $ \(model, opt) _ -> do
    -- J = (1-lambda) * J_data + lambda * J_know
    let dataLoss = if lambda == 1.0 then zeroTens
                   else let preds = Torch.sigmoid (hThetaReal model trainData)
                        in Torch.sumAll (lossData preds trainLabels) `Torch.div` nTens
    let knowLoss = if lambda == 0.0 then zeroTens
                   else lossKnow (toDynamic (kbSatFormula betaT trainData model))
    let totalLoss = lossComb dataLoss knowLoss lambdaTens
    (newModel, newOpt) <- runStep model opt totalLoss lrTens
    return (newModel, newOpt)

  return paramMLPOpti

-- Helpers
avg :: [Double] -> Double
avg xs = sum xs / fromIntegral (length xs)

std :: [Double] -> Double
std xs = let m = avg xs; n = fromIntegral (length xs)
         in sqrt (sum (map (\x -> (x-m)*(x-m)) xs) / n)

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
