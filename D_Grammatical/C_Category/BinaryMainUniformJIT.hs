{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Executable for Binary Classification (TensUniform) using JIT training.
module Main where

import C_NonLogical.C_Category.BinaryUniformMLP (hTheta)
import D_Grammatical.C_Category.BinaryFormulasUniform (axiomUniform)
import E_Inference.C_NonLogical.BinaryTrainingUniformJIT (trainBinaryUniformJIT)
import E_Benchmark.Metrics.Metrics (evaluateMetrics)

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensUniform (JIT Compiled) Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryUniformJIT 1000 0.001 axiomUniform

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (hTheta finalModel trainData) trainLabels (hTheta finalModel testData) testLabels
  putStrLn "Finished."
