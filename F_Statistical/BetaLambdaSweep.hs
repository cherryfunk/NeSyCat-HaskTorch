{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Two-stage sweep benchmark:
--   1. Beta sweep: find optimal beta (lambda=1, pure axiom)
--   2. Lambda sweep: with best beta, sweep lambda from 0 (pure data) to 1 (pure axiom)
--
--   Outputs CSV-style data for plotting.
--
--   Usage: cabal run beta-lambda-sweep
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

import Data.List (maximumBy)
import Data.Ord (comparing)
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
  let nRuns = 20 :: Int
  startTime <- getCurrentTime

  -- ============================================================
  -- Stage 1: Beta sweep (lambda=1, pure axiom)
  -- ============================================================
  let betas = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0] :: [Float]

  putStrLn "========================================"
  putStrLn "Stage 1: Beta Sweep (lambda=1, pure axiom)"
  putStrLn "========================================"
  putStrLn $ printf "%d runs per setting, 1000 epochs" nRuns
  putStrLn ""

  betaResults <- mapM (\beta -> do
    runs <- mapM (\_ -> singleRun 1.0 beta) [1..nRuns]
    let accs = map fst runs
        f1s  = map snd runs
    putStrLn $ printf "  beta=%.2f  Acc=%.4f +/- %.4f  F1=%.4f +/- %.4f"
      beta (avg accs) (std accs) (avg f1s) (std f1s)
    return (beta, avg accs, std accs, avg f1s, std f1s)
    ) betas

  -- Find best beta by F1
  let (bestBeta, _, _, bestF1, _) = maximumBy (comparing (\(_,_,_,f,_) -> f)) betaResults
  putStrLn ""
  putStrLn $ printf "Best beta: %.2f (F1=%.4f)" bestBeta bestF1

  -- Print beta sweep CSV
  putStrLn ""
  putStrLn "--- Beta Sweep CSV ---"
  putStrLn "beta,acc_mean,acc_std,f1_mean,f1_std"
  mapM_ (\(b, am, as, fm, fs) ->
    putStrLn $ printf "%.2f,%.4f,%.4f,%.4f,%.4f" b am as fm fs
    ) betaResults

  -- ============================================================
  -- Stage 2: Lambda sweep (with best beta)
  -- ============================================================
  let lambdas = [0.0, 0.25, 0.5, 0.75, 1.0] :: [Float]

  putStrLn ""
  putStrLn "========================================"
  putStrLn $ printf "Stage 2: Lambda Sweep (beta=%.2f)" bestBeta
  putStrLn "========================================"
  putStrLn $ printf "%d runs per setting, 1000 epochs" nRuns
  putStrLn ""

  lambdaResults <- mapM (\lam -> do
    runs <- mapM (\_ -> singleRun lam bestBeta) [1..nRuns]
    let accs = map fst runs
        f1s  = map snd runs
    putStrLn $ printf "  lambda=%.2f  Acc=%.4f +/- %.4f  F1=%.4f +/- %.4f"
      lam (avg accs) (std accs) (avg f1s) (std f1s)
    return (lam, avg accs, std accs, avg f1s, std f1s)
    ) lambdas

  -- Print lambda sweep CSV
  putStrLn ""
  putStrLn "--- Lambda Sweep CSV ---"
  putStrLn "lambda,acc_mean,acc_std,f1_mean,f1_std"
  mapM_ (\(l, am, as, fm, fs) ->
    putStrLn $ printf "%.2f,%.4f,%.4f,%.4f,%.4f" l am as fm fs
    ) lambdaResults

  endTime <- getCurrentTime
  let totalTime = realToFrac (diffUTCTime endTime startTime) :: Double
  putStrLn ""
  putStrLn $ printf "Total time: %.1fs" totalTime

-- | Single training + evaluation run.
singleRun :: Float -> Float -> IO (Double, Double)
singleRun lambda beta = do
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

  paramMLPOpti <- trainBinary 1000 0.001 lambda beta trainData trainLabels binaryAxiomTens

  let toPairs pts = [(predProb pt, labelA @FrmwkMeas pt) | pt <- pts]
        where predProb pt = pTrueDist (classifierA @FrmwkMeas paramMLPOpti pt)
      testPts = map (\[x1,x2] -> (x1,x2)) (Torch.asValue testData :: [[Float]]) :: [Point FrmwkMeas]
      testPairs = toPairs testPts
  return (accuracy testPairs, f1Score testPairs)

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
    let dataLoss = if lambda == 1.0 then zeroTens
                   else let preds = Torch.sigmoid (hThetaReal model trainData)
                        in Torch.sumAll (lossData preds trainLabels) `Torch.div` nTens
    let knowLoss = if lambda == 0.0 then zeroTens
                   else lossKnow (toDynamic (kbSatFormula betaT trainData model))
    let totalLoss = lossComb dataLoss knowLoss lambdaTens
    (newModel, newOpt) <- runStep model opt totalLoss lrTens
    return (newModel, newOpt)

  return paramMLPOpti

avg :: [Double] -> Double
avg xs = sum xs / fromIntegral (length xs)

std :: [Double] -> Double
std xs = let m = avg xs; n = fromIntegral (length xs)
         in sqrt (sum (map (\x -> (x-m)*(x-m)) xs) / n)

foldLoop :: a -> [b] -> (a -> b -> IO a) -> IO a
foldLoop acc [] _ = return acc
foldLoop acc (x : xs) f = f acc x >>= \a -> foldLoop a xs f
