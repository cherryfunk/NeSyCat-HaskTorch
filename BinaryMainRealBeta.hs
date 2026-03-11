{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Binary Classification with learnable β (TensRealBeta, eager).
--
--   Joint optimization of β (LogSumExp sharpness) and θ (MLP weights).
module Main where

import C_NonLogical.D_Interpretation.DATA (DATA (..))
import C_NonLogical.D_Interpretation.BinaryRealMLP (hThetaReal)
import C_NonLogical.D_Interpretation.BinaryReal ()
import E_Inference.C_NonLogical.BinaryTrainingRealBeta (trainBinaryRealBeta)
import D_Grammatical.D_Interpretation.BinaryFormulasRealBeta (axiomRealBeta)
import C_NonLogical.A_Signature.BinarySig (BinaryKlFuns (classifierA))
import E_Benchmark.Metrics.Metrics (evaluateMetrics)
import qualified Torch

main :: IO ()
main = do
  putStrLn "Starting Binary Classification with Learnable Beta"
  (finalModel, learnedBeta, trainData, trainLabels, testData, testLabels) <-
    trainBinaryRealBeta 1000 0.001 1.25 axiomRealBeta

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
