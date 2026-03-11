{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Binary Classification evaluation (TensReal, eager only).
module Main where

import B_Logical.D_Interpretation.DATA (DATA (..))
import C_NonLogical.D_Interpretation.BinaryRealMLP (hThetaReal)
import C_NonLogical.D_Interpretation.BinaryReal ()
import E_Inference.C_NonLogical.BinaryTrainingReal (trainBinaryReal)
import D_Grammatical.D_Interpretation.BinaryFormulasReal (axiomReal)
import C_NonLogical.A_Signature.BinarySig (BinarySig (classifierA))
import E_Benchmark.Metrics.Metrics (evaluateMetrics)
import qualified Torch

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensReal Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryReal 1000 0.001 axiomReal

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels (Torch.sigmoid (hThetaReal finalModel testData)) testLabels

  putStrLn "\n--- Inference Test using DATA Category (Encoder + Decoder) ---"
  let pt1 = [0.5, 0.5] :: [Float]
  let pt2 = [0.9, 0.9] :: [Float]
  let ans1 = classifierA @DATA () pt1
  let ans2 = classifierA @DATA () pt2
  putStrLn $ "Inference for " ++ show pt1 ++ ": " ++ show ans1
  putStrLn $ "Inference for " ++ show pt2 ++ ": " ++ show ans2
  putStrLn "Finished."
