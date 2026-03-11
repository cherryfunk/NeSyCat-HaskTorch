{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Executable for Binary Classification (TensReal) using JIT training.
module Main where

import C_NonLogical.C_Category.BinaryRealMLP (hThetaReal)
import D_Grammatical.C_Category.BinaryFormulasReal (axiomReal)
import E_Inference.C_NonLogical.BinaryTrainingRealJIT (trainBinaryRealJIT)
import E_Benchmark.Metrics.Metrics (evaluateMetrics)
import qualified Torch

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensReal (JIT Compiled) Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryRealJIT 1000 0.001 axiomReal

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels (Torch.sigmoid (hThetaReal finalModel testData)) testLabels
  putStrLn "Finished."
