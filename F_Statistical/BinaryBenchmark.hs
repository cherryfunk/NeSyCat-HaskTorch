{-# LANGUAGE TypeApplications #-}

-- | Benchmark for binary classification.
--
--   1. Trains via BinaryTrainLib (epsilon level) -> theta*
--   2. Evaluates via classifierA @MeasU (gamma level) + BenchmarkFun (zeta level)
--
--   Training modes:
--     cabal run binary-benchmark                 -- fixed beta (default)
--     cabal run binary-benchmark -- beta          -- learnable beta
module Main where

-- Training (epsilon level) -- separate module
import BinaryTrainLib
  ( BinaryDataset (..),
    generateBinaryDataset,
    trainBinary,
    trainBinaryBeta,
  )

-- Domain theory (gamma level) -- classifierA, labelA
import A_Categorical.BA_Interpretation.StarIntp (MeasU)
import C_Domain.B_Theory.BinaryTheory (BinaryFun (..), BinaryKlFun (..), BinarySorts (..))
import C_Domain.BA_Interpretation.BinaryReal ()

-- Categorical realization -- pTrueDist
import B_Logical.DA_Realization.ExpectDist (pTrueDist)

-- Benchmark theory (zeta level) -- accuracy, f1Score, etc.
import F_Statistical.B_Theory.BenchmarkTheory (BenchmarkFun (..))
import F_Statistical.BA_Interpretation.BenchmarkIntpData ()

import System.Environment (getArgs)
import Text.Printf (printf)
import qualified Torch

main :: IO ()
main = do
  args <- getArgs
  let mode = case args of { ("beta":_) -> "beta"; ("jit":_) -> "jit"; _ -> "fixed" }

  -- === TRAINING (epsilon level) ===
  ds <- generateBinaryDataset
  thetaStar <- case mode of
    "beta" -> do
      (params, learnedBeta) <- trainBinaryBeta 1000 0.001 2.0 1.0 ds
      putStrLn $ printf "Learned beta: %.4f" (Torch.asValue learnedBeta :: Float)
      return params
    _ ->
      trainBinary 1000 0.001 1.0 1.75 ds

  -- === BENCHMARKING (zeta level) ===
  -- Convert tensor data to MeasU points
  let toPoints t = map (\[x1, x2] -> (x1, x2)) (Torch.asValue t :: [[Float]]) :: [Point MeasU]
      trainPts = toPoints (trainData ds)
      testPts  = toPoints (testData ds)

  -- Build (prediction, label) pairs using the universe
  let evalPairs pts =
        [ (pTrueDist (classifierA @MeasU thetaStar pt), labelA @MeasU pt)
        | pt <- pts
        ]

  -- Apply BenchmarkFun metrics (from the theory)
  let trainPairs = evalPairs trainPts
      testPairs  = evalPairs testPts
      accTrain   = accuracy trainPairs
      accTest    = accuracy testPairs
      f1Test     = f1Score testPairs
      precTest   = precision testPairs
      (pPos, pNeg) = confidence testPairs

  -- Report
  putStrLn ""
  putStrLn $ printf "Binary Benchmark (mode=%s, classifierA @MeasU):" mode
  putStrLn $ printf "  Accuracy:    Train=%.4f  Test=%.4f" accTrain accTest
  putStrLn $ printf "  F1 Score:    %.4f" f1Test
  putStrLn $ printf "  Precision:   %.4f" precTest
  putStrLn $ printf "  Confidence:  P+=%.4f  P-=%.4f" pPos pNeg
