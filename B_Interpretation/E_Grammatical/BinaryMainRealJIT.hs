{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE TypeApplications #-}

-- | Executable for Binary Classification (TensReal) using JIT training.
module Main where

import B_Interpretation.D_NonLogical.BinaryRealMLP (hThetaReal)
import B_Interpretation.E_Grammatical.BinaryFormulasReal (axiomReal)
import D_Inference.D_NonLogical.BinaryTrainingRealJIT (trainBinaryRealJIT)
import E_Benchmark.Metrics.Metrics (evaluateMetrics)
import qualified Torch

main :: IO ()
main = do
  putStrLn "Starting Binary Classification TensReal (JIT Compiled) Evaluation"
  (finalModel, trainData, trainLabels, testData, testLabels) <- trainBinaryRealJIT 1000 0.001 axiomReal

  putStrLn "\n=== Evaluation ==="
  evaluateMetrics (Torch.sigmoid (hThetaReal finalModel trainData)) trainLabels (Torch.sigmoid (hThetaReal finalModel testData)) testLabels
  putStrLn "Finished."
