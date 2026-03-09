{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Executable for Binary Classification (TensUniform) using JIT training.
module Main where

import B_Interpretation.D_NonLogical.BinaryUniformMLP (hTheta)
import B_Interpretation.E_Grammatical.BinaryFormulasUniform (axiomUniform)
import D_Inference.D_NonLogical.BinaryTrainingUniformJIT (trainBinaryUniformJIT)
import E_Benchmark.Metrics.Metrics (evaluateMetrics)

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensUniform (JIT Compiled) Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryUniformJIT 1000 0.001 axiomUniform

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (hTheta finalModel trainData) trainLabels (hTheta finalModel testData) testLabels
  putStrLn "Finished."
