{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Binary Classification with learnable beta (TensRealBeta, eager).
--   Usage: binary-test-real-beta [lambda]
--   lambda=0 (default): pure axiom-driven
--   lambda=1: pure data-driven
module Main where

import C_Domain.A_Category.Data (DATA (..))
import C_Domain.F_Interpretation.BinaryRealMLP (hThetaReal)
import C_Domain.F_Interpretation.BinaryReal ()
import C_Domain.G_Parameters.BinaryTrainingRealBeta (trainBinaryRealBeta)
import D_Grammatical.F_Interpretation.BinaryFormulasRealBeta (axiomRealBeta)
import C_Domain.D_Theory.BinaryTheory (BinaryKlFun (classifierA))
import E_Benchmark.Metrics.Metrics (evaluateMetrics)
import qualified Torch
import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  let lambda = case args of
        (x:_) -> read x :: Float
        _     -> 0.0
  putStrLn $ "Starting Binary Classification with Learnable Beta (lambda=" ++ show lambda ++ ")"
  (finalModel, learnedBeta, trainData, trainLabels, testData, testLabels) <-
    trainBinaryRealBeta 1000 0.001 1.25 lambda axiomRealBeta

  let betaVal = Torch.asValue learnedBeta :: Float
  putStrLn $ "\n=== Learned Beta: " ++ show betaVal ++ " ==="

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics
    (Torch.sigmoid (hThetaReal finalModel trainData))
    trainLabels
    (Torch.sigmoid (hThetaReal finalModel testData))
    testLabels

  putStrLn "\n--- Inference Test using DATA Category ---"
  let pt1 = (0.5, 0.5) :: (Float, Float)
  let pt2 = (0.9, 0.9) :: (Float, Float)
  let ans1 = classifierA @DATA () pt1
  let ans2 = classifierA @DATA () pt2
  putStrLn $ "Inference for " ++ show pt1 ++ ": " ++ show ans1
  putStrLn $ "Inference for " ++ show pt2 ++ ": " ++ show ans2
  putStrLn "Finished."
