{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Executable for Binary Classification (TensUniform) using JIT training.
module Main where

import B_Interpretation.C_NonLogical.BinaryUniformMLP (hTheta)
import B_Interpretation.D_Grammatical.BinaryFormulasUniform (axiomUniform)
import D_Inference.C_NonLogical.BinaryTrainingUniformJIT (trainBinaryUniformJIT)
import E_Benchmark.Metrics.Metrics (evaluateMetrics)

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensUniform (JIT Compiled) Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryUniformJIT 1000 0.001 axiomUniform

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (hTheta finalModel trainData) trainLabels (hTheta finalModel testData) testLabels
  putStrLn "Finished."
