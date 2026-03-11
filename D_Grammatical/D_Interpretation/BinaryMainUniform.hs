{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Binary Classification evaluation (TensUniform, eager only).
module Main where

import B_Logical.D_Interpretation.DATA (DATA (..))
import C_NonLogical.D_Interpretation.BinaryUniformMLP (hTheta)
import C_NonLogical.D_Interpretation.BinaryUniform ()
import E_Inference.C_NonLogical.BinaryTrainingUniform (trainBinaryUniform)
import D_Grammatical.D_Interpretation.BinaryFormulasUniform (axiomUniform)
import C_NonLogical.A_Signature.BinarySig (BinaryFuns (classifierA))
import E_Benchmark.Metrics.Metrics (evaluateMetrics)

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensUniform Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryUniform 1000 0.001 axiomUniform

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (hTheta finalModel trainData) trainLabels (hTheta finalModel testData) testLabels

  putStrLn "\n--- Inference Test using DATA Category (Encoder + Decoder) ---"
  let pt1 = (0.5, 0.5) :: (Float, Float)
  let pt2 = (0.9, 0.9) :: (Float, Float)
  let ans1 = classifierA @DATA () pt1
  let ans2 = classifierA @DATA () pt2
  putStrLn $ "Inference for " ++ show pt1 ++ ": " ++ show ans1
  putStrLn $ "Inference for " ++ show pt2 ++ ": " ++ show ans2
  putStrLn "Finished."
