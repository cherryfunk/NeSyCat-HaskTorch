{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Binary Classification evaluation (TensReal, eager only).
--   Usage: binary-test-real [lambda]
--   lambda=0 (default): pure axiom-driven (paper setting)
--   lambda=1: pure data-driven (cross-entropy)
--   lambda=0.5: convex combination
module Main where

import C_Domain.A_Category.Data (DATA (..))
import C_Domain.F_Interpretation.BinaryRealMLP (hThetaReal)
import C_Domain.F_Interpretation.BinaryReal ()
import C_Domain.G_Parameters.BinaryTrainingReal (trainBinaryReal)
import D_Grammatical.F_Interpretation.BinaryFormulasReal (axiomReal)
import C_Domain.D_Theory.BinaryTheory (BinaryKlFun (classifierA))
import E_Benchmark.Metrics.Metrics (evaluateMetrics)
import qualified Torch
import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  let lambda = case args of
        (x:_) -> read x :: Float
        _     -> 0.0  -- default: pure axiom-driven (paper setting)
  putStrLn $ "Starting Binary Classification TensReal Evaluation (lambda=" ++ show lambda ++ ")"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryReal 1000 0.001 lambda axiomReal

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels (Torch.sigmoid (hThetaReal finalModel testData)) testLabels

  putStrLn "\n--- Inference Test using DATA Category (Encoder + Decoder) ---"
  let pt1 = (0.5, 0.5) :: (Float, Float)
  let pt2 = (0.9, 0.9) :: (Float, Float)
  let ans1 = classifierA @DATA () pt1
  let ans2 = classifierA @DATA () pt2
  putStrLn $ "Inference for " ++ show pt1 ++ ": " ++ show ans1
  putStrLn $ "Inference for " ++ show pt2 ++ ": " ++ show ans2
  putStrLn "Finished."
