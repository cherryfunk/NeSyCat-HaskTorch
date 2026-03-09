{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Binary Classification with learnable β (TensRealBeta, eager).
--
--   Joint optimization of β (LogSumExp sharpness) and θ (MLP weights).
module Main where

import B_Interpretation.B_Typological.DATA (DATA (..))
import B_Interpretation.D_NonLogical.BinaryRealMLP (hThetaReal)
import B_Interpretation.D_NonLogical.BinaryReal ()
import D_Inference.D_NonLogical.BinaryTrainingRealBeta (trainBinaryRealBeta)
import B_Interpretation.E_Grammatical.BinaryFormulasRealBeta (axiomRealBeta)
import A_Syntax.D_NonLogical.BinaryVocab (Binary_Vocab (classifierA))
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
  let pt1 = [0.5, 0.5] :: [Float]
  let pt2 = [0.9, 0.9] :: [Float]
  let ans1 = classifierA @DATA () pt1
  let ans2 = classifierA @DATA () pt2
  putStrLn $ "Inference for " ++ show pt1 ++ ": " ++ show ans1
  putStrLn $ "Inference for " ++ show pt2 ++ ": " ++ show ans2
  putStrLn "Finished."
